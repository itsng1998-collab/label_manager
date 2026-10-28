# SESSION HANDOFF

## 완료: VS Code 공통 환경 준비 및 PowerShell 호환 (1.8.23)
- tools/build_environment.ps1 공통 구현 + prepare_build.ps1 진입점. VS Code F5/preLaunch, Windows/Android Release/Package, 루트flutter/build/Inno, native FreeType/RTF XLSX가 공통 준비 사용. 선택RTF는 해당native작업에서만 준비. 존재하지 않는WebView2 파일을 호출하던 낡은task 제거.
- 프로필별 Git/Flutter/VC++/CMake/Windows SDK/필수FreeType/pub, Android JDK17+/Google SDK명령도구/platform-tools/build-tools/CMake/현재Flutter기준platform+NDK, Inno 준비. 기존설치 재사용, 공식SDK/도구다운로드 체크섬 검증, 구Dart환경보다 새프로젝트SDK 우선/구SDK불변/반복다운로드 방지. Dart getFlutterSdkCommand로 SDK경로 공유.
- 호환성: Windows PowerShell5.1 및 PowerShell7.x, 관리진입점11개 Requires5.1/각Shell AST검사. 5.1미만은 시작시명확히중단. HTTPS메타데이터/다운로드는 TLS1.2 명시 및 설정복구, 네이티브실패코드 전파.
- **검증완료: PS5.1 환경50/50+배포26/26, PS7 환경50/50+배포26/26**. 명령: 각shell `-NoProfile -File tools/test_build_environment.ps1`, `-NoProfile -File tools/test_windows_release.ps1`. 로그 tmp/test_{build_environment,windows_release}_{ps51,ps7}.log. VSCode참조/JSON/SDK출력/구SDK재사용/TLS성공·실패 및 실패전파 확인.
- 실제 `pwsh -NoProfile -File tools/prepare_build.ps1 -Target Windows` 성공(exit0), 설치된VC/SDK/CMake/FreeType 재사용·모든pub get완료. 로그 tmp/build_environment_windows.log. 변경파일 진단오류없음, diff공백검사통과. SDK조회로그 .tmp/sdk_prepare.log.
- 버전1.8.22→1.8.23 PATCH(개발/빌드환경설정). 임시fixture 자동정리, 검증로그는Git제외. 실제앱/DB/프린터/Release빌드·새배포산출물 미실행. 새PC실제도구설치/AndroidSDK대량설치/F5앱구동은 미검증(다운로드/설치 분기는 격리모의).
- 권한/지원한계: VS/SDK설치는 사용자가 관리자PowerShell에서 WindowsTools 프로필 실행 필요(자동UAC없음), Android라이선스는 사용자가수락후재실행, Git/VS미설치+winget없으면선행설치안내. Windows호스트만지원, iOS는macOS/Xcode/CocoaPods필요오류. 에뮬레이터/USB/DB/ODBC/프린터는 자동설치범위밖. README에 절차/제약기록.
- **구현·검증·커밋 완료: `044c594`**, push 없음. .vscode3개/README/이문서/pubspec/루트4 PS/tools helper·native·test 등19개파일만 분리커밋, cached stat/check 통과. 사용자 lib/core/app.dart 보존·제외. 이 해시 기록은 별도문서commit이며 버전재증가 없음.

## 완료: Windows 배포 및 Inno 자동 설치 (1.8.22)
- 순서 유지: build_windows.ps1 성공 후 inno_setup_installer.ps1. 루트 전용 Release 빌드, 공식 VS2022 CRT10 DLL 수집, EXE버전/AMD64/필수파일 검사 성공 후 version.txt 기록. Flutter stdout과 종료 코드 분리, 현재SDK 미지원 --target-platform 미사용.
- ISS: 고정 AppId 형식 수정, Windows10+/x64compatible, Release 폴더 단일 소스. 대상PC의 System32에서 런타임을 읽던 external 제거. 패키징은 pubspec/버전파일/EXE 버전 일치 필수, 과거EXE 대체 금지, 로그/ZIP SHA256 보존.
- Inno 미설치 시 공식6.5.4를 HTTPS로 받고 고정SHA256 검증 후 CURRENTUSER 무인설치/완료대기/재탐색/패키징 자동재개. winget 불필요, 기존설치/IsccPath 사용 시 설치생략. 잘못된 명시경로/해시/설치실패/설치후컴파일러누락은 중단.
- 검증 완료: tools/test_windows_release.ps1 **PowerShell7 26/26 + Windows PowerShell5.1 26/26**. 실제 ISCC 문법컴파일, 정상/실패/ZIP/해시/루트전용빌드/CRT/버전/아키텍처와 자동설치8회귀 포함. 자동설치 자체는 모의검증(기존Inno 제거/재설치 없음).
- 실제 `pwsh -NoProfile -File build_windows.ps1` 성공(163.3s), EXE1.8.22/AMD64 및 번들검사 통과. `pwsh -NoProfile -File inno_setup_installer.ps1` 성공. installer/Setup_LabelManager_v1.8.22.exe 18,295,170bytes, ZIP17,758,095bytes/해시검사 통과. 로그: tmp/windows_release_{build,packaging,tests,tests_ps51}.log 및 installer/build_1.8.22_20261027_160308.log.
- 스크립트7개 AST/공백검사 통과. 기존 ZXing/csc 빌드경고만 존재. 편집기의 과거 args 경고는 디스크 AST에서 제거 확인, windows_build_tools의 기존 args/unapproved verb 경고는 유지.
- 버전1.8.21→1.8.22 PATCH(배포 오류/환경 자동준비 수정). 앱/DB/실물인쇄 미실행. 임시 테스트 폴더 자동정리, 검증 로그와 실제EXE/ZIP은 보존하되 Git 제외.
- 미검증/다음 확인: 새PC 실제설치·업데이트·제거/서명/프린터. ODBC Driver17+ 및 프린터드라이버 별도설치. 이전배포판의 잘못된 AppId 등록키와 새GUID가 다른 경우 기존판 제거 후 재설치 필요.
- **구현·검증·커밋 완료: `a6bba00`**, push 없음. 배포스크립트/ISS/flutter, tools의 기존build helper+신규3 helper/test, README/pubspec/이문서 등11파일만 분리커밋, cached stat/check 통과. 사용자 lib/core/app.dart 및 루트/third_party pubspec.lock4개 보존·제외. 이 해시 기록은 후속 문서 전용 커밋이며 버전 재증가 없음.

## 최근 완료: 라벨출력 여백과 밀기 분리 (1.8.21)
- 제출 1.8.9 로그/이미지 확인: 실제 발행 기록은 없고 미리보기 비교. 기존 코드는 margin+push를 같은 시작점에 더하면서 본문 폭을 유지해 두 기능이 동일하게 보였음. 레거시 매뉴얼v2와 PrintManager의 FormatRange/별도 push 좌표 대조.
- 구현: 공통 출력용 formatter에서만 여백에 맞게 열 폭과 문단 줄바꿈을 재계산. 80mm 라벨의 좌여백10=본문70mm, 좌10+우5=65mm. 밀기10은 본문80mm를 유지한 위치 이동. 위여백은 시작점과 사용 가능 높이를 제한하며 회전 시 본문 축도 반영. 유효하지 않은 여백/빈 인쇄 영역은 명시적 오류.
- 미리보기·Windows·EZPL·래스터/PDF에 같은 계산 적용. 원본 workbook과 미리보기 변환본을 분리해 캡처 시 중복 적용 방지. 글꼴 크기, 표 고정행 높이, 절대좌표 이미지/도형/바코드 크기 보존; RTF 흐름 이미지는 문단 높이 변화만큼 세로 이동. 원본 시트/품목 DB 변경 없음.
- 검증 중 해결: 좁아진 본문을 다시 확대하지 않도록 여백 출력은 원래 물리 크기 캔버스로 padding. 기존 일반 capture 기본 동작 보존. push-only/no-options 전환은 불필요한 Workbench 재생성을 피해 zoom 보존. 미리보기 우측/하단 clip도 출력 영역과 일치.
- **구현·검증·커밋 완료: `cdb2831`**, push 없음. margin/printJob/lineSpacing/previewPush/session/pipeline/scale/Fortune capture/hybrid 9파일 **126/126 통과**. 실제 미리보기 픽셀 클립, 70/65mm 폭, push-only PNG 동일성, 여백 PNG 변화, PDF 생성, 줌150% 및 기존100/200%, 표 고정행·RTF 이미지 흐름, 원본 불변 검증.
- 변경 7파일 analyzer No issues found. 전체 변경 Dart 분석은 기존 unused 경고12건(인쇄 helper2/Canvas10)만 남음. diff --check 통과. README 갱신, 버전1.8.20→1.8.21 PATCH(기존 출력 레이아웃 수정, 저장형식/스키마 변경 없음).
- DTD 발견·기존 연결 확인 및 hot reload 시도했으나 실행 앱 없음. 운영 DB 접속 방지를 위해 앱 자동 실행하지 않음. 운영DB/실물인쇄 없음, 사용자 lib/core/app.dart 변경 보존.
- 다음 사용자 확인: 1.8.21에서 TEST 8*6의 첫 품목으로 여백/밀기0 기준, 좌여백10, 좌밀기10을 각각 비교. 여백은 좁아진 폭에서 줄바꿈/잘림, 밀기는 원래 폭의 위치 이동인지 미리보기와 실물 확인. 운영 라벨/프린터 결과는 사용자 확인 필요.

