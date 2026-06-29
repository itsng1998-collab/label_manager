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
