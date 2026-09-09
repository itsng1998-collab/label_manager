# 역상 RichEdit 무출력 회귀 검사

Windows, Visual Studio C++/Windows SDK, CMake와 설치된 `Godex G500` 프린터 큐가 필요하다.
기본 CTest/`--replay`는 큐의 DC를 참조하지만 `StartDoc`를 호출하지 않는다.
별도 `--driver-file` 모드만 출력 파일을 명시한 `StartDoc`를 호출한다.
프린터 설정과 DB는 변경하지 않는다.

```powershell
cmake -S tools/inverse_rich_edit_probe -B .tmp/inverse_probe_build -G "Visual Studio 17 2022" -A x64
cmake --build .tmp/inverse_probe_build --config Debug
ctest --test-dir .tmp/inverse_probe_build -C Debug --output-on-failure
```

CTest는 자체 합성 문자열을 사용한다.
좌/우 clip 경계의 3픽셀 표식이 원래 좌표에 남는지도 가로 변환 유무별로 검사한다.
재생 목적지는 출력 비트맵 폭이 아니라 EMF 헤더의 프레임과 참조 장치 크기로 환산한다.

저장된 역상 EMF로 검사하려면:

```powershell
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe <source.emf> .tmp/inverse_probe
./tools/inspect_inverse_emf.ps1 -Path .tmp/inverse_probe/5.emf
```

EMF 입력 모드는 기록된 텍스트에 합성 숫자 꼬리를 추가한다.
원본에서 미출력된 문자를 복원하지 않는다. 203dpi/620x480 페이지의 긴 역상 한 줄 재현용이다.
검사 결과의 BMP/EMF에는 입력 문구가 포함되며 로컬 출력 디렉터리에만 저장한다.

- 0: v1.3.93 배경/배치 기준, 줄 넘침과 흰 사각형을 재현한다.
- 1~3: 배경 확장/target device 옵션의 비교 기록. 폭 문제를 해결하지 못해 생산 경로에 적용하지 않는다.
- 4: 투명 control로 흰 배경 채우기를 없앤다. 폭 문제는 남는다.
- 5~6: 투명 control과 생산 코드의 `MeasureInverseTextLayout`을 사용한다.
  별도 DC 및 동일 DC 측정/출력에서 전체 문자열 기록, 수용 위치와 흰 사각형 제거를 검사한다.
- 7: 생산 코드의 `CompositeInverseTextBitmap`으로 역상 clip만 흑백 픽셀로 합성한다.
  영역 밖 픽셀과 alpha 보존, 흑백 값, 변경 픽셀 발생, 실제 DIB bit count=1을 검사한다.

v1.3.96은 역상 글자를 처음부터 1bpp DIB에 렌더한다. 검정0/흰색1 팔레트와
DWORD 정렬 stride를 사용하고, 글자 렌더 후 임계값 변환은 하지 않는다.
base의 초기 단색 변환만 128을 사용한다. 프린터에 전송하는 페이지는 기존 32bpp이다.
v1.3.95 컬러 렌더 후 임계값 방식은 실물 획 소실이 지속되어 대체했다.
이는 확대/팽창 보정이 아니며 실물 품질 개선은 별도 검증이 필요하다.

실제 진단 세트의 EMF와 base를 그대로 합성하려면 확장자 없는 접두 경로를 지정한다.

```powershell
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe --replay <diagnostic-prefix> .tmp/inverse_composite.bmp
```

이 모드는 같은 접두 경로의 `.txt`에서 clip을 읽고 `_base.bmp`와 `.emf`를 사용한다.
v1.3.95의 `_comparison.bmp`는 별도 참조 렌더가 아니라 실제 전송할 합성 벡터를 저장한 것이다.
앞서 합성한 역상은 포함되지만 뒤에 직접 그리는 일반 검정 글자와 워터마크는 포함하지 않는다.
실패한 native white printer DC 렌더와 전체 EMF 프린터 전송, 흰 마스크 추출은 재사용하지 않는다.

가로 맞춤은 높이와 세로 좌표를 유지한다. 짧은 문자열, wrap=true, 명시적 개행은 축소하지 않는다.
EMF 재생은 실제 스풀 캡처가 아니며 실물의 획 소실 개선 여부를 보장하지 않는다.

