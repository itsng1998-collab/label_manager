# 세션 인수인계

마지막 업데이트: 2026-07-03

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
- 라벨 시트 저장 포맷을 수정할 때는 `lib/page_label_sheet/label_sheet_save_codec.dart`의 `_labelSheetSaveFeatureKeys`에 항목별 feature key를 추가/정렬해 `labelSheetSaveFormatVersion`과 `labelSheetSaveFeatureVersions`가 자동 산출되도록 유지한다. 새로 지원하는 workbook/sheet/config/cell/cellType/inlineRun JSON 필드는 같은 파일의 allow-list 및 `labelSheetSanitizeWorkbookSaveJson` 경로에 반드시 반영하고, 상위 버전 payload가 지원 필드만 best-effort 로드하고 unknown 필드는 재저장 시 버려지는 테스트를 갱신한다.
- Godex G500 같은 라벨 프린터에서 정밀한 인쇄가 핵심이면 일반 프린터 경로와 직접 출력 경로를 분리한다. 직접 출력은 처음부터 모든 스타일을 100% EZPL 명령만으로 처리하기보다 `정밀 좌표 엔진 + EZPL 명령 + 셀 bitmap fallback` 구조를 우선한다. 테두리/선/박스와 바코드는 가능한 한 EZPL 명령으로 출력하고, 화면 폰트와 프린터 폰트 차이로 1:1 보장이 어려운 복합 스타일 텍스트/이미지/배경/RTF 계열 셀은 셀 단위 bitmap fallback을 사용해 시각적 일치도를 확보한다.

## 현재 상태

### 최근 완료 (2026-07-03)

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
