# 현재 작업 상태

## 완료: 품목관리 초기 저장 모드 표시 수정 v1.3.36
- 사용자 제보: 최근 가로 아이콘 footer 재배치 이후 품목관리 첫 진입에서 무조건 저장 모드가 되는 것으로 보인다.
- 최신 앱 로그 확인: session load 직후 draft는 `dirty=false`, 26초 뒤 rows가 모두 existing인 상태에서 `dirty=true`로 전환되어 행/셀 변경이 아닌 최소표시 draft 변경 가능성이 있다. 최근 footer는 clean 상태에서도 비활성 취소/저장 버튼을 항상 노출한다.
- 재현 테스트 결과: 실제 existing draft와 가로 overflow를 구성한 초기 여러 frame 후에도 `controller.isDirty=false`, 저장 버튼 `onPressed=null`로 기능상 dirty 전환은 재현되지 않았다.
- 편집 완료: clean 상태에서는 `취소`/`저장` 버튼을 렌더링하지 않고, draft가 dirty가 된 뒤에만 두 버튼을 가로 이동 아이콘 왼쪽에 표시한다. Excel 명령과 가로 이동 아이콘은 기존대로 유지한다.
- 테스트 수정: 초기 clean 상태에서는 취소/저장 버튼이 없고, 품명 변경 후 dirty 상태에서 버튼과 가로 이동 아이콘 배치/동작이 유지되는지 검증한다.
- focused 검증 완료: 수정한 footer 회귀 테스트 1건 및 `test/fortune_table_test.dart` 전체 72건 통과, 변경 파일 편집기 진단 없음.
- 버전 편집 완료: 초기 clean 상태의 저장 모드 오인 UI 수정이므로 PATCH 증가로 `1.3.35`에서 `1.3.36`으로 갱신했다.
- 인접 검증 예정: `test/fortune_table_test.dart`, `test/home_page_manager_session_test.dart`, `third_party/fortune_sheet/test/fortune_table_navigation_test.dart` 실행 후 변경 파일 strict analyzer를 수행한다.
- 인접 검증 완료: FortuneTable, home manager session, fortune_sheet navigation 테스트 총 77건 통과.
- strict analyzer 완료: `lib/features/item/presentation/item_manage.dart`, `test/fortune_table_test.dart` 분석 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.36`, `git diff --check` 통과.
- stage/commit 대상: `lib/features/item/presentation/item_manage.dart`, `test/fortune_table_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `f7e95ac` (`품목관리 초기 저장 모드 표시 수정`).

## 완료: 품목관리 가로 이동 아이콘 footer 배치 v1.3.35
- 사용자 실물 확인: FortuneTable 하단 좌우 아이콘 전용 30px 행이 공간을 낭비한다. 아이콘을 품목관리 footer의 `취소`/`저장` 오른쪽으로 적당한 간격을 두고 이동한다.
- 수정 방향: FortuneTable은 Shift+wheel과 12px scrollbar만 유지한다. `FortuneTableScrollController`에 가로 overflow/이동 API를 추가해 ItemManage footer가 좌우 아이콘과 툴팁을 소유하도록 변경한다.
- 플로팅 정렬 연계: 별도 30px 행 제거 후 Y target은 12px scrollbar+10px inset 기준으로 갱신한다.
- 구현 완료: FortuneTable의 별도 30px 아이콘 행을 제거하고 table viewport 높이를 복원했다. `FortuneTableScrollController`가 가로 overflow와 좌우 이동 가능 상태/command를 노출하며, ItemManage footer는 `저장` 오른쪽 12px 간격에 툴팁 좌우 아이콘을 표시한다. 시작/끝에서는 해당 방향 아이콘을 비활성화한다.
- 플로팅 연계 완료: Y target을 공용 12px 가로 scrollbar 두께+10px inset 기준으로 조정했다.
- focused 검증 완료: ItemManage footer 아이콘 배치·툴팁·양방향 이동, FortuneTable Shift+wheel·12px scrollbar, 플로팅 Y 기준 테스트 3건 통과.
- 인접 검증 완료: FortuneTable, home manager 정책 및 fortune_sheet navigation 테스트 총 77건 통과.
- strict analyzer 완료: 변경 구현/테스트 5개 파일 분석 결과 `No issues found`.
- 버전 편집 완료: 가로 이동 아이콘 footer 재배치이므로 PATCH 증가로 `1.3.34`에서 `1.3.35`로 갱신했다.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 예정: Debug EXE `FileVersion`/`ProductVersion`, `git diff --check`, 변경 파일 상태를 확인한다.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.35`, 변경 파일 편집기 진단 없음, `git diff --check` 통과.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/features/item/presentation/item_manage.dart`, `lib/home_page_manager.dart`, `test/fortune_table_test.dart`, `test/home_page_manager_session_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `1570164` (`가로 이동 아이콘을 품목관리 하단으로 이동`).

## 완료: 품목 플로팅창 하단 가로 스크롤 비가림 보정 v1.3.34
- 사용자 확인: FortuneTable 하단 가로 scrollbar와 좌우 이동 컨트롤 높이가 커져 기존 플로팅창 Y 정렬이 조작 영역을 가린다.
- 원인 확인: 플로팅창 bottom-right target은 테이블 bottom에서 기존 scrollbar theme 두께와 10px inset만 뺀다. 새 30px 하단 가로 컨트롤 높이를 반영하지 않는다.
- 회귀 테스트 예정: 800×600 테이블과 12px scrollbar에서 X는 기존 22px inset을 유지하고 Y는 30px 하단 컨트롤+10px 여백을 적용한 `(878, 610)`을 반환하는지 검증한다.
- 구현 전 focused 테스트 결과: `itemPreviewBottomRightTarget` 부재로 컴파일 실패해 새 하단 컨트롤 높이를 반영하는 정렬 정책이 없음을 확인했다.
- 구현 완료: FortuneTable 하단 컨트롤 높이 30px를 공용 상수로 노출했다. 품목 플로팅창 X target은 기존 scrollbar 두께+10px inset을 유지하고, Y target은 테이블 bottom에서 하단 컨트롤 30px+10px를 빼 해당 조작 영역 위에 정렬한다.
- focused 검증 완료: 플로팅 bottom-right target이 기존 X 위치를 유지하면서 Y를 하단 컨트롤 위 `(878, 610)`으로 계산하는 테스트 통과.
- 인접 검증 완료: home manager 정책, FortuneTable 통합 및 fortune_sheet navigation 테스트 총 76건 통과.
- 변경 파일 편집기 진단 완료: FortuneTable, home manager, 회귀 테스트 오류 없음.
- 버전 편집 완료: 품목 플로팅창 위치 보정이므로 PATCH 증가로 `1.3.33`에서 `1.3.34`로 갱신했다.
- strict analyzer 예정: `C:/Flutter/bin/flutter.bat analyze third_party/fortune_sheet/lib/src/fortune_table.dart lib/home_page_manager.dart test/home_page_manager_session_test.dart`.
- strict analyzer 완료: 변경 구현/테스트 3개 파일 분석 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 예정: Debug EXE `FileVersion`/`ProductVersion`, `git diff --check`, 변경 파일 상태를 확인한다.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.34`, 변경 파일 편집기 진단 없음, `git diff --check` 통과.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/home_page_manager.dart`, `test/home_page_manager_session_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `dd98dd6` (`플로팅창 가로 스크롤 비가림 보정`).

## 완료: 품목관리 가로 스크롤 접근성 개선 v1.3.33
- 요구 동작: FortuneTable에서 `Shift + 휠` 가로 이동을 지원하고 가로 scrollbar 두께를 확대하며, 가로 overflow 시 테이블 하단에 좌우 이동 아이콘을 제공한다.
- 현재 동작 확인: trackpad의 수평 delta와 8px 가로 scrollbar는 지원하지만 Shift modifier를 wheel 축 변환에 사용하지 않고, 품목관리의 multi-selection 때문에 mouse drag scroll은 비활성화된다.
- 회귀 테스트 예정: 세로 wheel delta가 Shift 입력 중 가로 offset을 증가시키고, 12px 가로 scrollbar와 하단 좌우 아이콘이 표시되며 아이콘 click으로 양방향 이동하는지 검증한다.
- 구현 전 focused 테스트 결과: 가로 scrollbar 두께가 기존 8px여서 실패해 요구 동작이 아직 없음을 확인했다.
- 구현 완료: Shift 입력 중 wheel의 우세 delta를 가로 controller로 전달한다. 가로 overflow 시 scrollbar를 12px로 확대하고 30px 하단 컨트롤 바에 좌우 chevron 아이콘을 제공하며, 각 아이콘에 `왼쪽으로 이동`/`오른쪽으로 이동` 툴팁을 적용했다.
- focused 검증 완료: Shift+wheel 가로 offset 증가, 12px scrollbar, 좌우 아이콘·툴팁 표시와 양방향 click 이동 테스트 통과.
- 인접 검증 완료: FortuneTable 통합 및 fortune_sheet navigation 테스트 총 71건 통과.
- 변경 파일 편집기 진단 완료: FortuneTable과 회귀 테스트 오류 없음.
- 버전 편집 완료: 품목관리 가로 스크롤 접근성 개선이므로 PATCH 증가로 `1.3.32`에서 `1.3.33`으로 갱신했다.
- strict analyzer 예정: `C:/Flutter/bin/flutter.bat analyze third_party/fortune_sheet/lib/src/fortune_table.dart test/fortune_table_test.dart`.
- strict analyzer 완료: 변경 구현/테스트 2개 파일 분석 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 예정: Debug EXE `FileVersion`/`ProductVersion`, `git diff --check`, 변경 파일 상태를 확인한다.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.33`, 변경 파일 편집기 진단 없음, `git diff --check` 통과.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `test/fortune_table_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `d755435` (`품목관리 가로 스크롤 조작 개선`).

## 완료: 품목관리 셀별 클라이언트 편집 권한 적용 v1.3.32
- 요구 동작: 동적 셀의 `RICH_EDITABLE=false`는 셀 색상을 변경하고 입력을 잠그며, `RICH_EDITABLE=true`는 로그인 사용자 등급과 무관하게 입력을 허용한다.
- 기존 경로 확인: 우클릭 `클라이언트 편집 허용/불가`와 draft/저장 payload의 `editable` 보존은 이미 구현되어 있다. 현재 `_canEditDynamicColumn()`이 사용자 등급 권한을 선행 조건으로 사용해 일반 사용자의 허용 셀도 차단하며 FortuneTable은 행 단위 색상 API만 제공한다.
- 회귀 테스트 예정: `canEdit=false`에서 불가 셀은 잠금 색상과 편집 차단, 허용 셀은 실제 inline editor 진입을 검증한다.
- 구현 전 focused 테스트 결과: 허용 셀의 `isTextEditable`이 `false`여서 실패해 사용자 등급 선행 조건이 원인임을 확인했다.
- 구현 완료: FortuneTable 컬럼에 `cellColorBuilder`를 추가했다. ItemManage는 baseline 또는 현재 column draft의 `editable`을 셀별로 계산해 `false`이면 회색과 입력 잠금을 적용하고, `true`이면 사용자 등급과 무관하게 텍스트/BMP 입력을 허용한다. 우클릭 허용/불가 설정은 기존 관리자 권한 조건을 유지한다.
- 설정 전환 검증 보완: 관리자 우클릭으로 같은 셀을 `불가 → 허용 → 불가` 전환할 때 편집 가능 여부와 잠금 색상이 즉시 바뀌고 최종 `editable=false`가 저장 payload에 반영되는지 검증한다.
- focused 검증 완료: 셀별 일반 사용자 입력 권한 테스트와 관리자 우클릭 허용/불가 왕복 테스트 2건 통과.
- 인접 검증 완료: FortuneTable 통합 및 fortune_sheet navigation 테스트 총 70건 통과.
- 변경 파일 편집기 진단 완료: FortuneTable, ItemManage, item manager rules, 회귀 테스트 오류 없음.
- 버전 편집 완료: 품목관리 셀별 클라이언트 편집 권한 적용이므로 PATCH 증가로 `1.3.31`에서 `1.3.32`로 갱신했다.
- strict analyzer 예정: `C:/Flutter/bin/flutter.bat analyze third_party/fortune_sheet/lib/src/fortune_table.dart lib/features/item/domain/item_manager_rules.dart lib/features/item/presentation/item_manage.dart test/fortune_table_test.dart`.
- strict analyzer 완료: 변경 구현/테스트 4개 파일 분석 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 예정: Debug EXE `FileVersion`/`ProductVersion`, `git diff --check`, 변경 파일 상태를 확인한다.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.32`, 변경 파일 편집기 진단 없음, `git diff --check` 통과.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/features/item/domain/item_manager_rules.dart`, `lib/features/item/presentation/item_manage.dart`, `test/fortune_table_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `aeb9a3c` (`품목관리 셀별 클라이언트 편집 권한 적용`).

## 완료: 품명 편집 중 다른 품목 클릭 후 스크롤 비활성 수정 v1.3.31
- 사용자 재현: 품목관리에서 품명을 더블클릭해 편집한 채 다른 품목을 한 번 클릭하면 이동 스크롤이 비활성화되고, 다시 편집 후 Enter를 눌러야 복구된다.
- 원인 가설: FortuneTable은 다른 셀 `onPointerDown`에서 선택과 품목 draft selection 재빌드를 먼저 수행하고 편집 commit은 `onPointerUp`에 예약한다. 재빌드로 pointer-up listener가 유실되면 editor/drag 상태가 남는다.
- 회귀 테스트 추가: 다른 셀 pointer-down 직후, pointer-up 전에도 기존 editor가 종료되고 commit이 1회 수행되는지 검증한다. 현재 구현에서 실패 확인 예정.
- 구현 전 focused 테스트 결과: pointer-down 직후 commit 횟수가 0으로 실패해 기존 editor가 pointer-up에 의존함을 확인했다.
- 구현 완료: FortuneTable의 다른 셀 `onPointerDown`에서 `_selectRow()`보다 먼저 `_queueTextEditingCommit()`을 시작한다. 기존 pointer-up은 pending 중복 방지 fallback으로 유지한다.
- focused 검증 완료: 동일 pointer-down commit 테스트가 통과해 pointer-up 전 commit 1회와 editor 종료를 확인했다.
- 첫 구현 후 핵심 commit/editor assertion은 통과했고, 테스트 종료 시 double-tap recognizer의 40ms 타이머만 남아 실패했다. gesture 종료 후 100ms pump를 추가해 테스트 타이머를 정리했다.
- 사용자 증상 직접 검증 보완: 회귀 테스트를 20행으로 확장하고 다른 품목 클릭/commit 후 wheel 이벤트가 FortuneTable 세로 scroll offset을 실제로 증가시키는지 확인한다.
- 스크롤 회귀 검증 완료: 확장된 focused 테스트 통과. FortuneTable 통합 및 fortune_sheet navigation 테스트 총 69건도 통과했다.
- 변경 파일 편집기 진단 완료: `fortune_table.dart`, `fortune_table_test.dart` 오류 없음.
- 버전 편집 완료: 사용자 조작으로 공용 FortuneTable 스크롤이 비활성화되는 회귀 수정이므로 PATCH 증가로 `1.3.30`에서 `1.3.31`로 갱신했다.
- strict analyzer 예정: `C:/Flutter/bin/flutter.bat analyze third_party/fortune_sheet/lib/src/fortune_table.dart test/fortune_table_test.dart`.
- strict analyzer 완료: 변경 구현/테스트 2개 파일 분석 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 예정: Debug EXE `FileVersion`/`ProductVersion`, `git diff --check`, 변경 파일 상태를 확인한다.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.31`, 변경 파일 편집기 진단 없음, `git diff --check` 통과.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `test/fortune_table_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `ff63111` (`품명 편집 후 스크롤 비활성 수정`).

## 완료: 품목 우클릭 새로고침 후 무한 로딩 확인 v1.3.30
- 사용자 재현: 품목관리 우클릭 `새로 고침` 후 하단 `처리 중`이 계속 표시되고 메뉴가 일괄 비활성화된다.
- 제출 로그 파일명 `품목관리_새로고침이후 무한 로딩 현상.log`, `품목관리_새로고침_무한로딩.log`는 workspace에서 발견되지 않았다. 기존 workspace 재현 로그에는 `sessionLoad event=renderWaiting` 이후 `renderReady`가 없는 사례가 존재한다.
- 코드 확인: `_refreshItemManager()`와 품목 순서 저장은 모두 `_reloadItemDraftFromDatabase()`를 호출한다. v1.3.30의 `isItemManagerReload=true` 및 render-ready 비대기 수정이 우클릭 새로고침에도 동일하게 적용된다.
- 추가 production 수정/버전 증가는 하지 않는다. 기존 정책 회귀 테스트 이름을 새로고침과 순서 저장 두 진입점이 모두 공통 reload 정책의 보호 대상임을 명시하도록 보강했다.
- 검증 완료: `home_page_manager_session_test.dart`, `fortune_table_test.dart` 총 72건 통과. `flutter analyze lib/home_page_manager.dart test/home_page_manager_session_test.dart` 결과 `No issues found`.
- stage/commit 대상: `test/home_page_manager_session_test.dart`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 회귀 검증 커밋: `7630359` (`품목 새로고침 무한 로딩 회귀 검증`).

## 완료: 품목 순서 변경 저장 후 무한 로딩 수정 v1.3.30
- 사용자 재현: 품목 순서 변경 다이얼로그에서 행을 드래그해 순서를 변경하고 저장하면 하단 `처리 중`이 계속 표시되고 품목관리 메뉴가 일괄 비활성화된다.
- 코드 경로: `_changeItemOrder()`가 `_itemDraftCommandBusy=true`로 진입한 뒤 `saveItemManagerOrder()`와 DB 재조회를 기다리며, `finally`는 있으므로 await 중 하나가 반환하지 않는 경우에만 busy가 지속된다.
- 조사 예정: 연결 DB의 `플로터 테스트` 품목을 현재 순서와 동일한 order로 `ItemDAO.updateOrders()`에 전달해 실제 SQL transaction 반환 여부와 시간을 측정한다.
- DB probe 결과: 현재 DB의 품목 20개 동일 순서 update는 transaction/COMMIT 포함 105ms에 정상 반환했다. 순서 저장 SQL 자체는 지속 busy 원인이 아니다.
- 원인 확인: 저장 후 `_reloadItemDraftFromDatabase()`가 DB 데이터와 controller 반영을 끝낸 뒤에도 `ItemManage.onReady` callback을 무기한 기다린다. callback이 유실되면 `_changeItemOrder()`의 `finally`에 도달하지 못해 `처리 중`이 영구 유지된다.
- 수정 방향: 일반 라벨 전환의 render-ready 대기는 유지하되, 저장 후 강제 재조회는 탭 재구성만 요청하고 render callback을 command 완료 조건에서 제외한다.
- 회귀 테스트 추가: 일반 세션 로드는 render-ready를 기다리고 저장 후 reload는 기다리지 않는 정책을 `home_page_manager_session_test.dart`에 추가했다. 구현 전 실패 확인 예정.
- 구현 전 focused 테스트 결과: `itemManagerSessionLoadWaitsForRenderReady` 부재로 컴파일 실패해 새 정책이 기존 코드에 없음을 확인했다.
- 구현 완료: `_reloadItemDraftFromDatabase()`가 `isItemManagerReload=true`를 전달하고, reload에서는 DB/controller 반영 후 `_resetTabs()`만 호출해 `ItemManage.onReady`를 기다리지 않는다. 일반 라벨 세션 로드의 render-ready 대기는 유지한다.
- focused 검증 완료: render-ready 대기 정책 회귀 테스트 1건 통과.
- 임시 산출물 정리: 현재 DB에서 동일 order update 반환 시간을 측정한 `test/item_order_db_probe_test.dart`를 삭제했다.
- 인접 검증 예정: 품목 순서 다이얼로그/세션/저장 DAO/draft 및 FortuneTable 품목관리 테스트를 실행한다.
- 인접 검증 완료: `item_order_dialog`, `home_page_manager_session`, `item_manager_save_dao`, `item_manager_draft`, `fortune_table` 총 115건 통과.
- 버전 편집 완료: 품목 순서 저장 후 command busy가 영구 유지되는 회귀 수정이므로 PATCH 증가로 `1.3.29`에서 `1.3.30`으로 갱신했다.
- strict analyzer 예정: `C:/Flutter/bin/flutter.bat analyze lib/home_page_manager.dart test/home_page_manager_session_test.dart`.
- strict analyzer 완료: 변경 구현/테스트 2개 파일 분석 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.30`, 변경 파일 편집기 진단 없음, `git diff --check` 통과. helper 들여쓰기 정리 후 focused 테스트도 재통과했다.
- stage/commit 대상: `lib/home_page_manager.dart`, `test/home_page_manager_session_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `3bac0a3` (`품목 순서 저장 무한 로딩 수정`).

## 완료: 날짜 시한 자유 입력 저장 오류 수정 v1.3.29
- 사용자 재현: 날짜 시한 사용 컬럼에서 빈값/한글/영문/숫자값 등 입력 내용과 무관하게 `소비시한 날짜/시간 형식 또는 범위가 올바르지 않습니다.` 오류로 품목 저장이 불가능하다.
- 원인 후보: 현재 `TYPE_VALIDDATE` validation은 `RICH_USE_DATERANGE=1`이면 `RICH_DATERANGE`가 양쪽 숫자인 `before|after` 형식이어야만 통과한다. 레거시 설정은 앞/뒤 범위를 비워 `|`, `3|`, `|5`로 저장하는 것도 허용한다.
- 현재 DB 확인: `BM_RICH_COLUMN`의 소비시한/날짜 범위 사용 컬럼 타입과 `RICH_DATERANGE` 원문을 읽기 전용 probe로 조회했다.
- DB 읽기 전용 probe 결과: 실제 `소비시한` 컬럼은 `RICH_TYPE=2`(`TYPE_VALIDTIME`)이며 날짜 범위를 사용하지 않는다. 현재 앱이 비어 있지 않은 값을 무조건 `HHmm`로 강제하는 것이 재현 원인이다.
- 레거시 확인: `CheckDateFormat`은 `TYPE_VALIDDATE`, `TYPE_MAKEDATE`에만 호출되며 `TYPE_VALIDTIME`은 형식 검증 없이 타임바코드 갱신 원본으로 사용된다.
- 테스트 추가: `item_manager_draft_test.dart`에 빈값/한글/영문/숫자 날짜 시한 값을 허용하는 회귀 테스트를 추가했다. 구현 전 실패 확인 예정.
- 구현 전 회귀 테스트 결과: 예상대로 `1행 소비시한 날짜/시간 형식 또는 범위가 올바르지 않습니다.`로 실패했다.
- 구현 완료: `_isValidDateOrTimeValue`에서 `TYPE_VALIDTIME`을 자유 문자열로 허용했다. `TYPE_MAKETIME`의 기존 `HHmm` 검증은 유지한다.
- focused 검증 완료: 날짜 시한 회귀 테스트 1건 통과.
- 임시 산출물 정리: 읽기 전용 DB 조회에 사용한 `test/date_range_probe_test.dart`를 삭제했다.
- 인접 검증 예정: `C:/Flutter/bin/flutter.bat test test/item_manager_draft_test.dart`로 품목 draft 저장 검증 전체를 실행한다.
- 품목 draft 전체 검증 완료: `item_manager_draft_test.dart` 33건 통과. 기존 제조일자·소비기한·제조시한 형식 및 범위 검증도 통과했다.
- 관련 통합 검증 예정: `item_manager_*_test.dart` 6개 파일을 실행해 저장/세션/조회/import/export 회귀를 확인한다.
- 관련 통합 검증 완료: `item_manager_*_test.dart` 6개 파일, 총 40건 통과.
- 버전 편집 완료: 날짜 시한 값 때문에 품목 저장이 차단되는 회귀 수정이므로 PATCH 증가로 `1.3.28`에서 `1.3.29`로 갱신했다.
- strict analyzer 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/item/domain/item_manager_draft.dart test/item_manager_draft_test.dart`.
- strict analyzer 완료: 변경 구현/테스트 2개 파일 분석 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.29`, 변경 파일 편집기 진단 없음, `git diff --check` 통과.
- stage/commit 대상: `lib/features/item/domain/item_manager_draft.dart`, `test/item_manager_draft_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `f05d6ab` (`날짜 시한 자유 입력 저장 오류 수정`).

## 완료: 품목 편집 중 주원료/출력 미리보기 재표시 및 draft 반영 v1.3.28
- 사용자 재현: 주원료 및 라벨출력 미리보기 창을 닫은 뒤 품목관리에서 셀 편집 중 다시 열거나 출력 탭을 선택하면 `품목 편집을 완료하거나 취소한 뒤 변경해 주세요.`로 차단된다.
- 요구사항: 주원료 입력도 품목 편집의 일부이므로 창을 다시 표시할 수 있어야 하고, 출력내용 미리보기는 품목 저장 전에도 현재 입력 내용을 즉시 표시해야 한다.
- 원인 확인: production의 `canSelectOutputPreview`가 브랜드/라벨 변경용 `_blockItemDraftContextChange()`를 재사용해 active editing과 dirty draft를 모두 차단한다. 출력 미리보기 입력도 저장된 `ItemOfMarket`과 baseline 컬럼값을 사용해 품명/컬럼 draft가 즉시 반영되지 않는다.
- 수정 예정: 창 복원 전에 품목 셀 편집을 commit하고, 출력 탭은 command 실행 중만 제한한다. 선택 행의 draft item과 baseline 위에 덮은 draft 컬럼값을 미리보기에 전달한다.
- 재현 테스트 추가: active/dirty 상태와 무관한 출력 탭 허용 정책(command busy만 차단) 및 저장 전 컬럼 draft 우선 투영을 검증한다.
- 구현 완료: 미리보기 복원과 출력 탭 선택 시 품목 테이블 active editing을 commit한다. 선택 품목을 현재 `ItemManagerDraftRow.toPreviewItem()`으로 만들고 baseline 출력값 위에 `columnDrafts`를 덮어 품명/주원료/컬럼 수정 내용을 저장 전에 표시한다. 출력 탭은 save command 진행 중에만 차단한다.
- 즉시 갱신 보완: 품목 draft listener가 dirty 여부 변화와 무관하게 열린 미리보기 child를 현재 draft로 다시 주입한다. 기존 panel guard 테스트명은 command-busy 등 실제 선택 제한 의미에 맞게 정리했다.
- 출력 형식 보완: draft 컬럼 raw 값을 scoped baseline에 먼저 합친 뒤 기존 `projectLabelPrintColumnValues()`를 통과시켜 날짜/바코드/자동증가 후처리가 실제 발행과 동일하게 적용되도록 했다.
- focused 및 인접 검증 완료: 미리보기 정책/투영 focused 5건과 품목 세션/toolbar/draft/fortune table 전체 295건 통과, 변경 파일 편집기 진단 없음.
- 버전 편집 완료: 품목 편집 중 미리보기 재표시 및 즉시 draft 반영 개선이므로 PATCH 증가로 `1.3.27`에서 `1.3.28`로 갱신했다.
- strict analyzer 예정: `C:/Flutter/bin/flutter.bat analyze lib/home_page_manager.dart test/home_page_manager_session_test.dart test/label_sheet_toolbar_test.dart`.
- strict analyzer 완료: 위 3개 변경 파일 분석 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.28`, `git diff --check` 통과, 변경 파일 진단 없음.
- stage/commit 대상: `lib/home_page_manager.dart`, 미리보기/세션 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `ffb5d53` (`품목 편집 중 미리보기 즉시 반영`).

## 완료: 재로그인 후 품목관리 브랜드 로딩 지속 수정 v1.3.27
- 사용자 재현: ID `3575` 로그인 → 우측 상단 로그아웃 → 같은 ID 재로그인 시 `브랜드 데이터를 불러오고 있습니다...`가 지속되고 품목 추가/삭제 등 이벤트가 비활성화된다.
- 실행본 참고: 첨부 화면은 `v1.3.5`; 현재 소스는 `v1.3.26`. workspace 최신 로그는 해당 3575 재현 로그가 아니어서 코드 경로로 원인을 확정했다.
- 원인 확인: 로그아웃 후 부모의 선택 라벨이 유지되고 새 `HomePageManager`가 그 라벨을 `_currentLabelSize`로 받는다. 초기 로드에서 요청/현재/부모 선택 ID가 같다는 이유만으로 `_handleLabelSizeChanged`가 조기 반환하여 실제 품목 세션과 draft controller를 만들지 않고, 로딩 스낵바도 닫지 않는다.
- 수정 예정: 동일 라벨 조기 반환은 `_itemDraftLoadedLabelSizeId`까지 일치해 현재 manager에 품목 세션이 실제 적재된 경우에만 허용한다.
- 재현 테스트 추가: 요청/현재/선택 라벨이 같아도 loaded session ID가 없으면 미적재로 판단하고, 모두 같을 때만 적재 완료로 판단한다.
- 구현 완료: `itemManagerSessionAlreadyLoaded` 판정에 `_itemDraftLoadedLabelSizeId`를 포함해 재로그인 새 manager의 미적재 상태에서는 동일 라벨도 반드시 다시 로드한다.
- 판정 보완: 요청 라벨 ID가 `null`인 빈 브랜드/라벨 상태는 적재 완료로 보지 않아 초기화 및 스낵바 종료 경로를 실행한다.
- focused 검증 완료: 신규 세션 적재 판정 테스트 통과. 포맷 후 `home_page_manager.dart` diff는 의도한 18줄 추가/2줄 변경이며 공백 오류 없음.
- 인접 검증 예정: `home_page_manager_session_test.dart`, `fortune_table_test.dart`, `label_sheet_toolbar_test.dart`를 실행해 품목 세션/탭 렌더링 회귀를 확인한다.
- 인접 검증 완료: 품목 세션/fortune table/label sheet toolbar 총 261건 통과.
- 버전 편집 완료: 재로그인 후 품목관리 사용 불가 오류 수정이므로 PATCH 증가로 `1.3.26`에서 `1.3.27`로 갱신했다.
- strict analyzer 예정: `C:/Flutter/bin/flutter.bat analyze lib/home_page_manager.dart test/home_page_manager_session_test.dart`.
- strict analyzer 완료: 위 2개 변경 파일 분석 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.27`, `git diff --check` 통과. helper 들여쓰기 보정 후 focused 테스트도 재통과했다.
- stage/commit 대상: `lib/home_page_manager.dart`, `test/home_page_manager_session_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `5cf1191` (`재로그인 품목관리 로딩 지속 수정`).

## 완료: 관리자 grade 0/1 ID/PW 표시 및 시리얼 인증 제외 v1.3.26
- 사용자 요청: `BM_USER.RICH_USER_GRADE`가 `0` 또는 `1`이면 사용자관리에서 ID/PW를 표시하고, SYSTEM과 같은 관리자 계정으로 취급해 다른 PC에서도 시리얼 인증 없이 로그인한다.
- 현재 동작: grade 0 자체 비밀번호만 `firstAdmin`, grade 1은 `regular`로 분류한다. 사용자관리 ID/PW는 `isFirstConnectByAdmin`만 보고, `firstAdmin`도 PC 시리얼 인증을 요구한다.
- 수정 예정: 공용 관리자 grade 판정을 0/1로 정의하고 로그인 모드·ID/PW 표시에서 사용한다. `firstAdmin`과 `masterKey`는 PC 시리얼 인증에서 제외한다.
- 재현 테스트 추가: grade 1 자체 비밀번호의 `firstAdmin` 분류, grade 0/1 자격정보 표시, `firstAdmin` 시리얼 인증 제외 계약을 검증한다.
- 첫 focused 검증: 기존 정책에서 `firstAdmin` 시리얼 인증 필요 값이 `true`라 신규 계약 테스트가 실패함을 확인했다.
- 구현 완료: 공용 `isAdministratorGrade`/`userCredentialsVisibleFor`를 추가해 grade 0/1 자체 비밀번호를 `firstAdmin`으로 분류하고 사용자관리 ID/PW를 표시한다. PC 시리얼 인증은 `regular` 로그인에만 수행한다.
- 핵심 정책 재검증 완료: 관리자 로그인 분류/표시 및 시리얼 인증 정책 테스트 10건 통과, 변경 파일 편집기 진단 없음.
- 사용자관리 표시 테스트 추가: `showCredentials=true`일 때 ID/PW 헤더와 실제 사용자 ID/비밀번호 값이 렌더링되는지 검증한다.
- 사용자관리 표시 focused 검증: fixture ID 기대값을 실제 `one`으로 맞춘 뒤 ID/PW 헤더와 값 렌더링 테스트 통과.
- 관련 통합 테스트 완료: 세션/시리얼/사용자관리/startup 로그인/메뉴 정책 총 29건 통과, 최종 변경 파일 편집기 진단 없음.
- 버전 편집 완료: 관리자 로그인 및 자격정보 표시 정책 개선이므로 PATCH 증가로 `1.3.25`에서 `1.3.26`으로 갱신했다.
- strict analyzer 예정: `C:/Flutter/bin/flutter.bat analyze lib/core/admin_connect_session.dart lib/features/login/application/user_access_service.dart lib/home_page.dart test/admin_connect_session_test.dart test/user_access_service_test.dart test/user_manager_dialog_test.dart`.
- strict analyzer 완료: 위 6개 변경 파일 분석 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.26`, `git diff --check` 통과.
- stage/commit 대상: `admin_connect_session.dart`, `user_access_service.dart`, `home_page.dart`, 관련 테스트 3개, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `3b4f0ea` (`관리자 계정 표시 및 시리얼 인증 정책 적용`).

## 완료: 품목 저장 데이터내용 이력 누락 수정 v1.3.25
- 사용자 재현: 품목 2번 `황치즈쿠키`를 `황치즈쿠키+`로 변경해 저장한 뒤 조회/이력 → 데이터내용 이력 조회에서 변경 당일 `2026-08-19`를 조회해도 결과가 없다.
- 원인 확인: 조회 DAO는 레거시와 동일하게 `BM_CONTENT_SAVE_LOG`를 날짜/거래처로 조회하지만 현재 `ItemManagerSaveDAO.saveSql` transaction에는 이력 INSERT가 전혀 없다. 레거시는 수정/신규 행별 표시 컬럼명과 최종 값, 사용자/거래처/라벨/IP를 `BM_CONTENT_SAVE_LOG`에 저장한다.
- 재현 테스트 추가: 품목 저장 SQL이 수정 행과 신규 행의 이력을 같은 transaction에서 `BM_CONTENT_SAVE_LOG`에 기록하는 계약을 검증한다.
- 구현 완료: save command에 사용자/거래처/라벨/IP 이력 context와 행별 레거시 `품목\n주원료\n...` 컬럼/최종값 wire를 추가했다. DAO는 수정 상태 `1`, 신규 상태 `0` 이력을 품목 변경과 같은 transaction에서 `BM_CONTENT_SAVE_LOG`에 INSERT한다.
- 첫 focused 재검증 완료: 실패했던 이력 INSERT SQL 계약 테스트 통과.
- 인접 테스트 결과: item manager save/draft 37건 중 기존 파라미터 key 목록 테스트만 이력 context 6개 추가로 실패했고 나머지 36건 및 편집기 진단은 통과했다.
- 테스트 보강: 확장 key 목록과 null context를 반영하고 한글/특수문자/줄바꿈 이력 XML wire 및 사용자 context 전달을 검증한다.
- 인접 재검증 완료: `item_manager_save_dao_test.dart`, `item_manager_draft_test.dart` 총 38건 통과.
- 실제 서버 compile probe 완료: 현재 저장 연결 정보로 `BM_CONTENT_SAVE_LOG` 스키마를 조회하고 변경된 전체 save SQL을 `IF 1=0` 블록에서 컴파일했으며 통과했다. 데이터 변경은 없고 임시 probe 테스트는 제거했다.
- diff/레거시 재검토: `GDS_NO=0`, 수정/신규 `SAVE_STATUS=1/0`, 전체 최종 행 wire 기록이 레거시와 일치한다. 현행 품목 모델의 최종 원본이 sheet payload이므로 `ELEMENT_DATA`에는 `ELEMENT_SHEET`를 보존한다.
- draft 테스트 보강: DB baseline 값과 수정값을 함께 사용해 `품목`, `주원료`, 전체 컬럼 순서 및 값 내부 개행 제거를 검증한다.
- 통합 focused 검증 완료: save DAO/draft와 `fortune_table_test.dart` 총 107건 통과.
- 버전 편집 완료: 데이터내용 이력 누락 수정이므로 PATCH 증가로 `1.3.24`에서 `1.3.25`로 갱신했다.
- strict analyzer 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/item/domain/item_manager_save_command.dart lib/features/item/domain/item_manager_draft.dart lib/features/item/application/item_manager_save_service.dart lib/features/item/data/item_manager_save.dart lib/home_page_manager.dart test/item_manager_save_dao_test.dart test/item_manager_draft_test.dart`.
- strict analyzer 완료: 위 7개 변경 파일 분석 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.25`, `git diff --check` 통과.
- stage/commit 대상: 품목 save command/draft/service/DAO, `home_page_manager.dart`, save/draft 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `7834912` (`품목 저장 데이터내용 이력 기록`).

