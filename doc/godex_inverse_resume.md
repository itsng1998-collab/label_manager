# G500 역상 출력 재개

## 재개 조건
- **2026-09-11 사용자 지시: 앱 오동작 디버깅 먼저, 역상은 이후 재개**. 현재 우선순위는 [SESSION_HANDOFF.md](../SESSION_HANDOFF.md), 상시 규칙은 [SESSION_RULES.md](../SESSION_RULES.md)를 따른다.
- 실물 역상 획 소실은 미해결이다. 레거시는 같은 PC/프린터에서 정상 출력된다. 설치/USB 캡처를 다음 필수 단계로 삼은 판단은 철회했다.
- 사용자에게 같은 코드의 재출력이나 동일 레거시 라벨 재현을 반복 요구하지 않는다. 현재 앱에서 동일 레거시 라벨을 출력할 수 없다는 조건을 유지한다.

## 확정 상태
- 마지막 생산 수정 **v1.3.112 / `02864cf`**: 새 RTF 가져오기 글자 크기의 point->logical pixel 변환(96/72). 셀/raw/인라인/native HTML에 적용하며 point 기반 줄간격 계산은 유지한다.
- 새 RTF의 일반 글자도 변환 대상이다. 기존 저장 시트/일반 출력 엔진/표선을 전역 확대하지는 않는다. 기존값의 point/pixel 출처가 불명확하므로 자동 재변환/재저장하지 않는다.
- 검증:5/6/8pt가14/17/23dot, 저장/재로드 크기 보존, 기존 시트8pixel 일반/역상17dot 유지. 관련203건/인쇄27건(중복 포함), analyze, Debug `/WX` 빌드, hot reload 통과. **현재 실패 라벨의 실물 개선은 미검증**.
- v1.3.113은 세션 전환 문서 정리 버전이며 새 EXE 빌드 없음. 마지막 검증 EXE1.3.112/native 마크1.3.107. 이후 run 터미널 종료 알림을 받았고 9월11일 앱 프로세스 없음 확인. 새 세션에서 실행 상태를 다시 확인한다.

## 다음 판별
1. 앱 오동작 처리를 먼저 마친다. 역상에 복귀할 때 현재 코드/버전/사용자 변경을 다시 확인한다.
2. 마지막 재현 대상 brand1526/labelSize8114/item722292의 **실제 저장 형식 및 글자 크기 출처**를 확인한다. 값은 이후 달라질 수 있으므로 사용자 재현 대상과 맞춘다.
3. 조회는 `COALESCE(NULLIF(RICH_FORM_SHEET, ''), RICH_FORM_DATA)` 및 품목의 `RICH_ELEMENT_SHEET` 우선 구조다. 최종 alias만 보고 원본 RTF라고 추정하지 않는다. 기존 자료를 우선하고 필요하면 읽기 전용으로 원본과 시트를 각각 비교한다. 로그 처리 함수에 이 판단을 넣지 않는다.
4. 원본 RTF point, 저장 시트 cell/inline fontSize, 현재 descriptor17dot, 폭636/616과 X축 축소율을 연결한다. **17dot만으로 원본8pt였다고 단정하지 않는다**.
5. 이미 저장된 시트라면1.3.112 새 가져오기 수정이 적용되지 않을 수 있다. 사용자 편집을 잃는 강제 RTF 재생성이나4/3 일괄 확대는 금지한다. 확인된 차이와 해당 테스트를 근거로 최소 변경한다.
6. 새로운 판별 목적/수정이 생겼을 때만 사용자 실물 테스트를 요청한다. 자동 물리 인쇄/프린터 설정 변경은 하지 않는다.

## 증거 목록
아래는 이전 세션에서 확인한 자료다. `.tmp`는 Git에 없으므로 실제 존재 여부를 확인한 뒤 사용한다. 없다면 이전 검증 결과와 현재 재검증 가능 여부를 구분한다.

