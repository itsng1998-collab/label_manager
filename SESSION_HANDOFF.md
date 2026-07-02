# 세션 인수인계

마지막 업데이트: 2026-07-02

## 작업 규칙

- FortuneSheet 작업이 길어지거나 다음 세션으로 이어질 수 있으면 이 파일을 현재 구현/검증/남은 작업 기준으로 갱신한다.
- 분석이나 단순 질문 답변만 수행한 경우에는 `SESSION_HANDOFF.md`를 갱신하지 않는다. 인수인계 갱신은 코드/설정/문서 변경, 검증 실행, 블로커, 중단 복구에 필요한 진행 상태가 생긴 경우에만 수행한다.
- 완료 마지막에 한 번만 갱신하지 않는다. 작업 중 파일 삭제/복사/의존성 변경/주요 코드 변경/검증 시작·완료/블로커 발생 같은 의미 있는 단계가 끝날 때마다 `SESSION_HANDOFF.md`를 즉시 갱신한다.
- OOM/중단 복구를 위해 큰 작업은 파일 단위 또는 의사결정 단위로 쪼개서 기록한다. 최소 기준은 `수정 예정 파일/목적 기록` -> `파일 하나 편집 완료 후 실제 변경 요약 기록` -> `테스트/검증 파일 추가 후 기록` -> `검증 실행 직전 명령 기록` -> `검증 직후 결과 기록` -> `임시 산출물/캐시 정리 여부 기록` -> `stage/commit 직전 대상 파일 기록` -> `commit 직후 해시 기록` 순서다.
- 코드 변경이 2개 이상 파일에 걸치면 각 파일 편집이 끝날 때마다 어떤 symbol/API/동작을 바꿨는지 한 줄로 기록한다. 다음 세션이 `git diff` 전체를 해석하지 않아도 남은 작업을 판단할 수 있어야 한다.
- 검증 전 중단될 수 있으므로, 아직 검증하지 않은 변경은 `미검증`으로 명시하고 남은 검증 명령을 그대로 적는다.
- 진행 중 작업은 `진행 중` 상태로 바로 기록하고, 완료되면 같은 항목을 `완료`와 검증 결과로 갱신한다.
- 긴 명령이나 빌드/테스트를 실행하기 전에는 실행 예정 명령을 기록하고, 끝난 직후 성공/실패/주요 오류를 바로 반영한다.
- 완료 후에는 최종 구현/검증/커밋 정보를 정리하되, 이 최종 정리는 실시간 업데이트를 대체하지 않는다.
- 다음 세션에서 구체 인수인계가 더 필요 없는 완료 기능은 긴 구현 로그를 계속 누적하지 않고, 기능명/핵심 동작/검증 또는 커밋 기준만 요약해 `완료된 기능 요약` 리스트에 추가한다.
- 오래되어 현재 판단에 불필요한 누적 인수인계 사항은 자동으로 적정 시점에 정리한다. 정리 시 진행 중/미검증/블로커/다음 작업에 필요한 정보는 유지하고, 이미 커밋·검증이 끝난 세부 로그는 요약 또는 삭제한다.
- LabelSheet에서 원본 시트와 맞추는 작업은 wrapper 중복 구현보다 `fortune_sheet`의 공용 API, 설정 hook, helper, 또는 원본 동작 보정으로 해결하는 것을 우선한다.
- Git 관리는 2026-06-24 사용자 요청으로 로컬 관리 활성화됨. 작업 완료 시 관련 변경분을 검토하고 로컬 Git 커밋까지 진행한다.
- 2026-06-29 사용자 요청으로 작업 완료 시 자동 Git 처리는 로컬 커밋까지만 수행한다. 원격 push는 사용자가 명시적으로 요청한 경우에만 실행한다.
- Git 커밋 메시지와 원격 push 관련 설명/주석은 한글로 작성한다.
- 기존 unrelated dirty 파일은 staging/commit에서 제외한다.
- 배포파일 작성(`flutter build windows --release`, `inno_setup_installer.ps1`, installer EXE/ZIP 생성 등)은 사용자가 명시적으로 요청할 때만 실행한다. 일반 작업 완료 검증에서는 자동으로 배포 패키징까지 진행하지 않는다.
- 솔루션 루트 구조나 로컬 패키지 경로를 바꾸면 이 파일에 변경 경로와 검증 명령을 기록한다. Git 상태와 커밋 정보도 함께 갱신한다.
- 라벨 시트 저장 포맷을 수정할 때는 `lib/page_label_sheet/label_sheet_save_codec.dart`의 `_labelSheetSaveFeatureKeys`에 항목별 feature key를 추가/정렬해 `labelSheetSaveFormatVersion`과 `labelSheetSaveFeatureVersions`가 자동 산출되도록 유지한다. 새로 지원하는 workbook/sheet/config/cell/cellType/inlineRun JSON 필드는 같은 파일의 allow-list 및 `labelSheetSanitizeWorkbookSaveJson` 경로에 반드시 반영하고, 상위 버전 payload가 지원 필드만 best-effort 로드하고 unknown 필드는 재저장 시 버려지는 테스트를 갱신한다.
- Godex G500 같은 라벨 프린터에서 정밀한 인쇄가 핵심이면 일반 프린터 경로와 직접 출력 경로를 분리한다. 직접 출력은 처음부터 모든 스타일을 100% EZPL 명령만으로 처리하기보다 `정밀 좌표 엔진 + EZPL 명령 + 셀 bitmap fallback` 구조를 우선한다. 테두리/선/박스와 바코드는 가능한 한 EZPL 명령으로 출력하고, 화면 폰트와 프린터 폰트 차이로 1:1 보장이 어려운 복합 스타일 텍스트/이미지/배경/RTF 계열 셀은 셀 단위 bitmap fallback을 사용해 시각적 일치도를 확보한다.