## 최근 완료: 라벨출력 다수 발행 시 단일 출력 (1.8.20)
- 제출1.8.9 로그/이미지 확인: item722776 발행3매, capture1/3·2/3·3/3 및 GoDEX G500 USB036에 copies=1인 PRN RAW작업3개(job77/79/81) 접수. UI입력 누락 아님. 스풀접수만으로 실물1장 원인을 확정할 수 없음.
- 레거시 매뉴얼v2의 품목별 발행매수와 PrintManager 실제코드 대조: GoDEX 등 dmCopies=요청매수, BIXOLON은dmCopies1/StartPage반복. 현재 Flutter는 모든unit마다 copies1 요청.
- 구현: Windows 출력은 같은행/같은투영값의 연속unit만 묶어 한 드라이버요청에 실제매수 전달. 자동증가/다른품목/크기/순서 보존, DEVMODE signed short 32767매 초과는분할. 그룹 구성은 내부list에append후immutable반환하여대량매수분할시반복전체복사방지. PDF/RAW/저울출력 별도흐름은 유지. 기존 캡처/역상PRN변환 및 드라이버환경설정 변경 없음.
- 회귀작성후 수정전2건 실패(투영값/품목구분 없이5개한그룹), 수정후pipeline/bitmap테스트 통과. 3매동일라벨/장별자동증가/다른행/동일map별도인스턴스/연속순서/32768→32767+1분할 및 드라이버요청copies3·GoDEX단일RAW전달 검사.
- 공유groupAdjacent는 저울도 사용하므로 기존 물리크기그룹 계약 유지, 라벨발행 전용groupLabelPrintUnitsForDispatch에서만 동일내용 다매수분할 적용. README갱신, 버전1.8.19→1.8.20 PATCH(기존Windows 다매수전달/배치수정, 저장형식·스키마변경없음).
- **구현·검증·커밋 완료: `ba13348`**, push 없음. pipeline/bitmap/autoIncrement/persistence/session/dispatcher/GoDEX inverse/scale 8파일101/101 통과. 다매수PRN(^P3) 역상변환 후에도매수보존, GoDEX한RAW제출 및 BIXOLON/일반드라이버copies3 전달, 동일라벨이력count3/자동증가이력개별count1, immutable그룹과저울기존그룹계약 확인. 변경5 Dart analyzer No issues found, diff --check통과.
- DTD발견·기존연결확인/앱목록/hot reload시도했으나 실행앱없음. DB접속 방지를 위해 앱자동실행하지않음. 운영DB/실제발행 없음, lib/core/app.dart 사용자변경 보존.
- 다음 사용자확인: 1.8.20에서 같은첫품목3매→GoDEX gdiDispatch units=3/copies=3 및실물3장확인. 기존로그의별도3작업이실물1장이된하드웨어원인은확정불가, 변경후에도발생하면새로그와같이생성된bitmap_print_requests의 .bin/.prn을확인(실제출력전송기록/명령수량대조). 자동증가설정있는품목은장별값순서별도확인.

## 최근 완료: 프린터 설정 자동줄간격 적용 (1.8.19)
- 제출1.8.9 로그에는 적용 당시 품목별 useLinefeed/linefeed 결과값이 없어 해당 화면의100% 유지 원인은 미확정. 기존 spacing/settings/session36건 통과.
- 사용자 지시: 레거시 동작 우선, 없으면 기존 우선순위 유지. 매뉴얼v2의 발행목록/프린터설정/품목별 줄간격 설명과 실제 LabelPrintModel::ChangePrintSetup 대조: !bUseLinefeed 행은 목록 직접편집 여부와 무관하게 설정 적용 시 새 기본값으로 갱신. 현재 sessionEdited 보존은 이 부분과 다름.
- 구현: 줄간격만 레거시 조건(!item.useLinefeed)으로 적용하고 출처를 preferenceFallback으로 복귀. 품목별 사용ON(설정안함 포함)과 그 행의 직접편집은 보존. 여백 등 다른 필드 정책 변경 없음. 300/null/80 및 baseline재동기화, 설정창→목록→미리보기/Windows인쇄준비 회귀 추가. 수정 전2건 모두300기대/100실제로 실패, 수정 후focused4건 통과.
- **구현·검증·커밋 완료: `a182326`**, push 없음. session/settings/lineSpacing/previewPush 4파일41/41 통과. 새 UI회귀는 실제 설정dialog의300선택 callback/적용을 거쳐 행300, 미리보기 문단행10→30, Windows인쇄준비 행30, zoom·원본시트·품목DB설정 불변 확인. 기존 표115%/고정행높이 및 capture/여백/밀기 회귀 유지. 변경2 Dart analyzer No issues found, diff --check통과.
- README 정책 정정, 버전1.8.18→1.8.19 PATCH(국소 줄간격 적용조건 수정, 저장형식/스키마 변경 없음). DTD발견/기존연결확인·앱목록/hot reload시도했으나 실행앱 없음. 운영DB 접속 방지를 위해 앱자동실행하지 않음. 운영DB/실제인쇄 없음, lib/core/app.dart 사용자변경 보존.
- 다음 사용자확인: 1.8.19에서 해당 첫품목을 발행목록에 올려 프린터설정300% 적용 후 목록/미리보기 확인. 품목별 줄간격 사용ON이면 기존값 유지가 레거시 동작이므로300% 일괄강제하지 않음. 제출로그 당시 실제 useLinefeed 값과 운영라벨에서의 재현은 사용자확인 필요.

