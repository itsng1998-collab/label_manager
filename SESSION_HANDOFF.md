# 세션 핸드오프

## 최우선 순서 (2026-09-11)
1. [SESSION_RULES.md](SESSION_RULES.md)를 읽고 **앱 오동작 디버깅을 먼저 진행**한다. 이번 요청은 문서 정리이며 앱 수정/재현은 아직 시작하지 않았다.
2. 구체적인 오동작 증상, 재현 순서, 기대/실제 결과, 발생 시각과 로그 또는 사진을 사용자에게 확인한다. 이전 역상 작업을 자동으로 계속하지 않는다.
3. 오동작 수정과 focused 검증/관련 커밋을 마친 뒤 사용자 우선순위를 확인하고 [doc/godex_inverse_resume.md](doc/godex_inverse_resume.md)에서 역상 문제를 재개한다. 두 문제의 가설과 변경을 섞지 않는다.

## 현재 실행 및 작업 트리
- 마지막 검증 앱은 **v1.3.112 일반 모드**. 빌드/hot reload 시점에는 runtime 오류가 없었으나 이후 터미널이 비정상 종료됐다는 알림을 받았다. 종료 원인은 미확정이며 앱 충돌/RTF 수정의 회귀로 단정하지 않는다.
- 종료된 run ID `62f68d45-1c1d-4bbb-b7b8-33d7a4d4dfb7`와 과거 DTD/VM 주소는 재사용하지 않는다. 2026-09-11 조회에서 `label_manager` 프로세스가 없었다. 새 세션에서는 다시 확인한다.
- 현재 확인된 최신 로그: [.tmp/log/app_2026-09-09_23-48-43.log](.tmp/log/app_2026-09-09_23-48-43.log). 마지막 수정 시각은 9월9일23:49:19. 다음 세션에서 최신 `app_*.log`를 다시 선택하고 시작 버전을 확인한다.
- 전달된 종료 알림에는 품목 세션 `renderReady/completed` 및 hot reload 성공까지 있다. 종료 예외/스택/종료 원인은 제시되지 않았다. `sqflite default factory` 경고만으로 원인 판정 금지.
- 범위 밖 기존 변경: [lib/core/app.dart](lib/core/app.dart), [pubspec.lock](pubspec.lock). 원복하거나 함께 stage/commit하지 않는다. 오동작과 관련되면 먼저 diff를 읽고 사용자 변경을 보존하면서 조사한다.
- 이번 문서 정리에 따른 버전은 PATCH **1.3.112 -> 1.3.113**. 앱 코드/의존성 변경이나 빌드는 하지 않으므로 마지막 검증 EXE는1.3.112, native 인쇄 마크는1.3.107이다.

## 앱 오동작 시작점
- 사용자가 지정한 로그/화면을 최우선으로 한다. 현재 증상이 아직 없으므로 과거 문제를 새 오동작이라고 가정하지 않는다.
- 가장 최근 생산 수정은 `02864cf`의 RTF 글자 크기 단위 변환이다. [lib/features/label_sheet/application/label_sheet_rtf_import.dart](lib/features/label_sheet/application/label_sheet_rtf_import.dart)의 셀/raw/인라인/native HTML 크기에96/72 변환을 적용했다. 새 RTF 가져오기에는 일반 글자도 포함된다. 기존 저장 시트나 출력 엔진 자체를 일괄 확대하지는 않는다.
- 새 RTF 로딩/품목 미리보기에서 크기·줄바꿈·잘림 문제가 재현되면 위 경로와 [lib/home_page_manager.dart](lib/home_page_manager.dart)의 호출부터 확인한다. 그 외 증상이면 해당 기능의 제어 지점에서 시작한다. 단위 수정과 실물 역상 문제의 인과관계는 아직 미확정이다.
- 이전 `503fa16`은 품목 단일 셀 미리보기만 native RTF 변환 대신 Dart parser를 사용해 UI 스레드 멈춤을 피한 수정이다. 일반 라벨의 native 가져오기는 유지했다. 이 차이를 모르고 미리보기에 동기 native 호출을 다시 연결하지 않는다.
- 인쇄가 필요 없는 재현에는 인쇄 버튼/자동 출력/데이터 재저장을 실행하지 않는다. 앱 실행 자체에는 기존 시작/로그인 DB 처리 등이 있을 수 있으며, 이를 'DB 접근 없음'으로 표현하지 않는다.

## 최근 완료 및 남은 확인
- **RTF 단위 수정 `02864cf` / 기록 `f1a1763`**: 새5/6/8pt 가져오기에서 Windows14/17/23dot 보존, 코덱 저장/재로드 보존, 기존 시트8pixel 일반/역상17dot 유지. 가져오기 관련203건/인쇄27건 통과(일부 중복), 관련3개 파일 analyze 및 Debug `/WX` 빌드/hot reload 통과. 실물 개선은 미검증.
- **레거시 글리프 비교 `eb2a01f`**: 동일 twip의 RTF/평문 재구성 글리프는 차이0. 크기 단위 차이를 무출력 native probe로 재현, CTest2/2 통과. 현재 실패17dot의 원본이8pt라는 증거는 아니다.
- 과거 사용자 확인 대기 유지: 품목값 편집 후 가로 스크롤(`6bccfd5`), BMP 미리보기(`logo.bmp` 실파일), 품목 순서 변경 후 로딩. 각각 구현/focused 검증은 완료됐으나 실제 환경 확인이 남았다. 새 증상과 관련될 때만 확인하며 과거 버전 실행을 요구하지 않는다.
- 완료된 공지/로그인/품목 편집 등의 상세 작업 로그는 Git 이력으로 넘긴다. 계정 전환/방향키는 `503fa16`, 편집 가능 기본값은 `9e1db2a`, 로그인/종료 속도는 `13396fa`를 기준으로 조회할 수 있다.

