## 다음 세션 시작 문구
- SESSION_RULES.md와 SESSION_HANDOFF.md를 확인해 이전 세션 작업을 이어서 진행해줘
- SESSION_RULES.md와 SESSION_HANDOFF.md를 확인해 이전 세션 작업을 이어서 진행하게 대기해줘

## 상시 규칙
- 상시 규칙은 [SESSION_RULES.md](SESSION_RULES.md)를 기준으로 따른다.
- 이 파일에는 현재 상태, 최근 완료 항목, 검증, 다음 액션만 기록한다.

## 현재 상태
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
- `flutter test test/fortune_table_test.dart` 통과.
- `flutter test test/fortune_table_test.dart test/automatic_item_update_page_test.dart test/scale_output_test.dart` 통과.
- `flutter test test/fortune_table_test.dart` 통과.
- `flutter test test/label_print_session_test.dart` 통과.
- `flutter test test/scale_output_test.dart` 통과.
- `flutter test test/db_scale_connect_info_test.dart` 통과.
- `lib/home_page_manager.dart` analyzer 오류 없음 확인.
- 저울출력 관련 수정 파일 analyzer 오류 없음 확인.

## 다음 작업 시작점
- 품목관리 헤더 최소표시 동작 후속 요청은 [lib/page_home/item_manage.dart](lib/page_home/item_manage.dart), [lib/models/column.dart](lib/models/column.dart), [lib/models/column_special.dart](lib/models/column_special.dart), [third_party/fortune_sheet/lib/src/fortune_table.dart](third_party/fortune_sheet/lib/src/fortune_table.dart)부터 확인한다.
- 저울출력 후속 요청이 들어오면 [lib/page_home/scale_output_page.dart](lib/page_home/scale_output_page.dart), [lib/home_page_manager.dart](lib/home_page_manager.dart), [lib/models/scale_output.dart](lib/models/scale_output.dart)부터 확인한다.
- 미리보기/개체 패널/줌 위치 관련 후속 요청은 [lib/widgets/label_output_preview.dart](lib/widgets/label_output_preview.dart)와 [lib/page_label_sheet/label_sheet_workbench.dart](lib/page_label_sheet/label_sheet_workbench.dart)를 먼저 본다.
- DB 저장 경로 정책 후속 요청은 [lib/database/db_scale_connect_info.dart](lib/database/db_scale_connect_info.dart)와 [test/db_scale_connect_info_test.dart](test/db_scale_connect_info_test.dart)를 먼저 본다.

## 주의사항
- 현재 저장소에는 범위 밖 사용자 변경 [lib/core/app.dart](lib/core/app.dart)가 있으므로 이후 작업에서도 분리 유지가 필요하다.
- 과거 상세 완료 로그는 git history와 관련 커밋 메시지로 추적한다.
