#include <windows.h>
#include <richedit.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include "../../windows/runner/inverse_text_layout.h"
#include "../../windows/runner/inverse_text_bitmap.h"
#include "../../windows/runner/inverse_text_geometry.h"
#include "../../windows/runner/native_text_comparison.h"
#include "driver_file_probe.h"
#include "../../windows/runner/debug_print_file_target.h"
#include "font_reference_probe.h"

int CALLBACK CollectText(HDC, HANDLETABLE*, const ENHMETARECORD* record,
                         int, LPARAM context) {
  if (record->iType == EMR_EXTTEXTOUTW) {
    const auto* output = reinterpret_cast<const EMREXTTEXTOUTW*>(record);
    if ((output->emrtext.fOptions & ETO_GLYPH_INDEX) == 0) {
      const auto* text = reinterpret_cast<const wchar_t*>(
          reinterpret_cast<const BYTE*>(record) + output->emrtext.offString);
      reinterpret_cast<std::wstring*>(context)->append(text, output->emrtext.nChars);
    }
  }
  return 1;
}

bool VerifyDeviceCoordinates(HDC printer) {
  const int dpi_x = GetDeviceCaps(printer, LOGPIXELSX);
  const int dpi_y = GetDeviceCaps(printer, LOGPIXELSY);
  RECT frame{0, 0, MulDiv(620, 2540, dpi_x), MulDiv(480, 2540, dpi_y)};
  bool valid = true;
  for (int fitted = 0; fitted < 2; ++fitted) {
    HDC recording = CreateEnhMetaFileW(printer, nullptr, &frame, nullptr);
    if (recording == nullptr) return false;
    SetMapMode(recording, MM_TEXT);
    if (fitted != 0) {
      SetGraphicsMode(recording, GM_ADVANCED);
      XFORM transform{0.5f, 0, 0, 1, 7.5f, 0};
      SetWorldTransform(recording, &transform);
    }
    RECT left{15, 90, fitted != 0 ? 21 : 18, 93};
    RECT right{fitted != 0 ? 1179 : 597, 106,
               fitted != 0 ? 1185 : 600, 109};
    FillRect(recording, &left, static_cast<HBRUSH>(GetStockObject(WHITE_BRUSH)));
    FillRect(recording, &right, static_cast<HBRUSH>(GetStockObject(WHITE_BRUSH)));
    HENHMETAFILE metafile = CloseEnhMetaFile(recording);
    if (metafile == nullptr) return false;
    std::vector<uint8_t> pixels(620 * 480 * 4, 0);
    const auto result = CompositeInverseTextBitmap(
        printer, metafile, RECT{15, 90, 600, 109}, 620, 480, pixels);
    DeleteEnhMetaFile(metafile);
    valid = valid && result.success;
    int mismatches = 0;
    for (int row = 0; row < 480; ++row) {
      for (int column = 0; column < 620; ++column) {
        const bool expected_white =
            (row >= 90 && row < 93 && column >= 15 && column < 18) ||
            (row >= 106 && row < 109 && column >= 597 && column < 600);
        const uint8_t expected = expected_white ? 255 : 0;
        const size_t offset = (static_cast<size_t>(row) * 620 + column) * 4;
        if (pixels[offset] != expected || pixels[offset + 1] != expected ||
            pixels[offset + 2] != expected) ++mismatches;
      }
    }
    std::cout << "deviceCoordinates fitted=" << fitted
              << " mismatches=" << mismatches << "\n";
    valid = valid && mismatches == 0;
  }
  return valid;
}

