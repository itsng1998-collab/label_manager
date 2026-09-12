# 세션 핸드오프

## 시트 기반 레거시 좌표 적용 (2026-09-12)
- **일반 문자 장치 좌표 적용/무출력 검증 완료, 실물 품질 미검증**. 실제 출력 원본은 현재 시트만 사용한다. RTF는 이전 라벨 변환 참고용이며 원본RTF 직접 출력/시트->RTF 변환 제안은 철회했다. 편집/저장/변수치환은 유지한다.
- `native_text_device_layout.h`의 `MapNativeTextToDevice`/`SetNativeTextDeviceCoordinates`: 셀좌표를 기존 배율로 먼저 변환하고 글자높이는 세로배율로 환산한다. `RenderNativeTextToPrinterDc`는 MM_TEXT에서 측정/출력해 페이지 가로배율이 글꼴에 걸리지 않는다. 셀내 맞춤/정렬/줄바꿈/DC복원은 유지한다.
- 범위: Windows driver 일반문자와 후속 참조 렌더에 적용. 시트저장/배경/표선/바코드/이미지/역상 엔진은 변경하지 않는다. 과거 실패한 역상 직접 흰글자 출력은 재사용하지 않는다. 전체 레거시 조판 엔진 이식 완료가 아니다.
- pubspec PATCH1.3.123->1.3.124. 적용 로그는 `nativeTextMapping=devicePixelsMMText`, `nativeTextDeviceVersion=1.3.124`; 역상 전송/워터마크1.3.107과 구분한다.
- 검증: `C:/Flutter/bin/flutter.bat build windows --debug --no-pub`47.4초PASS; probe build/CTest3건PASS. 강화된 `--native-device-text`는 G500 printer DC/참조EMF 기준 이전640->620의171x17dot vs MM_TEXT175x17dot 차이를 재현했고 새620/640/1240 입력은 모두175x17dot PASS. StartDoc 없는 메트릭 검사다.
- `C:/Flutter/bin/flutter.bat test --no-pub test/windows_bitmap_printer_test.dart test/label_sheet_print_job_test.dart test/label_print_dispatcher_test.dart`32/32PASS(VS Code runTests 미발견으로CLI 대체). 빌드/테스트 로그 `.tmp/native_text_v124_build.log`, `.tmp/native_text_v124_tests.log` 보존.
- 실제 앱 Debug 실행/hot reload/런타임 오류없음 확인. 환경변수 `LABEL_MANAGER_DEBUG_PRINT_FILE`의 로컬경로를 VM에서 먼저 확인한 뒤 합성descriptor4개(굵기/가운데/우측/긴문구/두줄)를 native채널로 직접 전달했다. `nativeTextDrawn=4`, `nativeTextFailed=0`, `nativeTextFitted=1`, 새mapping/version, `debugFileCaptured=true`, `physicalPrintSubmitted=false` 확인. PRN해석/PNG 배치 확인PASS. DB/업무 인쇄이력/물리인쇄/설정변경 없음.
- 산출물 `.tmp/log/godex_inverse/native_device_v124.prn/.png`, 실행로그 `.tmp/native_text_v124_run.log`는 로컬 보존/커밋 제외. 파일전용 검증 앱은 Flutter q로 종료했다. 일반모드 앱은 새로 실행하지 않았다.
- README/doc에 시트전용 원칙/변경 범위/검증 명령을 반영했다. 남은 이슈: 실물 일반문자 품질과 기존 역상 획소실 미확인. 역상 수정 버전으로 안내하거나 효과 없는 동일 역상 재출력을 요구하지 않는다.
- 기능 커밋 **`aea007b`** (`시트 일반 문자 출력을 레거시 장치 좌표 방식으로 변경`) 완료. native helper/header+printer cpp, probe main/CMake/README, doc/godex_inverse_resume.md, pubspec.yaml, 이handoff의8개만 포함. 최종 probe build/CTest3건/diagnostics/공백검사PASS, 앱 프로세스 종료 확인. 기존 사용자 `.vscode/settings.json`, `lib/core/app.dart` 제외. 배포 빌드/원격push 없음. 해시 기록 후속 문서는 같은 요청으로 버전을 다시 올리지 않는다.

