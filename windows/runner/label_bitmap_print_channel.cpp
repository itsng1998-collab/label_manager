#include "label_bitmap_print_channel.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <richedit.h>
#include <windows.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_SYNTHESIS_H

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

namespace {

using EncodableMap = flutter::EncodableMap;
using EncodableList = flutter::EncodableList;
using EncodableValue = flutter::EncodableValue;

constexpr LONG kNativeTextRightOverhangDots = 1;
constexpr int kInverseMinimumFontDots = 20;
constexpr wchar_t kPrintTestWatermark[] = L"v1.3.93";

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
  bool preserve_height_fit = false;
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

struct InverseCoolingStats {
  int inverse_rects = 0;
  size_t pixels_modified = 0;
};

#if 0
// v1.3.89 changed 22,230 inverse background pixels to RGB 96, but the G500
// driver converted them to a coarse pattern that made the white text worse.
InverseCoolingStats ApplyInverseDriverGray(
    std::vector<uint8_t>& bitmap, int target_width, int target_height,
    int source_width, int source_height,
    const std::vector<NativeTextDescriptor>& text_descriptors) {
  InverseCoolingStats stats;
  constexpr uint8_t kDriverGray = 96;
  for (const auto& descriptor : text_descriptors) {
    if (descriptor.color != RGB(255, 255, 255)) continue;
    ++stats.inverse_rects;
    const RECT rect{
        std::clamp(MulDiv(descriptor.rect.left, target_width, source_width),
                   0, target_width),
        std::clamp(MulDiv(descriptor.rect.top, target_height, source_height),
                   0, target_height),
        std::clamp(MulDiv(descriptor.rect.right, target_width, source_width),
                   0, target_width),
        std::clamp(MulDiv(descriptor.rect.bottom, target_height, source_height),
                   0, target_height),
    };
    for (int y = rect.top; y < rect.bottom; ++y) {
      for (int x = rect.left; x < rect.right; ++x) {
        const size_t offset =
            (static_cast<size_t>(y) * target_width + x) * 4;
        if (bitmap[offset] != 0 || bitmap[offset + 1] != 0 ||
            bitmap[offset + 2] != 0) {
          continue;
        }
        bitmap[offset] = kDriverGray;
        bitmap[offset + 1] = kDriverGray;
        bitmap[offset + 2] = kDriverGray;
        ++stats.pixels_modified;
      }
    }
  }
  return stats;
}
#endif

#if 0
// v1.3.75 physical output changed 4,740 black pixels but did not recover
// inverse Korean strokes. Keep the failed cooling experiment retired.
InverseCoolingStats ApplyInverseBackgroundCoolingPattern(
    void* mono_bits, int target_width, int target_height,
    int source_width, int source_height,
    const std::vector<NativeTextDescriptor>& text_descriptors) {
  InverseCoolingStats stats;
  const int stride = ((target_width + 31) / 32) * 4;
  auto* pixels = static_cast<uint8_t*>(mono_bits);
  for (const auto& descriptor : text_descriptors) {
    if (descriptor.color != RGB(255, 255, 255)) continue;
    ++stats.inverse_rects;
    const RECT rect{
        std::clamp(MulDiv(descriptor.rect.left, target_width, source_width),
                   0, target_width),
        std::clamp(MulDiv(descriptor.rect.top, target_height, source_height),
                   0, target_height),
        std::clamp(MulDiv(descriptor.rect.right, target_width, source_width),
                   0, target_width),
        std::clamp(MulDiv(descriptor.rect.bottom, target_height, source_height),
                   0, target_height),
    };
    for (int y = rect.top; y < rect.bottom; ++y) {
      for (int x = rect.left; x < rect.right; ++x) {
        if ((x & 1) != 0 || (y & 1) != 0) continue;
        uint8_t& value = pixels[static_cast<size_t>(y) * stride + x / 8];
        const uint8_t mask = static_cast<uint8_t>(0x80u >> (x & 7));
        if ((value & mask) == 0) continue;
        value = static_cast<uint8_t>(value & ~mask);
        ++stats.pixels_modified;
      }
    }
  }
  return stats;
}
#endif

struct InversePolarityFallbackStats {
  int panel_rects = 0;
};

#if 0
// v1.3.76 proved that changing inverse text to a local white panel did not
// solve the broken Korean strokes and also changed the intended design.
std::vector<NativeTextDescriptor> PrepareInversePolarityFallback(
    HDC page_dc, int target_width, int target_height, int source_width,
    int source_height,
    const std::vector<NativeTextDescriptor>& text_descriptors,
    InversePolarityFallbackStats& stats) {
  auto fallback_descriptors = text_descriptors;
  for (auto& descriptor : fallback_descriptors) {
    if (descriptor.color != RGB(255, 255, 255)) continue;
    RECT panel_rect{
        std::max(0, MulDiv(descriptor.rect.left, target_width, source_width) - 1),
        std::max(0, MulDiv(descriptor.rect.top, target_height, source_height) - 1),
        std::min(target_width,
                 MulDiv(descriptor.rect.right, target_width, source_width) + 1),
        std::min(target_height,
                 MulDiv(descriptor.rect.bottom, target_height, source_height) + 1),
    };
    FillRect(page_dc, &panel_rect,
             reinterpret_cast<HBRUSH>(GetStockObject(WHITE_BRUSH)));
    descriptor.color = RGB(0, 0, 0);
    ++stats.panel_rects;
  }
  return fallback_descriptors;
}
#endif

struct InverseReadabilityStats {
  int descriptors = 0;
};

#if 0
// v1.3.77 applied 20-dot height-preserving width fit to both inverse rows,
// but the physical print still lost the same Korean strokes.
std::vector<NativeTextDescriptor> PrepareInverseReadabilityDescriptors(
    int source_height,
    const std::vector<NativeTextDescriptor>& text_descriptors,
    InverseReadabilityStats& stats) {
  auto readability_descriptors = text_descriptors;
  for (auto& descriptor : readability_descriptors) {
    if (descriptor.color != RGB(255, 255, 255)) continue;
    const int growth = std::max(
        0, kInverseMinimumFontDots - descriptor.font_pixel_height);
    descriptor.rect.top = std::max<LONG>(0, descriptor.rect.top - (growth + 1) / 2);
    descriptor.rect.bottom = std::min<LONG>(
        source_height, descriptor.rect.bottom + growth / 2);
    descriptor.font_pixel_height =
        std::max(kInverseMinimumFontDots, descriptor.font_pixel_height);
    descriptor.preserve_height_fit = true;
    ++stats.descriptors;
  }
  return readability_descriptors;
}
#endif

struct InverseRowFallbackStats {
  int descriptors = 0;
  int bands = 0;
  size_t cleared_pixels = 0;
};

std::vector<NativeTextDescriptor> PrepareInverseRowFallback(
    HDC page_dc, const std::vector<uint8_t>& bitmap, int target_width,
    int target_height, int source_width, int source_height,
    const std::vector<NativeTextDescriptor>& text_descriptors,
    InverseRowFallbackStats& stats) {
  auto fallback_descriptors = text_descriptors;
  std::vector<RECT> cleared_bands;
  const auto row_is_black_band = [&](int y) {
    int dark_pixels = 0;
    for (int x = 0; x < target_width; ++x) {
      const size_t offset =
          (static_cast<size_t>(y) * target_width + x) * 4;
      if (bitmap[offset] < 128 && bitmap[offset + 1] < 128 &&
          bitmap[offset + 2] < 128) {
        ++dark_pixels;
      }
    }
    return dark_pixels * 5 >= target_width * 3;
  };
  for (auto& descriptor : fallback_descriptors) {
    if (descriptor.color != RGB(255, 255, 255)) continue;
    ++stats.descriptors;
    descriptor.color = RGB(0, 0, 0);
    const int center_y = std::clamp(
        MulDiv((descriptor.rect.top + descriptor.rect.bottom) / 2,
               target_height, source_height),
        0, target_height - 1);
    const bool already_cleared = std::any_of(
        cleared_bands.begin(), cleared_bands.end(),
        [center_y](const RECT& band) {
          return center_y >= band.top && center_y < band.bottom;
        });
    if (already_cleared || !row_is_black_band(center_y)) continue;
    int top = center_y;
    int bottom = center_y + 1;
    while (top > 0 && row_is_black_band(top - 1)) --top;
    while (bottom < target_height && row_is_black_band(bottom)) ++bottom;
    RECT band{0, top, target_width, bottom};
    FillRect(page_dc, &band,
             reinterpret_cast<HBRUSH>(GetStockObject(WHITE_BRUSH)));
    FrameRect(page_dc, &band,
              reinterpret_cast<HBRUSH>(GetStockObject(BLACK_BRUSH)));
    cleared_bands.push_back(band);
    ++stats.bands;
    stats.cleared_pixels +=
        static_cast<size_t>(target_width) * (bottom - top);
  }
  return fallback_descriptors;
}

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
  int inverse_width_fitted = 0;
  int white_bitmap_drawn = 0;
  size_t white_knockout_pixels = 0;
  size_t white_glyph_bitmaps = 0;
  int outline_fonts = 0;
  int no_outline_fonts = 0;
  size_t bitmap_changed_pixels = 0;
  size_t characters = 0;
};

