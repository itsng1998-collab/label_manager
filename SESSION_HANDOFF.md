# 완료: 라벨 workbench 업무 정책 분리

## 완료: 신규 품목 다건 ID 매핑 중복 수정
- 최신 로그 `app_2026-07-30_13-09-38.log`: 서로 다른 draft key의 신규 2건 저장 중 `@InsertedRows.DRAFT_ROW_KEY`에 두 번째 key가 중복 삽입되어 native 2627이 발생했고 transaction은 rollback됐다.
- 원인: SQL `WHILE`의 `@CapturedItem` table variable에 이전 반복의 ITEM_ID가 남아, 두 번째 반복에서 누적된 두 ID를 모두 두 번째 draft key로 매핑했다.
- 레거시 비교: batch INSERT 후 마지막 N건을 재조회해 매핑하므로 캡처 table 누적은 없다. 현재 `OUTPUT INSERTED` 방식은 유지하되 반복마다 캡처 table을 초기화한다.
- 수정 예정: `@CapturedItem`을 루프 밖에서 선언하고 각 반복 시작 시 `DELETE FROM @CapturedItem`을 실행하며, SQL 선언/초기화 순서 계약 테스트를 추가한다.
- 편집 완료(`item_manager_save.dart`): `@CapturedItem`을 루프 전에 선언하고 각 반복의 draft key 조회/INSERT 전에 내용을 삭제한다.
- 테스트 추가(`item_manager_save_dao_test.dart`): 캡처 table 선언 < WHILE < 초기화 < OUTPUT 순서를 검증해 다건 반복 누적을 방지한다.
- focused 검증: `item_manager_save_dao_test.dart` 4건 통과.
- 최종 검증: `item_manager_save_dao_test.dart`와 `item_manager_draft_test.dart` 총 30건 통과. 변경 파일 analyzer `No issues found`; diagnostics 0건.
- stage 대상: `lib/features/item/data/item_manager_save.dart`, `test/item_manager_save_dao_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

## 완료: 신규 품목 RICH_ELEMENT_RTF 저장 실패 수정
- 최신 로그 `app_2026-07-30_13-03-43.log`: 신규 2건 저장의 첫 `BM_RICH_ITEM` INSERT에서 `RICH_ELEMENT_RTF` NOT NULL 위반(native 515, state 23000)이 발생했고 transaction은 rollback됐다.
- 레거시 비교: `CItem` 신규 생성자는 element RTF를 빈 문자열로 초기화하고 `CItemDAO::Insert/InsertBatch`는 `RICH_ELEMENT_RTF`를 항상 INSERT한다.
- 원인: 현재 `ItemManagerSaveDAO.saveSql`의 신규 `BM_RICH_ITEM` INSERT가 기준 데이터인 `RICH_ELEMENT_SHEET`만 기록하고 legacy 필수 컬럼 `RICH_ELEMENT_RTF`를 누락했다.
- 수정 예정: 신규 INSERT에 `RICH_ELEMENT_RTF=N''`를 명시하고 SQL 계약 테스트를 추가한다. DB schema/default/migration은 변경하지 않는다.
- 편집 완료(`item_manager_save.dart`): 신규 `BM_RICH_ITEM` INSERT 컬럼/SELECT에 `RICH_ELEMENT_RTF`와 `N''`를 같은 위치로 추가했다.
- 테스트 추가(`item_manager_save_dao_test.dart`): 신규 INSERT가 `RICH_ELEMENT_SHEET` 다음에 legacy RTF 컬럼과 빈 값을 명시하는 계약을 검증한다.
- focused 검증: `item_manager_save_dao_test.dart` 4건 통과.
- 최종 검증: `item_manager_save_dao_test.dart`와 `item_manager_draft_test.dart` 총 30건 통과. 변경 파일 analyzer `No issues found`; diagnostics 0건.
- stage 대상: `lib/features/item/data/item_manager_save.dart`, `test/item_manager_save_dao_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

## 완료: 품목 인라인 editor 문자별 초기화 수정
- 현상: 품목 추가 행의 인라인 editor에서 연속 입력할 때 기존 입력이 지워지고 마지막 문자만 남는다.
- 원인: `EditableText`가 처리할 문자 `KeyDownEvent`가 자식 `Focus`에서 테이블 `Focus`로 버블링되고, `_handleKeyEvent()`가 이를 선택 셀의 새 편집 시작으로 오인해 매 문자마다 `TextEditingController(initialText: 마지막 문자)`로 교체했다.
- 편집 완료(`fortune_table.dart`): 인라인 편집 활성 중에는 테이블 단위 편집 시작/선택 단축키 처리를 건너뛰어 문자 키를 현재 `EditableText`만 처리하게 했다.
- 테스트 추가(`fortune_table_test.dart`): 실제 품목 추가 후 빈 동적 셀 editor에서 문자 key event가 발생해도 동일 controller와 기존 text/selection이 유지되는지 검증한다.
- focused 검증: `ItemManage keeps the active editor during character key events` 통과.
- 최종 검증: `fortune_table_test.dart` 전체 62건 통과. 변경 파일 analyzer `No issues found`; diagnostics 0건.
- stage 대상: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

