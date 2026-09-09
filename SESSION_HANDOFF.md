# 현재 작업 상태

## 환경 확인 완료 / 설치 동의 대기: USB 전송 관측
- 사용자 요청: 역상 보완 계속. 실제 앱 파일 캡처의 픽셀 보존은 이미 검증되어 같은 렌더링/실물 검사를 반복하지 않았다.
- 읽기 전용 확인 완료: G500은 USB001에 정상 연결되어 있다. 큐는 RAW/winprint, `KeepPrintedJobs=False`, 현재 작업 없음. 완료된 IMG0003 작업의 전송 바이트는 확보되지 않았다.
- USBPcap 드라이버 조회 결과 없음. `USBPcapCMD`/`tshark`/`dumpcap`은 PATH에 없고 USBPcap/Wireshark 표준 설치 위치에도 실행파일 없음. 기존 환경만으로 USB 캡처를 시작할 수 없다는 가설이 이 검사에서 확인됐다.
- 블로커: USBPcap 설치는 시스템 캡처 드라이버 추가이며 관리자 권한과 재부팅이 필요할 수 있다. 자동 설치/권한 상승/프린터 설정 변경/물리 인쇄는 하지 않았다. 설치 및 캡처 진행에 사용자 동의가 필요하다.
- 다음 절차: 사용자 설치 후 G500이 연결된 hub와 해당 장치만 선택, 짧은 캡처 동안 사용자 수동 인쇄 1회, 성공한 bulk OUT 데이터의 중복/순서를 검사하여 PRN과 명령 및 두 역상 픽셀을 비교한다. 캡처 준비 전 재출력을 요청하지 않는다. 다른 USB 장치 트래픽 수집과 자료 외부 전송은 하지 않는다.
- 한계: USBPcap은 호스트 USB 요청 관측이지 장치 내부 처리나 물리 버스의 하드웨어 분석이 아니다. 바이트 동일성이 확인돼도 열/하드웨어 결함으로 즉시 단정하지 않는다.
- 편집 완료: 이 문서와 `doc/godex_inverse_resume.md`에 관측 환경/다음 절차 기록, `pubspec.yaml`은 문서 변경 규칙에 따른 PATCH **1.3.109 -> 1.3.110**. 앱/렌더링 코드와 native 마크1.3.107은 변경하지 않았다. 앱 빌드/재실행 없음, 기존 파일 전용 앱의 현재 실행 여부는 이번에 확인하지 않았다.
- 검증 완료: 읽기 전용 도구/연결/큐 확인 및 `git diff --check` 통과. 실행 코드 변경이 없어 앱 테스트/빌드/hot reload는 수행하지 않았다. 관련 문서2개와 pubspec만 커밋하고 사용자 `lib/core/app.dart` 및 `.tmp` 자료는 제외한다.