bool ResolveWindowsFontFile(const std::wstring& family,
                            std::string& path, FT_Long& face_index) {
  if (family != L"굴림" && family != L"Gulim" && family != L"굴림체" &&
      family != L"GulimChe" && family != L"돋움" && family != L"Dotum" &&
      family != L"돋움체" && family != L"DotumChe") {
    return false;
  }
  if (family == L"굴림체" || family == L"GulimChe") {
    face_index = 1;
  } else if (family == L"돋움" || family == L"Dotum") {
    face_index = 2;
  } else if (family == L"돋움체" || family == L"DotumChe") {
    face_index = 3;
  } else {
    face_index = 0;
  }
  char windows_directory[MAX_PATH]{};
  const UINT length = GetWindowsDirectoryA(windows_directory, MAX_PATH);
  if (length == 0 || length >= MAX_PATH) return false;
  path = std::string(windows_directory, length) + "\\Fonts\\gulim.ttc";
  return GetFileAttributesA(path.c_str()) != INVALID_FILE_ATTRIBUTES;
}

#if 0
// Retired after the v1.3.62 physical print lost substantially more white
// glyph pixels than the prior renderer. Keep it isolated from future reuse.
class BilevelTextRenderer final : public IDWriteTextRenderer {
 public:
  BilevelTextRenderer(IDWriteFactory* factory, int width, int height,
                      std::vector<uint8_t>* mask)
      : factory_(factory), width_(width), height_(height), mask_(mask) {
    factory_->AddRef();
  }

  ~BilevelTextRenderer() { factory_->Release(); }

  IFACEMETHOD(QueryInterface)(REFIID iid, void** object) override {
    if (object == nullptr) return E_POINTER;
    *object = nullptr;
    if (iid == __uuidof(IUnknown) || iid == __uuidof(IDWritePixelSnapping) ||
        iid == __uuidof(IDWriteTextRenderer)) {
      *object = static_cast<IDWriteTextRenderer*>(this);
      AddRef();
      return S_OK;
    }
    return E_NOINTERFACE;
  }

  IFACEMETHOD_(ULONG, AddRef)() override { return ++reference_count_; }

  IFACEMETHOD_(ULONG, Release)() override {
    const ULONG count = --reference_count_;
    if (count == 0) delete this;
    return count;
  }

  IFACEMETHOD(IsPixelSnappingDisabled)(void*, BOOL* disabled) override {
    if (disabled == nullptr) return E_POINTER;
    *disabled = FALSE;
    return S_OK;
  }

  IFACEMETHOD(GetCurrentTransform)(void*, DWRITE_MATRIX* transform) override {
    if (transform == nullptr) return E_POINTER;
    *transform = DWRITE_MATRIX{1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f};
    return S_OK;
  }

  IFACEMETHOD(GetPixelsPerDip)(void*, FLOAT* pixels_per_dip) override {
    if (pixels_per_dip == nullptr) return E_POINTER;
    *pixels_per_dip = 1.0f;
    return S_OK;
  }

  IFACEMETHOD(DrawGlyphRun)(
      void*, FLOAT baseline_origin_x, FLOAT baseline_origin_y,
      DWRITE_MEASURING_MODE measuring_mode, const DWRITE_GLYPH_RUN* glyph_run,
      const DWRITE_GLYPH_RUN_DESCRIPTION*, IUnknown*) override {
    IDWriteGlyphRunAnalysis* analysis = nullptr;
    HRESULT result = factory_->CreateGlyphRunAnalysis(
        glyph_run, 1.0f, nullptr, DWRITE_RENDERING_MODE_ALIASED,
        measuring_mode, baseline_origin_x, baseline_origin_y, &analysis);
    if (FAILED(result)) return result;

    RECT bounds{};
    result = analysis->GetAlphaTextureBounds(DWRITE_TEXTURE_ALIASED_1x1,
                                             &bounds);
    if (SUCCEEDED(result)) {
      bounds.left = std::max<LONG>(0, bounds.left);
      bounds.top = std::max<LONG>(0, bounds.top);
      bounds.right = std::min<LONG>(width_, bounds.right);
      bounds.bottom = std::min<LONG>(height_, bounds.bottom);
      const LONG texture_width = bounds.right - bounds.left;
      const LONG texture_height = bounds.bottom - bounds.top;
      if (texture_width > 0 && texture_height > 0) {
        std::vector<uint8_t> alpha(
            static_cast<size_t>(texture_width) * texture_height);
        result = analysis->CreateAlphaTexture(
            DWRITE_TEXTURE_ALIASED_1x1, &bounds, alpha.data(),
            static_cast<UINT32>(alpha.size()));
        if (SUCCEEDED(result)) {
          for (LONG y = 0; y < texture_height; ++y) {
            for (LONG x = 0; x < texture_width; ++x) {
              if (alpha[static_cast<size_t>(y) * texture_width + x] == 0) {
                continue;
              }
              (*mask_)[static_cast<size_t>(bounds.top + y) * width_ +
                       bounds.left + x] = 1;
            }
          }
          ++glyph_runs_;
        }
      }
    }
    analysis->Release();
    return result;
  }

  IFACEMETHOD(DrawUnderline)(void*, FLOAT, FLOAT,
                             const DWRITE_UNDERLINE*, IUnknown*) override {
    return S_OK;
  }

  IFACEMETHOD(DrawStrikethrough)(
      void*, FLOAT, FLOAT, const DWRITE_STRIKETHROUGH*, IUnknown*) override {
    return S_OK;
  }

  IFACEMETHOD(DrawInlineObject)(void*, FLOAT, FLOAT, IDWriteInlineObject*, BOOL,
                                BOOL, IUnknown*) override {
    return S_OK;
  }

  size_t glyph_runs() const { return glyph_runs_; }

 private:
  std::atomic<ULONG> reference_count_{1};
  IDWriteFactory* factory_;
  int width_;
  int height_;
  std::vector<uint8_t>* mask_;
  size_t glyph_runs_ = 0;
};
#endif