## 최근 완료: GS1 AI 표시값 혼입 및 항목/바코드 속성 정리
- 제출 로그1.8.9 및 첨부5장 확인. GS1 AI showGS1Code가 tokenColumnValue에서 (00)을 붙인 표시값을 _resolveGs1 검증/조합에 전달하는 것이 원인. 레거시 GetGS1CodeData는 원본값(날짜는 DATE_FORMAT_NONE)만 조합, TYPE_GS1_AI 텍스트치환에서만 괄호표시.
- 구현: GS1_AI 원본과 표시분리, 발행projector의 (AI)첨가 제거/출력텍스트에서만첨가(라벨·저울·자동갱신 모두 공유), 원본에괄호붙은잘못된값은 그대로검사실패. 이미지/1D/GS1바코드 열편집 크기·1D line/rotate 숨김(기존값유지), GS1 code사용 출력강제ON/적용시ON저장/숨김, CODE39/MicroQR/CODE93 제외(열편집/연결개체형식목록/해석기차단).
- 바코드 형식유지 강제ON/속성·삽입선택기숨김, 형식오류 CODE128대체금지(기존OFF도 새정책적용), 1D모듈배율 비활성화. 개체연결만바꾸면 기존개체형식유지, 신규삽입연결은 열설정형식초기선택. 기존불가형식은 임의변환금지/선택안내. 날짜token callback은 기존원본기준계산유지.
- **구현·검증·커밋 완료(1.8.18): `8c9b097`**, push 없음. resolver/editor/height/commonLabel/autoIncrement/pipeline/persistence/scale/objectController/objectCodec10파일225/225, toolbar GS1/2D/barcode22/22(native GS1 PNG/Windows 인쇄이미지준비 포함), native height/property/GS1삽입전체33/33 통과. 최종247건 + native재검증33건. SSCC표시ON/OFF·18자리/잘못된자리수/선행0·원본괄호오류·포맷불일치·기존OFF무시·새옵션목록·숨김값보존·연결1D모듈불가·형식유지선택기hit제거·저장재읽기/undo/redo 검증. 범위밖 formatter변경 제거후 autoIncrement8/8/analyzer재통과.
- 변경13 Dart analyzer에서 canvas의 기존unused10건만 유지, 나머지11파일 No issues found. diff --check통과. 레거시매뉴얼v2 GS1상세설명없음(XML문단검색), 실제코드대조 완료. DTD발견·기존연결확인/앱목록/hot reload시도했으나 실행 앱 없음으로 미적용, 운영DB접속 방지를 위해 앱자동실행안함.
- 운영DB/실제인쇄 없음. lib/core/app.dart 사용자변경 보존. 버전1.8.17→1.8.18 PATCH: 기존GS1 표시혼입오류수정과 중복/미지원옵션정리, 저장포맷·스키마변경없음. README갱신.
- 다음 사용자확인:1.8.18→GS1AI AI00/표시ON→GS1바코드 포함#GS1AI 적용/저장→code128개체연결/저장→4번째품목(원본18자리) 텍스트(00)표시와바코드정상확인. 표시OFF에서도동일스캔값. 기존개체의형식이열설정과달라도자동변경하지않으므로 개체속성에서올바른형식을직접선택. Micro QR 네이티브생성미지원은직전handoff참조, 이번GS1에서는선택제외.

## 최근 완료: 2D 연결 바코드 품목 미리보기/발행 실패
- 제출1.8.9 로그/이미지: #2DBARCODE 품목값1234567891이 존재하나 생성data가 비어 출력차단. 같은라벨8243의 제출XML 로그에서 column141679의 qrCreateType=1(10/22)/2(10/26 11:03), userQrData/natrium 모두빈값 확인. 현재로그10/26 10:57에는 열설정 실제행이 없어 직전/직후 로그로 대조.
- 레거시 TableRowRTFMaker::GetQRCodeData는 기본=품목값, 사용자정의=조합, 나트륨=URL이며 빈조합 대체처리 없음. 사용자 지시: 레거시대조, 없으면 제시1번(raw-with-warning). 따라서 QR 사용자정의/나트륨의 조합설정 자체가 빈경우만 품목값 사용+명시적경고, DB설정 변경없음으로 보완.
- 설정된조합의 결과가빈경우/비어있지않은 잘못된나트륨설정은 대체하지 않고 기존오류유지. 실제품목값도없으면 계속차단. 명시적인 QR text/공백payload는 보존. 출력 재해석 시 오래된경고/오류 제거.
- **구현·검증·커밋 완료(1.8.17): `3655161`**, push 없음. resolver+toolbar QR/barcode focused43/43 통과. QR데이터보기에도 경고표시/진단 연결. 저장재읽기/삽입연결과 code128→2D속성연결의 동등한 품목별payload/포맷, 3종2D×2가지빈설정, 품목값비어있음차단 확인. native6/6 통과(QR/DataMatrix4건 PNG/Windows인쇄이미지 준비, Micro QR2건 기존명시적실패유지). 변경4 Dart analyzer No issues found, diff --check통과. 범위밖 포맷변경 제거후 resolver24/24 재통과.
- 운영DB/실제인쇄 없음, 사용자 lib/core/app.dart 보존. 버전1.8.16→1.8.17 PATCH: 기존2D 데이터원본 선택의 빈설정 처리 보완, 저장형식/DB변경 없음. README갱신. DTD발견/기존연결확인후 hot reload시도했으나 실행앱 없음.
- 주의: flutter_zxing2.4.0/src/zxing/core/src/MultiFormatWriter.cpp에 MicroQRCode writer branch 없음 확인. 이번데이터원본수정과별개인 기존한계로 명시적실패/오류placeholder/형식유지 계약을 테스트하고 README제한사항 기록. 인코더교체/형식임의대체 안함.
- 다음 사용자확인:1.8.17에서 기존라벨의 #2DBARCODE 삽입/속성재연결→저장→품목 선택→품목값1234567891의 이미지 및 빈설정대체 경고 확인. 실제 운영 발행은 사용자확인 필요. 다른2D형식의 속성테스트는 QR/DataMatrix로 진행, Micro QR 생성지원은 별도작업 필요.

## 최근 완료: 바코드 체크박스만 변경 시 미적용/글꼴 콤보
- 제출1.8.9 로그/이미지 확인. 비율유지는 직전1.8.15에 개체별저장 수정 완료, 이번 요청에서 조합 회귀 유지.
- 원인: 속성 _fieldsMatchInitialText가 텍스트/비율만 비교해 showText와 preserveTemplateFormat만 바꾸면 무변경으로 처리. 두 boolean을 동일 baseline판정에 포함 완료. 수정전 checkbox-only2회귀 모두 renderer미호출로 실패, 수정후통과.
- 글꼴은 controller.settingsSnapshot.fontFamilies(삽입창과 같은 로드목록)를 재사용한 검색/직접입력 가능 콤보로 교체 완료. 기존목록밖저장값도 유지, 빈입력은 기존 null/default. mutation불가시 disabled 유지.
- 레거시 Barcode 화면코드는 굴림 미리보기 설정, 매뉴얼v2에는 해당Flutter property패널 상세계약 없음. 현재 삽입창의 글꼴목록/저장필드 재사용.
- **구현·검증·커밋 완료(1.8.16): `e8f0655`**, push 없음. height/property+object controller+codec85/85, toolbar barcode13/13, native encoder height/property전체30/30 통과. 글꼴목록선택·직접입력·목록밖저장값·재로드·빈값/default·show/aspect조합, 두checkbox ON/OFF단독변경·metadata·request·PNG변경·undo/redo 검증. 변경2 Dart analyzer No issues found, diff --check통과.
- 운영DB/실제인쇄 없음, 사용자 lib/core/app.dart 보존. 버전1.8.15→1.8.16 PATCH: 기존 checkbox dirty판정 누락 수정과 글꼴필드 선택기 보완. README갱신.
- DTD발견·기존연결확인 후 hot reload시도했으나 실행 앱 없음으로 미적용. 다음확인:1.8.16→바코드삽입→속성에서 비율유지OFF/텍스트표시ON만변경→적용→글꼴콤보선택→적용→라벨저장→재로드/품목출력 미리보기 확인. 실제 운영 발행은 사용자확인 필요.

