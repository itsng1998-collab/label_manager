# 역상 RichEdit 무출력 회귀 검사

Windows, Visual Studio C++/Windows SDK, CMake와 설치된 `Godex G500` 프린터 큐가 필요하다.
기본 CTest/`--replay`는 큐의 DC를 참조하지만 `StartDoc`를 호출하지 않는다.
별도 `--driver-file` 계열과 `--comparison-label` 계열은 출력 파일을 명시한 `StartDoc`를 호출한다.
프린터 설정과 DB는 변경하지 않는다.

## 기존 자료 기반 호출 비교 (v1.3.123)

기존 레거시 정상 사진과 동일 PC/프린터 정보는 유효하며 재제출을 요구하지 않는다.
아래 합성 RTF 진단은 실제 레거시 프로그램 실행이나 원본 RTF 전체 출력을 대체하지 않는다.
비교 라벨 실물 제출도 코드 조사의 선행 조건이 아니다.

`--comparison-label-swapped`는 크기와 좌표를 유지하고 A/B를 비트맵, C/D를 직접 출력으로 바꾼다.
`--comparison-label-display-band`는 기본 A/B 직접 출력에만 레거시의
FormatRange(TRUE) -> DisplayBand(&rc) 순서를 적용한다. 캐시는 그 뒤 해제한다.
두 모드 모두 새 로컬 PRN만 생성하며 물리 제출 기능을 호출하지 않는다.
기존 파일과 바이트 비교할 수 있도록 라벨 문구/형식은 v1.3.122를 유지하고 실행 로그에
`probeVersion=1.3.123`, `swapPaths`, `displayBand`를 따로 출력한다.

```powershell
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe --comparison-label-swapped .tmp/log/godex_inverse/inverse_paths_swapped.prn
./tools/inspect_inverse_driver_file.ps1 -Path .tmp/log/godex_inverse/inverse_paths_swapped.prn
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe --comparison-label-display-band .tmp/log/godex_inverse/inverse_display_band.prn
Get-FileHash .tmp/log/godex_inverse/inverse_comparison_v122.prn,.tmp/log/godex_inverse/inverse_display_band.prn
```

현재 G500 파일 결과: 동일 좌표의5pt 역상 차이0,17dot 차이132(흰66개씩 양방향 이동).
17dot 차이는 뒤쪽120g 위치에만 있고 한글 영역은 차이0이다. Y위치를 통제해도 같았다.
PNG 물리 좌표의 비교 영역은 x10..609, y75..106/180..211/285..316/390..421이다.
DisplayBand는4회 모두1을 반환했고, 생성 PRN은 기본 파일과 전체 SHA256이 같다.
따라서 이 호출 누락은 해당 검사에서 차이를 설명하지 못하며 생산에 추가하지 않는다.
기존 font-reference의120twip(`6pt_0.bmp`)/121twip(`8pt_2.bmp`)도 파일 해시가 같다.
합성 검사 문구에서의 결과이며 실제 라벨 전체나 실물 품질의 동등성은 입증하지 않는다.

## 실물 비교 진단 (v1.3.122)

IMG_20260912_0002에서 v1.3.121 공백 맞춤 적용(scaleX1) 후에도 획 소실이 남았다.
이번 버전은 진단 도구 추가이며 생산 인쇄 경로를 변경하지 않는다.
같은 문구의 일반/역상을 각 구역에 넣고 A/C는100twip(5pt), B/D는121twip(17dot)을 사용한다.
A/B는 RichEdit FormatRange를 printer DC로 직접 호출하며 C/D는 현재1bpp 합성/검정region 경로다.
실패했던 직접 흰 글자 출력의 생산 재적용이 아니라 두 렌더 경로를 비교하기 위한 진단이다.
원본 RTF 전체/저장 라벨을 복원하지 않으며 DB를 사용하지 않는다.

파일 준비와 미리보기는 실제 인쇄하지 않는다. 기존 PRN은 덮어쓰지 않는다.

```powershell
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe --comparison-label .tmp/log/godex_inverse/inverse_comparison_v122.prn
./tools/inspect_inverse_driver_file.ps1 -Path .tmp/log/godex_inverse/inverse_comparison_v122.prn
```

생성한 PRN의8개 Q블록에서 미리보기를 추출한다. 미리보기 모드에만 다중 Q를 허용하며
기존 SourcePrefix 원본 비교는 단일 Q 조건을 유지한다. 해석기 회귀9건 통과.
현재 파일에서 A/C의 역상 픽셀 차이는0, B/D는132다. 기본/고급 조판5/6/8pt
동일 twip 글리프 비교는 차이0이며, 실물 정상이나 USB 전달 동일성을 입증하지 않는다.

