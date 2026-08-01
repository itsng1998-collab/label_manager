# 완료: 라벨 workbench 업무 정책 분리

## 완료: 공용라벨 필수등록 수동 변경 반영
- 재현 화면: 특별 항목의 `저울중량`, `최종가격` 필수등록을 언체크해도 저장 시 누락 경고가 계속 표시된다. 사용 항목도 같은 구조다.
- 원인: `requiredKeywords`는 `CommonLabelManage.build()`에서 snapshot으로 생성되지만 `_CommonLabelTable` 체크박스는 내부 `setState()`로 모델만 바꾸고 부모를 rebuild하지 않는다.
- 수정 예정: 특별/사용 항목 체크 변경을 부모까지 전달해 현재 `useMissingKeywordCheck` 상태로 저장 검증 목록을 즉시 재계산한다. 실제 언체크 이벤트 회귀 테스트를 추가한다.
- 편집 완료: `_CommonLabelTable → _RightPane → CommonLabelManage`로 `onRequiredChanged`를 전달하고 부모 `setState()`에서 `requiredKeywords`를 현재 모델로 재계산한다. 특별/사용 항목 모두 같은 경로를 사용한다.
- 1차 검증 완료: 실제 FortuneTable 체크박스 언체크 후 모델 값 `false`, 부모 callback 1회, `commonLabelRequiredKeywordsFromColumns()` 빈 목록을 확인했다. 변경 파일 diagnostics 0건.
- formatter 완료: `dart format lib/features/label_sheet/presentation/common_label_manage.dart test/common_label_manage_test.dart`.
- 전체 검증 완료: `test/common_label_manage_test.dart`, `test/label_sheet_toolbar_test.dart` 총 178개 통과. 변경 파일 `flutter analyze` issue 없음.
- 최종 검증 완료: `git diff --check` 통과, `pubspec.yaml` 버전 `1.0.1` 유지. 사용자 변경 `lib/core/app.dart`, `lib/core/app_menu_controller.dart`는 제외하고 대상 세 파일만 stage/commit한다.
- 기능 커밋: `22fdba4 주원료 줄 수별 여백 누적 제거`.
- Debug 확인 완료: 실행 중 앱 종료 후 `flutter build windows --debug` 성공, 최신 앱을 다시 실행했다.
- 기능 커밋: `bbfc665 공용라벨 필수등록 변경 즉시 반영`.
- Debug 확인 완료: 실행 중 앱 종료 후 `flutter build windows --debug` 성공, 최신 앱을 다시 실행했다.

## 완료: `#ELEMENT` 병합 셀 세로 여백 통일
- 최신 두 화면 비교: 주원료 줄 수가 늘수록 병합 셀의 위/아래 여백도 증가한다.
- 확정 원인: FortuneSheet 일반 셀 렌더러는 `lineHeight` 미지정 시 `TextStyle.height=null`을 사용하지만 `_itemPreviewTextStyle()`만 기본 `height=1.2`를 강제해 각 줄의 leading을 누적했다.
- 수정 예정: 대상 라벨 셀에 명시된 `lineHeight`만 사용하고 기본은 null로 맞춘다. 내용 줄 수와 무관하게 실제 text height 외 세로 여백은 합계 6px로 고정한다.
- 편집 완료: `_itemPreviewTextStyle()`의 기본 `height`를 null로 변경해 FortuneSheet 화면·캡처 renderer와 동일한 font metrics를 사용한다.
- 집중 검증 완료: 1줄과 3줄 각각 `계산 행 높이 - 실제 TextPainter 높이 = 6px`임을 확인했다. 변경 파일 diagnostics 0건.
- 전체 검증 완료: 출력 미리보기·바코드 resolver·출력 pipeline 관련 테스트 180개 통과. `flutter analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart` issue 없음.
- 최종 검증 완료: `git diff --check` 통과, `pubspec.yaml` 버전 `1.0.1` 유지. 사용자 변경 `lib/core/app.dart`, `lib/core/app_menu_controller.dart`는 제외하고 대상 세 파일만 stage/commit한다.
- 추가 제출 화면 확인: 병합 폭 수정 후에도 주원료 내용이 길수록 위/아래 여백이 증가한다.
- 추가 원인: `fontScale`/첨자 inline run은 FortuneSheet가 저장된 개행 단위로 렌더링하지만 `_itemPreviewRequiredRowHeight()`는 폭 기준 자동 줄바꿈으로 높이를 측정해 실제로 그리지 않는 줄 높이를 누적한다.
- 추가 수정 예정: FortuneSheet와 동일하게 해당 rich run은 저장된 줄 단위 높이만 합산하고, 일반 셀과 같은 고정 세로 여백 6px만 더한다.
- 출력 경로 확인: PDF/EZPL 캡처는 `captureRangeAsPng()`/`captureHybridPlanAsPng()`의 일반 TextPainter 줄바꿈을 사용한다. 미리보기와 실제 출력 일치를 위해 주원료 편집 전용 `fontScale`도 병합 run에서 제거하고 대상 라벨 셀의 일반 줄바꿈·고정 6px 여백을 사용한다.
- 편집 완료: 병합 run에서 `lineHeight`와 `fontScale`만 제거한다. 내용이 길면 대상 셀 폭에 맞춰 필요한 줄 수만 증가하고, 행 높이는 실제 text height + 고정 6px로 계산된다.
- 집중 검증 완료: source `fontScale=80`이 결과 run에서 제거되고 긴 내용이 대상 셀 일반 줄바꿈으로 확장되는 회귀 테스트 통과. 변경 파일 diagnostics 0건.
- 전체 검증 완료: 관련 출력 미리보기·바코드 resolver·출력 pipeline 테스트 179개 통과. `flutter analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart` issue 없음.
- 최종 검증 완료: `git diff --check` 통과, `pubspec.yaml` 버전 `1.0.1` 유지. 사용자 변경 `lib/core/app.dart`, `lib/core/app_menu_controller.dart`는 제외하고 대상 세 파일만 stage/commit한다.
- 기능 커밋: `2141101 주원료 셀 세로 여백 고정`.
- Debug 확인 완료: 실행 중 앱 종료 후 `flutter build windows --debug` 성공, 최신 앱을 다시 실행했다.
- 추가 제출 화면 확인: 주원료 줄 간격 제거 후에도 `#ELEMENT` 행 자체가 크게 남아 텍스트가 가운데 배치된다.
- 추가 원인: 대상은 가로 병합 셀인데 `_itemCellRect()`가 anchor의 첫 열 너비만 사용해 텍스트를 과도하게 여러 줄로 측정한다. 또한 계산 높이가 기존 행보다 작으면 행을 줄이지 않는다.
- 추가 수정 예정: 병합 전체 열 너비로 높이를 계산하고 `#ELEMENT` 행을 계산 높이로 축소·확장한다. 축소 시 아래 이미지·선·도형도 같은 delta로 이동한다.
- 추가 편집 완료: `FortuneCellMerge.columnSpan`의 전체 열 폭을 합산해 텍스트 높이를 측정하고, 기존 행보다 작아도 계산 높이를 적용한다. row shift는 음수 delta도 처리한다.
- 추가 테스트 완료: 4열 병합 `#ELEMENT`의 180px 행이 일반 셀 여백 높이로 축소되고 아래 이미지가 같은 delta로 위로 이동하는 회귀 테스트 통과. 변경 파일 diagnostics 0건.
- 추가 전체 검증 완료: 관련 출력 미리보기·바코드 resolver·출력 pipeline 테스트 178개 통과. `flutter analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart` issue 없음.
- 추가 최종 검증 완료: `git diff --check` 통과, `pubspec.yaml` 버전 `1.0.1` 유지. 사용자 변경 `lib/core/app.dart`, `lib/core/app_menu_controller.dart`는 제외하고 대상 세 파일만 stage/commit한다.
- 추가 기능 커밋: `69eb92d 병합 주원료 셀 높이 계산 수정`.
- Debug 확인 완료: 실행 중 앱 종료 후 `flutter build windows --debug` 성공, 최신 앱을 다시 실행했다.
- 제출 화면 확인: 주원료 시트 셀을 라벨 시트 `#ELEMENT` 셀에 병합하면 대상 라벨의 일반 셀보다 위/아래 여백이 크게 출력된다.
- 원인 가설: `_replaceElementKeywordInCell()`이 주원료 셀·inline run의 `lineHeight`를 대상 라벨 셀에 덮어써 행 높이 계산과 렌더링 모두 주원료 편집 셀의 줄 간격을 사용한다.
- 수정 예정: 주원료의 글자 서식은 유지하되 병합 레이아웃은 대상 라벨 셀의 `extraFields`/`lineHeight`를 사용한다. 공용 output workbook 생성 경로를 수정해 품목관리·라벨출력·저울출력 미리보기와 실제 캡처/프린트에 함께 적용한다.
- 편집 완료: 병합 셀은 대상 라벨 셀 `extraFields`를 유지하고, 삽입되는 주원료 inline run에서는 `lineHeight`만 제거한다. 글꼴·크기·굵기·기울임 등 글자 서식은 유지한다.
- 테스트 추가: source `lineHeight=3.0`이어도 일반 source와 결과 행 높이가 동일하고 대상 셀 `lineHeight=1.2`가 유지되는 회귀를 추가했다.
- 1차 검증 완료: rich run 보존 테스트와 대상 셀 기준 행 높이 수치 테스트 각각 통과. 변경 파일 diagnostics 0건.
- 로그 정리: 사용자 수동 활성화 `itemOutputPreviewMappingDebugEnabled`를 원래 기본값 `false`로 복구했다.
- formatter 완료: `dart format lib/home_page_manager.dart test/label_sheet_toolbar_test.dart`.
- 검증 완료: 출력 미리보기·바코드 resolver·출력 pipeline 관련 테스트 177개 통과. `flutter analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart` issue 없음.
- 실제 출력 적용 확인: 라벨출력과 저울출력 모두 `_ItemOutputPreviewTab`에서 생성된 같은 workbook을 `LabelSheetOutputCaptureController.capture()` 또는 `captureHybridEzpl()`로 캡처하므로 PDF·EZPL hybrid 출력에도 같은 셀/행 높이가 적용된다.
- 최종 검증 완료: `git diff --check` 통과, `pubspec.yaml` 버전 `1.0.1` 유지. 사용자 변경 `lib/core/app.dart`, `lib/core/app_menu_controller.dart`는 제외하고 `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`만 stage/commit한다.
- 기능 커밋: `74be4c7 주원료 병합 셀 세로 여백 통일`.