## 기존 레거시 근거로 조사 재개 (2026-09-12)
- **코드 비교/무출력 검증 완료, 실물 문제 미해결**. 기존 `.tmp/IMG_v0.Legacy_print.png`와 제공된 정보/환경은 그대로 유효하다. 레거시 재출력·동일 자료 재제출을 요구한 안내는 철회했다. 진단 A/B는 실제 레거시 프로그램 출력이 아니며 정상 레거시 기준을 대체하지 않는다. 비교 라벨 실물 제출을 선행 조건으로 두지 않는다.
- 레거시 `CITSnGRichEditCtrl::PreCreateWindow`도 RICHEDIT50W이다. `SetRTFText`는 장평 초기화 후 원본을SF_RTF로 읽고, `PrintRichEdit`는 printer DC의 FormatRange(TRUE) 직후 DisplayBand(&rc)를 호출한다.
- v1.3.123: 진단 `CreateInverseComparisonLabel`/main의 `--comparison-label-swapped`로 같은 좌표/크기에서 직접·비트맵을 비교한다.5pt 차이0,17dot 차이132(흰66개씩 이동), 차이는120g 구간뿐이고 한글 차이0이다. 기존120/121twip font-reference BMP도 해시동일. 해당 검사에서 한글 획 소실을 설명하지 못한다.
- `RenderInverseComparisonText`/main의 `--comparison-label-display-band`는 직접 구역에 레거시 후속 호출을 적용하고 실패 반환을 FAIL로 처리한다.4회 반환1, 추가 전후PRN SHA256동일(`4C4D6074FDC6C20276ECA493D3987D0424CC8DAE400EEF27E55B6307A2E4B360`). 해당 호출을 생산에 추가하지 않는다.
- 검증 완료: probe Debug build, `ctest --test-dir .tmp/inverse_probe_build -C Debug --output-on-failure`2/2, `./tools/test_inverse_driver_file.ps1 -OutputDirectory .tmp/inverse_driver_parser_v123`9건, 세 모드 파일생성/동일좌표0/132/0/132 및120g 밖0 자동검사, 기존v122 baseline/DisplayBand해시 동등성, 후속 반환값 검사 build/실행, diagnostics/`git diff --check` 모두PASS.
- 산출물 `.tmp/log/godex_inverse/inverse_paths_swapped*`, `inverse_display_band.prn`, `inverse_v123_checked_*`, `inverse_v123_display_result.prn`과 기존 증거는 로컬 보존/커밋 제외. 원본삭제/외부전송/DB/프린터 설정/실물 인쇄/앱 재실행 없음. 마지막 앱은1.3.121이며 종료 상태다.
- 진단README/doc의 재제출·실물대기 지시를 철회했다. pubspec PATCH1.3.122 ->1.3.123(진단/문서 변경). 비교 파일 형식1.3.122와 실행로그 probeVersion1.3.123을 구분한다. 생산 출력 코드는 변경하지 않았다.
- 남은 경계: 생성/파일변환에서 보존된 한글 획과 실물 소실의 차이. 사진상 레거시는 문구 주변 국소 검정, 현재는 전체 행 검정이나 이것을 원인으로 확정하거나 레이아웃/열 설정을 임의 변경하지 않는다. 효과를 입증할 생산 수정은 아직 특정하지 못했다.
- 기능 커밋 **`9286d05`** (`역상 동일 좌표 및 레거시 후속 호출 비교 검증`) 완료: probe header/main/README, doc/godex_inverse_resume.md, pubspec.yaml, 이handoff의6개 파일만 포함했다. 기존 사용자 `.vscode/settings.json`, `lib/core/app.dart`는 제외했다. 원격push 없음. 이 해시 기록은 같은 요청의 후속 문서 커밋이며 추가 버전 증가는 없다.