## 현재 상태

### 최근 완료 (2026-07-01, 커밋: `647f081`)

- **브랜드 설정 다이얼로그 편집 취소 오동작 + textChanged 이중 발생 수정**
  - `lib/home_page_manager.dart` `_BrandSettingsDialogState.didUpdateWidget`: brands 변경 시 편집 인덱스가 새 목록 범위를 벗어난 경우에만 취소하도록 변경 (기존: 항상 취소)
  - `_toggleBrandNameEdit`: `.text = X` + `.selection = Y` 두 번 할당 → `.value = TextEditingValue(...)` 단일 할당 교체 (리스너 2회 → 1회)
  - 검증: `flutter analyze lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공

- **한글 IME 오동작 수정 (`third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`)**
  - `_trackImeResidualRestoreCandidate` / `_restoreImeResidualAfterCaret` / `_isHangulResidualExpansion`: 정상 글자(`차`)가 잔여형(`챀`)으로 바뀐 뒤 composing collapsed 시 이전 정상 글자로 복원
  - IME 조합 축소 직후 `imeDeletion` 보호 구간: 커서 오른쪽 잔여 suffix가 조합 시작 원문에 없던 경우에만 제거
  - composing 중 Enter → `keyEvent ignored composingEnter`로 EditableText/IME 위임, 셀 커밋 보류
  - Backspace/Delete → `keyEvent ignored editableTextDeletion`으로 EditableText 기본 처리 위임 (`imeDeletion` 1회 예외 유지)
  - IME composing 텍스트 축소 감지 후 200ms 내 첫 Backspace 1회 소비 (`keyEvent handled imeDeletion`)
  - 회귀 테스트: `fortune_debug_log_test.dart` 11개 통과

- **SwipeActionTable 브랜드 이름 더블클릭 개선 (`lib/widgets/swipe_action_table.dart`)**
  - `GestureDetector.onTapUp` 기반 더블클릭 판정 → `Listener.onPointerDown` 기반으로 변경 (gesture arena/drag recognizer 영향 제거)
  - 더블클릭 시 행 선택 `_selectedIndex` 먼저 `setState`, 컬럼 `onDoubleTap` 콜백은 post-frame 호출
  - 회귀 테스트: `swipe_action_table_test.dart` 4개, `common_label_manage_test.dart` 2개 통과

- **로그/성능 개선**
  - FortuneSheet debug 로그를 앱 로그 경로 `.tmp/log/app_*.log`로 통일 (`fortune_debug_log.dart` 파일 writer 제거)
  - `writeAsStringSync` sync flush 제거 → `File.openWrite` 기반 `IOSink.writeln`으로 변경
  - `cellEditorTrace#` 고빈도 로그: 앱 로그 파일 저장 유지, `OutputDebugString`/debugPrint 콘솔 출력 생략
  - 셀 편집 debug text 최대 300자 제한

- **브랜드 설정 인라인 편집 시 엔터 버튼·액션 레일 미표시 수정** (커밋: `5df0beb`)
  - 원인: `_buildDataRow`에서 `isRowContentInteractive=true`이면 `isOpen=false`로 강제하고 `postFrameCallback`으로 `_openActionIndex=null` 리셋 → action rail 숨김 + `rowWidths`에 inset 미적용 → 엔터 버튼도 inset 없이 full-width 셀에 렌더링됨
  - `lib/widgets/swipe_action_table.dart` `_buildDataRow`: postFrameCallback 강제 닫기 블록 제거, `isOpen` 조건에서 `&& !isRowContentInteractive` 제거 → 편집 중 스와이프 행도 `isOpen=true` 유지
  - `lib/home_page_manager.dart` `_buildBrandNameCell`: 로그에 `width=$width` 추가 (다음 디버깅용)
  - 결과: 스와이프 → 수정 버튼 진입 시 셀 폭이 `_withTrailingInset`으로 줄어 엔터 버튼 + 오른쪽 액션 레일 동시 표시
  - 검증: `flutter analyze --no-fatal-warnings --no-fatal-infos ...` 성공, `test/swipe_action_table_test.dart` 4개 통과

