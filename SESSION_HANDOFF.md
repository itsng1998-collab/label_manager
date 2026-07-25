## 다음 세션 시작 문구
- SESSION_RULES.md와 SESSION_HANDOFF.md를 확인해 이전 세션 작업을 이어서 진행해줘
- SESSION_RULES.md와 SESSION_HANDOFF.md를 확인해 이전 세션 작업을 이어서 진행하게 대기해줘

## 상시 규칙
- 상시 규칙은 [SESSION_RULES.md](SESSION_RULES.md)를 기준으로 따른다.
- 이 파일에는 현재 상태, 최근 완료 항목, 검증, 다음 액션만 기록한다.

## 현재 상태
- 완료: 앱 시작 locale/날짜 표시를 OS 설정에 맞추고 공용라벨관리 우측 패널의 초기·최소 폭과 컬럼 리사이징 계약을 수정했다.
- locale 정책: 앱 시작 시 OS locale로 `Intl.defaultLocale`/날짜 심볼을 초기화하고 Flutter Material/Cupertino localization을 활성화한다. 화면 표시 날짜는 locale skeleton을 사용하고 DB·로그 저장 문자열 형식은 유지한다.
- 공용라벨관리 정책: 기존 테이블 기본 합계 360에서 10을 뺀 `350.0`을 우측 패널 초기·최소 폭 상수로 사용하며, 실제 테이블 viewport에서 행번호 40과 필수등록 70을 고정하고 키워드/이름에 나머지 폭을 균등 배분한다.
- 수정 예정: [lib/main.dart](lib/main.dart), locale 초기화 helper, [lib/page_login/login_history_page.dart](lib/page_login/login_history_page.dart), [lib/page_home/common_label_manage.dart](lib/page_home/common_label_manage.dart), 관련 테스트와 [pubspec.yaml](pubspec.yaml).
- 편집 완료: `lib/core/locale_config.dart`의 `initializeLabelManagerLocale`가 OS locale을 `Intl.defaultLocale`과 날짜 심볼에 적용하며, `lib/main.dart`는 Material/Cupertino localization delegate와 지원 locale을 활성화한다. `lib/page_login/login_history_page.dart`의 표시 포맷은 `DateFormat.yMd()`/`DateFormat.jms()`로 변경했다.
- 편집 완료: `lib/page_home/common_label_manage.dart`에 우측 패널 초기·최소 폭 350, 행번호 40, 필수등록 70 상수를 추가했다. `commonLabelColumnWidthsForViewport`가 패널 리사이징마다 나머지 폭을 키워드/이름에 균등 배분하고 필수등록 폭을 고정한다.
- 테스트 추가: `test/locale_config_test.dart`에서 `en_US`/`ko_KR` 기본 locale 및 날짜 형식을 검증하고, `test/common_label_manage_test.dart`에서 350px 초기·최소 폭과 키워드/이름 균등 배분·필수등록 70px 고정을 검증한다.
- 검증 완료: `flutter pub get` 성공. 수정 Dart 파일 전체 정적 진단 오류 없음. `locale_config_test.dart`와 `common_label_manage_test.dart` 관련 테스트 통과.
- 커밋 대상: `SESSION_HANDOFF.md`, `lib/main.dart`, `lib/core/locale_config.dart`, `lib/page_login/login_history_page.dart`, `lib/page_home/common_label_manage.dart`, `pubspec.yaml`, `pubspec.lock`, 관련 테스트. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `2ca11e6` (`OS 로케일과 공용라벨 패널 리사이징 적용`). 원격 push 및 배포 빌드는 수행하지 않았다.
- 완료: 바코드 삽입 다이얼로그와 개체 패널 속성의 값 입력에 형식별 지원 문자 제한을 공통 적용하고 검증했다. 기능 커밋 `916ae00` 완료.
- 정책: EAN/UPC/ITF는 숫자, Codabar는 ZXing alphabet/guard 문자, Code39/Code93/Code128은 extended ASCII만 입력받고, 길이·체크디지트는 입력 중간 상태를 막지 않는다. 형식 변경 시 현재 값도 같은 규칙으로 정리한다.
- [third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart](third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart): `fortuneFilterBarcodeInput`/`FortuneBarcodeInputFormatter`를 추가하고 삽입 값 입력 및 형식 변경에 적용했다.
- [third_party/fortune_sheet/lib/src/fortune_object_layer_panel.dart](third_party/fortune_sheet/lib/src/fortune_object_layer_panel.dart): 바코드 데이터 필드에 공용 formatter를 적용하고 형식 변경 시 기존 값을 즉시 정리한다.
- [third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart](third_party/fortune_sheet/test/fortune_barcode_dialog_test.dart), [third_party/fortune_sheet/test/fortune_object_controller_test.dart](third_party/fortune_sheet/test/fortune_object_controller_test.dart): EAN-13 비지원 문자 차단, ZXing writer별 문자 규칙, 속성 패널 입력/형식 변경 테스트를 추가했다.
- 검증: 집중 테스트 5개, 바코드 다이얼로그 전체 33개, 개체 컨트롤 전체 49개, 라벨 시트 툴바 전체 147개 통과. 수정 Dart 파일 diagnostics 오류 없음.
- 완료: 바코드 객체 표시 깨짐, 좁은 개체 패널의 바코드 연결 ID overflow, 패널 리사이즈 시 툴바 `더 보기` 미노출을 수정하고 검증했다. 기능 커밋 `c3877af` 완료.
- 원인: 바코드 PNG까지 일반 이미지와 동일한 `FilterQuality.medium`으로 확대해 비정수 줌에서 모듈 경계가 보간되고, 연결 ID 드롭다운이 `isExpanded` 없이 선택 항목의 본래 폭을 요구하며, 최신 수동 커밋 `75bf1b8`에서 `_labelSheetZoomToolbarRightInset`과 `toolbarRightInset` 전달이 삭제됐다.
- [third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart](third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart): 바코드 객체 bitmap만 `FilterQuality.none`/antiAlias 비활성으로 그리고 일반 이미지는 기존 medium 필터를 유지한다.
- [third_party/fortune_sheet/lib/src/fortune_object_layer_panel.dart](third_party/fortune_sheet/lib/src/fortune_object_layer_panel.dart): 연결 ID 드롭다운에 `isExpanded: true`를 적용해 160px 패널에서도 선택 항목을 가용 폭 안에 제한한다.
- [lib/page_label_sheet/label_sheet_workbench.dart](lib/page_label_sheet/label_sheet_workbench.dart): 최신 수동 커밋에서 삭제된 124px 줌 툴바 우측 예약 전달을 복원했다.
- [third_party/fortune_sheet/test/fortune_object_controller_test.dart](third_party/fortune_sheet/test/fortune_object_controller_test.dart), [test/label_sheet_toolbar_test.dart](test/label_sheet_toolbar_test.dart): 바코드 필터, 좁은 속성 패널, 패널 리사이징 후 더보기 동작 회귀 테스트를 추가/보강했다.
- 검증: FortuneSheet 개체 컨트롤 전체 48개, 라벨 시트 툴바 전체 147개 통과. 포맷 후 패널 폭/리사이징/더보기 집중 테스트 3개 재통과, 수정 Dart 파일 diagnostics 오류 없음.
- 완료: 라벨 시트 도킹 개체 패널의 최소 폭과 초기 폭을 상단 상수 `_labelSheetObjectPanelMinWidth`, `_labelSheetObjectPanelInitialWidth`로 정의해 모두 `150.0`으로 통일했다. 기능 커밋 `2f68cdc` 완료.
- [lib/page_label_sheet/label_sheet_workbench.dart](lib/page_label_sheet/label_sheet_workbench.dart): 초기 상태, 저장 폭 복원, 도킹 폭 계산, 드래그 최소 폭, 더블클릭 초기화를 두 상수 기준으로 변경했다.
- [test/label_sheet_toolbar_test.dart](test/label_sheet_toolbar_test.dart): 기존 폭 저장 테스트가 초기 폭 150, 드래그 최소 폭 150, 확대 폭 저장, 더블클릭 초기화 150을 검증하도록 보강했다.
- 검증: 포맷 후 개체 패널 폭 집중 테스트 1개 통과, 수정 Dart 파일 2개 diagnostics 오류 없음. 전체 147개 중 145개 통과, 더보기 관련 2개는 범위 밖 사용자 변경인 `toolbarRightInset` 제거로 `More` 클릭이 줌 툴바에 차단되어 실패했다. 해당 사용자 변경은 unstaged로 유지한다.
- 완료: 라벨 시트 툴바 `더 보기`에서 바코드/선/도형/개체 명령을 원래 툴바 동작으로 연결하고, 더보기에서 연 모든 2차 popup을 시트 우상단에 배치하며 체크 열과 병합 메뉴 아이콘 정렬을 보완했다. 검증 및 기능 커밋 `188b834` 완료.
- 원인: more popup 항목 클릭이 원래 툴바 버튼 문맥을 잃은 채 `_activateToolbarPopupCommand`로 전달되고, 2차 popup은 화면에서 숨은 원래 버튼 rect를 찾지 못한다. more-origin 상태와 현재 toolbar 항목 기준 dispatcher가 필요하다.
- [third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart](third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart): more 항목을 현재 toolbar 명령 유형으로 다시 dispatch하고, 2차 popup의 more-origin 상태와 우상단 가상 anchor를 추가했다.
- [third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart](third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart): 모든 more-origin 2차 popup의 우상단 anchor, more 고정 체크 열/활성 항목 체크, 병합 메뉴의 라벨 뒤 아이콘 배치를 추가했다.
- [test/label_sheet_toolbar_test.dart](test/label_sheet_toolbar_test.dart): 바코드/선/도형/개체 more 동작과 체크/토글/우상단 popup, 체크 열/병합 아이콘 배치 테스트를 추가했다.
- 완료: 라벨 시트 개체 패널 도킹 시 축소된 시트 툴바에서 가려진 명령을 `더 보기(...)`로 노출하고 팝업으로 실행할 수 있도록 보완했다. 관련 검증 및 기능 커밋 `73c8c5f` 완료.
- 범위 밖 [lib/core/app.dart](lib/core/app.dart)는 커밋에서 제외했다.
- 원인: 라벨 시트의 줌 컨트롤이 시트 툴바 우측 위에 겹치지만 FortuneSheet overflow 계산은 전체 폭을 사용해, 우측 끝 `더 보기` 버튼이 줌 컨트롤 아래에 가려지고 pointer 입력도 줌 컨트롤이 가로챘다.
- [third_party/fortune_sheet/lib/src/fortune_sheet_app.dart](third_party/fortune_sheet/lib/src/fortune_sheet_app.dart): 런타임 전용 `toolbarRightInset`을 canvas로 전달한다.
- [third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart](third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart): toolbar hit-test와 overflow popup 항목 계산에 우측 예약 폭을 적용한다.
- [third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart](third_party/fortune_sheet/lib/src/fortune_sheet_painter.dart): toolbar 그리기, semantics, popup anchor/항목 계산에 같은 예약 폭을 적용한다.
- [lib/page_label_sheet/label_sheet_workbench.dart](lib/page_label_sheet/label_sheet_workbench.dart): 줌 컨트롤이 sheet toolbar 끝에 있을 때만 124px을 FortuneSheet toolbar 우측에서 예약한다.
- [test/label_sheet_toolbar_test.dart](test/label_sheet_toolbar_test.dart): 개체 패널 도킹 상태에서 `더 보기` 버튼이 노출되고 클릭 시 popup이 열리는 회귀 테스트를 추가했다. 기존 fixture의 필수 `useMinColumnCheck: false`도 보완했다.
- 사용자가 [lib/page_label_sheet/label_sheet_workbench.dart](lib/page_label_sheet/label_sheet_workbench.dart)의 패널 복원/드래그 최소 폭 일부를 `260→200`, 더블클릭 기본 폭을 `300→200`으로 변경한 상태이며 이 변경은 유지한다.
- 품목관리에 레거시형 컬럼 헤더 체크박스를 추가했다. 현재 포팅에서도 `주원료`와 동적 컬럼 헤더에서 최소표시 체크/언체크가 가능하고, `BM_RICH_COL_MIN.RICH_MIN_CHECK`로 즉시 저장된다.
- 공용 `FortuneTable`에 헤더 체크박스 옵션을 추가했고, 품목관리에서는 체크 시 컬럼 폭을 축소하고 해제 시 원래 폭으로 복원한다.
- 이번 작업 관련 검증과 handoff 갱신은 완료됐고, 남은 것은 관련 파일만 분리 커밋하는 단계다.
- 현재 작업트리에는 이번 품목관리 헤더 체크박스 작업과 범위 밖 사용자 변경 [lib/core/app.dart](lib/core/app.dart)가 있다.

