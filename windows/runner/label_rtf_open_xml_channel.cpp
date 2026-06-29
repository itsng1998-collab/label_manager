#include "label_rtf_open_xml_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cstring>
#include <filesystem>
#include <memory>
#include <richedit.h>
#include <sstream>
#include <string>
#include <vector>
#include <windows.h>

#if defined(LABEL_MANAGER_HAS_NATIVE_RTF_XLSX)
bool WriteRtfOpenXmlWithNativeLibraries(const std::string& rtf,
                                        const std::wstring& output_path,
                                        double width_mm, double height_mm,
                                        std::string* error_message);
bool ConvertRtfHtmlWithNativeLibraries(const std::string& rtf,
                                       const std::wstring& debug_dir_path,
                                       std::string* normalized_html,
                                       std::string* error_message);
#endif

namespace {

constexpr char kChannelName[] = "label_manager/rtf_open_xml";
constexpr char kWriteMethod[] = "writeRtfOpenXml";
constexpr char kConvertHtmlMethod[] = "convertRtfHtml";
constexpr char kCaptureRtfImageMethod[] = "captureRtfImage";
constexpr char kResetRtf[] =
    "{\\rtf1\\ansi\\ansicpg949\\deff0\\nouicompat\\deflang1033"
    "\\deflangfe1042{\\fonttbl{\\f0\\fnil\\fcharset129 "
    "\\'b1\\'bc\\'b8\\'b2;}} {\\*\\generator Riched20 10.0.22621}"
    "\\viewkind4\\uc1 \\pard\\pard\\pard\\f0\\fs24\\par }";

using EncodableMap = flutter::EncodableMap;
using EncodableValue = flutter::EncodableValue;

const std::string* StringArg(const EncodableMap& args, const char* key) {
  const auto iter = args.find(EncodableValue(key));
  if (iter == args.end()) {
    return nullptr;
  }
  return std::get_if<std::string>(&iter->second);
}

double NumberArg(const EncodableMap& args, const char* key,
                 double fallback) {
  const auto iter = args.find(EncodableValue(key));
  if (iter == args.end()) {
    return fallback;
  }
  if (const auto value = std::get_if<double>(&iter->second)) {
    return *value;
  }
  if (const auto value = std::get_if<int>(&iter->second)) {
    return static_cast<double>(*value);
  }
  if (const auto value = std::get_if<int64_t>(&iter->second)) {
    return static_cast<double>(*value);
  }
  return fallback;
}

bool BoolArg(const EncodableMap& args, const char* key, bool fallback) {
  const auto iter = args.find(EncodableValue(key));
  if (iter == args.end()) {
    return fallback;
  }
  if (const auto value = std::get_if<bool>(&iter->second)) {
    return *value;
  }
  return fallback;
}

int IntArg(const EncodableMap& args, const char* key, int fallback) {
  const auto iter = args.find(EncodableValue(key));
  if (iter == args.end()) {
    return fallback;
  }
  if (const auto value = std::get_if<int>(&iter->second)) {
    return *value;
  }
  if (const auto value = std::get_if<int64_t>(&iter->second)) {
    return static_cast<int>(*value);
  }
  if (const auto value = std::get_if<double>(&iter->second)) {
    return static_cast<int>(*value);
  }
  return fallback;
}

struct RtfStreamState {
  const char* data = nullptr;
  size_t length = 0;
  size_t offset = 0;
};

DWORD CALLBACK RtfStreamInCallback(DWORD_PTR cookie, LPBYTE buffer,
                                   LONG buffer_size,
                                   LONG* bytes_written) noexcept {
  auto* state = reinterpret_cast<RtfStreamState*>(cookie);
  if (state == nullptr || bytes_written == nullptr || buffer_size <= 0) {
    return 1;
  }
  const size_t remaining = state->length - state->offset;
  const size_t count = remaining < static_cast<size_t>(buffer_size)
                           ? remaining
                           : static_cast<size_t>(buffer_size);
  if (count > 0) {
    memcpy(buffer, state->data + state->offset, count);
    state->offset += count;
  }
  *bytes_written = static_cast<LONG>(count);
  return 0;
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

EncodableValue Result(bool ok, const std::string& path,
                      const std::string& reason) {
  EncodableMap result;
  result[EncodableValue("ok")] = EncodableValue(ok);
  result[EncodableValue("path")] = EncodableValue(path);
  if (!reason.empty()) {
    result[EncodableValue("reason")] = EncodableValue(reason);
  }
  return EncodableValue(result);
}

EncodableValue HtmlResult(bool ok, const std::string& html,
                          const std::string& reason) {
  EncodableMap result;
  result[EncodableValue("ok")] = EncodableValue(ok);
  result[EncodableValue("html")] = EncodableValue(html);
  if (!reason.empty()) {
    result[EncodableValue("reason")] = EncodableValue(reason);
  }
  return EncodableValue(result);
}

EncodableValue ImageResult(bool ok, int width, int height,
                           std::vector<uint8_t> rgba,
                           const std::string& reason,
                           const std::string& renderer = "",
                           const std::string& diagnostics = "") {
  EncodableMap result;
  result[EncodableValue("ok")] = EncodableValue(ok);
  result[EncodableValue("width")] = EncodableValue(width);
  result[EncodableValue("height")] = EncodableValue(height);
  result[EncodableValue("rgba")] = EncodableValue(std::move(rgba));
  if (!renderer.empty()) {
    result[EncodableValue("renderer")] = EncodableValue(renderer);
  }
  if (!diagnostics.empty()) {
    result[EncodableValue("diagnostics")] = EncodableValue(diagnostics);
  }
  if (!reason.empty()) {
    result[EncodableValue("reason")] = EncodableValue(reason);
  }
  return EncodableValue(result);
}

bool StreamRtfIntoRichEdit(HWND rich_edit, const std::string& rtf) {
  RtfStreamState state{rtf.data(), rtf.size(), 0};
  EDITSTREAM stream{};
  stream.dwCookie = reinterpret_cast<DWORD_PTR>(&state);
  stream.pfnCallback = RtfStreamInCallback;
  const LRESULT result = SendMessage(rich_edit, EM_STREAMIN, SF_RTF,
                                     reinterpret_cast<LPARAM>(&stream));
  return result > 0 && stream.dwError == 0;
}

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }
  const int size = WideCharToMultiByte(CP_UTF8, 0, value.data(),
                                      static_cast<int>(value.size()), nullptr,
                                      0, nullptr, nullptr);
  if (size <= 0) {
    return "<wide-conversion-failed>";
  }
  std::string utf8(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.data(), static_cast<int>(value.size()),
                      utf8.data(), size, nullptr, nullptr);
  return utf8;
}