## 역상 두 번째 재테스트 (2026-09-12)
- **진단 준비 완료, 실물 문제 미해결**: `.tmp/IMG_20260912_0002.png`에서도 획 소실 지속. 앱1.3.121 실제 출력의 두 TXT는 padding11/4twip, scaleX1/width585/17dot이며 이전 수정 미적용이 아니다. 공백 맞춤만으로 실물 문제를 해결하지 못했다.
- 실제 새 원본은 `.tmp/log/godex_inverse/v1.3.107_12208_4741203_1`, `4741234_2`, `4741546_1_after_native`. 보기용 `sep12_v121_source.png`를 생성했으며 원본은 보존했다.
- 글리프 모드 비교 build/CTest통과:5/6/8pt 기본/고급 조판의 동일 twip 픽셀 동등성 통과. 해당 모드 자체가 글리프를 바꾼다는 가설은 지지되지 않았다. 생산 글리프 보정은 추가하지 않았다.
- 새 원본 driver-file-page 성공, 두 clip whiteLost/whiteGained/mismatches 모두0. 흰1266/1427이 보존됐다. 생성/파일 변환에서는 실물 손실이 재현되지 않으며 USB 데이터 동일성은 여전히 미확정이다.
- 사용자 선택: **별도 비교 진단 라벨 준비**, 자동 인쇄 없음.5pt/17dot과 RTF직접/현재비트맵 합성을 한 장에서 비교한다. 저장 라벨/프린터 설정 변경 없이 파일 생성과 명시적 수동 제출을 분리한다.
- 준비된 구역: A/B=RTF직접100/121twip, C/D=현재1bpp+검정region100/121twip.8개 일반·역상 문구의 크기/폰트/전체수용 검증 및 파일 생성PASS, physicalPrintRequested=false. `CreateInverseProbePrinter`는 기존80x60/203dpi DC 구성을 재사용한다. `--comparison-label` 파일 준비와 `--submit-comparison-label` 사용자 수동 제출을 분리했다.
- PRN은 Q블록8개다. `inspect_inverse_driver_file.ps1`에 SourcePrefix 생략 미리보기/다중Q를 지원하고 기존 단일Q 원본 비교는 유지했다. 해석기 검증 명령: `./tools/test_inverse_driver_file.ps1 -OutputDirectory .tmp/inverse_driver_parser_v122`.
- 해석기9건PASS, native CTest2/2 PASS, 진단PNG 시각 확인 완료(네 구역/8문구 잘림·겹침없음). PRN의 역상 정렬 비교는 A/C차이0, B/D차이132다. 실제 실물 비교 결과는 아직 없다.
- 버전 PATCH1.3.121 -> 1.3.122: 생산 인쇄 동작 변경 없이 진단 도구/검사 추가. Windows 앱 재빌드/실행/배포 및 DB 변경은 이번 단계에서 하지 않았다.
- 진단 도구 README에 파일 생성/미리보기/사용자 수동 RAW 제출 명령을 기록했다. 제출 경로는 실제 인쇄 미검증이며 에이전트는 실행하지 않는다. `.tmp/log/godex_inverse/inverse_comparison_v122.prn`/`.png`는 로컬 보존/커밋 제외한다.
- 최종 build/CTest2건/해석기9건 및 diagnostics/공백 검사PASS. 최종 코드 재생성 파일과 준비된 PRN SHA256동일(`4C4D6074FDC6C20276ECA493D3987D0424CC8DAE400EEF27E55B6307A2E4B360`), 기존파일 덮어쓰기 거부PASS. 새 임시 PRN과 원본 증거는 삭제/외부전송/stage하지 않는다.
- 실물 비교/사진 제출을 다음 필수 액션으로 삼은 안내는 철회했다. 준비된 파일/수동제출 기능은 보존하지만 추가승인 없이 실행하지 않는다.132픽셀차이는 위 동일좌표 검사에서120g 구간으로 분리했다.
- 기능 커밋 **`40af7eb`** (`역상 실물 판별용 글자 크기와 출력 경로 비교 진단 추가`) 완료. 진단/검사/문서9개만 포함하고 기존 사용자 `.vscode/settings.json`, `lib/core/app.dart`는 제외했다. 생산 코드 변경 없음/앱 종료 상태 유지. 후속 기록은 같은 요청의 문서 정리로 버전을 다시 올리지 않는다.