## 검정 글자 후속 합성 진단

v1.3.97은 기존 역상 전송 픽셀 외에 `_after_native.bmp/.emf/.txt`를 저장한다.
실제 검정 글자 출력 함수를 참조 EMF에 실행한 결과를 전송 비트맵 위에 재생한다.
이 이미지는 실제 전송 비트맵이나 실제 스풀 캡처가 아니며 워터마크는 포함하지 않는다.
참조 EMF와 실제 printer DC의 글꼴 측정 차이가 있을 수 있다.

`inverse[index].whitePixelsLost`는 역상 안의 흰 픽셀이 검정 글자 합성 후
휘도 128 미만으로 바뀐 수이다. `native[index].sourceRect`는 검정 글자의 입력 영역이다.
0이면 참조 재생에서 덮임이 없다는 뜻이며, 드라이버나 열 문제가 확정되는 것은 아니다.
CTest는 경계의 3x3 겹침에서 손실 9, 비겹침에서 0과 alpha 보존을 검사한다.

## 역상 도형 전송 검사

v1.3.107은 역상 clip의 픽셀을 바꾸지 않고 검정 run을 GDI region으로 전달한다.
일반 글자/표선은 기존 전송을 유지한다. 역상 clip을 비운 32bpp DIB 전송 후
`ExtCreateRegion`/`FillRgn`으로 검정 부분만 복원하므로 흰 글자 직접 렌더는 하지 않는다.
v1.3.96/97의 역상 포함 bitmap 전송은 실물 획 소실이 지속되어 이 영역에 재사용하지 않는다.

CTest와 `--replay`는 생산 `PrepareInverseTextGeometry`/`RenderInverseTextGeometry`로
`StretchDIBits` 후 도형 합성 결과가 원본 RGB와 같은지 검사한다.
전송 raster의 clip 비움, 외부 RGB 및 alpha 보존, 좌표 이동과 중복 clip도 검증한다.
흰 획 확대/팽창/회색/threshold 조정은 없으며 무출력 동등성이 실물 개선을 입증하지는 않는다.
v1.3.107 `_comparison.bmp`는 도형 분리 전 픽셀 원본으로 실제 전송 raster와 구분한다.

## 로컬 드라이버 파일 판별

v1.3.108 진단 도구는 단일 역상 clip의 기존 원본을 80x60mm/203dpi/620x480
G500 드라이버로 변환하되 `DOCINFO.lpszOutput`에 절대 경로를 지정한다.
새 `.prn` 경로와 기존 부모 디렉터리가 필요하며 기존 파일은 덮어쓰지 않는다.
실물 포트로 출력하는 fallback이나 `DM_UPDATE`는 없다. 출력 파일에도 라벨 내용이
있으므로 `.tmp`에 보존하고 외부 전송하거나 stage하지 않는다.

```powershell
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe --driver-file <diagnostic-prefix> .tmp/inverse_driver.prn
./tools/inspect_inverse_driver_file.ps1 -Path .tmp/inverse_driver.prn -SourcePrefix <diagnostic-prefix>
./tools/test_inverse_driver_file.ps1 -OutputDirectory .tmp/inverse_driver_parser_test
```

`--driver-file-legacy-devmode`는 레거시의 dmFields 교체 및 재정규화 생략만 비교한다.
폰트/농도/속도/프린터 전역 설정을 바꾸지 않는다.
해석기는 현재 드라이버의 단일 `Qx,y,widthBytes,height` 뒤 CR과 길이 고정 binary를
MSB-first/1=검정으로 읽는다. 알 수 없는 명령/잘린 데이터는 오류 처리한다.
출력 PNG와 clip의 `whiteLost/whiteGained/mismatches`를 제공하며 값이 0이 아니어도
해석 성공 자체는 오류가 아니다. 실행 로그의 조건과 좌표를 먼저 대조해야 한다.

실제 자료 두 건의 PRN clip 차이0/흰 손실0, 레거시·현재 DEVMODE의 파일 SHA256
동일을 확인했다. 이 재현은 일반 native text/워터마크를 제외하며 지정 clip만
도형으로 전송한다. 다른 역상은 저장 BMP 상태 그대로이므로 실제 전체 인쇄 스풀과
같다고 단정하지 않는다. 원인/실물 품질 개선은 미확정이다.