# 현재 작업 상태

## 새 세션 우선순위 (2026-09-09)
1. **완료: 김영모 계정 접속 멈춤 및 품목관리 좌우 방향키 수정.** 지정 v1.3.58 로그에서 `75806065` 전환 후 브랜드·라벨크기·품목 세션은 `renderReady`와 `completed`까지 끝났고 마지막 로그가 품목 미리보기의 native RTF 변환 시작에서 멈췄다. 품목 단일 셀 미리보기만 Dart RTF 파서를 사용해 Windows UI 스레드의 동기 native 변환 정지를 피하고, 하단 가로 이동 버튼에 포커스가 있으면 좌우 방향키가 동일 스크롤 callback을 실행하도록 구현했다. 관련 전체 테스트 273건과 analyzer/diff 검증을 통과했다.
2. **완료: 품목관리 추가 열의 `클라이언트 편집 불가` 기본값 수정.** 기존 품목에 `BM_RICH_COL_CONTENT` 레코드가 없는 추가 열은 저장 draft에서 편집 가능을 기본값으로 사용하지만 화면의 `_dynamicCellEditable`만 false를 사용해 자동 잠금됐다. 미설정 기본값을 true로 통일하고 명시적 false는 유지하도록 수정했다.
2. **완료: 업데이트 메시지 대상 사용자 검색 기능.** 우측 대상 목록에 거래처·지점 필터와 계정 ID 다음 검색을 추가했다. 검색 결과는 강조되며 화면 밖 사용자도 목록 중앙으로 자동 스크롤한다. 필터를 변경해도 기존 체크 선택은 유지된다.
3. **완료: 관리자가 선택한 사용자의 업데이트 메시지 미표시 수정.** v1.3.58 설정 로그에서 `TESTER1` 대상 UPDATE와 커밋은 성공했지만 영향 행 수가 확인되지 않았고, 로그인 화면에는 공지 영역만 열린 채 본문이 비었다. 레거시는 로그인 시 없는 `BM_UPDATE_NOTICE` 사용자 행을 생성하지만 Flutter에는 이 보장이 없었다. 선택 사용자 저장을 정규화 ID UPDATE 후 영향 행이 없으면 사용자 소속 협력업체와 함께 INSERT하도록 수정했다.
3. **완료: 로그인 공지의 `다음 업데이트까지 이 창 보지 않음` 복원 수정.** v1.3.58 재현 로그와 레거시를 대조한 결과 Flutter는 공지 조회 전 빈 내용 hash로 로컬 suppression을 판정하고 DB `UN_STATE`를 버려 재실행 시 공지가 다시 표시됐다. 로그인 조회 결과에 `Notice.state`를 전달하고 확인 시 기존 `NoticeDAO.updateUserState`로 상태를 저장하도록 수정했다.
4. **완료: 로그인·로그아웃·프로그램 종료 체감 속도 개선.** 로그인/초기 브랜드 로딩을 `SnackBar.onVisible`까지 미루지 않고 즉시 시작하도록 변경하고 Windows 종료의 고정 120ms 대기를 제거했다. v1.3.101 실행 로그에서 인증 종료→초기 로딩 시작은 약 681ms에서 376ms, 종료 승인→후속 닫기는 약 122ms에서 1ms로 감소했다.
5. **구현·focused 검증 완료: 품목값 편집 후 가로 스크롤 소실 수정.** 품목관리에서 revision 재계산 시 기존 자동 너비를 보존하여 편집 확정 후 overflow와 가로 스크롤이 사라지지 않게 했다. 최신 v1.3.100 실행본에서 사용자 재현 확인이 필요하다.
6. 품목관리 BMP 미리보기 수정은 구현·자동 검증 완료 상태다. 최신 v1.3.99 실행본에서 실제 `logo.bmp` 확인이 필요하다.
7. 품목 순서 변경 후 무한 로딩은 현재 코드에서 수정 및 focused 검증 완료 상태다. 앱 오동작 확인 후 [doc/godex_inverse_resume.md](doc/godex_inverse_resume.md)를 기준으로 역상 출력 문제를 재개한다.