## 진단 구현/검증 완료, 품질 미해결: IMG0003 페이지 재생
- `.tmp/IMG_20260909_0003.png`에서 역상 획 소실 지속. 최신 `app_2026-09-09_23-10-24.log`는 앱1.3.108/인쇄1.3.107, 두 역상·도형951개·흰2806·후속 손실0으로 이전 경로와 같다. 생산 변경 없는 진단 버전 재출력이다.
- 가설: 부분 재현에서 빠진 후속 검정 문자/워터마크를 포함할 때 드라이버 Q 데이터가 달라지는지 검사. 실제 작업의 참조 검정 EMF와 마지막 역상 원본을 사용하며 실제 USB 스풀 캡처라고 부르지 않는다.
- 편집 완료: `driver_file_probe.h`에 두 clip 처리와 `RenderDriverPageTail`(저장 native EMF+기존 v1.3.107 워터마크 동일 GDI 조건), `main.cpp`에 `--driver-file-page <last-inverse-prefix> <after-native-prefix> <new.prn>` 추가. 출력은 명시한 로컬 파일만 사용한다.
- 미검증. 다음 검증: probe `/WX` build 후 `.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe --driver-file-page .tmp/log/godex_inverse/v1.3.107_18248_10663312_2 .tmp/log/godex_inverse/v1.3.107_18248_10663640_1_after_native .tmp/log/godex_inverse/v108_driver_page.prn` 실행 및 두 clip의 Q 픽셀 비교.
- probe build/페이지 파일 생성 성공: 두 clip·흰2806·검정19424. Q 헤더 `Q10,11,76,472`는 워터마크 포함 시 8행 정렬로 페이지 높이480을 3행 초과하여 기존 해석기가 거부했다.
- 편집 완료: `inspect_inverse_driver_file.ps1`은 최대7픽셀 정렬 범위의 백색 패딩만 허용하고 페이지 밖 검정 픽셀은 오류 처리한다. `test_inverse_driver_file.ps1`에 빈 패딩 허용/검정 overflow 거부 2건 추가. 다음 검증은 해석기7건 후 같은 페이지 PRN의 두 clip 비교.
- 검증 완료: 해석기7건 통과. 페이지 PRN의 두 역상 모두 흰 손실0/증가0/픽셀 차이0(흰1298/1508). 범위 밖 1824픽셀은 모두 백색 패딩. 복원 PNG에서 일반 문자/표선/워터마크와 두 역상 확인.
- 테스트 추가: `VerifyDriverPageTail`에 EMF 표식9픽셀 재생/하단 워터마크 실제 출력/다른 영역 보존/DC 상태 복원 검사. 페이지 모드는 워터마크가 일치하는 v1.3.107 진단만 허용. 다음 검증은 `/WX` probe build/CTest.
- 첫 회귀 검사 실패: 테스트만 EMF 프레임 환산 대신 620x480 직접 지정해 표식9 중3픽셀만 예상 좌표에 남았다. 이미 알려진 EMF 프레임 차이를 테스트에서 재도입한 오류이며, 실제 파일 probe의 프레임 환산은 유지되고 있었다. `SetDriverPageTextFrame`을 테스트/파일 probe가 공유하도록 수정했다. 다음 검증은 동일 build/CTest 재실행.
- 현재 판단: 일반 검정 문자와 워터마크를 포함한 참조 페이지 재생에서도 손실이 없어 추가 보정 근거 없음. 실제 앱 DrawText 호출 대신 참조 EMF를 재생하므로 실제 USB 전송과 동일하다고 단정하지 않는다. 실제 앱 인쇄 호출을 파일로 전송하는 검사가 다음 필요 단계다.
- 최종 native 검증: 프레임 환산 수정 후 동일 `/WX` probe build/CTest1/1 통과. 해석기 회귀7건 통과. 생산/Dart 변경은 없으므로 앱 빌드/실행/hot reload/실물 인쇄는 하지 않는다.
- 편집 완료: README/역상 재개 문서에 페이지 재생, Q 백색 패딩, 실제 앱 호출과 남는 차이, 같은 실물 재출력 불필요를 기록했다. 버전은 진단 변경으로 PATCH **1.3.108 -> 1.3.109**, native 인쇄 마크1.3.107 유지.
- 임시 파일/캐시는 `.tmp` 로컬 보존, stage 제외. 다음 확인은 `git diff --check`/변경 diagnostics 및 관련 파일만 stage/commit. 기존 사용자 변경 `lib/core/app.dart` 제외.
- 추가 구현 진행: 참조 재생 한계를 다음 세션으로만 넘기지 않도록 실제 `PrintBitmap`의 Debug 전용 파일 대상 지원을 추가했다. `debug_print_file_target.h`는 `LABEL_MANAGER_DEBUG_PRINT_FILE`의 새 절대 로컬 PRN 경로만 허용, release에서는 무시한다. 잘못된 경로/다른 backend는 실제 출력 없이 실패한다.
- 편집 완료: `PrintBitmap`은 파일 모드에서 동일 장치/합성/DrawText/워터마크 코드를 그대로 쓰고 `DOCINFO.lpszOutput`만 파일로 바꾼다. 파일 성공도 `ok=false`와 `debugFileCaptured=true`로 반환해 Dart의 인쇄 성공/이력/자동증가 경로로 넘어가지 않는다. 환경변수 미설정 시 기존 출력 유지. 이 모드는 품질 보정이 아닌 실제 호출 캡처다.
- 테스트 추가: 경로 미설정/정상 새 경로/상대 경로/UNC/부모 없음/확장자 오류/기존 파일 거부 검사. 다음 검증은 probe `/WX` build/CTest 후 Windows Debug `/WX` build 및 실패 결과의 저장 차단 계약 확인.
- 검증 완료: 경로 검사 포함 probe `/WX` build/CTest1/1 및 실제 Windows Debug `/WX` build 성공. 기존 앱 프로세스 없음 확인.
- 테스트 추가: `test/windows_bitmap_printer_test.dart`의 파일 캡처 ok=false 예외/일반 성공 유지, `test/label_print_persistence_test.dart`의 빈 접수 데이터 DB 트랜잭션0 계약. 다음 검증: `flutter test test/windows_bitmap_printer_test.dart test/label_print_persistence_test.dart`.
- 검증 완료: 위 Dart 테스트8건 통과. 다음 실행은 `LABEL_MANAGER_DEBUG_PRINT_FILE=<repo>/.tmp/log/godex_inverse/actual_app_v109.prn`을 해당 Flutter run 프로세스에만 지정하고 `C:/Flutter/bin/flutter.bat run -d windows --debug --no-pub`. 환경변수 미설정 앱에는 영향 없다. 실제 앱 캡처는 아직 미검증이다.
- 실행 완료: `.tmp/log/app_2026-09-09_23-21-37.log`에서 앱v1.3.109 확인, 파일 전용 run 터미널 `3f5a1c99-3bc0-4e7f-a6fe-5d943ee214dd`. DTD 연결/hot reload 성공, runtime 오류 없음. 사용자에게 이 실행본에서 같은 라벨의 인쇄 버튼을 눌러 파일만 생성하도록 요청했다. 실제 앱 PRN 생성/픽셀 판별은 아직 미검증.
- 최종 검증: Dart8건 및 관련2개 파일 analyze 통과, native/probe `/WX` build와 CTest1/1 통과, PowerShell7건 통과, 변경 diagnostics 없음. 일반 인쇄 품질은 미해결. Debug 파일 전용 모드 추가까지 포함해 버전은1.3.109 한 번만 증가.
- 문서 갱신: 실제 앱 파일 전용 실행법/의도된 실패 메시지/DB 저장 차단/환경변수 없이 재실행하면 일반 인쇄 복귀를 README와 재개 문서에 기록했다. 관련 인쇄 채널/헤더/테스트/도구/문서/pubspec만 commit하고 사용자 `lib/core/app.dart` 및 `.tmp`는 제외한다.
- 실제 앱 캡처 검증 완료: 사용자가 파일 전용 앱에서 23:23:51 인쇄 요청. `.tmp/log/godex_inverse/actual_app_v109.prn` 35933바이트 생성, 로그 `debugFileCaptured=true physicalPrintSubmitted=false`, 후속 인쇄 DB 트랜잭션 없음. 접수 성공으로 처리하지 않는 동작을 실제 확인했다.
- 실제 앱 픽셀 결과: 같은 실행 `v1.3.107_13308_11451875_1`/`v1.3.107_13308_11451906_2` 대비 두 역상 모두 흰 손실0/증가0/차이0(1298/1508). 참조 페이지와 복원 이미지 차이는 역상 밖 (537,58) 한 픽셀뿐이다. 실제 PRN SHA256 `C0D38BD589BE26465B8F955F9D3EAC261B1E20A4190BCBA9E9B347F1D6AE50B5`.
- 남은 제한: 실제 앱의 파일 대상 호출에서도 획 보존을 확인했지만, IMG0003을 만든 USB 작업 바이트는 확보하지 못했다. 다음 판별은 파일 대상과 USB 실제 전송의 동일성이다. 열/드라이버 결함 확정이나 소프트웨어 개선 불가 판단은 하지 않는다. 일반 품질 보정은 근거가 없어 추가하지 않았다.
- 현재 실행본은 파일 전용이다. 동일 PRN이 이미 있어 다음 인쇄 요청은 덮어쓰기 없이 거부된다. 일반 인쇄 복귀는 앱 종료 후 환경변수 없이 재실행. 이 상태를 사용자에게 안내했다.
- 기능 커밋 완료: `a4ffd5e` (`역상 실제 앱 파일 캡처와 페이지 전송 검증 추가`). 관련12개 파일만 포함했으며 사용자 `lib/core/app.dart` 변경과 `.tmp` 자료는 제외했다. 해시 기록 후속 문서 커밋에서는 버전 재증가 없음.