## 완료: 품목 주원료 표-플로팅 시트 양방향 동기화
- 표→플로팅 원인 1: `_applyItemElementDraft()`가 `_selectedItemOfMarket`만 갱신하고 열린 `PreviewFloatingWindow` child를 다시 설정하지 않는다.
- 표→플로팅 원인 2: `_ItemPreviewPanel.didUpdateWidget()`이 같은 `rowIdentity`의 element text/payload 변경을 무시한다.
- 반대 방향 확인: 플로팅 시트 `onChange`는 `_commitItemElementDraft()`를 거쳐 draft controller를 갱신하므로 ItemManage 표는 listener rebuild로 반영된다.
- 수정 예정: element commit 후 열린 품목 preview를 갱신하고, panel이 같은 행의 외부 element 변경을 현재 local workbook과 다를 때만 반영하도록 한다. 양방향 widget 회귀를 추가한다.
- 재현 완료: 같은 `rowIdentity`에 변경된 text/payload를 전달해도 FortuneSheet workbook은 기존 `원재료`를 유지해 focused 테스트가 수정 전 실패했다.
- 편집 완료(`home_page_manager.dart`): element draft 적용 후 품목 탭의 열린 preview child를 갱신한다. panel은 같은 행의 element text/payload 변경도 감지하되 현재 local workbook과 내용이 다를 때만 form을 교체해 시트 자체 commit의 되돌림을 방지한다.
- 테스트 추가: 표에서 같은 행의 text/payload가 바뀌면 preview workbook이 갱신되는 경로와, 시트 변경 commit을 부모 item이 다시 전달해도 local workbook이 유지되는 반대 경로를 검증한다.
- focused 검증: 표→preview, 시트→parent echo, 신규 표 주원료→draft plain/payload 3개 경로 통과.
- 전체 검증 실행 예정: `flutter test test/label_sheet_toolbar_test.dart`, `flutter test test/fortune_table_test.dart`, `flutter analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart test/fortune_table_test.dart`.
- 최종 검증: `label_sheet_toolbar_test.dart` 166건, `fortune_table_test.dart` 61건 통과. 변경 파일 analyzer `No issues found`; diagnostics 0건.
- stage 대상: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

## 완료: 품목 인라인 editor 연속 입력 선택 오동작 수정
- 현상: 신규 품목 컬럼 editor에서 입력 내용이 계속 선택되어 다음 키가 이전 입력을 대체하고 최종 문자만 남는다.
- 로컬 가설: 기존 테스트의 `enterText()`는 전체 값을 직접 설정해 실제 키 입력 중 selection 변화를 검증하지 못했다. 실제 키 이벤트 연속 입력으로 controller text와 collapsed selection 계약을 재현한다.
- 수정 예정: 신규 빈 동적 셀을 더블클릭한 뒤 `A`, `B` 키 입력이 각각 `a`, `ab`로 누적되고 selection이 끝에 collapsed 상태인지 회귀 테스트를 추가한다.
- 원인: 직전 즉시 focus 수정에서 `EditableText.autofocus`와 post-frame `requestFocus()`를 함께 사용해 실제 빠른 입력 중 focus 요청이 중복될 수 있고, Windows focus 선택 동작이 입력 내용을 다시 선택할 수 있었다.
- 편집 완료(`fortune_table.dart`): autofocus를 제거해 post-frame 명시적 focus 하나만 사용하고 `selectAllOnFocus: false`를 고정했다.
- 테스트 보강: 빈 셀의 IME 입력 `a`→`ab` 누적과 collapsed selection, 값이 있는 셀의 끝 커서, autofocus/select-all 비활성 계약을 검증한다.
- focused 검증: 값이 있는 신규 셀과 빈 신규 셀 2건 통과. 전체 검증 예정: `flutter test test/fortune_table_test.dart`, `flutter analyze third_party/fortune_sheet/lib/src/fortune_table.dart test/fortune_table_test.dart`.
- 최종 검증: 전체 `fortune_table_test.dart` 61건 통과. 변경 파일 analyzer `No issues found`.
- stage 대상: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

