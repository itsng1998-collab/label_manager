# label_manager

Flutter 기반 레이블 관리 도구입니다. Windows 환경에서 실행되며, MS SQL Server와의 연동을 위해 FFI 및 ODBC를 사용합니다.

## 주요 구성
- Flutter UI 레이어: 사용자 인터페이스와 라벨 관리 기능을 지원하는 화면 및 상태 관리 코드.
- FFI 바인딩: Dart에서 Windows ODBC API를 직접 호출하기 위한 네이티브 연동 계층.
- 데이터 접근 계층: DbClient 추상화를 통해 MS SQL Server 쿼리를 수행하고 결과를 전달합니다.

## MS SQL Server 연동
- FFI를 사용해 네이티브 ODBC 드라이버에 접속하고, 연결/쿼리/결과 처리 전 과정을 Dart에서 제어합니다.
- mssql_connection 모듈은 ODBC 연결을 열고 닫으며, 파라미터 바인딩과 레코드 변환을 담당합니다.
- DbClient 구현체는 외부에서 동일한 인터페이스로 사용할 수 있도록 설계되어, 다른 데이터 소스로의 교체가 용이합니다.

### 발행내역 조회 인덱스 자동 준비
- 발행내역 조회 전에 현재 연결된 DB의 `IX_BM_RICH_PRINT_LOG_CustomerDate` 인덱스를 확인합니다. 다른 DB로 전환해도 이전 DB의 확인 결과를 재사용하지 않습니다.
- 인덱스가 없으면 테이블의 실제 스키마에 `(RICH_CUSTOMER_ID, RICH_DATE_YYYYMMDD) INCLUDE (RICH_DATETIME)` 비클러스터형 인덱스를 자동 생성합니다. 기존 데이터나 인덱스를 삭제하거나 조회 건수를 제한하지 않습니다.
- 생성 중에는 `인덱스 생성 중입니다.`와 대기 표시를 띄우고 조회 조건/버튼을 비활성화합니다. 생성과 상태 재확인이 끝난 뒤 목록과 합계를 조회합니다. 이미 준비된 인덱스는 다시 생성하지 않습니다.
- 최초 생성에는 테이블 크기에 따라 시간이 걸리고, DB IO/디스크 사용과 쓰기 대기가 발생할 수 있습니다. DB 계정에는 해당 테이블의 인덱스 생성 권한(`ALTER`)이 필요합니다. 권한 부족, 생성 실패 또는 사용할 수 없는 인덱스 상태는 오류로 안내하며 조회를 중단합니다.
- SQL Server 2017 및 DB 호환성 수준 100에서 동작하며, 진단 로그는 `printHistoryQuery`의 `indexCheckStarted`, `indexCreating`, `indexReady`, `queryFailed` 이벤트를 확인합니다.

## 기본 항목 사용자 정의 text
- 공용라벨관리의 **항목 편집**에서 기본 항목의 `사용자 정의 text`에 내용을 입력한 뒤 **적용 → 저장**합니다. 입력란 오른쪽 키워드 삽입 버튼을 누르면 큰 편집 창이 열립니다.
- 편집 창의 입력 항목을 **더블클릭**하거나 텍스트 입력란으로 **드래그**하면 현재 커서/선택 위치에 `#키워드`가 삽입됩니다. `#ITEMNAME`은 현재 품목명입니다. 직접 입력과 줄바꿈도 가능하며 200자까지 입력할 수 있습니다.
- 예: `#TEXT1 + #TEXT2 + #TEXT3 = 6`은 현재 품목값이 각각 `1`, `2`, `3`일 때 `1 + 2 + 3 = 6`으로 출력됩니다. 수식을 계산하지는 않습니다. 자기 키워드도 해당 품목의 원래 값을 사용하며, 치환된 값 속 키워드를 재귀적으로 확장하지 않습니다.
- **연한 하늘색은 현재 편집 항목**, **연한 보라색은 템플릿에 참조된 항목**입니다. 같은 행이 둘 다 해당하면 현재 편집 표시가 우선합니다.
- 설정한 내용은 품목의 출력내용 미리보기와 라벨/저울 발행에 적용되며, 품목 입력값과 자동증가 저장값은 덮어쓰지 않습니다. 빈 내용으로 적용·저장하면 다시 품목값을 출력합니다. 기존 기본 항목의 사용자 정의 QRData 형식도 읽을 수 있으며, 바코드·QR 전용 설정은 변경하지 않습니다.

## 시작하기
1. Windows 10/11 환경에서 PowerShell 5.1 이상과 winget 사용 가능 여부를 확인합니다.
2. Windows ODBC Driver를 설치합니다.
3. https://jrsoftware.org/isdl.php/Inno-Setup-Downloads을 다운로드 받아 설치 합니다. (배포 작성)
4. Flutter SDK를 설치하고 Flutter doctor로 환경을 확인합니다.
5. flutter.ps1 pub get으로 의존성을 받습니다. 이때 Windows용 MSBuild가 없으면 winget으로 Visual Studio Build Tools 2022(C++ workload) 설치를 시도합니다.
6. Flutter run을 실행하여 애플리케이션을 구동합니다.
7. Visual Studio Code에 최적화 되어 있습니다. (프로젝트 개발)

### Windows Build Tools 자동 설치 지원 환경
- 지원: Windows 10/11, PowerShell 5.1 이상, winget 사용 가능 환경.
- 확인: PowerShell에서 `winget --version`이 버전을 출력해야 합니다.
- winget이 없는 PC에서는 자동 설치가 중단됩니다. Microsoft App Installer가 포함된 Windows 10/11 환경에서 다시 `flutter.ps1 pub get`을 실행하거나, Visual Studio Build Tools 2022의 Desktop development with C++ workload를 수동 설치한 뒤 다시 실행합니다.

## 배포 작성 (Windows)
1. build_windows.ps1
2. inno_setup_installer.ps1

## 배포 작성 (Android) - 현재 미지원 (추후 지원 예정)
1. build_android.ps1

## 참고
- ODBC 드라이버는 Microsoft ODBC Driver 17 이상을 권장합니다.
- FFI 문서: https://dart.dev/guides/libraries/c-interop