## 진행 중: 품목 출력 미리보기 특수 품명 키 충돌 수정
- 최신 재현 로그: `itemOutputPreviewMapping-5`에서 `itemName=황치즈쿠키`와 `#품목`은 정상이지만 `#ITEMNAME`은 빈 값이다.
- 원인: 일반 컬럼 보호 뒤에도 `TColumnSpecial`의 `ITEMNAME`이 scale 전용 가상 ID `-1`로 해석돼 빈 projected value를 같은 replacement key에 다시 등록한다.
- 수정 예정: 특수 컬럼 loop에서도 `ITEMNAME`/`품목` 예약 키를 제외하고, `TColumnSpecial` 충돌 회귀를 추가한다.
- 편집 완료: 특수 컬럼 loop에서 예약 키 재등록을 막고, 일반·특수 `ITEMNAME` 충돌 fixture를 기존 출력 미리보기 회귀 테스트에 추가했다.
- 1차 검증 완료: `flutter test test/label_sheet_toolbar_test.dart --plain-name "item output preview uses private active saved sheet only"` 통과. 변경 Dart 파일 diagnostics 0건.
- formatter 완료: `dart format lib/home_page_manager.dart test/label_sheet_toolbar_test.dart`.
- 검증 완료: `runTests(test/label_sheet_toolbar_test.dart, test/item_code_data_resolver_test.dart, test/label_print_pipeline_test.dart)` 결과 176개 통과. `flutter analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart` 결과 issue 없음.
- Debug 번들 완료: 실행 중이던 이전 Debug 앱을 종료하고 `flutter build windows --debug` 성공. 최신 `kernel_blob.bin`에 이번 Dart 수정이 반영됐다.
- 최종 검증 완료: `git diff --check` 통과, `pubspec.yaml` 버전은 `1.0.1`이다. 사용자 변경 `lib/core/app.dart`, `lib/core/app_menu_controller.dart`는 worktree에 남기고 대상 파일만 stage/commit한다.
- 기능 커밋: `dcabec8 출력 미리보기 특수 품명 키 보호`.
- 확인 방법: 최신 Debug 번들에서 품목관리의 문제 행을 선택하면 `#ITEMNAME`이 선택 품명으로 표시된다. 진단 로그는 현재 `itemOutputPreviewMappingDebugEnabled = true`이며, 확인 완료 후 `false`로 되돌린다.

## 완료: 품목 출력 미리보기 제품명 매핑 수정
- 재현 로그 확인: `itemOutputPreviewMapping-3`에서 선택 행 `itemName=황치즈쿠키`는 정상이나, 템플릿 셀 `#ITEMNAME`은 빈 문자열로 치환됐다. `TColumn`의 `ITEMNAME` 일반 컬럼 entry가 앞서 넣은 예약 품명 값을 빈 컬럼값으로 덮어쓰는 것이 원인이다.
- 수정 예정: 일반 컬럼 replacement 생성에서 `ITEMNAME`과 `품목` 예약 키를 제외하고, 동일 이름의 빈 컬럼이 품명을 덮어쓰지 않도록 한다. 진단 로그는 확인 완료 후 기본 비활성화한다.
- 편집 완료: 일반 컬럼 loop에서 두 예약 키를 제외하고, `ITEMNAME` 일반 컬럼이 존재하는 기존 출력 미리보기 테스트에 회귀 조건을 추가했다. 전용 진단 로그는 기본 비활성화했다.
- 1차 검증 완료: `item output preview uses private active saved sheet only` 테스트 1개 통과 및 변경 Dart 파일 diagnostics 0건.
- formatter 완료: `dart format lib/home_page_manager.dart`.
- 검증 완료: `runTests(test/label_sheet_toolbar_test.dart, test/item_code_data_resolver_test.dart, test/label_print_pipeline_test.dart)` 결과 176개 통과. `flutter analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart` 결과 issue 없음.
- 최종 검증 완료: `git diff --check` 통과, `pubspec.yaml` 버전은 `1.0.1`이다. 사용자 변경 `lib/core/app.dart`, `lib/core/app_menu_controller.dart`는 worktree에 남기고 대상 파일만 stage/commit한다.
- 기능 커밋: `73369d9 출력 미리보기 품명 예약 키 보호`.
- 제출 화면 확인: 품목관리 선택 3번 행의 출력내용 미리보기에서 제품명 값이 비어 있다.
- 원인: `_itemOutputPreviewReplacements()`가 `#ITEMNAME`만 품명으로 치환한다. 바코드/QR 출력 resolver가 이미 지원하는 레거시 품명 별칭 `#품목`은 일반 출력 시트 replacement map에 없다.
- 편집 완료: 출력 미리보기 replacement map에 `#품목`을 선택 행 `item.item.itemName`으로 추가했다.
- 테스트 완료: `#ITEMNAME`과 `#품목`이 같은 선택 행 품명으로 치환되는 회귀를 기존 private active sheet 테스트에 추가했다.
- 검증 완료: 집중 테스트 1개와 출력 미리보기·바코드 resolver·출력 pipeline focused 테스트 166개 통과. 변경 Dart 2개 파일 `flutter analyze` 성공, 변경 파일과 `pubspec.yaml` diagnostics 0건, `git diff --check` 성공.
- 수정 위치: `lib/home_page_manager.dart`의 `_itemOutputPreviewReplacements()`.
- 기능 커밋: `435365a 출력 미리보기 품명 별칭 매핑`.
- 사용자 변경 `lib/core/app.dart`, `lib/core/app_menu_controller.dart`는 제외한다.

## 완료: 품목 출력 미리보기 제품명 매핑 진단 로그
- 사용자 확인: `#품목` 별칭 매핑 추가 후에도 제품명이 표시되지 않아, 추가 추측 수정 대신 실제 선택 행·template·cell 치환 경로를 로그로 확인한다.
- 수정 예정: `home_page_manager.dart`의 `itemOutputPreviewMappingDebugEnabled` 한 상수로 제어되는 전용 로그를 추가한다. 선택 item ID/품명, replacement map, 템플릿 keyword cell의 좌표·원문·치환 결과, 완료 상태를 같은 trace로 기록한다.
- 로그 제거 방법: 확인 완료 후 같은 상수를 `false`로 바꾸면 전용 로그가 중단된다.
- 편집 완료: `started → templateDecoded → cellBefore/cellAfter → completed` 순서의 전용 trace 로그를 추가했다. 저장된 라벨 없음·RTF 차단·decode 실패도 별도 event로 기록한다.
- 1차 검증 완료: 기존 출력 미리보기 집중 테스트 1개와 변경 파일 diagnostics 0건을 확인했다.
- formatter 완료: `dart format lib/home_page_manager.dart`.
- 검증 완료: `runTests(test/label_sheet_toolbar_test.dart, test/item_code_data_resolver_test.dart, test/label_print_pipeline_test.dart)` 결과 176개 통과. `flutter analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart` 결과 issue 없음.
- 최종 검증 완료: `git diff --check` 통과, `pubspec.yaml`의 버전은 `1.0.1`이다. 사용자 변경 `lib/core/app.dart`, `lib/core/app_menu_controller.dart`는 worktree에 남기고 대상 파일만 stage/commit한다.
- 커밋: `c94576a 출력 미리보기 매핑 진단 로그 추가`.
- 사용자 확인: 문제의 품목 행을 선택해 출력내용 미리보기를 열고, 최신 `.tmp/log/app_*.log`에서 같은 `itemOutputPreviewMapping-*` trace의 `started`, `templateDecoded`, `cellBefore`, `cellAfter`, `completed` event를 제출한다. 확인 완료 뒤 `itemOutputPreviewMappingDebugEnabled`를 `false`로 바꿔 전용 로그를 중단한다.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- stage/commit 대상: `lib/home_page_manager.dart`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`, `lib/core/app_menu_controller.dart`는 제외한다.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- stage/commit 대상: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.

## 완료: Excel 가져오기 신규 코드 13차 검토
- 앞선 12차까지 확정한 정책은 재검토하지 않고 첫 행 헤더의 sparse cell, leading blank, 병합·수식·shared string 경계를 확인했다.
- 검토 결론: 첫 빈 셀은 sparse/leading 여부와 관계없이 헤더 종료점이고, leading blank는 필수 `품목` 헤더 없음으로 실패하며, 빈 헤더 뒤 unknown 컬럼은 원래 매핑 대상이 아니므로 경고하지 않는 기존 계약과 일치한다.
- 테스트 확인: 기본 workbook이 `F1` 빈 칸 뒤 `G1=품목`인 sparse 헤더를 포함하며, 빈 헤더 뒤 known header warning을 이미 검증한다. shared/inline/formula header도 공용 parser의 parsed text 경로를 사용한다.
- production/test 수정 없음: 재현 가능한 오매핑이나 데이터 손실이 없어 방어 코드와 중복 테스트를 추가하지 않았다.
- 사용자 확인: 새로 확정할 사용자 정책 없음.
- 검증 완료: XLSX focused 테스트 19개 통과.
- 검토 커밋: `2178b2f 엑셀 헤더 경계 검토 기록`.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- stage/commit 대상: `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.

## 완료: Excel 가져오기 신규 코드 12차 검토
- 앞선 11차까지 확정한 정책은 재검토하지 않고 XLSX 데이터 행 탐색과 worksheet dimension 경계를 확인한다.
- 검토 결론: 과소 dimension은 공용 parser가 실제 row/cell 좌표로 보정해 행 누락이 없다. 빈 품목명 행과 cache 없는 수식은 기존 확정 정책대로 유지한다.
- 사용자 확정: worksheet dimension이 실제 데이터보다 큰 경우 품목/주원료/현재 컬럼에 실제 셀이 존재하는 행만 순회한다.
- 확인된 문제: `sheet.rowCount`가 stale 과대 dimension을 포함하므로 실제 데이터가 적어도 최대 1,048,575개 빈 행을 순회할 수 있다.
- application 편집 완료: 원본 cell metadata에서 매핑된 컬럼의 실제 행 좌표만 정렬해 순회한다. 빈 값 skip, 원본 Excel 행 번호, 최대 행 수 계약은 유지한다.
- 테스트 추가: 실제 데이터는 2행 하나지만 dimension은 1,048,576행인 workbook이 한 행만 가져오고 원본 행 번호 2를 유지하는 계약을 고정했다.
- 문서 편집 완료: `doc/item_manager_modify.txt`에 과대 dimension 시 실제 매핑 셀 행만 검사하는 정책을 반영했다.
- 검증 완료: 과대 dimension 집중 테스트 1개 및 Excel parser/연산·dialog·draft focused 테스트 56개 통과. 변경 Dart 2개 파일 `flutter analyze` 성공, 변경 파일과 `pubspec.yaml` diagnostics 0건, `git diff --check` 성공.
- 기능 커밋: `e5f00d4 엑셀 실제 데이터 행만 순회`.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- stage/commit 대상: `lib/features/item/application/item_manager_xlsx.dart`, `test/item_manager_xlsx_test.dart`, `doc/item_manager_modify.txt`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.