## 완료: 신규 품목 주원료 및 전체 컬럼 편집 확인
- 확인 결과: 발행은 체크박스, 라벨크기는 읽기 전용, 품명은 인라인 text, 이미지형은 BMP picker, 이미지 외 동적 타입은 인라인 text다. 주원료만 표에서 의도적으로 read-only여서 신규 행에서 편집할 수 없었다.
- 수정 예정: 주원료 인라인 commit callback을 추가하고 상위에서 plain text와 `elementPayload` workbook을 함께 갱신한다. 실제 추가 후 빈 주원료 셀 편집 회귀를 추가한다.
- 편집 완료(`item_manage.dart`): 주원료 callback이 연결되고 편집 가능 상태일 때 인라인 text editor를 제공한다.
- 데이터 보존 경계: 기존 품목 주원료는 서식 workbook을 plain text로 덮지 않도록 기존 시트 편집을 유지하고, 주원료 인라인 editor는 신규 추가/가져오기 행(`isNew`)에만 허용한다.
- 편집 완료(`home_page_manager.dart`): 주원료 text commit 시 기존 `_itemElementWorkbook()`과 `labelSheetEncodeWorkbookSave()`로 payload를 재생성한 뒤 draft를 갱신한다.
- 테스트 추가(`fortune_table_test.dart`): 실제 품목 추가 후 빈 주원료 셀 더블클릭, 즉시 focus, plain/payload 동시 반영을 검증한다.
- 타입별 focused 검증 6건 통과: 품명 text, 주원료 callback 유무별 편집 정책, 이미지 picker, 이미지 외 동적 타입 0~3/5~12 text, 신규 빈 동적 셀 text. 변경 파일 diagnostics 0건.
- 전체 검증 실행 예정: `flutter test test/fortune_table_test.dart`, `flutter analyze lib/features/item/presentation/item_manage.dart lib/home_page_manager.dart test/fortune_table_test.dart`.
- 신규 행 제한 후 테스트 어댑터가 0건을 반환해 CLI로 전환했다. 첫 CLI는 nullable draft callback 인수 컴파일 오류를 검출해 `isNew` 검사 후 non-null 값으로 전달하도록 수정했다.
- 최종 검증: CLI 전체 `fortune_table_test.dart` 61건 통과. 변경 3개 Dart 파일 analyzer `No issues found`.
- stage 대상: `lib/features/item/presentation/item_manage.dart`, `lib/home_page_manager.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

## 완료: 신규 품목 인라인 editor 즉시 focus
- 현상: 신규 품목의 빈 컬럼을 더블클릭하면 editor는 표시되지만 한 번 더 클릭해야 커서가 활성화된다.
- 로컬 가설: `FortuneTable._startTextEditing()`이 editor 생성 후 `autofocus`에만 의존하고 상위 rebuild 뒤 명시적으로 focus를 복원하지 않아 표 focus가 남는다.
- 수정 예정: 기존 실제 추가 흐름 회귀에 더블클릭 직후 `EditableText.focusNode.hasFocus`와 test input 연결 검증을 추가하고, editor focus node를 post-frame에 명시적으로 요청한다.
- 재현 완료: editor 생성 직후 `EditableText.focusNode.hasFocus`가 false여서 focused 테스트가 수정 전 실패했다.
- 편집 완료(`fortune_table.dart`): editor 시작 frame 이후 동일한 focus node가 여전히 활성 editor일 때 `requestFocus()`를 호출한다.
- focused 검증: 신규 빈 셀 즉시 focus, 기존 값 편집, 이미지 picker 분기 3건 통과. 변경 파일 diagnostics 0건.
- 전체 검증 실행 예정: `flutter test test/fortune_table_test.dart`, `flutter analyze third_party/fortune_sheet/lib/src/fortune_table.dart test/fortune_table_test.dart`.
- 최종 검증: 전체 `fortune_table_test.dart` 60건 통과. 변경 파일 analyzer `No issues found`.
- stage 대상: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

## 완료: 신규 품목 빈 셀 편집 진입 수정
- 사용자 재현 로그 `app_2026-07-30_11-57-45.log`: 품목 1개 추가는 성공했으나 빈 셀 더블클릭 후 편집 commit 이벤트가 없었다.
- 원인: `FortuneTable._buildTextCell()`의 비편집 `GestureDetector`가 셀 전체가 아니라 내부 `Text`의 크기만 사용해 빈 문자열 셀은 double-tap hit 영역 폭이 0이다.
- 수정 예정: 실제 품목 추가 명령 후 빈 동적 셀을 더블클릭하는 widget 회귀를 추가하고, 비편집 text cell의 hit 영역을 셀 내부 전체로 확장한다.
- 재현 완료: 실제 추가 명령 후 빈 동적 셀 좌표를 더블클릭했을 때 `EditableText`가 생성되지 않아 focused 테스트가 수정 전 실패했다.
- 편집 완료(`fortune_table.dart`): 비편집 text cell의 listener/gesture를 `SizedBox.expand`로 감싸 빈 문자열과 텍스트 오른쪽 여백도 셀 전체에서 hit-test되도록 변경했다.
- focused 검증: 신규 빈 셀 회귀, 기존 값 동적 셀 편집, 이미지 picker 분기 3건 통과. 변경 파일 diagnostics 0건.
- 전체 검증 실행 예정: `flutter test test/fortune_table_test.dart`, `flutter analyze third_party/fortune_sheet/lib/src/fortune_table.dart test/fortune_table_test.dart`.
- 최종 검증: 전체 `fortune_table_test.dart` 60건 통과. 변경 파일 analyzer `No issues found`.
- stage 대상: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

## 완료: 신규 품목 행 컬럼 타입별 편집
- 확정 정책: 레거시 품목 편집과 동일하게 이미지형은 BMP 파일 선택, 그 외 편집 가능한 타입은 인라인 텍스트를 사용한다. 일반 품목 셀용 dropdown 선택지 데이터는 현재 모델과 레거시에 없다.
- 수정 예정: `test/fortune_table_test.dart`에 신규 행 동적 텍스트 셀의 더블클릭 편집 회귀를 추가하고, 필요하면 `lib/features/item/presentation/item_manage.dart`의 draft 행 조회를 객체 identity 대신 안정적인 행 인덱스로 변경한다.
- 편집 완료(`item_manager_rules.dart`): 컬럼 타입을 텍스트 editor 또는 BMP image picker로 매핑하는 `itemManagerDynamicCellEditorForType()` 정책을 추가했다.
- 편집 완료(`item_manage.dart`): 신규/기존 draft의 편집·이미지 선택·선택·행 색상·context menu 대상 조회를 display 객체 identity가 아닌 현재 행 인덱스로 전환했다.
- 테스트 추가(`fortune_table_test.dart`): 이미지 타입만 image picker이고 나머지 타입은 text editor인 계약, 신규 행 동적 텍스트 셀의 더블클릭 편집과 draft 반영을 검증한다.
- focused 검증: 신규 행 텍스트 편집과 이미지 picker 열 배정 widget 테스트 2건 통과. editor 타입 정책 테스트도 통과. 변경 파일 diagnostics 0건.
- 전체 검증 실행 예정: `flutter test test/fortune_table_test.dart`, `flutter analyze lib/features/item/domain/item_manager_rules.dart lib/features/item/presentation/item_manage.dart test/fortune_table_test.dart`.
- 전체 widget 테스트 59건 통과. 첫 analyzer는 editor 정책 분리 후 남은 `item_manage.dart`의 `column_type.dart` 미사용 import 1건으로 실패해 해당 import를 제거했다.
- 최종 검증: focused widget 2건 및 전체 `fortune_table_test.dart` 59건 통과. 변경 3개 Dart 파일 analyzer `No issues found`; `git diff --check` 확인 후 커밋한다.
- stage 대상: `lib/features/item/domain/item_manager_rules.dart`, `lib/features/item/presentation/item_manage.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

## 완료: 품목 주원료 시트 개체보기 제거
- 원인: 품목 미리보기에서 `showObjectPanelOpenButton: false`만 지정해 좁은 창의 버튼은 숨겼지만 `allowObjectPanel` 기본값이 true라 넓은 창에서는 dock형 개체 패널이 허용됐다.
- 수정 예정: 품목 `주원료 및 함량`의 `LabelSheetWorkbench`에 `allowObjectPanel: false`를 지정하고 기존 widget 테스트에서 옵션을 직접 검증한다.
- 커밋 정책 변경: 앞으로 코드/설정/문서 작업 완료 커밋에는 `SESSION_HANDOFF.md`를 함께 포함한다. 기존 unrelated `lib/core/app.dart`는 제외한다.
- 편집 완료: `_ItemElementPreviewTab`의 workbench에 `allowObjectPanel: false`를 지정했다. 테스트는 렌더된 workbench 옵션과 개체 패널 버튼 부재를 함께 검증하며 focused 1건 통과.
- 검증: 전체 `label_sheet_toolbar_test.dart` 164건 통과. `flutter analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart` → `No issues found`; diagnostics 0건.
- stage 대상: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.
- 커밋 메시지: `품목 주원료 시트 개체보기 제거`. 원격 push 없음.

