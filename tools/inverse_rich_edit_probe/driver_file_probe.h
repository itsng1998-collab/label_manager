#ifndef INVERSE_DRIVER_FILE_PROBE_H_
#define INVERSE_DRIVER_FILE_PROBE_H_

#include <windows.h>
#include <winspool.h>
#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <sstream>
#include <string>
#include <vector>
#include "../../windows/runner/inverse_text_geometry.h"

struct DriverPageText {
  HENHMETAFILE metafile = nullptr;
  RECT destination{};
  ~DriverPageText() {
    if (metafile != nullptr) DeleteEnhMetaFile(metafile);
  }
};

inline bool SetDriverPageTextFrame(DriverPageText& text) {
  ENHMETAHEADER header{};
  if (text.metafile == nullptr ||
      GetEnhMetaFileHeader(text.metafile, sizeof(header), &header) == 0 ||
      header.szlMillimeters.cx <= 0 || header.szlMillimeters.cy <= 0) return false;
  text.destination = RECT{
      MulDiv(header.rclFrame.left, header.szlDevice.cx, header.szlMillimeters.cx * 100),
      MulDiv(header.rclFrame.top, header.szlDevice.cy, header.szlMillimeters.cy * 100),
      MulDiv(header.rclFrame.right, header.szlDevice.cx, header.szlMillimeters.cx * 100),
      MulDiv(header.rclFrame.bottom, header.szlDevice.cy, header.szlMillimeters.cy * 100)};
  return true;
}

inline bool RenderDriverPageTail(HDC printer, const DriverPageText& text) {
  const int saved = SaveDC(printer);
  if (saved == 0) return false;
  bool success = PlayEnhMetaFile(printer, text.metafile, &text.destination) != FALSE;
  SetMapMode(printer, MM_TEXT);
  SetBkMode(printer, TRANSPARENT);
  SetTextColor(printer, RGB(0, 0, 0));
  HFONT font = CreateFontW(-7, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
      DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
      DEFAULT_PITCH | FF_DONTCARE, L"Arial");
  if (font == nullptr) {
    RestoreDC(printer, saved);
    return false;
  }
  HGDIOBJ previous = SelectObject(printer, font);
  constexpr wchar_t watermark[] = L"v1.3.107";
  constexpr int length = static_cast<int>(std::size(watermark) - 1);
  SIZE size{};
  const BOOL measured = GetTextExtentPoint32W(printer, watermark, length, &size);
  const int left = std::max(0, 620 - (measured ? static_cast<int>(size.cx) : 32) - 2);
  const int top = std::max(0, 480 - (measured ? static_cast<int>(size.cy) : 7) - 2);
  success = TextOutW(printer, left, top, watermark, length) != FALSE && success;
  SelectObject(printer, previous);
  DeleteObject(font);
  RestoreDC(printer, saved);
  return success;
}

