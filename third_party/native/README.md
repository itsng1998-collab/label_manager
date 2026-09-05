# Native RTF/XLSX Dependencies

This folder stores the native dependency sources as module archives instead of expanded source trees.

Tracked files:

- `zlib.zip`
- `libxlsxwriter.zip`
- `rtf2html.zip`
- `freetype.zip`
- `README.md`

Generated and ignored files:

- `zlib/`, `libxlsxwriter/`, `rtf2html/`, `freetype/`
- `build/`
- `install/`

Run `tools/build_native_rtf_xlsx.ps1 -SkipClone` to expand the tracked archives and build the native RTF conversion dependencies. Without `-SkipClone`, the script can clone a missing dependency and create its archive.

Run `tools/build_native_freetype.ps1 -SkipClone` to expand and build the pinned FreeType 2.13.3 static libraries used by Windows inverse text rendering.

If an expanded source directory is edited, run `tools/build_native_rtf_xlsx.ps1 -SkipClone` again. The script refreshes the matching tracked zip archive whenever the source tree is newer than the archive, then builds from that source.