## 완료: 관리자 복사 진행바 표시 v1.3.24
- 사용자 요청: 약 45초 걸리는 관리자 복사 동안 진행 상태를 시각적으로 표시한다.
- 구현 완료: 기존 `_writeBusy` 수명에 맞춰 footer 왼쪽에 `복사 진행 중...` 문구와 indeterminate `LinearProgressIndicator`를 표시한다. 기존 취소/복사 버튼 위치와 footer 높이는 유지하며 복사 중 입력 차단도 그대로 사용한다.
- 테스트 추가: `Completer`로 복사를 대기시켜 작업 중 진행바 표시/취소 버튼 비활성화와 완료 후 진행바 제거를 검증한다.
- 첫 focused 검증: 신규 진행바 테스트는 통과했으나 dialog 전체 테스트에서 기존 `대상 지점 없음` 오류 dialog를 기다리는 동안 indeterminate bar가 계속 동작해 `pumpAndSettle` timeout을 재현했다.
- 오류 경로 보완: 복사 실패가 확정되면 `_writeBusy`와 진행바를 먼저 종료한 뒤 오류 dialog를 표시하도록 변경했다. 성공 경로는 `onCommitted` 완료까지 진행 상태를 유지한다.
- 재검증 완료: 신규 진행바/대상 지점 없음 focused 2건과 관리자 복사 dialog/DAO 전체 12건 통과, 변경 파일 편집기 진단 없음.
- 버전 편집 완료: 사용자에게 보이는 호환 UI 개선이므로 PATCH 증가로 `1.3.23`에서 `1.3.24`로 갱신했다.
- strict analyzer 완료: `C:/Flutter/bin/flutter.bat analyze lib/features/admin_copy/presentation/admin_copy_dialog.dart test/admin_copy_dialog_test.dart` 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 빌드 블로커 해결: 실행 중이던 workspace Debug `label_manager.exe`가 산출물을 잠가 첫 빌드가 `LNK1168`로 실패했다. 해당 앱 프로세스만 종료했다.
- Windows 통합 검증 완료: 잠금 해제 후 동일 `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.24`, `git diff --check` 통과. 진행바가 footer 버튼과 겹치지 않는 widget 위치 계약도 통과했다.
- stage/commit 대상: `lib/features/admin_copy/presentation/admin_copy_dialog.dart`, `test/admin_copy_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `2147fff` (`관리자 복사 진행 상태 표시`).

## 완료: 관리자 품목 복사 중 복원 DB ODBC 927 오류 수정 v1.3.23
- 사용자 재현: system 계정의 파일/관리 → 관리자 복사에서 `80*60 테스트용`을 `80*60 복사용`으로 품목까지 복사하면 `labelmanager_combine` 복원 중 ODBC 예외가 표시된다.
- 로그 확인: `.tmp/log/app_2026-09-03_14-33-44.log`의 실행본은 `v1.3.22`; 현재 연결 DB는 `labelmanager_combine2`이며 관리자 복사 transaction이 SQLSTATE `42000`, native `927`, `데이터베이스 'labelmanager_combine'을(를) 열 수 없습니다. 복원 중입니다.`로 rollback됐다.
- 원인 확인: 읽기 전용 `OBJECT_DEFINITION` probe 결과 서버의 `proc_copy_item_of_market`만 원본 market 행을 `[labelmanager_combine].[its_labelmanager].[BM_ITEM_OF_MARKET]`에서 읽도록 구 DB 이름을 하드코딩했다. 레거시도 같은 프로시저를 호출하지만 현재 연결 DB 기준 복사를 보장하지 못한다.
- 재현 테스트 추가: 품목/컬럼내용/지점 매핑의 레거시 순서는 유지하되 `proc_copy_item_of_market`과 `[labelmanager_combine]` 의존을 금지하고 현재 DB `BM_ITEM_OF_MARKET` 사용을 요구한다.
- 구현 완료: 결함 프로시저 호출을 서버 정의와 동일한 25개 `BM_ITEM_OF_MARKET` 컬럼 복사 SQL로 대체했다. 원본/대상 품목은 레거시처럼 `RICH_ITEM_ORDER`로 매핑하고 대상 거래처 첫 지점 ID를 저장하되, 원본 market 행은 현재 연결 DB에서 읽는다. 일반 라벨크기 복사와 브랜드 전체 복사에 모두 적용했다.
- 첫 focused 재검증 완료: 결함 프로시저/구 DB 의존 금지와 현재 DB market 행 사용 계약 테스트 통과.
- 테스트 보강 완료: 일반 라벨크기 복사와 브랜드 전체 복사 SQL에 동일 계약을 적용했고 관리자 복사 DAO/dialog 테스트 5건이 통과했다. 변경 파일 편집기 진단 없음.
- 실제 서버 검증 완료: 임시 읽기 전용 `IF 1=0` compile probe로 현재 `labelmanager_combine2`에서 일반 라벨크기/브랜드 복사 SQL의 테이블, 25개 market 컬럼, 문법을 검증했다. DML은 실행하지 않았고 probe 파일은 삭제했다.
- 버전 편집 완료: 호환 가능한 관리자 복사 ODBC 오류 수정이므로 PATCH 증가로 `1.3.22`에서 `1.3.23`으로 갱신했다.
- strict analyzer 완료: `C:/Flutter/bin/flutter.bat analyze lib/features/admin_copy/data/admin_copy_dao.dart test/admin_copy_dao_test.dart` 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 실제 재현 rollback 검증 완료: 로그의 source `8114`, target `8139`, target market `1`로 전체 일반 복사 SQL을 실행해 성공 응답을 확인하고 같은 batch에서 rollback했다. 기존 약 43초 후 ODBC 927이 발생하던 경로가 약 45초에 정상 완료됐으며 데이터 변경은 남기지 않았다. 임시 probe 파일은 삭제했다.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.23`, `git diff --check` 통과.
- stage/commit 대상: `lib/features/admin_copy/data/admin_copy_dao.dart`, `test/admin_copy_dao_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `69fceab` (`관리자 품목 복사 구 DB 의존 제거`).

## 완료: 출력내용 미리보기 열린 상태의 품목명 편집 build 예외 수정 v1.3.22
- 사용자 재현: 품목관리의 `출력내용 미리보기` 탭을 연 상태에서 항목명 편집에 들어가면 `_blockItemDraftContextChange()`가 build 중 `ScaffoldMessenger.showSnackBar()`를 호출해 미리보기 오류와 멈춤이 발생한다.
- 원인 확인: 신규 테스트가 `_ItemPreviewPanel.didUpdateWidget()` → `_replaceTabsPreservingSelection()` → `_handleTabSelection()` → `showSnackBar()`의 동일 build 예외로 실패했다. 탭 재생성 후 기존 출력 탭의 programmatic 재선택이 사용자 탭 guard를 다시 호출했다.
- 구현 완료: `_replaceTabsPreservingSelection()`이 탭 선택을 복원하는 동안 `_handleTabSelection()`을 억제해 편집 commit과 차단 알림이 실제 사용자 탭 선택에서만 실행되도록 했다.
- 검증 완료: 동일 재현 테스트와 품목 미리보기의 선택 행 변경/사용자 탭 차단/출력 줌 유지/최초 width-fit 인접 테스트 총 5건 통과.
- 버전 편집 완료: 호환 가능한 품목 미리보기 UI 예외 수정이므로 PATCH 증가로 `1.3.21`에서 `1.3.22`로 갱신했다.
- 포맷/진단 완료: 변경 Dart 2개 파일 포맷 후 production 13줄/테스트 40줄의 의도한 diff만 남았고 편집기 진단은 없다.
- 재검증 완료: `label_sheet_toolbar_test.dart`의 재현/인접 5건 통과, `C:/Flutter/bin/flutter.bat analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart` 결과 `No issues found`.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.22`, `git diff --check` 통과. 재현 테스트는 framework 예외 없음, guard 미재호출, 출력 탭 콘텐츠 유지를 모두 확인한다.
- stage/commit 대상: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `a02f0df` (`품목 미리보기 편집 중 build 예외 수정`).

## 완료: 품목 블록선택 발행 체크 줌 입력 build 예외 수정 v1.3.21
- 사용자 재현: 품목관리에서 블록선택 발행 체크 시 `LabelSheetZoomToolbar._handleZoomChanged()`의 `TextEditingController.value` 갱신으로 `EditableText setState() or markNeedsBuild() called during build` 예외가 발생한다.
- 실행 확인: 최신 로그 실행본은 `v1.3.20`; debugger 화면의 변경 값은 auto-fit 결과 `220`이고 현재 build widget은 `LayoutBuilder`다.
- 원인 확인: toolbar와 sibling `LayoutBuilder`가 같은 controller를 공유하고 builder에서 220%로 변경하는 테스트가 첨부 화면과 동일한 `EditableText`/`LayoutBuilder` framework assertion으로 실패했다.
- 구현 완료: toolbar listener는 controller 변경을 즉시 `TextEditingController`에 쓰지 않고 한 frame에 한 번으로 합쳐 post-frame에 최신 줌 값을 반영한다. idle 상태 변경도 반영되도록 visual update를 요청한다.
- 검증 완료: 동일 sibling build 재현 테스트 통과, 줌 toolbar/controller 7건, label output auto-fit/줌 유지 2건, 품목 블록선택 발행 체크와 dirty 차단 2건 통과. 변경 파일 편집기 진단 없음.
- 버전 편집 완료: 호환 가능한 공용 줌 입력 동기화 오류 수정이므로 PATCH 증가로 `1.3.20`에서 `1.3.21`로 갱신했다.
- strict analyzer 완료: `C:/Flutter/bin/flutter.bat analyze lib/widgets/label_sheet_zoom.dart test/label_sheet_zoom_toolbar_test.dart` 결과 `No issues found`.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.21`, `git diff --check` 통과.
- stage/commit 대상: `lib/widgets/label_sheet_zoom.dart`, `test/label_sheet_zoom_toolbar_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 범위 밖 `lib/core/app.dart`와 lockfile 4개는 제외한다.
- 구현 커밋: `4b8de1b` (`품목 발행 체크 줌 입력 예외 수정`).

## 완료: 검색출력 발행 줌 auto-fit build 예외 수정 v1.3.20
- 사용자 재현: 파일관리 → 검색출력에서 발행 시 `setState() or markNeedsBuild() called during build` 예외가 발생한다.
- 실행 로그 확인: `.tmp/log/app_2026-08-17_20-30-19.log`의 실행본은 `v1.3.18`이며, 검색 발행 직전 예외 stack은 `LabelOutputPreview`의 `LayoutBuilder` → `applyInitialAutoFit()` → 줌 toolbar `TextEditingController` 갱신 → `EditableText.markNeedsBuild()` 순서다.
- 기각한 가설: `LabelPrintSessionController.replaceRowsForIssue()`/`beginIssue()` 동기 알림을 page build 중 재현한 테스트는 통과했다. 해당 테스트와 가설은 제거했다.
- 원인 확인: 실제 출력 wrapper처럼 `LabelOutputPreview(autoFitWidth: true)`와 외부 줌 toolbar가 controller를 공유하는 테스트가 production 로그와 동일한 `EditableText`/`LayoutBuilder` assertion으로 실패했다.
- 구현 완료: `LabelOutputPreview`가 LayoutBuilder에서 계산한 최신 최초 auto-fit 값과 동일 controller를 보관하고 첫 frame 종료 후 적용한다. widget/controller가 교체된 callback은 적용하지 않으며 기존 controller 동기 API 계약은 유지한다.
- 검증 완료: 신규 auto-fit 재현 테스트 통과, `label_print_session_test.dart`와 줌 controller/toolbar 테스트 전체 27건 및 scale output 인접 테스트 1건 통과, 변경 파일 편집기 진단 없음.
- 버전 편집 완료: 호환 가능한 검색 발행 UI 오류 수정이므로 PATCH 증가로 `1.3.19`에서 `1.3.20`으로 갱신했다.
- strict analyzer 완료: `C:/Flutter/bin/flutter.bat analyze lib/widgets/label_output_preview.dart test/label_print_session_test.dart` 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE FileVersion/ProductVersion 모두 `1.3.20`, `git diff --check` 통과.
- 동작 기준: 검색출력 발행으로 출력 미리보기가 교체돼도 LayoutBuilder build가 끝난 뒤 최초 auto-fit을 적용하며, 줌 입력과 미리보기 배율은 예외 없이 동기화된다.
- 커밋 대상: `label_output_preview.dart`, 신규 회귀 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 범위 밖 lockfile 변경은 제외한다.
- null controller의 불필요한 callback 예약을 제거한 뒤 focused 재현 테스트 재통과, strict analyzer `No issues found`, 최종 `/WX` Windows Debug 재빌드 성공을 확인했다.
- 기능 커밋: `9b29e9d` (`검색출력 발행 줌 예외 수정`).

## 완료: 품목별 정보 편집 진입 build 중 알림 예외 수정 v1.3.19
- 사용자 재현: 설정 → 품목별 정보 편집 진입 시 `ItemInfoController.setLoading()`의 `notifyListeners()`에서 `setState() or markNeedsBuild() called during build` 예외가 발생한다.
- 원인 확인: 실제 `AnimatedBuilder` 부모 구조를 재현한 테스트가 `_dirty` framework assertion으로 실패했다. overlay가 `ItemInfoDialogContent`를 구성하는 동안 자식 `initState()`가 동기 `_load()`를 시작하고 `setLoading(true)`로 같은 builder에 알린다.
- 구현 완료: controller listener는 기존처럼 즉시 등록하되 초기 `_load()`만 첫 frame 종료 후 시작하고, frame 전에 dispose되면 실행하지 않는다.
- 검증 완료: 신규 overlay 재현 테스트와 `item_info_dialog_test.dart` 전체 4건 통과, 변경 Dart 파일 편집기 진단 없음.
- 버전 편집 완료: 호환 가능한 진입 오류 수정이므로 PATCH 증가로 `1.3.18`에서 `1.3.19`로 갱신했다.
- strict analyzer 완료: `C:/Flutter/bin/flutter.bat analyze lib/features/item/presentation/item_info_dialog.dart test/item_info_dialog_test.dart` 결과 `No issues found`.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE FileVersion/ProductVersion 모두 `1.3.19`, `git diff --check` 통과.
- 동작 기준: 설정 → 품목별 정보 편집 overlay 구성 중에는 controller가 알리지 않으며, 첫 frame 이후 로딩 상태와 조회 결과를 정상 반영한다.
- 커밋 대상: `item_info_dialog.dart`, 신규 회귀 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 기존 staged `startup_dialog.dart`와 범위 밖 lockfile 변경은 제외한다.
- 기능 커밋: `9fee4b4` (`품목별 정보 편집 진입 예외 수정`).

## 구현 완료·실물 확인 대기: Godex 역상 흰 글자 분산 외곽 열 보상 v1.3.18
- 사용자 실물 `.tmp/IMG_20260817_0013.png`: v1.3.17 워터마크, 양호한 표·선·일반 문자를 확인했다. 1x보다 획은 복구됐지만 역상 흰 글자는 여전히 불규칙하게 메워져 추가 개선이 필요하다.
- 최신 로그 `.tmp/log/app_2026-08-17_20-15-32.log`: 8배 원본 3328px, 4방향 bridge 595px, 총 knockout 3923px, 실패 0이다. 내부 간격 연결만으로는 검은 바탕의 열 번짐이 흰 외곽을 잠식하는 현상을 해결하지 못해 bridge를 폐기한다.
- 수정 완료: 8배/coverage 48 원본 mask는 유지하고, 원본 외곽에 상하좌우로 인접한 검은 픽셀 중 좌표 패턴으로 균등 분산된 4분의 1만 white relief로 합성한다. 추가 dot은 `nativeTextWhiteEdgeReliefPixels`로 집계한다.
- 회귀 방지: relief는 연속 외곽을 만들지 않으며 원본 glyph weight와 내부는 변경하지 않는다. 표·선·일반 문자, 검은 글자 printer DC, font/fit/좌표는 변경하지 않았다.
- 진단·버전: `supersample8xCoverage48EdgeRelief25`, 워터마크와 앱 버전을 `v1.3.18`로 갱신했다.
- 수정 직후 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. 다음으로 출력 회귀 테스트, 편집기 진단, EXE 버전과 최종 diff를 확인한다.
- 검증 완료: 출력 관련 4개 테스트 파일 통과, C++/pubspec/인수인계 편집기 진단 없음, 스타일 정리 후 `/WX` Windows Debug 재빌드 성공.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.18`, `git diff --check` 통과. 변경은 역상 흰 mask의 25% 분산 edge relief, 진단·워터마크·버전과 인수인계뿐이다.
- 판별 기준: v1.3.18 로그에서 `nativeTextWhiteBitmapDrawn=2`, `nativeTextWhiteEdgeReliefPixels>0`, `nativeTextFailed=0`이어야 한다. knockout은 원본 3328px보다 증가하되 연속 폐쇄의 4412px보다 작아야 하며, 실물은 볼드화 없이 흰 외곽 잠식이 줄어야 한다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.

## 구현 완료·실물 확인 대기: Godex 역상 흰 글자 방향성 단절 연결 v1.3.17
- 사용자 실물 `.tmp/IMG_20260817_0012.png`: v1.3.16 워터마크, 양호한 표·선·일반 문자를 확인했다. 볼드화는 사라졌지만 역상 흰 글자의 획이 심하게 탈락해 가독성이 나빠졌다.
- 최신 로그 `.tmp/log/app_2026-08-17_18-38-15.log`: `device1xMonochromeHinted`, knockout 2482px, 실패 0이다. 8배 원본 3328px보다 846px가 탈락해 1x monochrome hinting을 폐기한다.
- 수정 완료: 8배/coverage 48 원본 mask로 복귀하고, 원본 픽셀 사이의 정확한 1-dot 간격만 수평·수직·두 대각선 방향으로 연결했다. 추가 dot은 `nativeTextWhiteBridgedPixels`로 집계한다.
- 회귀 방지: bridge 후보는 원본 mask의 반대편 두 점 사이에만 생성돼 외곽으로 확장되지 않는다. 표·선·일반 문자, 검은 글자 printer DC, font weight/fit/좌표는 변경하지 않았다.
- 진단·버전: `supersample8xCoverage48Bridge4Way`, 워터마크와 앱 버전을 `v1.3.17`로 갱신했다.
- 메모리: 8배 full-page mask를 복원해 출력 중 약 76MB를 일시 사용한다. OOM 징후가 나타나면 즉시 중단·보고한다.
- 수정 직후 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. 다음으로 출력 회귀 테스트, 편집기 진단, EXE 버전과 최종 diff를 확인한다.
- 검증 완료: 출력 관련 4개 테스트 파일 통과, C++/pubspec/인수인계 편집기 진단 없음, `/WX` Windows Debug 빌드 성공.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.17`, `git diff --check` 통과. 변경은 역상 흰 mask의 8배 원본 복원·4방향 bridge, 진단·워터마크·버전과 인수인계뿐이다.
- 판별 기준: v1.3.17 로그에서 `nativeTextWhiteBitmapDrawn=2`, `nativeTextWhiteBridgedPixels>0`, knockout이 1x의 2482px보다 증가하되 폐쇄 방식의 4412px보다 작고, `nativeTextFailed=0`이어야 한다. 실물은 볼드화 없이 역상 획 결손이 줄어야 한다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 기능 커밋: `95226c5` (`Godex 역상 흰 글자 방향성 단절 연결`).

## 구현 완료·실물 확인 대기: Godex 역상 흰 글자 장치 해상도 힌팅 v1.3.16
- 사용자 실물 `.tmp/IMG_20260817_0011.png`: v1.3.15 워터마크, 양호한 표·선·일반 문자를 확인했다. 역상 흰 글자는 여전히 볼드처럼 뭉쳐 추가 개선이 필요하다.
- 최신 로그 `.tmp/log/app_2026-08-17_18-29-51.log`: 원본 3328px에 폐쇄 1084px가 추가돼 knockout 4412px이다. 원본 대비 약 32.6% 증가한 폐쇄 연산이 남은 볼드화의 직접 원인이라 폐기한다.
- 수정 완료: 흰 글자의 8배 확대·coverage threshold·형태 연산을 모두 제거하고, 최종 203dpi 크기 memory DIB에 `NONANTIALIASED_QUALITY`로 직접 렌더링한다. 장치 픽셀 font hinting으로 원래 weight와 외곽을 보존한다.
- 회귀 방지: 표·선·일반 문자, 검은 글자 printer DC, font/fit/좌표는 변경하지 않았다. 진단을 `device1xMonochromeHinted`, 워터마크와 앱 버전을 `v1.3.16`으로 갱신했다.
- 메모리: 흰 mask DIB가 8배 약 76MB에서 최종 크기 약 1.2MB로 감소해 출력 중 OOM 부담도 제거됐다.
- 수정 직후 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. 다음으로 출력 회귀 테스트, 편집기 진단, EXE 버전과 최종 diff를 확인한다.
- 회귀 검토: 중간 diff에서 힌팅 옵션이 일반 문자 함수에 잘못 적용된 것을 발견해 즉시 `DEFAULT_QUALITY`로 원복했다. 최종 코드는 흰 mask 한 곳만 `NONANTIALIASED_QUALITY`이며 재사용 방지 근거를 주석으로 남겼다.
- 검증 완료: 출력 관련 4개 테스트 파일 통과, C++/pubspec/인수인계 편집기 진단 없음, 옵션 범위 수정 후 `/WX` Windows Debug 재빌드 성공.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.16`, `git diff --check` 통과. 변경은 역상 흰 mask의 장치 해상도 힌팅, 기존 후처리 제거, 진단·워터마크·버전과 인수인계뿐이다.
- 판별 기준: v1.3.16 로그에서 `nativeTextWhiteRender=device1xMonochromeHinted`, `nativeTextWhiteBitmapDrawn=2`, `nativeTextWhiteKnockoutPixels>0`, `nativeTextFailed=0`이어야 한다. 실물은 v1.3.15의 볼드화가 사라지고 표·선·일반 문자가 유지돼야 한다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 기능 커밋: `cfab653` (`Godex 역상 흰 글자 장치 힌팅 적용`).

## 구현 완료·실물 확인 대기: Godex 역상 흰 글자 내부 단절 폐쇄 v1.3.15
- 사용자 실물 `.tmp/IMG_20260817_0010.png`: v1.3.14 워터마크, 양호한 표·선·일반 문자를 확인했다. 역상 흰 글자는 개선이 아니라 전체가 볼드처럼 뭉개졌다.
- 최신 로그 `.tmp/log/app_2026-08-17_18-08-56.log`: 원본 3328px에 확장 3293px가 추가돼 knockout이 6621px로 거의 두 배가 됐다. 전방향 1-dot 확장이 외곽 전체를 굵게 만든 원인으로 확정돼 폐기한다.
- 수정 완료: 원본 threshold mask에 3x3 팽창 후 3x3 침식을 적용하는 폐쇄 연산으로 교체했다. 원본 외곽 두께는 복원하고 1-dot 내부 구멍·단절을 닫아 추가된 픽셀만 `nativeTextWhiteClosedPixels`로 집계한다.
- 회귀 방지: 표·선·일반 문자, 검은 글자 printer DC, font/fit/좌표/coverage는 변경하지 않았다. 진단을 `supersample8xCoverage48Close3x3`, 워터마크와 앱 버전을 `v1.3.15`로 갱신했다.
- 수정 직후 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. 다음으로 출력 회귀 테스트, 편집기 진단, EXE 버전과 최종 diff를 확인한다.
- 검증 완료: 출력 관련 4개 테스트 파일 통과, C++/pubspec/인수인계 편집기 진단 없음, `/WX` Windows Debug 빌드 성공.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.15`, `git diff --check` 통과. 변경은 역상 흰 mask 폐쇄 연산·진단, 워터마크·버전과 인수인계뿐이다.
- 판별 기준: v1.3.15 로그에서 `nativeTextWhiteBitmapDrawn=2`, `nativeTextWhiteClosedPixels`가 0 초과이되 v1.3.14 확장 3293px보다 충분히 작고, `nativeTextFailed=0`이어야 한다. 실물은 v1.3.14의 볼드화가 사라지고 역상 글자 내부 단절만 줄어야 한다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 기능 커밋: `13bcf66` (`Godex 역상 흰 글자 내부 단절 보정`).

## 구현 완료·실물 확인 대기: Godex 역상 흰 글자 1-dot 획 보강 v1.3.14
- 사용자 실물 `.tmp/IMG_20260817_0009.png`: v1.3.13 워터마크와 양호한 표·선·일반 문자를 확인했다. 역상 흰 글자는 여전히 획 내부가 점상으로 끊겨 추가 개선이 필요하다.
- 최신 로그 `.tmp/log/app_2026-08-17_18-02-58.log`: `nativeTextWhiteSemiboldApplied=0`, 흰 knockout 3328px, 실패 0이다. 흰 descriptor 2건이 모두 원래 bold여서 v1.3.13의 normal 전용 semibold는 적용되지 않았고 v1.3.12와 mask가 동일했다.
- 수정 완료: font/fit/좌표/coverage는 유지하고, threshold를 통과한 역상 흰 mask에만 상하좌우 1 device-dot 확장을 적용했다. 최종 bitmap의 검은 영역에 실제 추가된 dot만 `nativeTextWhiteExpandedPixels`로 집계한다.
- 무효 경로 정리: v1.3.13 semibold와 적용 건수 진단을 제거하고 normal weight를 `FW_NORMAL`로 복원했다. 현재 역상 2건은 모두 원래 bold라 weight 변경으로 보강하지 않도록 코드에 재사용 방지 근거를 남겼다.
- 회귀 방지: 표·선·일반 문자와 검은 글자 printer DC 경로는 변경하지 않았다. 진단을 `supersample8xCoverage48OrthogonalExpand1`, 워터마크와 앱 버전을 `v1.3.14`로 갱신했다.
- 수정 직후 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. 다음으로 출력 회귀 테스트, 편집기 진단, EXE 버전과 최종 diff를 확인한다.
- 검증 완료: 출력 관련 4개 테스트 파일 통과, C++/pubspec/인수인계 편집기 진단 없음, semibold 제거 후 `/WX` Windows Debug 재빌드 성공.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.14`, `git diff --check` 통과. 변경은 역상 흰 mask 확장·진단, 무효 semibold 제거, 워터마크·버전과 인수인계뿐이다.
- 판별 기준: v1.3.14 로그에서 `nativeTextWhiteBitmapDrawn=2`, `nativeTextWhiteExpandedPixels`와 `nativeTextWhiteKnockoutPixels`가 0 초과, `nativeTextFailed=0`이어야 한다. 실물은 표·선·일반 문자를 유지하면서 역상 흰 획의 끊김이 줄어야 한다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 기능 커밋: `7503f53` (`Godex 역상 흰 글자 획 보강`).

## 구현 완료·실물 확인 대기: Godex 역상 흰 글자 최소 획 굵기 v1.3.13
- 사용자 실물 `.tmp/IMG_20260817_0008.png`: v1.3.12의 8배 mask는 정상 출력됐지만 역상 흰 한글의 가는 획 단절과 점상 거칠기가 여전히 남는다. 표·선·일반 문자는 좋은 상태다.
- 최신 로그 `.tmp/log/app_2026-08-17_17-57-35.log`: DebugLogger 1.3.12, 8배 mask·워터마크 정상, 흰 knockout 3328px, 실패 0이다. 4배 v1.3.11의 3504px보다 흰 dot이 줄어 가는 획 보존에 부족하다. supersampling 증가는 종료한다.
- 수정 완료: 흰 descriptor의 mask font에만 인쇄용 최소 `FW_SEMIBOLD`를 적용했다. 원래 normal은 400→600, 원래 bold는 `FW_BOLD` 700을 유지한다. 8배 coverage, font height, fit, 좌표와 합성 대상은 유지했다.
- 회귀 방지: 표·선·border, final bitmap, 일반 34개 printer DC 문자와 원래 bold 역상 문자는 변경하지 않았다. `nativeTextWhiteSemiboldApplied` 진단을 추가하고 워터마크를 `v1.3.13`으로 갱신했다.
- 버전 편집 완료: 호환 가능한 역상 문자 품질 개선이므로 PATCH 증가로 `1.3.12`에서 `1.3.13`으로 갱신했다.
- 수정 직후 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. 다음으로 출력 회귀 테스트, 진단, EXE 버전과 최종 diff를 확인한다.
- 검증 완료: 출력 관련 4개 테스트 파일 전체 30건 통과, C++/pubspec/인수인계 편집기 진단 없음. 최종 스타일 정리 후 `/WX` Windows Debug 재빌드도 성공했다.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.13`, semibold·워터마크 진단 일치, `git diff --check` 통과. production diff는 흰 normal weight, 적용 건수 진단, 워터마크·버전뿐이다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 판별 기준: v1.3.13 로그에서 흰 descriptor 2건, semibold 적용 건수 0 초과, 실패 0이어야 한다. 실물은 다른 출력과 글자 배치를 유지하면서 역상 normal 한글의 가는 획 연속성과 가독성이 개선돼야 한다.
- 기능 커밋: `8eb52d7` (`Godex 역상 흰 글자 최소 획 굵기 적용`).

## 구현 완료·실물 확인 대기: Godex 역상 흰 글자 8배 윤곽 샘플링 v1.3.12
- 사용자 실물 `.tmp/IMG_20260817_0007.png`: v1.3.11 워터마크는 정상 출력됐지만 역상 흰 글자는 육안상 이전과 차이가 없다. 표·선·일반 문자는 좋은 상태다.
- 최신 로그 `.tmp/log/app_2026-08-17_17-51-42.log`: DebugLogger 1.3.11, 흰 knockout 3504px 중 bridge는 33px(약 0.9%), 실패 0이다. 적용량이 너무 작아 실물 차이가 없으므로 bridge 접근은 종료한다.
- 수정 완료: 흰 descriptor 전용 mask만 4배(최종 dot당 16 sample)에서 8배(64 sample)로 올려 한글 윤곽 coverage 정밀도를 높였다. threshold 48/255 비율과 knockout 대상은 유지하고 효과 없던 bridge 및 관련 진단은 제거했다.
- 회귀 방지: 표·선·border, final bitmap, 일반 34개 printer DC 문자, font/fit/좌표와 흰 mask 합성 대상은 변경하지 않았다. 워터마크와 진단을 `v1.3.12`/`supersample8xCoverage48`로 갱신했다.
- 메모리: full-page 8배 32-bit mask는 출력 중 일시적으로 약 76MB를 사용한다. 현재 환경에서 허용 범위로 판단하되 OOM 징후가 나타나면 즉시 중단·보고한다. 상태: 미검증.
- 버전 편집 완료: 호환 가능한 역상 문자 품질 개선이므로 PATCH 증가로 `1.3.11`에서 `1.3.12`로 갱신했다.
- 수정 직후 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. 실제 DIB 할당은 실물 출력 시 검증하며, 다음으로 자동 회귀 테스트와 진단을 확인한다.
- 검증 완료: 출력 관련 4개 테스트 파일 전체 30건 통과, C++/pubspec/인수인계 편집기 진단 없음, `/WX` Windows Debug 빌드 성공.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.12`, 8배 mask·워터마크 진단 일치, bridge 코드·진단 제거, `git diff --check` 통과. 표·선·border, 일반 문자, knockout 대상 조건은 변경하지 않았다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 판별 기준: v1.3.12 로그는 `supersample8xCoverage48`, 흰 descriptor 2건, 실패 0이어야 한다. 실물에서 다른 출력은 동일하고 역상 한글의 모서리·대각선·내부 획만 더 균일해야 한다.
- 기능 커밋: `787d24d` (`Godex 역상 흰 글자 윤곽 샘플링 향상`).
- 실물 결론: 8배 mask는 오류 없이 적용됐지만 knockout이 3328px로 감소하고 `.tmp/IMG_20260817_0008.png`의 가는 획 품질이 부족해 supersampling 증가는 종료한다.

## 구현 완료·실물 확인 대기: Godex 역상 흰 획 1dot 단절 연결 v1.3.11
- 사용자 실물 `.tmp/IMG_20260817_0006.png`: v1.3.10은 육안상 v1.3.9와 차이가 없고 역상 한글의 내부 획 단절·점상 거칠기가 남는다. 표·선·일반 문자는 좋은 상태다.
- 최신 로그 `.tmp/log/app_2026-08-17_17-44-22.log`: DebugLogger 1.3.10, knockout 3471px로 v1.3.9의 3657px보다 186px(약 5%)만 줄어 threshold 32→48 변화가 실물에 작게 반영됐다. 단순 threshold 조정은 종료한다.
- 수정 완료: coverage 48의 강한 흰 mask 외곽은 유지하고, coverage 16 이상인 약한 pixel 중 원본 강한 mask가 좌우 또는 상하로 모두 이어진 1dot 내부 공백만 한 번 연결한다. 새 pixel을 다음 연결에 재사용하지 않아 연쇄 팽창하지 않는다.
- 회귀 방지: 흰 descriptor 전용 mask 후처리만 변경하며 표·선·border, 일반 34개 printer DC 문자, font/fit/좌표는 그대로 유지한다. `nativeTextWhiteBridgePixels` 진단을 추가했다.
- 사용자 추가 요청: 반복 실물 출력의 버전 구분을 위해 임시 워터마크를 허용했다. v1.3.11은 역상 검정 행을 피하고 라벨 우하단에 작은 `v1.3.11` 투명 배경 텍스트를 별도 printer DC로 출력하며 진단에 watermark 버전을 남긴다. 기존 descriptor와 bitmap 내용은 변경하지 않는다.
- 워터마크 구현 완료: 우하단 2dot 안쪽에 높이 7dot `v1.3.11`을 별도 printer DC로 출력하고 `printWatermark=v1.3.11`을 기록한다. 워터마크 실패 시 테스트 출력 자체를 실패 처리한다.
- 버전 편집 완료: 호환 가능한 역상 문자 보완이므로 PATCH 증가로 `1.3.10`에서 `1.3.11`로 갱신했다.
- 첫 워터마크 포함 `/WX` 빌드는 `SIZE.cx/cy`의 `LONG`과 좌표 `int`의 `std::max` 타입 불일치로 실패했다. 측정 크기를 명시적으로 `int` 변환한 뒤 동일 `/WX` 빌드 재실행에 성공했다.
- 검증 완료: 출력 관련 4개 테스트 파일 전체 30건 통과, C++/pubspec/인수인계 편집기 진단 없음. 최종 스타일 정리 후 `/WX` Windows Debug 재빌드도 성공했다.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.11`, bridge·watermark 진단과 표시 문자열 일치, `git diff --check` 통과. 기존 표·선·border와 일반 문자 렌더 본문은 변경하지 않았다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 판별 기준: v1.3.11 로그에서 흰 descriptor 2건, bridge pixel 0 초과, 실패 0이어야 한다. 실물에서 외곽 굵기·자간은 v1.3.10과 같고 제3·9행 흰 획 내부의 1dot 단절만 줄어야 한다.
- 기능 커밋: `2bee561` (`Godex 역상 흰 획 연결 및 테스트 워터마크 추가`).
- 실물 결론: bridge는 33px만 적용돼 `.tmp/IMG_20260817_0007.png`에서 차이가 없었다. bridge 접근은 종료하고 워터마크만 다음 테스트에 유지한다.

## 구현 완료·실물 확인 대기: Godex 역상 흰 글자 edge 정리 v1.3.10
- 사용자 실물 `.tmp/IMG_20260817_0005.png`: v1.3.9에서 제3·9행 역상 흰 글자는 이전보다 개선됐으나 낮은 coverage edge까지 흰 dot으로 확정돼 획 외곽과 모서리가 거칠고 일부 글자가 뭉쳐 보인다. 표·선·일반 문자는 좋은 상태다.
- 최신 로그 `.tmp/log/app_2026-08-17_17-30-29.log`: DebugLogger 1.3.9, 흰 bitmap descriptor 2건, knockout 3657px, 전체 문자 36건, 실패 0으로 분리 합성이 정상 적용됐다.
- 수정 완료: 흰 4배 mask의 평균 coverage 기준만 32(12.5%)에서 48(18.75%)로 올리고 진단을 `supersample4xCoverage48`로 갱신했다. 렌더·fit·좌표·final bitmap·border 및 일반 printer DC 문자는 변경하지 않았다.
- 버전 편집 완료: 호환 가능한 역상 문자 edge 조정이므로 PATCH 증가로 `1.3.9`에서 `1.3.10`으로 갱신했다.
- 검증 완료: 출력 관련 4개 테스트 파일 전체 30건 통과, C++/pubspec/인수인계 편집기 진단 없음, `/WX` Windows Debug 빌드 성공.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.10`, 상수·진단 모두 coverage 48로 일치, `git diff --check` 통과. production diff는 threshold·진단·버전뿐이다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 판별 기준: v1.3.10 로그는 `supersample4xCoverage48`, 흰 descriptor 2건, knockout 0 초과, 실패 0이어야 한다. 실물은 제3·9행 흰 획의 연속성은 유지하면서 외곽 돌출과 뭉침이 줄고 나머지는 v1.3.9와 같아야 한다.
- 기능 커밋: `19ff26f` (`Godex 역상 흰 글자 외곽 정리`).
- 실물 결론: knockout은 186px 감소했지만 `.tmp/IMG_20260817_0006.png`에서 육안상 차이가 없어 threshold 단독 조정은 종료한다.

## 구현 완료·실물 확인 대기: Godex 역상 흰 글자 전용 bitmap knockout v1.3.9
- 사용자 실물 `.tmp/IMG_20260817_0004.png`: v1.3.8도 제3·9행 역상 흰 글자의 점상·획 손실이 육안상 개선되지 않았고, 표·선·일반 문자는 좋은 상태다.
- 최신 로그 `.tmp/log/app_2026-08-17_17-22-53.log`: DebugLogger 1.3.8, `nativeTextWhitePathDrawn=2`, fallback 0, 실패 0으로 glyph path가 정확히 두 descriptor에 정상 적용됐다. printer DC에서 흰 글자를 후처리하는 방식 자체를 종료한다.
- 새 원인/방식: GoDEX driver가 먼저 출력된 검정 raster 위에 별도 흰 vector/path를 합성할 때 glyph edge를 안정적인 단색 dot으로 만들지 못한다. 흰 descriptor만 4배 coverage mask로 렌더하고 final 1:1 bitmap의 검정 배경에 순수 흰 dot으로 knockout한 뒤 한 번에 전송한다.
- 회귀 방지 범위: 검정 등 일반 34개 문자는 v1.3.6의 printer DC `DrawTextW`를 그대로 유지한다. 표·선·border 생성/좌표와 final bitmap 크기는 바꾸지 않으며, 흰 mask가 있는 검정 픽셀만 변경한다. 과거 전체 텍스트 supersample/threshold 방식은 재사용하지 않는다.
- 구현 완료: 흰 descriptor만 4배 memory DIB의 검정 mask에 `DEFAULT_QUALITY`로 렌더하고 평균 coverage 12.5% 이상인 final dot을 순수 흰색으로 만든다. 원래 final bitmap이 검정 계열인 픽셀만 변경한다. printer DC 일반 문자 루프는 흰 descriptor를 건너뛴다.
- 진단 갱신: `nativeTextWhiteRender=supersample4xCoverage32`, `nativeTextWhiteBitmapDrawn`, `nativeTextWhiteKnockoutPixels`, split mapping/composite로 실제 경로를 확인한다.
- 버전 편집 완료: 호환 가능한 역상 문자 출력 수정이므로 PATCH 증가로 `1.3.8`에서 `1.3.9`로 갱신했다.
- 첫 `/WX` Windows Debug 빌드는 mask `fill_n`의 `int`→`uint8_t` 축소 경고 C4244를 오류 처리해 실패했다. 초기화 값을 `uint8_t{0}`으로 명시한 뒤 동일 `/WX` 빌드 재실행에 성공했다.
- 검증 완료: 출력 관련 4개 테스트 파일 전체 30건 통과, C++/pubspec/인수인계 편집기 진단 없음, `/WX` Windows Debug 빌드 성공.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.9`, 실패한 opaque/path 흰 후처리 진단 제거, `git diff --check` 통과. 기존 `ComposeFinalDeviceBitmap`, border 병합/좌표, 검정 문자 렌더 본문은 변경하지 않았다.
- 판별 기준: v1.3.9 로그에서 흰 bitmap descriptor 2건, 전체 native text 36건, 흰 knockout pixel 0 초과, 실패 0이어야 한다. 실물에서 표·선·일반 문자는 v1.3.8과 같고 제3·9행 흰 획의 연속성과 가독성만 개선돼야 한다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 기능 커밋: `b6fc0d4` (`Godex 역상 흰 글자 비트맵 합성 적용`).
- 실물 결론: `.tmp/IMG_20260817_0005.png`에서 역상 글자 개선은 확인됐으나 coverage 32의 edge 과확장으로 외곽 정리가 더 필요하다. 분리 합성 구조는 유지한다.