## 보존할 상태
- 마지막 인쇄 구현: **v1.3.97 / d0ade63**, 기록 커밋: **a0f3a1e**. v1.3.97은 후속 검정 글자 합성 진단 추가이며 획 소실 해결 버전이 아니다.
- 마지막 분석 실물: [.tmp/IMG_20260908_0005.png](.tmp/IMG_20260908_0005.png), v1.3.96에서 역상 흰 획 소실 지속. 전체 문자 수용/1bpp 렌더 성공만으로 실물 품질 정상 판정 금지.
- 미검증: v1.3.97 이후 실제 출력의 `*_after_native` 생성 결과/역상별 `whitePixelsLost`. 새 세션에서는 기존 자료 이후의 사진/로그가 있는지 먼저 확인한다.
- 마지막 실행 확인: Debug EXE v1.3.97, 당시 PID8452 응답 정상. [.tmp/log/app_2026-09-08_23-25-53.log](.tmp/log/app_2026-09-08_23-25-53.log)에서 버전 및 DB 연결 성공. 현재 실행 여부는 새로 확인한다.
- 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 보존한다. 앱 오동작과 관련되면 현재 diff를 읽고 함께 작업하되 임의 원복/전체 stage 금지.
- 일반 글자/표선은 v1.3.58 기준 유지. 실물 획 소실을 열 번짐/드라이버 문제로 확정하거나 소프트웨어 개선 불가로 결론내리지 않는다.
- 사진/로그/EMF/BMP/probe 캐시는 `.tmp`에 로컬 보존, stage/외부 전송 제외. DB migration/프린터 설정/배포/원격 push 변경 금지.

