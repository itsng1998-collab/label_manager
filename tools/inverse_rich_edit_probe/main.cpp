#include <windows.h>
#include <richedit.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include "../../windows/runner/inverse_text_layout.h"

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

int wmain(int count, wchar_t** arguments) {
  if (count != 3) return 2;
  const auto output_directory = std::filesystem::path(arguments[2]);
  std::filesystem::create_directories(output_directory);
  std::wstring text;
  if (std::wstring(arguments[1]) == L"--synthetic") {
    text = L"\uc601\uc591\uc815\ubcf4" + std::wstring(55, L' ') +
           L"TOTAL 120g 30x430g 123456789";
  } else {
    HENHMETAFILE source = GetEnhMetaFileW(arguments[1]);
    if (source == nullptr) return 3;
    EnumEnhMetaFile(nullptr, source, CollectText,
                   reinterpret_cast<void*>(&text), nullptr);
    DeleteEnhMetaFile(source);
    text += L" 123456789";
  }
  HDC printer = CreateDCW(L"WINSPOOL", L"Godex G500", nullptr, nullptr);
  HMODULE module = LoadLibraryW(L"Msftedit.dll");
  if (printer == nullptr || module == nullptr) return 4;
  const int dpi_x = GetDeviceCaps(printer, LOGPIXELSX);
  const int dpi_y = GetDeviceCaps(printer, LOGPIXELSY);
  bool success = true;
  for (int variant = 0; variant < 7; ++variant) {
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
      layout = MeasureInverseTextLayout(edit, printer, RECT{15, 291, 600, 310},
                                         text, false);
      range = layout.range;
      range.hdc = recording;
      SetGraphicsMode(recording, GM_ADVANCED);
      SetWorldTransform(recording, &layout.transform);
      if (variant == 6) range.hdcTarget = recording;
    }
    const LRESULT until = SendMessageW(edit, EM_FORMATRANGE, TRUE,
                                       reinterpret_cast<LPARAM>(&range));
    SendMessageW(edit, EM_FORMATRANGE, FALSE, 0);
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