## 구현 완료·실물 확인 대기: Godex 역상 흰 glyph outline 출력 v1.3.8
- 사용자 실물 `.tmp/IMG_20260817_0003.png`: v1.3.7은 제3·9행 역상 흰 글자의 점상·획 손실이 육안상 v1.3.6과 차이가 없다.
- 최신 로그 `.tmp/log/app_2026-08-17_17-16-14.log`: DebugLogger 1.3.7, `nativeTextOpaqueBlackBackground=2`, 실패 0으로 정확히 두 역상 descriptor에 opaque 경로가 적용됐다. 따라서 background mode 원인 가설은 기각한다.
- 새 원인/방식: printer DC의 antialiased 흰 `DrawTextW`가 검정 raster 위에서 회색 edge를 단색 dot으로 안정적으로 제거하지 못한다. 흰 descriptor만 GDI TrueType glyph outline path로 변환하고 `WHITE_BRUSH`로 내부를 채워 회색 AA 없이 출력한다.
- 수정 완료: 흰 descriptor는 `BeginPath`/`DrawTextW`/`EndPath` 후 실제 path point가 있을 때 `WHITE_BRUSH`로 `FillPath`한다. path 생성·채움 실패 시 기존 직접 `DrawTextW`로 fallback한다. 검정 등 다른 문자의 호출문, font/fit/좌표, final bitmap·border는 그대로 유지했다.
- 진단 추가: `nativeTextWhiteRender=filledGlyphPath`, `nativeTextWhitePathDrawn=<성공 건수>`, `nativeTextWhitePathFallback=<fallback 건수>`로 실제 GoDEX printer DC 지원 여부를 확인한다.
- 버전 편집 완료: 호환 가능한 역상 문자 출력 수정이므로 PATCH 증가로 `1.3.7`에서 `1.3.8`로 갱신했다.
- 검증 완료: 출력 관련 4개 테스트 파일 전체 30건 통과, C++/pubspec/인수인계 편집기 진단 없음, `/WX` Windows Debug 빌드 성공.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.8`, 실패한 v1.3.7 opaque 진단 제거, `git diff --check` 통과. 실제 GoDEX path 지원과 품질은 v1.3.8 실물 출력으로 확인해야 한다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 판별 기준: v1.3.8 로그에서 흰 path 성공 2건/fallback 0건이어야 하며, 같은 실물에서 일반 문자는 유지되고 제3·9행 흰 glyph 내부의 점상 잔여와 획 단절이 줄어야 한다.
- 기능 커밋: `46f16c6` (`Godex 역상 흰 글자 윤곽 출력 적용`).
- 실물 결론: path 성공 2건/fallback 0건은 확인됐지만 `.tmp/IMG_20260817_0004.png`에서 육안상 차이가 없어 printer DC 흰 글자 후처리 접근은 종료한다.

## 구현 완료·실물 확인 대기: Godex 역상 흰 글자 가독성 개선 v1.3.7
- 사용자 실물 `.tmp/IMG_20260817_0002.png`: v1.3.6 printer DC 직접 출력으로 일반 문자는 전반적으로 개선됐으나 제3·9행 검정 배경의 흰 글자는 획 내부가 점상으로 남아 가독성이 낮다.
- 최신 로그 `.tmp/log/app_2026-08-17_17-06-56.log`: DebugLogger 1.3.6, `nativeTextComposite=printerDcAfterBitmap`, 36개/558자, 실패 0으로 새 직접 출력 경로 적용을 확인했다.
- 원인 가설: 흰 글자도 `TRANSPARENT` 배경으로 그려 printer driver가 먼저 전송된 검정 raster를 안티앨리어싱 합성 배경으로 안정적으로 참조하지 못한다. 과거 전체 문자 `NONANTIALIASED_QUALITY`는 계단·획 단절을 악화시켜 폐기됐으므로 재사용하지 않는다.
- 수정 완료: 정확히 흰색인 text descriptor의 실제 `DrawTextW` 호출에만 `OPAQUE` background mode와 `BLACK` background color를 적용하고 즉시 이전 GDI 상태로 복원한다. `DEFAULT_QUALITY`, font/fit/좌표, 검정 등 다른 문자와 final bitmap·border는 변경하지 않았다.
- 진단 추가: `nativeTextBackground=opaqueBlackForWhiteText`, `nativeTextOpaqueBlackBackground=<적용 건수>`로 실제 역상 전용 경로를 확인한다.
- 버전 편집 완료: 호환 가능한 역상 문자 품질 수정이므로 PATCH 증가로 `1.3.6`에서 `1.3.7`로 갱신했다.
- 검증 완료: 출력 관련 4개 테스트 파일 전체 30건 통과, C++/pubspec/인수인계 편집기 진단 없음, `/WX` Windows Debug 빌드 성공. 일반 descriptor의 GDI 상태를 전혀 변경하지 않도록 흰색 분기 안으로 좁힌 후 `/WX` 재빌드도 성공했다.
- 최종 확인: Debug EXE FileVersion/ProductVersion 모두 `1.3.7`, 폐기한 `NONANTIALIASED_QUALITY` 미재도입, `git diff --check` 통과. 실물은 v1.3.7로 같은 라벨을 재출력해 확인해야 한다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 판별 기준: v1.3.7 로그에서 opaque 역상 descriptor 수가 확인되어야 하며, 같은 라벨 실물에서 제3·9행 흰 글자의 점상 잔여가 줄고 일반 문자는 v1.3.6과 동일해야 한다.
- 기능 커밋: `95ae3b0` (`Godex 역상 흰 글자 가독성 개선`).
- 실물 결론: opaque 경로 2건 적용은 확인됐지만 `.tmp/IMG_20260817_0003.png`에서 육안상 차이가 없어 이 접근은 종료한다.

## 구현 완료·실물 확인 대기: Godex G500 한글 텍스트 출력 품질 복원 v1.3.6
- 사용자 실물 사진 `.tmp/IMG_20260817_0001.png`: 표와 선은 정상이나 작은 한글 획이 끊기고 거칠며, 검정 배경의 흰 한글도 획 손실이 보인다.
- 최신 로그 `.tmp/log/app_2026-08-17_16-49-14.log`: DebugLogger 1.3.5, `nativeTextRaster=supersample4xAdaptiveThreshold`, 36개/558자 모두 현재 memory DIB 텍스트 경로로 출력되어 미적용 문제는 아니다.
- 기술 확인: Microsoft GDI 문서상 ClearType은 프린터에서 지원되지 않는다. 현재 4배 antialias 렌더를 앱에서 다시 1bit adaptive threshold로 양자화하는 과정이 203dpi의 작은 한글 edge를 소실시키므로 추가 threshold 조정은 반복하지 않는다.
- 수정 완료: `label_bitmap_print_channel.cpp`의 텍스트만 v1.0.63 계열 printer DC `DrawTextW` 직접 출력으로 복원했다. 표·배경·barcode·현재 final-device bitmap 및 1dot border 경로는 유지했고, 이후 회귀가 확인된 `lfWidth` 장평 압축 대신 현재 uniform-height fit과 오른쪽 1dot overhang을 유지했다. v1.3.5 supersample/threshold 구현은 재사용 방지 설명과 함께 비활성화했다.
- 진단 갱신: `nativeTextRaster=printerDcDrawTextW`, `nativeTextMapping=anisotropicPrinterDc`, `nativeTextComposite=printerDcAfterBitmap`, `fontQuality=DEFAULT_QUALITY`, `fontOutputPrecision=OUT_DEFAULT_PRECIS`로 실제 경로를 식별한다.
- 버전 편집 완료: 호환 가능한 출력 품질 수정이므로 PATCH 증가로 `1.3.5`에서 `1.3.6`으로 갱신했다.
- 첫 `/WX` Windows Debug 빌드는 실행 중인 Debug EXE 잠금으로 `LNK1168` 실패했다. 해당 workspace 산출물 PID 11956만 `CloseMainWindow()`로 정상 종료 후 동일 빌드 재실행에 성공했다.
- 출력 회귀 검증 완료: `label_sheet_print_job_test.dart`, `label_print_pipeline_test.dart`, `label_print_dispatcher_test.dart`, `raw_printer_win32_test.dart` 전체 30건 통과.
- 최종 검증 완료: C++/pubspec 편집기 진단 없음, `/WX` Windows Debug 빌드 성공, Debug EXE FileVersion/ProductVersion 모두 `1.3.6`, 활성 printer DC 진단 문자열 확인, `git diff --check` 통과.
- 동작 기준: final bitmap과 1dot border는 v1.3.5 방식을 유지하고 텍스트 descriptor만 bitmap 전송 후 printer DC에 직접 그린다. 다음 사용자 확인은 v1.3.6 로그의 `nativeTextComposite=printerDcAfterBitmap`과 Godex G500 실물 한글 획 품질이다.
- stage/commit 대상: `label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다. 배포 EXE/ZIP/설치 프로그램은 생성하지 않는다.
- 기능 커밋: `d132209` (`Godex 한글 텍스트 출력 품질 복원`).

## 완료: 발행 체크 후 품목 저장 활성화 수정 v1.3.5
- 사용자 재현: 실행 중인 v1.3.4에서 품목관리 테이블의 발행 체크만 했는데 저장 버튼이 활성화된다.
- 최신 로그 `.tmp/log/app_2026-08-17_16-29-22.log`: 체크 직전 draft는 existing 19행, `dirty=false`. 체크 시 행 선택으로 주원료 preview가 갱신된 직후 `editElement requested rowKey=item:722322`가 호출되고 해당 행이 modified로 바뀌며 `dirty=true`가 됐다.
- 원인: FortuneTable checkbox cell도 일반 cell의 상위 pointer handler에서 `_selectRow()`를 호출한다. 발행 체크가 행 선택과 preview 교체까지 유발한다. 기존 회귀 테스트는 폭 40px인 발행 열 밖 `x=60`을 클릭해 실제 checkbox 경로를 검증하지 못했다.
- 수정: 공용 checkbox 기본 행 선택 동작은 유지하고 `selectRowOnCheckboxTap` 옵션을 추가해 품목 발행 컬럼만 체크 상태 변경 외 행 선택/cell activation/editor commit을 하지 않도록 했다.
- 구현 전 판별 테스트: 실제 checkbox key 클릭 시 `onRowSelected`가 1회 호출되어 실패해 원인 가설을 확인했다.
- `fortune_table.dart`, `item_manage.dart` 편집 완료: 품목 발행 checkbox cell만 일반 cell의 행 선택/cell activation/다른 editor commit pointer 경로를 타지 않고 checkbox 값만 변경한다.
- focused 검증 완료: 실제 `fortune_table_checkbox_publish_0` 클릭 후 체크 상태만 변경되고 `onRowSelected=0`, item draft clean, 저장 버튼 비활성, active table editing false를 확인했다.
- 관련 전체 테스트 완료: `fortune_table_test.dart`, `label_sheet_toolbar_test.dart`, `preview_floating_window_test.dart` 전체 259건 통과. 변경 파일 편집기 진단 없음.
- 버전 편집 완료: 호환 가능한 발행 체크 버그 수정이므로 PATCH 증가로 `1.3.4`에서 `1.3.5`로 갱신했다.
- 다음 검증 예정: FortuneTable nested package navigation 테스트, 변경 파일 strict analyzer, `/WX` Windows Debug 빌드.
- strict analyzer 완료: `fortune_table.dart`, `fortune_table_test.dart` `No issues found`.
- 중첩 package 검증 완료: VS Code test runner는 테스트를 발견하지 못했지만 FortuneSheet 디렉터리에서 `flutter test test/fortune_table_navigation_test.dart` CLI 실행 결과 2건 통과.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 EXE 버전과 최종 diff를 확인한다.
- 첫 Windows 통합 빌드는 실행 중인 Debug `label_manager.exe` 잠금으로 `LNK1168` 실패했다. 해당 Debug 산출물 프로세스만 `CloseMainWindow()`로 정상 종료한 뒤 동일 명령을 재실행한다.
- Debug 앱 PID 700 정상 종료 후 첫 수정 소스의 `/WX` Windows Debug 빌드 성공. 이후 공용 기본 동작 보존을 위해 옵션을 품목 발행 컬럼에만 scoped 처리했다.
- scoped 처리 후 관련 전체 테스트 259건 재통과, 변경 3개 Dart 파일 strict analyzer `No issues found`, 편집기 진단 없음. FortuneTable nested package 테스트와 `/WX` 빌드를 최종 재실행한다.
- 최종 검증 완료: FortuneTable nested package navigation 2건 통과, `/WX` Windows Debug 빌드 성공, EXE FileVersion/ProductVersion 모두 `1.3.5`, `git diff --check` 통과.
- 동작 기준: 품목 발행 checkbox는 발행 체크 상태만 변경한다. 현재 행 선택과 주원료 preview owner를 바꾸지 않으므로 item draft는 clean이고 저장 버튼은 비활성 상태를 유지한다. 다른 FortuneTable checkbox는 기존 행 선택 기본 동작을 유지한다.
- stage/commit 대상: `fortune_table.dart`, `item_manage.dart`, 실제 checkbox 회귀 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 기능 커밋: `725a3bf` (`발행 체크의 품목 초안 변경 방지`).

## 완료: 품목관리 비편집 상호작용의 편집모드 진입 차단 v1.3.4
- 요청: 발행 체크, 플로팅창 주원료/출력 미리보기 탭 클릭, 플로팅창 resize는 품목관리 편집모드로 들어가지 않아야 한다. 주원료 시트는 더블클릭 후 변경 없이 나와도 draft를 만들지 않아야 하며 출력 미리보기는 읽기 전용이어야 한다.
- 확인: 출력 미리보기는 `LabelOutputPreview`에서 `canEditObjects: false`로 `allowEdit=false`를 전달한다. 주원료 preview는 workbook 실내용 비교 후에만 commit하지만 실제 포인터 상호작용과 active editing 상태를 직접 검증하는 테스트가 부족하다.
- 수정 예정: `ItemManage` 발행 체크와 `_ItemPreviewPanel`의 탭/시트/resize 상호작용 회귀 테스트를 먼저 추가해 실패 제어 지점을 확정한 뒤 최소 범위로 수정한다. 상태: 미검증.
- 원인 확인: 주원료 시트 tab은 keepAlive라 cell editor가 열린 상태에서 출력 미리보기로 이동해도 `_editingCoord`가 유지된다. 변경 없는 editor는 draft commit은 만들지 않지만 편집 상태가 남는다. 출력 미리보기는 원본 workbook과 별도로 전달되는 effective settings에서 `allowEdit=false`가 적용된다.
- 구현 완료: FortuneSheet/LabelSheet lifecycle에 활성 cell 편집 조회·commit API를 추가하고, 품목 주원료 탭 전환과 플로팅 resize 시작 시 editor를 종료하도록 연결했다. 발행 체크는 기존 구현에서 active table editing을 만들지 않음을 테스트로 확인했다. focused 재검증 예정.
- focused 검증 완료: 발행 체크, 변경 없는 주원료 편집 후 탭 전환, 출력 미리보기 읽기 전용, 편집 중 플로팅 resize 3건 통과. 변경 Dart 6개 파일 편집기 진단 없음, `git diff --check` 통과.
- 버전 편집 완료: 호환 가능한 품목관리 편집 상태 수정이므로 PATCH 증가로 `1.3.3`에서 `1.3.4`로 갱신했다.
- 관련 전체 검증 예정: `flutter test test/fortune_table_test.dart test/label_sheet_toolbar_test.dart test/preview_floating_window_test.dart` 및 변경 Dart strict analyzer를 실행한다.
- 관련 전체 테스트 완료: `fortune_table_test.dart`, `label_sheet_toolbar_test.dart`, `preview_floating_window_test.dart` 전체 259건 통과.
- analyzer 실행 예정: 앱/테스트 변경 파일은 `flutter analyze lib/features/label_sheet/label_sheet_workbench.dart lib/home_page_manager.dart lib/widgets/preview_floating_window.dart test/fortune_table_test.dart test/label_sheet_toolbar_test.dart`, FortuneSheet canvas는 기존 미사용 경고와 분리해 `flutter analyze --no-fatal-warnings third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`로 확인한다.
- analyzer 완료: 앱/테스트 변경 5개 파일 `No issues found`. FortuneSheet canvas는 신규 오류 없이 기존 미사용 코드 경고 10건만 유지했다.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 실행 후 Debug EXE FileVersion/ProductVersion과 최종 diff를 확인한다.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 완료: Debug EXE FileVersion/ProductVersion 모두 `1.3.4`, `git diff --check` 통과. 추가 임시 산출물은 없고 Debug 빌드 산출물은 기존 ignored 경로에 있다.
- 동작 기준: 발행 체크는 품목 테이블 편집을 시작하지 않는다. 주원료 시트는 변경 없이 더블클릭 편집 후 탭 이동 또는 플로팅 resize 시 editor를 종료하고 draft를 만들지 않는다. 출력 미리보기는 effective `allowEdit=false`로 편집할 수 없다.
- stage/commit 대상: FortuneSheet cell editing API, LabelSheet lifecycle, 품목 preview/플로팅 연결, 관련 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 기능 커밋: `9bf9f2b` (`품목 미리보기 편집 상태 전환 수정`).

## 완료: 도움말 팝업 메뉴 스타일 통일
- 원인: 설정 등 `AppMenuBar` 팝업은 높이 28, 가로 패딩 12, 축소 tap target의 공용 `MenuItemButton` 스타일을 사용하지만 별도 `HelpMenuButton`은 Material 기본 스타일을 사용했다.
- 수정: `AppMenuBar.menuItemStyle`, `menuItemHeight`, `menuDividerHeight`를 공용으로 노출하고 도움말 4개 항목과 divider에 동일 적용했다. 실제 `MenuItemButton` 스타일과 최소 높이 `64x28`을 위젯 테스트로 고정했다.
- 검증: `flutter test test/help_menu_button_test.dart test/app_menu_bar_test.dart` 23 passed. 변경 3개 Dart 파일 strict analyzer `No issues found`, 편집기 진단 없음, `git diff --check` 통과.
- 커밋 대상: `app_menu_bar.dart`, `help_menu_button.dart`, `help_menu_button_test.dart`, `SESSION_HANDOFF.md`만 stage. 기존 unrelated `analysis_options.yaml`, lock 파일, `third_party` 변경은 제외.
- 기능 커밋: `f775af1` 도움말 팝업 메뉴 스타일 통일.

## 완료: 고객 확인 항목 4~9 수정 v1.3.3
- 사용자 확인: v1.0.1 관리자 복사 오류는 현재 버전에서 재현 확인되지 않음. SYSTEM 정상 로그인 발행도 이력 저장. 사용자 환경 접속 권한은 레거시대로 시스템 관리자/관리자 접속만 허용.
- 로그인 이력 기준: 마스터 PW 인증은 LOGIN/LOGOUT 모두 제외한다. 사용자 관리의 관리자 접속은 대상 사용자 LOGIN을 만들지 않으며, 이후 로그아웃은 정상 직접 로그인한 원 관리자 계정으로 기록해 LOGIN/LOGOUT 쌍을 맞춘다.
- 1차 수정 완료: 명시적 로그아웃/종료의 정상 로그인 이력 판정 통합, SYSTEM 발행 이력 제외 제거, 검색 출력 저장 changed key를 `searchPrint`로 제한. 관련 테스트 13 passed.
- 관리자 접속 구현 완료: 레거시 권한 조건으로 접속 버튼을 복원하고 원 사용자·거래처 컨텍스트를 세션에 보존한다. 대상 환경 전환 및 `BM_ADMIN_ACCESS_LOG` 기록 실패 시 전환 전 상태로 원복한다. 세션/다이얼로그 테스트 15 passed.
- 도움말 구현 완료: 액션바 `설정` 다음, 서버 상태 아이콘 바로 앞에 도움말 버튼을 고정 배치했다. 레거시 정보/쇼핑몰/원격지원/자료실 항목과 현재 `appVersion` 정보 창을 구현했다.
- 관리자 복사: 첨부는 v1.0.1이며 현재 v1.3.2 재현은 확인되지 않았다. 현재 SQL에는 `labelmanager_combine` 하드코딩이 없고 레거시 3개 품목 복사 프로시저 순서를 사용한다. 최신 DAO/다이얼로그 테스트 11 passed로 확인했으며 추측성 재시도/예외 처리는 추가하지 않았다.
- 도움말 테스트: 레거시 4개 항목, 현재 앱 버전, 외부 URL 3개 검증 2 passed.
- 관련 통합 테스트: 로그인 이력/발행 저장/검색 출력/관리자 접속/사용자 관리/도움말 30 passed, startup login 이력 조건 3 passed. 변경 파일 진단 없음.
- 버전: `pubspec.yaml`을 `1.3.3`으로 갱신. `version.txt`는 배포 요청이 없어 변경하지 않는다.
- 인접 테스트: app menu 12 passed, 검색 출력/사용자 관리/로그아웃 19 passed. `flutter test test/label_print_persistence_test.dart test/label_print_pipeline_test.dart` 9 passed.
- strict analyzer: 최초 실행에서 `home_page.dart`의 사용자 환경 접속 직접 의존 import 4개 누락을 발견해 `ManagedUser`, `MarketDAO`, `CustomerDAO`, `CooperatorDAO` import를 추가했다. 동일 변경 파일 15개 재실행 결과 `No issues found`.
- Windows 검증: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. `build/windows/x64/runner/Debug/label_manager.exe`의 `FileVersion`/`ProductVersion` 모두 `1.3.3`.
- 최종 점검: `git diff --check` 통과. 배포 EXE/ZIP/설치 프로그램은 요청되지 않아 생성하지 않았다.
- 커밋 대상: 본 항목 관련 구현·테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`만 stage한다.
- 기능 커밋: `38ba44b` 사용자 접속 및 이력 기능 복원.

## 완료: 사용자 관리 검색 결과 행 중앙 스크롤 v1.3.2
- 원인/수정: `_searchNext()`가 선택만 갱신하던 경로에 `FortuneTableScrollController`를 연결하고, 새 공용 API `revealRowCentered()`로 검색 결과 행 중심을 테이블 viewport 중심에 맞춘다. 기존 `revealRow()` 의미와 일반 행 선택 동작은 유지한다.
- 경계 동작: 첫/마지막 근처 결과는 유효 scroll extent로 제한하며, 검색 결과가 없을 때 기존 안내 동작을 유지한다.
- 테스트: `test/user_manager_dialog_test.dart` 전체 10 passed. 100행 중 80번째 검색 결과의 행/viewport 중심 offset 1px 이내를 검증했다. FortuneTable 기존 offscreen reveal 테스트도 1 passed.
- analyzer: 변경 Dart 파일 strict analyzer `No issues found`.
- 빌드: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.2`.
- 정리: 추가 임시 산출물 없음. `version.txt`와 배포 산출물은 변경하지 않았다.
- stage 대상: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/features/managed_user/presentation/user_manager_dialog.dart`, `test/user_manager_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `443ec3c` (`사용자 검색 행 중앙 스크롤 추가`).

## 완료: 품목관리 주원료 플로팅 preview 단일 셀 크기 복원 v1.3.1
- 원인/수정: `_ItemElementPreviewTab`의 누락된 `fitSingleCellToViewport`를 활성화해 1×1 셀이 플로팅 viewport를 채우도록 했다.
- 저장 경계: viewport 행·열 크기는 view state로 제외하고 `_itemElementWorkbookWithLabelSize()`가 자동 commit·명시 저장 payload를 실제 라벨 물리 크기로 정규화한다. 초기 표시와 창 resize는 초안을 commit하지 않는다.
- 테스트: `test/label_sheet_toolbar_test.dart` 전체 190 passed. 실제 preview 설정, 줌 유지, resize 무commit, 100×80mm 테스트 라벨 저장 크기를 검증한다.
- analyzer: 변경 파일 strict analyzer `No issues found`. 전체 strict analyzer는 기존 fortune_sheet 미사용 코드 경고 10건으로 종료 코드 1이며 이번 변경 파일 진단은 없다.
- 빌드: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. Debug EXE `FileVersion`/`ProductVersion` 모두 `1.3.1`.
- 정리: 추가 임시 산출물 없음. `version.txt`와 배포 산출물은 변경하지 않았다.
- stage 대상: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `ea97e8d` (`품목관리 주원료 단일 셀 크기 복원`).

## 완료: 공용라벨 키워드 더블클릭·드래그 삽입 v1.3.0
- 요청: 특별 항목/사용 항목의 키워드 셀을 더블클릭하면 현재 편집 커서 또는 마지막 선택 셀에 `{#키워드}`를 삽입하고, 키워드를 라벨 시트로 드래그하면 정확한 드롭 caret에 삽입한 뒤 편집 상태와 저장 활성화를 유지한다.
- 사용자 확인 완료: 편집 문자열 선택 시 선택을 유지하고 선택 끝에 삽입, `third_party/fortune_sheet` 공용 API 최소 확장, 데스크톱 즉시 마우스 드래그를 적용한다.
- `third_party/fortune_sheet/lib/src/fortune_table.dart` 편집 완료: `FortuneTableColumn.dragData`/`dragFeedbackBuilder`로 컬럼별 즉시 `Draggable` 소스를 제공한다.
- `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 편집 완료: `FortuneSheetController.insertTextAtCurrentContext()`와 `insertTextAtGlobalPosition()`이 편집 cursor, 마지막 선택 셀, 첫 셀 fallback, 글로벌 드롭 caret 삽입을 기존 editor/undo/selection 경로로 처리한다.
- `label_sheet_workbench.dart` 편집 완료: `LabelSheetKeywordInsertController`와 키워드 전용 `DragTarget`을 추가하고 삽입 성공 시 dirty/save 활성 상태를 즉시 반영한다.
- `label_sheet_page.dart` 편집 완료: 키워드 삽입 controller를 Workbench로 전달한다.
- `common_label_manage.dart` 편집 완료: 특별/사용 항목 키워드 컬럼의 기존 `onDoubleTap`과 새 drag source를 하나의 시트 controller에 연결한다.
- 테스트 편집 진행: FortuneTable drag source, 마지막 선택 셀 append/선택 복원, 편집 선택 끝 삽입, 첫 셀 fallback, 정확한 드롭 caret, 즉시 dirty 전환 테스트를 추가했다. 신규 테스트 6건 개별 통과.
- 공용 API 5개 파일 analyzer 신규 오류 0건. fortune_sheet 기존 미사용 코드 경고 10건은 범위 밖으로 유지한다. 중첩 package FortuneTable navigation 테스트 2건 통과.
- 포커스 회귀 수정 완료: FortuneTable의 pointer-up focus 요청 이후 다음 frame에 시트 editor focus를 복원해 더블클릭·드롭 후 편집 상태와 삽입 caret을 유지한다.
- 테스트 편집 완료: 실제 공용라벨 키워드 컬럼 wiring, 즉시 drag payload 전달, 편집/선택/첫 셀/drop/dirty/focus 복원 분기를 추가했다.
- 변경 Dart 8개 포맷 완료. 앱 변경 범위 strict analyzer·diagnostics 오류 0건, focused 테스트 3개 파일 268건 통과, 중첩 package 테스트 2건 통과. fortune_sheet analyzer는 신규 오류 0건이며 기존 미사용 경고 10건만 유지한다.
- 버전 편집 완료: 사용자 상호작용 기능 추가이므로 MINOR 증가로 `1.2.3`에서 `1.3.0`으로 갱신했다.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug`.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 커밋 전 요구사항 대조 검토 완료: 편집/선택/A1 fallback, 정확한 drop caret, focus·selection 복원, dirty 전환, controller lifecycle, undo/onOp 경로에서 누락·회귀 없음.
- 잔여 수동 확인: 실제 scroll/zoom 및 병합 셀 상태에서 드롭 위치 체감만 확인하면 된다. 좌표 계산은 fortune_sheet 기존 scroll/transform 및 `RenderEditable.getPositionForPoint` 경로를 사용한다.
- 최종 자동 검증 완료: EXE FileVersion/ProductVersion `1.3.0`, `git diff --check` 통과. formatter 디스크 정렬 확인 후 canvas 관련 테스트 2건 재통과, 신규 analyzer 오류 0건.
- stage/commit 대상: fortune_sheet 공용 API 2개, 라벨 시트 Workbench/Page/CommonLabelManage 3개, 관련 테스트 3개, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 기능 커밋 완료: `bae9199` (`공용라벨 키워드 삽입 동작 추가`).