**2026-09-11 점검 결과:** 정상/실패 사진, 레거시 `PrintManager.cpp`, 최신23:48 앱 로그는 존재한다. 아래23:10/23:21 앱 로그, 실제 앱 PRN/PNG, 대응 inverse/after-native TXT3개, RTF analyze/build 로그와 probe build 폴더는 현재 없다. 삭제 원인은 확인하지 않았고 이번 정리에서 삭제한 자료는 없다. 과거 픽셀/해시 수치는 이전 검증 기록이며 현재 다시 계산한 결과가 아니다. 추가 증거가 필요하면 기존 백업 유무부터 확인하고, 자동 재출력/재저장으로 복원하려 하지 않는다.

| 자료 | 이전 검증 결과 |
| --- | --- |
| `.tmp/IMG_v0.Legacy_print.png` | 같은 환경의 레거시 정상 역상. 문구/배치는 현재 실패 라벨과 다름. |
| `.tmp/IMG_20260909_0003.png` | 앱1.3.108/native1.3.107에서 두 검정 띠의 흰 획 소실 지속. |
| `.tmp/log/app_2026-09-09_23-10-24.log` | IMG0003 출력 로그. 도형951개, 흰2806, 후속 합성 손실0. |
| `.tmp/log/app_2026-09-09_23-21-37.log` | 실제 앱1.3.109 파일 캡처, `debugFileCaptured=true physicalPrintSubmitted=false`. 인쇄 저장 트랜잭션 없음. |
| `.tmp/log/godex_inverse/actual_app_v109.prn` 및 `.png` | 실제 앱의 최종 파일 대상 출력. 두 역상 흰1298/1508, 손실0/증가0/차이0. |
| `.tmp/log/app_2026-09-09_23-48-43.log` |1.3.112 일반 모드 실행/검증. 전달된 종료 알림은 품목 로드 완료와 hot reload 성공까지 포함, 종료 원인 미확정. |
| `.tmp/rtf_font_units_analyze.log`, `.tmp/rtf_font_units_build.log` |1.3.112 analyze 및 Debug `/WX` 빌드 성공 기록. |

- 실제 PRN SHA256: `C0D38BD589BE26465B8F955F9D3EAC261B1E20A4190BCBA9E9B347F1D6AE50B5`.
- 같은 실행 원본 prefix(디렉터리 `.tmp/log/godex_inverse`): `v1.3.107_13308_11451875_1`, `v1.3.107_13308_11451906_2`; 후속 참조 `v1.3.107_13308_11452203_1_after_native`. 각 prefix의 `.txt/.emf/_base.bmp/_comparison.bmp`를 한 세트로 사용한다.
- 참조 페이지 `v108_driver_page.prn/.png`는 IMG0003의 마지막 원본 `v1.3.107_18248_10663312_2`와 `v1.3.107_18248_10663640_1_after_native`로 재생했다. 실제 앱 파일과 차이는 역상 밖(537,58) 한 픽셀, 역상 차이0.
- Q10,11,76,472: 8행 정렬로 페이지 밖3행/1824픽셀이 있으나 전부 백색. 해석기는 최대7픽셀 빈 패딩만 허용하고 검정 overflow는 거부한다. payload의 CR/LF를 구분자로 해석하지 않는다.
- IMG0002는 스캐너 흑백 이미지이며 종이에서도 획 소실이 같다는 사용자 확인을 받았다. 스캔만의 문제로 판단하지 않는다.
- 레거시/current DEVMODE 방식의 단일 역상 PRN SHA256 동일: `00A3FE63D640B70C01DF5905717D5B4FE727C389A7A86E837FBC42CA4A5AF64B`.

## 글리프 비교
- `eb2a01f`의 무출력 `--font-reference`: 굴림 Bold의 '계란,우유,대두,밀 함유'를5/6/8pt RTF, 동일 twip 평문 재구성, 수정 전96dpi 환산으로 비교한다.
- 실제 문구/폰트/twip 계약 확인 후 위치 정렬 비교: 동일 twip이면 세 크기 모두 글리프 차이0. 수정 전 환산의 흰 픽셀은634->469/688->571/993->688.
- 합성8pt 원본은 글리프 높이20픽셀,17dot/121twip 재구성은14픽셀. 합성 크기 비교이지 현재 실패 라벨의 출처/실물 원인을 입증하지 않는다.