아래 명령은 **사용자가 직접 실행할 때만 GoDEX G500에 준비된 PRN을 RAW로 실제 제출한다**.
PNG를 이미지 뷰어에서 인쇄하면 다른 크기/변환이 개입하므로 비교에는 아래 PRN 제출을 사용한다.
매수1인 파일을 그대로 보내며 성공은 큐 접수 결과이지 실물 품질 확인이 아니다.
에이전트는 준비 단계에서 이 명령을 실행하지 않는다. 제출 기능 자체는 실물 미검증이다.

```powershell
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe --submit-comparison-label .tmp/log/godex_inverse/inverse_comparison_v122.prn
```

향후 별도로 실물 비교를 승인한 경우에만 같은 크기의 A/C 및 B/D, 같은 경로의 A/B 및 C/D를 비교한다.
현재 사용자에게 실행이나 사진을 요청한 상태가 아니다. 파일의132픽셀 차이는 위 동일 좌표 검사로 분리했다.
특정 구역의 결과만으로 프린터 결함이나 소프트웨어 개선 불가를 단정하지 않는다.

## 공백 맞춤 검사 (v1.3.121)

긴 내부 연속 공백으로 넘치는 역상은 공백 자간만 줄여 글자 X축 배율1을 유지한다.
글자 크기/글자 자간은 변경하지 않으며 공백은 최소1dot advance를 남긴다.
공백만으로 수용할 수 없으면 원래 자간/조판 옵션을 복원한 뒤 기존 X축 fit을 사용한다.
짧은 문구, wrap, 명시적 개행은 기존 동작을 유지한다.
native CTest는 전체 문구 수용, 글자121twip/자간0, selection 보존과 fallback 복원을 검사한다.

원문을 변경하지 않는 제출 EMF 검사는 아래 모드를 사용한다. 배율1/공백 맞춤을 기대하는
17dot 역상 진단용이며, 기존 EMF 입력 모드의 합성 숫자 꼬리를 붙이지 않는다.

```powershell
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe --exact-emf <source.emf> .tmp/inverse_exact
```

검사는 StartDoc 없이 수행한다. 배율1과 무출력 합성 통과가 실물 개선을 입증하지는 않는다.
v1.3.121은 `inversePaddingFitVersion`과 `inversePaddingReductionTwips`로 구분하며,
기존 전송/워터마크1.3.107을 유지한다. 아래 v1.3.94 이후 기록은 이전 검증 이력이다.

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

## RTF 글자 크기 비교

```powershell
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe --font-reference .tmp/inverse_font_reference
```

CTest `inverse_font_reference`에도 포함된다. StartDoc 없이 굴림 Bold의
`계란,우유,대두,밀 함유`를 5/6/8pt로 비교한다. 출력 이름의 variant는
0=RTF 원본 twip, 1=동일 twip 평문 재구성, 2=수정 전96dpi 환산 재구성이다.
문구/폰트/크기/전체 수용을 확인하고, 흰 글리프 경계 정렬 후 픽셀을 비교한다.
EMF/BMP는 지정 로컬 디렉터리에 저장한다.

203dpi 결과: 같은 twip이면 세 크기 모두 글리프 차이0.
현재 환산은 흰 픽셀634->469(5pt), 688->571(6pt), 993->688(8pt).
8pt 원본의 글리프 높이20픽셀이 17dot/121twip 재구성에서는14픽셀이다.
이는 단위 차이의 합성 재현이며 레거시 전체 앱 재현 또는 실물 품질 검사가 아니다.
현재 실패 라벨17dot의 원본이8pt였다고 추정하거나 모든 시트 크기를4/3 확대하지 않는다.
v1.3.112의 새 RTF 가져오기는 point를96/72 논리 pixel로 변환하여 출력 물리 크기를 보존한다.
기존 저장 시트는 재변환하지 않는다. 이 probe의 variant2는 이전 축소 현상을 고정한 비교 기준이다.

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

## 페이지 파일 재생

v1.3.109의 `--driver-file-page`는 마지막 역상 `_comparison.bmp`와
동일 작업의 `_after_native.txt/.emf`를 사용한다. 마지막 역상 원본에 이전 역상도
포함돼 있어야 한다. 모든 역상 clip을 한 번에 도형으로 전송하고, 기록된 검정 문자
EMF와 기존 v1.3.107 워터마크를 차례로 출력한다. 명시한 로컬 파일 외에는 보내지 않는다.