### 주의사항

- `lib/core/app.dart` dirty (`isAutoLogin`/`isDesktop`/`isShowLogo` 사용자 변경) → 계속 커밋 제외

### 대기/추후 작업

- **완료 (2026-07-02)**: 여러 번 브랜드 조회 후 `RTF를 변환 중입니다...` 스낵바가 남는 문제 수정.
  - 최신 로그 확인: `.tmp/log/app_2026-07-02_11-18-37.log`에서 RTF 변환 완료/미리보기 캡처 성공 후에도 스낵바 제어가 post-frame 예약에 의존하는 경로 확인.
  - `lib/page_label_sheet/label_sheet_workbench.dart` `_syncRtfSnackBar`: `_rtfSnackBarGeneration` 토큰 추가로 stale show/hide 예약 무효화.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart`, `lib/home_page_manager.dart` 기존 dirty 제외).
  - 구현 커밋: `8315e09` (`RTF 변환 스낵바 잔류 방지`).

- **완료 (2026-07-02)**: RTF 스낵바 잔류 재발 디버깅용 로그 추가.
  - `lib/page_label_sheet/label_sheet_workbench.dart` `_syncRtfSnackBar`: 상태 전환, post-frame stale skip, show/hide 실행, show skip, dispose hide 로그 추가.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart`, `lib/home_page_manager.dart` 기존 dirty 제외).
  - 구현 커밋: `65cafcc` (`RTF 스낵바 디버깅 로그 추가`).

- **완료 (2026-07-02)**: 브랜드 설정 다이얼로그 인라인 에디터 수정 시 `_updateBrandName`에 원본 `Brand` 객체와 수정 이름을 함께 전달하도록 변경.
  - `lib/home_page_manager.dart` `_submitBrandNameEdit`: 현재 편집 인덱스의 원본 `Brand`를 캡처해 `_updateBrandName(brand, newName)` 호출.
  - `lib/home_page_manager.dart` `_updateBrandName`: 시그니처를 `(Brand brand, String brandName)`으로 변경하고 전달받은 원본 객체 기준으로 확인/상태 갱신.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`의 해당 hunk만. 기존 dirty 파일(`lib/core/app.dart`, `lib/models/brand.dart`, `lib/models/label_size.dart`) 및 기존 `home_page_manager.dart` dirty hunk는 제외.
  - 구현 커밋: `b7d60fb` (`브랜드 이름 수정 원본 객체 전달`).

- **완료 (2026-07-02)**: `BrandDAO.updateByBrandId`를 DB UPDATE affected row 기준 성공/실패 반환으로 수정.
  - 확인 결과: ODBC 드라이버는 `Map`의 `affected`, FreeTDS 경로는 JSON 문자열의 `affected`를 반환.
  - `lib/models/brand.dart` `_affectedRows`: `Map`/JSON 문자열 결과에서 `affected`를 추출.
  - `BrandDAO.updateByBrandId`: `affected > 0`일 때만 `true`, 0건 업데이트 또는 예외는 `false` 반환.
  - 검증 완료: `flutter analyze lib/models/brand.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/models/brand.dart` (`lib/core/app.dart`, `lib/models/label_size.dart` 기존 dirty 제외).
  - 구현 커밋: `c3ca7f5` (`브랜드 수정 결과 행 수 판정`).

- **완료 (2026-07-02)**: `_affectedRows`를 `DAO` 공용 API로 이동해 write 결과 affected row 추출을 공유 가능하게 변경.
  - `lib/models/dao.dart` `DAO.affectedRows`: JSON 문자열/Map 결과에서 `affected`를 공용 추출.
  - `lib/models/brand.dart` `BrandDAO.updateByBrandId`: private `_affectedRows` 제거 후 `DAO.affectedRows(res)` 사용.
  - 검증 완료: `flutter analyze lib/models/dao.dart lib/models/brand.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/models/dao.dart`, `lib/models/brand.dart` (`lib/core/app.dart`, `lib/models/label_size.dart` 기존 dirty 제외).
  - 구현 커밋: `cf52883` (`DAO 영향 행 수 추출 공용화`).

- **완료 (2026-07-02)**: `LabelSizeDAO.updateByLabelSizeId`의 로그 INSERT와 본문 UPDATE를 단일 DB 트랜잭션으로 변경.
  - `lib/models/label_size.dart` `updateByLabelSizeId`: `BEGIN TRY/BEGIN TRANSACTION/COMMIT/ROLLBACK/THROW` SQL Server 배치 1회 호출로 로그 INSERT와 본문 UPDATE를 원자화.
  - 각 작업 직후 `@@ROWCOUNT <= 0`이면 `THROW`로 롤백되도록 처리하고, 정상/오류 경로 모두 `SET XACT_ABORT OFF`로 세션 옵션 복구.
  - 검증 완료: `flutter analyze lib/models/label_size.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/models/label_size.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `b3271dc` (`라벨 시트 저장 트랜잭션 적용`).

