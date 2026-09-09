# G500 역상 출력 재개

## 작업 순서
1. 새 세션에서는 사용자가 제시하는 앱 오동작부터 디버깅한다. 현재 증상/재현 절차는 미전달이며, 인쇄 문제와의 연관성도 미확인이다.
2. 앱 오동작 수정과 검증을 완료한 뒤 이 문서로 돌아온다. 인쇄 코드를 함께 수정하지 말고 두 작업의 원인/검증/커밋을 구분한다.
3. 아래 증거 기준 이후의 사진과 로그가 있으면 먼저 확인한다. 없으면 다음 사용자 출력에서 v1.3.97 이후의 후속 합성 진단을 확보한다. 자동 실물 인쇄는 하지 않는다.

## 현재 기준
- 구현 커밋: `d0ade63` (v1.3.97 후속 검정 글자 합성 진단), 인수인계 커밋: `a0f3a1e`.
- 마지막 확인한 실행: Debug EXE v1.3.97, 당시 PID 8452, 응답 및 DB 연결 성공. 현재도 실행 중이라고 가정하지 않는다.
- 시작 로그: [.tmp/log/app_2026-09-08_23-25-53.log](../.tmp/log/app_2026-09-08_23-25-53.log).
- 이번 핸드오프 정리로 pubspec만 v1.3.98이 된다. 빌드하지 않았으므로 EXE/native 인쇄 마크는 마지막 확인 기준 v1.3.97이다. 향후 앱 버전과 인쇄 실험 마크를 구분해 기록한다.
- 미해결: 검정 띠 안 작은 흰 한글 획 소실. v1.3.97은 관측 보완이며 품질 수정 완료가 아니다.
- 유지 조건: 일반 글자/표선은 v1.3.58 기준. GoDEX G500, USB001, 80x60mm, 약 203dpi. source640x480 -> target620x480, physical640x480, offset10,0, destination0,0.

## 마지막 분석 증거
- 실물 [.tmp/IMG_20260908_0005.png](../.tmp/IMG_20260908_0005.png): v1.3.96에서도 흰 획 소실 지속. 오른쪽 흰 사각형과 끝 문구 미수용은 이전 수정으로 해소됐으나 획 품질은 미해결.
- 로그 [.tmp/log/app_2026-09-08_22-39-21.log](../.tmp/log/app_2026-09-08_22-39-21.log), 출력 시각 23:18:55: `rasterBitCount=1`, 전체 문자 수용, `nativeTextWhiteDirectDrawn=0`, `nativeBordersDrawn=225`.
- 역상 1: [.tmp/log/godex_inverse/v1.3.96_4180_11669359_1.txt](../.tmp/log/godex_inverse/v1.3.96_4180_11669359_1.txt). clip15,90,600,109 / font17dot / layout636 / scaleX .919811 / input72 / formatted73 / changed1298.
- 역상 2: [.tmp/log/godex_inverse/v1.3.96_4180_11669390_2.txt](../.tmp/log/godex_inverse/v1.3.96_4180_11669390_2.txt). clip15,291,600,310 / layout616 / scaleX .949675 / input75 / formatted76 / changed1508.
- 각 TXT와 같은 접두사의 `.emf`, `_base.bmp`, `_comparison.bmp`를 보존한다. 라벨 내용이 있는 로컬 자료이므로 외부 전송하지 않는다.
- 레거시 정상 사진 [.tmp/Legacy_print.png](../.tmp/Legacy_print.png)는 같은 PC/프린터 기준이다. 현재 앱에서 동일 레거시 라벨을 출력할 수 없다는 사용자 조건을 유지하고 동일 라벨 재출력을 반복 요구하지 않는다.

