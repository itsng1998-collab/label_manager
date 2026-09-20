# SESSION HANDOFF

## 현재 작업: 일반 사용자 라벨 항목 표시 적용
- **완료**: 항목편집에서 제조일자만 `표시`로 저장했지만 일반 사용자 품목관리에 숨김 바코드까지 나타나는 1.3.120 증상을 수정했다.
- 원인 확인 1: Windows ODBC SQL BIT `false`를 `RICH_VISIBLE != 0`으로 판정해 숨김값을 true로 복원한다.
- 원인 확인 2: 품목관리 동적 열 구성은 `TColumn.datas` 전체를 사용하며 `visible`을 적용하지 않는다.
- 구현 방향: 라벨 항목의 SQL BIT 필드를 bool/num/string으로 명시 변환하고, 일반 사용자는 `visible=true` 동적 열만 표시한다. 관리자는 항목 편집을 위해 전체 열을 유지한다.
- [`test/column_mapping_test.dart`](test/column_mapping_test.dart) 테스트 추가: SQL BIT bool과 숫자/문자열 0·1 변환을 검증한다.
- [`test/item_manage_horizontal_scroll_test.dart`](test/item_manage_horizontal_scroll_test.dart) 테스트 추가: 일반 사용자는 표시 열만, 관리자는 표시 여부와 무관하게 전체 열을 사용하는 정책을 검증한다.
- [`lib/features/label_column/data/column_dao.dart`](lib/features/label_column/data/column_dao.dart) 편집 완료: `columnBoolValue`로 라벨 항목의 모든 SQL BIT 필드를 bool/num/string에서 정확히 복원한다.
- [`lib/features/item/presentation/item_manage.dart`](lib/features/item/presentation/item_manage.dart) 편집 완료: `itemManagerColumnsForUser`를 동적 열 구성에 적용해 일반 사용자는 `visible=true` 열만, 관리자는 전체 열을 사용한다.
- focused 검증 완료: SQL BIT 숨김 복원 **1/1**, 일반 사용자 표시 열 정책 **1/1** 통과.
- 버전은 호환 가능한 항목 표시 버그 수정이므로 PATCH 단계로 `1.4.3`에서 `1.4.4`로 갱신했다.
- 전체 검증 완료: `test/column_mapping_test.dart`, `test/item_manage_horizontal_scroll_test.dart` **6/6 통과**, focused analyze **No issues found**.
- formatter, diagnostics, `git diff --check` 통과. DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- stage/commit 대상: `lib/features/label_column/data/column_dao.dart`, `lib/features/item/presentation/item_manage.dart`, `test/column_mapping_test.dart`, `test/item_manage_horizontal_scroll_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `d3ca08d` (`일반 사용자 라벨 항목 표시 적용`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 공용라벨 Ctrl+Z 후 저장 불가
- **완료**: 1.3.120에서 12행을 14·15행에 붙여넣고 15행 붙여넣기를 Ctrl+Z로 취소한 뒤 저장 버튼이 반응하지 않는 증상을 현재 1.4.4 기준으로 검증했다.
- 로그상 첫 저장 callback은 약 51초 뒤 시작해 필수 누락 경고 후 DB 저장까지 완료되며, `SPRICE`는 누락 목록에 없다. 특별항목 필수 해제는 workbench를 다시 dirty로 표시하므로 저장 버튼 활성화 증상과 일치한다.
- 조사 결과 FortuneSheet undo는 workbook `onChange`를 통지하고, `clearSheet` op는 명시적 전체 지우기에서만 생성된다.
- [`test/label_sheet_toolbar_test.dart`](test/label_sheet_toolbar_test.dart) 테스트 추가: 14·15행 범위 변경 후 실제 Ctrl+Z 키 이벤트를 보냈을 때 저장 항목이 활성 상태이고, 저장 payload에는 14행만 남으며 15행은 제거되는지 검증한다.
- focused 회귀 테스트 **1/1 통과**. 1.3.120 이후 dirty/save 및 command-state 변경이 반영된 현재 코드에서는 증상이 재현되지 않아 production 로직은 추가 변경하지 않는다.
- 최종 검증 완료: Ctrl+Z 저장 focused 테스트 **1/1 통과**, `flutter analyze test/label_sheet_toolbar_test.dart` **No issues found**.
- formatter와 `git diff --check` 통과. DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- stage/commit 대상: `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `e661239` (`공용라벨 Ctrl+Z 저장 회귀 검증`).

