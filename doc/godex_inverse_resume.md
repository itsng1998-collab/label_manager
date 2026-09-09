# G500 역상 출력 재개

## 작업 순서
1. 최신 `.tmp/IMG_20260909_0003.png`(앱1.3.108/인쇄1.3.107)도 실패 확인 완료. 앞선 IMG0002는 종이에서도 같은 흰 획 소실임을 사용자에게 확인했다. 자동 실물 인쇄나 동일 도형 전송 실험을 반복하지 않는다.
2. 앱 오동작과 인쇄 작업의 원인/검증/커밋을 구분한다.
3. 참조 페이지 재생뿐 아니라 v1.3.109 실제 앱 파일 전용 호출에서도 두 역상 흰 손실0/차이0을 확인했다. 다음은 파일 대상과 USB 실제 전송의 동일성 판별이다. 종이 인쇄는 자동 실행하지 않는다. 파일 검사 통과를 품질 해결 또는 열 문제 확정으로 판단하지 않는다.

## 현재 기준
- v1.3.109는 페이지 파일 재생/Q 패딩 해석 보완 및 실제 앱 Debug 파일 전용 모드 추가 버전이다. 일반 출력 품질 보정은 없다. `/WX` Debug 빌드 및 파일 전용 앱 실행 완료. 인쇄 마크1.3.107 유지, 마지막 실물 앱은1.3.108이다.
- 파일 전용 실행/실제 확인 완료: 시작 로그 `.tmp/log/app_2026-09-09_23-21-37.log`, 대상 `.tmp/log/godex_inverse/actual_app_v109.prn`. 사용자 요청으로 23:23:52 생성(35933바이트), `debugFileCaptured=true`, 인쇄 저장 트랜잭션 없음. 현재 파일 전용 앱은 기존 파일을 덮어쓰지 않고 다음 요청을 거부한다. 일반 인쇄 복귀는 환경변수 없이 재실행한다.
- 최신 보완: v1.3.107 역상 검정 픽셀의 GDI region 전송. 기존 v1.3.97 진단 구현은 `d0ade63`, 새 커밋/실행 상태는 [SESSION_HANDOFF.md](../SESSION_HANDOFF.md)를 확인한다.
- v1.3.107 Debug `/WX` 빌드 완료. 앱/인쇄 마크 모두 v1.3.107로 통일했다.
- 마지막 실물: IMG0003에서도 획 소실 지속. 최신 로그는 [.tmp/log/app_2026-09-09_23-10-24.log](../.tmp/log/app_2026-09-09_23-10-24.log). 현재 실행 여부는 새로 확인한다.
- 미해결: 검정 띠 안 작은 흰 한글 획 소실. 도형 전송 변경은 해결되지 않았고 추가 생산 보정은 근거가 없어 적용하지 않았다.
- 유지 조건: 일반 글자/표선은 v1.3.58 기준. GoDEX G500, USB001, 80x60mm, 약 203dpi. source640x480 -> target620x480, physical640x480, offset10,0, destination0,0.

