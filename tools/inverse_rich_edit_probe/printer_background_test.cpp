// Exercise the production compositor without opening a printer or print job.
#include "../../windows/runner/label_bitmap_print_channel.cpp"

#include <iostream>
#include <stdexcept>

namespace {

void Require(bool condition, const char* message) {
  if (!condition) throw std::runtime_error(message);
}

struct MonoPage {
  struct Info {
    BITMAPINFOHEADER header{};
    RGBQUAD colors[2]{};
  } info;
  HDC dc = nullptr;
  HBITMAP bitmap = nullptr;
  HGDIOBJ previous = nullptr;
  void* pixels = nullptr;
  int stride;

  MonoPage(int width, int height) : stride(((width + 31) / 32) * 4) {
    info.header.biSize = sizeof(BITMAPINFOHEADER);
    info.header.biWidth = width;
    info.header.biHeight = -height;
    info.header.biPlanes = 1;
    info.header.biBitCount = 1;
    info.colors[0] = RGBQUAD{255, 255, 255, 0};
    info.colors[1] = RGBQUAD{0, 0, 0, 0};
    dc = CreateCompatibleDC(nullptr);
    if (dc != nullptr) {
      bitmap = CreateDIBSection(
          dc, reinterpret_cast<BITMAPINFO*>(&info), DIB_RGB_COLORS,
          &pixels, nullptr, 0);
    }
    if (bitmap != nullptr) previous = SelectObject(dc, bitmap);
  }

  ~MonoPage() {
    if (previous != nullptr && previous != HGDI_ERROR) SelectObject(dc, previous);
    if (bitmap != nullptr) DeleteObject(bitmap);
    if (dc != nullptr) DeleteDC(dc);
  }

  int BlackPixels(const RECT& area) const {
    const auto* bits = static_cast<const uint8_t*>(pixels);
    int count = 0;
    for (LONG y = area.top; y < area.bottom; ++y) {
      for (LONG x = area.left; x < area.right; ++x) {
        if ((bits[static_cast<size_t>(y) * stride + x / 8] &
             (0x80 >> (x % 8))) != 0) ++count;
      }
    }
    return count;
  }
};

RECT ScaleRect(const RECT& rect, int width, int height) {
  return {MulDiv(rect.left, width, 640), MulDiv(rect.top, height, 480),
          MulDiv(rect.right, width, 640), MulDiv(rect.bottom, height, 480)};
}

NativeTextDescriptor Text(const wchar_t* text, const RECT& rect,
                          COLORREF color, int font_height) {
  NativeTextDescriptor result;
  result.text = text;
  result.rect = rect;
  result.color = color;
  result.font_family = L"\uad74\ub9bc";
  result.font_pixel_height = font_height;
  result.bold = true;
  result.horizontal_align = "1";
  result.vertical_align = "1";
  return result;
}

void VerifyMonoBackground(const char* name, int width, int height,
                          int source_width, int source_height) {
  std::vector<uint8_t> source(
      static_cast<size_t>(source_width) * source_height * 4, 255);
  const RECT band = ScaleRect({8, 200, 632, 232}, source_width, source_height);
  const RECT panel = ScaleRect({12, 60, 152, 92}, source_width, source_height);
  for (const RECT& area : {band, panel}) {
    for (LONG y = area.top; y < area.bottom; ++y) {
      for (LONG x = area.left; x < area.right; ++x) {
        const size_t offset =
            (static_cast<size_t>(y) * source_width + x) * 4;
        source[offset] = source[offset + 1] = source[offset + 2] = 0;
      }
    }
  }
  const auto original = source;
  auto composed = ComposeFinalDeviceBitmap(
      source, source_width, source_height, width, height, {});
  const int font_height = MulDiv(17, source_height, 480);
  const std::vector<NativeTextDescriptor> descriptors{
      Text(L"\uc601\uc591\uc815\ubcf4",
           ScaleRect({16, 204, 140, 228}, source_width, source_height),
           RGB(255, 255, 255), font_height),
      Text(L"\ucd1d\ub0b4\uc6a9\ub7c9 105g 276kcal",
           ScaleRect({180, 204, 620, 228}, source_width, source_height),
           RGB(255, 255, 255), font_height),
      Text(L"Partial",
           ScaleRect({20, 64, 144, 88}, source_width, source_height),
           RGB(255, 255, 255), font_height),
      Text(L"Plain text",
           ScaleRect({20, 260, 300, 290}, source_width, source_height),
           RGB(0, 0, 0), font_height),
  };
  MonoPage page(width, height);
  Require(page.dc != nullptr && page.pixels != nullptr &&
              page.previous != nullptr && page.previous != HGDI_ERROR,
          "Cannot create monochrome memory page");
  BITMAPINFO info{};
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  info.bmiHeader.biWidth = width;
  info.bmiHeader.biHeight = -height;
  info.bmiHeader.biPlanes = 1;
  info.bmiHeader.biBitCount = 32;
  SetStretchBltMode(page.dc, COLORONCOLOR);
  Require(StretchDIBits(page.dc, 0, 0, width, height, 0, 0, width, height,
                       composed.data(), &info, DIB_RGB_COLORS, SRCCOPY) > 0,
          "Cannot transfer background to monochrome page");
  const auto render = PrepareDriverTextDescriptors(descriptors, false);
  NativeTextRenderStats stats;
  std::string error;
  Require(RenderNativeTextToPrinterDc(composed, width, height, source_width,
                                     source_height, render, page.dc, stats, error),
          error.c_str());
  GdiFlush();
  Require(stats.failed == 0 && stats.drawn == 4, "Native text rendering failed");
  const auto output_band = ScaleRect({8, 200, 632, 232}, width, height);
  const int band_area = (output_band.right - output_band.left) *
                        (output_band.bottom - output_band.top);
  Require(page.BlackPixels(output_band) > band_area * 3 / 4,
          "Black header background was cleared");
  for (size_t i = 0; i < 3; ++i) {
    const auto area = MapNativeTextToDevice(
        descriptors[i].rect, font_height, source_width, source_height,
        width, height).rect;
    const int pixels = (area.right - area.left) * (area.bottom - area.top);
    const int black = page.BlackPixels(area);
    Require(black > pixels / 2 && pixels - black > 10,
            "White text on black background was not preserved");
    Require(render[i].color == RGB(255, 255, 255),
            "Native white text color was changed");
  }
  Require(page.BlackPixels(ScaleRect({20, 260, 300, 290}, width, height)) > 10,
          "Ordinary black text disappeared");
  Require(page.BlackPixels(ScaleRect({400, 60, 620, 92}, width, height)) == 0,
          "Unrelated white background changed");
  Require(source == original, "Source bitmap was mutated");
  const auto direct = PrepareDriverTextDescriptors(descriptors, true);
  Require(direct.size() == 1 && direct.front().text == L"Plain text",
          "GoDEX white text must remain in its separate inverse compositor");
  std::cout << name << "=PASS headerBlackPixels="
            << page.BlackPixels(output_band) << "/" << band_area << "\n";
}

}  // namespace

int main() {
  try {
    VerifyMonoBackground("D420_203dpi", 639, 480, 639, 480);
    VerifyMonoBackground("Zebra_300dpi", 945, 709, 945, 709);
    VerifyMonoBackground("driver_resample", 639, 480, 1280, 960);
    VerifyMonoBackground("other_driver", 640, 480, 640, 480);
    return 0;
  } catch (const std::exception& error) {
    std::cerr << "printerBackground=FAIL " << error.what() << "\n";
    return 1;
  }
}