## 완료: Excel 가져오기 신규 코드 11차 검토
- 앞선 10차까지 확정한 정책은 재검토하지 않고 XLSX parser의 실제 셀 타입 해석 경계를 확인한다.
- 사용자 확정: Excel Boolean 셀은 내부 raw 값 `1/0`이 아니라 Excel 표시값 `TRUE/FALSE`로 가져온다.
- 확인된 문제: 공용 XLSX parser는 `t="b"` 셀을 `TRUE/FALSE`로 해석하지만 품목 import formatter가 raw value를 숫자로 다시 처리해 `1/0`으로 바꾼다.
- application 편집 완료: Boolean 타입만 공용 parser의 parsed text를 사용한다. 문자열·숫자·오류·수식 경로는 변경하지 않았다.
- 테스트 추가: 최소 worksheet XML의 Boolean true/false 셀이 각각 `TRUE/FALSE`로 import되는 계약을 고정했다.
- 문서 편집 완료: `doc/item_manager_modify.txt`에 Boolean 셀 표시값 유지 정책을 반영했다.
- 검토 결론: error 셀은 raw/parsed fallback으로 원문이 유지되고, 병합 범위의 sparse cell은 FortuneSheet의 정상 표현이라 데이터 손실이 재현되지 않아 추가 보완하지 않았다.
- 검증 기준: 최소 worksheet XML의 Boolean true/false 셀이 각각 `TRUE/FALSE`로 import되어야 한다.
- 검증 완료: XLSX focused 테스트 18개 및 Excel parser/연산·dialog·draft focused 테스트 55개 통과. 변경 Dart 2개 파일 `flutter analyze` 성공, 변경 파일과 `pubspec.yaml` diagnostics 0건, `git diff --check` 성공.
- 기능 커밋: `80429e6 엑셀 Boolean 셀 표시값 보존`.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- stage/commit 대상: `lib/features/item/application/item_manager_xlsx.dart`, `test/item_manager_xlsx_test.dart`, `doc/item_manager_modify.txt`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.

## 완료: Excel 가져오기 신규 코드 10차 검토
- 앞선 9차까지 확정한 정책은 재검토하지 않고 import 결과의 draft 전체 교체 상태 전환을 확인한다.
- 검토 결론: 연산 후 길이 초과는 7차에서 저장 전 검증으로 확정한 정책이므로 변경하지 않는다. `replaceAllWithImportedRows`의 정상 입력에서 중간 실패 가능성은 없지만 삭제 ID를 replacements 검증 전에 controller에 반영하는 순서는 불필요하게 상태를 먼저 변경한다.
- domain 편집 완료: 삭제 대상 ID를 로컬 set으로 계산하고 replacements 검증 성공 후 controller에 반영한다. rollback/예외 catch는 추가하지 않았으며 정상 동작과 외부 계약은 유지한다.
- 검증 기준: 기존 draft 전체 교체 테스트에서 삭제 ID, imported rows, 선택 및 dirty 상태가 동일하게 통과해야 한다.
- 검증 완료: draft 전체 교체 집중 테스트 1개 및 Excel parser/연산·dialog·draft focused 테스트 54개 통과. domain 파일 `flutter analyze` 성공, 변경 파일과 `pubspec.yaml` diagnostics 0건, `git diff --check` 성공, formatter churn 없음.
- 사용자 확인: 새로 확정할 사용자 정책 없음.
- 기능 커밋: `4aa3625 엑셀 전체 교체 상태 반영 순서 정리`.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- stage/commit 대상: `lib/features/item/domain/item_manager_draft.dart`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.

## 완료: Excel 가져오기 신규 코드 9차 검토
- 앞선 8차까지 확정한 정책은 재검토하지 않고 긴 숫자 연산 오류 메시지의 dialog 표시 경계를 확인한다.
- 사용자 확정: 숫자 연산이 불가능한 Excel 셀의 원본 값은 오류 메시지에 전체 표시를 유지한다.
- 확인된 문제: 숫자가 아닌 긴 셀 원문이 오류 Text 높이를 제한 없이 늘려 고정 높이 연산 dialog에서 `RenderFlex overflow`를 일으킬 수 있다.
- presentation 편집 완료: 오류 영역을 최대 96px로 제한하고 내부 스크롤로 전체 원문을 확인하게 했다. 원본 오류 문구와 transform 동작은 변경하지 않았다.
- 테스트 편집 완료: 긴 비숫자 원문 전체가 오류 Text에 보존되고 오류 영역 높이가 96px 이하이며 렌더링 예외가 없는지 기존 뒤 행 오류 테스트에 추가했다.
- 문서 편집 완료: `doc/item_manager_modify.txt`에 원본 값 전체 표시와 긴 오류 내부 스크롤 정책을 반영했다.
- 검토 결론: 다수 컬럼은 `Expanded + ListView`로 스크롤되고, Mid 위치는 검증 후 clamp되며, parse warning은 변환 결과에 보존되어 성공 직후 표시되므로 추가 보완하지 않았다.
- 검증 완료: dialog focused 테스트 8개 및 Excel parser/연산·dialog·draft focused 테스트 54개 통과. 변경 Dart 2개 파일 `flutter analyze` 성공, 변경 파일과 `pubspec.yaml` diagnostics 0건, `git diff --check` 성공.
- 기능 커밋: `baef280 엑셀 연산 긴 오류 표시 보완`.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- stage/commit 대상: `lib/features/item/presentation/item_manager_import_transform_dialog.dart`, `test/item_manager_import_transform_dialog_test.dart`, `doc/item_manager_modify.txt`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.

## 완료: Excel 가져오기 신규 코드 8차 검토
- 사용자 확정: 실제 전체 행 연산 실패 시 다이얼로그를 유지하고 오류를 표시한다. 연산 종류를 바꿔도 입력값을 유지하며, lazy list의 화면 밖 설정을 포함한 모든 설정을 검증한다.
- presentation 편집 완료: transform dialog가 모든 draft를 수동 검증하고 실제 전체 행 변환까지 한 번 수행한다. 실패 시 inline 오류를 표시하고 유지하며, 성공 시 설정과 변환 완료 결과를 함께 반환한다.
- integration 편집 완료: `_importItemManagerXlsx()`는 dialog의 변환 완료 결과를 그대로 사용해 같은 연산을 두 번 실행하지 않는다.
- 테스트 진행: dialog 반환값이 변환 완료 데이터를 포함하는지 보강하고 뒤 행 숫자 변환 실패 시 `Excel 3행 가격 연산 실패`를 표시하며 dialog가 유지되는 회귀 테스트를 추가했다.
- 테스트 완료: 연산 종류 변경 후 설정값 유지와 화면 밖 invalid draft 전체 검증을 추가했다.
- 문서 편집 완료: `doc/item_manager_modify.txt`에 연산 변경 값 유지, 전체 설정·전체 행 검증, 실패 시 dialog 유지, 성공 결과 단일 적용 정책을 반영했다.
- 검증 완료: dialog focused 테스트 8개 및 Excel parser/연산·dialog·draft focused 테스트 54개 통과. 변경 Dart 3개 파일 `flutter analyze` 성공, 변경 코드·테스트·문서·`pubspec.yaml` diagnostics 0건, `git diff --check` 성공.
- 기능 커밋: `48c325f 엑셀 연산 다이얼로그 전체 검증 보완`.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- stage/commit 대상: `lib/features/item/presentation/item_manager_import_transform_dialog.dart`, `lib/home_page_manager.dart`, `test/item_manager_import_transform_dialog_test.dart`, `doc/item_manager_modify.txt`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.

## 완료: Excel 가져오기 신규 코드 7차 검토
- 제외 범위: 앞선 6차까지 확정한 정책은 재검토하지 않고 연산 결과 길이, 타입별 연산 노출, 최대 1만 행 성능, 존재하지 않는 transform columnId와 warning/cancel 흐름을 확인했다.
- 사용자 확정: 품명 100자·일반 컬럼 200자 초과 결과는 가져온 뒤 기존 저장 전 검증에서 차단한다. 날짜·시간·바코드·QR·GS1에도 모든 연산을 유지하고 최종 형식은 저장 전 검증에 맡긴다. 측정된 장애 없이 isolate를 추가하지 않고 현 동기 방식을 유지한다.
- 검토 결론: 길이·날짜/시간·바코드·GS1 저장 검증은 기존 production 코드와 테스트로 보장된다. transform columnId는 다이얼로그의 현재 컬럼에서만 생성되고 warning/cancel/busy 복구도 정상이라 production/test 코드를 추가하지 않았다.
- 문서 편집 완료: `doc/item_manager_modify.txt`에 확정한 길이, 타입별 연산, 대량 동기 적용 정책을 추가했다.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- 검증 완료: Excel parser/연산 다이얼로그/draft 전체 교체 focused 테스트 51개 통과, 문서와 `pubspec.yaml` diagnostics 0건, `git diff --check` 성공.
- stage/commit 대상: `doc/item_manager_modify.txt`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `563d358 엑셀 연산 검증 시점과 타입 정책 명시`.

## 완료: Excel 가져오기 신규 코드 6차 검토
- 제외 범위: 앞선 5차까지 확정한 정책은 재검토하지 않고 숫자 연산 입력과 Excel 사용자 지정 숫자 서식을 확인했다.
- 사용자 확정: 연산값은 올바른 천 단위 쉼표와 점 소수점을 허용하고 쉼표 소수/잘못된 그룹은 거부한다. 과학 표기는 허용한다. Excel `00000` 숫자 서식은 표시값의 선행 0을 보존한다.
- 편집 완료: application 공용 숫자 parser로 다이얼로그 validator와 실제 연산 판정을 통일하고 유한하지 않은 숫자도 거부한다. `_formatNumeric`에 순수 0 자리 마스크의 선행 0 보존을 추가했다.
- 테스트 추가: `1,234.5`/`1e3` 허용, `1,2,3`/`2,5`/`Infinity` 거부, 다이얼로그 오류 표시, Excel `00000`의 `00123` import를 고정했다.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- 검증 완료: Excel parser/연산 다이얼로그/draft 전체 교체 focused 테스트 51개 통과. 변경 production/test 4개 파일 `flutter analyze` 성공, 변경 파일 diagnostics 0건, `git diff --check` 성공.
- stage/commit 대상: Excel application/dialog production 2개, 관련 테스트 2개, `doc/item_manager_modify.txt`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `66d17f1 엑셀 연산 숫자 형식과 선행 0 처리 보완`.

