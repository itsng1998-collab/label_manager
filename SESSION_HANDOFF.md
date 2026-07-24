## 다음 세션 시작 문구
- SESSION_RULES.md와 SESSION_HANDOFF.md를 확인해 이전 세션 작업을 이어서 진행해줘
- SESSION_RULES.md와 SESSION_HANDOFF.md를 확인해 이전 세션 작업을 이어서 진행하게 대기해줘

## 상시 규칙
- 상시 규칙은 [SESSION_RULES.md](SESSION_RULES.md)를 기준으로 따른다.
- 이 파일에는 현재 상태, 최근 완료 항목, 검증, 다음 액션만 기록한다.

## 현재 상태
- 탭메뉴 저울출력 처음 진입 빈 테이블 수정, 저울출력 lazy sync 전환, SQL Server 호환 규칙 추가, 로그 규칙 문구 명확화까지 모두 커밋 완료 상태다.
- 최신 관련 커밋:
- `d9bada5` Clarify logging rule wording
- `8846281` Add SQL Server compatibility session rule
- `2fc8ba2` Defer scale output sync until tab open
- `733d3b4` Fix initial scale output tab load
- 현재 작업트리에는 범위 밖 사용자 변경 [lib/core/app.dart](lib/core/app.dart)만 남아 있다.

## 최근 완료 항목
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
- `flutter test test/scale_output_test.dart` 통과.
- `flutter test test/db_scale_connect_info_test.dart` 통과.
- `lib/home_page_manager.dart` analyzer 오류 없음 확인.
- 저울출력 관련 수정 파일 analyzer 오류 없음 확인.

## 다음 작업 시작점
- 저울출력 후속 요청이 들어오면 [lib/page_home/scale_output_page.dart](lib/page_home/scale_output_page.dart), [lib/home_page_manager.dart](lib/home_page_manager.dart), [lib/models/scale_output.dart](lib/models/scale_output.dart)부터 확인한다.
- 미리보기/개체 패널/줌 위치 관련 후속 요청은 [lib/widgets/label_output_preview.dart](lib/widgets/label_output_preview.dart)와 [lib/page_label_sheet/label_sheet_workbench.dart](lib/page_label_sheet/label_sheet_workbench.dart)를 먼저 본다.
- DB 저장 경로 정책 후속 요청은 [lib/database/db_scale_connect_info.dart](lib/database/db_scale_connect_info.dart)와 [test/db_scale_connect_info_test.dart](test/db_scale_connect_info_test.dart)를 먼저 본다.

## 주의사항
- 현재 저장소에는 범위 밖 사용자 변경 [lib/core/app.dart](lib/core/app.dart)가 있으므로 이후 작업에서도 분리 유지가 필요하다.
- 과거 상세 완료 로그는 git history와 관련 커밋 메시지로 추적한다.
