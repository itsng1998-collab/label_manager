#define XAppName "Label Manager"
#define EAppName "label_manager.exe"
#define ReleaseDir SourcePath + "build\windows\x64\runner\Release"
#if !FileExists(ReleaseDir + "\vcruntime140.dll") || !FileExists(ReleaseDir + "\vcruntime140_1.dll") || !FileExists(ReleaseDir + "\msvcp140.dll")
  #error Run build_windows.ps1 successfully first to bundle the Microsoft C++ x64 runtime.
#endif
#ifdef AppVersion
  #define XAppVersion AppVersion
#else
  #define VerHandle FileOpen("version.txt")
  #define RawVersion FileRead(VerHandle)
  #expr FileClose(VerHandle)
  #undef VerHandle
  #define XAppVersion Trim(RawVersion)
#endif

; 1) 설치 프로그램 기본 정보
[Setup]
; 업데이트 시에도 동일한 AppId 유지
AppId={{A1B2C3D4-E5F6-47A8-9ABC-0123456789AB}
AppName={#XAppName}
AppPublisher=ITS&G Co., Ltd.
AppVersion={#XAppVersion}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

; 사용자 폴더 강제 (비승격, UAC 불필요)
PrivilegesRequired=lowest
DefaultDirName={localappdata}\{#XAppName}
AlwaysUsePersonalGroup=yes
DefaultGroupName=ITS&G

OutputDir=.\installer
OutputBaseFilename=Setup_LabelManager_v{#XAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#EAppName}
CloseApplications=yes
RestartApplications=no

; 2) 설치할 파일 지정
[Files]
; 상대경로로 Release 폴더 내 모든 파일을 복사
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
; 빌드 단계에서 Release 폴더에 수집한 Microsoft C++ 런타임도 함께 포함

; 3) 시작 메뉴 & 바탕화면 바로가기
[Icons]
Name: "{group}\{#XAppName}"; Filename: "{app}\{#EAppName}"
Name: "{userdesktop}\{#XAppName}"; Filename: "{app}\{#EAppName}"

; 4) 설치 완료 후 자동 실행 (선택)
[Run]
Filename: "{app}\{#EAppName}"; \
  Description: "Launch {#XAppName}"; \
  Flags: nowait postinstall skipifsilent

; 5) 언인스톨러 설정 (Inno Setup이 자동으로 생성)
;    기본으로 [UninstallDelete] 섹션 등이 추가됨
