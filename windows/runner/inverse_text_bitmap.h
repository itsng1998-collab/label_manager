#ifndef RUNNER_INVERSE_TEXT_BITMAP_H_
#define RUNNER_INVERSE_TEXT_BITMAP_H_

#include <windows.h>
#include <algorithm>
#include <cstdint>
#include <vector>

struct InverseBitmapResult {
  bool success = false;
  size_t changed_pixels = 0;
  size_t gray_pixels = 0;
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
  BITMAPINFO info{};
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  info.bmiHeader.biWidth = width;
  info.bmiHeader.biHeight = -height;
  info.bmiHeader.biPlanes = 1;
  info.bmiHeader.biBitCount = 32;
  void* pixels = nullptr;
  HBITMAP bitmap = CreateDIBSection(memory, &info, DIB_RGB_COLORS,
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
  std::copy(base.begin(), base.end(), static_cast<uint8_t*>(pixels));
  RECT area{std::max<LONG>(0, clip.left), std::max<LONG>(0, clip.top),
            std::min<LONG>(width, clip.right), std::min<LONG>(height, clip.bottom)};
  IntersectClipRect(memory, area.left, area.top, area.right, area.bottom);
  // NULL DC 개별 명령 재생은 변환 명령 실패로 폐기. 페이지 폭 대신 참조 장치의 프레임 좌표를 사용한다.
  result.success = PlayEnhMetaFile(memory, metafile, &destination) != FALSE;
  GdiFlush();
  if (result.success) {
    const auto* rendered = static_cast<const uint8_t*>(pixels);
    for (LONG row = area.top; row < area.bottom; ++row) {
      for (LONG column = area.left; column < area.right; ++column) {
        const size_t offset = (static_cast<size_t>(row) * width + column) * 4;
        const unsigned luminance = 77 * rendered[offset + 2] +
                                   150 * rendered[offset + 1] +
                                   29 * rendered[offset];
        const uint8_t value = luminance >= 128 * 256 ? 255 : 0;
        if (luminance != 0 && luminance != 255 * 256) ++result.gray_pixels;
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