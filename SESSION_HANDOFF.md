# 세션 인수인계

마지막 업데이트: 2026-07-04

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
- 라벨 시트 저장 포맷을 수정할 때는 `lib/page_label_sheet/label_sheet_save_codec.dart`의 `_labelSheetSaveFeatureKeys`에 항목별 feature key를 추가/정렬해 `labelSheetSaveFormatVersion`과 `labelSheetSaveFeatureVersions`가 자동 산출되도록 유지한다. 새로 지원하는 workbook/sheet/config/cell/cellType/inlineRun JSON 필드는 같은 파일의 allow-list 및 `labelSheetSanitizeWorkbookSaveJson` 경로에 반드시 반영한다. 구/외부 포맷 호환은 `labelSheetMigrateWorkbookSaveJson`과 `labelSheetNormalizeWorkbookForCurrentSaveFormat`에 함께 반영하고, `.lms` 초기 로드/라벨 파일에서 불러오기/`.xlsx` import가 모두 현재 포맷으로 처리되는 테스트를 갱신한다.
- Godex G500 같은 라벨 프린터에서 정밀한 인쇄가 핵심이면 일반 프린터 경로와 직접 출력 경로를 분리한다. 직접 출력은 처음부터 모든 스타일을 100% EZPL 명령만으로 처리하기보다 `정밀 좌표 엔진 + EZPL 명령 + 셀 bitmap fallback` 구조를 우선한다. 테두리/선/박스와 바코드는 가능한 한 EZPL 명령으로 출력하고, 화면 폰트와 프린터 폰트 차이로 1:1 보장이 어려운 복합 스타일 텍스트/이미지/배경/RTF 계열 셀은 셀 단위 bitmap fallback을 사용해 시각적 일치도를 확보한다.

## 현재 상태

### 진행 중 (2026-07-04): FortuneSheet canvas 전체 테스트 실패 묶음 정리

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
- 다음 작업: 다음 첫 실패 `bare active editor syncs text input after select all delete` 계열부터 계속 정리.
- 미검증/진행 중: 전체 canvas clean까지 추가 정리 필요. 기존 unrelated dirty `lib/core/app.dart` 제외.
- 커밋 완료: `9d9bde7` (`FortuneSheet canvas focused 실패 일부 정리`).

### 진행 중 (2026-07-04): FortuneSheet active editor 삭제 키 처리 정리

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
- 미검증/진행 중: 전체 canvas clean까지 추가 정리 필요. 기존 unrelated dirty `lib/core/app.dart` 제외.

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

### 진행 중 (2026-07-03): XLSX → 라벨 시트 변환 규칙 재정립 (1차 구현 완료, 재가져오기 검증 대기)

목적: `.xlsx` 엑셀을 라벨 시트로 가져오기. 원본과 최대한 100% 동일하게 변환.
규칙 전문은 세션 메모리 `/memories/session/xlsx-import-rules.md` 및 코드 상단 주석(`lib/page_label_sheet/label_sheet_xlsx_import.dart` 파일 헤더)에 명시. 완료 시까지 유지.

- **A. 테두리**: 엑셀 셀 테두리 속성(방향/스타일·두께/색)을 그대로 1:1 변환. 임의 변형(다운캐스트·합성·특수처리) 금지. 엑셀에 없으면 변환본에도 없음. ("세 표 외에는 테두리 없음"은 규칙 아님 — 사용자가 제외. 엑셀에 있으면 어느 영역이든 그대로.)
- **B. 일반화**: 특정 파일 전용 하드코딩 금지(`'영양정보'` 텍스트/고정 크기/특정 좌표). 순수 border 매핑만.
- **C. 스케일**: 물리 라벨 폭 우선 스케일(폭 대비 높이 비율). 가독 미달 시 최소 가독 문자 기준 재확대(인쇄영역 초과 허용). 가독 기준은 실물 프린트 mm.
- **D. 폰트/텍스트**: 글꼴/크기/굵게·기울임·밑줄·취소선/글자색 + 자간/장평/첨자/줄간격을 엑셀 그대로. 크기만 C 스케일 비례.