void SetRichEditDefaultFormat(HWND rich_edit) {
  CHARFORMAT2W char_format{};
  char_format.cbSize = sizeof(char_format);
  char_format.dwMask = CFM_FACE | CFM_SIZE;
  wcscpy_s(char_format.szFaceName, L"Gulim");
  char_format.yHeight = 240;
  SendMessage(rich_edit, EM_SETCHARFORMAT, SCF_DEFAULT,
              reinterpret_cast<LPARAM>(&char_format));
}

void SetRichEditDefaultZoom(HWND rich_edit) {
  HDC screen_dc = GetDC(nullptr);
  const int dpi_x = screen_dc == nullptr ? 96 : GetDeviceCaps(screen_dc, LOGPIXELSX);
  if (screen_dc != nullptr) {
    ReleaseDC(nullptr, screen_dc);
  }
  DWORD numerator = 10;
  DWORD denominator = 10;
  if (dpi_x == 96) {
    numerator = 15;
  } else if (dpi_x == 120) {
    numerator = 12;
  }
  SendMessage(rich_edit, EM_SETZOOM, numerator, denominator);
}

void PumpPendingWindowMessages() {
  MSG message{};
  int processed = 0;
  while (processed < 64 && PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE)) {
    TranslateMessage(&message);
    DispatchMessageW(&message);
    ++processed;
  }
}

LONG MillimetersToTwips(double millimeters) {
  return static_cast<LONG>((millimeters * 1440.0 / 25.4) + 0.5);
}

int MillimetersToPixels(double millimeters, int dpi) {
  return static_cast<int>((millimeters * (dpi <= 0 ? 96 : dpi) / 25.4) + 0.5);
}