bool VerifyNativeTextComparison(HDC printer) {
  RECT frame{0, 0, MulDiv(620, 2540, GetDeviceCaps(printer, LOGPIXELSX)),
                   MulDiv(480, 2540, GetDeviceCaps(printer, LOGPIXELSY))};
  bool valid = true;
  for (int overlaps = 0; overlaps < 2; ++overlaps) {
    HDC recording = CreateEnhMetaFileW(printer, nullptr, &frame, nullptr);
    if (recording == nullptr) return false;
    RECT mark{597, overlaps != 0 ? 106 : 120, 600, overlaps != 0 ? 109 : 123};
    FillRect(recording, &mark, static_cast<HBRUSH>(GetStockObject(BLACK_BRUSH)));
    HENHMETAFILE metafile = CloseEnhMetaFile(recording);
    std::vector<uint8_t> base(620 * 480 * 4, 255);
    const auto result = ReplayNativeTextComparison(
        printer, metafile, base, 620, 480, {RECT{15, 90, 600, 109}});
    DeleteEnhMetaFile(metafile);
    valid = valid && result.success && result.inverse_white_pixels_lost.size() == 1 &&
            result.inverse_white_pixels_lost[0] == (overlaps != 0 ? 9u : 0u);
    for (size_t offset = 0; offset < base.size(); offset += 4) {
      const int row = static_cast<int>(offset / 4 / 620);
      const int column = static_cast<int>(offset / 4 % 620);
      const uint8_t expected = column >= mark.left && column < mark.right &&
          row >= mark.top && row < mark.bottom ? 0 : 255;
      valid = valid && result.success && result.pixels[offset] == expected &&
              result.pixels[offset + 1] == expected && result.pixels[offset + 2] == expected &&
              result.pixels[offset + 3] == 255;
    }
  }
  std::cout << "nativeTextComparison=" << (valid ? "PASS" : "FAIL") << "\n";
  return valid;
}

bool VerifyDebugPrintFileTarget(const std::filesystem::path& directory) {
  const auto available = std::filesystem::absolute(directory / L"new_capture.prn");
  const auto disabled = ValidateDebugPrintFileTarget(L"");
  const auto accepted = ValidateDebugPrintFileTarget(available.wstring());
  bool valid = !disabled.enabled && disabled.valid && accepted.enabled && accepted.valid;
  for (const auto& value : {std::wstring(L"relative.prn"),
       std::wstring(L"\\\\server\\share\\capture.prn"),
       (directory / L"missing_parent" / L"capture.prn").wstring(),
       (directory / L"capture.txt").wstring()}) {
    const auto rejected = ValidateDebugPrintFileTarget(value);
    valid = valid && rejected.enabled && !rejected.valid;
  }
  const auto existing = directory / L"existing_capture.prn";
  std::ofstream(existing).put('x');
  const auto rejected_existing = ValidateDebugPrintFileTarget(
      std::filesystem::absolute(existing).wstring());
  valid = valid && rejected_existing.enabled && !rejected_existing.valid;
  std::filesystem::remove(existing);
  std::cout << "debugPrintFileTarget=" << (valid ? "PASS" : "FAIL") << "\n";
  return valid;
}