#if 0
// Retired after the v1.3.61 physical print still showed broken inverse glyphs.
// Keep this failed supersample experiment isolated so it cannot be reused.
bool RenderWhiteTextIntoBitmapSupersampleExperiment(
    std::vector<uint8_t>& bitmap, int target_width, int target_height,
    int source_width, int source_height,
    const std::vector<NativeTextDescriptor>& text_descriptors,
    HDC printer_dc, NativeTextRenderStats& stats, std::string& error) {
  const bool has_white_text = std::any_of(
      text_descriptors.begin(), text_descriptors.end(),
      [](const NativeTextDescriptor& descriptor) {
        return descriptor.color == RGB(255, 255, 255);
      });
  if (!has_white_text) return true;

  const int render_width = target_width * kWhiteTextSupersample;
  const int render_height = target_height * kWhiteTextSupersample;
  BITMAPINFO bitmap_info{};
  bitmap_info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bitmap_info.bmiHeader.biWidth = render_width;
  bitmap_info.bmiHeader.biHeight = -render_height;
  bitmap_info.bmiHeader.biPlanes = 1;
  bitmap_info.bmiHeader.biBitCount = 32;
  bitmap_info.bmiHeader.biCompression = BI_RGB;
  HDC memory_dc = CreateCompatibleDC(printer_dc);
  if (memory_dc == nullptr) {
    error = "CreateCompatibleDC for white text failed: " +
            std::to_string(GetLastError());
    return false;
  }
  void* dib_bits = nullptr;
  HBITMAP dib = CreateDIBSection(memory_dc, &bitmap_info, DIB_RGB_COLORS,
                                 &dib_bits, nullptr, 0);
  if (dib == nullptr || dib_bits == nullptr) {
    error = "CreateDIBSection for white text failed: " +
            std::to_string(GetLastError());
    if (dib != nullptr) DeleteObject(dib);
    DeleteDC(memory_dc);
    return false;
  }
  HGDIOBJ previous_bitmap = SelectObject(memory_dc, dib);
  auto* rendered = static_cast<uint8_t*>(dib_bits);
  std::fill_n(rendered,
              static_cast<size_t>(render_width) * render_height * 4,
              uint8_t{0});
  SetMapMode(memory_dc, MM_ANISOTROPIC);
  SetWindowExtEx(memory_dc, source_width, source_height, nullptr);
  SetViewportExtEx(memory_dc, render_width, render_height, nullptr);
  SetViewportOrgEx(memory_dc, 0, 0, nullptr);
  const int previous_background_mode = SetBkMode(memory_dc, TRANSPARENT);
  const COLORREF previous_text_color = SetTextColor(memory_dc, RGB(255, 255, 255));

  for (const auto& descriptor : text_descriptors) {
    if (descriptor.color != RGB(255, 255, 255)) continue;
    const int font_pixel_height = std::max(1, descriptor.font_pixel_height);
    // Preserve the glyph outline; sparse edge relief is applied after sampling.
    HFONT font = CreateFontW(
        -font_pixel_height, 0, 0, 0,
        descriptor.bold ? FW_BOLD : FW_NORMAL, descriptor.italic,
        descriptor.underline, descriptor.strike_through, DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
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
      ++stats.white_bitmap_drawn;
      stats.characters += descriptor.text.size();
    } else {
      ++stats.failed;
    }
    SelectObject(memory_dc, previous_font);
    if (fitted_font != nullptr) DeleteObject(fitted_font);
    DeleteObject(font);
  }
  GdiFlush();
  constexpr int sample_count =
      kWhiteTextSupersample * kWhiteTextSupersample;
  std::vector<uint8_t> white_mask(
      static_cast<size_t>(target_width) * target_height, uint8_t{0});
  for (int y = 0; y < target_height; ++y) {
    for (int x = 0; x < target_width; ++x) {
      int luminance_sum = 0;
      for (int sample_y = 0; sample_y < kWhiteTextSupersample; ++sample_y) {
        for (int sample_x = 0; sample_x < kWhiteTextSupersample; ++sample_x) {
          const int render_x = x * kWhiteTextSupersample + sample_x;
          const int render_y = y * kWhiteTextSupersample + sample_y;
          const size_t render_offset =
              (static_cast<size_t>(render_y) * render_width + render_x) * 4;
          luminance_sum += rendered[render_offset];
        }
      }
      if (luminance_sum < kWhiteTextCoverageThreshold * sample_count) {
        continue;
      }
      white_mask[static_cast<size_t>(y) * target_width + x] = 1;
    }
  }
  const std::vector<uint8_t> threshold_mask = white_mask;
  for (int y = 1; y < target_height - 1; ++y) {
    for (int x = 1; x < target_width - 1; ++x) {
      const size_t mask_offset =
          static_cast<size_t>(y) * target_width + x;
      if (threshold_mask[mask_offset] != 0) continue;
      const bool touches_glyph =
          threshold_mask[mask_offset - 1] != 0 ||
          threshold_mask[mask_offset + 1] != 0 ||
          threshold_mask[mask_offset - target_width] != 0 ||
          threshold_mask[mask_offset + target_width] != 0;
      const bool relief_sample = ((x + 2 * y) & 3) == 0;
      if (touches_glyph && relief_sample) {
        white_mask[mask_offset] = 1;
      }
    }
  }
  for (int y = 0; y < target_height; ++y) {
    for (int x = 0; x < target_width; ++x) {
      const size_t mask_offset =
          static_cast<size_t>(y) * target_width + x;
      if (white_mask[mask_offset] == 0) {
        continue;
      }
      const size_t target_offset =
          (static_cast<size_t>(y) * target_width + x) * 4;
      if (bitmap[target_offset] >= 128 || bitmap[target_offset + 1] >= 128 ||
          bitmap[target_offset + 2] >= 128) {
        continue;
      }
      bitmap[target_offset] = 255;
      bitmap[target_offset + 1] = 255;
      bitmap[target_offset + 2] = 255;
      ++stats.white_knockout_pixels;
      if (threshold_mask[mask_offset] == 0) ++stats.white_edge_relief_pixels;
    }
  }
  SetTextColor(memory_dc, previous_text_color);
  SetBkMode(memory_dc, previous_background_mode);
  SelectObject(memory_dc, previous_bitmap);
  DeleteObject(dib);
  DeleteDC(memory_dc);
  return true;
}
#endif

#if 0
// Retired with BilevelTextRenderer after the v1.3.62 physical print failed.
bool RenderWhiteTextIntoBitmapDirectWriteExperiment(
    std::vector<uint8_t>& bitmap, int target_width, int target_height,
    int source_width, int source_height,
    const std::vector<NativeTextDescriptor>& text_descriptors,
    HDC printer_dc, NativeTextRenderStats& stats, std::string& error) {
  (void)printer_dc;
  const bool has_white_text = std::any_of(
      text_descriptors.begin(), text_descriptors.end(),
      [](const NativeTextDescriptor& descriptor) {
        return descriptor.color == RGB(255, 255, 255);
      });
  if (!has_white_text) return true;

  IDWriteFactory* factory = nullptr;
  HRESULT result = DWriteCreateFactory(
      DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory),
      reinterpret_cast<IUnknown**>(&factory));
  if (FAILED(result) || factory == nullptr) {
    error = "DWriteCreateFactory for white text failed: " +
            std::to_string(static_cast<unsigned long>(result));
    return false;
  }

  std::vector<uint8_t> white_mask(
      static_cast<size_t>(target_width) * target_height, uint8_t{0});
  auto* renderer =
      new BilevelTextRenderer(factory, target_width, target_height, &white_mask);
  for (const auto& descriptor : text_descriptors) {
    if (descriptor.color != RGB(255, 255, 255)) continue;
    const LONG left = MulDiv(descriptor.rect.left, target_width, source_width);
    const LONG top = MulDiv(descriptor.rect.top, target_height, source_height);
    const LONG right =
        MulDiv(descriptor.rect.right, target_width, source_width);
    const LONG bottom =
        MulDiv(descriptor.rect.bottom, target_height, source_height);
    const FLOAT available_width =
        static_cast<FLOAT>(std::max<LONG>(1, right - left));
    const FLOAT available_height =
        static_cast<FLOAT>(std::max<LONG>(1, bottom - top));
    FLOAT font_size = static_cast<FLOAT>(std::max(
        1, MulDiv(descriptor.font_pixel_height, target_height, source_height)));
    IDWriteTextFormat* format = nullptr;
    IDWriteTextLayout* layout = nullptr;
    for (int attempt = 0; attempt < 5; ++attempt) {
      const std::wstring family = descriptor.font_family.empty()
                                      ? std::wstring(L"Arial")
                                      : descriptor.font_family;
      result = factory->CreateTextFormat(
          family.c_str(), nullptr,
          descriptor.bold ? DWRITE_FONT_WEIGHT_BOLD
                          : DWRITE_FONT_WEIGHT_NORMAL,
          descriptor.italic ? DWRITE_FONT_STYLE_ITALIC
                            : DWRITE_FONT_STYLE_NORMAL,
          DWRITE_FONT_STRETCH_NORMAL, font_size, L"ko-KR", &format);
      if (FAILED(result) || format == nullptr) break;
      format->SetTextAlignment(
          descriptor.horizontal_align == "0"
              ? DWRITE_TEXT_ALIGNMENT_CENTER
              : descriptor.horizontal_align == "2"
                    ? DWRITE_TEXT_ALIGNMENT_TRAILING
                    : DWRITE_TEXT_ALIGNMENT_LEADING);
      format->SetParagraphAlignment(
          descriptor.vertical_align == "2"
              ? DWRITE_PARAGRAPH_ALIGNMENT_FAR
              : descriptor.vertical_align == "1"
                    ? DWRITE_PARAGRAPH_ALIGNMENT_NEAR
                    : DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
      format->SetWordWrapping(descriptor.wrap ? DWRITE_WORD_WRAPPING_WRAP
                                               : DWRITE_WORD_WRAPPING_NO_WRAP);
      result = factory->CreateTextLayout(
          descriptor.text.c_str(), static_cast<UINT32>(descriptor.text.size()),
          format, available_width, available_height, &layout);
      if (FAILED(result) || layout == nullptr) break;
      const DWRITE_TEXT_RANGE entire_text{
          0, static_cast<UINT32>(descriptor.text.size())};
      if (descriptor.underline) layout->SetUnderline(TRUE, entire_text);
      if (descriptor.strike_through) {
        layout->SetStrikethrough(TRUE, entire_text);
      }
      DWRITE_TEXT_METRICS metrics{};
      result = layout->GetMetrics(&metrics);
      if (FAILED(result) || descriptor.wrap ||
          metrics.widthIncludingTrailingWhitespace <= available_width ||
          font_size <= 1.0f) {
        break;
      }
      const FLOAT fitted_size = std::max(
          1.0f, font_size * (available_width - 1.0f) /
                    metrics.widthIncludingTrailingWhitespace);
      layout->Release();
      layout = nullptr;
      format->Release();
      format = nullptr;
      font_size = fitted_size < font_size
                      ? fitted_size
                      : std::max(1.0f, font_size - 1.0f);
      ++stats.fitted;
    }
    if (SUCCEEDED(result) && layout != nullptr) {
      const size_t previous_glyph_runs = renderer->glyph_runs();
      result = layout->Draw(nullptr, renderer, static_cast<FLOAT>(left),
                            static_cast<FLOAT>(top));
      if (SUCCEEDED(result) && renderer->glyph_runs() > previous_glyph_runs) {
        ++stats.drawn;
        ++stats.white_bitmap_drawn;
        stats.characters += descriptor.text.size();
      } else {
        ++stats.failed;
      }
    } else {
      ++stats.failed;
    }
    if (layout != nullptr) layout->Release();
    if (format != nullptr) format->Release();
  }
  stats.white_bilevel_glyph_runs = renderer->glyph_runs();
  renderer->Release();
  factory->Release();

  for (int y = 0; y < target_height; ++y) {
    for (int x = 0; x < target_width; ++x) {
      const size_t mask_offset = static_cast<size_t>(y) * target_width + x;
      if (white_mask[mask_offset] == 0) continue;
      const size_t target_offset = mask_offset * 4;
      if (bitmap[target_offset] >= 128 || bitmap[target_offset + 1] >= 128 ||
          bitmap[target_offset + 2] >= 128) {
        continue;
      }
      bitmap[target_offset] = 255;
      bitmap[target_offset + 1] = 255;
      bitmap[target_offset + 2] = 255;
      ++stats.white_knockout_pixels;
    }
  }
  return true;
}
#endif