## 완료: 로그인 실패 메시지 색상 변경
- 대상: 로그인 다이얼로그의 `_infoText` 로그 영역. 아이디 없음, 비밀번호 오류, 인증 예외 메시지가 표시되는 영역이다.
- 수정 예정: 메시지 `Text`에 빨간색 스타일과 테스트 key를 적용하고 실제 다이얼로그 widget 테스트로 색상을 검증한다.
- 편집 완료: `_infoText` 메시지에 `Colors.red`와 `startup-login-info-text` key를 적용했다.
- 테스트 추가: 실제 로그인 다이얼로그를 열어 메시지 영역의 `TextStyle.color`가 빨간색인지 검증하며 focused 테스트 1건 통과.
- 검증: 전체 `startup_dialog_test.dart` 4건 통과. `flutter analyze lib/features/login/presentation/startup_dialog.dart test/startup_dialog_test.dart` → `No issues found`; diagnostics 0건.
- stage 예정: `lib/features/login/presentation/startup_dialog.dart`, `test/startup_dialog_test.dart`만 포함한다. 기존 unrelated `lib/core/app.dart`와 `SESSION_HANDOFF.md`는 제외한다.
- cached diff check 통과. 기능 커밋: `23a3fcd` (`로그인 실패 메시지 빨간색 표시`). 원격 push 없음.

## 완료: 품목 미리보기 resize의 편집 상태 전환 수정
- 기대 계약: 플로팅 창 위치/크기는 UI 상태이며 품목 draft 데이터가 아니므로 resize만으로 편집/dirty가 되면 안 된다.
- 확인 결과: 품목 `PreviewFloatingWindow`에는 geometry 콜백이 없고 resize handle은 opaque hit-test라 직접 draft 경로는 없다. 의심 경로는 resize rebuild 중 품목 `LabelSheetWorkbench`의 workbook op가 `onUserWorkbookChanged`로 전달되는 경우다.
- 재현: 실제 품목 미리보기 플로팅 resize 후 `onElementCommitted`는 0회로 draft commit은 없었다. 그러나 업무 변경 필터가 `false`인 op 뒤에도 `LabelSheetWorkbench` 저장 버튼이 활성화되는 별도 내부 dirty 결함을 테스트로 재현했다.
- 원인: `onUserWorkbookChangedShouldNotify`가 view-state 변경을 거부해도 `onOp`가 무조건 `_isDirty=true`로 전환했다.
- 편집 완료: clear-sheet 특수 처리는 유지하고, 필터가 거부한 op는 dirty 전환 전에 반환한다.
- 첫 회귀 테스트는 수정 전 저장 버튼 활성화로 실패했고 수정 후 통과했다.
- 테스트 추가: 실제 품목 플로팅 resize가 draft commit을 만들지 않는 계약과 필터된 user op가 시트 dirty를 만들지 않는 계약.
- 검증: focused 3건 통과, 전체 `label_sheet_toolbar_test.dart` 164건 통과. `flutter analyze lib/features/label_sheet/label_sheet_workbench.dart test/label_sheet_toolbar_test.dart` → `No issues found`; diagnostics 0건.
- stage 예정: `lib/features/label_sheet/label_sheet_workbench.dart`, `test/label_sheet_toolbar_test.dart`만 포함한다. 기존 unrelated `lib/core/app.dart`와 `SESSION_HANDOFF.md`는 제외한다.
- cached diff check 통과. 기능 커밋: `1884492` (`품목 미리보기 크기 변경 dirty 오인 수정`). 원격 push 없음.

## 완료: 플로팅 창 모서리 기준 리사이징
- 대상: 품목 미리보기, 공통 라벨 미리보기, 영양성분 RTF 미리보기가 공유하는 `PreviewFloatingWindow`.
- 원인: `_buildProportionalCornerRect()`가 어느 모서리를 드래그해도 `base.left/top`을 고정해 모든 조작이 우측하단 resize처럼 동작한다.
- 수정 예정: 좌/상단 모서리 drag 시 반대편 right/bottom을 고정하도록 rect 위치를 보정한다. 기존 top-right 테스트를 올바른 고정점 계약으로 변경하고 좌측 모서리 회귀를 추가한다.
- 편집 완료(`preview_floating_window.dart`): left handle은 기존 right, top handle은 기존 bottom을 기준으로 새 left/top을 계산한다. bottom-right의 기존 left/top 고정은 유지한다.
- 테스트 편집 완료(`label_sheet_toolbar_test.dart`): top-right는 bottom-left 고정으로 계약을 교정하고, bottom-left의 top-right 고정 및 top-left의 bottom-right 고정을 추가했다.
- 첫 기존 테스트는 origin 고정 기대 때문에 의도대로 실패해 좌표 변화가 확인됐다. 계약 교정 후 네 모서리 관련 focused 테스트 4건 통과.
- 검증: 전체 `label_sheet_toolbar_test.dart` 162건 통과. `flutter analyze lib/widgets/preview_floating_window.dart test/label_sheet_toolbar_test.dart` → `No issues found`; diagnostics 0건.
- stage 예정: `lib/widgets/preview_floating_window.dart`, `test/label_sheet_toolbar_test.dart`만 포함한다. 기존 unrelated `lib/core/app.dart`와 `SESSION_HANDOFF.md`는 제외한다.
- cached diff check 통과. 기능 커밋: `a66384b` (`플로팅 창 모서리 리사이징 기준 수정`). 원격 push 없음.

## 완료: ODBC Driver 18 미설치 연결 실패 보완
- 대상 로그: `.tmp/app_2026-07-16_15-12-30.log`. 로컬 SQLite 설정 DB는 정상 개방됐고 SQL Server 연결에서 `IM002`(지정한 ODBC 드라이버 없음)가 발생했다.
- 원인: 현재 연결 문자열 후보가 `ODBC Driver 18 for SQL Server` 하나뿐이다. README의 Driver 17 이상 지원 안내와 달리 Driver 17만 설치된 PC에서 같은 오류가 재현된다.
- 수정 예정: Driver 18을 우선 사용하고 IM002 등 연결 실패 시 Driver 17을 fallback으로 시도하도록 후보를 추가하며 순서 단위 테스트를 고정한다.
- 편집 완료(`odbc_driver.dart`): 연결 문자열 후보를 Driver 18, Driver 17 순서로 생성한다. 첫 focused 검증에서 기존 ODBC 연결 상태 테스트 3건 통과.
- 오류 보존: Driver 18의 인증·네트워크 오류를 Driver 17 시도로 덮지 않도록 fallback은 공급자 미등록 `IM002`에만 허용한다.
- 테스트 추가(`odbc_connection_state_test.dart`): Driver 18→17 후보 순서와 IM002 허용/인증 오류 거부 계약을 추가했다.
- 검증: ODBC 연결 상태 테스트 5건 통과. `flutter analyze lib/database/windows_odbc/odbc_driver.dart test/odbc_connection_state_test.dart` → `No issues found`.
- 환경 확인: 개발 PC에는 `ODBC Driver 18 for SQL Server`가 32/64비트 모두 등록돼 있다. 운영 로그 자격 증명으로 실제 서버 연결은 수행하지 않았다.
- stage 예정: `lib/database/windows_odbc/odbc_driver.dart`, `test/odbc_connection_state_test.dart`만 포함하고 `SESSION_HANDOFF.md`는 제외한다.
- cached diff check 통과. 기능 커밋: `f340004` (`ODBC 드라이버 17 연결 fallback 추가`). 원격 push 없음.