## 최근 완료 항목
- 품목관리 `주원료`와 동적 컬럼 헤더에 레거시형 체크박스를 추가했다.
- `BM_RICH_COL_MIN`의 `RICH_MIN_CHECK`를 현재 Flutter 모델에 로드하도록 일반 컬럼/특수 컬럼 조회를 보강했다.
- 품목관리 헤더 체크 변경 시 `BM_RICH_COL_MIN`을 즉시 upsert 하도록 저장 경로를 추가했다.
- `FortuneTable` 헤더가 선택적으로 체크박스를 렌더링할 수 있도록 공용 테이블 컴포넌트를 확장했다.
- 품목관리 헤더 체크박스 노출과 폭 변경을 위젯 테스트로 추가했다.
- 자동품목갱신과 저울출력도 홈 상단 검색 바가 보이도록 탭 노출 조건을 확장했다.
- 공용 `TableSearchResult`를 도입해 품목관리, 자동품목갱신, 저울출력이 같은 검색 결과 계약을 사용하도록 정리했다.
- 자동품목갱신 페이지 컨트롤러에 검색/검색 reset API를 추가하고, target 테이블의 현재 활성 컬럼 기준으로 다음 일치 행을 선택하도록 연결했다.
- 저울출력 페이지 컨트롤러에 검색/검색 reset API를 추가하고, 현재 활성 컬럼 기준으로 다음 일치 행을 선택하면서 선택 품목과 포커스를 함께 이동하도록 연결했다.
- 자동품목갱신/저울출력 검색 동작을 위젯 테스트로 추가했다.
- 최신 `.tmp/log/app_2026-07-24_17-23-30.log`에서 F1/F2/F3가 모두 `routeInactive routeCurrent=false`로 무시되는 것을 확인했다.
- HomePageManager의 global F키 핸들러에서 잘못된 route current 차단을 제거했다.
- 중복 단축키 로그와 이중 처리 경로를 만들던 HomePageManager 최상위 Focus 래퍼를 제거했다.
- F1/F2/F3/F5가 무시되거나 처리될 때 이유를 추적할 수 있도록 home tab shortcut debug 로그를 추가했다.
- 같은 output capture owner token으로 preview workbench state가 재생성될 때는 기존 attach를 합법적인 owner 교체로 받아들이도록 `LabelSheetOutputCaptureController` attach 검증을 보정했다.
- 같은 owner token remount 시 attach 오류가 재발하지 않는 위젯 테스트를 추가했다.
- 다음 세션에서 바로 복사/붙여넣기할 수 있도록 이 파일 상단에 시작 문구를 추가했다.
- [SESSION_RULES.md](SESSION_RULES.md)의 `로그 파일에는 비즈니스 로직을 넣지 않는다` 문구를 로그 기록/파싱은 관측과 진단만 담당하고 업무 판단·상태 변경·저장·재시도는 직접 수행하지 않는다는 의미로 구체화했다.
- 탭메뉴 저울출력 처음 진입시 라벨/품목 로드 직후 `_syncScaleOutputRows()`가 호출되지 않아 테이블 rows가 비어 있던 문제를 수정했다.
- 라벨 변경 시 저울출력 rows를 즉시 만들지 않고, 저울출력 탭이 실제로 선택될 때만 sync하도록 바꿨다.
- git history의 `963e22e`, `14ce98b`, `9288f62` 흐름을 근거로 SQL Server 2017 호환 구문 사용 원칙을 상시 규칙으로 승격했다.
- 저울출력 테이블이 baseline 전체 품목을 기본 표시하도록 수정했고, 발행은 선택 품목 기준으로 정리했다.
- 저울출력 테이블 우클릭 메뉴를 추가했고, 레거시처럼 `전체내용 다시가져오기`와 비활성 `선택내용 다시가져오기`를 적용했다.
- 저울출력 로컬 DB를 디버그에서도 작업폴더 밖 지원 디렉터리로 저장하게 바꾸고, 생성 DB 파일은 [.gitignore](.gitignore)로 제외했다.
- 저울출력 미리보기에서 개체 패널을 숨기고, 줌 툴바를 우하단 command bar에서 중량/가격 영역 상단으로 이동했다.

