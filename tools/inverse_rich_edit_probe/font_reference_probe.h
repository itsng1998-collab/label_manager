#ifndef INVERSE_RICH_EDIT_FONT_REFERENCE_PROBE_H_
#define INVERSE_RICH_EDIT_FONT_REFERENCE_PROBE_H_

#include <windows.h>
#include <richedit.h>
#include <algorithm>
#include <array>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include "../../windows/runner/inverse_text_bitmap.h"
#include "../../windows/runner/inverse_text_layout.h"
#include "driver_file_probe.h"

struct FontReferenceStream {
  std::string bytes;
  size_t offset = 0;
};

inline DWORD CALLBACK ReadFontReferenceRtf(
    DWORD_PTR cookie, LPBYTE buffer, LONG requested, LONG* copied) {
  auto& stream = *reinterpret_cast<FontReferenceStream*>(cookie);
  const size_t available = std::min(static_cast<size_t>(requested),
                                    stream.bytes.size() - stream.offset);
  std::memcpy(buffer, stream.bytes.data() + stream.offset, available);
  stream.offset += available;
  *copied = static_cast<LONG>(available);
  return 0;
}

inline int CompareInverseFontReference(const std::filesystem::path& directory) {
  std::filesystem::create_directories(directory);
  HDC printer = CreateDCW(L"WINSPOOL", L"Godex G500", nullptr, nullptr);
  HMODULE module = LoadLibraryW(L"Msftedit.dll");
  if (printer == nullptr || module == nullptr) {
    if (printer != nullptr) DeleteDC(printer);
    if (module != nullptr) FreeLibrary(module);
    return 4;
  }
  const std::wstring text = L"\uacc4\ub780,\uc6b0\uc720,\ub300\ub450,\ubc00 \ud568\uc720";
  const int dpi_x = GetDeviceCaps(printer, LOGPIXELSX);
  const int dpi_y = GetDeviceCaps(printer, LOGPIXELSY);
  const RECT clip{15, 20, 600, 70};
  bool success = true;
  for (const int points : {5, 6, 8}) {
    std::array<std::vector<uint8_t>, 4> images;
    std::array<RECT, 4> bounds{};
    for (int variant = 0; variant < 4; ++variant) {
      HWND host = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
          L"STATIC", L"", WS_POPUP, 0, 0, 620, 100, nullptr, nullptr,
          GetModuleHandleW(nullptr), nullptr);
      HWND edit = host == nullptr ? nullptr : CreateWindowExW(
          WS_EX_TRANSPARENT, L"RICHEDIT50W", L"",
          WS_CHILD | ES_MULTILINE, 0, 0, 585, 50, host, nullptr,
          GetModuleHandleW(nullptr), nullptr);
      if (edit == nullptr) {
        if (host != nullptr) DestroyWindow(host);
        success = false;
        break;
      }
      const int twips = variant == 2
          ? MulDiv(MulDiv(points, dpi_y, 96), 1440, dpi_y) : points * 20;
      if (variant == 0) {
        FontReferenceStream input;
        input.bytes = "{\\rtf1\\ansi\\ansicpg949\\deff0\\uc1"
            "{\\fonttbl{\\f0\\fnil\\fcharset129 Gulim;}}"
            "{\\colortbl;\\red255\\green255\\blue255;\\red0\\green0\\blue0;}"
            "\\pard\\ql\\f0\\fs" + std::to_string(points * 2) +
            "\\b\\cf1\\highlight2 ";
        for (const wchar_t unit : text) {
          input.bytes += "\\u" + std::to_string(
              unit > 32767 ? static_cast<int>(unit) - 65536 : unit) + "?";
        }
        input.bytes += "}";
        EDITSTREAM stream{};
        stream.dwCookie = reinterpret_cast<DWORD_PTR>(&input);
        stream.pfnCallback = ReadFontReferenceRtf;
        SendMessageW(edit, EM_STREAMIN, SF_RTF,
                     reinterpret_cast<LPARAM>(&stream));
        success = success && stream.dwError == 0;
      } else {
        SetWindowTextW(edit, text.c_str());
        SendMessageW(edit, EM_SETSEL, 0, -1);
        CHARFORMAT2W character{};
        character.cbSize = sizeof(character);
        character.dwMask = CFM_FACE | CFM_SIZE | CFM_COLOR | CFM_BACKCOLOR |
                           CFM_BOLD | CFM_ITALIC | CFM_UNDERLINE | CFM_STRIKEOUT;
        character.dwEffects = CFE_BOLD;
        character.yHeight = twips;
        character.crTextColor = RGB(255, 255, 255);
        character.crBackColor = RGB(0, 0, 0);
        wcscpy_s(character.szFaceName, L"\uad74\ub9bc");
        SendMessageW(edit, EM_SETCHARFORMAT, SCF_SELECTION,
                     reinterpret_cast<LPARAM>(&character));
      }
      SendMessageW(edit, EM_SETBKGNDCOLOR, FALSE, RGB(0, 0, 0));
      SendMessageW(edit, EM_SETMARGINS, EC_LEFTMARGIN | EC_RIGHTMARGIN, 0);
      RECT edit_rect{0, 0, 585, 50};
      SendMessageW(edit, EM_SETRECTNP, 0,
                   reinterpret_cast<LPARAM>(&edit_rect));
        std::wstring actual_text(GetWindowTextLengthW(edit) + 1, L'\0');
        const int text_length = GetWindowTextW(edit, actual_text.data(),
                          static_cast<int>(actual_text.size()));
        actual_text.resize(text_length);
        if (!actual_text.empty() && actual_text.back() == L'\r') actual_text.pop_back();
        SendMessageW(edit, EM_SETSEL, 0, -1);
        CHARFORMAT2W actual_format{};
        actual_format.cbSize = sizeof(actual_format);
        SendMessageW(edit, EM_GETCHARFORMAT, SCF_SELECTION,
               reinterpret_cast<LPARAM>(&actual_format));
          const std::wstring actual_face(actual_format.szFaceName);
          success = success && actual_text == text && actual_format.yHeight == twips &&
            (actual_face == L"\uad74\ub9bc" || actual_face == L"Gulim");
          std::cout << "fontContract points=" << points << " variant=" << variant
              << " textMatches=" << (actual_text == text)
              << " actualTwips=" << actual_format.yHeight
              << " face=" << static_cast<int>(actual_format.szFaceName[0])
              << "," << static_cast<int>(actual_format.szFaceName[1]) << "\n";
      if (variant == 3) {
        SendMessageW(edit, EM_SETTYPOGRAPHYOPTIONS, TO_ADVANCEDTYPOGRAPHY,
                     TO_ADVANCEDTYPOGRAPHY);
      }
      const auto layout = MeasureInverseTextLayout(edit, printer, clip, text, false);
      success = success && layout.all_characters_fit && !layout.fitted;
      const auto name = std::to_wstring(points) + L"pt_" +
                        std::to_wstring(variant);
      const auto emf_path = directory / (name + L".emf");
      const RECT frame{0, 0, MulDiv(620, 2540, dpi_x), MulDiv(100, 2540, dpi_y)};
      HDC recording = CreateEnhMetaFileW(printer, emf_path.c_str(), &frame, nullptr);
      if (recording == nullptr) {
        DestroyWindow(host);
        success = false;
        break;
      }
      SetMapMode(recording, MM_TEXT);
      FORMATRANGE range = layout.range;
      range.hdc = recording;
      const LRESULT until = SendMessageW(edit, EM_FORMATRANGE, TRUE,
                                         reinterpret_cast<LPARAM>(&range));
      SendMessageW(edit, EM_FORMATRANGE, FALSE, 0);
      HENHMETAFILE metafile = CloseEnhMetaFile(recording);
      auto& pixels = images[variant];
      pixels.assign(620 * 100 * 4, 0);
      const auto composite = CompositeInverseTextBitmap(
          printer, metafile, clip, 620, 100, pixels);
      if (metafile != nullptr) DeleteEnhMetaFile(metafile);
      DestroyWindow(host);
      success = success && composite.success && until >= static_cast<LRESULT>(text.size());
      BITMAPINFOHEADER info{};
      info.biSize = sizeof(info);
      info.biWidth = 620;
      info.biHeight = -100;
      info.biPlanes = 1;
      info.biBitCount = 32;
      BITMAPFILEHEADER header{};
      header.bfType = 0x4d42;
      header.bfOffBits = sizeof(header) + sizeof(info);
      header.bfSize = header.bfOffBits + static_cast<DWORD>(pixels.size());
      std::ofstream output(directory / (name + L".bmp"), std::ios::binary);
      output.write(reinterpret_cast<const char*>(&header), sizeof(header));
      output.write(reinterpret_cast<const char*>(&info), sizeof(info));
      output.write(reinterpret_cast<const char*>(pixels.data()), pixels.size());
      success = success && output.good() && composite.changed_pixels > 0;
      int left = 620, top = 100, right = 0, bottom = 0;
      for (int row = clip.top; row < clip.bottom; ++row) {
        for (int column = clip.left; column < clip.right; ++column) {
          if (pixels[(row * 620 + column) * 4] != 255) continue;
          left = std::min(left, column);
          top = std::min(top, row);
          right = std::max(right, column + 1);
          bottom = std::max(bottom, row + 1);
        }
      }
      std::cout << "fontReference points=" << points << " variant=" << variant
                << " twips=" << twips << " white=" << composite.changed_pixels
                << " bounds=" << left << "," << top << "," << right << "," << bottom << "\n";
      bounds[variant] = {left, top, right, bottom};
    }
    if (images[0].empty() || images[1].empty() || images[2].empty() ||
      images[3].empty()) {
      success = false;
      continue;
    }
    for (int variant = 1; variant < 4; ++variant) {
      size_t mismatches = 0;
      const auto reference = bounds[0];
      const auto candidate = bounds[variant];
      const int width = std::max(reference.right - reference.left,
                                 candidate.right - candidate.left);
      const int height = std::max(reference.bottom - reference.top,
                                  candidate.bottom - candidate.top);
      for (int row = 0; row < height; ++row) {
        for (int column = 0; column < width; ++column) {
          const bool before = column < reference.right - reference.left &&
              row < reference.bottom - reference.top &&
              images[0][((row + reference.top) * 620 + column + reference.left) * 4] == 255;
          const bool after = column < candidate.right - candidate.left &&
              row < candidate.bottom - candidate.top &&
              images[variant][((row + candidate.top) * 620 + column + candidate.left) * 4] == 255;
          if (before != after) ++mismatches;
        }
      }
      std::cout << "fontReference points=" << points << " variant=" << variant
                << " alignedGlyphMismatches=" << mismatches << "\n";
      if (variant == 1) success = success && mismatches == 0;
      if (variant == 2) success = success && mismatches > 0;
      if (variant == 3) success = success && mismatches == 0;
    }
  }
  FreeLibrary(module);
  DeleteDC(printer);
  std::cout << "fontReference=" << (success ? "PASS" : "FAIL") << "\n";
  return success ? 0 : 5;
}