1차 구현 완료 (미검증, 사용자 재가져오기 후 확인 필요):
- `lib/page_label_sheet/label_sheet_xlsx_import.dart`:
  - 파일 헤더에 변환 규칙 A~D 주석 명시(추후 수정 방향 고정).
  - 영양정보 전용 보정 전부 제거: `_adjustXlsxImportedBorder`(다운캐스트), `_missingNutritionOuterBorders`(합성), `_isXlsxNutritionHeader`/`_isXlsxNutritionOuterBorder`/`_isXlsxNutritionInnerBorder`/`_nutritionRangeFromHeaderMerge`, `#BARCODE`/안내문/빈셀 skip(`_shouldSkipXlsxCellBorders`/`_shouldImportXlsxCellBorders`), `_isInsideXlsxMergeRange`, `_mergeRangeFromJson`, `_isSameXlsxBorderLog`, 관련 sample 로그/변수(`nutritionBorderRanges`·`borderlessMergeRanges`·`mergeRanges`·`adjustedBorderSamples`·`skipped*BorderSamples`).
  - 테두리 변환은 이제 `style.borderInfo()`(엑셀 styles.xml border 1:1 매핑, `_borderStyle`/`_borderStrokeWidth`)를 셀별로 그대로 emit. 값/채움 없는 border-only 빈 셀도 `cellJson.isEmpty` skip 이전에 border를 유지.
- `lib/page_label_sheet/label_sheet_workbench.dart`: `_labelSheetScaledToPhysicalWidth`에 규칙 C 참조 주석 추가. 스케일 로직(widthScale 우선 + `max(widthScale, readableScale)` 재확대 + mm 기준 최소 가독)이 규칙 5·6·7과 일치함 확인, 코드 변경 없음.
- 폰트/자간/장평/첨자/줄간격 import는 `_XlsxFont`+inline runs+customXml metadata에서 이미 충실 파싱됨 확인, 변경 없음.
- `test/label_sheet_xlsx_import_test.dart`: 충실 변환 기준으로 테두리 기대값 갱신(borderId 있는 셀은 값/종류 무관 테두리 유지, borderId=0은 없음). `*유통기한:`/`#BARCODE`/빈셀도 엑셀 border가 있으면 유지.
- 검증: `flutter test test/label_sheet_xlsx_import_test.dart` 3개 성공, `flutter analyze`(3파일) No issues.

다음 작업 (재가져오기 후):
- **근본 원인 확정 + 수정 + 검증 완료**: 원본 `.tmp/label_sample2_converted.xlsx` styles.xml 직접 확인.
  - `<x:borders count="62">`인데 맨 앞 self-closing `<x:border /><x:border />` 2개(무테두리)를 파서가 **여는 태그로 오인해 삼켜** 60개만 파싱 → 모든 borderId 2씩 밀림. 예: A14는 borderId 33(=회색 왼쪽선)이어야 하는데 index 35의 4면 검정 테두리를 잘못 참조.
  - 수정: `_elementBodies` 정규식을 self-closing(`<tag/>`) 대안 먼저 매칭. borders/fonts/fills 정렬 교정.
  - 검증: 재가져오기 로그 `app_2026-07-03_15-03-43.log`에서 border수 **2365→792**, A14=회색 왼쪽선만, L19/N20/L30 무테두리/회색만, 표(A5/A7/A9)는 굵은 외곽선 유지 확인. 변환본이 엑셀과 시각적으로 일치.
- 진단 로그(border defs/format 덤프, sample 3000) 제거, sample 한도 200 복원, xfId 진단 필드 제거. applyBorder 처리는 유지.
- 검증: `flutter test` 4개 성공, `flutter analyze` No issues.
- 스케일 확인 완료(로그 `app_2026-07-03_15-11-05.log`): 규칙 C대로 `widthScale=0.232` vs `readableScale=0.644` 중 readable 채택, overflow 168mm. 사용자 결정 = **이대로 유지**(규칙 C6: 가독 우선, 인쇄영역 초과 허용). 코드 변경 없음.
- 결론: XLSX→라벨시트 변환(테두리 1:1, 폰트/자간/장평/첨자/줄간격 그대로, 스케일 C) 규칙대로 구현·검증 완료.

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
