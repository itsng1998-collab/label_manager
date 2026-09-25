# SESSION HANDOFF

## 완료 작업: 품목 출력 미리보기 연결 바코드 렌더링
- **완료**: 공용라벨의 바코드 개체를 `바코드 (#BARCODE)`에 연결한 뒤 품목 값 `88123456789012`를 입력해도 출력 내용 미리보기에 저장 당시 표시용 바코드가 남는 1.4.16 회귀를 수정했다.
- 재현 로그 확인: `.tmp/1.4.16로그/공용라벨관리_바코드 미표시.log`에는 저장 workbook과 미리보기 생성 흔적은 있으나 연결 바코드의 resolve/render 단계 로그가 없다.
- 원인 확인: `_replaceImageKeywords`는 `barcodeObjectId`를 `ItemCodeDataResolver`로 해석해 `barcodeText` metadata만 교체하고 실제 표시되는 `FortuneImage.src`는 저장 당시 PNG로 유지한다.
- 구현 방향: 품목 출력 미리보기에서 치환된 barcode metadata로 `labelSheetBarcodeRenderer`를 실행하고, 완료된 PNG `src`가 준비된 뒤 `LabelOutputPreview`를 표시/캡처한다.
- 재현 로그 계획: `itemOutputBarcode` feature에 objectId/text/format/geometry 및 render 성공·실패를 기록한다.
- 수정 전 focused test 추가: `barcodeText=88123456789012` metadata를 renderer 요청에 전달하고 기존 `src`를 반환 PNG data URI로 교체하는지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "item output preview renders resolved barcode image source"`.
- 수정 전 테스트 결과: **실패(예상)**. 재렌더 helper가 없었고, 테스트 fixture의 잘못된 `const Uint8List.fromList`도 확인해 함께 수정했다.
- `lib/home_page_manager.dart` 편집 완료: 연결값 해석 성공 metadata를 표시하고, 품목 미리보기에서 해당 바코드를 `labelSheetBarcodeRenderer`로 비동기 렌더한 뒤 PNG `src`와 body geometry를 갱신한다. 미리보기/출력 캡처는 렌더 완료 workbook을 사용한다.
- 재현 로그 추가: `regression-debug-v1 feature=itemOutputBarcode`의 `renderStarted`, `renderCompleted`, `renderFailed`, `renderException` 이벤트에 objectId/text/format/geometry/결과를 기록한다.
- `test/label_sheet_toolbar_test.dart` 편집 완료: `88123456789012`가 renderer 요청에 전달되고 반환 PNG data URI와 body ratio가 적용되는지 검증한다.
- focused test 재실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "item output preview renders resolved barcode image source"`.
- focused test 결과: **통과(1/1)**. `itemOutputBarcode/renderStarted` 및 `renderCompleted` 로그에서 `objectId=#BARCODE text=88123456789012 format=code128`을 확인했다.
- Dart formatter 적용 완료: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`.
- IDE diagnostics 결과: production/test 파일 오류 0건.
- 앱 바코드 관련 테스트 결과: **통과(7/7)**.
- `pubspec.yaml` 버전: `1.4.24` → `1.4.25`.
- 품목 출력 미리보기 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "item output preview"`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart`.
- analyzer 1차 결과: **No issues found**.
- 품목 출력 미리보기 관련 테스트 1차 결과: 8개 중 1개 실패. 바코드가 없는 일반 미리보기까지 Future 경로를 거치며 `item output preview keeps zoom after panel recreation`의 폭맞춤 적용 시점이 바뀌었다.
- 회귀 보정: `itemCodePreviewResolved=true`인 연결 바코드가 있는 workbook만 비동기 재렌더하고, 일반 미리보기는 기존 동기 `LabelOutputPreview` 경로를 유지한다.
- zoom focused test 재실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "item output preview keeps zoom after panel recreation"`.
- zoom focused test 결과: **통과(1/1)**.
- 품목 출력 미리보기 관련 테스트 최종 결과: **통과(9/9)**.
- analyzer 최종 결과: **No issues found**(종료 코드 0).
- IDE diagnostics 최종 결과: production/test 파일과 `pubspec.yaml` 오류 0건.
- 첨부 화면 추가 확인: 흰색 `#BARCODE` 박스는 저장 PNG가 아니라 painter의 편집용 연결 ID 오버레이다. 재렌더 완료된 미리보기 사본에서 `barcodeObjectId` metadata를 제거해 숫자 바코드를 가리지 않도록 보정하고, 원본 공용라벨 데이터는 유지한다.
- 오버레이 제거 focused test 재실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "item output preview renders resolved barcode image source"`.
- 오버레이 제거 focused test 결과: **통과(1/1)**.
- 최종 품목 출력 미리보기 관련 테스트 결과: **통과(9/9)**.
- 최종 analyzer 결과: **No issues found**(종료 코드 0).
- 최종 IDE diagnostics 결과: production/test 파일과 `pubspec.yaml` 오류 0건.
- 최종 diff 검토 예정: `git diff --check`, `git status --short`, 관련 파일 diff 확인.
- stage/commit 대상: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 dirty `lib/core/app.dart` 제외.
- 최종 diff 검토 완료: `git diff --check` 통과, 관련 파일 외 무관한 포맷 변경 없음.
- 기능 구현 커밋: `75f5593` (`품목 미리보기 연결 바코드 렌더링`).
- DTD 확인 결과: VS Code DTD는 연결돼 있으나 실행 중인 앱이 없어 hot reload 대상 없음.
- 최종 diff 검토 예정: `git diff --check`, `git status --short`, 관련 파일 diff 확인.
- stage/commit 예정: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 dirty `lib/core/app.dart` 제외.
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 완료 작업: 바코드 개체 속성 형식 ComboBox
- **완료**: 시트의 바코드 개체를 선택했을 때 `바코드 속성`의 형식을 자유 입력 TextField가 아닌 삽입 다이얼로그와 동일한 형식 목록 ComboBox로 변경했다.
- 현재 원인: `FortuneObjectLayerPanel`은 barcode format 목록을 받지 않으며 `_ObjectPropertyEditor`가 `barcodeFormatId`를 일반 `_field` TextField로 렌더링한다.
- 구현 방향: `LabelSheetWorkbench`의 `labelSheetBarcodeFormats`를 개체 패널까지 전달하고, metadata `barcodeFormatId`를 초기 선택값으로 사용하는 DropdownButtonFormField로 교체한다.
- 재현 로그 계획: 패널 초기화와 형식 선택 변경 시 objectId/previous/next/options/matched 및 데이터 필터 전후 길이를 기록한다.
- 수정 전 focused test 추가: 삽입 metadata가 `code128`인 바코드의 형식 컨트롤이 ComboBox이고 초기 표시가 `Code128`, 옵션이 `Code128`/`EAN13`인지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_object_controller_test.dart --plain-name "barcode property format uses insert formats and initial selection"`.
- 수정 전 테스트 결과: **실패(예상)**. `FortuneObjectLayerPanel`에 `barcodeFormats` named parameter가 없어 컴파일 실패했다. 테스트의 Flutter API 비호환 `DropdownButtonFormField.items` 직접 접근은 실제 메뉴 표시 검증으로 교체했다.
- `third_party/fortune_sheet/lib/src/fortune_object_layer_panel.dart` 편집 완료: panel/editor에 `barcodeFormats` 전달, metadata format ID 정규 매칭, 형식 DropdownButtonFormField, 변경 시 데이터 formatter/draft 갱신, `fortune-object-barcode-format-debug-v1` 초기화/변경 로그를 추가했다.
- `third_party/fortune_sheet/test/fortune_object_controller_test.dart` 편집 완료: ComboBox 초기값/실제 메뉴 옵션 회귀 테스트를 추가하고 기존 draft 테스트의 형식 변경을 실제 dropdown 선택으로 전환했다.
- focused test 1차는 높이 700인 속성 lazy list가 형식 필드를 아직 build하지 않아 finder가 비어 실패했다. 기존 패널 테스트와 동일한 높이 1200으로 조정했다.
- focused test 재실행 결과: **통과(1/1)**. 로그에서 `metadataFormat=code128 selectedFormat=code128 matched=true options=2`를 확인했다.
- `lib/features/label_sheet/label_sheet_workbench.dart` 편집 완료: 실제 개체 패널에도 canvas와 동일한 `labelSheetBarcodeFormats`를 전달한다.
- 로그 보정 완료: object 식별자를 `kind/id`로 기록한다.
- `pubspec.yaml` 버전: `1.4.23` → `1.4.24`.
- 기존 draft 회귀 + 새 ComboBox 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_object_controller_test.dart --plain-name "barcode property"`.
- 기존 draft 회귀 + 새 ComboBox 테스트 결과: **통과(4/4)**. `CODE128 → ean13 → CODE128` 선택 로그와 데이터 필터 길이 변화를 확인했다.
- Dart formatter 적용 완료: `fortune_object_layer_panel.dart`, `fortune_object_controller_test.dart`, `label_sheet_workbench.dart`.
- 전체 개체 컨트롤 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_object_controller_test.dart`.
- 앱 바코드/툴바 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze third_party/fortune_sheet/lib/src/fortune_object_layer_panel.dart lib/features/label_sheet/label_sheet_workbench.dart third_party/fortune_sheet/test/fortune_object_controller_test.dart test/label_sheet_toolbar_test.dart`.
- 전체 개체 컨트롤 테스트 결과: **통과(50/50)**.
- `label_sheet_toolbar_test.dart` 전체 결과: **실패(203 통과/1 실패)**. 실패는 이번 변경과 무관한 기존 RTF 문자셋 테스트 `item element RTF conversion decodes Korean ANSI hex`이며 예상 문자열과 실제 mojibake가 달랐다(`?쒗뭹紐? ?멸린` 예상, `?쒗뭹紐? ?り린` 실제).
- 앱 바코드 관련 테스트 재실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "barcode"`.
- 앱 바코드 관련 테스트 결과: **통과(6/6)**. 실제 workbench 패널 초기화 로그에서 `selectedFormat=code128 matched=true options=13`을 확인했다.
- IDE diagnostics 결과: production/test 파일과 `pubspec.yaml` 오류 0건.
- analyzer 결과: **No issues found**(종료 코드 0).
- DTD 확인 결과: VS Code DTD 연결 성공, 연결된 실행 앱이 없어 hot reload 대상 없음.
- 최종 diff 검토 완료: `git diff --check` 통과, 관련 파일 외 무관한 포맷 변경 없음.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_object_layer_panel.dart`, `third_party/fortune_sheet/test/fortune_object_controller_test.dart`, `lib/features/label_sheet/label_sheet_workbench.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 dirty `lib/core/app.dart` 제외.
- 기능 구현 커밋: `f1225f7` (`바코드 속성 형식 선택 목록 적용`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 완료 작업: 공용라벨 이름 열 더블클릭 삽입 재검증
- **완료**: 우측 `사용 항목`의 이름 셀을 더블클릭하면 키워드 셀과 동일하게 현재 편집 위치에 `#키워드`를 삽입하는 요청을 현재 코드 기준으로 재검증했다.
- 구현 확인: `common_label_manage.dart`는 키워드·이름 열(`index < 2`) 모두 `_insertKeyword`를 호출하며, `LabelSheetKeywordInsertController.insertAtCurrentContext('#${row.keyword}')`를 사용한다.
- 재현 로그 확인: `regression-debug-v1 feature=commonLabelKeyword event=doubleTapInsert`에 column/rowIndex/keyword/name/inserted를 기록한다.
- 기존 테스트 한계: FortuneTable column callback을 직접 호출해 실제 이름 셀의 double-tap gesture 연결은 검증하지 않았다.
- 테스트 강화: 이름 열 검증을 실제 `저울중량` 셀 두 번 탭으로 교체해 `#SWEIGHT` 삽입을 확인한다.
- focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/common_label_manage_test.dart --plain-name "keyword and name columns insert keyword on double tap"`.
- focused test 1차 결과: 실제 삽입 assertion은 통과했으나 테스트 종료 시 `DoubleTapGestureRecognizer` Timer가 남아 실패했다. 제스처 후 `pumpAndSettle`로 Timer를 정리하도록 테스트를 보정했다.
- focused test 재실행 결과: **통과(1/1)**.
- 재현 로그 검증 강화: 실제 이름 셀 더블클릭 시 `commonLabelKeyword/doubleTapInsert` 로그의 `column=이름`, `keyword=SWEIGHT`, `name=저울중량`, `inserted=true`를 확인한다.
- 로그 검증 focused test 1차는 nullable `debugPrint` message 타입으로 로드 실패해 null 메시지를 제외하도록 캡처를 보정했다.
- 로그 검증 focused test 2차는 Flutter 전역 debug 변수 복원 시점 assertion으로 실패해, 캡처 범위를 실제 더블클릭 구간으로 좁히고 `try/finally`에서 즉시 복원하도록 보정했다.
- 로그 검증 focused test 최종 결과: **통과(1/1)**.
- Dart formatter 적용 완료: `test/common_label_manage_test.dart`.
- IDE diagnostics 결과: production/test 파일과 `pubspec.yaml` 오류 0건.
- DTD 확인 결과: 연결된 실행 앱이 없어 hot reload 대상 없음.
- 공용라벨 관리 전체 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/common_label_manage_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/label_sheet/presentation/common_label_manage.dart test/common_label_manage_test.dart`.
- 공용라벨 관리 전체 테스트 결과: **통과(13/13)**.
- analyzer 결과: **No issues found**(종료 코드 0).
- production 결론: 이름 열 삽입 콜백과 재현 로그가 이미 구현돼 있어 동작 코드 추가 변경은 필요하지 않았다.
- 최종 diff 검토 완료: `git diff --check` 통과, 테스트·버전·handoff 외 무관한 포맷 churn 없음.
- stage/commit 대상: `test/common_label_manage_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `25d24132dc342f0bc24d07c718086ce079ed89d9` (`공용라벨 이름 더블클릭 삽입 검증 강화`).
- `pubspec.yaml` 편집 완료: 기존 기능의 실제 UI 제스처와 로그 회귀 검증 보강이므로 PATCH 단계로 `1.4.22`에서 `1.4.23`으로 갱신했다.
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 완료 작업: GS1 AI 포함 항목 저장 실패
- **완료**: 1.4.16에서 GS1AL의 AI code를 저장한 뒤 GS1BARCODE에 `#GS1AL`을 포함하고 저장하면 `Unsupported changed property key for column 140793`로 실패하는 증상을 수정했다.
- 제출 로그/코드 확인: `LabelColumnDraft.persistedValues`는 `useGs1` 변경을 생성하지만 `LabelColumnSaveDao._validateCommand` auxiliary allow-list와 GS1 SQL projection에는 `useGs1`이 빠져 있다.
- 레거시 확인: GS1 AI 포함 추가 시 `SetGS1CodeSetting(TRUE, 포함ID, CODE128)`로 사용 여부와 포함 관계를 함께 설정한다. 현재 DB 조회의 `USE_GS1_CODE`는 `BM_GS1_CONTAIN_COLUMN` 관계 존재 여부로 파생된다.
- 구현 방향: `useGs1`을 저장 command의 지원 key로 포함하고 XML projection 및 touched GS1 row에 전달한다. false이면 포함 관계를 삭제만 하고, true이면 유효한 포함 ID를 다시 삽입한다.
- 재현 로그: 저장 command 검증과 GS1 관계 적용 시 columnId/type/useGs1/changedKeys/contain count를 기록하되 로그에는 업무 판단을 넣지 않는다.
- 수정 전 focused test 추가 및 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_column_save_test.dart --plain-name "GS1 barcode use and contain changes build save statement"`.
- 수정 전 focused test 결과: **실패(예상 일치)**. `Bad state: Unsupported changed property key for column 140793`를 재현했다.
- `lib/features/label_column/data/label_column_save.dart` 편집 완료: `useGs1`을 새/수정 GS1 projection과 touched row에 포함하고, false일 때 포함 관계를 재삽입하지 않도록 제한했다.
- 재현 로그 추가 완료: `labelColumnGs1Save`의 `buildRequested`, `validated`, `validationRejected` 이벤트에 columnId/type/useGs1/changedKeys/containCount/unsupported를 기록한다.
- 수정 후 DAO focused test 결과: **통과(1/1)**.
- `test/label_column_edit_dialog_test.dart` 강화: 실제 GS1 barcode 편집 command의 `useGs1` changed key와 DAO statement 생성 성공을 검증한다.
- `test/label_column_save_test.dart` 강화: GS1 사용=false일 때 관계를 재삽입하지 않는 SQL gate가 INSERT/검증 양쪽에 있는지 확인한다.
- 다이얼로그 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_column_edit_dialog_test.dart --plain-name "GS1 barcode shows contain column IDs as keywords"`.
- 다이얼로그 focused test 결과: **통과(1/1)**.
- `pubspec.yaml` 편집 완료: 호환 가능한 국소 저장 버그 수정이므로 PATCH 단계로 `1.4.21`에서 `1.4.22`로 갱신했다.
- Dart formatter 적용 후 라벨 항목 편집·저장 전체 테스트 및 analyzer 실행 예정.
- Dart formatter 적용 완료: `label_column_save.dart`, `label_column_save_test.dart`, `label_column_edit_dialog_test.dart`.
- IDE diagnostics 결과: 변경 production/test 파일과 `pubspec.yaml` 오류 0건.
- 관련 전체 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_column_edit_test.dart test/label_column_edit_dialog_test.dart test/label_column_save_test.dart`.
- 관련 전체 테스트 결과: **통과(53/53)**.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/label_column/data/label_column_save.dart test/label_column_save_test.dart test/label_column_edit_dialog_test.dart`.
- analyzer 결과: **No issues found**(종료 코드 0).
- DTD 확인 결과: 연결된 실행 앱이 없어 hot reload 대상 없음.
- 최종 diff 검토 완료: `git diff --check` 통과, SQL projection 필드/SELECT 순서와 GS1 relation gate 정합성 확인, 무관한 포맷 churn 없음.
- stage/commit 대상: `label_column_save.dart`, `label_column_save_test.dart`, `label_column_edit_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `cb749aff0c5bd9c0ccc48eda3d416d9eb7cf804e` (`GS1 AI 포함 항목 저장 오류 수정`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 완료 작업: 공용라벨 Ctrl+Z 후 저장 아이콘 무반응
- **완료**: 1.4.16에서 12행 복사본을 14·15행에 붙여넣고 15행을 Ctrl+Z로 취소한 뒤 저장 아이콘이 반응하지 않으며, `SPRICE` 필수등록 체크 해제 후에야 저장되는 증상을 수정했다.
- 제출 로그 확인: 첫 시트 변경 직후 dirty=true였지만 저장 callback은 약 47초 동안 시작되지 않았고, `SPRICE` 체크 해제로 부모가 재빌드된 직후 시작됐다. 이후 필수 누락 경고와 DB 저장은 정상 완료됐다.
- 원인 가설: FortuneSheet 히스토리 snapshot의 JSON 복제에서 `customToolbarItems.onClick`이 제외되고, Undo가 callback 없는 저장 항목을 복원한다. 부모 재빌드가 live settings를 다시 주입하면 저장이 복구된다.
- 판별 테스트 수정 완료: 기존 Ctrl+Z 회귀 테스트의 settings callback 직접 호출을 실제 화면 저장 아이콘 탭으로 교체했다. 수정 전 `savedPayload`가 null로 **실패(예상 일치)**해 내부 toolbar callback 소실을 확인했다.
- `third_party/fortune_sheet/lib/src/fortune_sheet_codec.dart` 편집 완료: custom toolbar 항목 역직렬화 시 동일 key의 fallback 항목에서 직렬화 불가능한 `onClick`만 복원한다.
- `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 편집 완료: workbook 복제는 기존 설정 복원 의미를 유지하며, Undo/toolbar 상태 로그만 추가한다.
- `third_party/fortune_sheet/test/fortune_sheet_codec_test.dart` 테스트 추가: JSON tooltip/disabled를 유지하면서 동일 key fallback의 runtime callback만 복원하는 계약을 검증한다.
- codec focused test 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_sheet_codec_test.dart --plain-name "workbookFromJson restores custom toolbar runtime callback"`.
- codec focused test 결과: **통과(1/1)**.
- IDE diagnostics 결과: 변경 production/test 파일과 `pubspec.yaml` 오류 0건.
- DTD 확인 결과: 연결된 실행 앱이 없어 hot reload 대상 없음.
- Dart formatter 적용 완료: `fortune_sheet_codec.dart`, `fortune_sheet_codec_test.dart`, `label_sheet_toolbar_test.dart`. 대형 `fortune_sheet_canvas.dart`는 변경 구간만 수동 정리해 불필요한 전면 포맷을 피했다.
- codec 전체 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_sheet_codec_test.dart`.
- 라벨시트 툴바 전체 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart`.
- codec 전체 테스트 결과: **통과(135/135)**.
- 라벨시트 툴바 전체 테스트 결과: **203/204 통과**, 수정과 무관한 `Gemini HTTP errors include response diagnostics`가 외부 Gemini API HTTP 429 `RESOURCE_EXHAUSTED`로 실패했다.
- 저장 관련 테스트 재검증 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "label sheet save"`.
- FortuneSheet custom toolbar 입력 검증 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart --plain-name "canvas custom toolbar item invokes callback"`.
- 저장 관련 테스트 재검증 결과: **통과(3/3)**.
- FortuneSheet custom toolbar 입력 검증 결과: **통과(1/1)**.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/lib/src/fortune_sheet_codec.dart third_party/fortune_sheet/test/fortune_sheet_codec_test.dart test/label_sheet_toolbar_test.dart`.
- analyzer 1차 결과: 이번 변경의 불필요한 `foundation.dart` import 1건과 `fortune_sheet_canvas.dart`의 기존 미사용 항목 10건으로 종료 코드 1. 신규 import는 제거하고 기존 범위 밖 경고는 수정하지 않는다.
- analyzer 재검증 결과: 전체 지정 분석에는 `fortune_sheet_canvas.dart`의 기존 unused warning 10건만 남았고, codec 및 두 테스트 파일 분석은 **No issues found**(종료 코드 0).
- 최종 diff 검토 완료: `git diff --check` 통과, 요청 관련 6개 파일 외 무관한 포맷 churn 없음.
- stage/commit 대상: `fortune_sheet_canvas.dart`, `fortune_sheet_codec.dart`, `fortune_sheet_codec_test.dart`, `label_sheet_toolbar_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `0886ac9c75215733d853d907ae8c825254cb9a88` (`공용라벨 실행 취소 후 저장 복구`).
- 재현 로그 추가: `fortune-history-toolbar-debug-v1`으로 Undo 복원 전 current/snapshot callback 상태와 custom toolbar 클릭의 command/disabled/callback/undo/redo 상태를 기록한다.
- 수정 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "label sheet save remains available after undoing latest paste"`.
- 수정 후 focused test 결과: **통과(1/1)**. 로그에서 `undoRestore`의 save/print callback과 `customToolbarClick` callback이 모두 true로 확인됐다.
- `pubspec.yaml` 편집 완료: 호환 가능한 국소 저장 버그 수정이므로 PATCH 단계로 `1.4.20`에서 `1.4.21`로 갱신했다.
- Dart formatter 적용 및 관련 전체 테스트/analyzer 실행 예정.
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 완료 작업: 타임바코드 종류 ComboBox 및 제한
- **완료**: 라벨 항목 편집의 정수 `타임바코드` 입력을 레거시와 같은 ComboBox로 변경하고 EAN13·UPC-A·EAN8에서는 비활성화한다.
- 레거시 확인: 옵션은 `사용안함(0)`, `DDMM(1)`, `HHDD(2)`, `DDHH(4)`, `YYMMDD(9)`이며 EAN13·UPC-A에서는 비활성화와 함께 `사용안함`으로 초기화한다. EAN8도 타임바코드 지원 대상이 아니다.
- 현재 원인: `label_column_edit_dialog.dart`가 `timeBarcodeType`을 자유 정수 `TextFormField`로 노출해 허용 종류를 선택할 수 없고 바코드 종류별 제한도 없다.
- 구현 방향: 기존 정수 저장 포맷은 유지하고 위 5개 값만 제공하는 ComboBox를 사용한다. EAN13·UPC-A·EAN8 선택 시 비활성화하고 stale 값을 `0`으로 정규화한다.
- 디버그 로그: 바코드 종류 변경과 타임바코드 선택 시 columnId/keyword/barcodeType/previous/next/enabled를 기록한다. 로그 함수에는 비즈니스 로직을 넣지 않는다.
- `lib/features/label_column/presentation/label_column_edit_dialog.dart` 편집 완료: 레거시 5개 옵션의 `DropdownMenu<int>`를 추가하고 EAN13·UPC-A·EAN8에서 비활성화 및 `0` 초기화한다. 바코드 종류/타임바코드 변경을 `regression-debug-v1` 로그로 기록한다.
- `test/label_column_edit_dialog_test.dart` 편집 완료: 옵션 값, 세 제한 바코드 정책, 실제 DDHH 선택 후 EAN13 전환 시 `사용안함` 초기화·비활성화를 검증한다.
- focused 테스트 결과: 정책 **2/2**, 위젯 상호작용 **1/1** 통과.
- `pubspec.yaml` 편집 완료: 기존 타임바코드 속성의 UI/활성화 조건 개선이므로 PATCH 단계로 `1.4.19`에서 `1.4.20`으로 갱신했다.
- Dart formatter 적용 완료: `label_column_edit_dialog.dart`, `label_column_edit_dialog_test.dart`.
- 관련 테스트 명령: `C:/Flutter/bin/flutter.bat test test/label_column_edit_dialog_test.dart test/label_column_edit_test.dart test/label_column_save_test.dart`.
- analyzer 명령: `C:/Flutter/bin/flutter.bat analyze lib/features/label_column/presentation/label_column_edit_dialog.dart test/label_column_edit_dialog_test.dart`.
- 관련 테스트 결과: `label_column_edit_dialog_test.dart`, `label_column_edit_test.dart`, `label_column_save_test.dart` 합계 **52/52 통과**.
- analyzer 결과: 변경 production/test 파일 **No issues found**, 종료 코드 0.
- IDE diagnostics 결과: 변경 production/test 파일과 `pubspec.yaml` 오류 0건.
- DTD 확인 결과: 연결된 실행 앱이 없어 hot reload 대상 없음.
- diff 검토 완료: `git diff --check` 통과, 무관한 formatter 변경 없음.
- stage/commit 대상: `label_column_edit_dialog.dart`, `label_column_edit_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `3322f7e7b570fff6631a9791187afdb0f4723405` (`타임바코드 종류 선택과 바코드 제한 적용`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 현재 작업: 품목관리 새로고침 후 무한 처리 중
- **진행 중**: 1.4.16에서 품목관리 우클릭 `새로 고침` 후 `처리 중`이 계속 표시되고 편집할 수 없는 제출 화면과 `.tmp/1.4.16로그/품목관리_새로고침_무한로딩.log`를 처리한다.
- 로그 버전은 **1.4.16**이다. `contextMenu refresh` → `reload-5 started` → `sessionLoad-6 completed` → `reload-5 completed`까지 정상 완료됐지만, 새 탭은 `busy=true` 상태로 생성됐고 이후 busy=false/탭 재생성 로그가 없다.
- 원인 확인: `_refreshItemManager()`가 reload 전에 `_itemDraftCommandBusy=true`로 설정하고 reload 내부 `_resetTabs()`가 `ItemManage(commandBusy: true)`를 캐시한다. `finally`는 부모 필드만 false로 바꾸고 `_resetTabs()`를 다시 호출하지 않아 화면만 영구 busy 상태로 남는다.
- 구현 방향: reload 성공 여부와 무관하게 mounted 상태에서는 busy를 먼저 false로 해제한 뒤 탭을 재생성한다. 새로고침 시작·reload 결과·실패·finishing/finished와 busy 전후, 탭 수를 디버그 로그에 기록한다.
- `lib/home_page_manager.dart` 편집 완료: `completeItemRefreshCommand`가 busy를 먼저 false로 바꾼 뒤 `_resetTabs()`를 실행한다. `_refreshItemManager()`는 성공·실패 모두 이 완료 경로를 사용하고 시작·reload 완료·실패·finishing·finished 상태를 기록한다.
- `test/home_page_manager_session_test.dart` 회귀 테스트 추가: 새로고침 완료 시 탭이 `busy=false` 상태로 재생성되는 순서를 검증한다.
- `lib/features/item/item_manager_debug_log.dart` 편집 완료: 로그 버전을 `item-manager-debug-v25`로 갱신했다.
- focused 테스트 결과: `item refresh completion clears busy before rebuilding cached tabs` **통과(1/1)**.
- `pubspec.yaml` 편집 완료: 새로고침 UI busy 캐시 버그 수정이므로 PATCH 단계로 `1.4.18`에서 `1.4.19`로 갱신했다.
- Dart formatter 적용 완료: `home_page_manager.dart`, `item_manager_debug_log.dart`, `home_page_manager_session_test.dart`.
- 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/home_page_manager_session_test.dart test/fortune_table_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/home_page_manager.dart lib/features/item/item_manager_debug_log.dart test/home_page_manager_session_test.dart`.
- 관련 테스트 결과: **통과(84/84)**. 새로고침 메뉴 dispatch, busy footer, 완료 순서에 회귀 없음.
- 정적 분석 결과: **통과**, `No issues found` (3개 대상, 종료 코드 0).
- DTD 연결 결과: 실행 중인 Flutter 앱이 없어 hot reload 대상 없음.
- 변경 파일 diagnostics와 `git diff --check` 통과. `home_page_manager.dart` diff는 완료 helper와 `_refreshItemManager` 상태 전이 로그/완료 순서에만 한정된다.
- `_resetTabs()`가 내부에서 `setState`와 탭 컨트롤러 재생성을 수행하므로 busy=false 상태가 새 cached tab과 화면에 반영됨을 확인했다.
- 상태: **완료**. stage/commit 대상은 `lib/home_page_manager.dart`, `lib/features/item/item_manager_debug_log.dart`, `test/home_page_manager_session_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`다.
- 기능 커밋: `d3ed0206074b2ab9f783385d348866cc3faa85ec` (`품목관리 새로고침 무한 로딩 수정`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 현재 작업: 기존 등록 키워드 클라이언트 편집 기본값 복구
- **진행 중**: 1.4.16에서 품명·주원료 외 기존 키워드가 별도 설정 없이 `클라이언트 편집 불가`로 표시되는 제출 화면과 `.tmp/1.4.16로그/품목관리_등록키워드_클라이언트 편집 불가.log`를 처리한다.
- 로그 버전은 **1.4.16**이나 조회 SQL만 있고 반환된 열·품목별 `RICH_EDITABLE` 값과 판정 결과는 기록되지 않았다.
- 원인 확인: 1.3.132 이전 라벨 항목 추가 SQL이 기존 품목 콘텐츠를 `RICH_EDITABLE=0`으로 일괄 생성했다. 1.3.132부터 신규 행은 `1`로 생성하지만 기존 `0`은 그대로 남아 있다.
- 데이터 제약: 과거 자동 생성 `0`과 사용자가 명시한 불가 `0`은 동일한 필드이며 생성일·변경주체·명시 여부 메타데이터가 없다.
- 사용자 선택: 현재 DB에 명시적 불가 설정이 없다는 전제로 **전체 기존 `0`을 `1`로 한 번 교정**한다.
- 구현 방향: 품목 세션 첫 로드 전에 전체 `RICH_EDITABLE=0`을 `1`로 교정하고 성공한 경우에만 로컬 완료 마커를 저장한다. 이후 호출은 건너뛰어 새 명시적 불가 설정을 보존한다.
- 디버그 로그: 교정 시작·완료·건너뜀·실패, 앱/로그 버전, 교정 건수를 기록하고 열·품목별 editable 분포를 세션 조회 로그에 추가한다. 로그 함수에는 비즈니스 로직을 넣지 않는다.
- `lib/features/item/application/item_editable_default_repair.dart` 추가: 일회성 완료 마커를 확인하고 교정 성공 후에만 마커를 저장한다. 동시 호출은 같은 Future를 공유하고 실패 시 다음 세션에서 재시도한다.
- `lib/features/item/data/column_content_dao.dart` 편집 완료: `SET NOCOUNT ON`으로 전체 `RICH_EDITABLE=0`을 `1`로 교정하고 명시적 `NORMALIZED_COUNT` 결과를 반환한다. 조회 후 editable/불가 건수와 불가 column별 분포를 로그로 기록한다.
- `lib/features/item/application/item_manager_session_loader.dart` 편집 완료: 유효한 로그인/거래처 확인 후 일반 품목 데이터 조회 전에 일회성 교정을 실행한다.
- `lib/features/item/item_manager_debug_log.dart` 편집 완료: 로그 버전을 `item-manager-debug-v24`로 갱신했다.
- 테스트 추가: 교정 성공 후 1회만 실행, 실패 시 완료 마커 미저장, UPDATE 범위·NOCOUNT·명시적 교정 건수 반환 계약을 고정했다.
- focused 테스트 결과: `item_editable_default_repair_test.dart`, `item_manager_read_snapshot_test.dart` **통과(8/8)**.
- `pubspec.yaml` 편집 완료: 기존 데이터 기본값 복구 버그 수정이므로 PATCH 단계로 `1.4.17`에서 `1.4.18`로 갱신했다.
- Dart formatter 적용 완료: 변경된 production 4개와 테스트 2개 파일.
- 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/item_editable_default_repair_test.dart test/item_manager_read_snapshot_test.dart test/item_manager_session_loader_test.dart test/item_manager_draft_test.dart test/item_manager_save_dao_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/item/application/item_editable_default_repair.dart lib/features/item/application/item_manager_session_loader.dart lib/features/item/data/column_content_dao.dart lib/features/item/item_manager_debug_log.dart test/item_editable_default_repair_test.dart test/item_manager_read_snapshot_test.dart`.
- 관련 테스트 결과: **통과(51/51)**. 기존값 일회성 복구와 이후 명시적 허용/불가 draft·save 계약을 확인했다.
- 정적 분석 결과: **통과**, `No issues found` (6개 대상, 종료 코드 0).
- DTD 연결 결과: 실행 중인 Flutter 앱이 없어 hot reload 대상 없음.
- 신규 키워드 기본 허용 회귀 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_column_save_test.dart`.
- 신규 키워드 기본 허용 회귀 테스트 결과: **통과(16/16)**. 관련 최종 테스트는 합계 **67/67 통과**다.
- 변경 파일 diagnostics와 `git diff --check` 통과. formatter에 의한 요청 범위 밖 변경 없음.
- 운영 DB 데이터 교정은 앱의 첫 품목 세션 로드에서 실행되며, 이 작업 중 운영 DB UPDATE를 직접 실행하지 않아 실제 교정 건수는 사용자 재현 로그로 확인해야 한다.
- 상태: **완료**. stage/commit 대상은 `lib/features/item/application/item_editable_default_repair.dart`, `lib/features/item/application/item_manager_session_loader.dart`, `lib/features/item/data/column_content_dao.dart`, `lib/features/item/item_manager_debug_log.dart`, `test/item_editable_default_repair_test.dart`, `test/item_manager_read_snapshot_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`다.
- 기능 커밋: `dc59a24fd4810569ed25b4eade2b757a96525d5b` (`기존 키워드 클라이언트 편집 기본값 복구`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 현재 작업: 품목 편집 후 가로 스크롤 표시 유지 (1.4.16 재발)
- **진행 중**: 품목관리에서 소비기한을 `365`에서 `360`으로 Enter 확정한 뒤 필요한 가로 스크롤이 사라지는 제출 화면과 `.tmp/1.4.16로그/품목관리_수정진행시_가로스크롤오류.log`를 조사한다.
- 로그 버전은 **1.4.16**이다. 편집 전후 테이블은 `columns=18`, `contentWidth=2023.6`, `viewportWidth=1849.7`, `overflow=true`, `maxExtent=173.9`를 유지해 열 폭이나 overflow 계산 소실은 아니다.
- 편집 완료는 `17:34:48.049`의 `operation=editColumn event=completed`이며 직후 같은 18열로 다시 빌드됐다. State 교체나 overflow=false 전환은 기록되지 않았다.
- 원인 확인: Flutter `RawScrollbar`는 자식 rebuild 중 들어오는 `maxScrollExtent=0` 알림을 받으면 `thumbVisibility=true`여도 fade animation을 reverse한다. 레이아웃 overflow가 계속 true인데 정상 metrics 알림이 다시 오지 않으면 설정값은 true인 채 실제 painter만 사라질 수 있어 기존 테스트가 놓쳤다.
- `third_party/fortune_sheet/lib/src/fortune_table.dart` 편집 완료: 현재 레이아웃이 가로 overflow인 동안 일시적인 horizontal zero-extent 알림을 scrollbar painter에 전달하지 않는다. 정상 가로 metrics와 실제 overflow 해제 알림은 계속 처리한다.
- `lib/features/item/presentation/item_manage.dart` 편집 완료: `FortuneTable` 관측 콜백으로 가로 metrics의 accepted/ignored, notification 종류, 레이아웃 overflow, extent, pixels, viewport, 편집 상태를 중복 억제 후 기록한다.
- `lib/features/item/item_manager_debug_log.dart` 편집 완료: 제출 로그 판별을 위해 버전을 `item-manager-debug-v23`으로 갱신했다. 로그 함수에는 비즈니스 로직을 넣지 않았다.
- 회귀 테스트 추가: overflow 중 zero-extent 알림 차단 계약과 실제 품목관리 `RawScrollbar.notificationPredicate` 연결을 검증한다.
- focused 계약 테스트 결과: `가로 overflow 중 일시적인 zero extent 알림을 무시한다` **통과(1/1)**.
- `pubspec.yaml` 편집 완료: 호환 가능한 스크롤 표시 버그 수정이므로 PATCH 단계로 `1.4.16`에서 `1.4.17`로 갱신했다.
- Dart formatter 적용 완료: `fortune_table.dart`, `item_manage.dart`, `item_manager_debug_log.dart`, `item_manage_horizontal_scroll_test.dart`.
- 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/item_manage_horizontal_scroll_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze third_party/fortune_sheet/lib/src/fortune_table.dart lib/features/item/presentation/item_manage.dart lib/features/item/item_manager_debug_log.dart test/item_manage_horizontal_scroll_test.dart`.
- 관련 테스트 결과: `item_manage_horizontal_scroll_test.dart` **통과(3/3)**. Enter 편집 후 5초 지속 표시, 좌우 스크롤, zero-extent 차단 계약 및 실제 predicate 연결을 확인했다.
- 정적 분석 결과: **통과**, `No issues found` (4개 대상, 종료 코드 0).
- DTD 연결 결과: 실행 중인 Flutter 앱이 없어 hot reload 대상 없음.
- 공용 테이블 회귀 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/fortune_table_test.dart test/item_manage_horizontal_scroll_test.dart`.
- 공용 테이블 회귀 테스트 결과: **통과(79/79)**, 종료 코드 0.
- 변경 파일 diagnostics 및 `git diff --check` 통과. formatter에 의한 요청 범위 밖 변경 없음.
- 상태: **완료**. stage/commit 대상은 `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/features/item/presentation/item_manage.dart`, `lib/features/item/item_manager_debug_log.dart`, `test/item_manage_horizontal_scroll_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`다.
- 기능 커밋: `cc4ac5f7de106294b7980677fbe5a446d1624463` (`품목 편집 후 가로 스크롤 표시 유지`).
- 기존 사용자 dirty 파일은 수정·stage·commit에서 제외한다.

## 현재 작업: Windows CMake 경로 자동 인식
- **진행 중**: 다른 PC에서도 CMake Tools가 현재 프로젝트의 Windows 소스를 찾도록 `.vscode/settings.json`의 고정 로컬 경로를 워크스페이스 기준 경로로 변경한다.
- 원인 확인: `cmake.sourceDirectory`가 `C:/Workspace/ITSnG/label_manager/windows`로 고정되어 있었다. `build_windows.ps1`은 파일 경로에는 `$PSScriptRoot`를 사용했지만 버전 생성 명령의 작업 디렉터리는 호출 위치를 따랐다.
- `.vscode/settings.json` 편집 완료: `cmake.sourceDirectory`를 `${workspaceFolder}/windows`로 변경했다.
- `build_windows.ps1` 편집 완료: 버전 생성과 Flutter Windows 빌드를 `Push-Location $ScriptRoot` 범위에서 실행하고 `finally`에서 원래 위치를 복원한다.
- JSONC 및 VS Code 진단 오류 없음. PowerShell parser 구문 오류 0건.
- 빌드 경로 검증 완료: `$ScriptRoot` 계산, 빌드 전 프로젝트 루트 이동, `finally` 원위치 복원, 루트 기준 `flutter.ps1` 해석, 실패 종료 코드 보존을 확인했다.
- 고정 실행 경로 잔존 검색 결과: 설정·빌드 스크립트에는 없음. 테스트 fixture의 Windows 경로 정규화 입력 2건은 실제 빌드 경로가 아니므로 유지한다.
- `git diff --check` 통과. 실제 release 빌드/배포파일 생성은 요청 범위가 아니므로 수행하지 않았다.
- 상태: **완료**. 기존 사용자 dirty `lib/core/app.dart`는 제외했다.
- 기능 커밋: `980174a65a0b52dd22ad670c080509c20b5d82a6` (`Windows 빌드 경로 자동 인식 적용`).

## 현재 작업: 최근 수정 기능 진단 로그 보강
- **진행 중**: 최근 확인·수정·추가한 저장 ID 조회, 관리자 복사/거래처 검색, 품목정보 출력 동기화, 날짜 타입 저장 busy, 사용자 Enter 검색, 공용라벨 키워드 삽입의 다음 재현 분석에 필요한 상태 전이 로그를 추가한다.
- 원칙: 사용자 최신 요청에 따라 진단에 필요한 ID, 입력값, 검색어, 복사 명령 데이터 원문 기록을 허용한다. 로그 함수에는 비즈니스 로직을 포함하지 않는다.
- `lib/utils/regression_debug_log.dart` 추가: 공통 버전 `regression-debug-v1`과 `feature/event/fields` 형식만 담당하는 로그 전용 유틸리티다.
- 포맷 단위 테스트 추가: 버전·기능·이벤트·필드가 일관된 한 줄로 생성되는지 검증한다.
- `lib/features/login/presentation/startup_dialog.dart` 편집 완료: 저장 ID 복원 판단, 사용자 입력 세대, lookup 시작·적용·폐기·오류를 기록한다.
- `lib/widgets/modeless_dropdown_form_field.dart` 편집 완료: 선택적 `debugLabel`과 검색창 열기·검색 결과 수·선택값 로그를 추가했다.
- `lib/features/admin_copy/presentation/admin_copy_dialog.dart` 편집 완료: 원본/대상 거래처 선택과 전체 복사 명령, 완료·실패·commit 불명 결과를 기록한다.
- `lib/features/item/presentation/item_info_dialog.dart` 편집 완료: 품목정보 저장 시작, DB 완료, 메모리 반영, 실패, 최종 busy/dirty 상태를 기록한다.
- `lib/home_page_manager.dart` 편집 완료: 품목정보의 라벨출력 row 동기화 전후와 날짜 설정 저장의 busy 해제·탭 재생성 결과를 기록한다.
- `lib/features/managed_user/presentation/user_manager_dialog.dart` 편집 완료: Enter 검색 시작·일치/불일치와 post-frame 포커스 복원 결과를 기록한다.
- `lib/features/label_sheet/presentation/common_label_manage.dart` 편집 완료: 더블클릭 열·행·키워드·이름과 실제 삽입 성공 여부를 기록한다.
- focused test 결과: 공통 로그 1/1, 로그인 13/13, 공용 드롭다운 3/3, 관리자 복사 8/8, 품목정보·출력 동기화 24/24, 날짜 설정 10/10, 사용자 검색·공용라벨 26/26 통과.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.15`에서 `1.4.16`으로 갱신한다.
- Dart formatter 적용 완료: 변경된 Dart 소스 8개와 테스트 1개를 포맷했다.
- 관련 전체 테스트 결과: 10개 테스트 파일 **통과(85/85)**.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/utils/regression_debug_log.dart lib/features/login/presentation/startup_dialog.dart lib/widgets/modeless_dropdown_form_field.dart lib/features/admin_copy/presentation/admin_copy_dialog.dart lib/features/item/presentation/item_info_dialog.dart lib/home_page_manager.dart lib/features/managed_user/presentation/user_manager_dialog.dart lib/features/label_sheet/presentation/common_label_manage.dart test/regression_debug_log_test.dart`.
- 정적 분석 결과: **통과**, `No issues found` (9개 대상, 종료 코드 0).
- 변경 파일 VS Code 진단 오류 없음.
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. 기존 사용자 dirty `.vscode/settings.json`, `lib/core/app.dart`는 제외했다.
- 기능 커밋: `ffb38062d6afc6b3906261c610cd5b6050d7b049` (`최근 수정 기능 진단 로그 보강`).

## 현재 작업: 공용라벨 이름 열 키워드 삽입
- **진행 중**: 공용라벨관리의 `사용 항목` 표에서 키워드 열은 더블클릭으로 `#키워드`가 삽입되지만 이름 열은 삽입되지 않는 1.3.120 증상을 수정한다.
- 원인 확인: `_CommonLabelTable`의 `FortuneTableColumn.onDoubleTap`이 열 인덱스 `0`(키워드)에만 설정되고 인덱스 `1`(이름)은 null이다.
- 구현 방향: 키워드와 이름 열(`index < 2`)이 동일한 `LabelSheetKeywordInsertController.insertAtCurrentContext('#${row.keyword}')`를 호출하게 한다. 드래그 삽입은 요청 범위가 아니므로 기존 키워드 열에만 유지한다.
- 회귀 테스트 변경: 키워드·이름 열 모두 더블클릭 시 `#SWEIGHT`를 삽입하고, 이름 열 dragData는 계속 null인지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/common_label_manage_test.dart --plain-name "keyword and name columns insert keyword on double tap"`.
- 수정 전 테스트 결과: **실패(예상 일치)**. 이름 열의 `onDoubleTap`이 null이었다.
- `lib/features/label_sheet/presentation/common_label_manage.dart` 편집 완료: 키워드와 이름 열(`index < 2`)에 동일한 `#키워드` 더블클릭 삽입 콜백을 적용했다. 이름 열 드래그 동작은 추가하지 않았다.
- 수정 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/common_label_manage_test.dart --plain-name "keyword and name columns insert keyword on double tap"`.
- 수정 후 focused test 결과: **통과(1/1)**.
- Dart formatter 적용 완료: `common_label_manage.dart`, `common_label_manage_test.dart`.
- 공용라벨관리 전체 테스트 결과: `C:/Flutter/bin/flutter.bat test test/common_label_manage_test.dart` **통과(13/13)**.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.14`에서 `1.4.15`로 갱신했다.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/label_sheet/presentation/common_label_manage.dart test/common_label_manage_test.dart`.
- 정적 분석 결과: **통과**, `No issues found` (종료 코드 0). 변경 파일 VS Code 진단 오류 없음.
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. stage/commit 대상은 `lib/features/label_sheet/presentation/common_label_manage.dart`, `test/common_label_manage_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 커밋 전 `git diff --check`, 변경 파일 및 diff 검토 예정.
- 기능 커밋: `cb1ae938dfdb816eb26c60da265e5c6b1cf2632d` (`공용라벨 이름 열 키워드 삽입 추가`).

## 현재 작업: 사용자 관리 Enter 연속 검색
- **진행 중**: `파일/관리 > 사용자 관리`에서 이름 검색 후 Enter를 다시 눌러도 다음 사용자를 찾지 못하고 돋보기 버튼을 눌러야 하는 1.3.120 증상을 수정한다.
- 원인 가설: `_searchNext()`가 결과 행 선택과 시트 스크롤 후 검색 `TextField` 포커스를 복구하지 않아 다음 Enter가 검색 입력으로 전달되지 않는다.
- 구현 방향: 검색 필드 전용 `FocusNode`를 소유하고, 검색 결과 선택·스크롤이 반영된 다음 프레임에 검색 필드로 포커스를 명시적으로 복원한다. 검색어와 선택 범위는 유지한다.
- 회귀 테스트 추가: 같은 이름의 두 사용자에서 Enter를 두 번 연속 입력해 검색 필드 포커스 유지와 두 번째 사용자 선택을 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/user_manager_dialog_test.dart --plain-name "enter searches repeatedly and restores search field focus"`.
- 수정 전 테스트 결과: **실패(예상 일치)**. 첫 Enter 직후 검색 필드의 `focusNode.hasFocus`가 `false`로 바뀌었다.
- `lib/features/managed_user/presentation/user_manager_dialog.dart` 편집 완료: 검색 전용 `FocusNode`를 추가하고 결과 행 선택·스크롤 다음 프레임에 검색 필드 포커스와 검색어 끝 커서를 복원한다.
- 수정 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/user_manager_dialog_test.dart --plain-name "enter searches repeatedly and restores search field focus"`.
- 수정 후 focused test 결과: **통과(1/1)**. Enter 두 번으로 두 번째 일치 사용자까지 선택되고 검색 필드 포커스가 유지된다.
- Dart formatter 적용 완료: `user_manager_dialog.dart`, `user_manager_dialog_test.dart`.
- 사용자 관리 전체 테스트 결과: `C:/Flutter/bin/flutter.bat test test/user_manager_dialog_test.dart` **통과(13/13)**.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.13`에서 `1.4.14`로 갱신했다.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/managed_user/presentation/user_manager_dialog.dart test/user_manager_dialog_test.dart`.
- 정적 분석 결과: **통과**, `No issues found` (종료 코드 0). 변경 파일 VS Code 진단 오류 없음.
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. stage/commit 대상은 `lib/features/managed_user/presentation/user_manager_dialog.dart`, `test/user_manager_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 커밋 전 `git diff --check`, 변경 파일 및 diff 검토 예정.
- 기능 커밋: `bd90753cc49263c006578fb94934486933eece20` (`사용자 관리 Enter 연속 검색 수정`).

## 현재 작업: 관리자 복사 거래처 검색
- **진행 중**: `파일/관리 > 관리자 복사`의 긴 거래처 목록에서 원본·대상 거래처를 이름으로 검색할 수 있도록 개선한다.
- 권장안: 별도 검색 결과 화면 대신 거래처 드롭다운 메뉴 상단에 검색창을 제공하고, 입력 즉시 공백·대소문자를 무시한 이름 부분 일치로 목록을 필터링한다. 기존 협력업체→거래처→브랜드→라벨 크기 선택 흐름은 유지한다.
- 구현 방향: 공용 `ModelessDropdownFormField`에 선택적 검색 API를 추가하고 관리자 복사의 원본·대상 거래처 선택기에만 활성화한다.
- 회귀 테스트 추가: 공용 드롭다운에서 `대상` 검색 시 대상 거래처만 남고 선택되는지, 관리자 복사의 두 거래처 선택기에 검색 설정이 적용되는지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/modeless_dropdown_form_field_test.dart test/admin_copy_dialog_test.dart`.
- 수정 전 테스트 결과: **실패(예상 일치)**. `ModelessDropdownFormField`에 `searchTextForValue`, `searchHintText` API가 없어 두 테스트 파일이 컴파일 실패했다.
- `lib/widgets/modeless_dropdown_form_field.dart` 편집 완료: 선택적 검색창, 실시간 부분 일치 필터, 검색 결과 없음 상태를 추가했다. 검색을 사용하지 않는 기존 호출 동작은 유지한다.
- `lib/features/admin_copy/presentation/admin_copy_dialog.dart` 편집 완료: 원본·대상 거래처 선택기에 거래처명 검색을 활성화했다.
- 수정 후 focused tests 실행 예정: `C:/Flutter/bin/flutter.bat test test/modeless_dropdown_form_field_test.dart test/admin_copy_dialog_test.dart`.
- 수정 후 focused tests 결과: **통과(11/11)**.
- Dart formatter 적용 완료: `modeless_dropdown_form_field.dart`, `admin_copy_dialog.dart`, 두 관련 테스트 파일.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.12`에서 `1.4.13`으로 갱신했다.
- 포맷 후 관련 테스트 및 공용 드롭다운 사용처 회귀 테스트 실행 예정.
- 공용 드롭다운 사용처 회귀 테스트 결과: **통과(50/50)**. 관리자 복사와 기존 7개 사용 화면의 선택 동작에 회귀 없음.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/widgets/modeless_dropdown_form_field.dart lib/features/admin_copy/presentation/admin_copy_dialog.dart test/modeless_dropdown_form_field_test.dart test/admin_copy_dialog_test.dart`.
- 정적 분석 결과: **통과**, `No issues found` (종료 코드 0). 변경 파일 VS Code 진단 오류 없음.
- 관리자 복사 통합 테스트 보강: 원본 거래처에서 `대상` 검색→필터된 거래처 선택→해당 거래처의 `브랜드 2` 로드까지 검증한다.
- 보강 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/admin_copy_dialog_test.dart --plain-name "source and target customer selectors provide name search"`.
- 보강 후 focused test 결과: **통과(1/1)**.
- 최종 관련 테스트 결과: `modeless_dropdown_form_field_test.dart`, `admin_copy_dialog_test.dart` **통과(11/11)**.
- 최종 정적 분석 결과: **통과**, `No issues found` (종료 코드 0).
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. stage/commit 대상은 `lib/widgets/modeless_dropdown_form_field.dart`, `lib/features/admin_copy/presentation/admin_copy_dialog.dart`, `test/modeless_dropdown_form_field_test.dart`, `test/admin_copy_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 커밋 전 `git diff --check`, 변경 파일 및 diff 검토 예정.
- 기능 커밋: `04752e35a2ee0212da151637028a736e684bc257` (`관리자 복사 거래처 검색 추가`).

## 현재 작업: 날짜 타입 저장 후 무한 처리 중
- **진행 중**: `test / testflutter`의 날짜 타입 설정에서 제조시한을 `12:01`에서 `12시01분`으로 변경해 저장하면 품목관리 하단의 `처리 중`이 계속 표시되고 편집할 수 없는 1.3.120 증상을 수정한다.
- 로그 확인: `LabelSizeDAO.updateDateSetup`의 조회·UPDATE는 정상 완료됐고 `dateSetup updateCompleted`도 기록됐다. 이후 내부 상태 로그는 `busy=false`인데 화면에는 `처리 중`이 남는다.
- 원인 확인: 저장 성공 경로가 `_itemDraftCommandBusy == true`인 상태에서 `_resetTabs()`를 호출해 `_tabs`에 `ItemManage(commandBusy: true)`를 캐시한다. `finally`의 `setState(...false)`는 `_tabs`를 다시 만들지 않아 화면만 영구 busy 상태로 남는다.
- 구현 방향: 날짜 설정 저장 완료 시 `_itemDraftCommandBusy`를 먼저 해제한 다음 `_resetTabs()`로 탭 위젯을 재생성한다. 실패 시에는 기존처럼 busy만 해제한다.
- 회귀 테스트 추가: 날짜 설정 완료 함수가 busy를 먼저 `false`로 바꾼 뒤 탭 재생성 콜백을 호출하는 순서를 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/home_page_manager_session_test.dart --plain-name "date setup completion clears busy before rebuilding cached tabs"`.
- 수정 전 테스트 결과: **실패(예상 일치)**. `completeDateSetupCommand`가 없어 컴파일 실패했고 기존 저장 경로에는 올바른 완료 순서가 없음을 확인했다.
- `lib/home_page_manager.dart` 편집 완료: 날짜 설정 저장 성공 시 `completeDateSetupCommand`가 busy를 먼저 해제하고 `_resetTabs()`를 호출한다. 실패 경로는 busy만 해제한다.
- 수정 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/home_page_manager_session_test.dart --plain-name "date setup completion clears busy before rebuilding cached tabs"`.
- 수정 중 짧은 패치 문맥이 `_flushItemDraftEdits`에 성공 플래그를 잘못 삽입해 focused test가 컴파일 실패했다. 해당 변경을 즉시 제거하고 `_openDateTypeSetupDialog`에 정확히 배치했다.
- 수정 후 focused test 결과: **통과(1/1)**.
- Dart formatter 적용 완료: `lib/home_page_manager.dart`, `test/home_page_manager_session_test.dart`. 소스 diff는 의도한 `completeDateSetupCommand`와 `_openDateTypeSetupDialog`에만 한정됨을 확인했다.
- 관련 테스트 결과: `C:/Flutter/bin/flutter.bat test test/home_page_manager_session_test.dart test/date_type_setup_dialog_test.dart` **통과(10/10)**.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.11`에서 `1.4.12`로 갱신했다.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/home_page_manager.dart test/home_page_manager_session_test.dart test/date_type_setup_dialog_test.dart`.
- 정적 분석 결과: **통과**, `No issues found` (종료 코드 0).
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. stage/commit 대상은 `lib/home_page_manager.dart`, `test/home_page_manager_session_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 커밋 전 `git diff --check`, 변경 파일 및 diff 검토 예정.
- 기능 커밋: `fc802a1e2dc6c908b6fd2e5ce9761ed9d49a1d40` (`날짜 타입 저장 무한 로딩 수정`).

## 현재 작업: 품목별 정보 저장 후 라벨출력 즉시 반영
- **진행 중**: 발행 체크된 품목의 줄간격·기본 발행 수·개별 크기·여백을 `품목별 정보 편집`에서 저장해도 라벨출력 탭에 즉시 반영되지 않고, 발행 체크를 해제 후 재선택해야 반영되는 1.3.120 증상을 수정한다.
- 원인 확인: `_handleItemInfoCommitted`는 최신 `ItemOfMarket.datas`를 저장하고 `_syncLabelPrintRows()`를 호출하지만, `LabelPrintSessionController.syncCheckedItems()`는 이미 체크된 품목의 기존 `LabelPrintRowDraft` 전체를 재사용한다.
- 구현 방향: 동기화 때 최신 baseline row를 생성하고, `sessionEdited` 출처인 라벨출력 직접 수정값만 기존 값으로 유지한다. 품목 정보 및 fallback 출처 값은 최신 baseline으로 교체한다.
- 회귀 테스트 추가: 체크 상태를 유지한 품목의 발행 수·크기·여백·줄간격은 갱신되고, 라벨출력에서 직접 수정한 발행 수와 폭은 유지되는지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_print_session_test.dart --plain-name "checked row refreshes item info while preserving session edits"`.
- 수정 전 테스트 결과: **실패(예상 일치)**. 기존 row가 저장 전 `ItemOfMarket` 인스턴스를 계속 참조해 최신 품목별 설정이 반영되지 않음을 확인했다.
- `lib/features/label_print/domain/label_print.dart` 편집 완료: `LabelPrintRowDraft.preserveSessionEditsFrom`을 추가하고, `syncCheckedItems`가 최신 baseline row에 `sessionEdited` 필드만 병합하도록 변경했다.
- 수정 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_print_session_test.dart --plain-name "checked row refreshes item info while preserving session edits"`.
- 수정 후 focused test 결과: **통과(1/1)**.
- 후속 정리: `syncCheckedItems`가 품목당 baseline row를 한 번만 생성하도록 지역 함수로 정리했다.
- 전체 라벨출력 세션 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_print_session_test.dart`.
- 전체 라벨출력 세션 테스트 결과: **통과(24/24)**.
- VS Code 진단 결과: 변경한 `label_print.dart`, `label_print_session_test.dart` 오류 없음.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.10`에서 `1.4.11`로 갱신했다.
- 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/item_info_batch_test.dart test/item_info_dialog_test.dart test/label_print_session_test.dart`.
- 관련 테스트 결과: **통과(29/29)** (Flutter 명령 직접 실행, 종료 코드 0).
- Dart formatter 적용 완료: `lib/features/label_print/domain/label_print.dart`, `test/label_print_session_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/label_print/domain/label_print.dart test/label_print_session_test.dart lib/home_page_manager.dart lib/features/item/presentation/item_info_dialog.dart`.
- 정적 분석 결과: **통과**, `No issues found` (종료 코드 0).
- DTD 연결 앱 조회 및 hot reload 실행 예정.
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. stage/commit 대상은 `lib/features/label_print/domain/label_print.dart`, `test/label_print_session_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 커밋 전 `git diff --check`, 변경 파일 및 diff 검토 예정.
- 기능 커밋: `04c6ffdea668e4f5205037f0a5cf80e28c4e115c` (`품목별 정보 출력 즉시 반영`).

## 현재 작업: 저장 아이디의 사용자 입력 덮어쓰기
- **진행 중**: 로그인 창에서 저장 ID `3575` 대신 `TESTER1`을 입력한 뒤 비밀번호를 클릭하면 다시 `3575`로 강제 전환되는 1.3.120 증상을 수정한다.
- 로그 확인: `TESTER1` 공지/사용자 조회가 성공한 직후 약 0.16초 내 저장 ID `3575` 공지/사용자 조회가 다시 시작된다.
- 원인 확인: 사용자 조회 결과로 공지 패널이 닫힐 때 `_LoginPanel`이 `Row > Expanded` 아래에서 다이얼로그 루트로 이동하며 State가 재생성되고, `initState`의 `_loadPreferences()`가 저장 ID를 다시 주입한다.
- 구현 방향: `_DialogBodyState`가 소유한 안정적인 `GlobalKey<_LoginPanelState>`를 `_LoginPanel`에 부여해 공지 레이아웃 전환에도 동일 State를 재사용한다.
- 회귀 테스트 추가: 저장 ID `3575`에서 `TESTER1` 입력 후 비밀번호 포커스로 공지 패널이 닫혀도 입력 ID와 조회 순서가 유지되는지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/startup_dialog_test.dart --plain-name "saved id does not replace edited id when notice closes"`.
- 수정 전 회귀 재현 완료: 기대 ID `TESTER1` 대신 실제 ID `3575`로 실패했다(종료 코드 1).
- [`lib/features/login/presentation/startup_dialog.dart`](lib/features/login/presentation/startup_dialog.dart) 편집 완료: `_DialogBodyState`가 소유한 `GlobalKey<_LoginPanelState>`를 `_LoginPanel`에 적용해 공지 표시 전환 시 로그인 State를 보존한다.
- focused 회귀 테스트 통과: 입력 ID가 `TESTER1`로 유지되고 `TESTER1` 조회 이후 저장 ID `3575` 재조회가 발생하지 않는다.
- 버전은 로그인 입력 보존 버그 수정이므로 PATCH 단계로 `1.4.8`에서 `1.4.9`로 갱신했다.
- Dart 포맷 완료: `startup_dialog.dart`, `startup_dialog_test.dart`. 포맷 후 focused 회귀 재검증 **1/1 통과**.
- 전체 관련 검증 통과: `C:/Flutter/bin/flutter.bat test test/startup_dialog_test.dart` (**12/12**, 종료 코드 0).
- 정적 분석 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/login/presentation/startup_dialog.dart test/startup_dialog_test.dart`.
- 정적 분석 통과: `No issues found` (종료 코드 0). 변경 파일 VS Code 진단 오류 없음.
- DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- 상태: **완료**. stage/commit 대상은 `startup_dialog.dart`, `startup_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 최종 보강: 늦게 완료된 `3575` 조회가 사용자 이름 등 조회 결과를 덮지 않고 `name:TESTER1`이 유지되는지 검증한다.
- 보강 후 최종 검증 통과: `startup_dialog_test.dart` **13/13**, focused analyze 오류·경고 0.
- 기능 커밋: `9873e6275600136bc1552dd508426bb8e2753fdd` (`저장 아이디 조회 경합 수정`).
- 최종 보강: 아이디/비밀번호 필드에 안정적인 테스트 key를 추가하고, `TESTER1` 조회 이후 `3575`가 다시 조회되지 않는 조건을 명시적으로 검증한다.
- 보강 후 최종 검증 통과: `startup_dialog_test.dart` **12/12**, focused analyze 오류·경고 0.
- 기능 커밋: `361b4ac8690f94dbfc5871ee49562d958fae901a` (`저장 아이디 입력 덮어쓰기 수정`).

## 현재 작업: 공지 숨김 상태의 저장 아이디 조회 경합
- **진행 중**: 저장 ID `3575`에서 `다음 업데이트까지 이 창 보지 않음`을 저장한 뒤 재로그인하여 `TESTER1`을 입력하면 `3575`로 돌아가는 추가 재현을 처리한다.
- 원인 가설: 저장 ID의 공지 조회가 진행 중일 때 `_LoginPanel._noticeFetchInFlight`가 새 `TESTER1` 조회를 즉시 버리고, 늦게 완료된 `3575` 결과가 현재 로그인 정보로 적용된다.
- 구현 방향: 사용자 ID 입력 변경 시 이전 조회를 무효화하고, 서로 다른 최신 ID 조회는 실행하되 현재 입력과 요청 세대가 일치하는 결과만 적용한다. 비동기 preference 로딩도 사용자가 입력을 시작한 뒤에는 ID를 덮어쓰지 않게 한다.
- 회귀 테스트 추가: 저장 ID `3575` 공지 조회를 지연시킨 상태에서 `TESTER1`로 이동해도 새 조회가 실행되고 입력 ID가 유지되는지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/startup_dialog_test.dart --plain-name "edited id supersedes saved id lookup in flight"`.
- 수정 전 회귀 재현 완료: 기대 조회 `3575 → TESTER1` 대신 `3575`만 실행되어 실패했다(종료 코드 1).
- [`lib/features/login/presentation/startup_dialog.dart`](lib/features/login/presentation/startup_dialog.dart) 편집 완료: 전역 조회 잠금을 제거하고 ID 입력마다 이전 요청을 무효화한다. 현재 입력 및 최신 요청 세대와 일치하는 조회 결과만 적용하며, 사용자가 편집을 시작한 뒤 완료된 preference 로딩은 저장 ID를 주입하지 않는다.
- 수정 후 focused 회귀 테스트 통과: **1/1**.
- 버전은 저장 ID 비동기 경합 수정이므로 PATCH 단계로 `1.4.9`에서 `1.4.10`으로 갱신했다.
- Dart 포맷 완료: `startup_dialog.dart`, `startup_dialog_test.dart`.
- 전체 관련 검증 통과: `C:/Flutter/bin/flutter.bat test test/startup_dialog_test.dart` (**13/13**, 종료 코드 0).
- 정적 분석 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/login/presentation/startup_dialog.dart test/startup_dialog_test.dart`.
- 정적 분석 통과: `No issues found` (종료 코드 0). 변경 파일 VS Code 진단 오류 없음.
- DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- 상태: **완료**. stage/commit 대상은 `startup_dialog.dart`, `startup_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.

## 현재 작업: 관리자 복사 품목 포함 SQL 512 오류
- **진행 중**: 관리자 복사에서 원본 라벨 `677`을 대상 라벨 `8156`으로 `품목까지 복사`하면 SQL Server 오류 512(스칼라 하위 쿼리 복수행)가 발생하는 1.3.106 로그 증상을 수정한다.
- 로그 확인: `copyItems=1`, `targetFirstMarketId=1`로 실행된 트랜잭션이 `proc_copy_item`과 `proc_copy_item_content`를 포함한 품목 복사 구간에서 실패하고 전체 롤백됐다. 앱이 직접 작성한 품목-지점 INSERT의 하위 쿼리는 이미 `TOP 1`이라 오류 512 대상이 아니다.
- 원인 가설: 구 DB 저장 프로시저 내부가 품목 순번 또는 컬럼 대응을 스칼라 하위 쿼리로 가정해 복수 매칭 데이터에서 실패한다. 프로시저 정의는 저장소에 없으므로 DB 마이그레이션 없이 앱 SQL에서 의존을 제거한다.
- 구현 방향: 원본 품목을 한 건씩 삽입하며 원본→대상 품목 ID를 캡처하고, 원본→대상 컬럼도 정렬 순번으로 1:1 매핑한다. 열 내용은 집합 기반 `UPDATE ... JOIN`과 누락 행 INSERT로 복사하고, 품목-지점 정보는 품목 ID 매핑을 사용한다. `STRING_AGG` 등 compatibility 100 비지원 문법은 사용하지 않는다.
- 수정 예정 파일: `lib/features/admin_copy/data/admin_copy_dao.dart`, `test/admin_copy_dao_test.dart`, `pubspec.yaml`.
- 회귀 테스트 추가: 두 복사 SQL이 구 품목 복사 프로시저를 호출하지 않고 `@ItemMap`/`@ColumnMap`, `ROW_NUMBER`, 집합 기반 내용 UPDATE를 사용하는 계약을 고정한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/admin_copy_dao_test.dart --plain-name "item copy uses explicit item and column mappings"`.
- 수정 전 회귀 재현 완료: 프로시저 대신 품목 ID 캡처를 요구하는 첫 기대값이 실패했다(종료 코드 1).
- [`lib/features/admin_copy/data/admin_copy_dao.dart`](lib/features/admin_copy/data/admin_copy_dao.dart) 편집 완료: `proc_copy_item`/`proc_copy_item_content`를 제거하고, 원본→대상 품목 ID와 컬럼 ID를 명시적으로 매핑한다. 열 내용은 `UPDATE ... JOIN` 후 누락 행만 INSERT하며 품목-지점 연결도 품목 ID 맵을 사용한다.
- 수정 후 focused 회귀 테스트 통과: **1/1**.
- 버전은 관리자 복사 DB 오류 수정이므로 PATCH 단계로 `1.4.7`에서 `1.4.8`로 갱신했다.
- Dart 포맷 완료: `admin_copy_dao.dart`, `admin_copy_dao_test.dart`.
- 포맷 후 focused 회귀 재검증 통과: **1/1**. 변경 파일 VS Code 진단 오류 없음.
- 전체 관련 검증 통과: `C:/Flutter/bin/flutter.bat test test/admin_copy_dao_test.dart test/admin_copy_dialog_test.dart` (**12/12**, 종료 코드 0).
- 정적 분석 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/admin_copy/data/admin_copy_dao.dart test/admin_copy_dao_test.dart`.
- 긴 열 내용 보존: 복사 임시 테이블의 `RICH_COL_CONTENT_DATA`를 `NVARCHAR(MAX)`로 유지하고 회귀 테스트에 고정했다.
- 최종 검증 완료: 관련 테스트 **12/12 통과**, focused analyze **No issues found**, 변경 파일 진단 오류 없음.
- DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다. 운영 DB 데이터 변경 재현은 사용자 승인 없이 수행하지 않아 미검증이다.
- 상태: **완료**. stage/commit 대상은 `admin_copy_dao.dart`, `admin_copy_dao_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 기능 커밋: `9f26f98f3260cf4213c19b93ce60351e541c5fb5` (`관리자 품목 포함 복사 오류 수정`).

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
- 기능 커밋: `2868028` (`고정 항목 사용자 정의 입력 비활성화`).

## 현재 작업: GS1 AI 코드 표시 및 설정 ComboBox
- **완료**: GS1 AI 항목에서 `GS1 code 표시`를 저장해도 품목 출력 미리보기에 AI 코드가 나타나지 않는 1.3.120 증상을 수정하고, AI code와 Format option을 ComboBox로 제공했다.
- 원인 확인: 현재 `itemCodeTokenColumnValue`는 GS1 AI의 `showGs1Code`를 적용하지 않고 원본 값만 반환한다. 레거시는 `(<AI code>)<값>` 형식으로 치환한다.
- 구현 예정: GS1 AI 출력 토큰을 레거시 형식으로 만들고, `Gs1AiDefinitions`의 DB 정의를 AI code ComboBox로 사용한다. `dataFormatType == 2`인 AI만 소수점 `0~9` Format option을 활성화하고 나머지는 `해당 없음(-1)`으로 유지한다.
- 수정 예정 파일: `lib/features/label_print/domain/item_code_data_resolver.dart`, `lib/features/label_column/presentation/label_column_edit_dialog.dart`, 관련 테스트, `pubspec.yaml`.
- [`lib/features/label_print/domain/item_code_data_resolver.dart`](lib/features/label_print/domain/item_code_data_resolver.dart) 편집 완료: GS1 AI의 `showGs1Code`가 켜지면 출력 토큰을 레거시와 같은 `(<AI code>)<값>` 형식으로 반환한다.
- [`lib/features/label_column/presentation/label_column_edit_dialog.dart`](lib/features/label_column/presentation/label_column_edit_dialog.dart) 편집 완료: AI code를 DB 정의 기반 ComboBox로 제공하고, 소수점형 AI는 `0~9`, 일반 AI는 `해당 없음(-1)` Format option ComboBox를 제공한다.
- [`test/item_code_data_resolver_test.dart`](test/item_code_data_resolver_test.dart) 테스트 추가: 표시 해제 시 원본 값, 표시 설정 시 `(01)12341234123412` 출력을 검증한다.
- [`test/label_column_edit_dialog_test.dart`](test/label_column_edit_dialog_test.dart) 테스트 추가: 일반 AI의 Format option 비활성화와 소수점형 AI 선택 후 `0~9` 옵션 활성화를 검증한다.
- 버전은 GS1 AI 출력/UI 버그 수정이므로 PATCH 단계로 `1.4.5`에서 `1.4.6`으로 갱신했다.
- focused 검증 완료: GS1 AI 표시 형식 **1/1**, AI/Format ComboBox 선택 및 `gs1ai=3102`, `formatOption=2` 저장 명령 전달 **1/1** 통과.
- 최종 검증 완료: `test/item_code_data_resolver_test.dart`, `test/label_column_edit_dialog_test.dart` **37/37 통과**, focused analyze **No issues found**.
- formatter, diagnostics, `git diff --check` 통과. DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- stage/commit 대상: `lib/features/label_print/domain/item_code_data_resolver.dart`, `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/item_code_data_resolver_test.dart`, `test/label_column_edit_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `7dc391d` (`GS1 AI 코드 표시와 설정 선택 개선`).

## 현재 작업: GS1바코드 포함 키워드 표시 복원
- **진행 중**: `포함 GS1 AI 키워드`에 `#GS1AI`를 저장한 뒤 재진입하면 관계 테이블의 내부 ID `140792|`가 노출되는 1.3.120 증상을 수정한다.
- 원인 확인: DB 조회의 `containColumns`는 관계 저장용 column ID 목록이며 라벨 항목 편집 폼이 이를 그대로 표시한다. 저장 SQL은 `#키워드`와 숫자 ID를 모두 관계 ID로 해석한다.
- 구현 방향: 저장·출력 모델의 ID 목록은 유지하고, GS1바코드 속성 폼의 표시값만 현재 사용 항목을 기준으로 ID→`#키워드`로 변환한다. 단순 조회 시 dirty 상태는 만들지 않는다.
- 수정 예정 파일: `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/label_column_edit_dialog_test.dart`, `pubspec.yaml`.
- 편집 완료: `_gs1ContainKeywords`가 기존 관계 ID를 `#키워드`로 표시하고 `_normalizeGs1ContainColumns`가 속성 적용 시 키워드를 관계 ID로 복원한다. 알 수 없는 키워드는 `입력 확인`으로 적용을 차단한다.
- 테스트 추가: column ID `140792`를 포함한 GS1바코드가 `#GS1AI`로 표시되고 저장 명령에서는 `140792|`를 유지하는 위젯 회귀 테스트를 추가했다.
- 단일 회귀 검증 통과: `C:/Flutter/bin/flutter.bat test test/label_column_edit_dialog_test.dart --plain-name "GS1 barcode shows contain column IDs as keywords"` (종료 코드 0).
- 버전 갱신: `pubspec.yaml`의 앱 버전을 `1.4.6`에서 `1.4.7`로 올렸다.
- Dart 포맷 완료: `label_column_edit_dialog.dart`, `label_column_edit_dialog_test.dart`.
- 포맷 후 단일 회귀 재검증 통과: 1/1.
- 전체 관련 검증 통과: `C:/Flutter/bin/flutter.bat test test/label_column_edit_dialog_test.dart` (28/28, 종료 코드 0).
- 정적 분석 통과: `C:/Flutter/bin/flutter.bat analyze lib/features/label_column/presentation/label_column_edit_dialog.dart test/label_column_edit_dialog_test.dart` (`No issues found`, 종료 코드 0).
- VS Code 진단: 변경한 Dart 파일과 `pubspec.yaml` 모두 오류 없음.
- DTD 연결 확인: 실행 중인 Flutter 앱이 없어 hot reload는 수행하지 못했다.
- 상태: **완료**. stage/commit 대상은 `label_column_edit_dialog.dart`, `label_column_edit_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 사용자 dirty 파일은 제외한다.
- 기능 커밋: `551511ec219531e79c8871bd30e875ec81e5df31` (`GS1 바코드 포함 키워드 표시 복원`).

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