inline bool RenderInverseComparisonText(HDC printer, HWND edit,
                                       const RECT& clip, int twips,
                                       bool inverse,
                                       std::vector<uint8_t>* raster,
                                       bool display_band = false) {
  const std::wstring text =
      L"\uc54c\ub808\ub974\uae30\uc720\ubc1c\ubb3c\uc9c8 "
      L"\uc6b0\uc720,\ubc00,\uacc4\ub780,\ud638\ub450 \ud568\uc720 120g";
  FontReferenceStream input;
  input.bytes = "{\\rtf1\\ansi\\ansicpg949\\deff0\\uc1"
      "{\\fonttbl{\\f0\\fnil\\fcharset129 Gulim;}}"
      "{\\colortbl;\\red255\\green255\\blue255;\\red0\\green0\\blue0;}"
      "\\pard\\ql\\f0\\fs10\\b\\cf" + std::string(inverse ? "1" : "2") +
      "\\highlight" + std::string(inverse ? "2 " : "1 ");
  for (const wchar_t unit : text) {
    input.bytes += "\\u" + std::to_string(
        unit > 32767 ? static_cast<int>(unit) - 65536 : unit) + "?";
  }
  input.bytes += "}";
  EDITSTREAM stream{};
  stream.dwCookie = reinterpret_cast<DWORD_PTR>(&input);
  stream.pfnCallback = ReadFontReferenceRtf;
  SendMessageW(edit, EM_STREAMIN, SF_RTF, reinterpret_cast<LPARAM>(&stream));
  SendMessageW(edit, EM_SETSEL, 0, -1);
  CHARFORMAT2W format{};
  format.cbSize = sizeof(format);
  format.dwMask = CFM_SIZE | CFM_SPACING;
  format.yHeight = twips;
  SendMessageW(edit, EM_SETCHARFORMAT, SCF_SELECTION,
               reinterpret_cast<LPARAM>(&format));
  SendMessageW(edit, EM_GETCHARFORMAT, SCF_SELECTION,
               reinterpret_cast<LPARAM>(&format));
  std::wstring actual(GetWindowTextLengthW(edit) + 1, L'\0');
  actual.resize(GetWindowTextW(edit, actual.data(), static_cast<int>(actual.size())));
  if (!actual.empty() && actual.back() == L'\r') actual.pop_back();
    const std::wstring face(format.szFaceName);
    if (stream.dwError != 0 || actual != text || format.yHeight != twips ||
      format.sSpacing != 0 || (format.dwEffects & CFE_BOLD) == 0 ||
      (face != L"Gulim" && face != L"\uad74\ub9bc")) return false;
    const auto layout = MeasureInverseTextLayout(edit, printer, clip, text, false);
  if (!layout.all_characters_fit || layout.fitted ||
      layout.padding_reduction_twips != 0) return false;
  HDC target = printer;
  if (raster != nullptr) {
    const RECT frame{0, 0, MulDiv(620, 2540, 203), MulDiv(480, 2540, 203)};
    target = CreateEnhMetaFileW(printer, nullptr, &frame, nullptr);
    if (target == nullptr) return false;
  }
  const int saved = SaveDC(target);
  SetMapMode(target, MM_TEXT);
  IntersectClipRect(target, clip.left, clip.top, clip.right, clip.bottom);
  FORMATRANGE range = layout.range;
  range.hdc = target;
  const auto until = SendMessageW(edit, EM_FORMATRANGE, TRUE,
                                  reinterpret_cast<LPARAM>(&range));
  bool success = until >= static_cast<LRESULT>(text.size());
  if (display_band) {
    const auto displayed = SendMessageW(edit, EM_DISPLAYBAND, 0,
                                        reinterpret_cast<LPARAM>(&range.rc));
    success = success && displayed != 0;
    std::cout << "comparisonDisplayBand result=" << displayed << "\n";
  }
  SendMessageW(edit, EM_FORMATRANGE, FALSE, 0);
  RestoreDC(target, saved);
  if (raster != nullptr) {
    HENHMETAFILE metafile = CloseEnhMetaFile(target);
    const auto composite = CompositeInverseTextBitmap(
        printer, metafile, clip, 620, 480, *raster);
    if (metafile != nullptr) DeleteEnhMetaFile(metafile);
    success = success && composite.success && composite.changed_pixels > 0;
  }
  std::cout << "comparisonText twips=" << twips << " inverse=" << inverse
            << " raster=" << (raster != nullptr) << " fit=" << success << "\n";
  return success;
}