## 완료: 브랜드·라벨 설정 CRUD UX 통일
- 목표: 행 안에서 나타나는 인라인 수정/삽입/삭제를 제거하고 목록 위 고정 추가/수정/삭제 명령으로 통일한다. 추가/수정은 작은 입력 다이얼로그, 삭제는 기존 확인 다이얼로그를 사용한다.
- 보존: 브랜드/라벨 활성 선택 더블클릭, 브랜드 selector, 순서 변경 모드·적용/취소, 라벨 전자저울 사용 값, 기존 DAO/reload/busy/error 경계.
- 편집 완료: 브랜드·라벨 목록을 일반 `SwipeActionTable`로 전환하고 표 위에 고정 추가/수정/삭제 아이콘을 배치했다. 추가는 항상 활성, 수정·삭제는 선택 행이 있을 때 활성화된다.
- 추가/수정: 공용 `SettingsNameEditDialog`를 root modeless overlay에 표시하며 이름 trim·빈 값 차단을 적용한다. 라벨은 같은 다이얼로그에서 전자저울 사용을 함께 편집한다. 입력 다이얼로그의 저장을 최종 확인으로 사용해 기존 중복 확인창은 제거했다.
- 삭제: 선택 행을 대상으로 기존 삭제 확인·DAO·reload 경로를 유지한다. 순서 변경과 활성 브랜드/라벨 더블클릭 동작도 유지한다.
- 테스트 추가: 공용 명령바의 선택 기반 활성화, 입력 trim·전자저울 값 반환, 빈 이름 저장 차단 3건.
- 첫 widget 검증 2건 통과. manager 연결 후 label sheet toolbar 161건 통과, diagnostics 0건. CLI DAO/swipe/widget 회귀 30건 통과.
- 테스트 어댑터가 다중 파일과 포맷 후 신규 파일을 `0 passed / 0 failed`로 반환해 CLI로 재실행했으며 신규 widget 3건 통과.
- `git diff --check` 통과. 신규 widget/test만 포맷했고 대형 manager 전체 포맷은 실행하지 않았다.
- stage 예정: `lib/home_page_manager.dart`, `lib/widgets/settings_name_edit_dialog.dart`, `test/settings_name_edit_dialog_test.dart`만 포함하고 `SESSION_HANDOFF.md`는 제외한다.
- cached diff check 통과. 기능 커밋: `541e160` (`브랜드 라벨 설정 편집 UX 통일`). 원격 push 없음.
- 오류 수정: 변경 없음 비교가 add handler에 잘못 삽입되어 `label`/`brand` undefined analyzer 오류 3건이 발생했다. 비교를 각 edit handler로 이동했다.
- 인라인 UX 제거 후 남은 `_insertActionIndex`, insert toggle, 라벨 inline scale widget/painter를 제거해 미사용 경고 3건도 정리했다.
- 수정 검증: `flutter analyze lib/home_page_manager.dart lib/widgets/settings_name_edit_dialog.dart` → `No issues found`; toolbar 161건 + CRUD widget 3건, 총 164 tests passed; `git diff --check` 확인 후 별도 오류 수정 커밋으로 기록한다.
- 오류 수정 커밋: `e78b889` (`브랜드 라벨 설정 편집 오류 수정`). 원격 push 없음.

## 완료: 폴더 구조 변경 후 빈 폴더 정리
- 삭제: `lib/models`, `lib/page_home`, `lib/page_login`, `lib/features/admin_access/data`와 그 결과 비게 된 `lib/features/admin_access`.
- 확인: 삭제 대상에 Git 추적 파일, ignore placeholder, 일반 파일이 없었고 정리 후 `lib` 아래 빈 디렉터리는 0개다.
- 제외: `android/.gradle/8.12/expanded`, `android/.gradle/8.12/vcsMetadata`는 Gradle 생성 캐시이므로 소스 구조 정리 대상에서 제외했다.
- Git은 빈 디렉터리를 추적하지 않으므로 기능 파일 diff·커밋·Flutter 테스트 대상은 없다. 원격 push 없음.

## 완료: LabelSheetWorkbench 잔여 정책 감사
- 비출력 private method를 감사한 결과, 남은 계산 helper는 import 적용 상세 로그 샘플링 전용이며 업무 경로에는 picker/controller/mounted/snackbar/focus/dirty lifecycle과 분리할 다음 순수 정책이 없다.
- `_workbookHasRtfImportSource()`와 `_opsClearSheet()`는 각각 RTF import dirty 전환과 controller op dirty 전환에 직접 붙은 짧은 상태 query라 별도 application API로 만들지 않는다.
- `_labelSheetAxisLogicalTotalSize()`는 실제 map entry 합계 로그이고 application의 `labelSheetAxisLogicalTotalSizeForCount()`는 누락 축 default를 포함하는 업무 계산이므로 의미가 달라 통합하지 않는다. 로그에 업무 로직을 추가하지 않았다.
- 결론: import/export/save/print 업무 정책은 application/printing 계층으로 이동했고 workbench에는 UI/controller/platform/lifecycle orchestration만 남았다. 추가 억지 추출 없이 이 리팩터링 범위를 완료한다.
- 코드 변경 및 추가 테스트 없음. 감사 기록만 갱신하며 기능 커밋은 만들지 않는다.