bool VerifyDriverPageTail(HDC printer) {
  RECT frame{0, 0, MulDiv(620, 2540, GetDeviceCaps(printer, LOGPIXELSX)),
                   MulDiv(480, 2540, GetDeviceCaps(printer, LOGPIXELSY))};
  HDC recording = CreateEnhMetaFileW(printer, nullptr, &frame, nullptr);
  if (recording == nullptr) return false;
  RECT mark{597, 106, 600, 109};
  FillRect(recording, &mark, static_cast<HBRUSH>(GetStockObject(BLACK_BRUSH)));
  DriverPageText text;
  text.metafile = CloseEnhMetaFile(recording);
  if (!SetDriverPageTextFrame(text)) return false;
  BITMAPINFO info{};
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  info.bmiHeader.biWidth = 620;
  info.bmiHeader.biHeight = -480;
  info.bmiHeader.biPlanes = 1;
  info.bmiHeader.biBitCount = 32;
  HDC memory = CreateCompatibleDC(printer);
  void* pixels = nullptr;
  HBITMAP bitmap = CreateDIBSection(printer, &info, DIB_RGB_COLORS, &pixels, nullptr, 0);
  if (text.metafile == nullptr || memory == nullptr || bitmap == nullptr || pixels == nullptr) {
    if (bitmap != nullptr) DeleteObject(bitmap);
    if (memory != nullptr) DeleteDC(memory);
    return false;
  }
  HGDIOBJ previous = SelectObject(memory, bitmap);
  std::fill_n(static_cast<uint8_t*>(pixels), 620 * 480 * 4, uint8_t{255});
  SetBkMode(memory, OPAQUE);
  SetTextColor(memory, RGB(20, 40, 60));
  bool valid = RenderDriverPageTail(memory, text);
  valid = valid && GetMapMode(memory) == MM_TEXT && GetBkMode(memory) == OPAQUE &&
          GetTextColor(memory) == RGB(20, 40, 60);
  GdiFlush();
  size_t mark_pixels = 0;
  size_t watermark_pixels = 0;
  const auto* actual = static_cast<const uint8_t*>(pixels);
  for (int row = 0; row < 480; ++row) {
    for (int column = 0; column < 620; ++column) {
      const size_t offset = (static_cast<size_t>(row) * 620 + column) * 4;
      const bool white = actual[offset] == 255 && actual[offset + 1] == 255 &&
                         actual[offset + 2] == 255;
      if (column >= mark.left && column < mark.right && row >= mark.top && row < mark.bottom) {
        if (!white) ++mark_pixels;
      } else if (column >= 550 && row >= 460) {
        if (!white) ++watermark_pixels;
      } else {
        valid = valid && white;
      }
    }
  }
  SelectObject(memory, previous);
  DeleteObject(bitmap);
  DeleteDC(memory);
  valid = valid && mark_pixels == 9 && watermark_pixels > 0;
  std::cout << "driverPageTail=" << (valid ? "PASS" : "FAIL")
            << " markPixels=" << mark_pixels << " watermarkPixels=" << watermark_pixels << "\n";
  return valid;
}

bool VerifyInverseTextGeometry(HDC printer, const std::vector<uint8_t>& source,
                               int width, int height,
                               const std::vector<RECT>& clips) {
  auto raster = source;
  const auto geometry = PrepareInverseTextGeometry(raster, width, height, clips);
  if (!geometry.success) return false;
  bool valid = true;
  for (int row = 0; row < height; ++row) {
    for (int column = 0; column < width; ++column) {
      const size_t offset = (static_cast<size_t>(row) * width + column) * 4;
      const bool inside = std::any_of(clips.begin(), clips.end(),
          [&](const RECT& clip) {
            return column >= clip.left && column < clip.right &&
                   row >= clip.top && row < clip.bottom;
          });
      valid = valid && raster[offset + 3] == source[offset + 3];
      for (size_t channel = 0; channel < 3; ++channel) {
        valid = valid && raster[offset + channel] ==
            (inside ? uint8_t{255} : source[offset + channel]);
      }
    }
  }
  BITMAPINFO info{};
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  info.bmiHeader.biWidth = width;
  info.bmiHeader.biHeight = -height;
  info.bmiHeader.biPlanes = 1;
  info.bmiHeader.biBitCount = 32;
  HDC memory = CreateCompatibleDC(printer);
  void* pixels = nullptr;
  HBITMAP bitmap = CreateDIBSection(memory, &info, DIB_RGB_COLORS, &pixels, nullptr, 0);
  if (memory == nullptr || bitmap == nullptr || pixels == nullptr) {
    if (bitmap != nullptr) DeleteObject(bitmap);
    if (memory != nullptr) DeleteDC(memory);
    return false;
  }
  HGDIOBJ previous = SelectObject(memory, bitmap);
  SetStretchBltMode(memory, COLORONCOLOR);
  for (int shifted = 0; shifted < 2; ++shifted) {
    SetViewportOrgEx(memory, -shifted, -shifted, nullptr);
    const int scan_lines = StretchDIBits(
        memory, shifted, shifted, width, height, 0, 0, width, height,
        raster.data(), &info, DIB_RGB_COLORS, SRCCOPY);
    valid = valid && scan_lines == height;
    valid = RenderInverseTextGeometry(memory, geometry, shifted, shifted) && valid;
    GdiFlush();
    const auto* actual = static_cast<const uint8_t*>(pixels);
    size_t mismatches = 0;
    for (size_t offset = 0; offset < source.size(); offset += 4) {
      if (!std::equal(source.begin() + offset, source.begin() + offset + 3,
                      actual + offset)) ++mismatches;
      valid = valid && raster[offset + 3] == source[offset + 3];
    }
    std::cout << "inverseGeometry shifted=" << shifted
              << " runs=" << geometry.black_runs.size()
              << " blackPixels=" << geometry.black_pixels
              << " whitePixels=" << geometry.white_pixels
              << " mismatches=" << mismatches << "\n";
    valid = valid && mismatches == 0;
  }
  SelectObject(memory, previous);
  DeleteObject(bitmap);
  DeleteDC(memory);
  return valid;
}

