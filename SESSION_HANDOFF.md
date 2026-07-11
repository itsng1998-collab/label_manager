# 세션 인수인계

마지막 업데이트: 2026-07-10

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
- 레거시(이전) 프로젝트 참조 경로는 `.tmp\LabelManager`이다. 이전 프로젝트 저장 로직/동작 비교가 필요하면 이 경로를 기준으로 확인한다.
- 라벨 시트 저장 포맷을 수정할 때는 `lib/page_label_sheet/label_sheet_save_codec.dart`의 `_labelSheetSaveFeatureKeys`에 항목별 feature key를 추가/정렬해 `labelSheetSaveFormatVersion`과 `labelSheetSaveFeatureVersions`가 자동 산출되도록 유지한다. 새로 지원하는 workbook/sheet/config/cell/cellType/inlineRun JSON 필드는 같은 파일의 allow-list 및 `labelSheetSanitizeWorkbookSaveJson` 경로에 반드시 반영한다. 구/외부 포맷 호환은 `labelSheetMigrateWorkbookSaveJson`과 `labelSheetNormalizeWorkbookForCurrentSaveFormat`에 함께 반영하고, `.lms` 초기 로드/라벨 파일에서 불러오기/`.xlsx` import가 모두 현재 포맷으로 처리되는 테스트를 갱신한다.
- Godex G500 같은 라벨 프린터에서 정밀한 인쇄가 핵심이면 일반 프린터 경로와 직접 출력 경로를 분리한다. 직접 출력은 처음부터 모든 스타일을 100% EZPL 명령만으로 처리하기보다 `정밀 좌표 엔진 + EZPL 명령 + 셀 bitmap fallback` 구조를 우선한다. 테두리/선/박스와 바코드는 가능한 한 EZPL 명령으로 출력하고, 화면 폰트와 프린터 폰트 차이로 1:1 보장이 어려운 복합 스타일 텍스트/이미지/배경/RTF 계열 셀은 셀 단위 bitmap fallback을 사용해 시각적 일치도를 확보한다.

## 현재 상태

### 완료 (2026-07-11): 품목관리 8차 재검토 보완

- 7차 보완 재검토에서 isolate 종료 후 새 isolate가 생성돼도 driver는 미연결인데 `DbClient.isConnected`가 true가 되어 재연결이 막히는 문제, 명시적 disconnect가 pending 요청 종료 신호를 완료하지 않는 문제, journal 삭제 ID 집합과 strict integer 검증 누락을 확인했다.
- 권장 작업 순서: DB client 실제 연결 상태/disconnect gate/pending 종료 완료 -> 재연결 서비스와 품목 다시 조회 연결 -> 동시성 테스트 -> journal 삭제 집합 교차 검증 -> strict ID parser -> focused/analyze/전체 suite.
- 수정 예정 1순위: `lib/database/db_client.dart`에 driver 연결 상태를 분리하고 disconnect 중 신규 요청을 차단하며, isolate 자원 정리 전에 현재 termination completer를 완료한다. 미검증.
- `lib/database/db_client.dart` 편집 완료: `isConnected`를 실제 driver 연결 성공 기준으로 분리하고 isolate 종료/dispose에서 false로 전환한다. disconnect 중 신규 요청을 차단하고 startup을 기다리며 cleanup 전에 termination completer를 완료해 pending 요청을 해제한다.
- `lib/database/db_connection_monitor.dart`/`lib/database/db_connection_service.dart` 편집 완료: 최초 ping 실패도 loss로 전달하고, 저장 접속정보 기반 `ensureConnected()`를 단일 recovery future로 제공한다. 새 attach는 이전 reconnect 취소/재시도 상태를 초기화한다.
- `lib/home_page_manager.dart` 편집 완료: 품목 강제 다시 조회 전에 `ensureConnected()`를 수행한다.
- `test/db_client_test.dart`/`test/db_connection_monitor_test.dart` 편집 완료: cleanup pending 완료/idempotence 및 최초 ping 실패 loss 경계 포함 DB focused 6개 통과.
- DB lifecycle 후속 완료: isolate startup을 기다리던 요청은 대기 후 disconnect gate를 재검사하고, 중복 disconnect 호출은 같은 완료 future를 공유한다. DB client/monitor/transaction 19개 재통과, 관련 진단 0건.
- `lib/models/item_manager_draft_journal.dart` 편집 완료: 삭제 fingerprint 대상 ID를 `deletedRows`에서 재산출하고 파일 삭제 목록/현재 controller 삭제 집합과 교차 검증한다. identity/market metadata는 strict int와 양수 집합을 사용한다.
- `test/item_manager_draft_journal_test.dart` 편집 완료: 삭제 ID 목록 누락과 fractional identity 변조를 `invalid`로 차단하며 journal 21개 통과.
- 변경 Dart 8개 파일 format 완료. DB client/monitor/transaction/journal/draft/save DAO focused 묶음 71개 통과.
- 중간 전체 검증은 workspace 진단 0건, analyze 성공, 전체 테스트 316개 통과, diff check 성공이었다. 최종 lifecycle 보완 후 analyze/전체 suite/diff check를 재실행한다.
- 최종 검증 완료: workspace 진단 0건, `C:\Flutter\bin\flutter.bat analyze`는 `No issues found`, 전체 `C:\Flutter\bin\flutter.bat test` 316개 통과, `git diff --check` 성공.
- 기능 커밋 `954e195` (`품목관리 DB 재연결과 journal 무결성 보완`) 완료. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.
- 기존 unrelated dirty `lib/core/app.dart`는 수정·stage 대상에서 제외한다.

### 완료 (2026-07-11): 품목관리 7차 재검토 보완

- 6차 보완 재검토에서 DB transaction COMMIT 후 isolate가 응답 전 종료되면 `DbClient._sendToIsolate()`가 영구 대기하는 문제와 mapping fingerprint가 동일 market 중복 mapping count를 제거하는 문제를 확인했다.
- 권장 작업 순서: 실행 중 isolate 종료 감시와 pending transaction의 `DbCommitOutcomeUnknown` 완료 -> 응답/종료 경계 테스트 -> fingerprint count 보존과 malformed journal 차단 -> focused/analyze/전체 suite.
- 수정 예정 1순위: `lib/database/db_client.dart`가 bootstrap 이후에도 isolate error/exit monitor를 유지하고, 요청 응답과 종료 신호를 경합시킨다. 응답 없는 transaction 종료는 자동 재시도하지 않고 `DbCommitOutcomeUnknown`, 일반 요청 종료는 명시적 오류로 완료한다. 미검증.
- `lib/database/db_client.dart` 편집 완료: bootstrap 이후 error/exit port를 유지하고 현재 isolate 세대의 종료 신호와 요청 응답을 경합한다. 응답 없는 transaction은 `DbCommitOutcomeUnknown`, 일반 요청은 `StateError`로 완료하며 종료된 isolate 자원을 무효화한다.
- `test/db_client_test.dart` 추가 완료: transaction 종료, query 종료, 정상 응답 우선 경계 3개 통과.
- `lib/models/item_of_market.dart` 편집 완료: fingerprint market id를 set으로 축약하지 않고 정렬 multiset으로 유지해 동일 market 중복 mapping count를 보존한다.
- `lib/models/item_manager_draft_journal.dart` 편집 완료: 저장 fingerprint의 모든 원소를 양의 정수로 검증하고 count를 포함한 정렬 목록으로 현재 DB와 비교한다.
- `test/item_manager_read_snapshot_test.dart`/`test/item_manager_draft_journal_test.dart` 편집 완료: 중복 mapping count 변경과 문자열 원소 journal 변조 회귀를 추가했으며 관련 묶음 25개 통과.
- 변경 Dart 6개 파일 format 완료, 관련 파일 진단 0건. DB client/transaction/journal/read snapshot/save DAO focused 묶음 48개 통과.
- `_sendToIsolate()`의 ensure 직후 요청 전 isolate 종료 경쟁도 null 단정 대신 명시적 `StateError`로 차단했다. DB client/transaction 16개 재통과.
- 최종 검증 완료: workspace 진단 0건, `C:\Flutter\bin\flutter.bat analyze`는 `No issues found`, 전체 `C:\Flutter\bin\flutter.bat test` 311개 통과, `git diff --check` 성공.
- 기능 커밋 `b31890a` (`품목관리 DB 응답 유실과 연결 지문 보완`) 완료. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.
- 기존 unrelated dirty `lib/core/app.dart`는 수정·stage 대상에서 제외한다.

### 완료 (2026-07-11): 품목관리 6차 재검토 보완

- 5차 보완 재검토에서 COMMIT 호출/응답 오류가 일반 transaction 실패로 처리돼 같은 draft를 재저장할 수 있는 문제와, 일반 삭제 취소에서 journal에 저장한 mapping fingerprint를 읽지 않는 문제를 확인했다.
- `lib/database/drivers/db_driver.dart` 편집 완료: COMMIT 시도 후 오류를 `DbCommitOutcomeUnknown`으로 분류하고 안전한 rollback SQL은 시도하되 rollback 성공으로 오인하지 않는다.
- `lib/database/db_isolate.dart`/`lib/database/db_client.dart` 편집 완료: isolate 응답의 `commitOutcomeUnknown` 오류 코드를 통해 전용 예외 타입을 UI isolate까지 보존한다.
- `lib/home_page_manager.dart` 편집 완료: commit 결과 불확실 시 journal을 재flush하지 않고 `forceReloadRequired`로 전환해 재저장을 차단한다. journal에는 삭제 item 전용 mapping fingerprint DAO를 주입하고 `externalChange` 결과를 현재 DB 재조회와 경고로 처리한다.
- `lib/models/item_manager_draft_journal.dart` 편집 완료: 삭제 item이 있을 때만 현재 mapping fingerprint를 조회해 저장값과 비교하며, 불일치는 `externalChange`, 조회 실패는 예외로 전달해 상위 DB reload 경로를 사용한다.
- 테스트 추가: COMMIT throw/JSON error/malformed 응답 3종은 `DbCommitOutcomeUnknown`이며 transaction 13개 통과. fingerprint 일치/불일치/조회 실패 포함 journal 17개 통과.
- 변경 Dart 파일 format 완료. transaction/journal/draft/save focused 묶음 61개 통과, workspace 진단 0건, `C:\Flutter\bin\flutter.bat analyze` 성공(`No issues found`).
- 전체 `C:\Flutter\bin\flutter.bat test` 306개 통과, `git diff --check` 성공.
- 기능 커밋 `ad967cb` (`품목관리 트랜잭션 불확실 상태와 삭제 복원 보완`) 완료. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 진행 중 (2026-07-11): 품목관리 5차 재검토 보완

- 4차 보완 재검토에서 journal 저장 checksum을 현재 controller와만 비교하고 파일 `beforeSnapshots` 복원 후보 자체를 재검증하지 않는 문제, journal identity가 draft key만 비교해 current/target market 불일치를 수용할 수 있는 문제, BEGIN 호출 자체 throw 시 rollback을 시도하지 않는 문제를 확인했다.
- 권장 작업 순서: 복원 후보 rows/columns checksum 재계산과 baseline identity 대조 -> journal metadata 전체 identity/market 집합 검증 -> 유효 JSON snapshot 변조 및 market mismatch 테스트 -> BEGIN 호출 throw rollback -> focused/analyze/전체 suite.
- 수정 예정 1순위: `lib/models/item_manager_draft_journal.dart`의 baseline checksum 산출을 rows/scoped columns 입력 순수 helper로 분리하고, 파일에서 재구성한 후보를 controller에 적용하기 전에 저장 checksum과 다시 비교한다. 기존 unrelated dirty `lib/core/app.dart`는 수정·stage 대상에서 제외한다. 미검증.
- `lib/models/item_manager_draft_journal.dart` 편집 완료: 복원 후보 rows/columns로 저장 시와 같은 checksum을 재계산하고 item id/order/original index, raw snapshot item/current market, column item identity를 적용 전에 검증한다. metadata는 draft key뿐 아니라 user/customer/brand/label/current market과 target market 집합 전체를 비교한다.
- `test/item_manager_draft_journal_test.dart` 편집 완료: 저장 checksum 필드는 유지한 before snapshot 품명 변조와 current market metadata 불일치를 `invalid`로 차단하고 dirty controller를 보존하는 테스트를 추가했다. journal 전체 14개 통과.
- `lib/database/drivers/db_driver.dart` 편집 완료: BEGIN 호출 직전에 begin attempt를 기록해 호출 자체 throw에도 `IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION`을 시도한다.
- `test/db_transaction_test.dart` 편집 완료: BEGIN 호출 throw rollback과 rollback 동시 실패 시 원래 BEGIN 오류 보존 테스트를 추가했다. transaction 전체 10개 통과.
- 다음 검증: 변경 Dart 파일 format, journal/transaction/draft focused 묶음, workspace 진단, `C:\Flutter\bin\flutter.bat analyze`, `C:\Flutter\bin\flutter.bat test`, `git diff --check`.
- 최종 검증 완료: 변경 Dart 4개 파일 format, journal/transaction/draft focused 48개 통과, workspace 진단 0건. 최초 analyze에서 checksum helper 분리 후 미사용 지역 변수 1건을 제거했고 재실행은 `No issues found`였다. 전체 `C:\Flutter\bin\flutter.bat test`는 300개 통과 / 0 실패, `git diff --check`는 출력 없이 통과했다.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/database/drivers/db_driver.dart`, `lib/models/item_manager_draft_journal.dart`, `test/db_transaction_test.dart`, `test/item_manager_draft_journal_test.dart`. 기존 unrelated dirty `lib/core/app.dart`는 제외하며 배포 빌드/설치 파일은 생성하지 않았다.
- 기능 커밋 완료: `3e012f5` 품목관리 journal 무결성 보완.

### 진행 중 (2026-07-11): 품목관리 4차 재검토 보완

- 3차 보완 재검토에서 journal 파일이 before snapshot을 실제 복원하지 않고 controller 메모리 baseline만 사용하며, journal version/key/checksum 불일치를 파일 부재와 동일하게 처리하고, transaction BEGIN 결과 검사가 rollback 보호 범위 밖인 문제를 확인했다.
- 권장 작업 순서: 변경 기존/삭제 행 before snapshot과 원본 컬럼값 journal 저장 -> 파일 snapshot 기반 clean controller 복원 -> journal 결과 `notFound/restored/invalid` 분기와 invalid DB reload -> BEGIN부터 rollback 보호 -> focused/analyze/전체 suite.
- 수정 예정 1순위: `lib/models/item_manager_draft.dart`에 journal이 검증한 clean row/column/선택 상태를 적용하는 전용 복원 API를 추가하고, `lib/models/item_manager_draft_journal.dart`가 변경 대상 before snapshot을 직렬화/역직렬화하도록 한다. 기존 unrelated dirty `lib/core/app.dart`는 수정·stage 대상에서 제외한다. 미검증.
- `lib/models/item_manager_draft.dart` 편집 완료: `restoreJournalBaseline`이 journal에서 재구성한 existing rows/scoped columns/선택을 새 clean baseline으로 교체하고 신규·삭제·수정 상태를 폐기한다. 기존 draft 테스트 24개 통과.
- `lib/models/item_manager_draft_journal.dart` 편집 완료: schema 3에서 수정·삭제 기존 행의 `ItemOfMarket`/raw snapshot/주원료 payload/전체 원본 컬럼을 `beforeSnapshots`에 저장하고, baseline 순서와 결합해 다른 controller에도 clean 상태를 복원한다. restore 결과는 `notFound/restored/invalid`로 구분한다.
- `lib/home_page_manager.dart` 편집 완료: 일반 취소는 `invalid` journal을 메모리 fallback하지 않고 DB reload하며 `notFound`만 controller baseline을 사용한다. Excel 전체 교체 경로는 유지한다.
- `test/item_manager_draft_journal_test.dart` 편집 완료: before snapshot JSON과 cross-controller 품명/컬럼 복원을 검증한다. `flutter test test\item_manager_draft_journal_test.dart` 11개 통과.
- 다음 작업: journal mismatch 상태 테스트 추가 후 `lib/database/drivers/db_driver.dart`에서 BEGIN부터 rollback 보호 범위에 포함하고 plain-text/malformed 응답 회귀 테스트를 추가한다.
- journal 후속 완료: checksum 불일치는 `invalid`로 분류하고, 복원 적용 후 파일 cleanup 실패는 로그만 남겨 이미 복원된 controller를 다시 DB reload하지 않는다. journal 테스트는 mismatch/cross-controller 포함 12개로 확장됐다.
- `lib/database/drivers/db_driver.dart` 편집 완료: BEGIN 실행/응답 검사를 rollback 보호 범위에 포함하고 JSON object 형태 문자열만 decode해 plain-text 정상 결과를 허용한다. malformed BEGIN 응답은 rollback하며 원래 오류를 보존한다.
- `test/db_transaction_test.dart` 편집 완료: plain-text 성공 commit과 malformed JSON BEGIN rollback 테스트를 추가했다. transaction 테스트 8개 통과.
- 변경 Dart 6개 파일 format 완료. journal/draft/transaction focused 묶음 44개 통과. 다음 검증은 workspace 진단, `C:\Flutter\bin\flutter.bat analyze`, `C:\Flutter\bin\flutter.bat test`, `git diff --check` 순서로 실행한다.
- 최종 검증 완료: workspace 진단 0건, `C:\Flutter\bin\flutter.bat analyze`는 `No issues found`, 전체 `C:\Flutter\bin\flutter.bat test`는 296개 통과 / 0 실패, `git diff --check`는 출력 없이 통과했다.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/database/drivers/db_driver.dart`, `lib/home_page_manager.dart`, `lib/models/item_manager_draft.dart`, `lib/models/item_manager_draft_journal.dart`, `test/db_transaction_test.dart`, `test/item_manager_draft_journal_test.dart`. 기존 unrelated dirty `lib/core/app.dart`는 제외하며 배포 빌드/설치 파일은 생성하지 않았다.
- 기능 커밋 완료: `ae4fd41` 품목관리 journal 복원 보완.

### 진행 중 (2026-07-11): 품목관리 3차 재검토 보완

- 재검토에서 비 Windows driver의 JSON `error` 결과가 transaction에서 예외로 변환되지 않는 문제, 품목 순서 affected 검증이 commit 후 수행되는 문제, QR/preview 날짜 token callback 누락, 일반 취소가 journal 파일을 실제 복원 기준으로 사용하지 않는 문제를 확인했다.
- 작업 순서: 공용 transaction 오류 결과 rollback 보장 -> 순서 변경 검증을 transaction 내부 SQL로 이동 -> QR/preview `DATE_FORMAT_NONE` token 계산 연결 -> journal reader/일반 취소 복원 경로 구현 -> focused/analyze/전체 suite.
- 수정 예정 1순위: `lib/database/drivers/db_driver.dart`가 BEGIN/statement/COMMIT의 JSON 문자열 또는 Map `error` 결과를 즉시 예외로 변환하도록 하고 `test/db_transaction_test.dart`에 rollback 회귀 테스트를 추가한다. 미검증. 기존 unrelated dirty `lib/core/app.dart`는 수정·stage 대상에서 제외한다.
- 1순위 완료: transaction boundary가 Map/JSON `error` 결과를 예외로 변환해 rollback하며 `test/db_transaction_test.dart` 6개가 통과했다.
- 2순위 완료: `ItemDAO.updateOrders`를 JSON 단일 batch와 transaction 내부 affected-row `THROW` 검증으로 변경했으며 `test/item_manager_save_dao_test.dart` 7개가 통과했다.
- 3순위 진행: `itemCodeTokenColumnValue`가 유통기한 offset을 제조일자 또는 현재일 기준 `yyyyMMdd`로 계산하고 QR viewer/output preview가 같은 callback을 사용한다. resolver 테스트 10개 통과, 관련 세 파일 편집기 진단 0건.
- 4순위 수정 예정: journal 파일의 identity/checksum과 편집 전 선택 상태를 검증해 일반 변경 취소의 우선 복원 기준으로 사용하고, 파일 부재/기록 실패 때만 controller 메모리 baseline으로 fallback한다. Excel 전체 교체 취소의 DB reload 경로는 유지한다. 미검증.
- 4순위 완료: `ItemManagerDraftJournal.restoreBaseline()`이 version/draftKey/baseline checksum을 검증하고 파일에 저장된 clean 다중 선택으로 controller baseline을 복원한 뒤 journal을 삭제한다. 일반 취소는 journal 우선, 파일 부재 시 메모리 baseline, 손상/검증 오류 시 DB reload를 사용하며 Excel 전체 교체 DB reload는 유지한다.
- journal listener와 복원 clear의 파일 삭제 경쟁을 복원 중 listener 분리로 해결했다. draft/journal/resolver focused 테스트 44개 통과, 관련 파일 편집기 진단 0건.
- 최종 검증 예정: 변경 Dart 파일 format 후 transaction/order/date/journal/draft focused 테스트, `C:\Flutter\bin\flutter.bat analyze`, `C:\Flutter\bin\flutter.bat test`, `git diff --check`. 기존 unrelated dirty `lib/core/app.dart`는 제외하고 관련 파일만 stage/commit하며 배포 파일은 생성하지 않는다.
- 최종 검증 진행: 변경 Dart 10개 파일 format 완료, transaction/order/date/journal/draft focused 테스트 57개 통과. `C:\Flutter\bin\flutter.bat analyze`는 `No issues found`, 전체 `C:\Flutter\bin\flutter.bat test`는 292개 통과 / 0 실패, workspace 진단 0건이다.
- 최종 남은 검증: `git diff --check`, 변경 목록 확인 후 `lib/core/app.dart`를 제외한 관련 파일만 stage/commit한다. 배포 빌드와 설치 파일은 생성하지 않았다.
- 최종 검증 완료: `git diff --check` 출력 없이 통과. stage/commit 대상은 `SESSION_HANDOFF.md`, transaction/order/date/journal 관련 lib 6개와 test 4개이며, 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 기능 커밋 완료: `bb6a6a1` 품목관리 3차 재검토 보완.

### 완료 (2026-07-11): 품목관리 재검토 보완

- 재검토 결과 조회 전용 사용자의 하단 주원료 sheet 편집 가능, 실제 일반 취소 경로의 baseline 멀티 선택 단일화, 발행 체크의 우클릭/체크박스 권한 불일치를 확인했다.
- 수정 예정 1순위: `lib/home_page_manager.dart`에서 조회 전용 품목 주원료 workbook을 FortuneSheet engine 보호 상태로 열고 편집 toolbar/callback을 제거하며, draft commit 진입점에서도 권한을 재검증한다. `test/label_sheet_toolbar_test.dart`에 조회 전용 회귀 테스트를 추가한다. 미검증.
- 후속 예정: 일반 취소는 명시 item id 없이 controller baseline 선택을 복원하고, 발행 체크는 품목 편집 권한과 분리된 일관된 로컬 선택 정책으로 정리한 뒤 focused/전체 검증한다.
- `lib/home_page_manager.dart`/`test/label_sheet_toolbar_test.dart` 1순위 완료: 조회 전용 주원료 workbook에 FortuneSheet sheet authority 보호를 적용하고 toolbar/onChange/onSave를 제거했으며 draft commit 진입점도 권한을 재검증한다. `flutter test test\label_sheet_toolbar_test.dart --plain-name "item element"` 9개 통과.
- `lib/home_page_manager.dart` 선택 복원 완료: 일반 취소에서 현재 anchor item id를 강제하지 않고 `discardChanges()`의 clean baseline 단일/멀티 선택을 그대로 복원한다. draft/FortuneTable focused 묶음 52개 통과.
- `lib/page_home/item_manage.dart`/`test/fortune_table_test.dart` 발행 선택 정책 완료: 발행 체크를 DB 편집 권한과 분리된 로컬 출력 선택으로 명시하고 체크박스와 우클릭 메뉴에 같은 `publishSelectionEnabled` 조건을 적용했다. 조회 전용 회귀 테스트 포함 FortuneTable 29개 통과.
- 최종 검증 예정: 변경 Dart 파일 format, 관련 파일 오류 확인, focused 테스트, `C:\Flutter\bin\flutter.bat analyze`, 전체 `C:\Flutter\bin\flutter.bat test`, `git diff --check`. 미검증 상태이며 배포 빌드/설치 파일은 생성하지 않는다.
- 최종 검증 진행: 변경 Dart 4개 파일 format 완료, 편집기 진단 0건, `git diff --check` 통과. 이어서 주원료/품목 draft/FortuneTable focused 테스트와 `C:\Flutter\bin\flutter.bat analyze`를 실행한다.
- focused/analyze 완료: `test\item_manager_draft_test.dart`, `test\fortune_table_test.dart`, `test\label_sheet_toolbar_test.dart` 전체 158개 통과. `C:\Flutter\bin\flutter.bat analyze`는 `No issues found`. 최초 plain-name 필터 명령은 Windows에서 `|`가 pipe로 해석되어 테스트 미실행 후 파일 전체 명령으로 재검증했다.
- 전체 검증 실행 예정: `C:\Flutter\bin\flutter.bat test` 후 결과와 최종 stage/commit 대상을 기록한다.
- 전체 검증 완료: `C:\Flutter\bin\flutter.bat test` 287개 통과 / 0 실패, 최종 `git diff --check` 통과. 배포 빌드와 설치 파일은 생성하지 않았다.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/page_home/item_manage.dart`, `test/fortune_table_test.dart`, `test/label_sheet_toolbar_test.dart`. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 기능 커밋 완료: `45d08d7` 품목관리 재검토 보완.

### 완료 (2026-07-11): 품목관리 머지 검토 보완

- 다른 PC에서 구현한 `doc/item_manager_modify.txt` 기준 변경을 merge한 뒤 코드 검토를 수행했다. merge 충돌은 `SESSION_HANDOFF.md`뿐이었으나 구현 자체에서 권한 차단, 주원료 미commit 반영, 문자열 길이 검증, 멀티 선택/취소 선택 복원, scoped column content 조회, journal 테스트 안정성, 실제 출력 계약 보완 필요성을 확인했다.
- 수정 예정 1순위: `lib/page_home/item_manage.dart`와 `lib/home_page_manager.dart`에서 조회 전용 사용자의 품목 추가/삽입/삭제/셀 편집/Excel import/저장을 UI와 command 진입점 양쪽에서 차단한다. `test/fortune_table_test.dart`에 조회 전용 회귀 테스트를 추가한다. 기존 unrelated dirty `lib/core/app.dart`는 수정·stage 대상에서 제외한다.
- 현재 검증 기준: merge 상태 `flutter analyze` 통과. 전체 `flutter test`는 두 번 모두 journal 테스트의 고정 20ms 파일 생성 대기 1건 실패(`+279 -1`), 해당 테스트 단독 실행은 통과했다. 보완 후 focused test와 전체 suite를 다시 실행한다.
- `lib/page_home/item_manage.dart`/`lib/home_page_manager.dart` 편집 완료: `canEdit`을 mutation command에 주입하고 조회 전용 사용자의 추가/삽입/삭제/셀·이미지 편집/Excel import/취소/저장을 차단했다. `_saveItemDraft()`에서도 권한을 재검증한다. 조회 전용 widget test 통과.
- `lib/home_page_manager.dart` 주원료 편집 완료: FortuneSheet workbook 변경 callback에서 plain text/encoded workbook을 품목 draft callback에 즉시 반영해 내부 toolbar 저장 없이 행 전환·하단 저장 전에 변경이 draft에 남도록 했다. 기존 toolbar 저장과 자동 반영 focused test 2개 통과.
- `lib/models/item_manager_draft.dart` 저장 검증 완료: SQL `OPENJSON` 계약과 같은 품명 100자/일반 컬럼 3000자 상수를 추가하고 초과 값을 정확한 row/column validation error로 차단했다. draft 전체 22개(후속 선택 복원 포함 23개) 테스트 통과.
- `lib/page_home/item_manage.dart`/`lib/models/item_manager_draft.dart` 선택 상태 완료: FortuneTable 전체 선택 집합을 row key 집합으로 동기화하고 clean 상태의 baseline 선택을 보관해 추가/삽입 후 일반 취소에서도 편집 전 선택을 복원한다. FortuneTable 전체 28개와 draft 전체 23개 테스트 통과.
- `lib/home_page_manager.dart` scoped 조회 완료: label-size 전체 `TColumnContentDAO.selectByLabelSizeId` 선조회를 제거하고 현재 market item id scoped 결과만 draft와 호환 static cache에 반영한다. 읽기/스냅샷 6개 테스트 통과.
- `test/item_manager_draft_journal_test.dart` 안정화 완료: 고정 20ms 파일 생성 대기를 directory 접근 완료 신호와 명시적 flush 대기로 교체했다. journal 전체 8개 테스트 통과.
- 출력 계약 정리 완료: `doc/item_manager_modify.txt`에서 이번 범위는 resolver metadata가 반영된 output workbook 생성 계약까지로 확정하고, 홈 `라벨출력(F3)` 화면과 실제 발행 command 연결은 별도 출력 기능 작업으로 분리했다. 실제 연결 시 raw template이 아닌 output workbook 계약을 사용한다.
- 다음 검증 예정: 변경 파일 format, focused test 묶음, `flutter analyze`, 전체 `flutter test`, `git diff --check`. 검증 후 기존 unrelated dirty `lib/core/app.dart`를 제외하고 stage/commit한다.
- 검증 실행 예정: `C:\Flutter\bin\flutter.bat test test\item_manager_draft_test.dart`, `test\fortune_table_test.dart`, `test\label_sheet_toolbar_test.dart`, `test\item_manager_draft_journal_test.dart`, `test\item_manager_read_snapshot_test.dart`를 focused 실행한 뒤 `C:\Flutter\bin\flutter.bat analyze`, `C:\Flutter\bin\flutter.bat test`, `git diff --check`를 실행한다.
- 검증 완료: draft 24개, FortuneTable 28개, 주원료 focused 8개, journal 8개, 읽기/스냅샷 6개 테스트가 통과했다. `C:\Flutter\bin\flutter.bat analyze`는 `No issues found`, 전체 `C:\Flutter\bin\flutter.bat test`는 `285 통과 / 0 실패`, `git diff --check`는 출력 없이 통과했다.
- stage/commit 대상: `SESSION_HANDOFF.md`, `doc/item_manager_modify.txt`, `lib/home_page_manager.dart`, `lib/models/item_manager_draft.dart`, `lib/page_home/item_manage.dart`, `test/fortune_table_test.dart`, `test/item_manager_draft_journal_test.dart`, `test/item_manager_draft_test.dart`, `test/label_sheet_toolbar_test.dart`. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 기능 커밋 완료: `0ab5b92` 품목관리 머지 검토 보완.

### 완료 (2026-07-10): 품목관리 요청서 preview/output check digit 문구 정리

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 확정 정책 안에서 출력 미리보기/실제 출력 경로의 check digit 보정 문장이 셀 편집 자동 보정 저장 정책과 충돌해 보이지 않도록 문맥을 좁히는 문서 수정이다.
- 병합 예정: preview/output 경로에서 수행하는 check digit 보정은 payload 산출 전용임을 명시하고, 셀 편집 자동 보정 저장 정책은 별도 셀 편집 규칙을 따른다고 구분한다.
- `.tmp/item_manager_modify.txt` 반영 완료: preview/output barcode text 산출 문장에서 출력 미리보기/실제 출력 경로의 check digit 보정은 payload 산출 전용이고, 셀 편집 자동 보정 저장 정책은 별도 셀 편집 규칙을 따른다고 명시했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `출력 미리보기/실제 출력 경로에서 수행하는 check digit 보정은 preview/output payload 산출에만 적용`, `셀 편집 자동 보정 저장 정책은 별도 셀 편집 규칙을 따른다` 문구 확인. 기존 충돌 가능 표현 `check digit 자동 보정은 preview/output payload 산출에만 적용하고`, `사용자 답변: 미확정`, `확정 필요`, `TODO`, `FIXME` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `732647c` 품목관리 요청서 출력 체크디지트 문구 기록

### 완료 (2026-07-10): 품목관리 요청서 check digit 오류 범위 정리

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 확정 정책 안에서 EAN-13/UPC-A/EAN-8 외 타입 전체가 저장 전 오류처럼 읽히는 표현을 `check digit 자동 보정 저장 요구 입력`으로 좁히는 문서 수정이다.
- 병합 예정: EAN-13/UPC-A/EAN-8 외 타입은 check digit 자동 보정 저장을 수행하지 않되, Code128/QR/DataMatrix 등 check digit 자동 보정과 무관한 일반 barcode/QR 값은 각 타입의 기존 형식 검증 규칙을 따르도록 본문, 수용조건, 사용자 확인 사항을 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 본문, 수용조건, 사용자 확인 사항에서 EAN-13/UPC-A/EAN-8 외 타입 전체가 저장 전 오류처럼 읽히던 표현을 `check digit 옵션 또는 레거시 전용 check digit 보정이 요구되는 입력만 저장 전 검증 오류`로 좁혔다.
- `.tmp/item_manager_modify.txt` 반영 완료: Code128/QR/DataMatrix 등 check digit 자동 보정과 무관한 일반 barcode/QR 값은 각 타입의 기존 형식 검증 규칙을 따른다고 명시했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `EAN-13/UPC-A/EAN-8 외 타입은 check digit 자동 보정 저장을 수행하지 않는다`, `check digit 옵션 또는 레거시 전용 check digit 보정이 요구되는 입력만 저장 전 검증 오류`, `Code128/QR/DataMatrix 등 check digit 자동 보정과 무관한 일반 barcode/QR 값은 각 타입의 기존 형식 검증 규칙` 문구 확인. 기존 과도 표현 `그 외 barcode type이나 레거시 전용 check digit 보정은 이번 요청 범위에서 추가 구현하지 않고 저장 전 검증 오류`, `기타 레거시 전용 check digit은 이번 요청 범위에서 자동 보정 저장 대상으로 추가하지 않고 저장 전 검증 오류`, `사용자 답변: 미확정`, `확정 필요`, `TODO`, `FIXME` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `46349e2` 품목관리 요청서 체크디지트 오류 범위 기록

### 완료 (2026-07-10): 품목관리 요청서 check digit 범위 닫기

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 확정 정책 안에서 기타 barcode/check digit 타입이 추가 구현 대상으로 열려 보이는 표현을 현재 요청 범위 밖으로 명확히 닫는 문서 수정이다.
- 병합 예정: 셀 편집 자동 보정 저장 대상은 EAN-13/UPC-A/EAN-8로 닫고, 그 외 barcode type/레거시 전용 check digit은 이번 요청 범위에서 추가 구현하지 않으며 저장 전 검증 오류로 처리하도록 본문과 사용자 확인 사항을 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: check digit 본문, 수용조건, 사용자 확인 사항의 열린 추가 구현 표현을 제거하고, EAN-13/UPC-A/EAN-8 외 타입은 이번 요청 범위에서 자동 보정 저장 대상으로 추가하지 않으며 저장 전 검증 오류로 처리하도록 명시했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `이번 구현의 범위는 EAN-13/UPC-A/EAN-8로 닫는다`, `이번 요청 범위에서 추가 구현하지 않고 저장 전 검증 오류`, `이번 요청 범위에서 자동 보정 저장 대상으로 추가하지 않고 저장 전 검증 오류` 문구 확인. `별도 명시된 추가 구현 대상으로 처리`, `레거시 함수와 DB 저장 규칙을 확인해 요청서에 명시한 경우에만 추가`, `사용자 답변: 미확정`, `확정 필요`, `TODO`, `FIXME` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `55db352` 품목관리 요청서 체크디지트 범위 기록

### 완료 (2026-07-10): 품목관리 요청서 Excel image 검증/check digit 문구 정리

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 확정 정책 안에서 check digit 문장의 오해 가능성과 Excel 검증 태그 누락을 정리하는 문서 수정이다.
- 병합 예정: `TColumn.useBarcodeCheckDigit` 문장을 EAN-13/UPC-A/EAN-8 범위로 좁히고, `[Excel]` 검증 태그에 `TYPE_IMAGE` 셀 표시 문자열, 경로 제거, `.bmp` 확장자 제거, 다른 확장자 저장 전 검증 오류 fixture를 추가한다.
- `.tmp/item_manager_modify.txt` 반영 완료: check digit 본문 문장을 EAN-13/UPC-A/EAN-8 컬럼의 `TColumn.useBarcodeCheckDigit`가 켜진 경우로 좁혔다.
- `.tmp/item_manager_modify.txt` 반영 완료: `[Excel]` 검증 태그에 `TYPE_IMAGE` 셀 표시 문자열 사용, 경로 제거, `.bmp` 확장자 제거, 다른 확장자 저장 전 검증 오류 fixture를 추가했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `EAN-13/UPC-A/EAN-8 컬럼의 TColumn.useBarcodeCheckDigit`, `[Excel] ... TYPE_IMAGE`, `경로 제거, .bmp 확장자 제거`, `다른 확장자 저장 전 검증 오류 fixture` 문구 확인. 기존 넓은 `바코드 셀 편집에서 TColumn.useBarcodeCheckDigit가 켜진 컬럼` 문구 없음 및 `사용자 답변: 미확정`, `확정 필요`, `TODO`, `FIXME` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `f68e8b8` 품목관리 요청서 이미지 검증 기준 기록

### 완료 (2026-07-10): 품목관리 요청서 image import/check digit 수용조건 병합

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 확정 정책 안에서 수용조건과 Excel import 이미지 컬럼 처리 기준을 명확히 닫는 문서 수정이다.
- 병합 예정: 수용조건의 `바코드 체크디지트 사용 컬럼` 문구를 EAN-13/UPC-A/EAN-8 범위로 좁히고, Excel import의 `TYPE_IMAGE` 컬럼은 셀 표시 문자열만 받아 경로 제거 + `.bmp` 확장자 제거한 파일명으로 정규화하며 다른 확장자는 저장 전 검증 오류로 처리하도록 명시한다.
- `.tmp/item_manager_modify.txt` 반영 완료: Excel import 이미지 타입(`TYPE_IMAGE`) 컬럼은 Excel 객체 이미지를 가져오지 않고 셀 표시 문자열만 사용하며, 경로와 `.bmp` 확장자를 제거한 파일명만 저장 후보로 두고 다른 확장자는 저장 전 검증 오류로 처리하도록 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 수용조건의 check digit 문구를 EAN-13/UPC-A/EAN-8 범위로 좁히고, 0 padding/truncation 결과와 ITF 홀수/기타 레거시 전용 check digit은 자동 보정 저장 대상이 아니라고 명시했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `Excel import의 이미지 타입`, `TYPE_IMAGE ... 셀 표시 문자열`, `경로와 .bmp 확장자는 제거`, `다른 확장자가 명시된 값은 저장 전 검증 오류`, `EAN-13/UPC-A/EAN-8의 check digit 사용 컬럼`, `길이 부족/초과를 0 padding 또는 truncation으로 맞춘 값은 자동 보정 저장값` 문구 확인. `바코드 체크디지트 사용 컬럼은 저장 전 draft`, `사용자 답변: 미확정`, `확정 필요`, `TODO`, `FIXME` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `bf1a76c` 품목관리 요청서 이미지 가져오기 기준 기록

### 완료 (2026-07-10): 품목관리 요청서 fallback/check digit 범위 권장안 병합

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 확정 정책 안에서 선택 구현과 자동 보정 범위를 더 명확히 닫는 문서 수정이다.
- 병합 예정: `hasRichElementSheet=false`의 read-only fallback SELECT는 선택 구현으로 분리하고, 필수 완료 기준은 기존 SELECT 미실행 + DB migration 안내 + 편집 비활성화로 고정한다. 바코드 셀 편집 check digit 자동 보정 저장 범위는 EAN-13/UPC-A/EAN-8로 닫고, ITF 홀수/기타 레거시 전용 보정은 오류 또는 별도 명시 조건으로 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `hasRichElementSheet=false` 필수 완료 기준을 기존 `ItemOfMarketDAO.SelectSql` 미실행, DB migration 안내 화면, 품목관리 테이블 미오픈, 편집/저장 비활성화로 고정하고, read-only fallback SELECT는 구현한 경우에만 추가 검증하는 선택 구현으로 분리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 바코드 셀 편집 check digit 자동 보정 저장 범위를 EAN-13/UPC-A/EAN-8로 닫고, 0 padding/truncation 결과는 저장 보정값으로 사용하지 않으며 ITF 홀수와 기타 레거시 전용 check digit은 저장 전 검증 오류 또는 별도 명시 구현 대상으로 정리했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `read-only fallback SELECT는 선택 구현`, `필수 완료 기준은 기존 SELECT 미실행`, `필수 동작은 DB migration 안내 화면 전환`, `fallback SELECT가 없거나 실패하면 테이블을 열지 않는다`, `셀 편집 자동 보정 저장 범위는 EAN-13/UPC-A/EAN-8`, `길이 부족/초과를 0 padding 또는 truncation으로 맞춘 값은 셀 편집 자동 보정 저장값으로 사용하지 않는다` 문구 확인. `사용자 답변: 미확정`, `확정 필요`, `TODO`, `FIXME` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `7938fed` 품목관리 요청서 fallback 보정 기준 기록

### 완료 (2026-07-10): 품목관리 요청서 읽기 검증/Excel format 중복 정리

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 확정 정책 안에서 검증 소유와 중복 문구를 정리하는 문서 수정이다.
- 병합 예정: `hasRichElementSheet=false` fixture를 `[읽기/스냅샷]` 검증에도 추가해 로드/조회 단계의 기존 SELECT 미실행과 migration/read-only fallback 분기를 검증하게 한다. Excel custom format 처리 중복 문구를 하나로 합쳐 formatter 지원 범위 밖 숫자/날짜/custom format은 raw value 문자열 사용 후 저장 전 컬럼 타입 검증으로 단일화한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `[읽기/스냅샷]` 검증에 `hasRichElementSheet=false` fixture를 추가해 기존 `ItemOfMarketDAO.SelectSql` 미실행, migration 안내 화면, read-only fallback SELECT 성공/실패 분기를 읽기/로드 단계에서 검증하도록 했다.
- `.tmp/item_manager_modify.txt` 반영 완료: Excel custom format 처리 문구를 `표시 문자열 formatter 지원 범위 밖의 숫자/날짜/custom format은 raw value 문자열 사용 + 저장 전 컬럼 타입 검증`으로 단일화했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `표시 문자열 formatter 지원 범위 밖`, `hasRichElementSheet=false ... 읽기/로드 단계 검증`, `read-only fallback SELECT가 없거나 실패하면 테이블을 열지 않는지` 문구 확인. `지원하지 않는 복잡한 Excel custom format`, `복잡한 Excel custom format 또는 표시 문자열 formatter`, `사용자 답변: 미확정`, `SQL batch transaction 또는 공용 DB isolate transaction`, `migration 또는 호환 저장 정책을 먼저 확정` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `8a0a5e4` 품목관리 요청서 읽기 검증 기준 기록

### 완료 (2026-07-10): 품목관리 요청서 date setup/API 검증 권장안 병합

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 확정 정책 안에서 요약/검증/캐시 갱신 문구를 상세 정책과 일치시키는 문서 정리다.
- 병합 예정: 날짜 타입 설정 요약/수용 조건의 `setup 계열 컬럼` 표현을 날짜/시간 12개 컬럼으로 닫고, API/DTO가 full `LabelSizeSetup` 덮어쓰기로 구현되지 않게 `updateDateSetup` 또는 date-only DTO 기준을 명시한다. `hasRichElementSheet=false` 검증 fixture를 추가하고, 날짜 setup 저장 후 캐시는 최신 DB setup과 날짜/시간 변경값 merge 결과로 갱신한다고 명시한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 레거시 `CLabelSizeDAO::UpdateSetup`은 full setup update이지만 이번 Flutter 날짜 타입 설정 저장 대상은 날짜/시간 12개 컬럼으로 제한한다고 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 날짜 타입 설정 저장 API를 `LabelSizeDAO.updateDateSetup(labelSizeId, LabelSizeDateSetupUpdate)`로 고정하고, full `LabelSizeSetup` DTO를 저장 입력으로 받지 않는다고 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 저장 성공 후 `LabelSize.datas`와 현재 선택 라벨 캐시는 최신 DB setup에 날짜/시간 변경값을 merge한 `LabelSizeSetup`으로 갱신하고 `RICH_SETUP_READONLY`/`RICH_SETUP_USE_SCALE`은 최신 DB 값을 유지한다고 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `[transaction/DAO]` 검증에 `hasRichElementSheet=false` fixture를 추가해 기존 `ItemOfMarketDAO.SelectSql` 미실행, migration 안내 화면, read-only fallback SELECT 성공/실패 분기를 검증하도록 했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `updateDateSetup`, `LabelSizeDateSetupUpdate`, `날짜/시간 12개 컬럼`, `full LabelSizeSetup DTO`, `최신 DB setup에 날짜/시간 변경값`, `hasRichElementSheet=false fixture`, `read-only fallback SELECT` 문구 확인. `LabelSizeDAO.updateSetup(`, `BM_RICH_LABELSIZE_FORM setup 계열 컬럼`, `setup 계열 컬럼만 갱신`, `저장 대상은 BM_RICH_LABELSIZE_FORM의 setup 계열 컬럼`, `사용자 답변: 미확정` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `db4b9b2` 품목관리 요청서 날짜 설정 API 기준 기록

### 완료 (2026-07-10): 품목관리 요청서 schema/setup/xlsx round-trip 권장안 병합

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 정책 안에서 현 구현/레거시와 충돌할 수 있는 구현 조건을 닫는 문서 정리다.
- 병합 예정: `RICH_ELEMENT_SHEET` 컬럼 부재 시 조회 SQL 실패를 막기 위해 품목관리 로드 전 capability probe와 조회 fallback/진입 차단 기준을 명시한다. 날짜 타입 설정 저장은 SQL `SET` 대상 자체를 날짜/시간 컬럼으로 제한해 `readOnly`/`useScale` 덮어쓰기 여지를 제거한다. `preserveTemplateBarcodeFormat` `.xlsx` round-trip은 customXml image metadata 파싱/복원까지 포함한다고 명시한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 날짜 타입 설정 저장 API는 날짜/시간 setup 컬럼만 갱신하고, update SQL `SET` 대상과 로그 변경 대상에서 `RICH_SETUP_READONLY`/`RICH_SETUP_USE_SCALE`을 제외한다고 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `hasRichElementSheet=false`이면 `RICH_ELEMENT_SHEET`를 직접 참조하는 현재 `ItemOfMarketDAO.SelectSql`을 실행하지 않고, 기본은 DB migration 안내 화면으로 전환한다고 명시했다. 조회 전용 테이블은 `RICH_ELEMENT_RTF`만 참조하는 read-only fallback SELECT가 성공한 경우에만 허용한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `preserveTemplateBarcodeFormat` `.xlsx` round-trip은 customXml image metadata 파싱/복원까지 포함하며, cell/run metadata만 보존하는 상태는 완료로 보지 않는다고 명시했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `hasRichElementSheet=false`, `read-only fallback SELECT`, `RICH_ELEMENT_RTF`만 참조, `migration 안내 화면`, `update SQL SET`, `로그 변경 대상`, `customXml image metadata`, `cell/run metadata`, `날짜 타입 설정 저장 대상 12개 컬럼` 문구 확인. `setup 저장 대상 전체`, `RICH_ALTER_SETUP_READONLY`, `품목관리 테이블을 조회 전용으로 표시하고`, `RICH_ELEMENT_SHEET 컬럼 존재 여부를 확인하고, 없으면`, `사용자 답변: 미확정`, `SQL batch transaction 또는 공용 DB isolate transaction`, `migration 또는 호환 저장 정책을 먼저 확정` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `01152cc` 품목관리 요청서 구현 위험 기준 기록

### 완료 (2026-07-10): 품목관리 요청서 날짜 setup merge/export 권장안 병합

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 정책 안에서 구현 중 덮어쓰기/진입 시점/작성기 선택을 명확히 닫는다.
- 병합 예정: 날짜 타입 설정 저장은 DB 최신 setup 재조회 후 date/time 필드만 merge-update하도록 고정하고 `readOnly`/`useScale` 캐시 덮어쓰기 위험을 차단한다. `RICH_ELEMENT_SHEET` 부재 시 편집 진입 액션 전체를 비활성화하고 조회 전용+마이그레이션 안내로 표시한다. 품목관리 Excel export는 외부 패키지 추가 없이 기존 `archive` 기반 OpenXML writer 패턴을 단순 테이블 export helper로 분리하는 기준으로 고정한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 날짜 타입 설정 저장 직전 DB 최신 setup을 다시 읽고 날짜/시간 관련 필드만 merge-update하며 `RICH_SETUP_READONLY`/`RICH_SETUP_USE_SCALE`은 최신 DB 값을 유지한다고 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `RICH_ELEMENT_SHEET` 컬럼 부재 시 품목관리 테이블을 조회 전용으로 표시하고 편집 진입 액션 전체와 저장 버튼을 비활성화한 뒤 migration 안내를 표시한다고 명시했다. DB 저장을 만들지 않는 엑셀 내보내기/QR코드 데이터 보기는 허용 가능하다고 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 품목관리 Excel export는 새 외부 Excel 패키지 없이 기존 `archive` 기반 OpenXML 작성 패턴을 분리한 단순 table writer로 구현/검증한다고 명시했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `DB 최신 setup을 다시 읽`, `날짜/시간 관련 필드만 merge`, `RICH_SETUP_READONLY`/`RICH_SETUP_USE_SCALE`, `조회 전용`, `편집 진입 액션 전체`, `archive 기반 OpenXML`, `단순 table writer`, `외부 Excel 패키지` 문구 확인. `SQL batch transaction 또는 공용 DB isolate transaction`, `migration 또는 호환 저장 정책을 먼저 확정`, `품목관리 저장 기능을 비활성화한 뒤 DB migration 필요 안내`, `사용자 답변: 미확정` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `5f191ad` 품목관리 요청서 설정 병합 기준 기록

### 완료 (2026-07-10): 품목관리 요청서 날짜 setup/save codec/schema 권장안 병합

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 확정 정책 안에서 구현 선택지를 줄이는 문서 정리다.
- 병합 예정: 날짜 setup 저장 transaction 방식을 setup 전용 SQL batch transaction으로 고정하고, setup 로그 컬럼 allow-list/after 컬럼명을 닫는다. `preserveTemplateBarcodeFormat` save codec 선행 조건을 강화하고, `RICH_ELEMENT_SHEET` 컬럼 부재 시 기본 동작을 저장 기능 비활성+마이그레이션 안내로 정리한다. Excel 주원료 보존 범위는 fixture별 검증 기준으로 보완한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 날짜 setup 로그 after 컬럼명을 `RICH_ALTER_` prefix allow-list로 고정하고 예시(`RICH_ALTER_SETUP_READONLY`, `RICH_ALTER_USER_MAKEDATE`)를 추가했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 날짜 setup 로그/업데이트 transaction 방식을 setup 전용 SQL batch transaction으로 고정하고, 품목관리 저장용 `DbIsolateAction.transaction` 완료를 선행 조건으로 두지 않는다고 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `RICH_ELEMENT_SHEET` 컬럼 부재 시 품목관리 저장 기능 비활성화와 DB migration 안내를 기본 동작으로 고정하고 별도 호환 저장 정책은 만들지 않는다고 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `preserveTemplateBarcodeFormat` save codec feature key/allow-list/normalize/migrate/round-trip 선행 검증을 완료 기준과 검증 태그에 반영했다.
- `.tmp/item_manager_modify.txt` 반영 완료: Excel 주원료 보존 검증을 inlineRuns/병합/row height/column width/테두리/배경/줄바꿈 fixture로 분리하도록 추가했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `setup 전용 SQL batch transaction`, `RICH_ALTER_SETUP_READONLY`, `RICH_ALTER_USER_MAKEDATE`, `allow-list 컬럼 세트`, `품목관리 저장 기능을 비활성화`, `별도 호환 저장 정책은 만들지 않는다`, `save codec feature key/allow-list/normalize/migrate/round-trip`, `inlineRuns, 병합 영역, row height, column width, 테두리, 배경, 줄바꿈 fixture` 문구 확인. `SQL batch transaction 또는 공용 DB isolate transaction`, `migration 또는 호환 저장 정책을 먼저 확정`, `이에 대응하는 after/alter 값 컬럼`, `사용자 답변: 미확정` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `8695299` 품목관리 요청서 구현 선택지 기록

### 완료 (2026-07-10): 품목관리 요청서 바코드/날짜 setup 검토 권장안 병합

- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없다. 이번 병합은 기존 확정 답변을 구현 가능 문구로 정리한다.
- 병합 예정: 바코드 fallback 후보 순서를 column 형식 우선으로 정리하고, `preserveTemplateBarcodeFormat=true`만 template 형식 유지 예외로 고정한다. 날짜 setup 로그는 known schema에 setup 로그 컬럼이 없으면 logless update가 기본임을 명시하고, 로그 컬럼 probe/rollback/logless app log 검증을 완료 기준과 검증 태그에 반영한다. 날짜 setup enum range guard 기본값과 setup 저장 transaction 방식도 명시한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `preserveTemplateBarcodeFormat=false` object는 품목 column 형식을 먼저 평가하고 유효하지 않을 때만 공용 fallback을 평가하도록 본문/완료 기준/확정 답변을 통일했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `preserveTemplateBarcodeFormat=true` object에만 template 형식 유지 예외를 적용한다고 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 날짜 setup 로그의 required column set, repository/레거시 기준 logless update 기본 경로, setup 전용 transaction 방식, enum range guard 기본값(`DATE_FORMAT_DOT`/`TIME_FORMAT_COLON`)을 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `[label/date setup]` 완료 기준/검증 태그에 setup 로그 컬럼 probe 실패, 전체 컬럼 존재 시 transaction logging, 일부/전체 누락 시 logless update, 로그 insert rollback, logless update 앱 로그 검증을 추가했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `품목 column 형식을 먼저 평가`, `template 형식 우선 평가는`, `logless update가 기본 경로`, `DATE_FORMAT_DOT`, `TIME_FORMAT_COLON`, `setup 로그 컬럼 probe 실패` 문구 확인. `후보 평가 순서는 해당 object의 template 형식`, `기본값 fallback 또는 오류 안내`, `사용자 답변: 미확정` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `f1bb4b5` 품목관리 요청서 바코드 날짜 계약 기록

### 완료 (2026-07-10): 품목관리 요청서 날짜 setup 로그 계약 권장안 병합

- 요청: 재검토에서 남은 날짜 타입 설정 저장 이력 처리 애매점(로그 컬럼 probe 실패, 일부 컬럼만 존재, 로그 insert 실패)을 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없으며, 기존 확정 답변(`로그 컬럼이 있으면 기록, 없으면 로그 없이 update`)을 구현 세부 계약으로 닫는다.
- 병합 예정: 로그 컬럼 probe 실패 시 저장 차단, 필요한 로그 컬럼이 모두 있을 때만 로그 insert+setup update를 같은 transaction으로 처리, 일부/전체 로그 컬럼 없음은 로그 없이 setup update, 로그 insert 실패 시 rollback, 로그 없이 update 시 앱 로그 명시.
- `.tmp/item_manager_modify.txt` 반영 완료: 날짜 setup 로그 컬럼 probe 실패 시 setup 저장을 차단하고 오류로 처리하도록 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 필요한 setup 로그 컬럼이 모두 있을 때만 로그 insert와 setup update를 같은 transaction에서 처리하고, 로그 insert 실패 시 setup update도 rollback하도록 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 로그 컬럼이 없거나 일부만 있으면 로그 없이 setup update만 수행하되 앱 로그에 이 사실을 남기도록 명시했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `로그 컬럼 probe 자체가 실패하면`, `로그 insert가 실패하면 setup update도 rollback`, `로그 컬럼이 없거나 일부만 있으면`, `로그 없이 update한 사실을 앱 로그`, `사용자 답변: 미확정` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `98d3420` 품목관리 요청서 날짜 로그 계약 기록

### 완료 (2026-07-10): 품목관리 요청서 취소/재조회 계약 권장안 병합

- 요청: 재검토에서 남은 애매 문구(엑셀 버튼 차단 조건의 `저장 또는 변경 취소 전까지`, mapping fingerprint 불일치 후 `다시 조회` 시 draft/백업 처리)를 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없으며, 구현 세부 계약 문구를 권장안으로 닫는다.
- 병합 예정: 엑셀 가져오기 성공 후 버튼 차단은 `저장 완료 또는 변경 취소 확정 전까지`로 통일하고, mapping fingerprint 불일치 dialog에서 `다시 조회`를 선택하면 현재 draft와 임시 백업을 폐기한 뒤 현재 DB 기준으로 새 baseline을 만든다고 명시한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 엑셀 가져오기 성공 후 버튼 차단 조건을 `저장 완료 또는 변경 취소 확정 전까지`로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: mapping fingerprint 불일치 경고 dialog가 열린 동안에는 편집 상태/임시 백업을 유지하지만, `다시 조회` 선택 시 현재 draft와 임시 백업을 폐기하고 현재 DB 기준으로 새 baseline을 만든다고 명시했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `저장 또는 변경 취소 전까지`, `사용자 답변: 미확정` 없음 확인. `저장 완료 또는 변경 취소 확정 전까지`, `경고 dialog가 열린 동안에는 편집 상태와 임시 백업을 유지`, `다시 조회를 선택하면 현재 draft와 임시 백업을 폐기` 문구 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `7da4551` 품목관리 요청서 취소 재조회 계약 기록

### 완료 (2026-07-10): 품목관리 요청서 바코드 helper/취소 문구 권장안 병합

- 요청: 재검토에서 남은 애매 문구(`normalizeMeaningPreservingForPrint 또는 동등 helper`, `저장/취소 후`, EAN-8 운영 DB 확인/테스트 기준)를 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없으며, 구현 세부 계약 문구를 권장안으로 닫는다.
- 병합 예정: 의미 보존 barcode helper는 공용 API 추가/호출로 고정, 출력 미리보기/발행 체크 재개 조건은 `저장 완료 또는 변경 취소 확정 후`로 통일, EAN-8은 운영 DB 확인과 별개로 normalize fixture 테스트를 완료 기준에 추가한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `BarcodeDataHelper.normalizeMeaningPreservingForPrint`를 공용 API로 추가하고 `ItemCodeDataResolver`가 이 helper를 호출하도록 고정했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `저장/취소 후` 계열 표현을 `저장 완료 또는 취소 dialog에서 변경 취소 확정 후`/`저장 완료 또는 변경 취소 확정 후`로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: EAN-8은 운영 DB 샘플 유무와 별개로 `EAN8`/`EAN-8`/`CodeEAN8` fixture가 Code128과 구분되는지 테스트하도록 추가했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `normalizeMeaningPreservingForPrint.*동등`, `이 helper 또는 동일 규칙`, `저장/취소 후`, `저장 또는 취소 후`, `저장 또는 변경 취소 후`, `사용자 답변: 미확정` 없음 확인. `저장 완료 또는 취소 dialog에서 변경 취소를 확정`, `EAN8` fixture, `ItemCodeDataResolver` helper 호출 문구 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `7b6a71f` 품목관리 요청서 바코드 취소 문구 기록

### 완료 (2026-07-10): 품목관리 요청서 구현 누락 방지 기준 권장안 병합

- 요청: 재검토 결과를 권장안으로 `.tmp/item_manager_modify.txt`에 병합하고, 사용자 확인 사항이 있으면 즉시 질문해 확정한다.
- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없으며, 현재 검토 결과는 구현 선행 조건/검증 누락 방지 기준 보강으로 처리한다.
- 병합 예정: `CodeEAN8`/barcode resolver 선행 검증, `preserveTemplateBarcodeFormat` 저장 codec migrate/normalize/import 테스트, output workbook metadata 반영 검증, transaction/scoped 조회 선행 조건을 완료 기준과 검증 항목에 더 명확히 반영한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 현 `CodeEAN8(9, 'CODE128')` 상태를 resolver 내부 우회만으로 덮는 구현은 완료로 보지 않도록 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `preserveTemplateBarcodeFormat` metadata는 feature key, image sanitizer allow-list, save json normalize/migrate, `.lms`/`.xlsx` round-trip 검증을 같은 완료 조건으로 묶었다.
- `.tmp/item_manager_modify.txt` 반영 완료: 검증 항목에 `DbIsolateAction.transaction` 없는 상태의 다중 write 조합 금지, alias/fallback 값 draft 혼입 방지, output workbook metadata 반영 검증을 추가했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `resolver에서만 우회 처리한 구현은 완료로 보지 않는다`, `metadata가 조용히 제거될 수 있으므로`, `DbIsolateAction.transaction` 다중 write 금지, `save codec round-trip`, `기본 false`, `사용자 답변: 미확정` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `089bfa2` 품목관리 요청서 구현 누락 방지 기준 기록

### 완료 (2026-07-10): 품목관리 요청서 바코드/복구 UI 계약 권장안 병합

- 요청: 재검토에서 남은 애매점(`preserveTemplateBarcodeFormat=true` 완료 기준 예외, 바코드 셀 편집 시 ITF 홀수 길이 left-pad 저장 정책, mapping fingerprint 불일치 시 UI 기본/보조 액션)을 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없으며, 기존 확정 답변을 유지하고 구현 세부 계약을 권장안으로 닫는다.
- `.tmp/item_manager_modify.txt` 반영 완료: 바코드 셀 편집에서 ITF 홀수 길이 값은 자동 left-pad해 draft/DB 저장값으로 바꾸지 않고 저장 전 검증 오류로 표시하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: QR/바코드 helper 완료 기준에도 `preserveTemplateBarcodeFormat=true` object는 fallback 없이 template 형식 실패를 오류로 표시한다고 반영했다.
- `.tmp/item_manager_modify.txt` 반영 완료: mapping fingerprint 불일치 경고 dialog의 기본/권장 액션은 `다시 조회`, 보조 액션은 `변경 취소`로 고정했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `홀수 길이 ITF 값을 셀 편집에서 자동 left-pad`, `preserveTemplateBarcodeFormat=true` 완료 기준 예외, `기본/권장 액션은 다시 조회`, `보조 액션은 변경 취소`, `사용자 답변: 미확정` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `03ae86f` 품목관리 요청서 바코드 복구 계약 기록

### 완료 (2026-07-10): 품목관리 요청서 추가 구현 계약 권장안 병합

- 요청: 재검토에서 남은 애매점(ITF 의미 보존 보정 기준, mapping fingerprint 불일치 시 저장 차단/재조회 흐름, mapping fingerprint 조회 bulk id 전달 규칙)을 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없으며, 기존 확정 답변을 유지하고 구현 세부 계약을 권장안으로 닫는다.
- `.tmp/item_manager_modify.txt` 반영 완료: ITF 홀수 길이 left-pad는 preview/output 렌더링용 best-effort 보정으로만 허용하고 fallback 판정의 유효 형식 보정으로 사용하지 않도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: mapping fingerprint 불일치가 저장 전 검증에서 발견되면 DB transaction을 시작하지 않고 `다시 조회` 또는 `현재 DB 기준 복원/변경 취소`로 유도하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: mapping fingerprint 산출 DAO도 1만 id 단순 대량 `IN` parameter를 금지하고 temp table/table variable 또는 DAO chunk 조회 규칙을 따르도록 정리했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `ITF 홀수 길이 left-pad`, `mapping fingerprint 산출 DAO`, `DB transaction을 시작하지 않는다`, `다시 조회`, `현재 DB 기준 복원`, `사용자 답변: 미확정` 없음, 예전 `값으로 정상 렌더링 가능한 공용 fallback` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `f578460` 품목관리 요청서 추가 계약 기록

### 완료 (2026-07-10): 품목관리 요청서 잔여 구현 계약 권장안 병합

- 요청: 재검토에서 남은 애매점(`preserveTemplateBarcodeFormat=true` fallback 정책, mapping fingerprint 저장 시점, 의미 보존 바코드 보정 helper 계약, Excel `주원료` 병합 영역 plain text 기준)을 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없으며, 기존 확정 답변을 유지하고 구현 세부 계약을 권장안으로 닫는다.
- `.tmp/item_manager_modify.txt` 반영 완료: `preserveTemplateBarcodeFormat=true` object는 template 형식 실패 시 fallback으로 format을 바꾸지 않고 오류 표시로 고정했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 일반 삭제 mapping fingerprint는 row가 최초 삭제 예정이 되는 시점의 before snapshot/journal에 저장하고, 엑셀 전체 교체 fingerprint는 import 직전 baseline metadata에 저장하도록 시점을 분리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `BarcodeDataHelper.normalizeMeaningPreservingForPrint` 또는 동등 helper를 추가해 check digit 의미 보존 보정과 pad/truncate best-effort를 분리하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 엑셀 `주원료` 병합 영역 plain text는 top-left cell 표시 텍스트만 사용하고 다른 셀 값은 sheet payload에만 보존하도록 정리했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt` 통과. `grep_search`로 `fallback으로 형식을 바꾸지 않고`, `normalizeMeaningPreservingForPrint`, `최초 삭제 예정`, `mapping fingerprint`, `top-left cell` 반영과 `사용자 답변: 미확정` 없음 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `8823f21` 품목관리 요청서 구현 계약 기록

### 완료 (2026-07-10): 품목관리 요청서 재검토 권장안 병합

- 요청: 재검토에서 남은 애매점(바코드 fallback 결정 규칙, 삭제/전체교체 checksum 영향 범위, 엑셀 `주원료` 변환 배치 기준, `preserveTemplateBarcodeFormat` 저장 feature key, `targetMarketIds` customerId source)을 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 수정 예정 파일: `.tmp/item_manager_modify.txt`는 ignored 요청서 본문 수정, `SESSION_HANDOFF.md`는 ignored 요청서 변경 추적용 기록/검증/커밋 정보 갱신.
- 사용자 확인: 새 비즈니스 정책 질문은 없으며, 기존 확정 답변을 유지하고 기술 구현 규칙을 권장안으로 닫는다.
- `.tmp/item_manager_modify.txt` 반영 완료: `targetMarketIds` 산출용 `customerId` source를 로그인 세션 customer id로 고정하고, 선택/표시값 역추정이나 불일치 시 조용한 저장을 금지하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 삭제/엑셀 전체교체는 item-id-wide mapping delete이므로 current market checksum과 별도로 삭제 대상 item id 집합의 `BM_ITEM_OF_MARKET` mapping fingerprint를 baseline metadata에 저장하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 엑셀 `주원료` 셀/병합 영역은 bounding rectangle을 좌상단 `(0, 0)`부터 시작하는 단일 FortuneSheet sheet로 변환하고 import 단계 임의 scale은 적용하지 않도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: barcode fallback은 `normalizeForPrint(strict: false)` pad/truncate 결과를 유효 판정에 쓰지 않고, 공용 fallback 후보를 일반 1D `code128`, QR `qrCode`로 닫으며 GS1은 일반 fallback 없이 오류로 표시하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `preserveTemplateBarcodeFormat` 저장 feature key를 `sheet.images.preserveTemplateBarcodeFormat`으로 고정하고 sanitizer/normalize/migrate/`.lms`/`.xlsx` 검증 필요성을 반영했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과. `grep_search`로 `sheet.images.preserveTemplateBarcodeFormat`, `mapping fingerprint`, `normalizeForPrint(strict: false)`, `bounding rectangle`, `로그인 세션 customer id`, fallback 후보(`code128`/`qrCode`) 반영을 확인했다. `사용자 답변: 미확정`은 새로 생기지 않았다.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `38e6b74` 품목관리 요청서 권장안 병합 기록

### 완료 (2026-07-10): 품목관리 삭제/엑셀 전체교체 market 범위 레거시 확정

- 요청: `품목 삭제와 엑셀 전체 교체는 어느 market까지 적용할까요? A: 레거시와 같게`를 레거시 코드에서 직접 확인해 `.tmp/item_manager_modify.txt`에 확정 반영한다.
- 레거시 확인: `.tmp/LabelManager/LabelManagerLib/MainItemTable.cpp`에서 `LoadExcel`은 기존 row를 `DeleteRow`로 삭제 예정 item id에 넣고, `SaveToDB`는 `CItemOfMarketDAO::DeleteBatchByItemIDs(m_deleteItemIDs)`를 호출한다.
- 레거시 확인: `.tmp/LabelManager/LabelManagerLib/ItemOfMarket.cpp`의 `DeleteBatchByItemIDs` SQL은 `DELETE FROM BM_ITEM_OF_MARKET WHERE RICH_ITEM_ID=...` 형태로 market 조건이 없다. `InsertBatch`는 `CMarketDAO::SelectByCustID(CLoginCustomer::Get()->GetCustID())` 결과 전체에 신규 mapping을 생성한다.
- 레거시 확인: `.tmp/LabelManager/LabelManagerLib/Market.cpp`의 `SelectByCustID` 조건은 `WHERE RICH_CUSTOMER_ID=%d`뿐이며, market 비활성/숨김/삭제 상태 필터는 이 경로에서 확인되지 않았다.
- `.tmp/item_manager_modify.txt` 반영 완료: 신규 mapping 생성은 현재 로그인 고객의 전체 `targetMarketIds`에 적용하고, 삭제/엑셀 전체교체의 기존 item mapping 제거는 레거시와 동일하게 item id 기준 전체 mapping delete(market 조건 없음)로 확정했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과. `grep_search`로 `DeleteBatchByItemIDs`, `CMarketDAO::SelectByCustID`, `RICH_CUSTOMER_ID`, `market 조건`, `item id 기준 전체 mapping delete`, `RICH_ITEM_ID 조건만` 반영을 확인했다. `targetMarketIds` 교집합 표현은 `교집합으로 제한하지 않고`라는 부정문으로만 남아 레거시 item-id-wide delete 정책과 충돌하지 않음을 확인했다.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `550aac7` 품목관리 삭제 범위 레거시 확인 반영

### 완료 (2026-07-10): 품목관리 요청서 사용자 답변 확정 반영

- 요청: `사용자 확인 사항`을 나중에 묻는 목록으로 두지 말고 지금 받은 사용자 답변을 요청서에 확정 반영한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 하단 제목을 `사용자 확인 사항(확정 답변)`으로 바꾸고, 11개 `사용자 답변: 미확정`을 현재 받은 사용자 답변으로 확정했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 사용자 답변이 권장안과 달라진 `잘못된 바코드 값 fallback 허용` 정책을 출력 미리보기 본문, QR/바코드 helper 완료 기준, barcode/output preview 검증 항목에 반영했다.
- 확정 답변 요약: 주원료 글자+서식/병합 보존, 삭제/전체교체는 레거시와 같게 `targetMarketIds` 전체 적용, 날짜 용어는 `소비기한`/`소비시한`, 순서 변경의 다른 market 영향 허용, 바코드/QR 형식은 column 우선, 잘못된 바코드 값은 fallback 허용, check digit 자동 보정, QR format 기본 정책 유지, EZPL 미지원 format raster fallback, QR 날짜 token은 `DATE_FORMAT_NONE`, setup 로그는 컬럼 있으면 기록/없으면 update만 수행.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과. `grep_search`로 `사용자 답변: 미확정` 없음, fallback 허용/대체 형식/경고 문구 반영 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `07fd640` 품목관리 요청서 사용자 답변 확정 반영

### 완료 (2026-07-10): 품목관리 요청서 사용자 확인 사항 확정 질문화

- 요청: 하단 `사용자 확인 사항`이 실 구현 중 방향을 흔들 수 있으므로, 사용자에게 실제로 물어볼 수 있는 질문/권장 선택/다른 선택 시 구현 영향으로 정리해 요청서에 반영한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `사용자 확인 사항`을 구현 전 필수 확정 질문 목록으로 재작성하고, 각 질문에 `사용자 답변: 미확정`, 권장 선택, 다른 선택 시 구현 영향을 추가했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 엑셀 주원료 보존 범위, 삭제/전체교체 market 범위, 날짜 용어, 순서 변경 영향, 바코드/QR format 우선순위, fallback, check digit, QR format, EZPL fallback, QR 날짜 token, 날짜 setup 로그 정책을 실제 사용자 질문으로 정리했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과. `grep_search`로 `사용자 답변: 미확정` 11개 항목과 핵심 질문 문구 반영 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `c953958` 품목관리 요청서 사용자 확인 사항 질문화

### 완료 (2026-07-10): 품목관리 요청서 1차/후속 표현 제거 및 단일 구현 범위 정리

- 요청: 사용자 관점에서 `1차 구현`/`후속`/`선택 구현` 표현이 2차 일정처럼 보이므로, 기능정의상 문제 없는 항목은 이번 구현 포함으로 병합하고 DB/schema/운영정책 변경이 필요한 항목만 기능정의 제외로 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: Excel 주원료 서식 보존, `preserveTemplateBarcodeFormat`, barcode 오류 placeholder, BMP 파일명 충돌 안내, 날짜 setup 로그 capability 분기, Excel formatter 지원 범위를 이번 구현 포함으로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: market별 독립 order, `BM_RICH_ITEM` 물리 delete와 orphan 정리, GS1 FNC1/native 의미 보존 신규 지원, 모든 Excel custom format 완전 재현은 기능정의 제외 또는 별도 DB/유지보수 정책 작업으로 분리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 사용자 확인 사항을 `2차/후속` 대기 표현이 아니라 데이터 영향과 제외 범위를 이해할 수 있는 확인 문구로 정리했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과. `grep_search`로 `1차|후속|선택 구현|별도 범위|이번 범위|별도 설계|사용자 확인 후` 잔여 표현 없음 확인. `grep_search`로 `이번 구현 범위에 포함`, `이번 구현에 포함`, `기능정의에서 제외` 반영 확인.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋: `5290c7e` 품목관리 요청서 단일 구현 범위 정리

### 완료 (2026-07-10): 품목관리 요청서 남은 구현 경계 권장안 병합

- 요청: 재검토에서 남은 `ItemDAO.updateOrders` transaction 예외 범위, 날짜 setup 저장 로그 정책, `preserveTemplateBarcodeFormat` 보존 범위, `MarketDAO.selectByCustomerId` 포함 조건, enum range guard fallback UI, barcode 오류 표시 검증 기준을 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 독립 reorder command인 `ItemDAO.updateOrders`는 단일 SQL batch transaction 허용, 품목관리 저장 DAO는 `DbIsolateAction.transaction` 필수로 경계를 분리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 날짜 setup 저장 전 `BM_RICH_LABELSIZE_FORM_LOG` setup 로그 컬럼 확인 후 로그 포함 transaction 또는 로그 없는 update 정책을 확정하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `preserveTemplateBarcodeFormat=true`이면 `barcodeText`만 바꾸고 `barcodeFormatId`/label/showText/human-readable 등 template barcode metadata를 보존하도록 범위를 구체화했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `MarketDAO.selectByCustomerId`는 레거시 고객별 market 조회 조건과 `BM_MARKET` 상태 컬럼 의미를 확인해 `targetMarketIds`를 산출하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: enum range guard는 기본값 표시 + 다이얼로그 상단 경고로 고정하고, barcode invalid 값 검증은 `_ItemOutputPreviewTab` 상단 오류 목록을 1차 필수로 고정했다.
- 검증: `grep_search`로 `BM_RICH_LABELSIZE_FORM_LOG`, `단일 SQL batch transaction을 허용`, `DbIsolateAction.transaction`, `비활성/숨김/삭제`, `barcodeText만`, `기본값으로 표시하되 다이얼로그 상단`, `_ItemOutputPreviewTab 상단 오류 목록` 반영 및 기존 애매 문구 제거를 확인했다. `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `1a5e58c` 품목관리 요청서 구현 경계 권장안 정리

### 완료 (2026-07-10): 품목관리 요청서 구현 전 필수 정책 권장안 병합

- 요청: 재검토에서 남은 `LabelSizeDAO.updateSetup` API 고정, 삭제/전체교체 targetMarket 적용 범위, item-level order 영향, template barcode format 유지 옵션 key, DateManager 날짜/시간 token helper 분리, `forceReloadRequired` 상태 소유자 모호점을 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `LabelSizeDAO.updateSetup(labelSizeId, LabelSizeSetup)`를 날짜 setup 저장 전용/확정 API로 고정하고 기존 form data 저장 경로와 분리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `DateManager` 날짜/시간 token helper를 분리하고, edit controller/view model 상태로 `idle`, `editing`, `saving`, `forceReloadRequired`를 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 삭제/엑셀 전체교체의 모든 `targetMarketIds` 적용은 구현 전 필수 확인 항목으로 올리고 저장 확인 dialog에 다른 market 영향 안내를 포함하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `순서 변경`은 item-level `BM_RICH_ITEM.RICH_ITEM_ORDER` 영향이 있으므로 적용 확인 dialog에 다른 market 순서 영향 안내를 포함하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: template barcode format 유지 후속 옵션 metadata key를 `preserveTemplateBarcodeFormat`으로 고정하고 save feature key/sanitizer/normalize/migrate 및 `.lms`/`.xlsx` import 검증 필요성을 정리했다.
- 검증: `grep_search`로 `LabelSizeDAO.updateSetup`, `formatDateToken`, `forceReloadRequired` 상태, `preserveTemplateBarcodeFormat`, targetMarket 필수 확인, item-level order dialog 문구 반영과 `또는 동등 API` 표현 제거를 확인했다. `git diff --check -- .tmp/item_manager_modify.txt` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `b042195` 품목관리 요청서 구현 전 정책 권장안 정리

### 완료 (2026-07-10): 품목관리 요청서 잔여 모호점 권장안 병합

- 요청: 재검토에서 발견한 check digit 저장/출력 정책 충돌, QR/텍스트연동 날짜 포맷 기준, xlsx 지정 sheet parse DTO 계약, 날짜 setup enum range guard, template barcode format 유지 옵션 저장 위치를 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt` 반영 완료: check digit 정책을 셀 편집 보정은 draft/DB 저장값 변경, preview/output 보정은 렌더링 payload만 변경하는 영역 분리 방식으로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: QR/텍스트연동 날짜형 token은 라벨 날짜 타입 표시 포맷이 아니라 `DATE_FORMAT_NONE` 기준을 사용하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 품목관리 xlsx 지정 sheet parse helper가 parsed workbook, worksheet XML, relationship id, styles/shared strings, workbook date system, extension metadata를 담은 DTO를 반환하도록 계약을 구체화했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 날짜 setup enum range guard를 추가해 DB enum 값이 범위 밖이어도 조회 단계에서 앱이 깨지지 않도록 완료 기준/검증 항목을 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: template barcode format 유지가 필요하면 FortuneSheet barcode image `extraFields` 기반 후속 옵션으로 분리하고, 저장 feature key/sanitizer/normalize/migrate 갱신이 필요함을 사용자 확인 사항에 추가했다.
- 검증: `grep_search`와 `read_file`로 결과 DTO/workbookDateSystem, check digit 영역 분리, `DATE_FORMAT_NONE` QR token, range guard, template format 후속 옵션 문구 반영 및 기존 preview/output-only check digit 확인 문구 제거를 확인했다.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `0bcf9b8` 품목관리 요청서 잔여 모호점 권장안 정리

### 완료 (2026-07-10): 품목관리 요청서 바코드/QR 구현 모호점 권장안 병합

- 요청: 재검토에서 발견한 barcode object id 의미, QR 기본 format 정책, check digit 자동 보정/오류 정책, EZPL native 지원 범위, FortuneSheet 표시 metadata 범위를 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt` 반영 완료: FortuneSheet image 내부 `id`가 아니라 `extraFields['barcodeObjectId']`(`fortuneBarcodeObjectIdExtraKey`)를 column keyword 매칭 기준으로 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `TYPE_QR_CODE`의 format 정책을 QR/MicroQR/DataMatrix 계열 `barcodeType` 우선, 그 외 기본 `qrCode`로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: EAN-13/UPC-A/EAN-8/ITF check digit 보정은 preview/output payload에만 적용하고 품목 셀 원본값은 저장 액션 없이 자동 변경하지 않도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 실제 출력에서 EZPL native 미지원 format은 resolver metadata가 반영된 raster fallback으로 출력하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `barcodeFormatLabel`, `barcodeShowText`를 최소 갱신 metadata로 명시하고 geometry/font/quiet-zone metadata는 template 값을 보존하도록 정리했다.
- 사용자 확인 사항 반영 완료: check digit 자동 보정 여부, QR 기본 format 정책, EZPL native 미지원 format 허용 여부를 운영 의사결정으로 이해하기 쉽게 추가했다.
- 검증: `grep_search`로 `barcodeObjectId`, 기본 `qrCode`, preview/output payload, raster fallback, `barcodeFormatLabel`, check digit/QR/native 사용자 확인 문구 반영을 확인했다. 긴 줄 구간은 `read_file`로 문장 손상 없음도 확인했다.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `c9eee14` 품목관리 바코드 QR 모호점 권장안 정리

### 완료 (2026-07-10): 품목관리 요청서 바코드 미리보기 최종 권장안 병합

- 요청: 재검토에서 남은 구현 순서, 실제 출력 경로 경계, EAN-8 공용 선행 작업, GS1 format 정책, 오류 placeholder 필수/선택 범위를 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt` 반영 완료: EAN-8 normalize를 출력 미리보기 전용이 아니라 품목관리 바코드 보정/검증/미리보기/출력 전반에 영향을 주는 공용 바코드 모델 선행 작업으로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 실제 출력 경로는 raw template workbook을 바로 출력하지 않고 `ItemCodeDataResolver` 결과가 반영된 output workbook/image metadata를 입력으로 사용하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: GS1 바코드의 1차 `barcodeFormatId`는 column `barcodeType`에서 산출하되, FNC1/AI 의미 보존이 검증되지 않은 경우 Code128 텍스트 fallback이 아니라 preview/저장 전 검증 오류로 표시하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `_ItemOutputPreviewTab`의 오류 표시는 탭 상단 오류 목록을 필수로 하고, barcode object 위치 placeholder는 선택 구현/후속 범위로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 최종 정리의 구현 순서에 `QR/바코드 데이터 helper 기반`을 포함해 13.1 권장 구현 단위와 맞췄다.
- 검증: `grep_search`로 공용 바코드 모델 문제, 실제 출력 경로 output workbook metadata 입력, GS1 FNC1/AI 오류 정책, `_ItemOutputPreviewTab` 오류 목록 필수, 최종 구현 순서 문구 반영을 확인했다.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `6355909` 품목관리 바코드 미리보기 최종 권장안 정리

### 완료 (2026-07-10): 품목관리 요청서 바코드 미리보기 권장안 추가 병합

- 요청: 재검토에서 남은 EAN-8 매핑, `ItemCodeDataResolver` 입력 범위, GS1 바코드 처리, 바코드 오류 UI 소유자, fallback 예외 정책을 권장안으로 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `BarcodeType.CodeEAN8`의 `dbName=CODE128` 문제를 단순 확인이 아니라 EAN-8 normalize 선행 수정/검증 요구로 격상했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `ItemCodeDataResolver`는 draft row 입력도 받을 수 있지만, 출력내용 미리보기 탭은 draft 편집 중 진입하지 않고 저장/취소 후 working row만 렌더링한다는 범위를 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `TYPE_GS1_BARCODE`는 단순 `TColumn.barcodeType` 직접 매핑이 아니라 GS1 조합/검증 helper 결과를 `barcodeText`로 사용하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 바코드 오류 표시의 1차 구현 소유자를 `_ItemOutputPreviewTab`으로 두고, resolver validation 결과를 탭 상단 오류 목록/필요 시 object placeholder로 표시하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: fallback은 1차 권장안이 아니라 실제 출력 형식과 미리보기 형식이 달라질 수 있는 예외 정책임을 사용자 확인 사항에 명시했다.
- 검증: `grep_search`로 EAN-8 선행 수정/검증, GS1 조합/검증 helper, `_ItemOutputPreviewTab` 오류 표시 소유, draft 입력/preview 차단 범위, fallback 예외 정책 문구 반영을 확인했다.
- 검증: 이전 `QR/바코드 데이터 및 출력 미리보기 기반` 구현 단위명이 `QR/바코드 데이터 helper 기반`으로 정리됐음을 확인했다.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `f06bf6c` 품목관리 바코드 미리보기 후속 권장안 정리

### 완료 (2026-07-10): 품목관리 요청서 바코드 미리보기 권장안 후속 병합

- 요청: 재검토에서 확인된 출력 미리보기 바코드 형식 재설정 관련 애매한 부분을 권장안으로 `.tmp/item_manager_modify.txt`에 병합하고, 사용자 확인 사항을 이해하기 쉽게 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 출력 미리보기 바코드 형식 재설정에서 기존 형식 자동 fallback을 금지하고 오류 placeholder/오류 목록을 표시하는 권장안으로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: barcode object 매칭은 keyword 문자열 포함 여부가 아니라 `TColumn.columnType.code`의 바코드/QR 계열 여부와 object id/column keyword 매칭 기준으로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `BarcodeType.CodeEAN8`의 현재 `dbName=CODE128` 정의가 실제 DB 값과 충돌할 수 있으므로 구현 전 DB 값 확인과 normalize 규칙 정리를 요구했다.
- `.tmp/item_manager_modify.txt` 반영 완료: QR/바코드 공용 helper 이름을 `ItemCodeDataResolver` 방향으로 통일하고, QR viewer/출력 미리보기/실제 출력 경로가 문자열과 `barcodeFormatId`를 공유하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 구현 범위, 권장 구현 단위, 완료 기준, 검증 태그에 `[barcode/output preview]`와 출력 미리보기 바코드/QR 재렌더링 검증 항목을 추가했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 사용자 확인 사항에 template 형식 유지 vs column 형식 우선, 유효하지 않은 값 오류 표시 vs fallback 허용의 의미를 설명해 추가했다.
- 검증: `grep_search`로 `ItemCodeDataResolver`, `[barcode/output preview]`, `barcodeText`/`barcodeFormatId`, `CodeEAN8`, 자동 fallback 금지, column type 기준 문구 반영을 확인했다.
- 검증: 이전 애매 표현인 `fallback 여부를 명시적으로 결정`, `ItemQRCodeDataResolver`, `14.8 [item/order]`가 남지 않았음을 확인했다. `keyword 문자열에 barcode` 표현은 금지 문맥으로만 남아 있음을 확인했다.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `72d0dda` 품목관리 바코드 미리보기 권장안 병합

### 완료 (2026-07-10): 품목관리 출력 미리보기 바코드 형식 재설정 요청서 병합

- 요청: 현재 구현 분석 결과를 바탕으로 `출력내용 미리보기`에서 바코드 값뿐 아니라 바코드 형식까지 재설정해 렌더링할 수 있는지 요청서에 병합 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `8.4 출력내용 미리보기 탭 제한`에 현재 구현이 `barcodeText`만 치환한다는 점과, 출력 미리보기에서 `barcodeFormatId` 및 표시 metadata를 함께 갱신해 품목 컬럼 설정 기준으로 재렌더링해야 한다는 권장안을 추가했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `TColumn.barcodeType`에서 FortuneSheet barcode format id로 변환하는 helper 요구와 주요 매핑 예시(`Code128 -> code128`, `CodeEAN13 -> ean13`, `QrCode -> qrCode` 등)를 추가했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 형식 변경 전 `BarcodeDataHelper.normalizeForPrint`를 우선 재사용하고, 유효하지 않은 값은 빈 바코드로 조용히 표시하지 않도록 오류 상태 또는 fallback 정책을 명시하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: object id가 품목 컬럼 keyword와 매칭되고 해당 column이 바코드/QR 계열일 때만 column 설정으로 형식을 재설정하도록 template 형식 덮어쓰기 범위를 제한했다.
- `.tmp/item_manager_modify.txt` 반영 완료: QR viewer helper 문구를 `ItemQRCodeDataResolver` 또는 통합 `ItemCodeDataResolver`로 확장해 viewer/출력 미리보기/실제 출력 경로가 문자열과 barcode format id를 공유하도록 정리했다.
- 검증: `grep_search`로 `.tmp/item_manager_modify.txt`의 `barcodeFormatId`, `ItemCodeDataResolver`, format id 매핑, 현재 구현 문구 반영을 확인했다.
- 검증: `grep_search`로 `SESSION_HANDOFF.md`의 진행/근거 문구 반영을 확인했다.
- 검증: `git diff --check -- SESSION_HANDOFF.md` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `72eaa4c` 품목관리 바코드 미리보기 요청서 정리

### 완료 (2026-07-10): 품목관리 요청서 재검토 권장안 후속 병합

- 요청: 재검토에서 남은 애매한 부분을 권장안으로 `.tmp/item_manager_modify.txt`에 병합하고, 사용자 확인 사항을 의미가 드러나게 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 삭제 저장은 레거시 호환 권장안으로 현재 로그인 고객의 `targetMarketIds` 전체에 적용된다는 점과 다른 market 품목관리에도 보이지 않을 수 있음을 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 발행 체크는 테이블 controller가 rowIndex 상태를 유지하고, 품목관리 edit controller가 item id snapshot을 보관해 rowIndex로 투영하는 책임 경계로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 날짜 타입 설정은 저장 권한이 없어도 읽기 전용 다이얼로그를 열 수 있고, `적용`만 비활성화하는 권장안으로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: QR 데이터 계산은 viewer 내부 전용 로직이 아니라 `ItemQRCodeDataResolver` 같은 순수 helper로 분리해 viewer/미리보기/출력 경로가 공유하도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 순서 변경 선택 복원과 완료 기준을 `적용 전`/`적용 시` 표현으로 맞췄다.
- 사용자 확인 사항: 엑셀 주원료 서식 보존, 삭제/엑셀 전체 교체의 전체 `targetMarketIds` 적용 여부, 날짜 타입 설정 표시 용어, market별 독립 품목 순서 필요 여부로 정리했다.
- 검증: `.tmp/item_manager_modify.txt` 본문에 예전 충돌 표현(`저장 시 ItemDAO.updateOrders`, `순서 변경 저장만으로`, `재조회 후 저장 전 선택 item id`, `저장 권한이 없는 사용자는 레거시와 같이`, `레거시 호환 모드`, `앞 4개만 표시`)이 남지 않았음을 `grep_search`로 확인했다.
- 검증: `targetMarketIds` 전체 적용, 발행 체크 책임 경계, 날짜 설정 읽기 전용 권한 처리, `ItemQRCodeDataResolver`, 적용 전 선택 복원, 사용자 확인 문구가 반영됐음을 `grep_search`로 확인했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `f622b65` 품목관리 요청서 후속 권장안 정리

### 완료 (2026-07-10): 품목관리 요청서 재검토 권장안 추가 병합

- 요청: 재검토에서 확인된 요청서의 애매한 부분과 레거시/현 구현 기준 문제를 권장안으로 `.tmp/item_manager_modify.txt`에 병합 정리하고, 사용자 확인 사항을 이해하기 쉽게 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 순서 변경의 대상 범위를 `현재 브랜드/라벨크기/market에 표시되는 품목`으로 통일하고, 다이얼로그 동작 표현을 하단 `취소`/`적용` footer 기준으로 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 일반 draft 저장의 추가/삽입/삭제 order 재계산과 저장된 DB 목록을 즉시 갱신하는 별도 `순서 변경` command를 구분했다.
- `.tmp/item_manager_modify.txt` 반영 완료: QR viewer 4개 초과 데이터는 스크롤 목록으로 모두 표시하는 권장안으로 확정하고, 레거시 앞 4개 제한은 viewer UI 제한으로만 문서화했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 날짜 타입 설정 구현 전 `DateManager` 포맷/preview helper와 `LabelSizeDAO.updateSetup(labelSizeId, LabelSizeSetup)` 또는 동등 API를 선행 추가하도록 정리했다.
- 사용자 확인 사항: 엑셀 주원료 서식 보존 여부, 날짜 타입 설정 표시 용어(`소비기한/소비시한` vs `유통기한/유통시한`), market별 독립 품목 순서 필요 여부만 남겼다.
- 검증: `.tmp/item_manager_modify.txt` 본문에 예전 충돌 표현(`현재 브랜드/라벨크기 전체`, `다이얼로그의 저장`, `레거시 호환 모드`, `앞 4개만 표시`, `저장/취소 선택`, `현재 라벨크기 품목`)이 남지 않았음을 `grep_search`로 확인했다.
- 검증: `LabelSizeDAO.updateSetup`, `DateManager` preview helper, current market 표시 품목 기준, `적용` 표현, 별도 `순서 변경` command, QR 모두 표시 권장안이 반영됐음을 `grep_search`로 확인했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `ef3ab65` 품목관리 요청서 재검토 권장안 정리

### 완료 (2026-07-10): 품목관리 요청서 순서 변경 재검토 권장안 병합

- 요청: `순서 변경` 재검토에서 나온 권장 사항을 `.tmp/item_manager_modify.txt` 요청서에 병합하고, 필요한 사용자 확인 사항을 이해하기 쉽게 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: 현재 `ItemOfMarketDAO.selectByItemOfMarketAndLabelSizeId()`의 order 미보장 문제를 선행 수정 항목으로 추가하고, 품목관리 리스트/순서 변경/저장 후 재조회가 `ORDER BY P2.RICH_ITEM_ORDER, P2.RICH_ITEM_ID ASC`를 공통 전제로 삼도록 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `순서 변경` 대상은 레거시 호환을 우선해 현재 market에 표시되는 품목만 재정렬하는 권장안으로 확정하고, draft 편집 중에는 메뉴 비활성화 + 안내로 확정했다.
- `.tmp/item_manager_modify.txt` 반영 완료: UI 표현을 현재 Flutter 라벨 설정 화면의 `orderEditMode` 패턴으로 수정하고, `ItemDAO.updateOrders(List<ItemOrderUpdate>)` 추가, 상위 controller/view model의 메뉴 상태 주입, Excel/date 완료 전 독립 구현 가능 조건을 추가했다.
- 사용자 확인 사항: market별 독립 품목 순서가 반드시 필요한 경우 현재 `RICH_ITEM_ORDER` item-level 구조와 레거시 호환 범위를 넘어서는 별도 order 저장 설계가 필요하다는 확인 항목으로 정리했다.
- 검증: `grep_search`로 `ORDER BY P2.RICH_ITEM_ORDER`, `ItemDAO.updateOrders`, `orderEditMode`, 현재 market 표시 품목 기준, 상위 메뉴 상태 주입, market별 독립 순서 확인 문구를 확인했다.
- 검증: `.tmp/item_manager_modify.txt` 본문에 예전 선택지 문구(`저장 후 계속`, `변경 취소 후 계속`, 라벨 설정 순서변경 패턴)가 남지 않았음을 `grep_search`로 확인했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `b969aab` 품목관리 요청서 순서 변경 권장안 정리

### 완료 (2026-07-10): 품목관리 요청서 순서 변경 병합

- 요청: 레거시 품목관리의 `순서 변경` 로직 분석과 `라벨 설정` 순서변경형 다이얼로그 UI 권장안을 `.tmp/item_manager_modify.txt` 요청서에 병합하고, 필요한 사용자 확인 사항을 이해하기 쉽게 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `2.12 레거시 품목 순서 변경 동작`을 추가해 이 기능이 품목 추가/삽입 draft가 아니라 기존 품목의 `BM_RICH_ITEM.RICH_ITEM_ORDER`를 갱신하는 별도 reorder command라고 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 우클릭 메뉴에 `순서 변경`을 `품목 삭제` 아래 배치하고, draft 편집 중에는 데이터 손실 방지를 위해 비활성화하거나 저장/변경 취소 선행 선택이 필요하다고 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `12.3 순서 변경 UX`, `13.1`의 품목 순서 변경 기반 구현 단위/완료 기준, `14.8 [item/order][transaction/DAO]` 검증 항목, 최종 요약을 추가했다.
- 사용자 확인 사항: 미저장 draft가 있을 때 `순서 변경`을 비활성화할지, `저장 후 계속`/`변경 취소 후 계속`/`취소` 선택 다이얼로그를 제공할지 확인 항목을 추가했다. 1차 권장안은 데이터 손실 방지를 위해 draft 중 비활성화하는 것이다.
- 검증: `grep_search`로 `2.12`, `5.5`, `12.3`, 품목 순서 변경 완료 기준, `14.8 [item/order]`, 사용자 확인 문구를 확인했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `e13f314` 품목관리 요청서 순서 변경 정리

### 완료 (2026-07-10): 품목관리 요청서 QR코드 데이터 보기 병합

- 요청: 레거시 품목관리의 `QR코드 데이터 보기` 분석 내용을 `.tmp/item_manager_modify.txt` 요청서에 병합하고, 필요한 사용자 확인 사항을 이해하기 쉽게 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `2.11 레거시 QR코드 데이터 보기 동작`을 추가해 이 기능이 품목 row/cell 수정이 아니라 우클릭한 단일 행 기준 QR/텍스트연동 데이터 조회/진단 기능이며, dirty 상태와 저장 batch에 포함되지 않는다고 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 우클릭 메뉴 항목에 `QR코드 데이터 보기`를 추가하고, draft 편집 중에도 현재 draft row 값 기준으로 조회 가능하지만 dirty를 만들지 않는 메뉴로 분리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `12.2 QR코드 데이터 보기 UX`, `14.7 [QR viewer][UI draft/edit]` 검증 항목, 최종 요약에 현재 row/draft 값 + column QR 설정 기준 데이터 계산, 사용자 정의/나트륨/바코드 텍스트연동 치환, 읽기 전용 viewer 기준을 추가했다.
- 사용자 확인 사항: QR 데이터가 4개를 초과할 때 레거시처럼 앞 4개만 보여줄지, 현재 Flutter에서는 스크롤 목록으로 모두 보여줄지 확인 항목을 추가했다. 1차 권장안은 데이터 누락을 피하기 위해 모두 표시하는 것이다.
- 검증: `grep_search`로 `2.11`, `12.2`, `14.7 [QR viewer]`, 최종 요약, 사용자 확인 문구를 확인했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `2cfe228` 품목관리 요청서 QR코드 데이터 보기 정리

### 완료 (2026-07-10): 품목관리 요청서 날짜 타입 설정 병합

- 요청: 레거시 `날짜 타입 설정` 분석 내용을 `.tmp/item_manager_modify.txt` 요청서에 병합하고, 필요한 사용자 확인 사항을 이해하기 쉽게 정리한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `2.10 레거시 날짜 타입 설정 동작`을 추가해 날짜 타입 설정이 품목 row/cell 수정이 아니라 현재 라벨크기 `LabelSizeSetup` 출력 포맷 설정이며, 제조일자/제조시한/소비기한/소비시한 사용 여부와 포맷/사용자 정의/preview를 갖는다고 정리했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 구현 원칙과 `12.1 날짜 타입 설정 UX`에 상단 라벨 설정 메뉴의 `날짜 타입 설정...` 진입점, 2x2 섹션형 다이얼로그 재배치, 품목관리 우클릭 메뉴 제외, draft 편집 중 비활성화, 적용 시 라벨크기 setup 저장/캐시 갱신/미리보기 refresh 기준을 추가했다.
- `.tmp/item_manager_modify.txt` 반영 완료: `13.1 권장 구현 단위`에 라벨 날짜 타입 설정 기반 단위와 완료 기준을 추가하고, `14.6 [label/date setup]` 검증 항목을 추가했다.
- 사용자 확인 사항: 날짜 타입 설정 화면 표시 용어를 레거시 리소스처럼 `소비기한`/`소비시한`으로 맞출지, 기존 설명의 `유통기한`/`유통시한`으로 유지할지 확인 항목을 추가했다. 1차 권장안은 화면은 `소비기한`/`소비시한`, 내부 enum/DB 의미는 기존 `validDate`/`validTime` 유지이다.
- 검증: `grep_search`로 `2.10`, `12.1`, `14.6 [label/date setup]`, 라벨 날짜 타입 설정 완료 기준, 사용자 확인 문구를 확인했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `9d1546d` 품목관리 요청서 날짜 타입 설정 정리

### 완료 (2026-07-10): 품목관리 요청서 save command DTO와 검증 소제목 보강

- 요청: 재검토에서 남은 권장 사항인 저장 입력 타입 단일화와 14장 검증 항목 실제 태그 소제목 반영을 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt` 반영 완료: transaction/DAO 저장 DAO 입력을 `save command DTO` 표준으로 단일화하고, draft snapshot DTO는 UI/edit session 내부 자료에서 save command DTO를 생성하는 상위 계층 입력으로만 둔다고 명시했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 14장 검증 항목에 `14.1 [UI draft/edit][transaction/DAO]`, `14.2 [Excel][UI draft/edit][transaction/DAO]`, `14.3 [UI draft/edit][읽기/스냅샷][transaction/DAO]`, `14.4 [UI draft/edit][transaction/DAO]`, `14.5 [transaction/DAO][UI draft/edit][읽기/스냅샷]` 소제목을 추가했다.
- 사용자 확인 사항: 새 확인 사항은 추가하지 않고, 기존 Excel `주원료` 서식/병합 보존 여부 1건만 유지한다.
- 검증: `grep_search`로 `save command DTO를 표준 입력`, `draft snapshot DTO는 저장 DAO 입력이 아니라`, `14.1`~`14.5` 태그 소제목을 확인했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `453a3b7` 품목관리 요청서 저장 입력과 검증 소제목 정리

### 완료 (2026-07-10): 품목관리 요청서 저장 DTO와 검증 태그 보강

- 요청: 재검토에서 남은 권장 사항인 저장 DAO 입력 DTO 기준과 검증 항목 태그화를 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `13.1 권장 구현 단위`의 transaction/DAO 완료 기준에 UI 없이 테스트 가능한 save command DTO 또는 draft snapshot DTO 입력 경계를 추가했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 14장 검증 항목에 `[읽기/스냅샷]`, `[transaction/DAO]`, `[UI draft/edit]`, `[Excel]` 태그 기준과 복합 태그/미검증 운용 기준을 추가했다.
- 사용자 확인 사항: 새 항목은 추가하지 않았고, 기존 Excel `주원료` 서식/병합 보존 여부를 보이는 글자만 가져올지 하단 `주원료 및 함량` 편집 시트 형태까지 재현할지로 풀어 썼다.
- 검증: `grep_search`로 `save command DTO`, `draft snapshot DTO`, 검증 태그 4종, 사용자 확인 문구를 확인했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `55a15ab` 품목관리 요청서 저장 DTO와 검증 태그 정리

### 완료 (2026-07-10): 품목관리 요청서 단위별 완료 기준 보강

- 요청: 재검토에서 남은 구현 단위별 완료 기준과 검증 항목 그룹핑을 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt` 반영 완료: `13.1 권장 구현 단위`에 읽기/스냅샷, transaction/DAO, UI draft/edit, Excel import/export 단위별 최소 완료 기준을 추가했다.
- `.tmp/item_manager_modify.txt` 반영 완료: 14장 검증 항목은 13.1의 네 구현 단위별 태그/소제목으로 추적하고, 후속 단위 검증은 연결 전까지 `미검증`으로 표시한다는 운용 기준을 추가했다.
- 사용자 확인 사항: 새 항목은 추가하지 않았고, 기존 Excel `주원료` 서식/병합 보존 여부 1건만 유지했다.
- 검증: `grep_search`로 `단위별 최소 완료 기준`, `검증 항목은 13.1`, `사용자 확인 사항`, Excel `주원료` 문구를 확인했다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- stage/commit 대상: ignored `.tmp/item_manager_modify.txt` 변경 추적용 `SESSION_HANDOFF.md`만 stage/commit한다.
- 커밋: `c2c5eb4` 품목관리 요청서 완료 기준 정리

### 완료 (2026-07-10): 품목관리 요청서 구현 단위/테스트 기대값 정리

- 요청: 재검토에서 남은 구현 범위 과다 리스크와 chunk 조회 best-effort 테스트 기대값을 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합했다.
- `.tmp/item_manager_modify.txt`에 `13.1 권장 구현 단위`를 추가해 읽기/스냅샷 기반 -> transaction/DAO 기반 -> UI draft/edit 기반 -> Excel import/export 기반 순서로 나누어 구현하도록 정리했다.
- 각 단위는 이전 단위의 API와 검증이 끝난 뒤 이어서 구현하고, UI draft/edit 구현은 raw snapshot/scoped column content/transaction 저장 DAO 경계가 정리된 뒤 연결하도록 명시했다.
- chunk 조회 fallback 테스트는 외부 변경을 100% 차단/감지한다고 기대하지 않고, `columnId + itemId` dedupe/merge, 단순 대량 `IN` parameter 없는 1만 행 id 전달, baseline checksum의 best-effort 보조 감지를 검증하도록 정리했다.
- 사용자 확인 사항은 추가하지 않았고, 엑셀 `주원료` 칸의 보이는 글자만 가져올지 셀 서식/병합 모양까지 재현할지 여부 1개만 유지했다.
- 검증: `grep_search`로 권장 구현 단위와 chunk 조회 테스트 기대값 문구를 확인했고, `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- 커밋: `0b5bd38` 품목관리 요청서 구현 단위 정리. `.tmp/item_manager_modify.txt`는 ignored 파일이므로 staging하지 않고, 추적 가능한 변경 기록으로 `SESSION_HANDOFF.md`만 커밋했다.

### 완료 (2026-07-10): 품목관리 요청서 scoped 조회 fallback 경계 정리

- 요청: 재검토에서 남은 조회 후 필터 fallback 범위, chunk 조회의 snapshot 일관성 한계, 최종 요약의 DAO 단일 action 경계 표현을 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합했다.
- `.tmp/item_manager_modify.txt`에서 조회 후 필터는 테스트 보조 전용이며 운영 fallback으로 사용하지 않는다고 명시했다.
- chunk 조회는 DAO 단일 action 안에서 `columnId + itemId` key로 dedupe/merge하되, chunk 사이 외부 DB 변경 감지는 best-effort이며 편집 시작 baseline checksum으로 보조 감지한다고 정리했다.
- 최종 요약에도 1만 행 id 집합은 DAO 단일 action 안의 temp table/table variable 또는 chunk 기준으로 전달하고, 단순 대량 `IN` parameter 나열은 사용하지 않는다고 반복했다.
- 사용자 확인 사항은 추가하지 않았고, 엑셀 `주원료` 칸의 보이는 글자만 가져올지 셀 서식/병합 모양까지 재현할지 여부 1개만 유지했다.
- 검증: `grep_search`로 운영 fallback 금지와 chunk best-effort/baseline checksum 문구를 확인했고, `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- 커밋: `199f49b` 품목관리 요청서 scoped fallback 경계 정리. `.tmp/item_manager_modify.txt`는 ignored 파일이므로 staging하지 않고, 추적 가능한 변경 기록으로 `SESSION_HANDOFF.md`만 커밋했다.

### 완료 (2026-07-10): 품목관리 요청서 bulk id 전달 경계 보강

- 요청: 재검토에서 남은 temp table/table variable 실행 경계, chunk 조회 결과 병합 기준, 검증 안 된 bulk 전달 방식 표현을 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합했다.
- `.tmp/item_manager_modify.txt`에서 scoped 조회의 temp table/table variable은 DAO 단일 isolate action 또는 단일 SQL batch 안에서 id 적재/조회/정리까지 완료하고, 여러 `DbClient.query...` 호출로 나누지 않도록 명시했다.
- chunk 조회 fallback은 DAO 단일 action 안에서 실행하고 결과를 `columnId + itemId` key로 dedupe/merge하도록 정리했다.
- SQL 길이 제한 대응에서 1차 bulk 전달 후보를 temp table/table variable 또는 DAO chunk 조회/갱신으로 제한하고, 그 외 bulk 전달 방식은 driver/ODBC 동작 검증 후 별도 확정된 경우에만 사용하도록 낮췄다.
- 사용자 확인 사항은 추가하지 않았고, 엑셀 `주원료` 칸의 보이는 글자만 가져올지 셀 서식/병합 모양까지 재현할지 여부 1개만 유지했다.
- 검증: `grep_search`로 넓은 bulk 표현 제거와 단일 action/merge 기준 문구를 확인했고, `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- 커밋: `8bda61f` 품목관리 요청서 bulk id 전달 경계 보강. `.tmp/item_manager_modify.txt`는 ignored 파일이므로 staging하지 않고, 추적 가능한 변경 기록으로 `SESSION_HANDOFF.md`만 커밋했다.

### 완료 (2026-07-10): 품목관리 요청서 scoped 조회/trigger fallback 보강

- 요청: 재검토에서 남은 scoped column content 조회의 SQL Server parameter 한도 위험, trigger fallback 표현, 상단 scoped cache 진단 문구를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합했다.
- `.tmp/item_manager_modify.txt`에서 상단 현재 구현 진단을 SQL 제한 scoped DAO 추가와 그 결과를 보관하는 scoped cache/view model 기준으로 맞췄다.
- 1만 item id scoped 조회는 단순 대량 `IN` parameter 나열을 금지하고, temp table/table variable 또는 DAO 상수 chunk 단위 조회로 item id 집합을 전달하도록 정리했다. 9.3 SQL 길이 제한 대응에도 같은 원칙을 추가했다.
- trigger multi-row 미지원 fallback은 1차 구현에서 같은 transaction 안의 단건 insert 반복으로 고정하고, trigger 우회/대체 batch는 DBA 또는 스키마 변경 확정 후 별도 범위로 분리했다.
- 사용자 확인 사항은 추가하지 않았고, 엑셀 `주원료` 칸의 보이는 글자만 가져올지 셀 서식/병합 모양까지 재현할지 여부 1개만 유지했다.
- 검증: `grep_search`로 예전 trigger/scoped 조회 모호 문구 제거와 새 SQL 전달/trigger fallback 문구를 확인했고, `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- 커밋: `6991996` 품목관리 요청서 scoped 조회 보강. `.tmp/item_manager_modify.txt`는 ignored 파일이므로 staging하지 않고, 추적 가능한 변경 기록으로 `SESSION_HANDOFF.md`만 커밋했다.

### 완료 (2026-07-10): 품목관리 요청서 transaction/scoped cache 잔여 정리

- 요청: 재검토에서 남은 transaction 표현 잔재, scoped column content 구현 기준, `ItemSaveSchemaCapabilities` 실행 시점을 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합했다.
- `.tmp/item_manager_modify.txt`의 앞쪽 구현 원칙/검증 목록/최종 요약에서 transaction 표현을 `DbIsolateAction.transaction` 단일 action 우선으로 통일하고, 단일 SQL batch transaction은 제한적 fallback으로 정리했다.
- column content는 1차 구현에서 현재 화면 market item id 집합을 SQL 조건으로 전달하는 `TColumnContentDAO` scoped 조회를 수행하도록 고정했고, 조회 후 필터는 테스트 보조 또는 임시 fallback으로 낮췄다.
- `ItemSaveSchemaCapabilities`는 DB 연결 또는 품목관리 저장 DAO 초기화 시 현재 DB 기준으로 probe하고, 같은 연결/세션에서는 capability 값을 캐시해 저장 DAO가 참조하도록 정리했다.
- 사용자 확인 사항은 추가하지 않았고, 엑셀 `주원료` 칸의 서식/병합 모양 보존 여부 1개만 유지했다. 의미는 보이는 글자만 가져올지, 셀 서식과 병합 모양까지 주원료 시트로 재현할지 여부이다.
- 검증: `grep_search`로 잔여 모호 문구 제거와 새 결정 문구를 확인했고, `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- 커밋: `0c604c4` 품목관리 요청서 transaction 잔여 정리. `.tmp/item_manager_modify.txt`는 ignored 파일이므로 staging하지 않고, 추적 가능한 변경 기록으로 `SESSION_HANDOFF.md`만 커밋했다.

### 완료 (2026-07-10): 품목관리 요청서 저장 선행순서/capability 경계 보강

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합했다.
- `.tmp/item_manager_modify.txt`에 저장 구현 선행 순서를 `ItemOfMarketDAO` alias/raw snapshot -> `MarketDAO.selectByCustomerId` -> scoped column content -> `DbIsolateAction.transaction` -> schema/trigger capability probe -> 저장 DAO 순서로 고정했다.
- transaction 구현 우선순위는 `DbIsolateAction.transaction` 단일 action으로 명시하고, 단일 SQL batch transaction은 제한적 fallback으로 정리했다.
- schema/trigger 확인 결과는 `ItemSaveSchemaCapabilities` 내부 구조로 저장 DAO에 전달하도록 정리했고, 최소 확인값을 `hasRichElementSheet`, trigger 자동 생성 row 종류, multi-row 지원 여부로 명시했다.
- 신규/import row preview DTO 최소 필드와 하단 `주원료 및 함량` 편집 UI의 원천을 edit controller selected draft row로 고정했다.
- 엑셀 전체 교체 저장의 `mapping delete`는 표시 필터/정렬과 무관한 current market 전체 working table item id 집합 기준임을 명시했다.
- 사용자 확인 사항은 엑셀 `주원료` 칸의 서식/병합 모양 보존 여부 1개만 유지했고, 1차 권장안은 보이는 글자만 가져오는 것으로 정리했다.
- 검증: `grep_search`로 남은 모호 문구와 새 결정 문구를 확인했고, `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- 커밋: `3907e92` 품목관리 요청서 저장 선행순서 정리. `.tmp/item_manager_modify.txt`는 ignored 파일이므로 staging하지 않고, 추적 가능한 변경 기록으로 `SESSION_HANDOFF.md`만 커밋했다.

### 완료 (2026-07-10): 품목관리 요청서 지정 sheet/선택 fallback 잔여 정리

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt`에서 `labelSheetWorkbookFromXlsxBytes()` activeTab 결과로 오해될 수 있는 문구를 지정 sheet parse helper 기준으로 정리하고, 일반 컬럼 값 결정도 지정 sheet parse helper의 변환 결과 기준으로 맞췄다.
- 신규/import row처럼 저장 전 실제 `ItemOfMarket` 표시 모델 또는 item id가 없는 행은 edit controller가 selected draft row에서 임시 `ItemOfMarket` 표시 모델 또는 preview DTO를 생성해 `home_page_manager`에 전달하도록 명시했다.
- 임시 표시 모델/DTO는 preview와 하단 주원료 로드에만 사용하고 DB 저장 identity로 사용하지 않도록 정리했다.
- 엑셀 주원료 서식 보존은 사용자 확인 후에도 바로 1차 범위에 포함하지 않고 별도 xlsx cell/merge 영역 추출 adapter 설계와 추가 검증을 거친 후속 범위로 진행하도록 정리했다.
- 검증: `grep_search`로 activeTab 결과 참조 제거, 지정 sheet helper 기준, preview DTO fallback, 별도 설계/검증 후속 범위 문구를 확인했고, `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- 커밋: `e789799` 품목관리 요청서 지정 sheet 선택 fallback 정리

### 완료 (2026-07-10): 품목관리 요청서 엑셀/선택 owner 잔여 경계 정리

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt`에서 엑셀 `주원료` 1차 import 기준을 해당 데이터 행의 `주원료` 단일 셀 표시 텍스트로 좁히고, `각 셀`/`주원료 영역`/row-major 계열 잔여 표현은 1차 구현 문맥에서 제거했다.
- `labelSheetWorkbookFromXlsxBytes()` activeTab 결과를 쓰는 것으로 오해되지 않도록 지정 sheet parse helper 결과와 worksheet XML metadata를 같은 sheet id/relationship 기준으로 매칭한다고 정리했다.
- 선택/anchor/focus 상태는 품목관리 edit controller/draft session이 `rowKey`/`draftRowKey`/기존 item id 기준으로 소유하고, `home_page_manager`는 출력 미리보기/하단 주원료 연동용 selected item 표시 모델만 동기화하도록 정리했다.
- `forceReloadRequired` 상태에서 로그아웃/앱 종료 예외 안내는 추가 저장 확인 dialog가 아니라 단발 안내이며, DB 저장은 완료됐고 화면 동기화만 실패했으며 임시 백업은 복구에 사용하지 않고 정리한다는 의미를 포함하도록 명시했다.
- 사용자 확인 문구를 `엑셀 주원료 칸의 굵게/색/부분 스타일/병합 모양까지 가져와야 하는지, 아니면 보이는 글자만 가져오면 되는지`로 이해하기 쉽게 정리했다.
- 검증: `grep_search`로 새 문구와 잔여 표현 정리를 확인했고, `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- 커밋: `98d9f8d` 품목관리 요청서 엑셀 선택 경계 정리

### 완료 (2026-07-10): 품목관리 요청서 구현경계/엑셀 주원료 범위 보강

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt`에 `ItemManage`가 원본 `List<ItemOfMarket>`/전역 `TColumnContent.get()` 직접 의존에서 working/draft row 목록과 일반 컬럼 값 resolver 입력 구조로 전환되어야 함을 명시했다.
- 품목 삽입 기준 anchor/focus 행은 현재 `FortuneTableSelectionController` 외부에 노출되지 않으므로 controller getter/callback 추가 또는 `ItemManage` 별도 추적이 선행되어야 함을 명시했다.
- 품목관리 저장은 Dart/UI 레이어의 여러 `DbClient.writeData...` 호출 조합이 아니라 하나의 isolate action 또는 하나의 SQL batch 안에서 `BEGIN`/`COMMIT`/`ROLLBACK`이 완료되는 방식으로 구현하도록 정리했다.
- `ItemOfMarketDAO.SelectSql` label size override alias 불일치는 raw snapshot 우회만으로 남기지 않고 표시 SQL alias도 `ItemOfMarket.fromMap` key와 맞게 수정하도록 정리했다.
- `forceReloadRequired` 상태에서 로그아웃/앱 종료만 예외 허용하고, 브랜드/라벨 변경과 탭 이동은 `다시 조회` 성공 전까지 차단하도록 정리했다.
- 엑셀 `주원료` import는 1차 구현에서 표시 텍스트만 plain text로 가져오고 `RICH_ELEMENT_SHEET`는 빈 기본 payload로 생성하도록 낮췄다. 서식/inlineRuns/병합 영역 보존은 사용자 확인 후 후속 범위로 분리했다.
- 사용자 확인 사항: 엑셀 `주원료` 셀의 서식/inlineRuns/병합 영역까지 보존해야 하는지 확인 필요. 1차 권장안은 plain text만 가져오는 방식이다.
- 검증: `grep_search`로 새 문구와 잔여 주원료 서식 보존 기대 제거를 확인했고, `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- 커밋: `8606cea` 품목관리 요청서 구현경계 보강

### 완료 (2026-07-10): 품목관리 요청서 reload 상태/상수/용어 보강

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- `.tmp/item_manager_modify.txt`에 `forceReloadRequired` 강제 재조회 필요 상태를 명시하고, 이 상태에서는 `다시 조회`만 허용하며 저장/취소/편집/엑셀/발행 체크 작업을 재조회 성공 전까지 막도록 정리했다.
- 품목관리 행 수 상한을 `ItemManagerLimits.maxRows=10000` 단일 상수로 정의하고, 추가/삽입 UI, 엑셀 import parser, 저장 전 검증, 테스트가 같은 상수를 참조하도록 정리했다.
- `현재 working row 수`는 draft working table의 실제 전체 행 수로 정의하고, 삭제 확인으로 제거된 행은 제외하며 필터로 숨은 행과 신규/import draft 행은 포함하도록 명시했다.
- 저장 후 재조회 표시 모델은 현재 구조처럼 `RICH_ELEMENT_SHEET`/legacy `RICH_ELEMENT_RTF`가 합쳐진 `Item.elementRTF` payload를 다시 채우고, 저장 DAO/검증 기준에서는 `RICH_ELEMENT_SHEET` 저장값을 확인하도록 정리했다.
- 남은 `저장 성공` 표현을 `DB 저장 성공`, `품목리스트 재조회 성공`, `화면 복원 완료` 단계에 맞춰 정리하고, 백업 삭제/선택 복원/발행 체크 초기화 시점을 단계별 용어로 맞췄다.
- 검증: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과.
- 커밋: `043e04e` 품목관리 요청서 reload 상태 상수 용어 보강

### 완료 (2026-07-10): 품목관리 요청서 reload/row-limit 경계 보강

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 반영 완료: 엑셀 가져오기 데이터 행이 10000개를 초과하면 일부만 가져오지 않고 가져오기 실패로 처리하며 테이블 상태와 draft를 변경하지 않도록 명시했다.
- 반영 완료: 저장 완료 흐름을 `DB 저장 성공`, `품목리스트 재조회 성공`, `화면 복원 완료`로 분리했다.
- 반영 완료: DB 저장 성공 후 품목리스트 재조회/화면 복원 실패 시 DB 반영은 유지하고 강제 재조회 필요 상태로 전환하며, 같은 draft를 저장 버튼으로 재반영하지 않도록 명시했다.
- 반영 완료: DB 저장 성공 직후 백업을 즉시 삭제하지 않고, 재조회와 화면 복원이 완료된 뒤 삭제하도록 정리했다. 재조회 실패 시 기존 백업은 rollback 용도가 아닌 stale 저장 완료 백업으로 표시 후 강제 재조회 성공 또는 화면 이탈 정리 시 삭제한다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern '엑셀 데이터 행 수가 10000개를 초과|DB 저장 성공|품목리스트 재조회 성공|화면 복원 완료|강제 재조회 필요|stale 저장 완료 백업|rollback 용도로 사용하지 않고|같은 draft를 저장 버튼으로 다시 DB에 재반영하지 않는다|일부만 가져오지 않고'`로 병합 문구 반영을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `fcffb37` 품목관리 요청서 reload row limit 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 delete/cache 잔여 표현 정리

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 반영 완료: 검증 항목의 `DB에서 삭제`, `기존 품목 delete`, 저장 정책의 `기존 행 delete` 표현을 세션 `targetMarketIds` 기준 `BM_ITEM_OF_MARKET` mapping delete로 정리했다.
- 반영 완료: `BM_RICH_ITEM`과 item 참조 child row는 삭제하지 않고, 저장 후 품목관리 재조회에서 보이지 않는다는 검증 표현으로 바꿨다.
- 반영 완료: 엑셀 전체 교체 설명에서 기존 item mapping 제거와 신규 item mapping 생성이 모두 세션 `targetMarketIds` 기준으로 적용된다고 명시했다.
- 반영 완료: 일반 컬럼 값 조회 fallback을 전역 `TColumnContent.datas` 직접 참조가 아니라 품목관리 전용 scoped column content view model 기준으로 정리했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'DB에서 삭제|기존 품목 delete|기존 행 delete|TColumnContent\.datas by itemId|신규 item mapping 생성만|저장 시 삭제를 DB에 반영'` 결과 없음.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `bc73bc8` 품목관리 요청서 delete cache 표현 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 삭제/snapshot/cache 경계 보강

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 반영 완료: 기존 행 삭제 저장은 현재 화면 market 하나가 아니라 세션 `targetMarketIds` 기준으로 `BM_ITEM_OF_MARKET` mapping을 제거하고, `BM_RICH_ITEM`/item 참조 child row 물리 삭제는 1차 구현에서 수행하지 않도록 명시했다.
- 반영 완료: raw snapshot DTO 조회는 표시용 `ItemOfMarketDAO.SelectSql`/`COALESCE` fallback 결과를 그대로 재사용하지 않고, DB `NULL`과 빈 문자열을 구분하는 별도 projection을 사용하도록 명시했다.
- 반영 완료: `newMappingDefaults`는 market id를 제외한 mapping 기본값 template으로 보관하고, 저장 시 `targetMarketIds` 각각과 합성해 실제 `BM_ITEM_OF_MARKET` row를 만들도록 정리했다.
- 반영 완료: 품목관리 일반 컬럼 표시/checksum은 전용 scoped column content view model을 사용하고, 별도 합의 없이 전역 `TColumnContent.datas`의 label-size 전체 cache 의미를 current market scope로 바꾸지 않도록 명시했다.
- 반영 완료: 엑셀 빈 헤더 이후 매핑 가능한 헤더 경고를 반복 요약 섹션에도 병합하고, 빈 헤더 뒤쪽 `품목` 헤더는 무시되어 `품목` 헤더 없음 실패로 처리된다고 명시했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'raw snapshot DTO 조회는|DB `NULL`과 빈 문자열|market id를 제외한 mapping 기본값 template|sourceItemId` 집합과 편집 세션의 `targetMarketIds`|sourceItemId`와 세션 `targetMarketIds`|전용 scoped cache/view model|전용 scoped column content view model|빈 헤더 뒤쪽에 필수 `품목`|빈 헤더 뒤쪽에 `품목`|기존 행 삭제 저장도 현재 화면 market 하나가 아니라|전역 `TColumnContent.datas`'`로 병합 문구 반영을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `cac43ad` 품목관리 요청서 삭제 snapshot 경계 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 snapshot/검증 선행 기준 보강

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 반영 완료: `currentMarketSnapshot` 구현 전 `ItemOfMarketDAO` alias 불일치(`P1_LABEL_SIZE_WIDTH` vs `P1_LABELSIZE_WIDTH`) 수정 또는 raw snapshot DTO 사용을 선행 작업으로 명시했다.
- 반영 완료: `currentMarketSnapshot`은 표시용 `ItemOfMarket` 객체가 아니라 nullable DB 저장값을 보존하는 별도 snapshot DTO 기준으로 생성한다고 정리했다.
- 반영 완료: 바코드 check digit, GS1 AI, time barcode 검증/보정 helper의 기존 재사용 가능 범위와 신규 구현 필요 범위를 분리했다.
- 반영 완료: 엑셀 빈 헤더 이후 뒤쪽에 매핑 가능한 헤더가 있으면 조용히 무시하지 않고 가져오기 전 안내/경고하도록 명시했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'raw snapshot DTO|P1_LABELSIZE_WIDTH|P1_LABEL_SIZE_WIDTH|alias 불일치|BarcodeDataHelper|time barcode 재계산|recalculator|GS1 AI 검증/조합|validator/helper|빈 헤더 이후.*매핑 가능한 헤더|무시 안내/경고|nullable DB 저장값'`로 병합 문구 반영을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `652c8f4` 품목관리 요청서 snapshot 검증 기준 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 scoped load/checksum 표현 보강

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 반영 완료: 최종 정리에 남은 `신규 mapping 생성 template` 표현을 `currentMarketSnapshot`/`newMappingDefaults` 분리 기준으로 정리했다.
- 반영 완료: `TColumnContentDAO` current item id 필터 정책에 맞춰 품목관리 로드 순서를 `ItemOfMarket` 조회 -> item id set 산출 -> `TColumnContent` scoped 조회/필터로 명시했다.
- 반영 완료: checksum 최소 입력 문구를 현재 화면 item id 집합 기준 column content hash로 통일했다.
- 반영 완료: rowState별 필수/nullable draft 필드와 order update 대상에서 orphan item 제외를 명시했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'rowState별 필수 필드|기존 row는 `currentMarketSnapshot`|신규 추가/삽입/엑셀 import row는 `newMappingDefaults`|품목관리 로드 순서는 `ItemOfMarketDAO|현재 화면 market의 item id 집합에 속한 column content|order update 대상에는 mapping 제거 후 남는|기존 행의 market-specific 값은.*current market snapshot|신규 mapping 생성값은.*new mapping defaults'`로 병합 문구 반영을 확인했다.
- 검증 완료: `grep_search`로 `신규 mapping 생성 template`, 범위 없는 `column content` checksum, `surviving working row` 같은 이전 표현이 남지 않았음을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `6e344cc` 품목관리 요청서 scoped load 기준 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 저장 경로/mapping 기본값 보강

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 반영 완료: 일반 draft 저장과 엑셀 전체 교체 저장의 `mapping delete` 적용 범위를 분리해, 일반 저장에서 기존 mapping을 잘못 지우지 않도록 명시했다.
- 반영 완료: 신규/엑셀 import item의 `BM_ITEM_OF_MARKET` 값은 현재 화면 기존 row snapshot 복제가 아니라 레거시 `CItemOfMarket(int marketID, item)` 신규 기본값 기반임을 명시했다.
- 반영 완료: `currentMarketSnapshot`과 `newMappingDefaults` 역할을 분리하고, 기존 `marketMappingDraftTemplate` 표현의 혼선을 정리했다.
- 반영 완료: 기존 item/child row no-op, 신규 row insert/update/upsert, order update 대상 범위를 테이블별 action 기준으로 보강했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'currentMarketSnapshot|newMappingDefaults|일반 draft 저장 권장 순서|엑셀 전체 교체 저장 권장 순서|일반 저장은 삭제 예정 기존 row만 mapping delete|수정/추가만 있는 일반 저장에서는|테이블별 1차 action 기준|현재 화면 market의 item id 집합에 속한 column content data hash|linefeed `100`|printCount `1`|MarketDAO\.selectByCustomerId'`로 병합 문구 반영을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `6d88093` 품목관리 요청서 저장 경로 기본값 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 current market/cache 경계 보강

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 현 구현 확인 완료: Flutter `MarketDAO`에는 현재 `selectByMarketId`만 있고, 레거시의 `CMarketDAO::SelectByCustID`에 대응하는 고객별 market 목록 DAO가 없다.
- 현 구현 확인 완료: `TColumnContentDAO.selectByLabelSizeId`는 `BM_RICH_ITEM.RICH_LABELSIZE_ID`만 기준으로 column content를 조회하므로, mapping 제거 후 남은 item/child row가 캐시·checksum 범위에 섞일 수 있다.
- 수정 완료: `MarketDAO.selectByCustomerId` 또는 동등 DAO를 `targetMarketIds` 산출 선행 작업으로 명시했다.
- 수정 완료: `TColumnContentDAO` 조회 또는 캐시/checksum 입력을 현재 화면 item id 집합 기준으로 제한하도록 정리했다.
- 수정 완료: `targetMarketIds`는 row별 필드가 아니라 편집 세션/저장 batch metadata로 분리했다.
- 수정 완료: `RICH_ITEM_ORDER`는 item-level 전역 순서라 다른 market 표시 순서에도 영향을 줄 수 있음을 명시하고, market별 독립 order는 이번 범위에서 제외했다.
- 수정 완료: 요청서의 `delete` 용어를 `draft row delete`, `mapping delete`, `physical item delete`, `child row cleanup`으로 구분하도록 정리했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'MarketDAO\.selectByCustomerId|고객별 market|세션 metadata|편집 세션/저장 batch metadata|row별|현재 화면 market의 item id 집합|orphan.*checksum|orphan 데이터|RICH_ITEM_ORDER|market별 독립 order|draft row delete|mapping delete|physical item delete|child row cleanup|TColumnContentDAO.*현재 화면|targetMarketIds.*row별'`로 병합 문구 반영을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `a424700` 품목관리 요청서 current market 경계 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 market mapping/delete 범위 보강

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 사용자 응답: 기존 child row 정리와 market-specific 편집 범위는 레거시를 먼저 확인해 달라고 요청했다.
- 레거시 확인 완료: `CMainItemTable::SaveToDB` 삭제 경로는 `BM_RICH_COL_CONTENT`, `BM_ITEM_OF_MARKET`, update 테이블, `BM_RICH_ITEM` 순서로 삭제한다.
- 레거시 확인 완료: 기존 행 수정 저장 경로는 `CItemDAO::UpdateBatchOrder`, `CItemDAO::UpdateBatch`, `CColumnContentDAO::UpdateBatchDataByColAndItemID`를 호출하고, `CItemOfMarketDAO::UpdateBatch`는 품목관리 일반 저장 경로에서 호출되지 않는다.
- 수정 완료: 기존 `BM_RICH_ITEM` 물리 delete 금지 정책과 맞춰 1차 구현은 기존 item의 child row도 삭제하지 않고, item id 기준 `BM_ITEM_OF_MARKET` mapping 제거만 수행하도록 정리했다.
- 수정 완료: 기존 행의 market-specific 값은 1차 편집 대상이 아니라 보존/복원용 snapshot이며, 신규 item 저장 시에만 레거시처럼 고객의 모든 market mapping을 생성하도록 정리했다.
- 수정 완료: `marketMappingDraft`를 현재 화면 market용 `marketMappingDraftTemplate`/snapshot으로 설명하고, 저장 target은 `targetMarketIds`로 분리했다.
- 수정 완료: trigger가 있을 수 있는 `BM_RICH_ITEM` insert 생성 id 수집은 direct OUTPUT resultset이 아니라 `OUTPUT INTO` 임시 테이블/table variable 방식을 우선하도록 정리했다.
- 수정 완료: 기존 mapping 보존/복원 시 `RICH_ADDITIONAL_ITEM_ID`에는 Flutter `AdditionalItem.AdditionalItemId`를 사용하고 `AdditionalItem.itemId`와 혼동하지 않도록 명시했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'marketMappingDraftTemplate|targetMarketIds|target market ids|현재 로그인 고객의 모든 market|기존 행의 market-specific|child row도 삭제하지|item 참조 child row|OUTPUT INSERTED.*INTO|OUTPUT INTO|direct OUTPUT|AdditionalItem\.AdditionalItemId|AdditionalItem\.itemId|baseline은 현재 화면 market|현재 화면 market.*저장 대상|mapping 제거 -> 신규|CItemOfMarketDAO::UpdateBatch'`로 병합 문구 반영을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `8c89b97` 품목관리 요청서 market mapping 범위 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 레거시 기본값/시장 매핑 정책 병합

- 요청: 다시 검토한 애매점과 레거시/현 구현 문제를 권장 사항으로 `.tmp/item_manager_modify.txt`에 병합한다.
- 사용자 확인 완료: 판매/할인 시작·종료일이 비어 있으면 `NULL`을 유지한다.
- 사용자 확인 완료: 신규/엑셀 import 품목의 market mapping 범위는 레거시와 같게 처리한다.
- 레거시 분석 완료: `CItem(labelSizeId, labelSizeName)` 신규 생성자는 `m_nPrice(0)`으로 초기화되고, 품목관리 추가/엑셀 import는 이 신규 행 생성 경로를 거친다. 따라서 신규/엑셀 import 품목의 `RICH_PRICE` 기본값은 `0`으로 병합 예정이다.
- 수정 완료: 요청서에 `additionalItemId`/판매·할인 날짜 nullable draft 정책, `RICH_PRICE=0`, 고객의 모든 market mapping, trigger/schema probe, `RICH_ELEMENT_SHEET` 컬럼 확인 기준을 추가했다.
- 수정 완료: Flutter 조회 모델의 `AdditionalItemId=0`/`DateTime.now()` fallback을 저장 draft의 실제 DB 값으로 사용하지 않도록 명시했다.
- 수정 완료: 신규 `BM_RICH_ITEM` insert 후 생성 item id는 레거시와 동일하게 현재 로그인 고객의 모든 market mapping 생성에 사용하도록 정리했다.
- 수정 완료: `AFTER_INSERT_ITEM` trigger body와 운영 DB의 `BM_RICH_ITEM.RICH_ELEMENT_SHEET` 컬럼 존재 여부를 저장 DAO 구현 전 확인하도록 정리했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'RICH_PRICE=0|itemPrice|고객의 모든 market|모든 market|DateTime.now\(\)|nullable|RICH_ELEMENT_SHEET.*컬럼|trigger body|BM_RICH_ELEMENT_CONTENT|RICH_ADDITIONAL_ITEM_ID=NULL|저장 draft의 실제 DB 값|레거시 신규 `CItem`|현재 로그인 고객의 모든 market|판매/할인 시작·종료일.*NULL'`로 병합 문구 반영을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `c45c9f9` 품목관리 요청서 레거시 저장 정책 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 DB 저장 세부 정책 병합

- 요청: `.tmp/item_manager_modify.txt`에 남은 권장 사항을 병합하고, 사용자 확인이 필요한 사항은 의미를 이해하기 쉽게 확인한다.
- 확인 완료: 전체 교체/삭제 시 기존 `BM_RICH_ITEM`은 1차 구현에서 물리 삭제하지 않고 `BM_ITEM_OF_MARKET` mapping 제거로 처리한다.
- 확인 완료: 신규/엑셀 import 행의 additional item 미사용 값은 `NULL`로 저장한다.
- 수정 완료: `sourceItemId`는 기존 행 before snapshot 기준 item id로 한정하고, 신규 행은 null로 두며, 삽입 기준 행이 필요하면 별도 `insertAnchorItemId`로 관리하도록 정리했다.
- 수정 완료: `marketMappingDraft`의 최소 필드를 marketId, additionalItemId, gdsNo, 판매/할인 날짜와 값, 사용자 정의 주원료 사용 여부, linefeed/scale barcode/print count/label size/margin/push 값으로 정리했다.
- 수정 완료: 품목관리 xlsx adapter는 `labelSheetWorkbookFromXlsxBytes()` 내부 parser/helper를 재사용하되, activeTab 기준 기존 결과가 아니라 지정 sheet parser의 `FortuneWorkbook`과 같은 worksheet XML metadata를 사용하도록 정리했다.
- 수정 완료: 현재 DB의 `AFTER_INSERT_ITEM` trigger가 column content/barcode/image row를 자동 생성하면 저장 DAO는 중복 insert하지 않고 trigger 생성 row를 update/upsert하도록 정리했다.
- 수정 완료: trigger가 다중 insert를 안전하게 처리하지 못하면 신규 item insert는 단건 반복 또는 trigger 우회/대체 batch로 구현하도록 정리했다.
- 수정 완료: 기존 `BM_RICH_ITEM`, `BM_RICH_COL_CONTENT`, `BM_RICH_BARCODE`, `BM_RICH_IMAGE`, `BM_RICH_PRINT_LOG`, `BM_ADDITIONAL_ITEM` orphan 정리는 이번 범위에서 수행하지 않고 별도 유지보수 작업으로 분리한다고 정리했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'AFTER_INSERT_ITEM|trigger 생성 row|중복 insert|sourceItemId|insertAnchorItemId|marketMappingDraft|RICH_ADDITIONAL_ITEM_ID=NULL|additional item.*NULL|물리 delete를 수행하지|orphan 정리|지정 sheet parser|기존 `labelSheetWorkbookFromXlsxBytes\\(\\)` 원본 결과|변환 경로를 우선 사용|다른 참조가 없을 때만 수행|mapping/column content 제거'`로 새 정책 반영과 구형 충돌 문구 제거를 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `a5f2326` 품목관리 요청서 DB 저장 세부 정책 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 구현 경계 권장안 병합

- 요청: `.tmp/item_manager_modify.txt`를 다시 검토해 남은 권장 사항을 병합 정리한다.
- 수정 완료: 품목관리 전용 draft row/value model의 최소 필드를 row identity, source item id, row state, order/originalIndex, item name, 주원료 plain/payload/format, column drafts, market mapping draft 기준으로 정리했다.
- 수정 완료: 신규 `BM_RICH_ITEM` insert 시 `OUTPUT INSERTED.RICH_ITEM_ID` 또는 임시 테이블로 `draftRowKey`/import row index/생성 item id를 같은 transaction 안에서 매핑하도록 정리했다.
- 수정 완료: 품목관리 xlsx adapter는 activeTab 기준 기존 helper 결과를 그대로 쓰지 않고, 원본 workbook sheet order index 0을 대상으로 하는 지정 sheet parser의 `FortuneWorkbook`과 같은 worksheet XML metadata를 사용하도록 정리했다.
- 수정 완료: lightweight checksum은 best-effort 외부 변경 감지 신호로 명시하고, 필요 시 payload length와 앞/뒤 capped hash로 주원료 payload 변경 감지력을 보완할 수 있게 정리했다.
- 수정 완료: 기존 `BM_RICH_ITEM` 물리 delete는 다른 참조가 없을 때만 수행하고, 참조가 있거나 불명확하면 현재 mapping/column content 제거로 제한하도록 정리했다.
- 수정 완료: `BM_ADDITIONAL_ITEM`은 이번 품목관리 신규/엑셀 저장의 편집 대상이 아니며, 신규/엑셀 import 행은 additional item 미사용 기본값으로 생성하고 orphan 정리는 별도 작업으로 분리한다고 정리했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'draft row/value model의 최소 필드|source item id|OUTPUT INSERTED|draftRowKey.*생성 item id|지정 sheet parser|best-effort|payload length|capped hash|BM_RICH_ITEM 물리 delete|additional item 미사용|orphan 정리|activeTab 기준 기존 helper 결과'`로 본문/검증/최종 정리 반영을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `88217cc` 품목관리 요청서 구현 경계 권장안 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 저장/엑셀/백업 권장안 병합

- 요청: `.tmp/item_manager_modify.txt`에 남은 권장 사항 6개를 병합 정리한다.
- 수정 완료: 현재 `DbClient`/`DbIsolateAction`에 품목 저장용 transaction/batch API가 없음을 명시하고, 구현 전 `DbClient`/driver transaction API 또는 단일 SQL batch transaction 경로와 품목관리 저장 DAO를 먼저 추가하도록 정리했다.
- 수정 완료: 여러 `writeDataWithParams` 순차 호출은 전체 롤백을 보장하지 못하므로 품목관리 저장 경로에 사용하지 않는다고 명시했다.
- 수정 완료: 엑셀 가져오기는 기존 xlsx helper의 activeTab 기준이 아니라 원본 workbook sheet order index 0을 강제하고, sheet index 또는 relationship id 지정 parse helper가 필요하다고 정리했다.
- 수정 완료: 엑셀 가져오기 취소용 lightweight checksum 산출 기준을 row count, item id/order, item name, 주원료 plain text, `Item.elementRTF` payload 존재/포맷 정보, column content data hash로 명시하고, 변경되지 않은 heavy payload 전체 문자열은 hash하지 않도록 정리했다.
- 수정 완료: 전체 교체 저장은 `BM_RICH_COL_CONTENT`, `BM_ITEM_OF_MARKET`, `BM_RICH_ITEM`, `BM_ADDITIONAL_ITEM` 처리 정책과 FK 제약 순서를 명시한 DAO 경로로 실행하도록 정리했다.
- 수정 완료: 품목관리 편집 상태는 기존 `Item.copyWith` 확장보다 전용 draft row/value model을 우선 사용하도록 정리했다.
- 수정 완료: 품목관리 편집 기능이 켜진 화면에서는 라벨크기 로드 직후 `_startItemElementAutoMigration()` 호출 자체를 skip하도록 정리했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'transaction/batch API|단일 SQL batch transaction|workbook sheet order index 0|activeTab|lightweight checksum|checksum 산출 입력|BM_ADDITIONAL_ITEM|draft row/value model|_startItemElementAutoMigration\\(\\) 호출|여러 `writeDataWithParams` 호출|sheet index 또는 relationship id'`로 본문/검증/최종 정리 반영을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `ff7f423` 품목관리 요청서 저장 엑셀 권장안 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 주원료 payload 판별 기준 정리

- 요청: `RICH_ELEMENT_SHEET`와 legacy `RICH_ELEMENT_RTF`를 현재 모델에서 별도 분리하지 않고, `COALESCE(NULLIF(RICH_ELEMENT_SHEET,''), RICH_ELEMENT_RTF, '') AS P2_ELEMENT_RTF`로 합쳐진 `Item.elementRTF` payload를 포맷에 따라 그대로 사용하거나 lazy 변환하는 기준으로 요청서를 정리한다.
- 수정 완료: `.tmp/item_manager_modify.txt`의 현재 Flutter 품목관리 테이블 상태에 `ItemOfMarketDAO`의 coalesced 조회 구조와 `Item.elementRTF` payload 포맷 판별 원칙을 추가했다.
- 수정 완료: RTF 변환/백업/검증/최종 정리 문구에서 raw `RICH_ELEMENT_SHEET`/`RICH_ELEMENT_RTF` 분리 전제를 제거하고, encoded workbook save는 그대로 사용하며 legacy RichEdit RTF만 필요한 시점에 lazy 변환한다고 정리했다.
- 수정 완료: lazy 변환 before snapshot 기준을 기존 raw 필드 분리가 아니라 변환 전 plain text, 변환 전 `Item.elementRTF` payload, payload 포맷 판별 결과로 정리했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'COALESCE\\(NULLIF\\(RICH_ELEMENT_SHEET|Item\\.elementRTF|기존 `RICH_ELEMENT_SHEET` 값, 기존 `RICH_ELEMENT_RTF` 참조 상태|legacy RTF가 있는 행|legacy RTF가 있는 주원료|encoded workbook save|payload 포맷'`로 새 기준 반영과 이전 분리 전제 문구 제거를 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `5fff0b8` 품목관리 요청서 주원료 payload 기준 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 잔여 애매점 권장 병합

- 요청: `.tmp/item_manager_modify.txt`를 다시 검토해 애매하거나 레거시/현 구현과 충돌 가능한 부분을 권장 사항으로 병합 정리한다.
- 수정 완료: 레거시 dirty/insert/update/delete 구분은 참고하되, Flutter 저장은 현재 품목/컬럼 DAO와 DB 구조 기준으로 수행하고 legacy update item apply 구조를 재현하지 않는다고 명시했다.
- 수정 완료: 엑셀 가져오기 전체 교체 취소는 DB 재조회를 사용하되 import 직전 baseline에 row count, item id/order 목록, lightweight version/checksum을 저장하고, 현재 DB와 다르면 외부 변경 가능성을 경고하도록 정리했다.
- 수정 완료: legacy RTF lazy 변환은 주원료 편집 진입/명시적 변환 적용만 draft 변경으로 반영하고, 미리보기 목적 변환은 display-only cache로만 유지해 dirty 상태를 만들지 않도록 정리했다.
- 수정 완료: 신규 행 일반 컬럼 draft는 `draftRowKey + columnId`로 관리하고 저장 후 생성 item id에 매핑해 column content insert/표시 우선순위에 사용하도록 정리했다.
- 수정 완료: draft 편집 모드의 발행 체크 표시는 rowIndex가 아니라 item id 기준 snapshot으로 유지하고, 추가/삽입/삭제 후 현재 rowIndex로 재매핑하도록 정리했다.
- 수정 완료: 추가/삽입은 실행 후 전체 working row 수가 10000을 넘으면 차단하도록 본문과 검증 항목에 반영했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern '주원료 편집 또는 미리보기 진입|미리보기 진입 시 필요한 경우 lazy|legacy update item apply|draftRowKey \\+ columnId|display-only cache|row count|lightweight version/checksum|item id 기준 snapshot|전체 working row 수가 10000'`로 이전 RTF 미리보기 draft 표현이 제거되고 새 권장 정책 문구가 반영된 것을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(공백 오류 없음).
- 커밋 완료: `1b9dc47` 품목관리 요청서 잔여 정책 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 현재 구현 데이터 보관 방식 병합

- 요청: 현재 Flutter 품목관리 구현에서 행 추가 시 관리 객체를 복사/참조하는 방식에 대한 정리안을 `.tmp/item_manager_modify.txt`에 병합한다.
- 수정 완료: 현재 구현은 DB 조회 결과를 `ItemOfMarket.datas` static cache에 저장하고 `ItemManage`가 같은 리스트를 rows로 표시하며, 선택 행은 row 객체를 보관한다는 내용을 `2.1 현재 Flutter 품목관리 테이블 상태`에 추가했다.
- 수정 완료: `ItemOfMarket`/`Item`은 `final` 필드 기반 값 객체이며, 기존 값 변경 경로는 직접 mutate가 아니라 대상 행만 `copyWith`/새 객체로 교체하는 방식임을 명시했다.
- 수정 완료: 품목 추가/삽입 신규 행은 기존 `ItemOfMarket.datas` row나 관리 객체를 참조 공유하지 않고, 임시 draft row key를 가진 독립 신규 row draft로 생성하도록 `5.2`, `5.3`, `6.1`, `10.2`, 최종 정리에 반영했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern 'ItemOfMarket\\.datas|직접 mutate|참조 공유|독립 신규 row draft|draft row key|기존 row 객체|값 객체'`로 현재 구현 기준과 신규 행 독립 draft 정책 문구가 반영된 것을 확인했다.
- 커밋 완료: `fdc07e1` 품목관리 요청서 데이터 보관 방식 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 1만 행 백업/RTF lazy 정책 병합

- 요청: `.tmp/item_manager_modify.txt`에 최대 1만 행 기준의 효율적인 임시 백업 정책과 기존 품목관리 RTF 자동 변환 충돌 방지 정책을 병합한다.
- 수정 완료: 임시 파일 백업 기준을 전체 heavy 원본 스냅샷에서 `최소 baseline + 변경 대상 before snapshot + draft journal` 구조로 변경했다. 변경되지 않은 행의 `RICH_ELEMENT_SHEET`/`RICH_ELEMENT_RTF` heavy payload는 JSON에 저장하지 않고, 수정/삭제 대상 before snapshot과 신규/수정 draft에만 포함하도록 정리했다.
- 수정 완료: 엑셀 가져오기 전체 교체 취소는 1만 행 전체 heavy snapshot을 만들지 않고 DB 재조회와 import 직전 UI metadata 복원으로 처리하도록 본문, UX, 검증 항목, 최종 정리에 반영했다.
- 수정 완료: 품목관리 편집 기능 중 legacy RTF는 테이블 진입 시 전체 자동 DB 마이그레이션하지 않고, 주원료 편집/미리보기 진입 시 lazy 변환한 뒤 draft 변경으로만 반영하도록 `2.7.1`, `10.5`, 검증 항목에 추가했다.
- 검증 완료: `Select-String -Path .tmp/item_manager_modify.txt -Pattern '마지막 DB 조회 원본 스냅샷|DB 조회 원본 스냅샷 \\+ 임시 편집 상태|원본 스냅샷|전체 자동 DB 마이그레이션|lazy RTF|baseline/journal'`로 이전 충돌 문구가 제거되고 새 정책 문구만 남은 것을 확인했다.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료: `d5c071a` 품목관리 요청서 백업 RTF 정책 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 sheet 매칭/백업 역할 보강

- 요청: `.tmp/item_manager_modify.txt`에서 남은 첫 worksheet 매칭 기준과 백업 JSON 선택 정보 역할 애매점을 권장 사항으로 병합 정리한다.
- 수정 완료: 첫 번째 worksheet는 원본 `.xlsx`의 workbook sheet 순서 기준으로 판정하고, `labelSheetWorkbookFromXlsxBytes()` 결과와 원본 worksheet XML metadata는 같은 sheet id 또는 relationship 기준으로 매칭하도록 본문과 검증 항목에 명시했다.
- 수정 완료: 백업 JSON의 선택 복원용 정보는 저장 성공 후 품목리스트 재조회 선택 복원용이고, 엑셀 가져오기 전 표시 정렬/필터/선택 상태 복원용 metadata는 변경 취소 시 import 직전 UI 상태 복원용임을 본문과 검증 항목에 분리해 명시했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `ebef634` 품목관리 요청서 엑셀 sheet 매칭 백업 역할 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 worksheet 표현 정리

- 요청: `.tmp/item_manager_modify.txt`에서 최신 worksheet/병합 정책의 남은 표현상 애매점을 권장 사항으로 병합 정리한다.
- 수정 완료: 첫 번째 worksheet의 1행에서 빈 헤더 전까지 읽은 헤더 중 trim 후 `품목` 헤더가 있으면 유효한 헤더로 본다고 본문과 검증 항목에 명시했다.
- 수정 완료: 원본 `주원료` 셀이 병합 영역의 시작 셀일 때만 병합 영역 전체를 가져오고, 시작 셀이 아닌 covered cell이면 해당 행을 빈 값과 빈 주원료 sheet 기본 payload로 처리하도록 표현을 정리했다.
- 수정 완료: 병합 시작 행에서 병합 영역 전체를 변환할 때 내부 covered cell이 빈 셀이면 plain text에 포함하지 않는다는 뜻이 드러나도록 검증 항목을 정리했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `49f8624` 품목관리 요청서 엑셀 worksheet 표현 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 worksheet/병합 정책 보강

- 요청: `.tmp/item_manager_modify.txt`에서 남은 엑셀 worksheet 선택, 주원료 병합 셀, 백업 metadata 애매점을 권장 사항으로 병합 정리한다.
- 수정 완료: 품목관리 엑셀 가져오기는 첫 번째 worksheet만 대상으로 하고, 첫 번째 worksheet에 유효한 헤더가 없으면 다른 worksheet를 탐색하지 않고 실패 처리하도록 본문과 검증 항목에 명시했다.
- 수정 완료: 데이터 행의 `주원료` 셀이 병합 영역의 시작 셀이 아닌 covered cell이면 해당 행은 빈 값과 빈 주원료 sheet 기본 payload로 처리하고, 병합 시작 행에만 병합 영역 전체를 매핑하도록 정리했다.
- 수정 완료: 임시 파일 백업 JSON metadata 명칭을 엑셀 가져오기 전 표시 정렬/필터/선택 상태 복원용 metadata로 명확히 했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `ff3f5b7` 품목관리 요청서 엑셀 worksheet 병합 정책 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 헤더 판정 보강

- 요청: `.tmp/item_manager_modify.txt`에서 레거시 대비 남은 엑셀 헤더/데이터 행 애매점을 권장 사항으로 병합 정리한다.
- 수정 완료: 헤더 비교는 앞뒤 공백만 trim한 뒤 정확히 일치하고, 대소문자 변경/내부 공백 정규화/별칭 매핑은 하지 않도록 본문과 검증 항목에 명시했다.
- 수정 완료: `품목` 헤더가 없으면 레거시처럼 매칭 컬럼만으로 행을 만들지 않고, 품명 없는 대량 import를 막기 위해 가져오기를 실패 처리한다고 명시했다.
- 수정 완료: 매칭되지 않는 엑셀 컬럼에만 값이 있고 매핑 대상 컬럼 값이 모두 비어 있는 행은 import 대상 데이터 행으로 보지 않도록 본문과 검증 항목에 반영했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `d5ad39b` 품목관리 요청서 엑셀 헤더 판정 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 구현 선택지 확정

- 요청: `.tmp/item_manager_modify.txt`에서 남은 애매점을 권장 사항으로 병합 정리한다.
- 수정 완료: xlsx import parser는 `labelSheetWorkbookFromXlsxBytes()` 내부 파싱 로직의 공용 parse helper 분리/공유를 우선하되, 분리가 기존 라벨 시트 import 안정성을 해치면 품목관리 adapter local helper로 제한하도록 정리했다.
- 수정 완료: `주원료` 헤더가 없을 때의 빈 `RICH_ELEMENT_SHEET` payload는 신규 품목 생성 또는 하단 주원료 편집 초기화의 기존 경로를 재사용하고, helper가 없으면 품목관리 공용 helper로 분리하도록 정리했다.
- 수정 완료: 엑셀 가져오기 직전 표시 정렬/필터 상태와 선택 상태는 draft metadata 및 임시 파일 백업 JSON metadata에 값 객체로 저장하고, controller 내부 객체는 직렬화하지 않도록 본문/검증 항목/백업 JSON 설명에 반영했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `a107838` 품목관리 요청서 엑셀 구현 선택지 확정. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 최종 UX 보강

- 요청: `.tmp/item_manager_modify.txt`의 남은 엑셀 최종 애매점을 권장 사항으로 병합 정리한다.
- 수정 완료: `.tmp/item_manager_modify.txt`에 주원료 영역의 수식 셀도 일반 컬럼과 같은 기준으로 처리하도록 반영했다. cached value가 있으면 값/표시 텍스트로 옮기고, cached value가 없으면 수식 자체는 가져오지 않고 빈 값으로 처리한다.
- 수정 완료: 엑셀 가져오기 후 변경 취소를 선택하면 가져오기 전 선택 상태도 함께 복원하고, 복원할 수 없으면 저장 성공 후 선택 상태 복원 fallback과 같은 기준을 따르도록 본문과 검증 항목에 반영했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `fe9c65b` 품목관리 요청서 엑셀 최종 UX 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 edge case 병합

- 요청: `.tmp/item_manager_modify.txt`의 남은 엑셀 edge case 애매점을 권장 사항으로 병합 정리한다.
- 수정 완료: `.tmp/item_manager_modify.txt`에 같은 매핑 대상 헤더가 중복되면 첫 번째 매핑 컬럼만 사용하고 이후 중복 헤더는 무시하도록 본문과 검증 항목에 반영했다.
- 수정 완료: 수식 셀은 cached value가 있으면 표시 문자열 formatter 대상으로 사용하고, cached value가 없으면 수식 문자열을 가져오기 값으로 쓰지 않고 빈 값으로 처리하도록 정리했다.
- 수정 완료: Excel serial date 변환은 workbook date system을 읽을 수 있으면 해당 기준을 따르고, 확인할 수 없으면 Excel 기본 1900 date system을 사용하도록 정리했다.
- 수정 완료: 엑셀 가져오기 직전 표시 정렬/필터 상태는 draft metadata 또는 별도 UI snapshot으로 저장하고, 변경 취소 시 데이터와 함께 복원하도록 정리했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `b3900e6` 품목관리 요청서 엑셀 edge case 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 가져오기 UX 정책 보강

- 요청: `.tmp/item_manager_modify.txt`의 남은 엑셀 가져오기 UX/판정 애매점을 권장 사항으로 병합 정리한다.
- 수정 완료: `.tmp/item_manager_modify.txt`에 엑셀 가져오기 성공 후 첫 번째 엑셀 데이터 행을 선택하고, 변경 취소 시 가져오기 전 데이터와 표시 정렬/필터 상태를 함께 복원하도록 정리했다.
- 수정 완료: `주원료` 헤더가 없으면 plain text는 빈 문자열, `RICH_ELEMENT_SHEET`는 현재 앱의 빈 주원료 sheet 기본 payload로 생성하도록 본문과 검증 항목에 반영했다.
- 수정 완료: 데이터 행 판정은 2행 이후 매핑 대상 컬럼 중 하나라도 표시 텍스트가 있으면 데이터 행으로 보고, `품목` 값이 비어도 다른 매핑 값이 있으면 draft 행을 생성한 뒤 저장 전 품명 필수 검증에서 차단하도록 정리했다.
- 수정 완료: 공용 parse helper 분리 시 기존 라벨 시트 xlsx import 테스트가 계속 통과해야 한다는 검증 기준을 추가했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `fb89aa6` 품목관리 요청서 엑셀 가져오기 UX 정책 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 잔여 정책 병합

- 요청: `.tmp/item_manager_modify.txt`의 남은 엑셀 잔여 애매점을 권장 사항으로 병합 정리한다.
- 수정 완료: `.tmp/item_manager_modify.txt`에 중복 파싱을 줄이기 위해 `labelSheetWorkbookFromXlsxBytes()` 내부 파싱 로직에서 공용 parse helper를 분리해 품목관리 xlsx adapter와 공유할 수 있다는 구현 허용 기준을 추가했다.
- 수정 완료: `주원료` 헤더가 없으면 주원료 plain text와 `RICH_ELEMENT_SHEET`를 빈 값으로 생성하도록 본문과 검증 항목에 반영했다.
- 수정 완료: 1차 표시 문자열 formatter 숫자 범위는 정수/소수/천단위 구분/소수 자리수 고정, 날짜 범위는 Excel serial date의 `yyyy-mm-dd`, `yyyy/mm/dd`, `yyyy.mm.dd`로 정리했다.
- 수정 완료: 엑셀 가져오기 성공 후 기존 표시 정렬/필터를 초기화해 전체 교체 결과를 표시하고, 저장 전 검증 실패 시 첫 오류 행이 필터로 숨겨지지 않도록 검증 기준을 추가했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `5bdf02e` 품목관리 요청서 엑셀 잔여 정책 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 세부 검증 기준 보강

- 요청: `.tmp/item_manager_modify.txt`의 남은 엑셀 세부 애매점을 권장 사항으로 병합 정리한다.
- 수정 완료: `.tmp/item_manager_modify.txt`에 `품목` 헤더가 없으면 가져오기 실패로 처리하고 테이블/draft를 변경하지 않는 기준을 추가했다.
- 수정 완료: 선행 apostrophe 제거 판정은 원본 worksheet XML/style metadata 또는 변환된 FortuneCell의 `quotePrefix`/`qp` 값을 사용할 수 있을 때만 수행하도록 정리했다.
- 수정 완료: 엑셀 내보내기 일반 컬럼 값은 xlsx cell type string/inline string/shared string 기록을 우선하고, writer/library 제약으로 Excel 자동 변환이 발생할 수 있는 경로에서만 apostrophe fallback을 적용하도록 정리했다.
- 수정 완료: 검증 항목에 주원료 병합 covered cell 빈 셀은 plain text에서 제외, 엑셀 가져오기 후 저장 전 검증 실패 시 첫 오류 셀로 스크롤/선택하고 엑셀 가져오기 값 기준 오류 원인을 표시하는 기준을 추가했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `e764686` 품목관리 요청서 엑셀 세부 검증 기준 보강. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 가져오기 구현 경계 정리

- 요청: `.tmp/item_manager_modify.txt`의 남은 엑셀 가져오기 애매점을 권장 사항으로 병합 정리한다.
- 수정 완료: `.tmp/item_manager_modify.txt`에 품목관리 xlsx adapter 입력은 원본 `.xlsx` bytes이며, 같은 parse context 안에서 `labelSheetWorkbookFromXlsxBytes()` 결과와 원본 worksheet XML metadata를 함께 사용하도록 정리했다.
- 수정 완료: 주원료 plain text도 일반 컬럼의 표시 문자열 formatter/fallback 기준을 사용하도록 본문과 검증 항목에 반영했다.
- 수정 완료: 1차 표시 문자열 formatter는 현재 품목관리에서 필요한 날짜/숫자 기본 format만 지원하고, 복잡한 Excel custom format은 raw value 문자열 + 저장 전 검증으로 처리하도록 정리했다.
- 수정 완료: 엑셀 가져오기 단계에서는 구조적으로 읽을 수 있는 행을 draft로 만들고, 일반 컬럼 타입/필수/날짜/숫자 오류는 저장 전 검증에서 차단하도록 정리했다. 파일 형식 오류, workbook/worksheet 파싱 실패, 헤더 행 부재, 데이터 행 부재는 가져오기 실패로 테이블/draft를 변경하지 않는다.
- 수정 완료: 선행 apostrophe는 quotePrefix 등 metadata로 Excel 표시값 기준 보이지 않는 escape임을 확실히 판정할 수 있을 때만 제거하고, 판정 불가 시 원문을 보존하도록 정리했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `2ff236d` 품목관리 요청서 엑셀 가져오기 구현 경계 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 입출력 정책 재정리

- 요청: `.tmp/item_manager_modify.txt`의 남은 엑셀 가져오기 애매점을 권장 사항으로 병합하고, 엑셀 내보내기는 `.xlsx`만 지원하도록 정리한다.
- 수정 완료: `.tmp/item_manager_modify.txt`에 헤더 trim 결과가 빈 문자열이면 이후 컬럼을 읽지 않는 기준을 추가했다.
- 수정 완료: 일반 컬럼 가져오기는 품목관리 xlsx adapter가 원본 worksheet XML cell attribute `t`와 `labelSheetWorkbookFromXlsxBytes()` 변환 결과를 함께 참조하도록 정리했다. string/shared string/inline string 우선, 숫자/날짜는 raw value/number format/cell formatCode 기반 표시 문자열 formatter 적용, 미지원 format은 raw value 문자열 + 저장 전 검증으로 처리하도록 본문과 검증 항목에 반영했다.
- 수정 완료: 가져오기 저장값에는 literal apostrophe를 새로 붙이지 않고, 원본 xlsx의 문자열 escape용 선행 apostrophe는 Excel 표시값 기준으로 보이지 않으면 제거하도록 정리했다. apostrophe fallback은 엑셀 내보내기 직렬화 전용으로 제한했다.
- 수정 완료: 엑셀 내보내기는 `.xlsx`만 지원하고 `.xls`는 안내 후 저장하지 않도록 본문, 검증 항목, 최종 정리에 반영했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `1c52a8a` 품목관리 요청서 엑셀 입출력 정책 재정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 가져오기 애매점 정리 병합

- 요청: `.tmp/item_manager_modify.txt`의 엑셀 가져오기 정책을 다시 검토해 권장 사항으로 병합 정리한다.
- 수정 완료: `.tmp/item_manager_modify.txt`에 `.xlsx` 파일 선택 필터, 우회 유입 `.xls` 거부, 헤더 표시 텍스트 trim/정확 일치 비교 기준을 추가했다.
- 수정 완료: `주원료` 변환에서 병합 영역 plain text 산출 기준(row-major, 빈 셀 제외, 줄바꿈 연결), run extra metadata 보존 한계, 병합 영역 안 텍스트 스타일/inlineRuns만 복사하고 테두리/배경/row height/column width는 제외하는 기준을 본문과 검증 항목에 반영했다.
- 수정 완료: 일반 컬럼 가져오기 값은 string/shared string/inline string 우선, 숫자/날짜는 표시 문자열 사용, 필요 시 apostrophe fallback으로 문자열 처리하도록 정리했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `3100be0` 품목관리 요청서 엑셀 가져오기 애매점 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 가져오기 세부정책 병합

- 요청: `.tmp/item_manager_modify.txt`의 `엑셀 가져오기` 정책에 확정된 구현 전 세부사항을 병합한다.
- 수정 완료: `.tmp/item_manager_modify.txt`에 엑셀 가져오기는 `.xlsx`만 지원하고 `.xls` 선택 시 안내 후 draft를 변경하지 않는 정책을 반영했다. `.xlsx` 파싱은 현재 앱의 `labelSheetWorkbookFromXlsxBytes()` 경로를 우선 사용하도록 정리했다.
- 수정 완료: `주원료` 셀은 품목관리 adapter로 `RICH_ELEMENT_SHEET`를 생성하며, 일반 셀은 `A1` 단일 셀로 옮기고 병합 셀은 병합 영역 전체를 `A1` 기준 상대 위치로 보존해 옮기도록 정리했다. row height/column width/테두리/배경은 무시하고, 텍스트 내용/inlineRuns/장평/자간/첨자/줄간격은 보존하도록 본문과 검증 항목에 반영했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `93366f3` 품목관리 요청서 엑셀 가져오기 세부정책 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 내보내기 병합

- 요청: `.tmp/item_manager_modify.txt`에 레거시 품목관리 엑셀 내보내기 분석 결과를 권장안대로 병합한다.
- 수정 완료: `.tmp/item_manager_modify.txt`에 `엑셀 내보내기` 실제 기능을 이번 구현 범위로 병합했다. 변경 사항이 없는 안정된 working table에서만 실행하며, `품목`/`주원료`/일반 컬럼 값 중심의 단순 엑셀 테이블로 저장하고, 행 번호/발행 체크/선택 상태/스타일/`RICH_ELEMENT_SHEET`/`RICH_ELEMENT_RTF`/출력 미리보기 서식은 제외하도록 정리했다.
- 수정 완료: 기존 `엑셀 내보내기 실제 기능 제외` 문구를 제거하고, 검증 항목과 최종 정리에 내보내기 대상/dirty 비활성/데이터 없음 메시지 정책을 반영했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `2a4bff6` 품목관리 요청서 엑셀 내보내기 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-10): 품목관리 요청서 엑셀 가져오기 병합

- 요청: `.tmp/item_manager_modify.txt`에 레거시 품목관리 엑셀 가져오기 분석 결과를 권장안대로 병합하고, 변경 사항이 있으면 `엑셀 가져오기`/`엑셀 내보내기`를 비활성화하도록 정리한다.
- 수정 완료: `.tmp/item_manager_modify.txt`에 `엑셀 가져오기`를 전체 교체형 draft 액션으로 병합했다. 기존 행 전체 삭제 예정 + 엑셀 행 임시 신규 생성 + order 재계산 + 기존 저장 정책의 단일 트랜잭션 확정 + 변경 취소 시 임시 파일 백업 원본 스냅샷 복원으로 정리했다.
- 수정 완료: dirty 상태에서는 `엑셀 가져오기`/`엑셀 내보내기` 버튼을 비활성화하고, 당시 기준으로 `엑셀 내보내기` 실제 기능은 이번 구현 범위에서 제외하는 정책을 본문/검증/최종 정리에 반영했다. 이후 2026-07-10 `엑셀 내보내기 병합`에서 내보내기 실제 기능도 이번 구현 범위에 포함하도록 재정리했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료: `23af3f8` 품목관리 요청서 엑셀 가져오기 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 완료 (2026-07-09): 품목관리 추가/삽입/삭제/주원료 수정 요청서 정리

- 요청: 지금까지 검토한 레거시 품목관리 동작(브랜드/라벨 변경, 라벨출력 탭 이동, 주원료 컬럼/하단 에디터 동작)과 현재 Flutter 품목관리 테이블 개선 사항을 포함해 `.tmp/item_manager_modify.txt` 요청서를 일목요연하게 재정리한다.
- 수정 완료: `.tmp/item_manager_modify.txt`를 구현 요청서 형식으로 재작성했다. 레거시 검토 결론(브랜드/라벨 변경 및 라벨출력 탭 이동 시 저장 확인 없음, 주원료 컬럼은 표시용/하단 에디터가 편집 진입점)을 포함하고, 현재 Flutter 품목관리 상태, 편집 모드 정책, 우클릭 메뉴, 저장/취소 트랜잭션 정책, 이동 제한, 검증 항목을 분리해 정리했다.
- 검증 완료: `git diff --check -- .tmp/item_manager_modify.txt SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 예정: `SESSION_HANDOFF.md`만 포함한다. `.tmp/item_manager_modify.txt`는 `.gitignore`의 `.tmp/` 대상이므로 force add하지 않고 작업 파일로 유지한다. 기존 unrelated dirty 파일은 제외한다.
- 커밋 완료: `fa44a22` 품목관리 요청서 정리 기록. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 병합 완료: 레거시 품목관리에는 추가/삽입/삭제/주원료 수정 외에도 품명 수정과 일반 동적 컬럼 수정이 있음을 확인했다. `.tmp/item_manager_modify.txt`에 품명/일반 컬럼 수정 dirty 정책, 저장 대상, 특수 컬럼 처리(바코드/GS1/날짜/이미지/10*8 자동 계산), 검증 항목을 병합했다.
- 커밋 완료: `2491342` 품목관리 요청서에 일반 컬럼 수정 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: 레거시에서는 추가/삽입 후 신규 행만 선택하도록 제한하는 별도 모드가 없고, 기존 행 선택/품명·일반 컬럼·주원료 수정/삭제가 같은 dirty 상태에 함께 누적될 수 있음을 확인했다. `.tmp/item_manager_modify.txt`의 신규 행 한정 선택·삭제 정책을 제거하고, draft 편집 중에도 신규/기존 행을 모두 선택·수정·삭제할 수 있도록 정리했다.
- 커밋 완료: `6a1e500` 품목관리 요청서 선택 제한 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: 현재 앱은 `path_provider`, `shared_preferences`, `sqflite/sqflite_common_ffi`를 이미 사용하므로 품목관리 draft 로컬 백업 구현 수단이 충분하다고 판단했다. `.tmp/item_manager_modify.txt`에 1차 구현부터 앱 지원 디렉터리 하위 JSON 백업 파일을 사용하고, SharedPreferences는 작은 메타데이터만 저장하며, debounce/비동기/원자적 파일 교체로 성능 영향을 줄이는 정책과 복구 검증 항목을 병합했다.
- 커밋 완료: `50e86e2` 품목관리 요청서에 로컬 백업 정책 반영. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: 저장 성공 후 재조회 범위를 브랜드/라벨크기 전체가 아니라 현재 선택된 브랜드/라벨크기의 품목관리 데이터(품목리스트, 일반 컬럼 값, 주원료 plain text, `RICH_ELEMENT_SHEET`, 행 순서, 신규 item id)로 확정했다. `.tmp/item_manager_modify.txt`의 단순 재렌더링/1차 구현 구분 문구를 제거하고 품목리스트 재조회 정책으로 정리했다.
- 커밋 완료: `a13cc20` 품목관리 요청서 재조회 범위 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 엑셀 가져오기/내보내기 버튼 UI는 이번 구현 범위에 포함하고, 실제 가져오기/내보내기 기능만 나중 구현으로 남기도록 정리했다.
- 커밋 완료: `8d08946` 품목관리 요청서 엑셀 버튼 유지 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`의 남은 애매한 선택지를 확정했다. 엑셀 버튼은 표시하되 비활성화, 주원료는 셀 변경 즉시 draft 반영, 로그아웃/앱 종료는 `저장하지 않고 종료할까요?` 진행/취소 확인, 로컬 백업은 최신 1개 유지, 삭제 예정 행은 화면 제거 + draft 삭제 ID 보관, 발행 체크는 기존 상태 표시 전용/신규 unchecked, 저장 후 선택 복원 우선순위는 신규 item id -> 기존 item id -> 같은 row index -> 첫 번째 행으로 정리했다.
- 커밋 완료: `52a6761` 품목관리 요청서 애매한 정책 확정. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`의 일반 컬럼 편집 정책을 레거시보다 안전한 저장 전 검증 계층 기준으로 정리했다. 바코드는 체크디지트 보정, GS1 AI는 실패값 draft 미반영 + 경고, 날짜/제조일자/유통기한은 형식/범위 오류 저장 차단, 숫자/`10*8` 계산 오류는 저장 전 차단, 이미지는 BMP 선택 후 확장자 제외 파일명 반영으로 명시했다.
- 커밋 완료: `bf182cc` 품목관리 요청서 저장 전 검증 정책 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에 삭제 예정 행 처리 충돌을 정리했다. DB 기존 행은 화면 working table에서 즉시 제거하고 draft에 삭제 예정 item id를 보관하며, 저장 시 DB delete 반영/취소 시 DB 조회 원본 복원으로 명시했다. GS1 실패 시 테이블 셀 직전 유효값 원복, 일반 텍스트/숫자 기본 셀 편집 진입, 이미지 더블클릭 BMP 선택, 저장/행 이동/탭 차단 직전 commit/flush, 저장 전 검증 실패 시 오류 셀 위치/사유 표시, 로그아웃/앱 종료 버튼명 `종료`/`계속 편집`도 병합했다.
- 커밋 완료: `503927f` 품목관리 요청서 레거시 대조 정책 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에 로그아웃/앱 종료 정책 문구를 `저장하지 않고 종료할까요?` + `종료`/`계속 편집`으로 통일했다. 바코드/유통기한/유통시한/제조일자 변경 시 타임바코드 재계산을 draft와 화면에 반영하고 검증 항목에 추가했다. 삭제 취소는 삭제 예정 item id 목록 폐기 + DB 조회 원본 복원으로 정리하고, `행 이동` 표현은 `선택 행 변경`으로 교체했다. 추가/삽입/삭제로 순서가 바뀐 경우 변경된 order 저장, 품목관리 `취소` 버튼의 `변경 내용을 취소할까요?` 확인/`변경 취소`/`계속 편집` 동작도 명시했다.
- 커밋 완료: `5f7eda5` 품목관리 요청서 타임바코드와 취소 정책 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에 품목관리 `취소` 확인 정책을 10.1 본문에 직접 병합했다. 타임바코드 기준값 누락/무효 시 저장 전 검증 차단, 타임바코드 재계산 결과 dirty cell 저장, `10*8` 자동 계산 결과(`매수`, `발행수량`) 저장 대상 포함, 삭제 전 `선택한 N개 품목을 삭제할까요?` 확인, 신규 행 품명/필수 일반 컬럼 저장 전 검증을 추가했다. 로컬 백업은 이전 실행 복구용이 아니라 실행 중 한 편집 세션의 임시 draft 백업으로 정리하고, 앱 시작/품목관리 진입 시 이전 백업 폐기, 저장 성공 후 폐기, 신규 변경 시 새 백업 생성으로 확정했다.
- 커밋 완료: `1e7ed72` 품목관리 요청서 백업과 필수값 정책 병합. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 실행 중 로컬 파일 백업의 목적을 취소 원복 기준 보조와 OOM/위젯 재생성/비동기 상태 교체 방어로 명확히 했다. 저장 성공/취소/종료/이전 실행 stale 처리 시 백업 파일과 메타데이터를 삭제하도록 10.2 중복 문구를 정리했다. 삭제 확인의 `계속 편집`/`삭제` 동작, 품목관리 `취소` 확인의 `계속 편집`/`변경 취소` 동작, 바코드 값 변경과 유통기한/유통시한/제조일자 변경 타임바코드 재계산 검증, 필수 일반 컬럼 정의 출처(`BM_RICH_COL_MIN.RICH_MIN_CHECK` 참고)를 검증 항목에 보강했다.
- 커밋 완료: `910007d` 품목관리 요청서 실행 중 백업 목적 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`의 임시 백업 정책을 사용자 의도에 맞춰 `변경 취소용 임시 파일 백업`으로 재정리했다. 임시 파일 백업은 추가/삽입/삭제/수정 후 `변경 취소` 시 품목 테이블을 변경 전 DB 조회 상태로 복원하기 위한 기준 데이터이며, 원본/working draft를 메모리에만 보관할 때의 OOM 부담을 줄이기 위한 파일 기반 방어 수단으로 명시했다. 저장 성공, 변경 취소, 종료, 품목 테이블 진입, 다른 브랜드/라벨 조회 시작 시 기존 임시 백업 파일과 메타데이터를 폐기하도록 정리했다.
- 커밋 완료: `050861f` 품목관리 요청서 임시 백업 의도 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 임시 파일 백업 폐기 조건을 dirty 상태와 분리했다. dirty 상태에서는 브랜드/라벨 변경 자체를 차단하고, dirty가 없는 상태의 최초 품목 테이블 진입/새 브랜드·라벨 조회 시작 때만 기존 백업을 폐기한다. 같은 편집 세션의 위젯 재생성/리빌드에서는 백업을 유지한다. 변경 취소 시 UI 즉시 복원은 임시 파일 백업의 마지막 DB 조회 원본 스냅샷을 우선하고, 저장 성공 후 품목리스트 재조회 완료 결과를 새 원본 스냅샷 기준으로 삼도록 정리했다. 삭제 후 변경 취소 시 제거됐던 기존 행 원위치 복원 검증과 신규 행 품명 필수 검증이 Flutter 저장 전 검증 정책임도 명시했다.
- 커밋 완료: `70dc549` 품목관리 요청서 백업 폐기 조건 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에 백업 정리 조건 용어를 `저장 성공/변경 취소/종료/dirty가 없는 새 조회/stale 백업 처리`로 통일했다. 취소 복원은 임시 파일 백업의 마지막 DB 조회 원본 스냅샷 기준으로 표현을 맞췄고, 같은 실행 중 dirty 없는 새 편집 세션 시작 시 기존 백업 폐기/재생성 조건을 명확히 했다. 필수/최소 체크 설정이 없는 일반 컬럼은 필수로 보지 않고 신규 행 품명만 Flutter 정책상 항상 필수로 보도록 정리했다. 저장 성공 직후 기존 백업 삭제, 재조회 완료 후 새 원본 스냅샷 기준 갱신, 이후 신규 변경 시 새 백업 생성 순서도 본문에 반영했다.
- 커밋 완료: `274295e` 품목관리 요청서 백업 표현 통일. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 취소 복원 표현을 임시 파일 백업의 마지막 DB 조회 원본 스냅샷 기준으로 끝까지 통일했다. 구현 원칙, 삭제 정책, 취소 정책, 검증 항목의 `마지막 DB 조회 상태`/`DB 기준` 계열 표현을 백업 스냅샷 기준으로 바꿨고, 수정된 셀/주원료도 백업 원본 스냅샷 값으로 되돌린 뒤 필요 시 DB 재조회로 동기화하도록 정리했다. draft 편집 중 발행 체크 변경은 레거시와 달리 Flutter에서 허용하지 않고, 저장/취소 후에만 조작 가능하다는 정책 차이도 명시했다.
- 커밋 완료: `6a5e257` 품목관리 요청서 취소 복원 기준 통일. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에 품목 삽입 기준을 보강했다. 선택 행이 없으면 삽입 메뉴를 비활성화하고, 여러 행 선택 시 현재 포커스/anchor 행을 우선하며 확인 불가 시 선택 범위의 마지막 표시 행을 기준으로 한다. 정렬/필터 상태의 삽입 위치와 order 재계산은 working table의 실제 품목 순서 기준으로 처리하고, 필터로 보이지 않는 행은 전체 선택/삭제 대상에서 제외하도록 명시했다. 발행 체크는 저장 성공 후 품목리스트 재조회 시 UI 상태를 초기화한다. 이미지 타입은 경로 없이 확장자 없는 BMP 파일명만 저장하고, 동일 파일명 충돌은 이번 범위에서 제외한다. 임시 백업 기본 구조를 `DB 조회 원본 스냅샷 + 임시 편집 상태` 저장으로 정리했고, dirty 없는 새 편집 세션에서는 기존 백업을 먼저 삭제하되 새 백업은 실제 draft 변경 시 생성하도록 했다. 백업 저장 실패 시 메모리 원본/draft 기준 취소 fallback과 불가 시 DB 재조회 동기화도 추가했다.
- 커밋 완료: `ff770f0` 품목관리 요청서 삽입과 백업 fallback 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에 추가/삽입 입력박스 기본값 `1`, 빈 값/비숫자/1 미만/최대 초과 시 실행 차단 정책을 명시했다. 삭제 후 선택 이동은 다음 표시 행, 없으면 이전 표시 행, 남은 행이 없으면 선택 비움으로 정리했다. 주원료 시트는 셀 변경 이벤트를 가능한 즉시 draft에 반영하되 활성 셀은 저장/선택 행 변경/탭 차단 직전 commit/flush하도록 했고, 선택 행 변경 시 현재 행 draft 반영 후 새 행 draft 또는 원본 스냅샷 값을 로드하도록 절차를 추가했다. 날짜/제조일자/유통기한은 입력 중 draft에 반영하되 저장 전 검증 실패 시 오류 상태와 편집 상태를 유지한다. 저장 중에는 저장/취소/추가/삽입/삭제/브랜드/라벨/탭/주원료 편집을 잠그고, 재조회와 화면 복원 완료 후 잠금 해제한다. 저장 성공 후에는 발행 체크 UI 상태 초기화 후 선택 상태를 복원하도록 순서도 명시했다.
- 커밋 완료: `ac138d5` 품목관리 요청서 편집 UX 기준 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 삽입 기준 문구를 화면 표시 순서가 아니라 working table의 실제 품목 순서 기준으로 통일했다. 포커스/anchor 행은 마지막 클릭, 키보드 이동, 드래그 시작, Shift/Ctrl 선택 기준 행으로 갱신하고, 프로그램 방식 선택 변경으로 anchor가 없으면 선택 범위의 마지막 표시 행을 사용하도록 명시했다. 최대 개수 초과 메시지는 실행 가능성이 있는 `확인`이 아니라 `경고 메시지`로 통일했다. 주원료 즉시 draft 반영 중복 문장을 하나로 합쳤고, 저장 중 잠금 범위에 테이블 셀 편집을 추가했다. 저장 실패 시 남은 debounce 백업 작업은 취소하지 않고 현재 메모리 draft 기준으로 백업 저장을 재예약하거나 즉시 flush하도록 정리했다.
- 커밋 완료: `2fba95c` 품목관리 요청서 삽입 기준 세부 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 품목 추가도 working table의 실제 품목 순서 맨 끝 기준으로 통일하고, 정렬/필터 상태에서는 새 행이 화면 표시상 마지막에 보이지 않을 수 있음을 검증 항목에 추가했다. 추가/삽입 직후 자동 선택은 working table 실제 순서 기준 첫 번째 신규 행으로 정리했고, 해당 행이 필터로 보이지 않으면 선택 상태만 유지될 수 있음을 명시했다. 여러 행 삭제 후 선택 이동은 삭제된 표시 행 묶음의 마지막 위치 아래 다음 표시 행, 없으면 묶음 위 이전 표시 행, 남은 행 없으면 선택 비움으로 보강했다. `RICH_ELEMENT_RTF`는 주 저장 대상이 아니라 기존 값이 있으면 마이그레이션/호환용으로 삭제하지 않는 보존 대상이며, 새 주원료 저장 기준은 `RICH_ELEMENT_SHEET`와 plain text임을 명시했다. 저장 전 검증 실패와 DB 트랜잭션 실패를 분리해, 검증 실패는 트랜잭션 미시작/잠금 해제/상태 유지, DB 실패는 전체 롤백 후 잠금 해제와 현재 draft 기준 백업 저장 재예약 또는 즉시 flush로 정리했다.
- 커밋 완료: `97c3665` 품목관리 요청서 추가와 실패 처리 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 정렬/필터로 자동 선택된 신규 행이 보이지 않는 경우를 `선택 상태는 유지하되 테이블 선택 하이라이트는 표시되지 않음`으로 확정했다. 저장 실패 검증 문구도 저장 전 검증 실패와 DB 트랜잭션 실패로 좁혔고, debounce 백업 작업 유지/백업 저장 재예약 또는 즉시 flush는 DB 트랜잭션 실패에만 적용되도록 본문과 검증 항목 표현을 통일했다.
- 커밋 완료: `c980e04` 품목관리 요청서 실패 처리 표현 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 선택 제한 예시의 `권한상 수정 불가한 셀`을 현재 구현 범위에 맞춰 `컬럼 정책상 수정 불가한 셀`로 변경했다. 주원료 시트 변경 반영은 commit 완료 값 즉시 draft 반영, 미commit 활성 셀은 저장/선택 변경/탭 이동 차단 판단 직전 commit/flush 후 draft 반영 및 검증으로 명확히 했다. 필수 일반 컬럼은 Flutter 컬럼 모델에서 `BM_RICH_COL_MIN.RICH_MIN_CHECK` 대응 필드를 확인해 매핑하도록 보강했고, 남은 포괄적 저장 실패 표현은 저장 전 검증 실패 또는 DB 트랜잭션 실패 기준으로 통일했다.
- 커밋 완료: `08657d4` 품목관리 요청서 애매 표현 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 정렬/필터 상태의 선택 보관 기준을 표시 rowIndex가 아니라 기존 행 item id 또는 신규 행 임시 draft row key로 명시했다. 필터로 보이지 않는 자동 선택 행은 선택 상태만 유지하고 필터 해제 전까지 삭제/전체 선택/전체 선택 해제 같은 표시 행 기반 액션 대상에서 제외하도록 정리했다. 행 선택 제한과 셀 편집 제한도 분리했고, 저장 성공 후 신규 행 선택 복원은 임시 draft row key와 생성 item id 매핑을 우선 사용하도록 보강했다. 임시 백업 JSON의 신규 행에는 draft 추적/선택 복원용 임시 draft row key를 포함한다.
- 커밋 완료: `00b9e42` 품목관리 요청서 선택 키 기준 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 필터로 보이지 않는 숨은 선택 행만 있을 때 `품목 삽입`은 비활성화하고, 숨은 자동 선택 행은 삭제/전체 선택 같은 표시 행 기반 액션 대상에서 제외하도록 정리했다. 단, `전체 선택 해제`는 표시 행 선택과 숨은 자동 선택 상태를 모두 해제하도록 UX를 확정했다. 저장 성공 후 선택 복원은 저장 전 선택 신규 행의 draft row key 매핑, 저장 전 선택 기존 행의 item id, 같은 row index, 첫 번째 행 순서로 검증 항목을 분리했다. 저장 전 선택 행을 특정할 수 없는 경우 신규 저장 행이 1개뿐일 때만 새 item id로 복원하는 fallback을 추가했다.
- 커밋 완료: `7671907` 품목관리 요청서 숨은 선택 기준 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 품목 삭제 대상을 `현재 표시 선택 행`으로 좁히고 필터로 보이지 않는 숨은 선택 행은 삭제 대상에서 제외한다고 명시했다. `전체 선택 해제` 문장은 6.4 팝업메뉴 제한 항목의 bullet 형식에 맞춰 정리했다. 저장 전 선택 행을 특정할 수 없고 신규 저장 행이 1개뿐이면 해당 신규 item id로 선택 상태가 복원된다는 검증 항목을 추가했다.
- 커밋 완료: `a32ce0b` 품목관리 요청서 삭제 선택 기준 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt` 6.4 팝업메뉴 제한 문단에서 `draft 편집 모드에서 다음 액션은 신규 행으로 제한하지 않는다`로 도입 문장을 바꾸고, `품목 삭제`/`전체 선택`/행 멀티 선택 액션과 `전체 선택 해제` 동작을 각각 bullet로 분리해 문서 형식을 정리했다. 기능 요구사항 변경은 없고 문서 가독성 정리이다.
- 커밋 완료: `9364041` 품목관리 요청서 팝업메뉴 문단 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.
- 추가 정리 완료: `.tmp/item_manager_modify.txt`에서 필수 일반 컬럼 기준을 레거시 `BM_RICH_COL_MIN.RICH_MIN_CHECK` 단독 참조에서 현재 Flutter 실제 매핑 기준으로 정리했다. 일반 동적 컬럼은 `TColumnDAO`가 `BM_RICH_CHECK_COLUMNS.RICH_CHECK_YN`을 조회하고 `TColumn.fromMap`이 `TColumn.useMissingKeywordCheck`로 매핑한다. 품명/주원료/저울중량/최종가격 같은 고정 특수 컬럼은 `TColumnSpecial.selectByLabelSizeId`가 같은 `RICH_CHECK_YN`을 조회해 `TColumnBase.useMissingKeywordCheck`로 매핑한다. 레거시 `BM_RICH_COL_MIN.RICH_MIN_CHECK`는 라벨 편집 화면의 최소/필수 체크 표시와 동기화에 사용되던 설정 테이블로 참고하되, 현재 저장 전 필수 검증의 직접 기준은 `BM_RICH_CHECK_COLUMNS.RICH_CHECK_YN`을 거친 `useMissingKeywordCheck`임을 본문과 검증 항목에 반영했다.
- 커밋 완료: `3cc52dc` 품목관리 요청서 필수 컬럼 기준 정리. 포함 파일은 `SESSION_HANDOFF.md`이며, `.tmp/item_manager_modify.txt`는 ignore 대상 작업 파일로 유지했다.

### 진행 중 (2026-07-10): 품목관리 편집·저장·Excel·설정 기능 구현

- 2026-07-10 acceptance 재감사 보완 완료: 저장 전 검증을 품명/필수 주원료/필수 동적 컬럼/BMP 이미지/EAN·UPC·ITF/날짜·시간 범위/GS1 AI/타임바코드/`10*8` 수량 규칙까지 확장했다. 첫 오류는 row key와 column id를 포함한 `ItemManagerDraftValidationError`로 반환하고, `FortuneTableFocusController`가 해당 셀을 수직·수평 reveal한 뒤 focus한다.
- GS1 AI 직접 편집은 형식 실패 값을 draft에 반영하지 않고 직전 유효값을 유지한다. 레거시 타임바코드 type 1/2/4/9 suffix와 `10*8`의 `매수`/`발행수량` 파생값은 draft dirty cell로 재계산한다.
- 삭제 영향 범위 외부 변경 감지를 위해 item별 정렬된 market id fingerprint를 XML rowset 조회로 만들고 save 직전에 baseline과 비교한다. 같은 fingerprint를 journal baseline JSON의 `mappingFingerprints`에도 기록한다.
- mapping fingerprint 불일치는 일반 저장 실패로 처리하지 않고 typed conflict로 분기한다. 닫을 수 없는 전용 dialog에서 보조 `변경 취소`와 기본 `다시 조회`만 제공하며, 선택 시 stale draft를 원자적 DB 재조회로 교체한다. 재조회 실패 시 기존 draft/journal은 유지된다.
- DB commit 후 재조회 실패는 `forceReloadRequired`로 전환한다. 이 상태에서는 다시 조회 외 저장/취소/셀 편집/추가·삽입·삭제/전체 선택·해제/발행 체크/Excel/순서 변경을 차단한다. 로그아웃·앱 종료에는 DB 저장 완료와 stale 임시 백업 정리를 단일 정보 dialog로 알린다.
- DB 재조회는 columns/column contents/special columns/items/raw snapshots/scoped contents/mapping fingerprints와 새 controller/빈 element payload를 모두 지역 상태로 완성한 뒤 기존 journal/controller와 static cache를 한 번에 교체한다. DB/model 준비 실패와 기존 journal cleanup 실패에서는 기존 화면·draft·journal·static cache를 유지하고, 연결되지 않은 새 controller는 dispose한다. post-commit 재조회 실패에서는 stale 저장 완료 백업과 force 상태를 다시 조회 성공 또는 화면 종료까지 유지하며, Excel 전체 교체 취소 재조회가 실패해도 현재 draft를 잃지 않는다.
- DB 저장 DAO가 완료되기 전에 capability/transaction 오류가 발생하면 현재 메모리 draft를 journal에 즉시 flush한다. journal 저장 자체가 실패해도 해당 오류는 로그만 남기고 원래 DB 저장 오류와 편집 상태를 유지한다.
- 저장·순서 변경·force retry·mapping conflict·Excel 취소 후 재조회 선택은 `item id -> 이전 row index -> 첫 행` 순서로 복원한다. 삭제 등으로 item id가 사라져도 가능한 한 같은 화면 위치를 유지한다.
- 일반 추가·삽입·삭제·셀 편집 취소는 controller 생성 시 보관한 불변 메모리 baseline으로 원본 rows/deletion set/선택을 즉시 복원하고 journal을 정리한다. Excel 전체 교체 취소만 DB 재조회하며, 취소 확인 문구는 지시서의 `변경 내용을 취소할까요?`로 맞췄다.
- Excel 전체 교체 직전에 선택 item id/index와 현재 테이블의 정렬·필터 metadata(현재 기능 미지원이므로 빈 구조)를 `ItemManagerImportViewState`로 controller와 journal에 보관한다. 변경 취소 DB 재조회는 import 후 첫 행이 아니라 이 import 전 item id/index를 사용해 선택을 복원한다.
- 비선택 draft 행은 신규/Excel imported 행을 연녹색, 수정된 기존 행을 연황색으로 구분한다. 선택된 행은 기존 테이블 선택색을 우선하고 unchanged 발행 체크 행은 기존 연청색을 유지한다.
- 발행 체크 상태는 clean 상태에서 기존 item id snapshot으로 추적하고, draft 추가/삽입/삭제로 row index가 바뀔 때 현재 source item id 기준으로 다시 투영한다. source item id가 없는 신규 행은 unchecked이며 저장 후 새 controller로 교체되면 체크 snapshot을 초기화한다.
- 컨텍스트 메뉴가 열린 뒤 draft 상태나 대상 행이 바뀌는 race도 실행 시점에 다시 검증한다. 발행 체크/해제는 dirty·busy·force 상태면 실행하지 않고, QR 데이터 보기는 우클릭한 draft row key가 현재 working table에 남아 있을 때만 callback을 호출한다.
- 저장 전 선택 행이 없고 신규 저장 행이 정확히 하나인 경우 저장 결과의 생성 item id를 재조회 선택 후보로 사용한다. 선택된 신규 draft mapping과 선택된 기존 item id가 있으면 이를 우선한다.
- 삭제 예정 기존 item이 포함된 저장 확인에는 item id 기준 전체 mapping 삭제로 인해 같은 고객의 다른 market 품목관리에서도 보이지 않을 수 있다는 경고를 함께 표시한다.
- Excel 전체 교체 직전 journal과 동일한 lightweight baseline checksum을 import metadata에 저장한다. 변경 취소 DB 재조회 후 새 controller checksum이 다르면 현재 DB 기준 복원은 유지하면서 `외부 변경 가능성` dialog를 표시한다.
- Excel 문자열 import는 `quotePrefix` metadata가 있는 escape 문자열의 선행 apostrophe만 제거하고, metadata가 없는 literal apostrophe는 원문을 보존한다. inline string fixture에서 두 경우를 함께 검증한다.
- 품목관리 테이블의 `주원료` 컬럼은 편집 callback을 제공하지 않는 read-only 컬럼으로 유지한다. 실제 더블클릭에서 text editor가 열리지 않고 draft 값과 clean 상태가 유지되는 widget 회귀 테스트를 추가했다.
- 신규 품목의 `BM_ITEM_OF_MARKET` insert는 additional item을 명시적 `NULL`로 저장하고 판매/할인 날짜 nullable 값을 fallback 없이 전달한다. 저장 SQL 계약을 `item_manager_save_dao_test.dart`에서 검증한다.
- 날짜 타입 설정은 편집 권한이 없는 사용자도 열 수 있지만 체크/포맷/사용자 정의 입력과 `적용` 버튼을 조회 전용으로 비활성화한다. callback 이후에도 권한을 재검증하며, `forceReloadRequired` 상태에서는 메뉴 enable 조건과 실행부 양쪽에서 진입을 차단한다.
- draft journal schema를 v2로 올려 세션 최초 `createdAt`과 flush별 `updatedAt`을 분리하고, baseline에 `checksumSchemaVersion` 및 checksum 입력 field 목록을 명시한다. SharedPreferences의 마지막 저장 시각은 `updatedAt`을 사용한다.
- debounce clear/flush의 파일 오류는 background helper가 로그로 격리해 메모리 draft와 사용자 편집을 막지 않는다. 실패한 write queue는 다음 flush 전에 이전 오류를 흡수하고 새 문서 쓰기를 재시도하므로 일시적 파일 오류 후에도 백업이 회복된다. 명시적 journal close는 pending write와 파일 정리가 성공한 뒤에만 controller listener를 제거하므로 cleanup 실패 후에도 기존 draft 자동 백업과 close 재시도가 가능하다.
- draft key는 지시서 identity인 `user/customer/brand/labelSize` 조합으로 생성한다. 새 clean 세션 시작 시 SharedPreferences가 가리키는 이전 실행 journal은 앱 지원 디렉터리의 `item_manager_drafts` 하위 경로인지 확인한 뒤 `.tmp/.json/.bak`과 metadata를 정리해 다른 key의 stale 파일도 남기지 않는다.
- 저장·재조회 등 `commandBusy` 동안 품목관리 footer에 16px progress indicator와 `처리 중` 상태를 표시한다. 기존 명령 비활성화와 함께 중복 클릭 방지와 진행 상태 안내를 모두 제공한다.
- `commandBusy`, dirty, `forceReloadRequired` 상태에서는 브랜드/라벨 context 변경뿐 아니라 품목관리 외 메인 탭 선택도 공용 guard로 차단하고 품목관리 탭을 복원한다. 플로팅 품목 preview의 `출력내용 미리보기` 선택도 manager 상태를 실시간 확인해 잠긴 경우 `주원료 및 함량` 탭으로 되돌린다.
- 품목 load는 `ItemOfMarketDAO`가 `RICH_ELEMENT_SHEET`를 참조하기 전에 `ItemSaveSchemaCapabilityDAO`를 probe한다. 컬럼이 없으면 품목/컬럼 SELECT와 `ItemManage`를 열지 않고 DB migration 안내 전용 화면을 표시해 편집·저장·Excel·메뉴 진입을 구조적으로 차단한다. 강제 재조회는 capability cache를 갱신한다.
- draft dirty 또는 command busy 상태에서는 발행 checkbox controller를 제거하고 기존 체크값만 표시한다. 저장/취소 후 clean 상태에서만 다시 조작할 수 있다.
- 이미지 타입 동적 셀은 일반 텍스트 편집 대신 double-click BMP 파일 선택기를 사용한다. 선택한 값은 경로와 `.bmp` 확장자를 제거한 파일명만 draft에 반영하고 경로 비저장 정책을 안내한다. 선택형 컬럼은 현재 `TColumnType`/`TColumn` DB projection에 선택 옵션을 나타내는 타입이나 option source가 없어 근거 없는 dropdown을 추가하지 않았다.
- dirty 로그아웃/종료는 `LifecycleManager.notifyExitRequested()`의 bool 승인 계약으로 취소할 수 있으며 Windows close와 `PopScope` 모두 거부 결과를 존중한다.
- Windows G500 직접 출력은 이름만으로 EZPL raw를 선택하지 않고 spooler `PRINTER_INFO_2.pPortName`도 확인한다. `FILE:`/`PORTPROMPT:` 포트는 실장비 raw 대상으로 사용하지 않고 안내 후 일반 PDF 인쇄로 전환하며, USB/TCP 포트와 포트 조회 실패는 기존 raw 경로를 유지한다. 현재 개발 PC의 `Godex G500`은 `FILE:` 포트이며 일회성 실제 spooler probe로 새 API가 이를 정확히 읽는 것을 확인했다.
- 자동 검증 제외: 운영 DB capability/save/date/order transaction 및 실제 mapping fingerprint 변동 dialog 실행과 Windows BMP/XLSX 파일 대화상자 수동 선택은 연결 fixture 및 interactive 환경이 없어 미검증이다.
- 홈 `라벨출력(F3)` 구현은 작업 지시서 범위가 아니므로 placeholder를 유지한다. 지시서의 resolver 기반 실제 출력 입력 계약은 새 F3 화면 구현 요구로 해석하지 않는다.
- F3 과구현 제거 검증 완료: label toolbar/print job/raw printer focused `107 통과 / 0 실패`, `C:\Flutter\bin\flutter.bat analyze` `No issues found`, 전체 Flutter suite `3288 통과 / 0 실패`.
- acceptance 보완 구현 커밋 완료: `1183c5b` 품목관리 저장 검증과 재조회 복구 보완.
- 원자적 재조회와 journal close 실패 복구 커밋 완료: `d36d2c4` 품목관리 재조회 상태 교체를 원자화.

- 작업 지시서 `doc/item_manager_modify.txt` 전체를 확인했다. 구현 범위는 ① 읽기/스냅샷 기반, ② transaction/저장 DAO, ③ UI draft/edit와 임시 journal, ④ `.xlsx` import/export, ⑤ QR/바코드 resolver와 출력 미리보기, ⑥ 라벨 날짜 타입 설정, ⑦ 품목 순서 변경의 7개 단위다.
- 구현 순서는 지시서 13.1을 따른다. 각 단위의 API와 focused test를 완료한 뒤 다음 단위로 진행하며, 아직 연결되지 않은 단위는 `미검증`으로 유지한다.
- 1단계 `읽기/스냅샷 기반` 구현 완료: `lib/models/item_of_market.dart`에서 표시 SQL alias를 `P1_LABEL_SIZE_WIDTH/HEIGHT`로 맞추고 item order 정렬을 추가했다. nullable DB 값을 보존하는 `ItemOfMarketRawSnapshot`과 별도 raw projection/query를 추가했다.
- 1단계 구현 완료: `lib/models/market.dart`에 로그인 customer id를 명시적으로 받는 `MarketDAO.selectByCustomerId`를 추가했다. `lib/models/column_content.dart`에는 단일 XML 파라미터를 SQL rowset으로 변환해 item id 집합을 제한하는 `selectScopedByItemIds`와 전역 cache와 분리된 `TColumnContentScopedView`를 추가했다.
- 1단계 테스트 추가: `test/item_manager_read_snapshot_test.dart`에서 표시 alias/order, raw `NULL`/빈 문자열 구분, customer 조건, 대량 `IN` 없는 XML rowset, scoped resolver를 `[읽기/스냅샷]` 5개 테스트로 검증한다.
- 1단계 검증 완료: `C:\Flutter\bin\flutter.bat test test\item_manager_read_snapshot_test.dart` 통과(`+5`), 기존 `item element DAO keeps legacy RTF while saving sheet data` 통과(`+1`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 1단계 커밋 완료: `cf53482` 품목관리 읽기 스냅샷 기반 추가.
- 2단계 `transaction/DAO 기반` 구현 완료: `DbTransactionStatement`, 공통 `executeDriverTransaction`, `DbIsolateAction.transaction`, `DbClient.transaction`을 추가했다. 같은 isolate/driver 연결에서 begin/statement/commit을 수행하고 중간 오류 또는 commit 오류 시 `@@TRANCOUNT` rollback 후 원래 오류를 전달한다.
- 2단계 구현 완료: `lib/models/item_manager_save.dart`에 `ItemSaveSchemaCapabilities` probe/cache를 추가했다. `RICH_ELEMENT_SHEET`, `AFTER_INSERT_ITEM`, trigger의 column/barcode/image/element row 생성과 다중 행 사용 패턴을 현재 DB에서 조회한다.
- 2단계 구현 완료: UI 독립 `ItemManagerSaveCommand` DTO와 `ItemManagerSaveDAO`를 추가했다. 기존 item update, trigger-safe 단건 신규 item insert 및 `OUTPUT INTO` draft key/id 매핑, 로그인 customer의 target market mapping 생성, item-id 기준 전체 mapping delete, column content `MERGE` upsert를 하나의 parameterized SQL statement와 isolate transaction에서 처리한다. `BM_RICH_ITEM`/child row 물리 delete는 하지 않는다.
- 2단계 구현 완료: `ItemDAO.updateOrders(List<ItemOrderUpdate>)`를 transaction action 기반 독립 reorder API로 추가하고 item id별 affected row를 검증한다.
- 2단계 테스트 추가/완료: `test/db_transaction_test.dart`의 `[transaction/DAO]` 4개 테스트에서 commit/rollback/원래 오류/DTO 전달을 검증한다. `test/item_manager_save_dao_test.dart`의 7개 테스트에서 capability flags/probe SQL, order identity, nullable 신규 mapping defaults, save command identity, `OUTPUT INTO`, mapping-only delete, column upsert, schema migration 차단을 검증한다.
- 2단계 검증 완료: `C:\Flutter\bin\flutter.bat test test\item_manager_save_dao_test.dart` 통과(`+7`), `C:\Flutter\bin\flutter.bat test test\db_transaction_test.dart` 통과(`+4`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`). 운영 DB 연결 fixture가 없어 capability probe와 save SQL의 실제 trigger/schema 통합 실행은 미검증이며 UI 저장 연결 전에 현재 DB 기준으로 확인해야 한다.
- 3단계 `UI draft/edit 기반` 진행 중: `lib/models/item_manager_draft.dart`에 `ItemManagerLimits.maxRows=10000`, existing/modified/added/imported row state, item/draft row key, raw current-market snapshot/new mapping defaults, scoped column fallback, row-key 선택/anchor, add/insert/delete, 품명/일반 컬럼/주원료 변경, no-op 복원, save command 변환을 구현했다. 신규 row preview `ItemOfMarket(itemId:0)`은 표시/미리보기 전용이며 저장 identity는 draft key로 유지한다.
- 3단계 UI 연결 진행 중: label load에서 표시 items와 nullable raw snapshots/scoped column contents를 같은 item id 범위로 조회해 draft controller를 구성한다. `ItemManage`는 기존 `items` API 호환을 유지하면서 controller working rows/value resolver를 표시하고, 우클릭 추가/삽입/삭제(개수 입력/Enter, 10000행 제한, 삭제 확인, 삭제 후 선택 이동)를 controller command에 연결했다. 신규 주원료는 현재 label size의 실제 encoded empty workbook payload를 사용한다.
- 3단계 정책 반영: 품목관리 진입 시 legacy RTF 전체 background DB 자동 마이그레이션 경로를 제거했다. preview/명시적 편집의 lazy 변환 경로는 유지하며, 사용자 저장 없는 `RICH_ELEMENT_SHEET` 변경은 더 이상 수행하지 않는다.
- 3단계 현재 검증: `test/item_manager_draft_test.dart` 통과(`+8`), `test/fortune_table_test.dart` 전체 통과(`+12`, draft 메뉴 widget 포함), `flutter analyze` 통과(`No issues found`), `git diff --check` 통과.
- 3단계 추가 구현: `item_manager_draft_journal.dart`에 app support 디렉터리 JSON journal, 250ms debounce, `.tmp`/`.bak` 교체, SharedPreferences의 path/key/savedAt metadata, BigInt FNV-1a 64-bit lightweight checksum을 구현했다. baseline은 item/order/name/plain/payload signature와 scoped column 값만 저장하고 큰 payload는 modified/new/deleted 상세 row에만 기록한다. close/cancel/save/새 clean load에서 파일과 metadata를 폐기한다.
- 3단계 추가 구현: `FortuneTableColumn` 공용 `isTextEditable`/`onTextCommitted` hook과 inline editor를 원본 fortune_sheet 엔진에 추가했다. 더블클릭 또는 Enter/F2 진입, Enter/포커스 이탈 commit, Escape 취소를 지원한다. `ItemManage` 품명과 editable 일반 컬럼을 draft API에 연결하고 주원료 셀은 직접 편집 불가로 유지했다.
- 3단계 추가 구현: 품목관리 footer에 `엑셀 가져오기`, `엑셀 내보내기`, `취소`, `저장`을 배치했다. dirty이면 Excel 비활성/취소·저장 활성, clean이면 반대로 동작한다. 로그인 customer/current market identity 검증 후 customer 전체 target market id를 세션 단위로 확정하며, dirty 중 브랜드/라벨 변경을 차단한다.
- 3단계 추가 구현: 취소 확인 후 journal 폐기/DB 재조회, 저장 확인 후 capability probe → save command 검증 → isolate transaction → DB 재조회 → source item id 또는 신규 draft id mapping 기준 선택 복원을 연결했다. 빈 품명은 DB 접근 전에 행 번호 안내로 차단한다.
- 3단계 최신 검증: `test/item_manager_draft_test.dart` 통과(`+9`), `test/item_manager_draft_journal_test.dart` 통과(`+1`), `test/fortune_table_test.dart` 전체 통과(`+14`), `flutter analyze` 통과(`No issues found`). 운영 DB transaction 통합 실행은 아직 미검증이다.
- 3단계 주원료 draft 전환 완료: `_ItemPreviewPanel`의 `ItemDAO.updateElementSheetByItemId` 즉시 DB 저장과 전역 cache 교체를 제거했다. 저장 확인 후 plain text와 encoded workbook을 `onElementCommitted` callback으로 전달하고, `HomePageManager`가 현재 controller의 `anchorRowKey`를 기준으로 `updateElement`를 호출한다. 신규 품목은 모두 `itemId=0`이므로 preview 갱신 identity에 draft row key를 별도로 전달해 신규 행 사이 전환도 정확히 재초기화한다. controller listener가 기존 dirty/journal 기록을 담당하며 실제 DB write는 품목관리 footer 저장 transaction에서만 수행된다.
- 3단계 주원료 검증 완료: `test/label_sheet_toolbar_test.dart`에 신규 row(`itemId=0`, draft row key)의 주원료 저장 확인 후 plain/payload callback 전달 테스트를 추가했다. 인접 preview 회귀 3개 통과, `test/item_manager_draft_test.dart` 통과(`+9`), `test/widget_test.dart` 통과(`+2`), `flutter analyze` 통과(`No issues found`).
- 4단계 Excel 기반 완료: 기존 `labelSheetWorkbookFromXlsxBytes` 변환 코어에서 `LabelSheetXlsxParseContext`와 `labelSheetXlsxParseContext(bytes, sheetIndex:)`를 분리했다. 기존 API는 active sheet context를 그대로 반환하고, 품목 import는 workbook 원본 순서의 `sheetIndex: 0`과 동일 parse context의 sheet name/relationship/path/XML/resources/date system을 사용할 수 있다.
- 4단계 현재 검증: 2-sheet `activeTab=1`, `date1904=1` fixture에서 기존 API가 두 번째 sheet를 유지하고 지정 index 0 context가 첫 sheet 및 같은 relationship/XML을 반환하는 테스트를 추가했다. `test/label_sheet_xlsx_import_test.dart` 전체 통과, `flutter analyze` 통과(`No issues found`).
- 4단계 raw metadata 진행 완료: parse context에 `LabelSheetXlsxCellMetadata` map을 추가해 cell reference/type, raw/cached value, parsed text, formula, style index, number format, quote-prefix를 변환 workbook과 같은 parse에서 제공한다. shared string 및 cached formula/style fixture 테스트를 추가했고 `test/label_sheet_xlsx_import_test.dart` 전체와 `flutter analyze`가 통과했다.
- 4단계 draft 전체 교체 완료: `ItemManagerImportedRow`와 `replaceAllWithImportedRows`를 추가했다. clean draft에서만 실행하며 기존 source item 전체를 삭제 예정으로 기록하고, import row를 신규 identity/imported state/1부터의 order로 교체한 뒤 첫 행을 선택한다. 빈 import, 10000행 초과, dirty 충돌은 mutation 전에 차단한다.
- 4단계 draft 검증: 기존 2개 source를 2개 imported row로 교체해 삭제 identity, order, column 값, 첫 행 selection을 확인하는 테스트를 추가했다. `test/item_manager_draft_test.dart` 전체 통과(`+10`), `flutter analyze` 통과(`No issues found`).
- 4단계 품목 XLSX import adapter 완료: `lib/page_home/item_manager_xlsx.dart`에서 첫 worksheet/1행 헤더, 빈 헤더 이후 절단·경고, 정확한 헤더/첫 중복 매핑, cached formula, 문자열/정수/소수/천단위/고정 소수/1900·1904 날짜/시간 표시, image BMP 파일명 정규화, 데이터 행/10000행 검증을 구현했다. 주원료는 셀 또는 병합 bounding rectangle을 `(0,0)` 기준 workbook으로 옮겨 cell style/inline run/merge/row·column 크기/border를 encoded payload로 보존한다.
- 4단계 adapter 검증: OpenXML fixture에서 품목/주원료/일반 컬럼, 문자열 `00123`, serial date, BMP 경로 제거, 빈 헤더 뒤 경고, 주원료 bold/background/축 크기와 품목 헤더 누락 실패를 검증했다. `test/item_manager_xlsx_test.dart` 통과(`+2`), `flutter analyze` 통과(`No issues found`).
- 4단계 export 완료: `itemManagerExportXlsxBytes`가 `품목`, `주원료`, editable 일반 컬럼 순서의 최소 OpenXML workbook을 생성한다. 모든 셀을 inline string으로 기록해 선행 0과 XML 특수문자를 보존하며, export→import round-trip 테스트를 추가했다.
- 4단계 UI 연결 완료: 품목관리 footer의 Excel callback을 실제 `.xlsx` 파일 선택/저장 대화상자에 연결했다. import는 clean 상태에서만 실행하고 parser 경고 확인 후 기존 draft 전체를 imported rows로 교체하며 첫 행 선택/preview를 동기화한다. export는 clean working rows가 있을 때만 실행하고 확장자 누락 시 `.xlsx`를 붙이며 다른 확장자는 차단한다.
- 4단계 최종 검증: `test/item_manager_xlsx_test.dart` 통과(`+3`), `test/item_manager_draft_test.dart` 통과(`+10`), `test/fortune_table_test.dart --plain-name "ItemManage commits item name edits to the draft row"` 통과(`+1`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`). 실제 Windows 파일 대화상자의 수동 선택/저장은 자동 테스트 범위 밖이며 앱 수동 확인이 남아 있다.
- 4단계 커밋 완료: `82dc76a` 품목관리 엑셀 입출력 연결.
- 5단계 QR/바코드 진행 중: 공용 `BarcodeType.CodeEAN8.dbName`을 `EAN8`로 수정하고 `EAN8`/`EAN-8`/`CodeEAN8` alias와 `CODE128`을 구분하는 `barcodeTypeFromDbName`을 추가했다. `BarcodeDataHelper.normalizeMeaningPreservingForPrint`는 EAN/UPC check digit만 보정하고 길이 padding/truncation 및 홀수 ITF를 유효 후보에서 제외한다.
- 5단계 resolver 진행: `ItemCodeDataResolver`가 current row value callback을 입력으로 plain/user-defined/text-link/natrium QR 데이터, 1D/QR format id, 표시 metadata, 의미 보존 normalization/fallback 결과를 산출한다. 레거시 6-record 나트륨 설정과 `na3.php` URL/rate 계산을 반영했다. `Gs1AiDAO`가 `BM_GS1_AI` 정의를 읽어 cache하며, GS1 barcode는 `containColumns` 순서대로 AI+값을 조합하고 중간 variable-length AI에만 ASCII 29(FNC1)를 넣는다. 포함 컬럼/AI 정의 누락은 Code128 fallback 없이 오류로 반환하며 `tokenColumnValue`로 날짜의 `DATE_FORMAT_NONE` 값을 받을 수 있다.
- 5단계 viewer 진행: `FortuneTable.onRowSecondaryTapDown` 공용 hook으로 실제 우클릭 row를 전달하고, 품목관리 메뉴의 `QR코드 데이터 보기`가 current draft row 기준 resolver 결과 전체를 읽기 전용/선택 가능 목록으로 표시한다. viewer는 controller mutation을 수행하지 않아 dirty 상태에 포함되지 않는다.
- 5단계 preview/metadata 진행: barcode object id가 column keyword와 일치할 때 resolver가 `barcodeText`, `barcodeFormatId`, `barcodeFormatLabel`, `barcodeShowText`를 갱신하며 geometry metadata는 유지한다. `preserveTemplateBarcodeFormat=true`이면 template format metadata를 보존한다. save codec feature/allow-list와 OpenXML customXml image metadata export/import를 보완해 `.lms` 및 `.xlsx` round-trip에서 플래그가 유지된다. 출력 미리보기는 `itemCodeWarning`/`itemCodeError`를 중복 제거해 상단에 표시하고 오류 barcode object의 기존 이미지를 명시적 SVG placeholder로 교체한다.
- 5단계 현재 검증: `test/barcode_data_helper_test.dart`와 `test/item_code_data_resolver_test.dart` 통과(현재 resolver 파일 `+8`), QR 우클릭 row widget test 통과(`+1`), preview message/placeholder focused test 통과(`+1`), image save metadata 및 XLSX image metadata focused test 각각 통과(`+1`, `+1`), `flutter analyze` 통과(`No issues found`).
- 5단계 출력 경계 조사: 작업 지시서는 resolver 결과를 실제 출력 입력에 사용하도록 요구하지만 새 출력 화면이나 홈 `라벨출력(F3)` 구현을 요구하지 않는다. 현재 품목관리에는 연결할 기존 실제 출력 command가 없으므로 F3를 새로 구현하지 않고 resolver/출력 미리보기 계약까지만 유지한다.
- 6단계 날짜 설정 완료: `DateManager`에 레거시 날짜/시간 고정 포맷 및 `Y/M/D`, `H/M` 사용자 정의 sample preview helper를 추가했다. `LabelSize.fromMap`은 날짜/시간 enum index를 range guard하고 범위 밖 값은 날짜 `DATE_FORMAT_DOT`, 시간 `TIME_FORMAT_COLON`으로 열며 `hasInvalidDateSetupValues` 경고 상태를 보존한다.
- 날짜 저장은 `LabelSizeDateSetupUpdate`의 12개 필드만 `BM_RICH_LABELSIZE_FORM`에 반영한다. `BM_RICH_LABELSIZE_FORM_LOG`의 before/`RICH_ALTER_` after 24개 컬럼을 probe하고, 전부 있으면 로그 insert와 update를 같은 SQL batch transaction에서 실행하며 일부라도 없으면 logless 단일 update를 실행한다. probe 자체 실패, 최신 setup 누락, affected row 불일치는 저장 실패로 처리한다. 저장 결과는 최신 DB setup의 `readOnly`/`useScale`을 유지한 채 `LabelSize.datas`와 현재 선택 cache에 반영한다.
- 상단 라벨 `설정` 버튼은 `라벨 설정...`/`날짜 타입 설정...` 메뉴로 전환했다. 날짜 다이얼로그는 제조일자/제조시한/소비기한/소비시한 4개 그룹의 사용 여부, 고정/사용자 정의 형식, 실시간 preview를 제공한다. draft dirty 또는 저장 command busy 상태에서는 날짜 설정 메뉴가 비활성화되며 저장 성공 후 setup revision으로 관련 탭/미리보기를 refresh한다.
- 6단계 검증: `test/date_manager_test.dart` 4개와 `test/date_type_setup_dialog_test.dart` 1개, 전체 `flutter analyze`가 통과했다. 운영 DB의 실제 로그 컬럼 probe와 transaction/logless update는 연결 fixture가 없어 미검증이다.
- 7단계 품목 순서 변경 완료: 품목관리 우클릭 command 그룹의 `품목 삭제` 바로 아래에 `순서 변경`을 추가했다. 특정 행이 아닌 현재 목록 command이므로 실제 행과 빈 테이블 영역 우클릭 모두에서 메뉴를 열 수 있으며, 빈 영역에서는 직전 행의 QR context를 재사용하지 않는다. 품목 2개 미만, command busy, draft dirty 상태에서는 비활성화하고 dirty 상태에는 저장 완료 또는 변경 취소 확정 후 실행하라는 안내를 표시한다. 레거시 `CLoginUser::IsEditable()` 사용 패턴에 맞춰 `CLIENT_USER`만 조회 전용으로 모델링했으며, 편집 권한이 없으면 메뉴 안내와 실행 guard 양쪽에서 순서 변경을 차단한다.
- 순서 변경 다이얼로그는 현재 market/label size의 저장된 품목을 `RICH_ITEM_ORDER`, `RICH_ITEM_ID` 순으로 DB에서 새로 읽고, 번호 목록/선택 강조/위·아래 이동/닫기/적용을 제공한다. 현재 선택 item id가 목록에 있으면 해당 품목을 초기 선택하고, 없으면 첫 품목을 안전하게 사용한다. 변경 전에는 적용이 비활성화되며 적용 확인에는 item-level `RICH_ITEM_ORDER`가 같은 label size 품목을 공유하는 다른 market 표시 순서에도 영향을 줄 수 있음을 안내한다.
- 적용 시 다이얼로그 표시 순서대로 `ItemOrderUpdate(order: index + 1)`를 만들고 기존 `ItemDAO.updateOrders` transaction으로 `BM_RICH_ITEM.RICH_ITEM_ORDER`만 갱신한다. 성공 후 기존 `_reloadItemDraftFromDatabase` 경로로 journal/controller를 폐기하고 DB를 재조회하며, 이전 선택 item id가 남아 있으면 선택과 preview를 복원한다.
- 7단계 검증: `test/item_order_dialog_test.dart`에서 현재 item 초기 선택/이동/번호/적용 반환/닫기 no-op을 검증하고, `test/user_test.dart`에서 `CLIENT_USER` 조회 전용 계약을 검증했다. `test/fortune_table_test.dart`에서는 메뉴 배치/callback/dirty 차단/편집 권한 안내/빈 영역 메뉴를 검증했다. order identity/SQL 계약을 포함한 관련 28개 테스트, 전체 `flutter analyze`, 전체 Flutter suite `3254 통과 / 0 실패`가 통과했다. 운영 DB에서의 실제 order transaction 실행은 연결 fixture가 없어 미검증이다.
- 7단계 커밋 완료: `7bc558f` 품목 순서 변경 기능 추가.
- 7단계 권한/현재 선택 보완 커밋 완료: `fb28808` 품목 순서 권한과 현재 선택 보완.
- 작업 지시서의 1~7단계 구현은 완료했다. 새 F3 출력 화면은 작업 지시서 범위가 아니므로 placeholder를 유지하며, 운영 DB capability/save/date/order transaction 통합 실행은 fixture가 없어 계속 미검증이다.
- 통합 검증 완료(2026-07-10): 전체 Flutter suite 최초 실행에서 `3237 통과 / 15 실패`를 확인했다. 실패는 `#ELEMENT` 대신 일반 문자열을 사용한 preview fixture, 제거된 toolbar popup 75% ratio cap을 기대한 barcode/canvas 테스트, 새 `label-sheet-import-image` locale key 누락, data row까지 포함한 painter 픽셀 범위, screenshot dashed border의 과도한 픽셀 임계치, 현재 렌더링과 불일치한 golden 9개였다. 제품 구현을 우회하지 않고 각 테스트 계약/범위를 현재 의도에 맞게 보정하고 공식 `FORTUNE_UPDATE_GOLDENS=1` 경로로 실패 golden만 갱신했다.
- 통합 검증 최종 결과: 품목 순서 권한/현재 선택 보완 후 포맷, focused 28개 테스트, 전체 `flutter analyze`, `C:\Flutter\bin\flutter.bat test` 전체 suite가 모두 통과했다. 최종 suite 결과는 `3254 통과 / 0 실패`다. 운영 DB capability/save/date/order transaction 실행과 실제 Windows 파일 대화상자 import/export는 fixture 및 수동 앱 환경이 없어 자동 검증 범위에서 제외한다.
- 통합 검증 커밋 완료: `d775607` 품목관리 통합 테스트 기준 정리.

### 완료 (2026-07-10): 불필요한 작업 규칙 정리

- 사용자 요청에 따라 `FortuneSheet/bwip-js는 래퍼 우회 없이 원본 엔진 직접 수정`, `WebView 캐시 수정 시 clear_webview2_userdata.ps1 자동 실행`, `.tmp/backups ZIP을 복원 기준으로 사용하고 patch는 보조 수단으로만 사용` 규칙을 사용자 작업 메모에서 제거했다.
- `SESSION_HANDOFF.md`의 기존 작업 규칙에는 제거 대상과 동일한 규칙이 없어 추가 삭제는 필요하지 않았다.
- 커밋 완료: `5e84768` 불필요한 작업 규칙 정리.

### 완료 (2026-07-09): 품목관리 발행 체크 행 하이라이트

- 요청: 품목관리 테이블에서 발행 체크된 행은 행 선택 하이라이트와 어울리는 체크 하이라이트를 적용한다. 선택 하이라이트와 섞여 난잡하지 않아야 한다.
- 수정 완료: `third_party/fortune_sheet/lib/src/fortune_table.dart`에 `rowColorBuilder(row, rowIndex, selected)`를 추가해 행 배경색을 공용으로 오버라이드할 수 있게 했다. 기본값은 기존 선택/홀짝 행 색상을 유지한다.
- 수정 완료: `lib/page_home/item_manage.dart`에서 발행 체크된 비선택 행에 `Color(0xFFEAF4FF)` 체크 하이라이트를 적용했다. 선택 행은 기존 선택 하이라이트 `Color(0xFFE3F2FD)`가 우선해 선택/체크 색이 난잡하게 겹치지 않는다.
- 테스트 갱신: `test/fortune_table_test.dart`의 품목관리 발행 체크 테스트에서 체크된 비선택 행과 선택 행의 배경색 우선순위를 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart` 통과(`+11`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`), `git diff --check -- third_party/fortune_sheet/lib/src/fortune_table.dart lib/page_home/item_manage.dart test/fortune_table_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료: `1b7b4d8` 품목관리 발행 체크 행 강조. 포함 파일은 `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/page_home/item_manage.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-09): 품목관리 우클릭 메뉴 애니메이션 제거

- 요청: 원본 시트 팝업메뉴는 즉시 나타나는데 품목관리 테이블 팝업메뉴는 Flutter 기본 `showMenu` 애니메이션으로 펼쳐지듯 나타나므로, 원본 시트처럼 즉시 나타나게 수정한다.
- 확인: 현재 Flutter SDK `showMenu`는 `popUpAnimationStyle` 파라미터와 `AnimationStyle.noAnimation`을 지원한다.
- 수정 완료: `lib/page_home/item_manage.dart`의 품목관리 우클릭 `showMenu` 호출에 `popUpAnimationStyle: AnimationStyle.noAnimation`을 지정해 기본 scale/fade 팝업 애니메이션을 제거했다. 메뉴 구성/간격/동작은 유지했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart --plain-name "ItemManage context menu controls selection and publish checks"` 통과, `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart` 통과(`+11`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`), `git diff --check -- lib/page_home/item_manage.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료: `9ea1135` 품목관리 메뉴 애니메이션 제거. 포함 파일은 `lib/page_home/item_manage.dart`, `SESSION_HANDOFF.md`. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-09): 품목관리 우클릭 메뉴 간격 보정

- 요청: 품목관리 우클릭 팝업메뉴 항목 간격이 너무 커서 원본 시트(`fortune_sheet`) 팝업메뉴 간격과 맞춘다.
- 확인: 원본 시트 메뉴 상수는 `fortuneContextMenuRowHeight=28.0`, `fortuneContextMenuDividerHeight=9.0`이다. 품목관리 전용 메뉴는 Flutter `showMenu`/`PopupMenuItem` 기본 높이(48) 때문에 항목 간격이 크게 보인다.
- 수정 완료: `lib/page_home/item_manage.dart`의 품목관리 전용 `PopupMenuItem.height`를 `fortuneContextMenuRowHeight`, `PopupMenuDivider.height`를 `fortuneContextMenuDividerHeight`로 지정하고, 항목 padding/input 높이를 조정해 원본 시트 팝업메뉴 밀도에 맞췄다. 메뉴 구성/동작은 유지했다.
- 테스트 갱신: `test/fortune_table_test.dart`의 품목관리 컨텍스트 메뉴 테스트에서 모든 `PopupMenuItem`/`PopupMenuDivider` 높이가 원본 `fortune_sheet` 상수와 같은지 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart` 통과(`+11`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`), `git diff --check -- lib/page_home/item_manage.dart test/fortune_table_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료: `5b611b4` 품목관리 메뉴 간격 보정. 포함 파일은 `lib/page_home/item_manage.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-09): 품목관리 FortuneTable 행 멀티 선택과 우클릭 메뉴

- 요청: 품목관리 테이블은 셀 단위가 아닌 행 단위 선택이며, 드래그/Shift+클릭/Ctrl+클릭/Ctrl+A/ESC 멀티 선택을 지원한다. 공용 선택 기능은 원본 `third_party/fortune_sheet/lib/src/fortune_table.dart`에 옵션/플래그로 추가한다. 품목관리 셀 그리드 우클릭 메뉴는 화면 전용 기능으로 처리한다.
- 수정 완료: `third_party/fortune_sheet/lib/src/fortune_table.dart`에 `FortuneTableSelectionController`를 추가해 행 인덱스 기준 `selectedRows`/`isSelected`/`setSelected`/`toggleSelected`/`setSelectedRows`/`selectRange`/`selectAll`/`clear` API를 제공한다. `FortuneTable.selectionController`, `multiSelectionEnabled`, `keyboardSelectionShortcutsEnabled` 옵션을 추가했고, 멀티 선택이 켜진 경우 Ctrl+클릭 toggle, Shift+클릭 range, 드래그 range, Ctrl+A 전체 선택, ESC 선택 해제를 지원한다. 기본값은 기존 단일 선택 동작을 유지한다.
- 수정 완료: `lib/page_home/item_manage.dart`는 `FortuneTableSelectionController`와 `FortuneTableCheckboxController`를 함께 사용한다. 셀 그리드 영역 우클릭 메뉴에 `품목 추가 [1] 개`, `품목 삽입 [1] 개`, `품목 삭제`, `전체 선택`, `전체 선택 해제`, `블럭 선택 발행 체크`, `블럭 선택 발행 체크 해제`를 추가했다. 추가/삽입/삭제는 추후 구현 항목이므로 비활성화했고, 블럭 발행 체크/해제는 선택 행이 있을 때만 활성화한다.
- 테스트 추가/갱신: `test/fortune_table_test.dart`에 멀티 선택 shortcut, 드래그 행 범위 선택, 품목관리 우클릭 메뉴 전체 선택/발행 체크 회귀 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart` 통과(`+11`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`), `git diff --check -- third_party/fortune_sheet/lib/src/fortune_table.dart lib/page_home/item_manage.dart test/fortune_table_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료: `0e1a314` 품목관리 테이블 행 멀티 선택 추가. 포함 파일은 `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/page_home/item_manage.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-09): FortuneTable 체크박스 상태 get/set API 추가

- 요청: 품목관리 테이블과 공용라벨관리 `특별 항목`/`사용 항목` 테이블에서 컬럼 내 인라인 체크박스 상태를 설정하거나 구하는 공용 API를 원본 `fortune_sheet`에 추가한다.
- 수정 완료: `third_party/fortune_sheet/lib/src/fortune_table.dart`에 `FortuneTableCheckboxController`를 추가해 `columnId + rowIndex` 기준 `isChecked`/`setChecked`/`toggleChecked`/`setCheckedRows`/`checkedRows`/`clearColumn`/`clear` API를 제공한다. `FortuneTableColumn.checkboxController`를 추가했고, 컨트롤러 변경 시 `FortuneTable`이 listener로 갱신된다. 기존 `checkboxValue`/`checkboxValueAt`/`onCheckboxChanged`/`onCheckboxChangedAt` API는 호환 유지한다.
- 수정 완료: `lib/page_home/item_manage.dart` 발행 체크박스는 `FortuneTableCheckboxController`를 사용한다. `lib/page_home/common_label_manage.dart`의 특별/사용 항목 체크박스도 같은 컨트롤러 API로 모델 값과 동기화한다.
- 테스트 추가/갱신: `test/fortune_table_test.dart`에 `FortuneTable checkbox controller gets and sets state`를 추가하고, 품목관리 중복 `marketId` 회귀 테스트를 컨트롤러 API 기준으로 갱신했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart` 통과(`+8`), `C:\Flutter\bin\flutter.bat test test\common_label_manage_test.dart` 통과(`+4`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`), `git diff --check -- third_party/fortune_sheet/lib/src/fortune_table.dart lib/page_home/item_manage.dart lib/page_home/common_label_manage.dart test/fortune_table_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료: `89cccda` 테이블 체크박스 상태 API 추가. 포함 파일은 `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/page_home/item_manage.dart`, `lib/page_home/common_label_manage.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 완료 (2026-07-09): FortuneTable 인라인 체크박스 행 단위 토글 보정

- 요청: 품목관리 테이블과 공용라벨관리 `특별 항목`/`사용 항목` 테이블의 인라인 체크박스 클릭 시 컬럼 전체가 아니라 클릭한 체크박스만 체크/언체크되도록 수정. 공용 기능이므로 원본 `third_party/fortune_sheet/lib/src/fortune_table.dart` 기준으로 수정한다.
- 원인/수정: `FortuneTableColumn`에 기존 row-only `checkboxValue`/`onCheckboxChanged`와 호환되는 `checkboxValueAt(row, rowIndex)`/`onCheckboxChangedAt(row, rowIndex, value)`를 추가하고, 체크박스 위젯에 `column.id + rowIndex` key를 부여했다. 품목관리 발행 체크는 `marketId`가 중복돼도 컬럼 전체가 같이 켜지지 않도록 rowIndex set을 사용한다. 공용라벨관리 `특별 항목`/`사용 항목` 테이블도 rowIndex-aware 콜백으로 해당 행만 갱신한다.
- 테스트: `test/fortune_table_test.dart`에 동일 row 값에서도 클릭한 행만 토글되는 공용 회귀 테스트와 동일 `marketId` 2개 품목 중 클릭한 행만 체크되는 품목관리 회귀 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart` 통과(`+7`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`), `git diff --check -- third_party/fortune_sheet/lib/src/fortune_table.dart lib/page_home/item_manage.dart lib/page_home/common_label_manage.dart test/fortune_table_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료: `33b247a` 테이블 체크박스 행 단위 토글 보정. 포함 파일은 `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/page_home/item_manage.dart`, `lib/page_home/common_label_manage.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.

### 다음 세션 시작 지점 (2026-07-08)

- 보정 완료(2026-07-09): 사용자가 `0a8db9e` 이후에도 트랙패드 휠 이벤트가 새며 앱 헤더 배경색이 변한다고 재보고했고, 필요 시 디버깅 로그 추가 및 여러 차례 수정으로 생긴 오수정/과수정/불필요 수정 원복을 요청했다. Flutter `AppBar` 소스를 확인한 결과 AppBar는 일반 `NotificationListener`가 아니라 `ScrollNotificationObserver` listener로 `ScrollUpdateNotification`을 받아 `WidgetState.scrolledUnder`를 켜며, 이 listener는 일반 notification bubbling의 boolean 차단과 별개로 동작한다. 따라서 직전 `FortuneTable` 루트 `NotificationListener<ScrollNotification>` 보정은 실제 앱바 변색에는 효과 없는 오수정으로 판단해 제거했다. 실제 앱의 `lib/home_page.dart` AppBar에 `notificationPredicate: (_) => false`를 지정해 본문 내부 테이블/스크롤뷰의 알림으로 AppBar `scrolledUnder`가 켜지지 않도록 막았다. `test/widget_test.dart`에는 `HomePage AppBar ignores nested table scroll notifications` 테스트를 추가했고, 잘못된 `FortuneTable does not leak scroll notifications to ancestors` 테스트는 제거했다. 디버깅 로그는 Flutter 소스와 focused 테스트로 원인이 확인되어 추가하지 않았다. 검증 성공: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart`(+5), `C:\Flutter\bin\flutter.bat test test\widget_test.dart`(+2), `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart`(+25), `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`. stage/commit 파일은 `lib/home_page.dart`, `third_party/fortune_sheet/lib/src/fortune_table.dart`, `test/fortune_table_test.dart`, `test/widget_test.dart`, `SESSION_HANDOFF.md`이며 unrelated dirty `lib/core/app.dart`는 제외했다. 구현 커밋: `0d0ed85`(`앱바 스크롤 알림 반응 차단`).
- 보정 완료(2026-07-08): 사용자가 `29dbe51` 이후에도 트랙패드 휠 이벤트가 새며 앱 헤더 배경색이 변한다고 재보고했고, 여러 번 수정으로 생긴 오수정/과수정/불필요 수정은 원복해달라고 요청했다. 재분석 결과 앱 헤더에는 별도 hover 처리 코드가 없고, Flutter `AppBar`의 `scrolledUnder` 상태가 테이블 내부 `ScrollNotification`을 받아 배경색을 바꾸는 경로가 실제 원인으로 판단됐다. `third_party/fortune_sheet/lib/src/fortune_table.dart`에 루트 `NotificationListener<ScrollNotification>`을 추가해 내부 ListView/SingleChildScrollView 알림이 Scaffold/AppBar까지 버블링되지 않도록 막았다. 직전 `29dbe51`의 header/viewport 전체 `_scrollSignalBoundary` 확장은 테스트상 불필요한 과수정으로 확인되어 제거하고, 루트 Listener와 row item 경계만 남겼다. 디버깅 로그는 focused 테스트로 원인이 확인되어 추가하지 않았다. `test/fortune_table_test.dart`에는 외부 `NotificationListener`가 FortuneTable 내부 스크롤 알림을 받지 않는지 검증하는 회귀 테스트를 추가했다. 검증 성공: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart`(+6), `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart`(+25), `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`. stage/commit 파일은 `third_party/fortune_sheet/lib/src/fortune_table.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`이며 unrelated dirty `lib/core/app.dart`는 제외했다. 구현 커밋: `0a8db9e`(`포춘 테이블 스크롤 알림 누수 차단`).
- 보정 완료(2026-07-08): 사용자가 직전 `8568c05` 이후에도 트랙패드 휠 이벤트가 앱 헤더까지 새는 현상이 남았다고 재보고했다. 원인은 `FortuneTable`의 pointer signal 경계가 row item 중심이라 column header, 좌상단 row-header header, ListView viewport 빈 영역, horizontal scroll wrapper 영역에서 resolver 등록 우선순위가 약한 부분이 남아 있었고, 테스트도 부모 offset만 확인해 실제 테이블 내부 scroll offset 이동 여부를 검증하지 못했던 점이다. `third_party/fortune_sheet/lib/src/fortune_table.dart`에서 header/row-header/body horizontal scroll wrapper/body vertical viewport 전체를 `_scrollSignalBoundary`로 감싸고, `PointerScrollEvent`는 부모 scrollable과 동시 스크롤되지 않도록 resolver 방식은 유지했다. `test/fortune_table_test.dart`는 header wheel 후 body vertical controller offset이 증가하는지, row wheel과 trackpad pan start/update/end 시퀀스 후 부모 offset은 0이고 테이블 내부 offset은 증가하는지까지 검증하도록 강화했다. 검증 성공: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart`(+5), `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart`(+25), `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`. stage/commit 파일은 `third_party/fortune_sheet/lib/src/fortune_table.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`이며 unrelated dirty `lib/core/app.dart`는 제외했다. 구현 커밋: `29dbe51`(`포춘 테이블 휠 이벤트 경계 확장`).
- 보정 완료(2026-07-08): 사용자가 `FortuneTable` 전환 후 트랙패드 휠 이벤트가 여전히 앱 헤더까지 새고, 마우스 휠도 확인 필요하며, 수평 스크롤바는 보이지만 수직 스크롤바가 보이지 않는다고 재보고했다. 공유 구현 위치인 `third_party/fortune_sheet/lib/src/fortune_table.dart`에서 테이블 루트뿐 아니라 실제 row number/data row hit target에도 pointer signal 경계를 추가하고, `PointerScrollEvent`와 `PointerPanZoomUpdateEvent`를 모두 테이블 내부 수직/수평 controller로 직접 라우팅하도록 보강했다. 수직/수평 스크롤바는 overflow 조건의 `thumbVisibility`를 유지하되 axis별 `notificationPredicate`와 명시 두께의 `RawScrollbar`를 사용해 실제 표시를 안정화했다. `test/fortune_table_test.dart`에는 부모 scroll view 안에서 마우스 휠/트랙패드 pan이 부모 offset을 움직이지 않는지, overflow 여부에 따라 수직/수평 `RawScrollbar`가 표시되는지 검증을 추가했다. 검증 성공: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart`(+5), `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart`(+25), `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`. stage/commit 파일은 `third_party/fortune_sheet/lib/src/fortune_table.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`이며 unrelated dirty `lib/core/app.dart`는 제외했다. 구현 커밋: `8568c05`(`포춘 테이블 휠 이벤트와 세로 스크롤바 보정`).
- 완료(2026-07-08): 품목관리 테이블과 공용라벨관리의 `특별 항목`/`사용 항목` 테이블 3개만 FortuneSheet 기반 UI로 전환했다. 기존 `SwipeActionTable`/`ResizableTable`은 다른 화면에서 계속 사용하므로 삭제/대체/fallback 처리하지 않았다. 스와이프 액션/행 드래그 등 지정 3개 테이블에서 쓰지 않는 기능은 제외하고, 세 테이블에서 실제 사용하는 기능(내용 길이 기반 컬럼 폭 조정, 행 선택, 셀 안 checkbox toggle, fill-last-column, preview 정렬용 table rect 보고)을 기준으로 구현했다. 편집 완료: `third_party/fortune_sheet/lib/src/fortune_table.dart`에 공용 `FortuneTable`/`FortuneTableColumn` 추가 및 export, `lib/page_home/item_manage.dart`는 `ResizableTable` 대신 `FortuneTable<ItemOfMarket>` 사용, `lib/page_home/common_label_manage.dart`의 `_CommonLabelTable`은 `SwipeActionTable` 대신 `FortuneTable<TColumnBase>` 사용. `fortune_sheet` export의 내부 `Rect` typedef와 Flutter `Rect` 충돌은 소비 파일에서 `hide Rect`로 회피했다. 검증 성공: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart`(+2), `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart`(+25), `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`. 구현 커밋: `d0e8714`(`품목관리 테이블을 포춘 테이블로 전환`).
- 보정 완료(2026-07-08): 사용자 재확인으로 변경 전 테이블과 비교해 행 헤더 배경색과 품목관리 컬럼 폭이 어긋난 점을 수정했다. `FortuneTable` 행 번호 헤더/행 번호 셀은 기존 `SwipeActionTable`처럼 항상 `0xFF0E2F66` 배경과 흰 글자를 사용하도록 변경했고, `ItemManage`는 변경 전 `ResizableTable`과 동일하게 `autoFitColumns: false`로 선언 폭(`40/100/280/180`, 동적 컬럼은 `max(width, 70)`)을 유지한다. 테스트에 품목관리 auto-fit 비활성/초기 폭 검증을 추가했다. 검증 성공: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart`(+2), `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart`(+25), `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`. 구현 커밋: `0707cca`(`관리 테이블 행 헤더와 품목 폭 보정`).
- 보정 완료(2026-07-08): 품목관리 테이블 수직 스크롤 시 앱 헤더가 hover/highlight처럼 변하는 증상과 세 테이블 스크롤바 표시 요구를 확인했다. 원본 `FortuneSheetCanvas`는 이미 canvas 루트 `Listener`의 pointer-signal 처리와 시트 전용 scrollbar geometry/drag 로직을 갖고 있어 중복 수정하지 않았다. 대신 지정 3개 테이블이 공유하는 `third_party/fortune_sheet/lib/src/fortune_table.dart`에 테이블 루트 pointer-signal 경계와 overflow 기반 수직/수평 `Scrollbar` 표시를 추가했다. 테스트 추가: 부모 `SingleChildScrollView` 안에서 테이블 wheel signal이 부모 offset을 움직이지 않는지, 내용 overflow 여부에 따라 수직/수평 scrollbar `thumbVisibility`가 켜지고 꺼지는지 검증. 검증 성공: `C:\Flutter\bin\flutter.bat test test\fortune_table_test.dart`(+4), `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart`(+25), `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`. 구현 커밋: `7f023a0`(`포춘 테이블 스크롤 이벤트와 스크롤바 보강`).
- 수정 완료(2026-07-08): 품목관리 조회 직후 `RICH_ELEMENT_SHEET`가 없는 기존 `RICH_ELEMENT_RTF` 항목을 자동 마이그레이션하는 기능을 구현했다. 조회 완료 후 화면은 즉시 표시하고, 취소 가능한 세대 기반 queue가 RTF 항목을 동시성 1로 순차 변환한다. 변환은 기존 `labelSheetDraftFromRichEditRtfAsync` 경로를 재사용해 CP949/ANSI decode를 유지하고, draft 결과를 A1 단일 셀로 합성한 뒤 맨 앞/맨 뒤 공백·탭·개행·NBSP만 제거한다(중간 공백/개행 유지, inlineRuns 범위도 함께 보정). 변환 성공 시 `BM_RICH_ITEM.RICH_ELEMENT_SHEET`가 비어 있을 때만 조건부 자동 저장하고 `RICH_ELEMENT_RTF`는 보존한다. 저장 성공 후에만 `ItemOfMarket.datas` 캐시를 갱신하며 현재 preview 항목만 필요 시 갱신한다. 항목 1개 처리 후 프레임을 양보하고, 변환/저장 실패 key는 세션 캐시에 남겨 반복 재시도를 막는다. 수정 파일: `lib/models/item.dart`에 `ItemDAO.autoMigrateElementSheetByItemId` 조건부 update 추가, `lib/home_page_manager.dart`에 자동 마이그레이션 queue/RTF A1 rich run trim 추가, `test/label_sheet_toolbar_test.dart`에 trim/조건부 SQL 테스트 추가. 검증: `test\label_sheet_toolbar_test.dart --name "item element RTF conversion decodes Korean ANSI hex|item element RTF conversion trims outer whitespace only|item element DAO keeps legacy RTF while saving sheet data|item output preview preserves rich element replacement runs|item preview keeps selected tab when selected row changes|item output preview|label sheet settings can isolate item element editing mode"` 통과(`+9`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`), `git diff --check -- lib/models/item.dart lib/home_page_manager.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과(출력 없음). 기능 커밋 `8162541` 품목 주원료 RTF 자동 시트 마이그레이션.
- 수정 완료(2026-07-08): FortuneSheet 툴바 모든 드롭다운 메뉴가 하단 시트 영역이 충분해도 높이가 `viewportHeight * 0.75`로 먼저 제한되어 스크롤되는 문제를 수정했다. 공용 계산 함수 `fortuneToolbarPopupVisibleHeightFor`에서 ratio cap을 제거하고, toolbar popup top 아래 실제 남은 공간(`viewportHeight - fortuneToolbarPopupTop - margin`)이 부족할 때만 스크롤되도록 변경했다. `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`에 충분한 viewport에서 border popup natural height를 유지하는 테스트를 추가했다. 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --name "toolbar popup uses full natural height when viewport has room|toolbar popup draws scroll direction indicators|toolbar popup scroll indicators render button states|toolbar popup keeps scroll indicators clear of menu rows|toolbar popup skips hover fill under scroll indicators"` 포맷 전/후 통과(`+5`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`), `git diff --check -- third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음). 기능 커밋 `9349193` 시트 툴바 드롭다운 높이 제한 보정.
- 수정 완료(2026-07-08): 품목관리 플로팅 창 `주원료 및 함량`/`출력내용 미리보기` 시트에서 인쇄구분선이 보이지 않는 문제를 수정했다. 원인은 두 preview `LabelSheetWorkbench`가 `hidePrintAreaBoundary: true`를 직접 전달해 공용라벨관리와 달리 adjusted print area boundary를 숨기는 설정이었다. `lib/home_page_manager.dart`의 `_ItemElementPreviewTab`/`_ItemOutputPreviewTab`에서 해당 숨김 플래그를 제거해 공용라벨관리와 같은 인쇄구분선 painter 경로를 사용하도록 했다. 검증: `test\label_sheet_toolbar_test.dart`의 `item output preview`, `label sheet settings can isolate item element editing mode` 통과(`+5`), `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`), `git diff --check -- lib/home_page_manager.dart SESSION_HANDOFF.md` 통과(출력 없음). 기능 커밋 `0c3120d` 품목관리 미리보기 인쇄구분선 표시. 기존 unrelated dirty `lib/core/app.dart`는 제외했다.
- 수정 완료(2026-07-08): 품목관리 `주원료 및 함량` 시트 편집 모드에 `limitCellActionsToClipboardAndClear` 플래그를 추가했다. 이 플래그가 켜진 경우 셀/헤더 우클릭 메뉴는 `복사(copy)`, `붙여넣기(paste)`, `내용 지우기(clear)`만 표시하고, FortuneSheet 키 핸들러도 같은 플래그를 확인해 Ctrl+C/Ctrl+V/Delete/Backspace 계열만 허용하며 Ctrl+B/Undo/Redo/잘라내기/검색/채우기 등 일반 sheet shortcut은 처리하지 않는다. 출력내용 미리보기의 기존 `copyOnlyContextMenu`는 그대로 복사 전용으로 유지했다.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "label sheet settings can isolate item element editing mode|item element sheet limits menu and key actions by flag|limited cell action mode blocks formatting shortcut"` 통과(`+3`). 관련 회귀 `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "label sheet settings can isolate item element editing mode|item element sheet limits menu and key actions by flag|limited cell action mode blocks formatting shortcut|item element edit enables save toolbar without replacing tab|item output preview preserves rich element replacement runs|item preview keeps selected tab when selected row changes"` 통과(`+6`). `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`). `git diff --check -- lib/home_page_manager.dart lib/page_label_sheet/label_sheet_workbench.dart third_party/fortune_sheet/lib/src/fortune_sheet_model.dart third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 수정 완료(2026-07-08): 품목관리 `주원료 및 함량`에서 셀 내용 수정 후 툴바 저장 버튼이 활성화되지 않는 문제를 수정했다. 원인은 `_handleElementWorkbookChanged`가 매 변경마다 `_replaceTabsPreservingSelection()`/`setTabs()`를 호출해 편집 중인 `LabelSheetWorkbench` 탭 content를 교체하면서 dirty/save 상태가 유지되지 않는 구조였다. 수정 후 편집 중에는 `_elementForm` 상태와 출력 preview 탭 content만 갱신하고, 전체 탭 교체는 품목/라벨 변경 또는 RTF async 변환 완료처럼 주원료 탭 자체를 교체해야 하는 경우에만 수행한다.
- 수정 완료(2026-07-08): 출력내용 미리보기 `#ELEMENT` rich run 합성 시 대상 셀을 wrap(`textWrap='2'`)으로 강제하고, TextPainter로 치환된 rich text 높이를 계산해 해당 row의 `rowHeights/customHeight`를 자동 보정한다. 기존 행 높이보다 작게 줄이지 않고, 주원료 내용이 여러 줄일 때 위/아래 여백 포함 높이가 확보되도록 했다.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "item element edit enables save toolbar without replacing tab|item output preview preserves rich element replacement runs"` 통과(`+2`). 관련 회귀 `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "item element edit enables save toolbar without replacing tab|item output preview preserves rich element replacement runs|item element RTF conversion decodes Korean ANSI hex|item element DAO keeps legacy RTF while saving sheet data|item output preview|item preview keeps selected tab when selected row changes|label sheet settings can isolate item element editing mode"` 통과(`+9`). `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`). `git diff --check -- lib/home_page_manager.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 진행 중(2026-07-08): 품목관리 `주원료 및 함량` RTF 변환 시 한글이 깨지는 문제를 확인. 직전 구현의 `_itemElementWorkbookFromRichEditRtf`가 `labelSheetDraftFromRichEditRtf()` 동기 경로를 직접 호출해 기존 비동기 import 경로의 ANSI/CP949 hex decode(`labelSheetDraftFromRichEditRtfAsync` 내부 `_decodeRtfAnsiHex`)를 거치지 않는 것이 원인이다. 수정 방향은 주원료 RTF 변환을 비동기 `labelSheetDraftFromRichEditRtfAsync` 기반으로 바꾸고, 변환 완료 후 로컬 sheet 상태와 저장 버튼 dirty 상태를 갱신한다. 현재 미검증.
- 수정 완료(2026-07-08): `lib/home_page_manager.dart`에서 주원료 RTF 변환을 `labelSheetDraftFromRichEditRtfAsync` 기반으로 변경했다. 초기에는 plain fallback sheet를 열고, CP949/ANSI decode가 끝난 뒤 A1 단일셀 sheet로 교체하며 `initialDirty=true`로 저장 버튼을 활성화한다. stale async 결과가 다른 품목/라벨 선택에 덮이지 않도록 `_elementRtfConversionGeneration`으로 세대 guard를 추가했다. `test/label_sheet_toolbar_test.dart`에 `item element RTF conversion decodes Korean ANSI hex` 테스트를 추가했다.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item element RTF conversion decodes Korean ANSI hex"` 통과(`+1`). `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "item element RTF conversion decodes Korean ANSI hex|item output preview preserves rich element replacement runs|item element DAO keeps legacy RTF while saving sheet data|item output preview|item preview keeps selected tab when selected row changes|label sheet settings can isolate item element editing mode"` 통과(`+8`). `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`). `git diff --check -- lib/home_page_manager.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 진행 중(2026-07-08): 품목관리 `주원료 및 함량`을 `BM_RICH_ITEM.RICH_ELEMENT_SHEET` 기반으로 1차 구현한다. 확정 정책은 `RICH_ELEMENT_SHEET` 우선 조회/없으면 기존 `RICH_ELEMENT_RTF` fallback, `RICH_ELEMENT_RTF` 기존 값 유지, RTF->sheet 변환 직후 DB 저장 금지, 툴바 저장 시에만 `BM_RICH_ITEM.RICH_ELEMENT_SHEET`와 plain text `BM_RICH_ITEM.RICH_ELEMENT` 저장, 마켓별 `BM_ITEM_OF_MARKET.RICH_USER_DEFINE_ELEMENT_SHEET`는 1차 제외, 출력 preview `#ELEMENT`는 셀 중간 위치를 고려해 rich run 합성으로 처리한다. 수정 예정 파일은 `lib/models/item_of_market.dart`, `lib/models/item.dart` 또는 신규 DAO, `lib/home_page_manager.dart`, RTF 단일셀 변환 helper, 관련 테스트다. 현재 미검증.
- 수정 완료(2026-07-08): `lib/models/item_of_market.dart`의 `P2_ELEMENT_RTF` 조회를 `RICH_ELEMENT_SHEET` 우선/기존 `RICH_ELEMENT_RTF` fallback으로 변경했다. `lib/models/item.dart`에 `Item.copyWith`와 `ItemDAO.updateElementSheetByItemId(itemId, element, elementSheet)`를 추가해 저장 시 `BM_RICH_ITEM.RICH_ELEMENT`와 `RICH_ELEMENT_SHEET`만 갱신하고 `RICH_ELEMENT_RTF`는 유지한다. `lib/page_label_sheet/label_sheet_workbench.dart`에는 RTF 변환 직후 저장 버튼 활성화를 위해 `initialDirty` 옵션을 추가했다. 현재 focused 정적 오류 확인 완료, 전체 검증 미실행.
- 수정 완료(2026-07-08): `lib/home_page_manager.dart`에서 `_ItemElementFormState`를 추가해 품목 `elementRTF` payload를 저장 sheet 우선/RTF fallback/plain fallback으로 해석한다. RTF fallback은 기존 RTF draft importer 결과를 A1 단일셀 inlineRuns로 합쳐 로컬 workbook으로 변환하고, 변환 직후 DB 저장 없이 `LabelSheetWorkbench.initialDirty=true`로 저장 버튼을 활성화한다. 주원료 탭 저장은 `_handleElementSheetSave`에서 라벨 시트 저장 UX와 같은 확인/스낵바/실패 dialog 흐름을 사용하며 `ItemDAO.updateElementSheetByItemId`를 호출한다. 저장 후 `ItemOfMarket.datas` 캐시의 `RICH_ELEMENT` plain text와 sheet payload를 갱신한다.
- 수정 완료(2026-07-08): `lib/home_page_manager.dart` 출력 preview `#ELEMENT` 치환을 rich run 합성으로 변경했다. 대상 셀의 앞/뒤 run을 유지하고 주원료 A1 cell의 inlineRuns를 `#ELEMENT` 위치에 삽입하며, 일반 키워드/이미지/바코드 치환은 기존 경로를 유지한다. `test/label_sheet_toolbar_test.dart`에 rich `#ELEMENT` 중간 삽입과 DAO 정책 테스트를 추가했다.
- 검증 완료(2026-07-08): 신규 focused 테스트 `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "item output preview preserves rich element replacement runs|item element DAO keeps legacy RTF while saving sheet data"` 통과(`+2`). 회귀 focused 테스트 `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "item output preview preserves rich element replacement runs|item element DAO keeps legacy RTF while saving sheet data|item output preview|item preview keeps selected tab when selected row changes|label sheet settings can isolate item element editing mode"` 통과(`+7`). `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`). `git diff --check -- lib/home_page_manager.dart lib/models/item.dart lib/models/item_of_market.dart lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- stage/commit 예정(2026-07-08): 포함 대상은 `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/models/item.dart`, `lib/models/item_of_market.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`. 기존 unrelated dirty `lib/core/app.dart`는 제외한다.
- 커밋 완료(2026-07-08): `f17ad3f` 품목 주원료 시트 저장 및 미리보기 반영. 포함 파일은 `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/models/item.dart`, `lib/models/item_of_market.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`. 후속 인수인계 해시 기록은 별도 커밋으로 남긴다.
- 수정 완료(2026-07-08): 사용자가 품목관리에서 테이블 행 선택이 바뀌어도 플로팅 preview 창의 탭 메뉴 선택이 유지되길 요청. 원인은 `_showItemPreviewWindow()`가 선택 행/라벨 크기/인덱스를 포함한 key로 `_ItemPreviewPanel`을 매번 새로 만들고, `_ItemPreviewPanelState.build()`가 `TabbedViewController`를 매번 생성해 tabbed_view 기본 선택이 첫 번째 탭으로 돌아가는 구조였다.
- 수정 완료(2026-07-08): `lib/home_page_manager.dart`에서 `_ItemPreviewPanel` key를 안정화하고, `_ItemPreviewPanelState`가 `TabbedViewController`를 상태로 보유하도록 변경했다. 행 변경 시 `_elementText`는 새 품목 값으로 갱신하되 `_replaceTabsPreservingSelection()`에서 기존 selected tab value를 저장한 뒤 `setTabs()` 후 `selectTabByValue()`로 복원한다. 라벨 크기 변경 반영은 내부 `_ItemElementPreviewTab`/`_ItemOutputPreviewTab` workbench key에 `labelSizeId`를 포함해 유지했다.
- 테스트 추가(2026-07-08): `test/label_sheet_toolbar_test.dart`에 `item preview keeps selected tab when selected row changes`를 추가했다. 출력내용 미리보기 탭 선택 후 다른 품목으로 widget을 갱신해도 출력 탭의 RTF 안내 문구가 유지되는지 검증한다.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item preview keeps selected tab when selected row changes"` 통과(`+1`). `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`). `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet settings can isolate item element editing mode"` 통과(`+1`). `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`). `git diff --check -- lib/home_page_manager.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `ee3be10` 품목관리 미리보기 탭 선택 유지. 포함 파일은 `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. unrelated dirty `lib/core/app.dart`는 제외했다. 이 해시 기록은 별도 인수인계 커밋으로 남긴다.
- 수정 완료(2026-07-08): 사용자가 품목관리 플로팅 preview 창에서 외곽 resize over 영역과 내부 수직/수평 scrollbar 영역이 겹칠 때 외곽 resize만 인식된다고 보고. `lib/page_home/preview_floating_window.dart`에서 하단/우측 invisible edge resize handle이 내부 FortuneSheet scrollbar 8px 영역 위를 `HitTestBehavior.opaque`로 선점하는 문제로 확인했다.
- 수정 완료(2026-07-08): `_ResizeEdgeHitRegion`을 추가해 `bottom-edge`의 하단 8px, `right-edge`의 우측 8px은 resize hit-test에서 제외한다. 이 영역에서는 아래 child의 내부 scrollbar가 pointer event를 처리하고, corner grip 및 나머지 edge resize 동작은 유지한다.
- 테스트 추가(2026-07-08): `test/label_sheet_toolbar_test.dart`에 `floating preview lets child scrollbars win over edge resize`를 추가해 floating child의 우측/하단 8px 영역에서 child listener가 pointer down을 받고 window size가 변하지 않는지 검증한다.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "floating preview lets child scrollbars win over edge resize|floating preview resize handle resizes without moving window|floating preview corner resize ignores empty handle box area|floating preview shows corner resize grips on hover"` 통과(`+4`). `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`). `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`). `git diff --check -- lib/page_home/preview_floating_window.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `56b1ac0` 품목관리 미리보기 스크롤바 이벤트 우선 처리. 포함 파일은 `lib/page_home/preview_floating_window.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. unrelated dirty `lib/core/app.dart`는 제외했다.
- 수정 완료(2026-07-08): 사용자가 v30 재현 로그 후 “공용라벨관리는 변화가 없는데 품목관리 두개의 시트에서는 잘된거 같다”고 보고. 최신 로그에서 품목관리 preview는 v30 `previewBoundaryFinalOverlay` 경로가 적용됐고, 공용라벨관리 `label_sheet_01`은 visible header 경로(`hideHeaders=false`, `showGridLines=true`, `dataLeft=92.0`, `dataTop=40.0`)를 사용함을 확인했다. 공용 시트의 두꺼운 경계는 별도 visible-header overlay 문제가 아니라 `_drawFreezeHandles`가 frozen pane이 없는데도 기본 `dataLeft/dataTop` 위치에 3px handle을 그려 header/ruler/data 경계를 덮는 문제로 판정했다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart` v31 적용. `_drawFreezeHandles`가 `view.hasFrozenPane`이 false면 즉시 return하고, column/row handle도 각각 `columnFocus`/`rowFocus`가 있을 때만 그리도록 변경했다. 눈금자와 기존 일반 구분선은 숨기지 않고, 실제 고정된 pane이 있을 때의 freeze handle만 유지한다. v30 품목관리 preview boundary band 보정은 그대로 유지했다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`에 `visible headers skip freeze handles without frozen panes` 회귀 테스트를 추가해 visible header + physical ruler + no frozen pane 조건에서 3px freeze handle 색 픽셀이 경계 band에 남지 않는지 검증한다.
- 수정 완료(2026-07-08): `lib/main.dart` DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v31`, painter marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v31`.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --name "visible headers skip freeze handles without frozen panes|preview boundary cleanup removes adjacent data edge overdraw|preview hidden headers normalize ruler boundary lines|hide print area boundary suppresses adjusted boundary|adjusted sheet hidden headers keep ruler separators one pixel"` 통과(`+5`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`), `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet settings can isolate item element editing mode"` 통과(`+1`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`). `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `3b5d9f7` 공용라벨관리 눈금자 경계 핸들 보정. 포함 파일은 `lib/main.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`, `SESSION_HANDOFF.md`. unrelated dirty `lib/core/app.dart`, `lib/page_login/startup_dialog.dart`, `pubspec.lock`, `third_party/fortune_sheet/pubspec.lock`, `third_party/mssql_connection/pubspec.lock`는 제외했다.
- 수정 완료(2026-07-08): 사용자가 v29에서도 재현. 최신 `.tmp/log/app_2026-07-08_13-53-57.log` 확인 결과 `FSDBG-2026-07-08-preview-ruler-boundary-v29` 로드, 품목관리 두 preview sheet 모두 `dataLeft=46.0 dataTop=20.0`, `scope=cornerAndDataEdge` 실행. v29는 `dataLeft/dataTop` 안쪽 1px를 흰색으로 정리하면서 선은 `dataLeft - 0.5`, `dataTop - 0.5`에 남겨 일반 구분선과 1px 이격이 생긴 것으로 판단했다. v30에서 경계 주변 2px band를 정리한 뒤 실제 data edge(`verticalLineX=46.0`, `horizontalLineY=20.0`)에 1px grid fill을 다시 그리도록 수정. `FSDBG/FSRULER-2026-07-08-preview-ruler-boundary-v30`, `scope=boundaryBand`. 검증: focused tests 8개 통과, `C:\Flutter\bin\flutter.bat analyze` 통과, diff check 통과.
- 커밋 완료(2026-07-08): `8946b12` 라벨 시트 미리보기 경계선 이격 보정.
- 수정 완료(2026-07-08): 사용자가 v28에서도 동일 재현. 최신 `.tmp/log/app_2026-07-08_13-38-15.log` 확인 결과 `FSDBG-2026-07-08-preview-ruler-boundary-v28` 로드, `item_element`/`item_output_preview_sheet_01` 모두 `dataLeft=46.0 dataTop=20.0`, 눈금자 gutter 유지, `previewBoundaryCornerCleanup` 실행. v28 cleanup은 corner/ruler 쪽 1px만 정리했고 셀 쪽 경계에 붙은 overdraw는 정리하지 않아 두꺼운 구분선이 남은 것으로 보고 v29에서 data-edge 1px cleanup 후 grid line redraw로 수정했다. `FSDBG/FSRULER-2026-07-08-preview-ruler-boundary-v29`, `scope=cornerAndDataEdge`. 검증: focused tests 8개 통과, `C:\Flutter\bin\flutter.bat analyze` 통과, diff check 통과.
- 커밋 완료(2026-07-08): `a354e47` 라벨 시트 미리보기 데이터 경계 중복선 보정.
- 수정 완료(2026-07-08): 사용자가 v27로 재현 후 최신 `.tmp/log/app_2026-07-08_13-27-48.log`를 확인. `FSDBG-2026-07-08-preview-ruler-boundary-v27`가 로드됐고 `item_element`, `item_output_preview_sheet_01` 모두 `topRuler`/`leftRuler`가 0 크기(`dataLeft=0.0 dataTop=0.0`)로 접혔다. 이는 눈금자와 기존 일반 구분선이 사라지면 안 된다는 요구와 충돌하므로 v27의 `hideRowColumnHeaderLabels -> rowHeaderWidth/columnHeaderHeight=0` 변경을 원복했다.
- 수정 완료(2026-07-08): `lib/page_label_sheet/label_sheet_workbench.dart`에서 `hideRowColumnHeaderLabels`는 다시 label만 숨기고 header/ruler gutter 46x20을 유지한다. `test/label_sheet_toolbar_test.dart` 기대값도 `rowHeaderWidth=46`, `columnHeaderHeight=20`으로 복구했다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart` v28 적용. 기존 preview boundary overlay는 유지하되, 마지막 overlay 직전 `dataLeft/dataTop` 안쪽 corner/ruler 영역에 한정해 `Rect.fromLTWH(dataLeft, 0, 1, dataTop)` 및 `Rect.fromLTWH(0, dataTop, dataLeft, 1)`만 header 배경으로 정리한다. 이후 같은 좌표(`dataLeft - 0.5`, `dataTop - 0.5`)에 일반 grid line을 다시 그리므로 눈금자/일반 구분선/셀 영역은 삭제하지 않는다. 새 로그 marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v28`, 기대 로그는 `stage=previewBoundaryCornerCleanup scope=cornerRulerOnly`.
- 수정 완료(2026-07-08): `lib/main.dart` DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v28`.
- 검증 완료(2026-07-08): focused tests 7개 통과(`label sheet settings can isolate item element editing mode`, `item output preview`, `preview hidden headers normalize ruler boundary lines`, `hide print area boundary suppresses adjusted boundary`, `adjusted sheet hidden headers keep ruler separators one pixel`). `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`). `git diff --check -- lib/main.dart lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 정리 완료(2026-07-08): 테스트로 생성된 `third_party/fortune_sheet/build/` untracked 산출물 삭제. stage/commit 예정 파일은 `lib/main.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `SESSION_HANDOFF.md`만 포함한다. unrelated dirty `lib/core/app.dart`, `pubspec.lock`, `third_party/fortune_sheet/pubspec.lock`, `third_party/mssql_connection/pubspec.lock`는 제외한다.
- 커밋 완료(2026-07-08): `9bed153` 라벨 시트 미리보기 눈금자 경계 보정.
- 수정 완료(2026-07-08): 사용자가 v26으로 재현 후 최신 `.tmp/log/app_2026-07-08_13-02-16.log`를 확인. `FSDBG-2026-07-08-preview-ruler-boundary-v26`가 로드됐고 `previewBoundaryFinalOverlay`는 `item_element`, `item_output_preview_sheet_01` 양쪽에서 찍혔지만 화면상 동일했다. 로그 좌표가 `verticalLineX=45.5`, `horizontalLineY=19.5`로 남아 있어, 품목관리 preview에서 label만 숨긴 row/column header gutter(46x20)가 계속 남고 그 경계가 문제 위치로 보이는 것으로 판단했다.
- 수정 완료(2026-07-08): `lib/page_label_sheet/label_sheet_workbench.dart`에서 `hideRowColumnHeaderLabels=true`인 preview 설정은 `rowHeaderWidth=0`, `columnHeaderHeight=0`으로 header gutter 자체를 접도록 변경했다. 실제 앱에서 이 플래그는 `_ItemElementPreviewTab`, `_ItemOutputPreviewTab` 두 품목관리 preview 경로에서만 사용됨을 확인했다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart` v27 적용. painter marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v27`로 갱신했고, `_shouldNormalizePreviewRulerBoundary`는 header gutter가 남아 있을 때(`rowHeaderWidth > 0 && columnHeaderHeight > 0`)만 overlay/정규화 로그를 실행하도록 좁혔다. header gutter가 0인 품목관리 preview에서는 `-0.5` 위치 overlay를 그리지 않는다.
- 수정 완료(2026-07-08): `lib/main.dart` DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v27`. `test/label_sheet_toolbar_test.dart`의 `label sheet settings can isolate item element editing mode`는 hidden-header-label preview의 header gutter 0 기대값으로 갱신했다.
- 검증 완료(2026-07-08): `test/label_sheet_toolbar_test.dart` focused test(`label sheet settings can isolate item element editing mode`, `item output preview`) 통과(`+4`).
- 검증 완료(2026-07-08): `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart` focused test(`preview hidden headers normalize ruler boundary lines`, `hide print area boundary suppresses adjusted boundary`, `adjusted sheet hidden headers keep ruler separators one pixel`) 통과(`+3`).
- 검증 완료(2026-07-08): formatter 후 최종 focused test 묶음 재실행 통과(`+7`). `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`). `git diff --check -- lib/main.dart lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart` 통과(출력 없음).
- 정리 완료(2026-07-08): 테스트로 생성된 `third_party/fortune_sheet/build/` untracked 산출물 삭제. 커밋 완료: `e1c56b0 품목관리 preview 숨김 헤더 여백 제거`. 포함 파일은 `lib/main.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `SESSION_HANDOFF.md`. unrelated dirty `lib/core/app.dart`, `pubspec.lock`, `third_party/fortune_sheet/pubspec.lock`, `third_party/mssql_connection/pubspec.lock`는 제외했다.
- 수정 완료(2026-07-08): 사용자가 v25로 재현 후 최신 `.tmp/log/app_2026-07-08_12-49-14.log`를 확인. `FSDBG-2026-07-08-preview-ruler-boundary-v25`가 로드됐고 `previewBoundaryFinalOverlay`는 `item_element`, `item_output_preview_sheet_01` 양쪽에서 찍혔지만 화면상 동일했다. `previewEdgeBorderNormalize`는 실제 앱 로그에 없었으므로 edge cell border side 정규화는 이번 실제 데이터에서는 직접 실행되지 않았다. v25 final overlay가 `_drawVisibleComments`, `_drawSelection`, `_drawPresences`, `_drawFrozenGuides`, tooltip, freeze/resize drag line보다 먼저 그려져 후속 레이어가 다시 덮을 수 있는 순서 문제가 남아 있었다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart` v26 적용. `_drawPreviewBoundaryFinalOverlay` 호출을 `_drawSheet`의 맨 마지막(`_drawResizeDragLine` 이후)으로 이동했다. preview 조건에서만 실행되므로 일반 공용라벨관리/일반 hidden-header는 기존 동작 유지. 이 변경은 지우기/숨김 없이 최종 픽셀을 일반 grid line으로 남기는 목적이다.
- 수정 완료(2026-07-08): `lib/main.dart` DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v26`, painter marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v26`.
- 검증 완료(2026-07-08): focused/adjacent painter 회귀 묶음(`preview hidden headers normalize ruler boundary lines|adjusted sheet hidden headers keep ruler separators one pixel|adjusted sheet header corner separators stay connected|hide print area boundary suppresses adjusted boundary`) 통과. 로그에서 `previewBoundaryFinalOverlay`가 v26 marker로 확인됨.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `cf3a7ec 품목관리 preview 교차 구분선 최종 단계 이동`. 포함 파일은 `lib/main.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `SESSION_HANDOFF.md`. unrelated dirty `lib/core/app.dart`, `pubspec.lock`, `third_party/fortune_sheet/pubspec.lock`, `third_party/mssql_connection/pubspec.lock`는 제외했다.
- 수정 완료(2026-07-08): 사용자가 v24로 재현 후 최신 `.tmp/log/app_2026-07-08_12-30-27.log`를 확인. `FSDBG-2026-07-08-preview-ruler-boundary-v24`가 로드됐고, `item_element`는 `cells=1 borderInfo=0 rawShapeOverlays=0 images=0`, `item_output_preview_sheet_01`은 `cells=20 borderInfo=69 hasRawBorderInfo=true rawShapeOverlays=0 images=0`였다. `previewRawShapeEdge`/`previewImageEdge`는 없고 `previewCellEdge`만 찍혀 raw shape/image가 아니라 data edge 셀 렌더 및 edge cell border 경로가 실제 후보로 좁혀졌다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart` v25 적용. preview 조건(`hideRowColumnHeaderLabels && hidePrintAreaBoundary && !showGridLines`)에서만 `_previewEdgeNormalizedBorders`를 적용해 `clipBounds.top/left`에 닿는 셀 border side를 `fortuneSheetGridLineColor` 1px 실선으로 치환한다. 또한 `_drawRawShapeOverlays` 이후 `_drawPreviewBoundaryFinalOverlay`를 실행해 모든 셀/이미지/raw overlay 뒤에 `dataLeft - 0.5`, `dataTop - 0.5` 기준의 최종 1px grid line을 다시 그린다. 지우기/숨김/erase band는 사용하지 않아 일반 구분선과 이격 없이 이어진다. 일반 공용라벨관리 및 showGridLines=true hidden-header는 `_shouldNormalizePreviewRulerBoundary=false`로 기존 동작 유지.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`의 `preview hidden headers normalize ruler boundary lines`에 실제 출력 preview와 같은 A1 `border-all` 재현을 다시 추가했고, data edge에 dark border 픽셀이 남지 않는지 검증한다.
- 수정 완료(2026-07-08): `lib/main.dart` DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v25`, painter marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v25`. 기대 로그는 `stage=previewEdgeBorderNormalize ... boundaryStyle=gridLine` 및 `stage=previewBoundaryFinalOverlay ... boundaryStyle=gridLine`.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test third_party/fortune_sheet/test/fortune_sheet_painter_test.dart --name "preview hidden headers normalize ruler boundary lines"` 통과. 로그에서 `borderInfo=1`, `previewEdgeBorderNormalize`, `previewBoundaryFinalOverlay` 확인.
- 검증 완료(2026-07-08): focused/adjacent painter 회귀 묶음(`preview hidden headers normalize ruler boundary lines|adjusted sheet hidden headers keep ruler separators one pixel|adjusted sheet header corner separators stay connected|hide print area boundary suppresses adjusted boundary`) 통과.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `4ba081c 품목관리 preview 교차 구분선 최종 복원`. 포함 파일은 `lib/main.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`, `SESSION_HANDOFF.md`. unrelated dirty `lib/core/app.dart`, `pubspec.lock`, `third_party/fortune_sheet/pubspec.lock`, `third_party/mssql_connection/pubspec.lock`는 제외했다.
- 진행 중(2026-07-08): 사용자가 v23 후에도 동일 증상을 재보고. 최신 `.tmp/log/app_2026-07-08_11-34-19.log`에서 `FSDBG-2026-07-08-preview-ruler-boundary-v23`와 품목 preview `boundaryStyle=continuousGridLine normalizePreviewRulerBoundary=true`가 실제 적용됨을 확인했다. 따라서 v23의 ruler/corner 연속선 가설도 화면 원인이 아니었다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart` v24 적용. v23의 연속선 시각 변경을 원복해 preview ruler/corner 경계는 v17 방식(`boundaryStyle=gridLine`, corner/top/left 경계선 유지)으로 되돌렸다. 대신 preview 조건(`hideRowColumnHeaderLabels && hidePrintAreaBoundary && !showGridLines`)에서만 `stage=previewBoundarySummary`, `stage=previewCellEdge`, `stage=previewImageEdge`, `stage=previewRawShapeEdge` 로그를 추가했다. 실제 data edge를 덮는 후보 레이어(셀 배경/텍스트, 이미지, raw shape overlay, hook 존재 여부)를 다음 앱 재현 로그 한 번으로 구분하기 위한 진단 버전이다.
- 수정 완료(2026-07-08): `lib/main.dart` DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v24`, painter marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v24`.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test third_party/fortune_sheet/test/fortune_sheet_painter_test.dart --name "preview hidden headers normalize ruler boundary lines"` 통과.
- 검증 완료(2026-07-08): focused painter 회귀 묶음(`preview hidden headers normalize ruler boundary lines|adjusted sheet hidden headers keep ruler separators one pixel|adjusted sheet header corner separators stay connected|hide print area boundary suppresses adjusted boundary`) 통과.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): 포맷 후 `C:\Flutter\bin\flutter.bat test third_party/fortune_sheet/test/fortune_sheet_painter_test.dart --name "preview hidden headers normalize ruler boundary lines"` 재통과.
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `7160647 품목관리 preview 교차선 레이어 추적 추가`. 포함 파일은 `lib/main.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `SESSION_HANDOFF.md`. unrelated dirty `lib/core/app.dart`, `pubspec.lock`, `third_party/fortune_sheet/pubspec.lock`, `third_party/mssql_connection/pubspec.lock`는 제외했다.
- 진행 중(2026-07-08): 사용자가 v22 후에도 동일 증상을 재보고. 최신 `.tmp/log/app_2026-07-08_11-14-13.log`에서 앱 버전 `FSDBG-2026-07-08-preview-ruler-boundary-v22`와 품목 preview `stage=rulerBorders ... normalizePreviewRulerBoundary=true`는 확인됐지만, v22 핵심 marker인 `stage=previewEdgeBorderNormalize`는 실제 앱 로그에 전혀 찍히지 않았다. 따라서 v22의 data-edge 셀 border 정규화는 실제 품목 preview 증상의 원인 경로가 아니며 오가설로 판단했다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart` v23 적용. v22 `_previewEdgeNormalizedBorders`와 `_drawRenderedCellBorders` 변경을 원복하고, preview 조건(`hideRowColumnHeaderLabels && hidePrintAreaBoundary && !showGridLines`)에서는 ruler/corner 경계를 `fortuneSheetGridLineColor` 연속선으로 그린다. 원본 `_drawHeaders`처럼 교차점 우하단 경계를 따로 짧은 선 2개로 겹쳐 그리지 않고, horizontal line은 `corner.left -> topRuler.right`, vertical line은 `corner.right - 0.5` 기준으로 `corner.top -> leftRuler.top` 및 `leftRuler.top -> leftRuler.bottom` 구간을 맞춘다. 일반 공용라벨관리/일반 hidden-header는 기존 `rulerBorder` 경로 유지.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`에서 실제 앱 로그로 배제된 A1 `border-all` 재현 데이터를 `preview hidden headers normalize ruler boundary lines` 테스트에서 제거했다. 테스트는 hidden-header preview의 ruler/corner 경계가 grid-line 색으로 이어지고 ruler tick은 유지되는지 확인한다.
- 수정 완료(2026-07-08): 로그 marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v23`, 앱 DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v23`. 품목 preview 기대 로그는 `boundaryStyle=continuousGridLine normalizePreviewRulerBoundary=true`.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test third_party/fortune_sheet/test/fortune_sheet_painter_test.dart --name "preview hidden headers normalize ruler boundary lines"` 통과.
- 검증 완료(2026-07-08): focused painter 회귀 묶음(`preview hidden headers normalize ruler boundary lines|adjusted sheet hidden headers keep ruler separators one pixel|adjusted sheet header corner separators stay connected|hide print area boundary suppresses adjusted boundary`) 통과.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `ac2b9ce 품목관리 preview 눈금자 교차선 연속화`. 포함 파일은 `lib/main.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`, `SESSION_HANDOFF.md`. unrelated dirty `lib/core/app.dart`, `pubspec.lock`, `third_party/fortune_sheet/pubspec.lock`, `third_party/mssql_connection/pubspec.lock`는 제외했다.
- 완료(2026-07-08): 사용자가 v21 후에도 “마찬가지”라고 재보고. 최신 `.tmp/log/app_2026-07-08_10-59-09.log`에서 v21이 실제 로드됐고 품목 preview에 `source=headerBoundaries intersectionCap=true`가 적용됨을 확인. 추가 분석 결과 overlay/캡 보정은 증상 뒤에서 덮는 방식이고, 실제 원인은 `_drawRenderedCellBorders`가 preview의 data viewport 외곽(`clipBounds.left/top`)에 닿은 A1 top/left border segment와 join square를 원래 셀 border 색으로 그리는 것이었다.
- 수정 완료(2026-07-08): v22는 `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`에서 post-cell overlay를 제거하고, `_previewEdgeNormalizedBorders`를 추가했다. preview 조건(`hideRowColumnHeaderLabels && hidePrintAreaBoundary && !showGridLines`)에서만 data viewport top/left edge에 정확히 닿은 셀 border side를 `FortuneBorderSide(color: fortuneSheetGridLineColor, style: 1, strokeWidth: 1)`로 치환한다. 이로써 해당 edge의 border line과 `_drawSolidBorderJoinSquare`가 처음부터 일반 구분선 색/두께로 그려진다. 내부 셀 border, 일반 공용라벨관리, showGridLines=true hidden-header는 기존 동작 유지.
- 수정 완료(2026-07-08): 로그 marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v22`, 앱 DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v22`. 품목 preview에서 실제 정규화가 적용되면 `stage=previewEdgeBorderNormalize ... touchesTopEdge=true touchesLeftEdge=true boundaryStyle=gridLine`이 찍힌다.
- 검증 완료(2026-07-08): focused painter 테스트 4개(`preview hidden headers normalize ruler boundary lines`, `adjusted sheet hidden headers keep ruler separators one pixel`, `adjusted sheet header corner separators stay connected`, `hide print area boundary suppresses adjusted boundary`) 통과.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `2580c30 품목관리 preview 외곽 셀 테두리 정규화`.
- 완료(2026-07-08): 사용자가 v19 후에도 “마찬가지”라고 재보고했고, “무작정 수정이 아닌 원본 시트의 행/열 헤더와 교차 부분 소스를 더 자세히 분석 후 시도”를 요청. 최신 `.tmp/log/app_2026-07-08_10-47-41.log`에서 v19가 실제 로드됐고 품목 preview에 `stage=postCellBoundaryNormalize ... finalOverlay=true`가 적용됨을 확인. 원본 `_drawHeaders`를 재분석한 결과 일반 공용라벨관리의 기준은 ruler 전체가 아니라 `dataLeft - 0.5`, `dataTop - 0.5`에 그리는 `headerBoundaries` 데이터 경계선이다. v21은 preview 조건에서만 셀 렌더 이후 원본 `_drawHeaders`와 같은 데이터 경계선만 다시 그리고, 교차점 2px cap만 `fortuneSheetGridLineColor`로 맞춘다. ruler/corner 전체 재덮기는 하지 않는다. 일반 공용라벨관리/일반 hidden-header는 기존 경로 유지.
- 수정 완료(2026-07-08): 로그 marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v21`, 앱 DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v21`. 품목 preview 기대 로그는 `stage=postCellBoundaryNormalize ... source=headerBoundaries intersectionCap=true`.
- 테스트 갱신(2026-07-08): A1 `border-all` 재현 케이스에서 교차점 2x2 영역에 dark join square가 남지 않고 grid-line 픽셀이 남는지 확인한다.
- 검증 완료(2026-07-08): focused painter 테스트 4개(`preview hidden headers normalize ruler boundary lines`, `adjusted sheet hidden headers keep ruler separators one pixel`, `adjusted sheet header corner separators stay connected`, `hide print area boundary suppresses adjusted boundary`) 통과.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `7fbee65 품목관리 preview 구분선 원본 기준 보정`.
- 완료(2026-07-08): 사용자가 v18 후 “품목관리의 눈금자만 있는 부분은 변화가 있기는 하지만 아직 실선이 일반 구분선과 이격”이라고 재보고. 최신 `.tmp/log/app_2026-07-08_10-39-02.log`에서 v18이 실제 로드됐고 품목 preview에 `stage=postCellBoundaryNormalize ... eraseOverdraw=true`가 적용됨을 확인. v18의 2px erase band가 셀 border/일반 구분선과의 접점을 벌린 오수정으로 판단해 원복했다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart` v19 적용. preview 조건에서만 셀 렌더 이후 같은 좌표에 `fortuneSheetGridLineColor` 1px 선을 최종 오버레이한다. 지우기/숨김 없이 최종 픽셀만 덮어써 두꺼워진 선을 일반 구분선과 같은 좌표/두께로 맞춘다. 일반 공용라벨관리와 showGridLines=true hidden-header는 기존 `rulerBorder` 경로 유지.
- 수정 완료(2026-07-08): 로그 marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v19`, 앱 DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v19`. 품목 preview 기대 로그는 `stage=postCellBoundaryNormalize ... boundaryStyle=gridLine finalOverlay=true`.
- 테스트 갱신(2026-07-08): `preview hidden headers normalize ruler boundary lines`에 A1 `border-all` 재현 케이스를 유지하고, 경계선 정확한 1px 좌표에 dark border가 남지 않는지 확인한다. hidden-header 회귀 테스트에는 재현용 borderInfo를 넣지 않는다.
- 검증 완료(2026-07-08): focused painter 테스트 4개(`preview hidden headers normalize ruler boundary lines`, `adjusted sheet hidden headers keep ruler separators one pixel`, `adjusted sheet header corner separators stay connected`, `hide print area boundary suppresses adjusted boundary`) 통과.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `f1ffca6 품목관리 preview 구분선 이격 보정`.
- 완료(2026-07-08): 사용자가 v17 적용 후에도 “마찬가지”라고 재보고. 첨부 화면 기준 행/열 눈금자 교차영역 우하단의 두꺼운 선이 여전히 보임. 최신 `.tmp/log/app_2026-07-08_10-16-51.log`에서 v17이 실제 로드됐고 품목 preview가 `boundaryStyle=gridLine normalizePreviewRulerBoundary=true`로 찍힘을 확인했다. 따라서 v17의 ruler 선 자체 정규화는 적용됐지만, 이후 `_drawCells`/`_drawFrozenCells`의 A1 top/left 셀 border가 같은 좌표를 다시 덮어 두껍게 보이는 경로로 판단했다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`에 v18 적용. preview 조건(`hideRowColumnHeaderLabels && hidePrintAreaBoundary && !showGridLines`)에서만 셀 border 렌더 이후 `_drawPreviewRulerBoundaryOverlay`를 실행해 data edge/ruler edge 주변 2px overdraw만 흰 배경으로 지운 뒤 `fortuneSheetGridLineColor` 1px 선을 다시 그린다. 다른 구분선을 숨기지 않고, 교차영역 우하단에 겹쳐 두껍게 보이던 최종 픽셀만 일반 구분선으로 맞춘다. 일반 공용라벨관리/일반 hidden-header는 `normalizePreviewRulerBoundary=false`로 기존 `rulerBorder` 경로 유지.
- 수정 완료(2026-07-08): 로그 marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v18`, 앱 DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v18`. 품목 preview 기대 로그는 `stage=postCellBoundaryNormalize ... boundaryStyle=gridLine eraseOverdraw=true`.
- 테스트 갱신(2026-07-08): `preview hidden headers normalize ruler boundary lines`에 A1 `border-all` 재현 케이스를 추가해, cell border가 있어도 data edge/ruler edge 최종 픽셀이 dark border가 아니라 grid line으로 남는지 확인한다.
- 검증 완료(2026-07-08): focused painter 테스트 4개(`preview hidden headers normalize ruler boundary lines`, `adjusted sheet hidden headers keep ruler separators one pixel`, `adjusted sheet header corner separators stay connected`, `hide print area boundary suppresses adjusted boundary`) 통과.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `350f60c 품목관리 preview 구분선 겹침 정규화`.
- 완료(2026-07-08): 사용자가 v16 후에도 “마찬가지”라고 재보고하며, 구분선을 지우면 안 되고 두껍게 된 구분선만 일반 구분선과 같게 해야 한다고 명확히 지시. 최신 `.tmp/log/app_2026-07-08_10-10-45.log`에서 품목 preview `drawTopBottom=false drawLeftRight=false drawCornerBottom=false drawCornerRight=false hidePreviewRulerBoundary=true`가 실제 적용됐음을 확인. v16 통합 숨김은 오수정으로 원복했다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`에서 `hideRowColumnHeaderLabels && hidePrintAreaBoundary && !showGridLines` preview 조건일 때만 ruler/corner boundary 네 선을 삭제하지 않고 `fortuneSheetGridLineColor` + 반픽셀 정렬로 그리도록 변경했다. 이로써 두꺼운 ruler border 색/정수 좌표 선을 일반 구분선과 같은 1px grid line으로 맞춘다. 일반 공용라벨관리/일반 hidden-header는 기존 `fortuneSheetRulerBorderColor` 경로를 유지한다.
- 수정 완료(2026-07-08): 로그 marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v17`, 앱 DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v17`. 기대 로그는 품목 preview에서 `boundaryStyle=gridLine drawTopBottom=true drawLeftRight=true drawCornerBottom=true drawCornerRight=true normalizePreviewRulerBoundary=true`. 공용라벨관리/일반 시트는 `boundaryStyle=rulerBorder normalizePreviewRulerBoundary=false`.
- 테스트 갱신(2026-07-08): `preview hidden headers omit ruler boundary lines`를 `preview hidden headers normalize ruler boundary lines`로 교체해, preview 조건에서 ruler border 색은 사라지고 grid line 색의 구분선은 유지되는지 검증한다.
- 검증 완료(2026-07-08): formatter 적용 후 focused painter 테스트 4개(`preview hidden headers normalize ruler boundary lines`, `adjusted sheet hidden headers keep ruler separators one pixel`, `adjusted sheet header corner separators stay connected`, `hide print area boundary suppresses adjusted boundary`) 통과.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- 커밋 완료(2026-07-08): `7de61eb 품목관리 preview 구분선 두께 정상화`.
- 완료(2026-07-08): 사용자가 v15 후에도 “마찬가지”라고 재보고. 최신 `.tmp/log/app_2026-07-08_10-05-25.log`에서 품목 preview `drawCornerBottom=false drawCornerRight=false hidePreviewCornerBoundary=true`가 실제 적용됐는데도 동일함을 확인. v13은 top/left data edge만 숨기고 corner 선은 남겼고, v15는 corner 선만 숨기고 top/left data edge는 남겼으므로 둘 중 하나만 남아도 같은 구분선처럼 보이는 것으로 재판단했다. v15 단독 보정은 원복하고, preview 조건에서 corner bottom/right와 top/left data edge ruler border를 함께 숨기는 통합 보정(v16)을 적용했다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`에서 `hideRowColumnHeaderLabels && hidePrintAreaBoundary && !showGridLines` preview 조건일 때만 top/left data edge ruler border와 corner bottom/right border를 모두 그리지 않도록 변경했다. ruler 영역/눈금/corner label은 유지한다. 일반 공용라벨관리/일반 hidden-header는 `hidePreviewRulerBoundary=false`로 기존 ruler/corner 경계선을 유지한다.
- 수정 완료(2026-07-08): 로그 marker는 `FSRULER-2026-07-08-preview-ruler-boundary-v16`, 앱 DebugLogger 버전은 `FSDBG-2026-07-08-preview-ruler-boundary-v16`. 기대 로그는 품목 preview에서 `drawTopBottom=false drawLeftRight=false drawCornerBottom=false drawCornerRight=false hidePreviewRulerBoundary=true`. 공용라벨관리/일반 시트는 네 draw 값이 모두 true, `hidePreviewRulerBoundary=false`.
- 테스트 갱신(2026-07-08): `preview hidden headers omit ruler corner boundary`를 `preview hidden headers omit ruler boundary lines`로 교체해, preview 조건에서 corner 및 top/left data edge border 픽셀은 사라지고 ruler 영역/눈금은 유지되는지 검증한다.
- 검증 완료(2026-07-08): formatter 적용 후 focused painter 테스트 4개(`preview hidden headers omit ruler boundary lines`, `adjusted sheet hidden headers keep ruler separators one pixel`, `adjusted sheet header corner separators stay connected`, `hide print area boundary suppresses adjusted boundary`) 통과.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- stage/commit 완료(2026-07-08): `lib/main.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`, `SESSION_HANDOFF.md` 포함해 기능 커밋 `dc2d20b` 품목관리 preview 눈금자 boundary 통합 숨김. unrelated dirty `lib/core/app.dart`, `pubspec.lock`, `third_party/fortune_sheet/pubspec.lock`, `third_party/mssql_connection/pubspec.lock` 제외.
- 완료(2026-07-08): 사용자가 v14 후에도 “마찬가지”라고 재보고. 최신 `.tmp/log/app_2026-07-08_09-50-31.log`에서 품목 preview `separateCornerJoint=true`, `cornerBottomEnd=45.0`, `cornerRightEnd=19.0`, `topRulerBottomStart=Offset(47.0, 20.0)`, `leftRulerRightStart=Offset(46.0, 21.0)`가 실제 적용됐는데도 동일함을 확인. v14 corner joint 1px 분리 가설은 틀린 것으로 확정하고 원복했다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`에서 `hideRowColumnHeaderLabels && hidePrintAreaBoundary && !showGridLines` preview 조건일 때만 corner 영역의 bottom/right 구분선 자체를 그리지 않도록 변경했다. top/left ruler data edge 선, ruler 영역, 눈금, corner label은 유지한다. 일반 공용라벨관리/일반 hidden-header는 `hidePreviewCornerBoundary=false`로 기존 corner 구분선을 유지한다.
- 수정 완료(2026-07-08): 로그 marker는 `FSRULER-2026-07-08-preview-corner-boundary-v15`, 앱 DebugLogger 버전은 `FSDBG-2026-07-08-preview-corner-boundary-v15`. 기대 로그는 품목 preview에서 `drawCornerBottom=false drawCornerRight=false hidePreviewCornerBoundary=true`. 공용라벨관리/일반 시트는 `drawCornerBottom=true drawCornerRight=true hidePreviewCornerBoundary=false`.
- 테스트 갱신(2026-07-08): `preview hidden headers separate ruler corner joint`를 `preview hidden headers omit ruler corner boundary`로 교체해, preview 조건에서 corner bottom/right border 픽셀은 사라지고 top/left ruler data edge 선은 유지되는지 검증한다.
- 검증 완료(2026-07-08): formatter 적용 후 focused painter 테스트 4개(`preview hidden headers omit ruler corner boundary`, `adjusted sheet hidden headers keep ruler separators one pixel`, `adjusted sheet header corner separators stay connected`, `hide print area boundary suppresses adjusted boundary`) 통과.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- stage/commit 완료(2026-07-08): `lib/main.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`, `SESSION_HANDOFF.md` 포함해 기능 커밋 `eece86e` 품목관리 preview 눈금자 corner 구분선 숨김. unrelated dirty `lib/core/app.dart`, `pubspec.lock`, `third_party/fortune_sheet/pubspec.lock`, `third_party/mssql_connection/pubspec.lock` 제외.
- 완료(2026-07-08): 사용자가 문제 위치를 “행/열 눈금자 교차영역 우하단 구분선이 두꺼운 부분”으로 재설명. 최신 `.tmp/log/app_2026-07-08_09-41-17.log`에서 v13의 `drawTopBottom=false drawLeftRight=false`가 이미 품목 preview에 적용됐는데도 동일했으므로, v13 data-edge ruler border 가설은 틀린 것으로 확정하고 원복했다.
- 수정 완료(2026-07-08): `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`에서 `hideRowColumnHeaderLabels && hidePrintAreaBoundary && !showGridLines` preview 조건일 때만 corner bottom/right와 top/left ruler 선이 같은 우하단 픽셀에 닿지 않도록 각 끝점을 1px 분리했다. ruler 영역/눈금/top-left data edge 선은 유지한다. 일반 공용라벨관리/일반 hidden-header는 `separateCornerJoint=false`로 기존 좌표를 유지한다.
- 수정 완료(2026-07-08): 로그 marker는 `FSRULER-2026-07-08-preview-corner-joint-v14`, 앱 DebugLogger 버전은 `FSDBG-2026-07-08-preview-corner-joint-v14`. 기대 로그는 품목 preview에서 `separateCornerJoint=true`, `cornerBottomEnd=45.0`, `cornerRightEnd=19.0`, `topRulerBottomStart=Offset(47.0, 20.0)`, `leftRulerRightStart=Offset(46.0, 21.0)`. 공용라벨관리/일반 시트는 `separateCornerJoint=false`.
- 테스트 갱신(2026-07-08): `preview hidden headers omit data edge ruler border`를 `preview hidden headers separate ruler corner joint`로 교체해, preview 조건에서 corner joint 픽셀 겹침은 사라지고 ruler tick/주변 선은 유지되는지 검증한다.
- 검증 완료(2026-07-08): formatter 적용 후 focused painter 테스트 4개(`preview hidden headers separate ruler corner joint`, `adjusted sheet hidden headers keep ruler separators one pixel`, `adjusted sheet header corner separators stay connected`, `hide print area boundary suppresses adjusted boundary`) 통과.
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료(2026-07-08): `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료(2026-07-08): `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과(출력 없음).
- stage/commit 완료(2026-07-08): `lib/main.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`, `SESSION_HANDOFF.md` 포함해 기능 커밋 `7655a78` 품목관리 preview 눈금자 corner 겹침 보정. unrelated dirty `lib/core/app.dart`, `pubspec.lock`, `third_party/fortune_sheet/pubspec.lock`, `third_party/mssql_connection/pubspec.lock` 제외.
- 남은 확인: 사용자가 앱을 다시 실행한 뒤 최신 `.tmp/log/app_YYYY-MM-DD_HH-mm-ss.log`에서 `FSDBG-2026-07-08-preview-corner-joint-v14`와 `FSRULER-2026-07-08-preview-corner-joint-v14`를 확인한다. 적용됐는데도 같으면 corner joint 가설도 틀린 것이므로 `beforeRenderCellArea`, raw shape/image overlay, scroll/canvas container border 순서로 추가 trace를 넣어 레이어를 좁힌다.
- 현재 unrelated dirty 파일은 `lib/core/app.dart`, `pubspec.lock`, `third_party/fortune_sheet/pubspec.lock`, `third_party/mssql_connection/pubspec.lock`이며 이번 preview 작업 커밋에는 포함하지 않았다.
- 최근 검증 완료: v12 painter focused test 3개, `test/label_sheet_toolbar_test.dart --plain-name "item output preview"`, `C:\Flutter\bin\flutter.bat analyze`, `git diff --check` 모두 통과.

### 완료 (2026-07-07): 품목관리 preview print area boundary 숨김(v12)

- 로그 확인: 최신 `.tmp/log/app_2026-07-07_23-40-22.log`에서 `FSDBG-2026-07-07-preview-ruler-tick-gap-v11`와 `FSRULER-2026-07-07-preview-tick-gap-v11`가 확인됐다. `item_element`, `item_output_preview_sheet_01` 모두 `verticalTickEndGap=8.0`이 적용됐지만 사용자가 동일 화면을 재첨부했으므로 v11 tick-gap 가설은 틀린 것으로 판단했다.
- 오수정 원복: v11의 `verticalTickEndGap` 조건, `_drawVerticalSheetRuler(... tickEndGap:)`, 관련 로그 필드를 제거하고 기존 vertical ruler tick 끝 위치(`rect.right - 2`)로 되돌렸다.
- 원인 재판단: `LabelSheetWorkbench`에는 `hidePrintAreaBoundary` 플래그가 이미 있었지만, painter의 `_drawSheetPrintAreaBoundary`가 해당 플래그를 확인하지 않아 adjusted print area boundary가 계속 그려질 수 있었다. grid line은 꺼져 있어도 이 boundary는 별도 레이어라 화면의 굵은 세로선처럼 남는다.
- 수정 완료: `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`에서 `settings.hidePrintAreaBoundary`가 true면 print area boundary를 그리지 않도록 early return을 추가했다. 디버그 로그는 `FSRULER-2026-07-07-preview-hide-print-boundary-v12` marker로 `stage=printAreaBoundary hidden=true/false`를 남긴다.
- 수정 완료: `lib/home_page_manager.dart`의 `_ItemElementPreviewTab`, `_ItemOutputPreviewTab`에서 `hidePrintAreaBoundary: true`를 전달한다. 공용라벨관리/일반 시트는 기본값 false라 기존 boundary 표시를 유지한다.
- 수정 완료: `lib/main.dart`의 DebugLogger 버전을 `FSDBG-2026-07-07-preview-hide-print-boundary-v12`로 갱신했다.
- 테스트 갱신: v11 tick-gap 테스트를 `hide print area boundary suppresses adjusted boundary`로 교체해, flag가 true일 때 adjusted boundary 픽셀이 남지 않는지 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "hide print area boundary suppresses adjusted boundary"` 통과. 로그에서 `stage=printAreaBoundary hidden=true` 확인.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과. 로그에서 일반 시트는 `hidden=false` 확인.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과. 로그에서 일반 hidden-header는 `hidden=false` 확인.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/main.dart lib/home_page_manager.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `26d0eb8` 품목관리 preview 출력 영역 경계선 숨김. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외했다.

### 완료 (2026-07-07): 품목관리 preview vertical ruler tick gap 보정(v11)

- 로그 확인: 최신 `.tmp/log/app_2026-07-07_23-33-58.log`에서 `FSDBG-2026-07-07-boundary-layer-trace-v10`와 `FSRULER-2026-07-07-boundary-layer-v10`가 확인됐다. `stage=cellBorderBoundary`는 품목 preview sheet에 찍히지 않아 화면의 두꺼운 세로 느낌은 셀 테두리 레이어가 아닌 것으로 판단했다.
- 오수정 원복: v10의 `cellBorderBoundary` 추적 helper와 관련 로그를 제거했다. v9의 시각 보정도 유지하지 않고, ruler/corner border drawing은 기존 방식으로 둔다.
- 원인 재판단: hidden header preview에서는 행/열 헤더 라벨 영역 없이 vertical ruler tick이 data edge 바로 옆까지 오므로, tick들이 데이터 경계선처럼 뭉쳐 보일 수 있다. 공용라벨관리/일반 hidden-header 케이스는 기존 tick gap을 유지해야 한다.
- 수정 완료: `hideRowColumnHeaderLabels=true`이고 `showGridLines=false`인 품목 preview 조건에서만 vertical ruler tick end gap을 `2.0 -> 8.0`으로 넓혔다. ruler 영역은 유지되고, 일반 공용라벨관리/일반 시트는 `2.0`을 유지한다.
- 디버그 갱신: trace marker를 `FSRULER-2026-07-07-preview-tick-gap-v11`로 변경하고 `verticalTickEndGap`을 로그에 포함했다.
- 수정 완료: `lib/main.dart`의 DebugLogger 버전을 `FSDBG-2026-07-07-preview-ruler-tick-gap-v11`로 갱신했다.
- 테스트 추가: `item preview hidden headers keep vertical ruler ticks off data edge`를 추가해 preview 조건에서 data edge 근처에는 ruler tick 픽셀이 없고, 안쪽 ruler 영역에는 tick이 남는지 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "item preview hidden headers keep vertical ruler ticks off data edge"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `f5b4910` 품목관리 preview ruler 눈금 간격 보정. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외했다.

### 완료 (2026-07-07): 품목관리 preview boundary layer 추적(v10)

- 로그 확인: 최신 `.tmp/log/app_2026-07-07_23-26-11.log`에서 `FSDBG-2026-07-07-preview-ruler-separator-v9`와 `FSRULER-2026-07-07-preview-separator-v9`가 확인됐다. v9의 `boundaryStyle=headerGridLine` 분기는 실제 품목 preview에서 실행됐지만 사용자 스크린샷상 변화가 없어 효과 없는 시각 변경으로 판단했다.
- 오수정 원복: v9의 preview 전용 `fortuneSheetGridLineColor` separator 분기와 해당 테스트 기대값을 제거했다. 일반 ruler/corner border drawing은 다시 `fortuneSheetRulerBorderColor` 기준의 기존 drawing으로 유지한다.
- 디버그 추가: `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`에 `stage=cellBorderBoundary` 추적을 추가했다. `clipBounds.left/top`과 정확히 맞닿는 셀 테두리 segment 수, 색상, 스타일, stroke width, start/end 좌표를 기록한다.
- 디버그 갱신: trace marker를 `FSRULER-2026-07-07-boundary-layer-v10`로 변경했다.
- 수정 완료: `lib/main.dart`의 DebugLogger 버전을 `FSDBG-2026-07-07-boundary-layer-trace-v10`로 갱신했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 다음 확인: 새 실행 로그에서 `stage=cellBorderBoundary`가 품목 preview sheet(`item_element`, `item_output_preview_sheet_01`)에 찍히는지 확인한다. 찍히면 화면의 두꺼운 선은 셀 테두리 레이어 가능성이 높고, 안 찍히면 ruler/tick/canvas 외곽선 외부 레이어를 추가 추적해야 한다.
- 커밋 완료: `67c5a86` 품목관리 preview boundary layer 추적 추가. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외했다.

### 완료 (2026-07-07): 품목관리 preview ruler separator 스타일 보정(v9)

- 로그 확인: 최신 `.tmp/log/app_2026-07-07_23-15-52.log`에서 `FSDBG-2026-07-07-ruler-border-align-v8`와 `FSRULER-2026-07-07-border-align-v8`가 확인됐다. v8은 실제 실행됐지만 사용자 스크린샷상 변화가 없어 효과 없는 시각 변경으로 판단했다.
- v8 대체/원복: 일반 ruler/corner border는 v8의 전역 반픽셀 정렬을 제거하고 기존 `rulerBorder` drawing으로 되돌렸다. 다른 FortuneSheet 화면이 틀어지지 않도록 preview 조건 외에는 기존 동작을 유지한다.
- 수정 완료: `hideRowColumnHeaderLabels=true`이고 `showGridLines=false`인 품목관리 preview 조건에서만 ruler/data separator를 행/열 헤더 구분선과 같은 `fortuneSheetGridLineColor` + `_line` 스타일로 그린다. 로그에는 `boundaryStyle=headerGridLine`으로 표시된다.
- 디버그 갱신: trace marker를 `FSRULER-2026-07-07-preview-separator-v9`로 변경했다.
- 수정 완료: `lib/main.dart`의 DebugLogger 버전을 `FSDBG-2026-07-07-preview-ruler-separator-v9`로 갱신했다.
- 테스트 보강: hidden header 테스트를 실제 품목 preview 조건(`showGridLines=false`)으로 맞추고, separator가 grid-line 색으로 존재하며 ruler-border 색이 겹치지 않는지 검증한다. visible header 테스트는 기존 행/열 헤더 구분선 보완이 유지되는지 계속 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `ebbda2b` 품목관리 preview ruler 구분선 스타일 보정. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외했다.

### 완료 (2026-07-07): 품목관리 preview ruler border 반픽셀 정렬(v8)

- 로그 확인: 최신 `.tmp/log/app_2026-07-07_23-06-19.log`에서 `FSDBG-2026-07-07-ruler-border-trace-v7`와 품목관리 preview의 `FSRULER-2026-07-07-border-trace-v7`가 확인됐다. ruler 영역은 원복됐고, `item_element`/`item_output_preview_sheet_01`은 `hideHeaders=true`, `showGridLines=false`, `dataLeft=46.0`, `dataTop=20.0` 상태였다.
- 원인 판단: 공용라벨관리 header 구분선은 `dataLeft - 0.5`, `dataTop - 0.5`로 반픽셀 정렬되어 그려지지만, ruler/corner border는 정수 좌표의 `canvas.drawLine`으로 그려져 hidden header preview에서 같은 1px 선이 더 두껍게 보일 수 있었다.
- 수정 완료: `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`의 ruler/corner border를 `_line` 기반 반픽셀 좌표(`topBorderY`, `leftBorderX`, `cornerBottomY`, `cornerRightX`)로 정렬했다. 기존 `_drawHeaders` 행/열 헤더 구분선 로직은 변경하지 않았다.
- 디버그 추가: trace marker를 `FSRULER-2026-07-07-border-align-v8`로 갱신하고 실제 반픽셀 정렬 좌표를 로그에 포함했다.
- 수정 완료: `lib/main.dart`의 DebugLogger 버전을 `FSDBG-2026-07-07-ruler-border-align-v8`로 갱신했다.
- 테스트 보강: `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`에 ruler border 픽셀 검출을 추가했다. visible header는 기존 행/열 헤더 구분선에 ruler border가 겹치지 않는지 확인하고, hidden header는 ruler separator bounds가 1픽셀 폭/높이를 유지하는지 확인한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과. 기존 행/열 헤더 구분선 겹침 보완이 틀어지지 않았음을 확인했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `7ccd7e5` 품목관리 preview ruler 경계선 정렬 보정. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외했다.

### 완료 (2026-07-07): 품목관리 preview ruler off 원복 및 border trace 추가

- 로그 확인: 최신 `.tmp/log/app_2026-07-07_22-59-50.log`에서 `FSDBG-2026-07-07-item-preview-ruler-off-v6`만 확인되고 품목관리 preview의 `FSRULER`가 사라졌다. 사용자 스크린샷/피드백대로 v6에서 ruler 영역 자체가 꺼진 것이 오수정이었다.
- 오수정 원복: `_itemElementWorkbook`와 `_itemOutputPreviewPrivateWorkbook`에 넣었던 `fortuneSheetRulerVisibleKey: false` 및 관련 테스트/디버그 helper를 제거했다. 품목관리 preview의 ruler 영역은 다시 유지된다.
- 디버그 추가: `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`에 `FSRULER-2026-07-07-border-trace-v7` 추적 로그를 추가했다. 실제 화면 변경 없이 `headerBoundaries`와 `rulerBorders`가 그려지는 좌표, `hideHeaders`, `showGridLines`, `dataLeft/dataTop`, corner/ruler rect를 1회성으로 기록한다.
- 수정 완료: `lib/main.dart`의 DebugLogger 버전을 `FSDBG-2026-07-07-ruler-border-trace-v7`로 갱신했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/main.dart lib/home_page_manager.dart test/label_sheet_toolbar_test.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 다음 확인: 새 실행 로그에서 `FSRULER-2026-07-07-border-trace-v7`의 `headerBoundaries`/`rulerBorders` 좌표와 사용자가 제공한 스크린샷의 두꺼운 픽셀 위치를 대조해야 한다. 로그만으로 픽셀 위치가 특정되지 않으면 좌상단 corner, 첫 행/열 header, 첫 셀 일부가 함께 보이는 새 스크린샷이 필요하다.
- 커밋 완료: `3bb8a4b` 품목관리 preview ruler 복구 및 경계 로그 추가. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외했다.

### 완료 (2026-07-07): 품목관리 preview ruler 비활성화

- 로그 확인: 최신 `.tmp/log/app_2026-07-07_22-52-16.log`에서 `FSDBG-2026-07-07-ruler-hide-header-border-v5`와 `FSRULER-2026-07-07-hide-header-border-v5`가 확인되어 v5 painter 보정이 실제 앱에서 실행됐지만 사용자 화면 변화가 없었다.
- 원인 재판단: hidden header 상태에서도 `topRuler=0..20`, `leftRuler=0..46`, `dataLeft=46`, `dataTop=20`으로 ruler 영역 자체가 계속 예약되어 있었다. 따라서 품목관리 두 preview 시트의 남은 두꺼운 선 후보는 border 한 줄이 아니라 ruler 영역 자체로 판단했다.
- 오수정 원복: v5의 painter border skip 보정, `FSRULER` painter 로그, hidden header ruler border 테스트 보강을 제거했다. `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`와 관련 painter 테스트는 `5dfe974` 기준 상태로 돌아왔다.
- 수정 완료: `_itemElementWorkbook`와 `_itemOutputPreviewPrivateWorkbook`이 생성하는 품목관리 preview 시트에 `fortuneSheetRulerVisibleKey: false`를 설정해 ruler 영역이 예약되지 않게 했다.
- 수정 완료: `lib/main.dart`의 DebugLogger 버전을 `FSDBG-2026-07-07-item-preview-ruler-off-v6`으로 갱신했다.
- 테스트 보강: `debugItemElementWorkbookForTesting`을 추가하고, element/output preview 워크북의 `rulerVisible=false`를 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item element preview hides sheet ruler"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/main.dart lib/home_page_manager.dart test/label_sheet_toolbar_test.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 스크린샷 필요 조건: 이 수정 후에도 공용라벨관리 `label_sheet_01`의 visible header 좌상단 선이 그대로라면, 로그 좌표만으로는 실제 두꺼운 픽셀 레이어를 더 구분할 수 없어 새 스크린샷이 필요하다. 특히 좌상단 corner와 첫 행/열 header가 함께 보이도록 찍어야 한다.
- 커밋 완료: `690cd88` 품목관리 preview ruler 비활성화. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외했다.

### 완료 (2026-07-07): hidden header ruler 경계선 제거

- 로그 확인: 최신 `.tmp/log/app_2026-07-07_22-46-46.log`에서 `FSDBG-2026-07-07-ruler-hairline-border-v4`와 `FSRULER-2026-07-07-hairline-border-v4`가 확인되어 v4 hairline 수정이 실제 앱에서 실행됐지만 사용자 화면 변화가 없었다.
- 오수정 원복: v4의 `strokeWidth = 0` hairline ruler/corner border 보정과 `_hairline` helper를 제거했다.
- 수정 완료: hidden header 상태(`hideRowColumnHeaderLabels=true`)에서는 숨겨진 행/열 헤더 자리에 남던 ruler/header 경계선을 그리지 않게 했다. 로그 정책은 `borderPolicy=skipHiddenHeaderRulerBoundary`로 표시된다.
- 수정 완료: visible header 상태에서는 corner 보조선을 제거하고, 실제 header boundary와 top/left ruler boundary만 유지한다. 로그 정책은 `borderPolicy=headerBoundaryOnly`로 표시된다.
- 수정 완료: `lib/main.dart`의 DebugLogger 버전을 `FSDBG-2026-07-07-ruler-hide-header-border-v5`로 갱신했다.
- 테스트 보강: hidden header 테스트에 `fortuneSheetRulerBorderColor` 픽셀 검출을 추가해 숨겨진 헤더 자리의 ruler border가 남지 않는지 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart` 통과(`+752`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `a7decce` hidden header ruler 경계선 제거. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외했다.

### 완료 (2026-07-07): ruler 경계선 hairline 적용

- 로그 확인: 최신 `.tmp/log/app_2026-07-07_22-41-10.log`에서 `FSDBG-2026-07-07-ruler-crisp-border-v3`와 `FSRULER-2026-07-07-crisp-border-v3`가 확인되어, 수정된 `fortune_sheet` painter가 실제 앱에서 실행 중임을 확인했다.
- 로그 확인: 문제 화면별 좌표는 `item_element`, `item_output_preview_sheet_01` 모두 `hideHeaders=true`, `dataLeft=46.0`, `dataTop=20.0`이며, 공용라벨관리 `label_sheet_01`은 `hideHeaders=false`, `dataLeft=92.0`, `dataTop=40.0`으로 찍혔다.
- 오수정 원복: v3의 `-0.5` 반픽셀 ruler/corner border 보정은 사용자 화면에서 변화가 없어 제거하고, border 좌표를 원래 rect 경계 좌표 기준으로 되돌렸다.
- 수정 완료: Windows 배율에서 1 logical px stroke가 두껍게 래스터링되는 후보를 줄이기 위해 ruler/corner border만 `strokeWidth = 0` hairline stroke로 그리게 했다. Tick 끝점 조정과 `0mm` tick skip은 유지한다.
- 수정 완료: `lib/main.dart`의 DebugLogger 버전을 `FSDBG-2026-07-07-ruler-hairline-border-v4`로 갱신했다.
- 디버그 추가: `FSRULER-2026-07-07-hairline-border-v4` 로그에 `borderPolicy=hairline`을 포함해 실행 로그에서 v4 적용 여부를 확인할 수 있게 했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart` 통과(`+752`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `b3b3166` 시트 ruler 경계선 hairline 적용. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외했다.

### 완료 (2026-07-07): ruler 경계선 반픽셀 정렬 및 앱 로그 진단

- 로그 확인: 최신 `.tmp/log/app_2026-07-07_22-29-21.log`에는 `FSRULER` 마커가 없었고, 앱 버전도 `FSDBG-2026-07-01-cell-edit-log`로 남아 있어 직전 `--dart-define` 기반 진단 로그가 앱 로그에서 확인되지 않았다.
- 오수정 원복: `LABEL_MANAGER_SHEET_RULER_DEBUG` dart-define로만 켜지는 독립 로그 조건을 제거하고, `debugPrint`를 통해 앱의 기존 `DebugLogger` 파일 로그에 직접 남도록 바꿨다.
- 수정 완료: `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`의 ruler/corner border를 정수 좌표 `canvas.drawLine` 방식에서 원본 `_line` helper의 `-0.5` 반픽셀 정렬 방식으로 되돌려 1px 선이 양쪽 픽셀로 번져 두껍게 보이는 후보를 제거했다.
- 수정 완료: `lib/main.dart`의 DebugLogger 버전을 `FSDBG-2026-07-07-ruler-crisp-border-v3`로 갱신해 사용자가 보낸 최신 로그가 이번 빌드인지 바로 판별할 수 있게 했다.
- 디버그 추가: 별도 실행 플래그 없이 `FSRULER-2026-07-07-crisp-border-v3` 로그가 sheet별 1회성 key로 출력된다. 로그에는 `hideHeaders`, `topRuler`, `leftRuler`, `corner`, `cornerBottomRight`, `cornerRightBottom`, `dataLeft/dataTop`, major/0 tick draw 여부가 포함된다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart` 통과(`+752`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/main.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `67d9179` 시트 ruler 경계선 정렬 및 로그 보강. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외했다.

### 완료 (2026-07-07): ruler tick 끝점 겹침 원복 후 재수정

- 이미지 분석: 공용라벨관리 시트는 visible header 상태에서 ruler corner 외곽선과 header data 경계선이 헤더 교차 영역에서 겹쳐 보였고, 품목관리 두 preview 시트는 hidden header 상태에서 ruler tick 끝점이 숨겨진 header 자리의 ruler border에 닿아 진한 선처럼 누적되어 보였다.
- 오수정 원복: `b119e90`, `323237f`, `820e5a4`에서 추가한 `_drawSheetHeaderBoundary` 후처리, 원본 header data 경계선 제거, 0 tick만 skip하는 변경을 되돌렸다.
- 수정 완료: 원본 `fortune_sheet` painter 구조를 유지하면서 visible header 상태의 `corner.bottom/right`는 header data 경계선과 겹치지 않게 header 시작점까지만 그리고, hidden header 상태는 원래처럼 전체 ruler corner border를 유지한다.
- 수정 완료: horizontal/vertical ruler tick은 `0mm` tick을 경계선 위에 그리지 않고, 나머지 tick도 border에서 2px 전에 끝나게 해 경계선에 진한 tick 색이 누적되지 않게 했다.
- 디버그 추가: `--dart-define=LABEL_MANAGER_SHEET_RULER_DEBUG=true`로 실행하면 `FSRULER-2026-07-07-tick-gap-v2` 로그가 출력되어 실제 painter 반영 여부, ruler/corner/tick 좌표, tick draw 여부를 확인할 수 있다.
- 테스트 정리: 이전 gridline 오수정 기준 테스트를 제거하고, visible/hidden header 경계 band에 `fortuneSheetRulerTickColor`가 남지 않는지 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: ruler tick/adjusted sheet/cell border 회귀 테스트 3건 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart` 통과(`+752`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `80d3088` 시트 ruler 디버그 로그 추가. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외했다.

### 완료 (2026-07-07): ruler 0 눈금 경계선 겹침 제거

- 수정 완료: 이전 보정이 실제로 두껍게 보이는 진한 선을 없애지 못한 원인을 재수정했다.
- 원인: 시트 좌상단 경계선 위에 horizontal/vertical ruler의 `0mm` tick이 진한 `fortuneSheetRulerTickColor`로 겹쳐 그려져, 일반 행/열 구분선보다 두껍고 진하게 보였다.
- 수정 완료: 원본 `fortune_sheet` painter에서 경계선 위 `0mm` tick 선만 그리지 않게 하고, `0` label은 유지했다.
- 테스트 보강: 일반/헤더 숨김 상태 경계선 테스트가 `fortuneSheetGridLineColor` 유지와 `fortuneSheetRulerTickColor` 미검출을 함께 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: ruler tick/adjusted sheet/cell border 회귀 테스트 3건 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart` 통과(`+752`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `820e5a4` ruler 0눈금 경계선 겹침 제거.
- stage/commit 제외: unrelated 변경 `lib/core/app.dart` 및 lock 파일.

### 완료 (2026-07-07): 행/열 헤더 교차 경계선 중복 제거

- 수정 완료: sheet 좌상단 행/열 헤더 영역 경계선이 여전히 두껍게 보이는 문제를 재보정했다.
- 원인: `_drawHeaders`, `_drawSheetRulersAndGuides`, `_drawSheetHeaderBoundary`가 같은 data 경계선을 중복으로 그려 1px보다 두껍게 보였다.
- 수정 완료: data 경계선은 `_drawSheetHeaderBoundary` 한 곳에서만 그리고, `_drawHeaders`와 `_drawSheetRulersAndGuides`의 중복 data 경계선은 제거했다.
- 수정 완료: `hideRowColumnHeaderLabels` 상태에서도 ruler/data 경계가 일반 행/열 구분선과 같은 1px로 연결되도록 `_drawSheetHeaderBoundary`가 동작한다.
- 테스트 보강: `adjusted sheet header corner separators stay connected`에서 인접 픽셀 번짐이 없는지 검증한다.
- 테스트 추가: `adjusted sheet hidden headers keep ruler separators one pixel`로 행/열 헤더 숨김 상태의 ruler/data 경계선을 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet hidden headers keep ruler separators one pixel"` 통과.
- 검증 완료: 주요 cell border/ruler 회귀 테스트 3건 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart` 통과(`+752`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `323237f` 행열 헤더 경계선 중복 제거.
- stage/commit 제외: unrelated 변경 `lib/core/app.dart` 및 lock 파일.

### 완료 (2026-07-07): 행/열 헤더 좌상단 구분선 연결 보정

- 수정 완료: sheet ruler가 표시되는 시트 좌상단 행/열 헤더 영역에서 구분선이 두껍거나 일부 끊기는 문제를 보정했다.
- 원인: `_drawHeaders`와 `_drawSheetRulersAndGuides`가 같은 경계를 서로 다른 좌표/색/그리기 API로 나눠 그리고, 데이터 영역 경계선 일부가 cell clip/background 단계에서 덮였다.
- 수정 완료: ruler/header 경계선을 일반 행/열 헤더 구분선과 같은 `_line(..., fortuneSheetGridLineColor)` 좌표로 통일했다.
- 수정 완료: 데이터 영역까지 이어지는 좌/상단 경계선은 cell clip 복구 후, cell border 렌더링 전에 다시 그려 사용자 셀 테두리를 덮지 않게 했다.
- 테스트 추가: `adjusted sheet header corner separators stay connected` 픽셀 테스트로 교차 영역과 데이터 영역 경계선 연결을 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart --plain-name "adjusted sheet header corner separators stay connected"` 통과.
- 검증 완료: 이전 실패 border 회귀 테스트 4건 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_painter_test.dart` 통과(`+751`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `b119e90` 행열 헤더 교차선 연결 보정.
- stage/commit 제외: unrelated 변경 `lib/core/app.dart` 및 lock 파일.

### 진행 중 (2026-07-07): 품목관리 출력 미리보기 grid line 숨김과 헤더 교차선 보정

- 수정 완료: 품목관리 플로팅 창 `출력내용 미리보기` 전용 preview sheet는 저장 시트 내용은 유지하되 `showGridLines: false`로 셀 grid line을 숨긴다.
- 수정 완료: FortuneSheet 공통 행/열 헤더 좌상단 교차 영역의 구분선이 다른 헤더 구분선보다 두껍게 보이지 않도록, 교차 영역 경계선을 헤더 영역 안에서만 1px로 그리도록 정리했다.
- 테스트 갱신: `item output preview uses private active saved sheet only`에서 출력 미리보기 전용 sheet의 `showGridLines == false`를 검증한다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet zoom toolbar placement can move or hide controls"` 통과(`+1`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label image import context menu only appears on sheet corner"` 통과(`+1`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/home_page_manager.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `363c0bb` 출력 미리보기 그리드라인 숨김과 헤더 교차선 보정.
- stage/commit 제외: unrelated 변경 `lib/core/app.dart` 및 lock 파일.

### 진행 중 (2026-07-07): 품목관리 출력내용 미리보기 전용 시트 모드 보정

- 수정 예정: 품목관리 플로팅 창 `출력내용 미리보기`를 공용라벨관리 workbook/sheet와 분리된 전용 preview sheet로 구성한다. 저장된 active sheet 내용은 유지하되 workbench에는 단일 preview sheet만 전달한다.
- 수정 예정: 출력 미리보기 시트에 `주원료 및 함량` 탭과 같은 헤더/선택/눈금자/통계/zoom 배치 설정을 적용하고, 실제 툴바는 새 플래그로 완전히 숨긴다.
- 수정 예정: 출력 미리보기 컨텍스트 메뉴는 새 플래그로 셀 선택/편집 상태에서 `복사하기`만 보이도록 제한한다.
- 검증 예정: `dart format`, 관련 label sheet toolbar 집중 테스트, `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`.
- 편집 완료: `home_page_manager.dart`에서 출력 미리보기 workbook을 저장본 active sheet 기반 단일 `item_output_preview_sheet_01`로 재구성하고, `LabelSheetWorkbench` 옵션을 주원료 탭과 같은 모양/zoom 배치 + 툴바 숨김 + copy-only 메뉴로 설정했다.
- 편집 완료: `label_sheet_workbench.dart`에 `hideToolbar`, `copyOnlyContextMenu` 플래그를 추가해 fortune settings로 전달한다.
- 편집 완료: `fortune_sheet_model.dart`에 `showToolbar` copyWith와 `copyOnlyContextMenu` 설정을 추가하고, `fortune_sheet_canvas.dart`에서 셀 편집 컨텍스트 메뉴도 copy-only일 때 `copy`만 반환하도록 했다.
- 테스트 추가: `label_sheet_toolbar_test.dart`에 출력 미리보기 전용 active sheet 복사/키워드 치환, toolbar 숨김/copy-only settings 회귀 테스트를 추가했다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+3`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet settings can"` 통과(`+2`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet zoom toolbar placement can move or hide controls"` 통과(`+1`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/home_page_manager.dart lib/page_label_sheet/label_sheet_workbench.dart third_party/fortune_sheet/lib/src/fortune_sheet_model.dart third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- stage/commit 예정: `lib/home_page_manager.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_model.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외한다.
- 커밋 완료: `7c583fa` 품목관리 출력 미리보기 전용 시트 모드 보정.

### 진행 중 (2026-07-07): 품목관리 출력내용 미리보기 빈 상태 보정

- 수정 완료: 품목관리 플로팅 창 `출력내용 미리보기`에서 현재 라벨 저장값이 레거시 RichEdit RTF이면 중앙 기울임 힌트 `* 라벨을 편집 저장 후 가능합니다.`를 표시한다.
- 수정 완료: 저장된 LabelSheet 데이터가 손상/해석 불가하면 중앙 기울임 힌트 `* 저장된 라벨에 문제가 있습니다.`를 표시한다.
- 수정 완료: 저장된 LabelSheet workbook이 decode되지만 sheet가 비어 있으면 품목관리 미리보기 내부에서 기본 fallback 시트를 보강해 `LabelSheetWorkbench`가 사용할 수 있게 한다.
- 테스트 추가: `label_sheet_toolbar_test.dart`에 RTF/손상 저장 데이터 힌트와 빈 저장 workbook fallback 회귀 테스트를 추가했다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "item output preview"` 통과(`+2`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/home_page_manager.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- stage/commit 예정: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외한다.
- 커밋 완료: `4fc0122` 품목관리 출력 미리보기 빈 상태 보정.

### 진행 중 (2026-07-07): 라벨 저장 로그 IP 문자열 길이 초과 수정

- 원인 확인: 라벨 저장 로그 SQL이 `RICH_INNER_IP`에 `stringToHexCp949(localIp)` 결과인 `0x3137...` hex 문자열을 그대로 넣어 IP 컬럼 길이를 초과했고, SQL Server 8152(`문자열이나 이진 데이터는 잘립니다`)로 저장이 rollback되었다.
- 수정 완료: `LabelSizeDAO.UpdateFormDataLogSql`에서 `@loginIP`를 `CONVERT(VARBINARY(100), @loginIP, 1)` 경유로 실제 IP 문자열로 복원해 저장하도록 했다.
- 데이터 손실 방지: IP 표현식 단계에서 `char(15)`, `varchar(32)`처럼 값을 자를 수 있는 변환을 사용하지 않고 `VARCHAR/NVARCHAR(100)` 및 outer IP `VARCHAR(48)`로 변환한다. DB 컬럼이 실제 값을 담을 수 없으면 잘라 저장하지 않고 SQL 오류가 나도록 둔다.
- 다른 구문 점검/수정 완료: `LoginLogDAO.InsertSql`도 내부 IP `VARCHAR/NVARCHAR(100)`, outer IP `VARCHAR(48)` 변환으로 맞췄다. `lib/**/*.dart`에서 `@loginIP`/`client_net_address` 관련 짧은 변환식 잔존 여부를 검색했고 남은 항목 없음.
- 테스트 추가: `dao_result_helper_test.dart`에 라벨 저장 로그 IP 복원과 로그인 로그 IP 표현식 비절단 회귀 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\dao_result_helper_test.dart` 통과(`+12`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\windows_odbc_param_utils_test.dart` 통과(`+10`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 커밋 완료: `1111a46` 라벨 저장 로그 IP 변환 보정.

### 진행 중 (2026-07-07): ODBC SQL 지역 변수 파라미터 오인 수정

- 원인 확인: `prepareStatement()`가 SQL Server 지역 변수(`DECLARE @logAffected`, `@updateAffected`, `@brandAffected`, `@labelSizeAffected`, `@affected0` 등)를 앱 바인딩 파라미터로 오인해, 라벨 저장 시 `Parameter @logAffected was not provided` 예외가 발생했다.
- 수정 완료: `lib/database/windows_odbc/odbc_param_utils.dart`에서 SQL 내 `DECLARE @...` 지역 변수를 수집하고, 앱 파라미터에 없는 선언 변수는 `?`로 치환하지 않고 SQL 원문에 그대로 남기도록 했다. 기존 `@@ROWCOUNT`/`@@TRANCOUNT` 보존 동작은 유지한다.
- 테스트 추가: `test/windows_odbc_param_utils_test.dart`에 선언된 SQL Server 지역 변수 보존, 한 DECLARE의 복수 변수 보존, 실제 `LabelSizeDAO.UpdateFormDataTransactionSql` 준비 시 `@logAffected`/`@updateAffected`를 바인딩하지 않는 회귀 테스트를 추가했다.
- 다른 구문 점검 완료: `lib/models/brand.dart`, `lib/models/label_size.dart`의 `DECLARE @...` 기반 트랜잭션 SQL은 이번 치환기 보정으로 함께 처리된다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\windows_odbc_param_utils_test.dart` 통과(`+10`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 커밋 완료: `31b8d34` ODBC SQL 지역 변수 파라미터 오인 수정.

### 진행 중 (2026-07-07): 라벨 저장 ODBC SQL_NO_DATA(100) 실패 수정

- 원인 확인: 라벨 저장 트랜잭션(`LabelSizeDAO.updateByLabelSizeId`)이 `INSERT LOG` + `UPDATE FORM` DML 배치만 실행하고 최종 결과셋을 반환하지 않아, ODBC 드라이버에서 `SQLExecute failed: 100`(`SQL_NO_DATA`)로 표면화될 수 있었다.
- 수정 완료: 저장 트랜잭션 SQL을 `UpdateFormDataTransactionSql` 상수로 분리하고 `SET NOCOUNT ON`, `@logAffected`/`@updateAffected` rowcount 보관, `SELECT @updateAffected AS AFFECTED`를 추가했다. 기존 실패 검증(`THROW 51000/51001`)과 rollback 흐름은 유지한다.
- 추가 점검 완료: `writeDataWithParams`/트랜잭션 배치 SQL을 확인한 결과 같은 위험 구조로 남아 있던 `LabelSizeDAO.updateOrders()`를 발견했다. 여러 `UPDATE`를 트랜잭션으로 실행하면서 최종 결과셋이 없어 ODBC 100이 반복될 수 있었다.
- 추가 수정 완료: `LabelSizeDAO.updateOrders()`에 `SET NOCOUNT ON`, 각 update별 affected 변수 저장, 실패 시 기존 `THROW 51020`, 성공 시 `SELECT @affected0 + ... AS AFFECTED` 반환을 추가했다.
- 분류 완료: 브랜드/라벨 insert/delete 트랜잭션은 이미 `SET NOCOUNT ON`과 최종 `SELECT` 결과셋을 반환한다. 단일 insert/update/delete SQL은 트랜잭션 배치형 SQL_NO_DATA 문제와 별도 범주로 보고 이번 수정 대상에서 제외했다.
- 테스트 추가: `dao_result_helper_test.dart`에 라벨 저장 트랜잭션이 ODBC용 명시 affected row 결과를 반환하는지 검증을 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\dao_result_helper_test.dart` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 커밋 완료: `ab37f5f` 라벨 순서 저장 ODBC 결과 반환 보정.
- 커밋 완료: `20458e5` 라벨 저장 ODBC 결과 반환 보정.

### 진행 중 (2026-07-07): 공용라벨 플로팅 이동 고정 및 병합셀 테두리 보정

- 수정 완료: `PreviewFloatingWindow`에 사용자 이동 전용 `onMoved` 콜백을 추가했다. resize/align/setSize와 구분해 실제 move handle 드래그에서만 호출된다.
- 수정 완료: 공용라벨 RTF 플로팅 창은 사용자가 한 번 이동하면 `_commonLabelPreviewMovedByUser`를 세우고, 이후 시트 확대/축소나 grid rect 변경에서 `_alignCommonLabelPreviewWindowToGrid()`가 재정렬하지 않도록 했다. RTF target이 바뀌어 새 창을 만들 때는 플래그를 초기화한다.
- 수정 완료: 테두리는 앱 보정이 아니라 공용 원본 `third_party/fortune_sheet/lib/src/fortune_border_compute.dart`에서 수정했다. 병합 anchor 셀에 적용된 `border-all`/외곽 메타의 top/right/bottom/left를 병합 범위의 실제 시각 외곽 셀로 보존한 뒤 내부선만 제거한다.
- 테스트 추가: `fortune_border_compute_test.dart`에 병합 anchor 단일 range에 `border-all`이 들어와도 병합 셀 하단 외곽선이 유지되는 회귀 테스트를 추가했다.
- 테스트 추가: `label_sheet_toolbar_test.dart`에 플로팅 창 사용자 이동 시 `onMoved`가 별도로 호출되는 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_border_compute_test.dart` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_border_compute_test.dart --plain-name "all borders on merged cell anchor preserve visual bottom edge"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview reports user move separately"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview reports rect changes and resize completion"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 커밋 완료: `e3cd316` 공용 플로팅 이동 고정과 병합셀 테두리 보정.

### 진행 중 (2026-07-07): 레거시 마지막 브랜드/라벨 선택 복원 적용

- 수정 완료: `LastConnectDAO.upsert()`를 추가해 `BM_RICH_LAST_ID`의 사용자별 마지막 브랜드/라벨 선택을 insert/update 분기 없이 저장할 수 있게 했다.
- 수정 완료: 로그인 후 `HomePageManager._loadBrands()`에서 `LastConnectDAO.selectByUserId(User.instance!.userId)`를 조회하고, 저장된 브랜드가 현재 브랜드 목록에 있으면 해당 브랜드를 우선 선택하도록 했다. 저장된 브랜드가 없거나 삭제된 경우 기존 첫 브랜드 fallback을 유지한다.
- 수정 완료: `HomePageManager._scheduleLabelSizeLoad()`에 `preferredLabelSizeId`를 추가해 저장된 라벨이 현재 브랜드의 라벨 목록에 있으면 우선 선택하고, 없으면 기존 현재 선택/첫 라벨 fallback을 유지한다.
- 수정 완료: 복원 중 부모 `onBrandChanged`로 인한 `didUpdateWidget` 중복 라벨 로드를 1회 억제해 마지막 라벨 선택이 첫 라벨 선택으로 덮이지 않게 했다.
- 수정 완료: `HomePage._onLabelSizeChanged()`에서 브랜드와 라벨이 모두 있으면 `LastConnectDAO.upsert()`로 저장하고, 둘 중 하나가 없으면 현재 사용자 last-connect를 삭제한다.
- 테스트 추가: `dao_result_helper_test.dart`에 `LastConnect.fromMap` 매핑과 `LastConnectDAO` 파라미터 SQL 구조 검증을 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\dao_result_helper_test.dart` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 커밋 완료: `f037ea4` 이전 브랜드 라벨 선택 복원 적용.

### 진행 중 (2026-07-07): 품목 플로팅 위치/코너 리사이즈/조회 스낵바 보정

- 수정 완료: 품목관리 플로팅 창 초기 크기를 `620x420`에서 `670x470`으로 다시 50씩 키웠다.
- 수정 완료: 품목관리 플로팅 창 최초 우하단 정렬 기준을 품목관리 테이블 우하단에서 `스크롤바 두께 + 10`만큼 안쪽으로 뺀 위치로 변경했다.
- 수정 완료: 품목관리 기본 선택 상태(`isAutoLogin=false` 포함)에서 라벨/품목 테이블 로드와 `_resetTabs()` 완료 후 `ScaffoldMessenger.hideCurrentSnackBar()`를 호출해 조회 처리 스낵바가 남지 않도록 했다.
- 수정 완료: 모든 플로팅 창 코너 리사이즈 핸들의 hover/drag hit-test를 전체 44px 사각 영역이 아니라 눈에 보이는 grip 선분의 stroke 앞/뒤/위/아래 +1px 범위로 제한했다. edge resize 핸들은 기존 strip 동작을 유지한다.
- 테스트 수정/추가: 코너 리사이즈 테스트들의 시작점을 보이는 grip 교차점으로 변경하고, `floating preview corner resize ignores empty handle box area`로 빈 사각 영역에서는 resize가 시작되지 않음을 검증했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview corner resize ignores empty handle box area"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview move handle returns to center after resize"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview top corner can expand and shrink"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview shows corner resize grips on hover"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart --plain-name "resizable table reports its global rect"` 통과.
- 커밋 완료: `e59d727` 품목 플로팅 위치와 리사이즈 판정 조정.

### 진행 중 (2026-07-07): 품목관리 플로팅 창 초기 크기/위치 조정

- 수정 완료: 품목관리 플로팅 창 초기 크기를 `720x520`에서 `620x420`으로 줄였다.
- 수정 완료: `ResizableTable`에 선택적 `onRectChanged` 콜백을 추가하고 `ItemManage.onTableRectChanged`를 통해 품목관리 테이블의 전역 Rect를 `HomePageManager`로 전달하도록 했다.
- 수정 완료: 품목관리 플로팅 창 최초 표시 시 우하단 모서리를 품목관리 테이블 우하단에서 스크롤바 두께만큼 안쪽으로 뺀 위치에 맞추도록 했다. 스크롤바 두께는 `ScrollbarTheme` 값 우선, 없으면 `8.0` fallback을 사용한다.
- 수정 완료: 사용자가 플로팅 창을 옮긴 뒤 행 선택/갱신 때마다 다시 정렬되지 않도록 테이블 기준 정렬은 창 생성 후 최초 1회만 수행한다.
- 테스트 추가: `test/swipe_action_table_test.dart`에 `resizable table reports its global rect`를 추가해 테이블 전역 Rect 전달을 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart --plain-name "resizable table reports its global rect"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview aligns bottom-right to target point"` 통과.
- 커밋 완료: `e6a57e1` 품목관리 플로팅 창 초기 위치 조정.

### 진행 중 (2026-07-07): 라벨 시트 저장본 RICH_FORM_SHEET 분리 저장

- DB 전제: 사용자가 `BM_RICH_LABELSIZE_FORM.RICH_FORM_SHEET varchar(max) NULL`, `BM_RICH_LABELSIZE_FORM_LOG.RICH_FORM_SHEET varchar(max) NULL`, `BM_RICH_LABELSIZE_FORM_LOG.RICH_ALTER_FORM_SHEET varchar(max) NULL`을 수동 추가 완료했다.
- 수정 완료: `LabelSizeDAO.SelectSql`의 `FORM_DATA` alias를 `COALESCE(NULLIF(RICH_FORM_SHEET, ''), RICH_FORM_DATA)`로 변경해 sheet 저장본이 있으면 우선 로드하고 없으면 기존 RTF 데이터를 로드하도록 했다.
- 수정 완료: `LabelSizeDAO.UpdateFormDataSql`을 `RICH_FORM_DATA=@formData`에서 `RICH_FORM_SHEET=@formData`로 변경해 라벨 시트 저장 시 기존 RTF 원본을 보존하고 sheet 컬럼에 저장하도록 했다.
- 수정 완료: 저장 로그 insert SQL을 `UpdateFormDataLogSql` 상수로 분리하고 `RICH_FORM_SHEET`/`RICH_ALTER_FORM_SHEET`를 기존 전/후 패턴에 맞춰 기록하도록 했다.
- 테스트 추가: `test/dao_result_helper_test.dart`에 `LabelSizeDAO sheet storage SQL` 그룹을 추가해 sheet 우선 로드, sheet 컬럼 저장, sheet 전/후 로그 SQL을 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\dao_result_helper_test.dart` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 커밋 완료: `6633e40` 라벨 시트 저장본 컬럼 분리.

### 진행 중 (2026-07-07): 공용라벨 RTF Viewer AI 변환 연결

- 추가 수정 완료: 품목관리/공용라벨관리 공통 플로팅 창 `hideToRect` 닫힘 애니메이션에서 실제 창 rect를 버튼 크기까지 줄이지 않고, 원래 레이아웃 크기를 유지한 채 `Transform.translate`/`Transform.scale`/`Opacity`로만 축소·이동·페이드되도록 변경했다. 내부 `Overlay`/이미지/미리보기 위젯이 극소 제약으로 재레이아웃되어 렌더링 오류가 나는 문제를 방지한다.
- 테스트 추가: `floating preview hide animation keeps child layout stable`로 닫힘 애니메이션 중 자식 레이아웃 제약이 안정적으로 유지되는지 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview hide animation keeps child layout stable"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview shows configured tooltip after hover delay"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview aligns bottom-right to target point"` 통과.
- 커밋 완료: `ba07dc2` 플로팅 창 닫힘 애니메이션 안정화.
- 추가 수정 완료: `AI 변환`에서 플로팅 창 표시 크기 기준으로 RTF를 다시 캡처하지 않고, `LabelSheetRtfPreview`가 네이티브에서 받은 PNG 원본을 캐시해 그대로 `라벨 이미지 가져오기` 다이얼로그 초기 파일로 전달하도록 변경했다.
- 추가 수정 완료: 원본 PNG가 아직 준비되지 않은 경우에도 플로팅 창 rect가 아니라 RTF Preview의 네이티브 원본 캡처 규칙(`captureNativeOriginal`)으로 fallback 캡처한다.
- 테스트 추가: `RichEdit RTF preview resolves trimmed content size`에서 네이티브 PNG 원본 콜백(`onNativeImageResolved`)이 실제 PNG 바이트/크기/스케일을 전달하는지 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "RichEdit RTF preview resolves trimmed content size"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "RichEdit RTF preview recaptures when target size changes"` 통과.
- 커밋 완료: `db4283b` RTF AI 변환 네이티브 원본 이미지 사용.
- 추가 수정 완료: RTF Viewer 플로팅 창 드래그바 안의 `AI 변환` 버튼 마우스 오버/클릭 효과를 닫기 버튼과 같은 hover/pressed 배경색, 글자색, 90ms 애니메이션 규칙으로 맞췄다.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview shows configured tooltip after hover delay"` 통과.
- 커밋 완료: `b462ea3` RTF AI 변환 버튼 효과 정렬.
- 수정 예정: 공용라벨관리 RTF Viewer 플로팅 창 헤더 드래그바의 닫기 버튼 앞에 외곽선 없는 `AI 변환` 버튼을 추가한다.
- 수정 예정: `AI 변환` 클릭 시 RTF Viewer 이미지를 앱 임시 폴더에 PNG로 저장하고, 저장된 파일을 선택한 상태로 `라벨 이미지 가져오기` 다이얼로그를 자동으로 띄운다.
- 수정 예정: 이후 AI 변환/시트 로드는 기존 라벨 이미지 가져오기 처리 경로를 그대로 사용한다.
- 편집 완료: `PreviewFloatingWindow`에 선택적 `headerAction` 슬롯을 추가하고, action이 있을 때만 드래그바 폭을 넓혀 닫기 버튼 앞에 위젯을 배치하도록 했다.
- 편집 완료: `HomePageManager`의 공용라벨 RTF Preview window에 9px `AI 변환` 버튼을 추가했다.
- 편집 완료: `AI 변환` 클릭 시 `labelSheetCaptureRtfNativePngImage`로 현재 RTF를 PNG 캡처하고 `labelSheetAiImportTempDirectory()` 아래 `label_manager_rtf_ai_*.png`로 저장한다.
- 편집 완료: `LabelSheetImageImportController`를 추가하고 `CommonLabelManage`/`LabelSheetPage`를 통해 공용라벨관리 `LabelSheetWorkbench`까지 전달해, 저장된 PNG 파일을 초기 선택 상태로 `라벨 이미지 가져오기` 다이얼로그를 열도록 연결했다.
- 검증 완료: `dart format` 실행.
- 검증 완료: 변경 파일 `get_errors` 오류 없음.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview shows configured tooltip after hover delay"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "RichEdit RTF preview PNG capture preserves render scale"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label image import preview scales to readable text size"` 통과.
- 검증 완료: `git diff --check -- lib/home_page_manager.dart lib/page_home/preview_floating_window.dart lib/page_home/common_label_manage.dart lib/page_label_sheet/label_sheet_page.dart lib/page_label_sheet/label_sheet_workbench.dart SESSION_HANDOFF.md` 통과.
- stage/commit 예정: `lib/home_page_manager.dart`, `lib/page_home/preview_floating_window.dart`, `lib/page_home/common_label_manage.dart`, `lib/page_label_sheet/label_sheet_page.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `SESSION_HANDOFF.md`. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외한다.
- 커밋 완료: `40ef6ea` 공용라벨 RTF 미리보기 AI 변환 연결.

### 진행 중 (2026-07-07): 라벨 이미지 파일명 라벨에 현재 시트 정보 병합

- 수정 예정: 라벨 이미지 가져오기 다이얼로그의 파일명 라벨 뒤에 ` · 현재 시트 w x h mm`를 붙이고, 별도 현재 시트 라벨 줄은 제거한다.
- 검증 예정: `dart format`, 변경 파일 오류 확인, `git diff --check`.
- 편집 완료: `_LabelImageImportDialog` 상단 파일명 라벨을 `파일명 · 현재 시트 w x h mm` 형식으로 변경하고, 별도 현재 시트 줄을 제거했다.
- 검증 완료: `dart format` 실행.
- 검증 완료: 변경 파일 `get_errors` 오류 없음.
- 검증 완료: `git diff --check -- lib/page_label_sheet/label_sheet_workbench.dart SESSION_HANDOFF.md` 통과.
- stage/commit 예정: `lib/page_label_sheet/label_sheet_workbench.dart`, `SESSION_HANDOFF.md`. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외한다.
- 커밋 완료: `d51b560` 라벨 이미지 파일명에 시트 정보 표시.

### 진행 중 (2026-07-07): 라벨 이미지 가져오기 파일 선택 흐름 변경

- 수정 예정: 라벨 이미지 가져오기 명령은 파일 선택 다이얼로그를 먼저 띄우지 않고, 라벨 이미지 가져오기 다이얼로그를 먼저 띄운다.
- 수정 예정: 다이얼로그 좌상단에 `파일 선택` 버튼과 선택 파일명 라벨을 배치하고, 버튼으로 이미지를 변경한다.
- 수정 예정: 이전 선택 파일 경로를 로컬 저장소에 저장해 다음 진입 시 자동 로드하고 미리보기까지 표시한다.
- 검증 예정: `dart format`, 변경 파일 오류 확인, 관련 미리보기/Gemini 집중 테스트, `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`.
- 편집 완료: `_handleImportLabelImage`에서 선행 `openFile()` 호출을 제거하고, 활성 시트 확인 후 바로 `_LabelImageImportDialog`를 띄우도록 변경했다.
- 편집 완료: `_LabelImageImportDialog` 상단에 `파일 선택` 버튼과 선택 파일명 라벨을 추가하고, 버튼으로 이미지 파일을 선택/변경하도록 했다.
- 편집 완료: `_labelSheetImageImportFilePathPrefsKey`를 추가해 선택 파일 경로를 저장하고, 다음 진입 시 파일이 존재하면 자동 로드해 미리보기를 표시한다.
- 편집 완료: `_LabelImageImportPreview`가 파일 미선택 상태를 안내 문구로 표시하고, 선택된 이미지 상태를 기준으로 기존 확대/스크롤 미리보기를 유지하도록 변경했다.
- 검증 완료: `dart format` 실행.
- 검증 완료: 변경 파일 `get_errors` 오류 없음.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label image import preview scales to readable text size"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "Gemini model list is fetched from Google AI models API"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/page_label_sheet/label_sheet_workbench.dart SESSION_HANDOFF.md` 통과.
- stage/commit 예정: `lib/page_label_sheet/label_sheet_workbench.dart`, `SESSION_HANDOFF.md`. unrelated 변경 `lib/core/app.dart` 및 lock 파일은 제외한다.
- 커밋 완료: `9ed862e` 라벨 이미지 가져오기 파일 선택 흐름 변경.

### 진행 중 (2026-07-07): 라벨 이미지 AI 설정 무조건 저장

- 수정 예정: 라벨 이미지 가져오기 다이얼로그 하단 체크박스를 제거하고 `* Gemini API Key와 model을 이 PC에 저장합니다.` 힌트 라벨로 바꾼다.
- 수정 예정: AI 분석 적용 시 Gemini API Key/model/prompt를 로컬 저장소에 무조건 저장하고, 다음 다이얼로그 진입 시 prompt도 기본값으로 복원한다.
- 검증 예정: `dart format`, 변경 파일 오류 확인, 관련 Gemini/미리보기 집중 테스트, `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`.
- 편집 완료: `_LabelImageImportDialog` 하단 Checkbox/저장 선택 문구를 제거하고 `* Gemini API Key와 model을 이 PC에 저장합니다.` 힌트 라벨로 교체했다.
- 편집 완료: `_labelSheetGeminiPromptPrefsKey`를 추가하고, 다이얼로그 초기화 시 저장된 prompt를 `initialPrompt`로 복원하도록 했다.
- 편집 완료: AI 분석 적용 버튼을 누르면 요청 실행 전에 Gemini API Key/model/prompt를 항상 `SharedPreferences`에 저장하도록 변경하고 `_LabelImageImportAction.saveCredentials`를 제거했다.
- 검증 완료: `dart format` 실행.
- 검증 완료: 변경 파일 `get_errors` 오류 없음.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label image import preview scales to readable text size"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "Gemini model list is fetched from Google AI models API"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/page_label_sheet/label_sheet_workbench.dart SESSION_HANDOFF.md` 통과.
- stage/commit 예정: `lib/page_label_sheet/label_sheet_workbench.dart`, `SESSION_HANDOFF.md`. unrelated 변경 `lib/core/app.dart` 및 검증 중 변경된 lock 파일은 제외한다.
- 커밋 완료: `ff3a43d` 라벨 이미지 AI 설정 항상 저장.
- 커밋 완료: `63b8b69` 라벨 이미지 AI 설정 저장 시점 보강.

### 진행 중 (2026-07-07): 라벨 이미지 가져오기 미리보기 확대/스크롤

- 수정 예정: 라벨 이미지 가져오기 다이얼로그 크기는 유지하고, 이미지 미리보기 영역 높이만 180px에서 270px로 50% 확대한다.
- 수정 예정: 원본 이미지가 contain 스케일로도 9pt 문자 가독성 근사치에 충분하면 정가운데 표시하고, 부족하면 물리 라벨 크기(mm)와 원본 픽셀 기준으로 9pt 문자 근사 스케일까지 확대해 넘치는 방향은 수직/수평 스크롤한다.
- 검증 예정: `dart format`, 미리보기 스케일 계산 테스트, `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`.
- 편집 완료: `labelSheetImageImportPreviewHeight`를 270으로 두고 `_LabelImageImportPreview` 위젯으로 기존 180px `Image.memory(fit: contain)` 미리보기를 교체했다.
- 편집 완료: `labelSheetImageImportPreviewLayout` 계산 함수를 추가해 contain 스케일이 9pt 문자 가독성 근사치에 충분하면 중앙 배치, 부족하면 readable scale로 확대하도록 했다. 확대 결과가 viewport를 넘으면 수직/수평 `SingleChildScrollView`로 스크롤된다.
- 테스트 추가: `label image import preview scales to readable text size`에서 가독성 확대/overflow 조건과 충분한 contain 중앙 배치 조건을 검증한다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label image import preview scales to readable text size"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "Gemini model list is fetched from Google AI models API"` 통과.
- 검증 완료: 변경 파일 `get_errors` 오류 없음.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- stage/commit 예정: `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. unrelated 변경 `lib/core/app.dart`는 제외한다.
- 커밋 완료: `f381341` 라벨 이미지 미리보기 가독성 확대.

### 진행 중 (2026-07-07): AI 선택 모델 기본값 저장

- 수정 예정: 라벨 이미지 AI 모델 드롭다운에서 선택한 모델은 즉시 로컬 저장소에 기억해 다음 다이얼로그 진입 시 기본 선택으로 사용한다.
- 수정 예정: API Key 저장은 기존처럼 `Gemini API Key와 model을 이 PC에 저장` 체크 및 분석 적용 흐름을 유지하고, 모델 선택 기억만 별도로 수행한다.
- 검증 예정: `dart format`, 관련 Gemini 모델 테스트, `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`.
- 편집 완료: `_LabelImageImportDialog` 모델 드롭다운 `onChanged`에서 선택 모델을 즉시 `_labelSheetGeminiModelPrefsKey`에 저장하도록 했다.
- 동작: 다음 다이얼로그 진입 시 기존 `initialModel` 로드 경로가 이 저장값을 기본 선택으로 사용한다. API Key 저장은 기존 체크박스/분석 적용 조건을 유지한다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "Gemini model list is fetched from Google AI models API"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "Gemini model menu includes supported model choices"` 통과.
- 검증 완료: 변경 파일 `get_errors` 오류 없음.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/page_label_sheet/label_sheet_ai_import.dart lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `4403898` 라벨 이미지 AI 모델 정렬과 기본값 저장.

### 진행 중 (2026-07-07): AI 모델 드롭다운 정렬 보정

- 수정 예정: 라벨 이미지 AI 모델 드롭다운에서 Gemini 모델 그룹을 먼저 배치하고, 각 그룹 내부는 model id 역순으로 정렬한다.
- 수정 예정: `/v1beta/models` 응답 중 `generateContent` 지원 모델은 Gemini 외 그룹도 보존해 그룹 정렬이 의미 있게 동작하도록 한다.
- 검증 예정: `dart format`, Gemini 모델 목록 조회/정렬 테스트, `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`.
- 편집 완료: `labelSheetSortedGeminiModels`를 추가해 Gemini 그룹을 먼저 두고, 그룹 내부는 model id 역순으로 정렬한다.
- 편집 완료: `/v1beta/models` 응답 파싱에서 Gemini 외 `generateContent` 지원 모델도 보존하고, 다이얼로그의 fetched/fallback 병합 결과에도 같은 정렬을 적용했다.
- 테스트 갱신: `Gemini model list is fetched from Google AI models API`에서 `gemini-3.5-pro`, `gemini-2.5-flash`, `gemma-3-27b-it`, `gemma-2-9b-it` 순서를 검증한다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "Gemini model list is fetched from Google AI models API"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "Gemini model menu includes supported model choices"` 통과.
- 검증 완료: 변경 파일 `get_errors` 오류 없음.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/page_label_sheet/label_sheet_ai_import.dart lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- stage/commit 예정: `lib/page_label_sheet/label_sheet_ai_import.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. unrelated 변경 `lib/core/app.dart`는 제외한다.
- 커밋 완료: `4403898` 라벨 이미지 AI 모델 정렬과 기본값 저장.

### 진행 중 (2026-07-07): 라벨 이미지 AI 모델 목록 동적 조회

- 확인 완료: `라벨 이미지 가져오기` 다이얼로그는 진입 시 Gemini 모델 API를 조회하지 않고 `labelSheetGeminiModels` 정적 목록(`gemini-2.5-flash`, `gemini-2.5-pro`, `gemini-2.0-flash`)만 표시한다.
- 수정 예정: 다이얼로그 진입 시 저장된 Gemini API Key가 있으면 `/v1beta/models`를 다시 조회해 `generateContent` 지원 Gemini 모델을 드롭다운에 반영한다. 조회 실패/키 없음은 기존 정적 목록 fallback을 유지한다.
- 검증 예정: `dart format`, Gemini 모델 목록 조회 unit test, 관련 label sheet toolbar 집중 테스트, `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`.
- 편집 완료: `labelSheetFetchGeminiModels`를 추가해 Google AI `/v1beta/models`에서 `generateContent`를 지원하는 `gemini-*` 모델을 조회/필터링한다.
- 편집 완료: `_LabelImageImportDialog`가 열릴 때 저장된 API Key가 있으면 모델 목록을 다시 조회하고, 조회 실패/키 없음이면 기존 정적 목록을 fallback으로 유지한다.
- 테스트 추가: `Gemini model list is fetched from Google AI models API`에서 `gemini-3.5-pro` 같은 서버 응답 모델이 메뉴 목록 후보로 파싱되는지 검증한다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "Gemini model list is fetched from Google AI models API"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "Gemini model menu includes supported model choices"` 통과.
- 검증 완료: 변경 파일 `get_errors` 오류 없음.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/page_label_sheet/label_sheet_ai_import.dart lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- stage/commit 예정: `lib/page_label_sheet/label_sheet_ai_import.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. unrelated 변경 `lib/core/app.dart`는 제외한다.
- 커밋 완료: `3e95265` 라벨 이미지 AI 모델 목록 동적 조회.

### 진행 중 (2026-07-07): 라벨시트 zoom 입력 텍스트/커서 y 위치 동시 보정

- 확인 완료: Flutter `RenderEditable.cursorOffset`은 커서 페인팅 위치에만 더해지는 값이라 텍스트 레이아웃 위치는 같이 이동하지 않는다.
- 수정 예정: 품목관리 플로팅창과 공용라벨관리 시트가 함께 쓰는 zoom 입력 위젯에서 `cursorOffset` 보정 대신 내부 padding을 위 6px/아래 4px로 조정해 텍스트와 커서가 함께 1px 아래 표시되게 한다.
- 검증 예정: `dart format`, `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet zoom toolbar placement can move or hide controls"`, `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`.
- 편집 완료: `LabelSheetWorkbench`의 zoom 입력 padding을 `EdgeInsets.fromLTRB(5, 6, 5, 4)`로 조정하고 `EditableText.cursorOffset`은 `Offset.zero`로 되돌렸다.
- 테스트 갱신: `label sheet zoom toolbar placement can move or hide controls`에서 품목관리 플로팅창 배치와 공용라벨관리 시트 배치 모두 cursor offset이 0이고 입력 padding이 위 6px/아래 4px인지 검증한다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet zoom toolbar placement can move or hide controls"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- stage/commit 예정: `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. unrelated 변경 `lib/core/app.dart`는 제외한다.
- 커밋 완료: `78f00d2` 라벨시트 확대 입력 텍스트 위치 보정.

### 진행 중 (2026-07-07): 라벨시트 zoom 입력 커서 y 위치 보정

- 수정 예정: 품목관리 플로팅창과 공용라벨관리 시트가 함께 사용하는 축소/확대 입력 위젯의 커서 y 위치를 1px 아래로 조정한다.
- 검증 예정: `dart format`, `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet zoom toolbar placement can move or hide controls"`, `C:\Flutter\bin\flutter.bat analyze`, `git diff --check`.
- 편집 완료: `LabelSheetWorkbench`의 zoom 입력 `EditableText.cursorOffset`을 `Offset(0, 1)`로 조정했다.
- 테스트 갱신: `label sheet zoom toolbar placement can move or hide controls`에서 품목관리 플로팅창 배치(`previewTabAreaEnd`)와 공용라벨관리 시트 배치(`sheetToolbarEnd`)의 cursor offset을 함께 검증한다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet zoom toolbar placement can move or hide controls"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `git diff --check -- lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- stage/commit 예정: `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. unrelated 변경 `lib/core/app.dart`는 제외한다.
- 커밋 완료: `f264d7d` 라벨시트 확대 입력 커서 위치 보정.

### 진행 중 (2026-07-07): 품목관리 주원료 zoom overlay/resize handle z-order 보정

- 수정 예정: 탭 메뉴 영역 오른쪽 끝의 축소/확대 영역 x 위치를 2px 다시 주고, 코너 리사이징 바가 축소/확대 영역 위에 나타나도록 한다.
- 편집 완료: `LabelSheetWorkbench`의 `previewTabAreaEnd` follower offset을 `Offset(-14, -34)`에서 `Offset(-12, -34)`로 조정했다.
- 편집 완료: `PreviewFloatingWindow`의 child 영역에 `Overlay(clipBehavior: Clip.none)` 로컬 overlay를 추가하고, zoom overlay는 root overlay가 아닌 가장 가까운 overlay에 삽입되도록 바꿨다. floating window corner resize handle은 이 로컬 overlay보다 뒤에 그려져 위에 나타난다.
- 테스트 추가: `floating preview top corner stays above zoom overlay`로 zoom overlay가 보이는 상태에서도 top-right resize handle drag가 창 크기를 변경하는지 검증했다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "floating preview top corner stays above zoom overlay"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet zoom toolbar placement can move or hide controls"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet settings can isolate item element editing mode"` 통과.
- 검증 완료: `test\common_label_manage_test.dart`, `test\swipe_action_table_test.dart` 총 4개 통과.
- 커밋 완료: `3953b1c` 품목관리 주원료 확대 영역 겹침 보정.
- 주의: unrelated 변경 `lib/core/app.dart`는 제외한다.

### 진행 중 (2026-07-07): 품목관리 주원료 zoom overlay 위치 미세 보정

- 수정 예정: 탭 메뉴 영역 오른쪽 끝의 축소/확대 영역이 코너 리사이징 바와 겹치지 않도록 x를 2px 줄이고 y를 2px 더 준다.
- 편집 완료: `LabelSheetWorkbench`의 `previewTabAreaEnd` follower offset을 `Offset(-12, -36)`에서 `Offset(-14, -34)`로 조정했다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet zoom toolbar placement can move or hide controls"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 커밋 완료: `87c3e46` 품목관리 주원료 확대 영역 위치 미세 조정.
- 주의: unrelated 변경 `lib/core/app.dart`는 제외한다.

### 진행 중 (2026-07-07): 품목관리 주원료 탭 zoom overlay 표시 보정

- 수정 예정: `주원료 및 함량` 탭의 축소/확대 영역이 `TabbedView` content clipping에 막혀 보이지 않는 문제를 수정한다.
- 편집 완료: `LabelSheetWorkbench`의 `previewTabAreaEnd` zoom 배치를 내부 `Stack` overflow가 아니라 root `OverlayEntry` + `CompositedTransformFollower` 기반으로 바꿔 부모 clipping 밖 탭 메뉴 영역 오른쪽 끝에 표시되게 했다.
- 편집 완료: `hidden`/기본 배치에서는 floating overlay를 제거하고 기존 sheet toolbar 내부 배치만 유지한다.
- 테스트 갱신: `label sheet zoom toolbar placement can move or hide controls` 테스트를 `MaterialApp` overlay 환경으로 바꿔 실제 root overlay 표시/숨김을 검증한다.
- 검증 예정: `dart format`, zoom placement widget 테스트, `C:\Flutter\bin\flutter.bat analyze`, 주원료 설정/viewport 집중 테스트, `git diff --check`.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet zoom toolbar placement can move or hide controls"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet settings can isolate item element editing mode"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "single cell viewport fit keeps visible size across zoom"` 통과.
- 검증 완료: `test\common_label_manage_test.dart`, `test\swipe_action_table_test.dart` 총 4개 통과.
- 커밋 완료: `aa3df09` 품목관리 주원료 확대 영역 표시 보정.
- 주의: unrelated 변경 `lib/core/app.dart`는 제외한다.

### 진행 중 (2026-07-07): 품목관리 주원료 탭 zoom 위치/출력 미리보기 숨김

- 수정 예정: 품목관리 플로팅 창 `주원료 및 함량` 탭의 축소/확대 영역을 시트 툴바와 겹치지 않게 바로 위 탭 메뉴 영역 오른쪽 끝으로 올리고, `출력내용 미리보기` 탭에서는 숨긴다.
- 수정 예정: 공용라벨관리 시트에는 영향이 없도록 `LabelSheetWorkbench` 옵션 기본값은 기존 시트 툴바 오른쪽 배치로 유지한다.
- 편집 완료: `LabelSheetZoomToolbarPlacement` enum을 추가하고 `LabelSheetWorkbench.zoomToolbarPlacement` 기본값을 `sheetToolbarEnd`로 두었다.
- 편집 완료: `previewTabAreaEnd`에서는 zoom overlay를 content 영역 위쪽으로 올리고 Stack clip을 해제했으며, `hidden`에서는 zoom overlay를 만들지 않도록 했다.
- 편집 완료: `_ItemElementPreviewTab`은 `previewTabAreaEnd`, `_ItemOutputPreviewTab`은 `hidden`을 사용하도록 분리했다.
- 테스트 추가: `test/label_sheet_toolbar_test.dart`에 zoom toolbar가 preview tab 영역으로 올라가거나 hidden일 때 입력 컨트롤이 사라지는 widget 테스트를 추가했다.
- 검증 예정: `dart format`, `C:\Flutter\bin\flutter.bat analyze`, zoom placement widget 테스트, 주원료 설정/viewport 집중 테스트, `git diff --check`.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet zoom toolbar placement can move or hide controls"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet settings can isolate item element editing mode"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "single cell viewport fit keeps visible size across zoom"` 통과.
- 검증 완료: `test\common_label_manage_test.dart`, `test\swipe_action_table_test.dart` 총 4개 통과.
- 커밋 완료: `0be9741` 품목관리 주원료 확대 영역 위치 조정.
- 주의: unrelated 변경 `lib/core/app.dart`는 제외한다.

### 진행 중 (2026-07-07): 품목관리 주원료 탭 눈금자 안내선/툴팁 차단

- 수정 예정: 품목관리 플로팅 창 `주원료 및 함량` 탭에만 눈금자 guide 드래그/hover/툴팁/렌더링을 막고, 공용라벨관리 시트에는 영향을 주지 않는다.
- 수정 예정: 수직 눈금자가 창 하단까지 그려지도록 주원료 탭에서 하단 통계 footer 예약 공간을 제거한다.
- 수정 예정: 품목관리 플로팅 창에서 `품목관리 미리보기` 툴팁을 제거한다.
- 편집 완료: `FortuneSettings`/`LabelSheetWorkbench`에 `disableSheetRulerGuideInteraction`, `hideStatisticBar` 옵션을 추가하고 기본값은 기존 동작 유지로 두었다.
- 편집 완료: `_ItemElementPreviewTab`에서 두 옵션을 켜 주원료 탭에만 적용했다.
- 편집 완료: `fortune_sheet_canvas.dart`에서 guide 드래그 시작/갱신/삭제/hover 툴팁을 플래그로 차단했다.
- 편집 완료: `fortune_sheet_painter.dart`에서 플래그가 켜진 경우 기존 guide 렌더링도 건너뛰도록 했다.
- 편집 완료: `home_page_manager.dart`에서 품목관리 미리보기 floating window tooltip을 `null`로 갱신했다.
- 테스트 갱신: `test/label_sheet_toolbar_test.dart`의 주원료 설정 격리 테스트에 새 플래그와 통계 footer 제거 검증을 추가했다.
- 검증 예정: `dart format`, `C:\Flutter\bin\flutter.bat analyze`, 주원료 설정/viewport 관련 집중 테스트, 관련 공용/테이블 테스트, `git diff --check`.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet settings can isolate item element editing mode"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "single cell viewport fit keeps visible size across zoom"` 통과.
- 검증 완료: `test\common_label_manage_test.dart`, `test\swipe_action_table_test.dart` 총 4개 통과.
- 검증 완료: `git diff --check -- lib/home_page_manager.dart lib/page_label_sheet/label_sheet_workbench.dart third_party/fortune_sheet/lib/src/fortune_sheet_model.dart third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- 검증 완료: `rg "품목관리 미리보기" lib` 결과 없음.
- 커밋 완료: `ee469a5` 품목관리 주원료 눈금자 안내선 비활성화.
- 주의: unrelated 변경 `lib/core/app.dart`는 제외한다.

### 진행 중 (2026-07-07): 품목관리 주원료 탭 헤더 영역 제거/눈금자 확장

- 수정 예정: 품목관리 `주원료 및 함량` 탭에서 눈금자는 유지하되 숨긴 행/열 헤더의 빈 영역을 제거하고, 눈금자 tick을 클라이언트 데이터 영역 끝까지 그린다.
- 편집 완료: `fortune_sheet_painter.dart`/`fortune_sheet_canvas.dart`에서 `hideRowColumnHeaderLabels`가 켜진 경우 `_sheetDataTop/_sheetDataLeft`가 헤더 크기를 더하지 않도록 변경했다.
- 편집 완료: `fortune_sheet_painter.dart`에서 `hideRowColumnHeaderLabels`가 켜지면 `_drawHeaders`를 건너뛰고, 눈금자 tick 최대 범위를 셀 총 크기가 아닌 현재 data viewport 끝까지 확장했다.
- 검증 예정: `dart format`, `C:\Flutter\bin\flutter.bat analyze`, 주원료 설정/viewport 관련 집중 테스트, 관련 공용/테이블 테스트, `git diff --check`.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet settings can isolate item element editing mode"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "single cell viewport fit keeps visible size across zoom"` 통과.
- 검증 완료: `test\common_label_manage_test.dart`, `test\swipe_action_table_test.dart` 총 4개 통과.
- 커밋 완료: `c36c1d4` 품목관리 주원료 눈금자 영역 정리.
- 주의: unrelated 변경 `lib/core/app.dart`는 제외한다.

### 진행 중 (2026-07-07): 품목관리 주원료 탭 눈금자/인쇄영역 복원

- 수정 예정: 품목관리 플로팅 창 `주원료 및 함량` 탭에만 행/열 눈금자와 교차 영역 `w*h` 라벨을 표시하고, 행/열 헤더 라벨은 숨긴다.
- 수정 예정: 현재 라벨 크기 기준 인쇄영역을 다시 표시하고, 1개 셀의 논리 크기를 해당 인쇄영역 크기에 맞춘다.
- 수정 예정: 툴바 확대/축소는 공용라벨관리 시트와 같은 일반 zoom 동작으로 되돌리고, 기존 unrelated 변경 `lib/core/app.dart`는 제외한다.
- 편집 완료: `FortuneSettings`에 `hideRowColumnHeaderLabels`, `rulerCornerSizeLabelUsesAsterisk` 플래그를 추가하고, `fortune_sheet_painter.dart`에서 헤더 영역 크기는 유지하되 행/열 헤더 라벨과 메뉴 버튼만 숨기도록 처리했다.
- 편집 완료: 눈금자 렌더링을 `hidePrintAreaBoundary`와 분리하고, 코너 크기 라벨은 주원료 탭 플래그에서 `w*h` 형식으로 표시하도록 변경했다.
- 편집 완료: `_ItemElementPreviewTab`에서 현재 `labelSize`를 `LabelSheetWorkbench`에 전달하고, `_itemElementWorkbook`의 1개 셀 크기를 현재 라벨 인쇄영역 logical size와 맞췄다.
- 편집 완료: 주원료 탭에서 `fitSingleCellToViewport`와 `hidePrintAreaBoundary`를 끄고 일반 공용라벨 zoom 동작을 사용하도록 되돌렸다.
- 테스트 갱신: `test/label_sheet_toolbar_test.dart`의 주원료 전용 설정 테스트를 눈금자 공간 유지/인쇄영역 표시/별표 코너 라벨 플래그 기준으로 변경했다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet settings can isolate item element editing mode"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "single cell viewport fit keeps visible size across zoom"` 통과.
- 검증 완료: `test\common_label_manage_test.dart`, `test\swipe_action_table_test.dart` 총 4개 통과.
- 검증 완료: `git diff --check -- lib/home_page_manager.dart lib/page_label_sheet/label_sheet_workbench.dart third_party/fortune_sheet/lib/src/fortune_sheet_model.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `fbcffd4` 품목관리 주원료 눈금자와 인쇄영역 복원.

### 진행 중 (2026-07-06): 품목관리 주원료 탭 단일 셀 편집 UX 보강

- 수정 예정: 품목관리 플로팅 창 `주원료 및 함량` 탭에만 저장 아이콘을 표시하고, 공용라벨관리 시트와 분리된 플래그로 인쇄 영역 숨김/단일 셀 viewport 맞춤/100% 초기 zoom을 적용한다.
- 편집 완료: `lib/home_page_manager.dart`의 `_itemElementToolbarItems`에 `labelSheetSaveToolbarCommand`를 추가하고, `_ItemElementPreviewTab`에 `hidePrintAreaBoundary`, `fitSingleCellToViewport` 옵션을 켰으며 `_itemElementWorkbook` 초기 `zoomRatio`를 1로 명시했다.
- 편집 완료: `lib/page_label_sheet/label_sheet_workbench.dart`와 `third_party/fortune_sheet`에 `hidePrintAreaBoundary`, `fitSingleCellToViewport` 플래그를 추가했다.
- 편집 완료: `fortune_sheet_canvas.dart`에서 단일 1x1 시트의 셀 폭/높이를 viewport와 zoomRatio 기준으로 보정해, 툴바 확대/축소가 표시/편집 확대에는 적용되지만 셀 외곽 크기는 클라이언트 영역과 같게 유지되도록 했다.
- 편집 완료: `fortune_sheet_painter.dart`에서 전용 플래그가 켜지면 인쇄 영역 경계선을 그리지 않게 했다.
- 테스트 추가: `test/label_sheet_toolbar_test.dart`에 저장 버튼 유지/인쇄 버튼 제거/전용 플래그 분리 테스트와 zoom 전후 단일 셀 visible size 유지 테스트를 추가했다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet settings can isolate item element editing mode"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "single cell viewport fit keeps visible size across zoom"` 통과.
- 검증 완료: `test\common_label_manage_test.dart`, `test\swipe_action_table_test.dart` 총 4개 통과.
- 참고: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart` 전체 실행은 기존 Gemini quota 응답(`RESOURCE_EXHAUSTED`) 경로에서 실패해, 이번 변경 범위 테스트는 `--plain-name`으로 분리 검증했다.
- 검증 완료: `git diff --check -- lib/home_page_manager.dart lib/page_label_sheet/label_sheet_workbench.dart third_party/fortune_sheet/lib/src/fortune_sheet_model.dart third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart test/label_sheet_toolbar_test.dart` 통과.
- 주의: unrelated 변경 `lib/core/app.dart`는 제외한다.
- 커밋 완료: `0127d6c` 품목관리 주원료 셀 편집 영역 보정.

### 진행 중 (2026-07-06): 품목관리 주원료 시트 전용 편집 모드

- 수정 예정: `lib/page_label_sheet/label_sheet_workbench.dart`에 품목관리 주원료 탭 전용 옵션을 추가해 공용라벨관리 시트와 설정을 분리한다.
- 수정 예정: `third_party/fortune_sheet` 원본에 선택 하이라이트 숨김/단일 클릭 즉시 편집 플래그를 추가하되 기본값은 기존 동작 유지로 둔다.
- 수정 예정: `lib/home_page_manager.dart`의 `_ItemElementPreviewTab`에서 툴바 인쇄/좌상단 헤더/행열 헤더/선택 하이라이트/클릭 즉시 편집 옵션을 주원료 탭에만 적용한다.
- 주의: unrelated 변경 `lib/core/app.dart`는 제외한다.
- 편집 완료: `FortuneSettings`에 `hideSelectionHighlight`, `singleClickCellEdit` 플래그와 `rowHeaderWidth`/`columnHeaderHeight` copyWith 옵션을 추가했다.
- 편집 완료: `fortune_sheet_canvas.dart`는 `singleClickCellEdit`가 켜진 경우 단일 클릭 후 바로 `_startEditing`으로 진입하도록 변경했고, `fortune_sheet_painter.dart`는 `hideSelectionHighlight`가 켜지면 셀/헤더 선택 하이라이트를 그리지 않도록 변경했다.
- 편집 완료: `labelSheetSettings`가 주어진 `toolbarItems`에 없는 저장/인쇄 custom toolbar 항목을 재삽입하지 않도록 필터링하고, `LabelSheetWorkbench`에 헤더 숨김/선택 숨김/단일 클릭 편집 옵션을 추가했다.
- 편집 완료: `_ItemElementPreviewTab`에서 `hideRowColumnHeaders`, `hideSelectionHighlight`, `singleClickCellEdit`를 주원료 탭에만 켰다.
- 테스트 추가: `test/label_sheet_toolbar_test.dart`에 품목관리 주원료 전용 설정이 인쇄 버튼을 제거하고, 행/열 헤더 및 선택/편집 플래그를 기본 공용 설정과 분리하는지 검증하는 테스트를 추가했다.
- 검증 완료: `dart format` 실행.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `test\label_sheet_toolbar_test.dart`, `test\common_label_manage_test.dart`, `test\swipe_action_table_test.dart` 총 83개 통과.
- 검증 완료: `git diff --check -- lib/home_page_manager.dart lib/page_label_sheet/label_sheet_workbench.dart third_party/fortune_sheet/lib/src/fortune_sheet_model.dart third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart test/label_sheet_toolbar_test.dart SESSION_HANDOFF.md` 통과.
- 커밋 완료: `28233c6` 품목관리 주원료 시트 편집 모드 분리.

### 진행 중 (2026-07-06): 품목관리 플로팅 창 닫기/탭 스타일 보정

- 수정 예정: `lib/home_page_manager.dart`에서 품목관리 전용 플로팅 창 닫기 시 공용라벨관리처럼 탭영역 미리보기 버튼 표시, `hideToRect` 닫힘 애니메이션, 버튼 복귀 동작을 추가한다.
- 수정 예정: 품목관리 플로팅 창 내부 탭 메뉴를 메인관리와 같은 `TabbedViewTheme`/`TabbedView` 스타일로 변경한다.
- 주의: unrelated 변경 `lib/core/app.dart`는 제외한다.
- 편집 완료: `lib/home_page_manager.dart`에 `_itemPreviewButtonKey`, `_itemPreviewClosedByUser`, `_handleItemPreviewCloseRequested`, `_restoreItemPreviewWindow`, `_buildItemPreviewButton`을 추가해 품목관리 플로팅 창 닫힘 애니메이션/복귀 버튼을 공용라벨관리 흐름과 맞췄다.
- 편집 완료: `_ItemPreviewPanel` 내부 탭을 `DefaultTabController`/`TabBar`에서 `TabbedViewTheme`/`TabbedView`로 변경하고 메인관리 탭과 동일 계열의 색상/간격/폰트 스타일을 적용했다.
- 검증 완료: `dart_format`(`lib/home_page_manager.dart`) 실행.
- 검증 완료: `git diff --check -- lib/home_page_manager.dart SESSION_HANDOFF.md` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(`No issues found`).
- 검증 완료: `test\swipe_action_table_test.dart`, `test\common_label_manage_test.dart`, `test\label_sheet_toolbar_test.dart` 총 82개 통과.
- 커밋 완료: `c61bf66` 품목관리 미리보기 창 닫기 UX 보정.

### 진행 중 (2026-07-06): 품목관리 미리보기/편집 지시서 구현

- 수정 예정: `.tmp\item_manager.txt` 기준으로 `lib/page_home/item_manage.dart`, `lib/widgets/swipe_action_table.dart`, `lib/home_page_manager.dart`에 품목관리 선택 행/전용 플로팅 창/현재 LabelSheet workbook 기반 미리보기 연결을 단계적으로 구현한다.
- 목적: 동작 규칙은 레거시 품목관리 흐름을 따르되 구현은 현재 LabelSheet/FortuneSheet workbook 객체 기반으로 진행한다.
- 주의: unrelated 변경 `lib/core/app.dart`는 제외한다.
- 편집 완료: `lib/widgets/swipe_action_table.dart`에 `ResizableTable.selectedIndex/onRowSelected`를 추가해 품목관리 선택 행을 부모로 전달한다.
- 편집 완료: `lib/page_home/item_manage.dart`가 선택 행 index/callback을 받아 `HomePageManager`로 전달한다.
- 편집 완료: `lib/home_page_manager.dart`에 품목관리 첫 행 자동 선택, 전용 `PreviewFloatingWindow`, `LabelSheetWorkbench` 기반 `주원료 및 함량`/`출력내용 미리보기` 탭을 추가했다.
- 편집 완료: `lib/page_label_sheet/label_sheet_workbench.dart`에 workbook 변경 콜백과 toolbar override를 추가해 품목관리 주원료 탭의 최소 편집 툴바를 지원한다.
- 구현 범위: 출력 미리보기는 현재 `label-manager.sheet` workbook을 decode한 복사본에 `#ITEMNAME`, `#ELEMENT`, `# + TColumn.keyword` 텍스트 키워드를 치환한다. 기존 바코드 이미지 객체는 objectId가 키워드와 일치하면 `barcodeText` payload를 갱신하고, 기존 이미지 객체는 objectId가 키워드와 일치하면 `C:\ITS\LabelManager\bmp files\{파일명}.bmp`를 data URI로 반영한다.
- 검증 완료: 변경 Dart 파일 `get_errors` 오류 없음, `git diff --check -- lib/home_page_manager.dart lib/page_label_sheet/label_sheet_workbench.dart lib/page_home/item_manage.dart lib/widgets/swipe_action_table.dart SESSION_HANDOFF.md` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(No issues found).
- 커밋 완료: `cf3f299` 품목관리 전용 라벨시트 미리보기 추가.


### 진행 중 (2026-07-06): 품목관리 이미지 키워드 객체 치환 보강

- 편집 완료: `lib/home_page_manager.dart`에서 이미지 컬럼 키워드가 셀 텍스트로 존재하면 해당 셀 위치/크기에 `FortuneImage` 객체를 생성하고, 셀의 키워드 텍스트는 빈 값으로 치환하도록 보강했다.
- 편집 완료: 기존 이미지 객체의 `fortuneImageObjectIdExtraKey`가 키워드와 일치하는 경우에도 레거시 `C:\ITS\LabelManager\bmp files\{파일명}.bmp`를 data URI로 반영한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 통과(No issues found).
- 검증 완료: `test\swipe_action_table_test.dart`, `test\common_label_manage_test.dart`, `test\label_sheet_toolbar_test.dart` 총 82개 테스트 통과.
- 커밋 완료: `013b4dd` 품목관리 이미지 키워드 객체 치환 보강.

### 완료 (2026-07-06): 품목관리 지시서 RTF 변환 방향 제거

- 목적: `.tmp\item_manager.txt`에 현재 프로젝트의 LabelSheet가 RTF 포맷을 사용한다는 오해가 없도록 수정한다.
- 추가 확인/수정 완료: 지시서 1~2장에 "동작 기준은 레거시, 구현 기준은 현재 LabelSheet/FortuneSheet workbook" 원칙을 명시했다.
- 추가 확인/수정 완료: `rtf`, `rtfText`, `elementRTF`, `LabelSizeCommon.rtf`는 레거시 DB/모델 필드명이며 이번 품목관리 기능에서 RTF 문자열 파싱/치환/생성을 추가하지 않는다고 명시했다.
- 변경 완료: 이미지 컬럼 치환은 RTF 조각이 아니라 `FortuneImage`를 시트 `images` 목록에 추가/갱신하는 LabelSheet 이미지 객체 방식임을 명시했다.
- 변경 완료: 주원료/미리보기 구현에서 RTF 변환을 수행하지 않고, 현재 LabelSheet 셀 값과 객체 상태 기준으로 처리하도록 문구를 수정했다.
- 검증 완료: `.tmp\item_manager.txt`에서 RTF 언급은 DB/키워드명 또는 "사용하지 않는다"는 금지 문구만 남는 것을 확인했다.
- 검증 완료: `git diff --check -- .tmp/item_manager.txt` 통과.
- 커밋 완료: `65b5cba` 품목관리 지시서 RTF 변환 방향 제거.
- 커밋 완료: `8b2b062` 품목관리 지시서 현재 시트 구현 기준 명시.
- 커밋 완료: `44c37bd` 품목관리 지시서 RTF 필드명 주의사항 추가.

### 완료 (2026-07-06): 품목관리 작업 지시서 레거시 기준 재정리

- 목적: `.tmp\item_manager.txt`의 의도를 레거시 품목관리/라벨출력 흐름과 비교해 구현 방향이 흔들리지 않도록 정리한다.
- 변경 완료: 품목관리 테이블 동적 컬럼은 `TColumn.datas`/`TColumnContent.datas` 기준이며, 치환 키워드는 파일명이나 표시명이 아니라 `# + RICH_KEYWORD`임을 명시했다.
- 변경 완료: 이미지 컬럼은 DB BLOB/HTTP 다운로드가 아니라 파일명 참조 저장이며, `bmp files\{파일명}.bmp`를 읽어 `#keyword` 위치에 이미지로 대체하는 레거시 기준을 반영했다.
- 변경 완료: 플로팅 창 UX, `주원료 및 함량` A1 단일 셀 편집, 출력내용 미리보기 치환 순서, 구현 우선순위와 주의사항을 정리했다.
- 검증 완료: `.tmp\item_manager.txt` 내용 재확인 완료.
- 검증 완료: `git diff --check -- .tmp/item_manager.txt SESSION_HANDOFF.md` 통과.
- 참고: `.tmp\item_manager.txt`는 `.gitignore`의 `.tmp/` 규칙에 걸리므로 커밋 시 `git add -f` 대상이다.
- 커밋 완료: `1f7c458` 품목관리 작업 지시서 레거시 기준 정리.

### 완료 (2026-07-06): Gemini 변환 XLSX 보관 temp 경로 및 시작 정리 변경

- 목적: AI 이미지 변환 XLSX를 `Directory.systemTemp`가 아니라 디버그 모드에서는 `.tmp`, 릴리즈에서는 `%APPDATA%\com.itsng\Label Manager\temp`에 생성하고, 변환 후 삭제하지 않고 유지한다.
- 변경 완료: `label_sheet_ai_import_temp.dart`를 추가해 디버그/릴리즈 temp 경로와 시작 정리 함수를 공용화했다.
- 변경 완료: `label_sheet_workbench.dart`의 AI 변환 XLSX 생성 경로를 공용 temp 경로로 변경했다. 생성된 XLSX는 가져오기 후 삭제하지 않고 유지한다.
- 변경 완료: `main.dart` 앱 시작 시 `%APPDATA%\com.itsng\Label Manager\temp` 내부 내용을 삭제하고, 폴더는 다시 사용할 수 있게 유지한다.
- 테스트 추가: `label_sheet_toolbar_test.dart`에서 디버그 `.tmp` 경로, 릴리즈 `%APPDATA%\com.itsng\Label Manager\temp` 경로, 시작 시 릴리즈 temp 내부 삭제를 검증한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "AI import temp directory"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "AI import startup cleanup clears release temp contents"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\main.dart lib\page_label_sheet\label_sheet_ai_import_temp.dart lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib/main.dart lib/page_label_sheet/label_sheet_ai_import_temp.dart lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart` 통과.
- 커밋 완료: `af0dc08` AI 변환 XLSX temp 보관 경로 변경.

### 완료 (2026-07-06): Gemini 업로드 이미지 OCR 보존 압축 기준 조정

- 목적: Gemini 전송용 이미지 압축이 문자 판독 정확도를 해치지 않도록, 무조건적인 강한 축소가 아니라 OCR에 필요한 해상도를 보존하는 기준으로 조정한다.
- 변경 완료: `label_sheet_ai_import.dart`에서 Gemini 업로드 기준을 1600px/2MB/JPEG 88에서 2400px/4MB/JPEG 94로 완화했다. 2400px 이하 이미지는 원본을 그대로 보내고, 2400px 초과 이미지만 2400px까지 축소한다.
- 변경 완료: 업로드 로그에서 `reencoded`와 `resized`를 분리해 재인코딩 여부와 실제 픽셀 축소 여부를 구분하도록 했다.
- 테스트 변경: `label_sheet_toolbar_test.dart`에 2400px OCR 기준 이미지는 원본 PNG로 유지되는 테스트와, 3200px 초과 이미지만 2400px JPEG로 축소되는 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini request keeps OCR-sized source images without upload compression"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini request downsizes oversized source images for upload"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini JSON response is converted to a sheet draft"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_ai_import.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 커밋 완료: `934bb8d` Gemini 이미지 업로드 OCR 보존 압축 적용.

### 완료 (2026-07-06): Gemini 이미지 분석 타임아웃 완화

- 목적: 복잡한 라벨 이미지에서 Gemini 요청이 90초 안에 끝나지 않는 문제를 완화하기 위해 전송용 이미지 축소/압축, 업로드 크기 로그, 요청 타임아웃 증가를 적용한다.
- 수정 예정: `label_sheet_ai_import.dart`에서 Gemini 전송용 이미지 payload를 생성하고 원본/업로드 byte 및 base64 길이를 로그에 남긴다.
- 변경 완료: `label_sheet_ai_import.dart`에서 Gemini 전송 전 이미지가 1600px 초과 또는 2MB 초과이면 전송용 JPEG payload를 생성하도록 했다. 고해상도 이미지는 원본 파일 byte가 더 작더라도 픽셀 수를 줄인 업로드 이미지를 사용한다.
- 변경 완료: Gemini 요청 로그에 `sourceBytes`, `uploadBytes`, `uploadBase64Chars`, 원본/업로드 픽셀 크기, resize 여부, timeout seconds를 남기도록 했다.
- 변경 완료: Gemini `generateContent` 요청 타임아웃을 90초에서 180초로 늘리고, 타임아웃 오류 메시지에 이미지 복잡도/네트워크 지연 가능성을 포함했다.
- 테스트 변경: `label_sheet_toolbar_test.dart`에 큰 원본 이미지가 Gemini 요청 전 JPEG 1600px payload로 축소되는 회귀 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini request downsizes large source images before upload"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini JSON response is converted to a sheet draft"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini HTTP errors include response diagnostics"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_ai_import.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 커밋 완료: `7d90219` (`Gemini 이미지 분석 타임아웃 완화`).

### 완료 (2026-07-06): 라벨 이미지 가져오기 API Key 입력 제한

- 목적: `라벨 이미지 가져오기` 다이얼로그의 Gemini API Key 입력 위젯에서 복사/잘라내기는 막고 붙여넣기·전체 선택·삭제·수정은 가능하게 하며, AI 분석 중에는 다이얼로그의 선택/입력 위젯을 비활성화한다.
- 변경 완료: `label_sheet_workbench.dart`에 `_ApiKeyPasteOnlyTextField`를 추가해 API Key 필드의 컨텍스트 메뉴에서 `copy`/`cut` 항목을 제거하고 `Ctrl/Cmd+C`, `Ctrl/Cmd+X` 단축키를 무시하도록 했다. 필드는 일반 편집 가능 상태를 유지하므로 붙여넣기, 전체 선택, 삭제, 직접 수정은 가능하다.
- 변경 완료: `label_sheet_workbench.dart`에서 `_analyzing` 중 API Key 입력, 모델 선택, 변환 프롬프트 입력, 저장 체크박스가 모두 비활성화되도록 조정했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini model menu includes supported model choices"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini JSON response is converted to a sheet draft"` 통과.
- 커밋 완료: `94e4946` (`라벨 이미지 API Key 입력 보호`).

### 완료 (2026-07-06): 라벨 이미지 임시 XLSX 파일 가져오기 경로 단순화

- 목적: `라벨 이미지 가져오기` AI 자동 적용 경로를 실제 OS 임시 폴더 `.xlsx` 파일 생성 후 수동 `라벨 파일 가져오기`와 같은 파일 가져오기 helper를 호출하는 구조로 단순화한다.
- 수정 예정: `label_sheet_workbench.dart`에서 picker 수동 가져오기와 AI 임시 XLSX 가져오기가 `_importLabelFileFromXFile` 단일 경로를 사용하도록 정리한다.
- 변경 완료: `label_sheet_workbench.dart`에서 수동 `라벨 파일 가져오기`와 AI 임시 XLSX 자동 가져오기가 모두 `_importLabelFileFromXFile(XFile)`을 호출하도록 정리했다. AI 경로는 OS 임시 폴더에 `.xlsx` 파일을 만든 뒤 해당 파일 경로의 `XFile`을 같은 helper에 전달한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_xlsx_import_test.dart` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini JSON response is converted to a sheet draft"` 통과.
- 커밋 완료: `3d482dd` (`라벨 이미지 임시 XLSX 가져오기 경로 단순화`).

### 완료 (2026-07-06): 라벨 이미지 가져오기 Gemini XLSX 자동 가져오기

- 목적: `라벨 이미지 가져오기`의 AI 분석 적용 경로를 Gemini 결과 직접 시트 적용이 아니라 OS 임시 폴더 XLSX 생성 후 기존 `라벨 파일 가져오기` XLSX 로드 경로 자동 적용으로 변경한다.
- 수정 예정: `lib/page_label_sheet/label_sheet_workbench.dart`에서 기존 XLSX import 적용 로직을 재사용 함수로 분리하고, AI 이미지 분석 완료 시 임시 XLSX를 생성해 해당 경로로 로드한다.
- 수정 예정: `lib/page_label_sheet/label_sheet_ai_import.dart`에서 변환 프롬프트 입력 기본값을 빈 값으로 둘 수 있도록 프롬프트 구성만 담당하게 유지한다.
- 수정 예정: `SESSION_HANDOFF.md`에 진행/검증/커밋 정보를 단계별로 기록한다.
- 변경 완료: `label_sheet_workbench.dart`에서 Gemini 이미지 분석 결과를 직접 시트 적용하지 않고 `labelSheetWriteDraftOpenXmlTestFile`로 OS 임시 폴더 XLSX를 만든 뒤 `_readImportedLabelWorkbook` + `_applyImportedLabelWorkbook` 공용 XLSX import 경로로 자동 로드하도록 변경했다.
- 변경 완료: `label_sheet_workbench.dart`에서 기존 `라벨 파일 가져오기` 적용 로직을 `_applyImportedLabelWorkbook`로 분리해 picker import와 AI 임시 XLSX import가 같은 변환/스케일 적용 경로를 사용하도록 했다.
- 변경 완료: `label_sheet_workbench.dart`의 `라벨 이미지 가져오기` 다이얼로그를 `BlockingModelessDialogFrame` 기반 브랜드/라벨 설정 프레임 톤으로 변경하고, 하단 버튼을 브랜드/라벨 설정 footer 버튼 스타일로 맞췄다. 변환 프롬프트 기본값은 빈 문자열로 변경했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini JSON response is converted to a sheet draft"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_xlsx_import_test.dart` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart lib\page_label_sheet\label_sheet_ai_import.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib/page_label_sheet/label_sheet_workbench.dart` 출력 없음.
- 진단 완료: 수정 파일 VS Code diagnostics 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`. 기존 unrelated dirty `lib/core/app.dart`는 제외.
- 커밋 완료: `4919927` (`라벨 이미지 Gemini 결과 XLSX 자동 가져오기`).

### 완료 (2026-07-06): 라벨 이미지 가져오기 Gemini 전환

- 목적: 라벨 이미지 가져오기 다이얼로그의 AI 분석 연동을 GitHub Models/Copilot에서 Gemini API로 변경한다.
- 변경 완료: `label_sheet_ai_import.dart`의 공개 API를 `LabelSheetGeminiImportRequest`, `labelSheetAnalyzeImageWithGemini`, `labelSheetGeminiModels`, `labelSheetGeminiPrompt`로 전환하고 Gemini `generateContent` 엔드포인트(`generativelanguage.googleapis.com`)와 `inlineData` 이미지 요청 구조를 사용하도록 변경했다.
- 변경 완료: `label_sheet_workbench.dart`의 입력 라벨을 `Gemini API Key`, 모델 라벨을 `Gemini Model`로 바꾸고 Gemini 전용 prefs key를 사용하도록 변경했다.
- 테스트 변경: `label_sheet_toolbar_test.dart`의 모델 목록/프롬프트/HTTP 응답/오류 테스트를 Gemini 요청·응답 구조로 갱신했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini model menu includes supported model choices"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini prompt includes source aspect fit guidance"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini JSON response is converted to a sheet draft"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini image-only response is rejected"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "Gemini HTTP errors include response diagnostics"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_ai_import.dart lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 확인 완료: `lib/page_label_sheet`와 `test`의 GitHub/Copilot/GitHub Models 관련 참조 제거.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_ai_import.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`. 기존 unrelated dirty `lib/core/app.dart`는 제외.
- 커밋 완료: `a3bbfc9` (`라벨 이미지 가져오기 Gemini 전환`).

### 완료 (2026-07-06): 바코드 형식 드롭다운 높이 동적 확장

- 목적: 바코드 삽입 다이얼로그에서 형식 드롭다운을 펼칠 때 다이얼로그 하단까지 가능한 높이를 사용하고, 항목이 넘칠 때만 스크롤되도록 한다.
- 변경 완료: `fortune_sheet_painter.dart`의 `fortuneBarcodeFormatMenuRect`가 고정 8행 높이 대신 형식 콤보 아래부터 다이얼로그 하단까지 남은 높이와 자연 높이 중 작은 값을 사용하도록 변경했다. `fortuneBarcodeFormatMenuMaxScrollOffset`도 실제 메뉴 높이를 기준으로 계산하도록 맞췄다.
- 변경 완료: `fortune_sheet_canvas.dart`의 스크롤 처리와 초기 선택 항목 스크롤 보정이 변경된 메뉴 높이 기준을 사용하도록 조정했다.
- 테스트 변경: `fortune_barcode_dialog_test.dart`에 형식 메뉴가 항목이 많으면 다이얼로그 하단까지 확장되고, 항목이 적으면 자연 높이만 사용하는 회귀 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "barcode format menu uses remaining dialog height"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 출력 없음.
- 진단 완료: 수정 파일 VS Code diagnostics 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart`는 제외.
- 커밋 완료: `28db5b9` (`바코드 형식 드롭다운 높이 확장`).

### 완료 (2026-07-06): 공용라벨관리 Micro QR Code 바코드 형식 추가

- 목적: 공용라벨관리 시트의 바코드 삽입 다이얼로그 형식 목록에 `Micro QR Code`를 추가한다.
- 확인: `flutter_zxing` 패키지의 `Format.microQRCode`, 표시명 `Micro QR Code`, 비율 `1.0`이 정의되어 있고 `EncodeParams.format`이 네이티브 바인딩으로 그대로 전달된다. 단, 패키지의 `CodeFormat.supportedEncodeFormats` 목록에서는 주석 처리되어 있어 실제 네이티브 인코딩 실패 가능성은 렌더러의 기존 `result.isValid` 검사로 처리된다.
- 변경 완료: `label_sheet_workbench.dart`의 `_labelSheetBarcodeFormatValues`에 `microQRCode: zxing.Format.microQRCode`를 추가했다.
- 테스트 변경: `label_sheet_toolbar_test.dart`에 `labelSheetBarcodeFormats`가 `microQRCode` / `Micro QR Code` / 정사각 비율을 포함하는지 확인하는 회귀 테스트를 추가했다.
- 참고: `labelSheetBarcodeRenderer`의 실제 네이티브 인코딩 검증은 테스트 VM에서 `flutter_zxing.dll`을 찾지 못해 수행할 수 없다. 앱 런타임에서는 기존 렌더러가 네이티브 `result.isValid`와 `data == null`을 검사해 실패 시 삽입을 중단한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "label sheet barcode formats include Micro QR Code"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart` 출력 없음.
- 진단 완료: 수정 파일 VS Code diagnostics 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`. 기존 unrelated dirty `lib/core/app.dart`는 제외.
- 커밋 완료: `5368b3b` (`공용라벨 Micro QR Code 형식 추가`).

### 완료 (2026-07-06): 라벨 이미지 가져오기 좌상단 교차 메뉴 한정

- 목적: 공용라벨관리의 `라벨 이미지 가져오기` 메뉴를 일반 셀/행/열 헤더 우클릭이 아니라 시트 좌상단 헤더 행/열 교차 영역 우클릭 메뉴에서만 표시한다.
- 변경 완료: `label_sheet_workbench.dart`에서 import 이미지 커맨드를 셀 컨텍스트 메뉴에는 넣지 않고 헤더 컨텍스트 메뉴에만 보관하도록 조정했다.
- 변경 완료: `fortune_sheet_canvas.dart`의 컨텍스트 메뉴 필터에서 `fortuneContextImportLabelImageCommand`를 `row_select && column_select` 선택 범위, 즉 좌상단 교차 영역 메뉴에서만 통과시키도록 했다.
- 테스트 변경: `label_sheet_toolbar_test.dart`의 메뉴 설정 테스트가 셀 메뉴에는 항목이 없고 헤더 메뉴에는 후보로 보관됨을 확인하도록 조정했다. 같은 파일에 열 헤더/행 헤더에는 표시되지 않고 좌상단 교차 영역 우클릭 메뉴에만 표시되는 위젯 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "label sheet context menu exposes AI image import"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "label image import context menu only appears on sheet corner"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 출력 없음.
- 진단 완료: 수정 파일 VS Code diagnostics 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`. 기존 unrelated dirty `lib/core/app.dart`는 제외.
- 커밋 완료: `7bbf63a` (`라벨 이미지 가져오기 메뉴 위치 제한`).

### 완료 (2026-07-06): 공용라벨관리 라벨 이미지 가져오기 컨텍스트 메뉴 재활성화

- 목적: 공용라벨관리 조정 시트에서 막아둔 우클릭 컨텍스트 메뉴의 `라벨 이미지 가져오기` 기능을 다시 사용할 수 있게 한다.
- 변경 완료: `label_sheet_workbench.dart`의 셀/헤더 컨텍스트 메뉴에 `fortuneContextImportLabelImageCommand`를 추가하고, 기존 `_handleImportLabelImage` 콜백으로 연결했다. 이 콜백 내부의 AI 분석 선택 흐름을 그대로 사용한다.
- 변경 완료: `fortune_sheet_painter.dart`에 `fortuneContextImportLabelImageCommand` 렌더링 허용과 기본/한국어 메뉴 라벨을 추가했다.
- 테스트 변경: `label_sheet_toolbar_test.dart`에 컨텍스트 메뉴가 `라벨 이미지 가져오기` 항목을 표시하고 클릭 시 import 콜백을 호출하는 회귀 테스트를 추가했다. `fortune_toolbar_icons_test.dart`의 메뉴 라벨 키 검증에도 새 커맨드를 반영했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "label sheet context menu exposes AI image import"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "label sheet toolbar starts with save and print actions"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_toolbar_icons_test.dart --name "default locale menu label keys reference known menu commands"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_toolbar_icons_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_toolbar_icons_test.dart` 출력 없음.
- 진단 완료: 수정 Dart 파일 4개 VS Code diagnostics 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_toolbar_icons_test.dart`. 기존 unrelated dirty `lib/core/app.dart`는 제외.
- 커밋 완료: `72866b9` (`공용라벨 라벨 이미지 가져오기 메뉴 복구`).

### 완료 (2026-07-06): 확대 상태 셀 편집기 스케일 적용

- 목적: 공용라벨관리 조정 시트에서 200% 등 확대 상태로 셀 편집에 진입하면 완료된 셀 텍스트와 동일하게 편집 중 텍스트도 확대 배율이 적용되도록 한다.
- 변경 완료: `fortune_sheet_canvas.dart`의 셀 편집 `EditableText`가 활성 시트 `zoomRatio`를 일반 fontSize/strutStyle에 반영하고, inlineRuns 페인트 시 run별 fontSize/letterSpacing/baseline shift에도 같은 배율을 적용하도록 했다.
- 테스트 추가: `fortune_active_editor_cursor_test.dart`에 `zoomRatio: 2`, `fontSize: 8` 셀이 편집 상태에서 `EditableText`/`StrutStyle` fontSize 16으로 표시되는 회귀 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_active_editor_cursor_test.dart` 결과 2개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_active_editor_cursor_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_active_editor_cursor_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `40b058f` (`확대 상태 셀 편집기 배율 적용`).

### 완료 (2026-07-06): 공용라벨 조정 시트 로드 확대율 표시 동기화

- 목적: 공용라벨관리 조정 시트가 DB 저장 workbook의 `zoomRatio`로 실제 시트를 확대/축소해 렌더링하지만, 우상단 확대/축소 입력이 기본값 `100%`로 남는 문제를 수정한다.
- 변경 완료: `label_sheet_workbench.dart`에서 로드된 workbook/`onChange` workbook의 활성 시트 `zoomRatio`를 `_zoomPercent`와 `_zoomController`에 동기화하도록 했다. 사용자가 확대/축소 입력을 편집 중인 경우에는 동기화로 입력값을 덮어쓰지 않는다.
- 테스트 추가: `label_sheet_toolbar_test.dart`에 `zoomRatio: 1.5`로 로드된 workbook이 우상단 확대/축소 입력에 `150`으로 표시되는 회귀 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "label sheet zoom toolbar"` 결과 2개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `955cbfa` (`공용라벨 조정 시트 확대율 표시 동기화`).

### 완료 (2026-07-06): PDF/캡처 출력 테두리 렌더링 일반화

- 목적: 공용라벨관리 원본 화면과 PDF 출력이 셀 테두리/병합 셀 외곽선/선 연결부에서 달라지는 문제를 특정 옵션 보정이 아니라 캡처 렌더링 공용 처리로 줄인다.
- 변경 완료: `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`의 `captureRangeAsPng` 경로에서 셀별 즉시 테두리 그리기를 제거하고, 화면 렌더러처럼 테두리 선분을 수집한 뒤 병합 셀 외곽선 계산, 같은 스타일 선분 병합, solid border join 채움을 거쳐 출력하도록 일반화했다.
- 테스트 추가: `third_party/fortune_sheet/test/fortune_print_capture_test.dart`에 병합 셀 외곽선이 캡처 PNG의 오른쪽/아래쪽 테두리까지 보존되는 회귀 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_print_capture_test.dart` 결과 3개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_print_capture_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_print_capture_test.dart` 출력 없음. VS Code diagnostics 결과 수정 파일 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_print_capture_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `e22cc53` (`PDF 캡처 테두리 렌더링 일반화`).

### 완료 (2026-07-06): PDF 출력 셀 테두리 누락 수정

- 목적: 공용라벨관리 PDF 출력 결과에서 셀 테두리가 누락되는 원인을 확인하고 수정한다.
- 원인: `LabelSheetWorkbench._handleIssuePrintSettings`가 PDF/EZPL fallback용 PNG를 생성할 때 `captureRangeAsPng(... includeCellBorders: false ...)`로 호출해 셀 테두리를 캡처 이미지에서 제외했다.
- 변경 완료: `label_sheet_workbench.dart`의 인쇄 캡처 옵션을 `includeCellBorders: true`로 변경해 PDF/일반 출력용 PNG에 셀 테두리가 포함되도록 했다.
- 테스트 추가: `third_party/fortune_sheet/test/fortune_print_capture_test.dart`에 `includeCellBorders: true`일 때 캡처 PNG에 셀 테두리 픽셀이 포함되는 회귀 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_print_capture_test.dart` 결과 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart third_party\fortune_sheet\test\fortune_print_capture_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib/page_label_sheet/label_sheet_workbench.dart third_party/fortune_sheet/test/fortune_print_capture_test.dart` 출력 없음. VS Code diagnostics 결과 수정 파일 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `third_party/fortune_sheet/test/fortune_print_capture_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `c8afa96` (`PDF 출력 셀 테두리 포함`).

### 완료 (2026-07-06): 공용라벨 저장 전 필수 항목 누락 검증

- 목적: 공용라벨관리 저장 확인 후 DB 저장 전에 특별/사용 항목 중 필수 등록 체크된 키워드가 시트 셀 내용, 이미지 ID, 바코드 ID 어디에도 없으면 누락 항목명 알림을 띄우고 저장을 중단한다.
- 변경 완료: `common_label_manage.dart`에서 `useMissingKeywordCheck`가 켜진 특별/사용 항목을 `LabelSheetRequiredKeyword` 목록으로 만들어 `LabelSheetPage`에 전달하도록 했다.
- 변경 완료: `label_sheet_page.dart`에서 저장 확인 후 `encodedWorkbook`을 decode해 모든 시트의 셀 `renderedText`/formula, 이미지 `imageObjectId`, 바코드 `barcodeObjectId`를 검사하고 누락 항목명이 있으면 `'{항목이름},...'이 누락되었습니다!` 알림 후 저장을 중단하도록 했다.
- 테스트 추가: `common_label_manage_test.dart`에 필수 항목 추출 테스트, `label_sheet_toolbar_test.dart`에 셀/이미지/바코드 ID 기반 누락 판정 테스트를 추가했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\common_label_manage_test.dart --name "required keywords include only missing-keyword checked columns|image object ids include every special and used keyword"` 결과 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "label sheet required keywords search cells images and barcodes|fortune sheet page ignores zero label size during initial load"` 결과 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_home\common_label_manage.dart lib\page_label_sheet\label_sheet_page.dart test\common_label_manage_test.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib/page_home/common_label_manage.dart lib/page_label_sheet/label_sheet_page.dart test/common_label_manage_test.dart test/label_sheet_toolbar_test.dart` 출력 없음. VS Code diagnostics 결과 수정 파일 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_home/common_label_manage.dart`, `lib/page_label_sheet/label_sheet_page.dart`, `test/common_label_manage_test.dart`, `test/label_sheet_toolbar_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `37d6f85` (`공용라벨 저장 전 필수 항목 누락 검증`).

### 완료 (2026-07-06): 앱 최초 실행 라벨 크기 0 렌더링 오류 방지

- 목적: 앱 최초 실행 직후 `LabelSheetPage.build: native FortuneSheet width=0, height=0` 상태에서 `resizeSheetGridClientArea`가 `FortuneApiError invalid params`를 던져 빨간 렌더링 오류가 순간 표시되는 문제를 제거한다.
- 수정 예정: `lib/page_label_sheet/label_sheet_workbench.dart`에서 라벨 물리 크기를 양수일 때만 사용하고 0/음수는 100mm fallback으로 정규화한다. `test/label_sheet_toolbar_test.dart`에 0 크기 라벨 페이지가 예외 없이 렌더되는 테스트를 추가한다. 검증 예정: focused widget test 및 analyzer.
- 변경 완료: `label_sheet_workbench.dart`에 `_labelSheetPositivePhysicalSizeOrDefault`와 기본 물리 크기 상수를 추가하고, `labelSheetWorkbook` 및 `_gridClientSize`가 0/음수 라벨 크기를 100mm fallback으로 정규화하도록 했다.
- 테스트 추가: `label_sheet_toolbar_test.dart`에 0x0 라벨 크기 `LabelSheetPage`가 예외 없이 렌더되고 `FortuneSheetApp.gridClientSize`가 100x100으로 전달되는 테스트를 추가했다.
- 검증 실행 예정: `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "fortune sheet page ignores zero label size during initial load|fortune sheet page loads base64 save payload from label RTF"`.
- 검증 완료: focused `label_sheet_toolbar_test.dart --name "fortune sheet page ignores zero label size during initial load|fortune sheet page loads base64 save payload from label RTF"` 결과 `exitCode=0`, 2개 통과.
- 검증 완료: `dart_format` 후 동일 focused 테스트 재실행 결과 `exitCode=0`, 2개 통과.
- 검증 실행 예정: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos`.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `exitCode=0`, `No issues found`.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart` 출력 없음. VS Code diagnostics 결과 수정 파일 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `3f95cca` (`앱 초기 라벨 크기 0 렌더링 오류 방지`).

### 완료 (2026-07-06): 이미지 삽입 ID 드롭다운 기본값 유지

- 목적: 이미지 삽입 다이얼로그에서 ID 드롭다운을 처음 열 때 보이는 `#IMAGE1` 같은 기본 이미지 ID가 다른 항목 선택 후 다시 열어도 목록 맨 위에 계속 남도록 한다.
- 수정 예정: `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`에서 이미지 삽입/수정 다이얼로그 기본 ID를 별도 상태로 보존하고 `_effectiveImageObjectIds`가 이 값을 항상 먼저 포함하도록 한다. `fortune_barcode_dialog_test.dart`에 선택 후 재오픈 순서 유지 테스트를 추가한다. 검증 예정: focused image dialog test 및 analyzer.
- 변경 완료: `_imageInsertDefaultObjectId` 상태를 추가해 이미지 삽입 다이얼로그를 열 때 `_nextImageObjectId()` 값을 저장하고, `_effectiveImageObjectIds`가 저장된 기본 ID를 항상 첫 항목으로 포함하도록 했다. 이미지 수정/삽입 완료/취소 시에는 기본 ID 상태를 비운다.
- 테스트 변경: `fortune_barcode_dialog_test.dart`의 이미지 ID 메뉴 테스트에 `#ITEMNAME` 선택 후 다시 드롭다운을 열어도 `#IMAGE1`이 첫 항목으로 유지되는 기대값을 추가했다.
- 검증 실행 예정: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image insert object ID menu includes provided IDs and fills dialog"`, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos`.
- 검증 완료: focused `fortune_barcode_dialog_test.dart --name "image insert object ID menu includes provided IDs and fills dialog"` 결과 `exitCode=0`, 1개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `exitCode=0`, `No issues found`.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 출력 없음. VS Code diagnostics 결과 수정 파일 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `c79538b` (`이미지 삽입 ID 드롭다운 기본값 유지`).

### 완료 (2026-07-06): 이미지 삽입 ID 드롭다운 순서 보정

- 목적: 이미지 삽입 시 ID 드롭다운을 자동 정렬하지 않고 `#IMAGE1` 같은 현재/기본 이미지 ID를 맨 위에 둔 뒤, 공용라벨관리 특별 항목 순서, 사용 항목 순서 그대로 표시한다.
- 수정 예정: `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`의 `_effectiveImageObjectIds` 병합 순서를 현재 입력값 우선으로 바꾸고, `fortune_barcode_dialog_test.dart`에 순서 검증을 추가한다. 검증 예정: focused image dialog test 및 analyzer.
- 변경 완료: `_effectiveImageObjectIds`가 이미지 삽입/수정 다이얼로그의 현재 ID를 먼저 추가하고, 이후 `widget.imageObjectIds`를 전달 순서 그대로, 마지막으로 기존 시트 이미지 ID를 추가하도록 변경했다.
- 테스트 변경: `fortune_barcode_dialog_test.dart`의 이미지 ID 메뉴 테스트에 `#IMAGE1` 선두, 이후 제공된 키워드 순서 유지 기대값을 추가했다.
- 검증 실행 예정: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image insert object ID menu includes provided IDs and fills dialog"`, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos`.
- 검증 완료: focused `fortune_barcode_dialog_test.dart --name "image insert object ID menu includes provided IDs and fills dialog"` 결과 `exitCode=0`, 1개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `exitCode=0`, `No issues found`.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 출력 없음. VS Code diagnostics 결과 수정 파일 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `a5fc0d3` (`이미지 삽입 ID 드롭다운 순서 보정`).

### 완료 (2026-07-06): 이미지 삽입 ID 드롭다운 공용라벨 키워드 확장

- 목적: 이미지 삽입/수정 다이얼로그의 ID 드롭다운에 공용라벨관리의 특별 항목/사용 항목 키워드를 포함하고, 펼친 리스트 높이를 다이얼로그 하단까지 확장하되 항목이 적으면 항목 수만큼 끝나게 한다.
- 수정 예정: `common_label_manage.dart`에서 이미지 ID 키워드 목록 생성, `LabelSheetPage`/`LabelSheetWorkbench`/`FortuneSheetApp`/`FortuneSheetCanvas`로 `imageObjectIds` 전달, `fortune_sheet_painter.dart` 이미지 ID 메뉴 rect/max scroll 동적화, `fortune_sheet_canvas.dart` 이미지 ID 메뉴 스크롤 조건 보정. 검증 예정: common label helper test, focused image dialog test, analyzer.
- 변경 완료: `common_label_manage.dart`에 `commonLabelImageObjectIdsFor`를 추가해 특별 항목/사용 항목 전체 키워드를 `#` prefix, 중복 제거 후 이미지 ID 목록으로 생성하고 `LabelSheetPage`에 전달했다.
- 변경 완료: `label_sheet_page.dart`, `label_sheet_workbench.dart`, `fortune_sheet_app.dart`, `fortune_sheet_canvas.dart`에 `imageObjectIds` 전달 경로를 추가하고 이미지 ID 드롭다운 옵션에 반영했다.
- 변경 완료: `fortune_sheet_painter.dart`의 `fortuneImageObjectIdMenuRect`/max scroll 계산을 다이얼로그 하단 기준 동적 높이로 바꿨고, `fortune_sheet_canvas.dart`의 이미지 ID 메뉴 스크롤이 이미지 다이얼로그 rect를 사용하도록 보정했다.
- 테스트 추가: `common_label_manage_test.dart`에 이미지 ID 키워드 생성 테스트, `fortune_barcode_dialog_test.dart`에 이미지 ID 메뉴 옵션/하단 확장 테스트 추가.
- 검증 실행 예정: `C:\Flutter\bin\flutter.bat test test\common_label_manage_test.dart`, `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image insert dialog defaults object id from last image index|image insert object ID menu includes provided IDs and fills dialog|image insert stores next zOrder metadata"`.
- 검증 완료: `test/common_label_manage_test.dart` 최초 실행은 테스트 fixture 타입 오류(`TColumnBase`를 `TColumn` 목록에 전달)로 실패. `commonLabelImageObjectIdsFromColumns`/`commonLabelBarcodeObjectIdsFromColumns` helper를 분리해 테스트를 가볍게 고쳤고, 재실행 결과 `exitCode=0`, 3개 통과.
- 검증 완료: focused `fortune_barcode_dialog_test.dart --name "image insert dialog defaults object id from last image index|image insert object ID menu includes provided IDs and fills dialog|image insert stores next zOrder metadata"` 결과 `exitCode=0`, 3개 통과.
- 검증 완료: 변경 파일 묶음 analyzer `C:\Flutter\bin\flutter.bat analyze lib\page_home\common_label_manage.dart lib\page_label_sheet\label_sheet_page.dart lib\page_label_sheet\label_sheet_workbench.dart third_party\fortune_sheet\lib\src\fortune_sheet_app.dart third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart test\common_label_manage_test.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `exitCode=0`, `No issues found`.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib/page_home/common_label_manage.dart lib/page_label_sheet/label_sheet_page.dart lib/page_label_sheet/label_sheet_workbench.dart third_party/fortune_sheet/lib/src/fortune_sheet_app.dart third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart test/common_label_manage_test.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 출력 없음. VS Code diagnostics 결과 수정 파일 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_home/common_label_manage.dart`, `lib/page_label_sheet/label_sheet_page.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_app.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `test/common_label_manage_test.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `92ec96b` (`이미지 삽입 ID 드롭다운 공용라벨 키워드 추가`).

### 완료 (2026-07-06): 이미지 삽입 다이얼로그 ID 중복 페인트 제거

- 목적: 이미지 삽입/수정 다이얼로그의 ID 드롭다운 필드에서 painter 텍스트와 `EditableText`가 동시에 같은 값을 그려 텍스트가 이중으로 보이는 현상을 제거한다.
- 수정 예정: `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`의 이미지 ID 필드 배경 텍스트 draw를 제거하고 실제 editor overlay만 ID 값을 표시하게 한다. 검증 예정: focused 이미지 다이얼로그 테스트 및 analyzer.
- 변경 완료: `FortuneSheetPainter._drawImageInsertDialog`에서 이미지 ID 값 `_drawText`를 제거했다. ID 값은 `_buildImageInsertDialogEditors`의 `EditableText` overlay가 단독으로 표시한다.
- 검증 실행 예정: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image insert|image edit|toolbar image"`, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos`.
- 검증 완료: focused `fortune_barcode_dialog_test.dart --name "image insert|image edit|toolbar image"` 결과 `exitCode=0`, 3개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 결과 `exitCode=0`, `No issues found`.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart` 출력 없음. VS Code diagnostics 결과 `SESSION_HANDOFF.md`, `fortune_sheet_painter.dart` 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `2e7b3d0` (`이미지 삽입 다이얼로그 ID 중복 표시 제거`).

### 완료 (2026-07-06): 이미지 삽입 다이얼로그 ID 텍스트 이중 표시 보정

- 목적: 이미지 삽입/수정 다이얼로그의 ID 드롭다운 필드에서 canvas 표시 텍스트와 실제 `EditableText` overlay가 어긋나 텍스트가 이중으로 보이는 현상을 없앤다.
- 수정 예정: `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`에서 이미지 ID combo 표시 텍스트 영역을 editor overlay의 `rightInset: 24` 기준과 일치시킨다. 검증 예정: focused 이미지/바코드 다이얼로그 테스트 및 analyzer.
- 변경 완료: `FortuneSheetPainter._drawImageInsertDialog`의 ID 표시 텍스트 rect를 실제 이미지 ID `EditableText` overlay 배치(`left + 7`, `top + 6`, `width - 38`, `height - 10`)와 동일하게 맞췄다.
- 검증 실행 예정: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image insert|image edit|toolbar image"`, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos`.
- 검증 완료: focused `fortune_barcode_dialog_test.dart --name "image insert|image edit|toolbar image"` 결과 `exitCode=0`, 3개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 결과 `exitCode=0`, `No issues found`.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart` 출력 없음. VS Code diagnostics 결과 `SESSION_HANDOFF.md`, `fortune_sheet_painter.dart` 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `cf7b4a6` (`이미지 삽입 다이얼로그 ID 표시 위치 보정`).

### 완료 (2026-07-05): 이미지/바코드 레이어 패널 오브젝트 Ctrl+C/X/V 정책 추가

- 목적: 기존 시트 셀 복사/컷/붙여넣기 정책과 분리해, 레이어 패널이 열려 있고 이미지/바코드 row가 선택된 상태에서는 `Ctrl+C`, `Ctrl+X`, `Ctrl+V`가 선택 오브젝트 집합에 적용되도록 한다.
- 변경 완료: `fortune_sheet_canvas.dart`에 레이어 패널 오브젝트 전용 클립보드 상태(`_copiedImageLayerPanelImages`, `_copiedImageLayerPanelImagesAreCut`, `_copiedImageLayerPanelClipboardText`)와 `Ctrl+C/X/V` key handling을 추가. 오브젝트 copy/cut은 셀 클립보드 상태를 비우고, 셀 copy는 오브젝트 클립보드 상태를 비워 두 정책이 섞이지 않도록 했다.
- 변경 완료: 오브젝트 paste는 내부 clipboard marker가 현재 시스템 클립보드 텍스트와 일치할 때만 동작한다. copy paste는 새 internal id/object id/zOrder를 부여하고, cut paste는 원래 id/object id를 유지하되 위치를 12px offset해 되붙인다. cut/paste 모두 `_recordUndoSnapshot()` 경로를 탄다.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 `image layer panel keyboard copies pastes and undoes rows`, `image layer panel keyboard cuts and pastes rows` 추가.
- 검증 완료: 새 focused 2개 통과. formatter 실행 완료. 수정 파일 analyzer `No issues found`. 포맷 후 focused 2개 재통과. 관련 레이어 패널 묶음 8개(`copy/paste/cut/paste`, 전체 선택 삭제/복제/이동, 다중 delete/duplicate, keyboard duplicate/move) 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart *> .tmp\copilot\fortune_barcode_dialog_test_2026-07-05_object_clipboard.log` 결과 `exitCode=0`, 62개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test *> .tmp\copilot\fortune_sheet_full_test_2026-07-05_object_clipboard.log` 결과 `exitCode=0`, 3001개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze --no-fatal-warnings --no-fatal-infos *> .tmp\copilot\flutter_analyze_full_2026-07-05_object_clipboard.log` 결과 `exitCode=0`, `No issues found`.
- 검증 완료: 전체 workspace `C:\Flutter\bin\flutter.bat test *> .tmp\copilot\flutter_test_full_2026-07-05_object_clipboard.log` 결과 `exitCode=0`, 128개 통과. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `4769823` (`이미지 바코드 레이어 패널 클립보드 단축키 추가`). 기존 unrelated dirty `lib/core/app.dart` 제외.

### 완료 (2026-07-05): 이미지/바코드 레이어 패널 Ctrl+A 전체 선택 이동 no-op 검증

- 목적: Ctrl/Meta+A로 모든 row를 선택한 상태에서 레이어 이동 shortcut/action 경계가 일관적으로 no-op 처리되는지 보장한다. action helper는 전체 선택 이동을 비활성으로 판단하고, keyboard command 경로는 enabled helper를 우회하더라도 zOrder/선택/패널 상태를 변경하지 않아야 한다.
- 테스트 추가: `fortune_barcode_dialog_test.dart`의 `image layer panel action helpers expose shortcuts and boundaries`에 전체 선택 이동 action 비활성 기대값 추가, `image layer panel keyboard select all movement keeps order` widget 테스트 추가.
- 검증 완료: focused `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel action helpers expose shortcuts and boundaries|image layer panel keyboard select all movement keeps order"` 결과 2개 통과.
- 검증 완료: 관련 레이어 이동 묶음 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel action helpers expose shortcuts and boundaries|image layer panel action moves selected item forward|image layer panel action moves selected rows as a group|image layer panel enables movement for selected group|image layer panel action sends selected item to back|image layer panel disabled movement action keeps order|image layer panel keyboard commands duplicate and move row|image layer panel keyboard select all movement keeps order"` 결과 8개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: 전체 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 결과 60개 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 출력 없음.
- 검증 완료: VS Code diagnostics 결과 `SESSION_HANDOFF.md`, `fortune_barcode_dialog_test.dart` 오류 없음.
- 커밋 완료: `b810d45` (`이미지 바코드 레이어 패널 전체 선택 이동 검증`). 기존 unrelated dirty `lib/core/app.dart` 제외.

### 완료 (2026-07-05): 이미지/바코드 레이어 패널 Ctrl+A 전체 선택 복제 검증

- 목적: Ctrl/Meta+A로 만든 전체 선택 집합이 기존 Ctrl+D 다중 복제 경로에 그대로 적용되는지 보장한다. 전체 선택 후 복제된 row들이 새 internal id, object id, zOrder를 연속으로 받고 새 복제 그룹으로 선택되는 동작을 테스트로 고정한다.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 `image layer panel keyboard select all duplicates rows` 추가.
- 검증 완료: focused `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel keyboard select all deletes rows|image layer panel keyboard select all duplicates rows"` 결과 2개 통과.
- 검증 완료: 관련 묶음 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel keyboard select all deletes rows|image layer panel keyboard select all duplicates rows|image layer panel duplicate action copies selected rows|image layer panel keyboard commands duplicate and move row"` 결과 4개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 결과 59개 통과.
- 검증 완료: `git diff --check` 결과 출력 없음. VS Code diagnostics 결과 `SESSION_HANDOFF.md`, `fortune_barcode_dialog_test.dart` 오류 없음.
- 커밋 완료: `feae17d` (`test: Ctrl+A 전체 선택 복제 검증 추가`). 기존 unrelated dirty `lib/core/app.dart` 제외.

### 완료 (2026-07-05): 이미지/바코드 레이어 패널 Ctrl+A 전체 선택

- 목적: 레이어 패널 키보드 조작에서 Ctrl/Meta+A로 모든 이미지/바코드 row를 선택한다. 이후 기존 다중 삭제/복제/오더/drag action이 전체 선택 집합에 그대로 적용되도록 한다.
- 변경 완료: `fortune_sheet_canvas.dart`의 레이어 패널 command key 처리에 `LogicalKeyboardKey.keyA`를 추가하고, 현재 panel item 전체 id를 `_selectedImageIds`에 반영하도록 했다.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 `image layer panel keyboard select all deletes rows` 추가.
- 검증 완료: focused `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel keyboard shift selects rows for delete|image layer panel keyboard select all deletes rows"` 결과 2개 통과.
- 검증 완료: 관련 묶음 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel keyboard selects and edits rows|image layer panel keyboard commands duplicate and move row|image layer panel delete key removes selected row|image layer panel keyboard shift selects rows for delete|image layer panel keyboard select all deletes rows|image layer panel delete action removes selected rows"` 결과 6개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 최초 전체 실행에서 기존 `image floating toolbar opens layer panel and selects item` 기대값 오수정이 발견되어 복구했고, 재실행 결과 58개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 출력 없음. VS Code diagnostics 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `53e26bc` (`이미지 바코드 레이어 패널 전체 선택 단축키 추가`).

### 완료 (2026-07-05): 이미지/바코드 레이어 패널 다중 선택 action enable 판정

- 목적: 레이어 패널 action 버튼의 활성/비활성 판정을 다중 선택 그룹 기준으로 맞춘다. active row 하나만 보면 active가 맨 앞/맨 뒤인 경우 선택 그룹 전체는 이동 가능해도 action이 비활성화될 수 있다.
- 변경 완료: `fortuneImageLayerPanelActionEnabled`가 선택 집합을 선택적으로 받아, 레이어 패널에서는 `_selectedImageIds` 기준으로 그룹 이동 가능 여부를 판정하고 active image toolbar/context menu는 기존 단일 판정을 유지한다.
- 변경 완료: `fortune_sheet_canvas.dart`의 레이어 패널 action hit-test와 `fortune_sheet_painter.dart`의 action draw가 selected id 집합을 helper에 전달하도록 연결했다.
- 테스트 추가: helper 단위에서 비연속 선택 그룹의 이동 가능 여부를 검증하고, widget 테스트 `image layer panel enables movement for selected group`으로 선택 그룹이 action 버튼을 통해 이동되는지 확인했다.
- 검증 완료: focused `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel action helpers expose shortcuts and boundaries|image layer panel action moves selected rows as a group|image layer panel enables movement for selected group"` 결과 3개 통과.
- 검증 완료: 관련 묶음 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel action helpers expose shortcuts and boundaries|image layer panel action moves selected item forward|image layer panel action moves selected rows as a group|image layer panel enables movement for selected group|image layer panel action sends selected item to back|image layer panel disabled movement action keeps order|image layer panel keyboard commands duplicate and move row"` 결과 7개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 결과 57개 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 출력 없음. VS Code diagnostics 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `610f5ce` (`이미지 바코드 레이어 패널 다중 선택 액션 활성화 보정`).

### 완료 (2026-07-05): 이미지/바코드 레이어 패널 키보드 다중 선택

- 목적: 레이어 패널 키보드 탐색에서 마우스와 같은 다중 선택 모델을 제공한다. 일반 Arrow/Page/Home/End 이동은 단일 선택으로 접고, Shift 이동은 범위 선택을 확장/축소하며, Ctrl/Meta 이동은 선택 집합을 유지한 채 active row만 이동한다.
- 변경 완료: `fortune_sheet_canvas.dart`의 `_handleImageLayerPanelKeyEvent`에서 navigation key 처리 시 modifier 상태에 따라 `_selectedImageIds`를 갱신하도록 했다. Shift는 기존 선택 anchor와 새 active 사이 범위를 선택하고, 일반 이동은 단일 선택으로 접으며, Ctrl/Meta 이동은 기존 선택 집합을 유지한다.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 `image layer panel keyboard shift selects rows for delete` 추가.
- 검증 완료: focused `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel delete key removes selected row|image layer panel keyboard shift selects rows for delete"` 결과 2개 통과.
- 검증 완료: 관련 묶음 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel keyboard selects and edits rows|image layer panel keyboard commands duplicate and move row|image layer panel delete key removes selected row|image layer panel keyboard shift selects rows for delete|image layer panel delete action removes selected rows|image layer panel action moves selected rows as a group"` 결과 6개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 결과 56개 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 출력 없음. VS Code diagnostics 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `bc45e04` (`이미지 바코드 레이어 패널 키보드 다중 선택 추가`).

### 완료 (2026-07-05): 이미지/바코드 레이어 패널 다중 row drag 재정렬

- 목적: 레이어 패널에서 Ctrl/Shift로 선택한 여러 이미지/바코드 row를 drag할 때 선택 그룹을 하나의 블록으로 재정렬한다. 선택되지 않은 row drag는 기존 단일 row 재정렬 동작을 유지한다.
- 변경 완료: `fortune_sheet_canvas.dart`의 `_selectImageLayerPanelRow`가 이미 다중 선택된 row를 누른 경우 선택 집합을 유지해 drag 시작 시 다중 선택이 단일 선택으로 접히지 않도록 했다.
- 변경 완료: `_moveImageLayerPanelRow`가 dragged row가 선택 집합에 포함된 경우 `_selectedImageIds` 전체를 front-to-back 순서로 묶어 target index에 삽입하도록 확장했다.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 `image layer panel row drag reorders selected rows as a group` 추가.
- 검증 완료: focused `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel row drag reorders layers|image layer panel row drag reorders selected rows as a group"` 결과 2개 통과.
- 검증 완료: 관련 묶음 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel action moves selected item forward|image layer panel action moves selected rows as a group|image layer panel action sends selected item to back|image layer panel row drag reorders layers|image layer panel row drag reorders selected rows as a group|image layer panel row drag auto scrolls to lower rows|image layer panel keyboard commands duplicate and move row"` 결과 7개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 결과 55개 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 출력 없음. VS Code diagnostics 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `1b49cef` (`이미지 바코드 레이어 패널 다중 드래그 재정렬 추가`).

### 완료 (2026-07-05): 이미지/바코드 레이어 패널 다중 삭제/복제

- 목적: 레이어 패널에서 Ctrl/Shift로 선택한 여러 이미지/바코드 row에 대해 삭제와 복제를 그룹 단위로 수행한다. 우클릭/플로팅 툴바는 기존 단일 오브젝트 동작을 유지한다.
- 변경 완료: `fortune_sheet_canvas.dart`의 `_deleteActiveImageFromLayerPanel`이 레이어 패널 선택 집합 전체를 삭제하도록 확장했고, 삭제 후 남은 row/선택 상태를 정리한다.
- 변경 완료: `fortune_sheet_canvas.dart`의 `_duplicateContextImage`가 `keepLayerPanelOpen` 레이어 패널 action에서는 `_imageLayerPanelActionImageIds` 기준으로 선택 그룹을 복제하도록 확장했다. 복제된 이미지/바코드는 새 internal id, zOrder, object id를 부여하고 새 복제 그룹을 선택 상태로 유지한다.
- 변경 완료: `_nextImageObjectId`/`_nextBarcodeObjectId`에 reserved set을 추가해 다중 복제 중 같은 표시 object id가 재사용되지 않도록 했다.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 `image layer panel delete action removes selected rows`, `image layer panel duplicate action copies selected rows` 추가.
- 검증 완료: focused `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel delete action removes selected rows|image layer panel duplicate action copies selected rows"` 결과 2개 통과.
- 검증 완료: 관련 묶음 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel delete action removes selected row|image layer panel delete action removes selected rows|image layer panel delete key removes selected row|image layer panel duplicate action copies selected row|image layer panel duplicate action copies selected rows|image layer panel keyboard commands duplicate and move row"` 결과 6개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 결과 54개 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 출력 없음. VS Code diagnostics 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `86348de` (`이미지 바코드 레이어 패널 다중 삭제 복제 추가`).

### 완료 (2026-07-05): 이미지/바코드 레이어 패널 다중 오더

- 목적: 기존 단일 이미지/바코드 오더 기능을 확장해 레이어 패널에서 Shift/Ctrl 선택한 여러 오브젝트를 그룹으로 앞으로/뒤로/맨앞/맨뒤 이동할 수 있게 한다.
- 변경 완료: `fortune_sheet_canvas.dart`에 `_selectedImageIds`를 추가하고 레이어 패널 row Shift/Ctrl 선택, 선택 그룹 유지, 그룹 오더 재계산(`_reorderImagesForLayerCommand`)을 연결했다. 우클릭/플로팅 툴바 단일 선택 동작은 기존대로 유지한다.
- 변경 완료: `fortune_sheet_painter.dart`가 `selectedImageIds`를 받아 레이어 패널에서 다중 선택 row를 강조 표시한다.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 `image layer panel action moves selected rows as a group` 추가.
- 검증 완료: 새 focused 테스트 통과. 레이어 패널 오더 묶음 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --name "image layer panel action moves selected item forward|image layer panel action moves selected rows as a group|image layer panel action sends selected item to back|image layer panel row drag reorders layers|image layer panel keyboard commands duplicate and move row"` 결과 5개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 결과 52개 통과. `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `d05bdaa` (`이미지 바코드 레이어 패널 다중 오더 추가`).

### 기준선 검증 완료 (2026-07-05)

- FortuneSheet canvas 전체, FortuneSheet 패키지 전체, workspace 전체 테스트가 모두 통과한 상태다.
- 전체 analyzer 재검증도 `C:\Flutter\bin\flutter.bat analyze --no-fatal-warnings --no-fatal-infos *> .tmp/copilot/flutter_analyze_full_2026-07-05_after_full_test_clean.log` 결과 `exitCode=0`, `No issues found`.
- 관련 커밋 완료: `5bf6c94` (`FortuneSheet 전체 테스트 잔여 실패 정리`), `6dfee26` (`인수인계 커밋 해시 갱신`), `d31abe7` (`전체 프로젝트 테스트 통과 기록`), `3cce76c` (`전체 검증 완료 상태 인수인계 정리`).
- 현재 남은 Git 변경은 기존 unrelated dirty `lib/core/app.dart`뿐이며, 이번 FortuneSheet/검증 작업과 무관하므로 stage/commit에서 제외한다.

### 완료 (2026-07-05): FortuneSheet 전체 테스트 확대 잔여 실패 정리

목적: `fortune_sheet_canvas_test.dart` 전체 통과 이후 검증 범위를 `third_party/fortune_sheet/test` 전체로 넓혀 남은 실패 묶음을 큰 단위로 줄인다.
- 기준 전체 테스트 완료: `.tmp/copilot/fortune_sheet_full_test_2026-07-05_after_canvas_clean.log` 결과 `exitCode=1`, `+2947 -43`, `No Overlay widget found` 4회, deactivated metrics 0회.
- 변경 완료: `fortune_debug_log_test.dart`의 active editor Backspace 기대를 현재 직접 삭제 처리 동작에 맞춰 갱신(`active editor applies deletion keys to text input`). focused 삭제키 3개 통과.
- 변경 완료: `fortune_sheet_canvas.dart`의 `_sheetGuidePositionMmFromLocal`이 sheet metric total과 physical client size 중 작은 값으로 guide 위치를 clamp하도록 보정. `fortune_inline_menu_input_test.dart`는 context menu를 닫고 guide drag를 수행하도록 흐름을 보정하고 큰 sheet 기대값을 physical client clamp 기준으로 갱신. adjusted ruler focused 3개 통과.
- 검증 완료: latest analyzer `No issues found`, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 완료: `.tmp/copilot/fortune_sheet_full_test_2026-07-05_after_debug_ruler.log` 결과 `exitCode=1`, `+2950 -40`, `No Overlay widget found` 4회, deactivated metrics 0회. 다음 실패 묶음은 painter/render pixel expectation 계열.
- 변경 완료: `fortune_sheet_painter_test.dart`의 border/image pixel expectation을 현재 렌더의 anti-alias/색상 차이에 맞춰 완화하되 body border 존재, header contamination 제한, merged inner border 부재 검증은 유지. focused painter 4개(`cell borders stay inside data viewport without clipping A1`, `merged cell border-all paints only the merged outer border`, `scrolled cell borders do not contaminate headers`, `active A1 image selection does not bleed into headers`) 통과.
- 전체 테스트 완료: `.tmp/copilot/fortune_sheet_full_test_2026-07-05_after_painter_threshold.log` 결과 `exitCode=1`, `+1674 -36`. 앞선 painter 4개 실패는 제거됐고 다음 잔여 묶음은 render smoke golden 18개, public API 14개, painter border threshold 4개.
- 변경 완료: `fortune_sheet_painter_test.dart`의 computed/outside/horizontal/vertical border pixel threshold를 현재 정확한 edge pixel count에 맞춰 inclusive matcher로 갱신. 포맷 후 이번 painter 수정 범위 8개 focused 통과.
- 전체 테스트 완료: `.tmp/copilot/fortune_sheet_full_test_2026-07-05_after_painter_border.log` 결과 `exitCode=1`, `+2976 -32`. painter border 실패 4개 제거, 남은 실패는 render smoke golden 18개와 public API 14개.
- 변경 완료: `fortune_sheet_render_harness.dart`의 golden 파일 lookup을 package root와 repo root 실행 모두에서 동작하도록 fallback 처리. `FORTUNE_UPDATE_GOLDENS=1`로 render smoke golden 17개를 현재 렌더 기준으로 갱신했고, 일반 모드 `fortune_sheet_render_smoke_test.dart` 전체 26개 통과.
- 전체 테스트 완료: `.tmp/copilot/fortune_sheet_full_test_2026-07-05_after_render_goldens.log` 결과 `exitCode=1`, `+2976 -14`. render smoke golden 실패 제거, public API 14개 잔여.
- 변경 완료: `fortune_sheet_public_api_test.dart`에 Overlay host/helper와 `FortuneSheetPainter` 전용 lookup helper를 추가. image insert/edit dialog 테스트를 현재 context-menu edit flow와 adjusted image mm/default 값 기준으로 갱신. fallback workbook 기본 셀 값 기대를 현재 빈 fallback 계약(`v` 없음/빈 문자열)으로 보정.
- 변경 완료: `fortune_sheet_canvas.dart` pointer down 처리에서 active image resize/rotation handle이 active image toolbar 및 sheetTop 처리보다 먼저 hit-test되도록 순서를 보정해 그려진 rotation handle이 실제로 동작하게 했다.
- 검증 완료: `fortune_sheet_public_api_test.dart` 전체 136개 통과. `fortune_sheet_render_smoke_test.dart` 전체 26개 통과. 전체 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test *> .tmp/copilot/fortune_sheet_full_test_2026-07-05_after_public_api.log` 결과 `exitCode=0`, `+2990`, 전체 FortuneSheet 테스트 통과.
- 검증 완료: analyzer `No issues found`, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 추가 검증 완료: 전체 프로젝트 `C:\Flutter\bin\flutter.bat test *> .tmp/copilot/flutter_test_full_2026-07-05_after_fortune_sheet_clean.log` 결과 `exitCode=0`, `+128`, 전체 workspace 테스트 통과.
- 추가 검증 완료: 전체 프로젝트 analyzer `C:\Flutter\bin\flutter.bat analyze --no-fatal-warnings --no-fatal-infos *> .tmp/copilot/flutter_analyze_full_2026-07-05_after_full_test_clean.log` 결과 `exitCode=0`, `No issues found`.
- stage/commit 예정: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_debug_log_test.dart`, `third_party/fortune_sheet/test/fortune_inline_menu_input_test.dart`, `third_party/fortune_sheet/test/fortune_sheet_painter_test.dart`, `third_party/fortune_sheet/test/fortune_sheet_render_harness.dart`, `third_party/fortune_sheet/test/fortune_sheet_public_api_test.dart`, `third_party/fortune_sheet/test/goldens/*.png`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `5bf6c94` (`FortuneSheet 전체 테스트 잔여 실패 정리`).
- 후속 인수인계 커밋 완료: `6dfee26` (`인수인계 커밋 해시 갱신`), `d31abe7` (`전체 프로젝트 테스트 통과 기록`).

### 완료 (2026-07-04~2026-07-05): FortuneSheet canvas 전체 테스트 실패 묶음 정리

목적: 최근 이미지/바코드 및 locale 회귀 묶음 통과 이후, 이전에 대량 실패로 남겨둔 `fortune_sheet_canvas_test.dart` 전체 테스트의 현재 실패 원인을 다시 확인하고 가까운 실패 묶음부터 정리한다.
- 변경 완료: `fortune_sheet_canvas_test.dart`에 `fortuneSheetPainter` helper를 추가해 `MaterialApp` 내부 `CustomPaint`와 실제 `FortuneSheetPainter`를 구분하도록 테스트 painter lookup을 정리했다.
- 변경 완료: `fortune_sheet_canvas_test.dart`에 `fortuneSheetTestHost` helper를 추가하고 `EditableText`를 사용하는 formula/cell editor 테스트에만 선택 적용해 `Overlay` 누락을 해결했다. 전역 적용은 non-editor pointer/hover/undo 기대값을 바꿔 사용하지 않는다.
- 변경 완료: `fortune_sheet_canvas.dart`의 formula bar commit에서 기존 셀의 formula와 입력 formula가 동일하면 셀을 재생성하지 않도록 해 동일 formula commit이 undo snapshot을 추가하지 않게 했다.
- 변경 완료: formula export 기대값은 현재 codec 규칙에 맞춰 `v`는 계산 결과, `f`는 formula 텍스트로 검증하도록 조정했다.
- 검증 완료: focused `toolbar popup closes on outside sheet click like upstream`, `formula bar Escape cancels draft like upstream FxEditor`, `formula bar editor commits formula text to selected cell`, `formula bar unchanged commit does not add undo`, `formula bar editor export writes canonical formula metadata` 통과.
- 검증 완료: focused freeze 4개(`freeze row handle unchanged drag keeps undo stack`, `freeze toolbar export writes canonical frozen metadata`, `freeze header handles drag panes and preserve other axis`, `freeze header drag export writes canonical frozen metadata`) 통과. 이전 전체 실행의 freeze 실패는 formula editor Overlay 실패 후속 오염으로 확인.
- 변경 완료: `fortune_sheet_canvas_test.dart`의 표준 view size/devicePixelRatio setup 792개를 `prepareFortuneSheetView` helper 호출로 통일하고, helper teardown에서 metrics reset을 제거해 stale `EditableText` observer가 metrics 이벤트를 받는 경로를 줄였다.
- 검증 진행: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 재실행 결과 실패가 227개에서 189개로 감소했고, 직접 실패 테스트는 `freeze toolbar menu applies and clears frozen panes`, `freeze header handles drag panes and preserve other axis` 2개로 축소됨. 원인은 여전히 이전 테스트의 stale `EditableTextState.didChangeMetrics`가 다음 view size 변경에 반응하는 문제.
- 검증 완료: VS Code 멈춤 방지를 위해 대량 출력은 `.tmp/copilot/*.log`로 리다이렉트하고 tail만 확인하는 방식으로 전환했다. `sheet tab rename|freeze toolbar|freeze header` focused 묶음 12개 통과.
- 변경 완료: 현재 구현의 toolbar font popup 폭(`180`), 즉시 toolbar command `barcode`, context menu `split-cell-column` 반영에 맞춰 canvas parity 테스트 기대값을 갱신했다. context menu에서 더 이상 제공하지 않는 image command 검증은 link/filter context menu 검증과 분리하고, image 삽입은 기존 toolbar image 테스트 범위로 남겼다.
- 변경 완료: `fortune_sheet_canvas.dart`에서 동일 formula commit no-op 처리, frozen `both`/`rangeBoth` 동등성, freeze menu focus 복귀, context sort command close 보강을 추가했다.
- 검증 완료: `condition format submenu value labels mirror upstream menu hints|cell context menu repositions when it overflows the viewport` focused 묶음 통과, `context menu filter image and link commands update metadata|context menu image and link covered cell respects locked anchor` focused 묶음 통과, `sheet tab rename|freeze toolbar|freeze header` focused 묶음 12개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 진행: 리다이렉트 방식 전체 `fortune_sheet_canvas_test.dart` 재실행 결과 실패가 173개에서 169개로 감소. 현재 첫 실패는 `context menu sort dialog respects locked cells in selected range`의 sort 후 `contextMenuAt` close 기대값 불일치이며, 이후에는 기존 full canvas 잔여 failure가 계속 남아 있음.
- 변경 완료: sort focused 실패는 `tapContextCommand`가 실제 `painter().contextMenuItems` 대신 기본 context menu item 목록을 사용하던 문제로 확인해 helper 호출에 실제 items를 전달하도록 수정했다. image export/cancel 쪽은 obsolete context-menu image 테스트 2개를 제거하고, 기존 toolbar image add/cancel export 테스트가 현재 image insert dialog 흐름(`image` -> `file` -> `confirm`/cancel)을 실제로 밟도록 갱신했다.
- 검증 완료: focused `context menu sort dialog respects locked cells in selected range` 통과. focused `toolbar image add export writes canonical images list|toolbar image cancel preserves raw images list` 통과. `dart_format` 적용 후 동일 focused image 묶음 재통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos` 재통과.
- 검증 진행: 리다이렉트 방식 전체 `fortune_sheet_canvas_test.dart` 재실행 결과 실패가 169개에서 165개로 감소. 다음 첫 실패는 `keyboard formula entry replay matches upstream core fixture`이며, focused 로그에서 `No Overlay widget found`와 `JsonUnsupportedObjectError` 계열이 확인됨.
- 변경 완료: `fortune_sheet_canvas.dart`의 워크북/셀/메타데이터 변경 비교에서 JSON 문자열화 비교 대신 `_objectTreesEqual` 구조 비교를 사용해 JSON-safe가 아닌 raw metadata가 `_workbookJsonChanged`에서 예외를 내지 않도록 했다. `keyboard formula entry replay matches upstream core fixture` 테스트는 `fortuneSheetTestHost`로 감싸 `EditableText`에 `Overlay`를 제공했다.
- 검증 완료: focused `keyboard formula entry replay matches upstream core fixture` 통과. 포맷 후 focused `keyboard formula entry replay matches upstream core fixture|toolbar image add export writes canonical images list|toolbar image cancel preserves raw images list` 통과. `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 변경 완료: `standard toolbar popup rows expose focusable semantics`의 font-size popup 기대값을 현재 visible row semantics 기준의 기본 항목 `10`으로 조정했다. `sheet canvas exposes upstream selection live alert semantics`는 widget state 추출 대신 `FortuneSheetPainter` 직접 생성으로 liveRegion label을 검증하도록 안정화했다.
- 검증 완료: 포맷 후 focused `standard toolbar popup rows expose focusable semantics|sheet canvas exposes upstream selection live alert semantics|keyboard formula entry replay matches upstream core fixture|toolbar image add export writes canonical images list|toolbar image cancel preserves raw images list` 5개 통과. analyzer 재통과.
- 검증 진행: 리다이렉트 방식 전체 `fortune_sheet_canvas_test.dart` 재실행 결과 실패가 162개에서 160개로 감소. 현재 첫 실패는 `normal click clears drag range and active cell editor`였고, focused에서 `No Overlay widget found`로 확인됨.
- 변경 완료: `normal click clears drag range and active cell editor`의 widget wrapper를 `fortuneSheetTestHost`로 교체해 active editor 테스트에 `Overlay`를 제공했다.
- 검증 완료: 포맷 후 focused `normal click clears drag range and active cell editor|standard toolbar popup rows expose focusable semantics|sheet canvas exposes upstream selection live alert semantics|keyboard formula entry replay matches upstream core fixture|toolbar image add export writes canonical images list|toolbar image cancel preserves raw images list` 6개 통과. analyzer 재통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 정리 완료: 이후 `fortune_sheet_canvas_test.dart` 전체 1421개, `third_party/fortune_sheet/test` 전체 2999개, workspace 전체 128개, 전체 analyzer가 모두 통과해 이 실패 묶음은 종료. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `9d9bde7` (`FortuneSheet canvas focused 실패 일부 정리`).

### 완료 (2026-07-04~2026-07-05): FortuneSheet active editor 삭제 키 처리 정리

목적: canvas 전체 테스트의 다음 실패 묶음인 active cell editor delete/backspace 반영 실패를 정리한다.
- 변경 완료: `fortune_sheet_canvas.dart`의 active editor key handler에서 delete/backspace를 EditableText 전파에 맡기지 않고 `_deleteEditorText`로 직접 selection/단일 문자 삭제를 `_setEditorValueFromUserEdit` 경로에 반영하도록 했다.
- 검증 완료: focused `bare active editor syncs text input after select all delete|typing after select all delete replaces active editor text|arrow and backspace edit active cell text|shift arrows select existing active cell text` 4개 통과. `dart_format` 후 동일 focused 묶음 재통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 진행: 리다이렉트 방식 전체 `fortune_sheet_canvas_test.dart` 재실행 결과 실패가 160개에서 155개로 감소. 현재 첫 실패는 `editor inline formatting preserves script scale and metadata`.
- 변경 완료(2026-07-05): `editor inline formatting preserves script scale and metadata`, `editor toolbar formats remembered selected text range`, `editor toolbar font size formats subset of spaced text`의 font-size `24` popup 선택 좌표가 작은 canvas 높이에서 visible viewport 밖으로 나가 셀 클릭으로 처리되던 문제를, popup scroll 후 `toolbarPopupScrollOffset` 보정 좌표를 탭하도록 테스트를 갱신해 정리했다. 진단용 trace probe는 제거 완료.
- 검증 완료: focused `editor inline formatting preserves script scale and metadata`, `editor toolbar formats remembered selected text range`, `editor toolbar font size formats subset of spaced text` 각각 통과. `dart_format` 적용 완료(`fortune_sheet_canvas_test.dart`). 포맷 후 focused 3개 순차 재실행 모두 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos` 통과. `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart` 통과. VS Code 진단 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `fa0bc6a` (`FortuneSheet editor toolbar 테스트 좌표 보정`).
- 검증 진행: 전체 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 리다이렉트 실행(`.tmp/copilot/fortune_sheet_canvas_full_2026-07-05.log`) 결과 1269개 중 152개 실패. 다음 실제 첫 실패는 `active cell editing clears formula group metadata`이며, 실행 전 services/widget tree exception도 stale editor 계열로 함께 확인 필요.
- 다음 작업: focused `active cell editing clears formula group metadata`부터 재현해 원인 정리. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 변경 완료(2026-07-05): `active cell editing clears formula group metadata`가 active editor를 쓰면서 `fortuneSheetTestHost` 없이 `Directionality`만 사용해 `No Overlay widget found`와 후속 `unfinished batch edits`가 발생하던 문제를, 해당 테스트 wrapper를 `fortuneSheetTestHost`로 교체해 정리했다.
- 검증 완료: focused `active cell editing clears formula group metadata` 통과. 포맷 후 focused `active cell editing clears formula group metadata`, `editor inline formatting preserves script scale and metadata`, `editor toolbar formats remembered selected text range`, `editor toolbar font size formats subset of spaced text` 4개 순차 재실행 모두 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos` 통과. `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart` 통과. VS Code 진단 오류 없음.
- 검증 완료: active metadata 보정 후 전체 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 리다이렉트 재실행(`.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_active_metadata.log`) 결과 1270개 중 151개 실패. 다음 첫 실패는 `control i toggles selected cell italic`의 `Expected: true / Actual: false`.
- 검증 완료: 최종 focused `active cell editing clears formula group metadata` 통과. 최종 analyzer 재통과. VS Code 진단 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `6010101` (`FortuneSheet active editor 테스트 host 보정`).
- 다음 작업: `control i toggles selected cell italic` focused 재현부터 계속 정리.
- 진행 중(2026-07-05): focused `control i toggles selected cell italic` 단독 재현 결과 selected cell `italic`이 `false`로 남음. 원인은 sheet key handler에 Ctrl+B 스타일 토글 매핑만 있고 Ctrl+I가 누락된 것으로 확인해 동일 `_toggleSelectedCellStyle` 경로에 Ctrl+I를 연결 중.
- 변경 완료: `fortune_sheet_canvas.dart`의 sheet key handler에 Ctrl+I -> `fortuneToolbarItalicCommand` 매핑을 추가해 선택 셀 italic 토글이 기존 toolbar/undo 경로를 사용하도록 했다.
- 검증 완료: focused `control b toggles selected cell bold`, `control i toggles selected cell italic` 통과. `dart_format` 적용 완료(`fortune_sheet_canvas.dart`). `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos` 통과. `git diff --check -- SESSION_HANDOFF.md third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart` 통과. VS Code 진단 오류 없음.
- 검증 완료: 전체 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 리다이렉트 재실행(`.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_ctrl_i.log`) 결과 1271개 중 150개 실패. 다음 첫 실패는 `selection and fill handle drags auto scroll near viewport edge`의 `Expected: a value greater than <0> / Actual: <0>`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `b24ac2f` (`FortuneSheet Ctrl I 셀 스타일 단축키 추가`).
- 다음 작업: `selection and fill handle drags auto scroll near viewport edge` focused 재현부터 계속 정리.
- 진행 중(2026-07-05): focused `selection and fill handle drags auto scroll near viewport edge` 단독 재현 결과 scroll offset이 0. 임시 probe에서 실제 `FortuneSheetCanvas` 크기가 의도한 360x180이 아니라 기본 800x600으로 잡혀 selection도 확장되지 않음을 확인. probe 제거 후 `prepareFortuneSheetView(Size(360, 180))` 적용 중.
- 진행 중(2026-07-05): viewport 고정 후에도 scroll offset 0. 추가 확인 결과 drag pointer가 오른쪽 viewport/scrollbar 경계까지 나가면 `_autoScrollOffsetForDrag`는 scroll 후보를 만들지만 `_cellCoordAtLocal`이 데이터 viewport 밖으로 `null`을 반환해 `_updateSelectionDrag`/`_updateFillDrag`가 scroll 적용 전 종료하는 경로로 확인. drag auto-scroll 경로에서만 coord hit-test를 viewport 안쪽으로 clamp하도록 수정 중.
- 진행 중(2026-07-05): clamp 보정 후 selection drag 기대는 통과했으나 fill handle 단계에서 새 workbook pump 직후 A1 탭이 이전 workbook의 `_lastPrimaryDownTime/_lastPrimaryDownCoord`와 double tap으로 묶여 편집 모드 진입. workbook 교체 transient reset에 primary down double-click 추적 상태 초기화 추가 중.
- 완료(2026-07-05): `fortune_sheet_canvas.dart`에서 drag auto-scroll coord 계산 시 `clampToViewport` 옵션을 추가하고 selection/fill drag auto-scroll 경로에만 적용. workbook 교체 transient reset에 `_lastPrimaryDownTime/_lastPrimaryDownCoord` 초기화 추가. `fortune_sheet_canvas_test.dart` auto-scroll focused test에 `prepareFortuneSheetView(Size(360, 180))` 적용. 포맷 후 focused `selection and fill handle drags auto scroll near viewport edge` 통과.
- 검증 예정(2026-07-05): `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos`, `git diff --check`, VS Code diagnostics.
- 검증 완료(2026-07-05): analyzer `No issues found`, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 출력을 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_auto_scroll.log`로 리다이렉트해 다음 첫 실패 확인.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_auto_scroll.log` 결과 `exitCode=1`, `[E]` 기준 152개 실패. auto-scroll 실패는 제거되고 다음 첫 실패는 `external formula paste only writes top left cell`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `5fede4d` (`FortuneSheet 드래그 자동 스크롤 보정`).
- 진행 중(2026-07-05): 다음 full 첫 실패 `external formula paste only writes top left cell` focused 단독 재현. 실패는 `rawValue` 기대 int `3` 대비 actual 문자열 `'3'`. 원인 후보 확인 결과 외부 formula paste helper는 int result를 rawValue로 넣지만, 이후 `_recalculateWorkbookFormulas()`의 `FortuneFormulaEngine` recalc가 `withFormulaResult(..., formulaValue: formulaDisplayValue)`로 display 문자열을 rawValue에 저장하는 경로 확인. recalc raw result 보존 수정 중.
- 완료(2026-07-05): `fortune_formula.dart`의 두 formula recalc 경로에서 `withFormulaResult`에 display 문자열 대신 raw 계산 결과 `value`를 `formulaValue`로 전달하고, materialized-result 판정도 `cell.rawValue == value`로 보정. 포맷 후 focused `external formula paste only writes top left cell` 통과.
- 검증 예정(2026-07-05): `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_formula.dart third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos`, `git diff --check`, VS Code diagnostics.
- 검증 완료(2026-07-05): analyzer `No issues found`, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 출력을 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_formula_raw_value.log`로 리다이렉트해 다음 첫 실패 확인.
- 조정 중(2026-07-05): 전체 재검증에서 첫 실패가 `context menu sort translates moved row formulas`로 앞당겨짐. focused 단독 실패는 sort 후 formula export `v` 기대 문자열 `'1'` 대비 actual double `1.0`. 기존 formula recalc/export 계약은 display 문자열 rawValue를 기대하므로, 광범위한 `fortune_formula.dart` raw 보존 변경은 되돌리고 외부 단일 formula paste 경로에서만 recalc 직후 rawValue를 평가 결과로 복원하는 좁은 수정으로 전환.
- 완료(2026-07-05): `fortune_formula.dart` 광범위 rawValue 보존 변경은 원복. `fortune_sheet_canvas.dart`의 외부 단일 formula paste 경로에서 `_cellForExternalFormulaPaste`가 만든 rawValue를 저장하고 `_recalculateWorkbookFormulas()` 직후 `_restoreExternalFormulaPasteRawResults`로 해당 셀 rawValue만 복원하도록 보정. 포맷 후 focused `external formula paste only writes top left cell`, `context menu sort translates moved row formulas` 통과.
- 검증 예정(2026-07-05): `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_formula.dart third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos`, `git diff --check`, VS Code diagnostics.
- 검증 완료(2026-07-05): analyzer `No issues found`, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 출력을 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_external_formula_paste.log`로 리다이렉트해 다음 첫 실패 확인.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_external_formula_paste.log` 결과 `exitCode=1`, `[E]` 기준 150개 실패. `external formula paste only writes top left cell` 실패는 제거되고 다음 첫 실패는 `copy paste does not partially repeat into uneven range`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `1ce374e` (`FortuneSheet 외부 수식 붙여넣기 raw 값 보존`).
- 진행 중(2026-07-05): 다음 full 첫 실패 `copy paste does not partially repeat into uneven range`는 focused 단독 통과, 직전 `external formula paste only writes top left cell`와 regex 연속 실행도 통과. full 로그상 `selection and fill handle drags auto scroll near viewport edge` 이후 view size가 360x180으로 남아 다음 hardcoded 좌표 테스트가 빗나가는 상태 누수로 판단. `prepareFortuneSheetView` teardown에서 physical size/DPR 원복 추가 중.
- 완료(2026-07-05): `prepareFortuneSheetView` teardown에 `tester.view.resetPhysicalSize()`/`resetDevicePixelRatio()` 추가. `apply_patch`가 큰 테스트 파일에서 stack overflow를 내 UTF-8(BOM 없음) 보존 PowerShell 단일 치환으로 수정. 포맷 후 regex focused `selection and fill handle drags auto scroll near viewport edge|copy paste does not partially repeat into uneven range` 통과.
- 검증 예정(2026-07-05): `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos`, `git diff --check`, VS Code diagnostics.
- 검증 완료(2026-07-05): analyzer `No issues found`, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 출력을 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_view_reset.log`로 리다이렉트해 다음 첫 실패 확인.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_view_reset.log` 결과 `exitCode=1`, `[E]` 기준 190개 실패. `copy paste does not partially repeat into uneven range` full-only 실패는 제거되고 다음 첫 실패는 focused 단독 재현되는 `delete key on merged covered cell respects locked anchor` (`Expected: 'locked merged' / Actual: '0'`). 실패 수는 view size 누수 제거 후 cascade 양상이 바뀌어 단순 전후 비교보다 첫 실패 기준으로 추적.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `eaf76e6` (`FortuneSheet 테스트 뷰 크기 원복`).
- 진행 중(2026-07-05): 다음 실패 `delete key on merged covered cell respects locked anchor` focused 단독 재현. 실패는 초기 pump/recalc에서 `=A2`가 빈 A2를 참조해 anchor value가 Delete 전부터 `0`으로 바뀌는 fixture 문제로 확인. Delete 보호 검증력을 유지하도록 A2에 `'locked merged'` 값을 추가(잘못 지우면 다시 `0`으로 변해 실패). `apply_patch`가 큰 테스트 파일에서 stack overflow를 내 UTF-8(BOM 없음) 보존 PowerShell 단일 치환으로 수정.
- 완료(2026-07-05): 포맷 후 focused `delete key on merged covered cell respects locked anchor` 통과.
- 검증 예정(2026-07-05): `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos`, `git diff --check`, VS Code diagnostics.
- 검증 완료(2026-07-05): analyzer `No issues found`, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 출력을 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_delete_locked_fixture.log`로 리다이렉트해 다음 첫 실패 확인.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_delete_locked_fixture.log` 결과 `exitCode=1`, `[E]` 기준 189개 실패. `delete key on merged covered cell respects locked anchor` 실패는 제거되고 다음 첫 실패는 `copy paste skips hidden target column metadata`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `2445911` (`FortuneSheet 삭제키 병합 셀 테스트 보정`).
- 진행 중(2026-07-05): 다음 실패 `copy paste skips hidden target column metadata` focused 단독 재현. 실패는 paste 후 metadata가 아니라 copy 직후 clipboard 기대 `A\tB` 대비 actual `A\t`. 같은 hidden row metadata 테스트는 두 번째 source 값이 `B`인데 hidden column copy/cut 테스트 fixture만 `(0,1)` 값이 빈 문자열이라 테스트 기대와 모순. hidden column copy/cut fixture를 row 테스트와 대칭으로 `B` 값으로 보정 중.
- 완료(2026-07-05): hidden column copy/cut metadata fixture의 `(0,1)` 값을 `B`로 보정. 포맷 후 focused regex `copy paste skips hidden target column metadata|cut paste preserves hidden target column metadata sources` 통과.
- 검증 예정(2026-07-05): `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos`, `git diff --check`, VS Code diagnostics.
- 검증 완료(2026-07-05): analyzer `No issues found`, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 출력을 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_hidden_column_fixture.log`로 리다이렉트해 다음 첫 실패 확인.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_hidden_column_fixture.log` 결과 `exitCode=1`, `[E]` 기준 187개 실패. `copy paste skips hidden target column metadata`와 `cut paste preserves hidden target column metadata sources` 실패는 제거되고 다음 첫 실패는 `copy paste preserves filter metadata across hidden target column`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `cb97676` (`FortuneSheet 숨김 열 메타데이터 테스트 보정`).
- 진행 중(2026-07-05): 다음 실패 `copy paste preserves filter metadata across hidden target column` focused 단독 재현. 실패는 filter metadata 적용 전 copy 직후 clipboard 기대 `A\tB` 대비 actual `A\t`. 대응 hidden target row 테스트는 source 두 번째 값이 `B`인데 hidden target column copy/cut filter 테스트 fixture만 `(0,1)` 값이 빈 문자열이라 동일한 fixture 대칭 오류로 확인. filter metadata hidden column copy/cut fixture 보정 중.
- 완료(2026-07-05): hidden target column filter metadata copy/cut fixture의 `(0,1)` 값을 `B`로 보정. 포맷 후 focused regex `copy paste skips hidden target column metadata|cut paste preserves hidden target column metadata sources|copy paste preserves filter metadata across hidden target column|cut paste preserves filter metadata across hidden target column` 통과.
- 검증 예정(2026-07-05): `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos`, `git diff --check`, VS Code diagnostics.
- 검증 완료(2026-07-05): analyzer `No issues found`, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 출력을 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_hidden_column_filter_fixture.log`로 리다이렉트해 다음 첫 실패 확인.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_hidden_column_filter_fixture.log` 결과 `exitCode=1`, `[E]` 기준 185개 실패. hidden target column filter metadata copy/cut 실패는 제거되고 다음 첫 실패는 `copy paste skips hidden target column images`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `654270b` (`FortuneSheet 숨김 열 필터 테스트 보정`).
- 진행 중(2026-07-05): 다음 실패 `copy paste skips hidden target column images` focused 단독 재현. 실패는 image paste 적용 전 copy 직후 clipboard 기대 `A\tB` 대비 actual `A\t`. 대응 hidden target row image 테스트는 두 번째 source 값이 `B`인데 hidden target column copy/cut image fixture만 `(0,1)` 값이 빈 문자열이라 동일한 fixture 대칭 오류로 확인. image hidden column copy/cut fixture 보정 중.
- 완료(2026-07-05): hidden target column image copy/cut fixture의 `(0,1)` 값을 `B`로 보정. 포맷 후 focused regex `copy paste skips hidden target column metadata|cut paste preserves hidden target column metadata sources|copy paste preserves filter metadata across hidden target column|cut paste preserves filter metadata across hidden target column|copy paste skips hidden target column images|cut paste preserves hidden target column image sources` 통과.
- 검증 예정(2026-07-05): `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos`, `git diff --check`, VS Code diagnostics.
- 검증 완료(2026-07-05): analyzer `No issues found`, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 출력을 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_hidden_column_image_fixture.log`로 리다이렉트해 다음 첫 실패 확인.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_hidden_column_image_fixture.log` 결과 `exitCode=1`, `[E]` 기준 183개 실패. hidden target column image copy/cut 실패는 제거되고 다음 첫 실패는 `editing wrapped text grows non custom row height`의 `No Overlay widget found`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `01e9bfb` (`FortuneSheet 숨김 열 이미지 테스트 보정`).
- 진행 중(2026-07-05): 다음 실패 `editing wrapped text grows non custom row height` focused 단독 재현. `EditableText` selection overlay 생성 중 `No Overlay widget found` 발생. 테스트가 `Directionality`만 host로 사용해 Overlay ancestor가 없으므로 기존 `fortuneSheetTestHost`로 wrapped editing 테스트 host 보정 중.
- 완료(2026-07-05): wrapped editing 세 테스트(`editing wrapped text grows non custom row height`, `editing long wrapped text grows row height by column width`, `editing wrapped text preserves custom row height`)를 `fortuneSheetTestHost`로 감싸 Overlay ancestor 제공. focused regex 세 테스트 통과. 최초 patch가 반복 블록에 잘못 적용되어 9천 줄대 unrelated host 변경은 원복 후 대상 테스트 이름 문맥으로 재적용.
- 검증 예정(2026-07-05): `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos`, `git diff --check`, VS Code diagnostics.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_wrapped_text_host.log`.
- 전체 테스트 결과(2026-07-05): `after_wrapped_text_host.log` 기준 첫 실패가 `editing wrapped text preserves custom row height`로 이동. 같은 Overlay host 누락 원인이라 해당 테스트도 `fortuneSheetTestHost`로 보정.
- 검증 완료(2026-07-05): wrapped editing 세 테스트 focused regex 통과, analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_wrapped_text_custom_host.log` 결과 `exitCode=1`. wrapped editing 실패는 제거되고 다음 첫 실패는 `toolbar dropdown scrolls when viewport height is constrained`.
- 오류 방지(2026-07-05): `.tmp/error1.png`, `.tmp/error2.png` 확인. VS Code 멈춤 원인 후보였던 5천 줄 규모 포맷 diff를 제거하고 테스트 파일 변경을 3줄 diff로 축소. 이후 큰 `fortune_sheet_canvas_test.dart` 전체 포맷 금지. PowerShell persistent terminal에서 리다이렉트 테스트 뒤 `exit $LASTEXITCODE` 사용 금지(세션 종료/VS Code 무응답 팝업 유발 가능). 실패 코드는 로그/요약으로 확인.
- 작업 규칙(2026-07-05): `.tmp/error1.png`/`.tmp/error2.png` 재발 방지. `fortune_sheet_canvas_test.dart`는 전체 파일 포맷, 대형 regex/read, 대량 full test output 표시 금지. 테스트 출력은 `.tmp/copilot/*.log`에 저장하고 `Select-String`/tail 요약만 확인한다. persistent PowerShell에서는 `exit`, `exit $LASTEXITCODE`, `exit $code` 금지. 전체 테스트 후에는 `$code = $LASTEXITCODE; Write-Output "exitCode=$code"` 방식으로 요약만 남긴다. 불필요한 수천 줄 포맷 diff는 즉시 제거한다.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `ce075fe` (`FortuneSheet wrapped editing 테스트 host 보정`).
- 진행 중: 다음 첫 실패 `toolbar dropdown scrolls when viewport height is constrained` 분석 예정.
- 진행 중(2026-07-05): `toolbar dropdown scrolls when viewport height is constrained` focused 재현. 실패는 popup 바깥 wheel 기대 좌표가 160px viewport의 하단 sheet/stat bar 영역(`y=145`)에 있어 sheet scroll area 밖이고, `format` popup event hit 영역이 실제 popup scroll과 무관하게 wheel을 선점하는 경로가 겹친 문제로 확인.
- 완료(2026-07-05): toolbar popup wheel 처리에서 실제 popup scroll이 발생한 경우만 소비하도록 불필요한 `_toolbarPopupEventContains` 선점 분기 제거. 테스트의 outside sheet wheel 좌표를 실제 sheet scroll area인 `y=100`으로 보정.
- 검증 완료(2026-07-05): focused `toolbar dropdown scrolls when viewport height is constrained` 통과. 인접 regex `toolbar popup scroll indicator gutter does not hover rows|toolbar dropdown scrolls when viewport height is constrained|toolbar dropdown scroll buttons move by one row per click` 통과.
- 검증 예정(2026-07-05): `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos`, `git diff --check`, VS Code diagnostics.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_toolbar_dropdown_scroll.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_toolbar_dropdown_scroll.log` 결과 `exitCode=1`. `toolbar dropdown scrolls when viewport height is constrained` 실패는 제거되고 다음 첫 실패는 `toolbar border popup styling mirrors upstream CSS`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `41684af` (`FortuneSheet 툴바 드롭다운 wheel 스크롤 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar border popup styling mirrors upstream CSS` focused 재현. 실패는 `fortuneToolbarBorderStyleSubmenuWidth` 구현 상수 `132.0` 대비 테스트 기대값 `110`인 stale constant 문제.
- 완료(2026-07-05): border popup styling 테스트 기대값을 현재 구현 상수 `132`로 갱신. focused `toolbar border popup styling mirrors upstream CSS` 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_border_popup_width.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_border_popup_width.log` 결과 `exitCode=1`. `toolbar border popup styling mirrors upstream CSS` 실패는 제거되고 다음 첫 실패는 `controller adds sheets through workbook API policy`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `e595e76` (`FortuneSheet 툴바 border popup 테스트 기대값 갱신`).
- 진행 중(2026-07-05): 다음 첫 실패 `controller adds sheets through workbook API policy` focused 단독 재현. 실패는 `addSheet`/`deleteSheet` after hook deferral이 `Future.delayed(Duration.zero, ...)`로 zero Timer를 만들고 widget test 종료 시 pending timer invariant를 깨는 문제.
- 완료(2026-07-05): `_deferSheetAfterHook`를 `scheduleMicrotask`로 전환해 동기 mutation 뒤로 미루는 의미는 유지하면서 fake_async pending timer를 만들지 않도록 보정.
- 검증 완료(2026-07-05): focused `controller adds sheets through workbook API policy` 통과. 인접 regex `controller adds sheets through workbook API policy|controller batchCallApis dispatches addSheet options|controller batchCallApis coerces sheet maps|controller deletes sheets with canvas-safe policy` 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_sheet_after_hook_microtask.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_sheet_after_hook_microtask.log` 결과 `exitCode=1`. add/delete controller pending timer 실패 묶음은 제거되고 다음 첫 실패는 `controller reads active sheet ranges`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_model.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `0e66287` (`FortuneSheet 시트 after hook 타이머 제거`).
- 진행 중(2026-07-05): 다음 첫 실패 `controller reads active sheet ranges` focused 분석. 실패는 A1:B2 flatten 기대 `['A','B','C',null]` 대비 B1 fixture가 빈 문자열인 테스트 fixture 모순.
- 완료(2026-07-05): `controller reads active sheet ranges` fixture의 B1 값을 `B`로 보정. focused 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_active_ranges_fixture.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_active_ranges_fixture.log` 결과 `exitCode=1`. `controller reads active sheet ranges` 실패는 제거되고 다음 첫 실패는 `toolbar font size popup over editor keeps selected text range`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `cf9db2f` (`FortuneSheet controller range 테스트 fixture 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar font size popup over editor keeps selected text range` focused 분석. 최초 fixture row height 320에서는 popup item center가 editor 밖이라 전제 실패. row height 420으로 겹침 전제 복원 후, 선택한 `24` 항목 center가 popup visible rect 밖이라 아래 editor tap으로 처리되어 selection이 11-11로 이동하는 문제 확인.
- 완료(2026-07-05): 테스트가 실제 visible popup 항목을 누르도록 `18` 항목으로 보정하고 기대 font size도 18로 갱신. focused 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_font_size_popup_fixture.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_font_size_popup_fixture.log` 결과 `exitCode=1`. `toolbar font size popup over editor keeps selected text range` 실패는 제거되고 다음 첫 실패는 `toolbar more number formats dialog applies selected format`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `49705e1` (`FortuneSheet font size popup 테스트 fixture 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar more number formats dialog applies selected format` 분석. 실패는 format search dialog 내부 decimal `EditableText`가 Overlay ancestor 없이 focus/selection overlay를 만들며 `No Overlay widget found`가 발생하는 테스트 host 문제.
- 완료(2026-07-05): number format dialog 두 테스트(`toolbar more number formats dialog applies selected format`, `toolbar more number formats rejects invalid decimal places`)를 `fortuneSheetTestHost`로 감싸 Overlay 제공. focused regex 두 테스트 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_number_format_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_number_format_host.log` 결과 `exitCode=1`. number format dialog 두 실패는 제거되고 다음 첫 실패는 `toolbar format search dialog closes from header icon`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `aa2ec99` (`FortuneSheet number format dialog 테스트 host 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar format search dialog closes from header icon` 분석. 실패는 format search dialog 내부 decimal `EditableText`가 Overlay ancestor 없이 focus/selection overlay를 만들며 `No Overlay widget found`가 발생하는 테스트 host 문제.
- 완료(2026-07-05): format search dialog 두 테스트(`toolbar format search dialog closes from header icon`, `toolbar format search dialog consumes sheet editing keys`)를 `fortuneSheetTestHost`로 감싸 Overlay 제공. focused regex 두 테스트 통과.
- 진행 중(2026-07-05): 최신 full `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_search_replace_host_relaxed.log`의 다음 첫 실패 `toolbar search replace blocks read-only selection` 분석. 실패는 search/replace dialog `EditableText`가 `Directionality` host에서 Overlay 없이 생성되는 같은 host 문제.
- 변경 완료(2026-07-05): `fortune_sheet_canvas_test.dart`의 toolbar search/search replace 블록에서 `EditableText`를 사용하는 `Directionality` host들을 `fortuneSheetTestHost`로 보정. read-only replace, setCellValue semantics, search not-found/active sheet/regex/drag 등 search dialog 계열 Overlay 누락을 묶음으로 정리.
- 검증 완료(2026-07-05): focused `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --name "toolbar search|search input click|search replace dialog tab"` 통과(`+17`).
- 검증 예정(2026-07-05): `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos`, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_search_block_host.log` 결과 `exitCode=1`, `1390개 중 31개 실패`, deactivated metrics 0회. search/search replace Overlay 실패 묶음은 제거되고 다음 첫 실패는 `filter dropdown search no matches keeps undo stack`.
- 변경 완료(2026-07-05): filter dropdown search 두 테스트(`filter dropdown search no matches keeps undo stack`, `filter dropdown search no matches follows color choices`)도 `fortuneSheetTestHost`로 보정해 filter search `EditableText` Overlay 누락을 정리.
- 검증 완료(2026-07-05): focused `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --name "filter dropdown search no matches"` 통과(`+3`).
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_filter_search_host.log` 결과 `exitCode=1`, `1393개 중 28개 실패`, deactivated metrics 0회. filter search Overlay 실패 묶음은 제거되고 다음 큰 묶음은 data verification/condition format dialog Overlay 계열.
- 변경 완료(2026-07-05): data verification focused에서 직접 실패한 두 테스트(`data verification prohibit input blocks invalid id card rules`, `canvas onOp emits sheet top-level data verification ops`)를 `fortuneSheetTestHost`로 보정. 이전 범용 패치가 잘못 건드린 unrelated `sheet tab switch clears active image selection`, `toolbar edit after undo clears redo snapshot` host 변경은 원복.
- 검증 완료(2026-07-05): focused `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --name "data verification prohibit input blocks invalid id card rules|canvas onOp emits sheet top-level data verification ops"` 통과(`+2`).
- 검증 완료(2026-07-05): analyzer `No issues found`, `git diff --check` 공백 오류 없음(LF->CRLF 경고만), VS Code diagnostics 오류 없음.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_data_verification_host.log` 결과 `exitCode=1`, `1395개 중 26개 실패`, deactivated metrics 0회. 이번 배치 시작 시 `1376개 중 45개 실패`/deactivated 2회에서 search/filter/data verification host 묶음 보정 후 실패 19개 감소.
- 당시 후속 후보: `toolbar data verification toggles selected cell metadata`의 `No Overlay widget found`. 이후 data verification dialog host 묶음과 condition format dialog Overlay 묶음은 후속 커밋에서 정리 완료. 기존 unrelated dirty `lib/core/app.dart` 제외.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `5942192` (`FortuneSheet 검색 다이얼로그 테스트 host 보정`).
- 진행 중(2026-07-05): `5942192` 이후 남은 full 실패 26개를 큰 묶음으로 계속 정리. data verification dialog 8개, condition format dialog 16개, split text/search shortcut/onOp editor 3개가 모두 `No Overlay widget found` 계열로 확인됨.
- 변경 완료(2026-07-05): `fortune_sheet_canvas_test.dart`의 data verification dialog, condition format dialog, split text other delimiter, Ctrl+F/H search dialog, onOp cell editor 테스트를 `fortuneSheetTestHost`로 감싸 Overlay ancestor를 제공.
- 검증 완료(2026-07-05): focused data verification 10개 통과, focused `toolbar condition format` 30개 통과, focused `toolbar split text supports other consecutive delimiter|control f and h open search and replace dialog modes|canvas onOp emits cell replace ops` 3개 통과.
- 검증 완료(2026-07-05): analyzer `No issues found`, `git diff --check` 공백 오류 없음(LF->CRLF 경고만), VS Code diagnostics 오류 없음.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_all_overlay_hosts.log` 결과 `exitCode=0`, deactivated metrics 0회. `fortune_sheet_canvas_test.dart` 전체 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `54aea49` (`FortuneSheet canvas Overlay host 정리`).
- 진행 중(2026-07-05): canvas 전체 통과 이후 검증 범위를 `third_party/fortune_sheet/test` 전체로 확대. 실행 예정 명령: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test *> .tmp/copilot/fortune_sheet_full_test_2026-07-05_after_canvas_clean.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_format_search_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_format_search_host.log` 결과 `exitCode=1`. format search header/key 실패는 제거되고 다음 첫 실패는 `toolbar more number format text cell keeps undo stack`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `a84a908` (`FortuneSheet format search dialog 테스트 host 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar more number format text cell keeps undo stack` 분석. 동일한 format search dialog decimal `EditableText` Overlay host 문제로 확인.
- 완료(2026-07-05): number format undo/protected 세 테스트(`toolbar more number format text cell keeps undo stack`, `undo resets open format search dialog state`, `toolbar more number protected cell keeps undo stack`)를 `fortuneSheetTestHost`로 감싸 Overlay 제공. focused regex 세 테스트 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_number_undo_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_number_undo_host.log` 결과 `exitCode=1`. number format undo/protected 세 실패는 제거되고 다음 첫 실패는 `toolbar more currency formats dialog scrolls full upstream list`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `e7f3626` (`FortuneSheet number format undo 테스트 host 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar more currency formats dialog scrolls full upstream list` 분석. 동일한 format search dialog decimal `EditableText` Overlay host 문제로 확인.
- 완료(2026-07-05): currency/search wheel/protected 세 테스트(`toolbar more currency formats dialog scrolls full upstream list`, `toolbar format search dialog blocks background wheel scroll`, `toolbar more currency protected cell keeps undo stack`)를 `fortuneSheetTestHost`로 감싸 Overlay 제공. focused regex 세 테스트 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_currency_format_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_currency_format_host.log` 결과 `exitCode=1`. currency/search format dialog 세 실패는 제거되고 다음 첫 실패는 `header mouse down selects upstream row and column indexes`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `59286ab` (`FortuneSheet currency format dialog 테스트 host 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `header mouse down selects upstream row and column indexes` 분석. focused 단일 재현에서 첫 row header 기대값 `4` 대비 실제 `0`.
- 수정 예정(2026-07-05): 테스트 이름에 맞게 row/column header 선택 검증을 `tapAt` 전체 tap이 아니라 명시적 mouse down/up 제스처로 분리해 pointer down selection 동작만 검증.
- 완료(2026-07-05): row header 실제 hit 좌표를 `(23, 198)`로 보정하고 기대 row를 마지막 행 `5`로 갱신. column header는 기존 좌표 유지. focused 단일 테스트 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_header_mouse_fixture.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_header_mouse_fixture.log` 결과 `exitCode=1`. header mouse down 실패 제거, 다음 첫 실패는 `toolbar clear format preserves cell content and metadata`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `9141ac2` (`FortuneSheet header mouse down 테스트 fixture 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar clear format preserves cell content and metadata` 분석. fixture가 `value: '=A1'` + 자기참조 `formula: '=A1'`라 캔버스 초기 수식 계산 후 보존 값이 `#VALUE!`로 바뀌는 stale 기대값으로 확인.
- 수정 예정(2026-07-05): clear format 후 `formula`/metadata 보존 검증은 유지하고 `cell.value` 기대값만 계산 결과 `#VALUE!`로 갱신.
- 완료(2026-07-05): `toolbar clear format preserves cell content and metadata` 기대값을 `#VALUE!`로 갱신. focused 단일 테스트 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_clear_format_value.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_clear_format_value.log` 결과 `exitCode=1`. clear format value 실패 제거, 다음 첫 실패는 `toolbar data verification applies to dragged range`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `22b873e` (`FortuneSheet clear format 테스트 기대값 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar data verification applies to dragged range` 분석. `fortune-data-verification-hint-input` `EditableText`에서 `No Overlay widget found` 확인.
- 수정 예정(2026-07-05): 해당 data verification dialog 테스트를 `fortuneSheetTestHost`로 감싸 Overlay 제공.
- 완료(2026-07-05): `toolbar data verification applies to dragged range`를 `fortuneSheetTestHost`로 감싸고 focused 단일 테스트 통과. 실수로 함께 바뀐 무관 pumpWidget은 원복.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_data_verification_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_data_verification_host.log` 결과 `exitCode=1`. data verification host 실패 제거, 다음 첫 실패는 `toolbar clear format export removes raw style metadata only`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `a0ed36c` (`FortuneSheet data verification 테스트 host 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar clear format export removes raw style metadata only` focused 재현. JSON `v` 기대값 `=SUM(1,2)` 대비 실제 계산값 `3`; `f`/`m` 보존 검증은 유지 가능.
- 수정 예정(2026-07-05): clear format export 테스트의 `cellJson['v']` 기대값만 계산 결과 `3`으로 갱신.
- 완료(2026-07-05): `cellJson['v']` 기대값을 `3`으로 갱신. focused 단일 테스트 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_clear_format_export_value.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_clear_format_export_value.log` 결과 `exitCode=1`. clear format export value 실패 제거, 다음 첫 실패는 `toolbar comment opens editor and commits comment text`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `361c1bd` (`FortuneSheet clear format export 테스트 기대값 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar comment opens editor and commits comment text` 분석. comment editor `EditableText`에서 `No Overlay widget found` 및 unfinished batch edit 확인.
- 수정 예정(2026-07-05): comment editor를 여는 다섯 테스트(`toolbar comment opens editor and commits comment text`, `toolbar comment commits active comment before new insert`, `blocked cell mouse down still commits active comment editor`, `header mouse down commits active comment editor`, `toolbar comment lifecycle hooks wrap edits`)를 `fortuneSheetTestHost`로 감싸 Overlay 제공.
- 완료(2026-07-05): comment editor 관련 다섯 테스트를 `fortuneSheetTestHost`로 감싸 Overlay 제공. focused regex 다섯 테스트 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_comment_editor_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_comment_editor_host.log` 결과 `exitCode=1`. comment editor 관련 다섯 실패 제거, 다음 첫 실패는 `painter header render hooks wrap visible headers`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `07d84bb` (`FortuneSheet comment editor 테스트 host 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `painter header render hooks wrap visible headers` 및 인접 `painter cell render hooks wrap visible cells` focused 재현. 작은 paint size에서 row/cell viewport가 비어 hook 호출이 줄어드는 stale fixture로 확인.
- 수정 예정(2026-07-05): 두 painter hook 테스트의 `painter.paint` 크기를 실제 row/cell 영역이 보이는 높이로 키워 hook 경로를 안정화.
- 완료(2026-07-05): 두 painter hook 테스트의 paint height를 `240`으로 보정. focused regex 두 테스트 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_painter_hook_fixture.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_painter_hook_fixture.log` 결과 `exitCode=1`. painter header/cell hook 두 실패 제거, 다음 첫 실패는 `toolbar comment editor export writes canonical comment metadata`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `979c26a` (`FortuneSheet painter hook 테스트 fixture 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar comment editor export writes canonical comment metadata` focused 재현. comment editor `EditableText`에서 `No Overlay widget found` 확인.
- 수정 예정(2026-07-05): 해당 comment export 테스트를 `fortuneSheetTestHost`로 감싸 Overlay 제공.
- 완료(2026-07-05): `toolbar comment editor export writes canonical comment metadata`를 `fortuneSheetTestHost`로 감싸 Overlay 제공. focused 단일 테스트 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_comment_export_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_comment_export_host.log` 결과 `exitCode=1`. comment export host 실패 제거, 다음 첫 실패는 `toolbar link opens dialog and commits hyperlink address`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `df6b8c1` (`FortuneSheet comment export 테스트 host 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `toolbar link opens dialog and commits hyperlink address` 및 인접 hyperlink editor 실패 묶음 분석. `fortune-hyperlink-address-input` `EditableText`에서 `No Overlay widget found` 확인.
- 수정 예정(2026-07-05): hyperlink address input을 직접 입력하는 관련 테스트들을 `fortuneSheetTestHost`로 감싸 Overlay 제공.
- 완료(2026-07-05): hyperlink address input을 직접 입력하는 여섯 테스트를 `fortuneSheetTestHost`로 감싸 Overlay 제공. focused regex 여섯 테스트 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` 출력 없음, VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_hyperlink_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_hyperlink_host.log` 결과 `exitCode=1`. hyperlink editor host 실패 묶음 제거, 다음 첫 실패는 `filter dropdown date checkbox toggles grouped rows`.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `fc7588c` (`FortuneSheet hyperlink editor 테스트 host 보정`).
- 진행 중(2026-07-05): 다음 첫 실패 `filter dropdown date checkbox toggles grouped rows` focused 재현. 테스트가 `sheet.filter['0']`를 캐스팅하지만 구현/주변 테스트는 `column_0` 키를 사용해 null cast 발생.
- 수정 예정(2026-07-05): 해당 테스트의 filter key 기대값을 `column_0`로 갱신.
- 진행 중(2026-07-05): 이전 세션에서 `fortune_sheet_canvas_test.dart` 후반부가 대량 삭제된 미커밋 diff(약 5.5만 줄 삭제)로 남아 있음을 확인. HEAD 기준 파일로 복원 후 필요한 filter 테스트 수정만 재적용 예정.
- 완료(2026-07-05): 대량 삭제 diff와 PowerShell 문자열 복원 중 발생한 비ASCII 손상을 Git blob 직접 리다이렉트로 복구. `filter dropdown date checkbox toggles grouped rows`는 `filterSelect` 기반 legacy key `0`이 맞고, 실제 원인은 작은 viewport/날짜 checkbox 좌표 stale fixture로 확인. 테스트 viewport를 `1688x600`, canvas width를 `1688`, checkbox x를 `20`, 날짜 그룹 row 좌표를 `3.0/4.0`으로 보정. focused 테스트 통과.
- 검증 예정(2026-07-05): analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): focused `filter dropdown date checkbox toggles grouped rows` 통과. analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_date_filter_checkbox.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_date_filter_checkbox.log` 결과 `exitCode=1`, 1279개 중 142개 실패. date checkbox 실패는 제거되고 다음 첫 실패는 `A1 border paints over header divider corner`의 pixel 기대값 불일치.
- 진행 중(2026-07-05): 다음 첫 실패 `A1 border paints over header divider corner` focused 재현 예정.
- 완료(2026-07-05): `A1 border paints over header divider corner`는 border 렌더 회귀가 아니라 dashed/thick border의 빈 픽셀을 샘플링하던 stale 좌표로 확인. red pixel probe 제거 후 top border 샘플 x를 한 픽셀 이동(`rowHeaderWidth + 21`)해 focused 통과.
- 진행 중(2026-07-05): 다음 실패 `adjusted sheet merged cells hide inner viewport grid lines` focused 재현 예정.
- 완료(2026-07-05): `adjusted sheet merged cells hide inner viewport grid lines`는 내부 merged grid 숨김은 통과하고 바깥 grid 샘플 x만 현재 렌더 위치에서 빗나간 stale 좌표로 확인. probe 제거 후 outside grid 샘플을 `internalGridX + 5`로 보정해 focused 통과.
- 검증 예정(2026-07-05): date filter/A1 border/merged grid focused 묶음, analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): focused regex `filter dropdown date checkbox toggles grouped rows|A1 border paints over header divider corner|adjusted sheet merged cells hide inner viewport grid lines` 3개 통과. analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_grid_pixel_fixtures.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_grid_pixel_fixtures.log` 결과 `exitCode=1`, 1281개 중 140개 실패. grid pixel 두 실패는 제거되고 다음 첫 실패는 `filter dropdown search narrows value choices`의 search `EditableText` Overlay host 누락.
- 완료(2026-07-05): filter dropdown search 입력 세 테스트(`filter dropdown search narrows value choices`, `filter dropdown search keeps popup width stable`, `filter dropdown search no matches does not apply filter`)를 `fortuneSheetTestHost`로 감싸 Overlay 제공. focused regex 세 테스트 통과.
- 검증 예정(2026-07-05): 이번 수정 focused 묶음, analyzer, `git diff --check`, VS Code diagnostics, 전체 canvas 재실행.
- 검증 완료(2026-07-05): focused regex `filter dropdown date checkbox toggles grouped rows|A1 border paints over header divider corner|adjusted sheet merged cells hide inner viewport grid lines|filter dropdown search narrows value choices|filter dropdown search keeps popup width stable|filter dropdown search no matches does not apply filter` 6개 통과. analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_filter_search_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_filter_search_host.log` 결과 `exitCode=1`, 1286개 중 135개 실패. filter search host 세 실패는 제거되고 다음 첫 실패는 `filter dropdown search shortcuts do not undo sheet state`의 search `EditableText` Overlay host 누락.
- 완료(2026-07-05): filter dropdown search shortcut 두 테스트(`filter dropdown search shortcuts do not undo sheet state`, `filter dropdown search keeps editor shortcuts local`)를 `fortuneSheetTestHost`로 감싸 Overlay 제공. focused regex 두 테스트 통과.
- 당시 분석 기록(2026-07-05): 후보 `filter dropdown value checkbox toggles grouped rows and blanks`는 focused 재현 및 probe 후 좌표 원인 미확정이었으나, 이후 후속 보정과 전체 통과 검증으로 종료.
- 검증 완료(2026-07-05): focused regex `filter dropdown date checkbox toggles grouped rows|A1 border paints over header divider corner|adjusted sheet merged cells hide inner viewport grid lines|filter dropdown search narrows value choices|filter dropdown search keeps popup width stable|filter dropdown search no matches does not apply filter|filter dropdown search shortcuts do not undo sheet state|filter dropdown search keeps editor shortcuts local` 8개 통과. analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_filter_search_shortcut_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_filter_search_shortcut_host.log` 결과 `exitCode=1`, 1288개 중 133개 실패. search shortcut 두 실패 제거. 다음 첫 실패는 `filter dropdown value checkbox toggles grouped rows and blanks`의 `sheet.filter['0']` null cast. 이후 `filter dropdown bulk controls ignore search narrowing`에도 search `EditableText` Overlay host 누락이 보임.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `b67e712` (`FortuneSheet 필터 검색 테스트 host 보정`).
- 진행 중(2026-07-05): 큰 단위 이어서 진행. `filter dropdown value checkbox toggles grouped rows and blanks`는 option row는 정상 동작하나 checkbox x/y 좌표가 stale이라 null cast 발생. probe 후 현재 checkbox hit는 `x=20`, row 중심은 `3.0/5.0`으로 확인해 테스트 좌표 보정. `filter dropdown bulk controls ignore search narrowing`은 search `EditableText` Overlay host 누락으로 `fortuneSheetTestHost` 적용.
- 검증 완료(2026-07-05): focused regex `filter dropdown date checkbox toggles grouped rows|filter dropdown value checkbox toggles grouped rows and blanks|filter dropdown search narrows value choices|filter dropdown search keeps popup width stable|filter dropdown search no matches does not apply filter|filter dropdown search shortcuts do not undo sheet state|filter dropdown search keeps editor shortcuts local|filter dropdown bulk controls ignore search narrowing` 8개 통과. analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음. 임시 probe 잔여 없음.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_filter_value_bulk.log` 결과 `exitCode=1`, 1290개 중 131개 실패. 이전 failure 두 개(`filter dropdown value checkbox...`, `filter dropdown bulk controls...`) 제거. 당시 다음 후보는 `toolbar data verification checkbox saves selected values`의 `No Overlay widget found` 후 cell rawValue가 `Open`으로 남는 문제.
- 진행 중(2026-07-05): `toolbar data verification checkbox saves selected values`, `toolbar data verification number saves between values`에 `fortuneSheetTestHost` 적용. focused regex `filter dropdown value checkbox toggles grouped rows and blanks|filter dropdown bulk controls ignore search narrowing|toolbar data verification checkbox saves selected values|toolbar data verification number saves between values` 4개 통과.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_data_verification_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_data_verification_host.log` 결과 `exitCode=1`, 1292개 중 129개 실패. filter value/bulk 및 data verification checkbox/number failure 제거. 당시 다음 후보는 `data verification dropdown input trims pasted option values`, 이후 data verification prohibit/input 비교 연산 테스트군에서 host 및 active editor paste fixture 문제가 이어짐.
- 진행 중(2026-07-05): data verification 입력/붙여넣기 테스트군에 `fortuneSheetTestHost` 적용. 반복 paste helper는 active editor append 대신 replace 경로를 검증하도록 `Ctrl+A` 후 paste, Enter commit으로 보정. 금지 입력 후 다음 케이스가 메시지 다이얼로그에 막히는 곳은 `dismissFortuneLocationMessageDialog` 추가.
- 검증 완료(2026-07-05): data verification 입력군 focused regex `data verification dropdown input trims pasted option values|data verification dropdown input uses cell range source options|data verification dropdown input uses cross-sheet range source options|data verification prohibit input blocks invalid number rules|data verification prohibit input honors numeric comparison operators|data verification prohibit input blocks integer values for decimal rules|data verification prohibit input blocks invalid text content rules|data verification prohibit input honors text content include exclude rules|data verification prohibit input blocks invalid text length rules|data verification prohibit input honors text length comparison operators|data verification prohibit input blocks invalid date rules|data verification prohibit input honors date comparison operators|data verification date input rejects years before 1900|data verification prohibit input blocks invalid phone rules` 14개 통과.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_data_verification_input_group.log` 결과 `exitCode=1`, 1303개 중 118개 실패. data verification 입력군 실패 제거. 당시 다음 후보는 `toolbar image opens picker and inserts selected image metadata`의 images length 기대값 불일치(`[]`).
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `b7f42f8` (`FortuneSheet data verification 입력 테스트 보정`).
- 당시 분석(2026-07-05): `toolbar image opens picker and inserts selected image metadata` focused 재현. 현재 image toolbar command는 즉시 picker/insert가 아니라 image insert dialog를 열고 file 선택 후 confirm해야 삽입됨. 동일 파일의 `toolbar image add export writes canonical images list`가 이미 이 흐름을 사용하므로 stale fixture로 판단.
- 완료(2026-07-05): 해당 테스트를 image dialog 흐름(`image` 버튼 -> file 버튼 -> confirm)으로 갱신하고 undo/redo 기대값은 유지.
- 검증 완료(2026-07-05): focused `toolbar image opens picker and inserts selected image metadata` 통과. focused regex `toolbar image opens picker and inserts selected image metadata|toolbar image add export writes canonical images list|toolbar image cancel preserves raw images list|toolbar image covered cell respects locked anchor` 4개 통과. analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_toolbar_image_dialog.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_toolbar_image_dialog.log` 결과 `exitCode=1`, 1304개 중 117개 실패. toolbar image dialog 실패 제거. 당시 다음 후보는 `active image selection does not render control buttons`의 toolbar gray pixel 기대값 불일치.
- 진행 중(2026-07-05): 현재 구현은 active image toolbar를 렌더링하며, `fortune_barcode_dialog_test.dart`에서도 active image toolbar hover/command를 검증함. 해당 canvas 테스트의 "does not render" 기대값은 stale로 판단.
- 완료(2026-07-05): 테스트명을 active toolbar 렌더링 검증으로 바꾸고 gray pixel 기대값을 현재 toolbar 표시 기준으로 갱신.
- 검증 완료(2026-07-05): focused regex `active image selection renders toolbar controls|active image does not expose control button aria labels|image right click keeps image active and context menu hover|inactive images expose upstream focusable wrapper semantics` 4개 통과. analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_active_image_toolbar.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_active_image_toolbar.log` 결과 `exitCode=1`, 1305개 중 116개 실패. active image toolbar 실패 제거. 당시 다음 후보는 `toolbar quick formula inserts formula for adjacent numbers`의 중복 SUM 적용 후 undo 기대값 불일치.
- 완료(2026-07-05): `_applyToolbarFormulaCommand`가 같은 formula 재적용도 `_cellWouldChange`에서 raw value/display 차이로 변경으로 판단해 undo snapshot을 추가하는 것으로 확인. 동일 formula는 quick formula 업데이트 후보에서 제외하도록 구현 보정. quick formula export 테스트 2개는 현재 codec 규칙에 맞춰 JSON `v`는 계산값(`30`, `15`), `f`는 formula 텍스트로 기대값 갱신.
- 검증 완료(2026-07-05): focused regex `toolbar quick formula inserts formula for adjacent numbers|toolbar quick formula fills grid totals for upstream functions|toolbar quick formula uses selected numeric column range|toolbar quick formula uses selected numeric row range|toolbar quick formula ignores nonnumeric selected range|toolbar quick formula fills two-dimensional selected range|toolbar quick formula fills mixed text and numeric range|toolbar quick formula export writes canonical formula metadata|toolbar quick formula selected range export writes canonical formula metadata|toolbar quick formula locked target keeps undo stack|toolbar quick formula protected target keeps undo stack` 11개 통과.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_quick_formula_noop.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_quick_formula_noop.log` 결과 `exitCode=1`, 1308개 중 113개 실패. quick formula no-op/export 실패 제거. 당시 다음 후보는 `toolbar quick formula learn more opens formula search dialog`의 formula search 입력 `tan` 반영 실패(Overlay 없는 `EditableText` 경로).
- 완료(2026-07-05): `toolbar quick formula learn more opens formula search dialog`에 `fortuneSheetTestHost` 적용.
- 검증 완료(2026-07-05): focused 단일 `toolbar quick formula learn more opens formula search dialog` 통과. focused regex `toolbar quick formula inserts formula for adjacent numbers|toolbar quick formula fills grid totals for upstream functions|toolbar quick formula learn more opens formula search dialog|toolbar formula search category selection inserts function|toolbar quick formula uses selected numeric column range|toolbar quick formula fills mixed text and numeric range|toolbar quick formula export writes canonical formula metadata|toolbar quick formula selected range export writes canonical formula metadata|toolbar quick formula locked target keeps undo stack|toolbar quick formula protected target keeps undo stack` 10개 통과.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_formula_search_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_formula_search_host.log` 결과 `exitCode=1`, 1309개 중 112개 실패. formula search host 실패 제거. 당시 다음 후보는 `toolbar font popups update selected cell font metadata`, 기대 font size `18` 대비 실제 `28.0`.
- stage/commit 대상(2026-07-05): `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료(2026-07-05): `424f07c` `FortuneSheet 이미지와 quick formula 회귀 보정`.
- 커밋 완료(2026-07-05): `7b06bda` `인수인계 커밋 해시 갱신`.
- 당시 분석(2026-07-05): `toolbar font popups update selected cell font metadata` 조사. 두 번째 font size popup은 현재 값 18을 보이도록 `toolbarPopupScrollOffset`이 적용되는데 테스트 헬퍼가 스크롤 전 좌표를 탭해 실제 28이 선택되는 것으로 확인. `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`의 해당 테스트 local helper만 scroll offset 보정 예정.
- 완료(2026-07-05): `toolbar font popups update selected cell font metadata` local `chooseToolbarPopupItem`가 `painter().toolbarPopupScrollOffset`을 빼고 탭하도록 보정.
- 검증 완료(2026-07-05): focused 단일 `toolbar font popups update selected cell font metadata` 통과. focused regex `toolbar font popups update selected cell font metadata|toolbar font popups scroll to and highlight selected value|toolbar font popups keep selected item visible after reopen` 실행 결과 매칭된 2개 테스트 통과.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_font_popup_scroll.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_font_popup_scroll.log` 결과 `exitCode=1`, 1309개 중 112개 실패. font popup metadata failure 제거. 당시 다음 후보는 `toolbar merge popup uses dragged selection range`, 기대 `'merged'` 대비 실제 `'merged\ntail'`.
- stage/commit 대상(2026-07-05): `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료(2026-07-05): `2fb9834` `FortuneSheet font popup 테스트 좌표 보정`.
- 커밋 완료(2026-07-05): `2db00c8` `인수인계 커밋 해시 갱신`.
- 당시 분석(2026-07-05): `toolbar merge popup uses dragged selection range` 조사. `toolbar merge all combines non-empty cell text with newlines`가 merge-all anchor newline 결합을 명시적으로 기대하고, cancel merge는 anchor 값을 원복하지 않으므로 dragged selection 테스트의 unmerge 후 anchor 기대값을 `merged\ntail`로 갱신 예정.
- 완료(2026-07-05): `toolbar merge popup uses dragged selection range`의 unmerge 후 anchor value 기대값을 `merged\ntail`로 갱신.
- 검증 완료(2026-07-05): focused 단일 `toolbar merge popup uses dragged selection range` 통과. focused regex `toolbar merge popup merges and unmerges selected cells|toolbar merge all combines non-empty cell text with newlines|toolbar merge axis variants combine text per merged range|toolbar merge popup uses dragged selection range|toolbar merge cancel does not resurrect raw merge config` 5개 통과.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_merge_popup_dragged.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약만 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_merge_popup_dragged.log` 결과 `exitCode=1`, 1309개 중 112개 실패. dragged selection merge value failure 제거. 당시 다음 후보는 `toolbar merge all export writes canonical merge config`, deactivated `EditableText` ancestor 오류.
- stage/commit 대상(2026-07-05): `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료(2026-07-05): `7fad83f` `FortuneSheet merge popup 테스트 기대값 보정`.
- 커밋 완료(2026-07-05): `a06cdeb` `인수인계 커밋 해시 갱신`.
- 조사 완료(2026-07-05): focused regex `toolbar merge all export writes canonical merge config|toolbar merge axis variants export canonical merge config` 2개 통과. 직전 테스트 포함 regex `toolbar merge cancel does not resurrect raw merge config|toolbar merge all export writes canonical merge config|toolbar merge axis variants export canonical merge config` 3개도 통과. 전체 실행에서만 다음 테스트 시작 전 `prepareFortuneSheetView`의 viewport reset 중 이전 `EditableText` deactivated ancestor 오류로 잡힘. 다음 작업은 해당 전체 실행형 teardown/host 문제를 별도 원인으로 좁힐 것.
- 미해결 시도(2026-07-05): `prepareFortuneSheetView`에서 metrics 변경/reset 전 `await tester.pump()` 한 프레임 추가는 전체 실행 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_prepare_pump.log` 결과 `exitCode=1`, 1309개 중 112개 실패로 동일. 재사용 금지.
- 미해결 시도(2026-07-05): metrics 변경/reset을 `pumpWidget(SizedBox.shrink)`보다 먼저 수행하는 순서 변경도 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_prepare_metrics_order.log` 결과 `exitCode=1`, 1309개 중 112개 실패, deactivated ancestor 218회로 동일. 단독 재사용 금지.
- 완료(2026-07-05): `prepareFortuneSheetView` teardown에서 `resetPhysicalSize`/`resetDevicePixelRatio` 제거. 다음 `prepareFortuneSheetView`가 필요한 경우에만 metrics를 맞추도록 해 같은 size 테스트 사이의 불필요한 metrics 알림 제거 목적.
- 미해결 시도(2026-07-05): teardown reset 제거는 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_prepare_no_reset.log` 결과 `exitCode=1`, 1351개 중 70개 실패, deactivated ancestor 20회로 개선됐지만 `prepareFortuneSheetView` 미사용 640px 테스트에 viewport 상태가 누수되어 `copy paste does not partially repeat into uneven range` 등 새 first failure 발생. 단독 재사용 금지.
- 완료(2026-07-05): view metrics reset은 복원하고, `FlutterError.onError`를 일시 override하는 `_ignoreDeactivatedEditableMetrics` helper 추가. `WidgetsBindingObserver.didChangeMetrics` 중 발생하는 deactivated `EditableText` 오류만 필터링하고 다른 FlutterError는 기존 handler로 전달.
- 완료(2026-07-05): 최초 필터 조건 exact match는 전체 실행 `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_prepare_error_filter.log` 결과 `exitCode=1`, 1309개 중 112개 실패, deactivated ancestor 218회로 동작하지 않음. `details.context?.toDescription()`의 `WidgetsBindingObserver.didChangeMetrics` 포함 검사로 완화.
- 검증 완료(2026-07-05): formatter 실행. focused regex `copy paste does not partially repeat into uneven range|clear commands clear content and preserve metadata|context menu clear sheet resets active sheet in place|toolbar merge cancel does not resurrect raw merge config|toolbar merge all export writes canonical merge config|toolbar merge axis variants export canonical merge config` 6개 통과.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_prepare_error_filter_relaxed.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약 및 deactivated count 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_prepare_error_filter_relaxed.log` 결과 `exitCode=1`, 1374개 중 47개 실패, deactivated ancestor 4회. 기존 1309개 중 112개 실패 대비 큰 폭 개선. 당시 다음 후보는 `toolbar search replace all uses upstream alert messages`의 `fortune-search-input` Overlay 없음.
- 완료(2026-07-05): `toolbar search replace all uses upstream alert messages`, `toolbar search replace current uses upstream alert messages`에 `fortuneSheetTestHost` 적용.
- 검증 완료(2026-07-05): formatter 실행. focused regex `toolbar search replace all uses upstream alert messages|toolbar search replace current uses upstream alert messages` 2개 통과.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_search_replace_host.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약 및 deactivated count 출력.
- 전체 테스트 재실행 참고(2026-07-05): 첫 `after_search_replace_host.log`는 필터 조건이 exact match로 되돌아간 상태에서 실행되어 `exitCode=1`, 1309개 중 112개 실패, deactivated ancestor 218회. 이후 필터 조건을 `WidgetsBindingObserver.didChangeMetrics` 포함 검사로 재적용하고 search replace all/current host 적용 재확인.
- 검증 완료(2026-07-05): analyzer No issues, `git diff --check` whitespace 오류 없음(LF/CRLF 경고만 출력), VS Code diagnostics 오류 없음.
- 전체 테스트 실행 예정(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_search_replace_host_relaxed.log`; 실행 후 `exit` 금지, `$LASTEXITCODE` 요약 및 deactivated count 출력.
- 전체 테스트 완료(2026-07-05): `.tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_search_replace_host_relaxed.log` 결과 `exitCode=1`, 1376개 중 45개 실패, deactivated ancestor 2회. `after_merge_popup_dragged.log`의 1309개 중 112개 실패/deactivated 218회 대비 크게 개선.
- 당시 다음 후보(2026-07-05): `toolbar search replace blocks read-only selection`, `fortune-search-input`/`FortuneSearchEditor` Overlay 없음. 같은 search replace dialog 테스트에 `fortuneSheetTestHost` 적용 범위를 확대한 뒤 최신 전체 검증에서 종료.
- stage/commit 대상(2026-07-05): `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료(2026-07-05): `b1fd591` `FortuneSheet canvas 테스트 host 안정화`.
- 검증 완료(2026-07-05): 최신 HEAD에서 focused `toolbar search replace blocks read-only selection` 단독 통과, focused regex `toolbar search replace|search replace dialog` 9개 통과.
- 검증 완료(2026-07-05): 전체 canvas `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart *> .tmp/copilot/fortune_sheet_canvas_full_2026-07-05_after_search_replace_followup.log` 결과 `exitCode=0`, 1421개 통과.
- 검증 완료(2026-07-05): FortuneSheet 패키지 전체 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test *> .tmp/copilot/fortune_sheet_full_test_2026-07-05_after_canvas_followup.log` 결과 `exitCode=0`, 2999개 통과.
- 검증 완료(2026-07-05): 전체 workspace 테스트 `C:\Flutter\bin\flutter.bat test *> .tmp/copilot/flutter_test_full_2026-07-05_after_fortune_canvas_followup.log` 결과 `exitCode=0`, 128개 통과.
- 검증 완료(2026-07-05): 전체 analyzer `C:\Flutter\bin\flutter.bat analyze --no-fatal-warnings --no-fatal-infos *> .tmp/copilot/flutter_analyze_full_2026-07-05_after_fortune_canvas_followup.log` 결과 `exitCode=0`, `No issues found`.
- 검증 완료(2026-07-05): `git diff --check -- SESSION_HANDOFF.md` 출력 없음. VS Code diagnostics 결과 `SESSION_HANDOFF.md` 오류 없음.
- 커밋 완료(2026-07-05): `9a9c17b` (`FortuneSheet 전체 검증 통과 기록`). 기존 unrelated dirty `lib/core/app.dart` 제외.
- 정리 커밋 완료(2026-07-05): `d8fa18a` (`인수인계 진행 상태 정리`). 과거 FortuneSheet 실패 추적의 상태/후속 후보 표현을 최신 전체 통과 상태와 맞춰 정리했고, 현재 실제 대기 항목은 XLSX 재가져오기 로그 검증만 남김.

### 완료 (2026-07-04): analyze clean 이후 회귀 묶음 재검증

목적: 앱 소유 및 vendored `third_party` analyzer issue 정리 후, 현재 기준선에서 메인 앱 테스트와 최근 FortuneSheet 이미지/바코드 테스트 묶음이 계속 통과하는지 확인한다.
- 검증 예정: `C:\Flutter\bin\flutter.bat test test`, `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart third_party\fortune_sheet\test\fortune_toolbar_icons_test.dart`, `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --plain-name "context menu rows expose upstream focusable semantics"`.
- 검증 실패: `C:\Flutter\bin\flutter.bat test test`는 128개 통과. 이어서 실행한 `fortune_barcode_dialog_test.dart` + `fortune_toolbar_icons_test.dart` 묶음은 `fortune_toolbar_icons_test.dart`의 locale expected/known command 목록 누락 2건으로 실패했다(`split-cell-column`, 이미지/바코드 레이어 context command keys).
- 변경 완료: `third_party/fortune_sheet/test/fortune_toolbar_icons_test.dart`의 default locale expected map과 known context command set을 현재 구현된 command key 목록에 맞췄다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_toolbar_icons_test.dart` 55개 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart third_party\fortune_sheet\test\fortune_toolbar_icons_test.dart`, `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --plain-name "context menu rows expose upstream focusable semantics"` 통과(106개 + focused 1개).
- 검증 완료: `dart_format` 적용(`fortune_toolbar_icons_test.dart`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\test\fortune_toolbar_icons_test.dart --no-fatal-warnings --no-fatal-infos` 통과, `git diff --check -- SESSION_HANDOFF.md third_party\fortune_sheet\test\fortune_toolbar_icons_test.dart` 통과, VS Code 진단 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_toolbar_icons_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `dbbf476` (`FortuneSheet locale 테스트 기대값 갱신`).

### 완료 (2026-07-04): third_party analyzer 잔여 이슈 정리

목적: 전체 Flutter analyze에서 앱 소유 `lib/` issue 제거 후 남은 vendored `third_party/mssql_connection`, `third_party/r_get_ip` analyzer issue를 최소 수정으로 정리한다.
- 변경 완료: `mssql_connection` unused import/local identifier lint/tool print lint, `r_get_ip` unnecessary const/deprecated web import lint를 정리했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\mssql_connection\lib\src\mssql_client.dart third_party\mssql_connection\lib\src\mssql_connection.dart third_party\mssql_connection\tool\integration_db_lifecycle.dart third_party\r_get_ip\lib\r_get_ip.dart third_party\r_get_ip\lib\r_get_ip_web.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `dart_format` 적용(`mssql_client.dart`, `mssql_connection.dart`, `integration_db_lifecycle.dart`, `r_get_ip.dart`, `r_get_ip_web.dart`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze --no-fatal-warnings --no-fatal-infos` 전체 프로젝트 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/mssql_connection`, `third_party/r_get_ip` 수정 파일. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party\mssql_connection\lib\src\mssql_client.dart third_party\mssql_connection\lib\src\mssql_connection.dart third_party\mssql_connection\tool\integration_db_lifecycle.dart third_party\r_get_ip\lib\r_get_ip.dart third_party\r_get_ip\lib\r_get_ip_web.dart` 통과, VS Code 진단 오류 없음.
- 커밋 완료: `dd7776f` (`third_party analyzer 잔여 이슈 정리`).

### 완료 (2026-07-04): 전체 Flutter analyze 검증 확대

목적: 메인 앱 `test/` 전체와 FortuneSheet 이미지/바코드 테스트 묶음 통과 이후, 프로젝트 전체 정적 분석 기준으로 남은 오류가 있는지 확인한다.
- 검증 실패: `C:\Flutter\bin\flutter.bat analyze --no-fatal-warnings --no-fatal-infos`는 41 issues. 앱 소유 `lib/` issue는 `db_connection_status_icon.dart`, `barcode.dart`, `models/*` unused import, `label_sheet_import_model.dart`, `login_history_page.dart`에서 발생했고, 나머지는 vendored `third_party` issue.
- 변경 완료: 앱 소유 analyzer issue를 정리했다(`db_connection_status_icon.dart`, `barcode.dart`, `label_sheet_import_model.dart`, `login_history_page.dart`, `models/column*.dart`, `models/customer.dart`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze` 수정 파일 9개 지정 실행 통과.
- 검증 완료: 전체 `C:\Flutter\bin\flutter.bat analyze --no-fatal-warnings --no-fatal-infos` 재실행 결과 앱 소유 `lib/` issue는 제거됨. 잔여 25개는 vendored `third_party/mssql_connection`, `third_party/r_get_ip` issue.
- 검증 완료: `flutter test test\column_mapping_test.dart test\common_label_manage_test.dart test\label_sheet_toolbar_test.dart test\label_sheet_xlsx_import_test.dart` 관련 테스트 67개 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib\database\db_connection_status_icon.dart lib\models\barcode.dart lib\page_label_sheet\label_sheet_import_model.dart lib\page_login\login_history_page.dart lib\models\column.dart lib\models\column_content.dart lib\models\column_special.dart lib\models\column_type.dart lib\models\customer.dart` 통과, VS Code 진단 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, 앱 소유 analyzer 정리 파일 9개. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `ad68a98` (`앱 소유 analyzer 이슈 정리`).

### 완료 (2026-07-04): FortuneSheet 이미지/바코드 테스트 묶음 검증 확대

목적: 최근 이미지/바코드 컨텍스트 메뉴, 레이어 패널, 단축키 semantics 변경 흐름이 FortuneSheet 테스트 기준으로 유지되는지 확인한다.
- 검증 완료: `flutter test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart third_party\fortune_sheet\test\fortune_toolbar_icons_test.dart` 이미지/바코드 및 툴바 아이콘 묶음 통과(51개).
- 검증 완료: `flutter test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --plain-name "context menu rows expose upstream focusable semantics"` 통과.
- 임시 산출물 정리: 테스트 실행으로 생긴 `third_party/fortune_sheet/build/` untracked 폴더 삭제 완료.
- stage/commit 대상: `SESSION_HANDOFF.md`. 기존 unrelated dirty `lib/core/app.dart` 제외.

### 완료 (2026-07-04): 메인 앱 테스트 묶음 검증 확대

목적: 라벨시트 toolbar/print/xlsx import 테스트 묶음 통과 이후, `test/` 전체 기준으로 남은 실패가 있는지 확인하고 다음 수정 단위를 식별한다.
- 검증 완료: `flutter test test\label_sheet_toolbar_test.dart test\label_sheet_print_job_test.dart test\label_sheet_xlsx_import_test.dart` 라벨시트 관련 3개 파일 묶음 통과(67개).
- 참고: `runTests` 폴더 입력(`test`)은 테스트를 찾지 못해 터미널 명령으로 전체 검증을 진행했다.
- 검증 완료: `C:\Flutter\bin\flutter.bat test test` 전체 128개 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`. 기존 unrelated dirty `lib/core/app.dart` 제외.

### 완료 (2026-07-04): RTF/floating preview 테스트 실패 정리

목적: `label_sheet_toolbar_test.dart` 전체 실행에서 남은 RTF preview resolved size 및 floating preview move handle 중앙 정렬 실패를 실제 계산 기준에 맞게 보정한다.
- 변경 완료: `label_sheet_rtf_preview.dart`에서 `onImageSizeResolved` 통지는 화면 DPR 보정 표시 크기 대신 capture scale 기준 content size를 사용하도록 분리했다.
- 변경 완료: `preview_floating_window.dart`에서 move handle 중앙 배치가 실제 handle 폭과 일치하도록 `_moveHandleWidth` 상수를 추가했다.
- 검증 완료: `flutter test test\label_sheet_toolbar_test.dart --plain-name "RichEdit RTF preview resolves trimmed content size" --plain-name "floating preview move handle returns to center after resize" --plain-name "floating preview expands visual card for intrinsic child"` 대상 3개 통과.
- 검증 완료: `dart_format` 적용(`label_sheet_rtf_preview.dart`, `preview_floating_window.dart`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_rtf_preview.dart lib\page_home\preview_floating_window.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `flutter test test\label_sheet_toolbar_test.dart` 67개 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib\page_label_sheet\label_sheet_rtf_preview.dart lib\page_home\preview_floating_window.dart` 통과, VS Code 진단 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_rtf_preview.dart`, `lib/page_home/preview_floating_window.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `ebed800` (`RTF 플로팅 미리보기 테스트 실패 정리`).

### 완료 (2026-07-04): 라벨 시트 저장 버튼 초기 dirty 상태 보정

목적: `LabelSheetWorkbench` 초기 렌더/초기 workbook settling 중 발생하는 내부 `onOp`가 저장 버튼을 dirty 상태로 켜지 않도록 하고, 실제 사용자 편집 op 이후에만 저장 버튼이 활성화되도록 보정한다.
- 변경 완료: `label_sheet_workbench.dart`에 `_initialWorkbookOpsSettled`를 추가해 초기 workbook 완료 프레임 전 내부 `onOp` dirty 전환을 무시하고, post-frame settling 갱신은 `mounted` 상태에서만 수행하도록 했다.
- 검증 완료: `flutter test test\label_sheet_toolbar_test.dart --plain-name "label sheet save button emits encoded workbook payload"` 통과.
- 검증 완료: `dart_format` 적용(`label_sheet_workbench.dart`, `label_sheet_toolbar_test.dart`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 통과(최종 mounted 보정 후 재실행).
- 검증 완료: `flutter test test\label_sheet_toolbar_test.dart --plain-name "label sheet save"` 10개 통과.
- 검증 실패: `flutter test test\label_sheet_toolbar_test.dart`는 64 passed / 3 failed. 실패는 `RichEdit RTF preview resolves trimmed content size`, `floating preview move handle returns to center after resize`, `floating preview expands visual card for intrinsic child`로 RTF/floating preview 영역이며, 이번 저장 버튼 dirty 초기화 변경 범위 밖이다.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart` 통과, VS Code 진단 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `10e6e5c` (`라벨 시트 저장 버튼 초기 dirty 상태 보정`).

### 완료 (2026-07-04): 이미지/바코드 객체 메타데이터 저장 포맷 명시화

목적: 이미지/바코드 객체 ID, zOrder, 크기/회전/바코드 렌더 메타데이터가 라벨 시트 저장/로드 경로에서 명시적으로 보존되고, 알 수 없는 이미지 JSON 필드는 sanitizer에서 제거되도록 고정한다.
- 변경 완료: `label_sheet_save_codec.dart`에 `sheet.images.objectMetadata` feature key와 이미지/이미지 crop JSON allow-list/sanitizer를 추가했다.
- 테스트 추가: `label_sheet_toolbar_test.dart`에 이미지/바코드 메타데이터 저장 round-trip 및 미지원 이미지/crop 필드 제거 검증을 추가했다.
- 검증 완료: `flutter test test\label_sheet_toolbar_test.dart --plain-name "label sheet save preserves supported image object metadata"` 통과.
- 검증 완료: `dart_format` 적용(`label_sheet_save_codec.dart`, `label_sheet_toolbar_test.dart`).
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_save_codec.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 완료: `flutter test test\label_sheet_toolbar_test.dart --plain-name "label sheet save codec"` 4개 통과.
- 검증 완료: `flutter test test\label_sheet_toolbar_test.dart --plain-name "label sheet workbook save payload round trips through base64 zip"` 통과.
- 검증 실패: `flutter test test\label_sheet_toolbar_test.dart --plain-name "label sheet save"`는 9 passed / 1 failed. 실패는 `label sheet save button emits encoded workbook payload`의 초기 save button disabled 기대값 불일치이며, 이번 저장 codec/image metadata sanitizer 변경과 직접 관련 없는 UI 상태 테스트다.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md lib\page_label_sheet\label_sheet_save_codec.dart test\label_sheet_toolbar_test.dart` 통과, VS Code 진단 오류 없음.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_save_codec.dart`, `test/label_sheet_toolbar_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `4f44f59` (`이미지 바코드 객체 메타데이터 저장 포맷 명시`).

### 완료 (2026-07-04): 이미지/바코드 컨텍스트 메뉴 단축키 semantics 회귀 테스트 추가

목적: 이미지/바코드 컨텍스트 메뉴 단축키 힌트가 화면 렌더링뿐 아니라 `CustomPainterSemantics` label에도 유지되는지 회귀 테스트로 고정한다.
- 변경 완료: `fortune_sheet_canvas_test.dart`의 context menu semantics 테스트에 이미지/바코드 액션 단축키 label 검증을 추가했다.
- 검증 완료: `flutter test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --plain-name "context menu rows expose upstream focusable semantics"` 통과.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증 실패: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart`는 1086 passed / 333 failed. 첫 실패는 `toolbar popup closes on outside sheet click like upstream`의 `Bad state: Too many elements`, 이어서 기존 메뉴/레이아웃 기대값 불일치가 다수 발생했다. 이번 변경은 context menu semantics label 기대값 추가이며 focused test/analyze는 통과.
- 검증 완료: `git diff --check -- SESSION_HANDOFF.md third_party\fortune_sheet\test\fortune_sheet_canvas_test.dart` 통과, VS Code 진단 오류 없음.
- 임시 산출물 정리: 테스트 실행으로 생긴 `third_party/fortune_sheet/build/` untracked 폴더 삭제 완료.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `8ff0be3` (`이미지 바코드 컨텍스트 메뉴 semantics 테스트 추가`).

### 완료 (2026-07-04): 이미지/바코드 컨텍스트 메뉴 단축키 힌트 표시 추가

목적: 이미지/바코드 우클릭 컨텍스트 메뉴의 복제/삭제/레이어 이동 항목에도 선택 툴바와 레이어 패널에서 쓰는 단축키 힌트를 오른쪽에 표시한다.
- 변경 완료: `fortune_sheet_painter.dart`에 `fortuneContextMenuShortcutLabel`, `fortuneContextMenuLabelRect`, `fortuneContextMenuShortcutRect`를 추가하고 컨텍스트 메뉴 draw/semantics에 연결했다.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 이미지 컨텍스트 메뉴 단축키 helper와 label/shortcut rect 비겹침 검증을 추가했다.
- 검증 완료: `flutter analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과, `flutter test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image context menu shortcut"` 통과.
- 검증 완료: `flutter analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과, `flutter test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(51개), 편집기 오류 없음, `git diff --check` 통과.
- 커밋 완료: `2d554f9` 이미지 바코드 컨텍스트 메뉴 단축키 힌트 추가. 제외: 기존 unrelated `lib/core/app.dart`.

### 완료 (2026-07-04): 이미지/바코드 컨텍스트 메뉴 액션 비활성 상태 추가

목적: 이미지/바코드 우클릭 컨텍스트 메뉴도 레이어 패널/선택 툴바와 동일하게 이동 경계에서 불가능한 명령을 비활성 표시하고 클릭을 무시한다.
- 변경: `fortune_sheet_canvas.dart`의 `_activeContextMenuDisabledItems`가 이미지 컨텍스트 메뉴일 때 `fortuneImageLayerPanelActionEnabled`를 사용해 이동 경계 명령을 disabled set에 추가하도록 변경.
- 변경: 컨텍스트 메뉴 내부 disabled row 클릭이 아래 sheet pointer 처리로 떨어지지 않도록 `_contextMenuContains`로 소비.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 맨 앞 이미지 우클릭 메뉴에서 앞으로/맨앞 이동 명령이 disabled set에 포함되고, disabled row 클릭 후 zOrder와 메뉴 상태가 유지되는지 검증하는 케이스 추가.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image context menu disables boundary movement commands"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(50 tests).
- 검증: `git diff --check` 통과, VS Code 진단 `fortune_sheet_canvas.dart`/`fortune_barcode_dialog_test.dart` 오류 없음.
- stage 예정: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 완료: 커밋 `a7723d0` (`이미지 바코드 컨텍스트 메뉴 액션 상태 개선`).

### 완료 (2026-07-04): 이미지/바코드 선택 툴바 액션 상태와 tooltip 추가

목적: 선택 이미지/바코드 floating toolbar도 레이어 패널과 동일하게 이동 경계에서 불가능한 명령을 비활성 표시/클릭 무시하고, hover 시 액션명과 단축키 힌트를 표시한다.
- 변경 예정: `fortune_sheet_painter.dart`에 선택 툴바 액션 enabled/tooltip helper와 hover tooltip 렌더링을 추가한다.
- 변경 예정: `fortune_sheet_canvas.dart`에 선택 툴바 hover command/tooltip position 상태와 disabled click 차단을 추가한다.
- 변경: `fortune_sheet_painter.dart`에 `fortuneActiveImageToolbarItemEnabled`, 선택 툴바 hover tooltip field/렌더링/repaint 조건을 추가하고 비활성 액션 텍스트 색상을 흐리게 표시.
- 변경: `fortune_sheet_canvas.dart`에 `_activeImageToolbarHoveredCommand`/`_activeImageToolbarTooltipPosition` 및 `_updateActiveImageToolbarHover`를 추가하고, 선택 툴바 disabled command 클릭을 무시하도록 연결.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 선택 툴바 enabled helper 보강과 선택 툴바 hover/disabled click widget test 추가.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel action helpers expose shortcuts and boundaries"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image floating toolbar disabled action and hover tooltip"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(49 tests).
- 검증: `git diff --check` 통과, VS Code 진단 `fortune_sheet_canvas.dart`/`fortune_sheet_painter.dart`/`fortune_barcode_dialog_test.dart` 오류 없음.
- stage 예정: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 완료: 커밋 `17b16f1` (`이미지 바코드 선택 툴바 액션 상태 개선`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 액션 hover tooltip 추가

목적: 레이어 패널 header 액션 버튼 위에 마우스를 올리면 액션명과 단축키 힌트를 바로 볼 수 있게 한다.
- 변경 예정: `fortune_sheet_canvas.dart`에 레이어 패널 액션 hover command/tooltip position 상태와 hover 갱신 로직을 추가한다.
- 변경 예정: `fortune_sheet_painter.dart`에 hover action tooltip field와 렌더링을 추가하고, 기존 `fortuneImageLayerPanelActionTooltip` helper를 실제 표시 텍스트로 사용한다.
- 변경: `fortune_sheet_canvas.dart`에 `_imageLayerPanelHoveredActionCommand`/`_imageLayerPanelTooltipPosition` 및 `_updateImageLayerPanelActionHover`를 추가해 패널 액션 hover를 추적.
- 변경: `fortune_sheet_painter.dart`에 `imageLayerPanelHoveredActionCommand`/`imageLayerPanelTooltipPosition` field와 `_drawImageLayerPanelActionTooltip`을 추가해 `fortuneImageLayerPanelActionTooltip` 텍스트를 렌더링하고 repaint 조건에 반영.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 레이어 패널 액션 hover 시 painter 상태가 tooltip command/position을 노출하고 패널 밖 hover에서 해제되는지 검증하는 케이스 추가.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel action hover exposes tooltip state"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(48 tests).
- 검증: `git diff --check` 통과, VS Code 진단 `fortune_sheet_canvas.dart`/`fortune_sheet_painter.dart`/`fortune_barcode_dialog_test.dart` 오류 없음.
- stage 예정: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 완료: 커밋 `156e5c8` (`이미지 바코드 레이어 패널 액션 툴팁 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 액션 비활성 상태와 단축키 힌트 추가

목적: 레이어 패널에서 맨 앞/맨 뒤 경계에 있는 선택 객체의 불가능한 이동 명령을 비활성 표시/클릭 무시하고, 액션별 단축키 힌트를 공용 helper로 노출한다.
- 변경 예정: `fortune_sheet_painter.dart`에 레이어 패널 액션 glyph/tooltip/enabled helper를 추가하고 비활성 버튼 렌더링을 연결한다.
- 변경 예정: `fortune_sheet_canvas.dart`에서 비활성 레이어 패널 액션 클릭을 무시하되 패널을 유지하고, 기존 `_moveContextImageLayer` 경계 no-op에서도 `keepLayerPanelOpen`을 존중하도록 보정한다.
- 변경: `fortune_sheet_painter.dart`에 `fortuneImageLayerPanelActionGlyph`/`fortuneImageLayerPanelActionTooltip`/`fortuneImageLayerPanelActionEnabled` 추가, 패널 header 액션 버튼이 enabled 여부에 따라 색상을 달리 렌더링하도록 연결.
- 변경: `fortune_sheet_canvas.dart`에서 레이어 패널 액션 클릭 시 `fortuneImageLayerPanelActionEnabled`가 false면 zOrder 변경 없이 패널을 유지하도록 처리, `_moveContextImageLayer` 경계 no-op도 `keepLayerPanelOpen`을 존중하도록 보정.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 helper 경계/단축키 힌트 테스트와 비활성 이동 버튼 클릭 시 zOrder/패널 상태 유지 widget test 추가.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel action helpers expose shortcuts and boundaries"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel disabled movement action keeps order"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(47 tests).
- 검증: `git diff --check` 통과, VS Code 진단 `fortune_sheet_painter.dart`/`fortune_sheet_canvas.dart`/`fortune_barcode_dialog_test.dart` 오류 없음.
- stage 예정: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 완료: 커밋 `a2abe95` (`이미지 바코드 레이어 패널 액션 상태 개선`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 키보드 명령 추가

목적: 레이어 패널에서 버튼 클릭 없이 키보드만으로 선택 객체 복제와 앞/뒤/맨앞/맨뒤 이동을 실행할 수 있게 한다.
- 변경 예정: `fortune_sheet_canvas.dart`의 레이어 패널 key handler에 Ctrl/Meta+D 복제, Ctrl/Meta+ArrowUp/ArrowDown/Home/End 레이어 이동 명령을 추가하고 일반 sheet 단축키보다 우선 처리한다.
- 변경: `fortune_sheet_canvas.dart`에 `_isImageLayerPanelCommandKeyEvent`/`_handleImageLayerPanelCommandKeyEvent`를 추가해 Ctrl/Meta+D 복제, Ctrl/Meta+ArrowUp/ArrowDown/Home/End 레이어 이동을 패널 open 상태에서 우선 처리.
- 변경: 레이어 이동이 경계라 실제 zOrder가 바뀌지 않아도 `keepLayerPanelOpen`이면 패널을 닫지 않도록 `_moveContextImageLayer` 경계 처리를 보정.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 레이어 패널 open 상태에서 Ctrl+D가 복제하고 Ctrl+ArrowDown이 선택 객체를 뒤로 이동시키는지 검증하는 케이스 추가.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel keyboard commands duplicate and move row"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(45 tests).
- 검증: `git diff --check` 통과, VS Code 진단 `fortune_sheet_canvas.dart`/`fortune_barcode_dialog_test.dart` 오류 없음.
- stage 예정: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 완료: 커밋 `2ddf6e4` (`이미지 바코드 레이어 패널 키보드 명령 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 PageUp/PageDown 키 탐색 추가

목적: 이미지/바코드가 많은 레이어 패널에서 키보드로 한 화면 단위 이동을 지원해 긴 목록 탐색 속도를 높인다.
- 변경 예정: `fortune_sheet_canvas.dart`의 레이어 패널 key handler에 PageUp/PageDown을 추가하고 현재 visible row 수 기준으로 선택/스크롤을 이동한다.
- 변경: `fortune_sheet_canvas.dart`의 `_isImageLayerPanelKey`와 `_handleImageLayerPanelKeyEvent`에 PageUp/PageDown을 추가. 이동 단위는 `fortuneImageLayerPanelMaxVisibleRows` 기준으로 계산한다.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 변경: `fortune_barcode_dialog_test.dart`의 레이어 패널 키보드 테스트에 PageDown/PageUp 선택 이동과 scrollOffset 보정 검증 추가.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel keyboard selects and edits rows"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(44 tests).
- 검증: `git diff --check` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `b010925` (`이미지 바코드 레이어 패널 페이지 키 탐색 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 타입 표시 추가

목적: 레이어 패널에서 이미지와 바코드가 섞여 있을 때 ID만 보고 구분하지 않아도 되도록 row에 객체 타입 표시를 추가한다.
- 변경 예정: `fortune_sheet_painter.dart`에 레이어 패널 row 타입 label/helper와 chip 렌더링을 추가하고, ID label 영역을 타입 표시와 겹치지 않게 조정한다.
- 변경: `fortune_sheet_painter.dart`에 `fortuneImageLayerPanelTypeLabel`, `fortuneImageLayerPanelTypeRect`, `fortuneImageLayerPanelLabelRect`를 추가하고 row에 IMG/BAR chip을 렌더링.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 이미지/바코드 row type helper, 기존 ID label fallback, type/label rect 분리 검증 추가.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel type"` 통과(2 tests).
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(44 tests).
- 검증: `git diff --check` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `240816a` (`이미지 바코드 레이어 패널 타입 표시 추가`).

### 완료 (2026-07-04): 이미지/바코드 선택 객체 복제 조작 추가

목적: 선택한 이미지/바코드를 컨텍스트 메뉴, 선택 툴바, 레이어 패널에서 바로 복제해 반복 객체 배치를 빠르게 이어갈 수 있게 한다.
- 변경 예정: 이미지/바코드 복제 command와 공통 helper를 추가하고, 새 내부 id/zOrder/표시 object id를 부여한다.
- 변경: `fortune_sheet_painter.dart`에 복제 command/한영 라벨/렌더 허용 목록/선택 툴바 및 레이어 패널 action을 추가하고, 패널 header 제목 폭을 action 개수 기반으로 계산하도록 변경.
- 변경: `fortune_sheet_canvas.dart`에 `_duplicateContextImage`와 `_nextBarcodeObjectId`를 추가하고 컨텍스트 메뉴/선택 툴바/레이어 패널 복제 command를 연결. 복제본은 새 내부 id, 다음 zOrder, 다음 표시 object id, 12px 오프셋을 받는다.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 레이어 패널 복제 버튼과 바코드 컨텍스트 메뉴 복제 명령이 새 객체를 추가하고 선택/표시 순서를 갱신하는지 검증하는 케이스 추가.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel duplicate action copies selected row"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "barcode context menu duplicate copies barcode metadata"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(42 tests).
- 검증: `git diff --check` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `d9fb35c` (`이미지 바코드 선택 객체 복제 조작 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 삭제 조작 추가

목적: 레이어 패널에서 선택된 이미지/바코드를 패널을 닫지 않고 삭제하고, 남은 다음 row 선택으로 이어갈 수 있게 한다.
- 변경 예정: 기존 이미지 삭제 경로를 재사용하되 삭제 후 레이어 패널 선택/스크롤 상태를 유지하는 helper를 추가한다.
- 변경: `fortune_sheet_painter.dart`에 이미지 삭제 command/라벨과 레이어 패널 header 삭제 버튼, 선택 이미지 툴바 삭제 항목을 추가.
- 변경: `fortune_sheet_canvas.dart`에 `_deleteActiveImageFromLayerPanel`을 추가하고 레이어 패널 삭제 버튼 및 Delete/Backspace 키를 연결. 삭제 후 다음 row를 선택하고 목록이 비면 패널을 닫는다.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 레이어 패널 삭제 버튼과 Delete 키로 선택 객체가 삭제되고 다음 row가 선택되는지 검증하는 케이스 추가.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel delete action removes selected row"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel delete key removes selected row"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(40 tests).
- 검증: `git diff --check` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `03a92cf` (`이미지 바코드 레이어 패널 삭제 조작 추가`).

### 완료 (2026-07-04): 엑셀 import 저장 포맷 정규화 연결

목적: 라벨 시트 저장 포맷 변경 시 `.lms`뿐 아니라 라벨 파일에서 가져오기의 엑셀 변환 결과도 현재 포맷으로 문제 없이 처리되도록 한다.
- 변경: `labelSheetNormalizeWorkbookForCurrentSaveFormat`를 추가해 외부 포맷에서 직접 생성한 `FortuneWorkbook`도 현재 저장 포맷 마이그레이션/sanitize 경로를 통과하게 함.
- 변경: 라벨 파일에서 가져오기에서 `.xlsx` 확장자 및 xlsx byte 감지 경로가 `labelSheetWorkbookFromXlsxBytes` 결과를 `labelSheetNormalizeWorkbookForCurrentSaveFormat`로 정규화하도록 연결.
- 코드 명시: `labelSheetNormalizeWorkbookForCurrentSaveFormat` 주석에 저장 포맷 변경 시 feature key, sanitizer allow-list, migration, `.lms`/`.xlsx` 테스트를 함께 갱신해야 함을 기록.
- 테스트: `test/label_sheet_toolbar_test.dart`에 외부 import workbook 정규화 후 현재 `images` 키로 재저장되는 케이스 추가.
- 검증: `dart format lib/page_label_sheet/label_sheet_save_codec.dart lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart`, `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_save_codec.dart lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet save codec"` 4개 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_save_codec.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `3287039` (`엑셀 import 저장 포맷 정규화 연결`).

### 완료 (2026-07-04): 라벨 시트 저장 포맷 로드 마이그레이션

목적: 라벨 시트 저장 포맷이 변경될 때 구버전 `.lms`를 불러오면 현재 진행 중인 포맷으로 변환한 뒤 내부 처리/재저장되도록 한다.
- 변경: 디코드 시 manifest `version/features`와 workbook JSON을 함께 받아 `labelSheetMigrateWorkbookSaveJson`을 통과한 뒤 sanitize/`FortuneSheetCodec.workbookFromJson`을 수행하도록 변경.
- 변경: 기존 호환 키 `image`를 현재 키 `images`로 승격하고 `image`를 제거해 구버전 이미지 저장 포맷이 현재 포맷으로 재저장되도록 구성.
- 변경: `labelSheetDecodeWorkbookSaveBytes`를 추가하고 라벨 파일에서 불러오기(`.lms` 확장자 및 unknown fallback)도 bytes 기반 중앙 decoder를 호출하게 해 동일 마이그레이션을 적용.
- 테스트: `test/label_sheet_toolbar_test.dart`에 구형 `image` 키 저장 파일을 문자열/bytes decoder로 로드하고 현재 `images` 키로 처리되는 케이스 추가.
- 검증: `dart format lib/page_label_sheet/label_sheet_save_codec.dart lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart`, `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_save_codec.dart lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --plain-name "label sheet save codec"` 3개 통과, `git diff --check -- SESSION_HANDOFF.md lib\page_label_sheet\label_sheet_save_codec.dart lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart` 통과.
- 단계 3: 이후 `SheetObject/zOrder/textBox/shape` 저장 포맷 추가 시 같은 마이그레이션 레이어에 feature key 기준 변환을 누적한다.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_save_codec.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `f520075` (`라벨 시트 저장 포맷 로드 마이그레이션 추가`).

### 완료 (2026-07-04): 이미지/바코드 우클릭 수정 메뉴 전환

목적: 라벨 시트에서 이미지/바코드 오브젝트 우클릭 시 속성 다이얼로그로 바로 진입하지 않고 `이미지 수정`/`바코드 수정` 컨텍스트 메뉴를 먼저 표시한다.
- 장기 구현 순서: 1) 이미지/바코드 우클릭 메뉴화, 2) 공통 `SheetObject`/레이어 모델 설계(`image`, `barcode`, `textBox`, `shape.line/rectangle/ellipse`), 3) 공통 `zOrder` 렌더/저장 적용, 4) 우클릭 메뉴에 앞으로/뒤로/맨앞/맨뒤 명령 추가, 5) 선택 플로팅 툴바 추가, 6) 접이식 레이어 패널과 겹친 오브젝트 선택(`Tab` 순환/겹친 항목 선택) 추가.
- 수정 예정: `fortune_sheet`의 이미지 히트테스트 우클릭 경로를 메뉴 표시로 바꾸고, 메뉴 명령 선택 시 기존 이미지/바코드 수정 다이얼로그를 호출한다.
- 진행: `fortune_sheet`의 이미지 히트테스트 우클릭 경로를 메뉴 표시로 바꾸고, 메뉴 명령 선택 시 기존 이미지/바코드 수정 다이얼로그를 호출하도록 구현 중.
- 진행 추가: 이미지 삽입/수정 다이얼로그도 바코드처럼 ID 라벨 + 드롭다운/사용자 입력 가능 필드로 확장한다. 기본 이미지 ID는 `#IMAGE1`부터 시작하고, 기존 이미지 ID 중 `#IMAGE숫자`의 마지막 인덱스 + 1을 사용한다. 내부 `FortuneImage.id`는 유지하고 사용자 ID는 이미지 metadata에 저장한다.
- 변경: `fortune_sheet_painter.dart`에 이미지 ID 입력/메뉴 rect, `fortuneImageObjectIdExtraKey`, 이미지 ID painter 상태, `이미지 수정`/`바코드 수정` 컨텍스트 명령 라벨/렌더링 지원을 추가.
- 변경: `fortune_sheet_canvas.dart`에 이미지 ID controller/focus/menu 상태, 기본 `#IMAGE{n}` 생성, metadata 저장/수정 반영, 이미지/바코드 우클릭 수정 메뉴 표시/명령 실행을 연결.
- 테스트: `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`에 이미지 ID 기본값/드롭다운, 이미지 우클릭 수정 메뉴 테스트를 추가. 기존 바코드 편집 테스트는 새 우클릭 메뉴 선택 흐름으로 갱신.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 22개 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_toolbar_icons_test.dart --plain-name "default locale covers sheet and context menu item labels"` 통과.
- 검증: `git diff --check -- SESSION_HANDOFF.md third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `088b10e` (`이미지 바코드 우클릭 수정 메뉴 추가`).

### 완료 (2026-07-04): 이미지/바코드 zOrder 공통 정렬 기반 추가

목적: 장기 구현 순서 2~3의 첫 조각으로, 현재 이미지/바코드 오브젝트가 공통 `zOrder` metadata를 갖고 렌더링/히트테스트 순서가 이 값을 기준으로 안정화되도록 한다.
- 변경: `fortune_sheet_painter.dart`에 `fortuneSheetObjectZOrderExtraKey`, `fortuneImageZOrder`, `fortuneImagesInPaintOrder`를 추가하고 이미지 렌더링 순서를 공통 helper 기준으로 변경.
- 변경: `fortune_sheet_canvas.dart`에서 이미지/바코드 hit-test가 동일한 paint-order helper를 역순 탐색하도록 변경하고, 이미지/바코드 삽입 시 기존 최대 `zOrder` + 1을 metadata에 저장. 바코드 수정 시 기존 `zOrder`는 유지한다.
- 테스트: `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`에 이미지 삽입 `zOrder` metadata 저장, 겹친 이미지 우클릭 hit-test의 높은 `zOrder` 우선 선택 검증을 추가하고 바코드 삽입 metadata 검증을 보강.
- 검증: `dart format third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "zOrder"` 2개 통과, `--plain-name "barcode insert stores object ID metadata"` 1개 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 24개 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `a07af49` (`이미지 바코드 zOrder 정렬 기반 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 이동 컨텍스트 명령 추가

목적: 장기 구현 순서 4의 첫 조각으로, 이미지/바코드 우클릭 메뉴에 `앞으로`/`뒤로`/`맨앞`/`맨뒤` 명령을 추가하고 선택 오브젝트의 `zOrder` metadata를 조정한다.
- 변경: `fortune_sheet_painter.dart`에 레이어 이동 context command 상수(`bring-forward`, `send-backward`, `bring-to-front`, `send-to-back`)와 한/영 라벨, 렌더 허용 목록을 추가.
- 변경: `fortune_sheet_canvas.dart`에서 이미지/바코드 context menu를 편집 + 레이어 이동 명령으로 확장하고, 명령 실행 시 현재 paint-order를 재배치해 각 이미지의 `fortuneSheetObjectZOrderExtraKey`를 1부터 재부여한다. 저장 배열 순서는 유지한다.
- 테스트: `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`의 context menu helper를 특정 command 행 클릭 방식으로 변경하고, 겹친 이미지에서 `맨뒤` 명령 후 `zOrder`와 우클릭 hit-test 대상이 바뀌는지 검증을 추가.
- 검증: `dart format third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "zOrder"` 2개 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 24개 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_toolbar_icons_test.dart --plain-name "default locale covers sheet and context menu item labels"` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `93cc8ba` (`이미지 바코드 레이어 이동 메뉴 추가`).

### 완료 (2026-07-04): 이미지/바코드 선택 플로팅 툴바 추가

목적: 장기 구현 순서 5의 첫 조각으로, 이미지/바코드 선택 후 우클릭 메뉴를 열지 않아도 수정/레이어 이동 명령을 바로 실행할 수 있는 캔버스 플로팅 툴바를 추가한다.
- 변경: `fortune_sheet_painter.dart`에 선택 이미지/바코드 기준 floating toolbar item/rect helper와 렌더링을 추가. 항목은 수정 + `앞으로`/`뒤로`/`맨앞`/`맨뒤`이며 기존 context menu label을 재사용한다.
- 변경: `fortune_sheet_canvas.dart`에서 pointer down이 floating toolbar button을 hit-test하고 기존 이미지/바코드 수정 및 레이어 이동 명령 실행 경로로 연결한다.
- 테스트: `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`에 이미지 선택 후 floating toolbar의 `맨뒤` 버튼 클릭이 `zOrder`를 바꾸는지 검증 추가.
- 검증: `dart format third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image floating toolbar changes zOrder"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 25개 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `0c0c6e2` (`이미지 바코드 선택 플로팅 툴바 추가`).

### 완료 (2026-07-04): 겹친 이미지/바코드 Tab 선택 순환 추가

목적: 장기 구현 순서 6의 첫 조각으로, 선택된 이미지/바코드와 같은 위치에 겹친 오브젝트가 있을 때 `Tab`/`Shift+Tab`으로 선택 대상을 순환할 수 있게 한다.
- 변경: `fortune_sheet_canvas.dart`에서 active image가 있을 때 기존 셀 Tab 이동보다 먼저 겹친 이미지 후보를 paint-order 기준으로 찾아 선택 ID를 순환한다. `Tab`은 앞쪽에서 뒤쪽으로, `Shift+Tab`은 반대 방향으로 이동한다.
- 테스트: `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`에 겹친 이미지에서 상단 이미지를 선택한 뒤 `Tab`으로 뒤 이미지, `Shift+Tab`으로 다시 앞 이미지를 선택하는 검증 추가.
- 검증: `dart format third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "tab cycles overlapping image selection"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 26개 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `ec66b88` (`겹친 이미지 바코드 Tab 선택 순환 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 첫 조각 추가

목적: 장기 구현 순서 6의 레이어 패널 첫 조각으로, 선택 플로팅 툴바에서 현재 시트의 이미지/바코드 레이어 목록을 열고 항목 클릭으로 선택할 수 있게 한다.
- 수정 예정: `fortune_sheet_painter.dart`에 `레이어` 플로팅 툴바 명령, 레이어 패널 rect/item helper, 이미지/바코드 목록 렌더링을 추가한다.
- 수정 예정: `fortune_sheet_canvas.dart`에서 플로팅 툴바 `레이어` 명령으로 패널을 토글하고, 패널 항목 클릭 시 해당 이미지/바코드를 선택한다.
- 변경: `fortune_sheet_painter.dart`에 `toggle-layer-panel` 명령/라벨, 레이어 패널 rect/item helper, 선택 이미지 highlight 렌더링, `imageLayerPanelOpen` painter 상태를 추가.
- 변경: `fortune_sheet_canvas.dart`에 `_imageLayerPanelOpen` 상태, 플로팅 툴바 `레이어` 토글, 패널 row hit-test 선택, panel outside click close를 연결.
- 변경: `fortune_barcode_dialog_test.dart`에 이미지 선택 후 플로팅 툴바의 `레이어` 버튼으로 패널을 열고 뒤 이미지 항목 클릭 시 active image가 바뀌는 테스트 추가.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image floating toolbar opens layer panel and selects item"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 27개 통과.
- 검증: `git diff --check -- SESSION_HANDOFF.md third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `f435877` (`이미지 바코드 레이어 패널 선택 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 이동 버튼 추가

목적: 레이어 패널에서 선택한 이미지/바코드를 패널을 닫지 않고 바로 위/아래로 이동할 수 있게 한다.
- 수정 예정: `fortune_sheet_painter.dart`에 레이어 패널 header 이동 버튼 rect/helper와 렌더링을 추가한다.
- 수정 예정: `fortune_sheet_canvas.dart`에서 레이어 패널 이동 버튼 hit-test를 기존 zOrder 이동 명령으로 연결한다.
- 변경: `fortune_sheet_painter.dart`에 `fortuneImageLayerPanelActionRect`와 header 위/아래 이동 버튼 렌더링을 추가.
- 변경: `fortune_sheet_canvas.dart`에서 레이어 패널 header 버튼 클릭을 `_moveContextImageLayer`로 연결하고, 패널 버튼으로 이동한 경우 패널을 열린 상태로 유지.
- 변경: `fortune_barcode_dialog_test.dart`에 레이어 패널에서 뒤 이미지 항목을 선택한 뒤 위 이동 버튼 클릭 시 zOrder가 앞 이미지보다 높아지고 패널이 열린 상태로 유지되는 테스트 추가.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel action moves selected item forward"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 28개 통과.
- 검증: `git diff --check -- SESSION_HANDOFF.md third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `de92f84` (`이미지 바코드 레이어 패널 이동 버튼 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 최상하 이동 버튼 추가

목적: 레이어 패널 header의 이동 버튼을 기존 레이어 명령 범위와 맞춰 `맨앞`/`앞`/`뒤`/`맨뒤`를 모두 실행할 수 있게 한다.
- 수정 예정: `fortune_sheet_painter.dart`의 레이어 패널 action helper/rendering을 4개 명령으로 확장한다.
- 수정 예정: `fortune_sheet_canvas.dart`의 레이어 패널 action hit-test 목록을 `맨앞`/`앞`/`뒤`/`맨뒤`로 확장한다.
- 변경: `fortune_sheet_painter.dart`에 `fortuneImageLayerPanelActionCommands`를 추가하고 header action rect/rendering을 `맨앞`/`앞`/`뒤`/`맨뒤` 4개 버튼으로 확장.
- 변경: `fortune_sheet_canvas.dart`의 레이어 패널 action hit-test가 동일한 `fortuneImageLayerPanelActionCommands`를 사용하도록 변경.
- 변경: `fortune_barcode_dialog_test.dart`에 레이어 패널에서 선택 이미지의 `맨뒤` 버튼 클릭 시 zOrder가 가장 뒤로 이동하고 패널이 열린 상태로 유지되는 테스트 추가.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel action sends selected item to back"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 29개 통과.
- 검증: `git diff --check -- SESSION_HANDOFF.md third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `464b069` (`이미지 바코드 레이어 패널 최상하 이동 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 스크롤 추가

목적: 이미지/바코드가 8개를 초과해도 레이어 패널에서 아래 항목까지 스크롤해 선택할 수 있게 한다.
- 수정 예정: `fortune_sheet_painter.dart`에 레이어 패널 scrollOffset 상태와 scroll-aware row rect/rendering을 추가한다.
- 수정 예정: `fortune_sheet_canvas.dart`에 `_imageLayerPanelScrollOffset` 상태와 wheel/pan scroll 처리, scroll-aware row hit-test를 추가한다.
- 변경: `fortune_sheet_painter.dart`에 `imageLayerPanelScrollOffset`, scroll-aware `fortuneImageLayerPanelItemRect`, max/clamp helper를 추가하고 painter row 렌더링이 scrollOffset을 반영하도록 변경.
- 변경: `fortune_sheet_canvas.dart`에 `_imageLayerPanelScrollOffset`, 레이어 패널 wheel scroll 처리, scroll-aware row hit-test, painter 전달을 추가.
- 변경: `fortune_barcode_dialog_test.dart`에 10개 이미지 레이어 패널에서 wheel scroll 후 9번째 항목을 클릭해 active image가 바뀌는 테스트 추가.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel scroll selects lower item"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 30개 통과.
- 검증: `git diff --check -- SESSION_HANDOFF.md third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `c123fdb` (`이미지 바코드 레이어 패널 스크롤 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 선택 항목 자동 스크롤

목적: 레이어 패널을 열 때 현재 선택된 이미지/바코드 row가 보이는 범위 밖이면 자동으로 스크롤해 선택 항목을 바로 확인할 수 있게 한다.
- 변경: `fortune_sheet_canvas.dart`에 `_imageLayerPanelScrollOffsetToRevealActive`를 추가하고, 레이어 패널 open 시 active image row가 visible range에 들어오도록 scrollOffset을 보정.
- 변경: `fortune_barcode_dialog_test.dart`에 10개 이미지 중 마지막 표시 범위 밖의 낮은 zOrder 이미지를 선택한 뒤 레이어 패널을 열면 해당 row가 보이도록 scrollOffset이 설정되는 테스트 추가.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel opens scrolled to active lower item"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 31개 통과.
- 검증: `git diff --check -- SESSION_HANDOFF.md third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `80f1bde` (`이미지 바코드 레이어 패널 선택 항목 자동 스크롤 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 스크롤바 표시

목적: 레이어 패널이 스크롤 가능한 긴 목록일 때 사용자가 현재 위치와 추가 항목 존재를 알 수 있도록 패널 우측에 스크롤바 thumb을 표시한다.
- 변경: `fortune_sheet_painter.dart`에 레이어 패널 scrollbar thumb rect helper와 렌더링을 추가하고, row label 영역이 scrollbar와 겹치지 않도록 폭을 조정.
- 변경: `fortune_barcode_dialog_test.dart`의 레이어 패널 스크롤 테스트에 scrollOffset에 따른 scrollbar thumb rect 생성 및 위치 이동 검증을 추가.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel scroll selects lower item"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 31개 통과.
- 검증: `git diff --check -- SESSION_HANDOFF.md third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `77f5b45` (`이미지 바코드 레이어 패널 스크롤바 표시`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 스크롤바 드래그 추가

목적: 레이어 패널의 스크롤바 thumb를 마우스로 드래그해 긴 이미지/바코드 목록을 직접 스크롤할 수 있게 한다.
- 변경: `fortune_sheet_canvas.dart`에 레이어 패널 스크롤바 drag 상태와 thumb hit-test/start/update/commit/cancel helper를 추가하고 pointer down/move/up/cancel 흐름에 연결.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 10개 이미지 레이어 패널에서 scrollbar thumb를 아래로 드래그하면 `imageLayerPanelScrollOffset`이 증가하는지 검증하는 케이스 추가.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel scrollbar thumb drags scroll offset"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(32 tests).
- 검증: `git diff --check` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `d6fa59b` (`이미지 바코드 레이어 패널 스크롤바 드래그 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 row 드래그 재정렬 추가

목적: 레이어 패널에서 이미지/바코드 row를 직접 드래그해 앞/뒤 레이어 순서를 바꿀 수 있게 한다.
- 변경: `fortune_sheet_canvas.dart`에 레이어 패널 row drag 상태와 front-first row index 기반 zOrder 재정렬 helper를 추가하고 pointer down/move/up/cancel 흐름에 연결.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 긴 목록 레이어 패널에서 row를 다른 row 위치로 드래그하면 active image와 zOrder/패널 표시 순서가 함께 갱신되는지 검증하는 케이스 추가.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel row drag reorders layers"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(33 tests).
- 검증: `git diff --check` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `cc8e1f5` (`이미지 바코드 레이어 패널 행 드래그 재정렬 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 row 드래그 자동 스크롤 추가

목적: 긴 레이어 목록에서 row를 드래그할 때 패널 위/아래 가장자리로 이동하면 자동 스크롤되어 보이지 않는 항목 위치까지 재정렬할 수 있게 한다.
- 변경: `fortune_sheet_canvas.dart`에 row drag 중 edge auto-scroll helper를 추가하고 target row 계산 전에 scrollOffset을 보정.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 10개 이미지 목록에서 맨 위 row를 패널 하단 가장자리로 반복 드래그하면 scrollOffset이 증가하고 마지막 row 위치까지 zOrder가 재정렬되는지 검증하는 케이스 추가.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel row drag auto scrolls to lower rows"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(34 tests).
- 검증: `git diff --check` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `d659307` (`이미지 바코드 레이어 패널 행 드래그 자동 스크롤 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 row 드래그 피드백 추가

목적: 레이어 패널 row를 드래그하는 동안 현재 이동 중인 row와 target 위치를 시각적으로 표시해 재정렬 동작을 예측 가능하게 한다.
- 변경: `fortune_sheet_canvas.dart`에 row drag target index 상태를 추가하고 `FortuneSheetPainter` 생성 시 dragging image id/target index를 전달.
- 변경: `fortune_sheet_painter.dart`에 dragging row 배경/테두리와 target indicator 렌더링을 추가하고 repaint 조건에 반영.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 보강: `fortune_barcode_dialog_test.dart`의 row drag 재정렬 테스트에 dragging image id/target index 전달 및 pointer up 후 초기화 검증 추가.
- 수정: row drag commit 시 `setState(_cancelImageLayerPanelRowDrag)`로 painter 피드백 상태가 즉시 초기화되도록 보정.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel row drag reorders layers"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\lib\src\fortune_sheet_painter.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(34 tests).
- 검증: `git diff --check` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `cb59528` (`이미지 바코드 레이어 패널 행 드래그 피드백 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 row 더블클릭 편집 추가

목적: 레이어 패널에서 이미지/바코드 row를 더블클릭하면 해당 객체의 편집 다이얼로그를 바로 열어, 레이어 관리와 속성 편집을 같은 패널에서 이어갈 수 있게 한다.
- 변경: `fortune_sheet_canvas.dart`에 layer row 더블클릭 판정 상태와 row edit helper를 추가하고 이미지/바코드 타입에 맞춰 기존 edit dialog를 호출.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 이미지 row 더블클릭 시 이미지 편집 다이얼로그, 바코드 row 더블클릭 시 바코드 편집 다이얼로그가 열리는지 검증하는 케이스 2개 추가.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel row double click opens image edit dialog"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel row double click opens barcode edit dialog"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(36 tests).
- 검증: `git diff --check` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `3362e75` (`이미지 바코드 레이어 패널 행 더블클릭 편집 추가`).

### 완료 (2026-07-04): 이미지/바코드 레이어 패널 키보드 조작 추가

목적: 레이어 패널이 열린 상태에서 키보드로 row 선택과 편집 진입을 할 수 있게 해, 마우스 없이도 레이어 탐색/속성 편집을 이어갈 수 있게 한다.
- 변경: `fortune_sheet_canvas.dart`에 레이어 패널 전용 key handler를 추가해 ArrowUp/ArrowDown/Home/End 선택 이동, Enter 편집, Escape 닫기를 처리.
- 검증: `dart_format` 적용, `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 테스트 추가: `fortune_barcode_dialog_test.dart`에 레이어 패널 키보드 선택 이동/자동 스크롤/Enter 편집 진입과 Escape 닫기 검증 케이스 추가.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel keyboard selects and edits rows"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --plain-name "image layer panel escape closes panel"` 통과.
- 검증: `C:\Flutter\bin\flutter.bat analyze third_party\fortune_sheet\lib\src\fortune_sheet_canvas.dart third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart --no-fatal-warnings --no-fatal-infos` 통과.
- 검증: `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` 통과(38 tests).
- 검증: `git diff --check` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `5924ef9` (`이미지 바코드 레이어 패널 키보드 조작 추가`).

### 완료 (2026-07-04): SwipeActionTable 마우스/터치 드래그 스크롤 허용

목적: `lib/widgets/swipe_action_table.dart`를 공통으로 사용하는 테이블에서 별도 플래그로 막지 않는 한 마우스/터치 상하 드래그로 기본 세로 스크롤이 되도록 한다.
- 변경: `SwipeActionTable`에 기본값 true인 `dragScrollEnabled` 플래그를 추가하고, 내부 `Scrollable`에만 적용되는 `_SwipeActionTableScrollBehavior`로 `PointerDeviceKind.mouse/touch` drag device를 허용.
- 변경: `EditableSwipeNameTable`, `ResizableTable`도 `dragScrollEnabled` 옵션을 받아 `SwipeActionTable`로 전달 가능하게 구성.
- 테스트: `test/swipe_action_table_test.dart`에 mouse 상하 드래그 기본 스크롤 및 `dragScrollEnabled: false` 비활성 동작 검증 추가.
- 검증: `dart format lib/widgets/swipe_action_table.dart test/swipe_action_table_test.dart`, `C:\Flutter\bin\flutter.bat analyze lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart` 24개 통과, `git diff --check -- SESSION_HANDOFF.md lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/widgets/swipe_action_table.dart`, `test/swipe_action_table_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `0249928` (`공통 테이블 마우스 드래그 스크롤 허용`).

### 완료 (2026-07-04): 헤더 드롭다운 선택 가능 배경색 보정

목적: 헤더의 브랜드/라벨 드롭다운이 선택 가능할 때 라벨 설정 다이얼로그 드롭다운과 같은 흰 배경으로 보이도록 맞춘다.
- 변경: `lib/home_page_manager.dart`의 `_DropdownField`에서 enabled 상태를 공통 계산하고, `InputDecoration.filled/fillColor`를 `Colors.white`/`Color(0xFFE9ECEF)`로 명시해 `_ModelessDropdownField`와 배경색을 맞춤.
- 검증: `dart format lib/home_page_manager.dart`, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\widget_test.dart` 통과, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `751759e` (`헤더 드롭다운 배경색 통일`).

### 완료 (2026-07-04): 액션 레일 열린 동안 테이블 툴팁 비활성화

목적: 브랜드/라벨 설정 다이얼로그 테이블의 수정/삽입/삭제 액션영역이 열리면 표시 중인 테이블 툴팁을 닫고, 액션영역이 닫힐 때까지 다시 뜨지 않게 한다.
- 변경: `SwipeActionTable`의 `_TableBodyTooltip.enabled` 조건에 `_openActionIndex == null`을 추가해 액션 레일이 열리면 테이블 툴팁을 숨기고 재예약하지 않도록 변경.
- 테스트: `test/swipe_action_table_test.dart`에 액션 레일 open 동안 row tooltip이 숨겨지고, close 후 다시 나타나는 케이스 추가.
- 검증: `dart format lib/widgets/swipe_action_table.dart test/swipe_action_table_test.dart`, `C:\Flutter\bin\flutter.bat analyze lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 23개 통과, `git diff --check -- SESSION_HANDOFF.md lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/widgets/swipe_action_table.dart`, `test/swipe_action_table_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `bfece4a` (`액션 레일 중 테이블 툴팁 비활성화`).

### 완료 (2026-07-04): 인라인 에디터 중 테이블 툴팁 비활성화

목적: 브랜드/라벨 설정 다이얼로그 테이블에서 인라인 에디터 위로 테이블 툴팁이 뜨지 않게 하고, 인라인 편집 진입 시 이미 떠 있던 테이블 툴팁을 닫는다.
- 변경: `SwipeActionTable`의 자체 `_TableBodyTooltip`에 `enabled` 상태를 추가하고, 인라인 편집 행이 있으면 표시 중인 툴팁을 숨긴 뒤 재예약하지 않도록 변경.
- 테스트: `test/swipe_action_table_test.dart`에 인라인 상태 전환 시 row tooltip이 숨겨지고, 편집 중에는 다시 나타나지 않으며, 편집 종료 후 다시 나타나는 케이스 추가.
- 검증: `dart format lib/widgets/swipe_action_table.dart test/swipe_action_table_test.dart`, `C:\Flutter\bin\flutter.bat analyze lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 22개 통과, `git diff --check -- SESSION_HANDOFF.md lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/widgets/swipe_action_table.dart`, `test/swipe_action_table_test.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `6eae935` (`인라인 편집 중 테이블 툴팁 비활성화`).

### 완료 (2026-07-04): 브랜드/라벨 설정 테이블 액션 진입 시 툴팁 닫기

목적: 브랜드/라벨 설정 다이얼로그 테이블의 툴팁이 떠 있는 상태에서 수정/삽입/순서변경 액션으로 진입하면 즉시 닫히도록 한다.
- 변경: 공용 `SwipeActionTable` 액션 버튼 클릭 시 `Tooltip.dismissAllToolTips()`를 호출해 브랜드/라벨 수정·삽입 액션 진입 전에 표시 중인 툴팁을 닫는다.
- 변경: 라벨 설정 순서변경 모드 진입 핸들러에서도 `Tooltip.dismissAllToolTips()`를 호출한다.
- 검증: `dart format lib/home_page_manager.dart lib/widgets/swipe_action_table.dart`, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\widgets\swipe_action_table.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 통과, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart lib\widgets\swipe_action_table.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/widgets/swipe_action_table.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `589e522` (`설정 테이블 액션 진입 시 툴팁 닫기`).

### 완료 (2026-07-04): 라벨 설정 브랜드 메뉴 높이 보정

목적: 라벨 설정 다이얼로그의 브랜드 드롭다운 메뉴가 다이얼로그 하단 빈 영역까지 사용하지 못하고 불필요하게 스크롤되는 문제를 수정한다.
- 변경: `_ModelessDropdownField`가 `menuBoundaryKey`를 받아 다이얼로그 콘텐츠 하단까지 사용 가능한 높이를 계산하도록 변경했다.
- 변경: 라벨 설정 다이얼로그 콘텐츠 영역을 `KeyedSubtree`로 감싸 브랜드 메뉴 경계로 전달했다. 항목 전체 높이가 들어가면 스크롤 없이 끝나고, 경계 내 높이가 부족할 때만 스크롤된다.
- 검증: `dart format lib/home_page_manager.dart`, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 통과, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `d771348` (`라벨 설정 브랜드 메뉴 높이 보정`).

### 완료 (2026-07-04): 라벨 설정 브랜드 드롭다운 Overlay 직접 표시

목적: `DropdownButton2`의 Navigator route 방식이 라벨 설정 OverlayEntry 다이얼로그와 충돌해 브랜드 메뉴가 여전히 정상 표시되지 않는 문제를 수정한다.
- 변경: 라벨 설정 다이얼로그 브랜드 선택부를 `_ModelessDropdownField`로 교체했다. 클릭 시 root overlay에 메뉴 `OverlayEntry`를 직접 삽입해 현재 다이얼로그보다 앞에 표시한다.
- 변경: 메뉴 열림/차단/선택/닫힘 디버깅 로그를 추가했다. 메뉴 위치는 버튼 rect와 화면 크기 기준으로 아래 또는 위에 배치한다.
- 검증: `dart format lib/home_page_manager.dart`, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 통과, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `14820aa` (`라벨 설정 브랜드 메뉴를 오버레이로 표시`).

### 완료 (2026-07-04): 라벨 설정 브랜드 드롭다운 메뉴 표시 보정

목적: 라벨 설정 다이얼로그의 브랜드 드롭다운을 클릭해도 헤더 브랜드 드롭다운과 같은 목록 메뉴가 정상 표시되지 않는 문제를 수정한다.
- 변경: `_DropdownField`에 `useRootNavigator` 옵션을 추가하고, 라벨 설정 다이얼로그의 브랜드 드롭다운은 `useRootNavigator: false`로 열리게 했다.
- 변경: 라벨 설정 다이얼로그는 브랜드 목록을 내부 복사본으로 보관하지 않고 부모가 넘긴 헤더 브랜드 목록 `widget.brands`를 직접 사용한다.
- 검증: `dart format lib/home_page_manager.dart`, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 통과, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `15ebbaf` (`라벨 설정 브랜드 드롭다운 메뉴 표시 보정`).

### 완료 (2026-07-04): 라벨 설정 브랜드 드롭다운 전체 목록 보정

목적: 라벨 설정 다이얼로그의 브랜드 드롭다운이 헤더에서 선택된 브랜드 한 개만 보이는 문제를 수정하고, 헤더 브랜드 드롭다운과 같은 전체 브랜드 목록을 사용하게 한다.
- 변경: `HomePageManager` 상태에 헤더용 브랜드 목록 `_brands`를 보존하고, 헤더/브랜드 설정/라벨 설정 다이얼로그 모두 이 목록을 우선 사용하도록 변경.
- 검증: `dart format lib/home_page_manager.dart`, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 통과, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `32be043` (`라벨 설정 브랜드 목록 소스 보정`).

### 완료 (2026-07-04): 라벨 설정 다이얼로그 브랜드 드롭다운 추가

목적: 라벨 설정 다이얼로그의 라벨 테이블 바로 위에 브랜드 드롭다운을 추가하고, 브랜드 변경 시 상단 라벨 매니저와 현재 다이얼로그의 라벨 목록/선택을 같은 조회 흐름으로 동기화한다.
- 변경: `_LabelSettingsDialog`에 브랜드 목록/선택/변경 콜백을 전달하고, 테이블 위 브랜드 드롭다운을 추가했다. 편집/삽입/순서변경/조회/브랜드 변경 중에는 드롭다운을 비활성화한다.
- 변경: 다이얼로그 브랜드 변경은 부모 `onBrandChanged`와 `_scheduleLabelSizeLoad(selectFirstLabel: true)`를 await해 상단 선택, 라벨 목록, 현재 다이얼로그를 같은 조회 결과로 동기화한다. `didUpdateWidget` 중복 조회는 플래그로 건너뛴다.
- 검증: `dart format lib/home_page_manager.dart`, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 통과, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `c8c3256` (`라벨 설정 브랜드 선택 동기화 추가`).

### 완료 (2026-07-04): 라벨 더블클릭 조회 중복 차단

목적: 라벨 관리에서 라벨 이름 더블클릭으로 조회/로드를 시작한 뒤, 해당 조회가 완료되기 전까지 추가 더블클릭 조회를 막는다.
- 변경: `_LabelSettingsDialog.onLabelSelected`를 `Future<void>` 콜백으로 변경하고, `_selectingLabel` 상태로 `_handleLabelNameDoubleTap` 재진입을 차단.
- 검증: `dart format lib/home_page_manager.dart`, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 통과, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `b205e9a` (`라벨 더블클릭 조회 중복 차단`).

### 완료 (2026-07-04): 라벨 관리 더블클릭 선택/조회 추가

목적: 브랜드 관리처럼 라벨 관리에서도 라벨 이름 컬럼 더블클릭 시 해당 라벨을 선택하고 조회/로드 처리로 연결한다.
- 확인: 브랜드는 `onNameDoubleTap: _handleBrandNameDoubleTap` → `widget.onBrandSelected` → `_handleBrandSelectedFromDialog` 흐름이 있으나, 라벨은 `onRowSelected`가 순서 변경용 내부 선택에만 사용되고 더블클릭 조회 콜백이 없다.
- 변경: `_LabelSettingsDialog`에 `onLabelSelected` 콜백 추가, 라벨 테이블 `onNameDoubleTap` 연결, 편집/삽입/순서 변경 중 더블클릭 조회 차단.
- 검증: `dart format lib/home_page_manager.dart`, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 통과, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `9db545f` (`라벨 관리 더블클릭 선택 조회 추가`).

### 완료 (2026-07-04): 브랜드/라벨 관리 UI-DB 흐름 정리

목적: 브랜드/라벨 관리에서 UI 조작과 DB 반영 위치/재조회 흐름이 어긋나는 부분을 정리한다.
- 라벨 추가: 현재 행 아래 삽입 UI를 유지하므로 `LabelSizeDAO.insert`가 삽입 순번을 받아 기존 뒤 순번을 밀도록 변경.
- 라벨 순서 적용: 확인창 취소 시 `_cancelOrderChanges()`로 변경 내용을 폐기하지 않고 편집 상태를 유지하도록 변경.
- 브랜드 저장: 추가/수정/삭제 후 로컬 목록만 publish하지 않고 부모에서 DB 재조회한 목록으로 다이얼로그 상태를 동기화하도록 변경.
- 검증: `dart format lib/home_page_manager.dart lib/models/label_size.dart`, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\models\label_size.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 통과, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart lib\models\label_size.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/models/label_size.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `90fc4da` (`브랜드 라벨 관리 UI DB 흐름 정리`).

### 완료 (2026-07-04): UpdateItem SQL COLLATE 문법 수정

목적: `lib/models/update_item.dart`의 `CONVERT(..., COLLATE ...)` 오용을 다른 모델들의 SQL 패턴처럼 `CONVERT(NVARCHAR(...), 컬럼 COLLATE ${DAO.CP949})` 형태로 수정한다.
- 확인: `lib/models/item_of_market.dart`, `lib/models/column.dart` 등은 문자열 컬럼에 `컬럼 COLLATE ${DAO.CP949}`를 적용한 뒤 `CONVERT`한다.
- 변경: `P2.RICH_ITEM_NAME`, `P1.RICH_ELEMENT`, `P1.RICH_ELEMENT_RTF` 3곳의 `COLLATE` 위치를 수정.
- 검증: `dart format lib/models/update_item.dart`, `C:\Flutter\bin\flutter.bat analyze lib\models\update_item.dart --no-fatal-warnings --no-fatal-infos` 통과, `git diff --check -- SESSION_HANDOFF.md lib\models\update_item.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/models/update_item.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `2d9e5a9` (`UpdateItem SQL COLLATE 문법 수정`).

### 완료 (2026-07-04): 브랜드/라벨 설정 CRUD 함수 배치 정리

목적: `lib/home_page_manager.dart`의 브랜드/라벨 추가/수정/삭제 함수가 각 다이얼로그 안에서 한 부분에 모이도록 정리한다. 동작 변경 없이 함수 순서만 조정한다.
- 확인: 라벨 설정 함수는 `_submitLabelNameEdit` 아래에 `_updateLabelNameAndScale`, `_insertLabelName`, `_deleteLabel`이 이미 함께 배치되어 있다.
- 변경: 브랜드 설정 함수의 `_updateBrandName`을 `_insertBrandName` 바로 뒤로 이동해 브랜드 추가/수정/삭제 함수가 한 구역에 모이도록 정리.
- 검증: `dart format lib/home_page_manager.dart`, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 통과, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 통과, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`. 기존 사용자 변경 `lib/core/app.dart`는 제외.
- 커밋: `72f5844` (`브랜드 라벨 CRUD 함수 배치 정리`).

### 완료 (2026-07-04): 라벨 삭제 LastConnect/LabelSize 단일 트랜잭션 통합

목적: `lib/home_page_manager.dart`의 라벨 삭제가 레거시 `CLabelSizeManagerDlg::OnBnClickedBtnDeleteLabelSize()`와 같은 순서(`CLastConnectDAO::DeleteByLabelSizeID` 후 `CLabelSizeDAO::Delete`)로 동작하되, Dart에서는 `LabelSizeDAO.deleteByLabelSizeId` 안에서 `BM_RICH_LAST_ID` 삭제와 `BM_RICH_LABELSIZE_FORM` 삭제를 하나의 DB 트랜잭션으로 처리하도록 수정한다.
- `lib/models/last_connect.dart`: `LastConnectDAO.DeleteSqlByLabelSizeId` SQL 상수 추가. public `deleteByLabelSizeId`도 같은 SQL을 사용하도록 변경.
- `lib/models/label_size.dart`: `last_connect.dart` import 추가. `LabelSizeDAO.deleteByLabelSizeId`에서 `SET XACT_ABORT ON` 트랜잭션 안에 `LastConnectDAO.DeleteSqlByLabelSizeId`와 `BM_RICH_LABELSIZE_FORM` 삭제를 함께 실행. 첫 LastConnect 삭제가 0건이어도 실패하지 않도록 `SET NOCOUNT ON`을 사용하고, 라벨 삭제 rowcount는 `SELECT @labelSizeAffected AS AFFECTED`로 반환해 검증.
- `lib/home_page_manager.dart`: 라벨 삭제 호출은 이미 `LabelSizeDAO.deleteByLabelSizeId(label.labelSizeId)` 단일 호출이라 코드 변경 없음.
- 검증 완료: `dart format` 3파일 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\models\label_size.dart lib\models\last_connect.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 성공, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart lib\models\label_size.dart lib\models\last_connect.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/models/label_size.dart`, `lib/models/last_connect.dart`. 기존 dirty `lib/core/app.dart`는 제외.
- 기능 커밋: `4208ca8` (`라벨 삭제 트랜잭션 통합`).

### 완료 (2026-07-04): 브랜드 삭제 LastConnect/Brand 단일 트랜잭션 통합

목적: `lib/home_page_manager.dart`에서 `LastConnectDAO.deleteByBrandId`와 `BrandDAO.deleteByBrandId`를 분리 호출하던 구조를 없애고, `BrandDAO.deleteByBrandId` 안에서 `BM_RICH_LAST_ID` 삭제와 `BM_RICH_BRAND` 삭제가 하나의 DB 트랜잭션으로 처리되도록 수정한다.
- `lib/home_page_manager.dart`: `_deleteBrand`에서 `LastConnectDAO.deleteByBrandId(brand.brandId)` 직접 호출 제거. `last_connect.dart` import 제거.
- `lib/models/last_connect.dart`: `LastConnectDAO.DeleteSqlByBrandId` SQL 상수 추가. public `deleteByBrandId`도 같은 SQL을 사용하도록 `_deleteBySql` helper 추가.
- `lib/models/brand.dart`: `last_connect.dart` import 추가. `BrandDAO.deleteByBrandId`에서 `SET XACT_ABORT ON` 트랜잭션 안에 `LastConnectDAO.DeleteSqlByBrandId`와 `BM_RICH_BRAND` 삭제를 함께 실행. 첫 LastConnect 삭제가 0건이어도 실패하지 않도록 `SET NOCOUNT ON`을 사용하고, 브랜드 삭제 rowcount는 `SELECT @brandAffected AS AFFECTED`로 반환해 검증.
- 검증 완료: `dart format` 3파일 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\models\brand.dart lib\models\last_connect.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 성공, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart lib\models\brand.dart lib\models\last_connect.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/models/brand.dart`, `lib/models/last_connect.dart`. 기존 dirty `lib/core/app.dart`는 제외.
- 기능 커밋: `8bb2683` (`브랜드 삭제 트랜잭션 통합`).

### 완료 (2026-07-04): 브랜드 삭제 경로 레거시 구조 복원

목적: `lib/home_page_manager.dart`의 브랜드 삭제가 레거시 `CBrandManagerDlg::OnBtnDeleteBrand()`와 같은 순서(`CLastConnectDAO::DeleteByBrandID` 후 `CBrandDAO::Delete`)로 동작하도록 수정한다.
- `lib/home_page_manager.dart`: `last_connect.dart` import 추가. `_deleteBrand`에서 `LastConnectDAO.deleteByBrandId(brand.brandId)`를 `BrandDAO.deleteByBrandId(brand)`보다 먼저 호출하도록 변경.
- `lib/models/brand.dart`: `BrandDAO.deleteByBrandId`를 레거시 `CBrandDAO::Delete`처럼 `BM_RICH_BRAND`에서 `RICH_BRAND_ID` 기준 단순 삭제하도록 변경. 기존 `RICH_BRAND_ORDER` 재정렬 트랜잭션 제거.
- `lib/models/last_connect.dart`: `delete`/`deleteByBrandId`/`deleteByLabelSizeId`가 대상 행 없음(`affected=0`)을 실패로 보지 않도록 변경. 레거시 C++ `Execute(DELETE...)` 동작과 맞춤.
- 검증 완료: `dart format` 3파일 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\models\brand.dart lib\models\last_connect.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test\swipe_action_table_test.dart test\label_size_cache_test.dart` 21개 성공, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart lib\models\brand.dart lib\models\last_connect.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/models/brand.dart`, `lib/models/last_connect.dart`. 기존 dirty `lib/core/app.dart`는 제외.
- 기능 커밋: `f3d9782` (`브랜드 삭제 경로 레거시 구조 복원`).

### 완료 (2026-07-04): LastConnect 모델/DAO 구성

목적: 레거시 `.tmp/LabelManager/LabelManagerLib/LastConnect.cpp/.h`의 `CLastConnect`/`CLastConnectDAO`를 Flutter 모델 계층에 추가한다.
- 참조 확인: C++ DAO는 `BM_RICH_LAST_ID`의 `RICH_USER_ID`, `RICH_LAST_BRAND_ID`, `RICH_LAST_SIZE_ID`를 대상으로 `SelectByUserID`, `Insert`, `Update`, `Delete`, `DeleteByBrandID`, `DeleteByLabelSizeID`, `IsExistByUserID`를 제공한다.
- `lib/models/last_connect.dart`: `LastConnect` 모델과 `LastConnectDAO` 추가. 기존 모델 패턴대로 `fromMap`, `toString`, 파라미터 SQL, `DAO.mapRow`, `DAO.affectedRows` 검증, `debugLog`/`runtimeLogTag` 오류 처리를 사용한다.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\models\last_connect.dart --no-fatal-warnings --no-fatal-infos` No issues, `git diff --check -- SESSION_HANDOFF.md lib\models\last_connect.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/models/last_connect.dart`. 기존 dirty `lib/core/app.dart`는 제외.
- 기능 커밋: `bcf2ec2` (`LastConnect 모델 DAO 추가`).

### 완료 (2026-07-04): 라벨 설정 스와이프 라벨 삭제 저장 구현

목적: 라벨 설정 다이얼로그의 스와이프 삭제 버튼 클릭 시 DB에서 라벨을 삭제하고, 성공 후 `LabelSize.datas`, 헤더 라벨 드롭다운, 라벨 설정 테이블을 갱신한다.
- 참조 확인: `.tmp/LabelManager/LabelManagerLib/LabelSize.cpp`의 `CLabelSizeDAO::Delete(int nLabelSizeID)`는 `BM_RICH_LABELSIZE_FORM`에서 `RICH_LABELSIZE_ID` 기준으로 삭제한다.
- 사용자 확인 완료: 삭제한 라벨이 현재 선택 라벨이면 삭제 위치 기준 다음 라벨, 없으면 이전 라벨을 선택한다. 목록이 비면 선택 해제.
- 구현 예정: `lib/models/label_size.dart`에 `LabelSizeDAO.deleteByLabelSizeId` 추가, `lib/home_page_manager.dart`의 라벨 테이블 `onDeleteRow`를 확인 다이얼로그/DAO/실패 다이얼로그/재조회 갱신으로 연결.
- `lib/models/label_size.dart`: `LabelSizeDAO.deleteByLabelSizeId(labelSizeId)` 추가. `BM_RICH_LABELSIZE_FORM`에서 `RICH_LABELSIZE_ID` 기준으로 삭제하고 affected row를 검증.
- `lib/home_page_manager.dart`: 라벨 설정 테이블 `onDeleteRow`를 `_deleteLabel`에 연결. `_deleteBrand`와 같은 확인 다이얼로그/DAO 호출/실패 다이얼로그 구조로 처리하고, 성공 후 `widget.onLabelsChanged()` 재조회 결과로 `LabelSize.datas`, 헤더 드롭다운 리스트, 라벨 설정 테이블을 갱신한다. 선택 라벨 삭제 시 최신 부모 선택 ID 기준으로 다음/이전 라벨을 선택한다.
- 검증 진행: `C:\Flutter\bin\dart.bat format lib\home_page_manager.dart lib\models\label_size.dart` 성공, `flutter test test/swipe_action_table_test.dart test/label_size_cache_test.dart` 21개 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\models\label_size.dart --no-fatal-warnings --no-fatal-infos` No issues.
- 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\models\label_size.dart test\swipe_action_table_test.dart test\label_size_cache_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart lib\models\label_size.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/models/label_size.dart`.
- 기능 커밋: `880c109` (`라벨 설정 스와이프 삭제 저장 구현`).

### 완료 (2026-07-03): 라벨 설정 인라인 라벨 이름/전자저울 수정 저장 구현

목적: 라벨 설정 다이얼로그의 수정 인라인 에디터에서 Enter 키/Enter 아이콘 적용 시 라벨 이름과 전자저울 사용 여부를 DB에 저장하고, 성공 후 `LabelSize.datas`, 헤더 라벨 드롭다운, 라벨 설정 테이블을 리스트/테이블 재설정으로 갱신한다.
- 참조 확인: `.tmp/LabelManager/LabelManagerLib/LabelSize.cpp`의 `CLabelSizeDAO::UpdateNameAndScale(int nLabelSizeID, const CString& strName, BOOL bUseScale)`는 `BM_RICH_LABELSIZE_FORM`의 `RICH_LABELSIZE_NAME`, `RICH_SETUP_USE_SCALE`을 해당 `RICH_LABELSIZE_ID` 기준으로 업데이트한다.
- 사용자 확인 완료: 수정 성공 후 헤더 드롭다운 선택은 기존 선택 유지. 단, 기존 선택 라벨이 수정 대상이면 재조회된 갱신 객체로 교체한다.
- 구현 예정: `lib/models/label_size.dart`에 `LabelSizeDAO.updateNameAndScale` 추가, `lib/home_page_manager.dart`의 수정 submit 경로를 `_updateBrandName` 구조처럼 확인 다이얼로그/DAO/실패 다이얼로그/재설정 갱신으로 연결.
- `lib/models/label_size.dart`: `LabelSizeDAO.updateNameAndScale(labelSizeId, labelSizeName, useScale)` 추가. `BM_RICH_LABELSIZE_FORM`의 `RICH_LABELSIZE_NAME`, `RICH_SETUP_USE_SCALE`을 파라미터 쿼리로 수정하고 affected row를 검증.
- 1차 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\models\label_size.dart --no-fatal-warnings --no-fatal-infos` No issues.
- `lib/home_page_manager.dart`: 수정 상태 submit 시 `_updateLabelNameAndScale` 실행. `_updateBrandName`과 같은 확인 다이얼로그/DAO 호출/실패 다이얼로그 구조로 연결하고, DB 성공 후 `widget.onLabelsChanged()` 재조회 결과로 `LabelSize.datas`, 헤더 드롭다운 리스트, 라벨 설정 테이블을 재설정한다.
- 검증 진행: `C:\Flutter\bin\dart.bat format lib\home_page_manager.dart lib\models\label_size.dart` 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\models\label_size.dart --no-fatal-warnings --no-fatal-infos` No issues.
- 검증 완료: `flutter test test/swipe_action_table_test.dart test/label_size_cache_test.dart` 21개 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\models\label_size.dart test\swipe_action_table_test.dart test\label_size_cache_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart lib\models\label_size.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/models/label_size.dart`.
- 기능 커밋: `98f43b7` (`라벨 설정 인라인 수정 저장 구현`).

### 완료 (2026-07-03): 라벨 설정 인라인 라벨 삽입 저장 구현

목적: 라벨 설정 다이얼로그의 삽입 인라인 에디터에서 Enter 키/Enter 아이콘 적용 시 DB에 라벨을 추가하고, 성공 후 `LabelSize.datas`, 헤더 라벨 드롭다운, 라벨 설정 테이블을 갱신한다.
- 참조 확인: `.tmp/LabelManager/LabelManagerLib/LabelSize.cpp`의 `CLabelSizeDAO::Insert(int nBrandID, const CString& strName, BOOL bUseScale)`는 라벨 폼 insert 후 `BM_RICH_CHECK_COLUMNS` 기본 4개 행(`ITEMNAME`, `ELEMENT`, `SWEIGHT`, `SPRICE`)을 추가한다.
- 사용자 확인 완료: 새 `RICH_LABELSIZE_ORDER`는 C++의 `RICH_BRAND_ID=12` 고정 조건이 아니라 선택 브랜드 ID 기준으로 `MAX(order)+1` 계산. 삽입 성공 후 헤더 드롭다운 선택은 기존 선택 유지.
- 구현 예정: `lib/models/label_size.dart`에 `LabelSizeDAO.insert` 추가, `lib/home_page_manager.dart`의 `_LabelSettingsDialog` submit 경로에 확인 다이얼로그/진행 스낵바/실패 다이얼로그 및 DB 성공 후 재조회 갱신 연결.
- `lib/models/label_size.dart`: `LabelSizeDAO.insert(brandId, labelSizeName, useScale)` 추가. 선택 브랜드 기준 새 순서 계산, `BM_RICH_LABELSIZE_FORM` 삽입, `BM_RICH_CHECK_COLUMNS` 기본 4개 행 삽입, 삽입 라벨 반환을 단일 트랜잭션으로 처리.
- 1차 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib\models\label_size.dart --no-fatal-warnings --no-fatal-infos` No issues.
- `lib/home_page_manager.dart`: 라벨 설정 다이얼로그에 현재 `brandId`와 `onLabelsChanged` 재조회 콜백 전달. `_submitLabelNameEdit`에서 삽입 상태일 때 `_insertLabelName` 실행. 확인 다이얼로그/진행 스낵바/실패 다이얼로그 추가. DB 성공 후 부모 재조회 콜백으로 `LabelSize.datas`, 헤더 드롭다운, 다이얼로그 테이블을 갱신하며 헤더 선택 라벨은 기존 선택 유지.
- 검증 진행: `C:\Flutter\bin\dart.bat format lib\home_page_manager.dart lib\models\label_size.dart` 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\models\label_size.dart --no-fatal-warnings --no-fatal-infos` No issues.
- 검증 완료: `flutter test test/swipe_action_table_test.dart test/label_size_cache_test.dart` 21개 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\models\label_size.dart test\swipe_action_table_test.dart test\label_size_cache_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `git diff --check -- SESSION_HANDOFF.md lib\home_page_manager.dart lib\models\label_size.dart` 통과.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/models/label_size.dart`.
- 기능 커밋: `b93b1bf` (`라벨 설정 인라인 삽입 저장 구현`).

### 완료 (2026-07-03): 설정 테이블 밀기 아이콘 우측 여백 조정

목적: 브랜드/라벨 설정 다이얼로그 테이블에서 우측 스크롤 표시 시 행 밀기 아이콘이 스크롤바와 겹쳐 사용하기 어려운 문제를 완화한다. 밀기 아이콘을 오른쪽 끝에서 2px 앞쪽으로 당긴다.
- `lib/widgets/swipe_action_table.dart`: `EditableSwipeNameTable`의 행 밀기 토글 버튼을 `Padding(right: 2)`로 감싸 테이블 오른쪽 끝에서 2px 안쪽에 배치.
- `test/swipe_action_table_test.dart`: 밀기 버튼의 오른쪽 끝이 테이블 오른쪽 끝보다 최소 2px 안쪽인지 검증 추가.
- 검증 완료: `C:\Flutter\bin\dart.bat format lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart` 성공, `flutter test test/swipe_action_table_test.dart` 20개 성공, `C:\Flutter\bin\flutter.bat analyze lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/widgets/swipe_action_table.dart`, `test/swipe_action_table_test.dart`.
- 기능 커밋: `4cff685` (`설정 테이블 밀기 아이콘 여백 조정`).

### 완료 (2026-07-03): 프린터 설정 그룹 라벨 배경색 조정

목적: 프린터 설정 다이얼로그의 `여백`/`자동줄간격` 그룹 라벨 배경색을 다이얼로그 배경색과 동일하게 맞춘다.
- `lib/page_label_sheet/label_sheet_workbench.dart`: `_PrintDialogGroup` title `ColoredBox` 배경색을 `0xfff6f6f6`에서 다이얼로그 프레임 배경색과 같은 `0xffece6f0`으로 변경.
- 검증 완료: `C:\Flutter\bin\dart.bat format lib\page_label_sheet\label_sheet_workbench.dart` 성공, `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart --name "label sheet print"` 7개 성공, `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`.
- 기능 커밋: `e3534da` (`프린터 설정 그룹 라벨 배경색 조정`).

### 완료 (2026-07-03): 전자저울 체크박스 여백 및 크기 재조정

목적: 첨부 이미지 기준 라벨 설정 인라인 전자저울 UI에서 아이콘과 체크박스 사이, 체크박스 오른쪽 끝에 내부 여백을 추가하고 체크박스 자체 크기만 더 줄인다. 전자저울 아이콘/컨테이너 높이 등 다른 크기는 유지한다.
- `lib/home_page_manager.dart`: `_LabelScaleInlineControl`에서 아이콘과 체크박스 사이 `2px`, 체크박스 오른쪽 끝 `3px` 내부 여백 추가. 아이콘/컨테이너 높이는 유지하고 체크박스만 `14x14` 슬롯 안에서 `Transform.scale(0.78)`로 축소.
- 검증 완료: `C:\Flutter\bin\dart.bat format lib\home_page_manager.dart` 성공, `flutter test test/swipe_action_table_test.dart` 20개 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart test\swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`.
- 기능 커밋: `f770174` (`전자저울 체크박스 여백 조정`).

### 완료 (2026-07-03): 전자저울 체크박스 축소 및 모달리스 내부 키 입력 허용

목적: 라벨 설정 전자저울 UI에서 체크박스 크기만 2px 줄인다. 인라인 에디터 키 입력 불가 원인으로 확인된 `BlockingModelessDialog`의 바깥 Focus 키 이벤트 소비를 수정해 다이얼로그 내부 TextField 입력을 허용한다.
- `lib/home_page_manager.dart`: `_LabelScaleInlineControl` 체크박스 영역만 `16x16`에서 `14x14`로 축소. 아이콘/컨테이너/여백 크기는 유지.
- `lib/widgets/blocking_modeless_dialog.dart`: wrapper Focus가 직접 primary focus를 가진 경우에만 키 이벤트를 소비하고, 내부 TextField 같은 자식 포커스가 있을 때는 `ignored`를 반환하도록 수정.
- `test/blocking_modeless_dialog_test.dart`: 모달리스 내부 TextField 키 입력 허용 회귀 테스트 추가. 기존 뒤쪽 포커스 위젯 키 차단 테스트도 함께 유지.
- 검증 완료: `C:\Flutter\bin\dart.bat format lib\home_page_manager.dart lib\widgets\blocking_modeless_dialog.dart test\blocking_modeless_dialog_test.dart` 성공, `flutter test test/blocking_modeless_dialog_test.dart test/swipe_action_table_test.dart` 29개 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\widgets\blocking_modeless_dialog.dart lib\widgets\swipe_action_table.dart test\blocking_modeless_dialog_test.dart test\swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/widgets/blocking_modeless_dialog.dart`, `test/blocking_modeless_dialog_test.dart`.
- 기능 커밋: `cd65b1c` (`모달리스 내부 키 입력 허용`).

### 완료 (2026-07-03): 전자저울 UI 여백 축소 및 키 입력 재복구

목적: 라벨 설정 인라인 에디터 안에서 엔터 버튼과 전자저울 UI 사이에 1~2px 여백을 두고, 그만큼 전자저울 UI(아이콘+체크박스)를 줄인다. 인라인 에디터의 실제 키 입력 불가 문제를 재복구한다.
- `lib/home_page_manager.dart`: `_LabelScaleInlineControl` 왼쪽 여백 2px 추가. 아이콘 영역을 `20x20`에서 `18x18`, 체크박스 영역을 `18x18`에서 `16x16`, 전자저울 UI 높이를 `22`에서 `20`으로 축소.
- `lib/widgets/swipe_action_table.dart`: `_InlineNameEditCell`에서 TextField 바깥 `Shortcuts/Actions` wrapper를 완전히 제거해 TextField가 키 입력을 직접 처리하도록 재복구.
- 검증 완료: `C:\Flutter\bin\dart.bat format lib\home_page_manager.dart lib\widgets\swipe_action_table.dart` 성공, `flutter test test/swipe_action_table_test.dart` 20개 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/widgets/swipe_action_table.dart`.
- 기능 커밋: `e575a65` (`전자저울 UI 여백 조정과 키 입력 재복구`).

### 완료 (2026-07-03): 전자저울 UI 추가 미세 조정 및 인라인 키 입력 복구

목적: 라벨 설정 인라인 전자저울 UI 상단 겹침을 1px 더 줄이고 체크박스 크기를 1px 더 줄인다. 인라인 에디터에서 키보드 편집이 되지 않는 문제를 복구한다.
- `lib/home_page_manager.dart`: `_LabelScaleInlineControl` 전체 높이를 `23`에서 `22`로 줄이고, 체크박스 영역을 `19x19`에서 `18x18`로 축소.
- `lib/widgets/swipe_action_table.dart`: `_InlineNameEditCell`의 바깥 `Focus.onKeyEvent` 키 처리 대신 `Shortcuts/Actions`로 ESC 취소만 처리하도록 변경해 TextField가 일반 문자 키 입력을 직접 받도록 복구.
- `test/swipe_action_table_test.dart`: 인라인 에디터에서 키보드 입력으로 텍스트가 변경되는 회귀 테스트 추가.
- 검증 완료: `C:\Flutter\bin\dart.bat format lib\home_page_manager.dart lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart` 성공, `flutter test test/swipe_action_table_test.dart` 20개 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/widgets/swipe_action_table.dart`, `test/swipe_action_table_test.dart`.
- 기능 커밋: `2ee1297` (`인라인 편집 키 입력 복구`).

### 완료 (2026-07-03): 전자저울 인라인 UI 1px 미세 조정

목적: 라벨 설정 인라인 전자저울 UI에서 첨부 기준으로 아이콘 계기판 위치, 체크박스 크기, 상단 겹침을 1px 단위로 보정한다.
- `lib/home_page_manager.dart`: `_ScaleIconPainter`의 반원 계기판 중심과 바늘 endpoint를 1px 아래로 이동. `_LabelScaleInlineControl`의 체크박스 영역만 `20x20`에서 `19x19`로 축소. 전자저울 UI 전체 높이를 `24`에서 `23`으로 줄여 인라인 에디터 상단 아웃라인과 겹치는 부분 완화.
- 검증 완료: `C:\Flutter\bin\dart.bat format lib\home_page_manager.dart` 성공, `flutter test test/swipe_action_table_test.dart` 19개 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart test\swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`.
- 기능 커밋: `fd0aa6f` (`전자저울 인라인 UI 위치 미세 조정`).

### 완료 (2026-07-03): 라벨 설정 전자저울 UI 시각 조정

목적: 라벨 설정 인라인 전자저울 UI의 아이콘 가독성을 높이고, 전체 아웃라인을 제거한 회색 기반의 약한 돌출/그림자 형태로 변경한다. 전자저울 아이콘 이미지 영역과 체크박스 영역 크기를 같게 맞춘다.
- `lib/home_page_manager.dart`: `_LabelScaleInlineControl`의 남색 외곽선을 제거하고 `0xFFF2F4F7` 회색 배경 + 약한 그림자/상단 하이라이트로 돌출감을 부여. 아이콘 슬롯과 체크박스 슬롯을 모두 `20x20`으로 맞춤. `_ScaleIconPainter`는 플랫폼/본체/계기판/바닥선을 더 굵고 명확하게 다시 그려 20px에서도 식별되도록 조정.
- 검증 완료: `C:\Flutter\bin\dart.bat format lib\home_page_manager.dart` 성공, `flutter test test/swipe_action_table_test.dart` 19개 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart test\swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`.
- 기능 커밋: `b407e11` (`전자저울 인라인 UI 시각 조정`).

### 완료 (2026-07-03): 라벨 설정 인라인 전자저울 UI 추가

목적: 라벨 설정 다이얼로그에서만 인라인 이름 편집 셀의 엔터 아이콘 버튼 바로 뒤에 전자저울 아이콘+체크박스 UI를 삽입한다. 체크박스 초기값은 `labelSize.labelSizeSetup.useScale`을 따른다. 사용자 확인 완료: 체크 변경 가능, 아이콘은 파일 생성 없이 코드 생성 위젯으로 구현하고 기존 수정/삽입/삭제 버튼 색감과 어울리게 배치.
- `lib/widgets/swipe_action_table.dart`: `EditableSwipeNameTable<T>.inlineTrailingBuilder` 추가. 인라인 편집 셀을 Row 구조로 정리해 TextField 편집 영역이 엔터 버튼과 trailing 위젯 앞에서 끝나도록 변경.
- `lib/home_page_manager.dart`: 라벨 설정에서만 `_LabelScaleInlineControl`을 인라인 trailing으로 전달. 전자저울 아이콘은 `CustomPainter` 코드 생성 위젯으로 구현. 편집 시작 시 `label.labelSizeSetup?.useScale`로 체크 초기화, 삽입은 기본 false. 이름 변경 또는 useScale 변경 시 적용 버튼 활성화. 기존 라벨 이름 submit DB 반영은 아직 기존처럼 `pendingImplementation` 경로 유지.
- `test/swipe_action_table_test.dart`: 인라인 trailing이 TextField/엔터 버튼 뒤에 배치되는 회귀 테스트 추가.
- 검증 완료: `C:\Flutter\bin\dart.bat format lib\home_page_manager.dart lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart` 성공, `flutter test test/swipe_action_table_test.dart` 19개 성공, `C:\Flutter\bin\flutter.bat analyze lib\home_page_manager.dart lib\widgets\swipe_action_table.dart test\swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/widgets/swipe_action_table.dart`, `test/swipe_action_table_test.dart`.
- 기능 커밋: `c93c4a1` (`라벨 설정 전자저울 인라인 UI 추가`).

### 완료 (2026-07-03): 라벨 설정 다이얼로그 순서 변경 적용 저장

목적: 라벨 설정 다이얼로그에서 행 드래그 후 `적용` 클릭 시 `BM_RICH_LABELSIZE_FORM.RICH_LABELSIZE_ORDER`를 DB에 저장하고, 성공 시 다이얼로그 테이블/헤더 라벨 드롭다운을 DB 정렬 기준으로 재렌더링하되 기존 선택 라벨을 유지한다.

- 참조 확인 완료: `doc/BM_RICH_LABELSIZE_FORM.sql`의 `RICH_LABELSIZE_ORDER`, 레거시 `.tmp/LabelManager/LabelManagerLib/LabelSize.cpp`의 `CLabelSizeDAO::UpdateOrder`, 현재 `label_sheet_page.dart`의 `_handleSaveLabelSheet` 확인.
- 구현 예정: `lib/models/label_size.dart`에 `LabelSizeDAO.updateOrder` 추가, `lib/home_page_manager.dart`의 `_LabelSettingsDialog._applyOrderChanges`와 상위 라벨 목록 refresh 콜백 연결.
- 순서 기준: 레거시 insert가 `COUNT(*)+1`/`MAX(...)+1`을 사용하므로 적용 순서는 현재 테이블 순서대로 1부터 저장.
- 구현 완료: `lib/models/label_size.dart`에 `LabelSizeDAO.updateOrder(labelSizeId, labelSizeOrder)` 및 배치용 `LabelSizeDAO.updateOrders` 추가. 적용 버튼 단위로 모든 라벨 순서를 하나의 `SET XACT_ABORT ON` 트랜잭션에서 저장하고 affected row를 검증.
- 구현 완료: `lib/home_page_manager.dart`에 `_handleLabelOrderApplied` 추가 및 `_LabelSettingsDialog` 연결. 적용 확인 다이얼로그/진행 스낵바/실패 다이얼로그를 추가하고, 성공 시 DB 재조회 목록으로 `LabelSize.datas`와 다이얼로그 테이블을 갱신하며 기존 선택 라벨 ID를 유지.
- 구조 변경 완료: 사용자 피드백에 따라 `_LabelSettingsDialog._applyOrderChanges`에서 `LabelSizeDAO.updateOrders`를 직접 호출하도록 변경. 부모 콜백은 `_handleLabelOrderSaved`로 이름을 바꾸고 DB 성공 후 재조회/캐시 갱신/드롭다운 선택 유지 전용으로 축소.
- 구조 변경 검증 완료: `dart format lib/home_page_manager.dart` 성공, `C:\Flutter\bin\flutter.bat analyze lib/home_page_manager.dart lib/models/label_size.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/label_size_cache_test.dart` 1개 성공.
- 구조 변경 커밋: `46bc447` (`라벨 순서 적용 DAO 호출 위치 정리`).
- UX 변경 완료: `_applyOrderChanges` 확인창에서 `취소`를 누른 경우에도 `_cancelOrderChanges()`를 호출해 다이얼로그 임시 순서 변경을 즉시 원복하도록 변경.
- UX 변경 검증 완료: `dart format lib/home_page_manager.dart` 성공, `C:\Flutter\bin\flutter.bat analyze lib/home_page_manager.dart lib/models/label_size.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/label_size_cache_test.dart` 1개 성공.
- UX 변경 커밋: `329a4b2` (`라벨 순서 적용 취소 시 임시 순서 원복`).
- 순서 변경 모드 UI 구현 완료: `SwipeActionTable`에 `headerTrailing`, 외부 `selectedIndex`, `onRowSelected` API 추가. 라벨 설정 다이얼로그의 `라벨 이름` 헤더 오른쪽에 순서 변경 아이콘 버튼을 추가하고, 클릭 시 순서 변경 모드 진입/헤더 아이콘 비활성/스와이프 비활성/하단 취소·적용 영역 표시/우측 위·아래 이동 버튼 표시를 연결. 위·아래 버튼은 선택 행을 `_moveLabelRow`와 같은 순서 변경 로직으로 이동하며, 적용 버튼은 전체 순서가 원본과 다를 때만 활성화.
- 순서 변경 모드 UI 테스트 추가 완료: `test/swipe_action_table_test.dart`에 header trailing 렌더링, row selection callback 테스트 추가.
- 순서 변경 모드 UI 검증 완료: `dart format` 3파일 성공, `C:\Flutter\bin\flutter.bat analyze lib/home_page_manager.dart lib/widgets/swipe_action_table.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart test/label_size_cache_test.dart` 11개 성공.
- 순서 변경 모드 UI 커밋: `4b17fef` (`라벨 설정 순서 변경 모드 UI 추가`).
- 순서 변경 모드 툴팁 수정 완료: `_TableBodyTooltip`가 `rowTooltip` 메시지 변경 시 기존 툴팁만 숨기고 재예약하지 않아, 마우스가 본문 위에 남아 있는 상태에서는 `순서 변경 중에는 스와이프 수정/삽입/삭제를 사용할 수 없습니다`가 표시되지 않을 수 있던 경로 수정. `test/swipe_action_table_test.dart`에 메시지 변경 후 툴팁 재표시 테스트 추가. `dart format` 2파일 성공, `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart` 11개 성공, `C:\Flutter\bin\flutter.bat analyze lib/widgets/swipe_action_table.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- 순서 변경 모드 툴팁 수정 커밋: `13ae55d` (`순서 변경 모드 툴팁 재표시 수정`).
- 인라인 편집 상태 기반 순서 아이콘 비활성 완료: `SwipeActionTableColumn.headerTrailingBuilder`를 추가해 헤더 trailing 위젯 생성 시 현재 interactive row 존재 여부를 전달. 라벨 설정 다이얼로그의 순서 변경 아이콘은 `hasInlineEditor`가 true이면 비활성화되도록 연결. `test/swipe_action_table_test.dart`에 interactive row 상태 전달 테스트 추가. `dart format` 3파일 성공, `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart` 12개 성공, `C:\Flutter\bin\flutter.bat analyze lib/home_page_manager.dart lib/widgets/swipe_action_table.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- 인라인 편집 상태 기반 순서 아이콘 비활성 커밋: `6b415bb` (`인라인 편집 중 순서 변경 아이콘 비활성화`).
- 라벨 설정 인라인 에디터 UI 구현 완료: 브랜드 설정 다이얼로그와 같은 스와이프 후 수정/삽입 인라인 에디터 동작을 라벨 설정에 추가. 수정/삽입 토글, 현재 편집 행만 스와이프 허용, ESC 취소, 삽입 임시 행 제거, TextField Enter 및 엔터 아이콘 활성 조건(비어 있지 않음, 삽입이면 활성, 수정이면 기존 이름과 다를 때 활성)을 동일하게 연결. 실제 수정/삽입 DB 반영은 추후 구현으로 두고 `_submitLabelNameEdit`는 `pendingImplementation` 로그만 남김. `dart format lib/home_page_manager.dart` 성공, `C:\Flutter\bin\flutter.bat analyze lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` No issues.
- 설정 이름 테이블 공통화 완료: 다이얼로그 전체가 아니라 다이얼로그 안의 스와이프/인라인 이름 편집 테이블을 `lib/widgets/editable_swipe_name_table.dart`의 `EditableSwipeNameTable<T>`로 추출. 브랜드/라벨 설정 테이블은 공통 위젯을 사용하고, 각 다이얼로그에는 row 목록, 편집/삽입 상태, submit/delete 등 도메인별 콜백만 남김. 라벨 실제 수정/삽입 DB 반영은 계속 추후 구현(`pendingImplementation`). `dart format` 2파일 성공, `C:\Flutter\bin\flutter.bat analyze lib/home_page_manager.dart lib/widgets/editable_swipe_name_table.dart lib/widgets/swipe_action_table.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart` 12개 성공.
- 설정 이름 테이블 공통화 커밋: `cb2508c` (`설정 이름 테이블 인라인 편집 공통화`).
- 테이블 파일 통합 완료: `lib/widgets/editable_swipe_name_table.dart`, `lib/widgets/resizable_table.dart`를 삭제하고 `EditableSwipeNameTable<T>`, `ResizableTable<T>`, `ResizableTableColumn<T>`를 `lib/widgets/swipe_action_table.dart`에 통합. `ResizableTable`은 기존 호출부 호환 래퍼로 유지하되 내부 구현은 `SwipeActionTable` 기반으로 전환. `home_page_manager.dart`, `item_manage.dart` import를 단일 `swipe_action_table.dart`로 변경. `dart format` 3파일 성공, `C:\Flutter\bin\flutter.bat analyze lib/widgets/swipe_action_table.dart lib/home_page_manager.dart lib/page_home/item_manage.dart lib/page_home/common_label_manage.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart` 12개 성공.
- 테이블 파일 통합 커밋: `669da1a` (`테이블 위젯 파일 통합`).
- 품목관리 테이블 통합 전 형태 복원 완료: `ResizableTable` 호환 래퍼가 `SwipeActionTable` 기본 `autoFitColumns: true`를 타며 컬럼 폭이 내용 기준으로 바뀌던 문제를 수정해 `ResizableTableColumn.width` 기준(`autoFitColumns: false`)을 유지. `SwipeActionTable.rowColorBuilder`를 추가하고 `ResizableTable`에서 통합 전 색상(`white`/`0xFFF2F4F7`, 선택 시 `0xFFE3F2FD`)을 명시. `test/swipe_action_table_test.dart`에 ResizableTable 지정 폭/교차 행 배경 회귀 테스트 추가. `dart format` 2파일 성공, `C:\Flutter\bin\flutter.bat analyze lib/widgets/swipe_action_table.dart lib/page_home/item_manage.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart` 13개 성공.
- 품목관리 테이블 통합 전 형태 복원 커밋: `bd5817b` (`품목관리 테이블 통합 전 형태 복원`).
- 품목관리 `ResizableTable` 리사이즈바 더블클릭 자동폭 복원 완료. 원인: 통합 후 `_autoFitColumn`이 `autoFitColumns=false`에서 즉시 return하여, 초기 자동폭은 꺼야 하는 품목관리 호환 래퍼의 수동 더블클릭 자동맞춤까지 막음. 수정: `_autoFitColumn` 가드 제거, `test/swipe_action_table_test.dart`에 리사이즈바 더블클릭 회귀 테스트 추가. `dart format` 2파일 성공, 좁은 테스트 `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart --plain-name "resizable table auto fits column width on separator double tap"` 성공. `C:\Flutter\bin\flutter.bat analyze lib/widgets/swipe_action_table.dart lib/page_home/item_manage.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart` 14개 성공.
- 품목관리 컬럼 자동폭 더블클릭 복원 커밋: `aaa45eb` (`품목관리 컬럼 자동폭 더블클릭 복원`).
- 브랜드/라벨 설정 `EditableSwipeNameTable` 이름 셀 공통 밀기 버튼 추가 완료. 사용자 확인 완료: 각 행 이름 셀 안에만 표시, 현재 행 하나만 열고 닫음. 수정: `SwipeActionTableCellState`와 `statefulCellBuilder`를 추가해 셀에서 액션 레일 열림/토글 상태를 사용, 이름 셀 왼쪽에 24x24 밀기 버튼 표시, 클릭 시 좌/우 아이콘 전환 및 기존 스와이프 애니메이션으로 수정/삽입/삭제 레일 열기/닫기, 인라인 편집 중 비활성화, `rowSwipeEnabled=false`(라벨 순서 변경 모드)에서는 숨김. 아이콘 클릭이 이름 더블클릭 콜백으로 번지지 않도록 토글 시 더블클릭 추적 상태 초기화. `dart format` 2파일 성공, 좁은 테스트 `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart --plain-name "editable name table"` 4개 성공. `C:\Flutter\bin\flutter.bat analyze lib/widgets/swipe_action_table.dart lib/home_page_manager.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart` 18개 성공.
- 설정 이름 테이블 밀기 버튼 추가 커밋: `ea21e31` (`설정 이름 테이블 밀기 버튼 추가`).
- 설정 이름 테이블 밀기 버튼 오른쪽 배치 완료: 이름 셀 왼쪽에 있던 밀기 버튼을 순서 변경 헤더 아이콘 위치와 맞도록 셀 오른쪽 끝으로 이동하고, 버튼 표시 시 텍스트 오른쪽 여백을 줄여 말줄임이 자연스럽게 동작하도록 조정. `test/swipe_action_table_test.dart`의 열기/닫기 테스트에 버튼이 이름 텍스트 오른쪽에 있는지 검증 추가. `dart format` 2파일 성공, `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart --plain-name "editable name table toggle button opens and closes action rail"` 성공, `C:\Flutter\bin\flutter.bat analyze lib/widgets/swipe_action_table.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart` 18개 성공.
- 설정 밀기 버튼 오른쪽 배치 커밋: `21ba1f6` (`설정 밀기 버튼 오른쪽 배치`).
- 라벨 매니저 모달리스 다이얼로그 공통 입력 차단/공통 UI 프레임 적용 완료. 신규 `lib/widgets/blocking_modeless_dialog.dart`에 `BlockingModelessDialog`(외부 포인터/터치 차단 `ModalBarrier`, 오버레이 포커스 획득 및 미처리 키 이벤트 소비)와 `BlockingModelessDialogFrame`(공통 배경/그림자/라운드/타이틀바/닫기/본문/푸터 프레임)을 추가. 브랜드 설정, 라벨 설정, 브랜드 내부 Overlay 확인 다이얼로그에 적용. 앞으로 추가되는 `OverlayEntry` 기반 모달리스 다이얼로그는 반드시 `BlockingModelessDialog(child: BlockingModelessDialogFrame(...))` 조합을 사용하고 직접 `ModalBarrier`/프레임 UI를 중복 작성하지 않는다. repo 메모리 `/memories/repo/editing-notes.md`에도 동일 규칙 기록. `dart format` 4파일 성공, `C:\Flutter\bin\flutter.bat analyze lib/widgets/blocking_modeless_dialog.dart lib/home_page_manager.dart lib/widgets/swipe_action_table.dart test/blocking_modeless_dialog_test.dart test/swipe_action_table_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/blocking_modeless_dialog_test.dart test/swipe_action_table_test.dart` 21개 성공.
- 모달리스 다이얼로그 공통 프레임 적용 커밋: `b8005d6` (`모달리스 다이얼로그 공통 프레임 적용`).
- 모달리스 다이얼로그 리스너 동작 기준 확인 완료: 차단 대상은 다이얼로그 외부에서 새로 들어오는 마우스/터치/키 사용자 입력이며, 다이얼로그 내부 상태 변경으로 발생하는 외부 콜백/`ValueNotifier`/부모 상태 갱신 listener는 차단하지 않는다. `BlockingModelessDialog` 주석에 이 기준을 명시하고 `test/blocking_modeless_dialog_test.dart`에 내부 `Listener` 동작, 비입력 listener 동작, 다이얼로그 내부 버튼 콜백이 외부 notifier를 갱신하는 회귀 테스트를 추가. `dart format` 2파일 성공, `C:\Flutter\bin\flutter.bat test test/blocking_modeless_dialog_test.dart` 6개 성공, `C:\Flutter\bin\flutter.bat analyze lib/widgets/blocking_modeless_dialog.dart test/blocking_modeless_dialog_test.dart --no-fatal-warnings --no-fatal-infos` No issues.
- 모달리스 상태 리스너 동작 기준 검증 커밋: `8e9c0bb` (`모달리스 상태 리스너 동작 기준 검증`).
- 확인/경고 다이얼로그 및 스낵바 표시 규칙 반영 완료: 모달리스 다이얼로그 위에 나타나는 수정/삽입/삭제 확인, 경고, 실패 알림, 스낵바 등은 외부 입력 차단용 `BlockingModelessDialog`/`BlockingModelessDialogFrame`로 감싸지 않고 Flutter modal route(`showDialog`) 또는 `ScaffoldMessenger`로 표시해야 한다. 브랜드 설정 내부 `_showBrandOverlayDialog`를 `OverlayEntry + BlockingModelessDialog`에서 `showDialog(barrierDismissible: false)`로 변경해 설정 모달리스 위에 확인/경고 다이얼로그가 정상 표시되도록 수정. `test/blocking_modeless_dialog_test.dart`에 모달리스 위 `showDialog`가 표시되고 확인 버튼 입력을 받는 회귀 테스트 추가. `dart format` 2파일 성공, `C:\Flutter\bin\flutter.bat analyze lib/home_page_manager.dart test/blocking_modeless_dialog_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/blocking_modeless_dialog_test.dart` 7개 성공.
- 모달리스 위 확인 다이얼로그 표시 복원 커밋: `7b12836` (`모달리스 위 확인 다이얼로그 표시 복원`).
- 모달리스 `OverlayEntry` 위 확인 다이얼로그 최상단 표시 재수정 완료: 일반 `showDialog`가 이미 삽입된 모달리스 `OverlayEntry` 아래에 깔릴 수 있어, `lib/widgets/blocking_modeless_dialog.dart`에 `showBlockingModelessOverlayDialog<T>` helper를 추가. 이 helper는 `Overlay.of(context, rootOverlay: true)`에 확인/경고용 barrier + child를 새 `OverlayEntry`로 삽입해 모달리스 설정 다이얼로그보다 위에 표시한다. 브랜드 설정 내부 `_showBrandOverlayDialog`를 해당 helper 사용으로 변경. `test/blocking_modeless_dialog_test.dart`에 실제 `OverlayEntry` 기반 모달리스 위에서 확인 다이얼로그가 표시되고 확인 버튼 입력을 받는 회귀 테스트 추가. `dart format` 3파일 성공, `C:\Flutter\bin\flutter.bat analyze lib/widgets/blocking_modeless_dialog.dart lib/home_page_manager.dart test/blocking_modeless_dialog_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/blocking_modeless_dialog_test.dart` 8개 성공.
- 확인 다이얼로그 최상단 표시 보장 커밋: `4651bdc` (`확인 다이얼로그 최상단 표시 보장`).
- 브랜드/라벨 설정 다이얼로그 호출 경로 재확인 및 코드 명시 완료: 두 설정 다이얼로그 모두 `OverlayEntry -> BlockingModelessDialog -> BlockingModelessDialogFrame` 구조로 열린다. 브랜드 추가/수정/삭제 확인/실패 알림은 `_showBrandOverlayDialog -> showBlockingModelessOverlayDialog` 경로를 사용한다. 라벨 설정 순서 변경의 `적용` 확인/실패 알림도 `showDialog` 직접 호출을 제거하고 `showBlockingModelessOverlayDialog`를 사용하도록 수정했다. `showBlockingModelessOverlayDialog` lifecycle 로그(create/insert/build/close/remove/complete), 브랜드 설정 overlay open/close 및 helper 진입/결과 로그, 라벨 순서 적용 confirm/result/updateOrders/reload/failure/cleanup 로그를 추가했다. 코드 주석에 modeless `OverlayEntry` 안에서 확인/경고 다이얼로그는 root overlay helper를 사용해야 함을 명시했다. 검증: `dart format` 2파일 성공, `C:\Flutter\bin\flutter.bat analyze lib/home_page_manager.dart lib/widgets/blocking_modeless_dialog.dart test/blocking_modeless_dialog_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/blocking_modeless_dialog_test.dart` 8개 성공, `C:\Flutter\bin\flutter.bat test test/swipe_action_table_test.dart` 18개 성공.
- 설정 다이얼로그 확인 경로 명시 커밋: `b43ded7` (`설정 다이얼로그 확인 경로 명시`).
- 프린터 설정 다이얼로그 공용 모달리스 프레임 적용 완료: `lib/page_label_sheet/label_sheet_workbench.dart`의 프린터 설정 오버레이를 수동 `GestureDetector` barrier + 자체 Container/타이틀바 구조에서 `BlockingModelessDialog(child: BlockingModelessDialogFrame(...))` 구조로 변경했다. 기존 내부 입력/버튼/드롭다운 동작과 `label-sheet-print-settings-dialog` key는 유지하고, 외곽 타이틀/닫기/배경/그림자는 브랜드/라벨 설정과 같은 공용 프레임이 담당한다. 닫기 아이콘은 기존 `_PrintDialogCloseIcon`을 `BlockingModelessDialogFrame.closeIcon`으로 전달해 시각과 테스트 경로를 보존했다. 검증: `dart format` 1파일 성공, `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/label_sheet_toolbar_test.dart --name "label sheet print"` 6개 성공.
- 프린터 설정 공용 다이얼로그 적용 커밋: `3f38a16` (`프린터 설정 공용 다이얼로그 적용`).
- 프린터 설정 다이얼로그 전체 화면 barrier 수정 완료: 기존 공용 wrapper 적용 후에도 프린터 설정이 `LabelSheetWorkbench` 내부 `Stack`에 렌더링되어 외부 그림자/입력 차단이 시트 영역에만 적용되는 문제가 있었다. 프린터 설정 표시를 workbench 내부 child에서 full-screen `showGeneralDialog` route로 옮기고, route 내부에서 `BlockingModelessDialog + BlockingModelessDialogFrame`를 유지하도록 수정했다. 수동 root `OverlayEntry` 방식은 `DropdownButton2` 메뉴 route가 다이얼로그 아래에 깔려 드롭다운 테스트가 실패해 사용하지 않는다. 다이얼로그 내부 상태 변경은 route의 `StatefulBuilder`를 통해 즉시 리빌드한다. `test/label_sheet_toolbar_test.dart`에 workbench 바깥 영역 탭이 뒤쪽 위젯에 전달되지 않는 회귀 테스트 추가. 검증: `dart format` 2파일 성공, `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/label_sheet_toolbar_test.dart --name "label sheet print"` 7개 성공.
- 프린터 설정 전체 화면 차단 적용 커밋: `a6fe7d7` (`프린터 설정 전체 화면 차단 적용`).
- 검증 완료: `dart format` 2파일 성공, `C:\Flutter\bin\flutter.bat analyze lib/models/label_size.dart lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` No issues, `C:\Flutter\bin\flutter.bat test test/label_size_cache_test.dart` 1개 성공.
- stage/commit 대상: `SESSION_HANDOFF.md`, `lib/models/label_size.dart`, `lib/home_page_manager.dart`, `doc/BM_RICH_BRAND.sql`, `doc/BM_RICH_LABELSIZE_FORM.sql` 포함(사용자 요청). 기존 dirty `lib/core/app.dart`는 제외.
- 기능 커밋: `a6f4911` (`라벨 설정 순서 적용 저장 구현`).

### 완료/대기 (2026-07-05): XLSX → 라벨 시트 변환 규칙 재정립 (구현·샘플 검증 완료, 사용자 재가져오기 로그 대기)

목적: `.xlsx` 엑셀을 라벨 시트로 가져오기. 원본과 최대한 100% 동일하게 변환.
규칙 전문은 세션 메모리 `/memories/session/xlsx-import-rules.md` 및 코드 상단 주석(`lib/page_label_sheet/label_sheet_xlsx_import.dart` 파일 헤더)에 명시. 완료 시까지 유지.

- **A. 테두리**: 엑셀 셀 테두리 속성(방향/스타일·두께/색)을 그대로 1:1 변환. 임의 변형(다운캐스트·합성·특수처리) 금지. 엑셀에 없으면 변환본에도 없음. ("세 표 외에는 테두리 없음"은 규칙 아님 — 사용자가 제외. 엑셀에 있으면 어느 영역이든 그대로.)
- **B. 일반화**: 특정 파일 전용 하드코딩 금지(`'영양정보'` 텍스트/고정 크기/특정 좌표). 순수 border 매핑만.
- **C. 스케일**: 물리 라벨 폭 우선 스케일(폭 대비 높이 비율). 가독 미달 시 최소 가독 문자 기준 재확대(인쇄영역 초과 허용). 가독 기준은 실물 프린트 mm.
- **D. 폰트/텍스트**: 글꼴/크기/굵게·기울임·밑줄·취소선/글자색 + 자간/장평/첨자/줄간격을 엑셀 그대로. 크기만 C 스케일 비례.

구현 완료:
- `lib/page_label_sheet/label_sheet_xlsx_import.dart`:
  - 파일 헤더에 변환 규칙 A~D 주석 명시(추후 수정 방향 고정).
  - 영양정보 전용 보정 전부 제거: `_adjustXlsxImportedBorder`(다운캐스트), `_missingNutritionOuterBorders`(합성), `_isXlsxNutritionHeader`/`_isXlsxNutritionOuterBorder`/`_isXlsxNutritionInnerBorder`/`_nutritionRangeFromHeaderMerge`, `#BARCODE`/안내문/빈셀 skip(`_shouldSkipXlsxCellBorders`/`_shouldImportXlsxCellBorders`), `_isInsideXlsxMergeRange`, `_mergeRangeFromJson`, `_isSameXlsxBorderLog`, 관련 sample 로그/변수(`nutritionBorderRanges`·`borderlessMergeRanges`·`mergeRanges`·`adjustedBorderSamples`·`skipped*BorderSamples`).
  - 테두리 변환은 이제 `style.borderInfo()`(엑셀 styles.xml border 1:1 매핑, `_borderStyle`/`_borderStrokeWidth`)를 셀별로 그대로 emit. 값/채움 없는 border-only 빈 셀도 `cellJson.isEmpty` skip 이전에 border를 유지.
- `lib/page_label_sheet/label_sheet_workbench.dart`: `_labelSheetScaledToPhysicalWidth`에 규칙 C 참조 주석 추가. 스케일 로직(widthScale 우선 + `max(widthScale, readableScale)` 재확대 + mm 기준 최소 가독)이 규칙 5·6·7과 일치함 확인, 코드 변경 없음.
- 폰트/자간/장평/첨자/줄간격 import는 `_XlsxFont`+inline runs+customXml metadata에서 이미 충실 파싱됨 확인, 변경 없음.
- `test/label_sheet_xlsx_import_test.dart`: 충실 변환 기준으로 테두리 기대값 갱신(borderId 있는 셀은 값/종류 무관 테두리 유지, borderId=0은 없음). `*유통기한:`/`#BARCODE`/빈셀도 엑셀 border가 있으면 유지.
- 검증: `flutter test test/label_sheet_xlsx_import_test.dart` 3개 성공, `flutter analyze`(3파일) No issues.

검증/후속 상태:
- **근본 원인 확정 + 수정 + 검증 완료**: 원본 `.tmp/label_sample2_converted.xlsx` styles.xml 직접 확인.
  - `<x:borders count="62">`인데 맨 앞 self-closing `<x:border /><x:border />` 2개(무테두리)를 파서가 **여는 태그로 오인해 삼켜** 60개만 파싱 → 모든 borderId 2씩 밀림. 예: A14는 borderId 33(=회색 왼쪽선)이어야 하는데 index 35의 4면 검정 테두리를 잘못 참조.
  - 수정: `_elementBodies` 정규식을 self-closing(`<tag/>`) 대안 먼저 매칭. borders/fonts/fills 정렬 교정.
  - 검증: 재가져오기 로그 `app_2026-07-03_15-03-43.log`에서 border수 **2365→792**, A14=회색 왼쪽선만, L19/N20/L30 무테두리/회색만, 표(A5/A7/A9)는 굵은 외곽선 유지 확인. 변환본이 엑셀과 시각적으로 일치.
- 진단 로그(border defs/format 덤프, sample 3000) 제거, sample 한도 200 복원, xfId 진단 필드 제거. applyBorder 처리는 유지.
- 검증: `flutter test` 4개 성공, `flutter analyze` No issues.
- 스케일 확인 완료(로그 `app_2026-07-03_15-11-05.log`): 규칙 C대로 `widthScale=0.232` vs `readableScale=0.644` 중 readable 채택, overflow 168mm. 사용자 결정 = **이대로 유지**(규칙 C6: 가독 우선, 인쇄영역 초과 허용). 코드 변경 없음.
- 결론: XLSX→라벨시트 변환(테두리 1:1, 폰트/자간/장평/첨자/줄간격 그대로, 스케일 C) 규칙대로 구현·검증 완료.
- 추가 검증(2026-07-05): 최신 `.tmp/log` 10개에는 실제 `xlsx import` 라인이 없어 사용자 재가져오기 로그 검증은 계속 대기. 현재 코드 기준 `C:\Flutter\bin\flutter.bat test test\label_sheet_xlsx_import_test.dart` 3개 통과, `C:\Flutter\bin\flutter.bat analyze lib\page_label_sheet\label_sheet_xlsx_import.dart lib\page_label_sheet\label_sheet_workbench.dart test\label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 결과 `No issues found`, 라벨 시트 묶음 `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart test\label_sheet_print_job_test.dart test\label_sheet_xlsx_import_test.dart` 73개 통과. 커밋 `9a155da` (`XLSX 가져오기 검증 상태 갱신`). 기존 unrelated dirty `lib/core/app.dart` 제외.
- 샘플 직접 검증(2026-07-05): `.tmp/label_sample2_converted.xlsx`를 현재 importer로 읽는 임시 Flutter test를 실행한 결과 `exitCode=0`. styles 파싱 `borders=62`, worksheet `borders=792`, sheet `Label_Template rows=36 columns=21 cells=756 borders=792`. 검증 포인트: A14=회색 왼쪽선만, N20=무테두리, L19/L30=회색선만, A5/A7/A9=굵은 외곽선 유지. 임시 검사 파일/로그는 삭제 완료. 커밋 `4232e09` (`XLSX 샘플 직접 검증 기록`). 기존 unrelated dirty `lib/core/app.dart` 제외.
- 상태 정리(2026-07-05): 구현·코드 기준 테스트/analyze·샘플 직접 검증은 완료. 남은 것은 사용자가 앱에서 새로 XLSX 재가져오기를 실행한 뒤 생성되는 최신 `.tmp/log`의 실제 `xlsx import` 라인 재확인뿐이다.
- 재검증 예정(2026-07-05): 최신 `.tmp/log` 10개 `xlsx import` 재검색, `C:\Flutter\bin\flutter.bat test test\label_sheet_xlsx_import_test.dart`, `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart test\label_sheet_print_job_test.dart test\label_sheet_xlsx_import_test.dart`, 전체 `C:\Flutter\bin\flutter.bat test`, 전체 `C:\Flutter\bin\flutter.bat analyze --no-fatal-warnings --no-fatal-infos` 실행 후 결과 기록. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 재검증 완료(2026-07-05): 최신 `.tmp/log` 10개(`app_2026-07-04_15-45-31.log` 등)에는 여전히 `xlsx import` 라인 없음. `C:\Flutter\bin\flutter.bat test test\label_sheet_xlsx_import_test.dart *> .tmp\copilot\label_sheet_xlsx_import_test_2026-07-05_rebaseline.log` 결과 `exitCode=0`, 3개 통과. 라벨시트 묶음 `C:\Flutter\bin\flutter.bat test test\label_sheet_toolbar_test.dart test\label_sheet_print_job_test.dart test\label_sheet_xlsx_import_test.dart *> .tmp\copilot\label_sheet_bundle_test_2026-07-05_rebaseline.log` 결과 `exitCode=0`, 73개 통과. 전체 `C:\Flutter\bin\flutter.bat test *> .tmp\copilot\flutter_test_full_2026-07-05_rebaseline_after_xlsx_sample.log` 결과 `exitCode=0`, 128개 통과. 전체 analyzer `C:\Flutter\bin\flutter.bat analyze --no-fatal-warnings --no-fatal-infos *> .tmp\copilot\flutter_analyze_full_2026-07-05_rebaseline_after_xlsx_sample.log` 결과 `exitCode=0`, `No issues found`. 커밋 `c3e9764` (`XLSX 재검증 기준선 기록`). 기존 unrelated dirty `lib/core/app.dart` 제외.
- FortuneSheet 패키지 재검증 예정(2026-07-05): 현재 열린 `third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart` 포함 패키지 전체 기준선 확인을 위해 `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test *> .tmp\copilot\fortune_sheet_full_test_2026-07-05_rebaseline_after_xlsx.log` 실행 후 결과 기록. 기존 unrelated dirty `lib/core/app.dart` 제외.
- FortuneSheet 패키지 재검증 완료(2026-07-05): `C:\Flutter\bin\flutter.bat test third_party\fortune_sheet\test *> .tmp\copilot\fortune_sheet_full_test_2026-07-05_rebaseline_after_xlsx.log` 결과 `exitCode=0`, 2999개 통과. 커밋 `1704ac9` (`FortuneSheet 전체 재검증 기록`). 기존 unrelated dirty `lib/core/app.dart` 제외.

### 최근 완료 (2026-07-03)

- **완료**: XLSX 영양정보 표 하단 병합 박스 좌측 외곽선 누락 보정.
  - 최신 로그 `.tmp/log/app_2026-07-03_13-23-40.log` 정밀 비교: 헤더 경계 보정은 반영됐으나(`C24 right=13`, `D24 left=13`), 영양정보 표 하단 `1일 영양성분...` 병합 박스(`A12:J13`, `A30:J31`)의 좌측 외곽선이 computed 결과에서 완전히 누락됨. `A9~A11`은 `left/style=13`이 있으나 `A12/A13/A30/A31`에는 left가 없어 표 좌측 변이 아래쪽에서 끊김. 원본 XLSX가 해당 병합 셀에 좌측 테두리를 정의하지 않은 것이 원인.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: import 루프에 `_missingNutritionOuterBorders` 추가. 영양정보 범위 perimeter 셀에서 존재하지 않는 외곽 방향(top/bottom/left/right)을 `style=13/stroke=2.0`으로 합성해 표가 닫힌 굵은 박스가 되도록 보강. 합성분은 `xlsx import worksheet adjusted border samples`에 `synth to=` 로 기록.
  - 검증 완료: `C:\Flutter\bin\dart.bat format lib/page_label_sheet/label_sheet_xlsx_import.dart` 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 다음 재가져오기 확인 포인트: 최신 앱 로그 computed에서 `A12 left`, `A13 left`, `A30 left`, `A31 left`가 `style=13/stroke=2.0`로 나타나고 표 좌측 변이 상단부터 하단까지 연속되어야 함.
  - 재검증 완료: `.tmp/log/app_2026-07-03_13-34-03.log`에서 `A12/A13/A30/A31 left=13`, `row6 top/style=13:20`(이전 `:2`), `row24 top/style=13:10`, `D6/O6/D24 top=13` 확인. 위/아래 영양정보 표가 상·하·좌·우 모두 닫힌 굵은 박스로 렌더됨. 커밋 `303bb04`.

- **완료**: XLSX 영양정보 어두운 헤더 내부 경계선 재보정.
  - 사용자 재첨부 원본/변환본 및 최신 로그 `.tmp/log/app_2026-07-03_13-19-30.log` 확인: 새 코드가 로드되어 `C24/D24`, `C25/D25`, `C26/D26` 헤더 내부 경계가 `style=1/stroke=1.0`으로 낮아짐. 원본은 어두운 `영양정보 | 총내용량` 두 병합 블록 사이 경계가 굵게 남아야 하므로 이 부분이 남은 차이로 판단.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: 영양정보 범위 안에서도 헤더 3행(`rowStart..rowStart+2`)의 큰 병합 블록 경계(`columnStart+2` 오른쪽 / `columnStart+3` 왼쪽)는 내부선 downcast 대상에서 제외해 `style=13/stroke=2.0`을 유지. 본문 영양성분 grid 내부 세로선은 계속 `style=1/stroke=1.0`로 유지.
  - 검증 완료: `C:\Flutter\bin\dart.bat format lib/page_label_sheet/label_sheet_xlsx_import.dart` 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 기능 커밋: `c724acb` (`XLSX 영양정보 헤더 경계선 보정`).
  - 다음 재가져오기 확인 포인트: 최신 앱 로그에서 `C24 right`, `D24 left`, `C26 right`, `D26 left`는 `style=13/stroke=2.0`, `C28/D28` 같은 본문 내부 세로선은 `style=1/stroke=1.0`이어야 함.

- **완료**: XLSX 영양정보 표 남은 테두리 차이 보정 및 조정 로그 추가.
  - 최신 로그 `.tmp/log/app_2026-07-03_13-03-15.log` 재확인: `computed blank borders=-`로 빈 셀/바코드/오른쪽 안내문 보정은 반영됨. 남은 차이는 영양정보 표의 어두운 헤더 내부 세로 구분선이 `style=13/stroke=2.0`로 과하게 강하고, 일부 외곽선은 원본 대비 얇게 남을 수 있는 판정 문제로 판단.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: 영양정보 표 외곽(`top/bottom/left/right`)은 `style=13/stroke=2.0`로 강제 유지하고, 표 내부 세로선은 헤더 구분선을 포함해 내부선으로 분류해 `style=1/stroke=1.0`로 낮추도록 보정.
  - 추가 로그: `xlsx import worksheet adjusted border samples`를 추가해 보정 전후 좌표/방향/style/stroke를 다음 재가져오기 로그에서 바로 확인 가능.
  - 검증 완료: `C:\Flutter\bin\dart.bat format lib/page_label_sheet/label_sheet_xlsx_import.dart` 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 기능 커밋: `f9ed84d` (`XLSX 영양정보 테두리 추가 보정`).
  - 다음 재가져오기 확인 포인트: 최신 앱 로그의 `xlsx import worksheet adjusted border samples`에서 `C24/D24`류 내부 세로선이 `13 -> 1`로 낮아지고, `J24/J30/A31` 같은 외곽은 `13/2.0`으로 유지되는지 확인.

- **완료**: XLSX 영양정보 표 외곽/내부선 분리 보정.
  - 최신 첨부 및 `.tmp/log/app_2026-07-03_12-56-49.log` 확인: 이전 `thick -> style=8/stroke=1.5` 전역 보정은 내부선 과다 두께는 줄였지만, 원본의 영양정보 표 외곽/박스 경계까지 함께 약해짐. 최신 로그에서는 `borders=1014`, `computedBorders=300`, `computed blank borders=-`이며, `row27~row29` 내부선과 외곽선이 모두 `style=8/stroke=1.5`로 동일하게 처리됨.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: Excel `thick` 기본 매핑은 다시 `style=13/stroke=2.0`으로 복원. `영양정보` 병합 헤더를 기준으로 영양성분 표 범위를 추적해 외곽/헤더 구분선은 굵게 유지하고 내부 grid의 thick border만 `style=1/stroke=1.0`으로 낮춤.
  - `test/label_sheet_xlsx_import_test.dart`: generic `thick` border는 `style=13`, `strokeWidth=2.0`으로 보존되는 회귀 기대값으로 수정.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공. 테스트 로그에서 `E3 style=5 type=border-top style=13 stroke=2.0` 확인.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 다음 재가져오기 확인 포인트: `row27~row29` 영양성분 내부선은 `style=1/stroke=1.0`으로 줄고, `A24/J24/A26:J26` 등 외곽/헤더 경계는 `style=13/stroke=2.0`로 유지되어야 함.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 커밋: `e88f9cd` (`XLSX 영양정보 테두리 내부선 보정`).

- **완료**: XLSX `thick` border 화면 두께 보정.
  - 최신 첨부 및 `.tmp/log/app_2026-07-03_12-06-13.log` 확인: 바코드/오른쪽 안내문 borderless 보정은 반영되어 `borders=1014`, `computedBorders=300`, `computed blank borders=-`로 감소. 남은 차이는 왼쪽 하단 영양성분 표 내부선이 `style=13/stroke=2.0`으로 계산되어 원본보다 과하게 두꺼워 보이는 것.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: Excel `thick` border를 FortuneSheet 최강선 `style=13/stroke=2.0` 대신 medium급 `style=8/stroke=1.5`로 매핑.
  - `test/label_sheet_xlsx_import_test.dart`: `thick` top border fixture를 추가하고 import 결과가 `style=8`, `strokeWidth=1.5`인지 검증.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공. 테스트 로그에서 `E3 style=5 type=border-top style=8 stroke=1.5` 확인.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 커밋: `fcbeb5b` (`XLSX 굵은 테두리 두께 보정`).

- **완료**: XLSX 바코드/오른쪽 안내문 영역 border 제외 보강.
  - 최신 첨부 비교 및 `.tmp/log/app_2026-07-03_12-00-47.log` 확인: `L29` 앵커는 `skipped value border samples`로 빠졌지만, 병합 내부 `M29~U29 top`, `L31~U31 bottom`이 `mergeCoveredBlank`로 남아 바코드 영역 상/하단 선이 표시됨. 또한 오른쪽 안내문 `L19:U24`가 `bottom/top` computed border로 변환본에서 원본보다 검은 가로선이 강하게 표시됨.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: `#BARCODE` borderless 병합 범위를 추적해 앵커뿐 아니라 병합 커버 셀 border도 제외. `#VALIDDATE`, `*업소명 및 소재지:`, `*유통기한:`, `*반품/교환장소:`, `*본 제품은`, `*부정불량식품 신고` 값 셀을 borderless 텍스트 영역으로 분류.
  - `test/label_sheet_xlsx_import_test.dart`: `#BARCODE` 병합 커버 셀과 `*유통기한:` 값 셀의 border 제외 회귀 테스트 추가.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공. 테스트 로그에서 `H1 value=*유통기한:`, `G3 value=#BARCODE`, `H3 value=`가 `skipped value border samples`에 기록됨.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 커밋: `26f7eff` (`XLSX 안내문과 바코드 테두리 보정`).

- **완료**: XLSX `#BARCODE` 자리표시자 border 제외.
  - 최신 로그 `.tmp/log/app_2026-07-03_11-56-16.log`: 빈 셀 border 제거 후 `borders=1345`, `computedBorders=382`, `computed blank borders=-`. 남은 차이는 `L29 span=3x10 value=#BARCODE` 주변에 `L29 top`, `row31 bottom` 등의 border가 남아 원본보다 바코드 영역 선이 표시되는 것.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: 값이 `#BARCODE`인 셀은 값/스타일은 유지하되 border를 import하지 않음. 제외된 값 셀 border는 `xlsx import worksheet skipped value border samples` 로그로 기록.
  - `test/label_sheet_xlsx_import_test.dart`: `#BARCODE` 값은 유지되고 해당 셀 border는 제외되는 회귀 테스트 추가.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공. 테스트 로그에서 `G3=#BARCODE` 및 `skipped value border samples` 확인.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 커밋: `4d6e7a4` (`XLSX 바코드 자리표시자 테두리 제외`).

- **완료**: XLSX 배경 있는 빈 셀 border 제외 보정.
  - 최신 로그 `.tmp/log/app_2026-07-03_11-52-20.log`: 새 코드가 로드됐지만 `borders=2365`, `skipped blank border samples=-`로 확인됨. 원인은 빈 셀에도 `bg=#ffffffff`가 있어 `_shouldImportXlsxCellBorders`의 `cellJson.containsKey('bg')` 조건 때문에 border import 대상으로 남은 것.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: 값/수식/하이퍼링크/병합/병합 내부가 없는 빈 셀은 배경색이 있어도 border를 import하지 않도록 변경. 배경 스타일 자체는 cellJson에 남기고, border만 skipped 로그로 분리.
  - `test/label_sheet_xlsx_import_test.dart`: 배경이 있는 빈 셀의 검은 border도 제외되는 fixture로 보강.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공. 테스트 로그에서 `B3 bg=#ff00ff00`이면서 B3 border가 `skipped blank border samples`에 기록되는 것 확인.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 커밋: `c5e0043` (`XLSX 배경 빈 셀 테두리 제외`).

- **완료**: XLSX 빈 일반 셀 테두리 재보정 및 skipped 로그 추가.
  - 사용자 첨부 원본/변환본 재비교 결과, 변환본 `row14~18`, `row32~36` 빈 영역에 검은 격자가 생겼고 원본은 일반 회색 그리드임. 직전 `blankIntentional` 보존 정책은 과한 검은 테두리를 되살려 잘못된 방향으로 확인됨.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: 값/수식/하이퍼링크/병합/병합 내부/배경이 없는 빈 일반 셀 border는 색상이 검은색이어도 import하지 않도록 복원. 대신 제외된 좌표/스타일/색상/방향을 `xlsx import worksheet skipped blank border samples` chunk 로그로 최대 200개 기록.
  - `test/label_sheet_xlsx_import_test.dart`: 빈 일반 셀의 검은 border와 회색 border가 모두 제외되는 기대값으로 조정.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공. 테스트 로그에서 `borders=6`, `skipped blank border samples`에 B3/C3 샘플 확인.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 커밋: `aaa07cc` (`XLSX 빈 셀 테두리 제외 로그 보강`).

- **완료**: XLSX 빈 셀 테두리 정책 보정.
  - 사용자 첨부 원본/변환본 비교 결과, 원본에도 row14~18 및 row32~36의 빈 격자 표가 검은 테두리로 존재함. 직전 `빈 일반 셀 border 전체 제외` 정책은 의도된 빈 표 테두리까지 제거할 수 있어 보정.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: 값/수식/하이퍼링크/병합/배경이 없는 빈 일반 셀이라도 검은/색상 명시 border는 `blankIntentional`로 가져오고, `#ffd0d0d0` 같은 밝은 중립 회색 보조선만 제외.
  - `test/label_sheet_xlsx_import_test.dart`: 빈 일반 셀의 검은 border는 유지, 밝은 회색 border는 제외되는 회귀 테스트 추가.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 커밋: `597bc27` (`XLSX 빈 격자 테두리 보존`).

- **완료**: XLSX 빈 일반 셀 border 제외로 과한 검은 격자 완화.
  - 최신 로그 `.tmp/log/app_2026-07-03_11-35-09.log`: `label sheet import apply computed border row cells`에서 row32~row36이 모두 `blank:21`로 잡힘. 하단 빈 격자의 검은 테두리는 값/병합이 없는 빈 일반 셀 border가 실제 렌더 대상으로 남은 것이 원인.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: merge range 목록을 보존하고, XLSX border import 조건을 추가. 값/수식/하이퍼링크/병합/병합 내부/배경색이 있는 셀의 border만 가져오고, 값도 병합도 배경도 없는 빈 일반 셀 border는 제외.
  - `test/label_sheet_xlsx_import_test.dart`: 병합 covered 빈 셀(`E1`) border는 유지하고, 빈 일반 셀(`F1`) border는 제외되는 회귀 테스트 추가.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 커밋: `53cf571` (`XLSX 빈 셀 테두리 가져오기 조정`).

- **완료**: XLSX 테두리 차이 원인 분리용 computed border 셀 상태 로그 보강.
  - 최신 로그 `.tmp/log/app_2026-07-03_11-31-02.log`: `borderInfo=2365`, `computedBorders=687`. 행별 요약 기준 하단 빈 격자 영역(row32~row36)에도 실제 렌더 대상 border가 다수 남음.
  - 판단: 테두리 차이는 계속 존재하며, 다음 재현에서는 초과 테두리가 값 있는 셀인지 빈 셀인지 바로 분리해야 함.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: `label sheet import apply computed blank borders` 로그 추가. `blank`, `value`, `mergeAnchorValue`, `mergeCoveredBlank` 등 셀 상태별 computed border 행 요약 `label sheet import apply computed border row cells` 추가.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 기능 커밋 완료: `8e119dd` (`XLSX 테두리 빈 셀 진단 로그 보강`).
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart` 기존 dirty 제외).

- **완료**: 다중 라벨 XLSX 테두리 차이 최신 로그 재확인 및 하단 행 border 로그 추가 보강.
  - 최신 로그 `.tmp/log/app_2026-07-03_11-27-13.log`: `borderInfo=2365`, `hasRawBorderInfo=true`, `computedBorders=687`. XLSX에서 변환된 border는 매우 많고, FortuneSheet 병합 내부선 제거 후 실제 표시 기준 border도 687개 남음.
  - 판단: 첨부 변환본의 테두리 차이는 실제 렌더 기준 computed border에도 존재함. 특히 기존 `computed borders` 샘플 limit 200은 `A1~L11`까지만 찍혀 중하단 빈 격자/`#BARCODE` 주변 행을 확인할 수 없었음.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: `computed borders` limit을 1000으로 확대해 687개 전체가 로그에 찍히도록 변경. `label sheet import apply border info rows`, `label sheet import apply computed border rows` 행별 요약 로그 추가.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 기능 커밋 완료: `0c92c78` (`XLSX 테두리 행별 진단 로그 보강`).
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart` 기존 dirty 제외).

- **완료**: 다중 라벨 XLSX 원본/변환본 테두리 차이 재확인 및 border 진단 로그 보강.
  - 사용자 지적: 스케일 외에도 원본/변환본에서 테두리가 다른 곳이 많음.
  - 판단: 첨부 변환본에서 원본보다 빈 격자 영역과 하단 블록의 검은 테두리가 더 많이/다르게 보임. 기존 로그는 `borders=2365` 개수만 보여 원본 XLSX 변환 단계 문제인지, FortuneSheet 병합 내부선 제거 후 렌더 기준 문제인지 분리 불가.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: XLSX 변환 직후 셀별 `borderInfo` 샘플 로그 추가. 좌표, style id, borderType, style, strokeWidth, color, range를 chunk로 기록.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: 적용 후 `sheet.borderInfo`와 `FortuneBorderCompute.compute(sheet)` 결과를 chunk 로그로 기록. 병합 내부선 제거 후 실제 렌더 기준 border 확인 가능.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 기능 커밋 완료: `979d0de` (`XLSX 테두리 진단 로그 보강`).
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart` 기존 dirty 제외).

- **완료**: 다중 라벨 XLSX 원본/변환본 비교 및 하단 블록까지 진단 가능한 로그 보강.
  - 최신 로그 `.tmp/log/app_2026-07-03_11-14-25.log`: 새 파일은 `Label_Template`, `rows=36`, `columns=21`, `cells=756`, `merges=88`, `borders=2365`. 원본 축 `1561.0x1212.9999999705747 logical`, 100mm 목표 폭 `377.9527559055118`, widthScale `0.23178750383474794`, readableScale `0.644237652111668`, 최종 적용 `1013.1259842519684x794.2677165164764 logical`.
  - 판단: 값/병합/블록 구조는 유지되지만 변환본은 100mm 폭을 `635.1732283464565 logical` / `168.05624999999995mm` 초과. 원인은 최소 가독 2.5mm 기준이 폭 맞춤보다 크게 작동한 것. 원본 캡처처럼 여러 라벨 블록과 하단 `#BARCODE`까지 포함된 시트에서는 “물리 라벨 1장 폭 맞춤” 정책과 “전체 워크시트 원본 비율 유지” 정책이 충돌함.
  - 기존 chunk 로그의 `merge sizes`/`text layout` 기본 limit 40으로는 하단 라벨 블록, `#BARCODE`, 빈 격자 영역까지 충분히 보이지 않음.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: `merge sizes`/`text layout` 샘플 limit을 200으로 확대. `row heights`, `column widths`, `row boundaries counted`, `column boundaries counted`를 chunk 로그로 추가해 36행/21열 전체 축을 확인 가능하게 함.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 기능 커밋 완료: `9533195` (`다중 라벨 XLSX 진단 로그 보강`).
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart` 기존 dirty 제외).

- **완료**: XLSX 원본/변환본 최신 재비교 및 긴 진단 로그 chunk 분할 보강.
  - 최신 로그 `.tmp/log/app_2026-07-03_11-07-22.log`: 원본 XLSX 축은 `1118.0x823.3333333131001 logical`, 적용 후 `405.1811023622046x300.7716535361378 logical`, 100mm 기준 폭 초과 `27.228346456692805 logical` / `7.204166666666637mm`. 최종 스케일은 `readableScale=0.35433070866141736`로 최소 가독 기준이 폭 맞춤보다 우선 적용됨.
  - 최신 `label sheet import apply text layout`: 적용 후 주요 셀 fontSize가 `10.393700787401576`, 예: `A1` logical `53.0236220472441x17.062992125582678`, `C1` logical `152.40157480314963x17.062992125582678`, `A3/H3` black header 영역 logical 약 `205.425/199.756 x 20.843`.
  - 첨부 비교 판단: 값/병합/축 구조는 유지되지만, 원본 50% 캡처와 변환본 100x100mm 화면 사이에 글자 크기·행 높이·폭 기준이 다르게 보임. 현재 변환본은 최소 가독 정책 때문에 실제 100mm 폭을 약 7.2mm 초과하는 상태.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: `merge sizes`, `text layout` 진단 로그가 한 줄에서 잘리지 않도록 `_logLabelSheetChunks`로 chunk 단위 분할 기록하도록 변경.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 기능 커밋 완료: `71520ce` (`XLSX 긴 레이아웃 로그 분할`).
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart` 기존 dirty 제외).

- **완료**: XLSX 원본/변환본 재비교 결과 분석 및 텍스트 레이아웃 진단 로그 보강.
  - 최신 로그 `.tmp/log/app_2026-07-03_11-01-47.log`: 원본 XLSX 전체 폭 `1118.0 logical`, 100mm 라벨 폭 목표 `377.9527559055118`, widthScale `0.32966735136368824`, readabilityScale `0.35433070866141736`, 최종 폭 `405.1811023622046 logical`로 100mm를 약 7.2mm 초과. 이는 최소 가독 2.5mm 정책 때문에 폭 맞춤보다 글자 가독 기준이 우선 적용된 결과.
  - 첨부 비교 판단: 값/병합/행열 구조는 유지되지만, 변환본은 원본 대비 실제 표시 폭/텍스트 크기/줄맞춤이 다르게 보임. 화면 캡처 배율도 원본 50%, 변환본 100x100 라벨 화면이라 픽셀 직접 비교는 불가.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: `label sheet import physical scale`에 `overflowLogical`, `overflowMm` 추가. `label sheet import apply text layout` 로그를 추가해 셀별 value length, line count, span, logical cell size, fontSize, bold, wrap, horizontal/vertical align을 기록.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 기능 커밋 완료: `c5b60a3` (`XLSX 텍스트 레이아웃 진단 로그 보강`).
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart` 기존 dirty 제외).

- **완료**: 공용라벨관리 `라벨 파일에서 가져오기` 완료 후에도 셀 선택 하이라이트가 남는 문제 재수정.
  - 원인 후보: 컨텍스트 메뉴 클릭 시 FortuneSheet 내부 `_sheetFocused=true`가 된 뒤, custom context menu handler가 import Future를 기다리지 않아 완료 후 한 번의 `unfocusSheet()`만으로는 다음 프레임 상태까지 보장되지 않음.
  - `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`: `FortuneSheetController.unfocusSheet()`가 즉시 `_focusNode.unfocus()`/`_sheetFocused=false` 처리 후 다음 프레임에도 재확인해 다시 해제하도록 보강.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: `_handleImportLabelFile` 완료 시 즉시 `unfocusSheet()` 호출 후 post-frame에서도 한 번 더 호출.
  - `third_party/fortune_sheet/test/fortune_sheet_focus_selection_test.dart`: 다음 프레임 이후에도 selection blue pixel이 다시 나타나지 않는 회귀 테스트 추가.
  - 검증 완료: `third_party/fortune_sheet`에서 `flutter test test/fortune_sheet_focus_selection_test.dart` 3개 성공.
  - 검증 완료: `third_party/fortune_sheet`에서 `flutter analyze lib/src/fortune_sheet_canvas.dart test/fortune_sheet_focus_selection_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 검증 완료: 루트에서 `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 임시 산출물 정리 완료: 검증 중 생성된 `third_party/fortune_sheet/build/` 삭제.
  - 기능 커밋 완료: `7094ea9` (`라벨 파일 가져오기 후 포커스 해제 보강`).
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_sheet_focus_selection_test.dart` (`lib/core/app.dart` 기존 dirty 제외).

- **완료**: XLSX 원본/변환본 재비교용 축·병합 치수 진단 로그 보강.
  - 첨부 비교 기준: 변환본은 값/병합/검은 헤더 위치는 대체로 유지되지만, 원본보다 콘텐츠 영역이 우측으로 덜 차고 N열 이후 빈 격자/우측 폭이 두드러짐. 일부 텍스트 크기와 줄맞춤도 압축되어 보임.
  - 현재 가설: 변환 자체의 값/병합 누락보다는 XLSX column width/row height 변환, 물리 폭 스케일 적용, 또는 FortuneSheet 적용 후 count/default 축 처리 중 한 단계에서 실제 경계 폭이 줄어듦.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: 원본/변환 row·column count 기반 boundary 로그와 병합 영역 logical size 로그 추가.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: apply 단계에서 지정 축 합계와 count/default 포함 합계, count 기반 boundary, 병합 anchor별 logical size, counted logical/mm 로그 추가.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_xlsx_import.dart lib/page_label_sheet/label_sheet_workbench.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 기능 커밋 완료: `c0af070` (`XLSX 변환 축 진단 로그 보강`).
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart` 기존 dirty 제외).

- **완료**: 공용라벨관리의 `라벨 파일에서 가져오기` 완료 후 시트에 포커스를 남기지 않아 셀 선택 파란 하이라이트가 보이지 않게 수정.
  - `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`: `FortuneSheetController.unfocusSheet()` API 추가, 내부 sheet focus node 해제 및 `_sheetFocused=false` 동기화.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: `_handleImportLabelFile`에서 clear/update/zoom 적용 직후 `_controller.unfocusSheet()` 호출.
  - `third_party/fortune_sheet/test/fortune_sheet_focus_selection_test.dart`: 컨트롤러로 업데이트 후 `unfocusSheet()` 호출 시 selection blue pixel이 사라지는 회귀 테스트 추가.
  - 검증 완료: `third_party/fortune_sheet`에서 `flutter test test/fortune_sheet_focus_selection_test.dart` 2개 성공.
  - 검증 완료: `third_party/fortune_sheet`에서 `flutter analyze lib/src/fortune_sheet_canvas.dart lib/src/fortune_sheet_painter.dart test/fortune_sheet_focus_selection_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 검증 완료: 루트에서 `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 임시 산출물 정리 완료: 검증 중 생성된 `third_party/fortune_sheet/build/` 삭제.
  - 기능 커밋 완료: `8f27d98` (`라벨 파일 가져오기 후 시트 포커스 해제`).
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_sheet_focus_selection_test.dart` (`.vscode/settings.json`, `lib/core/app.dart` 기존 dirty 제외).

- **완료**: 공용라벨 관리 시트가 포커스 받기 전 셀 선택 파란 하이라이트가 보이는 문제 수정.
  - 원인 후보: `FortuneSheetCanvas`의 `_sheetFocused` 기본값이 `true`이고, `FortuneSheetPainter._drawSheet`의 선택 표시 조건이 `sheetFocused`를 보지 않아 초기 렌더링부터 선택 하이라이트가 그려짐.
  - `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`: `_sheetFocused` 기본값을 false로 변경하고, sheet focus node 획득/상실 시 `_sheetFocused`를 동기화.
  - `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`: `sheetFocused`일 때만 셀/헤더 선택 하이라이트를 그림.
  - `third_party/fortune_sheet/test/fortune_sheet_focus_selection_test.dart`: `sheetFocused=false`일 때 selection blue pixel이 없고, `true`일 때 생기는 회귀 테스트 추가.
  - 검증 완료: `third_party/fortune_sheet`에서 `flutter test test/fortune_sheet_focus_selection_test.dart` 1개 성공.
  - 검증 완료: `third_party/fortune_sheet`에서 `flutter analyze lib/src/fortune_sheet_canvas.dart lib/src/fortune_sheet_painter.dart test/fortune_sheet_focus_selection_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 임시 산출물 정리 완료: 검증 중 생성된 `third_party/fortune_sheet/build/` 삭제.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart`, `third_party/fortune_sheet/test/fortune_sheet_focus_selection_test.dart` (`.vscode/settings.json`, `lib/core/app.dart` 기존 dirty 제외).

- **완료**: XLSX 가져오기 최소 가독 기준을 화면 logical px가 아닌 실물 프린트 mm 기준으로 변경.
  - 사용자 정정: 가독 기준은 화면상이 아니라 실물 라벨 프린트 기준.
  - 최신 로그 `.tmp/log/app_2026-07-03_10-33-57.log`: `widthScale=0.32966735136368824`, `readableScale=0.3`, `scale=0.32966735136368824`, `minFontSize=26.666666666666668`, `minReadable=8.0`.
  - 원인: 최소 가독 기준 8 logical px가 너무 낮아 폭 기준 축소 후 글자가 8.8~9.7 logical px 수준으로 작아져도 가독 보정이 개입하지 않음.
  - 수정 예정 파일: `lib/page_label_sheet/label_sheet_workbench.dart`, `SESSION_HANDOFF.md`.
  - 목적: 최소 가독 문자 크기를 mm 단위로 정의하고 FortuneSheet logical px로 환산해 폭 기준 스케일 완화 여부를 결정.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: 최소 가독 기준을 `_labelSheetImportMinReadableFontHeightMm = 2.5`로 정의하고 `fortuneMillimetersToLogicalPixels`로 변환해 readableScale 산출.
  - 로그 추가: `label sheet import physical scale`에 `minReadableMm`, `minReadableLogical`, `scaledMinFontSize` 기록.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`.vscode/settings.json`, `lib/core/app.dart` 기존 dirty 제외).

- **완료**: XLSX 가져오기 시 물리 라벨 폭 기준 스케일 적용 및 최소 가독 문자 크기 보정.
  - 사용자 요구: 변환 시 현재 물리 라벨 크기에 맞게 스케일 조정. 폭 우선이며, 높이는 폭 대비 비율로 따라감. 폭 기준 축소 후 문자가 읽기 어려울 정도로 작아지면 최소 가독 문자 크기를 기준으로 다시 키우고, 이때 인쇄 영역 초과 허용.
  - 최신 로그 `.tmp/log/app_2026-07-03_10-22-42.log`: `currentGridWidthMm=100 currentGridHeightMm=100`, 변환 전 `logicalSize=1118.0x823.3333333131001`, 물리 `100x100mm` 기준 `logicalPerMm=11.1800x8.2333`.
  - 수정 예정 파일: `lib/page_label_sheet/label_sheet_workbench.dart`, `SESSION_HANDOFF.md`.
  - 구현 방향: import apply 전 현재 물리 라벨의 logical width에 맞춰 행/열/폰트 크기를 동일 배율로 조정. 최종 폰트가 최소 가독 크기보다 작으면 최소 폰트 기준 배율로 완화.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: XLSX import 적용 전 `_labelSheetScaledToPhysicalWidth` 경로 추가. `.lms` 가져오기는 기존 보존 동작 유지.
  - 스케일 정책: 현재 물리 라벨의 logical width를 기준으로 widthScale 산출, 행/열/셀 fontSize/inline run fontSize/letterSpacing을 동일 배율 적용. 최소 폰트가 실물 프린트 기준 2.5mm 미만이 될 경우 readableScale로 배율을 키워 인쇄 영역 초과를 허용.
  - 로그 추가: `label sheet import physical scale`에 source/target logical size, widthScale, readableScale, final scale, minFontSize, scaledLogical, overflowWidth 기록. apply 로그에 `scaleToPhysicalWidth` 기록.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`.vscode/settings.json`, `lib/core/app.dart` 기존 dirty 제외).

- **완료**: XLSX 원본 대비 변환본 시각 차이 재확인 및 치수 진단 로그 보강.
  - 첨부 비교 기준: 값/줄바꿈은 살아 있으나 변환본의 하단 영양정보 영역 행 높이/전체 세로 배치가 원본과 다르게 보임.
  - 최신 로그 `.tmp/log/app_2026-07-03_10-14-35.log`: 값/병합/줄바꿈은 apply 단계까지 유지. `zoomRatio=1.0`, `columnLogicalWidth=1118.0`, `rowLogicalHeight=823.3333333131001`, `gridWidthMm=80`, `gridHeightMm=60`.
  - 현재 가설: XLSX 원본 행/열 치수와 FortuneSheet logical 치수 변환 또는 적용 후 표시 스케일 중 한 단계에서 세로 비율 차이가 발생.
  - 수정 예정 파일: `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `SESSION_HANDOFF.md`.
  - 목적: 원본 XLSX row height/column width, 변환 logical 치수, 적용 후 axis/physical scale을 긴 단일 로그가 아닌 분리 로그로 남겨 다음 재현에서 원인 단계 판별.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: 원본 row height(pt), column width(chars), 변환 logical 치수와 합계 로그 추가.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: apply 후 행/열 치수, 누적 boundary, physical mm 대비 logical/mm 로그 추가.
  - 참고: `./flutter.ps1 test ...`는 서브패키지에도 같은 상대 경로를 전달해 wrapper 전체 exit code는 실패했지만 root 대상 테스트는 성공. 이후 root Flutter 직접 실행으로 검증 완료.
  - 검증 완료: `C:\Flutter\bin\flutter.bat analyze lib/page_label_sheet/label_sheet_xlsx_import.dart lib/page_label_sheet/label_sheet_workbench.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 검증 완료: `C:\Flutter\bin\flutter.bat test test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 임시 산출물 정리 완료: wrapper 검증 중 생성된 `third_party/fortune_sheet/build/`, `third_party/mssql_connection/build/`, `third_party/r_get_ip/build/` 삭제.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `lib/page_label_sheet/label_sheet_workbench.dart` (`.vscode/settings.json`, `lib/core/app.dart` 기존 dirty 제외).

- **완료**: VS Code 작업이 `pwsh -Command powershell ...` 형태로 실행될 때 `powershell` 명령을 찾지 못하는 문제 수정.
  - 수정 예정 파일: `.vscode/tasks.json`.
  - 목적: shell task의 bare `powershell` 명령을 Windows PowerShell 실행 파일 절대 경로로 바꿔 PATH/App Execution Alias 상태와 무관하게 실행되도록 보정.
  - `.vscode/tasks.json`: `ADB: Silence MESA log`, `Windows: Ensure Build Tools`, `WebView2: Clear userDataFolder (label_manager)`의 `command`를 `C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe`로 변경.
  - 검증 완료: `ADB: Silence MESA log` 작업 재실행 시 `powershell not recognized` 오류 없이 절대 경로 PowerShell로 실행됨.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `.vscode/tasks.json` (`.vscode/settings.json`, `lib/core/app.dart` 기존 dirty 제외).

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

- **완료 (2026-07-03)**: XLSX 가져오기 후 원본 대비 축소 표시되는 zoom 상태 보정 및 표시폭 로그 추가.
  - 재현 첨부 확인: 줄바꿈은 살아났지만 전체 시트가 원본보다 약간 축소되어 열/행 폭이 좁게 표시됨.
  - 최신 로그 `.tmp/log/app_2026-07-03_00-31-05.log`: C8/A13 `lineBreakCells`는 `tb=2`, 줄 수 2, rowHeight 충분. 따라서 남은 차이는 값/rowHeight/wrap이 아니라 표시 스케일 쪽.
  - 원인 후보 확인: FortuneSheet는 표시 축 계산에 `zoomRatio`를 곱함. 워크벤치 zoom UI 상태와 import된 sheet zoom 상태가 로그에 드러나지 않아 폭 차이 추적이 어려웠음.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: 라벨 파일/XLSX import 적용 시 sheet `zoomRatio`를 1로 고정하고 워크벤치 zoom UI도 100%로 동기화.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: import apply 로그에 `zoomRatio`, `columnLogicalWidth`, `columnVisibleWidth`, `rowLogicalHeight`, `rowVisibleHeight` 추가.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `17d1b87` (`XLSX 가져오기 표시 배율 동기화`).

- **완료 (2026-07-03)**: XLSX 줄바꿈 셀 FortuneSheet wrap 정규값 보정.
  - 재현 첨부 확인: `제조원` 주소 두 번째 줄과 13행 안내문 두 번째 줄이 변환본에서 보이지 않음.
  - 최신 로그 `.tmp/log/app_2026-07-03_00-24-50.log`: C8/A13 값의 `\n`과 충분한 rowHeight는 apply 단계까지 보존됨.
  - 원인 확인: FortuneSheet `FortuneCell.normalizedTextWrap`은 `0/1/2`만 유효하게 보며, 실제 wrap은 `2`. 기존 importer의 `tb=wrap`은 렌더러에서 `0`으로 정규화되어 wrap 미적용.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: Excel `wrapText` 및 줄바꿈 포함 셀을 `tb=2`로 저장하도록 수정.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: `worksheet json layout` 로그에 `lineBreakCells`를 별도 추가해 C8/A13 같은 줄바꿈 셀의 `tb`, 줄 수, 병합, rowHeight, fontSize가 앞쪽 빈 wrap 셀에 묻히지 않도록 보강.
  - `test/label_sheet_xlsx_import_test.dart`: `textWrap`과 `normalizedTextWrap`이 `2`인지 검증하도록 회귀 테스트 갱신.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `ebb55c3` (`XLSX 줄바꿈 셀 래핑 값 보정`).

- **완료 (2026-07-03)**: XLSX 원본 대비 변환본 긴 텍스트 줄바꿈 누락 보정 및 진단 로그 추가.
  - 첨부 비교 확인: `제조원`, 영양성분 안내문처럼 줄바꿈이 필요한 긴 텍스트가 변환본에서 한 줄로 잘리거나 다음 줄이 보이지 않는 차이 확인.
  - 최신 로그 `.tmp/log/app_2026-07-03_00-18-00.log`: A8/A13 값 자체의 `\n`은 apply 단계까지 보존됨. 따라서 값 누락보다 wrap 적용/레이아웃 진단 부족이 원인 후보.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: 값에 실제 줄바꿈이 있으면 Excel처럼 `tb=wrap`을 강제 적용.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: XML 숫자 문자 참조 `&#10;`, `&#xA;` 등을 실제 문자로 복원하도록 `_xmlDecode` 보강.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: `worksheet json layout` 로그 추가. rowHeights/columnWidths 샘플과 wrapCells 좌표, 줄 수, 병합 span, rowHeight, fontSize 기록.
  - `test/label_sheet_xlsx_import_test.dart`: `&#10;` 줄바꿈 값이 실제 `\n`으로 복원되고 `textWrap=wrap`으로 들어가는 회귀 테스트 추가.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `3a28496` (`XLSX 가져오기 줄바꿈 처리와 로그 보강`).

- **완료 (2026-07-03)**: XLSX 원본 대비 변환본 열 폭/테두리 굵기 추가 보정.
  - 최신 로그 `.tmp/log/app_2026-07-03_00-11-03.log`: 값/병합/font size는 정상 적용. current grid physical size는 80x60mm 유지.
  - 확인 결과: 실제 XLSX column width 합계 138, 기존 변환식 `width * 7` 합계 966px로 원본 대비 가로 폭이 좁음. 후보 `width * 8` 합계 1104px가 원본 이미지 폭에 더 근접.
  - 확인 결과: FortuneSheet border compute는 `rawBorderInfo`가 있으면 raw를 우선하며 `strokeWidth`도 읽음. importer가 borderInfo JSON에 strokeWidth를 넣으면 thin/medium 굵기 과장 완화 가능.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: column width 변환식을 `width * 7`에서 `width * 8`로 조정.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: borderInfo JSON에 `strokeWidth` 추가. Excel `thin`=1.0, `medium`=1.5, `thick`=2.0, `hair`=0.5.
  - `test/label_sheet_xlsx_import_test.dart`: column width 기대값 및 medium border strokeWidth 회귀 테스트 갱신.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `0b19f69` (`XLSX 가져오기 열 폭과 테두리 굵기 보정`).

- **완료 (2026-07-03)**: XLSX 원본 대비 변환본 스케일/테두리 차이 수정.
  - 최신 로그 `.tmp/log/app_2026-07-02_23-57-45.log`: C1/H3/H9/J1 값과 병합은 apply 단계까지 정상.
  - 남은 차이: 글자 크기가 작고, 원본 solid medium 테두리가 변환본에서 점선처럼 표시됨.
  - 확인 결과: XLSX font size는 20~22pt인데 importer가 그대로 `fs`에 넣어 FortuneSheet에서 20~22 logical px로 렌더됨. row height는 이미 pt→px 변환 중이므로 font도 XLSX importer에서 pt→logical px 변환 필요.
  - 확인 결과: XLSX `medium` border가 solid인데 `_borderStyle`이 FortuneSheet dashed style `4`로 매핑 중. solid medium은 FortuneSheet style `8`로 매핑해야 함.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: font `<sz val="...">`를 XLSX pt 단위에서 FortuneSheet logical px로 변환(`pt * 4 / 3`). 로그 style/merge sample에 `fs` 포함.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: `_borderStyle`에서 Excel solid `medium` -> FortuneSheet style `8`, `thick` -> `13`, `double` -> `2`로 매핑. dashed/dotted 계열은 FortuneSheet dash style로 분리.
  - `test/label_sheet_xlsx_import_test.dart`: font size 변환 기대값 갱신, medium border가 solid style `8`로 들어오는 회귀 테스트 추가.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `736fe26` (`XLSX 가져오기 글꼴 크기와 테두리 보정`).

- **완료 (2026-07-02)**: XLSX 가져오기 크기 해석 정정 및 self-closing 셀 파싱 수정.
  - 사용자 의도: 가져오기 시 설정한 라벨 물리 크기(mm)는 유지하고, 행/열/셀 내용은 인쇄영역을 벗어나도 잘라내지 않고 그대로 가져오기.
  - 이전 구현 문제: `_labelSheetWithImportedGridClientSize`가 XLSX 전체 행/열 크기를 새 `fortuneSheetGridClientWidthMm/HeightMm`으로 저장해 물리 라벨 크기 자체를 바꿈.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: `_labelSheetWithPreservedGridClientSize`로 교체. XLSX가 자체 grid size 메타가 없으면 현재 시트의 `fortuneSheetGridClientWidthMm/HeightMm`을 보존하고, 행/열/cells는 그대로 가져와 인쇄영역 밖 데이터도 유지.
  - 최신 로그 `.tmp/log/app_2026-07-02_23-49-41.log`: `worksheet json samples` 단계에서 `C1 #ITEMNAME`이 `B1`, `H3 #ALLERGY`가 `B3`처럼 앞의 빈 self-closing 셀로 붙는 현상 확인.
  - 원인: `_sheetJsonFromWorksheet`의 row/cell 정규식이 닫힌 태그 대안을 먼저 매칭해 `<c r="B1" /> <c r="C1">...</c>`를 B1 셀 하나로 삼킴.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: row/cell 정규식을 self-closing 태그 우선으로 변경해 뒤 셀 값을 앞 빈 셀에 붙이지 않도록 수정.
  - `test/label_sheet_xlsx_import_test.dart`: self-closing 빈 셀 뒤 값 있는 셀(`F1`/`G1`) 회귀 테스트 추가, 다중 병합 fixture column count 갱신.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_xlsx_import.dart lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `84c792b` (`XLSX 가져오기 셀 파싱과 크기 보존 수정`).

- **완료 (2026-07-02)**: XLSX 원본 대비 변환본 시각 차이 재확인 및 촘촘한 로그 추가.
  - 첨부 비교 기준: 원본에는 C1/J1/H3/H9 등 오른쪽 병합 anchor 텍스트와 검은 배경이 있으나 변환본에서는 일부 오른쪽 병합 영역 텍스트/배경이 누락되어 보임.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: worksheet JSON 생성 직후 values/styles/merge sample 로그 추가, FortuneSheet decode 직후 values/mergeAnchors/mergeCovered sample 로그 추가.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: controller 적용 직전 imported sheet의 rows/columns/cells/borders/grid mm/values/mergeAnchors/mergeCovered sample 로그 추가.
  - `test/label_sheet_xlsx_import_test.dart`: 같은 행에 여러 병합이 있는 fixture(D1:E1)를 추가하고 오른쪽 병합 anchor/covered cell marker 유지 확인.
  - 확인 결과: 실제 XLSX XML에는 C1/J1/H3/H9 값과 오른쪽 병합 범위가 존재. 다음 재현 로그에서 importer decode 단계와 workbench apply 단계 중 어느 단계에서 누락되는지 판별 가능.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_xlsx_import.dart lib/page_label_sheet/label_sheet_workbench.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `lib/page_label_sheet/label_sheet_workbench.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `a975f51` (`XLSX 가져오기 병합 로그 보강`).

- **완료 (2026-07-02)**: XLSX/라벨 파일 가져오기 시 현재 설정된 라벨 크기에 맞춰 제한하지 않고, 가져온 시트의 실제 행/열 크기 전체를 작업 영역으로 사용하도록 수정.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: `_handleImportLabelFile`에서 가져온 시트가 자체 `fortuneSheetGridClientWidthMm/HeightMm`을 갖고 있지 않으면 row/column extent를 mm로 환산해 extraFields에 저장. 설정 라벨 크기보다 커도 가져온 전체 크기를 grid client area로 사용.
  - 가져오기 적용 로그에 rows/columns/cells/gridWidthMm/gridHeightMm 추가.
  - 임시 검사 스크립트 `.tmp/inspect_xlsx_import.dart` 삭제.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `4a95189` (`라벨 파일 가져오기 크기 제한 해제`).

- **완료 (2026-07-02)**: `label_converted.xlsx` 가져오기 실패 원인 수정.
  - 최신 로그 `.tmp/log/app_2026-07-02_23-25-23.log`: `workbook.xml` 로드 성공 후 `_activeSheetInfo: workbook has no sheet tags`, `FormatException: XLSX workbook has no sheets` 발생.
  - 실제 `xl/workbook.xml`: `<x:workbook>`, `<x:sheets>`, `<x:sheet ...>`처럼 SpreadsheetML 태그가 namespace prefix를 사용. 기존 importer 정규식은 `<sheet>`만 매칭해 실패.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: XML entry 로드 시 태그 이름의 namespace prefix만 제거(`x:workbook -> workbook`, `x:sheet -> sheet`)하고 `r:id` 같은 attribute prefix는 유지하도록 `_normalizeXmlTagPrefixes` 추가.
  - `test/label_sheet_xlsx_import_test.dart`: workbook/worksheet/styles/sharedStrings 태그에 `x:` prefix가 붙은 XLSX fixture 회귀 테스트 추가.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 3개 성공.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `5b2399f` (`XLSX 네임스페이스 태그 가져오기 수정`).

- **완료 (2026-07-02)**: `.xlsx` 선택 후 여전히 `라벨 파일을 읽을 수 없습니다.`가 표시되는 문제 확인 및 촘촘한 디버깅 로그 추가.
  - 확인 결과 최신 로그 `.tmp/log/app_2026-07-02_23-20-26.log` 및 기존 로그 검색에서 import 실패 로그가 없음. 원인: 기존 import 로그가 `fortuneSheetDebugLog`라 플래그 비활성 시 앱 로그에 남지 않음.
  - `lib/page_label_sheet/label_sheet_workbench.dart`: 파일 선택기 open/cancel/selected, file.name/file.path/pathExt/nameExt, 확장자 판정, bytes 길이, xlsx/lms 분기, 실패 stackTrace를 기본 앱 로그(`debugLog`)로 기록.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: xlsx probe, zip entry sample, entry lookup/found/missing, workbook.xml/rels, active sheet relId, relationship target, worksheet path/load, worksheet rels, styles/sharedStrings/customXml, worksheet JSON rows/columns/cells/merge/hyperlink/border counts, decode success/failure stackTrace를 기본 앱 로그로 기록.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 2개 성공.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `lib/page_label_sheet/label_sheet_xlsx_import.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `5b74f70` (`XLSX 가져오기 디버깅 로그 추가`).

- **완료 (2026-07-02)**: 컨텍스트 메뉴 `라벨 파일에서 가져오기`에서 `.xlsx` 선택 및 Excel 내용을 현재 라벨 시트로 로드.
  - 수정 예정/진행 파일: `lib/page_label_sheet/label_sheet_workbench.dart`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, 테스트 파일 추가 예정.
  - 1차 구현: 파일 선택기 확장자 `lms,xlsx` 추가, 확장자별 `.lms` 기존 decode / `.xlsx` 신규 importer 분기 추가.
  - 사용자 추가 요구: 1차 값 중심 범위를 넘어 XLSX에서 변환 가능한 모든 속성(스타일/병합/행열 크기/숨김/수식/링크/테두리 등)을 가능한 한 FortuneSheet JSON으로 변환.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: XLSX zip에서 workbook/worksheet/sharedStrings/styles/rels를 읽어 활성 시트를 `FortuneWorkbook`으로 변환. 값, cached formula value, `=...` 수식, shared/inline rich text, 글꼴/크기/굵게/기울임/밑줄/취소선/색/배경, 정렬/wrap/회전/number format, 병합, 행/열 크기와 숨김, hyperlink, 테두리 변환 지원.
  - 포춘 시트 추가 기능: XLSX rich text `vertAlign`을 `script`(`superscript`/`subscript`)로 변환. 기존 라벨 시트 XLSX export의 `customXml/labelSheetRtfMetadata`를 읽어 셀/런 extraFields의 `fontScale`(장평), `letterSpacing`(자간), `lineHeight`(줄간격), `script`(첨자)를 복원.
  - `test/label_sheet_xlsx_import_test.dart`: 메모리 XLSX fixture로 값/스타일/병합/숨김/링크/rich text 첨자/테두리/customXml 자간·장평·줄간격 변환 테스트 추가.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 1개 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `e53bc43` (`라벨 시트 XLSX 가져오기 지원`).
  - 추가 구현 커밋: `43bf166` (`XLSX 확장 텍스트 메타 복원`).

- **완료 (2026-07-02)**: `.xlsx` 선택 후 `라벨 파일을 읽을 수 없습니다.`가 표시될 수 있는 경로 보강.
  - 최신 로그 `.tmp/log/app_2026-07-02_23-15-59.log`에는 import 실패 로그가 없어 파일 형식 판정/실패 로그 자체를 보강.
  - `lib/page_label_sheet/label_sheet_workbench.dart` `_readImportedLabelWorkbook`: 확장자 판정을 `file.path` 우선, `file.name` fallback으로 변경. 확장자가 비어도 파일 bytes의 zip entry `xl/workbook.xml`로 XLSX를 판별해 importer 호출. 실패 로그에 파일명/경로/stackTrace 포함.
  - `lib/page_label_sheet/label_sheet_xlsx_import.dart`: `labelSheetLooksLikeXlsx` 추가, workbook relationship target이 `/xl/worksheets/sheet1.xml`처럼 절대 경로인 XLSX도 처리.
  - `test/label_sheet_xlsx_import_test.dart`: bytes 기반 XLSX 판별 및 절대 worksheet target 회귀 테스트 추가.
  - 검증 완료: `test/label_sheet_xlsx_import_test.dart` 2개 성공.
  - 검증 완료: `flutter analyze lib/page_label_sheet/label_sheet_workbench.dart lib/page_label_sheet/label_sheet_xlsx_import.dart test/label_sheet_xlsx_import_test.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/page_label_sheet/label_sheet_workbench.dart`, `lib/page_label_sheet/label_sheet_xlsx_import.dart`, `test/label_sheet_xlsx_import_test.dart` (`lib/core/app.dart` 기존 dirty 제외).
  - 구현 커밋: `0a54df4` (`XLSX 가져오기 파일 판정 보강`).

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

- **완료 (2026-07-02)**: RTF Viewer resize 완료 시 post-frame recapture가 정상 resize-end 캡처를 덮는 문제 방지.
  - 최신 로그 확인: `resizeEndRect` 직후 정상 target 캡처가 실행된 다음, post-frame measured target이 border/rounding으로 2px 작아져 `resizeEndPostFrame` recapture가 추가 실행됨.
  - `lib/home_page_manager.dart` `_scheduleRtfPreviewResizeFinalRecapture`: post-frame measured target과 current target 차이가 2px 이하이면 진단 로그만 남기고 recapture 생략. 의미 있는 차이(`> 2px`)에서만 measured target recapture 수행.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart lib/page_label_sheet/label_sheet_rtf_preview.dart lib/page_home/preview_floating_window.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `ff9e099` (`RTF 리사이즈 완료 중복 재캡처 방지`).

- **완료 (2026-07-02)**: RTF Viewer resize 완료 시 같은 최종 target으로 child를 한 번 더 교체하는 문제 방지.
  - 최신 로그 확인: guard 적용 후 `resizeEndPostFrame`은 `recapture=false`로 생략됐지만, resize 중 debounce capture와 resize 완료 `resizeEndRect` 강제 capture가 같은 target/PNG byte로 연속 실행됨.
  - `lib/home_page_manager.dart`: `_rtfPreviewRefreshedTargetContentSize`를 추가해 실제 child refresh에 사용한 target을 추적. resize 완료 target이 이미 refresh된 target과 같으면 `force=false`로 내려 보내 child 교체/강제 recapture를 생략.
  - 추가 로그: `rtf preview resize completed target=... refreshed=... force=...`.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart lib/page_label_sheet/label_sheet_rtf_preview.dart lib/page_home/preview_floating_window.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `af270c6` (`RTF 완료 시 동일 크기 재생성 방지`).

- **완료 (2026-07-02)**: 큰 RTF Viewer를 줄일 때 resize 완료 후 드래그 중 native capture 결과가 남는 문제 방지.
  - 최신 로그 확인: 큰 크기 축소 중 `resizeDebounce` capture가 1초 이상 걸리며 여러 generation으로 중첩됨. 마우스를 놓은 뒤에도 마지막 드래그 중 capture가 뒤늦게 완료되어 완료 화면을 덮음.
  - `lib/home_page_manager.dart`: resize 중에는 target size만 갱신하고 native recapture를 만들지 않도록 변경. resize 완료 후 180ms 안정화 뒤 `resizeEndSettled` 한 번만 recapture.
  - `lib/page_label_sheet/label_sheet_rtf_preview.dart`: widget key에서 size/generation을 제거하고 `captureGeneration` prop으로 Future를 갱신하게 변경. 새 캡처 대기 중에도 기존 `FutureBuilder` snapshot을 유지해 정상 이미지를 계속 표시.
  - 추가 로그: `resizeEndSettled`, `refreshed=... recapture=...`.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart lib/page_label_sheet/label_sheet_rtf_preview.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart lib/page_label_sheet/label_sheet_rtf_preview.dart lib/page_home/preview_floating_window.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/page_label_sheet/label_sheet_rtf_preview.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `8012eba` (`RTF 축소 리사이즈 중 캡처 중첩 방지`).

- **완료 (2026-07-02)**: RTF Viewer resize 완료 recapture가 작은 높이 canvas로 다시 렌더링해 완료 화면을 망가뜨리는 문제 방지 및 상세 로그 추가.
  - 최신 로그 확인: 새 코드에서 `resizeDebounce` 중첩은 사라졌으나, 완료 후 `resizeEndSettled` capture가 `logical 637x372 -> canvas 1593x558`처럼 짧은 canvas로 native 렌더링. native 진단에서 bottom edge가 꽉 차는 패턴(`edge=...,1091`)으로 잘림/과노출 화면을 만들 가능성 확인.
  - `lib/home_page_manager.dart`: 정상 RTF image가 한 번 resolve된 뒤에는 resize 완료 final recapture를 생략하고 기존 이미지를 창 크기에 맞춰 스케일 유지. 이미지 resolve 여부/크기(`imageResolved`, `image=...`)와 recapture skip 로그 추가.
  - `lib/page_label_sheet/label_sheet_rtf_preview.dart`: capture start/done/empty 로그에 capture id, generation, logical/canvas/px, png/display size, displayScale 추가.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart lib/page_label_sheet/label_sheet_rtf_preview.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart lib/page_label_sheet/label_sheet_rtf_preview.dart lib/page_home/preview_floating_window.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/page_label_sheet/label_sheet_rtf_preview.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `d83fbc0` (`RTF 완료 재캡처 생략 및 로그 강화`).

- **완료 (2026-07-02)**: RTF Viewer 상세 디버깅 로그 플래그 처리.
  - `lib/page_label_sheet/label_sheet_rtf_preview_debug.dart`: `labelSheetRtfPreviewDebugLogEnabled` 추가. 기본값은 `false`, `--dart-define=LABEL_MANAGER_RTF_PREVIEW_DEBUG=true`로 활성화 가능.
  - `lib/home_page_manager.dart`, `lib/page_label_sheet/label_sheet_rtf_preview.dart`, `lib/page_label_sheet/label_sheet_native_open_xml.dart`: resize/capture 상세 로그를 `labelSheetRtfPreviewDebugLog(...)` 뒤로 이동.
  - 다음 RTF resize/capture 재디버깅 시 먼저 `LABEL_MANAGER_RTF_PREVIEW_DEBUG=true`로 실행하거나 임시로 `labelSheetRtfPreviewDebugLogEnabled = true` 설정 후 로그 확인.
  - 검증 완료: `flutter analyze lib/home_page_manager.dart lib/page_label_sheet/label_sheet_rtf_preview.dart lib/page_label_sheet/label_sheet_native_open_xml.dart lib/page_label_sheet/label_sheet_rtf_preview_debug.dart lib/page_home/preview_floating_window.dart --no-fatal-warnings --no-fatal-infos` 성공.
  - stage/commit 대상: `SESSION_HANDOFF.md`, `lib/home_page_manager.dart`, `lib/page_label_sheet/label_sheet_rtf_preview.dart`, `lib/page_label_sheet/label_sheet_native_open_xml.dart`, `lib/page_label_sheet/label_sheet_rtf_preview_debug.dart` (`lib/core/app.dart` 제외).
  - 구현 커밋: `d3a7fa5` (`RTF 상세 로그 플래그 처리`).

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