inline int CreateInverseComparisonLabel(const std::filesystem::path& path,
                                       bool swap_paths = false,
                                       bool display_band = false) {
  const auto output = std::filesystem::absolute(path);
  if (output.extension() != L".prn" || std::filesystem::exists(output) ||
      !std::filesystem::is_directory(output.parent_path())) return 2;
  HDC printer = CreateInverseProbePrinter();
  HMODULE module = LoadLibraryW(L"Msftedit.dll");
  HWND host = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE, L"STATIC", L"",
      WS_POPUP, 0, 0, 620, 480, nullptr, nullptr, GetModuleHandleW(nullptr), nullptr);
  HWND edit = module == nullptr || host == nullptr ? nullptr : CreateWindowExW(
      WS_EX_TRANSPARENT, L"RICHEDIT50W", L"", WS_CHILD | ES_MULTILINE,
      0, 0, 590, 19, host, nullptr, GetModuleHandleW(nullptr), nullptr);
  bool success = printer != nullptr && edit != nullptr;
  std::vector<uint8_t> raster(620 * 480 * 4, 255);
  std::vector<RECT> clips;
  const std::array<int, 4> sizes{100, 121, 100, 121};
  std::array<std::wstring, 4> headings{
      L"A  RTF 5pt / 100twip", L"B  RTF 17dot / 121twip",
      L"C  Bitmap 5pt / 100twip", L"D  Bitmap 17dot / 121twip"};
  if (swap_paths) {
    headings = {L"A  Bitmap 5pt / 100twip", L"B  Bitmap 17dot / 121twip",
                L"C  RTF 5pt / 100twip", L"D  RTF 17dot / 121twip"};
  }
  const int raster_start = swap_paths ? 0 : 2;
  for (int index = raster_start; success && index < raster_start + 2; ++index) {
    const int top = 25 + index * 105;
    const RECT band{10, top + 50, 610, top + 82};
    clips.push_back(band);
    for (int row = band.top; row < band.bottom; ++row) {
      for (int column = band.left; column < band.right; ++column) {
        const size_t offset = (row * 620 + column) * 4;
        raster[offset] = raster[offset + 1] = raster[offset + 2] = 0;
      }
    }
    success = RenderInverseComparisonText(printer, edit,
        RECT{15, top + 22, 605, top + 41}, sizes[index], false, &raster) &&
        RenderInverseComparisonText(printer, edit,
        RECT{15, top + 54, 605, top + 73}, sizes[index], true, &raster);
  }
  const auto geometry = PrepareInverseTextGeometry(raster, 620, 480, clips);
  success = success && geometry.success;
  DOCINFOW document{};
  document.cbSize = sizeof(document);
  document.lpszDocName = L"Inverse comparison v1.3.122 - FILE ONLY";
  document.lpszOutput = output.c_str();
  const int job = success ? StartDocW(printer, &document) : 0;
  success = success && job > 0 && StartPage(printer) > 0;
  if (success) {
    SetMapMode(printer, MM_TEXT);
    SetStretchBltMode(printer, COLORONCOLOR);
    BITMAPINFO info{};
    info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    info.bmiHeader.biWidth = 620;
    info.bmiHeader.biHeight = -480;
    info.bmiHeader.biPlanes = 1;
    info.bmiHeader.biBitCount = 32;
    success = StretchDIBits(printer, 0, 0, 620, 480, 0, 0, 620, 480,
        raster.data(), &info, DIB_RGB_COLORS, SRCCOPY) == 480 &&
        RenderInverseTextGeometry(printer, geometry, 0, 0);
    const int direct_start = swap_paths ? 2 : 0;
    for (int index = direct_start; success && index < direct_start + 2; ++index) {
      const int top = 25 + index * 105;
      const RECT band{10, top + 50, 610, top + 82};
      FillRect(printer, &band, static_cast<HBRUSH>(GetStockObject(BLACK_BRUSH)));
      success = RenderInverseComparisonText(printer, edit,
          RECT{15, top + 22, 605, top + 41}, sizes[index], false, nullptr,
          display_band) &&
          RenderInverseComparisonText(printer, edit,
          RECT{15, top + 54, 605, top + 73}, sizes[index], true, nullptr,
          display_band);
    }
    HFONT font = CreateFontW(-12, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        DEFAULT_QUALITY, DEFAULT_PITCH, L"Arial");
    if (font != nullptr) {
      HGDIOBJ previous = SelectObject(printer, font);
      SetBkMode(printer, TRANSPARENT);
      SetTextColor(printer, RGB(0, 0, 0));
      for (int index = 0; index < 4; ++index) {
        success = TextOutW(printer, 15, 25 + index * 105,
            headings[index].c_str(), static_cast<int>(headings[index].size())) && success;
      }
      constexpr wchar_t title[] = L"Inverse comparison v1.3.122 - 80x60mm";
      success = TextOutW(printer, 15, 5, title, static_cast<int>(std::size(title) - 1)) && success;
      SelectObject(printer, previous);
      DeleteObject(font);
    } else {
      success = false;
    }
    if (success) success = EndPage(printer) > 0 && EndDoc(printer) > 0;
  }
  if (!success && job > 0) AbortDoc(printer);
  if (host != nullptr) DestroyWindow(host);
  if (module != nullptr) FreeLibrary(module);
  if (printer != nullptr) DeleteDC(printer);
  std::cout << "comparisonLabel=" << (success ? "PASS" : "FAIL")
            << " swapPaths=" << swap_paths
            << " displayBand=" << display_band
            << " physicalPrintRequested=false version=1.3.122 probeVersion=1.3.123\n";
  return success ? 0 : 5;
}