## 이번 핸드오프 정리
- 계정 전환 멈춤 원인/수정: [.tmp/test_log/사용자관리 - 김영모 계정 접속시 프로그램 멈춤현상.log](.tmp/test_log/사용자관리%20-%20김영모%20계정%20접속시%20프로그램%20멈춤현상.log)의 마지막 미완료 작업은 `labelSheetDraftFromRichEditRtfAsync` native 변환이다. [lib/features/label_sheet/application/label_sheet_rtf_import.dart](lib/features/label_sheet/application/label_sheet_rtf_import.dart)에 native 우선 여부를 추가하고 [lib/home_page_manager.dart](lib/home_page_manager.dart)의 품목 단일 셀 미리보기만 기존 Dart parser를 선택했다. 일반 라벨 RTF 가져오기의 native 정밀 변환은 유지한다.
- 품목 좌우 방향키 구현: [lib/features/item/presentation/item_manage.dart](lib/features/item/presentation/item_manage.dart)의 하단 좌우 버튼이 footer 전용 포커스를 획득하고, 해당 포커스에서 왼쪽/오른쪽 방향키가 버튼과 동일한 `FortuneTableScrollController` callback을 실행한다. 테이블 셀 편집·셀 이동 포커스에서는 가로채지 않는다.
- 테스트 추가/검증: [test/label_sheet_toolbar_test.dart](test/label_sheet_toolbar_test.dart)는 품목 RTF 변환이 native 채널을 호출하지 않음을 검증하고, [test/fortune_table_test.dart](test/fortune_table_test.dart)는 버튼 클릭 후 좌우 방향키 스크롤을 검증한다. `flutter test test/label_sheet_toolbar_test.dart test/fortune_table_test.dart` 273건 통과, 관련 파일 `flutter analyze` 이슈 없음, `git diff --check` 통과.
- 실행 검증 제한: VS Code DTD에 실행 중인 Flutter 앱이 없어 hot restart, 실제 `75806065` 계정 전환 및 품목관리 키 입력 확인은 수행하지 못했다.
- 버전: 계정 전환 멈춤 및 품목관리 방향키 수정으로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.105 -> 1.3.106**.
- 기능 커밋: `503fa164dc285153d9e66215b0a44e0454ebfcf2` (`계정 전환 멈춤 및 품목 방향키 수정`). 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 제외했다.
- 품목 추가 열 편집 기본값 구현: [lib/features/item/presentation/item_manage.dart](lib/features/item/presentation/item_manage.dart)의 `_dynamicCellEditable`은 기존 품목의 열 콘텐츠 레코드가 없으면 편집 가능을 기본값으로 사용한다. DB에 저장된 명시적 `editable=false`와 현재 draft 설정은 계속 우선한다. DB migration이나 저장 포맷 변경은 없다.
- 품목 추가 열 편집 테스트: [test/fortune_table_test.dart](test/fortune_table_test.dart)에 기존 품목·빈 `scopedColumnContents`에서 추가 열 편집 가능 및 잠금 툴팁 미표시 계약을 추가했다. 신규 테스트 1건과 기존 명시 잠금·해제 테스트 2건 통과.
- 최종 검증: `flutter test test/fortune_table_test.dart` 74건 통과. `flutter analyze lib/features/item/presentation/item_manage.dart test/fortune_table_test.dart` 이슈 없음. `git diff --check` 통과.
- 실행 검증 제한: VS Code DTD에 실행 중인 Flutter 앱이 없어 hot restart와 실제 아이티에스엔지/6*9 데이터 화면 확인은 수행하지 못했다.
- 버전: 품목 추가 열 편집 기본값 버그 수정으로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.104 -> 1.3.105**.
- 기능 커밋: `9e1db2ada78d59fced240fe1a5b04c0519304ae2` (`품목 추가 열 편집 기본값 수정`).
- 대상 사용자 검색 구현: [lib/features/update_notice/domain/notice.dart](lib/features/update_notice/domain/notice.dart)의 `NoticeTargetUser`에 거래처·지점 ID/이름을 추가하고 로컬 필터 및 대소문자 무시 계정 ID 순환 검색 함수를 제공한다.
- 대상 사용자 조회 구현: [lib/features/update_notice/data/notice_dao.dart](lib/features/update_notice/data/notice_dao.dart)의 기존 협력업체 단위 단일 쿼리가 거래처·지점 정보를 함께 반환하고 거래처명, 지점명, 계정 ID 순으로 정렬한다. 추가 조회나 DB migration은 없다.
- 대상 사용자 UI 구현: [lib/features/update_notice/presentation/update_notice_dialog.dart](lib/features/update_notice/presentation/update_notice_dialog.dart)의 우측 패널에 거래처·지점 필터, 계정 ID 검색, 선택 인원 표시를 추가했다. Enter 또는 검색 버튼은 현재 필터 결과에서 다음 일치 사용자를 강조하고 고정 행 높이 기반으로 중앙 자동 스크롤하며 저장 단축키와 충돌하지 않는다. 필터 밖 사용자 선택도 유지되어 함께 저장된다.
- 대상 사용자 검색 테스트: [test/notice_menu_dao_test.dart](test/notice_menu_dao_test.dart)에 모델/SQL 필드, 거래처·지점 필터, trim·대소문자 무시 검색, 필터 밖 선택 유지·저장, 화면 밖 결과 자동 스크롤 계약을 추가했다. 공지 메뉴 테스트 15건 통과.
- 최종 검증: `flutter test test/notice_menu_dao_test.dart test/startup_login_service_test.dart test/startup_dialog_test.dart` 28건 통과. 대상 Dart 파일 `flutter analyze` 이슈 없음. `git diff --check` 통과.
- 실행 검증 제한: VS Code DTD에 실행 중인 Flutter 앱이 없어 hot restart, 실제 화면 크기 및 실제 DB 목록 확인은 수행하지 못했다.
- 버전: 업데이트 메시지 대상 사용자 검색 기능 추가로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.103 -> 1.3.104**.
- 기능 커밋: `eab0f0536ed5597cec89702ac601ad1ba77ec4a9` (`업데이트 메시지 대상 사용자 검색 추가`).
- 선택 사용자 공지 저장 구현: [lib/features/update_notice/data/notice_dao.dart](lib/features/update_notice/data/notice_dao.dart)의 `updateSelectedUserSql`은 조회와 동일한 trim/문자열 변환으로 대상 ID를 갱신하고, `@@ROWCOUNT=0`이면 `BM_USER`, `BM_MARKET`, `BM_CUSTOMER`에서 소속 협력업체를 조회해 `BM_UPDATE_NOTICE` 행을 생성한다. DB migration이나 테이블 변경은 없다.
- 선택 사용자 공지 테스트: [test/notice_menu_dao_test.dart](test/notice_menu_dao_test.dart)에 기존 행 갱신뿐 아니라 미존재 선택 사용자 행 INSERT와 앱 버전 저장 계약을 추가했다. `flutter test test/notice_menu_dao_test.dart` 11건 통과.
- 최종 검증: `flutter test test/notice_menu_dao_test.dart test/startup_login_service_test.dart test/startup_dialog_test.dart` 24건 통과. 관련 6개 Dart 파일 `flutter analyze` 이슈 없음. `git diff --check` 통과.
- 실행 검증 제한: VS Code DTD에 실행 중인 Flutter 앱이 없어 hot restart와 실제 DB 대상 재현은 수행하지 못했다.
- 버전: 선택 사용자 공지 미표시 버그 수정으로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.102 -> 1.3.103**.
- 기능 커밋: `9b064c39100a566355a0729e3d62809aa453f8a4` (`선택 사용자 업데이트 메시지 저장 수정`).
- 공지 suppression 구현: [lib/features/login/application/startup_login_service.dart](lib/features/login/application/startup_login_service.dart)는 공지 문자열 대신 `Notice(message, state)` 전체를 반환하고 기존 `NoticeDAO.updateUserState` writer를 제공한다. [lib/features/login/presentation/startup_dialog.dart](lib/features/login/presentation/startup_dialog.dart)는 DB `UN_STATE=1`을 재실행 시 닫힘으로 복원하며, 체크 후 확인에서 저장 성공 후에만 닫고 늦은 조회 callback이 다시 열지 못하게 한다.
- 공지 suppression 테스트: [test/startup_login_service_test.dart](test/startup_login_service_test.dart)에 공지 상태 전달 계약을, [test/startup_dialog_test.dart](test/startup_dialog_test.dart)에 DB 상태 1 복원, 상태 0 새 공지 재표시, 확인 시 사용자별 suppression 저장, 저장 실패 시 공지 유지와 즉시 오류 표시 계약을 추가했다.
- 최종 검증: `flutter test test/startup_login_service_test.dart test/startup_dialog_test.dart` 13건 통과. `flutter analyze lib/features/login/application/startup_login_service.dart lib/features/login/presentation/startup_dialog.dart test/startup_login_service_test.dart test/startup_dialog_test.dart` 이슈 없음. `git diff --check` 통과.
- 실행 검증 제한: VS Code DTD에는 연결했지만 실행 중인 Flutter 앱이 없어 hot restart와 runtime 오류 확인은 수행하지 못했다.
- 버전: 공지 상태 유지 버그 수정으로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.101 -> 1.3.102**.
- 기능 커밋: `3e40eb1d22ce7ed1d428f7329213aab9e1425bdb` (`로그인 공지 숨김 상태 유지 수정`).
- 로그인·종료 속도 구현: [lib/features/login/presentation/startup_dialog.dart](lib/features/login/presentation/startup_dialog.dart)는 진행 스낵바 표시 직후 인증을 시작하고 실제 인증 종료 시 스낵바를 닫는다. [lib/home_page_manager.dart](lib/home_page_manager.dart)는 초기 브랜드/품목 로딩을 스낵바 `onVisible` 콜백까지 미루지 않는다. [lib/main.dart](lib/main.dart)는 lifecycle 정리가 끝난 뒤 추가하던 Windows 고정 120ms 대기를 제거했다.
- 로그아웃 판단: 최신 실행에서 메뉴 클릭부터 `_doLogout` 완료까지 약 101ms, 실제 `_doLogout`은 약 1ms였다. 일반 계정의 로그아웃 이력 저장 순서를 바꾸면 레거시 및 이력 완료 계약이 달라지므로 추가 변경하지 않았다.
- 테스트 추가/최종 검증: [test/startup_dialog_test.dart](test/startup_dialog_test.dart)에 progress snackbar 프레임 전 로그인 DAO 시작 계약, [test/home_page_manager_session_test.dart](test/home_page_manager_session_test.dart)에 progress 표시와 초기 로딩 즉시 시작 순서 계약을 추가했다. 관련 focused 테스트 20건 통과, analyzer 이슈 없음, diagnostics 없음, `git diff --check` 통과.
- 실행 검증: v1.3.101 Windows Debug 앱 실행 및 hot restart 성공, runtime 오류 없음. 인증 자체는 83ms, 품목 세션 로드는 2.91초로 DB/렌더 비용은 유지됐지만 불필요한 표시 대기 약 305ms가 제거됐다. 종료는 `Window close start`부터 후속 닫기까지 13ms, 승인 후 후속 닫기까지 1ms였다.
- 버전: 기존 기능과 저장 형식을 유지하는 속도 버그 수정이므로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.100 -> 1.3.101**.
- 기능 커밋: `13396fa5020077b8f21b8810608e3279fee14b64` (`로그인 및 프로그램 종료 속도 개선`).
- 가로 스크롤 원인 확인: 품목 셀 편집 확정 시 `ItemManagerDraftController.contentRevision`이 증가하고 FortuneTable의 `_syncAutoWidthsIfNeeded`가 모든 자동 열 너비를 새 값 기준으로 축소한다. 총 너비가 viewport 이하가 되면 `RawScrollbar.thumbVisibility`가 false로 바뀐다.
- 레거시 재확인: [.tmp/LabelManager/LabelManager/LabelEditDlg.cpp](.tmp/LabelManager/LabelManager/LabelEditDlg.cpp)는 초기 전체 열 자동 맞춤 후 편집한 해당 열만 다시 계산한다. 현재 구현은 revision마다 모든 열을 축소하던 차이가 있었다. 공용 FortuneTable 기본값은 유지하고 품목관리에서만 revision 이후 기존 자동 너비 보존 옵션을 사용한다.
- 편집 완료: [third_party/fortune_sheet/lib/src/fortune_table.dart](third_party/fortune_sheet/lib/src/fortune_table.dart)에 `preserveAutoFitWidthsOnRevision` 옵션을 추가했다. 최초 자동 맞춤과 다른 화면의 기본 동작은 유지하며, 옵션 사용 시 같은 테이블 세션의 revision 갱신은 열을 축소하지 않고 필요한 확장만 허용한다.
- 편집 완료: [lib/features/item/presentation/item_manage.dart](lib/features/item/presentation/item_manage.dart)가 품목 테이블에서 자동 너비 보존 옵션을 활성화한다.
- 테스트 추가/검증: [test/fortune_table_test.dart](test/fortune_table_test.dart)에 revision 후 열 너비와 실제 가로 scrollbar thumb 유지, ItemManage 옵션 전달 계약을 추가했다. `flutter test test/fortune_table_test.dart` 73건 통과. 관련 3개 Dart 파일 analyzer 이슈 없음. `git diff --check` 통과.
- 실행 확인: DTD에 연결된 Flutter 앱이 없어 hot restart는 수행하지 못했다.
- 버전: 국소 UI 동작 수정이므로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.99 -> 1.3.100**.
- 기능 커밋: `6bccfd54ca54f244687340f9c64db4955def4c78` (`품목 편집 후 가로 스크롤 유지`).
- BMP 미리보기 원인: [.tmp/test_log/이미지를 불러오지 못하는 현상.log](.tmp/test_log/이미지를%20불러오지%20못하는%20현상.log) v1.3.58에서 선택한 `logo` 파일명은 저장됐지만, 미리보기는 LabelManager 고정 폴더만 조회해 BCSManager의 파일을 찾지 못했다.
- 레거시 재확인: [.tmp/LabelManager/LabelManager/LabelEditDlg.cpp](.tmp/LabelManager/LabelManager/LabelEditDlg.cpp)는 파일 선택 시작 위치를 `C:\ITS\LabelManager\bmp files`로 지정하고 확장자 없는 파일명만 저장한다. [.tmp/LabelManager/LabelManagerLib/RichEditImageMaker.cpp](.tmp/LabelManager/LabelManagerLib/RichEditImageMaker.cpp)는 실행 파일 옆 `bmp files`에서만 다시 읽으며 외부 선택 파일을 복사하지 않는다. 현재 수정은 이 저장 계약과 기존 경로 우선순위를 유지하고 BCSManager 공유 폴더만 호환 경로로 추가한다.
- 편집 완료: [lib/features/item/application/item_image_preview.dart](lib/features/item/application/item_image_preview.dart)에 `itemBmpPreviewDataUriForFileName`과 두 기본 탐색 폴더를 추가했다. 기존 LabelManager 폴더 우선순위를 유지하고 BCSManager `bmpfiles`를 fallback으로 사용한다.
- 편집 완료: [lib/home_page_manager.dart](lib/home_page_manager.dart)의 `_itemImageDataUri`가 공용 BMP 파일명 로더를 사용한다. DB에는 기존처럼 확장자를 제외한 파일명만 저장한다.
- 테스트 추가: [test/item_image_preview_test.dart](test/item_image_preview_test.dart)에 실제 경로 상수, BCSManager fallback, 동일 파일명일 때 LabelManager 우선 계약을 추가했다.
- 검증 완료: `flutter test test/item_image_preview_test.dart test/home_page_manager_session_test.dart test/item_order_dialog_test.dart` 13건 통과. `flutter analyze lib/features/item/application/item_image_preview.dart lib/home_page_manager.dart test/item_image_preview_test.dart` 이슈 없음. `git diff --check` 통과.
- 실행 검증 제한: DTD 연결은 성공했지만 실행 중인 Flutter 앱이 없어 hot restart는 수행하지 못했다. 개발 PC에도 두 기본 폴더의 `logo.bmp`가 없어 실파일 미리보기는 최신 v1.3.99 실행본에서 사용자 확인이 필요하다.
- 버전: 호환 저장 포맷을 유지하는 국소 미리보기 버그 수정이므로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.98 -> 1.3.99**.
- stage/commit 대상: [lib/features/item/application/item_image_preview.dart](lib/features/item/application/item_image_preview.dart), [lib/home_page_manager.dart](lib/home_page_manager.dart), [test/item_image_preview_test.dart](test/item_image_preview_test.dart), [pubspec.yaml](pubspec.yaml), 이 문서. 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 제외한다.
- 기능 커밋: `7c0908b` (품목 BMP 미리보기 경로 호환 수정). 이 해시 기록 후속 문서 커밋에서는 버전을 추가 증가하지 않는다.
- 품목 순서 변경 무한 로딩 분석: [.tmp/test_log/품목순서변경 후 무한로딩.log](.tmp/test_log/품목순서변경%20후%20무한로딩.log)는 v1.3.58 재현이며 DB 순서 갱신과 목록 강제 재조회까지 성공했다. 현재 코드는 강제 재조회에서 품목 위젯 렌더 완료를 기다리지 않아 순환 대기를 차단한다.
- 현재 수정 확인: `3bac0a32`에서 `itemManagerSessionLoadWaitsForRenderReady(isReload: true) == false` 계약과 회귀 테스트가 추가됐다. 새 production 코드 변경은 하지 않았다.
- 검증 완료: `flutter test test/home_page_manager_session_test.dart test/item_order_dialog_test.dart` 8건 통과. 최신 v1.3.98 실제 실행 재현은 사용자 확인 대기다.
- 분석·검증 기록 커밋: `e9d5587` (품목 순서 무한 로딩 수정 상태 확인). 이 해시 기록 후속 커밋에서는 버전을 추가 증가하지 않는다.
- 목적: 새 세션의 앱 오동작 우선 처리와 역상 문제 재개를 분리한다. 앱/인쇄 동작 코드는 변경하지 않았다.
- 편집 완료: 재개 문서 작성, 메인 핸드오프를 현재 상태로 축약. 오래된 상세 완료 기록은 `a0f3a1e` 이전 Git 이력에서 조회한다. 과거 '실물 검증 대기/예정'은 현재 할 일로 취급하지 않는다.
- 저장소 문서 변경 버전 규칙에 따라 [pubspec.yaml](pubspec.yaml) PATCH **1.3.97 -> 1.3.98**. 새 앱 빌드/실행 없음. **마지막 확인한 EXE와 native 인쇄 마크는 v1.3.97**이며 1.3.98은 인쇄 수정 버전이 아니다.
- 검증 완료: 문서 로컬 링크/필수 자료 존재, pubspec1.3.98 확인, `git diff --check` 통과. 메인 핸드오프 축약 후 링크와 diff 검사도 재통과. 문서/버전만 변경하므로 앱 테스트·빌드·실물 출력은 실행하지 않았다.
- stage/commit 대상: 이 문서, [doc/godex_inverse_resume.md](doc/godex_inverse_resume.md), [pubspec.yaml](pubspec.yaml) 세 파일. 기존 사용자 변경 제외. 임시 자료 삭제 없음.
- 이전 구현 검증: native CTest1/1, Dart31건, `/WX` Debug 빌드 통과. 이 결과는 이전 구현 기준이며 실물 획 소실 해결을 의미하지 않는다.
- 정리 커밋: `45c1088` (앱 오동작 우선 처리와 역상 출력 재개 핸드오프 정리). 문서/버전 편집기 오류 없음. 이 해시 기록 후속 커밋에서는 버전을 추가 증가하지 않는다.

## 상시 규칙
- 작업 규칙은 [SESSION_RULES.md](SESSION_RULES.md)를 따른다.
- 다음 세션에서도 의미 있는 수정/검증/블로커/커밋 단계마다 이 문서를 갱신한다. 분석·질문 답변만 한 경우에는 갱신하지 않는다.