struct BgraInkStats {
  size_t count = 0;
  size_t light_count = 0;
  int min_x = 0;
  int min_y = 0;
  int max_x = -1;
  int max_y = -1;
  size_t left_edge = 0;
  size_t top_edge = 0;
  size_t right_edge = 0;
  size_t bottom_edge = 0;
};

BgraInkStats AnalyzeBgraInk(const uint8_t* bgra, int width, int height) {
  BgraInkStats stats;
  if (bgra == nullptr || width <= 0 || height <= 0) {
    return stats;
  }
  stats.min_x = width;
  stats.min_y = height;
  for (int y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      const size_t index = static_cast<size_t>(y) * width + x;
      const uint8_t blue = bgra[index * 4 + 0];
      const uint8_t green = bgra[index * 4 + 1];
      const uint8_t red = bgra[index * 4 + 2];
      if (red >= 245 && green >= 245 && blue >= 245) {
        continue;
      }
      ++stats.count;
      const uint8_t darkest = std::min({red, green, blue});
      if (darkest >= 160) {
        ++stats.light_count;
      }
      stats.min_x = std::min(stats.min_x, x);
      stats.min_y = std::min(stats.min_y, y);
      stats.max_x = std::max(stats.max_x, x);
      stats.max_y = std::max(stats.max_y, y);
      if (x == 0) ++stats.left_edge;
      if (y == 0) ++stats.top_edge;
      if (x == width - 1) ++stats.right_edge;
      if (y == height - 1) ++stats.bottom_edge;
    }
  }
  if (stats.count == 0) {
    stats.min_x = 0;
    stats.min_y = 0;
  }
  return stats;
}

bool BgraStatsHasVisibleInk(const BgraInkStats& stats, size_t pixel_count) {
  const size_t minimum_ink_pixels = std::max<size_t>(24, pixel_count / 2000);
  return stats.count >= minimum_ink_pixels;
}

bool BgraStatsHasMoreTableDetail(const BgraInkStats& candidate,
                                 const BgraInkStats& baseline) {
  if (candidate.count == 0) {
    return false;
  }
  const size_t ink_delta =
      std::max<size_t>(200, std::max<size_t>(1, baseline.count) / 50);
  if (candidate.count > baseline.count + ink_delta) {
    return true;
  }
  const size_t light_delta =
      std::max<size_t>(80, std::max<size_t>(1, baseline.light_count) / 5);
  return candidate.light_count > baseline.light_count + light_delta;
}

void AppendBgraStats(std::ostringstream* diagnostics, const char* label,
                     const BgraInkStats& stats) {
  if (diagnostics == nullptr) {
    return;
  }
  *diagnostics << " attempt=" << label << " ink=" << stats.count
               << " light=" << stats.light_count;
  if (stats.count > 0) {
    *diagnostics << " bounds=" << stats.min_x << "," << stats.min_y << ","
                 << stats.max_x << "," << stats.max_y << " edge="
                 << stats.left_edge << "," << stats.top_edge << ","
                 << stats.right_edge << "," << stats.bottom_edge;
  }
}

void PrepareRichEditPhysicalLayout(HWND rich_edit, double width_mm,
                                   double height_mm, int capture_width,
                                   int capture_height, double render_scale) {
  render_scale = std::max(1.0, std::min(render_scale, 4.0));
  const int logical_width = std::max(
      1, static_cast<int>((capture_width / render_scale) + 0.5));
  const int logical_height = std::max(
      1, static_cast<int>((capture_height / render_scale) + 0.5));
  const int rect_width = std::min(capture_width, logical_width);
  const int rect_height = std::min(capture_height, logical_height);
  RECT formatting_rect{0, 0, rect_width, rect_height};
  SendMessage(rich_edit, EM_SETRECT, 0,
              reinterpret_cast<LPARAM>(&formatting_rect));
  SendMessage(rich_edit, EM_SETTARGETDEVICE, 0,
              MillimetersToTwips(width_mm));

  HDC measure_dc = GetDC(rich_edit);
  if (measure_dc != nullptr) {
    FORMATRANGE format_range{};
    format_range.hdc = measure_dc;
    format_range.hdcTarget = measure_dc;
    format_range.rc.left = 0;
    format_range.rc.top = 0;
    format_range.rc.right = MillimetersToTwips(width_mm);
    format_range.rc.bottom = MillimetersToTwips(height_mm);
    format_range.rcPage = format_range.rc;
    format_range.chrg.cpMin = 0;
    format_range.chrg.cpMax = -1;
    SendMessage(rich_edit, EM_FORMATRANGE, TRUE,
                reinterpret_cast<LPARAM>(&format_range));
    SendMessage(rich_edit, EM_FORMATRANGE, FALSE, 0);
    ReleaseDC(rich_edit, measure_dc);
  }
}