## 완료: Excel 가져오기 신규 코드 5차 검토
- 제외 범위: 앞선 4차까지 확정한 정책은 재검토하지 않고 컬럼명 공백, 수식 cache, 숨김 행, 빈 품목명 행과 숫자 표시 형식을 확인했다.
- 사용자 확정: 현재 라벨 컬럼명은 앞뒤 공백을 trim해 Excel 헤더 생성·매핑·중복 판정을 통일한다. 숨김 행도 가져오며, 품목명이 비고 다른 값이 있는 행은 draft에 가져온 뒤 저장 전 검증에서 차단한다.
- 편집 완료: export 헤더, import descriptor, transform 오류 컬럼명과 중복 검증에 trim된 컬럼명을 사용한다. trim 결과가 빈 컬럼명은 Excel 작업을 실패시켜 빈 헤더 중단으로 인한 데이터 유실을 막는다.
- 검토 결론: cached value 없는 수식은 빈 값, 숫자 표시는 앞서 확정한 raw 숫자 정책, warning 보존은 현재 계약대로 유지한다.
- 테스트 추가: 현재 라벨 컬럼명이 `  코드  `여도 Excel `코드` 헤더가 해당 columnId에 매핑되는 계약을 고정했다.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- 추가 테스트: 공백 포함 컬럼명의 export→import roundtrip, 숨김 데이터 행 포함, 빈 품목명 행 draft 유지를 고정했다.
- 검증 완료: Excel parser/연산 다이얼로그/draft 전체 교체 focused 테스트 48개 통과. 변경 production/test `flutter analyze` 성공, 변경 파일 diagnostics 0건, `git diff --check` 성공.
- stage/commit 대상: `lib/features/item/application/item_manager_xlsx.dart`, `test/item_manager_xlsx_test.dart`, `doc/item_manager_modify.txt`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `a383f5a 엑셀 컬럼명 공백 매핑 일관성 보완`.

## 완료: Excel 가져오기 신규 코드 4차 검토
- 제외 범위: 앞선 3차 검토까지 확정한 정책은 재검토하지 않고 동일 표시명 컬럼, Mid 문자 단위, 숫자 정밀도, 경고 순서와 transform 대상 타입을 확인했다.
- 사용자 확정: 현재 라벨에 표시명이 같은 컬럼이 둘 이상이면 Excel import/export를 실패시킨다. Mid의 N자는 눈에 보이는 문자 단위로 계산한다. 숫자 연산은 새 정밀 10진수 의존성 없이 기존 최대 소수 12자리 double 방식을 유지한다.
- 편집 완료: import/export 공용 중복 컬럼명 검증을 추가해 컬럼명과 ID를 오류에 표시한다. Mid는 `characters` grapheme cluster 기준으로 왼쪽 N자를 계산하며 기존 음수/초과 위치 clamp 동작을 유지한다.
- 의존성: `characters: ^1.4.1`을 직접 의존성으로 추가하고 `flutter pub get`을 실행했다. 앱 버전은 사용자 지정에 따라 `1.0.1` 유지.
- 테스트 추가: 결합 emoji를 한 글자로 처리하는 Mid와 동일 표시명 컬럼의 import/export 실패를 고정했다.
- 추가 확인: 일반 컬럼명이 Excel 기본 헤더 `품목`/`주원료`와 같은 경우도 같은 모호성이므로 import/export 전에 실패하도록 했다. 경고 순서, transform 대상 타입, import 이후 원본 행 metadata 미보존은 현재 실행 계약에 문제없어 유지했다.
- 검증 완료: Excel parser/연산 다이얼로그/draft 전체 교체 focused 테스트 46개 통과. 변경 production/test `flutter analyze` 성공, 변경 파일 diagnostics 0건, `git diff --check` 성공.
- stage/commit 대상: `lib/features/item/application/item_manager_xlsx.dart`, `test/item_manager_xlsx_test.dart`, `doc/item_manager_modify.txt`, `pubspec.yaml`, `pubspec.lock`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `65e7b2a 엑셀 컬럼명 충돌과 문자 위치 처리 보완`.

## 완료: Excel 가져오기 신규 코드 3차 검토
- 제외 범위: 기존에 확정한 Mid/빈 셀/샘플/중복 헤더/10*8/전체 교체/busy 정책은 재검토하지 않고, 원본 행 번호·숫자 서식·미매핑 헤더·적용 결과 일치 여부를 확인했다.
- 사용자 확정: 백분율 셀은 Excel 원 숫자값(예: `0.5`)으로, 통화 셀은 통화 기호를 제외한 숫자로 가져온다. 현재 formatter와 숫자 parser가 이 계약을 충족해 추가 변환하지 않는다.
- 편집 완료: import row에 원본 Excel 행 번호를 보존하고, 빈 행을 건너뛴 뒤 연산이 실패해도 실제 Excel 행 번호를 오류에 표시한다. transform 적용 후에도 원본 행 번호를 유지한다.
- 문서 정합성: `doc/item_manager_modify.txt`의 과거 중복 헤더 첫 값 사용 설명을 사용자 확정 정책인 중복 헤더 실패로 갱신했다.
- 테스트 추가: Excel 2~3행이 비고 4행의 숫자 연산이 실패할 때 `Excel 4행 코드 연산 실패`가 표시되는 계약을 고정했다.
- 검토 결론: 알 수 없는 헤더는 현재 라벨 크기의 컬럼명과 일치할 때만 매핑하는 기존 명시 계약이므로 경고를 추가하지 않는다.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- 검증 완료: Excel parser/연산 다이얼로그/draft 전체 교체 focused 테스트 43개 통과. 변경 Dart 3개 파일 `flutter analyze` 성공, 변경 파일 diagnostics 0건, `git diff --check` 성공. 중복 헤더의 과거 첫 값 사용 설명이 문서에 남지 않은 것을 확인했다.
- stage/commit 대상: `lib/features/item/domain/item_manager_draft.dart`, `lib/features/item/application/item_manager_xlsx.dart`, `test/item_manager_xlsx_test.dart`, `doc/item_manager_modify.txt`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `83d40de 엑셀 연산 오류에 원본 행 번호 표시`.

## 완료: Excel 가져오기 신규 코드 2차 검토
- 검토 범위: 직전 연산 의미/샘플 보완을 제외한 헤더 매핑, 전체 교체, 10*8 파생값, 취소/오류 상태와 관련 테스트. 과도한 보완/예외 처리는 추가하지 않는다.
- 사용자 확정: 알려진 헤더가 중복되면 첫/마지막 값을 임의 선택하지 않고 가져오기를 실패시킨다. 10*8의 매수·발행수량은 자동 재계산하지 않고 Excel 값을 그대로 유지한다.
- 편집 완료: 중복된 알려진 헤더를 발견하면 헤더명과 최초/중복 열 위치를 포함한 `FormatException`을 발생시킨다.
- 테스트 추가: 코드 헤더가 C열과 D열에 중복된 workbook이 정확한 위치 메시지로 거부되는 계약을 고정했다.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- 검증 완료: Excel parser/연산 다이얼로그/draft 전체 교체 focused 테스트 42개 통과. 변경 production/test 2개 파일 `flutter analyze` 성공, diagnostics 0건, `git diff --check` 성공.
- 검토 결론: 10*8 파생값은 사용자 확정대로 Excel 값을 유지했다. 주원료 payload 인코딩 실패는 빈 payload로 대체하면 데이터 유실이므로 상위 import 실패 표시를 유지했고, 전체 교체·취소·busy 해제 흐름도 기존 계약에 맞아 수정하지 않았다.
- stage/commit 대상: `lib/features/item/application/item_manager_xlsx.dart`, `test/item_manager_xlsx_test.dart`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `2298572 엑셀 가져오기 중복 헤더 검증 추가`.

## 완료: Excel 가져오기 연산 보완 검토
- 검토 범위: 신규 품목관리 Excel 가져오기 연산 모델, 설정 다이얼로그, import 호출 흐름과 관련 테스트. 과도한 방어/예외 처리는 추가하지 않는다.
- 사용자 확정: Mid는 왼쪽 N자 이후 원문을 설정값으로 대체하고, 원본 빈 셀은 연산 없이 빈 값으로 유지한다.
- 편집 완료: 오해를 만드는 `insertAfter`를 `replaceAfter`로 변경하고 UI를 `Mid (왼쪽 N자 이후 대체)`로 명확히 했다. 연산 설정 샘플은 첫 행 고정값 대신 해당 대상의 첫 non-empty 가져오기 값으로 표시한다.
- 테스트 추가: 빈 셀 연산 생략 계약과 첫 non-empty 샘플 표시를 고정했다.
- 버전: 사용자 지정에 따라 `1.0.1` 유지.
- 검증 완료: `item_manager_xlsx_test.dart`, `item_manager_import_transform_dialog_test.dart` focused 테스트 12개 통과. 변경 production/test 4개 파일 `flutter analyze` 성공, diagnostics 0건, `git diff --check` 성공.
- 검토 결론: import 취소/경고/busy 해제, 숫자 오류·0 나눗셈·행/컬럼 오류 표시는 문제없어 유지했다. nullable 폼 값은 입력 삭제 중 상태 표현에 필요하고, `editable=false` 컬럼 제외는 기존 import 계약을 바꾸므로 추가 보완하지 않았다.
- stage/commit 대상: `lib/features/item/application/item_manager_xlsx.dart`, `lib/features/item/presentation/item_manager_import_transform_dialog.dart`, 관련 테스트 2개, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `afc4454 엑셀 가져오기 연산 의미와 샘플 표시 보완`.

## 완료: 앱 버전 1.0.1 지정
- 사용자 요청에 따라 `pubspec.yaml` 버전을 `1.0.2`에서 `1.0.1`로 변경한다. 명시 버전 요청이므로 자동 PATCH 증가를 적용하지 않는다.
- `DebugLogger`는 `PackageInfo`의 앱 버전을 사용하므로 다음 실행 로그에도 `1.0.1`이 기록된다.
- 검증 완료: `dart run lib/utils/generate_version.dart`에서 `Generated version.txt: 1.0.1` 확인. 검증용 미추적 `version.txt`는 삭제했다.
- stage/commit 대상: `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `389645d 앱 버전을 1.0.1로 지정`.

## 완료: DebugLogger 버전 선설정
- 사용자 요청: `main()`에서 `DebugLogger.setVersion`을 로그 초기화보다 먼저 처리한다.
- 원인/수정: 기존에는 `DebugLogger.ensureInitialized()` 후 패키지 버전을 설정해 초기화 시점에 버전이 없었다. 플러그인 호출에 필요한 `WidgetsFlutterBinding.ensureInitialized()` 직후 `PackageInfo.fromPlatform()`으로 버전을 읽고 `DebugLogger.setVersion(appVersion)`을 호출한 다음 로거를 초기화하도록 순서를 변경했다.
- 버전 변경: startup 로그의 버전 기록을 바로잡는 호환 가능한 국소 수정이므로 PATCH 적용, `1.0.1` → `1.0.2`.
- 검증 완료: `flutter analyze lib/main.dart` 성공, `dart run lib/utils/generate_version.dart`에서 `Generated version.txt: 1.0.2` 확인, 세 변경 파일 diagnostics 0건, `git diff --check` 성공. 검증용 미추적 `version.txt`는 삭제했다.
- stage/commit 대상: `lib/main.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `6f4a0c1 로그 초기화 전에 앱 버전 설정`.