## 역상 재개 (2026-09-12)
- **이전 보완 구현/무출력 검증 완료, 후속 IMG0002 실물 실패**. 사용자 사진 `.tmp/IMG_20260912_0001.png`와 앱1.3.120 로그에서 brand1526/labelSize8114/item722292의 흰 획 소실 지속을 확인했다. 기존 두 역상은17dot/121twip, scaleX0.919811/0.949675, 후속 참조 흰 손실0이다.
- **v1.3.121**: [windows/runner/inverse_text_layout.h](windows/runner/inverse_text_layout.h)의 `MeasureInverseTextLayout`은 내부 연속 공백만 줄여 수용 가능한 경우 글자 배율1을 유지한다. 공백만으로 부족하면 원래 간격/조판 옵션을 복원하고 기존 X축 fit을 사용한다. 일반 글자/표선/저장 크기/문구는 변경하지 않았다.
- [windows/runner/label_bitmap_print_channel.cpp](windows/runner/label_bitmap_print_channel.cpp)의 `RenderWhiteTextIntoBitmap`은 descriptor마다 자간을 초기화하고 렌더 후 조판 옵션을 복원한다. 로그 `inversePaddingFitVersion=1.3.121`, `inversePaddingReductionTwips`, TXT `layoutPolicy=paddingSpacingThenMeasuredWidthV121`로 적용 여부를 확인한다. 기존 전송/워터마크1.3.107과 별도다.
- 읽기 전용 앱/DB 확인: `RICH_FORM_DATA`4396자와 `RICH_FORM_SHEET`4624자 모두 ZIP/base64 시트이며 역상 셀(3,1)/(9,1)은 fontSize8/raw8/runs없음이다. 새 RTF 가져오기 수정은 적용되지 않는다. 이력55202(2026-06-30)의 두 제목은5pt/별도 셀 구조여서 현재8px을 원래8pt의 축소로 단정할 수 없다. 강제 재생성/재저장/4:3 확대는 하지 않았다.
- 검증: probe Debug `/W4 /WX` 빌드, `ctest --test-dir .tmp/inverse_probe_build -C Debug --output-on-failure` **2/2 통과**. 합성 문구의 기존 폭659/배율0.887709 실패를 먼저 재현했고 수정 후585/1이다. 글자121twip/자간0, selection 및 공백 부족 fallback 복원도 통과했다.
- 오늘 실제 EMF의 원문72/75자 `--exact-emf` 검사 각각PASS. 공백 감소11/4twip, 두 배율1/폭585, 합성 불일치0이다. 숫자 꼬리를 붙이는 기존 모드도 두 건PASS. 이 검사는 StartDoc 없는 참조 검사이며 실물/실제 USB 전달을 입증하지 않는다.
- Windows Debug build성공, 일반 모드 v1.3.121 재실행/DTD 연결/hot reload성공, runtime error없음. 이후10:34 창 닫기 승인/DB disconnect완료와 앱 프로세스 없음 확인. 현재 앱은 종료 상태다. 로그는 `.tmp/log/app_2026-09-12_10-10-25.log`, 빌드/실행 로그는 `.tmp/inverse_v121_windows_build.log`/`.tmp/inverse_v121_windows_run.log`이다. 에이전트의 자동 실물 인쇄는 하지 않았다.
- 증거 보존: `.tmp/log/godex_inverse/v1.3.107_12824_2240312_1`, `2240343_2`, `2240656_1_after_native` EMF/BMP/TXT 및 보기용 `sep12_source.png`. 새 무출력 결과는 `.tmp/inverse_sep12_exact_allergy`/`.tmp/inverse_sep12_exact_nutrition`이다. 임시 판별 코드는 제거했고 로컬 자료/캐시는 삭제하거나 stage하지 않는다.
- 버전 PATCH **1.3.120 -> 1.3.121**: 저장 형식과 글자 높이를 유지하는 역상 배치 보완. 다음은 새 버전 실물 결과에서 흰 획을 비교하는 단계이며 같은 미변경 코드의 반복 출력은 요구하지 않는다.
- 최종 diagnostics/`git diff --check` 통과. stage/commit 대상7개: 이 문서, `pubspec.yaml`, 위 native2개, `tools/inverse_rich_edit_probe/main.cpp`, 해당 README, `doc/godex_inverse_resume.md`. 범위 밖 사용자 변경 `.vscode/settings.json`, `lib/core/app.dart`는 제외한다.
- 기능 커밋 **`afc0201`** (`역상 공백 우선 맞춤으로 글자 가로 축소 방지`) 완료. 커밋 해시 기록은 같은 요청의 후속 문서 변경이며 버전을 다시 올리지 않는다.

## 품목관리 키보드 가로 스크롤 (2026-09-11)
1. **완료**: 품목관리 표에 포커스가 있을 때 `Shift+왼쪽/오른쪽 방향키`로 가로 스크롤하도록 추가했다.
2. [lib/features/item/presentation/item_manage.dart](lib/features/item/presentation/item_manage.dart)의 품목관리 전체 `Focus`에서 조합키를 처리하되 셀 텍스트 편집 중에는 기존 키 동작을 유지한다.
3. [test/item_manage_horizontal_scroll_test.dart](test/item_manage_horizontal_scroll_test.dart)에서 오른쪽 키의 offset 증가와 왼쪽 키의 원점 복귀를 검증한다. 버전은 PATCH **1.3.119 -> 1.3.120**으로 갱신했다.
4. 회귀 테스트 **1건 통과**, focused analyze **No issues found**, diagnostics 및 `git diff --check` 통과.
5. Windows v1.3.120 디버그 빌드/실행 및 hot reload 성공. 터미널에 runtime 예외가 없었다. DTD에 앱이 노출되지 않아 실제 UI 자동 입력은 수행하지 않았다.
6. 기능 커밋 `b824454` (`품목관리 Shift 방향키 가로 스크롤 추가`) 완료. 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 제외했다.