## 마지막 분석 증거
- 실제 앱 파일 캡처: `.tmp/log/godex_inverse/actual_app_v109.prn/.png`, 동일 실행 inverse prefix `v1.3.107_13308_11451875_1`/`v1.3.107_13308_11451906_2`. 두 역상 흰 손실0/증가0/차이0(흰1298/1508), Q10,11,76,472 및 백색패딩1824. PRN SHA256 `C0D38BD589BE26465B8F955F9D3EAC261B1E20A4190BCBA9E9B347F1D6AE50B5`.
- 실제 앱 호출과 아래 참조 페이지의 PNG 차이는 역상 밖 원재료 영역(537,58)의1픽셀뿐이다. 파일 대상에서 실제 일반 DrawText/워터마크가 역상을 지우는 가설은 지지되지 않는다. 실제 USB 제출 데이터의 동일성은 아직 미검증이다.
- 최신 실물 [.tmp/IMG_20260909_0003.png](../.tmp/IMG_20260909_0003.png): 앱1.3.108/인쇄1.3.107, 도형951개/흰2806/후속 손실0. 이전과 같은 인쇄 코드이므로 품질 개선 버전 재현이 아니다.
- 페이지 재생: `.tmp/log/godex_inverse/v1.3.107_18248_10663312_2`와 `v1.3.107_18248_10663640_1_after_native`를 `--driver-file-page`로 재생한 `v108_driver_page.prn/.png`에 일반 문자/표선/두 역상/워터마크 포함. 두 clip의 손실0/증가0/차이0(흰1298/1508), 도형 소스 검정19424/흰2806. 검정 EMF의 referenceDrawn33/fitted12는 실제 검정33/fitted12와 일치한다.
- Q 헤더는 `Q10,11,76,472`. 8행 정렬로 페이지 밖 3행(1824픽셀)이 생기지만 전부 백색이다. 해석기는 빈 정렬 패딩만 허용하며 검정 overflow는 오류 처리한다. 이 빈 패딩은 역상 획 손실 근거가 아니다.
- 페이지 파일 재생도 실제 USB 스풀 캡처는 아니다. 실제 DrawText 호출 대신 기록된 참조 EMF를 사용한다는 차이가 남는다. 생산 프린터 설정/폰트/농도/획 보정은 변경하지 않았다.
- 최신 실물 [.tmp/IMG_20260909_0002.png](../.tmp/IMG_20260909_0002.png)는 스캐너 흑백 이미지이며 종이에서도 흰 획 소실이 같다는 사용자 확인을 받았다.
- v1.3.107 실제 출력 로그: 도형951개/검정19424/흰2806, 후속 합성 손실0, native 실패0, 출력 수락 및 이력 저장 성공. 성공 수치가 품질 성공을 뜻하지 않는다.
- v1.3.108 로컬 파일 probe: `v1.3.107_18476_1323265_1` / `v1.3.107_18476_1323281_2` 원본을 각각 G500 드라이버로 변환한 `.tmp/log/godex_inverse/v107_driver_geometry_first.prn` / `v107_driver_geometry.prn`에서 두 clip RGB 차이0/흰 손실0. Q 헤더 `Q10,11,75,464`, MSB-first/1=검정 해석. 흰1298/1508 보존.
- 레거시 DEVMODE 설정 방식의 PRN SHA256도 현재 방식과 동일(`00A3FE63D640B70C01DF5905717D5B4FE727C389A7A86E837FBC42CA4A5AF64B`). 이것만으로 장치/열 문제를 확정하지 않는다.
- 파일 probe는 일반 검정 native text/워터마크를 제외하고 지정 clip만 도형으로 전송한다. 실제 전체 작업 스풀 캡처가 아니며 다음에는 이 차이를 구분해야 한다. 실행 방법은 [tools/inverse_rich_edit_probe/README.md](../tools/inverse_rich_edit_probe/README.md).
- 최신 실물 [.tmp/IMG_20260909_0001.png](../.tmp/IMG_20260909_0001.png): 역상 두 띠에서 흰 획 소실 지속.
- 최신 진단 `.tmp/log/godex_inverse/v1.3.97_15924_468281_1_after_native.txt`: `referenceDrawn=33`, `referenceFitted=12`, 역상별 `whitePixelsLost=0/0`. 실제 `nativeTextDrawn=35` 중 역상2건을 제외한 검정33건/fitted12와 일치한다. 참조 BMP에는 획이 남아 있으며 검정 덮임을 재현하지 못했다.
- 실제 역상 EMF `v1.3.97_15924_468015_1` / `v1.3.97_15924_468046_2`: clip15,83,600,102 / 15,284,600,303. 무출력 DIB+region 재생은 도형403/548개, 검정9817/9607픽셀, 흰1298/1508픽셀, 원본과 RGB 차이0. 좌표 이동, 중복 clip, 외부 RGB 및 준비 raster alpha 보존 검사도 통과했다.
- 아래 v1.3.96 자료는 이전 분석 이력이며 파일이 현재 없으면 새로 확보된 2026-09-09 자료를 우선한다.
- 실물 [.tmp/IMG_20260908_0005.png](../.tmp/IMG_20260908_0005.png): v1.3.96에서도 흰 획 소실 지속. 오른쪽 흰 사각형과 끝 문구 미수용은 이전 수정으로 해소됐으나 획 품질은 미해결.
- 로그 [.tmp/log/app_2026-09-08_22-39-21.log](../.tmp/log/app_2026-09-08_22-39-21.log), 출력 시각 23:18:55: `rasterBitCount=1`, 전체 문자 수용, `nativeTextWhiteDirectDrawn=0`, `nativeBordersDrawn=225`.
- 역상 1: [.tmp/log/godex_inverse/v1.3.96_4180_11669359_1.txt](../.tmp/log/godex_inverse/v1.3.96_4180_11669359_1.txt). clip15,90,600,109 / font17dot / layout636 / scaleX .919811 / input72 / formatted73 / changed1298.
- 역상 2: [.tmp/log/godex_inverse/v1.3.96_4180_11669390_2.txt](../.tmp/log/godex_inverse/v1.3.96_4180_11669390_2.txt). clip15,291,600,310 / layout616 / scaleX .949675 / input75 / formatted76 / changed1508.
- 각 TXT와 같은 접두사의 `.emf`, `_base.bmp`, `_comparison.bmp`를 보존한다. 라벨 내용이 있는 로컬 자료이므로 외부 전송하지 않는다.
- 레거시 정상 사진 [.tmp/Legacy_print.png](../.tmp/Legacy_print.png)는 같은 PC/프린터 기준이다. 현재 앱에서 동일 레거시 라벨을 출력할 수 없다는 사용자 조건을 유지하고 동일 라벨 재출력을 반복 요구하지 않는다.