#if 0
// Retired after the v1.3.63 physical print produced only 2,381 knockout
// pixels and still showed severe inverse glyph loss. Keep this failed GGO
// bitmap experiment isolated so it cannot be reused.
bool RenderWhiteTextIntoBitmapGgoExperiment(
    std::vector<uint8_t>& bitmap, int target_width, int target_height,
    int source_width, int source_height,
    const std::vector<NativeTextDescriptor>& text_descriptors,
    HDC printer_dc, NativeTextRenderStats& stats, std::string& error) {
  const bool has_white_text = std::any_of(
      text_descriptors.begin(), text_descriptors.end(),
      [](const NativeTextDescriptor& descriptor) {
        return descriptor.color == RGB(255, 255, 255);
      });
  if (!has_white_text) return true;

  HDC memory_dc = CreateCompatibleDC(printer_dc);
  if (memory_dc == nullptr) {
    error = "CreateCompatibleDC for GGO bitmap failed: " +
            std::to_string(GetLastError());
    return false;
  }
  std::vector<uint8_t> white_mask(
      static_cast<size_t>(target_width) * target_height, uint8_t{0});
  MAT2 identity{};
  identity.eM11.value = 1;
  identity.eM22.value = 1;

  for (const auto& descriptor : text_descriptors) {
    if (descriptor.color != RGB(255, 255, 255)) continue;
    RECT text_rect{
        MulDiv(descriptor.rect.left, target_width, source_width),
        MulDiv(descriptor.rect.top, target_height, source_height),
        MulDiv(descriptor.rect.right, target_width, source_width),
        MulDiv(descriptor.rect.bottom, target_height, source_height),
    };
    const LONG available_width =
        std::max<LONG>(1, text_rect.right - text_rect.left);
    int font_height = std::max(
        1, MulDiv(descriptor.font_pixel_height, target_height, source_height));
    HFONT font = nullptr;
    HGDIOBJ previous_font = nullptr;
    bool fitted = false;
    SIZE measured{};
    for (int attempt = 0; attempt < 5; ++attempt) {
      HFONT next_font = CreateFontW(
          -font_height, 0, 0, 0,
          descriptor.bold ? FW_BOLD : FW_NORMAL, descriptor.italic,
          descriptor.underline, descriptor.strike_through, DEFAULT_CHARSET,
          OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, NONANTIALIASED_QUALITY,
          DEFAULT_PITCH | FF_DONTCARE, descriptor.font_family.c_str());
      if (next_font == nullptr) break;
      HGDIOBJ replaced = SelectObject(memory_dc, next_font);
      if (replaced == nullptr || replaced == HGDI_ERROR) {
        DeleteObject(next_font);
        break;
      }
      if (previous_font == nullptr) previous_font = replaced;
      if (font != nullptr) DeleteObject(font);
      font = next_font;
      if (!GetTextExtentPoint32W(memory_dc, descriptor.text.c_str(),
                                 static_cast<int>(descriptor.text.size()),
                                 &measured)) {
        break;
      }
      if (descriptor.wrap || measured.cx <= available_width ||
          font_height <= 1) {
        break;
      }
      font_height = std::max(
          1, MulDiv(font_height, std::max<LONG>(1, available_width - 1),
                    measured.cx));
      fitted = true;
    }
    if (font == nullptr || previous_font == nullptr ||
        previous_font == HGDI_ERROR) {
      ++stats.failed;
      continue;
    }
    if (fitted) ++stats.fitted;
    if (GetFontData(memory_dc, 0, 0, nullptr, 0) == GDI_ERROR) {
      ++stats.no_outline_fonts;
    } else {
      ++stats.outline_fonts;
    }

    TEXTMETRICW text_metrics{};
    std::vector<WORD> glyph_indices(descriptor.text.size());
    const DWORD glyph_result = GetGlyphIndicesW(
        memory_dc, descriptor.text.c_str(),
        static_cast<int>(descriptor.text.size()), glyph_indices.data(),
        GGI_MARK_NONEXISTING_GLYPHS);
    bool descriptor_ok =
        GetTextMetricsW(memory_dc, &text_metrics) && glyph_result != GDI_ERROR;
    std::vector<GLYPHMETRICS> glyph_metrics(glyph_indices.size());
    LONG total_advance = 0;
    if (descriptor_ok) {
      for (size_t index = 0; index < glyph_indices.size(); ++index) {
        if (glyph_indices[index] == 0xffff) {
          descriptor_ok = false;
          break;
        }
        const DWORD size = GetGlyphOutlineW(
            memory_dc, glyph_indices[index], GGO_BITMAP | GGO_GLYPH_INDEX,
            &glyph_metrics[index], 0, nullptr, &identity);
        if (size == GDI_ERROR) {
          descriptor_ok = false;
          break;
        }
        total_advance += glyph_metrics[index].gmCellIncX;
      }
    }

    LONG pen_x = text_rect.left;
    if (descriptor.horizontal_align == "0") {
      pen_x += std::max<LONG>(0, (available_width - total_advance) / 2);
    } else if (descriptor.horizontal_align == "2") {
      pen_x += std::max<LONG>(0, available_width - total_advance);
    }
    const LONG text_height = text_metrics.tmHeight;
    LONG line_top = text_rect.top;
    if (descriptor.vertical_align == "2") {
      line_top = std::max(text_rect.top, text_rect.bottom - text_height);
    } else if (descriptor.vertical_align != "1") {
      line_top += std::max<LONG>(
          0, (text_rect.bottom - text_rect.top - text_height) / 2);
    }
    const LONG baseline_y = line_top + text_metrics.tmAscent;

    if (descriptor_ok) {
      for (size_t index = 0; index < glyph_indices.size(); ++index) {
        GLYPHMETRICS& metrics = glyph_metrics[index];
        const DWORD buffer_size = GetGlyphOutlineW(
            memory_dc, glyph_indices[index], GGO_BITMAP | GGO_GLYPH_INDEX,
          &metrics, 0, nullptr, &identity);
        if (buffer_size == GDI_ERROR) {
          descriptor_ok = false;
          break;
        }
        std::vector<uint8_t> glyph_bitmap(buffer_size);
        if (buffer_size > 0 &&
            GetGlyphOutlineW(
                memory_dc, glyph_indices[index],
            GGO_BITMAP | GGO_GLYPH_INDEX, &metrics, buffer_size,
            glyph_bitmap.data(), &identity) == GDI_ERROR) {
          descriptor_ok = false;
          break;
        }
        const LONG glyph_left = pen_x + metrics.gmptGlyphOrigin.x;
        const LONG glyph_top = baseline_y - metrics.gmptGlyphOrigin.y;
        const size_t row_stride =
            (static_cast<size_t>(metrics.gmBlackBoxX) + 31) / 32 * 4;
        for (UINT y = 0; y < metrics.gmBlackBoxY; ++y) {
          const LONG target_y = glyph_top + static_cast<LONG>(y);
          if (target_y < text_rect.top || target_y >= text_rect.bottom ||
              target_y < 0 || target_y >= target_height) {
            continue;
          }
          for (UINT x = 0; x < metrics.gmBlackBoxX; ++x) {
            const size_t byte_offset =
                static_cast<size_t>(y) * row_stride + x / 8;
            if (byte_offset >= glyph_bitmap.size() ||
                (glyph_bitmap[byte_offset] & (0x80 >> (x % 8))) == 0) {
              continue;
            }
            const LONG target_x = glyph_left + static_cast<LONG>(x);
            if (target_x < text_rect.left || target_x >= text_rect.right ||
                target_x < 0 || target_x >= target_width) {
              continue;
            }
            white_mask[static_cast<size_t>(target_y) * target_width +
                       target_x] = 1;
          }
        }
        if (buffer_size > 0) ++stats.white_glyph_bitmaps;
        pen_x += metrics.gmCellIncX;
      }
    }
    if (descriptor_ok) {
      ++stats.drawn;
      ++stats.white_bitmap_drawn;
      stats.characters += descriptor.text.size();
    } else {
      ++stats.failed;
    }
    SelectObject(memory_dc, previous_font);
    DeleteObject(font);
  }
  DeleteDC(memory_dc);

  for (int y = 0; y < target_height; ++y) {
    for (int x = 0; x < target_width; ++x) {
      const size_t mask_offset = static_cast<size_t>(y) * target_width + x;
      if (white_mask[mask_offset] == 0) continue;
      const size_t target_offset = mask_offset * 4;
      if (bitmap[target_offset] >= 128 || bitmap[target_offset + 1] >= 128 ||
          bitmap[target_offset + 2] >= 128) {
        continue;
      }
      bitmap[target_offset] = 255;
      bitmap[target_offset + 1] = 255;
      bitmap[target_offset + 2] = 255;
      ++stats.white_knockout_pixels;
    }
  }
  return true;
}
#endif

