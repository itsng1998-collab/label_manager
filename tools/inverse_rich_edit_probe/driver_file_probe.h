#ifndef INVERSE_DRIVER_FILE_PROBE_H_
#define INVERSE_DRIVER_FILE_PROBE_H_

#include <windows.h>
#include <winspool.h>
#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include "../../windows/runner/inverse_text_geometry.h"

inline int CaptureInverseDriverFile(const std::filesystem::path& prefix,
                                    const std::filesystem::path& destination,
                                    bool legacy_devmode = false) {
  const auto output = std::filesystem::absolute(destination);
  if (output.extension() != L".prn" || std::filesystem::exists(output) ||
      !std::filesystem::is_directory(output.parent_path())) return 2;
  std::ifstream report(prefix.wstring() + L".txt");
  std::string line;
  RECT clip{};
  bool clip_found = false;
  while (std::getline(report, line)) {
    if (line.rfind("clip=", 0) != 0) continue;
    std::replace(line.begin(), line.end(), ',', ' ');
    std::istringstream values(line.substr(5));
    clip_found = static_cast<bool>(values >> clip.left >> clip.top >> clip.right >> clip.bottom);
  }
  std::ifstream input(prefix.wstring() + L"_comparison.bmp", std::ios::binary);
  BITMAPFILEHEADER file_header{};
  BITMAPINFO info{};
  input.read(reinterpret_cast<char*>(&file_header), sizeof(file_header));
  input.read(reinterpret_cast<char*>(&info.bmiHeader), sizeof(info.bmiHeader));
  if (!input || !clip_found || file_header.bfType != 0x4d42 ||
      info.bmiHeader.biWidth != 620 || info.bmiHeader.biHeight != -480 ||
      info.bmiHeader.biBitCount != 32 || info.bmiHeader.biCompression != BI_RGB) return 3;
  std::vector<uint8_t> raster(620 * 480 * 4);
  input.seekg(file_header.bfOffBits);
  input.read(reinterpret_cast<char*>(raster.data()), static_cast<std::streamsize>(raster.size()));
  if (!input) return 3;
  const auto geometry = PrepareInverseTextGeometry(raster, 620, 480, {clip});
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
    if (success) success = EndPage(printer) > 0;
  }
  if (success) success = EndDoc(printer) > 0;
  const DWORD error = success ? ERROR_SUCCESS : GetLastError();
  if (!success) AbortDoc(printer);
  DeleteDC(printer);
  std::cout << "driverFile=" << (success ? "PASS" : "FAIL")
            << " legacyDevmode=" << legacy_devmode
            << " job=" << job << " error=" << error
            << " sourceWhite=" << geometry.white_pixels
            << " sourceBlack=" << geometry.black_pixels
            << " physicalPrintRequested=false\n";
  return success ? 0 : 8;
}

#endif