## 최우선 순서 (2026-09-11)
1. **완료**: 사용자 관리에서 3575가 김영모(75806065) 계정으로 접속할 때 화면 전환 후 멈추는 재발 문제를 수정했다.
2. 제출된 v1.3.106 로그에서 대상 세션은 `renderReady/completed`까지 완료됐고 마지막 로그는 `labelSheetDraftFromRichEditRtfAsync: async convert start length=1235 hash=363178412`다. DB/화면 전환이 아니라 품목 미리보기 RTF 변환에서 멈췄다.
3. 과거 `503fa16`의 `preferNative:false`는 현재도 유지된다. 정상 325자 RTF도 CP949 첫 플랫폼 변환에 약 2.8초가 걸려, Windows item preview의 `CharsetConverter.decode` 플랫폼 채널을 Win32 `MultiByteToWideChar(CP949)` 직접 호출로 교체할 예정이다.
4. [lib/utils/windows_cp949.dart](lib/utils/windows_cp949.dart)에 Win32 CP949 decoder를 추가하고, [lib/features/label_sheet/application/label_sheet_rtf_import.dart](lib/features/label_sheet/application/label_sheet_rtf_import.dart)에 item preview 전용 선택 옵션을 연결했다.
5. [lib/home_page_manager.dart](lib/home_page_manager.dart)의 품목 단일 셀 RTF preview는 native RTF 변환과 charset 플랫폼 채널을 모두 우회한다. 일반 RTF 저장/편집과 비-Windows fallback은 유지한다.
6. [test/label_sheet_toolbar_test.dart](test/label_sheet_toolbar_test.dart)에 CP949 `제품명` 복원 및 플랫폼 채널 0회 회귀 테스트를 추가했고 해당 테스트 **1건 통과**. 버전은 PATCH **1.3.118 -> 1.3.119**로 갱신했다.
7. 제출 로그의 1235자보다 큰 다중 CP949 RTF 성능 테스트를 추가했다. Windows 직접 변환은 동기 **52ms**, 전체 **72ms**에 완료돼 2초 제한 내 통과했다.
8. `label_sheet_toolbar_test.dart`와 `home_page_manager_session_test.dart` 전체 실행은 **205건 통과, 1건 실패**다. 실패는 범위 밖 Gemini API의 `429 RESOURCE_EXHAUSTED` quota이며 RTF/홈 세션 테스트 실패는 없다.
9. 최종 관련 테스트 **9건 통과**, 변경 파일 focused analyze **No issues found**, diagnostics 및 `git diff --check` 통과. 성능 회귀 테스트는 CP949 한글 결과를 검증하고 10초 내 완료로 멈춤을 감지한다.
10. Windows v1.3.119 디버그 빌드/실행 및 hot reload 성공, runtime error 없음. 앱은 정상 종료했다. Flutter Driver 확장이 없어 실제 UI 자동 계정 전환은 수행하지 않았다.
11. 사용자 재테스트 로그에서 `labelSheetDraftFromRichEditRtfAsync: async convert start` 뒤 `charset decode success charset=Win32-CP949`, `async decode done`, `async convert done`이 이어져야 한다.
12. 기능 커밋 `1136fb9` (`품목 미리보기 CP949 변환 멈춤 수정`) 완료. 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 제외했다.

## 업데이트 메시지 재표시
1. **완료**: 관리자가 선택한 TESTER1의 업데이트 메시지가 재로그인 시 표시되지 않는 문제를 수정했다.
2. 제출된 v1.3.106 로그에서 TESTER1 대상 저장 배치는 성공/커밋됐고, 재로그인 공지 조회도 예외 없이 완료된 뒤 TESTER1 사용자 조회로 진행됐다. DB 저장 실패가 아니라 로그인 dialog의 사용자 전환 상태를 원인으로 확정했다.
3. 3575 공지를 확인해 `_noticeConfirmed=true`가 된 뒤 같은 dialog에서 TESTER1을 조회해도 이 값이 초기화되지 않아, DB의 TESTER1 공지가 `state=0`이어도 `_noticeClosed=true`로 숨겨졌다.
4. 조회 사용자가 바뀌면 `_noticeConfirmed`를 초기화해 새 사용자의 공지를 다시 표시하도록 수정했다. 정규화한 ID가 다른 경우만 초기화하는 `didNoticeUserChange` 계약 테스트를 추가했다. 버전은 PATCH **1.3.117 -> 1.3.118**로 갱신했다.
5. `flutter test test/startup_dialog_test.dart test/notice_menu_dao_test.dart`: **26건 통과**. 관련 파일 focused analyze **No issues found**, `git diff --check` 통과.
6. Windows v1.3.118 디버그 빌드/실행 및 hot reload 성공, runtime error 없음. 종료 시 DB disconnect와 `Application finished`를 확인했다.
7. 커밋 대상은 `lib/features/login/presentation/startup_dialog.dart`, `test/startup_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`다. 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 제외한다.
8. 기능 커밋 완료: `d9b01a6` (`사용자 전환 시 업데이트 공지 재표시`).

## 로그인·종료 성능 개선
1. ID 3575 로그인, 로그아웃, 프로그램 종료 속도를 다시 측정하고 공통 병목을 수정했다.
2. 기능 커밋 `d64f1e6`, 기록 커밋 `dc23403`. v1.3.117 실측에서 로그인 버튼 약 121ms, 홈 `renderReady` 약 3.27초, 명시적 로그아웃 약 887ms, 로그아웃 후 종료 약 9ms였다.