size_t CountBgraInkPixels(const uint8_t* bgra, size_t pixel_count) {
  if (bgra == nullptr) {
    return 0;
  }
  size_t ink_pixels = 0;
  for (size_t index = 0; index < pixel_count; ++index) {
    const uint8_t blue = bgra[index * 4 + 0];
    const uint8_t green = bgra[index * 4 + 1];
    const uint8_t red = bgra[index * 4 + 2];
    if (red < 245 || green < 245 || blue < 245) {
      ++ink_pixels;
    }
  }
  return ink_pixels;
}

LRESULT RenderRichEditWithFormatRange(HWND rich_edit, HDC target_dc, int width,
                                      int height) {
  const int dpi_x = GetDeviceCaps(target_dc, LOGPIXELSX);
  const int dpi_y = GetDeviceCaps(target_dc, LOGPIXELSY);
  FORMATRANGE format_range{};
  format_range.hdc = target_dc;
  format_range.hdcTarget = target_dc;
  format_range.rc.left = 0;
  format_range.rc.top = 0;
  format_range.rc.right = MulDiv(width, 1440, dpi_x <= 0 ? 96 : dpi_x);
  format_range.rc.bottom = MulDiv(height, 1440, dpi_y <= 0 ? 96 : dpi_y);
  format_range.rcPage = format_range.rc;
  format_range.chrg.cpMin = 0;
  format_range.chrg.cpMax = -1;
  const LRESULT formatted_until = SendMessage(
      rich_edit, EM_FORMATRANGE, TRUE, reinterpret_cast<LPARAM>(&format_range));
  SendMessage(rich_edit, EM_FORMATRANGE, FALSE, 0);
  return formatted_until;
}

void RenderRichEditWithControlPaint(HWND rich_edit, HDC target_dc) {
  SendMessage(rich_edit, WM_PRINT, reinterpret_cast<WPARAM>(target_dc),
              PRF_CLIENT | PRF_ERASEBKGND | PRF_CHILDREN | PRF_CHECKVISIBLE);
}