## 최근 완료: 삽입 바코드 비율 유지 상태 미전달
- 제출 로그1.8.9/첨부에서 삽입OFF→속성ON 확인. 삽입 _barcodeAspectLocked와 속성 _imageAspectLocked가 독립 기본true이며 개체 metadata에 상태가 없음.
- 사용자 확정 persist-per-object: 개체별 상태 저장, 선택전환/복제/저장재읽기 유지. 기존문서의 비저장 정책은 이번 요청으로 변경. metadata 없는 기존 개체는 기본ON 유지.
- 레거시 Barcode 속성코드와 매뉴얼v2 검토에서는 이번 Flutter 삽입/속성 사이 상태 전달에 대응하는 계약 없음. boolean barcodeAspectLocked metadata를 삽입/속성/기존편집dialog/codec에 연결, typed draft와 dirty판정·undo복원에 반영. 일반image의 기존 비저장 동작은 유지.
- 수정전OFF→속성ON 회귀실패 확인, 수정후통과. 변경3파일 집중analyzer No issues found, canvas는 기존 unused10건만 유지. height/object controller/codec3파일82/82 통과. width30을 기대한 과거tests2건은 삽입OFF 유지 계약에 맞게 폭20유지로 갱신. 새 회귀는1D/QR·mm/px·ON/OFF8조합·선택전환·복제·저장재읽기·undo/redo·기존metadata없음·aspect-only적용실패/재시도 검증.
- 실패후aspect-only 재시도가 finalized로 차단되는 결합문제도 수정: 실패한 속성 draft를 다시 등록해 입력유지/수정없는 재시도/저장차단 유지. toolbar barcode회귀13/13 및 native encoder로 height/aspect 전체27/27 추가통과. 최종 관련회귀95건 + native27건 통과.
- 운영DB/실제인쇄 없음. 사용자 lib/core/app.dart 보존, 버전1.8.14→1.8.15 PATCH: 삽입옵션 전달 누락 수정 및 사용자확정한 개체별 저장 유지. README의 기존 비저장정책 갱신.
- **구현·검증·커밋 완료(1.8.15): `c18f819`**, push 없음. 최종panel/codec/test analyzer No issues found, diff --check통과. DTD발견·기존연결확인/hot reload 시도했으나 실행 앱 없음으로 미적용.
- 다음 사용자확인:1.8.15→바코드 삽입에서 비율유지OFF→속성OFF 확인→폭/높이 독립변경→적용→라벨저장→다시열어OFF 확인. ON개체와 선택전환·복제도 각각의 상태 유지. 기존1.8.9 저장본에는OFF정보가 없어 기본ON이며 새버전에서 설정후저장 필요.

## 최근 완료: 바코드 사용자 정의 text 및 키워드 미리보기
- 제출1.8.9 로그/이미지 확인. 사용자 확정: caption-only(하단 글자만 치환, 스캔값 유지), select-item(항목편집에서 품목 선택 후 실제값 이미지 미리보기).
- 원인: ItemCodeColumnSpec가 userDefineBarcodeText를 읽지 않고 출력 metadata/renderer도 data만 하단에 표시. 기존 기본항목 키워드 편집기를 바코드에도 재사용, 품목 선택·실제값 이미지·오류 안내 추가 완료. 품목 데이터 snapshot은 기존 로드된 draft에서 제공하며 새DB조회 없음.
- 레거시 TableRowRTFMaker는 바코드 데이터와 사용자 text를 별도 GetBarcodeRTF 인자로 전달. 매뉴얼v2 확인했으나 해당 사용자 text 상세 설명 없음. 운영DB/실제인쇄 없이 회귀 검증 예정.
- **구현·검증·커밋 완료(1.8.14): `5ae2623`**, push 없음. 관련3파일79건/editor+resolver+height, toolbar 출력/자동영양18건, column save/edit34건으로 회귀131건 통과. native PNG추가1건은 기존 Debug DLL 디렉터리를 PATH에 추가해 통과(최초 DLL탐색실패 해결). 잘못 지정한 codec test 파일은 존재하지 않아 제외 후 실제 저장2파일34/34 재실행 통과.
- 미리보기 encoder오류는 로그+명시적 실패결과/UI 처리, 비동기 미처리예외 없음. native 인코더로 scan data와 caption 분리, PNG body전체픽셀동일/text영역차이 확인. 출력 mapping·저장재읽기·품목변경·빈값·이전caption제거·200자/취소·900x600 계약 유지.
- 변경9 Dart analyzer No issues found, canvas는 기존 unused10건만 존재. diff --check통과. DTD발견·기존연결 및앱목록 확인/hot reload 시도했으나 실행 앱 없음으로 미적용. 운영DB 접속·변경/실제인쇄 없음.
- 사용자 lib/core/app.dart 변경 보존. 버전1.8.13→1.8.14 PATCH: 기존 바코드 하단text 누락 수정 및 같은 필드의 키워드선택/미리보기 보완. README에 caption-only/품목선택/번호표시/빈값/별도저장 안내.
- 다음 사용자확인:1.8.14→공용라벨 항목편집 BARCODE→사용자text 추가버튼→TEST 더블클릭→미리보기 품목선택→하단2345/스캔값12345679123 확인→편집창적용→속성적용→저장→품목 출력내용 및 발행 확인. 기존 저장된 #TEST도 재입력 없이 출력 치환됨. 운영환경 발행은 사용자 확인 필요.

## 최근 완료: 자동 영양성분표 삽입 시 사용 키워드 미등록
- 제출 `.tmp\1.8.9로그\공용라벨_영양성분표삽입_키워드오류.log` 버전1.8.9. box117/type의 양식 선택 후 B2에 셀158개 삽입 성공, 항목 등록 경로 없음.
- 레거시 매뉴얼v2 자동성분표 절은 표와 영양 항목 자동 추가 명시. CommonLabelModel::InsertNutBox는 BM_RICH_NUTCOLUMN의 type별 키워드/이름→중복 검사→TYPE_NUT 항목과 기존/자동갱신 품목의 빈내용 등록→목록갱신. 하나라도 중복이면 삽입 거부.
- **구현·검증·커밋 완료(1.8.13): `3dca159`**, push 없음. Workbench→Page→CommonLabelManage→Home의 등록callback 연결. 양식파싱 후 선택type의 정의를 TYPE_NUT로 기존saveDialog 트랜잭션에 등록하고, 항목만 재조회/기존draft보존 후 표삽입. DB등록중 blocking overlay와 Home busy/권한/미저장 품목 guard 사용. duplicate/empty/실제저장오류는 표미삽입, 커밋불명·저장후reload실패는 기존 명시적오류 유지.
- 관련6파일 회귀84/84 통과(순수command, CommonLabelManage 전체, nutrition type DAO/box dialog, label column save/edit). 신규 full UI3건은 성공/B2·17항목·저장재읽기·undo/redo, 중복거부, 저장실패 시 표·항목·dirty 유지 검증. 기존 toolbar 자동삽입3건도 통과. 변경7 Dart analyzer No issues found, git diff --check 통과.
- 버전1.8.12→1.8.13 PATCH: 기존자동삽입의 항목등록 누락 수정. SQL추가 없이 기존2017/호환성100 save경로 재사용. README에 삽입시항목DB등록/중복거부/시트undo시항목유지/라벨별도저장/오류계약 기록.
- 운영DB 접속·변경/실제인쇄 없음. 사용자 `lib/core/app.dart` 변경 보존.
- DTD 발견·연결 후 hot reload 시도했으나 실행 앱 없음으로 미적용. 실제 운영DB 등록은 미검증. 다음 사용자확인:1.8.13 실행→복사테스트/TEST→B2 자동성분표 삽입→우측 사용 항목 N01~N17 확인→라벨 저장. 항목은 삽입 시 DB 등록, 표는 라벨 저장 필요. 기존항목 중복 시 레거시처럼 삽입 거부.