- **완료 (2026-07-02)**: 브랜드 설정 다이얼로그 `_updateBrandName`이 `BrandDAO.updateByBrandId`의 throw/rethrow 기반 성공/실패를 올바르게 반영하도록 수정.
  - `lib/home_page_manager.dart` `_updateBrandName`: `await BrandDAO.updateByBrandId(...)`로 DB 처리 완료를 기다리고, 예외 발생 시 오류 스낵바 표시 + 편집 유지 + 상태 갱신 중단.
  - 성공 시에만 편집 종료/캐시 갱신 수행. 편집 인덱스가 바뀐 경우 상태 갱신 skip.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `54a1445` (`브랜드 이름 수정 실패 처리 반영`).

- **완료 (2026-07-02)**: 브랜드 이름 변경 실패 표시를 스낵바에서 경고 다이얼로그로 변경.
  - `lib/home_page_manager.dart` `_updateBrandName`: `BrandDAO.updateByBrandId` 예외 발생 시 `AlertDialog`로 `브랜드 이름 변경 실패` 경고 표시 후 편집 포커스 복귀.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `5087a70` (`브랜드 이름 수정 실패 경고 다이얼로그 적용`).

- **완료 (2026-07-02)**: 브랜드 설정 다이얼로그 행 삽입 인라인 편집 구현.
  - `lib/home_page_manager.dart` `_BrandSettingsDialogState`: 삽입 버튼 클릭 시 현재 행 아래 빈 행 추가, 삽입 인라인에디터 표시, 빈 입력 Enter/아이콘 비활성, ESC/눌린 삽입 버튼 재클릭 시 삽입 취소 및 빈 행 제거.
  - 삽입 편집 중 시작 행의 삽입 버튼 pressed 유지, 수정/삭제 비활성. 삽입 성공 시 새 브랜드 행으로 테이블 목록 재구성 후 인라인에디터 종료.
  - `lib/models/brand.dart` `BrandDAO.insertByBrandName`: `RICH_BRAND_ORDER` 밀기 + INSERT + 새 identity 행 반환을 하나의 SQL Server 트랜잭션으로 처리.
  - `lib/database/windows_odbc/odbc_param_utils.dart`: SQL Server 시스템 변수 `@@ROWCOUNT`/`@@TRANCOUNT`를 named parameter로 오인하지 않도록 `@@` 보존.
  - 테스트 추가: `test/windows_odbc_param_utils_test.dart` double-at 시스템 변수 보존 케이스.
  - 검증 완료: `flutter analyze lib/models/brand.dart lib/home_page_manager.dart lib/database/windows_odbc/odbc_param_utils.dart test/windows_odbc_param_utils_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 검증 완료: `test/windows_odbc_param_utils_test.dart` 7개 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/models/brand.dart`, `lib/database/windows_odbc/odbc_param_utils.dart`, `test/windows_odbc_param_utils_test.dart` (`lib/core/app.dart`, `doc/BM_RICH_BRAND.sql` 제외).
  - 구현 커밋: `6c198a2` (`브랜드 행 삽입 인라인 편집 구현`).

- **완료 (2026-07-02)**: 브랜드 설정 다이얼로그 행 삭제 구현.
  - `lib/home_page_manager.dart` `_BrandSettingsDialogState`: 삭제 버튼 클릭 시 사용자 확인 다이얼로그 표시 후 `BrandDAO.deleteByBrandId` 호출, 성공 시 해당 브랜드를 목록에서 제거하고 `Brand.datas` 재구성.
  - `lib/models/brand.dart` `BrandDAO.deleteByBrandId`: `RICH_BRAND_ID` + `RICH_CUSTOMER_ID` 조건 삭제, 삭제된 `RICH_BRAND_ORDER` 이후 행 order -1 재정렬을 하나의 SQL Server 트랜잭션으로 처리.
  - 검증 완료: `flutter analyze lib/models/brand.dart lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/models/brand.dart` (`lib/core/app.dart`, `doc/BM_RICH_BRAND.sql` 제외).
  - 구현 커밋: `d4a5a89` (`브랜드 행 삭제 처리 구현`).