## 실제 코드 경로
- [windows/runner/label_bitmap_print_channel.cpp](../windows/runner/label_bitmap_print_channel.cpp): `PrintBitmap`이 출력 순서를 결정한다.
- Debug만 [windows/runner/debug_print_file_target.h](../windows/runner/debug_print_file_target.h)의 `LABEL_MANAGER_DEBUG_PRINT_FILE`을 사용한다. 새 절대 로컬 PRN 경로 검증 후 같은 `PrintBitmap` 실행의 출력 대상만 바꾼다. 파일 성공은 `ok=false`로 반환해 DB 인쇄 저장을 차단한다. Release와 변수 미설정 시 기존 인쇄 유지. 자세한 실행법은 probe README의 실제 앱 캡처 절을 따른다.
- `ComposeFinalDeviceBitmap`: 기본 raster와 225개 native border 합성.
- `RenderWhiteTextIntoBitmap`: 투명 RICHEDIT50W, 굴림17dot Bold 흰 글자, 검정 배경. printer-reference EMF에 역상만 렌더한다.
- [windows/runner/inverse_text_layout.h](../windows/runner/inverse_text_layout.h): `MeasureInverseTextLayout`이 printer DC로 필요한 한 줄 폭을 측정하고 X축만 축소한다. Y/높이 유지, wrap/명시적 개행은 무보정.
- [windows/runner/inverse_text_bitmap.h](../windows/runner/inverse_text_bitmap.h): `CompositeInverseTextBitmap`이 EMF를 1bpp DIB에 직접 재생한다. 역상 clip만 32bpp base에 복사, 바깥과 alpha 보존. 글리프 후처리 threshold 없음, 초기 base 변환에만 128 사용.
- [windows/runner/inverse_text_geometry.h](../windows/runner/inverse_text_geometry.h)의 `PrepareInverseTextGeometry`가 합성된 역상 clip의 검정 픽셀을 가로 run으로 분리하고 전송용 raster에서는 해당 검정 픽셀만 흰색으로 비운다. 기존 흰 픽셀, clip 밖 RGB, alpha는 보존하며 threshold/팽창/폰트 변경은 없다. 중복 clip도 한 번만 처리한다.
- 단일 32bpp `StretchDIBits`로 비운 raster를 전송한 뒤 `RenderInverseTextGeometry`가 같은 위치에 `ExtCreateRegion`/`FillRgn`으로 검정 도형을 출력한다. 이어서 기존 검정 `DrawTextW`와 워터마크를 출력한다. 일반 글자/표선은 기존 경로를 유지한다.
- `CaptureNativeTextComparison`: 실제 검정 출력 성공 후 같은 함수를 참조 EMF에 실행한다. [windows/runner/native_text_comparison.h](../windows/runner/native_text_comparison.h)의 `ReplayNativeTextComparison`으로 base 위에 재생하고 역상별 흰->어두운 픽셀 수를 센다. 실제 출력 비트맵이나 printer DC를 변경하는 보정은 아니다.