## 실제 코드 경로
- [windows/runner/label_bitmap_print_channel.cpp](../windows/runner/label_bitmap_print_channel.cpp): `PrintBitmap`이 출력 순서를 결정한다.
- `ComposeFinalDeviceBitmap`: 기본 raster와 225개 native border 합성.
- `RenderWhiteTextIntoBitmap`: 투명 RICHEDIT50W, 굴림17dot Bold 흰 글자, 검정 배경. printer-reference EMF에 역상만 렌더한다.
- [windows/runner/inverse_text_layout.h](../windows/runner/inverse_text_layout.h): `MeasureInverseTextLayout`이 printer DC로 필요한 한 줄 폭을 측정하고 X축만 축소한다. Y/높이 유지, wrap/명시적 개행은 무보정.
- [windows/runner/inverse_text_bitmap.h](../windows/runner/inverse_text_bitmap.h): `CompositeInverseTextBitmap`이 EMF를 1bpp DIB에 직접 재생한다. 역상 clip만 32bpp base에 복사, 바깥과 alpha 보존. 글리프 후처리 threshold 없음, 초기 base 변환에만 128 사용.
- 기존 단일 32bpp `StretchDIBits`로 printer DC에 전송한 뒤 흰 descriptor를 제외한 `RenderNativeTextToPrinterDc`의 검정 `DrawTextW`, 마지막 워터마크를 출력한다.
- `CaptureNativeTextComparison`: 실제 검정 출력 성공 후 같은 함수를 참조 EMF에 실행한다. [windows/runner/native_text_comparison.h](../windows/runner/native_text_comparison.h)의 `ReplayNativeTextComparison`으로 base 위에 재생하고 역상별 흰->어두운 픽셀 수를 센다. 실제 출력 비트맵이나 printer DC를 변경하는 보정은 아니다.

## 다음 판별
1. 최신 로그와 사진에서 실제 실행 버전/인쇄 마크를 확인한다. 최신 로그는 파일명 시각 기준으로 찾고 전체를 무작정 출력하지 않는다.
2. `.tmp/log/godex_inverse/*_after_native.txt`와 같은 접두사 BMP/EMF를 확인한다. 아직 이 문서 작성 시 새 진단의 실제 출력 생성/손실 수는 분석되지 않았다.
3. `referenceDrawn/Fitted`와 실제 `nativeTextDrawn/Fitted`를 비교한다. 실제 drawn에는 역상 2건도 포함될 수 있으므로 검정 descriptor 수를 따로 계산한다. 측정 차이가 있으면 같은 결과라고 단정하지 않는다.
4. `inverse[index].whitePixelsLost` 및 `native[index].sourceRect`, BMP를 함께 확인한다. 수치는 원래 흰 픽셀이 후속 합성 후 휘도128 미만으로 바뀐 수이다.
5. 손실이 있으면 실제 겹치는 descriptor/최종 DrawText 영역을 먼저 조사한다. 검정 글자의 기본 DrawText clip도 있으므로 역상 제외 clip이 없다는 사실만으로 덮임 원인이라고 판단하지 않는다.
6. 손실이 0이면 참조 재생에서 덮임을 재현하지 못한 것이다. 바로 열 번짐/드라이버 결함으로 확정하지 말고 참조와 실제 출력의 차이를 다음 국소 가설로 좁힌다. 근거 없이 폰트/농도/threshold를 다시 순환 변경하지 않는다.

## 진단 한계
- `_comparison.bmp`는 실제 합성 base이지만 일반 검정 native text/워터마크 이전이다. 뒤 역상 파일에는 앞 역상이 포함될 수 있다.
- `_after_native.bmp`는 검정 text까지 포함한 별도 참조 재생이다. 실제 전송 비트맵/스풀 캡처가 아니며 워터마크도 없다. EMF DC와 printer DC의 폰트 측정 차이 가능성을 남긴다.
- `EM_FORMATRANGE` 반환값은 boolean이 아니라 문자 위치이며 종결 문단 때문에 입력 길이+1이 가능하다. accepted=true, descriptor 성공 수, 전체 문자 수용은 실물 획 품질을 입증하지 않는다.
- 레거시 RTF 5pt -> 현재 descriptor11dot(레거시 물리 기대14dot) 차이는 characterization으로 재현됐지만 이번 실제 출력은17dot이다. 확정 원인으로 사용하지 않는다.

