# Native RTF to XLSX Adapter

The Windows runner exposes the `label_manager/rtf_open_xml` MethodChannel.
Dart calls `writeRtfOpenXml` first and falls back to the Dart Open XML writer only when the native path reports that it is unavailable.

The default adapter source is `windows/runner/label_rtf_xlsx_native_adapter.cpp`.
It writes the incoming RTF to a temporary file, runs an `rtf2html` executable to
produce HTML, extracts the first HTML table, and writes the result through
`libxlsxwriter`.

For this repository, run the bootstrap script first:

```powershell
.\tools\build_native_rtf_xlsx.ps1
```

The script clones/builds local native dependencies under `third_party/native`.
That directory is intentionally ignored by Git. When the expected outputs exist,
`windows/runner/CMakeLists.txt` auto-enables the native adapter.

During a real conversion, the native adapter writes diagnostic copies next to
the requested workbook path:

- `label_sheet_rtf_native_input.rtf`
- `label_sheet_rtf_native_output.html`

Files such as `.tmp/native_check.rtf` and `.tmp/native_check.html` are ad-hoc
smoke-test fixtures, not app conversion outputs.

To enable the native path, provide the native dependency paths through CMake:

```powershell
cmake -DLABEL_MANAGER_NATIVE_RTF_XLSX_ADAPTER=C:/path/to/label_rtf_xlsx_native_adapter.cpp `
      -DLABEL_MANAGER_NATIVE_RTF2HTML_EXECUTABLE=C:/path/to/rtf2html.exe `
      -DLABEL_MANAGER_NATIVE_XLSXWRITER_INCLUDE_DIR=C:/path/to/libxlsxwriter/include `
      -DLABEL_MANAGER_NATIVE_XLSXWRITER_LIBRARY=C:/path/to/xlsxwriter.lib `
      -DLABEL_MANAGER_NATIVE_ZLIB_LIBRARY=C:/path/to/libzs.lib
```

If any path is missing, the runner excludes the native adapter and the Dart
Open XML fallback remains active.

The adapter must implement:

```cpp
bool WriteRtfOpenXmlWithNativeLibraries(const std::string& rtf,
                                        const std::wstring& output_path,
                                        double width_mm,
                                        double height_mm,
                                        std::string* error_message);
```

Adapter flow:

1. Convert the RTF input to HTML/table structure with the configured `rtf2html` executable.
2. Map HTML table rows, cells, text, and simple row/column spans to worksheet operations.
3. Create the `.xlsx` file with `libxlsxwriter` (`workbook_new`, `workbook_add_worksheet`, `worksheet_write_string`, `worksheet_merge_range`, `format_set_*`, `workbook_close`).

The `rtf2html` source should be reviewed for its LGPL-2.1 obligations before bundling.
`libxlsxwriter` should be bundled according to its upstream license.
