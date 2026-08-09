#include "label_bitmap_print_channel.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <algorithm>
#include <cstring>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

namespace {

using EncodableMap = flutter::EncodableMap;
using EncodableList = flutter::EncodableList;
using EncodableValue = flutter::EncodableValue;

constexpr LONG kNativeTextRightOverhangDots = 1;

std::wstring Utf8ToWide(const std::string& value);

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

bool BoolArg(const EncodableMap& args, const char* key, bool fallback) {
  const auto iter = args.find(EncodableValue(key));
  if (iter == args.end()) return fallback;
  if (const auto* value = std::get_if<bool>(&iter->second)) return *value;
  return fallback;
}

int64_t Int64Arg(const EncodableMap& args, const char* key, int64_t fallback) {
  const auto iter = args.find(EncodableValue(key));
  if (iter == args.end()) return fallback;
  if (const auto* value = std::get_if<int32_t>(&iter->second)) return *value;
  if (const auto* value = std::get_if<int64_t>(&iter->second)) return *value;
  return fallback;
}

struct NativeTextDescriptor {
  std::wstring text;
  RECT rect{};
  std::wstring font_family;
  std::string font_family_utf8;
  int font_pixel_height = 0;
  bool bold = false;
  bool italic = false;
  bool underline = false;
  bool strike_through = false;
  COLORREF color = RGB(0, 0, 0);
  std::string horizontal_align;
  std::string vertical_align;
  bool wrap = false;
};

struct NativeBorderDescriptor {
  RECT rect{};
  bool horizontal = false;
  int thickness_dots = 1;
};

struct DeviceBorderRect {
  RECT rect{};
  bool horizontal = false;
  int segment_count = 1;
};

std::vector<uint8_t> ComposeFinalDeviceBitmap(
    const std::vector<uint8_t>& source, int source_width, int source_height,
    int target_width, int target_height,
    const std::vector<NativeBorderDescriptor>& border_descriptors) {
  std::vector<uint8_t> result(
      static_cast<size_t>(target_width) * target_height * 4, 0xFF);
  for (int target_y = 0; target_y < target_height; ++target_y) {
    const int source_y = std::min(
        source_height - 1,
        ((target_y * 2 + 1) * source_height) / (target_height * 2));
    for (int target_x = 0; target_x < target_width; ++target_x) {
      const int source_x = std::min(
          source_width - 1,
          ((target_x * 2 + 1) * source_width) / (target_width * 2));
      const size_t source_offset =
          (static_cast<size_t>(source_y) * source_width + source_x) * 4;
      const size_t target_offset =
          (static_cast<size_t>(target_y) * target_width + target_x) * 4;
      result[target_offset] = source[source_offset];
      result[target_offset + 1] = source[source_offset + 1];
      result[target_offset + 2] = source[source_offset + 2];
    }
  }
  std::vector<DeviceBorderRect> device_borders;
  device_borders.reserve(border_descriptors.size());
  for (const auto& descriptor : border_descriptors) {
    const LONG left = MulDiv(descriptor.rect.left, target_width, source_width);
    const LONG top = MulDiv(descriptor.rect.top, target_height, source_height);
    const LONG mapped_right =
        MulDiv(descriptor.rect.right, target_width, source_width);
    const LONG mapped_bottom =
        MulDiv(descriptor.rect.bottom, target_height, source_height);
    const LONG thickness = std::max(
        1L, static_cast<LONG>(MulDiv(
                descriptor.thickness_dots,
                descriptor.horizontal ? target_height : target_width,
                descriptor.horizontal ? source_height : source_width)));
    RECT rect{};
    if (descriptor.horizontal) {
      rect.left = left;
      rect.top = top - thickness / 2;
      rect.right = std::max(left + 1, mapped_right);
      rect.bottom = rect.top + thickness;
    } else {
      rect.left = left - thickness / 2;
      rect.top = top;
      rect.right = rect.left + thickness;
      rect.bottom = std::max(top + 1, mapped_bottom);
    }
    device_borders.push_back(DeviceBorderRect{rect, descriptor.horizontal, 1});
  }
  for (const auto& border : device_borders) {
    const RECT& rect = border.rect;
    const int clipped_left = std::clamp<int>(rect.left, 0, target_width);
    const int clipped_top = std::clamp<int>(rect.top, 0, target_height);
    const int clipped_right = std::clamp<int>(rect.right, 0, target_width);
    const int clipped_bottom = std::clamp<int>(rect.bottom, 0, target_height);
    for (int y = clipped_top; y < clipped_bottom; ++y) {
      for (int x = clipped_left; x < clipped_right; ++x) {
        const size_t offset =
            (static_cast<size_t>(y) * target_width + x) * 4;
        result[offset] = 0;
        result[offset + 1] = 0;
        result[offset + 2] = 0;
      }
    }
  }
  return result;
}

std::vector<NativeBorderDescriptor> BorderDescriptorsArg(
    const EncodableMap& args) {
  const auto iter = args.find(EncodableValue("borderDescriptors"));
  const auto* values = iter == args.end()
                           ? nullptr
                           : std::get_if<EncodableList>(&iter->second);
  if (values == nullptr) return {};
  std::vector<NativeBorderDescriptor> descriptors;
  descriptors.reserve(values->size());
  for (const auto& value : *values) {
    const auto* map = std::get_if<EncodableMap>(&value);
    if (map == nullptr) continue;
    NativeBorderDescriptor descriptor;
    descriptor.horizontal = BoolArg(*map, "horizontal", false);
    descriptor.thickness_dots =
      std::max(1, IntArg(*map, "thicknessDots", 1));
    descriptor.rect.left = IntArg(*map, "left", 0);
    descriptor.rect.top = IntArg(*map, "top", 0);
    descriptor.rect.right = IntArg(*map, "right", 0);
    descriptor.rect.bottom = IntArg(*map, "bottom", 0);
    if (descriptor.rect.right > descriptor.rect.left &&
        descriptor.rect.bottom > descriptor.rect.top) {
      descriptors.push_back(descriptor);
    }
  }
  return descriptors;
}

std::vector<NativeTextDescriptor> TextDescriptorsArg(
    const EncodableMap& args) {
  const auto iter = args.find(EncodableValue("textDescriptors"));
  const auto* values = iter == args.end()
                           ? nullptr
                           : std::get_if<EncodableList>(&iter->second);
  if (values == nullptr) return {};
  std::vector<NativeTextDescriptor> descriptors;
  descriptors.reserve(values->size());
  for (const auto& value : *values) {
    const auto* map = std::get_if<EncodableMap>(&value);
    if (map == nullptr) continue;
    const auto* text = StringArg(*map, "text");
    const auto* font_family = StringArg(*map, "fontFamily");
    const auto* horizontal_align = StringArg(*map, "horizontalAlign");
    const auto* vertical_align = StringArg(*map, "verticalAlign");
    NativeTextDescriptor descriptor;
    descriptor.text = text == nullptr ? std::wstring() : Utf8ToWide(*text);
    descriptor.rect.left = IntArg(*map, "left", 0);
    descriptor.rect.top = IntArg(*map, "top", 0);
    descriptor.rect.right = IntArg(*map, "right", 0);
    descriptor.rect.bottom = IntArg(*map, "bottom", 0);
    descriptor.font_family = font_family == nullptr
                                 ? L"Malgun Gothic"
                                 : Utf8ToWide(*font_family);
    descriptor.font_family_utf8 = font_family == nullptr
                      ? "Malgun Gothic"
                      : *font_family;
    descriptor.font_pixel_height = IntArg(*map, "fontPixelHeight", 0);
    descriptor.bold = BoolArg(*map, "bold", false);
    descriptor.italic = BoolArg(*map, "italic", false);
    descriptor.underline = BoolArg(*map, "underline", false);
    descriptor.strike_through = BoolArg(*map, "strikeThrough", false);
    const uint32_t argb = static_cast<uint32_t>(
        Int64Arg(*map, "colorArgb", 0xff000000));
    descriptor.color = RGB((argb >> 16) & 0xff, (argb >> 8) & 0xff,
                           argb & 0xff);
    descriptor.horizontal_align = horizontal_align == nullptr
                                      ? std::string()
                                      : *horizontal_align;
    descriptor.vertical_align = vertical_align == nullptr
                                    ? std::string()
                                    : *vertical_align;
    descriptor.wrap = BoolArg(*map, "wrap", false);
    if (!descriptor.text.empty() && descriptor.font_pixel_height > 0 &&
        descriptor.rect.right > descriptor.rect.left &&
        descriptor.rect.bottom > descriptor.rect.top) {
      descriptors.push_back(std::move(descriptor));
    }
  }
  return descriptors;
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

struct NativeTextRenderStats {
  int drawn = 0;
  int failed = 0;
  int fitted = 0;
  int outline_fonts = 0;
  int no_outline_fonts = 0;
  size_t bitmap_changed_pixels = 0;
  size_t characters = 0;
};

bool RenderNativeTextIntoBitmap(
    std::vector<uint8_t>& bitmap, int target_width, int target_height,
    int source_width, int source_height,
    const std::vector<NativeTextDescriptor>& text_descriptors,
    NativeTextRenderStats& stats, std::string& error) {
  if (text_descriptors.empty()) return true;
  BITMAPINFO bitmap_info{};
  bitmap_info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bitmap_info.bmiHeader.biWidth = target_width;
  bitmap_info.bmiHeader.biHeight = -target_height;
  bitmap_info.bmiHeader.biPlanes = 1;
  bitmap_info.bmiHeader.biBitCount = 32;
  bitmap_info.bmiHeader.biCompression = BI_RGB;
  HDC memory_dc = CreateCompatibleDC(nullptr);
  if (memory_dc == nullptr) {
    error = "CreateCompatibleDC for native text failed: " +
            std::to_string(GetLastError());
    return false;
  }
  void* dib_bits = nullptr;
  HBITMAP dib = CreateDIBSection(memory_dc, &bitmap_info, DIB_RGB_COLORS,
                                 &dib_bits, nullptr, 0);
  if (dib == nullptr || dib_bits == nullptr) {
    error = "CreateDIBSection for native text failed: " +
            std::to_string(GetLastError());
    if (dib != nullptr) DeleteObject(dib);
    DeleteDC(memory_dc);
    return false;
  }
  HGDIOBJ previous_bitmap = SelectObject(memory_dc, dib);
  std::memcpy(dib_bits, bitmap.data(), bitmap.size());
  SetMapMode(memory_dc, MM_ANISOTROPIC);
  SetWindowExtEx(memory_dc, source_width, source_height, nullptr);
  SetViewportExtEx(memory_dc, target_width, target_height, nullptr);
  SetViewportOrgEx(memory_dc, 0, 0, nullptr);
  const int previous_background_mode = SetBkMode(memory_dc, TRANSPARENT);
  for (const auto& descriptor : text_descriptors) {
    const int font_pixel_height = std::max(1, descriptor.font_pixel_height);
    HFONT font = CreateFontW(
        -font_pixel_height, 0, 0, 0,
        descriptor.bold ? FW_BOLD : FW_NORMAL, descriptor.italic,
        descriptor.underline, descriptor.strike_through, DEFAULT_CHARSET,
        OUT_TT_ONLY_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
        DEFAULT_PITCH | FF_DONTCARE, descriptor.font_family.c_str());
    if (font == nullptr) {
      ++stats.failed;
      continue;
    }
    HGDIOBJ previous_font = SelectObject(memory_dc, font);
    if (previous_font == nullptr || previous_font == HGDI_ERROR) {
      DeleteObject(font);
      ++stats.failed;
      continue;
    }
    if (GetFontData(memory_dc, 0, 0, nullptr, 0) == GDI_ERROR) {
      ++stats.no_outline_fonts;
    } else {
      ++stats.outline_fonts;
    }
    const COLORREF previous_color = SetTextColor(memory_dc, descriptor.color);
    RECT text_rect{
        descriptor.rect.left,
        descriptor.rect.top,
        descriptor.rect.right,
        descriptor.rect.bottom,
    };
    UINT flags = DT_NOPREFIX | DT_EDITCONTROL;
    if (descriptor.horizontal_align == "0") {
      flags |= DT_CENTER;
    } else if (descriptor.horizontal_align == "2") {
      flags |= DT_RIGHT;
    } else {
      flags |= DT_LEFT;
    }
    flags |= descriptor.wrap ? DT_WORDBREAK : DT_SINGLELINE;
    RECT measured = text_rect;
    DrawTextW(memory_dc, descriptor.text.c_str(),
              static_cast<int>(descriptor.text.size()), &measured,
              flags | DT_CALCRECT);
    HFONT fitted_font = nullptr;
    const LONG available_width = text_rect.right - text_rect.left;
    const LONG measured_width = measured.right - measured.left;
    if (!descriptor.wrap && measured_width > available_width &&
        available_width > 0) {
      LOGFONTW log_font{};
      if (GetObjectW(font, sizeof(log_font), &log_font) != 0) {
        const LONG desired_width = std::max(1L, available_width - 2);
        int fitted_height = std::max(
            1, MulDiv(font_pixel_height, desired_width, measured_width));
        for (int attempt = 0; attempt < 4; ++attempt) {
          log_font.lfHeight = -fitted_height;
          log_font.lfWidth = 0;
          HFONT next_fitted_font = CreateFontIndirectW(&log_font);
          if (next_fitted_font == nullptr) break;
          SelectObject(memory_dc, next_fitted_font);
          if (fitted_font != nullptr) DeleteObject(fitted_font);
          fitted_font = next_fitted_font;
          measured = text_rect;
          DrawTextW(memory_dc, descriptor.text.c_str(),
                    static_cast<int>(descriptor.text.size()), &measured,
                    flags | DT_CALCRECT);
          const LONG fitted_measured_width = measured.right - measured.left;
          if (fitted_measured_width <= desired_width) break;
          const int next_height = std::max(
              1, MulDiv(fitted_height, desired_width,
                        fitted_measured_width));
          fitted_height = next_height < fitted_height
                              ? next_height
                              : std::max(1, fitted_height - 1);
        }
        if (fitted_font != nullptr) ++stats.fitted;
      }
    }
    const LONG text_height = measured.bottom - measured.top;
    if (descriptor.vertical_align == "2") {
      text_rect.top = std::max(text_rect.top, text_rect.bottom - text_height);
    } else if (descriptor.vertical_align != "1") {
      text_rect.top += std::max<LONG>(
          0, (text_rect.bottom - text_rect.top - text_height) / 2);
    }
    text_rect.right += kNativeTextRightOverhangDots;
    const int draw_result = DrawTextW(
        memory_dc, descriptor.text.c_str(),
        static_cast<int>(descriptor.text.size()), &text_rect, flags);
    if (draw_result > 0) {
      ++stats.drawn;
      stats.characters += descriptor.text.size();
    } else {
      ++stats.failed;
    }
    SetTextColor(memory_dc, previous_color);
    SelectObject(memory_dc, previous_font);
    if (fitted_font != nullptr) DeleteObject(fitted_font);
    DeleteObject(font);
  }
  GdiFlush();
  const auto* rendered = static_cast<const uint8_t*>(dib_bits);
  for (size_t offset = 0; offset < bitmap.size(); offset += 4) {
    if (bitmap[offset] != rendered[offset] ||
        bitmap[offset + 1] != rendered[offset + 1] ||
        bitmap[offset + 2] != rendered[offset + 2]) {
      ++stats.bitmap_changed_pixels;
    }
  }
  std::memcpy(bitmap.data(), dib_bits, bitmap.size());
  SetBkMode(memory_dc, previous_background_mode);
  SelectObject(memory_dc, previous_bitmap);
  DeleteObject(dib);
  DeleteDC(memory_dc);
  return true;
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
  const int copies = std::max(1, IntArg(args, "copies", 1));
  const double width_append_mm =
      std::max(0.0, DoubleArg(args, "widthAppendMm", 0));
  const auto* legacy_printer_type_arg =
      StringArg(args, "legacyPrinterType");
  const std::string legacy_printer_type = legacy_printer_type_arg == nullptr
                                              ? "other"
                                              : *legacy_printer_type_arg;
  const bool bixolon = legacy_printer_type == "bixolon";
  const bool citizen = legacy_printer_type == "citizen";
  const auto pixels_iter = args.find(EncodableValue("bgra"));
  const auto text_descriptors = TextDescriptorsArg(args);
  const auto border_descriptors = BorderDescriptorsArg(args);
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
  devmode->dmPaperSize = DMPAPER_USER;
  const int legacy_citizen_tenth_mm =
      citizen ? static_cast<int>(page_width_mm * 0.2) : 0;
  devmode->dmPaperWidth = static_cast<short>(
      (page_width_mm + width_append_mm) * 10.0 +
      legacy_citizen_tenth_mm + 0.5);
  devmode->dmPaperLength = static_cast<short>(page_height_mm * 10.0 + 0.5);
  devmode->dmOrientation = DMORIENT_PORTRAIT;
  devmode->dmCopies = static_cast<short>(bixolon ? 1 : copies);
  if (DocumentPropertiesW(nullptr, printer,
                          const_cast<wchar_t*>(printer_name.c_str()), devmode,
                          devmode, DM_IN_BUFFER | DM_OUT_BUFFER) != IDOK) {
    ClosePrinter(printer);
    return PrintResult(false, {}, "DocumentPropertiesW apply failed");
  }
  ClosePrinter(printer);

  HDC printer_dc = CreateDCW(L"WINSPOOL", printer_name.c_str(), nullptr, devmode);
  if (printer_dc == nullptr) {
    return PrintResult(false, {},
                       "CreateDCW failed: " + std::to_string(GetLastError()));
  }

  const int dpi_x = GetDeviceCaps(printer_dc, LOGPIXELSX);
  const int dpi_y = GetDeviceCaps(printer_dc, LOGPIXELSY);
  const int physical_width = GetDeviceCaps(printer_dc, PHYSICALWIDTH);
  const int physical_height = GetDeviceCaps(printer_dc, PHYSICALHEIGHT);
  const int physical_offset_x = GetDeviceCaps(printer_dc, PHYSICALOFFSETX);
  const int physical_offset_y = GetDeviceCaps(printer_dc, PHYSICALOFFSETY);
    const int printable_width = GetDeviceCaps(printer_dc, HORZRES);
    const int printable_height = GetDeviceCaps(printer_dc, VERTRES);
    const int requested_target_width =
      dpi_x > 0
        ? static_cast<int>(page_width_mm * dpi_x / 25.4 + 0.5)
        : source_width;
    const int requested_target_height =
      dpi_y > 0
        ? static_cast<int>(page_height_mm * dpi_y / 25.4 + 0.5)
        : source_height;
    const int target_width = printable_width > 0
      ? std::min(requested_target_width, printable_width)
      : requested_target_width;
    const int target_height = printable_height > 0
      ? std::min(requested_target_height, printable_height)
      : requested_target_height;
    // 음수 physical offset은 양쪽 비인쇄 영역만 잘라내므로 재사용하지 않는다.
    // 전체 라벨을 printable DC에 맞춰 bitmap과 native text를 함께 축소한다.
    const int destination_x = 0;
    const int destination_y = 0;
  size_t native_text_requested_characters = 0;
  int native_text_min_height = 0;
  int native_text_max_height = 0;
  std::vector<std::string> native_text_fonts;
  for (const auto& descriptor : text_descriptors) {
    native_text_requested_characters += descriptor.text.size();
    native_text_min_height = native_text_min_height == 0
                                 ? descriptor.font_pixel_height
                                 : std::min(native_text_min_height,
                                            descriptor.font_pixel_height);
    native_text_max_height = std::max(native_text_max_height,
                                      descriptor.font_pixel_height);
    if (std::find(native_text_fonts.begin(), native_text_fonts.end(),
                  descriptor.font_family_utf8) == native_text_fonts.end()) {
      native_text_fonts.push_back(descriptor.font_family_utf8);
    }
  }
  std::ostringstream diagnostics;
  diagnostics << "printerDpi=" << dpi_x << "x" << dpi_y
              << " source=" << source_width << "x" << source_height
              << " requestedTarget=" << requested_target_width << "x"
              << requested_target_height
              << " target=" << target_width << "x" << target_height
              << " scale=" << static_cast<double>(target_width) / source_width
              << "x" << static_cast<double>(target_height) / source_height
              << " horzRes=" << printable_width
              << " vertRes=" << printable_height
              << " physical=" << physical_width << "x" << physical_height
              << " offset=" << physical_offset_x << "," << physical_offset_y
              << " destination=" << destination_x << "," << destination_y
              << " paperTenthMm=" << devmode->dmPaperWidth << "x"
              << devmode->dmPaperLength
              << " legacyType=" << legacy_printer_type
              << " copies=" << copies
              << " devmodeCopies=" << devmode->dmCopies
              << " widthAppendMm=" << width_append_mm
              << " nativeTextRequested=" << text_descriptors.size()
              << " nativeBordersRequested=" << border_descriptors.size()
              << " nativeTextRequestedCharacters="
              << native_text_requested_characters
              << " nativeTextHeight=" << native_text_min_height << ".."
              << native_text_max_height
              << " fontQuality=DEFAULT_QUALITY"
              << " fontOutputPrecision=OUT_TT_ONLY_PRECIS"
              << " nativeTextFitMode=uniformScale"
              << " nativeTextFonts=";
  for (size_t index = 0; index < native_text_fonts.size(); ++index) {
    if (index > 0) diagnostics << "|";
    diagnostics << native_text_fonts[index];
  }

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
  const int page_iterations = bixolon ? copies : 1;
  for (int page_index = 0; page_index < page_iterations && error.empty();
       ++page_index) {
    if (StartPage(printer_dc) <= 0) {
      error = "StartPage failed: " + std::to_string(GetLastError());
      break;
    }
    auto composed_bitmap = ComposeFinalDeviceBitmap(
        *bgra, source_width, source_height, target_width, target_height,
        border_descriptors);
    NativeTextRenderStats native_text_stats;
    if (!RenderNativeTextIntoBitmap(
            composed_bitmap, target_width, target_height, source_width,
            source_height, text_descriptors, native_text_stats, error)) {
      break;
    }
    BITMAPINFO bitmap_info{};
    bitmap_info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bitmap_info.bmiHeader.biWidth = target_width;
    bitmap_info.bmiHeader.biHeight = -target_height;
    bitmap_info.bmiHeader.biPlanes = 1;
    bitmap_info.bmiHeader.biBitCount = 32;
    bitmap_info.bmiHeader.biCompression = BI_RGB;
    const int previous_mode = SetStretchBltMode(printer_dc, COLORONCOLOR);
    const int scan_lines = StretchDIBits(
        printer_dc, destination_x, destination_y, target_width, target_height,
        0, 0, target_width, target_height, composed_bitmap.data(),
        &bitmap_info, DIB_RGB_COLORS, SRCCOPY);
    diagnostics << " stretchModeBefore=" << previous_mode
                << " stretchMode=COLORONCOLOR_1TO1"
                << " sourceRasterResample=nearestCenter"
                << " sourceBpp=" << bitmap_info.bmiHeader.biBitCount
                << " compression=BI_RGB"
                << " rasterOp=SRCCOPY"
                << " stretchLines=" << scan_lines;
    if (scan_lines == GDI_ERROR || scan_lines == 0) {
      error = "StretchDIBits failed: " + std::to_string(GetLastError());
    } else {
      int native_borders_drawn = 0;
      int native_border_fill_rects = 0;
      std::vector<DeviceBorderRect> device_borders;
      device_borders.reserve(border_descriptors.size());
      for (const auto& descriptor : border_descriptors) {
        const LONG left = destination_x +
            MulDiv(descriptor.rect.left, target_width, source_width);
        const LONG top = destination_y +
            MulDiv(descriptor.rect.top, target_height, source_height);
        const LONG mapped_right = destination_x +
            MulDiv(descriptor.rect.right, target_width, source_width);
        const LONG mapped_bottom = destination_y +
            MulDiv(descriptor.rect.bottom, target_height, source_height);
        const LONG thickness = std::max(
            1L, static_cast<LONG>(MulDiv(
                    descriptor.thickness_dots,
                    descriptor.horizontal ? target_height : target_width,
                    descriptor.horizontal ? source_height : source_width)));
        RECT device_rect{};
        if (descriptor.horizontal) {
          device_rect.left = left;
          device_rect.top = top - thickness / 2;
          device_rect.right = std::max(left + 1, mapped_right);
          device_rect.bottom = device_rect.top + thickness;
        } else {
          device_rect.left = left - thickness / 2;
          device_rect.top = top;
          device_rect.right = device_rect.left + thickness;
          device_rect.bottom = std::max(top + 1, mapped_bottom);
        }
        device_borders.push_back(
            DeviceBorderRect{device_rect, descriptor.horizontal, 1});
      }
      std::sort(
          device_borders.begin(), device_borders.end(),
          [](const DeviceBorderRect& left, const DeviceBorderRect& right) {
            if (left.horizontal != right.horizontal) {
              return left.horizontal < right.horizontal;
            }
            if (left.horizontal) {
              if (left.rect.top != right.rect.top) {
                return left.rect.top < right.rect.top;
              }
              if (left.rect.bottom != right.rect.bottom) {
                return left.rect.bottom < right.rect.bottom;
              }
              if (left.rect.left != right.rect.left) {
                return left.rect.left < right.rect.left;
              }
              return left.rect.right < right.rect.right;
            }
            if (left.rect.left != right.rect.left) {
              return left.rect.left < right.rect.left;
            }
            if (left.rect.right != right.rect.right) {
              return left.rect.right < right.rect.right;
            }
            if (left.rect.top != right.rect.top) {
              return left.rect.top < right.rect.top;
            }
            return left.rect.bottom < right.rect.bottom;
          });
      std::vector<DeviceBorderRect> merged_device_borders;
      merged_device_borders.reserve(device_borders.size());
      for (const auto& border : device_borders) {
        if (!merged_device_borders.empty()) {
          auto& previous = merged_device_borders.back();
          const bool same_axis = previous.horizontal == border.horizontal;
          const bool can_merge = previous.horizontal
              ? same_axis && previous.rect.top == border.rect.top &&
                    previous.rect.bottom == border.rect.bottom &&
                    border.rect.left <= previous.rect.right
              : same_axis && previous.rect.left == border.rect.left &&
                    previous.rect.right == border.rect.right &&
                    border.rect.top <= previous.rect.bottom;
          if (can_merge) {
            previous.rect.right =
                std::max(previous.rect.right, border.rect.right);
            previous.rect.bottom =
                std::max(previous.rect.bottom, border.rect.bottom);
            previous.segment_count += border.segment_count;
            continue;
          }
        }
        merged_device_borders.push_back(border);
      }
      native_borders_drawn = static_cast<int>(border_descriptors.size());
      native_border_fill_rects =
          static_cast<int>(merged_device_borders.size());
      diagnostics << " nativeTextDrawn=" << native_text_stats.drawn
                  << " nativeTextFailed=" << native_text_stats.failed
                  << " nativeTextFitted=" << native_text_stats.fitted
                  << " nativeTextOutlineFonts="
                  << native_text_stats.outline_fonts
                  << " nativeTextNoOutlineFonts="
                  << native_text_stats.no_outline_fonts
                  << " nativeTextBitmapChangedPixels="
                  << native_text_stats.bitmap_changed_pixels
                  << " nativeTextCharacters=" << native_text_stats.characters
                  << " nativeTextMapping=anisotropicMemoryDib"
                  << " nativeTextComposite=finalDeviceBitmap"
                  << " nativeBorderMapping=devicePixels"
                  << " nativeBorderThickness=oneDeviceDot"
                  << " nativeBorderJunction=singleFinalDeviceBitmap"
                  << " nativeBorderComposite=finalDeviceBitmap"
                  << " nativeBorderBitmapLines=" << scan_lines
                  << " nativeBorderFillRects=" << native_border_fill_rects
                  << " nativeBordersDrawn=" << native_borders_drawn;
      if (native_text_stats.failed > 0) {
        error = "Native text rendering failed: " +
                std::to_string(native_text_stats.failed);
      }
    }
    if (error.empty() && EndPage(printer_dc) <= 0) {
      error = "EndPage failed: " + std::to_string(GetLastError());
    }
  }
  ok = error.empty();
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