## 완료: Hybrid EZPL preparation 조립 분리
- 감사 결과: geometry 이후 candidate 생성, EZPL descriptor preflight, approval 기반 render plan 확정은 다른 production 호출자가 없는 동기·순수 정책 체인이다.
- 로컬 가설: geometry/descriptors/plan을 반환하는 preparation builder로 묶으면 workbench에는 controller capture와 filtered PNG bytes 생성 orchestration만 남고 승인된 native command는 동일하다.
- 편집 완료: `LabelSheetHybridPrintPreparation`과 `prepareLabelSheetHybridPrint()`를 추가해 geometry, candidate, descriptor preflight, approval 기반 plan 확정을 묶었다. workbench는 preparation 이후 controller capture와 filtered PNG bytes 생성만 수행한다.
- 테스트 변경: 기존 line+cell-border Hybrid 출력 fixture를 preparation builder 경유로 전환하고 승인 token 2개와 descriptor command encoding을 그대로 검증한다.
- 검증: print job 9 tests passed, label sheet toolbar 161 tests passed. 변경 파일 diagnostics 0건, `git diff --check` 통과.
- 최종 diff: print job/workbench/test 3개에 88 insertions, 84 deletions. formatter는 실행하지 않았다.
- stage 예정: 위 3개만 포함하고 `SESSION_HANDOFF.md`는 제외한다.
- cached diff check 통과. 기능 커밋: `e632e38` (`라벨 하이브리드 출력 계획 조립 분리`). 원격 push 없음.
- 출력 정책 분리 경계 완료: print job이 옵션 정규화, 출력 범위, Hybrid geometry/candidate/preflight/plan, PDF/EZPL bytes 정책을 소유한다. workbench에는 printer/platform 조회, controller finalize/capture, mounted/snackbar, 실제 전송 orchestration만 남았다.
- 다음 시작점: 출력 경로는 더 분리하지 않는다. workbench의 비출력 private method 중 controller/UI lifecycle과 분리 가능한 다음 순수 업무 계산을 표적 감사한다.

## 완료: Hybrid EZPL geometry 계산 분리
- 감사 결과: backend 선택은 이미 dispatcher에 있고 printer 조회·controller capture·플랫폼 전송은 workbench orchestration이다. 반면 `_captureHybridEzpl()`의 출력 range 정규화, source bounds/mm, layout, `FortunePrintTransform` 생성은 순수 계산이다.
- 로컬 가설: sheet/settings/physical size/metrics/options를 받는 geometry builder로 이 계산을 이동하면 candidate/plan/capture 순서는 유지되고 workbench의 출력 정책 책임만 줄어든다.
- 편집 완료: `LabelSheetHybridPrintGeometry`와 `resolveLabelSheetHybridPrintGeometry()`를 추가해 range/source bounds/source mm/layout/transform 계산을 print job으로 이동했다. workbench는 geometry로 candidate/descriptor/plan/capture를 조립한다.
- 테스트 추가: custom/default 3셀 축, source metrics, margin/clip/native transform 계약 1건.
- 첫 focused 검증은 source bounds를 40px로 예상해 1건 실패했다. FortuneSheet metrics가 셀 경계 3px을 포함하는 기존 계약을 확인해 기대값을 43×43px로 교정했다.
- 최종 검증: print job 9 tests passed, label sheet toolbar 161 tests passed. 변경 파일 diagnostics 0건, `git diff --check` 통과.
- 최종 diff: print job/workbench/test 3개에 121 insertions, 44 deletions. formatter는 실행하지 않았다.
- stage 예정: 위 3개만 포함하고 `SESSION_HANDOFF.md`는 제외한다.
- cached diff check 통과. 기능 커밋: `9413dab` (`라벨 하이브리드 출력 좌표 계산 분리`). 원격 push 없음.
- 다음 시작점: geometry 이후 `fortuneBuildNativeCandidates → preflightLabelSheetEzplCandidates → fortuneFinalizeHybridRenderPlan` 조립이 순수 print-job 정책으로 묶일 수 있는지 감사한다. controller capture와 filtered PNG 기반 bytes 생성은 orchestration 경계로 유지한다.

## 완료: 출력 옵션 입력 정규화 분리
- 감사 결과: `_currentPrintOptions()`가 controller 읽기와 함께 copies 최소 1, mm 음수·비숫자 0 보정, spacing/orientation 문자열 해석 정책을 소유한다.
- 로컬 가설: 문자열 입력을 받는 순수 print options builder로 전체 정규화 규칙을 이동하면 workbench에는 UI 값 전달만 남고 기존 출력 옵션은 동일하다.
- 편집 완료: `labelSheetPrintOptionsFromInput()`에 copies/mm/spacing/orientation 정규화를 이동하고 workbench는 controller와 선택값만 전달한다. 기존 fallback과 clamp는 변경하지 않았다.
- 테스트 추가: 정상 입력의 trim·orientation·spacing과 음수/비숫자/none/unknown fallback 계약 1건.
- 검증: print job 8 tests passed, label sheet toolbar 161 tests passed. 변경 파일 diagnostics 0건, `git diff --check` 통과.
- 최종 diff: print job/workbench/test 3개에 63 insertions, 18 deletions. formatter는 실행하지 않았다.
- stage 예정: 위 3개만 포함하고 `SESSION_HANDOFF.md`는 제외한다.
- cached diff check 통과. 기능 커밋: `ed285e8` (`라벨 출력 옵션 정규화 분리`). 원격 push 없음.
- 다음 시작점: `_handleIssuePrintSettings()`의 backend 선택 이후 분기를 감사하되 printer 조회, platform port/DPI 확인, mounted/snackbar는 workbench에 유지한다. 순수 print-job 조립 경계가 확인될 때만 다음 책임을 이동한다.