std::vector<uint8_t> CaptureRichEditRgba(HWND rich_edit, int width,
                                         int height, double render_scale,
                                         std::string* renderer,
                                         std::ostringstream* diagnostics) {
  BITMAPINFO bitmap_info{};
  bitmap_info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bitmap_info.bmiHeader.biWidth = width;
  bitmap_info.bmiHeader.biHeight = -height;
  bitmap_info.bmiHeader.biPlanes = 1;
  bitmap_info.bmiHeader.biBitCount = 32;
  bitmap_info.bmiHeader.biCompression = BI_RGB;

  void* bits = nullptr;
  HDC screen_dc = GetDC(nullptr);
  HDC memory_dc = CreateCompatibleDC(screen_dc);
  HBITMAP bitmap = CreateDIBSection(screen_dc, &bitmap_info, DIB_RGB_COLORS,
                                    &bits, nullptr, 0);
  ReleaseDC(nullptr, screen_dc);

  if (memory_dc == nullptr || bitmap == nullptr || bits == nullptr) {
    if (bitmap != nullptr) {
      DeleteObject(bitmap);
    }
    if (memory_dc != nullptr) {
      DeleteDC(memory_dc);
    }
    return {};
  }

  HGDIOBJ previous = SelectObject(memory_dc, bitmap);
  RECT rect{0, 0, width, height};
  HBRUSH white = reinterpret_cast<HBRUSH>(GetStockObject(WHITE_BRUSH));
  FillRect(memory_dc, &rect, white);
  SetTextColor(memory_dc, RGB(0, 0, 0));
  SetBkColor(memory_dc, RGB(255, 255, 255));
  SetBkMode(memory_dc, OPAQUE);
  render_scale = std::max(1.0, std::min(render_scale, 4.0));
  const int previous_graphics_mode = SetGraphicsMode(memory_dc, GM_ADVANCED);
  XFORM previous_transform{};
  const BOOL has_previous_transform = GetWorldTransform(memory_dc, &previous_transform);
  XFORM render_transform{};
  render_transform.eM11 = static_cast<FLOAT>(render_scale);
  render_transform.eM12 = 0.0f;
  render_transform.eM21 = 0.0f;
  render_transform.eM22 = static_cast<FLOAT>(render_scale);
  render_transform.eDx = 0.0f;
  render_transform.eDy = 0.0f;
  SetWorldTransform(memory_dc, &render_transform);
  const int logical_width = std::max(
      1, static_cast<int>((width / render_scale) + 0.5));
  const int logical_height = std::max(
      1, static_cast<int>((height / render_scale) + 0.5));
  if (diagnostics != nullptr) {
    *diagnostics << " captureDpi=" << GetDeviceCaps(memory_dc, LOGPIXELSX)
                 << "x" << GetDeviceCaps(memory_dc, LOGPIXELSY)
                 << " graphicsMode=" << previous_graphics_mode
                 << " hasTransform=" << (has_previous_transform ? 1 : 0)
                 << " logical=" << logical_width << "x" << logical_height;
  }
  const LRESULT format_range_until = RenderRichEditWithFormatRange(
      rich_edit, memory_dc, logical_width, logical_height);
  if (renderer != nullptr) {
    *renderer = render_scale > 1.0 ? "EM_FORMATRANGE scaled-HDC"
                                   : "EM_FORMATRANGE";
  }
  GdiFlush();

  const size_t pixel_count = static_cast<size_t>(width) * height;
  const size_t bgra_byte_count = pixel_count * 4;
  const auto* bgra = static_cast<const uint8_t*>(bits);
  auto stats = AnalyzeBgraInk(bgra, width, height);
  if (diagnostics != nullptr) {
    *diagnostics << " formatUntil=" << format_range_until;
    AppendBgraStats(diagnostics, "EM_FORMATRANGE", stats);
  }
  if (BgraStatsHasVisibleInk(stats, pixel_count)) {
    std::vector<uint8_t> format_bgra(bgra_byte_count);
    std::memcpy(format_bgra.data(), bgra, bgra_byte_count);
    FillRect(memory_dc, &rect, white);
    RenderRichEditWithControlPaint(rich_edit, memory_dc);
    GdiFlush();
    const auto control_stats = AnalyzeBgraInk(bgra, width, height);
    if (diagnostics != nullptr) {
      AppendBgraStats(diagnostics, "WM_PRINT", control_stats);
    }
    if (BgraStatsHasVisibleInk(control_stats, pixel_count) &&
        BgraStatsHasMoreTableDetail(control_stats, stats)) {
      stats = control_stats;
      if (renderer != nullptr) {
        *renderer = render_scale > 1.0 ? "WM_PRINT scaled-HDC" : "WM_PRINT";
      }
      if (diagnostics != nullptr) {
        *diagnostics << " selected=WM_PRINT tableDetail=1";
      }
    } else {
      std::memcpy(bits, format_bgra.data(), bgra_byte_count);
      if (diagnostics != nullptr) {
        *diagnostics << " selected=EM_FORMATRANGE tableDetail=0";
      }
    }
  }
  if (!BgraStatsHasVisibleInk(stats, pixel_count)) {
    FillRect(memory_dc, &rect, white);
    RenderRichEditWithControlPaint(rich_edit, memory_dc);
    if (renderer != nullptr) {
      *renderer = render_scale > 1.0 ? "WM_PRINT scaled-HDC" : "WM_PRINT";
    }
    GdiFlush();
    stats = AnalyzeBgraInk(bgra, width, height);
    if (diagnostics != nullptr) {
      AppendBgraStats(diagnostics, "WM_PRINT", stats);
    }
  }
  if (!BgraStatsHasVisibleInk(stats, pixel_count)) {
    FillRect(memory_dc, &rect, white);
    SendMessage(rich_edit, WM_PRINTCLIENT, reinterpret_cast<WPARAM>(memory_dc),
                PRF_CLIENT | PRF_ERASEBKGND | PRF_CHILDREN);
    if (renderer != nullptr) {
      *renderer = "WM_PRINTCLIENT";
    }
    GdiFlush();
    stats = AnalyzeBgraInk(bgra, width, height);
    if (diagnostics != nullptr) {
      AppendBgraStats(diagnostics, "WM_PRINTCLIENT", stats);
    }
  }

  std::vector<uint8_t> rgba(pixel_count * 4);
  size_t chroma_pixels = 0;
  size_t final_ink_pixels = 0;
  for (size_t index = 0; index < pixel_count; ++index) {
    const uint8_t red = bgra[index * 4 + 2];
    const uint8_t green = bgra[index * 4 + 1];
    const uint8_t blue = bgra[index * 4 + 0];
    const uint8_t darkest = std::min({red, green, blue});
    const uint8_t brightest = std::max({red, green, blue});
    if (darkest < 245) {
      ++final_ink_pixels;
    }
    if (brightest - darkest > 12 && darkest < 245) {
      ++chroma_pixels;
    }
    const uint8_t gray = brightest - darkest > 12 && darkest < 245
                             ? darkest
                             : static_cast<uint8_t>(
                                   (red * 299 + green * 587 + blue * 114) /
                                   1000);
    rgba[index * 4 + 0] = gray;
    rgba[index * 4 + 1] = gray;
    rgba[index * 4 + 2] = gray;
    rgba[index * 4 + 3] = 0xFF;
  }
  if (diagnostics != nullptr) {
    *diagnostics << " finalInk=" << final_ink_pixels
                 << " chroma=" << chroma_pixels;
  }

  if (has_previous_transform) {
    SetWorldTransform(memory_dc, &previous_transform);
  }
  if (previous_graphics_mode != 0) {
    SetGraphicsMode(memory_dc, previous_graphics_mode);
  }

  SelectObject(memory_dc, previous);
  DeleteObject(bitmap);
  DeleteDC(memory_dc);
  return rgba;
}