- **완료 (2026-07-02)**: 브랜드 설정 다이얼로그 내부 확인 다이얼로그가 보이지 않는 문제 수정.
  - 최신 로그 `.tmp/log/app_2026-07-02_16-53-07.log`: 삽입 Enter가 `_insertBrandName start`까지 도달했으나 확인/취소 결과 로그 없이 브랜드 설정 overlay만 계속 rebuild됨.
  - 원인: 브랜드 설정 다이얼로그가 모달리스 `OverlayEntry`라 `showDialog` route가 기존 overlay 뒤에 깔릴 수 있음.
  - `lib/home_page_manager.dart` `_BrandSettingsDialogState`: `_showBrandOverlayDialog` helper 추가. 삽입/수정/삭제 확인 및 실패 경고를 현재 overlay 위에 직접 삽입하도록 변경.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart` (`lib/core/app.dart`, `doc/BM_RICH_BRAND.sql` 제외).
  - 구현 커밋: `a29b7cd` (`브랜드 설정 확인 다이얼로그 표시 수정`).

- **완료 (2026-07-02)**: 브랜드 추가 DB 오류 수정.
  - 최신 로그 `.tmp/log/app_2026-07-02_16-59-47.log`: 확인 다이얼로그 결과 `true` 후 `BrandDAO.insertByBrandName`에서 `OdbcException(message: SQLExecute failed: 100)` 발생.
  - 원인: 마지막 행 아래 삽입 시 첫 DML인 order 밀기 `UPDATE`가 0건이라 ODBC가 `SQL_NO_DATA(100)`을 반환.
  - `lib/models/brand.dart` `insertByBrandName`: 트랜잭션에서 INSERT를 먼저 실행하고, 삽입된 행을 제외한 기존 행만 `RICH_BRAND_ORDER + 1` 처리하도록 순서 변경. `SET NOCOUNT ON` 및 `OUTPUT ... INTO #InsertedBrand (columns...)` 적용.
  - 검증 완료: `flutter analyze lib/models/brand.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/models/brand.dart` (`lib/core/app.dart`, `doc/BM_RICH_BRAND.sql` 제외).
  - 구현 커밋: `0a1330e` (`브랜드 추가 ODBC 실행 오류 수정`).

- **완료 (2026-07-02)**: 브랜드 설정 성공 변경을 헤더 브랜드 드롭다운에 반영.
  - `lib/home_page_manager.dart`: `_BrandSettingsDialog`에 `onBrandsChanged` 콜백 추가. 수정/삽입/삭제 성공 시 부모 `HomePageManager`를 rebuild해 헤더 브랜드 드롭다운 목록 갱신.
  - 현재 선택 브랜드가 수정되면 선택 브랜드 객체도 갱신. 현재 선택 브랜드가 삭제되면 삭제 위치의 다음 브랜드, 없으면 마지막 브랜드, 목록이 비면 `null` 선택으로 전환해 품목관리/공용라벨관리 상태를 초기화.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart` (`lib/core/app.dart`, `doc/BM_RICH_BRAND.sql` 제외).
  - 구현 커밋: `74fa0c3` (`브랜드 설정 변경 헤더 드롭다운 반영`).

- **완료 (2026-07-02)**: 브랜드 삽입 중 테이블 행 헤더 표시 규칙 수정.
  - `lib/widgets/swipe_action_table.dart`: 행 헤더 텍스트를 커스터마이즈하는 `rowNumberText` hook 추가.
  - `lib/home_page_manager.dart` `_BrandSettingsDialogState`: 삽입 중 임시 빈 행의 행 헤더는 빈 값, 아래로 밀린 기존 행의 행 헤더 인덱스는 기존 번호처럼 유지. ESC/삽입 취소 시 임시 행 제거로 자동 원복.
  - 검증 완료: `flutter analyze lib/widgets/swipe_action_table.dart lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/widgets/swipe_action_table.dart` (`lib/core/app.dart`, `doc/BM_RICH_BRAND.sql` 제외).
  - 구현 커밋: `ac5faf2` (`브랜드 삽입 행 헤더 표시 조정`).

- **완료 (2026-07-02)**: 헤더 라벨 설정 다이얼로그와 공용 테이블 행 드래그 순서 변경 플래그 구현.
  - `lib/widgets/swipe_action_table.dart`: `rowReorderEnabled` 플래그와 `onRowReorder` hook 추가. 플래그가 켜진 테이블에서만 행 `LongPressDraggable`/`DragTarget` reorder 동작.
  - `lib/home_page_manager.dart`: 헤더 라벨 설정 버튼 클릭 시 `라벨 설정` overlay 다이얼로그 표시. `LabelSize.datas`를 `라벨 이름` 컬럼 테이블로 표시하고 스와이프 액션 UI 유지.
  - 라벨 행 드래그/드랍 시 드랍 대상 행 바로 위로 로컬 순서 이동. 이동 발생 시 하단 오른쪽 `순서 변경` 영역과 `취소`/`적용` 버튼 표시. `취소`는 원래 순서 복원, `적용`은 추후 DB 처리 자리로 로그만 남김.
  - 검증 완료: `flutter analyze lib/widgets/swipe_action_table.dart lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/widgets/swipe_action_table.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `ab068a0` (`라벨 설정 순서 변경 UI 추가`).