## 완료: 수정 범위 기반 pubspec 버전 자동 갱신 및 로그 버전 연동
- 사용자 요청: 앞으로 저장소 변경 시 수정 범위에 따라 `pubspec.yaml` 버전을 자동 갱신하고 다음 세션에도 유지되도록 `SESSION_RULES.md`에 상시 규칙으로 명시한다.
- 기준 확정: 호환 가능한 국소 수정은 PATCH, 사용자 기능 추가/다중 production 흐름 확장은 MINOR, 비호환 계약 변경은 MAJOR로 판단한다. 한 요청당 최고 단계로 1회만 증가하며 후속 handoff 해시 기록 커밋은 재증가하지 않는다.
- 규칙 편집 완료: `SESSION_RULES.md`에 자동 갱신 시점, 단계 기준, 예외, 커밋/handoff 기록 규칙과 종료 체크리스트를 추가했다.
- 버전 변경: 문서·작업 정책의 호환 가능한 국소 변경이므로 PATCH 적용, `1.0.0` → `1.0.1`.
- 로그 버전 연동: `lib/main.dart`의 수동 `FSDBG-...` 식별자를 제거하고 `PackageInfo.fromPlatform()`이 반환한 `appVersion`을 `DebugLogger.setVersion`에 전달해 `pubspec.yaml` 기반 생성 버전이 로그에 기록되도록 변경했다.
- 추가 버전 증가 없음: 같은 사용자 요청의 후속 보완이며 한 요청당 1회 규칙에 따라 `1.0.1`을 유지한다.
- 검증 완료: `dart run lib/utils/generate_version.dart`가 `Generated version.txt: 1.0.1`을 출력했고 `flutter analyze lib/main.dart` 성공, 네 변경 파일 diagnostics 0건, `git diff --check` 성공, 규칙 섹션 번호 `1~10` 연속 확인. `FSDBG-` 하드코딩이 없고 `DebugLogger.setVersion(appVersion)`만 남은 것을 확인했다.
- 임시 산출물 정리: 버전 파싱 검증으로 생성된 미추적 `version.txt`를 삭제했다.
- stage/commit 대상: `pubspec.yaml`, `SESSION_RULES.md`, `SESSION_HANDOFF.md`, `lib/main.dart`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `1caf62d 수정 범위별 자동 버전 갱신 규칙 추가`.