EncodableValue CaptureRtfImageResult(const std::string& rtf, int width,
                                     int height, double width_mm,
                                     double height_mm, double render_scale) {
  width = std::max(80, std::min(width, 2400));
  height = std::max(60, std::min(height, 2400));
  width_mm = std::max(1.0, std::min(width_mm, 1000.0));
  height_mm = std::max(1.0, std::min(height_mm, 1000.0));
  render_scale = std::max(1.0, std::min(render_scale, 4.0));

  HWND host = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE |
                                  WS_EX_LAYERED,
                              L"STATIC", L"", WS_POPUP, 0, 0, width, height,
                              nullptr, nullptr, GetModuleHandle(nullptr),
                              nullptr);
  if (host == nullptr) {
    return ImageResult(false, width, height, {},
                       "failed to create hidden RTF host window");
  }

  struct RichEditCandidate {
    const wchar_t* dll_name;
    const wchar_t* class_name;
  };
  const RichEditCandidate candidates[] = {
      {L"Msftedit.dll", L"RICHEDIT50W"},
      {L"Riched20.dll", RICHEDIT_CLASSW},
      {L"Msftedit.dll", MSFTEDIT_CLASS},
  };
  HMODULE rich_edit_module = nullptr;
  HWND rich_edit = nullptr;
  const RichEditCandidate* selected_candidate = nullptr;
  for (const auto& candidate : candidates) {
    rich_edit_module = LoadLibraryW(candidate.dll_name);
    if (rich_edit_module == nullptr) {
      continue;
    }
    rich_edit = CreateWindowExW(
        0, candidate.class_name, L"",
        WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | ES_LEFT |
            ES_MULTILINE,
        0, 0, width, height, host, nullptr, GetModuleHandle(nullptr), nullptr);
    if (rich_edit != nullptr) {
      selected_candidate = &candidate;
      break;
    }
    FreeLibrary(rich_edit_module);
    rich_edit_module = nullptr;
  }
  if (rich_edit == nullptr) {
    DestroyWindow(host);
    return ImageResult(false, width, height, {},
                       "failed to create hidden RichEdit control");
  }

  std::ostringstream diagnostics;
  diagnostics << "request px=" << width << "x" << height << " mm="
              << width_mm << "x" << height_mm << " scale=" << render_scale
              << " rtfLen=" << rtf.size();
  if (selected_candidate != nullptr) {
    diagnostics << " dll=" << WideToUtf8(selected_candidate->dll_name)
                << " class=" << WideToUtf8(selected_candidate->class_name);
  }
  diagnostics << " style=0x" << std::hex << GetWindowLongPtr(rich_edit, GWL_STYLE)
              << std::dec;

  SetLayeredWindowAttributes(host, 0, 1, LWA_ALPHA);
  ShowWindow(host, SW_SHOWNOACTIVATE);
  ShowWindow(rich_edit, SW_SHOWNA);
  PumpPendingWindowMessages();
  SetWindowPos(rich_edit, nullptr, 0, 0, width, height,
               SWP_NOZORDER | SWP_NOACTIVATE | SWP_SHOWWINDOW);
  RECT host_rect{};
  RECT rich_rect{};
  GetWindowRect(host, &host_rect);
  GetWindowRect(rich_edit, &rich_rect);
  HDC screen_dc = GetDC(nullptr);
  const int screen_dpi_x = screen_dc == nullptr ? 0 : GetDeviceCaps(screen_dc, LOGPIXELSX);
  const int screen_dpi_y = screen_dc == nullptr ? 0 : GetDeviceCaps(screen_dc, LOGPIXELSY);
  if (screen_dc != nullptr) {
    ReleaseDC(nullptr, screen_dc);
  }
  diagnostics << " screenDpi=" << screen_dpi_x << "x" << screen_dpi_y
              << " hostRect=" << host_rect.left << "," << host_rect.top
              << "," << host_rect.right << "," << host_rect.bottom
              << " richRect=" << rich_rect.left << "," << rich_rect.top
              << "," << rich_rect.right << "," << rich_rect.bottom;
  SendMessage(rich_edit, EM_SETBKGNDCOLOR, 0, RGB(255, 255, 255));
  SetRichEditDefaultFormat(rich_edit);
  SetRichEditDefaultZoom(rich_edit);
  PrepareRichEditPhysicalLayout(rich_edit, width_mm, height_mm, width, height,
                                render_scale);
  const bool reset_ok = StreamRtfIntoRichEdit(rich_edit, kResetRtf);
  const bool stream_ok = StreamRtfIntoRichEdit(rich_edit, rtf);
  diagnostics << " resetOk=" << (reset_ok ? 1 : 0)
              << " streamOk=" << (stream_ok ? 1 : 0)
              << " textLength=" << GetWindowTextLengthW(rich_edit)
              << " lines=" << SendMessage(rich_edit, EM_GETLINECOUNT, 0, 0);
  RECT current_rect{};
  SendMessage(rich_edit, EM_GETRECT, 0, reinterpret_cast<LPARAM>(&current_rect));
  diagnostics << " rect=" << current_rect.left << "," << current_rect.top
              << "," << current_rect.right << "," << current_rect.bottom;
  if (!stream_ok) {
    DestroyWindow(rich_edit);
    DestroyWindow(host);
    FreeLibrary(rich_edit_module);
    return ImageResult(false, width, height, {},
                       "failed to stream RTF into RichEdit", "",
                       diagnostics.str());
  }
  PrepareRichEditPhysicalLayout(rich_edit, width_mm, height_mm, width, height,
                                render_scale);
  PumpPendingWindowMessages();

  InvalidateRect(rich_edit, nullptr, TRUE);
  RedrawWindow(host, nullptr, nullptr,
               RDW_INVALIDATE | RDW_ERASE | RDW_ALLCHILDREN | RDW_UPDATENOW);
  RedrawWindow(rich_edit, nullptr, nullptr,
               RDW_INVALIDATE | RDW_ERASE | RDW_UPDATENOW);
  PumpPendingWindowMessages();
  std::string renderer;
  auto rgba = CaptureRichEditRgba(rich_edit, width, height, render_scale, &renderer,
                                  &diagnostics);

  DestroyWindow(rich_edit);
  DestroyWindow(host);
  FreeLibrary(rich_edit_module);

  if (rgba.empty()) {
    return ImageResult(false, width, height, {}, "failed to capture RichEdit",
                       renderer, diagnostics.str());
  }
  return ImageResult(true, width, height, std::move(rgba), "", renderer,
                     diagnostics.str());
}

