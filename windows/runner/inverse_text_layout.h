#ifndef RUNNER_INVERSE_TEXT_LAYOUT_H_
#define RUNNER_INVERSE_TEXT_LAYOUT_H_

#include <windows.h>
#include <richedit.h>
#include <algorithm>
#include <string>

struct InverseTextLayout {
  FORMATRANGE range{};
  XFORM transform{1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f};
  int width = 0;
  bool fitted = false;
  bool all_characters_fit = false;
};

inline InverseTextLayout MeasureInverseTextLayout(
    HWND edit, HDC printer, const RECT& clip, const std::wstring& text,
    bool wrap) {
  InverseTextLayout layout;
  const int dpi_x = GetDeviceCaps(printer, LOGPIXELSX);
  const int dpi_y = GetDeviceCaps(printer, LOGPIXELSY);
  const int width = clip.right - clip.left;
  layout.width = width;
  layout.range.hdc = printer;
  layout.range.hdcTarget = printer;
  layout.range.rcPage = {
      0, 0, MulDiv(GetDeviceCaps(printer, PHYSICALWIDTH), 1440, dpi_x),
      MulDiv(GetDeviceCaps(printer, PHYSICALHEIGHT), 1440, dpi_y)};
  layout.range.chrg.cpMax = static_cast<LONG>(text.size());
  const auto measure = [&](int candidate) {
    layout.range.rc = {MulDiv(clip.left, 1440, dpi_x),
                       MulDiv(clip.top, 1440, dpi_y),
                       MulDiv(clip.left + candidate, 1440, dpi_x),
                       MulDiv(clip.bottom, 1440, dpi_y)};
    FORMATRANGE measured = layout.range;
    const LRESULT until = SendMessageW(edit, EM_FORMATRANGE, FALSE,
                                       reinterpret_cast<LPARAM>(&measured));
    SendMessageW(edit, EM_FORMATRANGE, FALSE, 0);
    return until >= static_cast<LRESULT>(text.size());
  };
  layout.all_characters_fit = measure(width);
  if (layout.all_characters_fit || wrap ||
      text.find_first_of(L"\r\n") != std::wstring::npos) return layout;
  int lower = width;
  int upper = width;
  for (int attempt = 0; attempt < 3 && !layout.all_characters_fit; ++attempt) {
    upper *= 2;
    layout.all_characters_fit = measure(upper);
  }
  if (!layout.all_characters_fit) {
    measure(width);
    return layout;
  }
  while (upper - lower > 1) {
    const int candidate = lower + (upper - lower) / 2;
    if (measure(candidate)) {
      upper = candidate;
    } else {
      lower = candidate;
    }
  }
  measure(upper);
  layout.width = upper;
  layout.fitted = true;
  layout.transform.eM11 = static_cast<FLOAT>(width) / upper;
  layout.transform.eDx = clip.left * (1.0f - layout.transform.eM11);
  return layout;
}

#endif