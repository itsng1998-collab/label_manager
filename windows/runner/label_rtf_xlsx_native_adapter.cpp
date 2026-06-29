#include <xlsxwriter.h>

#include <windows.h>

#include <algorithm>
#include <chrono>
#include <cctype>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <numeric>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace {

struct HtmlCell {
  std::string text;
  std::string html;
  std::string style;
  int row_span = 1;
  int column_span = 1;
  int width = 0;
};

using HtmlRow = std::vector<HtmlCell>;
using HtmlTable = std::vector<HtmlRow>;

struct HtmlTableData {
  HtmlTable rows;
  std::vector<int> column_widths;
  std::string css;
};

std::string HtmlEscape(const std::string& value);

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }
  const int size = WideCharToMultiByte(CP_UTF8, 0, value.data(),
                                      static_cast<int>(value.size()), nullptr,
                                      0, nullptr, nullptr);
  if (size <= 0) {
    std::string fallback;
    fallback.reserve(value.size());
    for (const wchar_t c : value) {
      fallback.push_back(static_cast<char>(c & 0xff));
    }
    return fallback;
  }
  std::string utf8(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.data(), static_cast<int>(value.size()),
                      utf8.data(), size, nullptr, nullptr);
  return utf8;
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }
  const int size = MultiByteToWideChar(CP_UTF8, 0, value.data(),
                                      static_cast<int>(value.size()), nullptr,
                                      0);
  if (size <= 0) {
    return std::wstring(value.begin(), value.end());
  }
  std::wstring wide(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.data(), static_cast<int>(value.size()),
                      wide.data(), size);
  return wide;
}

std::string BytesToUtf8(const std::string& value, UINT code_page) {
  if (value.empty()) {
    return std::string();
  }
  int size = MultiByteToWideChar(code_page, MB_ERR_INVALID_CHARS, value.data(),
                                 static_cast<int>(value.size()), nullptr, 0);
  DWORD flags = MB_ERR_INVALID_CHARS;
  if (size <= 0) {
    flags = 0;
    size = MultiByteToWideChar(code_page, flags, value.data(),
                               static_cast<int>(value.size()), nullptr, 0);
  }
  if (size <= 0) {
    return value;
  }
  std::wstring wide(size, L'\0');
  MultiByteToWideChar(code_page, flags, value.data(),
                      static_cast<int>(value.size()), wide.data(), size);
  return WideToUtf8(wide);
}

bool IsValidUtf8(const std::string& value) {
  if (value.empty()) {
    return true;
  }
  return MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
                             static_cast<int>(value.size()), nullptr, 0) > 0;
}

std::string RtfHtmlTextToUtf8(const std::string& value) {
  if (IsValidUtf8(value)) {
    return value;
  }
  const UINT ansi_code_page = GetACP();
  if (ansi_code_page != CP_UTF8) {
    return BytesToUtf8(value, ansi_code_page);
  }
  return BytesToUtf8(value, 949);
}

std::string LowerAscii(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
    return static_cast<char>(std::tolower(c));
  });
  return value;
}

std::string Trim(std::string value) {
  const auto first = std::find_if_not(
      value.begin(), value.end(),
      [](unsigned char c) { return std::isspace(c) != 0; });
  const auto last = std::find_if_not(
                        value.rbegin(), value.rend(),
                        [](unsigned char c) { return std::isspace(c) != 0; })
                        .base();
  if (first >= last) {
    return std::string();
  }
  return std::string(first, last);
}

void ReplaceAll(std::string* value, const std::string& from,
                const std::string& to) {
  if (from.empty()) {
    return;
  }
  std::string::size_type pos = 0;
  while ((pos = value->find(from, pos)) != std::string::npos) {
    value->replace(pos, from.size(), to);
    pos += to.size();
  }
}

std::string SanitizeCss(std::string css) {
  ReplaceAll(&css, "WindowText", "#000");
  ReplaceAll(&css, "Window", "#fff");
  ReplaceAll(&css, "'b1bcb8b2', monospace",
             "'Gulim','Malgun Gothic',monospace");
  ReplaceAll(&css, "b1bcb8b2, monospace",
             "'Gulim','Malgun Gothic',monospace");
  return css;
}