## 진단 보완 완료, 품질 미해결: 드라이버 파일 판별
- `.tmp/IMG_20260909_0002.png`에서도 흰 획 소실 지속. `app_2026-09-09_20-31-25.log`는 v1.3.107 도형951개/흰2806/검정19424, 후속 손실0, 출력 수락 및 이력 저장 성공. 기존 도형 전송 변경은 실물 문제를 해결하지 못했으며 새 해결책으로 반복하지 않는다.
- 확대 원본 `.tmp/log/godex_inverse/v107_inverse_zoom.png`에서는 가로 획 보존. 다음 가설은 최종 드라이버 데이터에서의 변화이며 열 문제로 확정하지 않는다.
- 편집 완료: `tools/inverse_rich_edit_probe/driver_file_probe.h`에 `CaptureInverseDriverFile` 추가, `main.cpp`에 `--driver-file` 명시 모드, CMake에 winspool 연결. 출력 경로를 `DOCINFO.lpszOutput`의 절대 `.prn` 파일로 지정하고 일반 USB 출력 fallback은 없다. 프린터 설정 저장/실물 인쇄는 하지 않는다. 생산 출력 변경은 아직 없음.
- 미검증. 다음 검증: `cmake --build .tmp/inverse_probe_build --config Debug` 및 기존 CTest 후 `inverse_rich_edit_probe.exe --driver-file <v107-prefix> <new-local.prn>`로 단일 역상 재생의 드라이버 파일을 검사한다. 일반 native text/워터마크 없는 부분 재현이므로 실제 작업 스풀과 구분한다.
- 검증: `/WX` probe build/CTest1/1 통과. 두 번째 역상 원본의 `--driver-file`이 성공했고 로컬 `v107_driver_geometry.prn` 34861바이트 생성. `Q10,11,75,464` 바이너리 형식 확인.
- 편집 완료: `tools/inspect_inverse_driver_file.ps1`은 EZPL Q의 길이 기반 바이너리 해석과 clip 픽셀 비교를 수행한다. 미검증, 다음 실행: `./tools/inspect_inverse_driver_file.ps1 -Path .tmp/log/godex_inverse/v107_driver_geometry.prn -SourcePrefix .tmp/log/godex_inverse/v1.3.107_18476_1323281_2`.
- 판별 완료: 첫/둘째 역상 PRN의 clip 픽셀 차이0, 흰 손실0, 흰1298/1508 보존. 단일 역상 재현에서 드라이버 Q 변환 손실 가설은 지지되지 않는다. 실제 전체 작업 및 실물 차이는 남는다.
- 편집 완료: 레거시 `PrintManager.cpp`의 dmFields 교체/DocumentProperties 재정규화 생략 차이를 검사할 `--driver-file-legacy-devmode` 추가. 생산 설정은 변경하지 않는다. 다음 검증은 probe build 후 같은 두 번째 역상 입력을 legacy 모드로 새 `.prn`에 생성하고 기존 파일과 해시/픽셀 비교한다.
- 판별 완료: legacy/current PRN의 SHA256이 `00A3FE63D640B70C01DF5905717D5B4FE727C389A7A86E837FBC42CA4A5AF64B`로 동일. DEVMODE 차이도 이번 재현의 원인으로 지지되지 않는다. 사용자 확인: 스캐너 흑백 이미지이며 종이에서도 흰 획 소실 동일. 스캔만의 문제로 판단하지 않는다.
- 테스트 추가: `tools/test_inverse_driver_file.ps1`에 합성 Q 자료의 무손실/흰 손실/흰 증가/잘린 payload/바이너리 CR·LF 계약 5건. `driver_file_probe.h`는 실패 시 AbortDoc 정리 및 독립 include 보완. 다음 검증: `./tools/test_inverse_driver_file.ps1 -OutputDirectory .tmp/inverse_driver_parser_test`, probe build/CTest.
- 현재 제한: 이 파일 전용 재현은 실제 인쇄 전체 스풀 캡처가 아니다. 생산 코드 추가 보정은 근거가 없어 수행하지 않았다. 실제 전체 전송 데이터와 장치 결과의 차이는 미확정이며 열/드라이버 결함 확정 또는 소프트웨어 개선 불가 결론 금지.
- 검증 완료: Q 해석기 회귀 5건 통과. 버전은 진단 도구/테스트 추가에 따른 PATCH **1.3.107 -> 1.3.108**. 새 앱 빌드/실행/실물 인쇄 없음. 마지막 EXE/native 마크는 v1.3.107이며 22:33 정상 종료됐다.
- 편집 완료: 재개 문서 및 probe README에 실패 실물, 드라이버 픽셀 보존, legacy DEVMODE 동일, 파일 전용 StartDoc의 범위/한계를 기록했다. 다음 최종 검증: probe `/WX` build/CTest, `git diff --check`, 변경 diagnostics.
- 최종 검증 완료: probe `/WX` build/CTest1/1, Q 해석기5건, 변경 diagnostics/diff 검사 통과. 생산/Dart 코드 변경이 없어 앱 빌드·Dart 테스트·hot reload는 수행하지 않았다.
- 블로커: `Get-PrintJob -PrinterName 'Godex G500'` 결과 큐가 비어 완료된 실제 전체 작업을 큐에서 대조할 수 없다. 새 실제 전송 캡처 또는 전체 작업의 동등한 파일 재현이 필요하며 지금의 부분 재현만으로 원인/해결 판정하지 않는다.
- 임시 자료: PRN/복원 PNG/합성 테스트 출력/기존 사진·로그·probe 캐시는 `.tmp` 로컬 보존, stage 제외. 프린터 설정/DB/실물 인쇄/배포/원격 push 변경 없음.
- stage/commit 대상: `tools/inverse_rich_edit_probe/{driver_file_probe.h,main.cpp,CMakeLists.txt,README.md}`, `tools/inspect_inverse_driver_file.ps1`, `tools/test_inverse_driver_file.ps1`, `doc/godex_inverse_resume.md`, `pubspec.yaml`, 이 문서. 기존 `lib/core/app.dart` 사용자 변경 제외.
- 기능 커밋: `ba52808` (`G500 역상 드라이버 파일 진단과 픽셀 비교 추가`). 해시 기록 후속 커밋에서 버전 재증가 없음. 품질 해결 커밋이 아니라 진단 보완 커밋이다.

