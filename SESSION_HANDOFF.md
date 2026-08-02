# 현재 작업 상태

## 완료·실물 검증 대기: Godex G500 획 연결성 보존 출력 v1.0.34
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
