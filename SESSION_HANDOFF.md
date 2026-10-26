# SESSION HANDOFF

## 현재 작업: 공용라벨 필수등록 체크 후 항목편집 해제 저장 오류
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