## 완료: 공용라벨 편집 모드에서 항목 편집 허용 v1.2.3
- 요청: 공용라벨관리의 라벨 시트 편집 모드에서도 사용 항목의 `항목 편집` 다이얼로그에 진입하고 저장할 수 있어야 한다.
- 원인: `HomePageManager._openLabelColumnEditDialog()`와 저장 가능/실행 조건이 `_commonLabelSheetDirty`를 미저장 충돌로 간주해 다이얼로그 진입과 저장을 모두 차단한다.
- 수정 방향: 품목관리 draft 및 명령 busy 차단은 유지하고 공용라벨 sheet dirty만 항목 편집 예외로 허용한다. 편집 중 항목 저장 시 기존 전체 세션 강제 reload로 workbook draft를 폐기하지 않고 현재 라벨 컬럼만 재조회해 실행 중인 시트 상태를 유지한다.
- 수정 예정: `lib/home_page_manager.dart`, 컬럼 저장 서비스/분기 테스트, `pubspec.yaml`. 수정 후 focused 테스트, strict analyzer, `/WX` Windows Debug 빌드를 검증한다.
- `lib/home_page_manager.dart` 편집 완료: `labelColumnEditAllowed()`로 진입·저장 조건을 통일해 공용라벨 sheet dirty를 허용하고, dirty 상태 저장 시 `_reloadLabelColumns()`로 현재 `TColumn`만 갱신해 workbook draft와 시트 widget 상태를 유지한다.
- `label_column_save_service.dart` 편집 완료: `reloadLabelColumnsAfterSave()`가 공용라벨 draft 유지 시 컬럼 부분 reload, clean 상태에서는 기존 전체 세션 reload를 선택한다.
- 테스트 편집 완료: `label_column_save_test.dart`에 부분/전체 reload 선택 2건, `label_sheet_toolbar_test.dart`에 편집 모드 허용 및 기존 busy/draft 차단 정책 2건을 추가했다.
- 변경 Dart 4개 포맷 완료. strict analyzer와 diagnostics 오류·경고 0건, focused 테스트 2개 파일 전체 200건 통과.
- 버전 편집 완료: 호환 가능한 편집 동작 수정이므로 PATCH 증가로 `1.2.2`에서 `1.2.3`으로 갱신했다.
- Windows 통합 검증 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug`.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 검증 완료: EXE FileVersion/ProductVersion `1.2.3`, 변경 파일 analyzer·diagnostics 오류 0건, focused 테스트 200건 통과, `git diff --check` 통과.
- 동작 기준: 공용라벨 시트 편집 중에도 `항목 편집` 진입·저장이 가능하다. 저장 후 사용 항목 컬럼만 갱신해 편집 중 workbook draft를 유지하며, 품목관리 미저장 draft와 항목 저장 busy 상태는 기존대로 진입·저장을 차단한다.
- stage/commit 대상: `home_page_manager.dart`, `label_column_save_service.dart`, 관련 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 기능 커밋 완료: `644d92e` (`공용라벨 편집 중 항목 편집 허용`).

## 완료: 액션 바 관리 메뉴와 협력업체 조회 범위 제한 v1.2.2
- 요청: 일반 업체 계정은 협력업체·거래처·지점·사용자 관리와 관리자 복사 메뉴를 조회할 수 없어야 하며, 협력업체 계정은 자기 협력업체 소속 거래처·지점·사용자만 조회하고 아이티에스엔지/TEST 계정만 전체 업체를 조회한다.
- 레거시 확인: `MainFrm.cpp`의 `OnEnableSystemAdmin`/`OnEnableAdmin`/`OnEnableManager`가 시스템·협력업체 관리자 및 관리자 접속 상태에 따라 `IDM_COOP_MANAGE`, `IDM_CUST_MANAGE`, `IDM_MARKET_MANAGE`, `IDM_USER_MANAGE`, `IDM_ADMIN_COPY`를 제한한다. `CustomerDAO::SelectByCoopID`, `UserDAO::SelectByCoopID`는 협력업체 ID로 조회 범위를 제한한다.
- 현재 메뉴 정책은 CLIENT_USER에서 관리 메뉴 5개를 숨기고 협력업체 관리 경계를 레거시와 동일하게 적용한다. 조회 결함은 협력업체 선택이 비활성인 거래처·지점·사용자·관리자 복사 다이얼로그도 초기화 때 `CooperatorDAO.selectAll()`을 호출해 전체 업체를 읽는 것이다.
- 수정 예정: 선택 권한이 없는 계정은 현재 `Cooperator.instance`만 사용하고 전체 협력업체 loader를 호출하지 않도록 네 관리 다이얼로그를 수정한다. 시스템/관리자 접속 등 전체 업체 선택 권한이 있는 경로는 기존 전체 조회를 유지한다.
- 거래처 관리 첫 focused 검증 완료: `customer_manager_dialog_test.dart` 7건 통과, 비활성 협력업체 selector에서 전체 업체 loader 호출 0회를 확인했다.
- 지점·사용자·관리자 복사 편집 완료: 협력업체 선택 권한이 없으면 `CooperatorDAO.selectAll()`을 호출하지 않고 현재 협력업체만 목록에 유지한다.
- 관리 다이얼로그 focused 검증 완료: 거래처·지점·사용자·관리자 복사 테스트 4개 파일 전체 24건 통과.
- 추가 원인 확인: 지점 관리의 `isCoopAdminConnect`가 전체 협력업체 선택을 허용해 협력업체 계정 범위를 벗어날 수 있었다. 전체 업체 조회 권한을 시스템 관리자 등급 또는 시스템 관리자 접속으로 통일하고 협력업체 관리자 접속은 현재 협력업체 범위로 제한한다.
- 메뉴/범위 정책 편집 완료: `canBrowseAllManagementCooperators()`를 공용 정책으로 추가해 시스템 관리자 등급 또는 시스템 관리자 접속만 네 관리 화면의 전체 협력업체 selector를 활성화한다. 일반 협력업체 관리자와 협력업체 관리자 접속은 현재 협력업체로 제한한다.
- 메뉴/범위 focused 검증 완료: 일반 업체 ID `22948997`의 관리 메뉴 5개 비노출, 시스템 관리자/관리자 접속의 전체 범위 허용, 협력업체 관리자 제한을 포함해 정책·관리 다이얼로그 5개 테스트 파일 전체 36건 통과.
- 변경 Dart 11개 파일 포맷 완료. 변경 파일 diagnostics 오류 0건, `git diff --check` 통과.
- strict analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/core/app_menu_policy.dart lib/home_page.dart lib/features/admin_copy/presentation/admin_copy_dialog.dart lib/features/customer/presentation/customer_manager_dialog.dart lib/features/market/presentation/market_manager_dialog.dart lib/features/managed_user/presentation/user_manager_dialog.dart test/app_menu_policy_test.dart test/admin_copy_dialog_test.dart test/customer_manager_dialog_test.dart test/market_manager_dialog_test.dart test/user_manager_dialog_test.dart`.
- 첫 strict analyzer는 관리자 복사 테스트가 존재하지 않는 `ModelessDropdownFormField.enabled` getter를 참조해 1건 실패했다. 실제 비활성 계약인 `onChanged == null`로 테스트를 수정한 뒤 같은 analyzer를 재실행한다.
- strict analyzer 재검증 완료: 변경 production/test Dart 11개 파일 오류·경고 0건.
- 포맷 후 최종 focused 검증 완료: 메뉴 정책·거래처·지점·사용자·관리자 복사 테스트 5개 파일 전체 42건 통과.
- 버전 편집 완료: 기존 권한과 조회 범위를 바로잡는 호환 가능한 버그 수정이므로 PATCH 증가로 `1.2.1`에서 `1.2.2`로 갱신했다.
- Windows 통합 검증 실행 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug`.
- 첫 Windows 통합 빌드는 실행 중인 Debug `label_manager.exe` 잠금으로 `LNK1168` 실패했다. 현재 Debug 산출물 프로세스만 정상 종료한 뒤 같은 명령을 재실행한다.
- Debug 앱 PID 16524에 `CloseMainWindow()`로 정상 종료를 요청한 뒤 동일 `/WX` Windows Debug 빌드 재실행 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 액션 바 메뉴 회귀 검증 완료: `app_menu_bar_test.dart`, `app_menu_command_test.dart`, `app_menu_controller_test.dart`, `app_menu_policy_test.dart` 전체 12건 통과.
- 최종 자동 검증 완료: Debug EXE FileVersion/ProductVersion `1.2.2`, 변경 파일 diagnostics 오류 0건, `git diff --check` 통과. 관리자 복사 테스트 들여쓰기 정리 후 단독 analyzer 오류·경고 0건 및 widget 테스트 6건 재통과.
- 동작 기준: CLIENT_USER 일반 업체(ID `22948997` 포함)는 관리 메뉴 5개를 볼 수 없다. 협력업체 관리자 및 협력업체 관리자 접속은 거래처·지점·사용자·관리자 복사에서 현재 협력업체만 조회하며 전체 협력업체 DAO를 호출하지 않는다. 시스템 관리자 등급(운영 데이터의 아이티에스엔지/TEST 계정)과 시스템 관리자 접속만 전체 협력업체 선택·조회를 유지한다.
- stage/commit 대상: 메뉴 정책·홈 2개, 관리 다이얼로그 4개, 관련 테스트 5개, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 기능 커밋 완료: `f33ed99` (`관리 메뉴와 협력업체 조회 범위 제한`).

## 완료: 공용라벨 라벨 항목 삭제 저장 무한 진행 수정 v1.2.1
- 사용자 재현: 공용라벨관리의 `라벨 항목 편집`에서 사용 항목 하나를 삭제한 뒤 저장하면 진행 표시가 끝나지 않는다.
- 최신 로그 `.tmp/log/app_2026-08-12_09-52-05.log` 확인: 라벨 컬럼 저장 복합 SQL이 기록된 뒤 완료·오류 로그 없이 파일이 끝난다.
- 원인 확인: `LabelColumnSaveDao.buildSaveStatement()`가 다수의 `INSERT`/`UPDATE`/`DELETE`/`MERGE`와 마지막 결과 `SELECT`를 단일 ODBC transaction statement로 실행하면서 `SET NOCOUNT ON`이 없어 중간 rowcount 결과에서 반환이 멈출 수 있다. UI는 `onSave` 반환을 정상 대기하므로 busy 해제 누락이 아니다.
- 수정: 저장 SQL 첫 문장에 `SET NOCOUNT ON;`을 추가하고 최종 신규 컬럼 mapping `SELECT`는 유지한다. 삭제 저장 SQL의 NOCOUNT 계약을 DAO 테스트에 추가한다.
- focused 검증 완료: `test/label_column_save_test.dart` 전체 14건 통과.
- 버전 편집 완료: 호환 가능한 저장 무한 진행 버그 수정이므로 PATCH 증가로 `1.2.0`에서 `1.2.1`로 갱신했다.
- strict analyzer 완료: `C:/Flutter/bin/flutter.bat analyze lib/features/label_column/data/label_column_save.dart test/label_column_save_test.dart` 오류·경고 0건.
- Windows 통합 검증 실행 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug`.
- 첫 Windows 통합 빌드는 실행 중인 Debug `label_manager.exe` 잠금으로 `LNK1168` 실패했다. 해당 빌드 산출물 프로세스만 정상 종료한 뒤 같은 명령을 재실행한다.
- Debug 앱 PID 11660에 `CloseMainWindow()`로 정상 종료를 요청한 뒤 동일 `/WX` Windows Debug 빌드 재실행 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 자동 검증 완료: Debug EXE FileVersion/ProductVersion `1.2.1`, 변경 파일 diagnostics 오류 0건, `git diff --check` 통과.
- 동작 기준: 사용 항목 삭제 저장 시 중간 DML rowcount를 ODBC 결과로 내보내지 않고 마지막 신규 컬럼 mapping 결과만 반환해 저장 transaction과 화면 재조회가 완료되어야 한다.
- stage/commit 대상: `lib/features/label_column/data/label_column_save.dart`, `test/label_column_save_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 기능 커밋: `50a9969` (`라벨 항목 삭제 저장 무한 대기 수정`).

## 완료: 품목관리·공용 테이블·플로팅 미리보기 개선 v1.2.0
- 사용자 확인 완료: 최소표시 헤더 체크는 품목 draft에 포함해 저장 버튼으로 일괄 저장하고, 새로 고침은 현재 라벨 전체 품목을 DB에서 다시 읽으며 현재 선택 품목을 복원한다. 우클릭 완전 차단은 `LabelOutputPreview` 기반 읽기 전용 출력 미리보기에만 적용한다.
- 레거시 확인: `IDR_ITEMMENU`의 클라이언트 편집 허용/불가는 관리자 편집 권한이 있고 우클릭 지점이 품목 행의 동적 컬럼일 때만 활성화하며, 단일 셀의 `RICH_EDITABLE`을 변경해 품목 저장 시 함께 반영한다. 새로 고침은 현재 라벨 전체 테이블을 DB에서 다시 읽는다.
- 원인 확인: 품목 저장 호출부가 `executeItemManagerSave()`의 `selectedItemId`/`selectedRowIndex`를 버리고 첫 행 선택 재조회를 요청한다. `ItemDAO.updateOrdersSql`은 복합 DML SQL인데 `SET NOCOUNT ON`이 없어 ODBC가 중간 rowcount 응답에서 대기할 위험이 있다.
- 원인 확인: 공용 `FortuneTable`은 Enter 편집 종료 후 다음 편집 셀 이동이 없고 Tab을 처리하지 않는다. mouse drag scrolling과 행 drag selection이 동시에 활성화되며 테이블 경계 밖 선택 autoscroll은 없다.
- 원인 확인: `PreviewFloatingWindow`의 상단·좌측 edge resize는 반대 변을 고정하지 않고, 이동은 overlay 경계 clamp가 없다. 읽기 전용 출력 미리보기는 현재 copy-only 우클릭 메뉴를 표시한다.
- 수정 예정: `home_page_manager.dart`, item draft/save/order/menu 관련 파일과 테스트, 공용 `fortune_table.dart`와 테스트, `preview_floating_window.dart`와 테스트, `label_output_preview.dart`/label sheet settings와 테스트를 순차 편집한다. 상태: 미검증.
- 첫 focused 검증 예정: 선택 복원 및 순서 SQL 변경 직후 관련 item manager save/order/DAO 테스트를 실행한다.
- `home_page_manager.dart` 편집 완료: 품목 저장 후 `executeItemManagerSave()`가 반환한 최종 선택 item ID와 저장 전 행 index를 강제 재조회 선택 복원에 전달한다.
- `item_dao.dart` 편집 완료: 순서 갱신 복합 SQL 첫 줄에 `SET NOCOUNT ON`을 추가해 ODBC 중간 rowcount 응답을 제거했다.
- 첫 focused 검증 완료: `item_manager_draft_test.dart`, `item_manager_save_dao_test.dart`, `item_order_dialog_test.dart` 전체 37건 통과.
- 최소표시 draft/save 편집 완료: 주원료·동적 컬럼 최소표시 체크를 즉시 별도 저장하지 않고 품목 draft dirty에 포함하며, 품목 저장 XML과 같은 SQL transaction에서 `BM_RICH_COL_MIN`에 MERGE한다. 취소·저널 복원 시 임시 설정을 제거한다.
- 품목 우클릭 메뉴 편집 완료: QR 데이터 보기 아래에 레거시와 같은 단일 동적 셀 대상 `클라이언트 편집 허용/불가`를 추가하고, 마지막에 현재 라벨 전체를 재조회하는 `새로 고침`을 추가했다. 새로 고침은 dirty/busy일 때 비활성이고 선택 item ID/index를 복원한다.
- 공용 `FortuneTable` 편집 완료: Enter/Tab은 commit 완료 후 다음 편집 가능 셀로 이동하고 마지막 편집 컬럼에서는 다음 행 첫 편집 셀로 이어진다. Shift+Tab 역방향도 지원한다. 멀티 선택 중 mouse drag scroll 충돌을 제거하고 body 상·하단 경계 밖에서만 autoscroll하며 선택을 연장한다.
- `PreviewFloatingWindow` 편집 완료: 상단·좌측 edge resize가 반대 변을 고정하도록 수정하고 최소 크기에서도 anchor를 유지한다. 이동 rect를 overlay에 clamp해 이동 핸들과 창이 화면 밖으로 벗어나지 않는다.
- 출력 미리보기 편집 완료: `LabelOutputPreview` 기반 읽기 전용 시트는 cell/header context menu 목록을 모두 비운다. 편집 가능한 주원료/공용라벨 시트의 우클릭은 유지한다.
- focused 검증 완료: 최소표시·editable·저장·순서 관련 39건, FortuneTable 키 이동/autoscroll 2건, 플로팅 rect 3건, 미리보기 메뉴 설정 1건, 품목 context menu 1건 통과.
- 다음 검증 예정: 변경 Dart 포맷 후 관련 테스트 묶음과 strict analyzer를 실행한다.
- 변경 Dart 파일 포맷 완료.
- 관련 테스트 실행 예정: `flutter test test/item_manager_draft_test.dart test/item_manager_save_dao_test.dart test/item_order_dialog_test.dart test/fortune_table_test.dart test/preview_floating_window_test.dart test/label_sheet_toolbar_test.dart` 및 FortuneSheet 패키지 `flutter test test/fortune_table_navigation_test.dart`.
- 관련 통합 테스트 완료: 루트 6개 파일 전체 290건, FortuneSheet `fortune_table_navigation_test.dart` 2건 통과.
- strict analyzer 실행 예정: 변경 production/test Dart 파일 전체를 대상으로 `flutter analyze` 실행.
- strict analyzer 완료: 변경 production/test Dart 17개 파일 오류·경고 0건.
- 버전 편집 완료: 사용자에게 보이는 품목관리 메뉴·키보드·드래그·플로팅 동작을 추가하므로 MINOR 증가로 `1.1.1`에서 `1.2.0`으로 갱신했다. 설치 패키지용 `version.txt`는 기존 별도 버전 상태를 유지한다.
- Windows 통합 검증 실행 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug`.
- Windows 통합 검증 완료: `/WX` Debug 빌드 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 UI 경로 검증 완료: 우클릭한 단일 동적 셀의 `클라이언트 편집 허용`이 셀 데이터는 유지하고 `editable`만 draft 저장값으로 변경하는 widget 테스트 통과.
- 최종 자동 검증 완료: Debug EXE FileVersion/ProductVersion `1.2.0`, 변경 파일 diagnostics 오류 0건, 마지막 테스트 파일 analyzer 오류·경고 0건, `git diff --check` 통과.
- 동작 기준: 저장 후 편집 품목 선택 유지, 순서 저장 완료, 최소표시/클라이언트 편집 권한의 품목 저장 일괄 반영, 전체 새로 고침 선택 복원, 공용 Enter/Tab 이동 및 경계 autoscroll 선택, 플로팅 8방향 resize·화면 내 이동, 읽기 전용 출력 미리보기 우클릭 완전 차단을 적용한다.
- stage/commit 대상: 품목 data/domain/presentation 5개, `home_page_manager.dart`, label sheet 설정/workbench 2개, preview widget 2개, FortuneTable, 관련 테스트 6개, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 구현 커밋: `f8bfa63` (`품목관리 편집 흐름과 공용 테이블 동작 개선`).

## 완료: 품목관리 빈 품명·주원료 저장 허용 v1.1.1
- 요청: 품목관리 저장 시 빈 품명과 빈 주원료를 허용하고, 신규 저장과 기존 품목 수정 모두 DB에 빈 문자열이 반영되게 한다.
- 원인 확인: `ItemManagerDraftController.validateForSave()`가 모든 빈 품명을 차단하고 `requireElement`일 때 빈 주원료를 차단한다. `ItemManagerSaveDAO.saveSql`은 XML의 `ITEM_NAME`·`ELEMENT_PLAIN`을 별도 대체 없이 `BM_RICH_ITEM.RICH_ITEM_NAME`·`RICH_ELEMENT`에 직접 INSERT/UPDATE하므로 DB 경로는 이미 빈 문자열 저장을 지원한다.
- `item_manager_draft.dart` 편집 완료: 빈 품명과 `requireElement` 상태의 빈 주원료 validation만 제거했다. 품명 최대 길이, 동적 필수 컬럼, 바코드·이미지 등 기존 검증은 유지한다.
- 테스트 편집 완료: 기존 행 수정과 신규 행 모두 빈 품명·빈 주원료 save command 생성을 허용하고, `existingRowsXml`/`newRowsXml`의 빈 요소와 SQL의 직접 UPDATE/INSERT 계약을 고정했다.
- focused 검증 완료: `test/item_manager_draft_test.dart`, `test/item_manager_save_dao_test.dart` 전체 34건 통과.
- strict analyzer 완료: `C:/Flutter/bin/flutter.bat analyze lib/features/item/domain/item_manager_draft.dart lib/features/item/application/item_manager_save_service.dart lib/features/item/data/item_manager_save.dart test/item_manager_draft_test.dart test/item_manager_save_dao_test.dart` 오류·경고 0건.
- 버전 편집 완료: 호환 가능한 품목 저장 동작 수정이므로 PATCH 증가로 `1.1.0`에서 `1.1.1`로 갱신했다.
- Windows 통합 검증 완료: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공, Debug EXE 생성.
- 최종 자동 검증 완료: Debug EXE FileVersion/ProductVersion `1.1.1`, 변경 파일 diagnostics 오류 0건, `git diff --check` 통과.
- 동작 기준: 품명과 주원료는 공백 문자열을 포함해 빈값 저장을 허용하며, 신규 품목 INSERT와 기존 품목 UPDATE 모두 XML 입력의 빈 문자열을 `BM_RICH_ITEM.RICH_ITEM_NAME`·`RICH_ELEMENT`에 그대로 반영한다.
- stage/commit 대상: `lib/features/item/domain/item_manager_draft.dart`, `test/item_manager_draft_test.dart`, `test/item_manager_save_dao_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 기능 커밋: `62cac72` (`빈 품명과 주원료 저장 허용`).

## 완료: 로그인 PC 시리얼 인증 포팅 v1.1.0
- 요청: 일반 비밀번호 로그인에서 이전 접속 PC와 서버의 사용자 접속 정보가 다르면 8자리 임시번호를 표시하고 대응 시리얼 번호가 일치할 때만 현재 PC 정보를 서버에 저장한 뒤 로그인한다. 마스터키 로그인은 이 검사를 제외한다.
- 레거시 확인: `LoginDlg::CheckUserAccess`는 `BM_USER_ACCESS.ACCESS_DATA` 17자리 값을 앞 8자리/뒤 9자리로 나눠 `CRandSerialDlg::Encoding`한 로컬 `C:\ITS\labelmanager_user_access.ini`의 `[USER_ACCESS_LOG] ACCESS_DATA`와 비교한다. 불일치 시 `CRandSerialDlg`의 8자리 임시번호와 시리얼 입력을 검증하고, 성공 시 서버 토큰 갱신·`BM_USER_ACCESS_LOG` 기록·로컬 값 저장을 수행한다.
- 적용 원칙: 레거시의 시장 ID 예외는 현재 요구에 없으므로 포팅하지 않는다. 일반 로그인에만 검사하고 `LoginAuthenticationMode.masterKey`는 제외한다. SQL Server compatibility 100을 유지해 `FORMAT`은 사용하지 않는다.
- `user_access_serial.dart` 편집 완료: 레거시 8자리 임시번호, 시리얼 인코딩, 17자리 서버 토큰의 로컬 PC 값 변환을 순수 함수로 포팅했다.
- `user_access_dao.dart`, `user_access_local_store.dart`, `user_access_service.dart` 편집 완료: 서버 접속 토큰 조회, compatibility 100 저장·이력 트랜잭션, 레거시 INI 읽기/쓰기, 일치·최초 등록·불일치 인증 흐름을 구현했다.
- `user_access_serial_dialog.dart`, `startup_dialog.dart` 편집 완료: PC 정보 불일치 시 임시번호/시리얼 입력 dialog를 표시하고, 마스터키가 아닌 로그인에서 성공해야 기존 로그인 세션 구성을 진행한다.
- 테스트 추가 및 focused 검증 완료: 산식·토큰 변환, 서비스 일치·최초 등록·인증 성공·취소, 마스터키 제외, SQL compatibility, dialog 오답/정답과 기존 startup login service를 포함한 12건 통과. 변경 파일 diagnostics 오류 0건.
- strict analyzer 완료: `C:/Flutter/bin/flutter.bat analyze lib/features/login/domain/user_access_serial.dart lib/features/login/data/user_access_dao.dart lib/features/login/data/user_access_local_store.dart lib/features/login/application/user_access_service.dart lib/features/login/presentation/user_access_serial_dialog.dart lib/features/login/presentation/startup_dialog.dart test/user_access_serial_test.dart test/user_access_service_test.dart test/user_access_dao_test.dart test/user_access_serial_dialog_test.dart` 오류·경고 0건.
- 버전 편집 완료: 사용자에게 보이는 신규 로그인 인증 흐름이므로 MINOR 증가로 `1.0.93`에서 `1.1.0`으로 갱신했다.
- Windows 통합 검증 완료: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공, Debug EXE 생성.
- 최종 자동 검증 완료: Debug EXE FileVersion/ProductVersion `1.1.0`, 변경 파일 diagnostics 오류 0건, `git diff --check` 통과.
- 동작 기준: 올바른 비밀번호 확인 후 마스터키가 아니면 서버 `BM_USER_ACCESS`와 로컬 `C:\ITS\labelmanager_user_access.ini` 값을 비교한다. 양쪽 최초 상태는 자동 등록하며, 기존 값이 다르면 임시번호/시리얼 인증 성공 후에만 서버 토큰·접속 이력·로컬 값을 갱신하고 로그인을 계속한다. 취소 또는 오답은 로그인과 저장을 진행하지 않는다.
- stage/commit 대상: 로그인 user-access 신규 production 5개, `startup_dialog.dart`, 회귀 테스트 4개, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 기능 커밋: `e3564a7` (`로그인 PC 시리얼 인증 추가`).
- 추가 수정 완료: 요청에 명시된 `00 + (월*3+일 두 자리)`는 `systemPasswordForDate()`이며 기존에는 SYSTEM 계정의 `firstAdmin`으로만 분류됐다. SYSTEM/일반 사용자 모두 이 값을 실제 `masterKey`로 분류해 시리얼 인증 제외 조건과 일치시켰다. 기존 일자 기반 direct key는 master-key 경로로 유지한다.
- 마스터키 수정 후 인증 관련 6개 테스트 파일 15건 통과, 변경 파일 diagnostics 오류 0건.
- 최종 재검증 완료: `C:/Flutter/bin/flutter.bat analyze lib/core/admin_connect_session.dart lib/features/login test/admin_connect_session_test.dart test/startup_login_service_test.dart test/user_access_serial_test.dart test/user_access_service_test.dart test/user_access_dao_test.dart test/user_access_serial_dialog_test.dart` 오류·경고 0건, `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공.
- 후속 stage/commit 대상: `lib/core/admin_connect_session.dart`, `test/admin_connect_session_test.dart`, `SESSION_HANDOFF.md`만 포함한다. 같은 사용자 요청의 보완이므로 버전은 `1.1.0`을 유지한다.
- 마스터키 후속 커밋: `666f094` (`00xx 마스터키 인증 분류 수정`).

## 완료·실물 검증 대기: 작은 한글 4배 supersampling 합성 v1.0.89
- v1.0.88 실물 `.tmp/IMG_20260809_0016.png`은 20% coverage 이진화 후 제2행 작은 한글이 굵고 네모지며 제3·9행 역상 한글 내부가 크게 비어 품질 개선에 실패했다. 로그 `.tmp/log/app_2026-08-09_16-00-55.log`는 `nativeTextCoverageKept=15379`, `nativeTextCoverageDiscarded=862`, `nativeTextFailed=0`으로 변경 적용은 정상임을 확인한다.
- 최종 11~17dot에서 먼저 rasterize한 glyph의 20% threshold를 바꾸는 접근은 원본 윤곽 정보가 부족해 재사용하지 않는다. v1.0.88 per-pixel coverage helper와 진단을 제거한다.
- `windows/runner/label_bitmap_print_channel.cpp` 편집 완료: final bitmap을 nearest 4배로 복제한 2480×1920 memory DIB에서 모든 native text를 최소 44px 높이로 GDI rasterize하고, 각 final dot의 4×4 luminance 평균을 threshold 128로 흑백 결정한다. 배경·border는 같은 값 16개로 복제됐다가 동일 값으로 복원되므로 fixed-X·1dot 좌표/두께를 유지한다. 모든 font height·색상·행·셀에 동일 적용하며 uniform overflow fit도 유지한다. diagnostics를 `nativeTextRaster=supersample4xBoxMonochrome128`로 변경했다.
- 최초 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug`는 실행 중인 Debug EXE 잠금으로 `LNK1168` 실패했다.
- Debug 앱 프로세스 종료 후 동일 `/WX` Windows build 재실행 성공. 출력 관련 5개 테스트 파일 18건 통과, 변경 파일 diagnostics 오류 0건, `git diff --check` 통과. 실패한 v1.0.88 `foregroundThreshold20` 코드가 제거된 것을 확인했다.
- 버전 편집 완료: `pubspec.yaml`을 `1.0.89`로 갱신했다.
- 1.0.89 최종 Windows 통합 검증 완료: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공, Debug EXE 생성.
- 최종 자동 검증 완료: Debug EXE `FileVersion/ProductVersion=1.0.89`, 변경 파일 diagnostics 오류 0건, `git diff --check` 통과. stage/commit 대상은 `windows/runner/label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md` 3개다.
- 기능 커밋: `c30a074` (`작은 한글 고해상도 합성 적용`).
- 실물 판별: 로그에 `nativeTextRaster=supersample4xBoxMonochrome128`, `nativeTextFailed=0`, `nativeTextBitmapChangedPixels>0`가 있어야 한다. 제2행 주원료의 작은 한글과 제3·9행 역상 한글의 내부 획·모서리가 v1.0.88보다 연속적이고 덜 네모져야 한다. 일반 글자·uniformScale overflow·표의 fixed-X·1dot border는 유지돼야 한다.

## 완료·실물 검증 대기: 작은 한글·역상 한글 coverage 합성 v1.0.88
- v1.0.87 실물 `.tmp/IMG_20260809_0015.png`은 표와 일반 크기 굴림은 안정적이나 제2행 주원료의 작은 한글과 검정 바탕인 제3·9행 흰색 한글의 획이 점처럼 끊기고 뭉개진다. 로그 `.tmp/log/app_2026-08-09_15-48-59.log`는 `version=1.0.87`, `nativeTextFitMode=uniformScale`, text 36개 모두 memory DIB에 합성, fit 13개, 실패 0을 확인한다.
- `NONANTIALIASED_QUALITY`는 v1.0.53 실물에서 계단과 획 단절이 악화돼 폐기됐으므로 재사용하지 않는다. 현재 원인은 final bitmap의 회색 GDI edge가 203dpi 흑백 프린터 변환에서 디더링·탈락하는 것이다.
- `windows/runner/label_bitmap_print_channel.cpp` 편집 완료: GDI anti-alias 결과를 각 descriptor의 coverage mask로 사용하되, 20% 이상 덮인 픽셀은 순수 전경색으로 확정하고 미만은 원래 배경으로 복원한다. 흰 배경 검정 글자와 검정 배경 흰 글자 모두 같은 수식이며 행·셀·색상·문구 분기 없음. font size, bold, 균일 overflow fit, 좌표, final 1dot border는 유지한다. diagnostics에 coverage mode와 kept/discarded pixel 수를 추가했다.
- 수정 직후 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. 출력 관련 5개 테스트 파일 18건 통과, 변경 파일 diagnostics 오류 0건, `git diff --check` 통과. 폐기한 `NONANTIALIASED_QUALITY`가 재도입되지 않은 것을 확인했다.
- 버전 편집 완료: `pubspec.yaml`을 `1.0.88`로 갱신했다.
- 1.0.88 최종 Windows 통합 검증 완료: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공, Debug EXE 생성.
- 최종 자동 검증 완료: Debug EXE `FileVersion/ProductVersion=1.0.88`, 변경 파일 diagnostics 오류 0건, `git diff --check` 통과. stage/commit 대상은 `windows/runner/label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md` 3개다.
- 기능 커밋: `fe80be0` (`작은 한글 획 품질 개선`).
- 실물 판별: 로그에 `nativeTextCoverage=foregroundThreshold20`, `nativeTextCoverageKept>0`, `nativeTextCoverageDiscarded>0`, `nativeTextFailed=0`가 있어야 한다. 제2행 주원료의 작은 한글과 제3·9행 검정 바탕 흰 한글의 끊긴 획이 이어져야 하며, 일반 글자·uniformScale overflow·표의 fixed-X·1dot border는 v1.0.87 상태를 유지해야 한다.

## 완료·실물 검증 대기: 굴림 overflow 장평 왜곡 제거 v1.0.87
- v1.0.86 실물 `.tmp/IMG_20260809_0014.png`은 표와 모든 굴림 텍스트가 출력됐고 마지막 행 `반품 및 교환...`은 품질이 좋지만, 다른 한글 다수는 획이 뭉개지고 장평이 불균일하다. 로그 `.tmp/log/app_2026-08-09_15-36-07.log`는 `nativeTextDrawn=36`, `nativeTextFailed=0`, `nativeTextFitted=13`, `nativeTextBitmapChangedPixels=20044`, memory-DIB 합성 적용을 확인한다.
- 마지막 행을 포함해 출력된 텍스트는 모두 v1.0.86 memory-DIB 경로다. 품질 차이의 제어 변수는 36개 중 13개 overflow descriptor에만 적용되는 `LOGFONT.lfWidth` 수평 장평 축소다. 과거 v1.0.64에서도 광범위한 `lfWidth` 보정이 셀별 장평·품질 회귀를 만들었으므로 같은 실패 방식을 재사용하지 않는다.
- `windows/runner/label_bitmap_print_channel.cpp` 편집 완료: overflow 대상은 `lfWidth`를 바꾸지 않고 `lfHeight`를 줄여 폭·높이를 같은 비율로 축소한다. 최대 4회 실측 fit과 2dot 안전 폭은 유지하고, v1.0.86 helper 이동에서 누락된 `kNativeTextRightOverhangDots=1`도 복원했다. diagnostics에 `nativeTextFitMode=uniformScale`을 추가했다. 특정 셀·행·문구 분기 없음.
- 수정 직후 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. 출력 관련 5개 테스트 파일 18건 통과, 변경 파일 diagnostics 오류 0건. `fitted_width`와 실행 중 비영(非零) `lfWidth` 대입이 남지 않은 것을 확인했다.
- 버전 편집 완료: `pubspec.yaml`을 `1.0.87`로 갱신했다.
- 1.0.87 최종 Windows 통합 검증 완료: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공, Debug EXE 생성.
- 최종 자동 검증 완료: Debug EXE `FileVersion/ProductVersion=1.0.87`, 변경 파일 diagnostics 오류 0건, `git diff --check` 통과. 변경 대상은 출력 C++, 버전, 이 문서 3개뿐이며 별도 임시 파일은 만들지 않았다.
- C++ 들여쓰기 정렬 후 최종 소스로 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 재실행 성공. stage/commit 대상은 `windows/runner/label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md` 3개다.
- 기능 커밋: `9cd6514` (`굴림 텍스트 장평 왜곡 제거`).
- 실물 판별: 로그에 `nativeTextComposite=finalDeviceBitmap`, `nativeTextFitMode=uniformScale`, `nativeTextFailed=0`, `nativeTextBitmapChangedPixels>0`가 있어야 한다. 마지막 행과 다른 한글이 같은 굴림 원래 비율로 보여야 하며, overflow 13개는 필요하면 폭·높이가 함께 작아질 수 있지만 가로만 찌그러지면 안 된다. 표의 fixed-X·1dot border와 제3·제9행 외곽선은 v1.0.85 상태를 유지해야 한다.

## 완료·실물 검증 대기: G500 resident 굴림 대체로 사라지는 native text 수정 v1.0.86
- v1.0.85 실물 `.tmp/IMG_20260809_0013.png`은 표·배경은 정상이나 글꼴을 모두 `굴림`으로 바꾼 뒤 텍스트가 전혀 출력되지 않았다. 로그 `.tmp/log/app_2026-08-09_15-15-31.log`는 `version=1.0.85`, `nativeTextRequested=36`, `nativeTextFonts=굴림`, `nativeTextDrawn=36`, `nativeTextFailed=0`, `nativeTextFitted=13`으로 앱과 `DrawTextW`는 성공 처리했다.
- Windows에는 `gulim.ttc`와 굴림 family가 정상 설치돼 있고 메모리 bitmap GDI 렌더는 `Resolved=굴림`, `InkPixels=297`로 정상이다. 사용자는 G500 드라이버 프린터 설정에도 내장 굴림을 설치했다. 따라서 Seagull 11.6 드라이버가 printer DC의 `CreateFontW("굴림")`을 resident font로 대체한 뒤 Unicode `DrawTextW`를 성공 반환하면서 실제 spool glyph는 버리는 것이 현재 가설이다.
- 수정 예정: `windows/runner/label_bitmap_print_channel.cpp`의 native text font output precision을 `OUT_TT_ONLY_PRECIS`로 바꿔 resident/device font 대체를 막고 Windows TrueType 굴림 outline만 선택한다. 선택 후 `TEXTMETRICW.tmPitchAndFamily & TMPF_TRUETYPE`을 집계해 로그에 TrueType/비TrueType 수를 남긴다. 텍스트 좌표·장평·native overflow-fit·border bitmap은 변경하지 않는다.
- `windows/runner/label_bitmap_print_channel.cpp` 편집 완료: `CreateFontW`를 `OUT_TT_ONLY_PRECIS`로 변경하고 `SelectObject` 실패를 native text 실패로 처리한다. 선택 직후 `GetTextMetricsW`로 `nativeTextTrueType`, `nativeTextDeviceOrRaster`, `nativeTextMetricsFailed`를 집계하고 `fontOutputPrecision=OUT_TT_ONLY_PRECIS`를 진단에 추가했다. `/WX` 빌드로 우선 검증 예정.
- printer DC 직접 probe 결과 `OUT_DEFAULT_PRECIS`와 `OUT_TT_ONLY_PRECIS` 모두 `face=굴림`, `trueType=false`, `pitch=0x00`으로 같아 precision만으로 resident 치환을 막는 가설은 반증됐다. 해당 printer-DC font type 진단 방식은 폐기했다. memory/printer DC 모두 `GetFontData`로 Windows 굴림 outline 13,531,160 bytes를 읽을 수 있어 드라이버의 spool 후단 치환을 우회해야 한다.
- `windows/runner/label_bitmap_print_channel.cpp` 재편집 완료: 기존 text 측정·장평 fitting·정렬 코드를 `RenderNativeTextIntoBitmap`으로 옮겼다. 최종 620×480 top-down memory DIB에 border/배경 bitmap을 복사하고 Windows 굴림 outline으로 텍스트를 그린 뒤 같은 BGRA bitmap을 단일 `SRCCOPY`로 출력한다. printer DC `DrawTextW`는 제거했으며 diagnostics는 `nativeTextMapping=anisotropicMemoryDib`, `nativeTextComposite=finalDeviceBitmap`, outline/no-outline count를 기록한다. `/WX` 빌드 예정.
- 최초 `/WX` Windows debug build 성공. `DrawTextW` 반환값과 별개로 memory DIB 합성 전후 BGR이 실제 달라진 픽셀 수를 세는 `nativeTextBitmapChangedPixels` 진단을 추가했다. 이 값이 실물 로그에서 양수면 텍스트가 spool 전 최종 bitmap에 들어간 것이다. 재빌드 예정.
- 변경 후 `/WX` Windows debug build 재성공, `test/label_sheet_print_job_test.dart` 전체 18건 통과, C++ `get_errors` 0건, `git diff --check` 통과. printer DC `DrawTextW`와 printer DC anisotropic text mapping 코드가 남지 않은 것도 확인했다.
- 버전 편집 완료: `pubspec.yaml`을 `1.0.86`으로 갱신했다.
- 최종 Windows 통합 검증 실행 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug`.
- 1.0.86 최종 Windows 통합 검증 완료: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공, Debug EXE 생성.
- 최종 확인 예정: EXE FileVersion/ProductVersion, 변경 파일 오류, `git diff --check`, stage 대상 점검.
- 최종 자동 검증 완료: Debug EXE `FileVersion/ProductVersion=1.0.86`, 변경 파일 `get_errors` 0건, `git diff --check` 통과. 별도 임시 파일은 만들지 않았고 Debug 빌드 산출물은 기존 ignored 경로에 있다.
- 실물 검증 필요: 글꼴을 모두 `굴림`으로 둔 동일 라벨을 출력해 텍스트 36개가 다시 보이고 표의 fixed-X·1dot 및 오른쪽 빈줄 제거 상태가 유지되는지 확인한다. 로그는 `nativeTextDrawn=36`, `nativeTextFailed=0`, `nativeTextOutlineFonts=36`, `nativeTextNoOutlineFonts=0`, `nativeTextBitmapChangedPixels>0`, `nativeTextMapping=anisotropicMemoryDib`, `nativeTextComposite=finalDeviceBitmap`이어야 한다.
- stage/commit 대상: `windows/runner/label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 기능 커밋: `a9af0d8` (`굴림 텍스트를 최종 비트맵에 합성`).

## 완료·실물 검증 대기: v1.0.84 native border footprint 과다 제외 회귀 수정 v1.0.85
- v1.0.84 실물 `.tmp/IMG_20260809_0012.png`와 로그 `.tmp/log/app_2026-08-09_14-56-50.log`를 확인했다. 로그는 version `1.0.84`, native border `225/225`, `sourceRasterResample=nearestCenter` 적용을 확인한다.
- 첫·두 번째 검정 띠의 왼쪽 경계는 인접 흰 행과 0~1 image px 차이로 v1.0.83의 약 3 image px 바깥 돌출은 사라졌지만, 사용자 지적대로 선이 안쪽으로 들어가 보인다. 오른쪽은 검정 배경 끝과 native 외곽선 사이에 약 4 image px(1 device dot)의 흰 세로 간격이 새로 생겼다.
- v1.0.83 raster ink `44749` 대비 v1.0.84는 `41414`로 3335px 감소했다. 원인은 화면용 border `logicalPaintedFootprint` 전체 폭(203.2dpi에서 약 2.12 source px)을 모든 인접 셀 배경에서 제외했지만 최종 native border는 1 device dot뿐인 폭 불일치다.
- 수정 예정: 승인된 border의 오른쪽/아래쪽 셀 배경에서 경계 첫 source raster pixel 1개만 제외한다. 왼쪽/위쪽 셀의 오른쪽·아래 경계 배경은 제외하지 않아 native 선 바로 안쪽까지 배경이 이어지게 한다. 특정 행·셀 분기 및 C++ 출력 후 clear는 사용하지 않는다.
- 테스트 편집 완료: 기존 테스트에 실제 approved border candidate를 넣고 경계 첫 pixel은 white, 바로 다음 pixel은 black이어야 하는 `hybrid capture reserves one raster dot for native border` 계약으로 강화했다. 구현 전 실패 확인 예정.
- 구현 전 검증: 강화 테스트는 바로 다음 pixel black 기대가 false로 실패해 v1.0.84의 전체 footprint 과다 제외를 재현했다.
- 1 source pixel difference clip 시도는 테스트 RGBA에서 X=42·43 white, X=44 gray, X=45 black으로 실제 2px 공백을 만들어 폐기했다. hard-edge difference clip 자체가 경계를 바깥으로 확장하므로 재사용하지 않는다.
- `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 편집 완료: footprint/strip 제외를 모두 제거하고, 승인된 native cell border가 있는 hybrid capture에서 셀 배경 `drawRect`를 `isAntiAlias=false`로 그린다. 배경 시작·끝이 동일 pixel grid의 nearest boundary에 맞으므로 왼쪽 바깥 AA coverage와 오른쪽 내부 빈줄을 동시에 만들지 않는다. 일반 screenshot과 raster fallback-only capture는 기존 anti-alias 경로를 유지한다. 집중 테스트 재실행 예정.
- no-AA capture 진단은 왼쪽 배경에서 X=42 outside white, X=43 native line slot white, X=44부터 solid black을 확인했다. 전체-footprint 방식의 X=44 gray/X=45 black보다 배경이 정확히 1px 선에 붙는다. 테스트를 오른쪽 셀의 left edge와 왼쪽 셀의 right edge 양방향으로 확장했으며 임시 RGBA 출력은 제거했다.
- 반대 방향 진단에서 왼쪽 검정 셀의 right edge는 X=42와 native line slot X=43까지 solid black이었다. native 선이 동일 픽셀을 검정으로 덮으므로 공백 없는 올바른 합성이며, 테스트 기대도 line slot underpaint를 허용하도록 수정했다.
- 집중 검증 완료: FortuneSheet 패키지에서 `C:/Flutter/bin/flutter.bat test test/fortune_print_capture_test.dart --plain-name "hybrid capture pixel-aligns backgrounds to native borders"` 통과.
- 다음 검증 예정: 수정 Dart 파일 포맷, FortuneSheet 캡처 테스트 전체, 루트 `test/label_sheet_print_job_test.dart`, `/WX` Windows debug build.
- 포맷 및 패키지 검증 완료: 수정 Dart 2개 파일 `dart format` 적용, FortuneSheet `test/fortune_print_capture_test.dart` 전체 10건 통과.
- 앱 레벨 검증 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_print_job_test.dart`.
- 앱 레벨 검증 완료: `test/label_sheet_print_job_test.dart` 전체 18건 통과. 수정 파일 `get_errors` 0건, `git diff --check` 통과, 폐기한 footprint/strip 및 임시 RGBA 진단 코드 없음.
- 버전 편집 완료: `pubspec.yaml`을 `1.0.85`로 갱신했다.
- Windows 통합 검증 실행 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug`.
- Windows 통합 검증 완료: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공, Debug EXE 생성.
- 최종 확인 예정: EXE FileVersion/ProductVersion, 변경 파일 `get_errors`, `git diff --check`, stage 대상 점검.
- 최종 자동 검증 완료: Debug EXE `FileVersion/ProductVersion=1.0.85`, 변경 파일 `get_errors` 0건, `git diff --check` 통과. 별도 임시 파일은 만들지 않았고 Debug 빌드 산출물은 기존 ignored 경로에 있다.
- 실물 검증 필요: v1.0.85로 동일 라벨을 출력해 제3·제9행 왼쪽 외곽선이 인접 흰 행보다 바깥/안쪽으로 1dot 이동하지 않는지, 같은 검정 행 오른쪽 외곽선 안쪽의 흰 세로줄이 사라졌는지 확인한다. 다른 세로선 fixed-X·1dot, native text, overflow-fit도 함께 유지돼야 한다.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_print_capture_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 기능 커밋: `b7b3796` (`네이티브 테두리 배경의 빈줄을 제거`).