- **완료 (2026-07-02)**: 라벨 설정 테이블 행 드래그/드랍 동작 수정 및 이동 애니메이션 추가.
  - `lib/widgets/swipe_action_table.dart`: reorder 플래그가 켜진 행을 `LongPressDraggable`에서 즉시 반응하는 `Draggable`로 변경. 행 드래그 상태(`_rowDraggingIndex`, `_rowDropTargetIndex`)를 별도로 관리해 컬럼 resize 상태와 분리.
  - 드래그 중 드랍 대상 행 위에 `AnimatedContainer` 간격/라인을 열어 행 내용이 아래로 밀리는 이동 위치 애니메이션 적용.
  - `test/swipe_action_table_test.dart`: `rowReorderEnabled` 테이블에서 실제 drag gesture 후 드랍 대상 행 바로 위로 이동하는 회귀 테스트 추가.
  - 검증 완료: `test/swipe_action_table_test.dart` 5개 성공.
  - 검증 완료: `flutter analyze lib/widgets/swipe_action_table.dart lib/home_page_manager.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/widgets/swipe_action_table.dart`, `test/swipe_action_table_test.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `9f1897f` (`라벨 설정 행 드래그 이동 개선`).

- **완료 (2026-07-02)**: 라벨 설정 테이블 행 헤더 reorder 동기화, 순서 변경 중 스와이프 비활성화, 하단 순서 변경 영역 표시 수정.
  - `lib/widgets/swipe_action_table.dart`: 행 헤더와 데이터 행이 같은 `_buildRowReorderTarget`을 사용하도록 공용화. 행 헤더도 드래그/드랍 가능하며, 드래그 중 같은 행 index의 헤더와 데이터 행이 함께 흐려지고 드랍 간격 애니메이션 공유.
  - `lib/home_page_manager.dart` `_LabelSettingsDialogState`: 순서 변경 감지를 `labelSizeId` 단독 비교에서 객체 identity + `labelSizeId` + `labelSizeName` 비교로 강화해 ID가 비어도 하단 `순서 변경` 영역이 표시되도록 수정.
  - 라벨 순서 변경 상태에서는 `SwipeActionTable.rowSwipeEnabled`를 false로 전달해 모든 컬럼 스와이프 수정/삽입/삭제를 비활성화.
  - `test/swipe_action_table_test.dart`: 행 헤더 드래그가 데이터 행 reorder와 같은 경로로 동작하는 회귀 테스트 추가.
  - 검증 완료: `test/swipe_action_table_test.dart` 6개 성공.
  - 검증 완료: `flutter analyze lib/widgets/swipe_action_table.dart lib/home_page_manager.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/widgets/swipe_action_table.dart`, `test/swipe_action_table_test.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `b881b64` (`라벨 설정 행 헤더 이동 동기화`).

- **완료 (2026-07-02)**: 라벨 설정 행 이동 후 행 헤더 인덱스 고정 및 하단 취소/적용 버튼 프린터 설정 스타일 적용.
  - `lib/home_page_manager.dart` `_LabelSettingsDialogState`: `rowNumberText`를 `_labelRowNumberText`로 전달해 행 이동 후에도 행 헤더가 최초 라벨 목록 기준 인덱스를 유지하도록 변경.
  - 하단 순서 변경 영역의 `취소`/`적용` 버튼을 프린터 설정 다이얼로그 `_PrintDialogButton`과 같은 84x30 흰색 `OutlinedButton`, 2px radius, `0xffc7c7c7` border 스타일로 변경.
  - 검증 완료: `test/swipe_action_table_test.dart` 6개 성공.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart lib/widgets/swipe_action_table.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `78195e4` (`라벨 설정 행 헤더 인덱스 고정`).

- **완료 (2026-07-02)**: 라벨 매니저 커스텀 다이얼로그 하단 버튼 순서를 일반 다이얼로그 기준(`취소` 왼쪽, 확인/적용/진행 오른쪽)으로 통일.
  - `lib/page_label_sheet/label_sheet_workbench.dart` 프린터 설정 다이얼로그: 하단 `적용`/`취소` 배치를 `취소`/`적용`으로 변경. `발행` 버튼은 별도 실행 버튼으로 왼쪽 위치 유지.
  - `lib/page_login/startup_dialog.dart` 시작 로그인 다이얼로그: 하단 `로그인`/`취소` 배치를 `취소`/`로그인`으로 변경.
  - 확인 결과 기존 `AlertDialog.actions` 기반 경고/확인 다이얼로그는 이미 `취소`/`확인` 순서 유지.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_login/startup_dialog.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `lib/page_login/startup_dialog.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `53d134c` (`다이얼로그 하단 버튼 순서 통일`).

- **완료 (2026-07-02)**: 프린터 설정 하단 적용 버튼과 같은 outline action 버튼 corner radius 1 증가.
  - `lib/page_label_sheet/label_sheet_workbench.dart` `_PrintDialogButton`: `RoundedRectangleBorder` radius `2 -> 3`.
  - `lib/home_page_manager.dart` `_LabelSettingsFooterButton`: 프린터 설정 하단 버튼과 같은 스타일 유지하며 radius `2 -> 3`.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `lib/home_page_manager.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `4ba6a95` (`다이얼로그 outline 버튼 곡률 조정`).