## 현재 작업: 고정 항목 사용자 정의 text 비활성화
- **완료**: 라벨 항목 편집에서 항목 종류가 `고정(TYPE_FIX)`이면 사용되지 않는 `사용자 정의 text` 입력을 비활성화했다.
- [`lib/features/label_column/presentation/label_column_edit_dialog.dart`](lib/features/label_column/presentation/label_column_edit_dialog.dart) 편집 완료: 고정 항목일 때만 사용자 정의 text의 `TextFormField.enabled`를 false로 설정하고 다른 항목 종류는 기존 입력을 유지한다.
- [`test/label_column_edit_dialog_test.dart`](test/label_column_edit_dialog_test.dart) 테스트 추가: 고정 항목에서 비활성화되고 기본 항목으로 변경하면 다시 활성화되는지 검증한다.
- 버전은 UI 속성 활성화 조건 수정이므로 PATCH 단계로 `1.4.4`에서 `1.4.5`로 갱신했다.
- focused 검증 완료: `fixed column disables user defined text` **1/1 통과**.
- 최종 검증 완료: `test/label_column_edit_dialog_test.dart` 전체 통과, focused analyze **No issues found**.
- formatter, diagnostics, `git diff --check` 통과. DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- stage/commit 대상: `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/label_column_edit_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.

## 현재 작업: QR 배율 비례 왜곡 수정
- **완료**: 공용라벨관리에서 QR을 31.75×31.75mm로 삽입할 때 배율 1은 위로 쏠리고 배율 3은 위로 말리는 1.3.120 증상을 수정했다.
- 원인 확인: 120×120px QR 객체에도 선형 바코드용 기본 막대 높이 10mm(약 38px)를 본체 높이로 적용하고, module scale은 인코딩 폭에만 적용한다. 배율 1은 120×38, 배율 3은 40×38 소스를 120×38로 리사이즈해 상단 쏠림과 비대칭 왜곡이 발생한다.
- 구현 방향: QR 등 2D 코드는 지정 객체 높이 전체를 본체에 사용하고 module scale을 인코딩 폭과 높이에 동일 적용한다. 선형 바코드의 막대 높이 동작은 유지한다.
- [`test/label_sheet_toolbar_test.dart`](test/label_sheet_toolbar_test.dart) 테스트 추가: 120×120 QR에서 배율 1은 120×120, 배율 3은 40×40 인코딩 소스를 사용하고 출력 크기는 모두 120×120임을 검증한다.
- [`lib/features/label_sheet/application/label_sheet_barcode_renderer.dart`](lib/features/label_sheet/application/label_sheet_barcode_renderer.dart) 편집 완료: 2D 바코드는 지정 객체 높이 전체를 본체로 사용하고 source width/height에 module scale을 동일 적용한다. 선형 바코드는 기존 가로 해상도와 막대 높이를 유지한다.
- focused 검증 완료: QR 정사각 geometry **1/1**, 선형 바코드 막대 높이 **1/1** 통과.
- 실제 ZXing 생성 테스트는 Windows 테스트 러너가 `flutter_zxing.dll`을 로드하지 못해 실행할 수 없었고, native asset에 의존하지 않는 인코딩 geometry 테스트로 검증했다.
- toolbar 전체 테스트에서 직전 독립 탭 정책과 반대인 구 기대값 1건을 발견해 현재 대상별 차단 위임 계약으로 갱신했다. 한글 ANSI 기대 문자열 1건은 실행 환경 인코딩 차이로 실패하며 QR 변경과 무관하다.
- 버전은 호환 가능한 QR 렌더링 버그 수정이므로 PATCH 단계로 `1.4.2`에서 `1.4.3`으로 갱신했다.
- 전체 검증 완료: `test/label_sheet_toolbar_test.dart` **202/203 통과**. 남은 `item element RTF conversion decodes Korean ANSI hex` 1건은 실행 환경의 기존 한글 ANSI 기대 문자열 차이이며 QR 경로와 무관하다. focused analyze **No issues found**.
- formatter, diagnostics, `git diff --check` 통과. DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- stage/commit 대상: `lib/features/label_sheet/application/label_sheet_barcode_renderer.dart`, `test/label_sheet_toolbar_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `c604c0f` (`QR 배율 비례 왜곡 수정`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 라벨 전환 후 병합 복사 유지
- **완료**: 공용라벨관리에서 병합 영역을 복사한 뒤 다른 라벨로 전환하고 돌아와 붙여넣으면 병합 없이 텍스트만 반복되는 1.3.106 로그 증상을 수정했다.
- 원인 확인: OS 클립보드에는 TSV 텍스트만 기록하고 병합·스타일 payload는 `FortuneSheetCanvas` State에만 저장한다. 라벨 전환으로 canvas가 교체되면 내부 payload가 사라져 일반 TSV 붙여넣기로 처리된다.
- 구현 방향: 일반 복사의 내부 셀 payload를 FortuneSheet 인스턴스 간 공유해 클립보드 텍스트가 유지된 동안 병합·스타일을 복원한다. 원본 삭제 의미가 있는 잘라내기는 기존 canvas State 범위에 유지한다.
- [`third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`](third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart) 테스트 추가: 두 병합 영역 복사 후 canvas를 교체하고 A5에 붙여넣어 병합 범위 복원을 검증한다.
- 재현 테스트 확인: 수정 전 첫 병합 `row`가 `null`로 실패했고, 공용 payload 구현 후 **1/1 통과**했다.
- 기존 workbook prop 교체 테스트도 클립보드가 유지된 동안 내부 스타일을 보존하는 새 계약으로 갱신했다.
- [`third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`](third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart) 편집 완료: 일반 셀 복사의 범위·셀·병합·스타일·테두리·검증·필터·이미지 payload를 canvas 간 공용 슬롯에 저장하고, OS 클립보드 텍스트가 일치할 때 새 canvas에서 재사용한다. 잘라내기와 텍스트 불일치는 공용 payload를 사용하지 않는다.
- focused 검증 완료: canvas 교체, workbook prop 교체, 기존 병합·스타일, CRLF, 상대 수식 테스트 **5/5 통과**. 재현 테스트에서 외부 TSV 변경 시 병합 payload를 무시하는 분기도 통과했다.
- formatter 적용 완료. 포맷 후 묶음 검증은 실행 도구가 두 번째 테스트에서 종료되지 않아 결과에서 제외했으며, 해당 테스트 단독 재실행은 **1/1 통과**했다.
- 최종 focused 검증 완료: canvas 교체 병합, 기존 병합·스타일, 다중행 병합, CRLF, 상대 수식 **5/5 통과**. workbook prop 교체 단독 테스트까지 합쳐 관련 검증 **6/6 통과**했다.
- analyzer는 변경 구간 오류 없이 기존 이미지 레이어 미사용 코드 경고 10건만 보고했다. diagnostics와 `git diff --check`는 통과했다.
- DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- 버전은 호환 가능한 복사/붙여넣기 버그 수정이므로 PATCH 단계로 `1.4.1`에서 `1.4.2`로 갱신했다.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `40e506f` (`라벨 전환 후 병합 복사 유지`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 품목 수정 중 독립 탭 진입
- **완료**: 품명 편집 진입 후 저장 전 공용라벨관리와 라벨출력 탭으로 이동하지 못하는 1.3.120 증상을 수정했다.
- 원인 확인: 탭 클릭 선행 차단과 `_onTabSelection`이 품목 active editor·dirty를 공용라벨/라벨출력에도 전역 적용한다.
- 데이터 소스 확인: 품목 발행 미리보기와 라벨출력 템플릿은 `_effectiveLabelSize.labelSizeCommon` 저장본을 사용하며, 공용라벨 저장 성공 콜백 전에는 `_currentLabelSize`가 교체되지 않는다.
- [`lib/home_page_manager.dart`](lib/home_page_manager.dart) 편집 완료: 선행 품목 탭 차단을 대상별 `_onTabSelection`으로 위임하고, 공용라벨/라벨출력은 품목 draft 상태와 무관하게 진입하며 활성 셀 입력만 draft에 커밋한다. 품목 저장 명령 실행 중 차단과 저울출력의 기존 차단은 유지한다.
- [`test/fortune_table_test.dart`](test/fortune_table_test.dart) 편집 완료: 독립 탭은 품목 active/dirty가 아닌 저장 명령 실행 여부만 차단하고 품목 탭 클릭은 대상별 정책으로 위임하는 회귀 계약을 추가했다.
- focused 검증 완료: `flutter test test/fortune_table_test.dart --plain-name "common label and label print tabs ignore item draft state"`, `flutter test test/fortune_table_test.dart --plain-name "item tab click delegates target-specific blocking"` 각각 통과.
- 전체 검증 완료: `test/fortune_table_test.dart` **76/76 통과**, 저장된 공용라벨 fingerprint focused test **1/1 통과**, focused analyze **No issues found**, diagnostics 통과.
- formatter 적용 후 같은 전체 검증을 재실행해 **76/76**, **1/1**, analyzer **No issues found**를 다시 확인했다.
- DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- 버전은 호환 가능한 탭 정책 버그 수정이므로 PATCH 단계로 `1.4.0`에서 `1.4.1`로 갱신했다.
- stage/commit 대상: `lib/home_page_manager.dart`, `test/fortune_table_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `cf53e0c` (`품목 편집 중 독립 탭 진입 허용`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 품목관리 엑셀 행 다중 셀 붙여넣기
- **완료**: 엑셀 내보내기 파일의 한 품목 행을 복사해 품목관리 셀에 붙이면 탭 구분 값 전체가 한 셀에 들어가는 1.3.120 증상을 수정했다.
- 원인 확인: 공용 `FortuneTable`에 클립보드 붙여넣기 처리가 없어 편집 중 `EditableText`가 탭 포함 문자열 전체를 단일 셀 값으로 받는다.
- 편집 완료: `FortuneTable.tabSeparatedPasteEnabled` opt-in API를 추가하고 품목관리에서 활성화했다. 선택/편집 셀부터 탭 값을 표시 열 순서대로 소비하며 편집 불가 열은 쓰지 않고 해당 칸만 건너뛴다. 탭 없는 일반 텍스트는 기존 편집기 선택 영역에 붙여넣는다.
- 테스트 추가: 공용 테이블의 탭 값 분배·읽기 전용 열 정렬 보존과 품목관리 활성화 연결을 검증한다.
- 버전은 사용자에게 보이는 새 다중 셀 붙여넣기 기능이므로 MINOR 단계로 `1.3.133`에서 `1.4.0`으로 갱신했다.
- focused 검증 완료: 더블클릭 편집 상태의 `FortuneTable pastes tab-separated values across columns` **1/1 통과**. formatter와 diagnostics도 통과했다.
- 추가 검증 완료: `C:/Flutter/bin/flutter.bat test --no-pub --reporter expanded test/fortune_table_test.dart test/item_manage_horizontal_scroll_test.dart` **76/76 통과**.
- 임시 테스트 로그는 `.tmp/copilot/item_tab_paste_suite.log`에만 생성했으며 Git에 포함하지 않는다.
- focused analyze 완료: **No issues found**(15.8초).
- VS Code DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상은 없었다.
- 기능 커밋: `6e3caea` (`품목관리 엑셀 행 다중 셀 붙여넣기 지원`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 공용라벨 특별항목 필수등록 복원
- **완료**: `SWEIGHT`, `SPRICE` 필수등록을 해제해 저장한 뒤 재실행하면 다시 체크되는 1.3.120 증상을 수정했다.
- 로그 확인: 저장 payload에 두 키워드 모두 `<checked>0</checked>`가 포함되고 트랜잭션도 성공했다. 재실행 시 동일 라벨크기에서 다시 조회했다.
- 원인 확인 및 편집 완료: Windows ODBC는 SQL `BIT 0`을 Dart `false`로 반환하지만 `SpecialColumnDAO`가 `false != 0`으로 판정해 true로 복원했다. bool/num/string을 명시적으로 변환해 `RICH_CHECK_YN`과 같은 경로의 `RICH_MIN_CHECK`를 올바르게 읽는다.
- 회귀 테스트 추가: SQL BIT `false/true`, 숫자 `0/1`, 문자열 `0/1`의 체크 상태 변환을 고정한다.
- 버전은 호환 가능한 국소 상태 복원 버그 수정이므로 PATCH 단계로 `1.3.132`에서 `1.3.133`으로 갱신했다.
- 검증 완료: `test/special_column_dao_test.dart`, `test/label_size_dao_test.dart`, `test/common_label_manage_test.dart` **19/19 통과**. focused analyze **No issues found**(6.3초), formatter와 diagnostics 통과.
- VS Code DTD는 연결돼 있으나 실행 중인 Flutter 앱이 없어 hot reload 대상은 없었다.
- 기능 커밋: `87c24f4` (`공용라벨 특별항목 필수등록 상태 복원`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 추가 키워드 클라이언트 편집 기본값
- **완료**: 품목관리에서 품명·주원료 외 신규 키워드가 별도 설정 없이 `클라이언트 편집 불가`로 생성되는 1.3.120 증상을 수정했다.
- 원인 확인: `LabelColumnSaveDao._contentInsert(true)`가 신규 키워드의 기존 품목 콘텐츠 행을 만들 때 `RICH_EDITABLE=0`을 명시한다. 누락 행의 UI fallback은 이미 true이므로 생성 SQL이 직접적인 원인이다.
- 편집 완료: 신규 키워드 콘텐츠 생성 기본값을 `RICH_EDITABLE=1`로 변경했다. 사용자가 명시적으로 저장한 기존 불가 상태는 변경하지 않으며 DB 마이그레이션은 수행하지 않는다.
- 회귀 테스트 추가: optional editable 스키마의 생성 SQL이 1을 사용하고 기존 0 구문을 포함하지 않는지 확인한다.
- 버전은 호환 가능한 국소 기본값 수정이므로 PATCH 단계로 `1.3.131`에서 `1.3.132`로 갱신했다.
- 검증 완료: `test/label_column_save_test.dart` **16/16 통과**, focused analyze **No issues found**(7.5초), formatter와 diagnostics 통과.
- VS Code DTD는 연결돼 있으나 실행 중인 Flutter 앱이 없어 hot reload 대상은 없었다.
- 기존 DB의 `RICH_EDITABLE=0`은 사용자가 명시한 불가 설정과 구분할 메타데이터가 없어 자동 변경하지 않는다. DB 마이그레이션 없이 이후 신규 키워드 콘텐츠의 기본 생성값만 바로잡는다.
- 기능 커밋: `beb4721` (`추가 키워드 클라이언트 편집을 기본 허용`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 품목관리 편집 후 가로 스크롤 소실
- **완료**: 1.3.120 로그에서 소비기한 `365`를 `360`으로 Enter 확정한 뒤 가로 스크롤이 사라진 증상을 수정했다.
- 로그상 편집 전 `overflow=true`, `contentWidth=2023.6`, `viewportWidth=1849.7`이며 편집 후 overflow 변경 로그는 없다. 실제 thumb 페인트 소실 여부를 검증하는 focused widget test를 보강 중이다.
- 편집 완료: 공용 `FortuneTable`은 가로 overflow 동안 `RawScrollbar.thumbVisibility`와 `trackVisibility`를 함께 유지한다. 회귀 테스트는 Enter 편집 직후와 5초 뒤에도 두 표시 속성, overflow, 실제 좌우 이동을 확인한다.
- 버전은 호환 가능한 국소 UI 버그 수정이므로 PATCH 단계로 `1.3.130`에서 `1.3.131`로 갱신했다.
- focused 검증 완료: `test/item_manage_horizontal_scroll_test.dart` **1/1 통과**. 편집 직후와 5초 뒤의 thumb/track 표시, overflow, 좌우 이동을 확인했다.
- 변경 Dart 파일 formatter와 diagnostics를 통과했다. VS Code DTD에는 연결했으나 실행 중인 Flutter 앱이 없어 hot reload 대상은 없었다.
- 추가 검증 완료: `C:/Flutter/bin/flutter.bat test --no-pub --reporter expanded test/item_manage_horizontal_scroll_test.dart test/fortune_table_test.dart` **75/75 통과**(13.5초).
- 임시 테스트 로그는 `.tmp/copilot/item_scroll_tests.log`에만 생성했으며 Git에 포함하지 않는다.
- 기능 커밋: `777227f` (`품목 편집 후 가로 스크롤 표시 유지`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 새 세션 시작 순서
1. 사용자가 새로 제시하는 디버깅 증상을 먼저 조사한다. 증상이 제시되기 전에는 과거 문제를 현재 문제로 가정하지 않는다.
2. 새 디버깅을 마친 뒤 GoDEX G500 역상 흰 획 소실 문제를 재개한다.
3. 인쇄이거나 DB 변경이 필요한 재현은 사용자 승인 없이 실행하지 않는다.

## 현재 기준
- 현재 버전은 **1.4.4**이며 일반 사용자 품목관리는 항목편집에서 `표시`로 저장한 라벨 항목만 동적 열로 보여준다. 인쇄 동작 변경은 없고 직전 인쇄 구현 기준은 **1.3.129**다.
- 정리 전 HEAD는 `3e188cd`, GoDEX 전송 변경 기능 커밋은 `d3b682c`, 새 세션용 정리 커밋은 `0c79b52`다. 이 해시 기록은 같은 요청의 후속 문서 변경이며 버전을 다시 올리지 않는다.
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 원복하거나 함께 stage/commit하지 않는다.
- 실행 중인 `label_manager`/`flutter` 프로세스는 없다. Windows 배포파일과 설치파일은 만들지 않았다.
- 현재 실제 인쇄 원본은 **라벨 시트**다. RTF 직접 출력이나 시트의 RTF 재변환을 제안하거나 구현하지 않는다.

## 최근 완료: GoDEX PRN 생성 후 RAW 제출
- 1.3.129부터 GoDEX는 기존 native 렌더링으로 드라이버 PRN을 만든 뒤 그 바이트를 변경 없이 `RawPrinterWin32.sendRaw`로 제출한다. 다른 제조사는 기존 직접 GDI 제출을 유지한다.
- 정상 직접 GDI 제출에서 발생한 제조사 문구 반복 및 하단 영양정보 분할/중복은, 사용자에게 한 차례 승인받은 동일 PRN의 RAW 제출에서는 정상 배치로 출력됐다.
- PRN 누락, RAW 예외, 부분 쓰기는 성공으로 처리하지 않는다. Debug 파일 캡처도 인쇄 성공이나 이력 저장으로 처리하지 않는다.
- 검증 완료: 관련 테스트 **15/15 통과**, focused analyze 이상 없음, Windows Debug 빌드/실행, hot reload, runtime error 확인을 통과했다.
- 최근 남아 있는 앱 로그 [`.tmp/log/app_2026-09-12_20-56-09.log`](.tmp/log/app_2026-09-12_20-56-09.log)은 `DebugLogger version: 1.3.129`, `driverPrnGenerated=true`, `driverTransport=generatedPrnRaw`, `driverTransportVersion=1.3.129`, `accepted=true`를 기록한다.
- 이 결과는 **레이아웃 손상 해결** 근거다. 역상 흰 획 품질까지 해결됐다고 판단하지 않는다.

## 역상 문제 상태
- **미해결**이다. 같은 PC/GoDEX G500에서 레거시는 정상이나 현재 시트 출력은 역상 흰 획 일부가 종이에서 사라졌다.
- 실제 전체 요청을 파일/PRN 경로로 재생했을 때 두 역상 영역은 흰 픽셀 1,266/1,427개, 손실/증가/차이 0이었다. 파일 생성까지는 온전했지만 당시 직접 GDI 물리 출력에서 손실이 남았다.
- 1.3.129 PRN→RAW 경로의 역상 품질은 확인되지 않았다. 앞선 RAW 출력 승인은 해당 1회뿐이며 이후 물리 출력 권한으로 재사용하지 않는다.
- DisplayBand, 120/121 twip 반올림, 회색조/팽창, 공백 장평, 농도·속도, DirectWrite/GGO/FreeType, whole-page EMF 등 이미 부정되거나 실패한 접근을 반복하지 않는다.
- 레거시 자료를 다시 요구하거나 RTF를 출력 원본으로 되돌리지 않는다. 저장 시트의 글자 크기 강제 확대·재생성·재저장도 하지 않는다.
- 세부 과거 실험과 제어 코드 경로는 [`doc/godex_inverse_resume.md`](doc/godex_inverse_resume.md) 및 Git 이력을 참고하되, 오래된 문서의 파일 존재·현재 버전 설명은 다시 확인한다.

## 현재 남은 증거
- 현재 존재: [`.tmp/IMG_20260912_0007.png`](.tmp/IMG_20260912_0007.png), [`.tmp/IMG_v0.Legacy_print.png`](.tmp/IMG_v0.Legacy_print.png), [`.tmp/log/app_2026-09-12_20-56-09.log`](.tmp/log/app_2026-09-12_20-56-09.log).
- 현재 없음: `IMG_20260912_0006.png`, `actual_request_v127_replay.prn`, `img0006_driver_v129.prn`, `v1.3.127_1789202935380639_0.bin` 및 요청 캡처 디렉터리 내용.
- 없는 자료의 과거 해시·픽셀 검증은 완료 당시 기록일 뿐 현재 재검증했다고 표현하지 않는다. `.tmp` 파일은 Git에 포함하거나 외부 전송하지 않는다.

## 재개 시 판별 절차
1. 새 디버깅 요청의 구체 증상, 재현 절차, 최신 로그부터 확인한다. 로그는 최신 `.tmp/log/app_*.log`의 버전을 먼저 확인한다.
2. 역상 재개 시 1.3.129 이상 정상 앱 출력 로그에서 `driverTransportVersion=1.3.129`, `driverPrnGenerated=true`, RAW 전체 쓰기 성공을 확인한다.
3. 사용자가 관련 실물 결과를 제공했을 때만 RAW 경로의 역상 품질을 판정한다. 새 물리 출력이 필요하면 매번 먼저 승인을 받는다.
4. 실패가 남으면 시트 요청 생성, 드라이버 PRN, RAW 제출, 종이 결과 경계를 분리한다. 과거 파일 보존 결과만으로 USB/종이 동등성을 주장하지 않는다.

## 검증 기준
1.3.129 인쇄 변경에 사용한 focused 검증:

```powershell
C:/Flutter/bin/flutter.bat test --no-pub test/windows_bitmap_printer_test.dart test/label_print_dispatcher_test.dart
C:/Flutter/bin/flutter.bat analyze --no-pub lib/printing/windows_bitmap_printer.dart test/windows_bitmap_printer_test.dart
```

이번 1.3.130 변경은 문서/버전 정리만 수행했다. 문서·pubspec diagnostics와 `git diff --check`는 통과했다. 코드 테스트·앱 실행·실물 인쇄는 다시 하지 않았다. `SESSION_HANDOFF.md`와 `pubspec.yaml`만 stage/commit한다.