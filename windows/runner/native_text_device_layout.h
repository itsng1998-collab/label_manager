#ifndef RUNNER_NATIVE_TEXT_DEVICE_LAYOUT_H_
#define RUNNER_NATIVE_TEXT_DEVICE_LAYOUT_H_

#include <windows.h>
#include <algorithm>

struct NativeTextDeviceLayout {
  RECT rect{};
  int font_height = 0;
};

inline NativeTextDeviceLayout MapNativeTextToDevice(
    const RECT& source_rect, int source_font_height,
    int source_width, int source_height, int target_width, int target_height) {
  return {{MulDiv(source_rect.left, target_width, source_width),
           MulDiv(source_rect.top, target_height, source_height),
           MulDiv(source_rect.right, target_width, source_width),
           MulDiv(source_rect.bottom, target_height, source_height)},
          std::max(1, MulDiv(source_font_height, target_height, source_height))};
}

inline bool SetNativeTextDeviceCoordinates(HDC target) {
  return SetMapMode(target, MM_TEXT) != 0 &&
         SetWindowOrgEx(target, 0, 0, nullptr) != FALSE &&
         SetViewportOrgEx(target, 0, 0, nullptr) != FALSE;
}

#endif