## 완료: Excel 가져오기 처리 중 고정 및 재로그인 로딩 잔류 수정
- 제출 이미지 분석: Excel 내보내기 파일을 다시 가져오면 품목 1개는 반영되지만 품목관리 하단에 `처리 중`이 계속 남고 편집이 비활성화된다. 로그아웃/재로그인 후에는 `브랜드 데이터를 불러오고 있습니다...` 장기 스낵바가 잔류한다.
- 원인 1: 가져오기 성공 시 `_resetTabs()`가 `_itemDraftCommandBusy=true` 상태의 `ItemManage`를 `_tabs` 캐시에 고정하고, `finally`는 바깥 `setState(false)`만 수행해 캐시된 `commandBusy`를 갱신하지 않는다. 저장 흐름은 이미 busy=false 후 `_resetTabs()` 패턴을 사용한다.
- 원인 2: 브랜드 로딩 스낵바는 HomePage의 ScaffoldMessenger에 1일 duration으로 표시되는데 로그아웃은 HomePageManager body만 제거하고 스낵바 큐를 비우지 않아 다음 로그인까지 이전 진행 표시가 살아남을 수 있다.
- 수정 예정: import `finally`를 저장 흐름과 같은 busy=false 후 탭 재생성으로 변경하고, 로그아웃 시 ScaffoldMessenger의 모든 스낵바를 제거한다.
- 편집 완료: `_importItemManagerXlsx()` finally가 `_itemDraftCommandBusy=false` 후 `_resetTabs()`를 호출해 캐시된 `ItemManage.commandBusy`를 갱신한다. `_doLogout()` 시작 시 HomePage ScaffoldMessenger의 스낵바 큐를 비운다.
- 1차 검증 완료: `flutter test test/widget_test.dart test/item_manager_xlsx_test.dart test/item_manager_import_transform_dialog_test.dart test/fortune_table_test.dart` 성공(79개), 수정 파일 진단 0건.
- 전체 검증 완료: `flutter test test/widget_test.dart test/item_manager_xlsx_test.dart test/item_manager_import_transform_dialog_test.dart test/item_manager_draft_test.dart test/item_manager_session_loader_test.dart test/item_manager_save_dao_test.dart test/item_manager_read_snapshot_test.dart test/fortune_table_test.dart` 성공(119개), 수정 파일 진단 0건, `git diff --check` 성공.
- analyzer: `flutter analyze`는 이번 변경 오류 없이 기존 `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 미사용 코드 경고 10건.
- stage/commit 대상: `lib/home_page.dart`, `lib/home_page_manager.dart`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외.
- 기능 커밋: `98fba44` (`Excel 가져오기 처리 상태와 재로그인 로딩 수정`).

## 완료: 품목관리 Excel 가져오기 컬럼 연산 설정
- 레거시 조사: `.tmp/LabelManager/LabelManagerLib/ExcelMananger.cpp`, `MainItemTable.cpp`, `UpdateItemTable.cpp`는 헤더명 매칭 후 원문을 직접 반영하며 컬럼별 사칙연산/텍스트 추가 기능과 설정 UI가 없다. 현 프로젝트 신규 설계로 구현한다.
- 설계: Excel 파싱 후 품목 적용 전에 별도 설정 dialog를 표시하고, 품목 및 이미지 외 동적 컬럼별로 숫자 `+/-/*//`와 텍스트 `Right/Left/Mid` 규칙을 선택한다. 주원료는 rich-text payload와 plain text 불일치를 막기 위해 대상에서 제외한다.
- application 편집 완료: `ItemManagerImportTransform`, `ItemManagerImportTransforms`, `itemManagerApplyImportTransforms`를 추가했다. 나눗셈은 최대 소수 자릿수 기본 2, trailing zero 제거 방식이며 숫자 오류/0 나눗셈은 Excel 행 정보와 함께 실패한다.
- 테스트 추가: 이미지 요구 예시 `3+5=8`, `3-5=-2`, `3*5=15`, `3/5=0.6`, `Right/Left/Mid` 결과와 import result 반영을 검증한다.
- presentation 편집 완료: `ItemManagerImportTransformDialog`를 추가했다. 대상 컬럼/Excel 샘플/연산/설정값을 한 행에서 구성하고 나눗셈 소수 자리와 Mid 왼쪽 자리를 조건부 입력한다. 이미지 컬럼과 주원료는 설정 대상에서 제외한다.
- dialog 테스트 추가: 동적 컬럼 곱하기 설정, 이미지 컬럼 제외, 품목 Mid 텍스트 설정 결과를 검증한다.
- integration 편집 완료: `_importItemManagerXlsx()`가 파일 파싱 후 설정 dialog를 열고, 취소 시 draft를 변경하지 않으며, 확인 시 `itemManagerApplyImportTransforms` 결과를 기존 warning 확인/전체 draft 교체 흐름에 전달한다.
- 숫자 formatting 보정: 소수부가 있을 때만 trailing zero를 제거해 나눗셈 소수 자리 `0`에서 `100`이 `1`로 축약되지 않도록 했다. 숫자가 아닌 원본과 0 나눗셈 실패도 테스트한다.
- dialog 테스트 보강: 나눗셈 연산값과 소수 자릿수 입력이 설정 결과에 반영되는지 검증한다.
- 검증 완료: `flutter test test/item_manager_xlsx_test.dart test/item_manager_import_transform_dialog_test.dart test/item_manager_draft_test.dart test/item_manager_session_loader_test.dart test/item_manager_save_dao_test.dart test/item_manager_read_snapshot_test.dart test/fortune_table_test.dart` 성공(117개), 수정 파일 진단 0건.
- 오류 계약 보강: 변환 실패 시 설정된 전체 컬럼이 아니라 실제 실패한 Excel 행 번호와 컬럼명 하나를 표시하도록 적용 루프를 분리하고 테스트를 추가했다.
- 정적 검증 완료: `git diff --check` 성공. `flutter analyze`는 이번 변경 오류 없이 기존 `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 미사용 코드 경고 10건으로 종료 코드 1.
- stage/commit 대상: `lib/features/item/application/item_manager_xlsx.dart`, `lib/features/item/presentation/item_manager_import_transform_dialog.dart`, `lib/home_page_manager.dart`, `test/item_manager_xlsx_test.dart`, `test/item_manager_import_transform_dialog_test.dart`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외.
- 기능 커밋: `5d8d16d` (`품목관리 Excel 가져오기 컬럼 연산 추가`).

## 완료: 포커스 편집 커서를 세로 가운데 정렬
- 제출 화면 확인: 신규 사용자 항목의 포커스 셀에서 편집 커서가 2px 외곽선 상단과 겹친다. 셀 높이는 전체 가용 영역을 사용하지만 `TextFormField`에 세로 정렬이 지정되지 않은 상태다.
- 수정 예정: 프로젝트의 28px 테이블 editor 패턴과 같이 `textAlignVertical: TextAlignVertical.center`를 적용하고, 포커스 외곽선 크기와 좌우 2px padding은 유지한다.
- 편집 완료: 사용자 항목 텍스트 `TextFormField`에 `textAlignVertical: TextAlignVertical.center`를 적용했다.
- 테스트 보강: 내부 `TextField`의 세로 정렬 설정과 `RenderEditable` caret 중심이 렌더 영역의 세로 중심과 일치하는지 검증한다.
- 검증 완료: 집중 테스트 성공(1개), `flutter test test/label_column_edit_dialog_test.dart test/swipe_action_table_test.dart test/fortune_table_test.dart` 성공(112개), 수정 파일 진단 0건.
- 정적 검증 완료: `git diff --check` whitespace 오류 없음(LF/CRLF 안내만 출력). `flutter analyze`는 이번 변경 오류 없이 기존 `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 미사용 코드 경고 10건으로 종료 코드 1.
- stage/commit 대상: `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/label_column_edit_dialog_test.dart`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외.
- 기능 커밋: `8c3e951` (`사용자 항목 편집 커서 세로 정렬`).

## 완료: 포커스 편집 외곽선을 컬럼 셀에 맞춤
- 제출 화면 확인: 신규 사용자 행의 포커스 외곽선이 키워드 컬럼 내부에서 세로로 행 높이를 채우지 못한다. custom cell editor가 폭만 지정하고 높이는 `TextFormField` intrinsic 크기를 사용하며, 공용 테이블 `Row`가 이를 세로 중앙 정렬하는 것이 원인이다.
- 수정 예정: 텍스트 editor wrapper가 행의 가용 높이를 전부 사용하도록 지정한다. 포커스 셀 한 곳만 외곽선을 표시하는 기존 동작과 dropdown 모양은 유지한다.
- 집중 검증 보정: 행 28px 중 하단 1px는 공용 테이블 구분선이므로 custom cell의 실제 가용 크기는 키워드 기준 `105x27`이다. `height: double.infinity`로 이 영역 전체를 채우도록 수정했다.
- 편집 완료: 포커스 텍스트 editor wrapper가 `height: double.infinity`를 사용해 하단 구분선을 제외한 컬럼 셀의 전체 폭/높이를 채운다.
- 테스트 추가: 키워드 포커스 decoration의 실제 렌더 크기가 `105x27`인지 검증한다.
- 검증 완료: 집중 테스트 성공(1개), `flutter test test/label_column_edit_dialog_test.dart test/swipe_action_table_test.dart test/fortune_table_test.dart` 성공(112개), 수정 파일 진단 0건.
- 정적 검증 완료: `git diff --check` whitespace 오류 없음(LF/CRLF 안내만 출력). `flutter analyze`는 이번 변경 오류 없이 기존 `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 미사용 코드 경고 10건으로 종료 코드 1.
- stage/commit 대상: `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/label_column_edit_dialog_test.dart`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외.
- 기능 커밋: `c405e15` (`포커스 편집 외곽선을 셀 크기에 맞춤`).

## 완료: 사용자 항목 편집 외곽선을 포커스 셀로 제한
- 제출 화면 확인: 신규 사용자 행의 키워드/항목명/종류 셀 전체에 파란 2px 외곽선이 표시된다. `_editingCustomerKey` 행 상태를 세 셀 decoration에 공통 적용한 것이 원인이다.
- 수정 예정: 텍스트 editor의 실제 `Focus` 상태에만 품목관리식 파란 외곽선을 적용하고, 종류 dropdown에는 편집 외곽선을 적용하지 않는다. 신규 행 자동 스크롤과 저장 동작은 유지한다.
- 편집 완료: 편집 행의 키워드/항목명은 `Focus.of(context).hasFocus`일 때만 선택 배경과 파란 2px 외곽선을 사용한다. 종류 dropdown의 행 단위 외곽 decoration과 `editorStyle` 분기를 제거해 일반 compact dropdown 모양을 유지한다.
- 테스트 보강: 키워드 포커스 시 항목명/dropdown에 편집 외곽선이 없고, 항목명으로 포커스 이동 시 키워드 외곽선이 제거되는 전환을 검증한다.
- 집중 검증 완료: `flutter test test/label_column_edit_dialog_test.dart --plain-name "adding a user row scrolls to its inline editor"` 성공(1개).
- 관련 검증 완료: `flutter test test/label_column_edit_dialog_test.dart test/swipe_action_table_test.dart test/fortune_table_test.dart` 성공(112개), 수정 파일 진단 0건.
- 정적 검증 완료: `git diff --check` whitespace 오류 없음(LF/CRLF 안내만 출력). `flutter analyze`는 이번 변경 오류 없이 기존 `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 미사용 코드 경고 10건으로 종료 코드 1.
- stage/commit 대상: `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/label_column_edit_dialog_test.dart`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외.
- 기능 커밋: `54cc053` (`사용자 항목 편집 외곽선 포커스 적용`).

## 완료: 사용자 항목 편집 셀을 품목관리 스타일로 통일
- 비교 결과: 품목관리는 `FortuneTable` 내장 editor의 선택 행 배경, 파란색 2px 테두리, 14px 글꼴, 좌우 2px padding을 사용한다. 라벨 사용자 항목은 별도 `SwipeActionTable + TextFormField` 구현으로 테두리 없음, 13px dialog 글꼴, 좌우 6px padding을 사용해 편집 상태가 다르다.
- 수정 예정: 라벨 사용자 항목의 신규/수정 텍스트 셀을 품목관리 FortuneTable editor 스타일로 맞추고 widget 테스트로 decoration/font/padding을 고정한다. 데이터 편집 동작과 dropdown 폭은 유지한다.
- 편집 완료: 키워드/항목명 TextFormField와 편집 중 종류 dropdown을 공용 `_customerEditorDecoration`으로 묶어 선택 배경 `#E3F2FD`, 파란 테두리 `#0188FB` 2px를 적용했다. 텍스트는 품목관리와 같은 14px, 좌우 2px이며 편집 dropdown의 내부 검은 outline은 제거했다.
- 테스트 추가: 신규 사용자 행의 키워드 editor와 종류 dropdown이 선택 배경/파란 2px 테두리/14px/좌우 2px를 사용하는지 검증한다. 종류 dropdown은 `customer-type:<row-key>`로 행 identity를 고정했다.
- 집중 검증 완료: `flutter test test/label_column_edit_dialog_test.dart --plain-name "adding a user row scrolls to its inline editor"` 성공(1개).
- 전체 검증 완료: `flutter test test/label_column_edit_dialog_test.dart test/swipe_action_table_test.dart test/fortune_table_test.dart` 성공(112개), formatter 후 집중 테스트 성공(1개), 수정 파일 진단 0건, `git diff --check` whitespace 오류 없음(LF/CRLF 안내만 출력).
- analyzer: `flutter analyze`는 이번 변경 오류 없이 기존 `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 미사용 코드 경고 10건으로 종료 코드 1.
- stage/commit 대상: `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/label_column_edit_dialog_test.dart`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외.
- 기능 커밋: `5126c00` (`라벨 사용자 항목 편집 스타일 통일`).

## 완료: 사용자 항목 추가 스크롤 및 드롭다운 잘림 재수정
- 최신 로그 `app_2026-07-30_15-15-05.log`: 신규 159행 추가 후 row 15부터 row 158까지 약 3.3초 동안 순차 build되어 자동 스크롤이 즉시 완료되지 않았다. 고정 높이 행 ListView에 `itemExtent`가 없어 max scroll extent를 점진 추정하는 것이 원인이다.
- 제출 화면 비교: 사용자 후보 영역은 약 386px인데 현재 열 합계가 `34+105+111+144=394px`라 144px로 확장한 종류 드롭다운도 8px 잘린다.
- 수정 예정: 공용 테이블 세로 ListView에 `itemExtent=rowHeight`를 적용하고, 사용자 후보 영역을 열 합계에 맞는 426px로 고정한다. 종류 열은 176px, 다이얼로그 최대 폭은 1264px로 조정한다.
- 1차 집중 검증: `itemExtent` 적용 후 대량 행은 즉시 마지막 구간을 materialize했지만 첫 callback의 max extent는 이전 행 기준이라 28px 부족했다. 첫 180ms 이동 완료 후 확정 extent로 두 번째 이동하는 기존 보정을 유지하며 완료 제한을 400ms로 검증한다.
- 테스트 보강: 사용자 후보 영역 426px와 종류 dropdown 176px뿐 아니라 사용자 테이블의 헤더/본문 가로 `maxScrollExtent=0`을 검증해 열 잘림이 없음을 고정한다.
- 전체 회귀 1차 결과: 46개 중 42개 통과, row reorder 4개가 drop gap의 가변 높이와 `itemExtent` 충돌로 실패했다. `rowReorderEnabled` 테이블은 기존 가변 extent를 유지하고, 일반 고정 행 테이블에만 `itemExtent`를 적용하도록 범위를 제한했다.
- 최종 검증: 공용 테이블/라벨 항목 편집 테스트 46개 통과, 변경 Dart 3개 analyzer `No issues found` (1.6초), diagnostics 0건. `git diff --check` 내용 오류 없음(LF→CRLF 정책 경고만 출력).
- 완료 결과: 158행 뒤 신규 사용자 항목은 400ms 안에 마지막 행까지 자동 스크롤되며, 사용자 후보 영역 426px에 열 전체가 들어가 가로 overflow 없이 176px 종류 드롭다운이 잘리지 않는다. row reorder 테이블의 가변 drop gap은 기존 동작을 유지한다.
- stage/commit 대상: `lib/widgets/swipe_action_table.dart`, `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/label_column_edit_dialog_test.dart`, `SESSION_HANDOFF.md`. unrelated `lib/core/app.dart` 제외.
- 기능 커밋: `fac568b` (`사용자 항목 추가 스크롤과 드롭다운 잘림 수정`).

## 완료: 사용자 항목 종류 드롭다운 한 줄 표시
- 사용자 제출 화면에서 사용자 항목 수정 모드의 종류 드롭다운 폭 80px가 부족해 `2D 바코드(QR 코드)`가 두 줄로 표시된다.
- 수정 예정: 사용자 항목 종류 열을 64px 넓힌 144px로 조정하고, 다이얼로그 최대 폭과 내부 최소 폭도 각각 같은 64px만큼 늘린다. 가장 긴 메뉴 항목의 한 줄 높이와 실제 프레임/열 폭을 widget 테스트로 고정한다.
- 편집 완료: 사용자 종류 열 `80→144`, 다이얼로그 최대 폭 `1168→1232`, 내부 최소 폭 `1028→1092`로 각각 64px 확장했다. 공용 `_DialogDropdown` 메뉴 label은 `maxLines: 1`, `softWrap: false`로 고정했다.
- 테스트 추가: 1300px 화면의 dialog width 계산 1232px, 사용자 종류 열/드롭다운 144px, `2D 바코드(QR 코드)` 메뉴 행 28px 및 한 줄 렌더 계약을 검증한다.
- 집중 검증: 레이아웃/사용자 종류 드롭다운 테스트 2개 통과.
- 최종 검증 예정: `test/label_column_edit_dialog_test.dart` 전체 실행 후 변경 Dart 2개 analyzer 및 `git diff --check`.
- 최종 검증: 라벨 항목 편집 다이얼로그 테스트 21개 통과, 변경 Dart 2개 analyzer `No issues found` (1.6초), diagnostics 0건. `git diff --check` 내용 오류 없음(LF→CRLF 정책 경고만 출력).
- 완료 결과: 사용자 항목 수정 모드의 종류 드롭다운과 다이얼로그가 각각 필요한 64px만큼 넓어지고, 긴 종류 이름은 메뉴에서 두 줄로 표시되지 않는다.
- stage/commit 대상: `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/label_column_edit_dialog_test.dart`, `SESSION_HANDOFF.md`. unrelated `lib/core/app.dart` 제외.
- 기능 커밋: `eca239f` (`사용자 항목 종류 드롭다운 폭 조정`).

## 완료: 사용자 항목 추가 행 자동 스크롤
- 사용자 제출 화면 기준 기존 사용자 항목 158행에서 신규 행 추가 후 마지막 inline editor가 viewport로 자동 스크롤되지 않는다.
- 현재 `_addCustomerRow()`는 마지막 index를 `SwipeActionTable.scrollToIndex`에 전달하고 공용 테이블은 행 수 변경 후 post-frame animate를 수행한다. 기존 테스트는 20행에서 임의 ListView offset만 확인해 실제 신규 행 노출을 보장하지 못한다.
- 수정 예정: 158행 회귀 테스트에서 신규 draft editor의 실제 viewport 생성과 body scroll 위치를 검증하고, 결과에 따라 공용 테이블의 렌더 완료 스크롤을 보강한다.
- 원인 확정: 159번째 신규 행 추가 후 `maxScrollExtent=4172`, 최종 offset `4144`로 행 높이 28px만큼 부족했다. 첫 post-frame 시점에는 이전 158행 extent까지만 이동하고 신규 sliver 반영은 다음 frame에 완료된다.
- 1차 보완 결과: 첫 post-frame 안에서 다음 post-frame을 예약하면 첫 animation 완료 전에 두 번째 callback이 실행되어 offset이 여전히 28px 부족했다.
- 편집 완료: `_scrollToRow()`가 `animateTo` 완료를 반환하도록 바꾸고, 첫 animation으로 신규 sliver를 materialize한 뒤 완료 시점의 확정된 extent를 사용해 두 번째 이동을 실행한다.
- 집중 검증: 158개 기존 행에 159번째 draft를 추가하는 `adding a user row scrolls to its inline editor` 테스트 통과. 두 세로 controller가 확정된 max extent에 도달하고 신규 keyword editor가 viewport에 존재함을 확인했다.
- 최종 검증 예정: `test/swipe_action_table_test.dart`, `test/label_column_edit_dialog_test.dart` 전체 실행 후 변경 Dart 2개 analyzer 및 `git diff --check`.
- 최종 검증: 공용 테이블/라벨 항목 편집 관련 테스트 46개 통과, 변경 Dart 2개 analyzer `No issues found` (1.5초), diagnostics 0건, `git diff --check` 통과.
- 완료 결과: 사용자 항목 수정 모드에서 대량 행 끝에 신규 행을 추가하면 첫 animation 완료 후 확정된 scroll extent로 다시 이동하여 추가된 inline editor가 자동으로 보인다.
- stage/commit 대상: `lib/widgets/swipe_action_table.dart`, `test/label_column_edit_dialog_test.dart`, `SESSION_HANDOFF.md`. unrelated `lib/core/app.dart` 제외.
- 기능 커밋: `418d633` (`사용자 항목 추가 행 자동 스크롤 수정`).

## 완료: 라벨 항목 저장 schema 판정 수정
- 사용자 제출 이미지/최신 로그 `app_2026-07-30_14-45-52.log` 분석: 라벨 항목 158행 조회는 성공했지만 저장 전 capability query 결과가 `hasCoreSchema=false`여서 `Required label column schema is not supported.`가 발생했다.
- 레거시 비교: `.tmp/LabelManager/LabelManagerLib/Column.cpp`의 조회/INSERT/UPDATE와 현재 실제 조회/저장 SQL은 테이블을 schema 없이 참조한다. capability 검사만 `dbo.`로 고정되어 연결 계정 기본 schema의 테이블을 오탐한다.
- 수정 예정: capability metadata 조회도 실제 SQL과 동일한 비정규화 object 이름을 사용하고, `dbo.` 재도입 방지 테스트를 추가한다. DB schema/migration은 변경하지 않는다.
- 편집 완료: `LabelColumnSaveDao.capabilitySql`의 core/optional `OBJECT_ID`·`COL_LENGTH` 대상에서 `dbo.` 고정을 제거했다. 실제 조회/저장 SQL과 같은 기본 schema 해석을 사용한다.
- 테스트 추가: capability metadata SQL에 `DBO.`가 없음을 고정했다.
- 집중 검증: `test/label_column_save_test.dart` 14개 통과.
- 최종 검증 예정: `test/label_column_save_test.dart`, `test/label_column_edit_dialog_test.dart`, `test/column_mapping_test.dart` 실행 후 변경 Dart 2개 analyzer 및 `git diff --check`.
- 최종 검증: 관련 테스트 17개 통과, 변경 Dart 2개 analyzer `No issues found` (1.1초), diagnostics 0건. `git diff --check` 내용 오류 없음(LF→CRLF 정책 경고만 출력).
- 완료 결과: capability metadata 검사와 실제 조회/저장/레거시 SQL의 object 이름 해석을 일치시켜 기본 schema의 기존 테이블을 `dbo` 누락으로 오탐하지 않는다. DB schema와 데이터는 변경하지 않았다.
- stage/commit 대상: `lib/features/label_column/data/label_column_save.dart`, `test/label_column_save_test.dart`, `SESSION_HANDOFF.md`. unrelated `lib/core/app.dart` 제외.
- 기능 커밋: `0ab01fb` (`라벨 항목 저장 스키마 판정 수정`).

## 완료: 날짜 타입 사용자 정의 형식 및 출력 반영
- 원인 1: `DateManager`가 다이얼로그 preview에서 대문자 단일 토큰을 `replaceAll`할 뿐 소문자/연속 토큰 폭을 해석하지 않는다.
- 원인 2: 실제 출력 공용 `projectLabelPrintColumnValues()`가 `LabelSizeSetup`을 입력받지 않아 날짜 설정 저장 후 preview를 재생성해도 raw `yyyyMMdd`/`HHmm` 값이 다시 치환된다.
- 레거시 확인: `CDateMananger::UserDefineYMD/HM`은 대소문자를 모두 허용하고 연속 토큰 길이에 맞춰 오른쪽 자릿수 또는 왼쪽 0 padding을 적용한다.
- 수정 예정: 공용 DateManager formatter를 다이얼로그와 출력 projection이 함께 사용하고, 품목관리/라벨출력/저울출력 preview 및 실제 발행에 현재 label setup을 전달한다. QR/GS1 token raw 날짜 계약은 유지한다.
- stage 예정: 날짜 setup/label print/scale output/home manager 관련 구현과 테스트, `SESSION_HANDOFF.md`. unrelated `lib/core/app.dart` 제외.
- 편집 완료: DateManager에 strict `yyyyMMdd`/`HHmm` formatter와 대소문자 `y/m/d`, `h/m` 연속 토큰 폭 해석을 추가했다. 연도는 오른쪽 N자리/4자리 초과 왼쪽 0 padding, 나머지 성분은 레거시 폭 규칙을 사용한다.
- 편집 완료: `projectLabelPrintColumnValues()`에 optional `LabelSizeSetup`을 연결하고 품목관리/라벨출력/저울출력 preview 및 실제 발행에서 현재 setup을 전달한다. 사용 해제 그룹은 raw 셀 값을 유지한다.
- 편집 완료: workbook direct 치환은 포맷된 projection을 사용하고 QR/GS1 token resolver는 raw column callback을 사용하도록 분리했다. 자동증가 DB 저장 projection에는 setup을 전달하지 않아 raw 저장 계약을 유지한다.
- 편집 완료: 날짜 타입 다이얼로그에 소문자 토큰과 반복 자릿수 도움말을 추가했다. 기본 preview `2000.01.01`, `12:01`을 테스트로 고정했다.
- 테스트 추가: 연도 `y`~`yyyyyy`, 소문자 날짜/시간, invalid raw 보존, setup 사용/해제 direct 출력, 다이얼로그 소문자 입력/도움말.
- 문서 변경: 사용자 정의 날짜/시간 토큰을 소문자 기준으로 설명하고 대문자 호환 및 반복 폭 규칙/연도 예시를 명시했다.
- focused 검증: DateManager 6개 통과(기본값 테스트 추가 전), DateManager+dialog+projection 15개 통과(기본값/도움말 테스트 추가 전), 기존 projection 5개 통과.
- 최종 테스트 실행 예정: `flutter test test/date_manager_test.dart test/date_type_setup_dialog_test.dart test/label_print_auto_increment_test.dart test/label_print_pipeline_test.dart test/scale_output_test.dart test/label_sheet_toolbar_test.dart`.
- analyzer 실행 예정: 변경된 날짜 setup/label print/scale output/home manager 구현과 테스트 파일 대상 `flutter analyze`.
- 최종 검증: 관련 테스트 184개 통과. 변경 Dart 10개 파일 analyzer `No issues found` (3.2초), diagnostics 0건.
- 완료 결과: 사용자 정의 날짜/시간은 대소문자 토큰과 반복 폭을 지원하고, 날짜 설정 저장 후 품목관리/라벨출력/저울출력 preview 및 실제 발행 direct 값에 즉시 적용된다. QR/GS1 token과 DB raw 저장값은 기존 형식을 유지한다.
- stage/commit 대상: `lib/features/date_setup/domain/date_manager.dart`, `lib/features/date_setup/presentation/date_type_setup_dialog.dart`, `lib/features/label_print/domain/label_print_auto_increment.dart`, `lib/features/label_print/application/label_print_pipeline.dart`, `lib/features/scale_output/application/scale_output.dart`, `lib/home_page_manager.dart`, 관련 테스트 4개, `doc/item_manager_modify.txt`, `SESSION_HANDOFF.md`. unrelated `lib/core/app.dart` 제외.
- 기능 커밋: `7ed5446` (`날짜 타입 형식을 출력에 반영`).

## 완료: 품목관리 조회 렌더 완료 후 첫 행 자동 선택
- 원인: 초기 session load는 draft 첫 행을 선택하지만 `ItemManage.initState()`가 해당 선택을 `FortuneTableSelectionController`에 투영하지 않아 첫 렌더의 선택 강조가 누락될 수 있다.
- 저장 재조회는 초기 load가 첫 행을 선택하고 render-ready까지 기다린 뒤, 저장 전 행을 다시 복원하고 tabs를 재생성해 첫 행 선택 요구와 충돌한다.
- 수정 예정: ItemManage 생성/새 draft 연결 시 draft 선택을 즉시 table selection에 투영한다. 저장 재조회는 초기 load의 첫 행 선택과 render-ready 결과를 유지한다. 변경 취소/품목 순서 변경의 기존 선택 복원은 유지한다.
- stage 예정: `lib/features/item/presentation/item_manage.dart`, `lib/home_page_manager.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. unrelated `lib/core/app.dart` 제외.
- 편집 완료: `ItemManage.initState()`와 새 draft controller 연결 시 draft 선택 key를 한 번 snapshot해 `FortuneTableSelectionController`에 투영한다. 첫 렌더 ready 시점부터 첫 행이 선택 표시된다.
- 편집 완료: 저장 reload는 `keepInitialFirstSelection` 경로를 사용해 session load가 선택한 첫 행과 render-ready 결과를 유지한다. 저장 전 행 복원과 추가 tab reset은 생략한다.
- 테스트 추가: `ItemManage projects initial draft selection before ready`에서 ready 시점의 실제 table selection `{0}`을 검증한다.
- focused 검증: `test/fortune_table_test.dart` 66개 통과(선택 key snapshot 최적화 전).
- 최종 검증 실행 예정: `flutter test test/fortune_table_test.dart test/label_sheet_toolbar_test.dart`.
- analyzer 실행 예정: `flutter analyze lib/features/item/presentation/item_manage.dart lib/home_page_manager.dart test/fortune_table_test.dart`.
- 최종 검증: 관련 테스트 232개 통과. analyzer `No issues found` (3.6초), 변경 파일 diagnostics 0건.
- 완료 결과: 초기 조회와 저장 재조회 모두 최종 ItemManage 렌더에서 첫 행이 선택 표시된다. 변경 취소와 품목 순서 변경은 기존 선택 복원 동작을 유지한다.
- stage/commit 대상: `lib/features/item/presentation/item_manage.dart`, `lib/home_page_manager.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. unrelated `lib/core/app.dart` 제외.
- 기능 commit: `e4c09f0` (`품목관리 조회 후 첫 행 자동 선택`).

## 완료: 품목관리 1만 행 build/auto-fit 최적화
- 병목 1: `FortuneTable`이 rebuild마다 전체 `행×컬럼` 문자열 signature를 만들고 다시 전체 셀을 TextPainter로 측정한다.
- 병목 2: `ItemManage._resolveDisplayItems()`가 선택/busy 같은 UI rebuild에도 전체 draft 행의 preview 객체와 identity map을 재생성한다.
- 수정 예정 1: FortuneTable에 opt-in auto-fit revision/sample API를 추가해 품목관리만 전체 signature를 생략하고 최대 200행을 측정한다. 기존 사용처의 전체 auto-fit 계약은 유지한다.
- 수정 예정 2: draft content revision과 ItemManage display cache를 추가해 데이터 변경 때만 전체 display 목록을 재생성한다.
- stage 예정: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/features/item/domain/item_manager_draft.dart`, `lib/features/item/presentation/item_manage.dart`, 관련 테스트, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.
- 편집 완료: `FortuneTable.autoFitRevision`/`autoFitSampleSize` opt-in API를 추가했다. revision 사용 시 전체 문자열 signature를 생략하며 지정된 선두 표본 행만 폭 측정한다. 기본값은 기존 전체 signature/전체 행 측정을 유지한다.
- 편집 완료: `ItemManagerDraftController.contentRevision`을 추가했다. 값/행 구조/column content 변경에서 증가하고 selection-only 변경에서는 증가하지 않는다.
- 편집 완료: `ItemManage._resolveDisplayItems()`가 controller identity + content revision + market/label size 기준으로 preview 객체/list/map을 재사용한다. draft table auto-fit은 최대 200행만 측정한다.
- 테스트 추가: revision 기반 표본 폭 재계산, 500행 rebuild 전체 text scan 방지, selection-only display 객체 identity 재사용, draft content revision 분리.
- 중간 검증: `test/fortune_table_test.dart` 64개 통과(500행 callback 계수 테스트 추가 전), `test/item_manager_draft_test.dart` 29개 통과, 변경 파일 diagnostics 0건.
- 최종 검증 실행 예정: `flutter test test/fortune_table_test.dart test/item_manager_draft_test.dart test/label_sheet_toolbar_test.dart`.
- analyzer 실행 예정: `flutter analyze third_party/fortune_sheet/lib/src/fortune_table.dart lib/features/item/domain/item_manager_draft.dart lib/features/item/presentation/item_manage.dart test/fortune_table_test.dart test/item_manager_draft_test.dart`.
- 최종 검증: 관련 테스트 260개 통과. analyzer `No issues found` (5.8초).
- 완료 결과: selection/focus/busy rebuild는 1만 행 preview 객체와 전체 auto-fit signature를 재생성하지 않는다. content revision 변경 시 preview cache를 갱신하고 선두 최대 200행만 폭 측정한다.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/features/item/domain/item_manager_draft.dart`, `lib/features/item/presentation/item_manage.dart`, `test/fortune_table_test.dart`, `test/item_manager_draft_test.dart`, `SESSION_HANDOFF.md`. unrelated `lib/core/app.dart` 제외.
- 로컬 commit: `09cde67` (`품목관리 대용량 테이블 재빌드 최적화`; handoff 해시 기록 후 amend).

## 완료: 품목 저장 완료 후 처리 중 표시 해제
- 현상: 수정 저장과 DB 재조회가 완료된 뒤에도 품목관리 좌하단 spinner와 `처리 중`이 남고 버튼이 비활성화된다.
- 원인: tab content는 `_createTabController()` 시점의 widget snapshot을 보관한다. 저장 reload 중 `commandBusy=true`로 `_resetTabs()`된 뒤 `finally`에서 bool만 false로 바꾸고 `setState()`해도 저장된 `ItemManage(commandBusy: true)` content가 교체되지 않는다.
- 수정 예정: 저장 `finally`에서 busy를 false로 바꾼 뒤 tabs를 재생성한다. footer widget 회귀를 busy true→false 전환까지 확장한다.
- 편집 완료(`home_page_manager.dart`): 저장 `finally`에서 `_itemDraftCommandBusy=false` 설정 후 `_resetTabs()`를 호출해 현재 선택 탭을 보존한 busy=false content snapshot으로 교체한다.
- 테스트 변경(`fortune_table_test.dart`): ItemManage footer를 busy true에서 false로 갱신한 뒤 spinner/문구가 사라지고 엑셀 가져오기 버튼이 다시 활성화되는지 검증한다.
- focused 검증: `ItemManage shows progress while a command is running` 통과.
- 최종 검증: `fortune_table_test.dart` 62건, `label_sheet_toolbar_test.dart` 166건 통과. 변경 파일 analyzer `No issues found`; diagnostics 0건.
- stage 대상: `lib/home_page_manager.dart`, `test/fortune_table_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

## 완료: 기존 품목 미수정 컬럼 형식 검증 차단
- 최신 로그 `app_2026-07-30_13-23-33.log`: 주원료 수정 저장 시 DB transaction 전에 `item:722292`, 컬럼 `139793` 제품유형의 바코드 형식 검증으로 두 차례 거부됐다.
- 레거시 비교: `CMainItemTable` 저장은 변경된 셀만 `CColumnContentDAO::UpdateBatchDataByColAndItemID`에 전달하며, 주원료 수정 시 기존 일반 컬럼 전체를 바코드 형식으로 재검증하지 않는다.
- 원인 1: 현재 저장 검증은 기존 행의 미수정 동적 컬럼까지 타입별 형식 검증한다.
- 원인 2: 바코드 검증/정규화 조건에 `TYPE_BARCODE` 확인이 없어 일반 컬럼의 barcode 설정값도 검증에 관여할 수 있다.
- 수정 예정: 길이·필수값 검사는 유지하고 타입별 형식 검증은 신규 행 또는 실제 변경된 기존 셀에만 적용한다. 바코드 정규화/검증은 `TYPE_BARCODE`로 제한하고 두 경로 회귀를 추가한다.
- 편집 완료(`item_manager_draft.dart`): 타입별 형식 검증 전에 신규 행 또는 해당 `columnDrafts` 변경 여부를 확인하고, 바코드 정규화/검증은 실제 `TYPE_BARCODE`에만 적용한다.
- 테스트 추가(`item_manager_draft_test.dart`): `TYPE_BASE` 제품유형의 `PE`가 ITF 설정 잔여값으로 거부되지 않는 경로와, 주원료만 수정할 때 미수정 legacy ITF 값은 건너뛰되 ITF 셀을 수정하면 거부되는 경로를 검증한다.
- 검증 전환: 테스트 어댑터와 CLI 복수 `--plain-name` 필터가 0건을 반환했고 첫 CLI가 scoped content fixture 타입 오류를 검출했다. fixture를 실제 `ColumnItemKey/TColumnContent` 구조로 수정했다.
- 최종 검증: `item_manager_draft_test.dart` 전체 28건 통과. 변경 파일 analyzer `No issues found`; diagnostics 0건, `git diff --check` 통과.
- stage 대상: `lib/features/item/domain/item_manager_draft.dart`, `test/item_manager_draft_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

## 완료: 기존 품목 주원료 인라인 편집 및 시트 동기화
- 현재 제한: `ItemManage`의 주원료 `isTextEditable`과 commit이 `draft.isNew`인 행만 허용해 기존 품목은 더블클릭 편집이 불가능하다.
- 확인: 상위 `_commitItemElementTextDraft()`는 행 종류와 무관하게 plain text로 workbook payload를 만들고, `_applyItemElementDraft()`가 draft와 열린 품목 preview를 갱신한다.
- 수정 예정: 편집 가능한 기존 draft에도 주원료 인라인 editor/commit을 허용하고, 기존 행 plain/payload 갱신 및 같은 기존 행 preview workbook 동기화 회귀를 추가한다.
- 편집 완료(`item_manage.dart`): 주원료 editor/commit의 `draft.isNew` 제한을 제거하고 유효한 기존/신규 draft 모두 callback으로 전달한다.
- 테스트 변경(`fortune_table_test.dart`): 기존 행 주원료 더블클릭, 즉시 focus, plain/payload 갱신과 `modified` 상태 전환을 검증한다.
- 테스트 변경(`label_sheet_toolbar_test.dart`): 기존 `item:41`의 외부 주원료 payload 변경이 열린 preview workbook에 반영되는지 검증한다.
- focused 검증: 기존 행 표 편집과 기존 행 preview 동기화 2건 통과.
- 최종 검증: `fortune_table_test.dart` 62건, `label_sheet_toolbar_test.dart` 166건 통과. 변경 파일 analyzer `No issues found`; diagnostics 0건.
- stage 대상: `lib/features/item/presentation/item_manage.dart`, `test/fortune_table_test.dart`, `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. 기존 unrelated `lib/core/app.dart`는 제외한다.

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