struct InverseDiagnosticResources {
  HDC recording = nullptr;
  HENHMETAFILE metafile = nullptr;
  HDC memory = nullptr;
  HBITMAP bitmap = nullptr;
  HGDIOBJ previous_bitmap = nullptr;

  ~InverseDiagnosticResources() {
    if (recording != nullptr) {
      HENHMETAFILE unfinished = CloseEnhMetaFile(recording);
      if (unfinished != nullptr) DeleteEnhMetaFile(unfinished);
    }
    if (metafile != nullptr) DeleteEnhMetaFile(metafile);
    if (previous_bitmap != nullptr && previous_bitmap != HGDI_ERROR) {
      SelectObject(memory, previous_bitmap);
    }
    if (bitmap != nullptr) DeleteObject(bitmap);
    if (memory != nullptr) DeleteDC(memory);
  }
};

std::string SaveInverseComparison(
    HWND rich_edit, const FORMATRANGE& actual_range, const RECT& clip,
    const std::vector<uint8_t>& base, int width, int height,
    const NativeTextDescriptor& descriptor, LONG text_length,
    LRESULT actual_until, LONG font_twips) {
  try {
    const auto directory = std::filesystem::path(".tmp") / "log" /
                           "godex_inverse";
    std::filesystem::create_directories(directory);
    static unsigned long sequence = 0;
    const auto prefix = directory /
        ("v1.3.93_" + std::to_string(GetCurrentProcessId()) + "_" +
         std::to_string(GetTickCount64()) + "_" + std::to_string(++sequence));
    const std::filesystem::path emf_path(prefix.string() + ".emf");
    InverseDiagnosticResources resources;
    const int dpi_x = GetDeviceCaps(actual_range.hdcTarget, LOGPIXELSX);
    const int dpi_y = GetDeviceCaps(actual_range.hdcTarget, LOGPIXELSY);
    RECT frame{0, 0, MulDiv(width, 2540, dpi_x),
               MulDiv(height, 2540, dpi_y)};
    resources.recording = CreateEnhMetaFileW(
        actual_range.hdcTarget, emf_path.c_str(), &frame,
        L"LabelManager\0Inverse comparison v1.3.93 - not spool capture\0");
    if (resources.recording == nullptr) return "recordingFailed";
    SetMapMode(resources.recording, MM_TEXT);
    IntersectClipRect(resources.recording, clip.left, clip.top,
                      clip.right, clip.bottom);
    FORMATRANGE reference_range = actual_range;
    reference_range.hdc = resources.recording;
    const LRESULT reference_until = SendMessageW(
        rich_edit, EM_FORMATRANGE, TRUE,
        reinterpret_cast<LPARAM>(&reference_range));
    SendMessageW(rich_edit, EM_FORMATRANGE, FALSE, 0);
    resources.metafile = CloseEnhMetaFile(resources.recording);
    resources.recording = nullptr;
    if (resources.metafile == nullptr) return "closeMetafileFailed";

    BITMAPINFO info{};
    info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    info.bmiHeader.biWidth = width;
    info.bmiHeader.biHeight = -height;
    info.bmiHeader.biPlanes = 1;
    info.bmiHeader.biBitCount = 32;
    info.bmiHeader.biCompression = BI_RGB;
    info.bmiHeader.biXPelsPerMeter = MulDiv(dpi_x, 10000, 254);
    info.bmiHeader.biYPelsPerMeter = MulDiv(dpi_y, 10000, 254);
    resources.memory = CreateCompatibleDC(actual_range.hdcTarget);
    if (resources.memory == nullptr) return "memoryDcFailed";
    void* pixels = nullptr;
    resources.bitmap = CreateDIBSection(resources.memory, &info,
        DIB_RGB_COLORS, &pixels, nullptr, 0);
    if (resources.bitmap == nullptr || pixels == nullptr) return "dibFailed";
    resources.previous_bitmap = SelectObject(resources.memory, resources.bitmap);
    if (resources.previous_bitmap == nullptr ||
        resources.previous_bitmap == HGDI_ERROR) return "selectBitmapFailed";
    std::copy(base.begin(), base.end(), static_cast<uint8_t*>(pixels));
    const auto save_bitmap = [&](const std::string& suffix) {
      BITMAPFILEHEADER header{};
      header.bfType = 0x4d42;
      header.bfOffBits = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER);
      header.bfSize = header.bfOffBits + static_cast<DWORD>(base.size());
      std::ofstream file(prefix.string() + suffix, std::ios::binary);
      file.write(reinterpret_cast<const char*>(&header), sizeof(header));
      file.write(reinterpret_cast<const char*>(&info.bmiHeader),
                 sizeof(info.bmiHeader));
      file.write(static_cast<const char*>(pixels),
                 static_cast<std::streamsize>(base.size()));
      file.close();
      return !file.fail();
    };
    const bool base_saved = save_bitmap("_base.bmp");
    RECT destination{0, 0, width, height};
    const BOOL replayed = PlayEnhMetaFile(resources.memory, resources.metafile,
                                        &destination);
    GdiFlush();
    size_t changed_pixels = 0;
    const auto* rendered = static_cast<const uint8_t*>(pixels);
    for (size_t offset = 0; offset < base.size(); offset += 4) {
      if (base[offset] != rendered[offset] ||
          base[offset + 1] != rendered[offset + 1] ||
          base[offset + 2] != rendered[offset + 2]) ++changed_pixels;
    }
    const bool comparison_saved = save_bitmap("_comparison.bmp");
    std::ofstream report(prefix.string() + ".txt");
    report << "version=1.3.93\nkind=printerReferenceEmfReplay\n"
           << "notActualSpoolCapture=true\nonlyThisWhiteDescriptor=true\n"
           << "dpi=" << dpi_x << "," << dpi_y << "\nsize=" << width << "," << height
           << "\nfont=" << descriptor.font_family_utf8
           << "\nfontDots=" << descriptor.font_pixel_height
           << "\nfontTwips=" << font_twips << "\nbold=" << descriptor.bold
           << "\nwrapRequested=" << descriptor.wrap
           << "\nwrapConfigured=false\nclip=" << clip.left << "," << clip.top
           << "," << clip.right << "," << clip.bottom
           << "\ninputUtf16=" << descriptor.text.size()
           << "\nrichEditLength=" << text_length
           << "\nactualFormattedUntil=" << actual_until
           << "\nactualAllCharactersFit=" << (actual_until >= text_length)
           << "\nreferenceFormattedUntil=" << reference_until
           << "\nreferenceAllCharactersFit=" << (reference_until >= text_length)
           << "\nreplaySucceeded=" << (replayed != FALSE)
           << "\nchangedPixels=" << changed_pixels
           << "\nbaseSaved=" << base_saved
           << "\ncomparisonSaved=" << comparison_saved << "\n";
    report.close();
    return prefix.generic_string() +
        ((base_saved && comparison_saved && replayed && !report.fail())
             ? ":saved" : ":incomplete");
  } catch (...) {
    return "diagnosticSaveFailed";
  }
}

