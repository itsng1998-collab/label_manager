#include "label_bitmap_print_channel.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <algorithm>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

namespace {

using EncodableMap = flutter::EncodableMap;
using EncodableValue = flutter::EncodableValue;

const std::string* StringArg(const EncodableMap& args, const char* key) {
  const auto iter = args.find(EncodableValue(key));
  if (iter == args.end()) return nullptr;
  return std::get_if<std::string>(&iter->second);
}

int IntArg(const EncodableMap& args, const char* key, int fallback) {
  const auto iter = args.find(EncodableValue(key));
  if (iter == args.end()) return fallback;
  if (const auto* value = std::get_if<int32_t>(&iter->second)) return *value;
  if (const auto* value = std::get_if<int64_t>(&iter->second)) {
    return static_cast<int>(*value);
  }
  return fallback;
}

double DoubleArg(const EncodableMap& args, const char* key, double fallback) {
  const auto iter = args.find(EncodableValue(key));
  if (iter == args.end()) return fallback;
  if (const auto* value = std::get_if<double>(&iter->second)) return *value;
  return fallback;
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) return {};
  const int size = MultiByteToWideChar(CP_UTF8, 0, value.data(),
                                       static_cast<int>(value.size()), nullptr, 0);
  if (size <= 0) return {};
  std::wstring result(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.data(),
                      static_cast<int>(value.size()), result.data(), size);
  return result;
}

EncodableValue PrintResult(bool ok, const std::string& diagnostics,
                           const std::string& error = {}) {
  EncodableMap result{
      {EncodableValue("ok"), EncodableValue(ok)},
      {EncodableValue("diagnostics"), EncodableValue(diagnostics)},
  };
  if (!error.empty()) {
    result[EncodableValue("error")] = EncodableValue(error);
  }
  return EncodableValue(result);
}