## 제어 코드
- [lib/features/label_sheet/application/label_sheet_rtf_import.dart](../lib/features/label_sheet/application/label_sheet_rtf_import.dart): 새 RTF의 point->logical pixel 변환. 관련 회귀는 [test/godex_inverse_reference_test.dart](../test/godex_inverse_reference_test.dart), [test/label_sheet_toolbar_test.dart](../test/label_sheet_toolbar_test.dart).
- [lib/printing/label_sheet_print_job.dart](../lib/printing/label_sheet_print_job.dart): 시트 논리 글자 크기와 `dotsPerLogicalPixel`로 native descriptor를 생성한다.
- [windows/runner/label_bitmap_print_channel.cpp](../windows/runner/label_bitmap_print_channel.cpp)의 `PrintBitmap`: 기본 raster/225개 border 합성 -> 역상 EMF/1bpp 합성 -> 역상 clip의 검정 분리 ->32bpp StretchDIBits -> 검정 GDI region -> 일반 DrawTextW -> 워터마크.
- [windows/runner/inverse_text_layout.h](../windows/runner/inverse_text_layout.h): printer DC 측정과 X축 fit. Y/높이는 유지, wrap/명시적 개행은 무보정.
- [windows/runner/inverse_text_bitmap.h](../windows/runner/inverse_text_bitmap.h): EMF를1bpp DIB에 재생, clip만 합성하고 외부/alpha 보존. 초기 base 변환만 threshold128, 글리프 후처리 없음.
- [windows/runner/inverse_text_geometry.h](../windows/runner/inverse_text_geometry.h): clip의 검정 run을 분리하여 전송 raster에서 비우고 `ExtCreateRegion/FillRgn`으로 복원.
- [windows/runner/native_text_comparison.h](../windows/runner/native_text_comparison.h): 일반 검정 문자의 별도 참조 재생과 역상 흰 손실 관측. 생산 bitmap이나 장치 출력 보정이 아니다.
- 레거시 `.tmp/LabelManager/LabelManagerLib/PrintManager.cpp`는 원본 RTF를 MM_TEXT/FormatRange로 출력한다. 같은 폴더 `ITSnGRichEditCtrl.cpp`도 참고. 레거시 소스가 없다면 먼저 존재 여부부터 확인한다.

## 환경 및 진단 한계
- G500/USB001/80x60mm/203dpi, source640x480 -> target620x480, physical640x480, offset10,0/destination0,0. 마지막 두 clip은15,83,600,102 및15,284,600,303, font17dot Bold/121twip, layout636/616, scaleX .919811/.949675.
- `_comparison.bmp`는 역상 도형 분리 전의 원본, `_after_native.bmp`는 별도 참조 재생이다. 둘 다 USB 전송 캡처가 아니다. `EM_FORMATRANGE` 반환값은 문자 위치로 종결 문단 때문에 길이+1이 가능하다.
- 실제 앱 PRN의 픽셀 보존은 '현재 원본이 그대로 전달된다'는 증거다. '레거시와 같은 원본/실물 정상/열 문제'를 입증하지 않는다. USB 제출 데이터 동일성도 미확정이나 현재 우선 블로커로 삼지 않는다.
- [windows/runner/debug_print_file_target.h](../windows/runner/debug_print_file_target.h)의 Debug 환경변수 `LABEL_MANAGER_DEBUG_PRINT_FILE`은 새 절대 로컬 PRN만 허용한다. 성공도 `ok=false`를 반환해 인쇄 접수/이력/자동증가를 막는다. 기존 파일 덮어쓰기나 실물 fallback은 없다. 일반 실행은 변수를 제거한다.
- 구체적인 파일 모드 사용법은 [tools/inverse_rich_edit_probe/README.md](../tools/inverse_rich_edit_probe/README.md). 실제 앱 파일 캡처는 이미 완료했으므로 다시 사용자 조작을 요구하지 않는다.

