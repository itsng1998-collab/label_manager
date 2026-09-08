#ifndef RUNNER_NATIVE_TEXT_COMPARISON_H_
#define RUNNER_NATIVE_TEXT_COMPARISON_H_

#include <windows.h>
#include <algorithm>
#include <cstdint>
#include <vector>

struct NativeTextComparison {
  bool success = false;
  std::vector<uint8_t> pixels;
  std::vector<size_t> inverse_white_pixels_lost;
};

inline NativeTextComparison ReplayNativeTextComparison(
    HDC printer, HENHMETAFILE metafile, const std::vector<uint8_t>& base,
    int width, int height, const std::vector<RECT>& inverse_areas) {
  NativeTextComparison result;
  if (width <= 0 || height <= 0 ||
      base.size() != static_cast<size_t>(width) * height * 4) return result;
  ENHMETAHEADER header{};
  if (GetEnhMetaFileHeader(metafile, sizeof(header), &header) == 0 ||
      header.szlMillimeters.cx <= 0 || header.szlMillimeters.cy <= 0) return result;
  RECT destination{
      MulDiv(header.rclFrame.left, header.szlDevice.cx, header.szlMillimeters.cx * 100),
      MulDiv(header.rclFrame.top, header.szlDevice.cy, header.szlMillimeters.cy * 100),
      MulDiv(header.rclFrame.right, header.szlDevice.cx, header.szlMillimeters.cx * 100),
      MulDiv(header.rclFrame.bottom, header.szlDevice.cy, header.szlMillimeters.cy * 100)};
  result.pixels = base;
  result.inverse_white_pixels_lost.resize(inverse_areas.size(), 0);
  HDC memory = CreateCompatibleDC(printer);
  if (memory == nullptr) return result;
  BITMAPINFO info{};
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  info.bmiHeader.biWidth = width;
  info.bmiHeader.biHeight = -height;
  info.bmiHeader.biPlanes = 1;
  info.bmiHeader.biBitCount = 32;
  void* pixels = nullptr;
  HBITMAP bitmap = CreateDIBSection(memory, &info, DIB_RGB_COLORS, &pixels, nullptr, 0);
  if (bitmap == nullptr || pixels == nullptr) {
    if (bitmap != nullptr) DeleteObject(bitmap);
    DeleteDC(memory);
    return result;
  }
  HGDIOBJ previous = SelectObject(memory, bitmap);
  if (previous == nullptr || previous == HGDI_ERROR) {
    DeleteObject(bitmap);
    DeleteDC(memory);
    return result;
  }
  std::copy(base.begin(), base.end(), static_cast<uint8_t*>(pixels));
  result.success = PlayEnhMetaFile(memory, metafile, &destination) != FALSE;
  GdiFlush();
  if (result.success) {
    const auto* rendered = static_cast<const uint8_t*>(pixels);
    for (size_t offset = 0; offset < base.size(); offset += 4) {
      std::copy_n(rendered + offset, 3, result.pixels.begin() + offset);
    }
    for (size_t index = 0; index < inverse_areas.size(); ++index) {
      const auto& area = inverse_areas[index];
      for (LONG row = std::max<LONG>(0, area.top);
           row < std::min<LONG>(height, area.bottom); ++row) {
        for (LONG column = std::max<LONG>(0, area.left);
             column < std::min<LONG>(width, area.right); ++column) {
          const size_t offset = (static_cast<size_t>(row) * width + column) * 4;
          const bool was_white = base[offset] == 255 && base[offset + 1] == 255 &&
                                 base[offset + 2] == 255;
          const unsigned luminance = 77 * rendered[offset + 2] +
                                     150 * rendered[offset + 1] + 29 * rendered[offset];
          if (was_white && luminance < 128 * 256) {
            ++result.inverse_white_pixels_lost[index];
          }
        }
      }
    }
  }
  SelectObject(memory, previous);
  DeleteObject(bitmap);
  DeleteDC(memory);
  return result;
}

#endif