EncodableValue PrintBitmap(const EncodableMap& args) {
  const auto* printer_name_utf8 = StringArg(args, "printerName");
  const auto* document_name_utf8 = StringArg(args, "documentName");
  const int source_width = IntArg(args, "sourceWidth", 0);
  const int source_height = IntArg(args, "sourceHeight", 0);
  const double page_width_mm = DoubleArg(args, "pageWidthMm", 0);
  const double page_height_mm = DoubleArg(args, "pageHeightMm", 0);
  const auto pixels_iter = args.find(EncodableValue("bgra"));
  const auto* bgra = pixels_iter == args.end()
                         ? nullptr
                         : std::get_if<std::vector<uint8_t>>(&pixels_iter->second);
  if (printer_name_utf8 == nullptr || printer_name_utf8->empty() ||
      source_width <= 0 || source_height <= 0 || page_width_mm <= 0 ||
      page_height_mm <= 0 || bgra == nullptr ||
      bgra->size() != static_cast<size_t>(source_width) * source_height * 4) {
    return PrintResult(false, {}, "invalid bitmap print arguments");
  }

  const std::wstring printer_name = Utf8ToWide(*printer_name_utf8);
  const std::wstring document_name = document_name_utf8 == nullptr
                                         ? L"ITSnG Label"
                                         : Utf8ToWide(*document_name_utf8);
  HANDLE printer = nullptr;
  if (!OpenPrinterW(const_cast<wchar_t*>(printer_name.c_str()), &printer,
                    nullptr)) {
    return PrintResult(false, {}, "OpenPrinterW failed: " +
                                      std::to_string(GetLastError()));
  }

  const LONG devmode_size = DocumentPropertiesW(
      nullptr, printer, const_cast<wchar_t*>(printer_name.c_str()), nullptr,
      nullptr, 0);
  if (devmode_size <= 0) {
    const DWORD error = GetLastError();
    ClosePrinter(printer);
    return PrintResult(false, {}, "DocumentPropertiesW size failed: " +
                                      std::to_string(error));
  }
  std::vector<uint8_t> devmode_storage(static_cast<size_t>(devmode_size));
  auto* devmode = reinterpret_cast<DEVMODEW*>(devmode_storage.data());
  if (DocumentPropertiesW(nullptr, printer,
                          const_cast<wchar_t*>(printer_name.c_str()), devmode,
                          nullptr, DM_OUT_BUFFER) != IDOK) {
    ClosePrinter(printer);
    return PrintResult(false, {}, "DocumentPropertiesW defaults failed");
  }
  devmode->dmFields |= DM_PAPERSIZE | DM_PAPERWIDTH | DM_PAPERLENGTH |
                       DM_ORIENTATION | DM_COPIES;
  devmode->dmPaperSize = 0;
  devmode->dmPaperWidth = static_cast<short>(page_width_mm * 10.0 + 0.5);
  devmode->dmPaperLength = static_cast<short>(page_height_mm * 10.0 + 0.5);
  devmode->dmOrientation = DMORIENT_PORTRAIT;
  devmode->dmCopies = 1;
  DocumentPropertiesW(nullptr, printer,
                      const_cast<wchar_t*>(printer_name.c_str()), devmode,
                      devmode, DM_IN_BUFFER | DM_OUT_BUFFER);
  ClosePrinter(printer);

  HDC printer_dc = CreateDCW(L"WINSPOOL", printer_name.c_str(), nullptr, devmode);
  if (printer_dc == nullptr) {
    return PrintResult(false, {},
                       "CreateDCW failed: " + std::to_string(GetLastError()));
  }

  const int dpi_x = GetDeviceCaps(printer_dc, LOGPIXELSX);
  const int dpi_y = GetDeviceCaps(printer_dc, LOGPIXELSY);
  const int target_width = std::max(
      1, static_cast<int>(page_width_mm * dpi_x / 25.4 + 0.5));
  const int target_height = std::max(
      1, static_cast<int>(page_height_mm * dpi_y / 25.4 + 0.5));
  std::ostringstream diagnostics;
  diagnostics << "printerDpi=" << dpi_x << "x" << dpi_y
              << " source=" << source_width << "x" << source_height
              << " target=" << target_width << "x" << target_height
              << " horzRes=" << GetDeviceCaps(printer_dc, HORZRES)
              << " vertRes=" << GetDeviceCaps(printer_dc, VERTRES)
              << " physical=" << GetDeviceCaps(printer_dc, PHYSICALWIDTH)
              << "x" << GetDeviceCaps(printer_dc, PHYSICALHEIGHT)
              << " offset=" << GetDeviceCaps(printer_dc, PHYSICALOFFSETX)
              << "," << GetDeviceCaps(printer_dc, PHYSICALOFFSETY)
              << " paperTenthMm=" << devmode->dmPaperWidth << "x"
              << devmode->dmPaperLength;

  DOCINFOW document_info{};
  document_info.cbSize = sizeof(DOCINFOW);
  document_info.lpszDocName = document_name.c_str();
  if (StartDocW(printer_dc, &document_info) <= 0) {
    const DWORD error = GetLastError();
    DeleteDC(printer_dc);
    return PrintResult(false, diagnostics.str(),
                       "StartDocW failed: " + std::to_string(error));
  }
  bool ok = false;
  std::string error;
  if (StartPage(printer_dc) <= 0) {
    error = "StartPage failed: " + std::to_string(GetLastError());
  } else {
    BITMAPINFO bitmap_info{};
    bitmap_info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bitmap_info.bmiHeader.biWidth = source_width;
    bitmap_info.bmiHeader.biHeight = -source_height;
    bitmap_info.bmiHeader.biPlanes = 1;
    bitmap_info.bmiHeader.biBitCount = 32;
    bitmap_info.bmiHeader.biCompression = BI_RGB;
    SetGraphicsMode(printer_dc, GM_ADVANCED);
    const int previous_mode = SetStretchBltMode(printer_dc, HALFTONE);
    SetBrushOrgEx(printer_dc, 0, 0, nullptr);
    const int scan_lines = StretchDIBits(
        printer_dc, 0, 0, target_width, target_height, 0, 0, source_width,
        source_height, bgra->data(), &bitmap_info, DIB_RGB_COLORS, SRCCOPY);
    diagnostics << " stretchModeBefore=" << previous_mode
                << " stretchLines=" << scan_lines;
    if (scan_lines == GDI_ERROR || scan_lines == 0) {
      error = "StretchDIBits failed: " + std::to_string(GetLastError());
    } else if (EndPage(printer_dc) <= 0) {
      error = "EndPage failed: " + std::to_string(GetLastError());
    } else {
      ok = true;
    }
  }
  if (ok) {
    if (EndDoc(printer_dc) <= 0) {
      ok = false;
      error = "EndDoc failed: " + std::to_string(GetLastError());
    }
  } else {
    AbortDoc(printer_dc);
  }
  DeleteDC(printer_dc);
  return PrintResult(ok, diagnostics.str(), error);
}

}  // namespace

void RegisterLabelBitmapPrintChannel(flutter::FlutterEngine* engine) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), "label_manager/bitmap_print",
      &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        if (call.method_name() != "printBitmap") {
          result->NotImplemented();
          return;
        }
        const auto* args = std::get_if<EncodableMap>(call.arguments());
        if (args == nullptr) {
          result->Error("invalid_arguments", "Expected argument map");
          return;
        }
        result->Success(PrintBitmap(*args));
      });
}