- **완료 (2026-07-02)**: 라벨 설정 테이블에서 바로 붙은 위/아래 행 드래그/드랍 시 서로 swap되도록 변경.
  - `lib/widgets/swipe_action_table.dart`: 인접 행 드랍도 no-op으로 막지 않고 `onRowReorder(fromIndex, toIndex)` 콜백 전달.
  - `lib/home_page_manager.dart` `_LabelSettingsDialogState._moveLabelRow`: `fromIndex`와 `toIndex`가 인접하면 insert 대신 두 라벨 위치를 직접 교환.
  - `test/swipe_action_table_test.dart`: 인접 행 드래그 시 두 행이 swap되는 회귀 테스트 추가.
  - 검증 완료: `test/swipe_action_table_test.dart` 7개 성공.
  - 검증 완료: `flutter analyze lib/widgets/swipe_action_table.dart lib/home_page_manager.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/widgets/swipe_action_table.dart`, `lib/home_page_manager.dart`, `test/swipe_action_table_test.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `d006174` (`라벨 설정 인접 행 이동 교환 처리`).

- **완료 (2026-07-02)**: 라벨 설정 순서 변경 영역의 `취소`/`적용` 버튼 배경색을 라이트그레이로 변경.
  - `lib/home_page_manager.dart` `_LabelSettingsFooterButton`: `backgroundColor`를 흰색 `0xffffffff`에서 라이트그레이 `0xFFF1F3F4`로 변경.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `bee4d5c` (`라벨 설정 순서 버튼 배경색 조정`).

- **완료 (2026-07-02)**: 프린터 설정 다이얼로그 하단 `발행` 버튼을 `적용` 버튼 뒤로 이동.
  - `lib/page_label_sheet/label_sheet_workbench.dart` `_LabelSheetPrintSettingsDialog`: 하단 버튼 좌표를 `취소`/`적용`/`발행` 순서로 재배치.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `7bec98f` (`프린터 설정 발행 버튼 위치 조정`).

- **완료 (2026-07-02)**: 브랜드/라벨 설정 테이블 툴팁 표시 범위를 실제 보이는 테이블 row 영역으로 제한.
  - `lib/widgets/swipe_action_table.dart` `_TableBodyTooltip`: `visibleBodyHeight`를 받아 마우스가 실제 보이는 row 영역 밖으로 나가면 예약/표시 중인 툴팁을 숨기도록 변경.
  - `SwipeActionTable.build`: row 개수와 body viewport 높이 기준으로 `visibleBodyHeight` 계산. row 아래 빈 영역이나 스크롤 영역 밖에서는 `rowTooltip` 미표시.
  - 검증 완료: `test/swipe_action_table_test.dart` 7개 성공.
  - 검증 완료: `flutter analyze lib/widgets/swipe_action_table.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/widgets/swipe_action_table.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `09f8489` (`테이블 툴팁 표시 범위 제한`).