inline int CaptureInverseDriverFile(const std::filesystem::path& prefix,
                                    const std::filesystem::path& destination,
                                    bool legacy_devmode = false,
                                    const std::filesystem::path& native_prefix = {}) {
  const auto output = std::filesystem::absolute(destination);
  if (output.extension() != L".prn" || std::filesystem::exists(output) ||
      !std::filesystem::is_directory(output.parent_path())) return 2;
  const bool page_replay = !native_prefix.empty();
  std::ifstream report((page_replay ? native_prefix : prefix).wstring() + L".txt");
  std::string line;
  std::vector<RECT> clips;
  bool supported_page_version = false;
  while (std::getline(report, line)) {
    if (line == "version=1.3.107") supported_page_version = true;
    const size_t marker = page_replay ? line.find("].clip=") : line.find("clip=");
    if (marker == std::string::npos ||
        (page_replay ? line.rfind("inverse[", 0) != 0 : marker != 0)) continue;
    std::replace(line.begin(), line.end(), ',', ' ');
    std::istringstream values(line.substr(marker + (page_replay ? 7 : 5)));
    RECT clip{};
    if (!(values >> clip.left >> clip.top >> clip.right >> clip.bottom) ||
        clip.left < 0 || clip.top < 0 || clip.right > 620 || clip.bottom > 480 ||
        clip.right <= clip.left || clip.bottom <= clip.top) return 3;
    clips.push_back(clip);
  }
  DriverPageText page_text;
  if (page_replay) {
    if (!supported_page_version) return 3;
    page_text.metafile = GetEnhMetaFileW((native_prefix.wstring() + L".emf").c_str());
    if (!SetDriverPageTextFrame(page_text)) return 3;
  }
  std::ifstream input(prefix.wstring() + L"_comparison.bmp", std::ios::binary);
  BITMAPFILEHEADER file_header{};
  BITMAPINFO info{};
  input.read(reinterpret_cast<char*>(&file_header), sizeof(file_header));
  input.read(reinterpret_cast<char*>(&info.bmiHeader), sizeof(info.bmiHeader));
  if (!input || clips.empty() || file_header.bfType != 0x4d42 ||
      info.bmiHeader.biWidth != 620 || info.bmiHeader.biHeight != -480 ||
      info.bmiHeader.biBitCount != 32 || info.bmiHeader.biCompression != BI_RGB) return 3;
  std::vector<uint8_t> raster(620 * 480 * 4);
  input.seekg(file_header.bfOffBits);
  input.read(reinterpret_cast<char*>(raster.data()), static_cast<std::streamsize>(raster.size()));
  if (!input) return 3;
  const auto geometry = PrepareInverseTextGeometry(raster, 620, 480, clips);
  if (!geometry.success) return 4;
  wchar_t printer_name[] = L"Godex G500";
  HANDLE queue = nullptr;
  if (!OpenPrinterW(printer_name, &queue, nullptr)) return 5;
  const LONG mode_size = DocumentPropertiesW(nullptr, queue, printer_name, nullptr, nullptr, 0);
  if (mode_size <= 0) {
    ClosePrinter(queue);
    return 5;
  }
  std::vector<uint8_t> storage(static_cast<size_t>(mode_size));
  auto* mode = reinterpret_cast<DEVMODEW*>(storage.data());
  bool configured = DocumentPropertiesW(nullptr, queue, printer_name, mode, nullptr,
                                        DM_OUT_BUFFER) == IDOK;
  if (configured) {
    if (legacy_devmode) mode->dmFields = 0;
    mode->dmFields |= DM_PAPERSIZE | DM_PAPERWIDTH | DM_PAPERLENGTH | DM_ORIENTATION | DM_COPIES;
    mode->dmPaperSize = DMPAPER_USER;
    mode->dmPaperWidth = 800;
    mode->dmPaperLength = 600;
    mode->dmOrientation = DMORIENT_PORTRAIT;
    mode->dmCopies = 1;
    if (!legacy_devmode) {
      configured = DocumentPropertiesW(nullptr, queue, printer_name, mode, mode,
                                       DM_IN_BUFFER | DM_OUT_BUFFER) == IDOK;
    }
  }
  ClosePrinter(queue);
  if (!configured) return 5;
  HDC printer = CreateDCW(L"WINSPOOL", printer_name, nullptr, mode);
  if (printer == nullptr) return 6;
  if (GetDeviceCaps(printer, HORZRES) != 620 || GetDeviceCaps(printer, VERTRES) != 480 ||
      GetDeviceCaps(printer, LOGPIXELSX) != 203 || GetDeviceCaps(printer, LOGPIXELSY) != 203) {
    DeleteDC(printer);
    return 6;
  }
  DOCINFOW document{};
  document.cbSize = sizeof(document);
  document.lpszDocName = L"Inverse diagnostic - local file only";
  document.lpszOutput = output.c_str();
  const int job = StartDocW(printer, &document);
  if (job <= 0) {
    DeleteDC(printer);
    return 7;
  }
  bool success = StartPage(printer) > 0;
  if (success) {
    SetMapMode(printer, MM_TEXT);
    SetStretchBltMode(printer, COLORONCOLOR);
    success = StretchDIBits(printer, 0, 0, 620, 480, 0, 0, 620, 480,
                            raster.data(), &info, DIB_RGB_COLORS, SRCCOPY) == 480;
    success = success && RenderInverseTextGeometry(printer, geometry, 0, 0);
    if (success && page_replay) success = RenderDriverPageTail(printer, page_text);
    if (success) success = EndPage(printer) > 0;
  }
  if (success) success = EndDoc(printer) > 0;
  const DWORD error = success ? ERROR_SUCCESS : GetLastError();
  if (!success) AbortDoc(printer);
  DeleteDC(printer);
  std::cout << "driverFile=" << (success ? "PASS" : "FAIL")
            << " pageReplay=" << page_replay << " inverseClips=" << clips.size()
            << " legacyDevmode=" << legacy_devmode
            << " job=" << job << " error=" << error
            << " sourceWhite=" << geometry.white_pixels
            << " sourceBlack=" << geometry.black_pixels
            << " physicalPrintRequested=false\n";
  return success ? 0 : 8;
}

#endif