## 최근 완료: 복제 바코드 속성 높이10→15가 막대 높이에 미반영
- 제출 `.tmp\1.8.9로그\공용라벨_바코드속성_높이제한오류.log` 버전1.8.9 확인. 첨부는 선택영역/속성20×10→30×15지만 실제 막대 높이는 동일.
- 원인: 속성 폭/높이는 geometry만 변경하고 barcodeBarHeight는10으로 유지. 이전 삽입창 sync-height 수정은 속성 패널에 적용되지 않았으며 기존 속성 회귀도 별도 바 높이 유지로 고정돼 있음.
- 사용자 선택 확정: sync-height. 1D 속성 높이 변경 시 바 높이도 같은 값, 비율유지 폭변경으로 바뀐 높이도 동기화. 이후 바 높이 직접입력은 우선. 회전만 변경/비율해제 폭만변경/2D 모듈·바 높이/RTF 단위는 유지.
- **구현·검증·커밋 완료(1.8.12): `d8cd574`**, push 없음. 속성 치수 입력에서 실제 적용될 높이로 barHeight 필드 동기화. 입력 이후 직접 바 높이 수정은 그대로 우선. 비율 토글 전에 폭을 수정한 경우도 최종 비율 상태로 동기화. 기존2D판정 helper를 삽입/속성에서 공유하고 렌더/메타데이터/저장포맷은 유지.
- 수정 전 복제 회귀3건(mm/px/RTF) 모두 실패: 기대56.693px(15mm)/실제37.795px(10mm), px기대15/실제10. 수정 후 portable16/16통과. 복제/회전보존 후10→15 실제PNG잉크, 원본보존/저장재읽기/undo·redo, 비율ON/OFF/입력순서/직접override/빈값0음수NaN/QR module·barHeight 계약 확인.
- analyzer는 canvas의 기존unused10건 외 신규 curly-braces info1건 발견해 해당if블록 수정. panel+test analyzer 재검증 No issues found, diff --check통과.
- 실제native encoder모드로 높이/전체object controller/삽입dialog/toolbar4파일 확대실행:314통과/1실패. 실패는 handoff에 이미 알려진 범위밖 ANSI RTF 딸기→딪기 계약1건이며 이번 변경에서 수정하지 않음. 이후4파일barcode선택 회귀58/58통과. 실제DLL로10mm38px→15mm57px 및px10→15의 실제PNG잉크 높이 확인.
- panel+test analyzer No issues found, canvas는 기존unused10건만 있고 오류/신규진단 없음. DTD발견·기존연결 상태확인 및hot reload시도했으나 실행 앱 없음으로 미적용.
- 버전1.8.11→1.8.12 PATCH, 기존속성 높이 반영 버그 수정, README갱신.
- 운영DB/실제인쇄 없음, 사용자 `lib/core/app.dart` 보존. 다음 사용자확인:1.8.12 실행→동일삽입/복제→높이10→15 적용 확인. 속성 비율유지ON이면20×10→30×15, OFF이면20×15이며 이후 바 높이 직접입력값은 우선.

## 최근 완료: 사용자 추가 후 로그인 불가
- 제출 `.tmp\1.8.9로그\파일관리_사용자관리_추가후로그인불가.log` 버전1.8.9 확인. BM_USER INSERT 성공 후 새ID의 BM_UPDATE_NOTICE 조회는 정상0건인데 NoticeDAO가 No rows in result 예외를 발생시켜 UserDAO 조회에 도달하지 않음.
- **구현·검증·커밋 완료(1.8.11): `db2f886`**, push 없음. NoticeDAO 정상0건은 빈 공지/state1의 표시용 결과로 처리하고 found=false 진단 추가. 본인 인증은 기존 UserDAO/비밀번호/사용자접속인증 경로에서 그대로 수행한다. 공지/억제 상태를 DB에 생성·저장하지 않음. message-only API도 공통 경로 사용. 실제DB/파싱 오류는 lookupFailed로 기록하고 전파.
- 수정 전 신규 Map/JSON0건 회귀2건이 No rows in result로 실패 확인. 최종 등록/로그인/공지/인증8파일82/82통과, 변경3 Dart analyzer No issues found, diff --check 통과. 새 실제UI회귀는 공지0건→없는ID거부→신규ID조직/이름표시→빈공지창없음→틀린비밀번호거부→선행0비밀번호로 일반로그인·접속인증/로그인내역callback·정상세션/다이얼로그닫힘 검증. 공지0/1/2상태 보존·message-only·실제오류전파 확인.
- 버전1.8.10→1.8.11 PATCH: 신규계정의 선택 공지0건을 ID오류로 오인하는 버그 수정. README 갱신, SQL/DB스키마/등록정보 변경 없음.
- DTD발견·기존 연결 확인 후 hot reload 시도했으나 실행 앱이 없어 미적용. 앱 임의 실행/운영DB 접속·변경 없음. 사용자 `lib/core/app.dart` 변경 보존. 직전1.8.10 필수등록 수정 유지.
- 다음 사용자 확인:1.8.11 실행 후 기존에 등록한 새ID로 조회·로그인. 재등록/공지행 수동생성 불필요. 실제 운영DB 로그인·저장은 미검증.

## 최근 완료: 공용라벨 필수등록 체크 후 항목편집 해제 저장 오류
- 제출 `.tmp\1.8.9로그\공용라벨_키워드_필수등록저장오류.log` 버전1.8.9 확인. 첨부 화면51115, 제출 로그의 실제 실패는51116(Main missing-keyword value changed).
- TEST 원본/수정 XML의 check는 모두0이며 changedKeys는check. 현재 DAO는 보조 BM_RICH_CHECK_COLUMNS 값만 읽는데51116은 본 BM_RICH_COLUMN의 값을 같은 원본과 비교한다. 본/보조 값이 다른 기존 데이터에서도 잘못 충돌할 수 있는 경로 확인.
- **구현·검증·커밋 완료(1.8.10): `14dbc25`**, push 없음. TColumn에 persistedMainMissingKeywordCheck 분리. DAO에서 COL_LENGTH로 선택 컬럼 확인 후 같은 항목 조회에 본/보조 값을 함께 읽는다. original XML mainCheck 및 SQL MAIN_CHECK_YN으로51116을 본 원본과 비교하며51115/잠금/롤백/기존 두 테이블 갱신 유지. 공용라벨 저장은 보조 원본만 승격한다.
- 수정 전 신규회귀 실패 확인 후 관련5파일103/103통과(매핑/저장SQL/도메인/실제UI/공용저장 snapshot). 본/보조4조합 및 UI 본false/true의 체크→해제→적용→저장, 선택 컬럼 없는 쿼리 계약 확인. 최초 compiler invalidation 안내 후 핵심9건 재실행도9/9통과, 안내 재발 없음. 변경7 Dart analyzer `No issues found`, diff --check 통과.
- 버전1.8.9→1.8.10 PATCH: 기존 저장 충돌 판정 버그 수정, 스키마/저장 포맷 변경 없음. README 갱신. 운영DB 접속·변경/실제 인쇄 없음. 사용자 `lib/core/app.dart` 변경 보존.
- DTD 발견·연결 완료, 연결된 실행 앱 없음. hot reload 시도는 No active app connection으로 미적용. 앱 임의 실행/DB접속 없음.
- 다음 사용자 확인:1.8.10에서 해당 브랜드/라벨을 다시 불러온 뒤 제출 재현순서 수행. 실제 운영DB 저장은 미검증이며 본/보조 현재 실제값은 조회하지 않아 추정하지 않는다.