## 완료·실물 검증 대기: native border와 source raster 배경의 경계 소유권 통일 v1.0.84
- v1.0.83 실물 완료 판정을 철회한다. `.tmp/IMG_20260809_0011.png`에서 첫 검정 띠의 왼쪽 경계는 인접 흰 행 X=1167 대비 X=1164, 두 번째는 X=1166 대비 X=1163으로 약 3 image px(약 1 device dot) 왼쪽이다. `.tmp/IMG_20260809_0010.png`도 같은 상대 이동이 있었으나 전체 X 분포만 보고 완료로 잘못 판정했다.
- 정상 기준 `.tmp/IMG_v1.0.44.png`는 동일한 3000×2102 사진에서 검정 띠와 앞뒤 흰 행의 왼쪽 경계가 모두 X=1176으로 일치한다. 따라서 남은 돌출은 촬영 원근이나 프린터 번짐이 아니라 v1.0.83 렌더 경로의 행별 차이다.
- 현재 가설: 승인된 cell border는 source raster에서 생략하고 final-device bitmap에 native 1dot으로 그리지만, 검정 셀 배경은 생략된 border 중심선까지 source raster에 남는다. 640→620 재표본화 phase와 border `MulDiv` 양자화가 달라 검정 배경이 native 외곽선 바깥 1dot을 소유한다.
- 수정 예정: `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`에서 hybrid capture의 승인된 native border footprint만 셀 배경에서 제외해 배경과 border의 경계 소유권을 통일하고, `third_party/fortune_sheet/test/fortune_print_capture_test.dart`에 검정 배경이 생략된 외곽 border 바깥으로 남지 않는 회귀 테스트를 추가한다. 특정 행·셀·품목 분기나 C++ 강제 흰색 후처리는 사용하지 않는다. 상태: 미검증.
- 테스트 편집 완료: `hybrid capture reserves approved native border footprint`를 추가했다. 최초 1:1 정수 경계 테스트는 기존 구현에서도 통과해 FortuneSheet의 기본 rect rasterization 자체가 원인이라는 가설을 반증했다. 실제 장치 배율 `203.2/96`과 소수 셀 경계에서 raster `floor`와 native descriptor `round` 위상 차이를 재현하도록 강화했으며 구현 전 실패 확인 예정이다.
- 구현 전 검증: 강화한 회귀 테스트는 경계 픽셀 white 기대가 false로 실패해 소수 경계의 raster/native 양자화 불일치를 재현했다.
- `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 편집 완료: 최초 셀 border 재계산 방식은 border가 인접 셀 한쪽에 귀속될 때 검정 배경 셀에서 선을 찾지 못해 회귀 테스트에 실패했다. 이를 제거하고 `FortuneHybridRenderPlan.candidates`의 승인된 `logicalPaintedFootprint`를 capture에 직접 전달한다. `_drawScreenshotCellBackground`는 실제 native footprint와 겹치는 배경만 비안티앨리어스 clip으로 제외하므로 병합·인접 셀 귀속·stroke width를 재추정하지 않는다. raster fallback border나 border가 없는 배경은 기존 `drawRect`를 유지하며 특정 셀 분기 및 출력 후 clear는 없다. 회귀 테스트 재실행 예정.
- 집중 검증 완료: `C:/Flutter/bin/flutter.bat test test/fortune_print_capture_test.dart --plain-name "hybrid capture reserves approved native border footprint"` 통과. 소수 경계 바깥 raster coverage가 흰색이고 native footprint 안쪽의 검정 배경은 유지된다.
- 다음 검증 예정: FortuneSheet 캡처 테스트 전체, 루트 `test/label_sheet_print_job_test.dart`, `/WX` Windows debug build를 순서대로 실행한다.
- 포맷 및 패키지 검증 완료: 수정한 Dart 2개 파일을 `dart format`으로 정리했고, FortuneSheet 패키지에서 `C:/Flutter/bin/flutter.bat test test/fortune_print_capture_test.dart` 전체 10건 통과.
- 앱 레벨 검증 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_print_job_test.dart`.
- 앱 레벨 검증 완료: `C:/Flutter/bin/flutter.bat test test/label_sheet_print_job_test.dart` 전체 18건 통과. 수정 Dart 파일 `get_errors` 0건, `git diff --check` 통과.
- 버전 편집 완료: `pubspec.yaml`을 `1.0.84`로 갱신했다.
- Windows 통합 검증 실행 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug`.
- Windows 통합 검증 완료: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공, `build/windows/x64/runner/Debug/label_manager.exe` 생성.
- 최종 확인 예정: Debug EXE FileVersion/ProductVersion, 전체 변경 파일 `get_errors`, `git diff --check`, stage 대상 점검.
- 최종 자동 검증 완료: Debug EXE `FileVersion/ProductVersion=1.0.84`, 변경 파일 `get_errors` 0건, `git diff --check` 통과. 별도 임시 파일은 만들지 않았고 Debug 빌드 산출물은 기존 ignored 경로에 있다.
- 실물 검증 필요: v1.0.84로 동일 라벨을 출력해 제3·제9행 검정 띠의 맨 왼쪽 경계가 인접 흰 행 외곽선보다 1dot 왼쪽으로 나오지 않는지 확인한다. 다른 세로선의 fixed-X·1dot, native text, overflow-fit도 함께 유지돼야 한다.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_print_capture_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`만 포함한다.
- 기능 커밋: `b151589` (`네이티브 테두리와 배경 경계를 일치`).

## 완료·실물 재검증 실패: source raster 검정 팽창 감소 v1.0.83
- v1.0.82 실물 `.tmp/IMG_20260809_0009.png`에서도 제3·제9행 맨 왼쪽 외곽 세로선의 바깥 돌출이 남았다. 로그 `.tmp/log/app_2026-08-09_14-28-27.log`는 version `1.0.82`, `nativeBorderOuterClearPixels=73`을 확인해 바깥 1dot 강제 제거는 실행됐지만 효과가 없었다. 사용자 지적대로 증상 후처리이며 원인 해결이 아니므로 전부 제거했다.
- FortuneSheet capture는 셀 배경을 정확한 셀 `Rect`에 먼저 그리고, 승인된 border edge만 source raster에서 생략한다. C++은 이 border 없는 640×480 raster를 620×480으로 줄이면서 destination 픽셀의 source 영역을 bitwise AND하는 소프트웨어 BLACKONWHITE를 사용했다.
- 원인: BLACKONWHITE는 source 영역 중 하나라도 검정이면 destination을 검정으로 만들어 검정 셀 배경 경계를 수평으로 팽창시킨다. 과거 COLORONCOLOR에서 유실되던 1px border는 현재 source raster에서 생략되고 final-device 1dot으로 별도 합성되므로 이 보존 필터를 유지할 이유가 없다.
- 일반화 수정: v1.82의 외곽 강제 clear를 제거하고, source raster를 destination 픽셀 중심 기준 nearest sampling으로 축소한다. 셀 배경의 논리 경계를 팽창시키지 않은 최종 bitmap에 기존 final-device 1dot border를 합성한다. 특정 행·셀·색상·품목 분기 없음.
- diagnostics를 `sourceRasterResample=nearestCenter`, `stretchMode=COLORONCOLOR_1TO1`로 변경한다. 기존 `nativeBorderJunction=singleFinalDeviceBitmap`, `nativeBorderComposite=finalDeviceBitmap`, native text 경로는 유지한다. 버전 `1.0.83`; `flutter test test/label_sheet_print_job_test.dart` 전체 18건 통과, `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 수정 직후·버전 반영·1:1 출력 모드 정리 후 모두 성공, Debug EXE `FileVersion/ProductVersion=1.0.83`, `get_errors` 0건, `git diff --check` 통과. 강제 외곽 clear와 영역 AND 축소 코드가 없는 것도 확인했다. 실물에서 제3·제9행 왼쪽 돌출이 제거되고 다른 세로선·1dot 및 raster fallback 품질이 유지되는지 확인이 필요하다.
- 기능 커밋: `8a4bd2f` (`인쇄 래스터의 검정 팽창을 제거`).
- 실물 검증: `.tmp/IMG_20260809_0009.png`는 생성 시각 14:29:33으로 v1.0.82 출력이며, 검정 행에서 왼쪽 최초 검정 픽셀이 정상 X=1156~1157보다 X=1150~1151로 5~7 image px 돌출됐다. `.tmp/IMG_20260809_0010.png`는 v1.0.83 출력 로그 14:34:30 직후 생성됐고, 전체 왼쪽 경계가 X=1161~1165 범위에 연속 분포해 검정 행만의 별도 왼쪽 돌출 군집이 사라졌다. 육안과 픽셀 추적 모두 지정 돌출 제거를 확인했다.
- 실물 검증 커밋: `61e25af` (`1.0.83 외곽선 실물 검증 기록`).

## 완료·실물 검증 대기: final bitmap 외곽 바깥 1dot overflow 제거 v1.0.82
- v1.0.81 실물 `.tmp/IMG_20260809_0008.png`에서 v1.80의 안쪽 흰 세로선은 사라졌지만 제3·제9행 맨 왼쪽 외곽선의 바깥 돌출은 남았다. 로그 `.tmp/log/app_2026-08-09_13-49-20.log`는 version `1.0.81`, `stretchMode=softwareBLACKONWHITE`, `nativeBorderJunction=singleFinalDeviceBitmap`, border `225/225`를 확인해 단일 bitmap 경로는 정상 적용됐다.
- 원인: BLACKONWHITE 축소는 source 영역 중 하나라도 검정이면 final-device 픽셀을 검정으로 보존하므로, 검정 셀 배경의 경계 source 픽셀이 외곽 세로 border 바로 바깥 1dot까지 확장된다. 별도 GDI 합성이나 가로 endpoint 문제가 아니다.
- 일반화 수정: source raster 축소 후 border를 그리기 전에 각 final-device Y에서 실제 vertical descriptor들의 최소 left와 최대 right를 구한다. 세로 border가 존재하는 Y에 한해 `left - 1`, `right`의 바깥쪽 1dot만 흰색으로 정리한 뒤 모든 1dot border를 같은 bitmap에 그린다.
- v1.80처럼 외곽선 안쪽을 지우지 않으므로 검정 행 앞·뒤의 흰 세로선 회귀를 만들지 않는다. 특정 행·셀·품목 분기 없이 최외곽 vertical geometry로만 동작하며 내부 세로선과 native text는 변경하지 않는다.
- diagnostics: `nativeBorderOuterClearance=exteriorOneDeviceDot`, `nativeBorderOuterClearPixels`. 버전 `1.0.82`; `flutter test test/label_sheet_print_job_test.dart` 전체 18건 통과, `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 수정 중간·버전 반영·스타일 정리 후 모두 성공, Debug EXE `FileVersion/ProductVersion=1.0.82`, `get_errors` 0건, `git diff --check` 통과. 폐기한 `WHITE_BRUSH`, `SRCAND`, endpoint guard가 없는 것도 확인했다. 실물 로그에서 `nativeBorderOuterClearPixels`가 양수인지, 제3·제9행 왼쪽 바깥 돌출이 제거되고 안쪽 흰 세로선 없이 나머지 세로선·1dot이 유지되는지 확인이 필요하다.
- 기능 커밋: `fa9ca91` (`최종 비트맵의 외곽 돌출을 제거`).

## 완료·실물 검증 대기: raster와 1dot border 단일 final-device bitmap 합성 v1.0.81
- v1.0.80 실물 `.tmp/IMG_20260809_0007.png`에서 제3·제9행 왼쪽 돌출은 남았고, 해당 검정 행의 앞·뒤에 이전에 없던 흰 세로선이 생겼다. 로그 `.tmp/log/app_2026-08-09_13-38-44.log`는 version `1.0.80`, `nativeBorderOuterRasterClearPixels=146`을 확인해 프린터 DC의 흰 덮기가 실제 회귀 원인이다.
- v1.0.80의 `WHITE_BRUSH` 접촉부 제거와 v1.0.77~79의 endpoint 보정은 모두 제거했으며 재사용하지 않는다. 별도 native border `SRCAND` 합성도 제거했다.
- 일반화 수정: 640×480 source raster를 소프트웨어 BLACKONWHITE 방식으로 최종 620×480 device bitmap에 먼저 축소한다. 모든 border descriptor를 같은 최종 bitmap 좌표에 정확히 1dot으로 직접 합성한 뒤 프린터에는 620×480 bitmap을 단일 `SRCCOPY`로 1:1 출력한다. native text는 기존 anisotropic `DrawTextW` 경로를 그대로 유지한다.
- 이 구조는 v1.44처럼 배경과 border 교차 형상을 한 bitmap이 소유하면서, v1.75 이후의 고정-X final-device 1dot 좌표를 유지한다. 특정 행·셀·품목 분기와 흰 픽셀 보정이 없다.
- diagnostics: `stretchMode=softwareBLACKONWHITE`, `nativeBorderJunction=singleFinalDeviceBitmap`, `nativeBorderComposite=finalDeviceBitmap`, `nativeBorderBitmapLines`. 버전 `1.0.81`; `flutter test test/label_sheet_print_job_test.dart` 전체 18건 통과, `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 수정 중간과 버전 반영 후 모두 성공, Debug EXE `FileVersion/ProductVersion=1.0.81`, `get_errors` 0건, `git diff --check` 통과. 폐기한 `WHITE_BRUSH`, `SRCAND`, endpoint/outer-raster clearance 코드가 남지 않은 것도 확인했다. 실물에서 제3·제9행 왼쪽 돌출과 v1.80의 흰 세로선이 모두 없어지고 나머지 세로선·1dot이 유지되는지 확인이 필요하다.
- 기능 커밋: `8d8009b` (`배경과 테두리를 최종 비트맵에 합성`).

## 완료·실물 검증 대기: 검정 raster와 외곽 세로선 접촉 분리 v1.0.80
- v1.0.79 실물 `.tmp/IMG_20260809_0006.png`에서도 세 번째·아홉 번째 행 맨 왼쪽 외곽 세로선의 바깥 돌출 점선이 남았다. 로그 `.tmp/log/app_2026-08-09_13-29-44.log`는 version `1.0.79`, border `225/225`, `nativeBorderOuterEndpointClearance=twoDeviceDots`, guard `28`건을 확인해 2dot 가로 endpoint 보정은 실제 적용됐다.
- 사진에서 돌출 구간은 두 개의 검정 배경 행과 정확히 일치한다. 가로 endpoint를 1dot·2dot으로 줄여도 동일하므로 원인은 가로 border가 아니라 source raster의 검정 셀 배경과 final-device native 외곽 세로선이 맞닿는 혼합 교차부 열 밀도다. v1.0.77~79 endpoint 방식은 재사용하지 않도록 제거했다.
- 일반화 수정: 최종 device border를 먼저 병합해 전체 vertical 중 최소 X와 최대 X를 외곽 boundary로 구한다. source raster를 출력한 뒤, 각 외곽 세로 segment의 안쪽 인접 source 픽셀이 실제 검정인 Y에서만 안쪽 1 device dot을 `WHITE_BRUSH`로 비운다. 이후 기존 native bitmap mask가 외곽 세로선 1dot을 다시 합성한다.
- 특정 행·셀·품목 분기 없이 raster 검정 접촉 여부로만 동작한다. 흰 셀 행, 내부 세로선, native text는 변경하지 않는다. diagnostics: `nativeBorderJunction=outerRasterContactClearance`, `nativeBorderOuterRasterClearance=oneDeviceDot`, `nativeBorderOuterRasterClearPixels`.
- 버전 `1.0.80`; `flutter test test/label_sheet_print_job_test.dart` 전체 18건 통과, `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 수정 직후와 버전 반영 후 모두 성공, Debug EXE `FileVersion/ProductVersion=1.0.80`, `get_errors` 0건, `git diff --check` 통과. 실물 로그에서 `nativeBorderOuterRasterClearPixels`가 양수인지, 제3·제9행 왼쪽 돌출이 제거되고 나머지 세로선·1dot이 유지되는지 확인이 필요하다.
- 기능 커밋: `868adae` (`검정 배경과 외곽선 접촉을 분리`).

## 완료·실물 검증 대기: 외곽 endpoint 2dot clearance v1.0.79
- v1.0.78 실물 `.tmp/IMG_20260809_0005.png`에서도 세 번째·아홉 번째 행 맨 왼쪽 외곽 세로선의 바깥 돌출 점선이 남았다. 최신 로그 `.tmp/log/app_2026-08-09_12-54-08.log`는 version `1.0.78`, border `225/225`, `nativeBorderOuterEndpointGuards=28`을 확인해 병합 후 guard는 실제 적용됐다.
- v1.0.77·78 동일 해상도 사진의 지정 경계 최초 검정 픽셀을 비교하면 일부 X 형상은 오른쪽으로 이동해 1dot guard가 mask에 영향을 줬지만 돌출 제거에는 부족했다. 코드 미적용이나 중복 segment 재채움이 아니라 1dot 흰 간격으로 교차부 열 누적을 상쇄하지 못한 결과다.
- v1.0.78의 1dot guard는 재사용하지 않는다고 코드에 명시했다. 병합된 가로선의 외곽 endpoint에만 세로선과 2 device dot 흰 clearance를 두도록 확대했다. 내부 교차점은 endpoint가 아니므로 변경하지 않고, 세로선 X·1dot 두께와 native text는 그대로 유지한다.
- diagnostics에 `nativeBorderOuterEndpointClearance=twoDeviceDots`를 추가했다. 버전 `1.0.79`; `flutter test test/label_sheet_print_job_test.dart` 전체 18건 통과, `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 수정 직후와 버전 반영 후 모두 성공, Debug EXE `FileVersion/ProductVersion=1.0.79`, `get_errors` 0건, `git diff --check` 통과. 실물 출력에서 제3·제9행 왼쪽 돌출 제거와 나머지 세로선·1dot 유지 확인이 필요하다.
- 기능 커밋: `76e0479` (`외곽선 끝점 여백을 2도트로 확대`).

## 완료·실물 검증 대기: 병합 후 외곽 endpoint 1dot guard v1.0.78
- v1.0.77 실물 `.tmp/IMG_20260809_0004.png`에서 세 번째·아홉 번째 행 맨 왼쪽 외곽 세로선의 바깥 돌출 점선이 그대로 재현됐다. 로그 `.tmp/log/app_2026-08-09_12-47-58.log`는 version `1.0.77`, border `225/225`, `nativeBorderJunctionSnaps=62`를 확인해 코드 미적용 문제가 아니다.
- 사진 픽셀 추적에서 외곽 세로선의 정상 X는 약 1159~1162지만 해당 행 경계에서만 1154~1157까지 왼쪽 검정 픽셀이 생겼다. 세로 segment 전체가 행별로 이동한 것이 아니라 가로선 endpoint 교차부 형상이다.
- v1.0.77의 병합 전 snap은 중복 border descriptor가 후속 merge에서 최종 mask endpoint를 다시 채울 수 있고, 세로선 바로 옆의 검정 dot도 남긴다. 해당 방식은 코드에 재사용 금지 코멘트를 남기고 제거했다.
- 일반화 수정: 모든 border를 final device에서 먼저 병합한 뒤, 병합된 가로선의 왼쪽·오른쪽 외곽 endpoint가 해당 Y의 세로 boundary와 ±1dot 이내인 경우에만 세로선과 가로선 사이에 흰색 1 device dot guard를 둔다. 내부 세로 교차점은 병합된 가로선의 endpoint가 아니므로 변경하지 않고, 세로선 X·1dot 두께와 native text는 유지한다.
- diagnostics: `nativeBorderJunction=mergedOuterEndpointGuard`, `nativeBorderOuterEndpointGuards`. 버전 `1.0.78`; `flutter test test/label_sheet_print_job_test.dart` 전체 18건 통과, `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 수정 직후와 버전 반영 후 모두 성공, Debug EXE `FileVersion/ProductVersion=1.0.78`, `get_errors` 0건, `git diff --check` 통과. 실물 출력에서 제3·제9행 왼쪽 돌출 제거와 나머지 세로선·1dot 유지 확인이 필요하다.
- 기능 커밋: `3c24de9` (`외곽선 끝점에 1도트 여백 적용`).

## 완료·실물 검증 대기: 외곽 가로 endpoint 1dot 오차 정렬 v1.0.77
- v1.0.76 실물 `.tmp/IMG_20260809_0003.png`에도 세 번째 행 맨 왼쪽 외곽 세로선의 반복 돌출이 남았다. 최신 로그 `.tmp/log/app_2026-08-09_12-42-28.log`는 `nativeBorderJunctionTrims=31`과 border `225/225`를 확인해 overlap trim은 실행됐지만 지정 현상에는 효과가 없었다.
- v1.74·75·76 동일 해상도 사진에서 각 Y의 표 왼쪽 첫 검정 픽셀을 추적했다. v1.74는 원근 기울기만 있는 매끄러운 X 궤적이고, v1.75·76은 행 경계에서 왼쪽으로 1 device dot에 해당하는 약 4~7 image px 급락이 반복됐다.
- 원인 정정: v1.76의 overlap-only trim은 최종 mask OR 결과를 바꾸지 않으며, 지정 외곽 가로 endpoint는 세로선과 겹친 것이 아니라 device 양자화 후 왼쪽으로 1dot 어긋나 조건에도 잡히지 않았다. 해당 방식은 코드에 재사용 금지 코멘트를 남기고 제거했다.
- 일반화 수정: 가로 endpoint와 해당 Y를 덮는 세로 boundary의 final device X 차이가 ±1dot이면 세로선 위치로 snap한다. 왼쪽 endpoint는 세로선 오른쪽부터 시작하고 오른쪽 endpoint는 세로선 왼쪽에서 끝난다. 세로선 X·1dot 두께는 변경하지 않으며, trim 후 최소 길이 조건도 유지한다.
- diagnostics를 `nativeBorderJunction=snapToVertical`, `nativeBorderJunctionSnaps`로 변경했다. 버전 `1.0.77`; `flutter test test/label_sheet_print_job_test.dart` 전체 18건 통과, `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공, Debug EXE `FileVersion/ProductVersion=1.0.77`, `get_errors` 0건, `git diff --check` 통과. 실물 출력에서 지정 외곽 돌출 제거와 나머지 세로선·1dot 유지 확인이 필요하다.
- 기능 커밋: `aed750d` (`외곽선 교차점 1도트 오차 정렬`).

## 완료·실물 검증 대기: 외곽 왼쪽 교차점 돌출 제거 v1.0.76
- v1.0.75 실물 `.tmp/IMG_20260809_0002.png`: 다른 세로선의 행별 지그재그는 사라지고 전체 테두리 `1px == 1dot`은 충족했다. 다만 세 번째 행 맨 왼쪽 외곽 세로선은 가로 행 경계마다 바깥쪽 돌출이 다시 보인다.
- 최신 로그 `.tmp/log/app_2026-08-09_12-35-07.log`: version `1.0.75`, `nativeBorderDescriptors=225`, `nativeBordersRequested=225`, `nativeBordersDrawn=225`, `nativeBorderThickness=oneDeviceDot`, `nativeBorderComposite=bitmapMask`로 외곽 포함 전체 border가 final device mask에 적용됐고 source raster 중복은 없다.
- 원인: half-open device rect에서 각 가로 segment의 왼쪽 픽셀이 해당 세로선의 1dot 열과 겹친다. 내부 교차점은 양쪽 선 때문에 두드러지지 않지만, 왼쪽 외곽에서는 교차점의 인접 가열이 여백 쪽 반복 돌출로 보인다.
- 일반화 수정: C++ final device mask 생성 전에 세로 rect가 해당 Y의 가로 rect를 실제 덮는 교차점만 찾고, 가로선 시작/끝이 세로선과 겹치면 세로선 바깥쪽으로 trim한다. 세로선이 교차점 픽셀을 소유하며 가로선은 바로 옆 1dot부터 이어진다. 세로선 좌표·두께와 내부 1dot 연속성은 변경하지 않으며 특정 셀·행 분기 없음.
- 1dot 길이의 극단적인 가로 segment가 사라지지 않도록 trim 후 최소 1dot 길이가 남을 때만 적용한다. Windows diagnostics에 `nativeBorderJunction=verticalOwnsIntersection`, `nativeBorderJunctionTrims`를 추가했다.
- 버전 `1.0.76`; 출력 job 전체 18건 통과. C++ 수정 직후와 버전 반영 후 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 모두 성공. Debug EXE FileVersion/ProductVersion 모두 `1.0.76`, 변경 파일 diagnostics 오류 0건, `git diff --check` 통과.
- 실물 로그 판별: 기존 `nativeBorderThickness=oneDeviceDot`, `nativeBorderComposite=bitmapMask`, border 요청/출력 수 일치에 더해 `nativeBorderJunction=verticalOwnsIntersection`, `nativeBorderJunctionTrims` 양수가 기록되어야 한다. 다른 세로선의 동일 X·1dot을 유지하면서 왼쪽 외곽 행 교차점의 돌출만 없어야 한다.
- 커밋 대상: `windows/runner/label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `a2d84b3` (`외곽선 교차점 돌출을 제거`).

## 완료·실물 검증 대기: 외곽 개선 유지 + 전체 세로선 final device 1dot v1.0.75
- v1.0.74 실물 `.tmp/IMG_20260809_0001.png`: 지정한 세 번째 행 맨 왼쪽 외곽 교차점 돌출은 개선됐지만, 모든 border를 source raster로 복원하면서 640→620 축소에 의해 다른 세로선의 X가 행별로 이동하는 지그재그와 1dot보다 두꺼운 선이 재현됐다.
- 원인: FortuneSheet cell border candidate는 1px stroke footprint가 printer clip 밖으로 0.5px라도 나가면 외곽선을 후보에서 제외했다. v1.0.73의 final device 1dot mask에는 내부선만 들어가고 외곽선은 source raster에 남아 혼합 교차점 돌출이 발생했다. v1.0.74는 혼합을 없앴지만 전체 source raster 축소 회귀를 만들었다.
- 일반화 수정: 공용 `_buildCellBorderCandidates`에서 border footprint가 clip과 교차하면 clipped footprint로 후보를 유지한다. Windows descriptor 좌표는 clipped footprint 중심이 아니라 sheet row/column의 실제 logical boundary를 printer dot으로 변환한다.
- 결과 구조: 모든 승인 가능한 검정 실선 cell border의 외곽·내부 가로/세로선이 source raster에서 함께 생략되고, C++ final device bitmap mask에서 정확히 1dot으로 함께 합성된다. 지정 외곽 교차점은 동일 mask 소유권을 유지하고, 다른 세로선은 source 640→target 620 축소를 거치지 않는다. 특정 셀·행·품목 분기 없음.
- `fortune_print_plan.dart`: clip에 일부 걸친 외곽 border candidate 유지. `label_sheet_print_job.dart`: 실제 grid boundary 기반 1dot descriptor 복원. 테스트 2개에 clip 외곽 네 변 후보, descriptor 4개 승인, 1dot 두께, half-open 네 모서리 접합 계약 추가.
- 단일 셀 외곽 네 변 및 2×2 다중 행 세로 boundary focused 테스트 통과. 출력 준비·dispatch·session·설정·pipeline과 FortuneSheet capture/plan 관련 7개 파일 81건 모두 통과. 최종 `label_sheet_print_job_test.dart` 전체 18건 재통과.
- 변경 파일 diagnostics 오류 0건, `git diff --check` 통과. 버전 `1.0.75`; Windows 검증 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. Debug EXE FileVersion/ProductVersion 모두 `1.0.75`.
- 실물 로그 판별: `nativeBorderDescriptors`가 표의 승인 가능한 검정 실선 edge 전체 수와 같고, Windows diagnostics가 `nativeBorderThickness=oneDeviceDot`, `nativeBorderComposite=bitmapMask`, `nativeBordersDrawn` 동일 수여야 한다. 지정 외곽 교차점 돌출은 없어야 하며 모든 세로선은 행 전체에서 동일 X의 1dot이어야 한다.
- 커밋 대상: `third_party/fortune_sheet/lib/src/fortune_print_plan.dart`, `third_party/fortune_sheet/test/fortune_hybrid_print_plan_test.dart`, `lib/printing/label_sheet_print_job.dart`, `test/label_sheet_print_job_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `9cf4183` (`모든 표 테두리를 1dot 실선으로 출력`).

## 완료·실물 검증 대기: 외곽 세로선 교차점 돌출 제거 v1.0.74
- 실물 재비교: `.tmp/IMG_v1.0.73.png`의 세 번째 행 맨 왼쪽 외곽 세로선에는 각 가로 행 경계 위치마다 바깥쪽 돌출 픽셀이 반복되지만, `.tmp/IMG_v1.0.44.png`의 같은 위치에는 없다. 따라서 이전의 `프린터 열전사 번짐으로 개선 불가` 결론은 이 현상에 대해서는 철회한다.
- 원인: v1.0.44는 모든 cell border를 최종 FortuneSheet raster 한 장에서 함께 그렸다. v1.0.73은 clip 외곽의 왼쪽 세로선은 raster에 남고 승인된 가로선은 native border descriptor로 분리되어, 서로 다른 rasterization의 교차점에서 가로선 끝점이 외곽 세로선 바깥으로 반복 돌출됐다.
- 일반화 수정: Windows hybrid의 cell border를 native 승인하지 않고 모두 FortuneSheet raster에 유지한다. 특정 행·셀·품목 분기 없이 표의 외곽선과 내부 가로·세로선을 하나의 painter/bitmap에서 함께 합성한다. native text와 overflow fit은 그대로 유지한다.
- `label_sheet_print_job.dart`: Windows `borderDescriptors`와 `approvedCellBorderEdgeKeys`를 비워 v1.0.44와 같은 단일 raster border 소유권으로 복원했다.
- `label_sheet_print_job_test.dart`: 계약을 `Windows hybrid keeps cell borders in one raster surface`로 변경해 native border descriptor와 승인 edge가 모두 비어 있는지 검증한다.
- focused 계약 테스트 1건 통과. 출력 준비·dispatch·session·설정·pipeline과 FortuneSheet capture/plan 관련 7개 파일 79건 모두 통과. 변경 파일 diagnostics 오류 0건.
- `pubspec.yaml`: 버전 `1.0.74`로 증가했다. Windows 검증 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. Debug EXE FileVersion/ProductVersion 모두 `1.0.74`, `git diff --check` 통과, 변경 파일 diagnostics 오류 0건.
- 커밋 대상: `lib/printing/label_sheet_print_job.dart`, `test/label_sheet_print_job_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 실물에서는 v1.0.73과 같은 세 번째 행 맨 왼쪽 외곽 세로선에서 가로 행 경계마다 바깥쪽 돌출 픽셀이 사라졌는지 확인한다.
- 기능 커밋: `0e2e8a6` (`표 외곽선의 교차점 돌출 제거`).

## 완료: FortuneSheet 기본 테두리 1px -> 1dot v1.0.73
- 사용자 요청에 따라 FortuneSheet cell border의 기본 1px를 물리 DPI 환산하지 않고 Windows 최종 device 1dot으로 고정한다. 특정 셀·품목·양식 분기 없이 승인된 모든 가로/세로 cell border에 공통 적용한다.
- `label_sheet_print_job.dart`: `thicknessDots`를 footprint 반올림 값에서 상수 1로 변경했다. boundary별 단일 좌표 양자화와 raster/native 중복 제거는 유지한다.
- `label_sheet_print_job_test.dart`: descriptor와 channel map의 두께 계약을 2dot에서 1dot으로 변경했다. `Windows hybrid moves solid black cell borders to native descriptors` focused 테스트 1건 통과.
- `label_bitmap_print_channel.cpp`: 실제 동작과 일치하도록 진단값을 `nativeBorderThickness=oneDeviceDot`으로 변경했다. final device bitmap mask 합성, native text 및 overflow fit은 유지한다.
- `pubspec.yaml`: 버전 `1.0.73`으로 증가했다.
- `label_sheet_print_job_test.dart` 전체 17건 통과, 변경 파일 diagnostics 오류 0건. VS Code test runner는 `label_print_settings_test.dart`를 발견하지 못했지만 `C:/Flutter/bin/flutter.bat test test/label_sheet_print_job_test.dart test/label_print_settings_test.dart` CLI 검증은 21건 모두 통과했다.
- Windows 검증 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공. `git diff --check` 통과, Debug EXE FileVersion/ProductVersion 모두 `1.0.73`, 변경 파일 diagnostics 오류 0건.
- 커밋 대상: `lib/printing/label_sheet_print_job.dart`, `test/label_sheet_print_job_test.dart`, `windows/runner/label_bitmap_print_channel.cpp`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경과 문서 삭제는 제외한다.
- 기능 커밋: `cceaaf2` (`시트 테두리를 1dot으로 출력`).

## 완료: G500 RAW 선 품질 분리 진단
- 작업 26에서 앱과 동일한 `QPatternContiguous` framing과 640x480 1-bit body를 사용해 RAW 출력 자체를 복구했다. 작업 27은 실물에서 확인된 G500 극성 `oneBlackZeroWhite`로 1·2·3dot 세로/가로선을 출력했고 `.tmp/IMG_20260809_0009.png`에서 Windows GDI를 완전히 우회한 고정 X bitmap 선에도 가장자리 변화가 재현됐다.
- RAW bitmap 세로선의 행별 사진 폭은 1dot `1..4px`(주로 2px), 2dot `2..7px`(주로 5px), 3dot `1..9px`(주로 8px)였다. 원본 raster는 모든 행에서 동일한 고정 열이므로 FortuneSheet 좌표, Windows driver, GDI primitive, segment 접합은 원인이 아니다. 두꺼울수록 열전사 가장자리 돌출이 커졌고 1dot이 최소 왜곡이었다.
- 작업 28은 blank `Q` body 뒤에 firmware native `Rleft,top,right,bottom,lrw,ubw` 명령으로 동일 선을 출력했다. `.tmp/IMG_20260809_0010.png`의 native 선도 돌출이 남았고 주 폭은 1dot-R 5px, 2dot-R 9px, 3dot-R 11px로 bitmap보다 두꺼워져 EZPL geometry 전환도 기각했다.
- 작업 29는 공식 EZPL `^H5`, `^S5`로 저농도 비교했다. `.tmp/IMG_20260809_0011.png`에서 1dot 누락 행이 기본 10행에서 33행으로, 좌우 경계 변화가 `117/179`에서 `216/254`로 증가했고 2·3dot도 악화되어 농도 저하도 기각했다. 작업 30으로 `^H10`, `^S5`를 RAW 전송해 프린터 설정을 복원했다.
- 결론: 앱이 생성한 최종 bitmap에는 점선/계단이 없으며 G500이 고정 dot 열을 라벨에 열전사하는 단계에서 가장자리 변화가 생긴다. native geometry와 농도 조절로도 개선되지 않아 특정 셀 또는 공용 렌더러 코드로 완전히 제거할 수 없다. production v1.0.72 코드는 변경하지 않았으며, 소프트웨어에서 가능한 최소 왜곡은 final device 1dot이지만 v1.0.71 실물에서도 사용자가 불합격 판정했으므로 자동 원복하지 않는다.
- 당시에는 FortuneSheet 기본 1px의 물리 환산값 약 2.12dot을 기준으로 v1.0.72의 2dot을 유지했으나, 이후 사용자 요청으로 `1px -> 1dot` 직접 대응을 최종 기준으로 변경했다. v1.0.73 진행 항목이 이 결정을 대체한다.

## 완료·실물 검증 대기: printer footprint 두께의 단일 bitmap border 합성 v1.0.72
- v1.0.71 실물 `.tmp/IMG_20260809_0005.png`에도 세로선의 점선형 돌출이 남았다. 로그 `.tmp/log/app_2026-08-09_00-27-26.log`는 `nativeBorderComposite=bitmapMask`, `nativeBorderMaskLines=-480`, `nativeBordersDrawn=225`로 최종 device mask가 실제 적용됐음을 확인했다.
- v1.0.68 사진의 2dot 세로선은 4~5 image px, v1.0.71의 1dot은 1~2 image px로 측정됐다. 이전 `개별 vector rect + footprint 두께`와 현재 `단일 bitmap + 1dot`은 각각 실패했지만, 레거시 border 폭에 해당하는 `단일 bitmap + footprint 물리 두께` 조합은 미검증이다.
- 특정 라벨/셀 분기 없이 FortuneSheet candidate의 printer footprint 두께를 descriptor에 복원하고, 최종 device bitmap mask에서 중심 기준으로 적용한다.
- descriptor/channel의 기본 border 물리 두께 2dot 계약을 포함한 `label_sheet_print_job_test.dart` 17건 통과. C++ 최종 device rect에 축척·중심 기준 footprint 두께 적용 완료; Windows `/WX` Debug 빌드 성공.
- 출력 관련 5개 파일 62건과 FortuneSheet capture 9건 통과, 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.72`, `git diff --check` 통과.
- 기능 커밋: `ac8572a` (`테두리 물리 폭을 비트맵에 적용`).
- 실물 로그 판별: `nativeBorderThickness=footprintRounded`, `nativeBorderComposite=bitmapMask`, top-down DIB 정상값 `nativeBorderMaskLines=-480`, `nativeBordersDrawn=225`여야 한다. native text/overflow fit은 v1.0.63 경로 그대로 유지한다.

## 완료·실물 검증 대기: native border 최종 device bitmap mask 합성 v1.0.71
- v1.0.70 실물 `.tmp/IMG_20260809_0004.png`에도 세로선 옆 반복 돌출이 남았다. 최신 로그 `.tmp/log/app_2026-08-09_00-22-53.log`는 `nativeBorderFillRects=30`, `nativeBordersDrawn=225`로 경계 좌표 고정과 연속 rect 병합이 실제 적용됐음을 확인했다. segment 접합 가설은 기각한다.
- 일반화 수정: 이미 병합된 모든 border rect를 최종 device 크기의 32bpp 흑백 mask에 1dot으로 채우고 `SRCAND` 단일 bitmap으로 프린터 DC에 합성한다. 개별 `FillRect`의 드라이버 rasterization을 제거하며, bitmap mask 미지원 시에만 기존 rect 출력으로 fallback한다.
- 버전 `1.0.71`; Windows `/WX` Debug 빌드 성공. 출력 관련 5개 파일 62건과 FortuneSheet capture 9건 통과, diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.71`, `git diff --check` 통과.
- 기능 커밋: `5e4d3c2` (`테두리를 최종 비트맵으로 합성`).
- 실물 로그 판별: `nativeBorderComposite=bitmapMask`, top-down DIB 정상값 `nativeBorderMaskLines=-480`, `nativeBordersDrawn=225`여야 한다. `fillRectFallback`이면 해당 드라이버에서 mask 합성이 실패한 것이다. native text/overflow fit은 v1.0.63 경로 그대로 유지한다.