## 완료: 출력 범위 계산 분리
- 감사 결과: `_labelSheetPrintRange()`와 `_lastPrintIndexForExtent()`가 physical mm와 sheet axis 크기만 사용하는 순수 계산인데 workbench에 남아 있고 일반/PNG/Hybrid 출력 3경로가 공유한다.
- 로컬 가설: 계산을 기존 `label_sheet_print_job.dart`의 public policy로 이동하면 세 호출자의 범위가 동일하게 유지되고 workbench의 출력 정책 책임이 줄어든다.
- 편집 완료: print job에 `labelSheetPrintRange()`를 추가하고 workbench private helper 2개를 제거했으며 기존 호출 3개를 전환했다.
- 테스트 추가: 10×10mm 범위에서 custom 첫 축과 default 후속 축이 각각 index 2까지 포함되는 계약 1건.
- 첫 focused 검증: `flutter test test/label_sheet_print_job_test.dart` 7 tests passed.
- 검증 중 현재 SDK `dart format`이 기존 스타일 파일 전체를 재작성해 의도 밖 churn을 만들었다. 세 코드 파일의 이번 diff만 역적용하고 작은 기능 patch를 재적용했으며 기존 사용자 변경은 없었다.
- 최종 diff: print job/workbench/test 3개에 65 insertions, 43 deletions. 전면 포맷 churn 없음, `git diff --check` 통과.
- 최종 검증: print job 7 tests passed, label sheet toolbar 161 tests passed.
- stage 예정: 위 3개만 포함하고 `SESSION_HANDOFF.md`는 제외한다.
- 변경 파일 diagnostics 0건, cached diff check 통과.
- 기능 커밋: `297e70b` (`라벨 출력 범위 계산 분리`). 원격 push 없음.
- 다음 시작점: workbench의 `_currentPrintOptions()`와 숫자 입력 정규화가 UI controller 읽기와 출력 옵션 정책을 함께 소유하는지 감사한다. 단순 parse helper만 옮기지 말고 응집된 options builder 경계가 확인될 때만 분리한다.

## 완료
- 감사 결과: 일반 파일 import가 `_applyImportedLabelWorkbook()` 호출 전에 `sheets.isEmpty`와 동일 snackbar 분기를 중복 수행한다.
- 로컬 가설: 빈 workbook 검증을 공통 apply 진입점에만 유지하면 일반 파일과 AI XLSX import 모두 같은 검증·표시 경로를 사용하면서 동작은 보존된다.
- 편집 완료: `_importLabelFileFromXFile()`의 중복 empty-sheet 분기 9줄을 제거하고 공통 apply 검증은 유지했다. application result 타입이나 새 abstraction은 추가하지 않았다.
- focused 검증: `flutter test test/label_sheet_toolbar_test.dart` 161 tests passed.
- 변경 파일 diagnostics 0건, `git diff --check` 통과.
- stage 예정: workbench 1개만 포함하고 `SESSION_HANDOFF.md`는 제외한다.
- 기능 커밋: `9a606a2` (`라벨 가져오기 검증 경로 단일화`). 원격 push 없음.
- 다음 시작점: import/export 범위 밖의 workbench private 정책 중 application 계층으로 이동할 수 있는 다음 순수 계산 책임을 감사한다.

## 완료
- 경계 감사 결과: picker, `XFile` 읽기, controller apply, mounted/snackbar는 workbench orchestration이지만 `XLSX이면 물리 폭 scaling`이라는 format-to-layout 정책 1개가 남아 있다.
- 로컬 가설: file path/name을 받는 import layout wrapper가 format을 해석하면 기존 LMS 무scaling/XLSX scaling 동작을 보존하면서 workbench의 enum 판단을 제거할 수 있다.
- 편집 완료: `labelSheetPrepareImportedSheetForFile()`을 추가하고 workbench의 format enum 및 scaling bool 판단을 제거했다.
- 테스트 추가: path 우선 format에서 XLSX는 물리 폭 scaling, LMS는 원래 폭 보존 계약 1건.
- focused 검증: import layout 4 tests passed.
- 변경 파일 Dart 포맷 완료.
- 통합 회귀: `flutter test test/label_sheet_import_codec_test.dart test/label_sheet_import_layout_test.dart test/label_sheet_toolbar_test.dart` 168 tests passed.
- analyzer: `flutter analyze`는 변경 파일이 아닌 `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`의 기존 미사용 선언 10건으로 종료 코드 1. 이번 변경 파일 진단은 별도 확인한다.
- 변경 파일 진단: import layout, workbench, layout test 모두 0 errors.
- 전체 테스트: `flutter test` 824 tests passed.
- stage 예정: import layout, workbench, layout test 3개만 포함. `SESSION_HANDOFF.md`와 unrelated dirty 파일은 제외.
- stage 검증 완료: 기능 파일 3개만 staged, `git diff --cached --check` 통과. 변경 규모 56 insertions, 8 deletions.
- 기능 커밋: `8d6d1f0` (`라벨 가져오기 레이아웃 정책 분리`). 원격 push 없음.
- label file 최종 경계: application이 format/decode/layout/scaling/content/payload/file I/O/persistence 정책을 소유하고, workbench에는 picker/controller/mounted/snackbar/dirty lifecycle만 남았다.
- 다음 시작점: label file import/export 책임 분리는 완료 상태다. 후속 요청이 없으면 추가 구조 변경을 진행하지 않는다.

## 완료
- 로컬 가설: workbook 물리 크기 → 전달 fallback → 100×100 순서와 print-area encoded workbook 조립을 application builder로 이동하면 save callback 동작을 보존하면서 workbench의 private 업무 변환을 제거할 수 있다.
- 편집 완료: save codec에 typed `LabelSheetSavePayload` builder를 추가하고 workbench save callback과 file writer encoding을 같은 API로 전환했다.
- 테스트 추가: workbook metadata 우선, 전달 fallback, 100×100 default, encoded workbook decode 계약 2건.
- focused 검증: save payload 2 tests passed.
- 포맷 후 결합 회귀: save payload 2건 + file writer 2건 + label sheet toolbar 161건, 총 165 tests passed.
- 정적 검증: `flutter analyze lib test` 0 issue.
- 전체 검증: `flutter test test` 823 tests passed.
- 구조 검증: `git diff --check`, staged diff check 통과.
- stage/commit 완료: save codec, file writer, workbench, save payload test 4개만 포함하고 이 문서는 제외했다.
- 커밋 완료: `89e7fbd` (`라벨 시트 저장 payload 조립 분리`).

