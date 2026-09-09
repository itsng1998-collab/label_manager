#ifndef RUNNER_INVERSE_TEXT_GEOMETRY_H_
#define RUNNER_INVERSE_TEXT_GEOMETRY_H_

#include <windows.h>
#include <algorithm>
#include <cstdint>
#include <cstring>
#include <vector>

struct InverseTextGeometry {
  bool success = false;
  std::vector<RECT> black_runs;
  size_t black_pixels = 0;
  size_t white_pixels = 0;
};

inline InverseTextGeometry PrepareInverseTextGeometry(
    std::vector<uint8_t>& raster, int width, int height,
    const std::vector<RECT>& clips) {
  InverseTextGeometry result;
  if (width <= 0 || height <= 0 ||
      raster.size() != static_cast<size_t>(width) * height * 4) return result;
  for (int row = 0; row < height; ++row) {
    int run_start = -1;
    for (int column = 0; column <= width; ++column) {
      const bool inside = column < width && std::any_of(
          clips.begin(), clips.end(), [&](const RECT& clip) {
            return column >= clip.left && column < clip.right &&
                   row >= clip.top && row < clip.bottom;
          });
      bool black = false;
      if (inside) {
        const size_t offset = (static_cast<size_t>(row) * width + column) * 4;
        const uint8_t value = raster[offset];
        if ((value != 0 && value != 255) || raster[offset + 1] != value ||
            raster[offset + 2] != value) return result;
        black = value == 0;
        if (black) ++result.black_pixels;
        else ++result.white_pixels;
      }
      if (black && run_start < 0) run_start = column;
      if (!black && run_start >= 0) {
        result.black_runs.push_back(RECT{run_start, row, column, row + 1});
        run_start = -1;
      }
    }
  }
  for (const auto& run : result.black_runs) {
    for (LONG column = run.left; column < run.right; ++column) {
      const size_t offset = (static_cast<size_t>(run.top) * width + column) * 4;
      raster[offset] = 255;
      raster[offset + 1] = 255;
      raster[offset + 2] = 255;
    }
  }
  result.success = true;
  return result;
}

inline bool RenderInverseTextGeometry(HDC target,
                                      const InverseTextGeometry& geometry,
                                      int destination_x, int destination_y) {
  if (!geometry.success) return false;
  if (geometry.black_runs.empty()) return true;
  const size_t data_size = sizeof(RGNDATAHEADER) +
                           geometry.black_runs.size() * sizeof(RECT);
  std::vector<DWORD> storage((data_size + sizeof(DWORD) - 1) / sizeof(DWORD));
  auto* data = reinterpret_cast<RGNDATA*>(storage.data());
  data->rdh.dwSize = sizeof(RGNDATAHEADER);
  data->rdh.iType = RDH_RECTANGLES;
  data->rdh.nCount = static_cast<DWORD>(geometry.black_runs.size());
  data->rdh.nRgnSize = static_cast<DWORD>(geometry.black_runs.size() * sizeof(RECT));
  data->rdh.rcBound = geometry.black_runs.front();
  for (const auto& run : geometry.black_runs) {
    data->rdh.rcBound.left = std::min(data->rdh.rcBound.left, run.left);
    data->rdh.rcBound.top = std::min(data->rdh.rcBound.top, run.top);
    data->rdh.rcBound.right = std::max(data->rdh.rcBound.right, run.right);
    data->rdh.rcBound.bottom = std::max(data->rdh.rcBound.bottom, run.bottom);
  }
  std::memcpy(data->Buffer, geometry.black_runs.data(),
              geometry.black_runs.size() * sizeof(RECT));
  HRGN region = ExtCreateRegion(nullptr, static_cast<DWORD>(data_size), data);
  if (region == nullptr) return false;
  const bool rendered = OffsetRgn(region, destination_x, destination_y) != ERROR &&
      FillRgn(target, region, static_cast<HBRUSH>(GetStockObject(BLACK_BRUSH))) != FALSE;
  DeleteObject(region);
  return rendered;
}

#endif