## 반복 금지 이력
| 버전/커밋 | 확인 결과 |
| --- | --- |
|1.3.94 / `4bc31d4` | 투명 control과 X축 fit으로 끝 흰 채움/문구 미수용 해소, 획 소실 지속. |
|1.3.95 / `fb01e91` | EMF frame 환산으로 약0.54% 확대 오류 교정, 획 소실 지속. |
|1.3.96 / `5c62559` | 직접1bpp 렌더, 실물 획 소실 지속. |
|1.3.97 / `d0ade63` | 후속 검정 덮임 관측, 손실0/0으로 원인 미재현. |
|1.3.107 / `1c013ce` | 역상 검정 GDI region 전송, 픽셀 동등성 통과했지만 실물 실패. |
|1.3.108 / `ba52808` | 단일 역상 드라이버 파일 손실0, legacy DEVMODE 파일 동일. |
|1.3.109 / `a4ffd5e` | 참조 페이지/실제 앱 파일 대상 모두 역상 손실0. |
|1.3.111 / `eb2a01f` | RTF/평문 동일 twip 글리프 동등성, 크기 단위 비교. |
|1.3.112 / `02864cf` | 새 RTF 크기 단위 수정, 기존 실패 시트 및 실물 개선 미검증. |

- DirectWrite/GGO/FreeType/supersample/마스크 팽창/direct-white/전체 페이지 EMF·1bpp/EZPL Q·펌웨어 역상/농도·속도·회색·checkerboard·냉각행은 실패 이력이 있다. 새 해결책으로 반복하지 않는다.
- SES_EXTENDBACKCOLOR/EM_SETTARGETDEVICE(0)만으로 폭 문제 미해결. NULL DC EnumEnhMetaFile callback 재생은 worldtransform 명령에서 실패했다.
- 프린터/열/하드웨어 결함 확정 또는 소프트웨어 개선 불가 결론 금지. 일반 표선이 capture에 있다고 가정해 native border 합성을 끄는 회귀 금지.

## 재검증 명령
아래는 필요 시 실행할 명령이다.1.3.113 문서 정리에서는 앱/인쇄 테스트를 재실행하지 않았다. 마지막 native CTest2/2, PowerShell 해석기7건은 이전 검증 결과다.

```powershell
& 'C:/Program Files/Microsoft Visual Studio/2022/Professional/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe' --build .tmp/inverse_probe_build --config Debug
& 'C:/Program Files/Microsoft Visual Studio/2022/Professional/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/ctest.exe' --test-dir .tmp/inverse_probe_build -C Debug --output-on-failure
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe --font-reference .tmp/inverse_font_reference
C:/Flutter/bin/flutter.bat test test/godex_inverse_reference_test.dart test/label_sheet_toolbar_test.dart
C:/Flutter/bin/flutter.bat test test/label_sheet_print_job_test.dart test/label_print_dispatcher_test.dart
./tools/test_inverse_driver_file.ps1 -OutputDirectory .tmp/inverse_driver_parser_test
```

- probe build 폴더가 없으면 README의 CMake 구성부터 수행한다. CTest/reference/replay는 StartDoc 없음, `--driver-file*`만 명시적 로컬 파일 출력이다.
- 새 native 수정은 Debug 재빌드/재실행 및 시작 로그 버전 확인. Dart 변경 후 DTD 연결/hot reload 또는 restart. 배포/설치파일/push/DB migration/프린터 설정 변경은 명시 요청 없이 하지 않는다.
- 로컬 사진/원본/PRN/EMF/BMP는 보존하되 stage/외부 업로드하지 않는다. 없는 자료와 미검증 사항을 다음 핸드오프에 남긴다.