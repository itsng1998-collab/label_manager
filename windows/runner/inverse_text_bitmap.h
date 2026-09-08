#ifndef RUNNER_INVERSE_TEXT_BITMAP_H_
#define RUNNER_INVERSE_TEXT_BITMAP_H_

#include <windows.h>
#include <algorithm>
#include <cstdint>
#include <vector>

struct InverseBitmapResult {
  bool success = false;
  size_t changed_pixels = 0;
  WORD raster_bit_count = 0;
};

inline InverseBitmapResult CompositeInverseTextBitmap(
    HDC printer, HENHMETAFILE metafile, const RECT& clip, int width, int height,
    std::vector<uint8_t>& base) {
  InverseBitmapResult result;
  if (width <= 0 || height <= 0 ||
      base.size() != static_cast<size_t>(width) * height * 4) return result;
    ENHMETAHEADER metafile_header{};
    if (GetEnhMetaFileHeader(metafile, sizeof(metafile_header), &metafile_header) == 0 ||
        metafile_header.szlMillimeters.cx <= 0 || metafile_header.szlMillimeters.cy <= 0) {
      return result;
    }
    const RECT destination{
        MulDiv(metafile_header.rclFrame.left, metafile_header.szlDevice.cx,
          metafile_header.szlMillimeters.cx * 100),
        MulDiv(metafile_header.rclFrame.top, metafile_header.szlDevice.cy,
          metafile_header.szlMillimeters.cy * 100),
        MulDiv(metafile_header.rclFrame.right, metafile_header.szlDevice.cx,
          metafile_header.szlMillimeters.cx * 100),
        MulDiv(metafile_header.rclFrame.bottom, metafile_header.szlDevice.cy,
          metafile_header.szlMillimeters.cy * 100)};
  HDC memory = CreateCompatibleDC(printer);
  if (memory == nullptr) return result;
  struct MonochromeBitmapInfo {
    BITMAPINFOHEADER header{};
    RGBQUAD colors[2]{};
  } info;
  info.header.biSize = sizeof(BITMAPINFOHEADER);
  info.header.biWidth = width;
  info.header.biHeight = -height;
  info.header.biPlanes = 1;
  info.header.biBitCount = 1;
  info.colors[1] = RGBQUAD{255, 255, 255, 0};
  const size_t stride = (static_cast<size_t>(width) + 31) / 32 * 4;
  void* pixels = nullptr;
  HBITMAP bitmap = CreateDIBSection(memory, reinterpret_cast<BITMAPINFO*>(&info), DIB_RGB_COLORS,
                                   &pixels, nullptr, 0);
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
  BITMAP bitmap_details{};
  GetObjectW(bitmap, sizeof(bitmap_details), &bitmap_details);
  result.raster_bit_count = bitmap_details.bmBitsPixel;
  auto* bits = static_cast<uint8_t*>(pixels);
  std::fill(bits, bits + stride * height, uint8_t{0});
  for (int row = 0; row < height; ++row) {
    for (int column = 0; column < width; ++column) {
      const size_t offset = (static_cast<size_t>(row) * width + column) * 4;
      const unsigned luminance = 77 * base[offset + 2] +
                                 150 * base[offset + 1] + 29 * base[offset];
      if (luminance >= 128 * 256) {
        bits[static_cast<size_t>(row) * stride + column / 8] |=
            static_cast<uint8_t>(0x80 >> (column % 8));
      }
    }
  }
  RECT area{std::max<LONG>(0, clip.left), std::max<LONG>(0, clip.top),
            std::min<LONG>(width, clip.right), std::min<LONG>(height, clip.bottom)};
  IntersectClipRect(memory, area.left, area.top, area.right, area.bottom);
  // NULL DC 개별 명령 재생은 변환 명령 실패로 폐기. 페이지 폭 대신 참조 장치의 프레임 좌표를 사용한다.
  result.success = PlayEnhMetaFile(memory, metafile, &destination) != FALSE;
  GdiFlush();
  result.success = result.success && result.raster_bit_count == 1;
  if (result.success) {
    const auto* rendered = static_cast<const uint8_t*>(pixels);
    for (LONG row = area.top; row < area.bottom; ++row) {
      for (LONG column = area.left; column < area.right; ++column) {
        const size_t offset = (static_cast<size_t>(row) * width + column) * 4;
        // v1.3.95의 컬러 렌더 후 임계값 변환은 실물 획 소실이 남아 재사용하지 않는다.
        const uint8_t value =
          (rendered[static_cast<size_t>(row) * stride + column / 8] &
           (0x80 >> (column % 8))) != 0 ? 255 : 0;
        if (base[offset] != value || base[offset + 1] != value ||
            base[offset + 2] != value) ++result.changed_pixels;
        base[offset] = value;
        base[offset + 1] = value;
        base[offset + 2] = value;
      }
    }
  }
  SelectObject(memory, previous);
  DeleteObject(bitmap);
  DeleteDC(memory);
  return result;
}

#endif