## 완료·실물 검증 대기: native border 경계 좌표 고정 및 연속 병합 v1.0.70
- v1.0.69 실물 `.tmp/IMG_20260809_0003.png`에서 세로 실선 옆 열의 반복 돌출이 남았다. 최신 로그 `.tmp/log/app_2026-08-09_00-15-20.log`는 v1.0.69, native border 225/225 draw, text 실패 0을 확인했다.
- 특정 라벨이 아닌 모든 FortuneSheet border에서 edge row/column identity를 유지하고 같은 경계 segment의 source X/Y를 한 번만 양자화한다. descriptor 경계 좌표 계약 테스트 17건 통과.
- Windows에서 동일한 device 축에 있고 맞닿거나 겹치는 1dot segment만 하나의 연속 rect로 병합한다. 성공 segment 수 225/225 진단은 유지하고 실제 호출 수는 `nativeBorderFillRects`로 기록한다. Windows `/WX` Debug 빌드 성공.
- 버전 `1.0.70`; FortuneSheet capture 9건과 출력 관련 5개 파일 62건 통과. 변경 파일 diagnostics 오류 0건, Windows `/WX` Debug 빌드 성공.
- 기능 커밋: `1334c7a` (`세로 테두리를 연속 선으로 출력`).
- 실물 로그 판별: `nativeBordersRequested=225`, `nativeBordersDrawn=225`를 유지하면서 `nativeBorderFillRects`는 225보다 작아야 한다. native text/overflow fit은 v1.0.63 경로 그대로이며 세로선은 경계별 하나의 연속 rect로 출력되어야 한다.

## 완료·실물 검증 대기: 병합 border native/raster 중복 제거 v1.0.69
- v1.0.68 실물 `.tmp/IMG_20260809_0002.png`: 2dot으로 전체 선만 두꺼워졌고 세로 실선의 점선 패턴은 유지됐다. 두께 가설은 기각하고 v1.0.67 device 1dot으로 복원한다.
- 최신 로그 `.tmp/log/app_2026-08-09_00-06-08.log`: device mapping 및 2dot 경로 적용, border 225/225 draw, text 실패 0. native dispatch 자체는 정상이다.
- 공용 FortuneSheet painter 원인: 병합 셀 한 변의 모든 edge key가 승인돼야 raster 전체 변을 생략하는 all-or-nothing 조건이다. native candidate가 실제 segment 일부만 승인하면 raster 전체 변과 native segment가 중복되어 점선/돌출 픽셀이 남는다.
- 일반화 수정: 병합/일반 셀 border를 가로는 열 단위, 세로는 행 단위 segment로 분할하고 승인된 edge key만 raster에서 생략한다. 미승인/미지원 segment는 raster fallback으로 유지한다. 특정 라벨, 품목 ID, 셀 좌표 분기 없음.
- 부분 승인된 병합 세로 변의 상단만 raster에서 제거되고 하단 fallback은 유지되는 widget capture 회귀 테스트 추가. 내부 병합 경계 기준 focused 테스트와 FortuneSheet capture 전체 9건 통과.
- root `label_sheet_print_job_test.dart` 17건 및 출력 관련 5개 테스트 파일 62건 통과. Windows `/WX` Debug 빌드 성공, 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.69`, `git diff --check` 통과.
- 커밋 대상: 공용 painter와 capture 테스트, 2dot 원복 관련 Dart/C++/계약 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`. unrelated 문서 삭제, 로고 설정, `pubspec.lock` 변경은 제외.
- 기능 커밋: `ad8edf5` (`병합 테두리의 중복 출력을 제거`).
- 실물 판별: v1.0.63 native text/overflow fit과 device 1dot border를 유지하면서 병합 변의 native 승인 segment가 raster에 중복되지 않아 세로 실선의 점선/돌출 픽셀이 없어야 한다.

## 완료·실물 검증 대기: native border 물리 stroke 2dot 복원 v1.0.68
- v1.0.67 실물 `.tmp/IMG_20260809_0001.png`: device-pixel mapping 적용 후에도 세로 실선에 점선처럼 불안정한 픽셀이 남았다.
- 최신 로그 `.tmp/log/app_2026-08-09_00-01-03.log`: `nativeBorderMapping=devicePixels`, border 225/225 draw, text 실패 0. 좌표 소실과 dispatch 누락은 해결됐으며 정확한 1 device dot 세로선 자체의 열전사 연속성이 남은 문제다.
- FortuneSheet 기본 1 logical px stroke의 203.2dpi 물리 두께는 `203.2/96=2.116... dots`다. v1.0.62의 `floor/ceil` 3~4dot은 두꺼웠고 v1.0.63~67의 강제 1dot은 편집기보다 얇다.
- candidate의 실제 printer footprint 두께를 반올림해 descriptor로 전달하고, C++에서 target device 축척 후 중심 기준 정확한 두께로 그린다. 현재 기본선은 가로/세로 모두 2 device dots이며 특정 라벨/좌표 분기 없이 모든 Windows native cell border에 적용한다.
- v1.0.63의 native text와 overflow fit은 그대로 유지. 기본 border 2dot 계약을 포함한 `label_sheet_print_job_test.dart` 17건 통과. 버전 `1.0.68`; Windows `/WX` Debug 빌드 성공.
- 출력 관련 5개 테스트 파일 62건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.68`, `git diff --check` 통과.
- 기능 커밋: `bd17dd0` (`셀 테두리 물리 두께를 정확히 출력`).
- 실물 로그 판별: `nativeBorderMapping=devicePixels`, `nativeBorderThickness=footprintRounded`, border descriptor/requested/drawn 수 일치, text 실패 0. 세로선은 편집기 기본 stroke에 해당하는 연속 2dot이며 점선 픽셀이 없어야 한다.

## 완료·실물 검증 대기: native border 최종 device 1dot 고정 v1.0.67
- v1.0.63 실물 `.tmp/IMG_20260808_0022.png`: 세로 실선 일부에 점선/교대 픽셀처럼 보이는 구간이 남았다.
- 최신 로그 `.tmp/log/app_2026-08-08_23-54-21.log`: v1.0.63, native border descriptor/requested/drawn 225개 일치, text 36개 draw 성공. raster 중복이나 dispatch 누락이 아니다.
- 원인 확인: 1 source dot 세로 `RECT`를 `MM_ANISOTROPIC` 640→620으로 변환하면 20개 source X(`16,47,80,...,623`)에서 device 폭이 0dot이 된다. 분할 border segment가 주기적으로 소실되어 실선에 점선이 섞여 보인다.
- v1.0.63의 native text, overflow fit, edge 중심 1dot descriptor는 유지한다. border 방향을 채널로 전달하고 C++에서 최종 device 좌표로 정수 변환한 뒤 세로 폭 또는 가로 높이를 정확히 1 device dot으로 `FillRect`한다. 텍스트만 기존 anisotropic mapping을 사용한다.
- 특정 라벨/좌표 분기 없이 모든 Windows native cell border에 동일 적용한다. 버전은 과거 실패 v1.0.64~66과 구분해 `1.0.67`로 증가.
- 가로/세로 방향 전달과 1dot descriptor 계약을 포함한 `label_sheet_print_job_test.dart` 17건 통과. Windows `/WX` 빌드 및 출력 회귀 검증 예정.
- 첫 `/WX` 빌드는 `RECT LONG`과 `MulDiv int` 사이 `std::max` 타입 불일치 2건으로 실패. device 우측/하단 매핑 결과를 `LONG` 변수로 명시해 수정 후 Windows `/WX` Debug 재빌드 성공.
- 출력 관련 5개 테스트 파일 62건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.67`, `git diff --check` 통과.
- 기능 커밋: `d08edf9` (`세로 실선을 최종 장치 좌표로 출력`).
- 실물 로그 판별: `nativeBorderMapping=devicePixels`, border descriptor/requested/drawn 수 일치, `nativeTextMapping=anisotropic`, `nativeTextFailed=0`. 세로 실선은 전 구간 동일 X의 연속 1dot이고 점선/교대 픽셀이 없어야 한다.

## 완료: v1.0.63 출력 기준선 원복
- v1.0.66 실물 `.tmp/IMG_20260808_0021.png`: FortuneSheet raster 텍스트가 작은 한글 획을 잃고 선 주변 왜곡도 커져 v1.0.63보다 나쁘다.
- 사용자 요청에 따라 v1.0.64~v1.0.66 실험을 중단하고 기능 커밋 `6ac7d72`의 v1.0.63 출력 구현으로 정확히 복원한다.
- `label_sheet_print_job.dart`: Windows native text descriptor 생성과 text candidate 승인 복원. `label_bitmap_print_channel.cpp`: 현재 코드가 이미 v1.0.63과 동일함을 `git diff 6ac7d72 HEAD`로 확인했다.
- 테스트의 Windows native text 승인/강제 줄간격 계약을 v1.0.63 상태로 복원하고 `pubspec.yaml` 버전도 요청대로 `1.0.63`으로 되돌렸다.
- `label_sheet_print_job_test.dart` 17건 통과. 출력 코드·테스트·버전은 `git diff 6ac7d72 -- ...` 결과 `V1_0_63_EXACT_MATCH`로 기준 커밋과 정확히 일치한다.
- Windows `/WX` Debug 빌드 성공. 출력 관련 5개 테스트 파일 62건 통과, 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.63`, `git diff --check` 통과. 출력 코드·테스트·버전은 최종 검증에서도 `V1_0_63_EXACT_MATCH`다.
- 원복 커밋: `09f1944` (`출력 품질을 v1.0.63 기준으로 원복`).

## 완료·실물 검증 대기: 편집기 동일 셀 텍스트 raster + native 1dot 선 v1.0.66
- 사용자 기준선은 실물 품질이 가장 좋은 v1.0.63이다. 이후 GDI `lfWidth`/draw rect 보정은 설정 font size와 셀 점유 비율을 동시에 재현하지 못했다.
- 일반화 원인: 같은 font size라도 Flutter `TextPainter`와 Windows GDI의 glyph metric이 달라 native text로 재생성하면 편집기 장평·점유율과 달라진다.
- 모든 FortuneSheet Windows 라벨의 셀 텍스트를 문구, 품목 ID, 셀 좌표, 서식 종류와 무관하게 native 승인하지 않고 편집기와 동일한 FortuneSheet raster에 유지한다. 설정 font size, 장평, inline run, 셀 점유 비율과 overflow가 편집기 렌더링 그대로 출력된다.
- 셀 테두리는 v1.0.63의 native edge 중심 1dot 승인만 유지해 640→620 bitmap 축소의 선 지그재그를 방지한다. v1.0.65의 우측 1dot GDI rect 보정은 제거했다.
- 버전 `1.0.66`; text raster 유지와 native 1dot border 계약을 포함한 `label_sheet_print_job_test.dart` 17건 통과. Windows `/WX` Debug 빌드 성공.
- 출력 관련 5개 테스트 파일 62건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.66`, `git diff --check` 통과.
- 기능 커밋: `8ce6e82` (`편집기 텍스트 비율로 일반화 출력`).
- 실물 로그 판별: 모든 양식에서 `nativeTextDescriptors=0`, `nativeTextRequested=0`, `nativeTextFallback=nativeTextCandidates`, native border descriptor/requested/drawn 수 일치. 텍스트 font size·장평·셀 점유율은 편집기와 같고 선은 v1.0.63의 곧은 1dot이어야 한다.

## 완료·실물 검증 대기: 장평 회귀 제거 및 일반화된 우측 glyph 여유 v1.0.65
- v1.0.64 실물 `.tmp/IMG_20260808_0020.png`: 세로선 지그재그가 다시 두드러지고 표 텍스트 장평이 셀마다 달라져 v1.0.63보다 악화됐다.
- v1.0.64 로그 `.tmp/log/app_2026-08-08_23-29-00.log`: 36개 descriptor 중 34개가 `nativeTextWidthCalibrated` 됐다. 거의 모든 fragment에 서로 다른 `lfWidth`를 적용한 양방향 보정이 장평 회귀 원인이다.
- v1.0.64의 양방향 폭 보정과 전역 `DT_NOCLIP`은 제거하고 재사용하지 않는다. v1.0.63의 overflow 2개만 축소하는 균일 장평 동작으로 복원한다.
- 오른쪽 마지막 glyph는 장평을 바꾸지 않고 최종 `DrawTextW` rect 오른쪽에 고정 1 source dot 여유만 추가한다. 표/셀/1dot 선 좌표와 640→620 비율은 변경하지 않는다.
- 일반화 계약: 품목 ID, 문구, 셀 좌표, 라벨 양식에 대한 분기 없이 `PrintBitmap`의 모든 native text descriptor에 renderer-wide `kNativeTextRightOverhangDots`를 동일 적용한다. source printer-dot 기준이므로 라벨 크기와 무관하다.
- 버전 `1.0.65`; 일반화 상수 적용 후 Windows `/WX` Debug 빌드 성공. 출력 관련 5개 테스트 파일 62건 통과, 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.65`, `git diff --check` 통과.
- 기능 커밋: `6ae1185` (`native 텍스트 장평 회귀 제거`).
- 실물 판별: v1.0.63처럼 균일한 장평과 곧은 1dot 세로선을 유지하면서 마지막 glyph만 보여야 한다. 로그의 `nativeTextFitted`는 실제 overflow descriptor에만 제한되고 v1.0.64의 `nativeTextWidthCalibrated` 항목은 없어야 한다.

## 완료·실물 검증 대기: native 글자 폭을 편집기 fragment 폭과 일치 v1.0.64
- v1.0.63 실물 `.tmp/IMG_20260808_0019.png`: 1dot 선 두께는 개선됐지만 긴 문장의 오른쪽 끝이 계속 잘린다.
- v1.0.63 로그 `.tmp/log/app_2026-08-08_23-15-37.log`: source 640x480, target 620x480, native text 36개/581자 모두 그리기 성공, fit 2개, border 225개 모두 그리기 성공. 표·선·텍스트의 640→620 가로 비율은 동일하므로 표 전체 축소 문제는 아니다.
- 원인: GDI 폭이 Flutter fragment 폭보다 넓을 때만 축소하며, 최종 `DrawTextW`가 Flutter 측정 폭과 정확히 같은 rect로 glyph를 clip한다. 글꼴 메트릭/오버행 차이가 오른쪽 끝 손실로 나타난다.
- 수정 예정: 모든 native text를 Flutter fragment 폭에 맞춰 GDI 실측 폭을 양방향 반복 보정하고 최종 glyph clip을 제거한다. 표/셀 좌표 및 640→620 물리 비율은 유지한다.
- 버전 `1.0.64`; Windows `/WX` Debug 빌드 성공. 출력 관련 5개 테스트 파일 62건 통과, 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.64`, `git diff --check` 통과.
- 기능 커밋: `887ea7f` (`편집기 기준으로 native 글자 폭 보정`).
- 실물 판별: 표/셀 위치와 1dot 선은 v1.0.63과 같아야 한다. 긴 문장은 편집기의 fragment 폭으로 보정되어 오른쪽 마지막 glyph가 잘리지 않아야 하며 로그에 `nativeTextFailed=0`, `nativeTextWidthCalibrated`가 기록되어야 한다.

## 완료·실물 검증 대기: native 테두리 1dot 및 overflow 반복 맞춤 v1.0.63
- v1.0.62 실물 `.tmp/IMG_20260808_0018.png`은 선 지그재그는 크게 줄었지만 편집 화면보다 선이 두껍고 오른쪽 끝이 계속 잘렸다.
- 최신 로그 `.tmp/log/app_2026-08-08_23-08-59.log`: native border 225개 요청/그리기 일치, text 실패 0, fit 2개. native 경로 적용은 정상이다.
- 선 두께 원인: 약 2.1dot stroke footprint를 `floor/ceil`해 3~4 source dot으로 확대했다. edge 중심 좌표에서 가로 높이 또는 세로 폭을 정확히 1 source dot으로 고정한다.
- 오른쪽 clipping 원인: 평균 glyph 폭으로 한 번만 축소해 실제 재측정 폭이 여전히 셀보다 클 수 있었다. 2dot 안전 여백을 두고 최대 4회 재측정하며 실제 폭이 셀 안에 들어올 때까지 fitted font 폭을 줄인다.
- 버전은 `1.0.63`으로 증가. 1dot native border 테스트를 포함한 `label_sheet_print_job_test.dart` 17건 통과. Windows `/WX` Debug 빌드 성공.
- 출력 관련 5개 테스트 파일 62건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.63`, `git diff --check` 통과.
- 기능 커밋: `6ac7d72` (`native 선 두께와 텍스트 넘침 보정`).
- 실물 판별: 선은 edge 중심의 1dot으로 편집 화면과 유사한 얇은 두께여야 한다. `nativeTextFitted` 대상은 2dot 안전 여백 안에서 반복 실측되어 오른쪽 끝이 모두 보여야 하며 `nativeTextFailed=0`이어야 한다.

## 완료·실물 검증 대기: Windows native 셀 테두리 및 overflow 글꼴 폭 맞춤 v1.0.62
- v1.0.61 실물 `.tmp/IMG_20260808_0017.png`과 로그 `.tmp/log/app_2026-08-08_22-52-42.log`: `BLACKONWHITE`, `nativeTextMapping=anisotropic` 모두 적용됐지만 선 지그재그/두께 편차와 오른쪽 clipping이 남았다. 후단 640→620 비정수 bitmap 축소 모드 튜닝은 종료한다.
- FortuneSheet의 검은 실선 cell border 후보는 stroke footprint와 edge key를 이미 제공한다. Windows border descriptor로 승인해 hybrid raster에서 제거하고 C++가 최종 mapping 좌표에서 직사각형 직선으로 직접 그리도록 전환한다.
- native text는 `DT_CALCRECT` 실측 폭이 셀 rect를 넘는 descriptor만 평균 glyph 폭을 비례 축소해 오른쪽 끝을 셀 안에 맞춘다. 높이와 비 overflow 텍스트는 유지한다.
- Dart descriptor/capture/일반·저울 출력 전달과 C++ native border/text fit 구현 완료. 첫 `/WX` 빌드는 `std::max` long/int 불일치 1건으로 실패했고 Win32 `MulDiv` 반환형에 맞춰 수정 후 성공했다.
- native border 승인 테스트를 포함한 `label_sheet_print_job_test.dart` 17건 통과. 최신 변경 포함 Windows `/WX` Debug 재빌드 성공.
- 출력 관련 5개 테스트 파일 62건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.62`, `git diff --check` 통과.
- 실물 로그 판별: `nativeBorderDescriptors`와 `nativeBordersRequested`/`nativeBordersDrawn`이 같은 양수, `nativeTextFailed=0`. overflow가 있으면 `nativeTextFitted`가 양수다. native border가 raster 축소에서 제거되어 선이 직선·균일 두께로 출력되고 오른쪽 문장이 셀 안에 모두 보여야 한다.
- 기능 커밋: `16d0e54` (`셀 테두리와 넘침 텍스트 직접 출력`). push하지 않음.

## 완료·실물 검증 대기: 흑백 선 보존 축소 및 native 글꼴 폭 동기화 v1.0.61
- v1.0.60 실물 `.tmp/IMG_20260808_0016.png`은 전체 내용과 외곽선은 들어왔지만 일부 세로선 지그재그, 가로/세로선 두께 편차, 긴 문장 오른쪽 clipping이 남았다.
- 최신 로그 `.tmp/log/app_2026-08-08_22-46-34.log`: `target=620x480`, `destination=0,0`, `gray=0` 적용 확인. 흑백화와 printable 폭 맞춤 자체는 적용됐다.
- 확정 원인 1: `COLORONCOLOR` 640→620 축소가 source 열 20개를 선택적으로 버려 1px 선이 불규칙하게 탈락했다. `BLACKONWHITE`로 바꿔 축소 시 검은 선 픽셀을 보존한다.
- 확정 원인 2: v1.0.60은 native text rect만 620/640으로 줄이고 GDI glyph 폭은 그대로 사용해 긴 텍스트가 좁아진 rect에서 잘렸다. `MM_ANISOTROPIC` source 640×480→viewport 620×480 mapping으로 rect와 글꼴 glyph를 함께 변환한다.
- 버전은 `1.0.61`로 증가. Windows `/WX` Debug 빌드 성공.
- 출력 관련 5개 테스트 파일 45건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.61`, `git diff --check` 통과.
- 실물 로그 판별: `target=620x480`, `gray=0`, `stretchMode=BLACKONWHITE`, `nativeTextMapping=anisotropic`, native text 실패 0. 세로선이 곧고 가로/세로선 두께가 균일하며 긴 문장의 오른쪽 끝이 모두 보여야 한다.
- 기능 커밋: `683a6bb` (`축소 출력 선과 글꼴 폭 동기화`). push하지 않음.

## 완료·실물 검증 대기: G500 printable 폭 맞춤 및 선 raster 흑백화 v1.0.60
- v1.0.59 실물 `.tmp/IMG_20260808_0014.png`에서 전체 80×60 내용 복원은 성공했다. 다만 일부 세로선이 점선/지그재그처럼 보이고 가로선에 점선이 생기며 오른쪽 끝 내용이 잘린다.
- 최신 로그 `.tmp/log/app_2026-08-08_22-28-12.log`: `source=640x480`, `target=639x480`, `horzRes=620`, `physical=640x480`, `offset=10,0`, `destination=-10,0`, gray raster 1,286px. 음수 offset은 620dot printable 영역 밖의 양끝을 잘라내므로 오른쪽 clipping을 해결하지 못했다.
- `label_bitmap_print_channel.cpp`: 실패한 음수 offset 재사용 금지 주석을 남기고, 최종 target을 실제 `HORZRES`/`VERTRES` 이하로 제한하며 destination 0에서 bitmap/native text 좌표를 함께 축소한다. G500에서는 640→620으로 약 3.1% 수평 축소된다.
- `prepareLabelSheetWindowsDriverPage`: raster를 luminance 200 기준 순수 흑백으로 고정해 회색 border anti-alias가 드라이버 dithering에서 점선으로 변하는 현상을 제거한다. native text는 기존 GDI 출력이라 영향받지 않는다.
- 버전은 `1.0.60`으로 증가. raster·zoom·단위 계약을 포함한 `label_sheet_print_job_test.dart` 16건 통과. Windows `/WX` Debug 빌드 성공.
- 출력 관련 5개 테스트 파일 45건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.60`, `git diff --check` 통과.
- 실물 로그 판별: `version=1.0.60`, `source=640x480`, `target=620x480`, `horzRes=620`, `destination=0,0`, `gray=0`. 오른쪽 끝 내용과 외곽선이 printable 영역 안에 모두 들어오고 가로·세로선의 점선/지그재그가 없어야 한다.
- 기능 커밋: `e7eeba2` (`라벨 선명도와 오른쪽 잘림 수정`). push하지 않음.

## 완료·실물 검증 대기: Windows hybrid 출력 zoom 정규화 v1.0.59
- v1.0.58 실물 `.tmp/IMG_20260808_0010.png`은 v1.0.57과 동일하게 제조원에서 끝나며 `120g`, 영양정보, 반품 문구가 누락됐다. 최신 로그 `.tmp/log/app_2026-08-08_22-18-09.log`도 capture/descriptor/ink가 v1.0.57과 동일해 owner 동기화 가설을 기각한다.
- 확정 원인: FortuneSheet `sheet.metrics(settings)`는 `sheet.zoomRatio`를 행·열 크기에 적용한다. 출력 미리보기 zoom은 1.5인데 Windows hybrid 경로만 이를 그대로 geometry와 screenshot capture에 사용해 80×60 물리 clip 안에 원본 앞쪽 약 2/3을 확대 출력했다. EZPL 경로는 이미 zoom 1로 정규화한다.
- `prepareLabelSheetWindowsHybridPrint`: geometry, native 후보/descriptor, raster plan이 모두 zoom 1의 `printSheet`를 사용하도록 통일한다. 화면 zoom은 출력 내용과 물리 좌표에 영향을 주지 않는다.
- v1.0.58 owner fingerprint 동기화는 stale capture 방지 안전장치로 유지한다. 버전은 `1.0.59`로 증가하고 zoom 독립 회귀 테스트를 추가한다.
- 라벨 단위 조사: 시트는 96 logical px/in, transform은 dpi/96, Windows bitmap은 mm×dpi/25.4, DEVMODE는 0.1mm 단위를 사용한다. 80×60mm·203.2dpi는 모든 Dart 단계에서 정확히 640×480dot이며 단위 혼용은 없다.
- 드라이버가 보고한 정수 203dpi로 C++ target 폭이 639dot이 되는 1dot(약 0.125mm) 반올림 차이는 있으나, v1.0.58의 하단 약 20mm 누락 원인은 될 수 없다. 80×60mm→640×480dot 계약 테스트를 추가한다.
- zoom 독립 및 80×60mm 단위 계약을 포함한 `label_sheet_print_job_test.dart` 16건 통과. Windows `/WX` Debug 빌드 성공.
- 출력 관련 5개 테스트 파일 45건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.59`, `git diff --check` 통과.
- 실물 판별: 미리보기 zoom 150%와 무관하게 전체 80×60mm가 640×480dot source에 들어가야 한다. `120g`, 오른쪽 테두리, 영양정보, 반품 문구가 모두 출력되고 제조원 행이 60mm 바닥까지 확대되지 않아야 한다.
- 기능 커밋: `a17540f` (`출력 시트 확대 배율 정규화`). push하지 않음.

## 완료·실물 검증 대기: 출력 preview/capture owner 동기화 v1.0.58
- v1.0.57 실물에서 물리 offset 보정은 적용됐지만 화면 미리보기와 다른 내용이 출력됐다. native text 실패가 0이고 후보 수 자체가 원본보다 적어 stale preview capture로 원인을 좁혔다.
- 발행 루프는 preview refresh 후 frame 두 번만 기다리고, 실제 capture controller owner가 발행 unit의 workbook fingerprint와 일치하는지 확인하지 않았다.
- `_itemOutputPreviewIdentityKey`로 화면과 발행 루프의 owner token 생성을 통일하고, `waitForLabelSheetOutputCaptureOwner`가 예상 token attach를 확인한 뒤에만 capture한다. 불일치가 지속되면 잘못된 라벨을 출력하지 않고 오류로 중단한다.
- 버전은 `1.0.58`로 증가. 신규 owner wait 테스트를 포함한 `label_print_session_test.dart` 22건 통과. Windows `/WX` Debug 빌드 성공.
- 출력 관련 5개 테스트 파일 43건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.58`, `git diff --check` 통과.
- 실물 판별: 화면에 보이는 최신 workbook owner가 attach된 경우에만 출력된다. 원본의 `120g`, 오른쪽 테두리, 영양정보, 반품 문구가 모두 나와야 한다. owner가 갱신되지 않으면 이전 내용을 출력하지 않고 `출력 미리보기 갱신을 확인할 수 없습니다.` 오류로 중단해야 한다.
- 기능 커밋: `b2c5c2c` (`출력 미리보기 캡처 동기화`). push하지 않음.

## 완료·실물 실패: GDI 물리 용지 offset clipping 수정 v1.0.57
- 원본 시트 이미지는 80×60mm 안에 모든 내용이 있지만 v1.0.56 실물 `.tmp/IMG_20260808_0008.png`은 오른쪽 마지막 내용이 잘렸다.
- v1.0.56 로그는 `source=640x480`, `target=639x480`, `horzRes=620`, `physical=640x480`, `offset=10,0`이다. GDI DC의 실제 인쇄 가능 폭 620도트보다 19도트 넓게 그려 오른쪽이 clipping됐다.
- `label_bitmap_print_channel.cpp`: GDI printable DC 원점은 물리 용지의 `(10,0)`인데 기존 destination `(0,0)`이 시트 전체를 오른쪽으로 10도트 이동시켰다. 원본 크기와 비율은 유지하고 destination을 `(-PHYSICALOFFSETX, -PHYSICALOFFSETY)`로 보정해 시트 물리 좌표와 프린터 용지 좌표를 일치시킨다. bitmap, 테두리, native text에 동일하게 적용된다.
- 버전은 `1.0.57`로 증가. `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공.
- 출력 관련 5개 테스트 파일 21건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.57`, `git diff --check` 통과.
- 실물 로그 확인 기준: `version=1.0.57`, `requestedTarget=639x480`, `target=639x480`, `offset=10,0`, `destination=-10,0`. 오른쪽 마지막 내용과 테두리가 원본 시트와 같은 위치에서 잘리지 않아야 한다.
- 기능 커밋: `eab066d` (`라벨 오른쪽 출력 잘림 수정`). push하지 않음.
- v1.0.57 실물 `.tmp/IMG_20260808_0009.png`과 로그 `.tmp/log/app_2026-08-08_21-57-54.log` 확인: `destination=-10,0` 적용 및 native text 22개 전부 draw 성공, 실패 0. 표는 왼쪽으로 이동했지만 `120g`, 오른쪽 세로 테두리, 영양정보·반품 문구가 계속 없고 제조원 두 번째 줄도 원본과 다르므로 사용자 문제는 해결되지 않았다.
- 사용자는 인쇄 직전 앱 출력 미리보기가 붙여넣은 원본과 동일했다고 확인했다. 프린터 clipping이 아니라 같은 화면 sheet에 대한 Windows hybrid capture/descriptor 결과가 미리보기와 달라지는 문제로 원인을 재분류한다.
- 물리 offset 보정은 좌표 정합을 위해 유지하지만 추가 이동·폭 축소로 해결하지 않는다. 다음 작업은 capture 직전 active sheet fingerprint/cell count/range와 생성 PNG를 미리보기 workbook과 대조해 stale capture 또는 hybrid omission/descriptor 결함을 찾는다.

## 완료: v1.0.55 글꼴 크기 회귀 복원 및 품질 개선 종료 v1.0.56
- v1.0.55 실물 `.tmp/IMG_20260808_0007.png`은 글자가 과대해져 셀 오른쪽 clipping과 정렬 손상이 발생했다.
- 최신 로그 `.tmp/log/app_2026-08-08_18-35-32.log`: `version=1.0.55`, `nativeTextHeight=14..23`, `nativeTextFailed=0`. 변경 적용 실패가 아니라 point→dot 계산 자체의 회귀다.
- `labelSheetWindowsFontPixelHeight`와 10pt→28dot 테스트를 제거하고 기존 `fontSize × dotsPerLogicalPixel` 계산으로 복원한다. 시트 조판과 Windows native text가 동일한 logical font size를 사용해야 셀 레이아웃과 일치한다.
- 버전은 `1.0.56`으로 증가한다. 자동 검증 후 프린터 속도도 품질 효과가 없었던 50.8mm/s에서 실험 전 127mm/s로 복원한다.
- Windows hybrid descriptor focused test 1건 통과. Windows `/WX` Debug 빌드 성공.
- G500 큐를 `JobPrintSpeed=opt127000`, `Ptxcn_PrintSpeed=127 mms`, `JobUseCurrentPrinterSettings=OptNo`로 복원했다. 농도 level 8, dithering opt2 유지 확인.
- 출력 관련 5개 테스트 파일 21건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.56`, `git diff --check` 통과.
- v1.0.56은 v1.0.54와 동일한 시트 logical font size 계산을 사용한다. 추가 실물 품질 실험은 종료하며, 더 높은 품질이 필수이면 300dpi 장비 또는 시트 글꼴 크기·셀 레이아웃 자체를 변경해야 한다.
- 기능 커밋: `49b6800` (`시트 글꼴 크기 회귀 복원`). push하지 않음.
- 최종 판정: RTF를 사용하지 않는 시트 전용, 203dpi G500, 기존 레이아웃 조건에서는 v1.0.54 계열 GDI hybrid가 현재 최선이다. 추가 font quality·크기·속도 튜닝은 모두 무효 또는 회귀가 확인되어 종료한다.

## 완료·실물 실패: 시트 point 글꼴의 Windows GDI 물리 크기 보정 v1.0.55
- 실물 비교: 현재 시트 출력 `.tmp/IMG_20260808_0005.png`은 50.8mm/s에서도 작은 한글 획이 끊기며, 레거시 결과 `.tmp/IMG_20260808_0006.png`은 같은 203dpi 장비에서 획이 더 굵고 연속적이다.
- 사용자 확정: 현재 프로젝트는 RTF를 출력 원본으로 사용하지 않으며 시트만 사용한다. 검토 중 추가했던 RTF 직접 출력 관련 미커밋 변경은 모두 제거했고 diff 0을 확인했다.
- 원인: FortuneSheet 저장/API의 `fontSize`는 point 단위인데 Windows descriptor는 `dpi/96` logical pixel 비율을 곱했다. GDI 음수 font height의 물리 변환은 `point × dpi / 72`가 맞아 현재 native text가 25% 작게 생성됐다.
- `labelSheetWindowsFontPixelHeight`: 시트 font point를 `point × dpi / 72`로 printer dot에 변환하고 Windows native descriptor에 적용했다. 시트 데이터·레이아웃·bitmap·프린터 설정은 변경하지 않았다.
- focused test: Windows hybrid descriptor와 10pt·203.2dpi→28dot 계약 2건 통과.
- 첫 Windows `/WX` 빌드는 실행 중인 `label_manager.exe`가 파일을 잠가 `LNK1168`로 실패했다. PID 14040 종료 후 동일 명령을 재실행해 성공했다.
- 출력 관련 5개 테스트 파일 22건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.55`, `git diff --check` 통과.
- 다음 실물 로그 판별 조건: `version=1.0.55`, `backend=windowsDriver`, `fontQuality=DEFAULT_QUALITY`, `nativeTextHeight`가 기존 `11..17`에서 예상 `15..23` 근처로 증가, `nativeTextFailed=0`.
- 프린터 큐는 마지막 A/B의 50.8mm/s, 농도 level 8, dithering opt2 상태다. v1.0.55 실물은 `.tmp/IMG_20260808_0005.png` 및 레거시 `.tmp/IMG_20260808_0006.png`과 글자 크기·획 연속성·cell clipping을 비교한다.
- 기능 커밋: `e5dc3e7` (`시트 글꼴 GDI 물리 크기 보정`). push하지 않음.

## 완료·실물 A/B 대기: GoDEX GDI 기준선 복원 및 프린터 속도 A/B v1.0.54
- v1.0.54 실물 `.tmp/IMG_20260808_0003.png`은 작은 한글과 검은 바탕의 흰 글자에 픽셀 계단이 남아 고품질 기준에 미달했다.
- 최신 로그 `.tmp/log/app_2026-08-08_18-03-35.log`: `version=1.0.54`, `backend=windowsDriver`, `fontQuality=DEFAULT_QUALITY`, `nativeTextFailed=0`; 출력 데이터는 v1.0.52 기준선과 동일하다.
- 실물 직후 PrintTicket 확인 결과 속도가 여전히 `127 mms`, `JobUseCurrentPrinterSettings=OptYes`여서 요청한 76.2mm/s A/B는 실제 수행되지 않았다.
- `Godex G500` 큐의 `JobUseCurrentPrinterSettings=OptNo`, `JobPrintSpeed=opt76200`을 적용했다. 재조회 결과 `Ptxcn_PrintSpeed=76 mms`, 농도 level 8, dithering opt2 유지 확인.
- 76.2mm/s 실물 `.tmp/IMG_20260808_0004.png`과 최신 로그 `.tmp/log/app_2026-08-08_18-09-15.log`를 확인했다. v1.0.54 출력 경로와 76.2mm/s 설정은 정상 적용됐지만 127mm/s 결과 대비 체감 가능한 품질 향상이 없었다.
- 마지막 물리 A/B로 `JobPrintSpeed=opt50800`을 적용했다. 재조회 결과 `Ptxcn_PrintSpeed=51 mms`, `JobUseCurrentPrinterSettings=OptNo`, 농도 level 8, dithering opt2 유지 확인.
- 50.8mm/s 실물도 같으면 현재 203dpi G500·작은 11~17px 한글·기존 레이아웃 조합의 실용 품질 한계로 최종 판정하고 코드 튜닝을 종료한다. 유의미한 향상은 300dpi 장비 또는 글꼴 크기/레이아웃 변경으로 전환한다.
- 최종 속도 검증 준비 커밋: `85fa237` (`GoDEX 최종 속도 품질 검증 준비`). push하지 않음.
- 속도 A/B 조건 갱신 커밋: `833f5fa` (`GoDEX 속도 실물 검증 조건 갱신`). push하지 않음.
- v1.0.53 실물 `.tmp/IMG_20260808_0002.png`은 비안티앨리어싱으로 작은 한글의 계단과 획 단절이 더 뚜렷해져 고품질 개선에 실패했다.
- 최신 로그 `.tmp/log/app_2026-08-08_17-57-52.log`: `version=1.0.53`, `backend=windowsDriver`, `fontQuality=NONANTIALIASED_QUALITY`, `nativeTextFailed=0`. capture, raster ink, descriptor, 640→639 배율은 v1.0.52와 동일하므로 변경 적용 실패나 다른 출력 변수의 영향이 아니다.
- `label_bitmap_print_channel.cpp`: 실패한 `NONANTIALIASED_QUALITY`를 `DEFAULT_QUALITY`로 복원하고 재사용 방지 사유를 남겼다. 진단 문자열도 `fontQuality=DEFAULT_QUALITY`로 복원했다.
- `pubspec.yaml`: 실패 실험 복원과 다음 속도 A/B 기준 버전을 `1.0.54`로 증가했다.
- 검증 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug`: 성공.
- 출력 관련 5개 테스트 파일 21건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.54`, `git diff --check` 통과.
- v1.0.54에서 G500 드라이버 속도만 127mm/s→76.2mm/s로 낮춰 실물 A/B한다. 농도 8, driver dithering opt2, 코드와 배율은 유지한다.
- 다음 로그 판별 조건: `version=1.0.54`, `backend=windowsDriver`, `fontQuality=DEFAULT_QUALITY`, `nativeTextFailed=0`. 실물 사진은 v1.0.52 `.tmp/IMG_20260808_0001.png`과 비교한다.
- 기능 커밋: `a077d6c` (`GoDEX 한글 출력 기준 품질 복원`). push하지 않음.