## 이전 구현: G500 역상 도형 전송 (실물 실패 확인)
- 사용자 사진 `.tmp/IMG_20260909_0001.png`에서 두 역상 띠의 흰 획 소실 지속. 앱 v1.3.106 / 인쇄 마크 v1.3.97이며 최신 `app_2026-09-09_20-19-37.log`의 실제 검정 33건/fitted12와 참조 33건/fitted12가 일치한다. `_after_native.txt`의 두 `whitePixelsLost`는 모두 0이다. 참조 BMP에는 획이 남아 있어 후속 검정 덮임을 재현하지 못했다.
- 국소 가설: 역상 raster 전송과 검정 도형의 드라이버 처리 차이. 역상 1bpp 글리프/좌표/크기는 유지하고 해당 clip의 검정 픽셀만 GDI region으로 전달한다. 폰트/threshold/농도 변경이나 전체 페이지 전송 변경은 하지 않는다. 드라이버/열 문제가 확정됐다는 뜻은 아니다.
- 수정 예정: `windows/runner/inverse_text_geometry.h`, `tools/inverse_rich_edit_probe/main.cpp`에 픽셀 동등성 무출력 검사 추가 후 `windows/runner/label_bitmap_print_channel.cpp`의 역상 전송에 연결한다. 일반 글자/표선 및 사용자 변경 `lib/core/app.dart` 보존.
- 편집 완료: `inverse_text_geometry.h`의 `PrepareInverseTextGeometry`는 역상 clip의 이진 픽셀을 검정 run으로 분리하며 바깥 RGB와 alpha를 보존한다. `RenderInverseTextGeometry`는 하나의 GDI region으로 검정 픽셀만 출력한다.
- 테스트 추가/검증 완료: `tools/inverse_rich_edit_probe/main.cpp`에 도형 재생 픽셀 동등성/좌표 이동/중복 clip 검사를 추가했다. `/WX` probe 빌드, CTest1/1 통과. 실제 역상 2개 EMF 재생에서 픽셀 차이0, 흰 픽셀1298/1508 보존, 좌표 이동 검사 통과. StartDoc 없이 수행했다.
- 편집 완료: `label_bitmap_print_channel.cpp`의 `PrintBitmap`에 역상 영역을 비운 raster 전송 후 검정 region 출력 연결. 기존 합성 원본은 진단용으로 유지하고 일반 글자/표선 전송은 유지한다. 새 인쇄 마크 v1.3.107.
- 검증 완료: 실제 앱 연결 후 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. 실물 인쇄는 실행하지 않았다.
- 편집 완료: probe에 전송 raster clip 비움/외부 RGB 및 alpha 보존 검사를 추가하고 실제와 같은 `StretchDIBits` 후 region 재생으로 검사 강화. native 진단 prefix/마크를 v1.3.107로 통일했다.
- 버전: 역상 전송의 국소 버그 보완으로 `pubspec.yaml` PATCH **1.3.106 -> 1.3.107**. 강화 검사와 실제 두 EMF replay도 픽셀 차이0으로 통과했고 최종 v1.3.107 `/WX` Windows Debug 빌드 성공. 변경 파일 diagnostics 없음.
- 편집 완료: `doc/godex_inverse_resume.md`의 최신 증거/전송 경로/다음 판별 갱신. `tools/inverse_rich_edit_probe/README.md`에 도형 검사 및 진단 BMP의 의미를 기록했다.
- 실행 검증 완료: `C:/Flutter/bin/flutter.bat run -d windows --debug --no-pub`로 native 재빌드/실행. `.tmp/log/app_2026-09-09_20-31-25.log`에서 v1.3.107 확인, PID18476 응답 정상, DTD 연결/hot reload 성공, runtime 오류 없음. 실물 인쇄/프린터 설정 변경은 하지 않았으며 품질 개선은 사용자 출력 확인 전까지 미검증이다.
- 임시 자료: 원본 사진/로그/EMF/BMP와 로컬 PNG·replay BMP·probe 캐시 보존, stage 제외. 배포 빌드/DB migration/원격 push 없음.
- stage/commit 대상: `windows/runner/inverse_text_geometry.h`, `windows/runner/label_bitmap_print_channel.cpp`, `tools/inverse_rich_edit_probe/main.cpp`, `tools/inverse_rich_edit_probe/README.md`, `doc/godex_inverse_resume.md`, `pubspec.yaml`, 이 문서. 기존 사용자 변경 `lib/core/app.dart` 제외. `git diff --check` 통과, 커밋 직전 cached diff/stat을 확인한다.
- 기능 커밋 완료: `1c013ce` (`G500 역상 픽셀을 검정 도형으로 전송하도록 보완`). 관련 7개 파일만 포함했다. 이 해시 기록 후속 문서 커밋에서는 버전을 다시 증가시키지 않는다.