std::string ExtractStyleSheet(const std::string& html) {
  const std::string lower = LowerAscii(html);
  const size_t style_start = lower.find("<style");
  if (style_start == std::string::npos) {
    return std::string();
  }
  const size_t open_end = lower.find('>', style_start);
  const size_t style_end = lower.find("</style>",
                                      open_end == std::string::npos
                                          ? style_start
                                          : open_end + 1);
  if (open_end == std::string::npos || style_end == std::string::npos) {
    return std::string();
  }
  const std::string css = SanitizeCss(
      html.substr(open_end + 1, style_end - open_end - 1));
  std::string filtered;
  size_t search = 0;
  while (search < css.size()) {
    const size_t block_end = css.find('}', search);
    if (block_end == std::string::npos) {
      break;
    }
    const std::string rule = Trim(css.substr(search, block_end - search + 1));
    const std::string rule_lower = LowerAscii(rule);
    if (rule_lower.rfind(".cls", 0) == 0 ||
        rule_lower.rfind("sup", 0) == 0 ||
        rule_lower.rfind("sub", 0) == 0) {
      filtered += rule;
      filtered.push_back('\n');
    }
    search = block_end + 1;
  }
  return filtered;
}

std::string DecodeHtmlEntities(std::string value) {
  struct Entity {
    const char* encoded;
    const char* decoded;
  };
  constexpr Entity entities[] = {
      {"&nbsp;", " "}, {"&amp;", "&"}, {"&lt;", "<"},
      {"&gt;", ">"},   {"&quot;", "\""}, {"&#39;", "'"},
      {"&frac14;", "\xBC"},
  };
  for (const auto& entity : entities) {
    std::string::size_type pos = 0;
    while ((pos = value.find(entity.encoded, pos)) != std::string::npos) {
      value.replace(pos, std::strlen(entity.encoded), entity.decoded);
      pos += std::strlen(entity.decoded);
    }
  }
  return value;
}

std::string NormalizeHtmlFragment(std::string_view html) {
  std::string normalized;
  size_t index = 0;
  while (index < html.size()) {
    if (html[index] == '<') {
      const size_t end = html.find('>', index);
      if (end == std::string_view::npos) {
        break;
      }
      normalized.append(html.substr(index, end - index + 1));
      index = end + 1;
      continue;
    }
    const size_t next_tag = html.find('<', index);
    const std::string text(html.substr(
        index, next_tag == std::string_view::npos ? std::string_view::npos
                                                  : next_tag - index));
    normalized += HtmlEscape(RtfHtmlTextToUtf8(DecodeHtmlEntities(text)));
    if (next_tag == std::string_view::npos) {
      break;
    }
    index = next_tag;
  }
  return normalized;
}

std::string StripHtmlTags(std::string_view html) {
  std::string text;
  for (size_t index = 0; index < html.size(); index += 1) {
    const char c = html[index];
    if (c != '<') {
      text.push_back(c);
      continue;
    }

    const size_t end = html.find('>', index);
    if (end == std::string_view::npos) {
      continue;
    }
    const std::string tag = LowerAscii(std::string(html.substr(index + 1, end - index - 1)));
    if (tag.rfind("p", 0) == 0 || tag.rfind("/p", 0) == 0 ||
        tag.rfind("br", 0) == 0) {
      if (!text.empty() && text.back() != '\n') {
        text.push_back('\n');
      }
    } else {
      text.push_back(' ');
    }
    index = end;
  }

  std::string collapsed;
  bool previous_space = false;
  for (const unsigned char c : text) {
    if (c == '\n') {
      while (!collapsed.empty() && collapsed.back() == ' ') {
        collapsed.pop_back();
      }
      if (!collapsed.empty() && collapsed.back() != '\n') {
        collapsed.push_back('\n');
      }
      previous_space = false;
      continue;
    }
    const bool is_space = std::isspace(c) != 0;
    if (is_space) {
      if (!previous_space && !collapsed.empty() && collapsed.back() != '\n') {
        collapsed.push_back(' ');
      }
      previous_space = true;
      continue;
    }
    collapsed.push_back(static_cast<char>(c));
    previous_space = false;
  }
  return RtfHtmlTextToUtf8(DecodeHtmlEntities(Trim(collapsed)));
}

