# 현재 작업 상태

## 새 세션 우선순위 (2026-09-09)
1. **구현·자동 검증 완료: 품목관리 BMP 선택 후 미리보기 미적용 수정.** 공용 로더가 기존 `C:\ITS\LabelManager\bmp files`를 우선하고 재현 위치 `C:\ITS\BCSManager\bmpfiles`를 fallback으로 탐색한다. 최신 v1.3.99 실행본에서 실제 `logo.bmp` 확인이 필요하다.
2. 품목 순서 변경 후 무한 로딩은 현재 코드에서 수정 및 focused 검증 완료 상태다. 제출 로그는 v1.3.58이며, 현재 브랜치에는 `3bac0a32`가 포함되어 있다. 최신 v1.3.98 실행본에서 같은 재현 절차로 사용자 확인이 필요하다.
3. 앱 오동작 확인 후 **역상 출력 문제를 재개한다.** [doc/godex_inverse_resume.md](doc/godex_inverse_resume.md)에 구현 경로, 마지막 실물/로그, 실패 이력, 새 진단의 한계와 검증 명령을 정리했다.

## 보존할 상태
- 마지막 인쇄 구현: **v1.3.97 / d0ade63**, 기록 커밋: **a0f3a1e**. v1.3.97은 후속 검정 글자 합성 진단 추가이며 획 소실 해결 버전이 아니다.
- 마지막 분석 실물: [.tmp/IMG_20260908_0005.png](.tmp/IMG_20260908_0005.png), v1.3.96에서 역상 흰 획 소실 지속. 전체 문자 수용/1bpp 렌더 성공만으로 실물 품질 정상 판정 금지.
- 미검증: v1.3.97 이후 실제 출력의 `*_after_native` 생성 결과/역상별 `whitePixelsLost`. 새 세션에서는 기존 자료 이후의 사진/로그가 있는지 먼저 확인한다.
- 마지막 실행 확인: Debug EXE v1.3.97, 당시 PID8452 응답 정상. [.tmp/log/app_2026-09-08_23-25-53.log](.tmp/log/app_2026-09-08_23-25-53.log)에서 버전 및 DB 연결 성공. 현재 실행 여부는 새로 확인한다.
- 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 보존한다. 앱 오동작과 관련되면 현재 diff를 읽고 함께 작업하되 임의 원복/전체 stage 금지.
- 일반 글자/표선은 v1.3.58 기준 유지. 실물 획 소실을 열 번짐/드라이버 문제로 확정하거나 소프트웨어 개선 불가로 결론내리지 않는다.
- 사진/로그/EMF/BMP/probe 캐시는 `.tmp`에 로컬 보존, stage/외부 전송 제외. DB migration/프린터 설정/배포/원격 push 변경 금지.

## 이번 핸드오프 정리
- BMP 미리보기 원인: [.tmp/test_log/이미지를 불러오지 못하는 현상.log](.tmp/test_log/이미지를%20불러오지%20못하는%20현상.log) v1.3.58에서 선택한 `logo` 파일명은 저장됐지만, 미리보기는 LabelManager 고정 폴더만 조회해 BCSManager의 파일을 찾지 못했다.
- 레거시 재확인: [.tmp/LabelManager/LabelManager/LabelEditDlg.cpp](.tmp/LabelManager/LabelManager/LabelEditDlg.cpp)는 파일 선택 시작 위치를 `C:\ITS\LabelManager\bmp files`로 지정하고 확장자 없는 파일명만 저장한다. [.tmp/LabelManager/LabelManagerLib/RichEditImageMaker.cpp](.tmp/LabelManager/LabelManagerLib/RichEditImageMaker.cpp)는 실행 파일 옆 `bmp files`에서만 다시 읽으며 외부 선택 파일을 복사하지 않는다. 현재 수정은 이 저장 계약과 기존 경로 우선순위를 유지하고 BCSManager 공유 폴더만 호환 경로로 추가한다.
- 편집 완료: [lib/features/item/application/item_image_preview.dart](lib/features/item/application/item_image_preview.dart)에 `itemBmpPreviewDataUriForFileName`과 두 기본 탐색 폴더를 추가했다. 기존 LabelManager 폴더 우선순위를 유지하고 BCSManager `bmpfiles`를 fallback으로 사용한다.
- 편집 완료: [lib/home_page_manager.dart](lib/home_page_manager.dart)의 `_itemImageDataUri`가 공용 BMP 파일명 로더를 사용한다. DB에는 기존처럼 확장자를 제외한 파일명만 저장한다.
- 테스트 추가: [test/item_image_preview_test.dart](test/item_image_preview_test.dart)에 실제 경로 상수, BCSManager fallback, 동일 파일명일 때 LabelManager 우선 계약을 추가했다.
- 검증 완료: `flutter test test/item_image_preview_test.dart test/home_page_manager_session_test.dart test/item_order_dialog_test.dart` 13건 통과. `flutter analyze lib/features/item/application/item_image_preview.dart lib/home_page_manager.dart test/item_image_preview_test.dart` 이슈 없음. `git diff --check` 통과.
- 실행 검증 제한: DTD 연결은 성공했지만 실행 중인 Flutter 앱이 없어 hot restart는 수행하지 못했다. 개발 PC에도 두 기본 폴더의 `logo.bmp`가 없어 실파일 미리보기는 최신 v1.3.99 실행본에서 사용자 확인이 필요하다.
- 버전: 호환 저장 포맷을 유지하는 국소 미리보기 버그 수정이므로 [pubspec.yaml](pubspec.yaml) PATCH **1.3.98 -> 1.3.99**.
- stage/commit 대상: [lib/features/item/application/item_image_preview.dart](lib/features/item/application/item_image_preview.dart), [lib/home_page_manager.dart](lib/home_page_manager.dart), [test/item_image_preview_test.dart](test/item_image_preview_test.dart), [pubspec.yaml](pubspec.yaml), 이 문서. 기존 사용자 변경 [lib/core/app.dart](lib/core/app.dart)는 제외한다.
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