## 새 세션 우선순위 (2026-09-09)
1. **완료: 김영모 계정 접속 멈춤 및 품목관리 좌우 방향키 수정.** 지정 v1.3.58 로그에서 `75806065` 전환 후 브랜드·라벨크기·품목 세션은 `renderReady`와 `completed`까지 끝났고 마지막 로그가 품목 미리보기의 native RTF 변환 시작에서 멈췄다. 품목 단일 셀 미리보기만 Dart RTF 파서를 사용해 Windows UI 스레드의 동기 native 변환 정지를 피하고, 하단 가로 이동 버튼에 포커스가 있으면 좌우 방향키가 동일 스크롤 callback을 실행하도록 구현했다. 관련 전체 테스트 273건과 analyzer/diff 검증을 통과했다.
2. **완료: 품목관리 추가 열의 `클라이언트 편집 불가` 기본값 수정.** 기존 품목에 `BM_RICH_COL_CONTENT` 레코드가 없는 추가 열은 저장 draft에서 편집 가능을 기본값으로 사용하지만 화면의 `_dynamicCellEditable`만 false를 사용해 자동 잠금됐다. 미설정 기본값을 true로 통일하고 명시적 false는 유지하도록 수정했다.
2. **완료: 업데이트 메시지 대상 사용자 검색 기능.** 우측 대상 목록에 거래처·지점 필터와 계정 ID 다음 검색을 추가했다. 검색 결과는 강조되며 화면 밖 사용자도 목록 중앙으로 자동 스크롤한다. 필터를 변경해도 기존 체크 선택은 유지된다.
3. **완료: 관리자가 선택한 사용자의 업데이트 메시지 미표시 수정.** v1.3.58 설정 로그에서 `TESTER1` 대상 UPDATE와 커밋은 성공했지만 영향 행 수가 확인되지 않았고, 로그인 화면에는 공지 영역만 열린 채 본문이 비었다. 레거시는 로그인 시 없는 `BM_UPDATE_NOTICE` 사용자 행을 생성하지만 Flutter에는 이 보장이 없었다. 선택 사용자 저장을 정규화 ID UPDATE 후 영향 행이 없으면 사용자 소속 협력업체와 함께 INSERT하도록 수정했다.
3. **완료: 로그인 공지의 `다음 업데이트까지 이 창 보지 않음` 복원 수정.** v1.3.58 재현 로그와 레거시를 대조한 결과 Flutter는 공지 조회 전 빈 내용 hash로 로컬 suppression을 판정하고 DB `UN_STATE`를 버려 재실행 시 공지가 다시 표시됐다. 로그인 조회 결과에 `Notice.state`를 전달하고 확인 시 기존 `NoticeDAO.updateUserState`로 상태를 저장하도록 수정했다.
4. **완료: 로그인·로그아웃·프로그램 종료 체감 속도 개선.** 로그인/초기 브랜드 로딩을 `SnackBar.onVisible`까지 미루지 않고 즉시 시작하도록 변경하고 Windows 종료의 고정 120ms 대기를 제거했다. v1.3.101 실행 로그에서 인증 종료→초기 로딩 시작은 약 681ms에서 376ms, 종료 승인→후속 닫기는 약 122ms에서 1ms로 감소했다.
5. **구현·focused 검증 완료: 품목값 편집 후 가로 스크롤 소실 수정.** 품목관리에서 revision 재계산 시 기존 자동 너비를 보존하여 편집 확정 후 overflow와 가로 스크롤이 사라지지 않게 했다. 최신 v1.3.100 실행본에서 사용자 재현 확인이 필요하다.
6. 품목관리 BMP 미리보기 수정은 구현·자동 검증 완료 상태다. 최신 v1.3.99 실행본에서 실제 `logo.bmp` 확인이 필요하다.
7. 품목 순서 변경 후 무한 로딩은 현재 코드에서 수정 및 focused 검증 완료 상태다. 역상은 IMG0003 실물 실패/v1.3.109 실제 앱 파일 캡처 픽셀 보존까지 확인했으며 [doc/godex_inverse_resume.md](doc/godex_inverse_resume.md)를 기준으로 파일 대상과 USB 실제 전송 차이를 판별한다.

## 보존할 상태
- 마지막 인쇄 구현: **v1.3.107 역상 검정 GDI region 전송**. 이전 v1.3.97/d0ade63 진단은 후속 검정 덮임0/0으로 분석 완료했으며 실물 획 소실 해결 버전이 아니다.
- 마지막 분석 실물: [.tmp/IMG_20260909_0003.png](.tmp/IMG_20260909_0003.png), 앱1.3.108/인쇄1.3.107에서 흰 획 소실 지속. 실제 앱 v1.3.109 파일 대상 캡처에서도 두 역상 흰 손실0이며 그 결과로 실물 정상/열 문제 확정 판정 금지.
- 미확정: 파일 대상으로 생성된 실제 앱 PRN과 USB 실제 전송의 차이. 품질 보정 없이 동일 코드 실물 재출력을 반복 요구하지 않는다.
- 마지막 실행: Debug EXE v1.3.109/PID13308, 파일 전용 모드. [.tmp/log/app_2026-09-09_23-21-37.log](.tmp/log/app_2026-09-09_23-21-37.log)에서 캡처 완료 확인. 현재 실행 여부는 새 세션에서 확인한다. 일반 인쇄로 돌아가려면 환경변수 없이 재실행해야 한다.
- 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 보존한다. 앱 오동작과 관련되면 현재 diff를 읽고 함께 작업하되 임의 원복/전체 stage 금지.
- 일반 글자/표선은 v1.3.58 기준 유지. 실물 획 소실을 열 번짐/드라이버 문제로 확정하거나 소프트웨어 개선 불가로 결론내리지 않는다.
- 사진/로그/EMF/BMP/probe 캐시는 `.tmp`에 로컬 보존, stage/외부 전송 제외. DB migration/프린터 설정/배포/원격 push 변경 금지.