int AttributeInt(std::string_view tag, const char* name, int fallback) {
  const std::string lower = LowerAscii(std::string(tag));
  const std::string key = std::string(name) + "=";
  auto pos = lower.find(key);
  if (pos == std::string::npos) {
    return fallback;
  }
  pos += key.size();
  while (pos < lower.size() &&
         std::isspace(static_cast<unsigned char>(lower[pos])) != 0) {
    pos += 1;
  }
  char quote = 0;
  if (pos < lower.size() && (lower[pos] == '\'' || lower[pos] == '"')) {
    quote = lower[pos++];
  }
  std::string digits;
  while (pos < lower.size()) {
    const char c = lower[pos++];
    if (quote != 0 && c == quote) {
      break;
    }
    if (std::isdigit(static_cast<unsigned char>(c)) != 0) {
      digits.push_back(c);
    } else if (!digits.empty()) {
      break;
    }
  }
  return digits.empty() ? fallback : std::max(1, std::stoi(digits));
}

std::string AttributeString(std::string_view tag, const char* name) {
  const std::string source(tag);
  const std::string lower = LowerAscii(source);
  const std::string key = std::string(name) + "=";
  size_t pos = lower.find(key);
  if (pos == std::string::npos) {
    return std::string();
  }
  pos += key.size();
  while (pos < source.size() &&
         std::isspace(static_cast<unsigned char>(source[pos])) != 0) {
    pos += 1;
  }
  if (pos >= source.size()) {
    return std::string();
  }
  if (source[pos] == '\'' || source[pos] == '"') {
    const char quote = source[pos++];
    const size_t end = source.find(quote, pos);
    return end == std::string::npos ? source.substr(pos)
                                    : source.substr(pos, end - pos);
  }
  const size_t end = source.find_first_of(" \t\r\n>", pos);
  return end == std::string::npos ? source.substr(pos)
                                  : source.substr(pos, end - pos);
}

std::string PresentationStyle(std::string style) {
  const std::string lower = LowerAscii(style);
  std::string kept;
  size_t start = 0;
  while (start < style.size()) {
    const size_t end = style.find(';', start);
    const std::string item = Trim(style.substr(
        start, end == std::string::npos ? std::string::npos : end - start));
    const std::string item_lower = LowerAscii(item);
    if (item_lower.rfind("background", 0) == 0 ||
        item_lower.rfind("color", 0) == 0 ||
        item_lower.rfind("font", 0) == 0 ||
        item_lower.rfind("vertical-align", 0) == 0) {
      if (!kept.empty() && kept.back() != ';') {
        kept.push_back(';');
      }
      kept += item;
    }
    if (end == std::string::npos) {
      break;
    }
    start = end + 1;
  }
  return SanitizeCss(kept);
}

std::vector<std::pair<size_t, size_t>> TagRanges(const std::string& html,
                                                const char* open_prefix,
                                                const char* close_tag) {
  std::vector<std::pair<size_t, size_t>> ranges;
  const std::string lower = LowerAscii(html);
  size_t search = 0;
  while (true) {
    const size_t open = lower.find(open_prefix, search);
    if (open == std::string::npos) {
      break;
    }
    const size_t open_end = lower.find('>', open);
    if (open_end == std::string::npos) {
      break;
    }
    const size_t close = lower.find(close_tag, open_end + 1);
    if (close == std::string::npos) {
      break;
    }
    ranges.emplace_back(open, close + std::strlen(close_tag));
    search = close + std::strlen(close_tag);
  }
  return ranges;
}