bool RenderWhiteTextIntoBitmap(
    std::vector<uint8_t>& bitmap, int target_width, int target_height,
    int source_width, int source_height,
    const std::vector<NativeTextDescriptor>& text_descriptors,
    HDC printer_dc, NativeTextRenderStats& stats, std::string& error,
    std::ostream& diagnostics) {
  const bool has_white_text = std::any_of(
      text_descriptors.begin(), text_descriptors.end(),
      [](const NativeTextDescriptor& descriptor) {
        return descriptor.color == RGB(255, 255, 255);
      });
  if (!has_white_text) return true;
  HMODULE rich_edit_module = LoadLibraryW(L"Msftedit.dll");
  if (rich_edit_module == nullptr) {
    error = "LoadLibraryW Msftedit.dll failed: " +
            std::to_string(GetLastError());
    return false;
  }
  HWND host = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
                              L"STATIC", L"", WS_POPUP, 0, 0,
                              target_width, target_height, nullptr, nullptr,
                              GetModuleHandle(nullptr), nullptr);
  HWND rich_edit = host == nullptr
                       ? nullptr
                       : CreateWindowExW(
                             0, L"RICHEDIT50W", L"",
                             WS_CHILD | WS_VISIBLE | ES_MULTILINE, 0, 0,
                             target_width, target_height, host, nullptr,
                             GetModuleHandle(nullptr), nullptr);
  if (rich_edit == nullptr) {
    if (host != nullptr) DestroyWindow(host);
    FreeLibrary(rich_edit_module);
    error = "CreateWindowExW RichEdit failed: " +
            std::to_string(GetLastError());
    return false;
  }
  const int dpi_x = std::max(1, GetDeviceCaps(printer_dc, LOGPIXELSX));
  const int dpi_y = std::max(1, GetDeviceCaps(printer_dc, LOGPIXELSY));

  for (const auto& descriptor : text_descriptors) {
    if (descriptor.color != RGB(255, 255, 255)) continue;
    RECT text_rect{
        MulDiv(descriptor.rect.left, target_width, source_width),
        MulDiv(descriptor.rect.top, target_height, source_height),
        MulDiv(descriptor.rect.right, target_width, source_width),
        MulDiv(descriptor.rect.bottom, target_height, source_height),
    };
    const int cell_width = std::max<LONG>(1, text_rect.right - text_rect.left);
    const int cell_height =
        std::max<LONG>(1, text_rect.bottom - text_rect.top);
    const int font_height = std::max(
        1, MulDiv(descriptor.font_pixel_height, target_height, source_height));
    SetWindowPos(rich_edit, nullptr, 0, 0, cell_width, cell_height,
                 SWP_NOZORDER | SWP_NOACTIVATE);
    SetWindowTextW(rich_edit, descriptor.text.c_str());
    SendMessageW(rich_edit, EM_SETBKGNDCOLOR, FALSE, RGB(0, 0, 0));
    SendMessageW(rich_edit, EM_SETMARGINS, EC_LEFTMARGIN | EC_RIGHTMARGIN, 0);
    RECT format_rect{0, 0, cell_width, cell_height};
    SendMessageW(rich_edit, EM_SETRECTNP, 0,
                 reinterpret_cast<LPARAM>(&format_rect));
    SendMessageW(rich_edit, EM_SETSEL, 0, -1);
    CHARFORMAT2W character_format{};
    character_format.cbSize = sizeof(character_format);
    character_format.dwMask = CFM_FACE | CFM_SIZE | CFM_COLOR |
                              CFM_BACKCOLOR | CFM_BOLD | CFM_ITALIC |
                              CFM_UNDERLINE | CFM_STRIKEOUT;
    character_format.dwEffects = 0;
    if (descriptor.bold) character_format.dwEffects |= CFE_BOLD;
    if (descriptor.italic) character_format.dwEffects |= CFE_ITALIC;
    if (descriptor.underline) character_format.dwEffects |= CFE_UNDERLINE;
    if (descriptor.strike_through) {
      character_format.dwEffects |= CFE_STRIKEOUT;
    }
    character_format.yHeight = MulDiv(font_height, 1440, dpi_y);
    character_format.crTextColor = RGB(255, 255, 255);
    character_format.crBackColor = RGB(0, 0, 0);
    wcsncpy_s(character_format.szFaceName, LF_FACESIZE,
              descriptor.font_family.c_str(), _TRUNCATE);
    SendMessageW(rich_edit, EM_SETCHARFORMAT, SCF_SELECTION,
                 reinterpret_cast<LPARAM>(&character_format));
    PARAFORMAT2 paragraph_format{};
    paragraph_format.cbSize = sizeof(paragraph_format);
    paragraph_format.dwMask = PFM_ALIGNMENT;
    paragraph_format.wAlignment = descriptor.horizontal_align == "0"
                                      ? PFA_CENTER
                                      : descriptor.horizontal_align == "2"
                                            ? PFA_RIGHT
                                            : PFA_LEFT;
    SendMessageW(rich_edit, EM_SETPARAFORMAT, 0,
                 reinterpret_cast<LPARAM>(&paragraph_format));

    const int printer_state = SaveDC(printer_dc);
    if (printer_state == 0) {
      ++stats.failed;
      continue;
    }
    IntersectClipRect(printer_dc, text_rect.left, text_rect.top,
                      text_rect.right, text_rect.bottom);
    FORMATRANGE format_range{};
    format_range.hdc = printer_dc;
    format_range.hdcTarget = printer_dc;
    format_range.rc = {MulDiv(text_rect.left, 1440, dpi_x),
                       MulDiv(text_rect.top, 1440, dpi_y),
                       MulDiv(text_rect.right, 1440, dpi_x),
                       MulDiv(text_rect.bottom, 1440, dpi_y)};
    format_range.rcPage = format_range.rc;
    format_range.chrg.cpMin = 0;
    format_range.chrg.cpMax = -1;
    const LRESULT formatted_until = SendMessageW(
        rich_edit, EM_FORMATRANGE, TRUE,
        reinterpret_cast<LPARAM>(&format_range));
    SendMessageW(rich_edit, EM_FORMATRANGE, FALSE, 0);
    GdiFlush();
    RestoreDC(printer_dc, printer_state);
    const LONG rich_edit_length = GetWindowTextLengthW(rich_edit);
    diagnostics << " inverseActualLength=" << rich_edit_length
          << " inverseActualFormattedUntil=" << formatted_until
          << " inverseActualAllCharactersFit="
          << (formatted_until >= rich_edit_length)
          << " inverseComparison="
          << SaveInverseComparison(
               rich_edit, format_range, text_rect, bitmap,
               target_width, target_height, descriptor,
               rich_edit_length, formatted_until, character_format.yHeight);
    if (formatted_until > 0) {
      ++stats.drawn;
      ++stats.white_bitmap_drawn;
      stats.white_glyph_bitmaps += descriptor.text.size();
      stats.characters += descriptor.text.size();
    } else {
      ++stats.failed;
    }
  }
  DestroyWindow(rich_edit);
  DestroyWindow(host);
  FreeLibrary(rich_edit_module);
  (void)bitmap;
  return true;
}