inline int SubmitInverseComparisonLabel(const std::filesystem::path& path) {
  if (path.filename() != L"inverse_comparison_v122.prn") return 2;
  std::ifstream input(path, std::ios::binary);
  const std::vector<char> bytes((std::istreambuf_iterator<char>(input)),
                               std::istreambuf_iterator<char>());
  if (!input.eof() && input.fail()) return 2;
  if (bytes.empty() || bytes.size() > 1024 * 1024) return 2;
  wchar_t printer_name[] = L"Godex G500";
  HANDLE queue = nullptr;
  if (!OpenPrinterW(printer_name, &queue, nullptr)) return 3;
  wchar_t document_name[] = L"Inverse comparison v1.3.122 - USER REQUEST";
  wchar_t datatype[] = L"RAW";
  DOC_INFO_1W document{document_name, nullptr, datatype};
  const DWORD job = StartDocPrinterW(queue, 1, reinterpret_cast<LPBYTE>(&document));
  DWORD written = 0;
  bool success = job > 0 && StartPagePrinter(queue) &&
      WritePrinter(queue, const_cast<char*>(bytes.data()),
                   static_cast<DWORD>(bytes.size()), &written) && written == bytes.size();
  if (success) success = EndPagePrinter(queue) && EndDocPrinter(queue);
  if (!success && job > 0) AbortPrinter(queue);
  ClosePrinter(queue);
  std::cout << "comparisonSubmit=" << (success ? "PASS" : "FAIL")
            << " job=" << job << " physicalPrintRequested=true\n";
  return success ? 0 : 4;
}

#endif