## 실험 이력 요약
| 기준 | 확인 결과 |
| --- | --- |
| v1.3.94 / 4bc31d4 | WS_EX_TRANSPARENT로 줄 끝 흰 채움 제거, 측정 폭/X축 fit으로 전체 문구 수용. 획 소실은 지속. |
| v1.3.95 / fb01e91 | 역상 EMF를 base에 합성. EMF 헤더 frame 기준 재생으로 약0.54% X 확대 오류 교정. 획 소실 지속. |
| v1.3.96 / 5c62559 | 글리프를 직접1bpp로 렌더. 물리 결과 IMG0005에서 획 소실 지속. |
| v1.3.97 / d0ade63 | 검정 글자 후속 합성 관측 추가. 실제 출력 진단 분석 대기. |

- DirectWrite/GGO/FreeType/supersample/마스크 팽창, direct-white, 전체 페이지 EMF/1bpp, EZPL Q/펌웨어 역상, 농도·속도·회색·checkerboard·냉각행 실험은 실패 이력이 있다. 과거 코드를 새 해결책처럼 재사용하지 않는다. 상세는 git history로 조회한다.
- SES_EXTENDBACKCOLOR/EM_SETTARGETDEVICE(0)만으로 폭 미수용을 해결하지 못했다. NULL DC EnumEnhMetaFile callback 재생도 worldtransform 명령에서 실패했다.
- 소프트웨어 개선 불가/열 번짐 확정이라는 과거 판정은 철회됐다. 일반 표선을 capture에 있다고 가정하고 native border 합성을 끄는 회귀도 반복하지 않는다.

## 검증과 실행
- 마지막 구현 검증: native CTest 1/1, 관련 Dart31건, Windows Debug `/WX` 빌드 성공. 합성 검사에서 3x3 겹침=9/비겹침=0, 좌표 및 alpha 보존 확인. 실제 출력 진단과 품질 개선은 별도 미검증.
- probe는 Godex G500 printer DC를 사용하되 StartDoc 없이 동작한다. 설치된 프린터/폰트가 필요하다. 옵션과 한계: [tools/inverse_rich_edit_probe/README.md](../tools/inverse_rich_edit_probe/README.md).
- PowerShell, 저장소 루트에서 실행할 명령:

```powershell
& 'C:/Program Files/Microsoft Visual Studio/2022/Professional/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe' --build .tmp/inverse_probe_build --config Debug
& 'C:/Program Files/Microsoft Visual Studio/2022/Professional/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/ctest.exe' --test-dir .tmp/inverse_probe_build -C Debug --output-on-failure
C:/Flutter/bin/flutter.bat test test/godex_inverse_reference_test.dart test/label_sheet_print_job_test.dart test/label_print_dispatcher_test.dart
$env:CL='/WX'; C:/Flutter/bin/flutter.bat build windows --debug
```

- native 변경은 hot reload만으로 반영되지 않는다. 기존 실행 프로세스 확인 후 Debug 재빌드/재실행 및 새 시작 로그 버전 확인. Dart 변경은 DTD 앱 연결/재시작 절차도 따른다.
- 배포 빌드/설치파일/원격 push/DB migration/프린터 설정 변경은 하지 않는다. 기존 [lib/core/app.dart](../lib/core/app.dart) 변경은 임의 원복하거나 섞어 커밋하지 않는다.
- `.tmp` 사진/진단/probe/캐시는 재개 자료로 보존하며 stage하지 않는다. 비밀번호 등 접속 비밀은 문서/로그에 재기록하지 않는다.
- 상시 규칙은 [SESSION_RULES.md](../SESSION_RULES.md), 현재 우선순위는 [SESSION_HANDOFF.md](../SESSION_HANDOFF.md)를 따른다.