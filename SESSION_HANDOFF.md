# SESSION HANDOFF

## 현재 작업: 최초 바코드 삽입 시 세로 10mm/20mm 표시 동일
- **구현·검증·커밋 완료: `bce0749` (1.8.4). push하지 않음.**
- 제출 `공용라벨_바코드삽입_세로길이오류.log`는1.6.0. 연결 안함/1234/가로20/비율해제에서 세로10과20의 막대 높이가 같은 현상. 세로 입력은 전달되지만 별도 `바코드 높이` 기본10이 그대로여서 renderer가 나머지를 빈 공간으로 남긴 것이 원인.
- 사용자 `sync-height` 선택: 세로를 바꾸면 바코드 높이도 같은 값으로 변경하고, 이후 바코드 높이를 직접 입력하면 그 값을 사용한다. 비율유지 가로→세로 변경도 같은 helper로 동기화. 비율해제 시에는 가로를 유지한다. 빈값/0 입력은 바코드 높이를 덮어쓰지 않는다.
- 변경 production 파일은 `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 한 곳. 2D 모듈 설정, 기존 저장 데이터 로드, renderer, 저장 포맷/DB/인쇄 경로는 변경하지 않았다. 문자 표시 시 전체 높이 안에 문자 영역을 확보하는 기존 동작도 유지.
- 레거시 `BarcodeImageKeywordModifyDlg.cpp`의 width/height 입력→InsertBarcode 저장 계약 확인. 메뉴얼v2에서 Flutter 삽입창의 별도 높이 설정에 대응하는 설명은 확인되지 않음.
- 수정 전 실제 UI 회귀3건에서 바코드 높이 기대20/실제10 실패 재현. 수정 후 새 회귀5건 portable 통과 및 실제 native encoder 모드 포함 관련37건 통과. 10mm=38px/20mm=76px의 실제 PNG 막대 높이, px 단위10/20, 저장·재읽기/undo·redo, 비율연동, 명시7mm 우선, 문자 표시/본문 비율 저장, QR 크기·모듈 유지 검증.
- 새 테스트 analyzer/IDE와 pubspec 진단 정상. canvas에는 알려진 기존 unused 경고10건만 존재(복사필드3/coord2/옛 편집메서드2/옛 layer mutation3). 오류/신규 진단 없음. 큰 vendor 파일 전체 format은 하지 않았다.
- DTD 발견·연결 확인 및 hot reload 시도했으나 실행 중 앱 없음. 운영 DB 변경·실제 인쇄·설치파일 생성 없음.
- 버전1.8.3→1.8.4 PATCH: 기존 삽입 높이 입력의 연동 누락 수정. README에 동작 및 portable/native 회귀 실행법 기록.
- 다음 사용자 확인:1.8.4 실행→test/testflutter→공용라벨에서 연결 안함/1234/비율해제/가로20/세로10과20 삽입→막대 높이가 다른지 확인. 별도 바코드 높이 직접 입력, 저장 후 재열기, 품목 미리보기도 확인.

## 회귀 실행
- 일반: `C:\Flutter\bin\flutter.bat test --no-pub test\label_sheet_barcode_height_test.dart`.
- 기본 테스트는 native encoder만 테스트 패턴으로 대체하고 production geometry/PNG 합성으로 실제 잉크 높이를 측정해 DLL 없는 환경도 지원한다.
- 실제 인코더: Windows 빌드의 `flutter_zxing.dll` 폴더를 해당 프로세스 PATH에 추가하고 `--dart-define=BARCODE_HEIGHT_NATIVE=true`로 같은 테스트 실행. 이번에는 기존 `build\windows\x64\runner\Debug` 사용. DLL/설정 파일은 복사·변경하지 않았다.
- 최종 관련37건: native 모드의 새 테스트 + `third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` + `test\label_sheet_toolbar_test.dart`, `--name 'barcode|bar height|QR '`. 기존 renderer의 별도 바코드 높이 계약과 품목 미리보기 오류/로딩 해제도 포함.

## 최근 완료
| 버전 | 변경 | 기능 커밋 |
|---|---|---|
| 1.8.3 | 이미지30→31 적용 후 항목편집32 저장51113: persistedWidth/Height 분리, pending 크기 포함, 성공한 제출 snapshot만 baseline 승격.108건 통과 | a427d7f |
| 1.8.2 | 연결 이미지 변경 시 공용 편집 화면도 현재 선택 품목의 draft/저장 이미지 표시. 표시용 source만 치환하고 canonical src/품목별 발행 분리 유지.82건 통과 | a7d9415 |
| 1.8.1 | 이미지 파일 교체에도 기본 picker fallback 적용.취소/오류/undo/속성 보존.57건 통과 | 0f2f7a1 |
| 1.8.0 | 기본 항목 사용자 정의 text 출력, 키워드 더블클릭/드래그 삽입, 보라색 참조 표시.품목 원본 유지·단일 치환.349건 통과 | 379b3b2 |
| 1.7.3 | 필수등록 로컬 토글을 DB original로 오인한51115 수정. persistedMissingKeywordCheck 분리.96건 통과 | 4e7b0c5 |
| 1.7.2 | 영양성분표 확대 시 입력 초기화 및 배율 Enter 오저장 수정.112건 통과 | 4041c11 |
| 1.7.1 | 영양성분표 Future 전환 중 이전 snapshot 사용 차단.30건 통과 | d457042 |
| 1.7.0 | 승인된 발행내역 인덱스 확인·자동 생성·대기 UI.약97,872ms→26ms | f0ecdc3 |
| 1.6.2 | 사용자 추가의 없는 ID 조회/예외 범위 수정.38건 통과 | 02d7000 |
| 1.6.1 | 연결 바코드 미리보기의 완료 null 결과를 무한 로딩으로 오인한 문제 수정.32건 통과 | 23473f2 |

## 보존할 상태 및 주의
- 상시 규칙은 [SESSION_RULES.md](SESSION_RULES.md). 작업 완료 시 관련 변경만 검증·버전 갱신·커밋, 기능 해시를 기록하는 후속 handoff 커밋은 버전 추가 증가 없음. push하지 않음.
- 사용자 기존 `lib/core/app.dart` 변경은 수정·원복·stage/commit하지 않는다. 이번 시작 시 다른 사용자 dirty 파일 없음.
- 승인 없는 운영 DB 변경/실제 인쇄 금지. SQL Server2017 및 실제 DB 호환성100 유지.
- 이전에 승인받아 생성한 `IX_BM_RICH_PRINT_LOG_CustomerDate`는 DB에 남아 있다. keys `(RICH_CUSTOMER_ID,RICH_DATE_YYYYMMDD)`, INCLUDE `RICH_DATETIME`.
- Flutter 테스트 프로세스를 동시에 실행하지 않는다(test_cache 충돌). spinner 뒤 모달은 bounded pump 사용. lazy 속성 패널은 해당 ListView를 명시적으로 스크롤한다.
- 기존 unrelated 실패: ANSI RTF 변환 딸기→딪기, LoginLogDAO의 IP truncate 계약. 이 요청에서는 수정하지 않았다.
- 수천 줄로 누적됐던 과거 완료/실험 상세는 이번에 정리했다. 필요한 이력은 이 파일의 `bb7fa6e` 및 이전 Git 버전/각 기능 커밋으로 추적한다.

## 남은 별도 이슈: GoDEX G500 역상 흰 획 소실
- **미해결**. 사용자 새 증상을 먼저 처리한다. 인쇄 원본은 라벨 시트이며 RTF 직접 출력/시트의 RTF 재변환으로 돌아가지 않는다.
- 1.3.129의 native 드라이버 PRN 생성→원본 바이트 RAW 제출은 배치 중복/분할 개선 근거일 뿐 역상 품질 해결 근거가 아니다. 이전 RAW 인쇄 승인은 해당1회에 한하며 추가 인쇄는 매번 승인을 받는다.
- 파일 재생에서 역상 흰 픽셀1,266/1,427, 손실0이었지만 실제 종이 결과와 동등함을 보장하지 않는다. 시트 요청/드라이버 PRN/RAW/실물을 구분해 판정한다.
- DisplayBand,120/121twip 반올림,회색조/팽창,공백 장평,농도·속도,DirectWrite/GGO/FreeType,whole-page EMF 등 이미 실패한 접근을 반복하지 않는다. 저장 시트 글자 강제 확대/재생성·저장도 하지 않는다.
- 세부 재개 지점은 [doc/godex_inverse_resume.md](doc/godex_inverse_resume.md) 및 Git 이력. 과거 기록상 증거는 `.tmp/IMG_20260912_0007.png`, `.tmp/IMG_v0.Legacy_print.png`, `.tmp/log/app_2026-09-12_20-56-09.log`이며 이번에는 존재/내용을 다시 검증하지 않았다.
- `IMG_20260912_0006.png`, `actual_request_v127_replay.prn`, `img0006_driver_v129.prn`, `v1.3.127_1789202935380639_0.bin`은 이전 정리 시 없었다. 오래된 파일/픽셀 기록을 현재 재검증 결과로 표현하지 않는다. `.tmp` 증거는 Git 포함/외부 전송 금지.