## 다음 판별
1. 실물 실패와 실제 앱 파일 대상 호출의 픽셀 보존 확인까지 완료됐다. 같은 원본을 다시 렌더하거나 같은 라벨을 같은 코드로 재출력하는 대신, 파일 대상/USB 실제 전송 바이트의 차이를 구분한다. 프린터 설정 변경이나 열 문제 확정으로 넘어가지 않는다.
2. v1.3.97 후속 합성은 2026-09-09 자료에서 손실0/0으로 분석 완료했다. 새 출력의 `*_after_native.txt`와 대응 BMP/EMF는 일반 글자 겹침 회귀가 없는지 확인한다.
3. `referenceDrawn/Fitted`와 실제 `nativeTextDrawn/Fitted`를 비교한다. 실제 drawn에는 역상 2건도 포함될 수 있으므로 검정 descriptor 수를 따로 계산한다. 측정 차이가 있으면 같은 결과라고 단정하지 않는다.
4. `inverse[index].whitePixelsLost` 및 `native[index].sourceRect`, BMP를 함께 확인한다. 수치는 원래 흰 픽셀이 후속 합성 후 휘도128 미만으로 바뀐 수이다.
5. 손실이 있으면 실제 겹치는 descriptor/최종 DrawText 영역을 먼저 조사한다. 검정 글자의 기본 DrawText clip도 있으므로 역상 제외 clip이 없다는 사실만으로 덮임 원인이라고 판단하지 않는다.
6. 손실이 0이면 참조 재생에서 덮임을 재현하지 못한 것이다. 바로 열 번짐/드라이버 결함으로 확정하지 말고 참조와 실제 출력의 차이를 다음 국소 가설로 좁힌다. 근거 없이 폰트/농도/threshold를 다시 순환 변경하지 않는다.

## 진단 한계
- v1.3.107 `_comparison.bmp`는 도형 분리 전의 역상 픽셀 원본이다. 실제 전송 raster는 해당 역상 clip을 비운 뒤 별도 검정 도형으로 복원한다. 일반 검정 native text/워터마크 이전이며 뒤 역상 파일에는 앞 역상이 포함될 수 있다.
- `_after_native.bmp`는 검정 text까지 포함한 별도 참조 재생이다. 실제 전송 비트맵/스풀 캡처가 아니며 워터마크도 없다. EMF DC와 printer DC의 폰트 측정 차이 가능성을 남긴다.
- `EM_FORMATRANGE` 반환값은 boolean이 아니라 문자 위치이며 종결 문단 때문에 입력 길이+1이 가능하다. accepted=true, descriptor 성공 수, 전체 문자 수용은 실물 획 품질을 입증하지 않는다.
- 레거시 RTF 5pt -> 현재 descriptor11dot(레거시 물리 기대14dot) 차이는 characterization으로 재현됐지만 이번 실제 출력은17dot이다. 확정 원인으로 사용하지 않는다.