- **완료 (2026-07-02)**: 라벨 설정 테이블 행 드래그 애니메이션 feedback에 행 헤더 포함.
  - `lib/widgets/swipe_action_table.dart`: row reorder feedback을 데이터 행 단독에서 `행 헤더 + 데이터 행` 전체 행으로 변경. 데이터 행을 잡아도, 행 헤더를 잡아도 동일한 전체 행 feedback 표시.
  - `SwipeActionTable` row number list가 effective column widths를 사용하도록 변경해 feedback 데이터 행 폭이 실제 표시 폭과 일치.
  - `test/swipe_action_table_test.dart`: 드래그 중 feedback overlay에 행 헤더 텍스트가 추가로 표시되는 회귀 테스트 추가.
  - 검증 완료: `test/swipe_action_table_test.dart` 8개 성공.
  - 검증 완료: `flutter analyze lib/widgets/swipe_action_table.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/widgets/swipe_action_table.dart`, `test/swipe_action_table_test.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `340bb49` (`행 드래그 피드백 헤더 포함`).

- **완료 (2026-07-02)**: RTF Viewer resize 완료 후 최종 크기 기준 recapture 보장 및 진단 로그 추가.
  - `lib/home_page_manager.dart`: RTF preview child를 `GlobalKey`가 붙은 `SizedBox.expand`로 감싸 실제 RenderBox 크기를 post-frame에 읽을 수 있게 변경.
  - resize end 시 기존 rect 기준 recapture 후, 다음 frame에서 실제 preview box 크기에서 padding을 뺀 content target을 다시 계산하고 generation을 증가시켜 `LabelSheetRtfPreview`를 강제 재생성/recapture.
  - 로그 추가: rect target, measured target, current target, recapture reason, generation, target size. 다음 재발 시 rect 계산 문제인지 최종 RenderBox size 문제인지 구분 가능.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart lib/page_label_sheet/label_sheet_rtf_preview.dart lib/page_home/preview_floating_window.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `139cefb` (`RTF Viewer 리사이즈 완료 재캡처 보장`).

- **ODBC 효율 개선**: `LabelSizeDAO.SelectSql`이 목록 조회에서도 `RICH_FORM_DATA`를 항상 가져오는 문제. 목록/상세 조회 분리, 목록에서 `FORM_DATA` 제외, 선택/시트 진입 시 상세 조회로 보강.

## 완료된 기능 요약

- **라벨 파일 가져오기/내보내기**: 좌상단 행/열 헤더 교차 우클릭 메뉴에 `.lms` import/export 연결 (`fortune_sheet_painter`, `label_sheet_workbench`)
- **브랜드 설정 다이얼로그**: `SwipeActionTable` 기반 수정/삽입/삭제 스와이프, 인라인 편집(`isRowContentInteractive`), `canSwipeRow`/`isEnabled` hook, 더블클릭으로 브랜드 선택, 커서 위치 기준 툴팁
- **ODBC 4000자 초과**: `SQL_WLONGVARCHAR` 바인딩 분기 추가 (`windows_odbc_param_utils_test.dart` 6개)
- **프린터 설정 다이얼로그**: 프린터 선택/저장(`SharedPreferences`), 발행(EZPL raw/PDF), 적용 버튼 저장, `DropdownButton2` compact 높이, Tab 포커스 `closedLoop`
- **하이브리드 EZPL 출력**: raster PNG fallback + native border(`R`) + native barcode(`BQ`/`BA`/`BE`/`BB`) 구조 (`label_sheet_print_job.dart`)
- **라벨 시트 저장/불러오기**: base64 ZIP codec, feature 버전 자동 산출, allow-list sanitize, 인쇄영역 기준 payload 축소 (`label_sheet_save_codec.dart`)
- **라벨 시트 zoom**: `+`/`-` 버튼 + EditableText, `FortuneSheetController.setZoomRatio`, 눈금자/경계선/셀 텍스트 zoom 동기화
- **셀 병합**: 병합 텍스트 합치기(`_combineMergeRangeTextIntoAnchor`), 내부 grid line 제거(`_mergedGridLineExcludedSpans`), `FortuneCell.withEditedValue` 경로 수정
- **바코드**: ID 드롭다운(`barcodeObjectIds`), 리사이즈 metadata 스케일링(`fortuneImageResizeExtraFieldsForMetadata`), `barcodeBodyRatio` 저장, ID 박스 위치/크기 비례
- **공용라벨관리 UI**: 특별항목/사용항목 테이블 컬럼 폭 통일, 오른쪽 패널 초기 폭 자동 맞춤, 가로 스크롤바 조건부 표시
- **RTF Viewer 플로팅창**: native RichEdit 캡처(`EM_FORMATRANGE`/`WM_PRINT`), DPI 보정, overflow canvas, 플로팅창 이동/리사이즈/닫기/복원, 드롭다운 z-order (`_PreviewFloatingRoute`)
- **탭/라벨 변경 최적화**: `keepAlive: true`, `_labelContentKey` ValueKey, `_commonLabelTabActivated` 게이트, RTF ready key 연동
- **배포/시작 개선**: AppData 로그/DB 경로(`kReleaseMode`), DB seed 복구(`getLastConnectDBInfo` fallback), 종료 경합 guard(`_closing`), isolate bootstrap retry (최대 2회)
- **FortuneSheet 다이얼로그**: close X glyph 통일(9px), hover/pressed 독점, Tab/Shift+Tab 포커스 순환 (`fortune_barcode_dialog_test.dart`)
- **라벨 시트 좌상단 메뉴**: 라벨 너비/높이 inline 입력, `.lms` 가져오기/내보내기, 코너 hover tooltip
- **RTF import**: CP949 charset 캐싱, 멀티라인 셀 확장, row/cell border, pict 이미지 import, 장평/자간/줄간격/첨자, native rtf2html 우선 경로
- **Git/프로젝트 정리**: generated registrant `.gitignore`, `pub.dev/` 제외, native dependency zip archive, `inno_setup_installer` 소문자 통일, Flutter plugin 구조 전환