HtmlTableData ParseHtmlTable(const std::string& html) {
  HtmlTableData data;
  data.css = ExtractStyleSheet(html);
  const std::string lower = LowerAscii(html);
  const size_t table_start = lower.find("<table");
  const size_t table_end = lower.rfind("</table>");
  std::string table_html = html;
  if (table_start != std::string::npos && table_end != std::string::npos &&
      table_end > table_start) {
    table_html = html.substr(table_start, table_end - table_start + 8);
  }

  for (const auto& row_range : TagRanges(table_html, "<tr", "</tr>")) {
    const std::string row_html =
        table_html.substr(row_range.first, row_range.second - row_range.first);
    const std::string row_lower = LowerAscii(row_html);
    HtmlRow row;
    size_t search = 0;
    while (true) {
      const size_t td = row_lower.find("<td", search);
      const size_t th = row_lower.find("<th", search);
      const size_t open = std::min(
          td == std::string::npos ? row_lower.size() : td,
          th == std::string::npos ? row_lower.size() : th);
      if (open >= row_lower.size()) {
        break;
      }
      const bool header = row_lower.compare(open, 3, "<th") == 0;
      const char* close_tag = header ? "</th>" : "</td>";
      const size_t open_end = row_lower.find('>', open);
      const size_t close = row_lower.find(
          close_tag, open_end == std::string::npos ? open : open_end + 1);
      if (open_end == std::string::npos || close == std::string::npos) {
        break;
      }
      const std::string open_tag = row_html.substr(open, open_end - open + 1);
      const std::string cell_html = std::string(
          std::string_view(row_html).substr(open_end + 1, close - open_end - 1));
      row.push_back(HtmlCell{
          StripHtmlTags(cell_html),
          NormalizeHtmlFragment(cell_html),
          PresentationStyle(AttributeString(open_tag, "style")),
          AttributeInt(open_tag, "rowspan", 1),
          AttributeInt(open_tag, "colspan", 1),
          AttributeInt(open_tag, "width", 0),
      });
      search = close + std::strlen(close_tag);
    }
    const bool has_text = std::any_of(row.begin(), row.end(), [](const auto& cell) {
      return !cell.text.empty();
    });
    if (!has_text && data.rows.empty()) {
      if (data.column_widths.empty()) {
        for (const auto& cell : row) {
          for (int repeat = 0; repeat < std::max(1, cell.column_span); repeat += 1) {
            data.column_widths.push_back(std::max(0, cell.width));
          }
        }
      }
      continue;
    }
    if (!row.empty()) {
      data.rows.push_back(row);
    }
  }

  if (!data.rows.empty()) {
    return data;
  }
  const std::string text = StripHtmlTags(html);
  if (!text.empty()) {
    data.rows.push_back(
        HtmlRow{HtmlCell{text, HtmlEscape(text), std::string(), 1, 1, 0}});
  }
  return data;
}

bool WriteTextFile(const std::filesystem::path& path, const std::string& value,
                   std::string* error_message) {
  std::ofstream file(path, std::ios::binary);
  if (!file) {
    if (error_message != nullptr) {
      *error_message = "failed to open temporary RTF file";
    }
    return false;
  }
  file.write(value.data(), static_cast<std::streamsize>(value.size()));
  return true;
}

bool ReadTextFile(const std::filesystem::path& path, std::string* value,
                  std::string* error_message) {
  std::ifstream file(path, std::ios::binary);
  if (!file) {
    if (error_message != nullptr) {
      *error_message = "rtf2html did not create an HTML output file";
    }
    return false;
  }
  std::ostringstream buffer;
  buffer << file.rdbuf();
  *value = buffer.str();
  return true;
}

void CopyIfPossible(const std::filesystem::path& source,
                    const std::filesystem::path& target) {
  std::error_code error_code;
  std::filesystem::create_directories(target.parent_path(), error_code);
  error_code.clear();
  std::filesystem::copy_file(source, target,
                             std::filesystem::copy_options::overwrite_existing,
                             error_code);
}

std::wstring Quote(const std::wstring& value) {
  std::wstring quoted = L"\"";
  quoted += value;
  quoted += L"\"";
  return quoted;
}

