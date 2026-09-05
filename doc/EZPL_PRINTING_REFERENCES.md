# EZPL 출력 기술 참조

## 로컬 공식 매뉴얼

- PDF: `EZPL_EN_J_20180226.pdf`
- 검색용 텍스트: `EZPL_EN_J_20180226.txt`
- 문서명: EZPL Programmer's Manual
- 원본 URL: https://www.godexprinters.co.uk/downloads/manuals/desktop/EZPL_EN_J_20180226.pdf
- 확인일: 2026-09-05
- PDF 크기: 2,318,076 bytes
- PDF SHA-256: `6B0FAE74312BE174C4F74C2A061A780681DCC27A3D49B6EBEFA080D064C907B9`
- PDF 페이지 수: 95

검색용 텍스트는 PDF 페이지마다 `===== PDF PAGE n =====` 표식을 추가한 UTF-8 추출본이다. 명령의 최종 해석은 PDF 원본의 표와 예제를 기준으로 한다.

## 역상 출력 관련 EZPL 명령

### 라벨 전체 반전

매뉴얼 PDF 11페이지의 `^Lx` 설명:

- `^L`: normal printing
- `^LI`: inverse printing
- `^LM`: mirror printing

`^LI`는 라벨 전체를 반전하므로 특정 역상 셀만 처리하는 용도로는 적합하지 않다.

### 텍스트 역상

매뉴얼 PDF 44페이지의 `At,x,y,x_mul,y_mul,gap,rotationInverse,data` 설명은 회전 매개변수 뒤에 `I`를 붙이면 inverse font로 출력한다고 명시한다.

Asian font `Z1`을 사용하는 기존 한글 명령:

```text
AZ1,x,y,x_mul,y_mul,gap,0,data
```

역상 후보 명령:

```text
AZ1,x,y,x_mul,y_mul,gap,0I,data
```

G500 펌웨어에서 검정 배경 래스터와 역상 글꼴이 어떻게 합성되는지는 실물 출력으로 검증해야 한다.

### Exclusive line

매뉴얼 PDF 54페이지의 `La,x,y,x1,y1`에서 `a=e`는 아래쪽 출력과 exclusive 합성을 수행한다. 역상 텍스트의 직접 대체 수단은 아니지만 장치 측 배타 합성 조사 시 참고한다.

## 관련 공식 기술 문서

### Microsoft GDI

- SetStretchBltMode: https://learn.microsoft.com/windows/win32/api/wingdi/nf-wingdi-setstretchbltmode
  - 단색 비트맵 축소 시 `WHITEONBLACK`은 흰색 픽셀을 우선 보존한다.
- GetGlyphOutlineW: https://learn.microsoft.com/windows/win32/api/wingdi/nf-wingdi-getglyphoutlinew
  - `GGO_BITMAP`은 grid-fitted 1-bit glyph bitmap을 반환한다.
- ExtTextOutW: https://learn.microsoft.com/windows/win32/api/wingdi/nf-wingdi-exttextoutw
  - `ETO_CLIPPED`, `ETO_OPAQUE`, glyph index 및 명시적 spacing을 지원한다.

### Microsoft DirectWrite

- DirectWrite 개요: https://learn.microsoft.com/windows/win32/directwrite/introducing-directwrite
- DWRITE_RENDERING_MODE: https://learn.microsoft.com/windows/win32/api/dwrite/ne-dwrite-dwrite_rendering_mode
  - `DWRITE_RENDERING_MODE_ALIASED`는 각 픽셀을 전경 또는 배경으로 확정한다.
- CreateAlphaTexture: https://learn.microsoft.com/windows/win32/api/dwrite/nf-dwrite-idwriteglyphrunanalysis-createalphatexture
  - `DWRITE_TEXTURE_BILEVEL_1x1`은 glyph run의 bi-level texture를 생성한다.

### FreeType

- Glyph retrieval 및 load target: https://freetype.org/freetype2/docs/reference/ft2-glyph_retrieval.html
  - `FT_LOAD_TARGET_MONO`는 monochrome 출력용 strong hinting을 선택한다.
  - `FT_RENDER_MODE_MONO`는 1-bit glyph bitmap을 생성한다.

## 현재 프로젝트 연결 지점

- `lib/printing/label_sheet_print_job.dart`
  - 한글 native text는 CP949 `AZ1` 명령으로 출력한다.
  - 현재 검정색이 아닌 텍스트는 native 후보에서 제외되어 raster fallback으로 처리된다.
  - EZPL `Q` raster는 `0=black`, `1=white` bit polarity를 사용한다.
- `lib/printing/godex_korean_font_provisioner.dart`
  - `AZ1`용 GoDEX 한글 폰트 설치 및 확인을 담당한다.
- `windows/runner/label_bitmap_print_channel.cpp`
  - Windows driver 출력의 역상 흰 글자 bitmap knockout 경로를 구현한다.
