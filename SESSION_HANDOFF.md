# SESSION HANDOFF

## 새 세션 시작 순서
1. 사용자가 새로 제시하는 디버깅 증상을 먼저 조사한다. 증상이 제시되기 전에는 과거 문제를 현재 문제로 가정하지 않는다.
2. 새 디버깅을 마친 뒤 GoDEX G500 역상 흰 획 소실 문제를 재개한다.
3. 인쇄이거나 DB 변경이 필요한 재현은 사용자 승인 없이 실행하지 않는다.

## 현재 기준
- 문서 정리 버전은 **1.3.130**이며 인쇄 동작 변경은 없다. 직전 인쇄 구현 기준은 **1.3.129**다.
- 정리 전 HEAD는 `3e188cd`, GoDEX 전송 변경 기능 커밋은 `d3b682c`, 새 세션용 정리 커밋은 `0c79b52`다. 이 해시 기록은 같은 요청의 후속 문서 변경이며 버전을 다시 올리지 않는다.
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 원복하거나 함께 stage/commit하지 않는다.
- 실행 중인 `label_manager`/`flutter` 프로세스는 없다. Windows 배포파일과 설치파일은 만들지 않았다.
- 현재 실제 인쇄 원본은 **라벨 시트**다. RTF 직접 출력이나 시트의 RTF 재변환을 제안하거나 구현하지 않는다.

## 최근 완료: GoDEX PRN 생성 후 RAW 제출
- 1.3.129부터 GoDEX는 기존 native 렌더링으로 드라이버 PRN을 만든 뒤 그 바이트를 변경 없이 `RawPrinterWin32.sendRaw`로 제출한다. 다른 제조사는 기존 직접 GDI 제출을 유지한다.
- 정상 직접 GDI 제출에서 발생한 제조사 문구 반복 및 하단 영양정보 분할/중복은, 사용자에게 한 차례 승인받은 동일 PRN의 RAW 제출에서는 정상 배치로 출력됐다.
- PRN 누락, RAW 예외, 부분 쓰기는 성공으로 처리하지 않는다. Debug 파일 캡처도 인쇄 성공이나 이력 저장으로 처리하지 않는다.
- 검증 완료: 관련 테스트 **15/15 통과**, focused analyze 이상 없음, Windows Debug 빌드/실행, hot reload, runtime error 확인을 통과했다.
- 최근 남아 있는 앱 로그 [`.tmp/log/app_2026-09-12_20-56-09.log`](.tmp/log/app_2026-09-12_20-56-09.log)은 `DebugLogger version: 1.3.129`, `driverPrnGenerated=true`, `driverTransport=generatedPrnRaw`, `driverTransportVersion=1.3.129`, `accepted=true`를 기록한다.
- 이 결과는 **레이아웃 손상 해결** 근거다. 역상 흰 획 품질까지 해결됐다고 판단하지 않는다.

## 역상 문제 상태
- **미해결**이다. 같은 PC/GoDEX G500에서 레거시는 정상이나 현재 시트 출력은 역상 흰 획 일부가 종이에서 사라졌다.
- 실제 전체 요청을 파일/PRN 경로로 재생했을 때 두 역상 영역은 흰 픽셀 1,266/1,427개, 손실/증가/차이 0이었다. 파일 생성까지는 온전했지만 당시 직접 GDI 물리 출력에서 손실이 남았다.
- 1.3.129 PRN→RAW 경로의 역상 품질은 확인되지 않았다. 앞선 RAW 출력 승인은 해당 1회뿐이며 이후 물리 출력 권한으로 재사용하지 않는다.
- DisplayBand, 120/121 twip 반올림, 회색조/팽창, 공백 장평, 농도·속도, DirectWrite/GGO/FreeType, whole-page EMF 등 이미 부정되거나 실패한 접근을 반복하지 않는다.
- 레거시 자료를 다시 요구하거나 RTF를 출력 원본으로 되돌리지 않는다. 저장 시트의 글자 크기 강제 확대·재생성·재저장도 하지 않는다.
- 세부 과거 실험과 제어 코드 경로는 [`doc/godex_inverse_resume.md`](doc/godex_inverse_resume.md) 및 Git 이력을 참고하되, 오래된 문서의 파일 존재·현재 버전 설명은 다시 확인한다.

## 현재 남은 증거
- 현재 존재: [`.tmp/IMG_20260912_0007.png`](.tmp/IMG_20260912_0007.png), [`.tmp/IMG_v0.Legacy_print.png`](.tmp/IMG_v0.Legacy_print.png), [`.tmp/log/app_2026-09-12_20-56-09.log`](.tmp/log/app_2026-09-12_20-56-09.log).
- 현재 없음: `IMG_20260912_0006.png`, `actual_request_v127_replay.prn`, `img0006_driver_v129.prn`, `v1.3.127_1789202935380639_0.bin` 및 요청 캡처 디렉터리 내용.
- 없는 자료의 과거 해시·픽셀 검증은 완료 당시 기록일 뿐 현재 재검증했다고 표현하지 않는다. `.tmp` 파일은 Git에 포함하거나 외부 전송하지 않는다.

## 재개 시 판별 절차
1. 새 디버깅 요청의 구체 증상, 재현 절차, 최신 로그부터 확인한다. 로그는 최신 `.tmp/log/app_*.log`의 버전을 먼저 확인한다.
2. 역상 재개 시 1.3.129 이상 정상 앱 출력 로그에서 `driverTransportVersion=1.3.129`, `driverPrnGenerated=true`, RAW 전체 쓰기 성공을 확인한다.
3. 사용자가 관련 실물 결과를 제공했을 때만 RAW 경로의 역상 품질을 판정한다. 새 물리 출력이 필요하면 매번 먼저 승인을 받는다.
4. 실패가 남으면 시트 요청 생성, 드라이버 PRN, RAW 제출, 종이 결과 경계를 분리한다. 과거 파일 보존 결과만으로 USB/종이 동등성을 주장하지 않는다.

## 검증 기준
1.3.129 인쇄 변경에 사용한 focused 검증:

```powershell
C:/Flutter/bin/flutter.bat test --no-pub test/windows_bitmap_printer_test.dart test/label_print_dispatcher_test.dart
C:/Flutter/bin/flutter.bat analyze --no-pub lib/printing/windows_bitmap_printer.dart test/windows_bitmap_printer_test.dart
```

이번 1.3.130 변경은 문서/버전 정리만 수행했다. 문서·pubspec diagnostics와 `git diff --check`는 통과했다. 코드 테스트·앱 실행·실물 인쇄는 다시 하지 않았다. `SESSION_HANDOFF.md`와 `pubspec.yaml`만 stage/commit한다.