## 최근 완료: GoDEX 외 프린터의 검정 배경 누락
- **구현·검증·커밋 완료(1.8.9): `23f40a8`**. push 없음. 제출 두 이미지에서 G500은 검정 제목행/흰 글자, D420·ZM410은 흰 제목행/검정 글자로 반전됨.
- 제출1.6.0 로그의 D420은 `inverseRowFallbackDescriptors=2 bands=1 clearedPixels=19809`, Zebra(ZDesigner ZT410-300dpi ZPL)는 2/1/41580. 둘 다 `inversePolarity=boxedHeaderBlackOnWhite`. G500은 원래 극성 유지 및 GoDEX 전용 PRN 전송.
- 원인: Windows native `PrepareInverseRowFallback`가 GoDEX 외 프린터에서 흰 글자를 검정으로 바꾸고 검정 행 전체를 흰색으로 덮음. 레거시 PrintManager::PrintRichEdit는 BIXOLON의 매수 처리만 분기하고 같은 RichEdit 서식을 출력하며 이런 배경 반전은 하지 않음.
- 구현: PrepareInverseRowFallback 삭제. non-GoDEX의 기존1bpp 메모리 DIB에 원래 배경/흰 native 글자를 유지. PrepareDriverTextDescriptors로 기존 GoDEX 흰글자 제외/일반글자 native 선택만 공유한다. GoDEX의 inverse bitmap/geometry/PRN 전송과 프린터 기본설정/배율/단색 전송은 유지. 진단은 originalWhiteOnBlack/nativeTextMonoDib/inverseRowFallback=disabled.
- production cpp를 포함하는 native 회귀 추가: 실제 장치bitmap/텍스트선택/GDI함수 사용, 프린터DC/StartDoc/DB 없이1bpp memory pixel 검사. 수정 전 `Black header background was cleared` 실패, 수정 후4시나리오 통과:203dpi639×480 제목행18887/19936검정,300dpi945×709는42061/44208검정,2배 원본재샘플/다른드라이버640×480. 전체·부분검정배경에 흰 글자/일반 검정 글자/무관 흰배경/원본/GoDEX분리계약 확인.
- 사용자 `lib/core/app.dart` 변경 보존/stage 제외. 버전1.8.8→1.8.9 PATCH: 기존 Windows 프린터 배경 극성 변경 버그 수정. README 및 native probe 문서에 동작/회귀/실물 미검증 한계 기록.
- 검증: native CTest4/4(기존 device layout/RichEdit inverse/font reference + 새 background4시나리오), Flutter7파일77/77(전체 non-GoDEX 벤더 GDI 제출/GoDEX PRN/배경·흰글자 descriptor·raster/줄간격 포함), 변경 Dart test analyzer `No issues found`. MSVC /W4 /WX native test 및 `flutter build windows --debug --no-pub` 성공. 생성 Debug exe ProductVersion/FileVersion 모두1.8.9 확인.
- 실제 프린터 전송/DB 변경 없음. 다음 확인: 새1.8.9 Windows 실행 파일로 앱을 다시 실행해 동일 품목을 G500/D420/Zebra로 비교. 제목행 검정 배경·흰 글자와 일반 본문/테두리/배치 유지 확인. C++ 변경은 hot reload로 반영되지 않아 새 실행 파일 재시작이 필요함.
- DTD발견 및 기존 연결 상태 확인 후 hot reload 시도했으나 실행 중 앱이 없어 미적용. 임의로 앱을 실행하거나 DB에 연결하지 않음.

## 최근 완료: 라벨출력 자동줄간격 80%/300% 결과 동일
- **구현·검증·커밋 완료(1.8.8): `11cb6c9`**. push 없음. 범위 밖 사용자 `lib/core/app.dart` 변경만 유지.
- 제출 `라벨출력_프린터설정_자동줄간격오류.log`는1.6.0. G500/windowsDriver/203.2dpi/80×60, 두 발행의 PNG5367bytes·ink27737·native34개·border63개 모두 동일. 설정값 자체는 이 구버전 로그에 없어 추정하지 않는다.
- 수정 전 신규회귀에서80% 기대 행높이8/실제20으로 실패 확인. 현재 코드도 lineSpacingPercent를 capture/native text layout에 전달하지만 셀 내부 TextStyle.height만 바꾸고 셀 행 높이/다음 문단 위치는 고정되어 있던 것이 원인.
- 사용자 추가 지시: 애매하면 레거시 참고. 실제 CRTFLineSpacer::LineSpacingAuto는 일반문단의 최대 글꼴 높이×선택%, 표 내부는 선택값과 관계없이115%. 줄간격0은 원본서식 유지. 전체 라벨 이미지/영양성분표/글자크기를 비례 확대하는 방식은 사용하지 않는다.
- 구현: 공통 labelSheetWithOutputLineSpacing으로 출력 복사본의 일반문단 행 높이·inline lineHeight를 계산. 테두리/다중셀/세로병합 및 명시RTF table cell은 표로 취급해115%, 표 행높이는 보존. RTF parser가 borderless 단일셀 표도 marker로 보존한다. RTF anchor 이미지 위치만 flow에 맞추고 일반 절대좌표 이미지/선/도형은 그대로 둔다.
- Windows/EZPL preparation과 PDF/bitmap capture 모두 같은 복사본 사용. captureRangeAsPng에 sheetOverride를 추가해 원본controller를 바꾸지 않는다. preview는 동일 helper + 줄간격별 Workbench key로 갱신하고 external zoom/capture owner는 유지. Workbench initialWorkbook은 초기화 전용이므로 key 갱신이 필요함을 UI 회귀로 확인했다.
- 최종102/102 통과: focused6건 포함8파일88건 + RTF import/기존 paragraph 관련14건.80/300 행8/30, table18 유지/115%, native text 위치·font 유지, 줄바꿈/혼합폰트, none/0 원본보존, borderless RTF marker save roundtrip, 반복적용 idempotence/RTF anchoring, G500 native+bitmap PNG차이/PDF·EZPL 동일행/preview80→300→80→none/zoom150 유지. 표 내부native descriptor 높이/폰트 동일 및 표 위치만 문단flow에 따라93dots가량 이동하는 assertion도 통과.
- 변경6 Dart analyzer/IDE는 기존 print_job2+canvas10 unused 경고뿐 오류/신규 진단 없음; 나머지4파일 analyzer `No issues found`. DTD발견·이미 연결 상태 확인 후 hot reload 시도했으나 실행 중 앱 없음.
- 버전1.8.7→1.8.8 PATCH: 기존 자동줄간격이 문단 위치에 반영되지 않는 버그 수정. README에 legacy115% 표 규칙/원본서식/잘림/출력준비 계약 기록. 기존 row 설정 우선순위 및 raw 저장값/DB/실제 인쇄 금지 유지. 사용자 app.dart만 기존 dirty.
- 다음 사용자 확인:1.8.8 실행→해당 브랜드/80×60 라벨→첫 품목 발행체크→프린터 설정80%/300% 적용→미리보기 문단 간격 변화와 표 크기 유지 확인 후 승인된 환경에서 G500 실인쇄 비교.300%에서 라벨 영역을 넘는 내용은 레거시처럼 잘릴 수 있다. 원본서식을 원하면 설정 안 함 선택. 단, 품목 고정 줄간격/목록 직접 수정 값이 있으면 그 값이 프린터 기본값보다 우선한다.

## 최근 완료: 라벨출력 미리보기 프린터 밀기 설정 미반영
- **구현·검증·커밋 완료: `34fb0bd` (1.8.7). push하지 않음.**
- 제출 `라벨출력_미리보기_프린터설정미적용.log`는1.6.0. 사용자 추가 요청: 왼쪽 한정이 아닌 모든 밀기(왼쪽/위쪽, 양수/음수)를 공통 확인.
- 원인: 설정 적용은 session rows를 갱신하지만 `_buildLabelPrintPreview`는 row의 위치조정값을 `_ItemOutputPreviewTab`에 전달하지 않는다. 실제 발행은 `_labelPrintOptions`의 row.leftPushMm/topPushMm를 layout에 적용한다.
- 구현: Home→ItemOutputPreviewTab→LabelOutputPreview→Workbench→FortuneSheetApp/Canvas/Painter에 display-only outputPreviewOffset 전달. actual print/validation/preview는 추출한 labelPrintOptionsForRow와 기존 LabelSheetPrintLayout 위치 계산을 재사용. 셀·이미지/바코드·선·도형·raw shape overlay의 표시좌표만 조정하며 ruler/페이지경계/원본workbook/capture는 유지한다.
- 새 focused UI·pixel 회귀1건 통과: 실제 프린터 설정창 왼쪽+5/위쪽-5 적용, 양쪽축±5/조합/0 복원, 모든 typed content의 위치 실측, 눈금자pixel 동일, raw capture bytes 동일, Windows driver 준비에서+5mm=19dots@96dpi를 한 번만 적용, itemOverride와 sessionEdited 두축 우선순위/zoom 유지. 초기 fixture의 SharedPreferences mock/자동fit 예상값만 보강했으며 제품 로직 추가 수정 없음.
- 최종 관련7파일131/131 통과(신규3건): preview/session/settings/pipeline/print job/barcode14/object controller50. 실제 native barcode encoder 모드 사용. 추가 clipping/100·200% zoom/shouldRepaint 회귀 완료. 새 standalone fixture에 labelSize를 명시해 Workbench 기본100×100이 아닌80×60을 검증하도록 보강했으며 제품 로직 수정은 추가하지 않았다.
- 변경7 Dart analyzer `No issues found`; canvas 포함8파일은 알려진 기존 unused10건만 있고 오류/신규 진단 없음. 변경8 Dart+pubspec IDE diagnostics 정상. 새 테스트 파일만 formatter 실행.
- 레거시 PrintManager.cpp336~337도 margin+push, ZoomPreviewView는 양축push를 공통preview에 전달. 메뉴얼은 프린터 여백/줄간격 및 라벨초과 잘림을 안내하고 별도 밀기 세부 설명은 없다.
- 버전1.8.6→1.8.7 PATCH: 기존 라벨출력 미리보기 밀기 연결 누락 수정. README에 양축·부호·잘림·원본capture 분리 및 테스트 안내 기록. DB/실제 인쇄 금지, 사용자 app.dart 제외. DTD발견·이미 연결 상태 확인 후 hot reload 시도했으나 실행 중 앱 없음.
- 다음 사용자 확인:1.8.7 실행→해당 품목 발행체크→라벨출력→프린터 설정 왼쪽/위쪽 각각0→5→-5→0 및 조합 적용→내용만 이동하고 눈금자/라벨크기/확대가 유지되는지 확인. 품목별 여백 사용 또는 목록 직접 수정 시 그 값이 기본 프린터 설정보다 우선하는 기존 동작은 유지된다. 실제 인쇄는 미수행.