bool RunRtf2Html(const std::filesystem::path& input_rtf,
                 const std::filesystem::path& output_html,
                 std::string* error_message) {
  std::wstring command =
      Quote(Utf8ToWide(LABEL_MANAGER_NATIVE_RTF2HTML_EXECUTABLE));
  command += L" ";
  command += Quote(input_rtf.wstring());
  command += L" ";
  command += Quote(output_html.wstring());

  STARTUPINFOW startup_info{};
  startup_info.cb = sizeof(startup_info);
  PROCESS_INFORMATION process_info{};
  std::vector<wchar_t> mutable_command(command.begin(), command.end());
  mutable_command.push_back(L'\0');
  if (!CreateProcessW(nullptr, mutable_command.data(), nullptr, nullptr, FALSE,
                      CREATE_NO_WINDOW, nullptr, nullptr, &startup_info,
                      &process_info)) {
    if (error_message != nullptr) {
      *error_message = "failed to start rtf2html executable";
    }
    return false;
  }
  WaitForSingleObject(process_info.hProcess, INFINITE);
  DWORD exit_code = 1;
  GetExitCodeProcess(process_info.hProcess, &exit_code);
  CloseHandle(process_info.hThread);
  CloseHandle(process_info.hProcess);
  if (exit_code != 0) {
    if (error_message != nullptr) {
      *error_message = "rtf2html exited with code " + std::to_string(exit_code);
    }
    return false;
  }
  return true;
}

int ColumnCount(const HtmlTable& table) {
  int column_count = 1;
  for (const auto& row : table) {
    int columns = 0;
    for (const auto& cell : row) {
      columns += std::max(1, cell.column_span);
    }
    column_count = std::max(column_count, columns);
  }
  return column_count;
}

std::vector<std::string> SplitLines(const std::string& text) {
  std::vector<std::string> lines;
  size_t start = 0;
  while (start <= text.size()) {
    const size_t end = text.find('\n', start);
    std::string line = text.substr(
        start, end == std::string::npos ? std::string::npos : end - start);
    while (!line.empty() && line.back() == ' ') {
      line.pop_back();
    }
    size_t first = 0;
    while (first < line.size() && line[first] == ' ') {
      first += 1;
    }
    if (first > 0) {
      line.erase(0, first);
    }
    lines.push_back(line);
    if (end == std::string::npos) {
      break;
    }
    start = end + 1;
  }
  while (lines.size() > 1 && lines.back().empty()) {
    lines.pop_back();
  }
  return lines.empty() ? std::vector<std::string>{std::string()} : lines;
}

std::vector<std::string> SplitHtmlLines(const HtmlCell& cell) {
  std::vector<std::string> lines;
  if (!cell.html.empty()) {
    for (const auto& range : TagRanges(cell.html, "<p", "</p>")) {
      std::string line = cell.html.substr(range.first, range.second - range.first);
      const std::string text = StripHtmlTags(line);
      if (!text.empty()) {
        lines.push_back(line);
      }
    }
  }
  if (!lines.empty()) {
    return lines;
  }
  for (const auto& text_line : SplitLines(cell.text)) {
    lines.push_back(HtmlEscape(text_line));
  }
  return lines.empty() ? std::vector<std::string>{std::string()} : lines;
}

HtmlTable ExpandMultilineRows(const HtmlTable& table) {
  HtmlTable expanded;
  for (const auto& row : table) {
    std::vector<std::vector<std::string>> cell_lines;
    std::vector<std::vector<std::string>> cell_html_lines;
    int expanded_row_count = 1;
    cell_lines.reserve(row.size());
    cell_html_lines.reserve(row.size());
    for (const auto& cell : row) {
      cell_lines.push_back(SplitLines(cell.text));
      cell_html_lines.push_back(SplitHtmlLines(cell));
      expanded_row_count = std::max(
          expanded_row_count, static_cast<int>(cell_lines.back().size()));
    }
    for (int line_index = 0; line_index < expanded_row_count; line_index += 1) {
      HtmlRow expanded_row;
      expanded_row.reserve(row.size());
      for (size_t cell_index = 0; cell_index < row.size(); cell_index += 1) {
        HtmlCell cell = row[cell_index];
        cell.text = line_index < static_cast<int>(cell_lines[cell_index].size())
                        ? cell_lines[cell_index][line_index]
                        : std::string();
        cell.html =
            line_index < static_cast<int>(cell_html_lines[cell_index].size())
                ? cell_html_lines[cell_index][line_index]
                : std::string();
        cell.row_span = 1;
        expanded_row.push_back(cell);
      }
      expanded.push_back(expanded_row);
    }
  }
  return expanded;
}

