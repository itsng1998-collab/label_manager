## 상시 규칙
- 상시 규칙은 [SESSION_RULES.md](SESSION_RULES.md)를 기준으로 따른다.
- 이 파일에는 현재 상태, 최근 완료 항목, 검증, 다음 액션만 기록한다.

## 현재 상태
- 최근 저울출력 관련 작업은 모두 커밋 완료 상태다.
- 최신 관련 커밋:
- `882447d` Adjust scale output preview controls
- `a22c006` Move scale output DB out of workspace
- `6344d28` Fix scale output table reload behavior
- 현재 작업트리의 범위 밖 변경은 [lib/core/app.dart](lib/core/app.dart) 1건만 남아 있다.

## 최근 완료 항목
- 저울출력 테이블이 baseline 전체 품목을 기본 표시하도록 수정했고, 발행은 선택 품목 기준으로 정리했다.
- 저울출력 테이블 우클릭 메뉴를 추가했고, 레거시처럼 `전체내용 다시가져오기`와 비활성 `선택내용 다시가져오기`를 적용했다.
- 저울출력 로컬 DB를 디버그에서도 작업폴더 밖 지원 디렉터리로 저장하게 바꾸고, 생성 DB 파일은 [.gitignore](.gitignore)로 제외했다.
- 저울출력 미리보기에서 개체 패널을 숨기고, 줌 툴바를 우하단 command bar에서 중량/가격 영역 상단으로 이동했다.

## 최근 검증
- `flutter test test/scale_output_test.dart` 통과.
- `flutter test test/db_scale_connect_info_test.dart` 통과.
- 저울출력 관련 수정 파일 analyzer 오류 없음 확인.

## 다음 작업 시작점
- 저울출력 후속 요청이 들어오면 [lib/page_home/scale_output_page.dart](lib/page_home/scale_output_page.dart), [lib/home_page_manager.dart](lib/home_page_manager.dart), [lib/models/scale_output.dart](lib/models/scale_output.dart)부터 확인한다.
- 미리보기/개체 패널/줌 위치 관련 후속 요청은 [lib/widgets/label_output_preview.dart](lib/widgets/label_output_preview.dart)와 [lib/page_label_sheet/label_sheet_workbench.dart](lib/page_label_sheet/label_sheet_workbench.dart)를 먼저 본다.
- DB 저장 경로 정책 후속 요청은 [lib/database/db_scale_connect_info.dart](lib/database/db_scale_connect_info.dart)와 [test/db_scale_connect_info_test.dart](test/db_scale_connect_info_test.dart)를 먼저 본다.

## 주의사항
- 현재 저장소에는 범위 밖 사용자 변경 [lib/core/app.dart](lib/core/app.dart)가 있으므로 이후 작업에서도 분리 유지가 필요하다.
- 과거 상세 완료 로그는 git history와 관련 커밋 메시지로 추적한다.