## 최근 완료: 바코드 속성의 비율 유지 선택 옵션
- **구현·검증·커밋 완료: `85e50c3` (1.8.6). push하지 않음.**
- 첨부 화면 확인. 삽입창에는 비율유지 토글이 있지만 속성에는 이미지 kind에만 체크박스를 표시한다. 실제 속성의 폭/높이 비율 적용 로직·동일 개체 적용 후 체크상태 보존 로직은 바코드에도 이미 공통 적용된다.
- 이미지와 같은 체크박스를 바코드에도 노출하고 기존 기본값ON/선택 개체의 현재 비율 기준/마지막 수정 치수 기준 적용/해제 시 독립 치수/바 높이 별도 설정 계약을 유지한다. 로컬 편집 옵션이며 저장 포맷·DB 변경 없음.
- 코드 수정은 체크박스의 이미지kind 한정 조건 제거뿐. 기존 비율 계산/렌더/권한/상태 유지 로직을 그대로 사용한다.
- 수정 전 새4회귀에서 체크박스 없음 실패 확인. 수정 후4/4 통과: 1D·QR × mm·px, 기본ON→폭40시높이20→높이15시폭30→해제폭50/높이15→해제상태유지→높이25/폭50→재체크폭60/높이30→회전1 치수유지→저장/undo/redo. 실제renderer request와 canonical 치수까지 검증하고 별도 바 높이10 유지도 확인.
- 버전1.8.5→1.8.6 PATCH: 기존 속성 비율유지 기능의 바코드 UI 노출 누락 수정. README에 적용 시 연동·로컬 옵션·바 높이 독립 동작 기록. 사용자 app.dart 보존·제외, DB/인쇄 변경 없음.
- 전체 회귀 첫 실행62통과/2실패는 새 행 추가로 기존 테스트의 화면 밖 lazy 데이터 입력란이 생성되지 않은 경우였다. 기능코드는 추가 변경하지 않고 해당2테스트만 필드 기준 스크롤로 보강했다. 최종 실제native encoder 모드64/64통과(바코드14+object controller50), 신규4건. 이미지 비율유지·바코드 속성실패/선택변경/권한차단/이전 높이·회전 회귀 유지.
- 변경 Dart3파일 analyzer 및 IDE/pubspec diagnostics 모두 정상. DTD 발견/연결 확인 후 hot reload를 시도했으나 실행 중 앱 없음. DB/실제 인쇄/배포파일 생성 없음.
- 다음 사용자 확인:1.8.6 실행→바코드 선택→폭·높이 아래 비율유지 체크/해제→치수 입력 후 적용. 해제 시 한 치수만 수정해 다른 치수가 유지되는지, 재체크 후 비율 적용/저장·재열기 확인.

## 최근 완료: 복제 바코드의 회전 속성 적용 시 막대 높이 축소
- **구현·검증·커밋 완료: `ebdca07` (1.8.5). push하지 않음.**
- 제출 `공용라벨_바코드속성_서식오류.log`는1.6.0. 첨부 이미지에서 회전0→1만 변경했는데 막대 높이가 약1/3.78로 줄어듦.
- 원인 확인: mm 라벨 삽입은 barcodeBarHeight를mm로 저장하지만 속성 패널은 단위 변환 없이renderer에 논리px로 전달한다. 속성 저장은 다시px로 저장해 metadata 계약까지 바뀐다. geometry width/height는 이미 올바르게 변환한다.
- 수정 전 실제UI 복제→회전1 적용에서 renderer.barHeight 기대37.795px/실제10px 실패, px 라벨은 통과. 속성 panel 숫자 읽기와 저장을 라벨 단위에 맞췄으며 공통 unit resolver를 품목 미리보기/EZPL 준비에도 연결했다. 바 높이 입력에도 mm/px 접미사 표시.
- RTF import는 기존부터 metadata가px인 점을 실제 import 코드에서 확인해 `rtfBarcodeDecoded` 경로는px 계약을 유지한다. 별도 schema/unit marker나 모호한 기존 데이터 추정 변환은 추가하지 않았다. 회전만 바꿔도 이미 손상된 과거 데이터의 원래 막대 높이를 복구하지는 않는다.
- portable10건 통과: 기존5 + 실제 복제/회전1→2 재적용/치수·잉크 높이/저장/undo·redo의mm·px·RTF3건 + 일반·RTF의 품목 미리보기 request와 native command높이10mm=80dots@203.2dpi2건. controller 전체·print job전체 포함3파일89건 통과. 실제 인쇄 없이 명령 준비까지만 검증.
- native encoder모드42건도 통과: 새10건+barcode dialog/toolbar의 관련32건. 중복 제외 전체 관련121건(89+32), 신규5건. `BARCODE_HEIGHT_NATIVE=true`와 기존 DLL의 프로세스 PATH를 사용했으며 DLL/설정 변경 없음.
- analyzer5파일: 오류/신규 진단 없음. 기존 canvas unused10건 + print job의 기존 `_unusedDarkBandCheckerboard`/`_unusedFeedLeadWhiteRelief`2건 경고만 존재(HEAD 원본 확인). 신규 테스트/패널/Home3파일만 분석은 `No issues found`.
- 버전1.8.4→1.8.5 PATCH: 속성 렌더링 시mm/px 혼동 수정. 저장 포맷 변경 없음. README 갱신. DTD발견·연결 확인 및hot reload 시도했으나 실행 중 앱 없음. 기존 사용자 app.dart 보존·제외, DB/실제 인쇄 금지.
- 다음 사용자 확인:1.8.5 실행→test/testflutter→연결 안함1234/20×10mm 삽입→선택한 개체 복제→회전0→1 적용→높이 유지 확인. 회전2 재적용/저장·재열기/품목 미리보기도 확인.