std::string RowText(const HtmlRow& row) {
  std::string text;
  for (const auto& cell : row) {
    if (!text.empty()) {
      text.push_back(' ');
    }
    text += cell.text;
  }
  return text;
}

bool IsSectionBottomRow(const HtmlTable& table, int row_index) {
  if (row_index == static_cast<int>(table.size()) - 1) {
    return true;
  }
  if (table.size() == 10) {
    return row_index == 2 || row_index == 3 || row_index == 6;
  }
  const std::string text = RowText(table[row_index]);
  return text.find("#ELEMENT") != std::string::npos ||
         text.find("#ALLERGY") != std::string::npos ||
         text.find("#PARTMARK") != std::string::npos;
}

std::string HtmlEscape(const std::string& value) {
  std::string escaped;
  escaped.reserve(value.size());
  for (const char c : value) {
    switch (c) {
      case '&':
        escaped += "&amp;";
        break;
      case '<':
        escaped += "&lt;";
        break;
      case '>':
        escaped += "&gt;";
        break;
      case '"':
        escaped += "&quot;";
        break;
      default:
        escaped.push_back(c);
        break;
    }
  }
  return escaped;
}

std::string BuildNormalizedHtml(const HtmlTableData& table_data) {
  const HtmlTable table = ExpandMultilineRows(table_data.rows);
  const int columns = ColumnCount(table);
  const int total_html_width = std::accumulate(
      table_data.column_widths.begin(), table_data.column_widths.end(), 0);
  std::ostringstream html;
  const std::string stylesheet = table_data.css.empty()
                                     ? ".cls0{font-weight:bold;}\n"
                                       ".cls1{font-weight:normal;}\n"
                                     : table_data.css;
  html << "<!doctype html>\n<html>\n<head>\n"
       << "<meta charset=\"utf-8\">\n"
       << "<style>\n"
       << stylesheet << "\n"
       << "body{margin:0;background:white;}\n"
       << "table{border-collapse:collapse;table-layout:fixed;}\n"
       << "p{margin:0;}\n"
       << "sup{vertical-align:super;font-size:75%;}\n"
       << "sub{vertical-align:sub;font-size:75%;}\n"
       << "td{border-left:1px solid #000;border-right:1px solid #000;"
         "border-top:0;border-bottom:0;vertical-align:middle;"
         "white-space:normal;overflow-wrap:anywhere;"
         "font-family:'Gulim','Malgun Gothic',monospace;"
         "font-size:4pt;line-height:1.05;padding:0 2px;}\n"
       << "td.bt{border-top:1px solid #000;}\n"
       << "td.bb{border-bottom:1px solid #000;}\n"
       << "</style>\n</head>\n<body>\n<table>\n";
  if (columns > 0) {
    html << "<colgroup>";
    for (int column = 0; column < columns; column += 1) {
      int width = 100;
      if (total_html_width > 0 &&
          column < static_cast<int>(table_data.column_widths.size())) {
        width = std::max(1, table_data.column_widths[column]);
      }
      html << "<col style=\"width:" << width << "px\">";
    }
    html << "</colgroup>\n";
  }
  for (int row_index = 0; row_index < static_cast<int>(table.size());
       row_index += 1) {
    const auto& row = table[row_index];
    html << "<tr>";
    const bool top_border = row_index == 0;
    const bool bottom_border = IsSectionBottomRow(table, row_index);
    for (const auto& cell : row) {
      html << "<td class=\"";
      if (top_border) {
        html << "bt";
      }
      if (bottom_border) {
        html << (top_border ? " bb" : "bb");
      }
      html << "\"";
      if (!cell.style.empty()) {
        html << " style=\"" << HtmlEscape(cell.style) << "\"";
      }
      if (cell.column_span > 1) {
        html << " colspan=\"" << cell.column_span << "\"";
      }
      html << ">" << (cell.html.empty() ? HtmlEscape(cell.text) : cell.html)
           << "</td>";
    }
    html << "</tr>\n";
  }
  html << "</table>\n</body>\n</html>\n";
  return html.str();
}