## 최근 검증
- 수정된 Dart 3개 파일 formatter 완료, diagnostics 오류 없음.
- `flutter test test/label_sheet_toolbar_test.dart` 147개 전체 통과.
- FortuneSheet canvas의 더보기/외부 닫기/병합 focused 테스트 3개 통과.
- 바코드 삽입 다이얼로그, 선 삽입, 개체 패널 직접 툴바 focused 테스트 각 1개 통과.
- `flutter test test/label_sheet_toolbar_test.dart --plain-name "toolbar more runs hidden object insertion commands"` 통과.
- `flutter test test/label_sheet_toolbar_test.dart --plain-name "toolbar popup rows reserve check space and trail merge icons"` 통과.
- `flutter test third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart --plain-name "toolbar more popup exposes overflowed dropdown items"` 통과.
- `flutter test test/label_sheet_toolbar_test.dart` 145개 전체 통과.
- `flutter test test/label_sheet_toolbar_test.dart --plain-name "docked object panel keeps toolbar overflow commands reachable"` 통과.
- `flutter test third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart --name "toolbar (overflow exposes upstream more aria label|more popup exposes overflowed item aria labels)"` 2개 통과.
- `flutter test test/fortune_table_test.dart` 통과.
- `flutter test test/fortune_table_test.dart test/automatic_item_update_page_test.dart test/scale_output_test.dart` 통과.
- `flutter test test/fortune_table_test.dart` 통과.
- `flutter test test/label_print_session_test.dart` 통과.
- `flutter test test/scale_output_test.dart` 통과.
- `flutter test test/db_scale_connect_info_test.dart` 통과.
- `lib/home_page_manager.dart` analyzer 오류 없음 확인.
- 저울출력 관련 수정 파일 analyzer 오류 없음 확인.

