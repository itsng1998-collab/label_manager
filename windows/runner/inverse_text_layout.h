#ifndef RUNNER_INVERSE_TEXT_LAYOUT_H_
#define RUNNER_INVERSE_TEXT_LAYOUT_H_

#include <windows.h>
#include <richedit.h>
#include <algorithm>
#include <string>
#include <vector>

struct InverseTextLayout {
  FORMATRANGE range{};
  XFORM transform{1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f};
  int width = 0;
  bool fitted = false;
  int padding_reduction_twips = 0;
  LRESULT original_typography_options = 0;
  bool all_characters_fit = false;
};

inline InverseTextLayout MeasureInverseTextLayout(
    HWND edit, HDC printer, const RECT& clip, const std::wstring& text,
    bool wrap) {
  InverseTextLayout layout;
  layout.original_typography_options =
      SendMessageW(edit, EM_GETTYPOGRAPHYOPTIONS, 0, 0);
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
      text.find_first_of(L"\r\n") != std::wstring::npos)
    return layout;
  struct PaddingRun {
    CHARRANGE selection;
    SHORT spacing;
    int available_twips;
  };
  std::vector<PaddingRun> padding_runs;
  CHARRANGE original_selection{};
  SendMessageW(edit, EM_EXGETSEL, 0,
               reinterpret_cast<LPARAM>(&original_selection));
  for (size_t start = 0; start < text.size();) {
    if (text[start] != L' ') {
      ++start;
      continue;
    }
    size_t end = start + 1;
    while (end < text.size() && text[end] == L' ') ++end;
    if (start > 0 && end < text.size() && end - start >= 2) {
      CHARRANGE selection{static_cast<LONG>(start), static_cast<LONG>(end)};
      SendMessageW(edit, EM_EXSETSEL, 0, reinterpret_cast<LPARAM>(&selection));
      CHARFORMAT2W format{};
      format.cbSize = sizeof(format);
      SendMessageW(edit, EM_GETCHARFORMAT, SCF_SELECTION,
                   reinterpret_cast<LPARAM>(&format));
      const DWORD uniform_mask =
          CFM_FACE | CFM_SIZE | CFM_BOLD | CFM_ITALIC | CFM_SPACING;
      if ((format.dwMask & uniform_mask) == uniform_mask) {
        HFONT font = CreateFontW(
            -MulDiv(format.yHeight, dpi_y, 1440), 0, 0, 0,
            (format.dwEffects & CFE_BOLD) ? FW_BOLD : FW_NORMAL,
            (format.dwEffects & CFE_ITALIC) != 0, FALSE, FALSE, format.bCharSet,
            OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
            DEFAULT_PITCH, format.szFaceName);
        if (font != nullptr) {
          HGDIOBJ previous_font = SelectObject(printer, font);
          SIZE advance{};
          const BOOL measured =
              GetTextExtentPoint32W(printer, L" ", 1, &advance);
          SelectObject(printer, previous_font);
          DeleteObject(font);
          if (measured && advance.cx > 1) {
            padding_runs.push_back(
                {selection, format.sSpacing,
                 std::max(0, MulDiv(advance.cx - 1, 1440, dpi_x) +
                                 format.sSpacing)});
          }
        }
      }
    }
    start = end;
  }
  const auto set_padding = [&](int reduction) {
    for (const auto& padding : padding_runs) {
      SendMessageW(edit, EM_EXSETSEL, 0,
                   reinterpret_cast<LPARAM>(&padding.selection));
      CHARFORMAT2W format{};
      format.cbSize = sizeof(format);
      format.dwMask = CFM_SPACING;
      format.sSpacing = static_cast<SHORT>(
          padding.spacing - std::min(reduction, padding.available_twips));
      SendMessageW(edit, EM_SETCHARFORMAT, SCF_SELECTION,
                   reinterpret_cast<LPARAM>(&format));
    }
    SendMessageW(edit, EM_EXSETSEL, 0,
                 reinterpret_cast<LPARAM>(&original_selection));
  };
  int maximum_reduction = 0;
  for (const auto& padding : padding_runs) {
    maximum_reduction = std::max(maximum_reduction, padding.available_twips);
  }
  if (maximum_reduction > 0) {
    SendMessageW(edit, EM_SETTYPOGRAPHYOPTIONS, TO_ADVANCEDTYPOGRAPHY,
                 TO_ADVANCEDTYPOGRAPHY);
    set_padding(maximum_reduction);
    if (measure(width)) {
      int lower_reduction = 0;
      int upper_reduction = maximum_reduction;
      while (upper_reduction - lower_reduction > 1) {
        const int candidate =
            lower_reduction + (upper_reduction - lower_reduction) / 2;
        set_padding(candidate);
        if (measure(width))
          upper_reduction = candidate;
        else
          lower_reduction = candidate;
      }
      set_padding(upper_reduction);
      layout.all_characters_fit = measure(width);
      layout.padding_reduction_twips = upper_reduction;
      return layout;
    }
    set_padding(0);
    SendMessageW(edit, EM_SETTYPOGRAPHYOPTIONS,
                 layout.original_typography_options, TO_ADVANCEDTYPOGRAPHY);
  }
  SendMessageW(edit, EM_EXSETSEL, 0,
               reinterpret_cast<LPARAM>(&original_selection));
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