bool RenderNativeTextToPrinterDc(
    std::vector<uint8_t>& bitmap, int target_width, int target_height,
    int source_width, int source_height,
    const std::vector<NativeTextDescriptor>& text_descriptors,
    HDC printer_dc,
    NativeTextRenderStats& stats, std::string& error) {
  if (text_descriptors.empty()) return true;
  (void)bitmap;
  const int text_dc_state = SaveDC(printer_dc);
  if (text_dc_state == 0) {
    error = "SaveDC for native text failed: " +
            std::to_string(GetLastError());
    return false;
  }
  SetMapMode(printer_dc, MM_ANISOTROPIC);
  SetWindowExtEx(printer_dc, source_width, source_height, nullptr);
  SetViewportExtEx(printer_dc, target_width, target_height, nullptr);
  SetViewportOrgEx(printer_dc, 0, 0, nullptr);
  const int previous_background_mode = SetBkMode(printer_dc, TRANSPARENT);
  for (const auto& descriptor : text_descriptors) {
    const int font_pixel_height = std::max(1, descriptor.font_pixel_height);
    HFONT font = CreateFontW(
        -font_pixel_height, 0, 0, 0,
        descriptor.bold ? FW_BOLD : FW_NORMAL, descriptor.italic,
        descriptor.underline, descriptor.strike_through, DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
        DEFAULT_PITCH | FF_DONTCARE, descriptor.font_family.c_str());
    if (font == nullptr) {
      ++stats.failed;
      continue;
    }
    HGDIOBJ previous_font = SelectObject(printer_dc, font);
    if (previous_font == nullptr || previous_font == HGDI_ERROR) {
      DeleteObject(font);
      ++stats.failed;
      continue;
    }
    if (GetFontData(printer_dc, 0, 0, nullptr, 0) == GDI_ERROR) {
      ++stats.no_outline_fonts;
    } else {
      ++stats.outline_fonts;
    }
    const COLORREF previous_color =
        SetTextColor(printer_dc, descriptor.color);
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
    DrawTextW(printer_dc, descriptor.text.c_str(),
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
        int fitted_dimension = std::max(
            1, MulDiv(font_pixel_height, desired_width, measured_width));
        for (int attempt = 0; attempt < 4; ++attempt) {
          log_font.lfHeight = descriptor.preserve_height_fit
                                  ? -font_pixel_height
                                  : -fitted_dimension;
          log_font.lfWidth = descriptor.preserve_height_fit
                                 ? fitted_dimension
                                 : 0;
          HFONT next_fitted_font = CreateFontIndirectW(&log_font);
          if (next_fitted_font == nullptr) break;
          SelectObject(printer_dc, next_fitted_font);
          if (fitted_font != nullptr) DeleteObject(fitted_font);
          fitted_font = next_fitted_font;
          measured = text_rect;
          DrawTextW(printer_dc, descriptor.text.c_str(),
                    static_cast<int>(descriptor.text.size()), &measured,
                    flags | DT_CALCRECT);
          const LONG fitted_measured_width = measured.right - measured.left;
          if (fitted_measured_width <= desired_width) break;
          const int next_dimension = std::max(
              1, MulDiv(fitted_dimension, desired_width,
                        fitted_measured_width));
          fitted_dimension = next_dimension < fitted_dimension
                                 ? next_dimension
                                 : std::max(1, fitted_dimension - 1);
        }
        if (fitted_font != nullptr) {
          ++stats.fitted;
          if (descriptor.preserve_height_fit) {
            ++stats.inverse_width_fitted;
          }
        }
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
        printer_dc, descriptor.text.c_str(),
        static_cast<int>(descriptor.text.size()), &text_rect, flags);
    if (draw_result > 0) {
      ++stats.drawn;
      stats.characters += descriptor.text.size();
    } else {
      ++stats.failed;
    }
    SetTextColor(printer_dc, previous_color);
    SelectObject(printer_dc, previous_font);
    if (fitted_font != nullptr) DeleteObject(fitted_font);
    DeleteObject(font);
  }
  SetBkMode(printer_dc, previous_background_mode);
  RestoreDC(printer_dc, text_dc_state);
  return true;

#if 0
  // v1.3.5의 supersample/threshold 경로는 203dpi 한글 획을 손실하므로
  // 재사용하지 않는다. 실물 비교 이력을 위해 구현은 비활성 상태로 남긴다.
  const int render_width = target_width * kNativeTextSupersample;
  const int render_height = target_height * kNativeTextSupersample;
  BITMAPINFO bitmap_info{};
  bitmap_info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bitmap_info.bmiHeader.biWidth = render_width;
  bitmap_info.bmiHeader.biHeight = -render_height;
  bitmap_info.bmiHeader.biPlanes = 1;
  bitmap_info.bmiHeader.biBitCount = 32;
  bitmap_info.bmiHeader.biCompression = BI_RGB;
  // 프린터 DC 기반 생성으로 203dpi 폰트 메트릭 상속 (레거시와 동일)
  HDC memory_dc = CreateCompatibleDC(printer_dc);
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
  auto* rendered = static_cast<uint8_t*>(dib_bits);
  for (int y = 0; y < render_height; ++y) {
    const int source_y = y / kNativeTextSupersample;
    for (int x = 0; x < render_width; ++x) {
      const int source_x = x / kNativeTextSupersample;
      const size_t source_offset =
          (static_cast<size_t>(source_y) * target_width + source_x) * 4;
      const size_t render_offset =
          (static_cast<size_t>(y) * render_width + x) * 4;
      std::memcpy(rendered + render_offset, bitmap.data() + source_offset, 4);
    }
  }
  SetMapMode(memory_dc, MM_ANISOTROPIC);
  SetWindowExtEx(memory_dc, source_width, source_height, nullptr);
  SetViewportExtEx(memory_dc, render_width, render_height, nullptr);
  SetViewportOrgEx(memory_dc, 0, 0, nullptr);
  const int previous_background_mode = SetBkMode(memory_dc, TRANSPARENT);
  for (const auto& descriptor : text_descriptors) {
    const int font_pixel_height = std::max(1, descriptor.font_pixel_height);
    HFONT font = CreateFontW(
        -font_pixel_height, 0, 0, 0,
        descriptor.bold ? FW_BOLD : FW_NORMAL, descriptor.italic,
        descriptor.underline, descriptor.strike_through, DEFAULT_CHARSET,
        OUT_TT_ONLY_PRECIS, CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY,
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
  constexpr int sample_count =
      kNativeTextSupersample * kNativeTextSupersample;
  for (int y = 0; y < target_height; ++y) {
    for (int x = 0; x < target_width; ++x) {
      int luminance_sum = 0;
      for (int sample_y = 0; sample_y < kNativeTextSupersample; ++sample_y) {
        for (int sample_x = 0; sample_x < kNativeTextSupersample;
             ++sample_x) {
          const int render_x = x * kNativeTextSupersample + sample_x;
          const int render_y = y * kNativeTextSupersample + sample_y;
          const size_t render_offset =
              (static_cast<size_t>(render_y) * render_width + render_x) * 4;
          luminance_sum +=
              (77 * rendered[render_offset + 2] +
               150 * rendered[render_offset + 1] +
               29 * rendered[render_offset]) >>
              8;
        }
      }
      const size_t target_offset =
          (static_cast<size_t>(y) * target_width + x) * 4;
      // 어두운 배경: 낮은 임계값으로 흰 텍스트 엣지 소실 방지
      const int threshold = (bitmap[target_offset] < 128)
          ? (kNativeTextThresholdDark * sample_count)
          : (kNativeTextThresholdLight * sample_count);
      const uint8_t monochrome = luminance_sum < threshold ? 0 : 255;
      if (bitmap[target_offset] != monochrome ||
          bitmap[target_offset + 1] != monochrome ||
          bitmap[target_offset + 2] != monochrome) {
        ++stats.bitmap_changed_pixels;
      }
      bitmap[target_offset] = monochrome;
      bitmap[target_offset + 1] = monochrome;
      bitmap[target_offset + 2] = monochrome;
    }
  }
  SetBkMode(memory_dc, previous_background_mode);
  SelectObject(memory_dc, previous_bitmap);
  DeleteObject(dib);
  DeleteDC(memory_dc);
  return true;
#endif
}

bool DrawPrintTestWatermark(HDC printer_dc, int destination_x,
                            int destination_y, int target_width,
                            int target_height, std::string& error) {
  const int dc_state = SaveDC(printer_dc);
  if (dc_state == 0) {
    error = "SaveDC for print watermark failed: " +
            std::to_string(GetLastError());
    return false;
  }
  SetMapMode(printer_dc, MM_TEXT);
  SetBkMode(printer_dc, TRANSPARENT);
  SetTextColor(printer_dc, RGB(0, 0, 0));
  HFONT font = CreateFontW(
      -7, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
      DEFAULT_PITCH | FF_DONTCARE, L"Arial");
  if (font == nullptr) {
    RestoreDC(printer_dc, dc_state);
    error = "CreateFontW for print watermark failed: " +
            std::to_string(GetLastError());
    return false;
  }
  HGDIOBJ previous_font = SelectObject(printer_dc, font);
  SIZE text_size{};
  const int text_length =
      static_cast<int>(std::size(kPrintTestWatermark) - 1);
  const BOOL measured = GetTextExtentPoint32W(
      printer_dc, kPrintTestWatermark, text_length, &text_size);
  const int measured_width = measured ? static_cast<int>(text_size.cx) : 32;
  const int measured_height = measured ? static_cast<int>(text_size.cy) : 7;
  const int left = std::max(
      destination_x,
      destination_x + target_width - measured_width - 2);
  const int top = std::max(
      destination_y,
      destination_y + target_height - measured_height - 2);
  const BOOL drawn = TextOutW(printer_dc, left, top, kPrintTestWatermark,
                              text_length);
  SelectObject(printer_dc, previous_font);
  DeleteObject(font);
  RestoreDC(printer_dc, dc_state);
  if (drawn == 0) {
    error = "TextOutW for print watermark failed: " +
            std::to_string(GetLastError());
    return false;
  }
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
  const bool godex_v1358_driver_direct = legacy_printer_type == "godex";
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
              << " fontOutputPrecision=OUT_DEFAULT_PRECIS"
              << " nativeTextFitMode=uniformScale"
                    << " outputMode="
                    << (godex_v1358_driver_direct
                      ? "driverDirect32V1358+legacyInverse"
                      : "monoDibBoxedHeader")
                    << " nativeTextRaster="
                    << (godex_v1358_driver_direct
                      ? "printerDcDirect32+legacyInverse"
                      : "boxedHeaderBlackOnWhite")
                    << " nativeTextWhiteRender="
                    << (godex_v1358_driver_direct ? "legacyRichEditPrinterDc"
                           : "fullRowPolarityFallback")
                    << " printWatermark=v1.3.93"
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
    struct MonoBitmapInfo {
      BITMAPINFOHEADER header{};
      RGBQUAD colors[2]{};
    } mono_info;
    mono_info.header.biSize = sizeof(BITMAPINFOHEADER);
    mono_info.header.biWidth = target_width;
    mono_info.header.biHeight = -target_height;
    mono_info.header.biPlanes = 1;
    mono_info.header.biBitCount = 1;
    mono_info.header.biCompression = BI_RGB;
    mono_info.header.biClrUsed = 2;
    mono_info.header.biClrImportant = 2;
    mono_info.colors[0] = RGBQUAD{255, 255, 255, 0};
    mono_info.colors[1] = RGBQUAD{0, 0, 0, 0};
    void* mono_bits = nullptr;
    HDC page_dc = godex_v1358_driver_direct
                      ? printer_dc
                      : CreateCompatibleDC(printer_dc);
    HBITMAP mono_bitmap = nullptr;
    HGDIOBJ previous_page_bitmap = nullptr;
    if (!godex_v1358_driver_direct) {
      mono_bitmap = CreateDIBSection(
          printer_dc, reinterpret_cast<BITMAPINFO*>(&mono_info), DIB_RGB_COLORS,
          &mono_bits, nullptr, 0);
      if (page_dc == nullptr || mono_bitmap == nullptr || mono_bits == nullptr) {
        if (mono_bitmap != nullptr) DeleteObject(mono_bitmap);
        if (page_dc != nullptr) DeleteDC(page_dc);
        error = "CreateDIBSection 1bpp page failed: " +
                std::to_string(GetLastError());
        break;
      }
      previous_page_bitmap = SelectObject(page_dc, mono_bitmap);
      RECT page_rect{0, 0, target_width, target_height};
      FillRect(page_dc, &page_rect,
               reinterpret_cast<HBRUSH>(GetStockObject(WHITE_BRUSH)));
    }
    auto composed_bitmap = ComposeFinalDeviceBitmap(
        *bgra, source_width, source_height, target_width, target_height,
        border_descriptors);
    NativeTextRenderStats native_text_stats;
    BITMAPINFO bitmap_info{};
    bitmap_info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bitmap_info.bmiHeader.biWidth = target_width;
    bitmap_info.bmiHeader.biHeight = -target_height;
    bitmap_info.bmiHeader.biPlanes = 1;
    bitmap_info.bmiHeader.biBitCount = 32;
    bitmap_info.bmiHeader.biCompression = BI_RGB;
    const int previous_mode = SetStretchBltMode(page_dc, COLORONCOLOR);
    const int scan_lines = StretchDIBits(
      page_dc, destination_x, destination_y, target_width, target_height,
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
      InverseRowFallbackStats inverse_row_fallback_stats;
      auto render_text_descriptors = text_descriptors;
      if (!godex_v1358_driver_direct) {
        render_text_descriptors = PrepareInverseRowFallback(
            page_dc, composed_bitmap, target_width, target_height, source_width,
            source_height, text_descriptors, inverse_row_fallback_stats);
      } else {
        render_text_descriptors.erase(
            std::remove_if(
                render_text_descriptors.begin(), render_text_descriptors.end(),
                [](const NativeTextDescriptor& descriptor) {
                  return descriptor.color == RGB(255, 255, 255);
                }),
            render_text_descriptors.end());
      }
        const bool legacy_inverse_rendered =
          !godex_v1358_driver_direct || RenderWhiteTextIntoBitmap(
            composed_bitmap, target_width, target_height, source_width,
            source_height, text_descriptors, page_dc, native_text_stats,
            error, diagnostics);
        if (legacy_inverse_rendered && !RenderNativeTextToPrinterDc(
              composed_bitmap, target_width, target_height, source_width,
              source_height, render_text_descriptors, page_dc,
              native_text_stats, error)) {
        } else if (legacy_inverse_rendered && !DrawPrintTestWatermark(
               page_dc, destination_x, destination_y, target_width,
               target_height, error)) {
        } else if (legacy_inverse_rendered) {
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
                  << " inverseTextWidthFitted="
                  << native_text_stats.inverse_width_fitted
                  << " nativeTextWhiteBitmapDrawn="
                  << native_text_stats.white_bitmap_drawn
                  << " nativeTextWhiteDirectDrawn="
                  << native_text_stats.white_bitmap_drawn
                  << " nativeTextWhiteKnockoutPixels="
                  << native_text_stats.white_knockout_pixels
                  << " nativeTextWhiteGlyphBitmaps="
                  << native_text_stats.white_glyph_bitmaps
                  << " nativeTextOutlineFonts="
                  << native_text_stats.outline_fonts
                  << " nativeTextNoOutlineFonts="
                  << native_text_stats.no_outline_fonts
                  << " nativeTextCharacters=" << native_text_stats.characters
                  << " nativeTextMapping=anisotropicSplit"
                  << " nativeTextComposite="
                  << (godex_v1358_driver_direct
                          ? "bitmapThenLegacyRichEditWhiteThenBlackPrinterDc"
                          : "boxedHeaderMonoDib")
                  << " inverseRowFallbackDescriptors="
                  << inverse_row_fallback_stats.descriptors
                  << " inverseRowFallbackBands="
                  << inverse_row_fallback_stats.bands
                  << " inverseRowClearedPixels="
                  << inverse_row_fallback_stats.cleared_pixels
                  << " inverseDriverGray=disabledAfterPhysicalFailure"
                  << " nativeBorderMapping=devicePixels"
                  << " nativeBorderThickness=oneDeviceDot"
                  << " nativeBorderJunction=singleFinalDeviceBitmap"
                  << " nativeBorderComposite="
                  << "finalDeviceBitmap"
                  << " nativeBorderBitmapLines=" << scan_lines
                  << " nativeBorderFillRects=" << native_border_fill_rects
                  << " nativeBordersDrawn=" << native_borders_drawn;
      if (native_text_stats.failed > 0) {
        error = "Native text rendering failed: " +
                std::to_string(native_text_stats.failed);
      }
      }
    }
    GdiFlush();
    int mono_scan_lines = 0;
    if (error.empty() && !godex_v1358_driver_direct) {
      mono_scan_lines = SetDIBitsToDevice(
          printer_dc, destination_x, destination_y, target_width,
          target_height, 0, 0, 0, target_height, mono_bits,
          reinterpret_cast<BITMAPINFO*>(&mono_info), DIB_RGB_COLORS);
      if (mono_scan_lines == 0 || mono_scan_lines == GDI_ERROR) {
        error = "SetDIBitsToDevice 1bpp failed: " +
                std::to_string(GetLastError());
      }
    }
    diagnostics << " spoolFormat="
                << (godex_v1358_driver_direct ? "DIB_32BPP_DRIVER_DIRECT"
                                               : "DIB_1BPP_DEVICE")
                << " monoStride=" << ((target_width + 31) / 32) * 4
                << " monoScanLines=" << mono_scan_lines
                << " monoPalette=zeroWhiteOneBlack"
                << " inversePolarity="
                << (godex_v1358_driver_direct ? "originalWhiteOnBlack"
                                               : "boxedHeaderBlackOnWhite")
                << " coolingPattern=disabledAfterPhysicalFailure";
    if (!godex_v1358_driver_direct) {
      SelectObject(page_dc, previous_page_bitmap);
      DeleteObject(mono_bitmap);
      DeleteDC(page_dc);
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