## 다음 작업 시작점
- 라벨 시트 툴바/개체 패널 후속 요청은 [lib/page_label_sheet/label_sheet_workbench.dart](lib/page_label_sheet/label_sheet_workbench.dart)와 FortuneSheet의 `toolbarRightInset` 전달 경로부터 확인한다.
- 품목관리 헤더 최소표시 동작 후속 요청은 [lib/page_home/item_manage.dart](lib/page_home/item_manage.dart), [lib/models/column.dart](lib/models/column.dart), [lib/models/column_special.dart](lib/models/column_special.dart), [third_party/fortune_sheet/lib/src/fortune_table.dart](third_party/fortune_sheet/lib/src/fortune_table.dart)부터 확인한다.
- 저울출력 후속 요청이 들어오면 [lib/page_home/scale_output_page.dart](lib/page_home/scale_output_page.dart), [lib/home_page_manager.dart](lib/home_page_manager.dart), [lib/models/scale_output.dart](lib/models/scale_output.dart)부터 확인한다.
- 미리보기/개체 패널/줌 위치 관련 후속 요청은 [lib/widgets/label_output_preview.dart](lib/widgets/label_output_preview.dart)와 [lib/page_label_sheet/label_sheet_workbench.dart](lib/page_label_sheet/label_sheet_workbench.dart)를 먼저 본다.
- DB 저장 경로 정책 후속 요청은 [lib/database/db_scale_connect_info.dart](lib/database/db_scale_connect_info.dart)와 [test/db_scale_connect_info_test.dart](test/db_scale_connect_info_test.dart)를 먼저 본다.

## 주의사항
- 현재 저장소에는 범위 밖 사용자 변경 [lib/core/app.dart](lib/core/app.dart)가 있으므로 이후 작업에서도 분리 유지가 필요하다.
- 과거 상세 완료 로그는 git history와 관련 커밋 메시지로 추적한다.