## 완료·실물 실패: GoDEX GDI 작은 한글 raster 품질 개선 v1.0.53
- v1.0.52 실물 `.tmp/IMG_20260808_0001.png`은 회전·분할·극성은 정상이나 작은 한글 획과 선이 거칠어 고품질 기준에는 미달했다.
- 최신 로그 `.tmp/log/app_2026-08-08_17-46-37.log`: `version=1.0.52`, `backend=windowsDriver`, 641x481 capture→640x480 page, raster ink 50,556, native descriptor 22개/378자, `nativeTextFailed=0`, GDI 640x480→639x480 성공.
- v1.0.44 로그 `.tmp/log/app_2026-08-07_20-47-37.log`와 capture PNG bytes, raster ink, native text 수/높이/font, GDI source/target/offset이 모두 동일해 backend 복원 누락이나 코드 회귀는 아니다.
- 원인 가설: `CreateFontW`의 `DEFAULT_QUALITY`가 11~17px 한글을 회색 안티앨리어싱하고 203dpi 단색 드라이버가 이를 디더링해 거친 획을 만든다.
- `label_bitmap_print_channel.cpp`: Windows native text를 `NONANTIALIASED_QUALITY`로 고정하고 GDI 진단에 `fontQuality=NONANTIALIASED_QUALITY`를 추가했다. 프린터 속도 127mm/s·농도 8 및 640→639 배율은 이번 실험에서 고정했다.
- `pubspec.yaml`: 호환 가능한 출력 품질 실험으로 PATCH 버전을 `1.0.52`에서 `1.0.53`으로 증가했다.
- 첫 검증 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug`: 성공.
- 출력 관련 5개 테스트 파일 21건 통과. 변경 파일 diagnostics 오류 0건.
- EXE FileVersion/ProductVersion 모두 `1.0.53`, `git diff --check` 통과.
- 실물 `.tmp/IMG_20260808_0002.png`과 로그에서 변경 적용은 확인됐지만 작은 한글의 계단과 획 단절이 더 두드러져 가설을 기각했다.
- 기능 커밋: `6baead8` (`GoDEX 작은 한글 비안티앨리어싱 출력 적용`). push하지 않음.
- 기존 unrelated 변경 `lib/core/app.dart`, `pubspec.lock`, 삭제 상태의 EZPL 문서 2개는 수정·stage·commit에서 제외한다.

## 완료·실물 검증 대기: GoDEX G500 기본 Windows 드라이버 출력 복원 v1.0.52
- 실물 비교 결과 v1.0.44의 Windows GDI 하이브리드 출력(`.tmp/IMG_20260807_0002.png`)이 v1.0.45~v1.0.51 RAW EZPL 결과보다 전체 레이아웃과 작은 한글 품질이 안정적이었다.
- 원인: `resolveLabelPrintBackend`가 GoDEX 물리 포트만 `ezplRaw`로 강제해 설치된 Seagull Godex G500 11.6 드라이버의 글꼴 rasterization과 프린터별 변환을 우회했다.
- `resolveLabelPrintBackend`: GoDEX를 포함한 모든 물리 포트를 기존 GDI 하이브리드 `windowsDriver`로 복원하고 FILE/PORTPROMPT는 PDF를 유지했다. EZPL RAW 및 한글 폰트 프로비저닝 구현은 후속 비교 실험을 위해 보존했다.
- `label_print_dispatcher_test.dart`: GoDEX USB/null 포트의 Windows driver 라우팅과 파일 포트 PDF 계약으로 회귀 테스트를 갱신했다.
- `pubspec.yaml`: 호환 가능한 출력 backend 수정으로 PATCH 버전을 `1.0.51`에서 `1.0.52`로 증가했다.
- 첫 focused 검증 `flutter test test/label_print_dispatcher_test.dart`: 7건 통과.
- 출력 관련 검증: 지정한 5개 테스트 파일 21건 통과.
- strict analyzer: 변경 Dart 2개 파일 오류·경고 0건. 편집기 diagnostics도 변경 4개 파일 오류 0건.
- Windows `/WX` Debug 빌드 성공. EXE FileVersion/ProductVersion 모두 `1.0.52`, `git diff --check` 통과.
- stage 대상: resolver, dispatcher 회귀 테스트, `pubspec.yaml`, 본 문서. 다음 실물 출력 로그에서 `backend=windowsDriver`, GDI dispatch 성공, `nativeTextFailed=0`을 확인하고 `.tmp/IMG_20260807_0002.png`와 품질을 비교한다.
- 기능 커밋: `76a3c15` (`GoDEX 기본 Windows 드라이버 출력 복원`). push하지 않음.
- 기존 unrelated 변경 `lib/core/app.dart`, `pubspec.lock`, 삭제 상태의 EZPL 문서 2개는 수정·stage·commit에서 제외한다.

## 완료·실물 검증 대기: GoDEX Q pattern polarity 수정 v1.0.51
- v1.0.50 실물 사진 `.tmp/IMG_20260807_0008.png`은 Q pattern 전환 후 두 장 분할은 사라졌지만 원본 흰 배경이 검정으로 출력됐다.
- 최신 로그 `app_2026-08-07_23-58-00.log`: 640x480, pattern data 38,400 bytes, zero=32,259/full=4,623/mixed=1,518, checksum `b655b1bb14c79e71`, RAW `44639/44639` 성공. source ink는 13.91%인데 다수의 zero byte 영역이 실물 검정과 대응한다.
- 원인 확정: label-format `Q` pattern은 `0=검정`, `1=흰색`이다. 이전 `~G` framing 실물 결과에서 추론한 `1=검정`을 Q pattern에도 적용해 흰 배경이 검정이 됐다.
- `label_sheet_print_job.dart`: Q row를 `0xff`로 초기화하고 ink bit만 clear하는 `zeroBlackOneWhite` polarity로 수정했다. 버전 `1.0.51`.
- print job 테스트 14건 통과. 다음 동일 라벨 로그의 예상 byte 분포는 `zero≈4623,full≈32259,mixed≈1518`이며 흰 배경이 `0xff`로 전송되는지 직접 판별한다.
- 출력 관련 65건 및 strict analyzer 통과.
- Windows `/WX` Debug 빌드 성공. `label_manager.exe` ProductVersion/FileVersion `1.0.51`, `godex_font_helper.exe` 동봉 확인.
- stage 대상: print job, 회귀 테스트, `pubspec.yaml`, 본 문서. 기존 unrelated dirty 파일은 제외. 다음 실물 로그에서 `polarity=zeroBlackOneWhite`, `framing=QPatternContiguous`, 예상 byte 분포와 RAW requested/written 일치를 확인한다.
- 기능 커밋: `fc22891` (`GoDEX Q 패턴 비트 극성 수정`). push하지 않음.

## 완료·실물 검증 대기: GoDEX hybrid bitmap Q pattern 전환 v1.0.50
- v1.0.49 실물 사진 `.tmp/IMG_20260807_0007.png`도 90도 회전 기준 두 검정 덩어리로 분할되고 원본 형상을 흰 구멍으로 출력했다.
- 최신 로그 `app_2026-08-07_23-42-52.log`: `version=1.0.49`, 640x480, copies=1, raster ink=13.91%, native AT 5/AZ1 24/geometry 225, RAW `46548/46548` 성공. 캡처·크기·전송은 정상인데 parser 출력만 비정상이다.
- 원인: `~G/G행`은 인쇄 버퍼 직접 수신 graphic mode인데 현재 hybrid payload는 그 binary stream 뒤에 native 명령 254개를 혼합했다. polarity를 바꿔도 parser 경계가 잘못되어 검정 블록/분할이 반복됐다.
- 매뉴얼의 label-format 내부 bitmap 명령 `Qx,y,width,height`는 정확히 `width*height` 연속 binary data를 받고 같은 `^L...E` 안에서 native 명령과 공존한다.
- `label_sheet_print_job.dart`: `~G/G행`을 `^L -> Q0,0,rowBytes,rows -> contiguous bitmap -> native -> E`로 교체하고 framing/commandOrder 진단을 갱신했다. 버전 `1.0.50`.
- Q pattern 진단에 exact data bytes, zero/full/mixed byte 분포, FNV-1a 64 checksum을 추가해 실제 라벨 문자열 없이 payload 무결성을 추적한다.
- print job 테스트 14건 통과. Q pattern의 정확한 `width*height` data 뒤 CRLF와 AZ1 native 명령 경계까지 검증한다.
- 출력 관련 65건 및 strict analyzer 통과.
- Windows `/WX` Debug 빌드 성공. `label_manager.exe` ProductVersion/FileVersion `1.0.50`, `godex_font_helper.exe` 동봉 확인.
- stage 대상: print job, 회귀 테스트, `pubspec.yaml`, 본 문서. 기존 unrelated dirty 파일은 제외. 다음 실물 로그에서 `framing=QPatternContiguous`, `patternDataBytes=38400`, byte 분포/checksum, `native=AT:5,AZ1:24,geometry:225`, RAW requested/written 일치를 확인한다.
- 기능 커밋: `ce60ce1` (`GoDEX 하이브리드 비트맵 명령 수정`). push하지 않음.

## 완료·실물 검증 대기: GoDEX EZPL polarity·단일 라벨 format 수정 v1.0.49
- v1.0.48 실물 사진 `.tmp/IMG_20260807_0005.png`은 90도 회전 기준으로 원본 내용이 급지 방향 두 라벨에 분리되고, 검정/흰색이 반전됐다.
- 최신 로그 `app_2026-08-07_23-30-57.log`: `version=1.0.48`, 80x60mm/640x480, `^P1`, RAW `46550/46550` 성공, 원본 raster ink `13.91%`인데 실물은 약 86% 검정이다. G500 실물 해석은 `1=검정`, `0=흰색`으로 확정됐다.
- 매뉴얼상 `~G`는 control command이고 `^L`은 label format 시작이다. 현재 `^LR0 -> ~G` 순서는 graphic mode를 format 안에서 시작해 raster와 native descriptor가 두 라벨로 분리될 수 있다.
- 수정 예정: `~G -> ^L -> G rows/native -> E` 단일 format 순서, `oneBlackZeroWhite` polarity, payload 경계·bit 밀도 진단 및 회귀 테스트.
- `label_sheet_print_job.dart`: `~G -> ^L` 순서와 `1=검정` row encoding을 적용했다. 로그에 label mm/dots, copies, white/ink dots, command order, format count를 추가했다.
- `label_sheet_print_job_test.dart`: 80x1mm/203.2dpi에서 `G,0x50`, 단일 검정 dot=`0x80`, 흰 dot=`0`, `~G -> ^L`, 단일 `E` 경계를 검증한다.
- print job 14건 및 출력 관련 provisioner/dispatcher/pipeline/print job/session/fortune hybrid 테스트 65건 통과.
- strict analyzer 통과: print job, home 품목/저울, workbench 직접 발행, 회귀 테스트.
- Windows `/WX` Debug 빌드 성공. `label_manager.exe` ProductVersion/FileVersion `1.0.49`, `godex_font_helper.exe` 동봉 확인.
- stage 대상: `label_sheet_print_job.dart`, 회귀 테스트, `pubspec.yaml`, 본 문서. 기존 unrelated dirty 파일은 제외. 다음 실물 로그에서 `polarity=oneBlackZeroWhite`, `commandOrder=setup>~G>^L>Grows+native>E`, `formatCount=1`, `640x480`, `copies=1` 확인 필요.
- 기능 커밋: `feb7530` (`GoDEX 단일 라벨 그래픽 출력 순서 수정`). push하지 않음.

## 완료·실물 검증 대기: GoDEX EZPL raster polarity 수정 v1.0.48
- v1.0.47 실물 출력 사진 `.tmp/IMG_20260807_0004.png`은 흰 배경이 대규모 검정 영역으로 출력되고 native text 위치도 깨졌다.
- 최신 로그 `app_2026-08-07_23-18-18.log`: G500/USB001, 80x60mm, 203.2dpi, `availableInstalled`, AZ1 24개/AT 5개, payload 46,550 bytes, RAW `46550/46550` 접수 성공을 확인했다. 전송 문제가 아니라 payload 해석 문제다.
- 조사 중 `Gwxxx`의 `w`를 십진 자릿수로 해석한 가설은 매뉴얼 예제 `50 bytes -> G2`의 설명 `(2: ASCII is 50 decimal)`과 맞지 않아 즉시 폐기했다. 기존 `G` + binary row byte count(`80 -> 0x50`, ASCII `P`) framing은 정상이다.
- 원인: G500 `~G` raster는 `0=검정`, `1=흰색`인데 기존 코드는 흰색을 0, 잉크를 1로 보내 전체 흰 배경과 검정 내용이 반전됐다. 실물 사진의 검정 배경/흰 글자 구멍 패턴과 일치한다.
- `label_sheet_print_job.dart`: raster row를 `0xff`로 초기화하고 잉크 pixel bit만 clear하도록 polarity를 수정했다.
- `label_sheet_print_job_test.dart`: 실제 80mm/203.2dpi 조건에서 row prefix가 `G,0x50`, 빈 raster data가 모두 `0xff`, 다음 행과 `E` 경계가 유지되는 회귀 테스트를 추가했다.
- `buildLabelSheetPlannedEzplBytes`: 선택적 진단 callback을 추가해 source/raster 크기, threshold, polarity/framing, row bytes/count, 전체·행별 ink dot 밀도, raster section bytes, 승인 token, AT/AZ1/geometry descriptor 수, payload bytes를 기록한다. 실제 라벨 문자열은 기록하지 않는다.
- `home_page_manager.dart`: 품목/저울 출력 모두 unit별 `labelPrintQuality ezpl`/`scalePrintQuality ezpl` 진단을 로그에 연결했다.
- `label_sheet_workbench.dart`: 직접 라벨시트 발행에도 `labelSheetPrint ezplQuality` 진단을 연결했다.
- 버전을 `1.0.48`로 증가했다. print job 테스트 14건 및 `git diff --check` 통과.
- 출력 관련 provisioner/dispatcher/pipeline/print job/session/fortune hybrid 테스트 65건 통과.
- strict analyzer 통과: `label_sheet_print_job.dart`, `home_page_manager.dart`, `label_sheet_print_job_test.dart`; 직접 발행 callback 추가 후 `label_sheet_workbench.dart`, `label_sheet_print_job.dart` 재분석도 통과.
- Windows `/WX` Debug 빌드 성공. `label_manager.exe` ProductVersion/FileVersion `1.0.48`, `godex_font_helper.exe` 동봉 확인.
- 임시 산출물/캐시 추가 없음. stage 대상: print job, home 품목/저울, workbench 직접 발행, 회귀 테스트, `pubspec.yaml`, 본 문서. 기존 unrelated dirty 파일은 제외.
- 기능 커밋: `408ceeb` (`GoDEX 래스터 반전 출력 및 품질 진단 수정`). push하지 않음.

## 완료·실물 검증 대기: Godex AZ1 CP949 Windows encoding 오류 수정 v1.0.47
- v1.0.46 실물 로그 `app_2026-08-07_23-08-20.log`: Korean package는 `282127/282127`, `status=installedByApp`, AZ1 descriptor 24개까지 성공했지만 payload 로그와 RAW dispatch 전에 중단됐다.
- 원인: Windows `charset_converter` plugin은 `CP949` alias가 없고 code page 이름 `949` 또는 `ks_c_5601-1987`만 지원한다. `CP949` 호출이 `charset_name_unrecognized`를 반환했다.
- `label_sheet_print_job.dart`: AZ1 command encoding charset을 `CP949`에서 Windows plugin 지원 이름 `949`로 수정했다.
- `home_page_manager.dart`: 품목·저울 발행 최상위 catch에서 오류와 stack trace를 로그에 기록해 payload 단계 예외가 누락되지 않게 했다.
- 버전을 `1.0.47`로 증가했다.
- print job/provisioner focused 테스트 16건 통과, 변경 Dart 3개 파일 formatter 적용 완료.
- strict analyzer 0 issues, 출력 관련 테스트 64건 통과, `git diff --check` 통과.
- 첫 Windows `/WX` Debug 빌드는 실행 중이던 `label_manager.exe`의 산출물 잠금으로 `LNK1168` 실패했고 해당 테스트 프로세스만 종료한 뒤 성공했다. EXE 제품/파일 버전 `1.0.47`, EXE 옆 `godex_font_helper.exe` 존재를 확인했다.
- 인쇄 최상위 catch 로그가 비슷한 일반 catch에 잘못 적용된 것을 커밋 전 diff 검토에서 발견해 원복하고 `_issueLabelPrint`/`_issueScaleOutput` catch로 정확히 이동했다. 이후 strict analyzer 0 issues 재확인.
- 최종 Windows 검증 `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 성공.
- 실물 확인: 기존 설치 marker를 재사용해 `availableInstalled`가 기록되고, `AZ1` payload/RAW dispatch까지 진행되며 한글이 출력되는지 확인한다. 글꼴 package 재설치는 불필요하다.
- stage/commit 대상: `lib/printing/label_sheet_print_job.dart`, `lib/home_page_manager.dart`, `test/label_sheet_print_job_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 unrelated 변경은 제외.
- 기능 커밋 완료: `344f425` (`Godex 한글 명령 CP949 인코딩 오류 수정`). 원격 push는 수행하지 않았다.

## 완료·실물 검증 대기: Godex G500 한글 Asian font 자동 프로비저닝 v1.0.46
- v1.0.45 실물 로그는 RAW spool `46865/46865` 성공과 ASCII `AT` 선명 출력을 확인했지만, G500 기본 내장 TTF에 한글 glyph가 없어 `AT`로 승인한 한글이 filtered raster에서도 제거된 뒤 누락됐다.
- 설치된 GoLabel II 1.2.0001에서 공식 `FontFile.dll`과 Korean 코드 테이블 `KSC.bin`/`KSC949.BIN`을 확인했다. DLL은 x86이며 `CreateKOFontFile` API를 export하므로 64비트 Flutter에서 직접 로드하지 않고 x86 helper 경계를 검토한다.
- 우선 수정: Asian font 설치가 확인되지 않은 기본 상태에서는 비ASCII 문자가 포함된 text candidate를 `AT`로 승인하지 않고 `~G` fallback에 보존한다. ASCII는 기존 제조사 내장 `AT`를 유지한다.
- 한글 raster 보존 focused 테스트 1건 통과.
- `windows/godex_font_helper/Program.cs`: GoLabel의 x86 `CreateKOFontFile` ABI를 그대로 호출해 GulimChe 16dot Korean `AZ1` package를 생성하는 helper를 추가했다. 공식 GoLabel 설치 DLL을 참조하며 DLL/font package를 앱에 복제하지 않는다.
- helper를 .NET Framework x86 compiler로 빌드하고 `굴림체/보통/16`을 선택해 공식 `AZ_KO16x16.DAT` 생성에 성공했다. 산출물은 282,127 bytes이며 AZ1용 package다.
- 자동 프로비저닝 구현 전 DAT 헤더가 그대로 RAW 전송 가능한 EZPL stream인지 확인한다.
- DAT는 `~MDELA,1` + `~F,1,Korean,16,16,...` + glyph binary로 구성된 완전한 RAW 설치 stream임을 확인했다. GoLabel SDK IL에서 출력 명령은 `AZ1,x,y,width,height,space,direction,data`임을 확인했다.
- `godex_korean_font_provisioner.dart`: 설치된 GoLabel/helper로 package를 캐시 생성하고 RAW 전체 byte 전송 성공 후에만 printer name+port+package ID marker를 저장한다. package 누락/생성 실패/부분 전송은 Asian font를 활성화하지 않는다.
- `windows/CMakeLists.txt`: .NET Framework x86 helper를 Windows 앱 빌드에 포함한다.
- `godex_korean_font_provisioner_test.dart`: 전체 전송 marker/reuse, 부분 전송 marker 금지, package 누락 fallback 테스트를 추가했다.
- provisioner focused 테스트 3건 통과.
- `label_sheet_print_job.dart`: 확인된 capability에서는 비ASCII/혼합 text candidate 전체를 `AZ1`로 승인하고 command data를 CP949로 encode한다. capability가 없으면 raster, ASCII는 기존 `AT` UTF-8을 유지한다.
- `label_sheet_print_job_test.dart`: provisioned Korean `AZ1` command와 CP949 payload 회귀 테스트를 추가했다. `charset_converter` channel은 실제 Windows CP949 기준 바이트로 mock한다.
- print job 테스트 파일 전체 13건 통과.
- `label_sheet_workbench.dart`: 라벨시트 Godex capture 전에 Korean font provisioner를 실행하고 성공 capability를 preparation에 전달한다. provision 결과와 AT/AZ1/raster 수, descriptor별 font/encoding을 기록한다.
- `home_page_manager.dart`: 품목·저울 발행도 세션당 1회 동일 provisioner를 실행하고 모든 unit capture에 같은 capability를 전달한다. AT/AZ1 descriptor 수를 로그에 기록한다.
- 실제 출력 경로 연결 후 production 4개 파일 편집기 진단 오류 0건.
- 버전을 `1.0.46`으로 증가했다.
- 변경 Dart 6개 파일 formatter 적용 완료.
- 출력 관련 테스트 실행 예정: `flutter test test/godex_korean_font_provisioner_test.dart test/label_print_dispatcher_test.dart test/label_print_pipeline_test.dart test/label_sheet_print_job_test.dart test/label_print_session_test.dart third_party/fortune_sheet/test/fortune_hybrid_print_plan_test.dart`.
- 출력 관련 테스트 43건 통과.
- strict analyzer 실행 예정: `flutter analyze lib/printing/godex_korean_font_provisioner.dart lib/printing/label_sheet_print_job.dart lib/features/label_sheet/label_sheet_workbench.dart lib/home_page_manager.dart test/godex_korean_font_provisioner_test.dart test/label_sheet_print_job_test.dart`.
- 최초 strict analyzer는 Korean capability 인자가 인접 Windows capture에 들어간 위치 오류와 null-aware collection 문법 오류를 보고했다. 인자를 EZPL capture로 이동하고 문법/info를 정리한 뒤 동일 analyzer 0 issues.
- formatter 후 출력 관련 테스트 64건 통과.
- Windows 검증 실행 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 후 helper 존재/PE x86, EXE version, `git diff --check` 확인.
- 최초 Windows `/WX` Debug 빌드는 CMake의 forward-slash C# source path를 `csc`가 옵션으로 해석해 실패했다. compiler/source/output을 native Windows 경로로 변환한 뒤 동일 빌드를 재실행한다.
- native path 수정 후 helper 빌드는 통과했으나 실행 중 Debug 앱 PID 2500의 파일 잠금으로 `LNK1168`이 발생했다. `CloseMainWindow`로 정상 종료 후 동일 Windows `/WX` Debug 빌드 성공.
- helper 존재/PE x86, 앱 EXE version, `git diff --check` 확인 예정.
- 빌드 산출물 확인: `label_manager.exe` FileVersion/ProductVersion `1.0.46`, `godex_font_helper.exe` 6,656 bytes 및 `14C machine (x86)`.
- `git diff --check` 통과, 변경 Dart 파일 편집기 진단 오류 0건.
- 최종 stage/commit 대상: Korean provisioner/helper/CMake, 라벨시트·품목·저울 AZ1 연결, print job과 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`, `pubspec.lock`, 삭제 상태의 `doc/EZPL_EN_J_20180226.pdf/.txt`는 제외한다.
- 기능 커밋: `ce0fd55 Godex 한글 폰트 자동 설치와 AZ1 출력`.
- 다음 실물 검증: marker가 없는 G500에서 최초 출력 시 `굴림체/보통/16` 선택 후 package spool 성공, 이어지는 라벨 payload의 `AZ1` 한글 품질과 이후 출력의 `availableInstalled` marker 재사용을 확인한다.
- 수정 예정: font package 생성/전송/설치 marker, 확인된 AZ slot 출력, provisioning 및 AT/AZ/raster 진단 로그와 테스트.

## 진행 중: Godex G500 제조사 내장 폰트 EZPL 직접 출력 v1.0.45
- 실물 v1.0.44 로그에서 `backend=windowsDriver`, G500 printable-area/DC 축소와 GDI 글꼴 raster 품질 저하를 확인했다. Godex 물리 포트만 `ezplRaw`, FILE/PORTPROMPT는 PDF, Zebra/BIXOLON/CITIZEN/기타는 기존 GDI로 자동 매핑한다.
- `label_print_dispatcher.dart`: `ezplRaw` backend와 Godex profile 기반 자동 라우팅, raw sender 계약을 복원했다.
- `raw_printer_win32.dart`: `StartDocPrinter`/`WritePrinter` RAW spool 전송과 job ID, 요청/기록 byte 진단을 복원했다.
- `label_sheet_print_job.dart`: 최종 FortuneSheet를 공용 hybrid plan으로 분리하고 G500 제조사 내장 TTF `AT` UTF-8 텍스트, `R` vector, `BQ/BA/BE/BB` barcode를 직접 출력한다. 미지원 이미지/배경/복합 스타일만 filtered PNG의 `~G` fallback으로 넣어 최종 출력 전체를 단일 EZPL job으로 만든다. 별도 RTF/Windows font/다운로드 font/AZ 슬롯은 사용하지 않는다.
- `label_sheet_workbench.dart`: 라벨시트/공용 capture controller에 2배 supersampling EZPL fallback capture를 연결했다. 고유 후보 token과 descriptor 수, 문자/줄/font dots/line bounds, 제외·fallback 사유, payload와 WritePrinter 결과를 구분해 기록한다.
- `home_page_manager.dart`: 품목·저울 라벨도 unit별 hybrid EZPL payload를 생성하고 group별 RAW spool job으로 전송한다. 비Godex GDI/PDF 경로는 유지한다.
- 테스트: dispatcher/print job focused 18건, 출력 pipeline/hybrid plan 59건 통과. G500 한글을 내장 `AT` UTF-8로 승인하고 `AT + ~G` 단일 payload를 생성하는 신규 focused 테스트 통과.
- 버전을 `1.0.45`로 증가했다.
- Dart formatter 적용 완료.
- 출력 관련 전체 테스트 실행 예정: `flutter test test/label_print_dispatcher_test.dart test/label_print_pipeline_test.dart test/label_sheet_print_job_test.dart test/label_print_session_test.dart third_party/fortune_sheet/test/fortune_hybrid_print_plan_test.dart`.
- strict analyzer 실행 예정: `flutter analyze lib/printing/label_print_dispatcher.dart lib/printing/raw_printer_win32.dart lib/printing/label_sheet_print_job.dart lib/features/label_sheet/label_sheet_workbench.dart lib/home_page_manager.dart test/label_print_dispatcher_test.dart test/label_sheet_print_job_test.dart`.
- formatter 후 출력 관련 전체 테스트 60건 통과.
- 최초 strict analyzer는 `home_page_manager.dart`의 `BytesBuilder` import 누락 2건으로 실패했다. `dart:typed_data` import 추가 후 동일 analyzer 재실행 결과 오류·경고 0건.
- Windows 검증 실행 예정: `$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug` 후 `git diff --check`, Debug EXE FileVersion/ProductVersion 확인.
- 최초 Windows `/WX` Debug build는 실행 중인 Debug `label_manager.exe`의 파일 잠금으로 `LNK1168` 실패했다. 빌드 산출물 PID 11668을 `CloseMainWindow`로 정상 종료한 뒤 동일 빌드 재실행에 성공했다.
- `git diff --check` 통과. Debug EXE FileVersion/ProductVersion 모두 `1.0.45` 확인.
- 최종 stage/commit 대상: `label_sheet_workbench.dart`, `home_page_manager.dart`, `label_print_dispatcher.dart`, `label_sheet_print_job.dart`, `raw_printer_win32.dart`, 출력 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`와 무관한 `pubspec.lock`은 제외한다.
- 기능 커밋: `91e3fc4 Godex 내장 폰트 EZPL 직접 출력 복원` (인수인계 해시 기록 amend 전 기준).
- stage/commit 예정: EZPL production 5개, 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`와 이번 작업과 무관한 자동 lockfile 변경 `pubspec.lock`은 제외한다.

## 완료·실물 검증 대기: 레거시 GDI 포팅 재점검 v1.0.44
- 사용자 확정: 세로 출력은 현재 용지 크기를 유지하지 않고 레거시 방식으로 폭·높이를 교환한다. 80x60 설정은 60x80 물리 용지로 출력한다.
- 확인된 수정 대상: 공용 `LabelSheetPrintLayout`의 세로 page/clip 크기, 품목·저울/라벨시트 dispatch의 실제 page mm, GDI native text의 source bitmap→printer DC 배율, `DocumentPropertiesW` DEVMODE 적용 실패 전달.
- `label_sheet_print_job.dart`: 세로 60x40 + 추가 2mm를 40x62mm page, 40x60mm clip으로 계산하도록 공용 layout/page API를 수정했다.
- `label_sheet_workbench.dart`, `home_page_manager.dart`: 라벨시트·품목·저울의 GDI/PDF dispatch page mm도 공용 세로 물리 크기를 사용한다.
- `label_bitmap_print_channel.cpp`: native text rect/font에 bitmap과 같은 source→actual DC 배율을 적용하고, 레거시에서 계산만 하고 쓰지 않던 `PHYSICALOFFSET` 음수 이동을 제거했다. DEVMODE 재적용 실패를 오류로 반환한다.
- 제기된 BIXOLON 복사, CITIZEN 폭, printer handle 누수는 레거시와 현재 호출 경로 대조 결과 실제 결함이 아니므로 추가 보완하지 않았다.
- 세로 물리 용지 focused 테스트 통과, 변경 Dart 파일 편집기 오류 0건. 버전을 `1.0.44`로 증가했다.
- 출력 관련 전체 테스트 52건 통과.
- 변경 Dart 4개 파일 strict analyzer 오류·경고 0건.
- Windows `/WX` Debug 빌드 성공. `git diff --check` 통과. Debug EXE FileVersion/ProductVersion 모두 `1.0.44` 확인.
- stage/commit 대상: `label_sheet_print_job.dart`, `label_sheet_workbench.dart`, `home_page_manager.dart`, Windows GDI bridge, 회귀 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `f252acc 레거시 GDI 출력 좌표와 세로 용지 보완`.

## 진행 중: 레거시 Windows GDI 프린터 엔진 포팅 v1.0.43
- 요청: 현재 raw EZPL/프린터별 직접 명령 중심 로직을 실제 고품질 레거시 `.tmp/LabelManager` 기준으로 제거하고, RTF 대신 최종 라벨시트를 출력 대상으로 포팅한다.
- 레거시 확인: `CPrintManager`는 직접 EZPL/ZPL/TSPL을 만들지 않는다. 프린터 이름을 GODEX/ZEBRA(ZDESIGNER)/BIXOLON/CITIZEN(CL-P7201E, CL-S700)/ETC로 분류한 뒤 모두 `CreateDC(WINSPOOL)` + GDI + Windows 드라이버로 출력한다.
- 실제 제조사 차이: BIXOLON은 `dmCopies=1`로 page를 반복 출력하고, CITIZEN은 주석의 20% 설명이 아니라 실제 식 `width*10 + int(width*0.2) + appendant`를 적용한다. GODEX `-2` 및 physical offset 인자는 호출되지만 `SetWidthFormatRange` 구현에서 사용되지 않아 동작상 무효다.
- `printer_profiles.dart`, `label_print_dispatcher.dart`: 선택 프린터 이름을 레거시 제조사 profile로 자동 매핑하고, 모든 물리 포트는 Windows driver, `FILE:/PORTPROMPT:`만 PDF로 라우팅한다. raw 언어 모델을 삭제했다.
- `label_bitmap_print_channel.cpp`, `windows_bitmap_printer.dart`: `DMPAPER_USER`, 실제 printer DPI 기준 mm 출력 크기, BIXOLON page 반복, CITIZEN 실제 폭 식, 별도 가로 폭 보정, driver 복사 수를 포팅했다.
- `label_sheet_print_job.dart`: FortuneSheet 공용 `TextPainter` layout으로 일반/inline 텍스트를 GDI descriptor로 전달하고, 이미지·바코드·복합 요소는 printer-DPI bitmap fallback으로 유지한다. EZPL preparation/preflight/payload/raster 코드는 삭제했다.
- `label_sheet_workbench.dart`, `home_page_manager.dart`: 라벨시트·품목·저울 발행의 raw capture/payload/send 분기를 삭제하고 Windows GDI/PDF만 사용한다.
- `raw_printer_win32.dart`: 프린터 선택/포트/DPI 조회는 유지하고 미사용 `WritePrinter` raw 전송 API를 삭제했다. production `lib/`의 EZPL/raw protocol 참조는 0건이다.
- 출력 설정 모델/저장/UI에 레거시 `Width Appendant` 의미의 `가로 폭 보정(mm)`을 `세로 추가`와 별도로 복원했다.
- EZPL 전용 테스트를 제거하고 Windows GDI/PDF 회귀 테스트를 유지했다. focused 검증: 포팅 관련 62건, dead EZPL 정리 후 print job 11건 및 dispatcher 6건 통과.
- 변경 Dart 파일 formatter 적용 및 편집기 analyzer 12개 파일 오류 0건.
- 출력 관련 전체 테스트 52건 통과.
- 최초 strict analyzer는 `raw_printer_win32.dart`의 미사용 `dart:typed_data` import 1건으로 실패했다. import 제거 후 동일 18개 파일 analyzer 재실행 결과 오류·경고 0건.
- CITIZEN 폭 계산을 레거시 실제 식으로 재대조해 보정 폭과 분리했으며 Windows `/WX` Debug 재빌드 성공.
- `git diff --check` 통과. Debug EXE FileVersion/ProductVersion 모두 `1.0.43` 확인.
- stage/commit 대상: 프린터 GDI 포팅 production 12개, 관련 테스트 6개, Windows bridge, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `cde3666 레거시 Windows GDI 프린터 엔진 포팅`.

## 완료·실물 검증 대기: Godex G500 출력 zoom/회전 정규화 v1.0.42
- v1.0.41 실물 `.tmp/KakaoTalk_20260803_214958449.jpg`와 `.tmp/log/app_2026-08-03_21-41-53.log` 분석: raw 전송은 `42749/42749`로 정상이나 native `AT`가 페이지 중심 기준 180도 반전됐고 하단 내용이 누락됐다.
- 직접 원인 1: EZPL job이 `^L`로 시작해 프린터에 저장된 whole-label rotation 상태를 상속했다. job-local `^LR0`로 회전을 명시적으로 초기화한다.
- 직접 원인 2: print geometry가 저장된 UI `sheet.zoomRatio` 약 1.7을 물리 좌표에 적용했다. 제조원 행이 49~58mm로 밀리고 30개 텍스트 중 12개가 `printerClip`으로 제외됐다. print snapshot만 `zoomRatio=1`로 정규화한다.
- 수정 예정: zoom/회전 회귀 테스트, source/print zoom·bounds·제외 좌표·줄별 명령 로그를 추가하고 검정 inline run을 run별 UTF-8 `AT`로 직접 출력한다.
- `label_sheet_print_job.dart`: 검정 inline run을 공용 `TextPainter`의 line boundary와 selection box로 분할해 run별 font size/bold/italic/underline을 보존한 UTF-8 `AT`로 출력한다. 비검정·취소선·배경·첨자 run만 명시적 fallback으로 남긴다.
- `label_sheet_print_job_test.dart`: `원재료명` 굵은 run과 일반 run의 실제 줄바꿈이 3개 native `AT`로 승인되는 회귀 테스트를 추가했다.
- focused 검증: 기존 한글 줄바꿈 `AT` 테스트와 신규 inline run native `AT` 테스트 통과.
- `fortune_print_plan.dart`: native text 후보 제외 시 reason 합계와 함께 셀 좌표, 원본 logical footprint, 변환된 printer footprint를 보존한다.
- `label_sheet_workbench.dart`: 품질 로그에 `sourceZoom`, 정규화 `printZoom`, `sourceLogicalBounds`, `printerClipDots`, 제외 셀별 reason/logical/printer footprint를 기록한다.
- 셀별 `printerClip` 제외 진단 focused 테스트와 변경 production 3개 파일 analyzer 통과. Dart formatter 적용 완료.
- 전체 출력 검증 실행 예정: `flutter test test/label_print_dispatcher_test.dart test/label_print_pipeline_test.dart test/label_sheet_print_job_test.dart test/label_print_session_test.dart third_party/fortune_sheet/test/fortune_hybrid_print_plan_test.dart`.
- 출력 관련 전체 테스트 70건 통과. 공용 line layout에 원문 `textStart/textEnd`를 보존해 빈 줄이 있어도 inline run fragment offset을 추정하지 않으며 focused 테스트 재통과.
- 버전을 `1.0.42`로 증가했다.
- 최종 검증 실행 예정: 변경 Dart 파일 strict analyzer, `$env:CL='/WX'; flutter build windows --debug`, `git diff --check`, Debug EXE FileVersion/ProductVersion 확인.
- 변경 production/test 5개 파일 strict analyzer 오류·경고 0건. line offset 보강 후 출력 관련 전체 테스트 70건을 재실행한다.
- line offset 보강 후 출력 관련 전체 테스트 70건 재통과.
- Windows 검증 실행 예정: `$env:CL='/WX'; flutter build windows --debug` 후 `git diff --check`, `build/windows/x64/runner/Debug/label_manager.exe` FileVersion/ProductVersion 확인.
- Windows `/WX` Debug build 성공. 최종 `git diff --check`와 Debug EXE FileVersion/ProductVersion를 확인한다.
- `git diff --check` 통과. Debug EXE FileVersion/ProductVersion 모두 `1.0.42` 확인.
- stage/commit 대상: EZPL production 2개, FortuneSheet print plan, 관련 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `329484a Godex EZPL 출력 좌표와 직접 텍스트 개선`.