void HandleWriteRtfOpenXml(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto* args = std::get_if<EncodableMap>(call.arguments());
  if (args == nullptr) {
    result->Error("bad-arguments", "Expected argument map.");
    return;
  }
  const std::string* rtf = StringArg(*args, "rtf");
  const std::string* path = StringArg(*args, "path");
  if (rtf == nullptr || path == nullptr || rtf->empty() || path->empty()) {
    result->Error("bad-arguments", "Expected non-empty rtf and path.");
    return;
  }

  const double width_mm = NumberArg(*args, "widthMm", 100.0);
  const double height_mm = NumberArg(*args, "heightMm", 100.0);
  std::filesystem::path output_path = Utf8ToWide(*path);

#if defined(LABEL_MANAGER_HAS_NATIVE_RTF_XLSX)
  std::error_code error_code;
  std::filesystem::create_directories(output_path.parent_path(), error_code);
  std::string error_message;
  if (!WriteRtfOpenXmlWithNativeLibraries(*rtf, output_path.wstring(), width_mm,
                                          height_mm, &error_message)) {
    result->Success(Result(false, *path, error_message));
    return;
  }
  result->Success(Result(true, *path, ""));
#else
  (void)width_mm;
  (void)height_mm;
  result->Success(Result(
      false, *path,
      "native rtf2html/libxlsxwriter adapter is not linked in this build"));
#endif
}