int ReplaySavedComposite(const std::filesystem::path& prefix,
                         const std::filesystem::path& output) {
  std::ifstream report(prefix.wstring() + L".txt");
  std::string line;
  RECT clip{};
  bool clip_found = false;
  while (std::getline(report, line)) {
    if (line.rfind("clip=", 0) == 0) {
      line.erase(0, 5);
      std::replace(line.begin(), line.end(), ',', ' ');
      std::istringstream values(line);
      clip_found = static_cast<bool>(values >> clip.left >> clip.top >> clip.right >> clip.bottom);
    }
  }
  std::ifstream input(prefix.wstring() + L"_base.bmp", std::ios::binary);
  BITMAPFILEHEADER header{};
  BITMAPINFOHEADER info{};
  input.read(reinterpret_cast<char*>(&header), sizeof(header));
  input.read(reinterpret_cast<char*>(&info), sizeof(info));
  if (!input || !clip_found || header.bfType != 0x4d42 ||
      info.biBitCount != 32 || info.biCompression != BI_RGB ||
      info.biWidth <= 0 || info.biHeight >= 0) return 2;
  const int width = info.biWidth;
  const int height = -info.biHeight;
  std::vector<uint8_t> pixels(static_cast<size_t>(width) * height * 4);
  input.seekg(header.bfOffBits);
  input.read(reinterpret_cast<char*>(pixels.data()),
             static_cast<std::streamsize>(pixels.size()));
  if (!input) return 3;
  const auto before = pixels;
  HDC printer = CreateDCW(L"WINSPOOL", L"Godex G500", nullptr, nullptr);
  HENHMETAFILE metafile = GetEnhMetaFileW((prefix.wstring() + L".emf").c_str());
  if (printer == nullptr || metafile == nullptr) {
    if (printer != nullptr) DeleteDC(printer);
    if (metafile != nullptr) DeleteEnhMetaFile(metafile);
    return 4;
  }
  const auto result = CompositeInverseTextBitmap(printer, metafile, clip,
                                                 width, height, pixels);
  const bool geometry_valid = VerifyInverseTextGeometry(
      printer, pixels, width, height, {clip});
  DeleteEnhMetaFile(metafile);
  DeleteDC(printer);
  bool valid = geometry_valid && result.success && result.changed_pixels > 0 && result.raster_bit_count == 1;
  for (int row = 0; row < height; ++row) {
    for (int column = 0; column < width; ++column) {
      const size_t offset = (static_cast<size_t>(row) * width + column) * 4;
      if (column < clip.left || column >= clip.right || row < clip.top || row >= clip.bottom) {
        valid = valid && std::equal(pixels.begin() + offset,
            pixels.begin() + offset + 4, before.begin() + offset);
      } else {
        valid = valid && (pixels[offset] == 0 || pixels[offset] == 255) &&
                pixels[offset] == pixels[offset + 1] && pixels[offset] == pixels[offset + 2];
      }
      valid = valid && pixels[offset + 3] == before[offset + 3];
    }
  }
  std::ofstream image(output, std::ios::binary);
  image.write(reinterpret_cast<const char*>(&header), sizeof(header));
  image.write(reinterpret_cast<const char*>(&info), sizeof(info));
  image.write(reinterpret_cast<const char*>(pixels.data()),
              static_cast<std::streamsize>(pixels.size()));
  image.close();
  valid = valid && !image.fail();
  std::cout << "savedComposite=" << (valid ? "PASS" : "FAIL")
            << " changedPixels=" << result.changed_pixels
            << " rasterBitCount=" << result.raster_bit_count << "\n";
  return valid ? 0 : 1;
}