```powershell
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe --driver-file-page <last-inverse-prefix> <after-native-prefix> .tmp/inverse_page.prn
./tools/inspect_inverse_driver_file.ps1 -Path .tmp/inverse_page.prn -SourcePrefix <first-inverse-prefix>
./tools/inspect_inverse_driver_file.ps1 -Path .tmp/inverse_page.prn -SourcePrefix <last-inverse-prefix>
```

워터마크와 맞는 `version=1.3.107` 참조 진단만 지원한다. EMF 재생 범위는 헤더의
장치/프레임으로 환산하며 페이지 크기를 직접 사용하지 않는다.
CTest는 문자 대신 기록한 3x3 표식, 워터마크 실제 픽셀, 나머지 영역 및 DC 상태
보존을 검사한다. Q 해석기는 최대7픽셀의 페이지 밖 백색 정렬 패딩만 허용하고,
그 범위의 검정 픽셀은 오류 처리한다. 해석기 회귀 검사는 7건이다.

IMG0003에 대응하는 페이지 PRN은 `Q10,11,76,472`, 끝의 백색 패딩1824픽셀,
역상별 흰1298/1508 및 손실0/차이0을 확인했다. 복원 PNG에는 일반 문자/표선/
워터마크가 포함된다. 다만 검정 문자는 실제 앱의 DrawText 호출을 다시 수행한 것이
아니라 참조 EMF 재생이다. 실제 USB 작업 스풀과 같다고 단정하지 않는다.
생산 출력 코드는 변경하지 않았으므로 이 진단 버전으로 동일 실물 재출력을 요구하지 않는다.

## 실제 앱 호출의 파일 전용 캡처

v1.3.109 Debug 앱은 `LABEL_MANAGER_DEBUG_PRINT_FILE` 환경변수가 설정된 경우
실제 `PrintBitmap` 호출의 `DOCINFO.lpszOutput`을 지정한 파일로 바꾼다.
일반 문자도 EMF 재생이 아닌 기존 DrawText 호출을 그대로 수행한다.
환경변수가 없는 일반 실행 및 Release는 기존 출력 동작을 유지한다.

```powershell
$env:LABEL_MANAGER_DEBUG_PRINT_FILE = Join-Path $PWD '.tmp/log/godex_inverse/actual_app_v109.prn'
try { C:/Flutter/bin/flutter.bat run -d windows --debug --no-pub }
finally { Remove-Item Env:LABEL_MANAGER_DEBUG_PRINT_FILE -ErrorAction SilentlyContinue }
```

파일 전용 앱에서 같은 라벨의 인쇄를 한 번 요청하면 종이 대신 파일을 만든다.
경로는 기존 디렉터리 아래의 새 절대 로컬 `.prn` 파일이어야 한다. 잘못된 경로나
기존 파일, GoDEX 이외 backend는 실제 출력으로 fallback하지 않고 실패한다.
파일이 이미 생성된 뒤 반복 요청도 거부하므로 새 경로로 재실행해야 한다.

파일 생성 성공 후에도 `ok=false`를 반환하며 화면에 `Debug print file captured`
문구를 포함한 인쇄 실패 메시지가 뜨는 것이 의도된 동작이다. 로그의
`debugFileCaptured=true physicalPrintSubmitted=false`를 확인한다.
접수 라벨에 포함하지 않아 인쇄 이력과 자동증가 값을 저장하지 않는다.
검증 후 일반 인쇄로 돌아가려면 파일 전용 앱을 종료하고 환경변수 없이 다시 실행한다.

생성된 PRN은 해당 실행에서 생성한 역상 진단 prefix들과 위 해석기로 비교한다.
이것은 실제 앱의 파일 대상 호출 결과이며 USB로 보낸 작업의 캡처는 아니다.
인쇄 마크는 기존1.3.107을 유지하며 앱 버전1.3.109/파일 전용 플래그로 구분한다.

실제 앱 캡처 검증: `actual_app_v109.prn`에서 두 역상 clip의 흰 손실0/증가0/차이0을
확인했다. 참조 페이지 PNG와 실제 앱 PNG의 차이는 역상 밖1픽셀이다.
파일 대상과 USB 실제 전송이 같은지는 이 결과만으로 증명되지 않는다.