bool WriteXlsx(const HtmlTableData& table_data, const std::wstring& output_path,
               double width_mm, double height_mm, std::string* error_message) {
  const HtmlTable table = ExpandMultilineRows(table_data.rows);
  if (table.empty()) {
    if (error_message != nullptr) {
      *error_message = "rtf2html produced no table or text rows";
    }
    return false;
  }
  const std::string output_utf8 = WideToUtf8(output_path);
  lxw_workbook* workbook = workbook_new(output_utf8.c_str());
  if (workbook == nullptr) {
    if (error_message != nullptr) {
      *error_message = "failed to create XLSX workbook";
    }
    return false;
  }
  lxw_worksheet* worksheet = workbook_add_worksheet(workbook, "RTF Test");
  lxw_format* border_formats[4] = {nullptr, nullptr, nullptr, nullptr};
  for (int index = 0; index < 4; index += 1) {
    lxw_format* format = workbook_add_format(workbook);
    format_set_left(format, LXW_BORDER_THIN);
    format_set_right(format, LXW_BORDER_THIN);
    if ((index & 1) != 0) {
      format_set_top(format, LXW_BORDER_THIN);
    }
    if ((index & 2) != 0) {
      format_set_bottom(format, LXW_BORDER_THIN);
    }
    format_set_text_wrap(format);
    format_set_align(format, LXW_ALIGN_VERTICAL_CENTER);
    border_formats[index] = format;
  }

  const int rows = static_cast<int>(table.size());
  const int columns = ColumnCount(table);
  const int total_html_width = std::accumulate(
      table_data.column_widths.begin(), table_data.column_widths.end(), 0);
  const double row_height = std::clamp(
      (height_mm * 72.0 / 25.4) / std::max(1, rows), 6.0, 409.0);
  for (int row = 0; row < rows; row += 1) {
    worksheet_set_row(worksheet, static_cast<lxw_row_t>(row), row_height,
                      nullptr);
  }
  for (int column = 0; column < columns; column += 1) {
    double column_width = (width_mm / std::max(1, columns)) / 1.9;
    if (total_html_width > 0 &&
        column < static_cast<int>(table_data.column_widths.size())) {
      column_width =
          (width_mm * table_data.column_widths[column] / total_html_width) /
          1.9;
    }
    column_width = std::clamp(column_width, 0.75, 80.0);
    const auto lxw_column = static_cast<lxw_col_t>(column);
    worksheet_set_column(worksheet, lxw_column, lxw_column, column_width,
                         nullptr);
  }

  std::vector<std::vector<bool>> occupied(
      rows + 64, std::vector<bool>(columns + 64, false));
  for (int row_index = 0; row_index < rows; row_index += 1) {
    const bool top_border = row_index == 0;
    const bool bottom_border = IsSectionBottomRow(table, row_index);
    lxw_format* format =
        border_formats[(top_border ? 1 : 0) | (bottom_border ? 2 : 0)];
    int column_index = 0;
    for (const auto& cell : table[row_index]) {
      while (row_index < static_cast<int>(occupied.size()) &&
             column_index < static_cast<int>(occupied[row_index].size()) &&
             occupied[row_index][column_index]) {
        column_index += 1;
      }
      const int row_span = std::max(1, cell.row_span);
      const int column_span = std::max(1, cell.column_span);
      const int last_row = row_index + row_span - 1;
      const int last_column = column_index + column_span - 1;
      if (row_span > 1 || column_span > 1) {
        worksheet_merge_range(worksheet, static_cast<lxw_row_t>(row_index),
                              static_cast<lxw_col_t>(column_index),
                              static_cast<lxw_row_t>(last_row),
                              static_cast<lxw_col_t>(last_column),
                              cell.text.c_str(), format);
      } else {
        worksheet_write_string(worksheet, static_cast<lxw_row_t>(row_index),
                               static_cast<lxw_col_t>(column_index),
                               cell.text.c_str(), format);
      }
      for (int row = row_index;
           row <= last_row && row < static_cast<int>(occupied.size());
           row += 1) {
        for (int column = column_index;
             column <= last_column &&
             column < static_cast<int>(occupied[row].size());
             column += 1) {
          occupied[row][column] = true;
        }
      }
      column_index = last_column + 1;
    }
  }

  const lxw_error close_error = workbook_close(workbook);
  if (close_error != LXW_NO_ERROR) {
    if (error_message != nullptr) {
      *error_message = "libxlsxwriter failed to close workbook: " +
                       std::to_string(close_error);
    }
    return false;
  }
  return true;
}