int wmain(int count, wchar_t** arguments) {
  if (count == 3 && std::wstring(arguments[1]) == L"--comparison-label-display-band") {
    return CreateInverseComparisonLabel(arguments[2], false, true);
  }
  if (count == 3 && std::wstring(arguments[1]) == L"--comparison-label-swapped") {
    return CreateInverseComparisonLabel(arguments[2], true);
  }
  if (count == 3 && std::wstring(arguments[1]) == L"--comparison-label") {
    return CreateInverseComparisonLabel(arguments[2]);
  }
  if (count == 3 && std::wstring(arguments[1]) == L"--submit-comparison-label") {
    return SubmitInverseComparisonLabel(arguments[2]);
  }
  if (count == 3 && std::wstring(arguments[1]) == L"--font-reference") {
    return CompareInverseFontReference(arguments[2]);
  }
  if (count == 5 && std::wstring(arguments[1]) == L"--driver-file-page") {
    return CaptureInverseDriverFile(arguments[2], arguments[4], false, arguments[3]);
  }
  if (count == 4 && std::wstring(arguments[1]) == L"--driver-file-legacy-devmode") {
    return CaptureInverseDriverFile(arguments[2], arguments[3], true);
  }
  if (count == 4 && std::wstring(arguments[1]) == L"--driver-file") {
    return CaptureInverseDriverFile(arguments[2], arguments[3]);
  }
  if (count == 4 && std::wstring(arguments[1]) == L"--replay") {
    return ReplaySavedComposite(arguments[2], arguments[3]);
  }
  const bool exact_emf =
      count == 4 && std::wstring(arguments[1]) == L"--exact-emf";
  if (count != 3 && !exact_emf) return 2;
  const auto output_directory =
      std::filesystem::path(arguments[exact_emf ? 3 : 2]);
  std::filesystem::create_directories(output_directory);
  std::wstring text;
  if (std::wstring(arguments[1]) == L"--synthetic") {
    text = L"\uc601\uc591\uc815\ubcf4" + std::wstring(55, L' ') +
           L"TOTAL 120g 30x430g 123456789";
  } else {
    HENHMETAFILE source = GetEnhMetaFileW(arguments[exact_emf ? 2 : 1]);
    if (source == nullptr) return 3;
    EnumEnhMetaFile(nullptr, source, CollectText,
                   reinterpret_cast<void*>(&text), nullptr);
    DeleteEnhMetaFile(source);
    if (!exact_emf) text += L" 123456789";
  }
  HDC printer = CreateDCW(L"WINSPOOL", L"Godex G500", nullptr, nullptr);
  HMODULE module = LoadLibraryW(L"Msftedit.dll");
  if (printer == nullptr || module == nullptr) return 4;
  const int dpi_x = GetDeviceCaps(printer, LOGPIXELSX);
  const int dpi_y = GetDeviceCaps(printer, LOGPIXELSY);
  bool success = VerifyDeviceCoordinates(printer) && VerifyNativeTextComparison(printer) &&
                 VerifyDriverPageTail(printer) && VerifyDebugPrintFileTarget(output_directory);
  for (int variant = 0; variant < 8; ++variant) {
    HWND host = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
        L"STATIC", L"", WS_POPUP, 0, 0, 620, 480, nullptr, nullptr,
        GetModuleHandleW(nullptr), nullptr);
    HWND edit = CreateWindowExW(variant >= 4 ? WS_EX_TRANSPARENT : 0,
      L"RICHEDIT50W", L"",
        WS_CHILD | WS_VISIBLE | ES_MULTILINE, 0, 0, 585, 19,
        host, nullptr, GetModuleHandleW(nullptr), nullptr);
    SetWindowTextW(edit, text.c_str());
    SendMessageW(edit, EM_SETBKGNDCOLOR, FALSE, RGB(0, 0, 0));
    SendMessageW(edit, EM_SETMARGINS, EC_LEFTMARGIN | EC_RIGHTMARGIN, 0);
    RECT edit_rect{0, 0, 585, 19};
    SendMessageW(edit, EM_SETRECTNP, 0, reinterpret_cast<LPARAM>(&edit_rect));
    SendMessageW(edit, EM_SETSEL, 0, -1);
    CHARFORMAT2W character{};
    character.cbSize = sizeof(character);
    character.dwMask = CFM_FACE | CFM_SIZE | CFM_COLOR | CFM_BACKCOLOR |
                       CFM_BOLD | CFM_ITALIC | CFM_UNDERLINE | CFM_STRIKEOUT;
    character.dwEffects = CFE_BOLD;
    character.yHeight = MulDiv(17, 1440, dpi_y);
    character.crTextColor = RGB(255, 255, 255);
    character.crBackColor = RGB(0, 0, 0);
    wcscpy_s(character.szFaceName, L"\uad74\ub9bc");
    SendMessageW(edit, EM_SETCHARFORMAT, SCF_SELECTION,
                 reinterpret_cast<LPARAM>(&character));
    PARAFORMAT2 paragraph{};
    paragraph.cbSize = sizeof(paragraph);
    paragraph.dwMask = PFM_ALIGNMENT;
    paragraph.wAlignment = PFA_LEFT;
    SendMessageW(edit, EM_SETPARAFORMAT, 0,
                 reinterpret_cast<LPARAM>(&paragraph));
    if (variant == 1 || variant == 3) {
      SendMessageW(edit, EM_SETEDITSTYLE, SES_EXTENDBACKCOLOR,
                   SES_EXTENDBACKCOLOR);
    }
    if (variant == 2 || variant == 3) {
      SendMessageW(edit, EM_SETTARGETDEVICE,
                   reinterpret_cast<WPARAM>(printer), 0);
    }
    RECT frame{0, 0, MulDiv(620, 2540, dpi_x), MulDiv(480, 2540, dpi_y)};
    const auto path = output_directory / (std::to_wstring(variant) + L".emf");
    HDC recording = CreateEnhMetaFileW(printer, path.c_str(), &frame, nullptr);
    SetMapMode(recording, MM_TEXT);
    IntersectClipRect(recording, 15, 291, 600, 310);
    FORMATRANGE range{};
    range.hdc = recording;
    range.hdcTarget = printer;
    range.rc = {MulDiv(15, 1440, dpi_x), MulDiv(291, 1440, dpi_y),
                MulDiv(600, 1440, dpi_x), MulDiv(310, 1440, dpi_y)};
    range.rcPage = range.rc;
    range.chrg.cpMax = -1;
    InverseTextLayout layout;
    if (variant >= 5) {
      const auto wrapped = MeasureInverseTextLayout(
          edit, printer, RECT{15, 291, 600, 310}, text, true);
      success = success && !wrapped.fitted && wrapped.width == 585;
      CHARRANGE selection_before{};
      SendMessageW(edit, EM_EXGETSEL, 0,
                   reinterpret_cast<LPARAM>(&selection_before));
      layout = MeasureInverseTextLayout(edit, printer, RECT{15, 291, 600, 310},
                                        text, false);
      if (std::wstring(arguments[1]) == L"--synthetic" || exact_emf) {
        success = success && layout.all_characters_fit &&
                  layout.transform.eM11 == 1.0f && layout.width == 585 &&
                  layout.padding_reduction_twips > 0;
        CHARRANGE selection{};
        SendMessageW(edit, EM_EXGETSEL, 0,
                     reinterpret_cast<LPARAM>(&selection));
        success = success && selection.cpMin == selection_before.cpMin &&
                  selection.cpMax == selection_before.cpMax;
        SendMessageW(edit, EM_SETSEL, 0, 4);
        CHARFORMAT2W glyph{};
        glyph.cbSize = sizeof(glyph);
        SendMessageW(edit, EM_GETCHARFORMAT, SCF_SELECTION,
                     reinterpret_cast<LPARAM>(&glyph));
        std::cout << "paddingSelection=" << selection.cpMin << ","
                  << selection.cpMax << " glyphTwips=" << glyph.yHeight
                  << " glyphSpacing=" << glyph.sSpacing << "\n";
        success = success && glyph.yHeight == character.yHeight &&
                  glyph.sSpacing == 0 && (glyph.dwEffects & CFE_BOLD) != 0;
        SendMessageW(edit, EM_EXSETSEL, 0,
                     reinterpret_cast<LPARAM>(&selection));
      }
      range = layout.range;
      range.hdc = recording;
      SetGraphicsMode(recording, GM_ADVANCED);
      SetWorldTransform(recording, &layout.transform);
      if (variant == 6) range.hdcTarget = recording;
    }
    const LRESULT until = SendMessageW(edit, EM_FORMATRANGE, TRUE,
                                       reinterpret_cast<LPARAM>(&range));
    SendMessageW(edit, EM_FORMATRANGE, FALSE, 0);
    SendMessageW(edit, EM_SETTYPOGRAPHYOPTIONS,
                 layout.original_typography_options, TO_ADVANCEDTYPOGRAPHY);
    HENHMETAFILE result = CloseEnhMetaFile(recording);
    if (variant >= 5) {
      std::wstring recorded;
      EnumEnhMetaFile(nullptr, result, CollectText,
             reinterpret_cast<void*>(&recorded), nullptr);
      success = success && recorded == text;
      SetWindowTextW(edit, L"SHORT");
      const auto short_layout = MeasureInverseTextLayout(
        edit, printer, RECT{15, 291, 600, 310}, L"SHORT", false);
      success = success && !short_layout.fitted &&
          short_layout.all_characters_fit && short_layout.width == 585;
      SetWindowTextW(edit, L"FIRST\r\nSECOND");
      const auto multiline = MeasureInverseTextLayout(
        edit, printer, RECT{15, 291, 600, 310}, L"FIRST\r\nSECOND", false);
      success = success && !multiline.fitted && multiline.width == 585;
      const std::wstring insufficient_padding =
          std::wstring(50, L'W') + L"  " + std::wstring(50, L'W');
      SetWindowTextW(edit, insufficient_padding.c_str());
      const auto original_typography =
          SendMessageW(edit, EM_GETTYPOGRAPHYOPTIONS, 0, 0);
      const auto fallback = MeasureInverseTextLayout(
          edit, printer, RECT{15, 291, 600, 310}, insufficient_padding, false);
      SendMessageW(edit, EM_SETSEL, 50, 52);
      CHARFORMAT2W restored{};
      restored.cbSize = sizeof(restored);
      SendMessageW(edit, EM_GETCHARFORMAT, SCF_SELECTION,
                   reinterpret_cast<LPARAM>(&restored));
      std::cout << "paddingFallback fitted=" << fallback.fitted
                << " allFit=" << fallback.all_characters_fit
                << " reduction=" << fallback.padding_reduction_twips
                << " spacing=" << restored.sSpacing << " typography="
                << SendMessageW(edit, EM_GETTYPOGRAPHYOPTIONS, 0, 0)
                << " original=" << original_typography << "\n";
      success = success && fallback.fitted && fallback.all_characters_fit &&
                fallback.padding_reduction_twips == 0 &&
                restored.sSpacing == 0 &&
                SendMessageW(edit, EM_GETTYPOGRAPHYOPTIONS, 0, 0) ==
                    original_typography;
    }
    BITMAPINFO info{};
    info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    info.bmiHeader.biWidth = 620;
    info.bmiHeader.biHeight = -480;
    info.bmiHeader.biPlanes = 1;
    info.bmiHeader.biBitCount = 32;
    HDC memory = CreateCompatibleDC(printer);
    void* pixels = nullptr;
    HBITMAP bitmap = CreateDIBSection(memory, &info, DIB_RGB_COLORS,
                                     &pixels, nullptr, 0);
    HGDIOBJ previous = SelectObject(memory, bitmap);
    PatBlt(memory, 0, 0, 620, 480, BLACKNESS);
    RECT destination{0, 0, 620, 480};
    const BOOL replayed = PlayEnhMetaFile(memory, result, &destination);
    GdiFlush();
    if (variant == 7) {
      std::vector<uint8_t> flattened(620 * 480 * 4, 0);
      for (size_t offset = 0; offset < flattened.size(); offset += 4) {
        const size_t row = offset / 4 / 620;
        const size_t column = offset / 4 % 620;
        if (row < 291 || row >= 310 || column < 15 || column >= 600) {
          flattened[offset] = 32;
          flattened[offset + 1] = 64;
          flattened[offset + 2] = 96;
        }
        flattened[offset + 3] = 255;
      }
      const auto before = flattened;
      const auto composite = CompositeInverseTextBitmap(
          printer, result, RECT{15, 291, 600, 310}, 620, 480, flattened);
      success = success && composite.success && composite.changed_pixels > 0 &&
            composite.raster_bit_count == 1;
      success = VerifyInverseTextGeometry(printer, flattened, 620, 480,
          {RECT{15, 291, 600, 310}, RECT{15, 291, 600, 310}}) && success;
      for (size_t offset = 0; offset < flattened.size(); offset += 4) {
        const size_t row = offset / 4 / 620;
        const size_t column = offset / 4 % 620;
        if (row < 291 || row >= 310 || column < 15 || column >= 600) {
          success = success && std::equal(flattened.begin() + offset,
              flattened.begin() + offset + 4, before.begin() + offset);
        } else {
          success = success && (flattened[offset] == 0 || flattened[offset] == 255) &&
              flattened[offset] == flattened[offset + 1] &&
              flattened[offset] == flattened[offset + 2];
        }
        success = success && flattened[offset + 3] == before[offset + 3];
      }
      std::copy(flattened.begin(), flattened.end(), static_cast<uint8_t*>(pixels));
      std::cout << "flattenedPixels=" << composite.changed_pixels
                << " rasterBitCount=" << composite.raster_bit_count << "\n";
    }
    BITMAPFILEHEADER header{};
    header.bfType = 0x4d42;
    header.bfOffBits = sizeof(header) + sizeof(BITMAPINFOHEADER);
    header.bfSize = header.bfOffBits + 620 * 480 * 4;
    std::ofstream image(output_directory / (std::to_wstring(variant) + L".bmp"),
               std::ios::binary);
    image.write(reinterpret_cast<const char*>(&header), sizeof(header));
    image.write(reinterpret_cast<const char*>(&info.bmiHeader), sizeof(info.bmiHeader));
    image.write(static_cast<const char*>(pixels), 620 * 480 * 4);
    image.close();
    int white_columns = 0;
    const auto* bytes = static_cast<const BYTE*>(pixels);
    for (int column = 15; column < 600; ++column) {
      bool white = true;
      for (int row = 294; row < 307; ++row) {
        const size_t offset = (static_cast<size_t>(row) * 620 + column) * 4;
        white = white && bytes[offset] == 255 && bytes[offset + 1] == 255 &&
                bytes[offset + 2] == 255;
      }
      if (white) ++white_columns;
    }
    std::cout << "variant=" << variant << " input=" << text.size()
              << " until=" << until << " whiteColumns=" << white_columns
              << " replay=" << replayed << " layoutWidth=" << layout.width
              << " paddingTwips=" << layout.padding_reduction_twips
              << " scaleX=" << layout.transform.eM11 << "\n";
    success = success && replayed != FALSE;
    if (variant == 0) success = success && until < static_cast<LRESULT>(text.size()) && white_columns > 0;
    if (variant == 4) success = success && white_columns == 0;
    if (variant >= 5) success = success && until >= static_cast<LRESULT>(text.size()) && white_columns == 0;
    SelectObject(memory, previous);
    DeleteObject(bitmap);
    DeleteDC(memory);
    DeleteEnhMetaFile(result);
    DestroyWindow(edit);
    DestroyWindow(host);
  }
  FreeLibrary(module);
  DeleteDC(printer);
  std::cout << "regression=" << (success ? "PASS" : "FAIL") << "\n";
  return success ? 0 : 1;
}