## 완료·실물 검증 대기: Godex G500 경계 셀 EZPL 직접 출력 v1.0.41
- v1.0.40 실물 `.tmp/KakaoTalk_20260803_205704138.jpg`와 `.tmp/log/app_2026-08-03_20-39-52.log` 분석: raw 전송은 `42461/42461`, native `AT` 텍스트는 선명하지만 30개 렌더 텍스트 중 20개가 모두 `printerClip`에서 후보 생성 전 탈락했다.
- `cellText=10`, `fontHeight=17..17`이며 원부재료·검은 띠·영양정보·하단 문구는 raster에 남았다. 물리 라벨 경계를 일부 넘는 병합/끝 셀 footprint를 전부 거절한 것이 직접 원인이다.
- `fortune_print_plan.dart`: 셀과 물리 page의 교차 영역을 native 제거 footprint로 사용하되 원래 셀 footprint를 텍스트 레이아웃 영역으로 별도 보존했다. 경계 셀 focused 테스트 통과.
- `fortuneLayoutCellText`: 화면 캡처와 EZPL이 동일한 `TextPainter` 인스턴스/offset 계산을 사용하도록 공용화했다. font family/size/bold/italic/line-height/정렬과 nowrap clamp를 보존하며 실제 줄 문자열과 좌표를 반환한다.
- `label_sheet_print_job.dart`: 고정 한글 폭 추정과 임의 줄간격을 제거하고 공용 레이아웃의 각 줄을 UTF-8 `AT`로 변환한다. 원래 셀 영역을 넘는 줄은 `widthOverflow/heightOverflow` fallback으로 유지한다.
- `label_sheet_workbench.dart`: `textLayouts` 진단에 각 `AT` 줄의 실제 dot `x,y,width,height`를 추가했다.
- GoLabel의 `AZ1`~`AZ9` Asian font 설정은 모두 비어 있다. 검증되지 않은 `At ... I`를 보내면 한글 누락 위험이 있어 검은 배경/흰 글자는 현재 `~G` EZPL fallback을 유지한다.
- focused/핵심 출력 테스트 33건 통과. 페이지 경계 셀의 UTF-8 `AT` 승인 통합 테스트를 추가했고 focused 재검증에 통과했다.
- 버전을 `1.0.41`로 증가했다. 검증 실행 예정: 출력 관련 전체 테스트, 변경 파일 analyzer, Windows `/WX` Debug build, `git diff --check`, EXE 버전 확인.
- 출력 관련 전체 테스트 67건 통과.
- analyzer 실행 예정: `flutter analyze lib/printing/label_sheet_print_job.dart lib/features/label_sheet/label_sheet_workbench.dart third_party/fortune_sheet/lib/src/fortune_print_plan.dart test/label_sheet_print_job_test.dart third_party/fortune_sheet/test/fortune_hybrid_print_plan_test.dart`.
- 최초 analyzer는 `fortune_print_plan.dart`의 중복 `dart:ui` import info 1건으로 실패했다. import 제거 후 동일 analyzer 재실행 결과 오류·경고 0건.
- Windows 검증 실행 예정: `$env:CL='/WX'; flutter build windows --debug` 후 `git diff --check`, EXE FileVersion/ProductVersion 확인.
- 최초 Windows `/WX` Debug 빌드는 실행 중인 Debug `label_manager.exe`의 파일 잠금으로 `LNK1168` 실패했다. PID 6680의 빌드 산출물 앱을 `CloseMainWindow`로 정상 종료했으며 동일 빌드를 재실행한다.
- Debug 앱 정상 종료 후 Windows `/WX` Debug 재빌드 성공. 최종 `git diff --check`와 EXE FileVersion/ProductVersion 확인을 실행한다.
- 공용 layout 연결 후 EZPL 한글 줄바꿈, filtered capture, screenshot 수평 정렬, red number TextSpan pixel focused 테스트 4건 통과. 최종 전체 출력 테스트/analyzer/Windows build를 재실행한다.
- 최종 출력 관련 전체 테스트 67건 재통과.
- 최종 strict analyzer는 canvas 제외 변경 5개 파일 오류·경고 0건. `fortune_sheet_canvas.dart --no-fatal-warnings`는 기존 미사용 경고 10건만 있고 새 오류는 없다.
- 최종 Windows `/WX` Debug build 재실행 예정.
- Dart formatter 적용 후 최종 출력 테스트 67건, strict analyzer 오류·경고 0건, Windows `/WX` Debug build 재통과.
- `git diff --check` 통과. Debug EXE FileVersion/ProductVersion 모두 `1.0.41` 확인.
- stage/commit 대상: EZPL production 2개, FortuneSheet layout/canvas 2개, 관련 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `a10317b Godex 경계 셀 EZPL 직접 출력 개선`.
- v1.0.39 실물 `.tmp/KakaoTalk_20260802_234102362.jpg`와 `.tmp/log/app_2026-08-02_23-39-00.log` 분석: `backend=ezplRaw`, `WritePrinter=42230/42230`, 내장 UTF-8 한글 출력은 성공했다.
- 원인은 화면/PNG만 `dynamicArrayCompute` 값을 렌더 셀로 변환하고 print plan은 원본 `sheet.cells`만 읽어 정적 텍스트 9개/35자만 직접 승인한 것이다. 품목명·중량·날짜·제조원 등 동적 값은 raster에 남아 직접 텍스트와 배치가 달라졌다.
- 수정 예정: FortuneSheet 공용 동적 텍스트 materialize helper를 추가하고, EZPL 후보 생성과 fallback 캡처가 동일한 snapshot을 사용하도록 한다. 후보/승인 누락 사유 로그도 확장한다.
- `fortuneSheetMaterializeDynamicComputedText`: `dynamicArrayCompute` map/list의 `v`를 기존 셀 스타일을 보존한 출력 셀로 변환한다. EZPL plan과 filtered PNG가 동일 snapshot을 사용한다.
- raw 로그에 전체 렌더 텍스트 수, 동적 materialize 수, 후보 전 제외 수, preflight 거절 사유, 각 직접 텍스트의 셀 token/영역/font dot/줄 수를 추가했다.
- FortuneSheet 후보 생성 전 제외 사유도 `nativeDisabled/outsideRange/nonMergeAnchor/emptyFootprint/objectOverlap/rawOverlayOverlap/printerClip`별로 기록한다.
- 강제 줄간격은 더 이상 전체 fallback 사유가 아니며, EZPL 줄별 Y advance에 비율을 직접 반영한다.
- 테스트: 동적 map/list 물질화 후 후보 증가, 동적 값 3건의 UTF-8 `AT` payload 승인, 승인된 동적 텍스트의 filtered PNG 완전 제거를 고정했다.
- 버전은 `1.0.40`으로 증가했다. 검증 예정: 출력 관련 테스트, 변경 파일 analyzer, Windows `/WX` Debug build, `git diff --check`.
- 검증 실행 예정: `flutter test test/label_print_dispatcher_test.dart test/label_print_pipeline_test.dart test/label_sheet_print_job_test.dart test/label_print_session_test.dart third_party/fortune_sheet/test/fortune_hybrid_print_plan_test.dart`.
- 관련 focused 테스트 32건 통과. 변경 production/test 8개 파일 analyzer 오류·경고 0건.
- 최종 출력 관련 테스트 65건 통과.
- Windows 검증 실행 예정: `$env:CL='/WX'; flutter build windows --debug` 후 `git diff --check`, EXE 버전 확인.
- Windows `/WX` Debug 빌드와 `git diff --check` 통과. EXE FileVersion/ProductVersion 모두 `1.0.40` 확인.
- 후보 제외 진단 반영 후 최종 analyzer 재실행 결과 오류·경고 0건, `git diff --check` 재통과.
- stage/commit 대상: EZPL production 2개, FortuneSheet print plan, 관련 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `c767e2b Godex 동적 셀 EZPL 직접 출력 적용`.
- v1.0.38 실물과 `.tmp/log/app_2026-08-02_23-12-13.log` 분석: native text 9/9, DrawTextW 9/9 성공이지만 Godex driver가 Arial 17-dot antialias를 점무늬로 변환해 품질이 낮다.
- G500의 Windows driver 우선을 제거해 `ezplRaw` backend로 전환했다.
- `label_sheet_print_job.dart`: 일반 가로 검정 셀 텍스트를 EZPL `AT` UTF-8 명령으로 생성하고, 셀 내부 줄 분할·정렬·bold/italic/underline을 적용한다. 승인된 텍스트는 fallback PNG에서 제외한다.
- overflow·회전·세로쓰기·inline rich run·justify·강제 줄간격·Y offset·비검정색·취소선 텍스트는 bitmap fallback을 유지한다. `AT` 매뉴얼에 없는 inverse style은 사용하지 않는다.
- `label_sheet_workbench.dart`, `home_page_manager.dart`: 라벨 시트·품목·저울 raw 출력에 후보/승인 종류, 텍스트 승인/fallback 수, 글자/줄/UTF-8 byte, font dot 범위, fallback PNG와 최종 payload 크기를 기록한다.
- `raw_printer_win32.dart`: spool job ID와 `WritePrinter` 요청/실제 기록 byte를 반환해 로그에 남긴다.
- 한글 UTF-8 payload/2줄 `AT` 분할, 미지원 속성 및 셀 높이 초과 fallback 테스트를 추가했다.
- 배경·이미지·조건부 서식은 합성 순서와 흰색 knockout 문제 때문에 bitmap fallback을 유지한다. 검은 띠/도형과 바코드는 기존 EZPL 명령을 유지한다.
- 버전은 `1.0.39`로 증가했다. 다음 단계는 실제 G500 내장 TTF의 한글 glyph 지원을 실물 검증하는 것이다.
- 검증 실행 예정: `flutter test test/label_print_dispatcher_test.dart test/label_print_pipeline_test.dart test/label_sheet_print_job_test.dart test/label_print_session_test.dart`.
- 출력 관련 테스트 29건 통과.
- analyzer 실행 예정: `flutter analyze lib/printing/label_sheet_print_job.dart lib/printing/printer_profiles.dart lib/printing/raw_printer_win32.dart lib/features/label_sheet/label_sheet_workbench.dart lib/home_page_manager.dart test/label_print_dispatcher_test.dart test/label_sheet_print_job_test.dart`.
- 최초 analyzer는 `label_sheet_workbench.dart`의 `dart:convert` import 누락 1건으로 실패했다. import 추가 후 동일 명령 재실행 결과 오류/경고 0건.
- Windows 검증 실행 예정: `$env:CL='/WX'; flutter build windows --debug` 후 `git diff --check`.
- 최종 출력 관련 테스트 50건 통과, 변경 파일 analyzer 오류/경고 0건.
- 최종 Windows `/WX` Debug 빌드와 `git diff --check` 통과. EXE FileVersion/ProductVersion 모두 `1.0.39` 확인.
- stage/commit 대상: EZPL 출력 production 5개, 출력 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart`는 제외한다.
- 기능 커밋: `e77b3d3 Godex EZPL 직접 텍스트 출력 적용`.
- 사용자 출력 사진에서 내용 위치/비율 왜곡과 작은 글자 획 손실을 확인했다. RTF 출력은 사용하지 않는다.
- 레거시는 원본 RTF를 printer DC에 직접 그리지만, 현재 앱은 최종 FortuneSheet 편집 결과를 출력해야 하므로 EZPL 정밀 좌표 + 셀 bitmap fallback 구조를 유지한다.
- 원인 1: 물리 라벨 경계가 마지막 포함 셀 전체로 확장되어 source 크기와 bitmap이 편집 mm보다 커졌다.
- `label_sheet_print_job.dart`: hybrid source bounds/metrics를 정확한 `FortuneSheetGridClientPhysicalSize`로 제한했다.
- `fortune_sheet_canvas.dart`: hybrid와 일반 PNG 캡처에 논리 clip 크기를 적용했다.
- `label_sheet_workbench.dart`: PDF 캡처도 물리 라벨 논리 크기를 전달한다.
- `label_sheet_workbench.dart`: EZPL bitmap fallback 캡처를 2배 supersampling한다.
- `label_sheet_print_job.dart`: 203dpi 최종 raster로 평균 축소 후 luminance 200 이하의 antialias 획을 보존한다. EZPL 테두리/바코드 좌표는 기존 printer dot 좌표를 유지한다.
- `label_sheet_print_job_test.dart`: 정확한 10mm source bounds와 luminance 200/201 이진화 경계를 고정했다. focused test 2건 통과.
- `printer_profiles.dart`: G500의 실제 좌표계인 8 dots/mm(203.2dpi)를 사용하고 다른 프린터는 device DPI를 유지한다.
- `home_page_manager.dart`, `label_sheet_workbench.dart`: 공용 G500 DPI 해석을 라벨/저울/시트 출력에 적용했다.
- 최종 관련 테스트 43건 통과.
- 변경 파일 diagnostics 0건. `--no-fatal-warnings` analyzer는 변경 오류 없이 기존 FortuneSheet canvas 미사용 경고 10건만 보고했다.
- 실행 중 Windows Flutter 앱에 최종 hot restart 성공, runtime error 없음. 수정 코드로 즉시 실물 재출력 가능하다.
- 버전은 호환 가능한 출력 버그 수정으로 `1.0.27`에서 `1.0.28`로 PATCH 증가했다.
- `git diff --check` 통과, 버전 생성 결과 `1.0.28`.
- stage 대상: 출력 production 5개, 관련 테스트 3개, FortuneSheet canvas/test, `pubspec.yaml`, `SESSION_HANDOFF.md`; 사용자 변경 `lib/core/app.dart` 제외.
- 기능 커밋: `3fc231e Godex 출력 크기와 래스터 품질 개선`.
- v1.0.28 실물 출력에서 위치/크기는 개선됐지만 작은 글자 획 손실, 계단, 굵은 선 번짐이 남았다.
- 원인: 최종 FortuneSheet를 앱에서 203dpi 1-bit EZPL `~G`로 직접 양자화해 Windows/Godex 드라이버의 폰트 rasterization과 보정을 우회한다.
- RTF는 사용하지 않는다. 최종 FortuneSheet를 406.4dpi로 캡처해 물리 크기 PDF로 만든 뒤 Godex Windows 드라이버에 전달한다.
- PDF 가상 프린터와 구분되는 `windowsDriver` backend를 추가하고 PDF 단일 파일 옵션에는 영향을 주지 않는다.
- 출력 로그에 앱 버전, backend, device/resolved/render DPI, 라벨/source mm, capture pixel/PNG/PDF bytes, 접수 결과를 기록한다.
- `label_print_dispatcher.dart`: PDF 가상 프린터와 분리된 `windowsDriver` backend 및 2배 render DPI 계산을 추가했다.
- `printer_profiles.dart`: Windows의 G500 profile이 드라이버 출력을 우선하도록 명시했다.
- `home_page_manager.dart`: 품목/저울 G500 출력을 406.4dpi PNG → 물리 크기 PDF → `Printing.directPrintPdf` 경로로 전환했다. 단계별 품질 진단 로그를 추가했다.
- `label_sheet_workbench.dart`: 라벨 시트 직접 출력도 같은 드라이버 경로를 사용하고 capture logical/pixel/bytes와 PDF/접수 결과를 기록한다.
- `label_sheet_workbench.dart`: `directPrintPdf`에 실제 라벨 폭·추가영역 포함 높이와 0 margin을 명시해 드라이버 기본 용지 크기 개입을 막았다.
- PDF 단일 파일 병합은 기존처럼 `LabelPrintBackend.pdf`에만 적용하며 `windowsDriver`에는 적용하지 않는다.
- 정적 검사 완료: `flutter analyze lib/printing/label_print_dispatcher.dart lib/printing/printer_profiles.dart lib/features/label_sheet/label_sheet_workbench.dart lib/home_page_manager.dart` 결과 오류/경고 0건.
- 관련 테스트 완료: `flutter test test/label_print_dispatcher_test.dart test/label_print_pipeline_test.dart test/label_sheet_print_job_test.dart test/label_print_session_test.dart` 41건 통과.
- Windows Debug 빌드 완료: `flutter build windows --debug` 성공.
- 마지막 물리 page format 보정 후 analyzer 0건, Windows Debug 재빌드, `git diff --check`를 다시 통과했다.
- 생성 EXE의 FileVersion/ProductVersion과 새 실행 로그 `.tmp/log/app_2026-08-02_17-58-51.log`의 `DebugLogger version`이 모두 `1.0.29`임을 확인했다. 검증용 프로세스는 종료했다.
- 실물 출력 시 로그에서 `backend=windowsDriver`, `renderDpi=406.4`, capture pixel/bytes, PDF bytes, dispatch 결과를 확인할 수 있다.
- stage/commit 대상: 출력 production 4개, 관련 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`; 사용자 변경 `lib/core/app.dart` 제외.
- 기능 커밋: `627942e Godex 드라이버 고품질 출력 적용`.
- v1.0.29 실물에서 검은 영역은 정상이나 작은 한글과 가는 선이 점 단위로 탈락했다. 로그상 G500 `windowsDriver`, 406.4dpi, 80×60mm=1281×961px 경로는 정상 실행됐다.
- 원인은 406.4dpi PNG의 회색 antialias 획을 203.2dpi 드라이버가 다시 halftone 처리하면서 작은 획을 버리는 것이다.
- `label_sheet_print_job.dart`: 2배 capture를 203.2dpi printer dots로 average 축소한 뒤 luminance 224 기준 완전한 흑/백 PNG로 고정하는 `prepareLabelSheetWindowsDriverRaster`를 추가했다.
- 품목/저울/라벨 시트의 `windowsDriver`에만 정규화를 적용한다. PDF 가상 프린터와 raw EZPL 경로는 변경하지 않는다.
- 로그에 capture source, 최종 printer dots, threshold, ink pixels/percent, 정규화 PNG bytes를 기록한다.
- focused test와 출력 관련 테스트 42건 통과.
- 변경 파일 analyzer 오류/경고 0건, `git diff --check` 통과.
- 최초 Windows Debug 빌드는 실행 중이던 v1.0.29 PID 3828의 EXE 잠금으로 `LNK1168` 실패했다. 사용자 정상 종료 확인 후 재실행했다.
- Windows Debug 빌드 성공. EXE FileVersion/ProductVersion과 `.tmp/log/app_2026-08-02_18-15-33.log` logger 헤더가 모두 `1.0.30`임을 확인했다. 검증용 PID 2220은 종료했다.
- 다음 실물 출력 로그에서 `normalize source=1281x961 printerDots=640x480 threshold=224`, ink 비율, PDF bytes, accepted 결과를 확인한다.
- stage/commit 대상: 출력 production 3개, 관련 테스트 1개, `pubspec.yaml`, `SESSION_HANDOFF.md`; 사용자 변경 `lib/core/app.dart` 제외.
- 기능 커밋: `9b5ed58 Godex 작은 글자 출력 품질 개선`.
- v1.0.30 실물은 203.2dpi 강제 1-bit 변환 때문에 모든 글자와 선이 dot 격자로 깨지는 명확한 회귀였다. 로그는 `1281x961 -> 640x480`, threshold 224, ink 18.53% 변환이 실행됐음을 확인했다.
- EZPL 문서의 `~G`는 1-bit graphic stream이므로 복합 한글 FortuneSheet의 레거시 품질을 재현할 수 없다. 초기 `.tmp/label_printer`도 unsupported drawable에 raster fallback을 사용한다.
- 레거시 `PrintManager.cpp`는 G500 DEVMODE의 용지를 0.1mm 단위로 설정하고 `CreateDC("WINSPOOL")`, `StartDoc/StartPage`, `EM_FORMATRANGE/DisplayBand`로 printer DC에 직접 렌더링한다.
- 새 `label_bitmap_print_channel.cpp`: printer DEVMODE에 실제 라벨 폭/높이를 설정하고 32-bit top-down BGRA를 `HALFTONE StretchDIBits`로 printer DC에 직접 출력한다. PDF 재샘플링과 앱 1-bit 양자화를 모두 제거했다.
- `prepareLabelSheetWindowsDriverPage`: 406.4dpi 전체 페이지 BGRA에서 antialias를 보존하며 margin/push/orientation/clip을 적용한다. v1.0.30 threshold 재도입 금지 주석을 남겼다.
- 품목/저울/라벨 시트 G500 출력은 `WindowsBitmapPrinter` method channel을 사용한다. PDF virtual printer와 raw EZPL은 기존 경로를 유지한다.
- 로그에 BGRA page 크기/bytes, ink/antialias 비율과 native printer DPI, target/HORZRES/VERTRES, physical size/offset, DEVMODE paper, StretchDIBits 결과를 기록한다.
- 출력 관련 테스트 최종 43건 통과. 변경 파일 analyzer 오류/경고 0건, `git diff --check` 통과.
- Windows `/WX` Debug 빌드 성공. EXE FileVersion/ProductVersion과 `.tmp/log/app_2026-08-02_18-36-17.log` logger 헤더가 모두 `1.0.31`임을 확인했다. 검증용 PID 9912는 종료했다.
- 실제 G500 출력은 용지를 소모하므로 자동 실행하지 않았다. 다음 실물 로그에서 `gdiPage=1280x960`, `gdiDispatch printerDpi=203x203`, `target=640x480`, `stretchLines`를 확인한다.
- stage/commit 대상: 출력 Dart 5개, Windows runner 4개, 관련 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`; 사용자 변경 `lib/core/app.dart` 제외.
- 기능 커밋: `e29ad21 Godex GDI 직접 출력 적용`.
- v1.0.31 실물은 회색 antialias가 거친 점무늬로 출력됐다. 로그에서 `source=1280x960 target=639x480`, `HALFTONE`, `physical=640x480`, `offset=10,0`, `HORZRES=620`을 확인했다.
- 원인: GDI가 2배 BGRA를 203dpi로 HALFTONE 축소하면서 열전사 드라이버가 회색을 거친 dither로 변환했고, 203 정수 DPI 계산으로 물리 폭도 639 dots가 됐다.
- `prepareLabelSheetWindowsDriverPage`: 2배 source를 정확한 203.2dpi 640×480으로 average 축소한 뒤 coverage threshold 160으로 완전한 흑/백 printer dots를 생성한다. v1.0.30의 과도한 threshold 224는 재사용하지 않는다.
- native GDI: `COLORONCOLOR`, physical 640×480, destination `-PHYSICALOFFSET`으로 1:1 복사해 추가 halftone/축소를 제거한다.
- 로그에 threshold와 8단계 luminance histogram, native destination/physical offset을 추가했다.
- 출력 관련 테스트 43건 통과. 변경 파일 analyzer 오류/경고 0건, `git diff --check` 통과.
- Windows `/WX` Debug 빌드 성공. EXE FileVersion/ProductVersion과 `.tmp/log/app_2026-08-02_18-48-57.log` logger 헤더가 모두 `1.0.32`임을 확인했다. 검증용 PID 17804는 종료했다.
- 다음 실물 로그에서 `gdiPage=640x480`, threshold 160/luminance bins, `source=640x480 target=640x480`, `destination=-10,0`, `stretchLines=480`을 확인한다.
- stage/commit 대상: 출력 Dart 3개, Windows channel 1개, 테스트 1개, `pubspec.yaml`, `SESSION_HANDOFF.md`; 사용자 변경 `lib/core/app.dart` 제외.
- 기능 커밋: `4a24ecd Godex 도트 출력 품질 개선`.
- v1.0.32 실물에서 일반 글자는 선명해졌지만 작은 원재료 한글 획이 끊겼다. 로그상 640×480 GDI 1:1 전송은 정확했다.
- luminance histogram은 160~223 구간에 3,909픽셀이 있었고 threshold 160이 이를 모두 흰색으로 버린 것이 원인이다.
- 단일 임계값 조정을 폐기하고 serpentine Floyd-Steinberg 오차 확산으로 2배 supersampling coverage를 주변 printer dot에 배분한다. 최종 payload는 여전히 완전한 흑/백 640×480이므로 드라이버 halftone은 발생하지 않는다.
- 로그에 source coverage 상당 ink, 최종 black dot coverage 보존율, 누적 양자화 오차를 추가했다.
- 출력 관련 테스트 43건 통과. 변경 파일 analyzer 오류/경고 0건, `git diff --check` 통과.
- `CL=/WX flutter build windows --debug` 성공.
- EXE FileVersion/ProductVersion 및 새 Debug 로그의 `DebugLogger version`이 모두 `1.0.33`임을 확인했다.
- 실물 출력 로그에서 `quantizeMode=floydSteinbergSerpentine`, `coverageInk`, `coveragePreserved`, `quantizationError`를 확인한다.
- 최종 로그 필드 반영 후 출력 관련 테스트 43건 재통과, 편집 파일 진단 오류 0건.
- 최종 `CL=/WX flutter build windows --debug` 및 `git diff --check` 성공.
- stage/commit 대상: `lib/printing/label_sheet_print_job.dart`, 출력 로그 call site 2개, 관련 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart` 제외.
- 기능 커밋: `e144d44 Godex 작은 글자 coverage 보존 개선`.
- v1.0.33 실물과 `.tmp/log/app_2026-08-02_21-03-19.log` 분석: 전체 coverage는 `99.82%`로 보존됐지만 Floyd-Steinberg가 작은 한글 획 내부의 black dot을 분산시켜 점선 형태로 열화했다.
- 2×2 supersampling 중 1개 원본 pixel에 해당하는 25% coverage를 printer dot으로 보존하는 독립 구조 판정으로 교체 중이다. GDI 640×480 1:1 경로는 유지한다.
- 로그 예정: partial coverage로 채택한 dot 수, 버린 coverage 상당량, 주변 8-dot과 연결되지 않은 고립 black dot 수.
- `minimumStructuralCoverage` 이진화와 `partialCoverageInk`, `discardedCoverage`, `isolatedInk` 로그를 출력 진입점 3곳에 적용했다.
- 25% edge dot이 본 획 옆에 연속 black dot으로 연결되고 `isolatedInk=0`인 fixture를 추가했다.
- 출력 관련 테스트 44건 통과, 변경 파일 진단 오류 0건, 제거한 Floyd-Steinberg 참조 0건.
- 변경 파일 analyzer 오류/경고 0건, 출력 관련 테스트 44건 및 `git diff --check` 통과.
- 최종 focused diff 기준 `CL=/WX flutter build windows --debug` 성공. EXE FileVersion/ProductVersion 및 logger가 모두 `1.0.34`임을 확인했다.
- stage/commit 대상: 출력 Dart 3개, 관련 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart` 제외.
- 기능 커밋: `258f64d Godex 작은 글자 획 연결성 개선`.
- v1.0.34 실물과 `.tmp/log/app_2026-08-02_21-19-09.log` 분석: source coverage 상당량 `48406.46` 대비 `54404` black dots로 `112.39%` 과팽창했다. `partialCoverageInk=14513`의 25% edge 일괄 채택이 글자와 선을 굵고 각지게 만든 원인이다.
- 50% 이상 coverage의 core 획을 고정하고 밝은 edge 후보를 어두운 순서로 core에 8방향 연결하면서 source coverage 목표 개수까지만 성장시키는 방식으로 교체 중이다.
- GDI 640×480 1:1 경로는 유지한다. 로그에 target/core/connected edge/rejected edge/discarded coverage/isolated ink를 기록할 예정이다.
- `connectedCoverageGrowth` 구현 완료. 로그에 core luminance 기준과 `targetShortfall`까지 추가했다.
- 출력 관련 테스트 44건 통과, 편집 파일 진단 오류 0건, 이전 25% 구조 threshold 참조 0건.
- 변경 파일 analyzer 오류/경고 0건 및 `git diff --check` 통과.
- `CL=/WX flutter build windows --debug` 성공. EXE FileVersion/ProductVersion 및 logger가 모두 `1.0.35`임을 확인했고 검증 프로세스를 종료했다.
- stage/commit 대상: 출력 Dart 3개, 관련 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart` 제외.
- 기능 커밋: `7f965b0 Godex 글자 coverage 과팽창 개선`.
- v1.0.35 실물과 `.tmp/log/app_2026-08-02_21-35-33.log` 분석: `coreInk=52005`가 source coverage `48406.46`보다 이미 커 `connectedEdgeInk=0`, `coveragePreserved=107.43%`였다. 406.4dpi 평균 축소 후 전역 이진화하는 접근이 작은 한글 획을 계속 훼손했다.
- Windows backend를 최종 printer grid인 203.2dpi에서 직접 캡처하도록 변경 중이다. 캡처 `ceil`로 641×481이 되면 평균 resize 없이 오른쪽/아래 1px만 crop한다.
- 최종 native grid에서 luminance 127.5 기준으로 1-bit화한다. PDF/EZPL raw와 GDI 640×480 1:1 전송은 변경하지 않는다.
- 로그에 `rasterInput`, `rasterMapping`, native-grid threshold, coverage, discarded coverage, isolated ink를 기록한다. `averageResize`는 native-grid 실패 신호다.
- dispatcher/print job 집중 테스트 18건 통과.
- 출력 관련 테스트 44건 통과, 편집 파일 진단 오류 0건, 이전 연결 성장 참조 0건.
- 변경 파일 analyzer 오류/경고 0건 및 `git diff --check` 통과.
- `CL=/WX flutter build windows --debug` 성공. EXE FileVersion/ProductVersion 및 logger가 모두 `1.0.36`임을 확인했고 검증 프로세스를 종료했다.
- 다음 실물 로그 정상 조건: `renderDpi=203.2`, `rasterInput=641x481` 또는 `640x480`, `rasterMapping=cropCeilOverflow` 또는 `direct`, `gdiPage=640x480`.
- stage/commit 대상: 출력 Dart 4개, 관련 테스트 2개, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart` 제외.
- 기능 커밋: `bae6848 Godex native-grid 글자 출력 적용`.
- v1.0.36 실물과 `.tmp/log/app_2026-08-02_22-29-20.log` 분석: native-grid/crop/GDI 1:1은 정상이나 작은 원재료 글자가 심하게 끊겼다. 앱 threshold가 `antialias=7987` 회색 edge 중 coverage `1705.13`을 흰색으로 버린 것이 원인이다.
- 과거 grayscale 실패는 1280×960→639×480 `HALFTONE` 축소와 결합된 결과였다. 이번에는 640×480 native-grid grayscale을 크기 변환 없이 `COLORONCOLOR` 1:1로 드라이버에 전달한다.
- 로그 예정: `toneMode=driverMonochrome`, exact black, gray, non-white, coverage 상당량, raster mapping, native GDI 1:1 진단.
- native 진단에 `sourceBpp=32`, `compression=BI_RGB`, `rasterOp=SRCCOPY`를 추가했다. Dart 로그는 exact black/gray/non-white/white를 분리한다.
- grayscale fixture에서 luminance 63/225가 BGRA에 그대로 보존되는 집중 테스트 통과.
- 출력 관련 테스트 44건 통과, 편집 Dart 파일 진단 오류 0건. Windows 경로의 threshold 참조는 0건이며 남은 threshold는 EZPL raw 전용이다.
- 변경 파일 analyzer 오류/경고 0건 및 `git diff --check` 통과.
- `CL=/WX flutter build windows --debug` 성공. EXE FileVersion/ProductVersion 및 logger가 모두 `1.0.37`임을 확인했고 검증 프로세스를 종료했다.
- 다음 실물 로그 정상 조건: `toneMode=driverMonochrome`, `gray>0`, `sourceBpp=32`, `compression=BI_RGB`, `rasterOp=SRCCOPY`, source/target `640x480`.
- stage/commit 대상: 출력 Dart 3개, Windows channel, 관련 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart` 제외.
- 기능 커밋: `4def9f6 Godex native-grid 회색 출력 적용`.
- v1.0.37 실물과 `.tmp/log/app_2026-08-02_22-41-42.log` 분석: grayscale 7,987픽셀과 32-bit SRCCOPY 640×480 전달은 정상이나 Godex 드라이버가 회색을 거친 halftone으로 변환했다.
- 레거시 고품질의 핵심은 RTF 데이터가 아니라 RichEdit `FormatRange/DisplayBand`가 printer DC에 텍스트를 직접 그리는 구조다.
- FortuneSheet 공용 hybrid plan에 `cellText` 후보, 승인 텍스트 좌표, fallback PNG 텍스트 제외 hook을 추가 중이다. 단순 셀 텍스트는 GDI `DrawTextW`, unsupported 텍스트/이미지는 bitmap fallback으로 출력할 예정이다.
- `fortune_print_plan.dart`, `fortune_sheet_canvas.dart`: 승인된 일반 셀 텍스트 좌표만 fallback PNG에서 제외하고 나머지 drawable은 기존 raster fallback에 남긴다.
- `label_sheet_print_job.dart`: 일반 셀 텍스트를 printer-dot RECT, 폰트/스타일/색상/정렬 정보가 포함된 Windows descriptor로 변환한다. inline run, 세로/회전, overflow, 강제 줄간격은 승인하지 않는다.
- `label_sheet_workbench.dart`, `home_page_manager.dart`: 시트 직접/품목/저울 Windows 출력을 filtered fallback PNG와 native descriptor 조합으로 연결했다. 로그에 텍스트 후보/승인/fallback 수를 추가했다.
- `windows_bitmap_printer.dart`, `label_bitmap_print_channel.cpp`: MethodChannel descriptor 전달과 fallback bitmap 이후 `CreateFontW`/`DrawTextW` printer-DC 렌더링을 추가했다. native 요청/성공/실패/문자 수를 진단한다.
- 첫 native 편집 직후 `$env:CL='/WX'; flutter build windows --debug` 성공. 세 출력 경로 연결 후 Dart diagnostics 0건.
- `label_sheet_print_job_test.dart`: 일반 텍스트만 native 승인하고 inline/회전/세로/overflow 및 강제 줄간격은 fallback으로 유지하는 테스트를 추가했다. focused 2건 통과.
- 출력 관련 테스트 58건 통과: FortuneSheet hybrid plan, print job, dispatcher, pipeline, session.
- analyzer 결과 변경 코드 경고 0건. 기존 FortuneSheet canvas 미사용 코드 경고 10건만 남았다.
- justify 및 사용자 지정 Y-offset은 DrawTextW와 FortuneSheet 렌더 결과가 달라 native 승인에서 제외했다. focused Windows hybrid 테스트 2건 재통과.
- native 진단에 요청 문자 수, 폰트 높이 min/max, 실제 font family 목록을 추가했다. `$env:CL='/WX'; flutter build windows --debug` 성공.
- 버전을 `1.0.38`로 증가했다.
- 버전 및 최종 fallback 조건 반영 후 출력 관련 테스트 58건 재통과.
- v1.0.38 `$env:CL='/WX'; flutter build windows --debug` 최종 성공.
- Debug EXE FileVersion/ProductVersion과 `.tmp/log/app_2026-08-02_23-06-58.log` logger 헤더가 모두 `1.0.38`임을 확인했다. 검증용 PID 20256은 종료했다.
- 세로 용지 방향은 RECT만 회전되고 GDI 글꼴은 회전되지 않으므로 native 승인에서 제외해 bitmap fallback으로 유지한다. Windows hybrid focused 테스트 3건 통과.
- native 폰트 생성/DrawText 실패가 한 건이라도 있으면 누락된 라벨을 성공 처리하지 않고 method channel 오류로 전달한다. 변경 후 `/WX` Windows Debug 빌드 성공.
- stage/commit 대상: FortuneSheet plan/canvas/test, 출력 Dart 4개, Windows channel, print job 테스트, `pubspec.yaml`, `SESSION_HANDOFF.md`. 사용자 변경 `lib/core/app.dart` 제외.
- 최종 출력 관련 테스트 59건 통과. `/WX` Windows Debug 빌드 성공, 실행 버전 `1.0.38` 확인 완료.
- `git diff --check` 통과. 관련 11개 파일만 stage했고 사용자 변경 `lib/core/app.dart`는 제외했다.
- 기능 커밋: `872128e Godex GDI 텍스트 혼합 출력 적용`.
- 완료·실물 검증 대기: 실제 G500 출력 후 로그에서 `nativeTextRequested`, `nativeTextDrawn`, `nativeTextFailed=0`, `nativeTextCharacters`, `nativeTextHeight`, `nativeTextFonts`를 확인한다.

# 최근 완료 요약

## Windows 앱 종료 대기 제한 제거 v1.0.24
- 창 종료 전체를 감싸던 5초 timeout을 제거해 사용자 확인과 정상 로그아웃/DB disconnect 완료 후 종료하도록 수정했다.
- `test/lifecycle_test.dart` 3건과 Windows Debug 빌드가 통과했다.
- 실제 `WM_CLOSE` 검증에서 6초 이상 사용자 응답을 기다린 뒤 취소 복귀 및 승인 후 프로세스 종료를 확인했다.
- 기능 커밋: `05f239f Windows 앱 종료 대기 제한 제거`.

## 주원료 키워드 공백 조정 제외 v1.0.23
- 일반 끝부분 키워드의 overflow 공백 조정에서 `#ELEMENT` 셀을 제외해 원본 앞 공백을 보존한다.
- 라벨 시트 182건, 영양성분 플로팅 11건이 통과했다.
- 기능 커밋: `156ac0d 주원료 키워드 공백 조정 제외`.

## 플로팅창 닫기 상태 완전 복원 v1.0.22
- portal 플로팅창의 child element와 창 `Rect`를 닫기/다시보기 사이 유지해 내부 탭, 스크롤, 편집 상태와 위치/크기를 복원한다.
- 라벨 시트 181건, 영양성분 플로팅 11건이 통과했다.
- 기능 커밋: `439e115 플로팅 닫기 상태 완전 복원`.

## 플로팅 미리보기 선택 상태 유지 v1.0.21
- portal hide 경로가 subtree를 폐기하지 않고 `Offstage`로 유지하도록 공용 플로팅창 동작을 수정했다.
- 기능 커밋: `c7ce461 플로팅 미리보기 선택 상태 유지`.

# 남은 이슈와 다음 액션
- 현재 알려진 미완료 작업이나 blocker는 없다.
- 후속 사용자 요청이 들어오면 해당 기능의 owning abstraction과 인접 테스트부터 확인한다.
- 과거 세부 구현과 검증 이력은 Git history 및 관련 커밋 메시지에서 확인한다.

# 범위 밖 변경 및 주의사항
- 사용자 변경 `lib/core/app.dart`는 유지하며 stage/commit에서 제외한다.
- 품목 출력 진단 토글 `itemOutputPreviewMappingDebugEnabled`, `itemElementLayoutDebugEnabled`는 커밋 `0344722`에서 모두 `false`로 복구됐다.
- 원격 push와 Windows/installer 배포 파일 생성은 명시 요청 전까지 수행하지 않는다.
