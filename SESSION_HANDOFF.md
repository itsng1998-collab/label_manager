# 현재 작업 상태

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