## 완료
- 로컬 가설: print-area 정규화 후 active sheet의 저장 가능한 7개 collection을 검사하는 순수 predicate를 save codec으로 이동하면 export menu/handler 판단을 보존하면서 workbench의 업무 정책을 줄일 수 있다.
- 편집 완료: save codec에 `labelSheetWorkbookHasSaveContent()`를 추가하고 workbench의 menu/handler 중복 predicate를 application API로 전환했다.
- 테스트 추가: 빈 active sheet, 7개 저장 collection 각각, inactive sheet 제외 계약 2건.
- 테스트 어댑터가 신규 파일을 0건으로 반환해 Flutter CLI로 직접 실행했다.
- 첫 CLI 검증은 test fixture의 지원하지 않는 `activeSheetId` 인자와 const map key 때문에 compile 실패; `activeSheetIndex=0` 기본값과 non-const map으로 교정했다.
- focused 검증: save content policy 2 tests passed.
- 포맷 후 결합 회귀: save content policy 2건 + label sheet toolbar 161건, 총 163 tests passed.
- 정적 검증: `flutter analyze lib test` 0 issue.
- 전체 검증: `flutter test test` 821 tests passed.
- 구조 검증: `git diff --check`, staged diff check 통과.
- stage/commit 완료: save codec, workbench, save content test 3개만 포함하고 이 문서는 제외했다.
- 커밋 완료: `61be931` (`라벨 파일 내보내기 내용 정책 분리`).

## 완료
- 로컬 가설: picker 이후 `.lms` 확장자 보정, print-area save payload 생성, flush 파일 쓰기를 application writer로 이동하고 최종 경로를 반환하면 export 동작을 보존하면서 workbench에는 picker와 UI lifecycle만 남길 수 있다.
- 편집 완료: `label_sheet_file_writer.dart`에 확장자 helper와 workbook writer를 추가하고 workbench의 export 및 suggested name 처리를 application API로 전환했다.
- 테스트 추가: 확장자 보정, 기존 `.LMS` 보존, 실제 파일 쓰기와 LMS decode 계약 2건.
- focused/포맷 후 검증: file writer 2 tests passed, 변경 파일 diagnostics 0건.
- 테스트 어댑터는 toolbar 파일을 발견하지 못했으나 Flutter CLI 직접 실행으로 toolbar 161 tests passed.
- 정적 검증: `flutter analyze lib test` 0 issue.
- 전체 검증: `flutter test test` 819 tests passed.
- 구조 검증: `git diff --check`, staged diff check 통과.
- stage/commit 완료: file writer, workbench, file writer test 3개만 포함하고 이 문서는 제외했다.
- 커밋 완료: `c582611` (`라벨 파일 내보내기 writer 분리`).
- label file import/export 최근 디렉터리 `SharedPreferences` load/save를 application settings API로 이동한다.
- 로컬 가설: 빈 저장값을 null로 정규화하고 성공한 파일 경로의 parent만 저장하면 기존 picker와 import/export 동작을 보존하면서 workbench의 prefs 전달을 제거할 수 있다.
- 수정 예정: `label_sheet_file_settings.dart`와 전용 테스트 추가, workbench load/save 전환 및 `prefs` 매개변수 제거.
- 편집 완료: 최근 디렉터리 load와 파일 경로 parent 저장을 application API로 이동하고 workbench의 key/prefs 전달을 제거했다.
- 테스트 추가: 빈 저장값 null 정규화, parent 저장, 빈 경로 무시 계약 1건.
- focused/포맷 후 검증: file settings 1 test passed.
- workbench 회귀: label sheet toolbar 161 tests passed.
- 정적/구조 검증: `flutter analyze lib test` 0 issue, 변경 파일 diagnostics 0건, 직접 key 접근은 application settings 1곳만 존재.
- 전체 검증: `flutter test test` 817 tests passed, `git diff --check` 통과.
- stage/commit 완료: file settings, workbench, file settings test 3개만 포함하고 이 문서는 제외했다.
- 커밋 완료: `eca0f84` (`라벨 파일 디렉터리 설정을 application으로 분리`).

## 최근 완료
- import path/name 확장자 우선순위와 XLSX layout 선택을 application codec의 단일 format 판정으로 통합했다.
- `LabelSheetImportFormat`과 `labelSheetResolveImportFormat()`을 추가했다.
- decode와 workbench scaling 선택이 같은 path 우선 format resolver를 사용한다.
- path 우선, 대소문자 무시, unknown format 계약 테스트 1건을 추가했다.
- focused 검증: import codec 3 tests passed.
- workbench 회귀: label sheet toolbar 161 tests passed.
- 정적 검증: `flutter analyze lib test` 0 issue, 변경 파일 diagnostics 0건.
- 전체 검증: `flutter test test` 816 tests passed, `git diff --check` 통과.
- stage/commit 완료: codec, workbench, codec test 3개만 포함하고 이 문서는 제외했다.
- 커밋 완료: `6ca40ba` (`라벨 import 형식 판정을 application으로 통합`).

- `3272da2`: 라벨 import sheet identity/zoom/layout 조립을 application으로 이동.
- `a9c8be8`: imported sheet 물리 크기 보존과 폭/최소 가독성 scaling 정책 분리.
- `fe2f448`: LMS/XLSX 확장자 선택, bytes sniffing, workbook decode를 application codec으로 분리.
- `f7c8ee5`: image import draft 임시 XLSX writer를 application으로 분리.
- `8f104d6`: image import dialog launcher를 presentation으로 분리.
- `5cf8c0c`: 저장 이미지 selection loader를 presentation으로 분리.
- `5926095`: image import 설정 persistence를 application으로 분리.

## 다음 시작점
- workbench의 남은 label file import/export method가 picker, `XFile` bytes, controller apply, mounted/snackbar orchestration만 소유하는지 인접 경로를 감사한다.
- 순수 format/decode/layout/content/payload/file I/O 정책이 더 남지 않았다면 label file 책임 분리는 완료로 판정하고 다음 대형 workbench 책임으로 이동한다.

## 주의사항
- `SESSION_HANDOFF.md`는 stage/commit에서 제외한다.
- 원격 push와 Windows/installer 배포 파일 생성은 명시 요청 전까지 수행하지 않는다.
- 범위 밖 사용자 변경이 있으면 유지하고 현재 작업 파일만 stage한다.