## 이번 핸드오프 정리
- 계정 전환 멈춤 원인/수정: [.tmp/test_log/사용자관리 - 김영모 계정 접속시 프로그램 멈춤현상.log](.tmp/test_log/사용자관리%20-%20김영모%20계정%20접속시%20프로그램%20멈춤현상.log)의 마지막 미완료 작업은 `labelSheetDraftFromRichEditRtfAsync` native 변환이다. [lib/features/label_sheet/application/label_sheet_rtf_import.dart](lib/features/label_sheet/application/label_sheet_rtf_import.dart)에 native 우선 여부를 추가하고 [lib/home_page_manager.dart](lib/home_page_manager.dart)의 품목 단일 셀 미리보기만 기존 Dart parser를 선택했다. 일반 라벨 RTF 가져오기의 native 정밀 변환은 유지한다.
- 품목 좌우 방향키 구현: [lib/features/item/presentation/item_manage.dart](lib/features/item/presentation/item_manage.dart)의 하단 좌우 버튼이 footer 전용 포커스를 획득하고, 해당 포커스에서 왼쪽/오른쪽 방향키가 버튼과 동일한 `FortuneTableScrollController` callback을 실행한다. 테이블 셀 편집·셀 이동 포커스에서는 가로채지 않는다.
- 테스트 추가/검증: [test/label_sheet_toolbar_test.dart](test/label_sheet_toolbar_test.dart)는 품목 RTF 변환이 native 채널을 호출하지 않음을 검증하고, [test/fortune_table_test.dart](test/fortune_table_test.dart)는 버튼 클릭 후 좌우 방향키 스크롤을 검증한다. `flutter test test/label_sheet_toolbar_test.dart test/fortune_table_test.dart` 273건 통과, 관련 파일 `flutter analyze` 이슈 없음, `git diff --check` 통과.
- 실행 검증 제한: VS Code DTD에 실행 중인 Flutter 앱이 없어 hot restart, 실제 `75806065` 계정 전환 및 품목관리 키 입력 확인은 수행하지 못했다.
- 버전: 계정 전환 멈춤 및 품목관리 방향키 수정으로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.105 -> 1.3.106**.
- 기능 커밋: `503fa164dc285153d9e66215b0a44e0454ebfcf2` (`계정 전환 멈춤 및 품목 방향키 수정`). 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 제외했다.
- 품목 추가 열 편집 기본값 구현: [lib/features/item/presentation/item_manage.dart](lib/features/item/presentation/item_manage.dart)의 `_dynamicCellEditable`은 기존 품목의 열 콘텐츠 레코드가 없으면 편집 가능을 기본값으로 사용한다. DB에 저장된 명시적 `editable=false`와 현재 draft 설정은 계속 우선한다. DB migration이나 저장 포맷 변경은 없다.
- 품목 추가 열 편집 테스트: [test/fortune_table_test.dart](test/fortune_table_test.dart)에 기존 품목·빈 `scopedColumnContents`에서 추가 열 편집 가능 및 잠금 툴팁 미표시 계약을 추가했다. 신규 테스트 1건과 기존 명시 잠금·해제 테스트 2건 통과.
- 최종 검증: `flutter test test/fortune_table_test.dart` 74건 통과. `flutter analyze lib/features/item/presentation/item_manage.dart test/fortune_table_test.dart` 이슈 없음. `git diff --check` 통과.
- 실행 검증 제한: VS Code DTD에 실행 중인 Flutter 앱이 없어 hot restart와 실제 아이티에스엔지/6*9 데이터 화면 확인은 수행하지 못했다.
- 버전: 품목 추가 열 편집 기본값 버그 수정으로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.104 -> 1.3.105**.
- 기능 커밋: `9e1db2ada78d59fced240fe1a5b04c0519304ae2` (`품목 추가 열 편집 기본값 수정`).
- 대상 사용자 검색 구현: [lib/features/update_notice/domain/notice.dart](lib/features/update_notice/domain/notice.dart)의 `NoticeTargetUser`에 거래처·지점 ID/이름을 추가하고 로컬 필터 및 대소문자 무시 계정 ID 순환 검색 함수를 제공한다.
- 대상 사용자 조회 구현: [lib/features/update_notice/data/notice_dao.dart](lib/features/update_notice/data/notice_dao.dart)의 기존 협력업체 단위 단일 쿼리가 거래처·지점 정보를 함께 반환하고 거래처명, 지점명, 계정 ID 순으로 정렬한다. 추가 조회나 DB migration은 없다.
- 대상 사용자 UI 구현: [lib/features/update_notice/presentation/update_notice_dialog.dart](lib/features/update_notice/presentation/update_notice_dialog.dart)의 우측 패널에 거래처·지점 필터, 계정 ID 검색, 선택 인원 표시를 추가했다. Enter 또는 검색 버튼은 현재 필터 결과에서 다음 일치 사용자를 강조하고 고정 행 높이 기반으로 중앙 자동 스크롤하며 저장 단축키와 충돌하지 않는다. 필터 밖 사용자 선택도 유지되어 함께 저장된다.
- 대상 사용자 검색 테스트: [test/notice_menu_dao_test.dart](test/notice_menu_dao_test.dart)에 모델/SQL 필드, 거래처·지점 필터, trim·대소문자 무시 검색, 필터 밖 선택 유지·저장, 화면 밖 결과 자동 스크롤 계약을 추가했다. 공지 메뉴 테스트 15건 통과.
- 최종 검증: `flutter test test/notice_menu_dao_test.dart test/startup_login_service_test.dart test/startup_dialog_test.dart` 28건 통과. 대상 Dart 파일 `flutter analyze` 이슈 없음. `git diff --check` 통과.
- 실행 검증 제한: VS Code DTD에 실행 중인 Flutter 앱이 없어 hot restart, 실제 화면 크기 및 실제 DB 목록 확인은 수행하지 못했다.
- 버전: 업데이트 메시지 대상 사용자 검색 기능 추가로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.103 -> 1.3.104**.
- 기능 커밋: `eab0f0536ed5597cec89702ac601ad1ba77ec4a9` (`업데이트 메시지 대상 사용자 검색 추가`).
- 선택 사용자 공지 저장 구현: [lib/features/update_notice/data/notice_dao.dart](lib/features/update_notice/data/notice_dao.dart)의 `updateSelectedUserSql`은 조회와 동일한 trim/문자열 변환으로 대상 ID를 갱신하고, `@@ROWCOUNT=0`이면 `BM_USER`, `BM_MARKET`, `BM_CUSTOMER`에서 소속 협력업체를 조회해 `BM_UPDATE_NOTICE` 행을 생성한다. DB migration이나 테이블 변경은 없다.
- 선택 사용자 공지 테스트: [test/notice_menu_dao_test.dart](test/notice_menu_dao_test.dart)에 기존 행 갱신뿐 아니라 미존재 선택 사용자 행 INSERT와 앱 버전 저장 계약을 추가했다. `flutter test test/notice_menu_dao_test.dart` 11건 통과.
- 최종 검증: `flutter test test/notice_menu_dao_test.dart test/startup_login_service_test.dart test/startup_dialog_test.dart` 24건 통과. 관련 6개 Dart 파일 `flutter analyze` 이슈 없음. `git diff --check` 통과.
- 실행 검증 제한: VS Code DTD에 실행 중인 Flutter 앱이 없어 hot restart와 실제 DB 대상 재현은 수행하지 못했다.
- 버전: 선택 사용자 공지 미표시 버그 수정으로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.102 -> 1.3.103**.
- 기능 커밋: `9b064c39100a566355a0729e3d62809aa453f8a4` (`선택 사용자 업데이트 메시지 저장 수정`).
- 공지 suppression 구현: [lib/features/login/application/startup_login_service.dart](lib/features/login/application/startup_login_service.dart)는 공지 문자열 대신 `Notice(message, state)` 전체를 반환하고 기존 `NoticeDAO.updateUserState` writer를 제공한다. [lib/features/login/presentation/startup_dialog.dart](lib/features/login/presentation/startup_dialog.dart)는 DB `UN_STATE=1`을 재실행 시 닫힘으로 복원하며, 체크 후 확인에서 저장 성공 후에만 닫고 늦은 조회 callback이 다시 열지 못하게 한다.
- 공지 suppression 테스트: [test/startup_login_service_test.dart](test/startup_login_service_test.dart)에 공지 상태 전달 계약을, [test/startup_dialog_test.dart](test/startup_dialog_test.dart)에 DB 상태 1 복원, 상태 0 새 공지 재표시, 확인 시 사용자별 suppression 저장, 저장 실패 시 공지 유지와 즉시 오류 표시 계약을 추가했다.
- 최종 검증: `flutter test test/startup_login_service_test.dart test/startup_dialog_test.dart` 13건 통과. `flutter analyze lib/features/login/application/startup_login_service.dart lib/features/login/presentation/startup_dialog.dart test/startup_login_service_test.dart test/startup_dialog_test.dart` 이슈 없음. `git diff --check` 통과.
- 실행 검증 제한: VS Code DTD에는 연결했지만 실행 중인 Flutter 앱이 없어 hot restart와 runtime 오류 확인은 수행하지 못했다.
- 버전: 공지 상태 유지 버그 수정으로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.101 -> 1.3.102**.
- 기능 커밋: `3e40eb1d22ce7ed1d428f7329213aab9e1425bdb` (`로그인 공지 숨김 상태 유지 수정`).
- 로그인·종료 속도 구현: [lib/features/login/presentation/startup_dialog.dart](lib/features/login/presentation/startup_dialog.dart)는 진행 스낵바 표시 직후 인증을 시작하고 실제 인증 종료 시 스낵바를 닫는다. [lib/home_page_manager.dart](lib/home_page_manager.dart)는 초기 브랜드/품목 로딩을 스낵바 `onVisible` 콜백까지 미루지 않는다. [lib/main.dart](lib/main.dart)는 lifecycle 정리가 끝난 뒤 추가하던 Windows 고정 120ms 대기를 제거했다.
- 로그아웃 판단: 최신 실행에서 메뉴 클릭부터 `_doLogout` 완료까지 약 101ms, 실제 `_doLogout`은 약 1ms였다. 일반 계정의 로그아웃 이력 저장 순서를 바꾸면 레거시 및 이력 완료 계약이 달라지므로 추가 변경하지 않았다.
- 테스트 추가/최종 검증: [test/startup_dialog_test.dart](test/startup_dialog_test.dart)에 progress snackbar 프레임 전 로그인 DAO 시작 계약, [test/home_page_manager_session_test.dart](test/home_page_manager_session_test.dart)에 progress 표시와 초기 로딩 즉시 시작 순서 계약을 추가했다. 관련 focused 테스트 20건 통과, analyzer 이슈 없음, diagnostics 없음, `git diff --check` 통과.
- 실행 검증: v1.3.101 Windows Debug 앱 실행 및 hot restart 성공, runtime 오류 없음. 인증 자체는 83ms, 품목 세션 로드는 2.91초로 DB/렌더 비용은 유지됐지만 불필요한 표시 대기 약 305ms가 제거됐다. 종료는 `Window close start`부터 후속 닫기까지 13ms, 승인 후 후속 닫기까지 1ms였다.
- 버전: 기존 기능과 저장 형식을 유지하는 속도 버그 수정이므로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.100 -> 1.3.101**.
- 기능 커밋: `13396fa5020077b8f21b8810608e3279fee14b64` (`로그인 및 프로그램 종료 속도 개선`).
- 가로 스크롤 원인 확인: 품목 셀 편집 확정 시 `ItemManagerDraftController.contentRevision`이 증가하고 FortuneTable의 `_syncAutoWidthsIfNeeded`가 모든 자동 열 너비를 새 값 기준으로 축소한다. 총 너비가 viewport 이하가 되면 `RawScrollbar.thumbVisibility`가 false로 바뀐다.
- 레거시 재확인: [.tmp/LabelManager/LabelManager/LabelEditDlg.cpp](.tmp/LabelManager/LabelManager/LabelEditDlg.cpp)는 초기 전체 열 자동 맞춤 후 편집한 해당 열만 다시 계산한다. 현재 구현은 revision마다 모든 열을 축소하던 차이가 있었다. 공용 FortuneTable 기본값은 유지하고 품목관리에서만 revision 이후 기존 자동 너비 보존 옵션을 사용한다.
- 편집 완료: [third_party/fortune_sheet/lib/src/fortune_table.dart](third_party/fortune_sheet/lib/src/fortune_table.dart)에 `preserveAutoFitWidthsOnRevision` 옵션을 추가했다. 최초 자동 맞춤과 다른 화면의 기본 동작은 유지하며, 옵션 사용 시 같은 테이블 세션의 revision 갱신은 열을 축소하지 않고 필요한 확장만 허용한다.
- 편집 완료: [lib/features/item/presentation/item_manage.dart](lib/features/item/presentation/item_manage.dart)가 품목 테이블에서 자동 너비 보존 옵션을 활성화한다.
- 테스트 추가/검증: [test/fortune_table_test.dart](test/fortune_table_test.dart)에 revision 후 열 너비와 실제 가로 scrollbar thumb 유지, ItemManage 옵션 전달 계약을 추가했다. `flutter test test/fortune_table_test.dart` 73건 통과. 관련 3개 Dart 파일 analyzer 이슈 없음. `git diff --check` 통과.
- 실행 확인: DTD에 연결된 Flutter 앱이 없어 hot restart는 수행하지 못했다.
- 버전: 국소 UI 동작 수정이므로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.99 -> 1.3.100**.
- 기능 커밋: `6bccfd54ca54f244687340f9c64db4955def4c78` (`품목 편집 후 가로 스크롤 유지`).
- BMP 미리보기 원인: [.tmp/test_log/이미지를 불러오지 못하는 현상.log](.tmp/test_log/이미지를%20불러오지%20못하는%20현상.log) v1.3.58에서 선택한 `logo` 파일명은 저장됐지만, 미리보기는 LabelManager 고정 폴더만 조회해 BCSManager의 파일을 찾지 못했다.
- 레거시 재확인: [.tmp/LabelManager/LabelManager/LabelEditDlg.cpp](.tmp/LabelManager/LabelManager/LabelEditDlg.cpp)는 파일 선택 시작 위치를 `C:\ITS\LabelManager\bmp files`로 지정하고 확장자 없는 파일명만 저장한다. [.tmp/LabelManager/LabelManagerLib/RichEditImageMaker.cpp](.tmp/LabelManager/LabelManagerLib/RichEditImageMaker.cpp)는 실행 파일 옆 `bmp files`에서만 다시 읽으며 외부 선택 파일을 복사하지 않는다. 현재 수정은 이 저장 계약과 기존 경로 우선순위를 유지하고 BCSManager 공유 폴더만 호환 경로로 추가한다.
- 편집 완료: [lib/features/item/application/item_image_preview.dart](lib/features/item/application/item_image_preview.dart)에 `itemBmpPreviewDataUriForFileName`과 두 기본 탐색 폴더를 추가했다. 기존 LabelManager 폴더 우선순위를 유지하고 BCSManager `bmpfiles`를 fallback으로 사용한다.
- 편집 완료: [lib/home_page_manager.dart](lib/home_page_manager.dart)의 `_itemImageDataUri`가 공용 BMP 파일명 로더를 사용한다. DB에는 기존처럼 확장자를 제외한 파일명만 저장한다.
- 테스트 추가: [test/item_image_preview_test.dart](test/item_image_preview_test.dart)에 실제 경로 상수, BCSManager fallback, 동일 파일명일 때 LabelManager 우선 계약을 추가했다.
- 검증 완료: `flutter test test/item_image_preview_test.dart test/home_page_manager_session_test.dart test/item_order_dialog_test.dart` 13건 통과. `flutter analyze lib/features/item/application/item_image_preview.dart lib/home_page_manager.dart test/item_image_preview_test.dart` 이슈 없음. `git diff --check` 통과.
- 실행 검증 제한: DTD 연결은 성공했지만 실행 중인 Flutter 앱이 없어 hot restart는 수행하지 못했다. 개발 PC에도 두 기본 폴더의 `logo.bmp`가 없어 실파일 미리보기는 최신 v1.3.99 실행본에서 사용자 확인이 필요하다.
- 버전: 호환 저장 포맷을 유지하는 국소 미리보기 버그 수정이므로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.98 -> 1.3.99**.
- stage/commit 대상: [lib/features/item/application/item_image_preview.dart](lib/features/item/application/item_image_preview.dart), [lib/home_page_manager.dart](lib/home_page_manager.dart), [test/item_image_preview_test.dart](test/item_image_preview_test.dart), [pubspec.yaml](pubspec.yaml), 이 문서. 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 제외한다.
- 기능 커밋: `7c0908b` (품목 BMP 미리보기 경로 호환 수정). 이 해시 기록 후속 문서 커밋에서는 버전을 추가 증가하지 않는다.
- 품목 순서 변경 무한 로딩 분석: [.tmp/test_log/품목순서변경 후 무한로딩.log](.tmp/test_log/품목순서변경%20후%20무한로딩.log)는 v1.3.58 재현이며 DB 순서 갱신과 목록 강제 재조회까지 성공했다. 현재 코드는 강제 재조회에서 품목 위젯 렌더 완료를 기다리지 않아 순환 대기를 차단한다.
- 현재 수정 확인: `3bac0a32`에서 `itemManagerSessionLoadWaitsForRenderReady(isReload: true) == false` 계약과 회귀 테스트가 추가됐다. 새 production 코드 변경은 하지 않았다.
- 검증 완료: `flutter test test/home_page_manager_session_test.dart test/item_order_dialog_test.dart` 8건 통과. 최신 v1.3.98 실제 실행 재현은 사용자 확인 대기다.
- 분석·검증 기록 커밋: `e9d5587` (품목 순서 무한 로딩 수정 상태 확인). 이 해시 기록 후속 커밋에서는 버전을 추가 증가하지 않는다.
- 목적: 새 세션의 앱 오동작 우선 처리와 역상 문제 재개를 분리한다. 앱/인쇄 동작 코드는 변경하지 않았다.
- 편집 완료: 재개 문서 작성, 메인 핸드오프를 현재 상태로 축약. 오래된 상세 완료 기록은 `a0f3a1e` 이전 Git 이력에서 조회한다. 과거 '실물 검증 대기/예정'은 현재 할 일로 취급하지 않는다.
- 저장소 문서 변경 버전 규칙에 따라 [pubspec.yaml](pubspec.yaml) PATCH **1.3.97 -> 1.3.98**. 새 앱 빌드/실행 없음. **마지막 확인한 EXE와 native 인쇄 마크는 v1.3.97**이며 1.3.98은 인쇄 수정 버전이 아니다.
- 검증 완료: 문서 로컬 링크/필수 자료 존재, pubspec1.3.98 확인, `git diff --check` 통과. 메인 핸드오프 축약 후 링크와 diff 검사도 재통과. 문서/버전만 변경하므로 앱 테스트·빌드·실물 출력은 실행하지 않았다.
- stage/commit 대상: 이 문서, [doc/godex_inverse_resume.md](doc/godex_inverse_resume.md), [pubspec.yaml](pubspec.yaml) 세 파일. 기존 사용자 변경 제외. 임시 자료 삭제 없음.
- 이전 구현 검증: native CTest1/1, Dart31건, `/WX` Debug 빌드 통과. 이 결과는 이전 구현 기준이며 실물 획 소실 해결을 의미하지 않는다.
- 정리 커밋: `45c1088` (앱 오동작 우선 처리와 역상 출력 재개 핸드오프 정리). 문서/버전 편집기 오류 없음. 이 해시 기록 후속 커밋에서는 버전을 추가 증가하지 않는다.

## 상시 규칙
- 작업 규칙은 [SESSION_RULES.md](SESSION_RULES.md)를 따른다.
- 다음 세션에서도 의미 있는 수정/검증/블로커/커밋 단계마다 이 문서를 갱신한다. 분석·질문 답변만 한 경우에는 갱신하지 않는다.