## 가로 스크롤 진단
1. 품목값 `365 -> 360` Enter 편집 후 가로 스크롤이 사라지는 문제를 재현하고 수정한다.
2. 제출된 v1.3.106 로그에는 편집 완료와 ItemManage 재빌드만 있고 열 너비/overflow/State 수명 로그는 없다. 기존 수정 `6bccfd5`(v1.3.100)는 v1.3.106과 현재 코드에 포함돼 있다.
3. 실제 ItemManage 14개 동적 열에서 Enter 편집 전후 `RawScrollbar.thumbVisibility`를 검증하는 [test/item_manage_horizontal_scroll_test.dart](test/item_manage_horizontal_scroll_test.dart)를 추가했고 현재 코드에서는 편집/스크롤 유지가 재현되지 않았다.
4. [third_party/fortune_sheet/lib/src/fortune_table.dart](third_party/fortune_sheet/lib/src/fortune_table.dart)의 실제 content/viewport/offset/maxExtent를 컨트롤러에 노출하고 [lib/features/item/presentation/item_manage.dart](lib/features/item/presentation/item_manage.dart)에 `operation=horizontalScroll event=changed` 진단 로그를 추가했다. 앱 버전은 **1.3.115 -> 1.3.116**, 로그 버전은 `item-manager-debug-v22`로 갱신했다.
5. 회귀/기존 테스트 **75건 통과**: `flutter test test/item_manage_horizontal_scroll_test.dart test/fortune_table_test.dart`. 변경 Dart 파일 focused analyze도 **No issues found**.
6. Windows v1.3.116 디버그 빌드/실행 완료. 로그에서 `DebugLogger version: 1.3.116`을 확인했고 hot reload 성공, runtime error 없음. 앱 실행은 정리했다.
7. 이번 단계는 기존 코드에서 현상이 재현되지 않아 동작 추측 수정 없이 재현 테스트와 원인 판별 로그를 추가한 상태다. 사용자 재테스트 로그에서 `item-manager-debug-v22 operation=horizontalScroll`의 편집 전후 지표를 비교한다.
8. 최종 diagnostics 및 `git diff --check` 통과. 기능 커밋 대상은 `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/features/item/presentation/item_manage.dart`, `lib/features/item/item_manager_debug_log.dart`, `test/item_manage_horizontal_scroll_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 제외한다.
9. 기능 커밋 완료: `b16ca38` (`품목 편집 가로 스크롤 진단 보강`). 사용자 재현 시 편집 직전/직후 `state`, `revision`, `columns`, `overflow`, `contentWidth`, `viewportWidth`, `offset`, `maxExtent`를 비교해 원인을 확정한다.

## BMP 미리보기 오동작 검증
- 제출 `logo.bmp` 헤더 확인: 120x93, 1-bit, compression 0, 정상 BMP. SHA256 `DD34E4EF943CE59F4907CB472D61443AC1F358A71FF7D2513496F74E7B2FAB65`.
- 회귀 테스트 추가: 고정 탐색 폴더 밖에서 선택한 1-bit BMP도 선택 바이트 캐시를 통해 PNG data URI로 변환한다.
- focused 테스트 완료: `item_image_preview_test.dart`와 `item_order_dialog_test.dart` 합계 **9건 통과**.
- focused analyzer 완료: 수정 Dart 파일 3개 **No issues found**. 포맷 후 테스트 9건 재통과.
- Windows 디버그 앱 v1.3.115 빌드/실행 및 hot reload 완료: 로그 버전 확인, `Reloaded 0 libraries in 206ms`, runtime 예외 없이 정상 종료.
- 사용자 재테스트 로그 판별점: `operation=itemImage event=selected` 뒤 `itemBmpPreview resolved source=selected`가 기록되어야 한다. 실패 시 `readFailed` 또는 `itemBmpPreview missing`으로 원인을 구분한다.
- 최종 diagnostics와 `git diff --check` 통과. formatter 변경은 ItemManage 19줄로 제한됐다.
- 기능 커밋 완료: `f5ea0bb` (`선택한 BMP 이미지 미리보기 즉시 반영`). 관련 5개 파일만 포함했으며 범위 밖 [lib/core/app.dart](lib/core/app.dart)는 제외했다.

## 품목 순서 저장 오동작 검증
- focused 테스트 완료: `flutter test test/home_page_manager_session_test.dart test/item_order_dialog_test.dart test/item_manager_save_dao_test.dart` 결과 **6건 통과**.
- analyzer 완료: `flutter analyze lib/home_page_manager.dart test/home_page_manager_session_test.dart test/item_order_dialog_test.dart test/item_manager_save_dao_test.dart` 결과 **No issues found**.
- Windows 디버그 앱 v1.3.114 실행 및 hot reload 완료: `Reloaded 0 libraries in 687ms`, runtime 예외 없이 정상 로그아웃/DB 연결 종료 후 앱을 닫았다.
- 사용자 재테스트 로그 판별점: `operation=itemOrder event=finished mounted=true busy=false` 뒤 `_buildTabs`와 `_ItemManageState.build`가 이어져야 한다.

## 현재 실행 및 작업 트리
- 마지막 검증 앱은 **v1.3.114 일반 모드**. 초기 품목 세션 `renderReady/completed`, hot reload, 정상 로그아웃과 DB 연결 종료까지 확인했다. 실사용 순서 저장은 DB 변경을 피하기 위해 실행하지 않았다.
- 제출 로그 [.tmp/1.3.106 2차 log/품목순서변경후 무한로딩.log](.tmp/1.3.106%202차%20log/품목순서변경후%20무한로딩.log)는 v1.3.106이며 DB 저장과 `reload completed`까지 정상이다. 마지막 탭 생성 시 `busy=true`였고 이후 ItemManage 재빌드 없이 표시가 고착됐다.
- 범위 밖 기존 변경: [lib/core/app.dart](lib/core/app.dart), [pubspec.lock](pubspec.lock). 원복하거나 함께 stage/commit하지 않는다. 오동작과 관련되면 먼저 diff를 읽고 사용자 변경을 보존하면서 조사한다.
- 이번 수정 버전은 PATCH **1.3.113 -> 1.3.114**. native 인쇄 코드는 변경하지 않아 native 인쇄 마크는1.3.107이다.
- 기능 커밋 완료: `c9a9637` (`품목 순서 저장 후 처리 중 상태 해제`). [lib/home_page_manager.dart](lib/home_page_manager.dart), [pubspec.yaml](pubspec.yaml), [SESSION_HANDOFF.md](SESSION_HANDOFF.md)만 포함했다.

## 앱 오동작 시작점
- 사용자가 지정한 로그/화면을 최우선으로 한다. 현재 증상이 아직 없으므로 과거 문제를 새 오동작이라고 가정하지 않는다.
- 가장 최근 생산 수정은 `02864cf`의 RTF 글자 크기 단위 변환이다. [lib/features/label_sheet/application/label_sheet_rtf_import.dart](lib/features/label_sheet/application/label_sheet_rtf_import.dart)의 셀/raw/인라인/native HTML 크기에96/72 변환을 적용했다. 새 RTF 가져오기에는 일반 글자도 포함된다. 기존 저장 시트나 출력 엔진 자체를 일괄 확대하지는 않는다.
- 새 RTF 로딩/품목 미리보기에서 크기·줄바꿈·잘림 문제가 재현되면 위 경로와 [lib/home_page_manager.dart](lib/home_page_manager.dart)의 호출부터 확인한다. 그 외 증상이면 해당 기능의 제어 지점에서 시작한다. 단위 수정과 실물 역상 문제의 인과관계는 아직 미확정이다.
- 이전 `503fa16`은 품목 단일 셀 미리보기만 native RTF 변환 대신 Dart parser를 사용해 UI 스레드 멈춤을 피한 수정이다. 일반 라벨의 native 가져오기는 유지했다. 이 차이를 모르고 미리보기에 동기 native 호출을 다시 연결하지 않는다.
- 인쇄가 필요 없는 재현에는 인쇄 버튼/자동 출력/데이터 재저장을 실행하지 않는다. 앱 실행 자체에는 기존 시작/로그인 DB 처리 등이 있을 수 있으며, 이를 'DB 접근 없음'으로 표현하지 않는다.

## 최근 완료 및 남은 확인
- **RTF 단위 수정 `02864cf` / 기록 `f1a1763`**: 새5/6/8pt 가져오기에서 Windows14/17/23dot 보존, 코덱 저장/재로드 보존, 기존 시트8pixel 일반/역상17dot 유지. 가져오기 관련203건/인쇄27건 통과(일부 중복), 관련3개 파일 analyze 및 Debug `/WX` 빌드/hot reload 통과. 실물 개선은 미검증.
- **레거시 글리프 비교 `eb2a01f`**: 동일 twip의 RTF/평문 재구성 글리프는 차이0. 크기 단위 차이를 무출력 native probe로 재현, CTest2/2 통과. 현재 실패17dot의 원본이8pt라는 증거는 아니다.
- 사용자 확인 대기: 품목 순서 변경 후 로딩은 이번 v1.3.114로 재테스트한다. 품목값 편집 후 가로 스크롤(`6bccfd5`)과 BMP 미리보기(`logo.bmp` 실파일)는 새 증상과 관련될 때만 확인한다.
- 완료된 공지/로그인/품목 편집 등의 상세 작업 로그는 Git 이력으로 넘긴다. 계정 전환/방향키는 `503fa16`, 편집 가능 기본값은 `9e1db2a`, 로그인/종료 속도는 `13396fa`를 기준으로 조회할 수 있다.

## 역상 복귀 시 요약
- **실물 품질 미해결**. 같은 환경의 레거시 정상 사진이 있으므로 USBPcap 설치 요청은 철회했다. 사용자 추가 설치나 같은 코드의 반복 출력을 요구하지 않는다.
- 마지막 실패 사진은 `.tmp/IMG_20260909_0003.png`(앱1.3.108/native1.3.107). 실제 앱1.3.109의 PRN에서는 두 역상 흰 손실0. 원본 생성의 적절성/USB 데이터 동일성/종이 품질을 모두 입증한 것은 아니다.
- 다음 판별은 실패 라벨의 실제 저장 형식과 원래 글자 크기다. 대상은 마지막 재현 기준 brand1526/labelSize8114/item722292. `RICH_FORM_SHEET` 및 `RICH_ELEMENT_SHEET` 우선 조회라 최종 alias만으로 원본 RTF 출처를 알 수 없다.
- 원본 RTF와 저장 시트를 읽기 전용으로 비교하기 전에는 기존 시트를4/3 확대하거나 RTF에서 강제 재생성/재저장하지 않는다. 사용자 편집 손실 가능성이 있다.
- 일반 출력/표선은 v1.3.58 기준, native 인쇄 경로는1.3.107 유지. 실패 실험·증거·파일 모드 한계는 재개 문서에 모아 둔다.
- 9월11일 자료 점검: 정상/실패 사진과 레거시 소스는 존재한다. 과거23:10/23:21 앱 로그, 실제 앱 PRN/PNG와 대응 inverse/after-native TXT, RTF analyze/build 로그, probe build 캐시는 현재 없다. 이전 검증 결과는 커밋/문서 기록으로만 보존하며 재검증 완료라고 표현하지 않는다. 앱 오동작은 남아 있는 최신 로그와 새 재현부터 조사할 수 있다.

## 검증 명령
오동작의 관련 테스트만 먼저 실행한다. 아래는 RTF 수정에 직접 관련된 재검증 명령이며 문서 정리에서는 실행하지 않았다.

```powershell
C:/Flutter/bin/flutter.bat test test/godex_inverse_reference_test.dart test/label_sheet_toolbar_test.dart
C:/Flutter/bin/flutter.bat test test/label_sheet_print_job_test.dart test/label_print_dispatcher_test.dart
C:/Flutter/bin/flutter.bat analyze lib/features/label_sheet/application/label_sheet_rtf_import.dart test/godex_inverse_reference_test.dart test/label_sheet_toolbar_test.dart
```

- 일반 앱 실행 시 `LABEL_MANAGER_DEBUG_PRINT_FILE`이 설정되지 않았는지 확인한다. Debug 파일 모드는 성공해도 `ok=false`를 반환해 인쇄 이력/자동증가를 막는 진단 기능이다. 앱 오동작 실패와 혼동하지 않는다.
- Dart 수정 뒤 DTD를 새로 발견/연결해 hot reload 또는 restart한다. native 변경은 재빌드/재실행해야 한다. Windows 배포/설치파일/원격 push/DB migration/프린터 설정 변경은 명시 요청 없이 하지 않는다.
- `.tmp` 자료와 캐시는 가능한 재개 증거로 보존하고 stage/외부 전송하지 않는다. 없는 자료는 없다고 기록하고 과거 결과를 새로 검증했다고 말하지 않는다.

## 이번 정리 진행
- 문서 편집 완료: 앱 오동작 우선, 종료된 실행 상태, 기존 dirty2개, RTF 수정의 적용 범위와 역상 복귀 지점으로 핸드오프를 재구성했다. 역상 재개 문서는 핵심 증거/실패 이력/명령 중심으로 축약했다.
- 검증 완료: `git diff --check`, 두 문서의 상대 링크 존재 확인, 문서/pubspec diagnostics 통과. 핵심 증거의 존재/누락을 위에 반영했다. 문서2개와 pubspec만 stage/commit한다. 앱 실행/테스트/빌드/실물 인쇄는 하지 않았으며 로컬 자료 삭제도 하지 않았다.
- 정리 커밋 완료: `abac7ab` (`앱 오동작 우선 세션 전환과 역상 재개 문서 정리`). 관련3개 파일만 포함했다. 후속 해시 기록은 같은 요청의 문서 기록으로 버전을 다시 올리지 않는다. 다음 세션은 앱 오동작의 구체 증상 확인부터 시작한다.