bool ConvertRtfToNormalizedHtml(const std::string& rtf,
                                const std::filesystem::path& debug_dir,
                                std::string* normalized_html,
                                HtmlTableData* table_data,
                                std::string* error_message) {
  const auto tick = std::chrono::steady_clock::now().time_since_epoch().count();
  const std::filesystem::path temp_dir = std::filesystem::temp_directory_path();
  const std::filesystem::path input_rtf =
      temp_dir / (L"label_manager_rtf_" + std::to_wstring(tick) + L".rtf");
  const std::filesystem::path output_html =
      temp_dir / (L"label_manager_rtf_" + std::to_wstring(tick) + L".html");
  if (!WriteTextFile(input_rtf, rtf, error_message)) {
    return false;
  }
  const auto cleanup = [&]() {
    std::error_code error_code;
    std::filesystem::remove(input_rtf, error_code);
    std::filesystem::remove(output_html, error_code);
  };
  if (!RunRtf2Html(input_rtf, output_html, error_message)) {
    cleanup();
    return false;
  }
  std::string html;
  if (!ReadTextFile(output_html, &html, error_message)) {
    cleanup();
    return false;
  }
  if (!debug_dir.empty()) {
    CopyIfPossible(input_rtf, debug_dir / L"label_sheet_rtf_native_input.rtf");
    WriteTextFile(debug_dir / L"label_sheet_rtf_native_raw_output.html", html,
                  nullptr);
  }
  const HtmlTableData parsed_table_data = ParseHtmlTable(html);
  const std::string normalized = BuildNormalizedHtml(parsed_table_data);
  if (table_data != nullptr) {
    *table_data = parsed_table_data;
  }
  if (!debug_dir.empty()) {
    WriteTextFile(debug_dir / L"label_sheet_rtf_native_output.html", normalized,
                  nullptr);
  }
  *normalized_html = normalized;
  cleanup();
  return true;
}

}  // namespace

bool ConvertRtfHtmlWithNativeLibraries(const std::string& rtf,
                                       const std::wstring& debug_dir_path,
                                       std::string* normalized_html,
                                       std::string* error_message) {
  return ConvertRtfToNormalizedHtml(rtf, std::filesystem::path(debug_dir_path),
                                    normalized_html, nullptr, error_message);
}

bool WriteRtfOpenXmlWithNativeLibraries(const std::string& rtf,
                                        const std::wstring& output_path,
                                        double width_mm, double height_mm,
                                        std::string* error_message) {
  const std::filesystem::path debug_dir =
      std::filesystem::path(output_path).parent_path();
  std::string normalized_html;
  HtmlTableData table_data;
  if (!ConvertRtfToNormalizedHtml(rtf, debug_dir, &normalized_html,
                                  &table_data, error_message)) {
    return false;
  }
  return WriteXlsx(table_data, output_path, width_mm, height_mm,
                   error_message);
}