void HandleConvertRtfHtml(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto* args = std::get_if<EncodableMap>(call.arguments());
  if (args == nullptr) {
    result->Error("bad-arguments", "Expected argument map.");
    return;
  }
  const std::string* rtf = StringArg(*args, "rtf");
  const std::string* debug_dir = StringArg(*args, "debugDir");
  if (rtf == nullptr || rtf->empty()) {
    result->Error("bad-arguments", "Expected non-empty rtf.");
    return;
  }

#if defined(LABEL_MANAGER_HAS_NATIVE_RTF_XLSX)
  std::string error_message;
  std::string html;
  const std::wstring debug_dir_path = debug_dir == nullptr
                                         ? std::wstring()
                                         : Utf8ToWide(*debug_dir);
  if (!ConvertRtfHtmlWithNativeLibraries(*rtf, debug_dir_path, &html,
                                         &error_message)) {
    result->Success(HtmlResult(false, "", error_message));
    return;
  }
  result->Success(HtmlResult(true, html, ""));
#else
  (void)debug_dir;
  result->Success(HtmlResult(
      false, "",
      "native rtf2html/libxlsxwriter adapter is not linked in this build"));
#endif
}

void HandleCaptureRtfImage(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto* args = std::get_if<EncodableMap>(call.arguments());
  if (args == nullptr) {
    result->Error("bad-arguments", "Expected argument map.");
    return;
  }
  const std::string* rtf = StringArg(*args, "rtf");
  if (rtf == nullptr || rtf->empty()) {
    result->Error("bad-arguments", "Expected non-empty rtf.");
    return;
  }
  const int width = IntArg(*args, "width", 400);
  const int height = IntArg(*args, "height", 300);
  const double width_mm = NumberArg(*args, "widthMm", 100.0);
  const double height_mm = NumberArg(*args, "heightMm", 100.0);
  const double render_scale = NumberArg(*args, "renderScale", 1.0);
  result->Success(CaptureRtfImageResult(*rtf, width, height, width_mm,
                                        height_mm, render_scale));
}

}  // namespace

void RegisterLabelRtfOpenXmlChannel(flutter::FlutterEngine* engine) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const auto& call, auto result) {
        if (call.method_name() == kWriteMethod) {
          HandleWriteRtfOpenXml(call, std::move(result));
          return;
        }
        if (call.method_name() == kConvertHtmlMethod) {
          HandleConvertRtfHtml(call, std::move(result));
          return;
        }
        if (call.method_name() == kCaptureRtfImageMethod) {
          HandleCaptureRtfImage(call, std::move(result));
          return;
        }
        result->NotImplemented();
      });
}