## 역상 복귀 시 요약
- **실물 품질 미해결**. 같은 환경의 레거시 정상 사진이 있으므로 USBPcap 설치 요청은 철회했다. 사용자 추가 설치나 같은 코드의 반복 출력을 요구하지 않는다.
- 마지막 실패 사진은 `.tmp/IMG_20260909_0003.png`(앱1.3.108/native1.3.107). 실제 앱1.3.109의 PRN에서는 두 역상 흰 손실0. 원본 생성의 적절성/USB 데이터 동일성/종이 품질을 모두 입증한 것은 아니다.
- 다음 판별은 실패 라벨의 실제 저장 형식과 원래 글자 크기다. 대상은 마지막 재현 기준 brand1526/labelSize8114/item722292. `RICH_FORM_SHEET` 및 `RICH_ELEMENT_SHEET` 우선 조회라 최종 alias만으로 원본 RTF 출처를 알 수 없다.
- 원본 RTF와 저장 시트를 읽기 전용으로 비교하기 전에는 기존 시트를4/3 확대하거나 RTF에서 강제 재생성/재저장하지 않는다. 사용자 편집 손실 가능성이 있다.
- 일반 출력/표선은 v1.3.58 기준, native 인쇄 경로는1.3.107 유지. 실패 실험·증거·파일 모드 한계는 재개 문서에 모아 둔다.
- 9월11일 자료 점검: 정상/실패 사진과 레거시 소스는 존재한다. 과거23:10/23:21 앱 로그, 실제 앱 PRN/PNG와 대응 inverse/after-native TXT, RTF analyze/build 로그, probe build 캐시는 현재 없다. 이전 검증 결과는 커밋/문서 기록으로만 보존하며 재검증 완료라고 표현하지 않는다. 앱 오동작은 남아 있는 최신 로그와 새 재현부터 조사할 수 있다.

## 검증 명령
오동작의 관련 테스트만 먼저 실행한다. 아래는 RTF 수정에 직접 관련된 재검증 명령이며 문서 정리에서는 실행하지 않았다.

```powershell
C:/Flutter/bin/flutter.bat test test/godex_inverse_reference_test.dart test/label_sheet_toolbar_test.dart
C:/Flutter/bin/flutter.bat test test/label_sheet_print_job_test.dart test/label_print_dispatcher_test.dart
C:/Flutter/bin/flutter.bat analyze lib/features/label_sheet/application/label_sheet_rtf_import.dart test/godex_inverse_reference_test.dart test/label_sheet_toolbar_test.dart
```

- 일반 앱 실행 시 `LABEL_MANAGER_DEBUG_PRINT_FILE`이 설정되지 않았는지 확인한다. Debug 파일 모드는 성공해도 `ok=false`를 반환해 인쇄 이력/자동증가를 막는 진단 기능이다. 앱 오동작 실패와 혼동하지 않는다.
- Dart 수정 뒤 DTD를 새로 발견/연결해 hot reload 또는 restart한다. native 변경은 재빌드/재실행해야 한다. Windows 배포/설치파일/원격 push/DB migration/프린터 설정 변경은 명시 요청 없이 하지 않는다.
- `.tmp` 자료와 캐시는 가능한 재개 증거로 보존하고 stage/외부 전송하지 않는다. 없는 자료는 없다고 기록하고 과거 결과를 새로 검증했다고 말하지 않는다.

## 이번 정리 진행
- 문서 편집 완료: 앱 오동작 우선, 종료된 실행 상태, 기존 dirty2개, RTF 수정의 적용 범위와 역상 복귀 지점으로 핸드오프를 재구성했다. 역상 재개 문서는 핵심 증거/실패 이력/명령 중심으로 축약했다.
- 검증 완료: `git diff --check`, 두 문서의 상대 링크 존재 확인, 문서/pubspec diagnostics 통과. 핵심 증거의 존재/누락을 위에 반영했다. 문서2개와 pubspec만 stage/commit한다. 앱 실행/테스트/빌드/실물 인쇄는 하지 않았으며 로컬 자료 삭제도 하지 않았다.
- 정리 커밋 완료: `abac7ab` (`앱 오동작 우선 세션 전환과 역상 재개 문서 정리`). 관련3개 파일만 포함했다. 후속 해시 기록은 같은 요청의 문서 기록으로 버전을 다시 올리지 않는다. 다음 세션은 앱 오동작의 구체 증상 확인부터 시작한다.