## 실험 이력 요약
| 기준 | 확인 결과 |
| --- | --- |
| v1.3.94 / 4bc31d4 | WS_EX_TRANSPARENT로 줄 끝 흰 채움 제거, 측정 폭/X축 fit으로 전체 문구 수용. 획 소실은 지속. |
| v1.3.95 / fb01e91 | 역상 EMF를 base에 합성. EMF 헤더 frame 기준 재생으로 약0.54% X 확대 오류 교정. 획 소실 지속. |
| v1.3.96 / 5c62559 | 글리프를 직접1bpp로 렌더. 물리 결과 IMG0005에서 획 소실 지속. |
| v1.3.97 / d0ade63 | 검정 글자 후속 합성 관측 추가. 2026-09-09 실물의 참조 손실0/0으로 덮임 미재현. |
| v1.3.107 / 1c013ce | 역상 clip의 검정 GDI region 전송. 픽셀 동등성 통과했으나 IMG0002/종이에서 흰 획 소실 지속. |
| v1.3.108 | 파일 전용 G500 드라이버 probe 및 Q 해석기 추가. 단일 역상 재현의 흰 손실0/레거시 DEVMODE 파일 동일. 생산 출력 변경 없음. |
| v1.3.109 | 페이지 재생과 실제 앱 Debug 파일 대상 호출 모두 두 역상 손실0/차이0. Q 백색 패딩 수정/파일 캡처 추가. 일반 품질 보정 없음. |

- DirectWrite/GGO/FreeType/supersample/마스크 팽창, direct-white, 전체 페이지 EMF/1bpp, EZPL Q/펌웨어 역상, 농도·속도·회색·checkerboard·냉각행 실험은 실패 이력이 있다. 과거 코드를 새 해결책처럼 재사용하지 않는다. 상세는 git history로 조회한다.
- SES_EXTENDBACKCOLOR/EM_SETTARGETDEVICE(0)만으로 폭 미수용을 해결하지 못했다. NULL DC EnumEnhMetaFile callback 재생도 worldtransform 명령에서 실패했다.
- 소프트웨어 개선 불가/열 번짐 확정이라는 과거 판정은 철회됐다. 일반 표선을 capture에 있다고 가정하고 native border 합성을 끄는 회귀도 반복하지 않는다.

## 검증과 실행
- 마지막 구현 검증: native CTest 1/1, 관련 Dart31건, Windows Debug `/WX` 빌드 성공. 합성 검사에서 3x3 겹침=9/비겹침=0, 좌표 및 alpha 보존 확인. 실제 출력 진단과 품질 개선은 별도 미검증.
- probe의 CTest/bitmap replay는 StartDoc 없이 동작하며, 명시적 `--driver-file*` 모드만 로컬 파일 대상 StartDoc를 사용한다. 설치된 프린터/폰트가 필요하다. 옵션과 한계: [tools/inverse_rich_edit_probe/README.md](../tools/inverse_rich_edit_probe/README.md).
- PowerShell, 저장소 루트에서 실행할 명령:

```powershell
& 'C:/Program Files/Microsoft Visual Studio/2022/Professional/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe' --build .tmp/inverse_probe_build --config Debug
& 'C:/Program Files/Microsoft Visual Studio/2022/Professional/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/ctest.exe' --test-dir .tmp/inverse_probe_build -C Debug --output-on-failure
C:/Flutter/bin/flutter.bat test test/godex_inverse_reference_test.dart test/label_sheet_print_job_test.dart test/label_print_dispatcher_test.dart
$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug
```

- native 변경은 hot reload만으로 반영되지 않는다. 기존 실행 프로세스 확인 후 Debug 재빌드/재실행 및 새 시작 로그 버전 확인. Dart 변경은 DTD 앱 연결/재시작 절차도 따른다.
- 배포 빌드/설치파일/원격 push/DB migration/프린터 설정 변경은 하지 않는다. 기존 [lib/core/app.dart](../lib/core/app.dart) 변경은 임의 원복하거나 섞어 커밋하지 않는다.
- `.tmp` 사진/진단/probe/캐시는 재개 자료로 보존하며 stage하지 않는다. 비밀번호 등 접속 비밀은 문서/로그에 재기록하지 않는다.
- 상시 규칙은 [SESSION_RULES.md](../SESSION_RULES.md), 현재 우선순위는 [SESSION_HANDOFF.md](../SESSION_HANDOFF.md)를 따른다.