## 최근 완료: 최초 바코드 삽입 시 세로 10mm/20mm 표시 동일
- **구현·검증·커밋 완료: `bce0749` (1.8.4). push하지 않음.**
- 제출 `공용라벨_바코드삽입_세로길이오류.log`는1.6.0. 연결 안함/1234/가로20/비율해제에서 세로10과20의 막대 높이가 같은 현상. 세로 입력은 전달되지만 별도 `바코드 높이` 기본10이 그대로여서 renderer가 나머지를 빈 공간으로 남긴 것이 원인.
- 사용자 `sync-height` 선택: 세로를 바꾸면 바코드 높이도 같은 값으로 변경하고, 이후 바코드 높이를 직접 입력하면 그 값을 사용한다. 비율유지 가로→세로 변경도 같은 helper로 동기화. 비율해제 시에는 가로를 유지한다. 빈값/0 입력은 바코드 높이를 덮어쓰지 않는다.
- 변경 production 파일은 `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 한 곳. 2D 모듈 설정, 기존 저장 데이터 로드, renderer, 저장 포맷/DB/인쇄 경로는 변경하지 않았다. 문자 표시 시 전체 높이 안에 문자 영역을 확보하는 기존 동작도 유지.
- 레거시 `BarcodeImageKeywordModifyDlg.cpp`의 width/height 입력→InsertBarcode 저장 계약 확인. 메뉴얼v2에서 Flutter 삽입창의 별도 높이 설정에 대응하는 설명은 확인되지 않음.
- 수정 전 실제 UI 회귀3건에서 바코드 높이 기대20/실제10 실패 재현. 수정 후 새 회귀5건 portable 통과 및 실제 native encoder 모드 포함 관련37건 통과. 10mm=38px/20mm=76px의 실제 PNG 막대 높이, px 단위10/20, 저장·재읽기/undo·redo, 비율연동, 명시7mm 우선, 문자 표시/본문 비율 저장, QR 크기·모듈 유지 검증.
- 새 테스트 analyzer/IDE와 pubspec 진단 정상. canvas에는 알려진 기존 unused 경고10건만 존재(복사필드3/coord2/옛 편집메서드2/옛 layer mutation3). 오류/신규 진단 없음. 큰 vendor 파일 전체 format은 하지 않았다.
- DTD 발견·연결 확인 및 hot reload 시도했으나 실행 중 앱 없음. 운영 DB 변경·실제 인쇄·설치파일 생성 없음.
- 버전1.8.3→1.8.4 PATCH: 기존 삽입 높이 입력의 연동 누락 수정. README에 동작 및 portable/native 회귀 실행법 기록.
- 다음 사용자 확인:1.8.4 실행→test/testflutter→공용라벨에서 연결 안함/1234/비율해제/가로20/세로10과20 삽입→막대 높이가 다른지 확인. 별도 바코드 높이 직접 입력, 저장 후 재열기, 품목 미리보기도 확인.

## 회귀 실행
- 일반: `C:\Flutter\bin\flutter.bat test --no-pub test\label_sheet_barcode_height_test.dart`.
- 기본 테스트는 native encoder만 테스트 패턴으로 대체하고 production geometry/PNG 합성으로 실제 잉크 높이를 측정해 DLL 없는 환경도 지원한다.
- 실제 인코더: Windows 빌드의 `flutter_zxing.dll` 폴더를 해당 프로세스 PATH에 추가하고 `--dart-define=BARCODE_HEIGHT_NATIVE=true`로 같은 테스트 실행. 이번에는 기존 `build\windows\x64\runner\Debug` 사용. DLL/설정 파일은 복사·변경하지 않았다.
- 최종 관련37건: native 모드의 새 테스트 + `third_party\fortune_sheet\test\fortune_barcode_dialog_test.dart` + `test\label_sheet_toolbar_test.dart`, `--name 'barcode|bar height|QR '`. 기존 renderer의 별도 바코드 높이 계약과 품목 미리보기 오류/로딩 해제도 포함.

## 최근 완료
| 버전 | 변경 | 기능 커밋 |
|---|---|---|
| 1.8.3 | 이미지30→31 적용 후 항목편집32 저장51113: persistedWidth/Height 분리, pending 크기 포함, 성공한 제출 snapshot만 baseline 승격.108건 통과 | a427d7f |
| 1.8.2 | 연결 이미지 변경 시 공용 편집 화면도 현재 선택 품목의 draft/저장 이미지 표시. 표시용 source만 치환하고 canonical src/품목별 발행 분리 유지.82건 통과 | a7d9415 |
| 1.8.1 | 이미지 파일 교체에도 기본 picker fallback 적용.취소/오류/undo/속성 보존.57건 통과 | 0f2f7a1 |
| 1.8.0 | 기본 항목 사용자 정의 text 출력, 키워드 더블클릭/드래그 삽입, 보라색 참조 표시.품목 원본 유지·단일 치환.349건 통과 | 379b3b2 |
| 1.7.3 | 필수등록 로컬 토글을 DB original로 오인한51115 수정. persistedMissingKeywordCheck 분리.96건 통과 | 4e7b0c5 |
| 1.7.2 | 영양성분표 확대 시 입력 초기화 및 배율 Enter 오저장 수정.112건 통과 | 4041c11 |
| 1.7.1 | 영양성분표 Future 전환 중 이전 snapshot 사용 차단.30건 통과 | d457042 |
| 1.7.0 | 승인된 발행내역 인덱스 확인·자동 생성·대기 UI.약97,872ms→26ms | f0ecdc3 |
| 1.6.2 | 사용자 추가의 없는 ID 조회/예외 범위 수정.38건 통과 | 02d7000 |
| 1.6.1 | 연결 바코드 미리보기의 완료 null 결과를 무한 로딩으로 오인한 문제 수정.32건 통과 | 23473f2 |

## 보존할 상태 및 주의
- 상시 규칙은 [SESSION_RULES.md](SESSION_RULES.md). 작업 완료 시 관련 변경만 검증·버전 갱신·커밋, 기능 해시를 기록하는 후속 handoff 커밋은 버전 추가 증가 없음. push하지 않음.
- 사용자 기존 `lib/core/app.dart` 변경은 수정·원복·stage/commit하지 않는다. 이번 시작 시 다른 사용자 dirty 파일 없음.
- 승인 없는 운영 DB 변경/실제 인쇄 금지. SQL Server2017 및 실제 DB 호환성100 유지.
- 이전에 승인받아 생성한 `IX_BM_RICH_PRINT_LOG_CustomerDate`는 DB에 남아 있다. keys `(RICH_CUSTOMER_ID,RICH_DATE_YYYYMMDD)`, INCLUDE `RICH_DATETIME`.
- Flutter 테스트 프로세스를 동시에 실행하지 않는다(test_cache 충돌). spinner 뒤 모달은 bounded pump 사용. lazy 속성 패널은 해당 ListView를 명시적으로 스크롤한다.
- 기존 unrelated 실패: ANSI RTF 변환 딸기→딪기, LoginLogDAO의 IP truncate 계약. 이 요청에서는 수정하지 않았다.
- 수천 줄로 누적됐던 과거 완료/실험 상세는 이번에 정리했다. 필요한 이력은 이 파일의 `bb7fa6e` 및 이전 Git 버전/각 기능 커밋으로 추적한다.

## 남은 별도 이슈: GoDEX G500 역상 흰 획 소실
- **미해결**. 사용자 새 증상을 먼저 처리한다. 인쇄 원본은 라벨 시트이며 RTF 직접 출력/시트의 RTF 재변환으로 돌아가지 않는다.
- 1.3.129의 native 드라이버 PRN 생성→원본 바이트 RAW 제출은 배치 중복/분할 개선 근거일 뿐 역상 품질 해결 근거가 아니다. 이전 RAW 인쇄 승인은 해당1회에 한하며 추가 인쇄는 매번 승인을 받는다.
- 파일 재생에서 역상 흰 픽셀1,266/1,427, 손실0이었지만 실제 종이 결과와 동등함을 보장하지 않는다. 시트 요청/드라이버 PRN/RAW/실물을 구분해 판정한다.
- DisplayBand,120/121twip 반올림,회색조/팽창,공백 장평,농도·속도,DirectWrite/GGO/FreeType,whole-page EMF 등 이미 실패한 접근을 반복하지 않는다. 저장 시트 글자 강제 확대/재생성·저장도 하지 않는다.
- 세부 재개 지점은 [doc/godex_inverse_resume.md](doc/godex_inverse_resume.md) 및 Git 이력. 과거 기록상 증거는 `.tmp/IMG_20260912_0007.png`, `.tmp/IMG_v0.Legacy_print.png`, `.tmp/log/app_2026-09-12_20-56-09.log`이며 이번에는 존재/내용을 다시 검증하지 않았다.
- `IMG_20260912_0006.png`, `actual_request_v127_replay.prn`, `img0006_driver_v129.prn`, `v1.3.127_1789202935380639_0.bin`은 이전 정리 시 없었다. 오래된 파일/픽셀 기록을 현재 재검증 결과로 표현하지 않는다. `.tmp` 증거는 Git 포함/외부 전송 금지.
