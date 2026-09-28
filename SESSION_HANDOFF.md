# SESSION HANDOFF

## 현재 작업: GoDEX G500 역상 흰 획 소실
- **진행 중**: `1.4.30` PRN→RAW 실물 결과 `.tmp/IMG_20260926_0001.png`에서 두 검정 띠의 흰 한글 획 소실이 계속된 것을 확인했다.
- 대응 로그 `.tmp/log/app_2026-09-26_11-37-49.log`: `driverPrnGenerated=true`, `driverTransport=generatedPrnRaw`, 요청/쓰기 `35933/35933`, `physicalPrintSubmitted=true`로 PRN 생성과 RAW 전체 제출은 정상이다.
- 보존 PRN `.tmp/log/bitmap_print_requests/v1.3.127_1790390845521249_0.bin.prn` 해석 결과 두 역상 clip의 흰 픽셀은 각각 `1266/1427`, 손실·증가·차이 모두 `0`이다. 앱 합성/드라이버 PRN까지는 온전하고 종이 열전사 단계에서 소실된다.
- 과거 firmware `AZ1` inverse 실험 재검토: 공식 `At` 명령의 `x_mul/y_mul`은 최대 8인데 `v1.3.67/68` 구현은 `fontDots=17`을 두 배율 자리에 넣었다. 당시 전체 검정 결과는 잘못된 명령 인자로 format이 깨진 결과일 가능성이 있어 firmware inverse 자체를 유효하게 기각하지 못했다.
- 다음 액션: 이번 실제 PRN의 일반 출력은 유지하고 두 역상 영역만 검정으로 복원한 뒤, 설치된 16x16 Korean `Z1` 폰트에 올바른 `AZ1 ... 1,1,0,0I`를 추가하는 **무출력 진단 PRN**을 준비·검증한다. 실제 제출은 사용자 승인 전 실행하지 않는다.
- `tools/prepare_inverse_firmware_probe.ps1` 추가: 보존 PRN의 단일 Q payload를 검증하고 지정 역상 clip만 solid black으로 복원한 뒤, 배율 `1..8`을 강제한 CP949 `AZ1 ... I` 명령을 `E` 앞에 삽입한다. 기존 파일 덮어쓰기는 거부한다.
- `tools/inspect_inverse_driver_file.ps1`/`tools/test_inverse_driver_file.ps1` 보강: 올바른 `AZ1` inverse 명령을 파싱하며 해석기 회귀 **10/10 통과**.
- 무출력 진단 PRN 준비 완료: `.tmp/log/godex_inverse/inverse_firmware_fixed_20260926.prn`, 36,102 bytes, SHA256 `7360C9170A9EFBB41B...`. Q `10,11,76,472`, 역상 clip 2개, native inverse 4개 모두 구조 검증 통과했다.
- PC 캐시와 설치 표식 확인: `AZ_KO16x16.DAT` 282,127 bytes, SHA256 `90644349AE81C901...`; shared preferences에 `az1-korean-gulimche-16-v1` 설치 표식이 남아 있다. 프린터 메모리의 현재 존재 여부는 실물 진단 결과로 판별한다.
- 최초 진단 전 상태: 사용자 승인 전에는 진단 PRN을 제출하지 않았으며, 승인 후 아래 1매만 RAW 제출했다.
- 사용자 승인 후 진단 PRN 1매를 `Godex G500`/`USB001`에 RAW 제출 완료: `jobId=4`, 요청/쓰기 `36102/36102` bytes. 첫 제출 시 임시 C# helper의 미사용 지역변수 경고가 오류로 처리되어 컴파일만 실패했고 프린터 제출은 발생하지 않았다. 해당 변수를 제거한 재실행에서 위 job 1건만 제출됐다.
- 최초 진단 판정 항목은 전체 레이아웃 유지 여부와 두 역상 띠의 `AZ1 1x1` 한글 출력·획 연속성이었다.
- 실물 결과 `.tmp/IMG_20260926_0002.png`: 일반 레이아웃은 유지됐고 네 `AZ1 ... 1,1,0,0I` 위치에 예상 폭의 흰 역상 박스가 생성됐지만 박스 안 한글/영문 glyph는 전부 비었다. 올바른 배율과 inverse 명령 자체는 G500이 정상 해석했으며, 현재 프린터 메모리에서 `Z1` 한글 폰트를 찾지 못한 상태로 판정한다.
- PC shared preferences의 설치 표식은 프린터 전원 초기화·메모리 소실을 검증하지 않아 stale 상태가 될 수 있다.
- 사용자 승인 후 보존된 `AZ_KO16x16.DAT` 패키지를 `Godex G500`에 RAW 재설치 완료: `jobId=5`, 요청/쓰기 `282127/282127` bytes. 이어서 동일 진단 PRN 1매를 RAW 제출 완료: `jobId=6`, 요청/쓰기 `36102/36102` bytes.
- 실물 결과 `.tmp/IMG_20260926_0003.png`: 폰트 상태 출력에 `1: Korean 16x16 Korean`, `001 ASIAN FONT(S) IN MEMORY`가 확인되어 Z1 설치는 성공했다. 진단 라벨에서는 네 명령 위치가 글자 폭만큼 흰 박스로 반전됐지만 glyph는 보이지 않았다.
- 판정: 폰트 부재나 잘못된 배율이 아니라, 이미 검정으로 채운 Q 영역 위에 `AZ1 ... 0I`를 겹쳐 inverse 영역 전체가 다시 흰색으로 반전된 합성 문제일 가능성이 높다. 현재 조합을 production에 반영하지 않는다.
- `tools/prepare_inverse_firmware_probe.ps1`에 `-ClipFill Black|White`를 추가했다. 기본값은 기존 진단과 같은 `Black`이며, 다음 진단은 `White`로 역상 영역 내부를 비운 뒤 native inverse가 검정 바탕·흰 glyph를 자체 생성하는지 분리한다.
- 다음 무출력 진단 PRN 준비 완료: `.tmp/log/godex_inverse/inverse_firmware_white_base_20260926.prn`, 36,102 bytes, SHA256 `FD40ACA02BF8428BBE734C9980299AFB88551AC66F8B80C13A02FAFCE1DBC19A`. Q `10,11,76,472`, white clip 2개, native inverse 4개이며 해석기 회귀 10/10 통과했다.
- 사용자 승인 후 white-base 진단 PRN 1매를 `Godex G500`/`USB001`에 RAW 제출 완료: `jobId=7`, 요청/쓰기 `36102/36102` bytes, 제출 전 SHA256 일치와 프린터 `Normal` 상태를 확인했다.
- 실물 결과 `.tmp/IMG_20260926_0004.png`: white-base에서는 `AZ1 0I`가 네 위치에 검정 바탕을 정상 생성했고 glyph 위치에 흰 픽셀도 나타났다. 다만 16x16 glyph의 1dot 흰 획 대부분이 검정 열 번짐에 메워져 점선 수준으로 남아 가독성은 실패했다. native inverse의 좌표·인코딩·합성 순서는 확인됐고 남은 문제는 열량이다.
- `AT` inverse는 공식 문법상 지원되지 않고 과거 v1.3.81에서 format을 오염시켰으므로 재사용하지 않는다. `AZ_KO16x16.DAT`도 단순 raw glyph 배열이 아닌 GoDEX 전용 인코딩 stream이어서 임의 bitmap 팽창은 하지 않는다.
- 현재 Windows 큐 표시값은 속도 127mm/s, 농도 level 8(42%)이다. 속도 저하는 과거 76.2/50.8mm/s 실물 A/B에서 효과가 없었고, job-local 농도 저하는 아직 분리 검증되지 않았다.
- `tools/prepare_inverse_firmware_probe.ps1`에 선택적 `-Darkness`/`-RestoreDarkness` 쌍을 추가했다. 진단 시작 전에 농도를 설정하고 `E` 직후 원래 값으로 복원하며, 해석기도 `^H00..19`를 검증한다. 회귀 11/11 통과.
- 다음 무출력 진단 PRN 준비 완료: `.tmp/log/godex_inverse/inverse_firmware_white_base_h04_20260926.prn`, 36,114 bytes, SHA256 `007E14DACFDFE6988640B3ACCFE49A56755CC43C89DA38B36962165814D5B6E7`. 순서는 `^H04` → white-base Q/native inverse 4개 → `E` → `^H08` 복원이다.
- 사용자 승인 후 저농도 진단 PRN 1매를 `Godex G500`/`USB001`에 RAW 제출 완료: `jobId=8`, 요청/쓰기 `36114/36114` bytes. 제출 전 SHA256, 프린터 `Normal`, `^H04 → ^L` 및 `E → ^H08` 복원 순서를 재확인했다.
- 실물 결과 `.tmp/IMG_20260926_0005.png`: 농도 4에서 네 역상 문자열의 한글/영문 형태가 모두 식별 가능하게 이어졌고 일반 검정 문자와 테두리도 유지됐다. `white-base + AZ1 1x1 inverse + ^H04` 조합을 해결 경로로 채택한다.
- 실제 요청 디코딩: 흰색 descriptor는 두 개이며 각 문자열의 긴 공백이 좌·우 문구 위치를 표현한다. 진단의 고정 문구/좌표를 제품 코드에 넣지 않고 `TextPainter.getBoxesForSelection`으로 공백 분리 run의 실제 시작 좌표를 보존한다.
- `lib/printing/godex_inverse_prn_transformer.dart` 추가: GoDEX 드라이버 PRN의 단일 Q payload를 검증하고 역상 descriptor 영역을 흰색으로 비운 뒤 CP949 `AZ1 ... 1,1,0,0I` run을 동적 삽입한다. `^L` 앞에 `^H04`, 최종 `E` 뒤에 `^H08` 복원을 추가하며 범위·payload 오류는 출력 전에 거부한다.
- `label_sheet_print_job.dart`: Windows 흰색 descriptor에 동적 firmware inverse run 텍스트/좌표를 보존한다. `windows_bitmap_printer.dart`: GoDEX 생성 PRN만 변환하고 font provision 성공 후 전체 RAW 제출한다. 일반/타사 경로는 그대로 유지한다.
- `godex_korean_font_provisioner.dart`: 캐시된 `AZ_KO16x16.DAT`가 있으면 GoLabel 설치가 제거된 뒤에도 읽도록 순서를 수정했다. 기존 printer+port 설치 표식은 계속 사용한다.
- Windows native 결과에 실제 driver target width/height를 반환해 640x480 source descriptor를 G500의 620x480 printable 좌표로 동일하게 변환한다. driver transport 진단 버전은 `1.3.130`이다.
- 버전 `1.4.31`. 관련 Flutter 테스트 40건 통과, PRN 해석기 11/11 통과, focused analyzer 새 오류 0건(기존 retired helper 미사용 경고 2건), `git diff --check` 통과, Windows `/WX` Debug 빌드 성공. EXE FileVersion/ProductVersion `1.4.31`.
- 새 Debug 앱 PID 20156 실행, `.tmp/log/app_2026-09-26_12-31-05.log`에서 `DebugLogger version: 1.4.31` 확인. 앱 실행 자체로 인쇄는 발생하지 않았다.
- `1.4.31` 실제 앱 경로 1매 승인 후 2026-09-26 13:07에 발행을 시작했으나, 임시 드라이버 PRN 생성 작업 9번(35,933 bytes, 0/1 page)이 완료되지 않고 네이티브 호출에서 정지했다. 약 2분간 앱 `Responding=False`, Dart로 PRN이 반환되지 않았고 RAW 제출 전 상태였다.
- 예기치 않은 지연 출력을 막기 위해 정지된 작업 9번만 취소했다. 취소 직후 앱은 정상 응답으로 복귀했고 로그에 `dispatchFailed ... Could not read generated driver PRN`이 기록됐다. 실제 라벨은 출력되지 않았고 업무 발행/이력도 성공 처리되지 않았다.
- 동일 드라이버의 파일 전용 회귀 도구는 작업공간과 `%TEMP%` 출력 모두 정상 완료했고 각 34,861-byte PRN을 만들었다. `%TEMP%` 검사 중 큐를 일시정지했으며 누출 작업 0건, 이후 정상 재개했다. 따라서 출력 경로 무시 가설은 폐기했고, 저장된 실제 전체 요청의 렌더/종료 단계를 파일 전용 재생해 정체를 좁힌다.
- 저장된 13:07 전체 요청을 `replayBitmapToFile`로 재생한 결과 드라이버 PRN 생성 924~957ms, 역상 변환 20~22ms, 전체 후처리 약 1초로 정상이다. 원본 PRN 35,933 bytes, 변환본 36,114 bytes, `firmwareInverse=2 nativeRuns=4 clearedPixels=19537 darkness=4 restoreDarkness=8`을 확인했다.
- 큐 일시정지/활성 상태 모두 전체 요청 재생이 성공했다. 활성 검사에서는 파일 출력용 작업 14번이 잠시 `Spooling`으로 나타난 뒤 자동 소멸했고 대기열 0건, 물리 출력 0건이다. 13:07 정체는 현재 재현되지 않는 Windows 스풀러 일시 상태로 판정하며 코드 경로 자체의 정체는 아니다.
- 폰트 표식 키도 실제 Windows Dart 계산 결과 `godex_korean_font_-33cdbcb9ab74d6f9`로 저장값과 정확히 일치해 재설치를 시도하지 않는다.
- 현재 blocker: 정상 `1.4.31` 앱을 복원한 뒤 별도 사용자 승인으로 실제 1매를 재시도해 `driverTransportVersion=1.3.130`, 변환 진단, RAW 전체 쓰기와 종이 품질을 확인한다.
- 정상 앱 복원 완료: `/WX` Windows Debug 빌드 성공, PID 19664로 실행 중이며 `.tmp/log/app_2026-09-26_13-23-40.log`에서 버전 `1.4.31`, 응답 정상, 대기열 0건을 확인했다.
- 최종 focused Flutter 테스트 40/40 통과. focused analyzer는 새 오류 0건이며 기존 retired helper 미사용 경고 2건만 남았다.
- 사용자 승인 후 정상 앱에서 동일 1매 재시도를 준비했으나 저장된 system 비밀번호가 거부되어 앱 화면 발행은 진행하지 않았다. 계정 비밀번호를 추측하거나 변경하지 않았다.
- 대신 13:07 실제 앱 요청에서 무출력 생성·변환한 동일 라벨 PRN `.tmp/log/godex_inverse/full_request_unpaused_20260926.prn.transformed`를 재검증했다. 36,114 bytes, SHA256 `64333A24BD4DACF2B1FB582F4959570E689237A806F1DEE0E9E64ADDC58E4734`, `^H04 -> Q -> AZ1 4개 -> E -> ^H08` 구조와 좌표가 정상이다.
- 승인 범위 내 위 PRN 1매를 `Godex G500`/`USB001`에 RAW 제출 완료: `jobId=15`, 요청/쓰기 `36114/36114` bytes. 작업은 대기열에서 소멸했고 프린터 `Normal`, 대기열 0건이다. 추가 출력은 하지 않는다.
- 현재 blocker: 작업 15번의 종이 결과 사진을 받아 네 역상 문자열의 가독성과 일반 검정 문자/테두리를 판정한다. 성공 확인 전에는 관련 변경을 커밋하지 않는다.
- 작업 15번 결과 `.tmp/IMG_20260926_0006.png`: 네 역상 문자열은 모두 식별 가능하고 상단 우측 문자열도 계산상 x=411..611로 Q 우측 618 안에 들어온다. 일반 검정 문자와 테두리도 유지됐다.
- 남은 실패는 두 역상 행에서 좌·우 문구 사이가 큰 흰 사각형으로 비어 검정 띠가 끊긴 점이다. 원인은 transformer가 inverse descriptor 전체를 흰색으로 지운 뒤 각 AZ1 문자열 상자만 검정으로 생성한 것이다.
- `godex_inverse_prn_transformer.dart`를 수정해 descriptor 전체가 아니라 각 CP949 run의 실제 펌웨어 폭(`encodedBytes * 8`) x 16dot만 흰 바탕으로 지우고, 문구 사이 원래 Q 검정 픽셀은 보존한다. run은 실제 Q 범위를 벗어나면 거부한다.
- transformer focused test를 32x16 Q에서 두 8x16 run 사이 16dot gap이 원래 값으로 보존되는 계약으로 보강했고 3/3 통과했다. 새 PRN 무출력 실제 요청 검증 후 별도 승인으로 1매만 재검증한다.
- 저장된 실제 요청으로 새 PRN 무출력 생성 완료: `.tmp/log/godex_inverse/full_request_run_clear_20260926.prn.transformed`, 36,114 bytes, SHA256 `2806409E46CC7F5AEED7C57AFDA1EA932F7A4848371B0CD78B0998201C6F9330`. `firmwareInverse=2 nativeRuns=4 clearedPixels=8437 darkness=4 restoreDarkness=8`; 구 버전의 19,537픽셀 전체 제거보다 run 상자만 제거한다.
- 해석 미리보기 `.tmp/log/godex_inverse/full_request_run_clear_20260926.prn.png`에서 두 행의 run 상자만 흰색이고 문구 사이/주변 검정 띠가 연속됨을 확인했다. 파일 전용 생성 중 물리 출력 0건, 큐 0건이다.
- 버전 `1.4.31 -> 1.4.32` PATCH 증가. 관련 Flutter 테스트 40/40 통과, focused analyzer 새 오류 0건(기존 retired helper 미사용 경고 2건), `git diff --check` 통과, Windows `/WX` Debug 빌드 성공. EXE FileVersion/ProductVersion 및 새 앱 로그가 `1.4.32`, PID 9752 응답 정상이다.
- 현재 blocker: 위 1.4.32 run-clear PRN 1매 실물 제출은 새 사용자 승인 전 실행하지 않는다. 결과에서 두 검정 띠의 연속성과 네 흰 문자열 가독성을 확인한 뒤 관련 변경만 커밋한다.
- 사용자 승인 후 1.4.32 run-clear PRN 1매를 `Godex G500`/`USB001`에 RAW 제출 완료: `jobId=18`, 요청/쓰기 `36114/36114` bytes, SHA256 `2806409E46CC7F5AEED7C57AFDA1EA932F7A4848371B0CD78B0998201C6F9330`. 작업은 대기열에서 소멸했고 프린터 `Normal`, 대기열 0건이다. 추가 출력은 하지 않는다.
- 현재 blocker: 작업 18번의 종이 결과 사진에서 두 역상 행의 검정 띠 연속성, 네 흰 문자열 가독성, 일반 문자/테두리를 판정한다. 성공 확인 후 관련 변경만 stage/commit한다.
- 작업 18번 결과 `.tmp/IMG_20260926_0007.png`: IMG_0006의 큰 흰 사각형은 사라져 상·하단 검정 띠가 연속되지만, 흰 글자 획이 심하게 끊기고 뭉개진다. 특히 `알레르기유발물질`과 `영양정보`는 정상 가독성·인쇄 품질에 미달한다. 앞선 실물 합격 판정은 잘못이므로 취소한다.
- **역상 문제 미해결**: 1.4.32 관련 구현은 커밋 `d5e56f0`, 결과 기록은 `3a770d3`에 있으나 실물 품질 기준을 통과하지 못했다. 추가 출력 전 기존 픽셀 보강 실험과 현재 AZ1 16x16 한계를 다시 대조한다.
- 과거 실험 재검토: 전방향 1dot 팽창은 v1.3.14에서 글자가 뭉치고 굵어져 기각됐고, 폐쇄/부분 edge/방향성 보정과 75%·50% 망점 및 냉각행도 획을 회복하지 못하거나 검정 배경을 거칠게 만들었다. 같은 픽셀 팽창·망점 방식은 반복하지 않는다.
- GoDEX 공식 `EZPL Programming Manual Rev.O.6` 확인: `AZ1` Asian font에는 굵게 옵션이 없고 1~8배 정수 확대만 지원한다. 한글 다운로드 생성기는 16x16 또는 24x24만 제공한다. 24x24는 짧은 제목에는 들어가지만 우측 상세 문자열이 현재 폭을 넘으므로 전체 대체안이 아니다.
- `.tmp/IMG_v0.Legacy_print.png`를 같은 PC/GoDEX G500의 실제 결과로 대조했다. 레거시의 `계란,우유,대두,밀 함유` 흰 획은 현재 `.tmp/IMG_20260926_0007.png`보다 뚜렷하고 연속적이다. 따라서 프린터·리본·용지의 물리 한계만으로 현재 저품질을 설명할 수 없으며, 현재 결과는 합격이 아니다. 다만 두 사진은 내용/레이아웃이 달라 glyph 단위 정량 비교 자료는 아니다.
- 레거시 소스의 실제 출력 경로 확인: `LabelPrintModel.cpp`가 RTF를 `CPrintManager::Print`로 넘기고, `PrintManager.cpp`는 GoDEX `DEVMODE`로 `CreateDC("WINSPOOL", ...)`한 실제 프린터 DC를 `FORMATRANGE.hdc/hdcTarget`에 지정한 뒤 `StartDoc/StartPage -> RichEdit FormatRange/DisplayBand -> EndPage/EndDoc`로 직접 출력한다. 중간 전체 페이지 bitmap 캡처나 `AZ1` 16x16 치환은 없다.
- 현재 경로는 Flutter 시트를 장치 dot 크기의 bitmap으로 만든 뒤 `StretchDIBits`로 드라이버 PRN을 생성하고, 역상 문자열만 고정 16x16 `AZ1`로 교체한다. 사진상 레거시는 텍스트 주변의 짧은 검정 블록이고 현재는 약 620dot 전폭 검정 띠이므로, `저해상도 AZ1 글꼴`과 `더 큰 연속 검정 면적`이 동시에 달라진다. 사진만으로 둘 중 하나를 단독 직접 원인으로 확정하지 않는다.
- 기존 무출력 제어 실험에서 `DisplayBand` 추가 전후 PRN SHA가 동일했고, 동일 좌표 RTF/현재 경로의 통제 한글 픽셀 차이도 0이었다. 레거시 호출 순서만 다시 구현하는 비교는 실제 차이를 만들지 못하므로 반복하지 않는다.
- 실물 `.tmp/IMG_20260926_0006.png`와 `0007.png`가 직접 분리한 변수는 검정 면적이다. 같은 H04/AZ1에서 0006의 run 주변만 검정일 때 글자가 식별됐지만, 0007의 전폭 연속 검정 띠에서는 흰 획이 심하게 소실됐다. 현재 증상에는 연속 열부하가 실제로 관여한다.
- GoLabel V1.18의 `StartDownloadAsianFontKO`/`CreateKOFontFile`을 추적해 24x24 패키지 생성을 시도했지만, 한국어 Windows의 표준 글꼴 선택 대화상자 자동화 뒤 native 성공 코드에도 DAT가 생성되지 않았다. 기존 16x16과 byte 동등한 재생성조차 검증할 수 없어 24x24 경로와 실험용 helper 변경은 폐기했다. 프린터 제출은 없었다.
- 공식 EZPL 문법상 `ATt` 다운로드 TrueType에는 inverse 옵션이 없고 `At`/`Vt` bitmap text만 `I` inverse를 지원한다. `~Jx`는 HP LaserJet II Plus PCL-4 bitmap soft font를 받을 수 있으므로 `~Jx + Vt ... I`가 문서상 대체 후보지만, GoLabel/레거시 추출물에는 `.SFP` 예제가 없고 새 포맷 생성·G500 호환 검증이 필요해 즉시 제품 코드에 넣지 않는다.
- H04→H02 무출력 PRN `.tmp/log/godex_inverse/full_request_run_clear_h02_20260926.prn`(36,114 bytes, SHA256 `3BB717B031AF1B2D58014C8D71ECEA57A5094688E20649364AC0BC89453CD9D5`)은 준비돼 있다. 현재 증거상 다음 최소 분리시험은 동일 레이아웃의 농도만 H02로 낮춘 실물 1매이며, 실제 제출은 새 사용자 승인 전 실행하지 않는다.
- 사용자 승인 후 위 H02 PRN 1매를 `Godex G500`/`USB001`에 RAW 제출 완료: `jobId=19`, 요청/쓰기 `36114/36114` bytes, SHA256 `3BB717B031AF1B2D58014C8D71ECEA57A5094688E20649364AC0BC89453CD9D5`. 작업은 대기열에서 소멸했고 프린터 `Normal`, 대기열 0건이다. 추가 출력은 하지 않는다.
- 작업 19번 결과 `.tmp/IMG_20260926_0008.png`: H02에서도 전폭 검정 띠의 네 흰 문자열 획은 정상 수준으로 회복되지 않았고, 일반 본문 문자와 표선까지 H04보다 옅고 끊겨 전체 인쇄 품질이 악화됐다. 농도 저하는 해결책에서 제외하며 H02를 제품 설정에 반영하지 않는다.
- 공식 HP PCL-4 Format 0 규격에 맞춘 실험용 생성기 `tools/godex_soft_font_probe/` 추가: 64-byte font header, 16-byte character block header/descriptor, big-endian metric, MSB-first row raster를 생성한다. GoDEX `~MDELE,<name> -> ~J<slot>` 포장과 `V<slot>,...,0I,<code>` 명령도 분리했다. 앱 출력 경로에는 아직 연결하지 않았다.
- 한글 전체 폰트 대신 역상 문자열 한 개를 PCL glyph 한 개에 매핑한다. Windows `gulim.ttc`를 명시적으로 로드해 네 실제 문자열을 20dot bold glyph A-D로 만들고 기존 폭 128/200/64/256dot 안에 맞췄다. Ahem 대체문자로 생성된 최초 파일은 즉시 무효화하고 실제 굴림으로 덮어썼다.
- 무출력 probe `.tmp/log/godex_inverse/full_request_vt_softfont_h04_20260926.prn`: 37,863 bytes, SHA256 `D5DAEE26CFE79070694B4749363CB0D7D11F415564174165E877C54D033B37F5`. `LMINV001` Format 0/type 2, glyph A-D 4개, H04/H08 각 1개, `VA ... I` 4개, `AZ1` 0개를 byte 파서로 확인했다. glyph 미리보기는 같은 이름 `.png`, 생성 기록은 `.txt`이며 실제 제출은 0건이다.
- 검증: `test/godex_pcl4_bitmap_font_test.dart` 4/4 통과, focused `dart analyze` No issues found. 임시 실제 라벨 probe 생성 테스트 1/1 통과했다.
- 사용자 제안에 따라 RichEdit 오픈소스를 조사했다. 레거시는 `CITSnGRichEditCtrl::PreCreateWindow`에서 `RICHEDIT50W`를 강제하므로 실제 엔진은 Windows `msftedit.dll`이다. 현재 시스템 DLL은 `10.0.22621.4599`다.
- Microsoft는 RichEdit50W 내부 인쇄 구현을 공개하지 않고 API/호출 예제만 제공한다. 최신 Wine `dlls/riched20/editor.c`는 `EM_FORMATRANGE`와 `EM_DISPLAYBAND`를 둘 다 `UNSUPPORTED_MSG`로 명시하며 TODO도 `Mission Impossible`로 남아 있다. ReactOS 사용자 영역도 Wine 기반이므로 실제 Windows 인쇄 구현의 대체 소스로 사용할 수 없다.
- 실제 `msftedit.dll`의 기존 통제 EMF를 다시 해석하면 `CreateFont/SetTextColor/BitBlt/ExtTextOutW` 레코드로 흰 한글과 검정 배경을 프린터 대상 DC에 보낸다. 전체 페이지 bitmap으로 먼저 평탄화하는 구현은 아니다. 다만 동일 좌표 통제 실험에서 이 출력과 현재 경로의 한글 픽셀 차이는 0이고 DisplayBand 추가 전후 PRN도 동일했으므로, 오픈소스 호출 순서 재현만으로 사진 차이를 설명하지 못한다.
- PCL soft-font 실물 결합 시험은 승인되지 않았고 보류한다. 다음 분석은 오픈소스가 아니라 실제 `msftedit.dll` black-box 캡처가 되어야 하며, 레거시 사진과 대응하는 원본 RTF/동일 레이아웃을 EMF 및 드라이버 파일로 캡처해야 glyph 크기·굵기·검정 면적 차이를 직접 분리할 수 있다. 추가 인쇄는 새 승인 전 실행하지 않는다.
- 레거시 로컬 Access DB를 읽기 전용으로 확인했다. `labelmanager*.mdb`의 인쇄 설정 테이블은 비어 있었지만 `ssmdatabase.mdb`에는 구형 품목 데이터가 있었고, 비교 사진의 `240g(755kcal)`/품목보고번호 조합은 존재하지 않아 사진 원본이 아니었다.
- 레거시의 마지막 서버 연결 정보를 출력하지 않고 읽기 전용 SQL 연결했으며 `BM_RICH_LABELSIZE_FORM` 5,240건을 확인했다. 비교 사진과 정확히 일치하는 품목은 `RICH_ITEM_ID=472139`, 서식은 `RICH_LABELSIZE_ID=4955`, 크기 `80x60mm`다. `240g(755kcal)`, `1개당 120g`, 품목보고번호, 알레르기 및 모든 영양값이 사진과 일치한다.
- 정확한 서버 원본을 로컬 진단 파일 `.tmp/log/godex_inverse/legacy_noted_4955_form.rtf`(12,721 bytes)와 `legacy_noted_472139_element.rtf`(1,311 bytes)로 추출했다. DB 변경·물리 인쇄는 없었다. 다음 액션은 이 RTF에 동일 품목 값을 RichEdit 방식으로 치환하고 `msftedit.dll`의 EMF 및 GoDEX 드라이버 파일을 무출력 캡처해 현재 620x480 시트 경로와 동일 좌표로 비교하는 것이다.
- `tools/inverse_rich_edit_probe --legacy-rtf-emf`를 추가해 실제 `RICHEDIT50W`에서 템플릿/주원료 RTF와 동적 필드를 치환하고, 레거시와 같은 80x60mm GoDEX DEVMODE 및 `EM_FORMATRANGE/EM_DISPLAYBAND` 호출을 `.rtf/.emf/.bmp/.prn`으로만 캡처한다. 물리 제출은 없고 캡처 전후 큐는 0건이다. 기존 native device text 회귀도 PASS했다.
- 정확한 캡처 `.tmp/log/godex_inverse/legacy_noted_472139_capture2.*`: 최종 RTF 13,995 bytes, EMF 30,128 bytes, BMP 1,190,454 bytes, PRN 33,348 bytes. PRN은 `Q4,26,73,456` 단일 1-bit raster이며 해석 PNG가 비교 사진의 레이아웃/문구와 일치한다. 즉 레거시도 프린터에 벡터 폰트를 직접 전송하지 않고 GoDEX 드라이버가 최종 페이지를 비트맵으로 만든다.
- 정확한 레거시 역상 EMF는 흰색 `ExtTextOutW`로 `계란,우유,대두,밀 함유`를 `rect=4,223,280,242`에 출력한다. 활성 폰트는 `굴림`, 높이 14dot, weight 700(Bold)이며 역상 배경은 약 276x19dot의 짧은 영역이다. 현재 결과는 16x16 AZ1과 약 620dot 전폭 검정 띠이므로 RichEdit 호출 자체가 아니라 glyph raster와 연속 열부하가 핵심 차이다.
- 다음 최소 분리시험은 준비된 20dot bold 굴림 PCL soft-font PRN 1매다. 전폭 검정 띠를 유지한 채 glyph만 바꾸므로 성공하면 glyph 해상도/굵기 문제, 실패하면 전폭 열부하 문제가 지배적임을 분리할 수 있다. 실제 제출은 새 사용자 승인 전 실행하지 않는다.
- 사용자 승인 후 PCL soft-font 진단 PRN `.tmp/log/godex_inverse/full_request_vt_softfont_h04_20260926.prn` 1매를 `Godex G500`/`USB001`에 RAW 제출했다. `jobId=21`, 요청/쓰기 `37863/37863` bytes, SHA256 `D5DAEE26CFE79070694B4749363CB0D7D11F415564174165E877C54D033B37F5`; 작업 소멸 후 프린터 `Normal`, 대기열 0건이다. 추가 출력은 하지 않는다.
- 작업 21번 결과 `.tmp/IMG_20260926_0009.png`: PCL Format 0 다운로드와 `Vt ... I`는 G500에서 정상 동작했고 네 문자열 모두 16x16 `AZ1`보다 획 연속성과 식별성이 크게 좋아졌다. 그러나 20dot bold를 고정 폭 128/200/64/256dot에 가로 압축해 획과 글자 사이가 붙고, 특히 우측 상세 문자열은 과도하게 뭉쳐 제품 품질에는 미달한다. 전폭 검정 띠의 흰 핀홀도 남아 연속 열부하가 함께 존재한다.
- 다음 후보는 실제 run 폭에 맞는 **16dot bold 굴림 soft-font**다. A/B/C는 자연 폭 128/182/64dot로 무압축이고 D만 자연 폭 264→256dot(약 3%)로 최소 압축된다. 무출력 PRN `.tmp/log/godex_inverse/full_request_vt_softfont_16b_h04_20260926.prn`은 37,506 bytes, SHA256 `6437C524B8BD232B6A183335041DE8D31A56325204EFC399343FBED7BBD430C0`; `LMIV16B` PCL header 1개, `VA ... I` 4개, `AZ1` 0개, `^H04/^H08` 각 1개, Q 1개를 확인했다. 미리보기와 생성 기록은 같은 basename의 `.png`/`.prn.txt`다.
- 사용자 승인 후 16dot bold 후보 `.tmp/log/godex_inverse/full_request_vt_softfont_16b_h04_20260926.prn` 1매를 `Godex G500`/`USB001`에 RAW 제출했다. 제출 직전 37,506 bytes와 SHA256 `6437C524B8BD232B6A183335041DE8D31A56325204EFC399343FBED7BBD430C0`, 프린터 `Normal`, 대기열 0건을 재확인했다. `jobId=22`, 요청/쓰기 `37506/37506` bytes이며 작업 소멸 후 프린터 `Normal`, 대기열 0건이다. 추가 출력은 하지 않는다.
- 작업 22번 결과 `.tmp/IMG_20260926_0010.png`에는 본 라벨 뒤 별도 용지에 `Duplicate Name`이 출력됐다. EZPL 매뉴얼상 `~Jx` bitmap font의 저장 파일명은 슬롯 문자 `x`이며 같은 이름 재다운로드는 거부된다. 생성기가 `~JA`로 저장하면서 잘못된 내부 font header 이름 `~MDELE,LMIV16B`를 삭제 대상으로 사용해 기존 슬롯 `A`를 지우지 못했다. 따라서 새 16dot 다운로드가 거부되고 슬롯 A에 남은 이전 20dot glyph가 다시 출력된 것으로 판정하며, 0010은 16dot 품질 판정 자료로 사용하지 않는다.
- `buildGodexBitmapFontDownload`를 `~MDELE,<slot> -> ~J<slot>` 순서로 수정하고 API에서 잘못된 `fontName` 삭제 인자를 제거했다. 회귀 테스트는 정확한 `~MDELE,A\r\n~JA\r\n` 바이트를 고정하며 4/4 통과했다. glyph raster 테스트는 `tester.runAsync`로 감싸 테스트 프로세스 종료도 정상화했다.
- 수정된 16dot bold 무출력 후보는 동일 경로 `.tmp/log/godex_inverse/full_request_vt_softfont_16b_h04_20260926.prn`에 다시 생성했다. 37,500 bytes, SHA256 `0528EE5D0A1B1844A30690C700783F1F6DAE63D558D8963732485DD9A87C3119`, prefix `~MDELE,A -> ~JA`, `physicalPrintSubmitted=false`이며 현재 프린터 `Normal`, 대기열 0건이다.
- 사용자 승인 후 슬롯 삭제를 수정한 16dot 후보 `.tmp/log/godex_inverse/full_request_vt_softfont_16b_h04_20260926.prn` 1매를 `Godex G500`/`USB001`에 RAW 제출했다. 제출 직전 37,500 bytes, SHA256 `0528EE5D0A1B1844A30690C700783F1F6DAE63D558D8963732485DD9A87C3119`, prefix `~MDELE,A -> ~JA`, 프린터 `Normal`, 대기열 0건을 확인했다. `jobId=23`, 요청/쓰기 `37500/37500` bytes이며 작업 소멸 후 프린터 `Normal`, 대기열 0건이다. 추가 출력은 하지 않는다.
- 작업 23번 결과 `.tmp/IMG_20260926_0011.png`: 별도 `Duplicate Name` 출력이 사라졌고 16dot glyph가 실제 적용됐다. 20dot의 과대 크기와 강한 가로 뭉침은 줄었으나 흰 획이 다시 가늘어져 일부 글자가 끊기고, 전폭 검정 띠의 흰 핀홀도 남아 제품 품질에는 아직 미달한다.
- 다음 무출력 후보는 **18dot bold 굴림 자연 폭**이다. 고정 AZ1 폭으로 압축하지 않고 각 띠의 실제 남은 공간을 사용해 A/B/C는 자연 폭 144/205/72dot 그대로, D만 페이지 우측 경계 때문에 자연 폭 297→296dot(0.3%)로 제한한다. 좌표 기준 B 끝은 x=616, D 끝은 x=618로 Q/페이지 안에 들어온다.
- 후보 `.tmp/log/godex_inverse/full_request_vt_softfont_18b_natural_h04_20260926.prn`: 37,856 bytes, SHA256 `F3F503D58F215C96C46BAABAF6141CF9E465B6AED267B509EB17ECD333F57160`, prefix `~MDELE,A -> ~JA`, `LMIV18B`, H04/H08, `physicalPrintSubmitted=false`. 미리보기/기록은 같은 basename의 `.png`/`.prn.txt`다.
- 사용자 승인 후 18dot 자연 폭 후보 `.tmp/log/godex_inverse/full_request_vt_softfont_18b_natural_h04_20260926.prn` 1매를 `Godex G500`/`USB001`에 RAW 제출했다. 제출 직전 37,856 bytes, SHA256 `F3F503D58F215C96C46BAABAF6141CF9E465B6AED267B509EB17ECD333F57160`, prefix `~MDELE,A -> ~JA`, 프린터 `Normal`, 대기열 0건을 확인했다. `jobId=24`, 요청/쓰기 `37856/37856` bytes이며 작업 소멸 후 프린터 `Normal`, 대기열 0건이다. 추가 출력은 하지 않는다.
- 작업 24번 결과 `.tmp/IMG_20260926_0012.png`: 16dot보다 흰 획이 회복되고 20dot보다 가로 뭉침이 줄어 현재까지 가장 가까운 결과다. 하지만 18dot 자체가 여전히 굵고, 하단 우측 D glyph가 x=322..618로 페이지/Q 우측까지 차면서 끝부분이 흰 덩어리처럼 뭉쳐 경계 여유가 부족하다. 전폭 검정 띠의 흰 핀홀도 지속되므로 아직 최종 합격으로 판정하지 않는다.
- 다음 무출력 후보는 **17dot bold 굴림 자연 폭**이다. A/B/C/D 모두 무압축 자연 폭 136/193/68/280dot이며, 우측 B는 x=411..604, D는 x=322..602로 16dot보다 획을 보강하면서 18dot보다 우측 여유를 확보한다.
- 후보 `.tmp/log/godex_inverse/full_request_vt_softfont_17b_natural_h04_20260926.prn`: 37,698 bytes, SHA256 `90902C4E325CDE5D08F80A1080A85FBD79E5B769785DF52AD9639338002EE69A`, prefix `~MDELE,A -> ~JA`, `LMIV17B`, H04/H08, `physicalPrintSubmitted=false`. 미리보기/기록은 같은 basename의 `.png`/`.prn.txt`이며 현재 프린터 `Normal`, 대기열 0건이다.
- 사용자 승인 후 17dot 자연 폭 후보 `.tmp/log/godex_inverse/full_request_vt_softfont_17b_natural_h04_20260926.prn` 1매를 `Godex G500`/`USB001`에 RAW 제출했다. 제출 직전 37,698 bytes, SHA256 `90902C4E325CDE5D08F80A1080A85FBD79E5B769785DF52AD9639338002EE69A`, prefix `~MDELE,A -> ~JA`, 프린터 `Normal`, 대기열 0건을 확인했다. `jobId=25`, 요청/쓰기 `37698/37698` bytes이며 작업 소멸 후 프린터 `Normal`, 대기열 0건이다. 추가 출력은 하지 않는다.
- 작업 25번 결과 `.tmp/IMG_20260926_0013.png`: 17dot는 18dot보다 간격과 우측 여유가 좋아졌지만 하단 우측 문자열 끝에 같은 흰 사각형 손상이 남았다. 처음에는 280/296dot에서만 나타난 점을 근거로 256dot 단일 glyph 제한을 의심했다.
- 이 가설을 분리하려고 하단 우측을 114dot/167dot 두 glyph로 나눈 17dot split 후보를 준비해 사용자 승인 후 1매 제출했다. 파일 37,767 bytes, SHA256 `AAF1F3E222C7F248A27F90682FA1224F5CD8FB5791B66AE71605F8A003692C8D`, `jobId=26`, 요청/쓰기 `37767/37767`, 작업 소멸 후 프린터 `Normal`, 대기열 0건이었다.
- 작업 26번 결과 `.tmp/IMG_20260926_0014.png`: 큰 흰 사각형은 줄었지만 하단 우측 `kcal` 끝부분은 여전히 온전하지 않아 256dot 제한만으로는 설명되지 않는다. 원본 Q는 기존 AZ1 폭 256dot까지만 흰색으로 비웠고 17dot 자연 glyph는 x=322..602(280dot)이므로, 마지막 24dot가 검정 바탕 위에 남은 것이 직접 원인이다. 이는 black-base에서 inverse glyph가 실패하고 white-base에서 나타난 앞선 실물 결과와 일치한다.
- 잘못 추정한 256dot 생성 제한과 테스트는 제거했다. 다음 무출력 후보는 17dot 자연 폭 A/B/C/D 136/193/68/280dot를 유지하면서 각 glyph의 **실제 폭 x 17dot 높이 전체**를 Q에서 먼저 흰색으로 지운다. 이전 후보의 D 전체 영역에는 검정 541픽셀, 특히 x=578..602 꼬리에는 365픽셀이 남았지만 새 후보는 네 glyph 영역과 D 꼬리가 모두 0픽셀임을 byte 검사했다.
- 후보 `.tmp/log/godex_inverse/full_request_vt_softfont_17b_fullclear_h04_20260926.prn`: 37,698 bytes, SHA256 `005A0BAFA38F1189FE6729765CCD1BB2CD858C01D7F7BDD9E5AC4A7B01B3129D`, prefix `~MDELE,A -> ~JA`, `LMIV17C`, Vt 4개, H04/H08, `physicalPrintSubmitted=false`. 미리보기/기록은 같은 basename의 `.png`/`.prn.txt`다.
- 사용자 승인 후 17dot full-clear 후보 `.tmp/log/godex_inverse/full_request_vt_softfont_17b_fullclear_h04_20260926.prn` 1매를 `Godex G500`/`USB001`에 RAW 제출했다. 제출 직전 37,698 bytes, SHA256 `005A0BAFA38F1189FE6729765CCD1BB2CD858C01D7F7BDD9E5AC4A7B01B3129D`, Vt 4개, prefix `~MDELE,A -> ~JA`, 프린터 `Normal`, 대기열 0건을 확인했다. Windows spooler 재시작 뒤 번호가 초기화된 상태에서 `jobId=2`, 요청/쓰기 `37698/37698` bytes이며 작업 소멸 후 프린터 `Normal`, 대기열 0건이다. 추가 출력은 하지 않는다.
- 작업 2번 결과 `.tmp/IMG_20260928_0001.png`: full-clear 효과가 확인됐다. 하단 우측 문자열이 `171.9kcal` 끝까지 출력되고 A/C 끝부분의 별도 흰 합성 손상도 사라졌다. PCL soft-font 역상 glyph 합성 문제는 해결됐다. 전폭 검정 띠의 핀홀·거친 면은 남지만 이는 레거시의 짧은 검정 블록과 다른 현재 라벨 형상에서 발생하는 연속 열부하 문제로, glyph 끝 손상과는 분리한다.
- production 반영 완료: 역상 run을 descriptor의 font family/높이/bold/italic으로 동적 래스터화하고, 실제 glyph 폭×높이만 Q에서 full-clear한 뒤 PCL4 Format 0 soft-font를 작업마다 `~MDELE,A -> ~JA`로 내려받아 `VA ... I`로 출력한다. 기존 CP949 `AZ1`과 프린터 상주 Korean Z1 font 설치 의존성은 제거했다.
- production PCL builder/rasterizer 테스트와 transformer actual-bounds 회귀 테스트를 추가했다. 관련 출력 경로 테스트 **22/22 통과**, production 및 probe focused analyzer **No issues found**, `git diff --check` 통과. 추가 실물 출력은 수행하지 않았다.
- Windows Debug 빌드 성공. EXE FileVersion/ProductVersion `1.4.33`; 레거시 RTF 비교 probe도 `/WX` 설정으로 재빌드 성공했다. 버전은 호환 가능한 역상 출력 버그 수정이므로 `1.4.32 -> 1.4.33` PATCH 증가했다.
- 기능 커밋 `7889fff` (`GoDEX 역상 soft-font 출력 적용`). 새 production 앱 경로의 최종 실물 1매 검증은 별도 사용자 승인 전 실행하지 않는다.
- 사용자 승인 후 1.4.33 production 변환 후보를 파일 전용으로 두 번 생성해 동일 SHA256을 확인했다. `.tmp/log/godex_inverse/production_v1433_widthcheck_20260928.prn.transformed`, 37,749 bytes, SHA256 `716184FC6A87FDF949F40572CDD463F16DE855ED8A5CF53C98E34FFFACC8A40C`; PCL glyph 139/197/70/289×17, `VA ... I` 4개, `AZ1` 0개이며 네 실제 glyph full-clear 영역의 잔여 검정 픽셀은 모두 0이다.
- 위 후보를 `Godex G500`/`USB001`에 정확히 한 번 실행 요청했다. 실행 전 프린터 `Normal`, 대기열 0건과 SHA256을 재확인했다. Windows GUI 실행 파일이 호출 셸과 분리되어 `jobId/writtenBytes` 표준출력은 회수하지 못했지만 프로세스는 종료됐고 이후 프린터 `Normal`, 대기열 0건이다. 중복 위험 때문에 재전송하지 않는다. 종이 결과 사진으로 최종 production 품질을 판정한다.
- production 결과 `.tmp/IMG_20260928_0002.png`: 실제 출력됐음이 확인됐다. 네 문자열 모두 표시되고 하단 우측은 `171.9kcal` 끝까지 출력돼 full-clear 합성 결함은 해결됐다. 그러나 레거시보다 전폭 검정 띠의 핀홀과 흰 획 거칠기가 여전히 커 전체 역상 품질 완료로 판정하지 않는다.
- 다음 최소 후보는 기존 18dot 실험의 끝 손상 원인이었던 불완전 clear를 제거한 **18dot full-clear**다. 파일 전용 production 경로 후보 `.tmp/log/godex_inverse/production_v1433_18dot_fullclear_20260928.prn.transformed`, 37,892 bytes, SHA256 `B3953967B85E579B9A28D2B33BBA65DDB717FCB6C29077F3B37F7050CE99B826`; glyph 147/207/74/296×18, Vt 4개, AZ1 0개, 네 glyph clear 영역 잔여 검정 0픽셀이다. `physicalPrintSubmitted=false`, 프린터 `Normal`, 대기열 0건이다. 실제 제출은 새 사용자 승인 전 실행하지 않는다.
- 사용자 승인 후 위 18dot full-clear 후보를 `Godex G500`/`USB001`에 정확히 1매 RAW 제출했다. `jobId=7`, 요청/쓰기 `37892/37892`, SHA256 일치, `physicalPrintSubmitted=true`; 작업 소멸 후 프린터 `Normal`, 대기열 0건이다. 추가 출력은 하지 않는다. 종이 결과에서 17dot production 대비 흰 획 연속성, 글자 뭉침, 우측 끝 손상을 비교한다.
- 18dot 결과 `.tmp/IMG_20260928_0003.png`: 17dot보다 흰 획은 조금 더 이어지지만 우측 두 문자열이 가로 폭 한계까지 압축돼 더 빽빽하고, 전폭 검정 띠의 핀홀도 그대로다. 18dot를 production에 채택하지 않는다.
- production 17dot와 성공한 `0001` 후보의 차이를 확인했다. descriptor의 `굴림`/`Gulim`을 Flutter 시스템 family로 요청하면 fallback glyph가 생성돼 폭이 139/197/70/289였지만, Windows `gulim.ttc` face를 `FontLoader`로 직접 등록하면 `0001`과 정확히 같은 136/193/68/280으로 생성된다. 명칭 변경만으로는 해결되지 않는다.
- `godex_text_glyph_rasterizer.dart`를 수정해 `굴림`/`Gulim` 역상 run은 `%WINDIR%\\Fonts\\gulim.ttc`를 작업 프로세스에 한 번 명시 등록한 뒤 래스터화한다. Windows Gulim 폭 136×17 회귀 테스트를 추가했다. 파일 전용 후보 `.tmp/log/godex_inverse/production_explicit_gulim_17dot_fullclear_20260928.prn.transformed`는 37,698 bytes, SHA256 `B9B92B23151BA4501908BE100CB72814657697167EF1A9D8B52DA39930F8C41C`, 네 glyph 폭 136/193/68/280, `firmwareInverse=2 nativeRuns=4 clearedPixels=9444`로 `0001` 성공 후보와 일치하며 물리 출력은 하지 않았다.
- 관련 출력 경로 테스트 **23/23 통과**, focused analyzer **No issues found**, `git diff --check` 통과, Windows Debug 빌드 성공. EXE FileVersion/ProductVersion `1.4.34`. 호환 가능한 글꼴 선택 버그 수정이므로 `1.4.33 -> 1.4.34` PATCH 증가했다. 새 후보 실물 출력은 별도 사용자 승인 전 실행하지 않는다.
- 기능 커밋 `e94b686` (`GoDEX 역상 굴림 글꼴 고정`).
- 기존 사용자/진행 중 변경 `lib/core/app.dart`, 영양성분표 관련 4개 파일은 수정·stage·commit에서 제외한다.

## 현재 작업: 영양성분표 RTF 선택 중 오류
- **진행 중**: 설정 → 영양성분표 추가에서 2번 `총 내용량 80mm` 선택 시 RTF 미리보기 전환 중 발생하는 1.4.16 오류를 수정한다.
- 제출 로그 확인: 영양성분표 목록 조회 후 RTF async 변환이 시작되고 CP949 hex decode 단계까지 진행된다. 첨부 디버거는 `FortuneTable._buildTextCell`의 `onPointerUp`에서 dispose된 State의 `context`를 조회해 `This widget has been unmounted`가 발생한 것을 보여준다.
- 원인 가설: 행 pointer-down에서 RTF floating portal이 생성되며 표 subtree가 교체되지만, 같은 포인터의 up 이벤트가 교체 전 Listener에 도착해 dispose된 표 State의 `context`와 focus node를 사용한다.
- 수정 전 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/fortune_table_test.dart --plain-name "FortuneTable ignores pointer up after row selection unmounts table"`.
- 수정 전 focused test 결과: **실패(예상 일치)**. pointer-down 직후 표를 제거하고 pointer-up하면 첨부와 동일한 `This widget has been unmounted` FlutterError가 발생했다.
- `third_party/fortune_sheet/lib/src/fortune_table.dart` 편집 완료: pointer-up에서 `mounted`를 검사하고, 해제된 표는 focus를 건너뛰며 `[fortune-table-pointer-debug-v1] event=focusSkipped reason=unmounted`를 기록한다. 활성 표는 context 조회 없이 자체 focus node에 직접 focus를 요청한다.
- 수정 후 FortuneTable focused test 결과: **통과(1/1)**.
- CP949 로그 판별: `charset decode failed charset=CP949`는 변환을 중단하는 throw가 아니라 다른 charset과 latin1 fallback으로 이어지는 기존 진단이다. 첨부의 실제 중단 원인은 해제된 FortuneTable State의 context 접근이다.
- `lib/features/nutrition/presentation/nutrition_box_dialog.dart` 편집 완료: 선택 행 ID/RTF 여부와 preview portal 생성·갱신·표시·skip 단계를 `nutritionBoxRtfSelection` 이벤트로 기록한다.
- `test/nutrition_box_dialog_test.dart` 편집 완료: 첫 행의 non-RTF 상태에서 `총 내용량 80mm` RTF 행을 실제 pointer로 선택해 portal 생성 중 예외가 없고 양쪽 재현 로그가 남는지 검증한다.
- 수정 예정 파일: `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/features/nutrition/presentation/nutrition_box_dialog.dart`, `test/fortune_table_test.dart`, `test/nutrition_box_dialog_test.dart`, `pubspec.yaml`.
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 현재 작업: 발행내역 조회 지연
- **완료**: 발행내역 조회가 1.4.16 제출 로그에서 15~21초 걸리는 문제를 빈 검색 조건 제거, 합계 스캔 통합, 상세 payload 지연 조회로 수정했다.
- 제출 로그 확인: 상세 조회는 17,482ms / 12,292ms / 11,064ms, 뒤이은 전체·기간 합계 조회는 합계 3,733ms / 4,671ms / 3,801ms가 소요됐다.
- 원인 가설: 빈 품목 검색에도 `RICH_ITEM_NAME LIKE N'%%'`를 붙이고, 전체·기간·라벨규격별 합계를 순차 쿼리해 같은 대형 로그 테이블을 반복 스캔한다.
- 수정 예정: `PrintLogDAO`에서 빈 품목 검색 조건을 생략하고 전체·기간·라벨규격별 합계를 조건부 집계 1회로 통합한다. `PrintHistoryDialogContent`는 통합 집계 결과를 사용하고 단계별 소요시간 재현 로그를 남긴다.
- 수정 전 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/print_log_test.dart --plain-name "empty item search omits no-op LIKE predicate"`.
- 수정 전 focused test 결과: **실패(예상 일치)**. 빈 품목 검색 SQL에 `RICH_ITEM_NAME LIKE N'%%'`와 `searchText` 파라미터가 남아 있었다.
- `lib/features/print_history/data/print_log_dao.dart` 1차 편집 완료: 빈 품목 검색일 때만 `LIKE` 조건과 `searchText` 파라미터를 생략한다.
- 빈 검색 SQL focused test 수정 후 결과: **통과(1/1)**.
- 통합 합계 SQL focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/print_log_test.dart --plain-name "print log summary query aggregates all scopes in one scan"`.
- 통합 합계 SQL focused test 수정 전 결과: **실패(예상 일치)**. `PrintLogDAO.buildSummaryQuery`가 없어 컴파일되지 않았다.
- `lib/features/print_history/domain/print_log.dart` 편집 완료: 라벨규격별 전체·기간 합계를 담는 `PrintLogSummary`를 추가했다.
- `lib/features/print_history/data/print_log_dao.dart` 2차 편집 완료: 고객 범위를 한 번 스캔해 라벨규격별 전체 누계와 날짜 조건 기간 합계를 반환하는 `buildSummaryQuery`/`selectSummary`를 추가했다.
- 통합 합계 SQL focused test 수정 후 결과: **통과(1/1)**.
- `lib/features/print_history/presentation/print_history_dialog.dart` 편집 완료: 전체·기간·라벨규격별 순차 합계를 통합 집계 1회로 교체하고 상세/집계/전체 완료 소요시간과 행 수를 `printHistoryQuery` 로그로 기록한다.
- `test/print_history_dialog_test.dart` 편집 완료: 선택 고객 조회가 통합 집계를 정확히 1회 호출하고 기존 합계 행과 상세 행을 유지하는지 검증한다.
- 화면 통합 집계 테스트 결과: **통과(3/3)**.
- 목록 payload 지연 조회 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/print_log_test.dart --plain-name "print log query contract keeps legacy scope and ordering|print log detail query loads payload by primary key"`.
- 목록 payload 지연 조회 테스트 수정 전 결과: **실패(예상 일치)**. `PrintLogDAO.buildDetailQuery`가 없어 컴파일되지 않았다.
- `lib/features/print_history/domain/print_log.dart` 2차 편집 완료: 상세 payload 전용 `PrintLogDetail` 모델을 추가했다.
- `lib/features/print_history/data/print_log_dao.dart` 3차 편집 완료: 목록 SELECT에서 `RICH_COLUMNS`, `RICH_PRINT_CELLS`, `RICH_SAVE_IN_DB_CELLS`를 제외하고 기본키 기반 `buildDetailQuery`/`selectDetail`을 추가했다.
- `lib/features/print_history/presentation/print_history_dialog.dart` 2차 편집 완료: 행 더블클릭 시 상세 payload를 지연 조회하며 조회 시작·완료·누락·실패 시간을 기록한다.
- `test/print_history_dialog_test.dart` 2차 편집 완료: 상세 payload 주입 API를 연결해 기존 상세 표시 동작을 검증한다.
- 목록/상세 SQL 테스트 결과: **통과(5/5)**. 화면 통합 집계·상세 지연 조회 테스트 결과: **통과(3/3)**.
- 재현 로그 검증 추가: 조회 4단계와 상세 지연 조회 2단계의 `printHistoryQuery` 이벤트가 실제 출력되는지 검증한다.
- 재현 로그 focused test 결과: **통과(1/1)**.
- `pubspec.yaml` 버전: `1.4.29` → `1.4.30`.
- 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/print_log_test.dart test/print_history_dialog_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/print_history/data/print_log_dao.dart lib/features/print_history/domain/print_log.dart lib/features/print_history/presentation/print_history_dialog.dart test/print_log_test.dart test/print_history_dialog_test.dart`.
- 관련 테스트 결과: **통과(8/8)**.
- analyzer 1차 결과: 불필요한 `flutter/foundation.dart` import info 1건. 해당 import를 제거했다.
- analyzer 최종 결과: **No issues found**.
- IDE diagnostics 결과: 변경 production/test 파일과 `pubspec.yaml` 오류 0건.
- DTD 확인 결과: VS Code DTD는 연결돼 있으나 실행 중인 앱이 없어 hot reload 대상 없음.
- 최종 관련 테스트 재실행 결과: **통과(8/8)**. 최종 `git diff --check` 통과.
- stage/commit 대상: `lib/features/print_history/data/print_log_dao.dart`, `lib/features/print_history/domain/print_log.dart`, `lib/features/print_history/presentation/print_history_dialog.dart`, `test/print_log_test.dart`, `test/print_history_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 구현 커밋: `5063439` (`발행내역 조회 성능 개선`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 현재 작업: 브랜드 복사 후선택 비활성화 누락
- **완료**: 관리자 복사에서 원본·대상 라벨크기까지 선택한 뒤 `브랜드 복사`를 체크하면 원본 라벨크기와 대상 브랜드·라벨크기가 비활성화되지 않는 1.4.16 회귀를 수정했다.
- 제출 로그 확인: source/target customer 선택 로그만 있고 브랜드 복사 토글 시 선택값과 selector 활성 상태 로그가 없어 당시 상태 전이를 판별할 수 없다.
- 원인 가설: checkbox handler가 `_copyWholeBrand`만 변경하고 `_sourceLabelSizeEnabled`, `_targetBrandEnabled`, `_targetLabelSizeEnabled`, `_copyEnabled`를 현재 선택값에 맞춰 재계산하지 않는다.
- 레거시 확인: 브랜드 복사 여부에 따라 이후 선택 이벤트에서 각 ComboBox 활성 상태를 전환하며 기존 선택값을 명시적으로 지우지는 않는다.
- 수정 전 회귀 테스트 추가: 원본·대상 라벨크기까지 모두 선택한 뒤 브랜드 복사를 체크하고 세 selector의 `onChanged`가 null인지 검증한다.
- 수정 전 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/admin_copy_dialog_test.dart --plain-name "brand checkbox disables completed label size selection"`.
- 수정 전 focused test 결과: **실패(예상 일치)**. 브랜드 복사 체크 후 원본 라벨크기의 `onChanged`가 계속 non-null이었다.
- `lib/features/admin_copy/presentation/admin_copy_dialog.dart` 편집 완료: `_changeCopyWholeBrand`가 현재 선택값과 mode를 기준으로 원본 라벨크기, 대상 거래처·브랜드·라벨크기 및 복사 버튼 활성 상태를 즉시 재계산한다.
- 재현 로그 추가: `adminCopy/copyWholeBrandChanged`에 mode, source/target 선택 ID, 네 selector와 복사 버튼 활성 상태를 기록한다.
- 수정 후 focused test 결과: **통과(1/1)**. 모두 선택한 뒤 체크하면 세 selector가 비활성화되고, 체크 해제 시 보존된 선택에 맞춰 다시 활성화된다.
- `pubspec.yaml` 버전: `1.4.28` → `1.4.29`.
- Dart formatter 적용 완료: `lib/features/admin_copy/presentation/admin_copy_dialog.dart`, `test/admin_copy_dialog_test.dart`.
- 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/admin_copy_dialog_test.dart test/admin_copy_dao_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/admin_copy/presentation/admin_copy_dialog.dart test/admin_copy_dialog_test.dart`.
- 관련 테스트 결과: **통과(15/15)**.
- analyzer 결과: **No issues found**.
- IDE diagnostics 결과: 변경 production/test 파일과 `pubspec.yaml` 오류 0건.
- DTD 확인 결과: VS Code DTD는 연결돼 있으나 실행 중인 앱이 없어 hot reload 대상 없음.
- 최종 `git diff --check` 통과, 관련 파일 외 포맷 churn 없음.
- stage/commit 대상: `lib/features/admin_copy/presentation/admin_copy_dialog.dart`, `test/admin_copy_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 dirty `lib/core/app.dart` 제외.
- 기능 구현 커밋: `89b311a` (`브랜드 복사 후선택 비활성화 수정`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 현재 작업: 관리자 브랜드 품목 복사 PK 오류
- **완료**: 관리자 복사에서 동일 거래처의 브랜드를 `품목까지 복사`하면 `@ItemMap`의 `SOURCE_ITEM_ID=722764` PK 중복으로 실패하는 1.4.16 회귀를 수정했다.
- 제출 로그 확인: source/target customerId=2, sourceBrandId=1288, copyItems=true이며 SQL Server native 2627 오류가 두 번째 라벨크기 처리 중 `@ItemMap`에 발생했다.
- 원인 가설: 브랜드의 라벨크기 반복문 안에서 선언된 `_copyItems` 테이블 변수가 반복 간 유지된다. `@SourceItems` IDENTITY는 계속 증가하지만 `@ItemRowNo=1`로 재시작해 이전 source item ID를 재사용하고, 비워지지 않은 `@ItemMap` PK에 중복 삽입한다.
- 수정 전 회귀 테스트 추가: 각 라벨크기 처리 전에 품목/매핑 작업 테이블을 비우고 현재 `@SourceItems`의 `MIN/MAX(ROW_NO)`를 순회하는 SQL 계약을 검증한다.
- 수정 전 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/admin_copy_dao_test.dart --plain-name "brand item copy resets mappings for every label size"`.
- 수정 전 focused test 결과: **실패(예상 일치)**. `DELETE FROM @SourceItems`가 없어 첫 assertion에서 실패했다.
- `lib/features/admin_copy/data/admin_copy_dao.dart` 편집 완료: `_copyItems` 시작 시 5개 작업 테이블을 초기화하고, 누적 IDENTITY에 맞춰 현재 행의 `MIN/MAX(ROW_NO)`를 순회한다.
- 재현 로그 추가: `adminCopyBrandSql`의 `transactionRequested`, `transactionCompleted`, `transactionFailed`에 sourceBrandId/targetCustomerId/copyItems/targetFirstMarketId와 `itemWorkspaceReset=v1`을 기록하고 오류는 그대로 재전파한다.
- 수정 후 focused test 결과: **통과(1/1)**. 초기화가 브랜드 라벨크기 반복문 내부이며 현재 source item identity 구간만 순회하는지 확인했다.
- `pubspec.yaml` 버전: `1.4.27` → `1.4.28`.
- Dart formatter 적용 완료: `lib/features/admin_copy/data/admin_copy_dao.dart`, `test/admin_copy_dao_test.dart`.
- 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/admin_copy_dao_test.dart test/admin_copy_dialog_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/admin_copy/data/admin_copy_dao.dart test/admin_copy_dao_test.dart lib/features/admin_copy/presentation/admin_copy_dialog.dart test/admin_copy_dialog_test.dart`.
- 관련 테스트 결과: **통과(14/14)**.
- analyzer 결과: **No issues found**.
- 운영 DB에 데이터를 생성하는 관리자 복사 실행은 자동 수행하지 않았으며, SQL Server 반복 상태는 DAO SQL 계약 테스트로 검증했다.
- IDE diagnostics 결과: 변경 production/test 파일과 `pubspec.yaml` 오류 0건.
- DTD 확인 결과: VS Code DTD는 연결돼 있으나 실행 중인 앱이 없어 hot reload 대상 없음.
- 최종 `git diff --check` 통과, 관련 파일 외 포맷 churn 없음.
- stage/commit 대상: `lib/features/admin_copy/data/admin_copy_dao.dart`, `test/admin_copy_dao_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 dirty `lib/core/app.dart` 제외.
- 기능 구현 커밋: `f9b2d69` (`관리자 브랜드 품목 복사 PK 오류 수정`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 현재 작업: 관리자 복사 거래처 검색 중 멈춤
- **완료**: 파일/관리 → 관리자 복사에서 거래처 검색 메뉴를 연 뒤 프로그램이 멈추고 디버그 재진입 시 화면 분할 및 반복 예외가 발생하는 1.4.16 회귀를 수정했다.
- 제출 로그 확인: `dropdownSearch/opened` 직후 조상 `Expanded` build 중 `ModelessDropdownFormField.didUpdateWidget`가 `_menuEntry.markNeedsBuild()`를 호출해 `setState() or markNeedsBuild() called during build`가 발생한다. 이후 layout overflow와 deactivated context gesture 예외는 손상된 widget tree의 후속 증상이다.
- 원인 가설: 열린 dropdown의 부모 rebuild에서 overlay를 동기 갱신하는 것이 직접 원인이다. overlay 갱신을 다음 frame으로 예약하고 동일 entry/mounted 여부를 재확인해야 한다.
- 수정 전 회귀 테스트 추가: 검색 메뉴가 열린 상태에서 부모를 rebuild하고 Flutter 예외 없이 메뉴가 유지되는지 검증한다.
- 수정 전 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/modeless_dropdown_form_field_test.dart --plain-name "parent rebuild while search menu is open keeps overlay stable"`.
- 수정 전 focused test 결과: **실패(예상 일치)**. `StatefulBuilder` build 중 `didUpdateWidget:77 → OverlayEntry.markNeedsBuild` 호출로 제출 로그와 동일한 framework assertion 및 후속 layout/semantics 오류를 재현했다.
- `lib/widgets/modeless_dropdown_form_field.dart` 편집 완료: 열린 overlay 갱신을 coalesced post-frame callback으로 예약하고, callback 시 동일 entry 및 mounted 상태를 재검증한다. disabled 전환은 이어지는 build를 사용해 별도 `setState` 없이 메뉴를 닫는다.
- 재현 로그 추가: `dropdownSearch`의 `refreshScheduled`, `refreshApplied`, `refreshSkipped` 이벤트에 control/scheduler phase/entry 상태를 기록한다.
- 수정 후 focused test 결과: **통과(1/1)**. 부모 rebuild 중 예외 없이 검색 overlay가 유지된다.
- 공용 dropdown + 관리자 복사 다이얼로그 테스트 결과: **통과(12/12)**.
- `test/modeless_dropdown_form_field_test.dart` 보강: 로그에 `refreshScheduled phase=persistentCallbacks`와 `refreshApplied`가 기록되는지 검증한다.
- `pubspec.yaml` 버전: `1.4.26` → `1.4.27`.
- 로그 검증 focused test 결과: **통과(1/1)**. `debugPrint`는 foundation invariant 검사 전에 `try/finally`로 즉시 복원한다.
- Dart formatter 적용 완료: `lib/widgets/modeless_dropdown_form_field.dart`, `test/modeless_dropdown_form_field_test.dart`.
- 최종 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/modeless_dropdown_form_field_test.dart test/admin_copy_dialog_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/widgets/modeless_dropdown_form_field.dart test/modeless_dropdown_form_field_test.dart lib/features/admin_copy/presentation/admin_copy_dialog.dart test/admin_copy_dialog_test.dart`.
- 최종 관련 테스트 결과: **통과(12/12)**.
- analyzer 결과: **No issues found**.
- IDE diagnostics 결과: 변경 production/test 파일과 `pubspec.yaml` 오류 0건.
- DTD 확인 결과: VS Code DTD는 연결돼 있으나 실행 중인 앱이 없어 hot reload 대상 없음.
- 최종 `git diff --check` 통과, 관련 파일 외 포맷 churn 없음.
- stage/commit 대상: `lib/widgets/modeless_dropdown_form_field.dart`, `test/modeless_dropdown_form_field_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 dirty `lib/core/app.dart` 제외.
- 기능 구현 커밋: `8ae219e` (`관리자 복사 거래처 검색 멈춤 수정`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 현재 작업: 병합 셀 포함 범위 테두리 누락
- **완료**: 공용라벨관리에서 `B2:C2`, `D3:D4`를 병합한 뒤 `B2:D4` 범위에 전체 테두리를 적용하면 일부 우측·하단 테두리가 표시되지 않는 1.4.16 회귀를 수정했다.
- 제출 로그: `.tmp/1.4.16로그/공용라벨관리_병합셀 테두리 미적용.log`의 초기 구간에는 로그인·DB 초기화만 있고 테두리 command/선택/병합/계산 결과 로그가 없다.
- 원인 확정: D4 병합 follower hit-test가 D3 anchor로 정규화된 뒤 저장 range만 `B2:D4`로 확장되고 runtime `FortuneSelection.rowEnd`는 D3에 남았다. toolbar가 runtime selection을 사용해 실제 command range를 `B2:D3`으로 축약했다.
- `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 편집 완료: `_updateSelectionDrag`가 drag 방향에 맞는 병합 확장 range 경계를 runtime selection end에도 기록하도록 수정했다.
- 재현 로그 추가 완료: `fortune-merged-border-debug-v1`에 drag anchor/hit/expanded/selectionEnd와 toolbar command range/merge/border cell 수를 기록한다.
- 수정 전 계산 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_border_compute_test.dart --plain-name "mixed merged cells preserve selected range border edges"`.
- 수정 전 계산 focused test 결과: **통과(1/1)**. `D2` 우측·하단, `D3:D4` 병합영역 상단·우측·하단 edge가 모두 계산돼 `_removeMergeInnerBorders` 원인 가설은 기각됐다.
- 제출 로그 키워드 재검색 결과: `border|merge|toolbar|selection|테두리|병합` 기록이 없어 당시 command/선택/병합/계산 상태를 확인할 수 없다.
- 수정 전 painter focused test 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_sheet_painter_test.dart --plain-name "mixed merged cells paint selected range border edges"`.
- 수정 전 painter focused test 결과: **통과(1/1)**. 동일 병합 배치의 `D2/D3` 공유선, `D3:D4` 우측선, `B4:D4` 하단선이 모두 실제 픽셀로 렌더돼 painter 원인 가설도 기각됐다.
- `third_party/fortune_sheet/test/fortune_merged_border_selection_test.dart` 추가 완료: 실제 `B2 → D4` drag와 toolbar 전체 테두리 적용 후 command range `B2:D4`, B4/C4 하단 edge를 검증한다.
- toolbar focused test 결과: **통과(1/1)**. `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_merged_border_selection_test.dart --plain-name "toolbar border preserves mixed merged selection edges"`.
- 기존 toolbar drag focused test 결과: **통과(1/1)**. `toolbar border popup uses dragged selection range`의 비병합 선택 동작을 유지한다.
- IDE diagnostics 결과: production 및 관련 테스트 파일 오류 0건.
- `pubspec.yaml` 버전: `1.4.25` → `1.4.26`.
- Dart formatter 적용 완료: production 파일과 계산/painter/widget 회귀 테스트 파일.
- 관련 테스트 파일 전체 결과: 이번 병합 테두리 3개 테스트는 통과했으나 painter의 기존 별도 테스트 `typed object culling includes exact clip boundary contact`가 예상 픽셀 `>20`, 실제 `0`으로 1건 실패했다(791개 실행 시점). 이번 선택/border 변경과 직접 관련 없음.
- 병합 테두리 focused 테스트 재실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_border_compute_test.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart third_party/fortune_sheet/test/fortune_merged_border_selection_test.dart --name "mixed merged cells|toolbar border preserves"`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/test/fortune_border_compute_test.dart third_party/fortune_sheet/test/fortune_sheet_painter_test.dart third_party/fortune_sheet/test/fortune_merged_border_selection_test.dart`.
- 병합 테두리 focused 테스트 최종 결과: **통과(3/3)**.
- 기존 비병합 toolbar drag focused 테스트 최종 결과: **통과(1/1)**.
- analyzer 결과: 새 오류 없음. 기존 `fortune_sheet_canvas.dart`의 미사용 필드/메서드 경고 10건으로 종료 코드 1이며 이번 변경 구간의 새 경고는 없다.
- IDE diagnostics 최종 결과: production 및 관련 테스트 파일 오류 0건.
- DTD 확인 결과: VS Code DTD는 연결돼 있으나 실행 중인 앱이 없어 hot reload 대상 없음.
- 최종 `git diff --check` 통과, 관련 파일 외 포맷 churn 없음.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, 계산/painter/widget 회귀 테스트 3개, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 dirty `lib/core/app.dart` 제외.
- 기능 구현 커밋: `492c8d6` (`병합 셀 범위 테두리 누락 수정`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 완료 작업: 품목 출력 미리보기 연결 바코드 렌더링
- **완료**: 공용라벨의 바코드 개체를 `바코드 (#BARCODE)`에 연결한 뒤 품목 값 `88123456789012`를 입력해도 출력 내용 미리보기에 저장 당시 표시용 바코드가 남는 1.4.16 회귀를 수정했다.
- 재현 로그 확인: `.tmp/1.4.16로그/공용라벨관리_바코드 미표시.log`에는 저장 workbook과 미리보기 생성 흔적은 있으나 연결 바코드의 resolve/render 단계 로그가 없다.
- 원인 확인: `_replaceImageKeywords`는 `barcodeObjectId`를 `ItemCodeDataResolver`로 해석해 `barcodeText` metadata만 교체하고 실제 표시되는 `FortuneImage.src`는 저장 당시 PNG로 유지한다.
- 구현 방향: 품목 출력 미리보기에서 치환된 barcode metadata로 `labelSheetBarcodeRenderer`를 실행하고, 완료된 PNG `src`가 준비된 뒤 `LabelOutputPreview`를 표시/캡처한다.
- 재현 로그 계획: `itemOutputBarcode` feature에 objectId/text/format/geometry 및 render 성공·실패를 기록한다.
- 수정 전 focused test 추가: `barcodeText=88123456789012` metadata를 renderer 요청에 전달하고 기존 `src`를 반환 PNG data URI로 교체하는지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "item output preview renders resolved barcode image source"`.
- 수정 전 테스트 결과: **실패(예상)**. 재렌더 helper가 없었고, 테스트 fixture의 잘못된 `const Uint8List.fromList`도 확인해 함께 수정했다.
- `lib/home_page_manager.dart` 편집 완료: 연결값 해석 성공 metadata를 표시하고, 품목 미리보기에서 해당 바코드를 `labelSheetBarcodeRenderer`로 비동기 렌더한 뒤 PNG `src`와 body geometry를 갱신한다. 미리보기/출력 캡처는 렌더 완료 workbook을 사용한다.
- 재현 로그 추가: `regression-debug-v1 feature=itemOutputBarcode`의 `renderStarted`, `renderCompleted`, `renderFailed`, `renderException` 이벤트에 objectId/text/format/geometry/결과를 기록한다.
- `test/label_sheet_toolbar_test.dart` 편집 완료: `88123456789012`가 renderer 요청에 전달되고 반환 PNG data URI와 body ratio가 적용되는지 검증한다.
- focused test 재실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "item output preview renders resolved barcode image source"`.
- focused test 결과: **통과(1/1)**. `itemOutputBarcode/renderStarted` 및 `renderCompleted` 로그에서 `objectId=#BARCODE text=88123456789012 format=code128`을 확인했다.
- Dart formatter 적용 완료: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`.
- IDE diagnostics 결과: production/test 파일 오류 0건.
- 앱 바코드 관련 테스트 결과: **통과(7/7)**.
- `pubspec.yaml` 버전: `1.4.24` → `1.4.25`.
- 품목 출력 미리보기 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "item output preview"`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/home_page_manager.dart test/label_sheet_toolbar_test.dart`.
- analyzer 1차 결과: **No issues found**.
- 품목 출력 미리보기 관련 테스트 1차 결과: 8개 중 1개 실패. 바코드가 없는 일반 미리보기까지 Future 경로를 거치며 `item output preview keeps zoom after panel recreation`의 폭맞춤 적용 시점이 바뀌었다.
- 회귀 보정: `itemCodePreviewResolved=true`인 연결 바코드가 있는 workbook만 비동기 재렌더하고, 일반 미리보기는 기존 동기 `LabelOutputPreview` 경로를 유지한다.
- zoom focused test 재실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "item output preview keeps zoom after panel recreation"`.
- zoom focused test 결과: **통과(1/1)**.
- 품목 출력 미리보기 관련 테스트 최종 결과: **통과(9/9)**.
- analyzer 최종 결과: **No issues found**(종료 코드 0).
- IDE diagnostics 최종 결과: production/test 파일과 `pubspec.yaml` 오류 0건.
- 첨부 화면 추가 확인: 흰색 `#BARCODE` 박스는 저장 PNG가 아니라 painter의 편집용 연결 ID 오버레이다. 재렌더 완료된 미리보기 사본에서 `barcodeObjectId` metadata를 제거해 숫자 바코드를 가리지 않도록 보정하고, 원본 공용라벨 데이터는 유지한다.
- 오버레이 제거 focused test 재실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "item output preview renders resolved barcode image source"`.
- 오버레이 제거 focused test 결과: **통과(1/1)**.
- 최종 품목 출력 미리보기 관련 테스트 결과: **통과(9/9)**.
- 최종 analyzer 결과: **No issues found**(종료 코드 0).
- 최종 IDE diagnostics 결과: production/test 파일과 `pubspec.yaml` 오류 0건.
- 최종 diff 검토 예정: `git diff --check`, `git status --short`, 관련 파일 diff 확인.
- stage/commit 대상: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 dirty `lib/core/app.dart` 제외.
- 최종 diff 검토 완료: `git diff --check` 통과, 관련 파일 외 무관한 포맷 변경 없음.
- 기능 구현 커밋: `75f5593` (`품목 미리보기 연결 바코드 렌더링`).
- DTD 확인 결과: VS Code DTD는 연결돼 있으나 실행 중인 앱이 없어 hot reload 대상 없음.
- 최종 diff 검토 예정: `git diff --check`, `git status --short`, 관련 파일 diff 확인.
- stage/commit 예정: `lib/home_page_manager.dart`, `test/label_sheet_toolbar_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 dirty `lib/core/app.dart` 제외.
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 완료 작업: 바코드 개체 속성 형식 ComboBox
- **완료**: 시트의 바코드 개체를 선택했을 때 `바코드 속성`의 형식을 자유 입력 TextField가 아닌 삽입 다이얼로그와 동일한 형식 목록 ComboBox로 변경했다.
- 현재 원인: `FortuneObjectLayerPanel`은 barcode format 목록을 받지 않으며 `_ObjectPropertyEditor`가 `barcodeFormatId`를 일반 `_field` TextField로 렌더링한다.
- 구현 방향: `LabelSheetWorkbench`의 `labelSheetBarcodeFormats`를 개체 패널까지 전달하고, metadata `barcodeFormatId`를 초기 선택값으로 사용하는 DropdownButtonFormField로 교체한다.
- 재현 로그 계획: 패널 초기화와 형식 선택 변경 시 objectId/previous/next/options/matched 및 데이터 필터 전후 길이를 기록한다.
- 수정 전 focused test 추가: 삽입 metadata가 `code128`인 바코드의 형식 컨트롤이 ComboBox이고 초기 표시가 `Code128`, 옵션이 `Code128`/`EAN13`인지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_object_controller_test.dart --plain-name "barcode property format uses insert formats and initial selection"`.
- 수정 전 테스트 결과: **실패(예상)**. `FortuneObjectLayerPanel`에 `barcodeFormats` named parameter가 없어 컴파일 실패했다. 테스트의 Flutter API 비호환 `DropdownButtonFormField.items` 직접 접근은 실제 메뉴 표시 검증으로 교체했다.
- `third_party/fortune_sheet/lib/src/fortune_object_layer_panel.dart` 편집 완료: panel/editor에 `barcodeFormats` 전달, metadata format ID 정규 매칭, 형식 DropdownButtonFormField, 변경 시 데이터 formatter/draft 갱신, `fortune-object-barcode-format-debug-v1` 초기화/변경 로그를 추가했다.
- `third_party/fortune_sheet/test/fortune_object_controller_test.dart` 편집 완료: ComboBox 초기값/실제 메뉴 옵션 회귀 테스트를 추가하고 기존 draft 테스트의 형식 변경을 실제 dropdown 선택으로 전환했다.
- focused test 1차는 높이 700인 속성 lazy list가 형식 필드를 아직 build하지 않아 finder가 비어 실패했다. 기존 패널 테스트와 동일한 높이 1200으로 조정했다.
- focused test 재실행 결과: **통과(1/1)**. 로그에서 `metadataFormat=code128 selectedFormat=code128 matched=true options=2`를 확인했다.
- `lib/features/label_sheet/label_sheet_workbench.dart` 편집 완료: 실제 개체 패널에도 canvas와 동일한 `labelSheetBarcodeFormats`를 전달한다.
- 로그 보정 완료: object 식별자를 `kind/id`로 기록한다.
- `pubspec.yaml` 버전: `1.4.23` → `1.4.24`.
- 기존 draft 회귀 + 새 ComboBox 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_object_controller_test.dart --plain-name "barcode property"`.
- 기존 draft 회귀 + 새 ComboBox 테스트 결과: **통과(4/4)**. `CODE128 → ean13 → CODE128` 선택 로그와 데이터 필터 길이 변화를 확인했다.
- Dart formatter 적용 완료: `fortune_object_layer_panel.dart`, `fortune_object_controller_test.dart`, `label_sheet_workbench.dart`.
- 전체 개체 컨트롤 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_object_controller_test.dart`.
- 앱 바코드/툴바 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze third_party/fortune_sheet/lib/src/fortune_object_layer_panel.dart lib/features/label_sheet/label_sheet_workbench.dart third_party/fortune_sheet/test/fortune_object_controller_test.dart test/label_sheet_toolbar_test.dart`.
- 전체 개체 컨트롤 테스트 결과: **통과(50/50)**.
- `label_sheet_toolbar_test.dart` 전체 결과: **실패(203 통과/1 실패)**. 실패는 이번 변경과 무관한 기존 RTF 문자셋 테스트 `item element RTF conversion decodes Korean ANSI hex`이며 예상 문자열과 실제 mojibake가 달랐다(`?쒗뭹紐? ?멸린` 예상, `?쒗뭹紐? ?り린` 실제).
- 앱 바코드 관련 테스트 재실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "barcode"`.
- 앱 바코드 관련 테스트 결과: **통과(6/6)**. 실제 workbench 패널 초기화 로그에서 `selectedFormat=code128 matched=true options=13`을 확인했다.
- IDE diagnostics 결과: production/test 파일과 `pubspec.yaml` 오류 0건.
- analyzer 결과: **No issues found**(종료 코드 0).
- DTD 확인 결과: VS Code DTD 연결 성공, 연결된 실행 앱이 없어 hot reload 대상 없음.
- 최종 diff 검토 완료: `git diff --check` 통과, 관련 파일 외 무관한 포맷 변경 없음.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_object_layer_panel.dart`, `third_party/fortune_sheet/test/fortune_object_controller_test.dart`, `lib/features/label_sheet/label_sheet_workbench.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 dirty `lib/core/app.dart` 제외.
- 기능 구현 커밋: `f1225f7` (`바코드 속성 형식 선택 목록 적용`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 완료 작업: 공용라벨 이름 열 더블클릭 삽입 재검증
- **완료**: 우측 `사용 항목`의 이름 셀을 더블클릭하면 키워드 셀과 동일하게 현재 편집 위치에 `#키워드`를 삽입하는 요청을 현재 코드 기준으로 재검증했다.
- 구현 확인: `common_label_manage.dart`는 키워드·이름 열(`index < 2`) 모두 `_insertKeyword`를 호출하며, `LabelSheetKeywordInsertController.insertAtCurrentContext('#${row.keyword}')`를 사용한다.
- 재현 로그 확인: `regression-debug-v1 feature=commonLabelKeyword event=doubleTapInsert`에 column/rowIndex/keyword/name/inserted를 기록한다.
- 기존 테스트 한계: FortuneTable column callback을 직접 호출해 실제 이름 셀의 double-tap gesture 연결은 검증하지 않았다.
- 테스트 강화: 이름 열 검증을 실제 `저울중량` 셀 두 번 탭으로 교체해 `#SWEIGHT` 삽입을 확인한다.
- focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/common_label_manage_test.dart --plain-name "keyword and name columns insert keyword on double tap"`.
- focused test 1차 결과: 실제 삽입 assertion은 통과했으나 테스트 종료 시 `DoubleTapGestureRecognizer` Timer가 남아 실패했다. 제스처 후 `pumpAndSettle`로 Timer를 정리하도록 테스트를 보정했다.
- focused test 재실행 결과: **통과(1/1)**.
- 재현 로그 검증 강화: 실제 이름 셀 더블클릭 시 `commonLabelKeyword/doubleTapInsert` 로그의 `column=이름`, `keyword=SWEIGHT`, `name=저울중량`, `inserted=true`를 확인한다.
- 로그 검증 focused test 1차는 nullable `debugPrint` message 타입으로 로드 실패해 null 메시지를 제외하도록 캡처를 보정했다.
- 로그 검증 focused test 2차는 Flutter 전역 debug 변수 복원 시점 assertion으로 실패해, 캡처 범위를 실제 더블클릭 구간으로 좁히고 `try/finally`에서 즉시 복원하도록 보정했다.
- 로그 검증 focused test 최종 결과: **통과(1/1)**.
- Dart formatter 적용 완료: `test/common_label_manage_test.dart`.
- IDE diagnostics 결과: production/test 파일과 `pubspec.yaml` 오류 0건.
- DTD 확인 결과: 연결된 실행 앱이 없어 hot reload 대상 없음.
- 공용라벨 관리 전체 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/common_label_manage_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/label_sheet/presentation/common_label_manage.dart test/common_label_manage_test.dart`.
- 공용라벨 관리 전체 테스트 결과: **통과(13/13)**.
- analyzer 결과: **No issues found**(종료 코드 0).
- production 결론: 이름 열 삽입 콜백과 재현 로그가 이미 구현돼 있어 동작 코드 추가 변경은 필요하지 않았다.
- 최종 diff 검토 완료: `git diff --check` 통과, 테스트·버전·handoff 외 무관한 포맷 churn 없음.
- stage/commit 대상: `test/common_label_manage_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `25d24132dc342f0bc24d07c718086ce079ed89d9` (`공용라벨 이름 더블클릭 삽입 검증 강화`).
- `pubspec.yaml` 편집 완료: 기존 기능의 실제 UI 제스처와 로그 회귀 검증 보강이므로 PATCH 단계로 `1.4.22`에서 `1.4.23`으로 갱신했다.
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 완료 작업: GS1 AI 포함 항목 저장 실패
- **완료**: 1.4.16에서 GS1AL의 AI code를 저장한 뒤 GS1BARCODE에 `#GS1AL`을 포함하고 저장하면 `Unsupported changed property key for column 140793`로 실패하는 증상을 수정했다.
- 제출 로그/코드 확인: `LabelColumnDraft.persistedValues`는 `useGs1` 변경을 생성하지만 `LabelColumnSaveDao._validateCommand` auxiliary allow-list와 GS1 SQL projection에는 `useGs1`이 빠져 있다.
- 레거시 확인: GS1 AI 포함 추가 시 `SetGS1CodeSetting(TRUE, 포함ID, CODE128)`로 사용 여부와 포함 관계를 함께 설정한다. 현재 DB 조회의 `USE_GS1_CODE`는 `BM_GS1_CONTAIN_COLUMN` 관계 존재 여부로 파생된다.
- 구현 방향: `useGs1`을 저장 command의 지원 key로 포함하고 XML projection 및 touched GS1 row에 전달한다. false이면 포함 관계를 삭제만 하고, true이면 유효한 포함 ID를 다시 삽입한다.
- 재현 로그: 저장 command 검증과 GS1 관계 적용 시 columnId/type/useGs1/changedKeys/contain count를 기록하되 로그에는 업무 판단을 넣지 않는다.
- 수정 전 focused test 추가 및 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_column_save_test.dart --plain-name "GS1 barcode use and contain changes build save statement"`.
- 수정 전 focused test 결과: **실패(예상 일치)**. `Bad state: Unsupported changed property key for column 140793`를 재현했다.
- `lib/features/label_column/data/label_column_save.dart` 편집 완료: `useGs1`을 새/수정 GS1 projection과 touched row에 포함하고, false일 때 포함 관계를 재삽입하지 않도록 제한했다.
- 재현 로그 추가 완료: `labelColumnGs1Save`의 `buildRequested`, `validated`, `validationRejected` 이벤트에 columnId/type/useGs1/changedKeys/containCount/unsupported를 기록한다.
- 수정 후 DAO focused test 결과: **통과(1/1)**.
- `test/label_column_edit_dialog_test.dart` 강화: 실제 GS1 barcode 편집 command의 `useGs1` changed key와 DAO statement 생성 성공을 검증한다.
- `test/label_column_save_test.dart` 강화: GS1 사용=false일 때 관계를 재삽입하지 않는 SQL gate가 INSERT/검증 양쪽에 있는지 확인한다.
- 다이얼로그 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_column_edit_dialog_test.dart --plain-name "GS1 barcode shows contain column IDs as keywords"`.
- 다이얼로그 focused test 결과: **통과(1/1)**.
- `pubspec.yaml` 편집 완료: 호환 가능한 국소 저장 버그 수정이므로 PATCH 단계로 `1.4.21`에서 `1.4.22`로 갱신했다.
- Dart formatter 적용 후 라벨 항목 편집·저장 전체 테스트 및 analyzer 실행 예정.
- Dart formatter 적용 완료: `label_column_save.dart`, `label_column_save_test.dart`, `label_column_edit_dialog_test.dart`.
- IDE diagnostics 결과: 변경 production/test 파일과 `pubspec.yaml` 오류 0건.
- 관련 전체 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_column_edit_test.dart test/label_column_edit_dialog_test.dart test/label_column_save_test.dart`.
- 관련 전체 테스트 결과: **통과(53/53)**.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/label_column/data/label_column_save.dart test/label_column_save_test.dart test/label_column_edit_dialog_test.dart`.
- analyzer 결과: **No issues found**(종료 코드 0).
- DTD 확인 결과: 연결된 실행 앱이 없어 hot reload 대상 없음.
- 최종 diff 검토 완료: `git diff --check` 통과, SQL projection 필드/SELECT 순서와 GS1 relation gate 정합성 확인, 무관한 포맷 churn 없음.
- stage/commit 대상: `label_column_save.dart`, `label_column_save_test.dart`, `label_column_edit_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `cb749aff0c5bd9c0ccc48eda3d416d9eb7cf804e` (`GS1 AI 포함 항목 저장 오류 수정`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 완료 작업: 공용라벨 Ctrl+Z 후 저장 아이콘 무반응
- **완료**: 1.4.16에서 12행 복사본을 14·15행에 붙여넣고 15행을 Ctrl+Z로 취소한 뒤 저장 아이콘이 반응하지 않으며, `SPRICE` 필수등록 체크 해제 후에야 저장되는 증상을 수정했다.
- 제출 로그 확인: 첫 시트 변경 직후 dirty=true였지만 저장 callback은 약 47초 동안 시작되지 않았고, `SPRICE` 체크 해제로 부모가 재빌드된 직후 시작됐다. 이후 필수 누락 경고와 DB 저장은 정상 완료됐다.
- 원인 가설: FortuneSheet 히스토리 snapshot의 JSON 복제에서 `customToolbarItems.onClick`이 제외되고, Undo가 callback 없는 저장 항목을 복원한다. 부모 재빌드가 live settings를 다시 주입하면 저장이 복구된다.
- 판별 테스트 수정 완료: 기존 Ctrl+Z 회귀 테스트의 settings callback 직접 호출을 실제 화면 저장 아이콘 탭으로 교체했다. 수정 전 `savedPayload`가 null로 **실패(예상 일치)**해 내부 toolbar callback 소실을 확인했다.
- `third_party/fortune_sheet/lib/src/fortune_sheet_codec.dart` 편집 완료: custom toolbar 항목 역직렬화 시 동일 key의 fallback 항목에서 직렬화 불가능한 `onClick`만 복원한다.
- `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart` 편집 완료: workbook 복제는 기존 설정 복원 의미를 유지하며, Undo/toolbar 상태 로그만 추가한다.
- `third_party/fortune_sheet/test/fortune_sheet_codec_test.dart` 테스트 추가: JSON tooltip/disabled를 유지하면서 동일 key fallback의 runtime callback만 복원하는 계약을 검증한다.
- codec focused test 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_sheet_codec_test.dart --plain-name "workbookFromJson restores custom toolbar runtime callback"`.
- codec focused test 결과: **통과(1/1)**.
- IDE diagnostics 결과: 변경 production/test 파일과 `pubspec.yaml` 오류 0건.
- DTD 확인 결과: 연결된 실행 앱이 없어 hot reload 대상 없음.
- Dart formatter 적용 완료: `fortune_sheet_codec.dart`, `fortune_sheet_codec_test.dart`, `label_sheet_toolbar_test.dart`. 대형 `fortune_sheet_canvas.dart`는 변경 구간만 수동 정리해 불필요한 전면 포맷을 피했다.
- codec 전체 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_sheet_codec_test.dart`.
- 라벨시트 툴바 전체 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart`.
- codec 전체 테스트 결과: **통과(135/135)**.
- 라벨시트 툴바 전체 테스트 결과: **203/204 통과**, 수정과 무관한 `Gemini HTTP errors include response diagnostics`가 외부 Gemini API HTTP 429 `RESOURCE_EXHAUSTED`로 실패했다.
- 저장 관련 테스트 재검증 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "label sheet save"`.
- FortuneSheet custom toolbar 입력 검증 예정: `C:/Flutter/bin/flutter.bat test third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart --plain-name "canvas custom toolbar item invokes callback"`.
- 저장 관련 테스트 재검증 결과: **통과(3/3)**.
- FortuneSheet custom toolbar 입력 검증 결과: **통과(1/1)**.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart third_party/fortune_sheet/lib/src/fortune_sheet_codec.dart third_party/fortune_sheet/test/fortune_sheet_codec_test.dart test/label_sheet_toolbar_test.dart`.
- analyzer 1차 결과: 이번 변경의 불필요한 `foundation.dart` import 1건과 `fortune_sheet_canvas.dart`의 기존 미사용 항목 10건으로 종료 코드 1. 신규 import는 제거하고 기존 범위 밖 경고는 수정하지 않는다.
- analyzer 재검증 결과: 전체 지정 분석에는 `fortune_sheet_canvas.dart`의 기존 unused warning 10건만 남았고, codec 및 두 테스트 파일 분석은 **No issues found**(종료 코드 0).
- 최종 diff 검토 완료: `git diff --check` 통과, 요청 관련 6개 파일 외 무관한 포맷 churn 없음.
- stage/commit 대상: `fortune_sheet_canvas.dart`, `fortune_sheet_codec.dart`, `fortune_sheet_codec_test.dart`, `label_sheet_toolbar_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `0886ac9c75215733d853d907ae8c825254cb9a88` (`공용라벨 실행 취소 후 저장 복구`).
- 재현 로그 추가: `fortune-history-toolbar-debug-v1`으로 Undo 복원 전 current/snapshot callback 상태와 custom toolbar 클릭의 command/disabled/callback/undo/redo 상태를 기록한다.
- 수정 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_sheet_toolbar_test.dart --plain-name "label sheet save remains available after undoing latest paste"`.
- 수정 후 focused test 결과: **통과(1/1)**. 로그에서 `undoRestore`의 save/print callback과 `customToolbarClick` callback이 모두 true로 확인됐다.
- `pubspec.yaml` 편집 완료: 호환 가능한 국소 저장 버그 수정이므로 PATCH 단계로 `1.4.20`에서 `1.4.21`로 갱신했다.
- Dart formatter 적용 및 관련 전체 테스트/analyzer 실행 예정.
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 완료 작업: 타임바코드 종류 ComboBox 및 제한
- **완료**: 라벨 항목 편집의 정수 `타임바코드` 입력을 레거시와 같은 ComboBox로 변경하고 EAN13·UPC-A·EAN8에서는 비활성화한다.
- 레거시 확인: 옵션은 `사용안함(0)`, `DDMM(1)`, `HHDD(2)`, `DDHH(4)`, `YYMMDD(9)`이며 EAN13·UPC-A에서는 비활성화와 함께 `사용안함`으로 초기화한다. EAN8도 타임바코드 지원 대상이 아니다.
- 현재 원인: `label_column_edit_dialog.dart`가 `timeBarcodeType`을 자유 정수 `TextFormField`로 노출해 허용 종류를 선택할 수 없고 바코드 종류별 제한도 없다.
- 구현 방향: 기존 정수 저장 포맷은 유지하고 위 5개 값만 제공하는 ComboBox를 사용한다. EAN13·UPC-A·EAN8 선택 시 비활성화하고 stale 값을 `0`으로 정규화한다.
- 디버그 로그: 바코드 종류 변경과 타임바코드 선택 시 columnId/keyword/barcodeType/previous/next/enabled를 기록한다. 로그 함수에는 비즈니스 로직을 넣지 않는다.
- `lib/features/label_column/presentation/label_column_edit_dialog.dart` 편집 완료: 레거시 5개 옵션의 `DropdownMenu<int>`를 추가하고 EAN13·UPC-A·EAN8에서 비활성화 및 `0` 초기화한다. 바코드 종류/타임바코드 변경을 `regression-debug-v1` 로그로 기록한다.
- `test/label_column_edit_dialog_test.dart` 편집 완료: 옵션 값, 세 제한 바코드 정책, 실제 DDHH 선택 후 EAN13 전환 시 `사용안함` 초기화·비활성화를 검증한다.
- focused 테스트 결과: 정책 **2/2**, 위젯 상호작용 **1/1** 통과.
- `pubspec.yaml` 편집 완료: 기존 타임바코드 속성의 UI/활성화 조건 개선이므로 PATCH 단계로 `1.4.19`에서 `1.4.20`으로 갱신했다.
- Dart formatter 적용 완료: `label_column_edit_dialog.dart`, `label_column_edit_dialog_test.dart`.
- 관련 테스트 명령: `C:/Flutter/bin/flutter.bat test test/label_column_edit_dialog_test.dart test/label_column_edit_test.dart test/label_column_save_test.dart`.
- analyzer 명령: `C:/Flutter/bin/flutter.bat analyze lib/features/label_column/presentation/label_column_edit_dialog.dart test/label_column_edit_dialog_test.dart`.
- 관련 테스트 결과: `label_column_edit_dialog_test.dart`, `label_column_edit_test.dart`, `label_column_save_test.dart` 합계 **52/52 통과**.
- analyzer 결과: 변경 production/test 파일 **No issues found**, 종료 코드 0.
- IDE diagnostics 결과: 변경 production/test 파일과 `pubspec.yaml` 오류 0건.
- DTD 확인 결과: 연결된 실행 앱이 없어 hot reload 대상 없음.
- diff 검토 완료: `git diff --check` 통과, 무관한 formatter 변경 없음.
- stage/commit 대상: `label_column_edit_dialog.dart`, `label_column_edit_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`.
- 기능 커밋: `3322f7e7b570fff6631a9791187afdb0f4723405` (`타임바코드 종류 선택과 바코드 제한 적용`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 현재 작업: 품목관리 새로고침 후 무한 처리 중
- **진행 중**: 1.4.16에서 품목관리 우클릭 `새로 고침` 후 `처리 중`이 계속 표시되고 편집할 수 없는 제출 화면과 `.tmp/1.4.16로그/품목관리_새로고침_무한로딩.log`를 처리한다.
- 로그 버전은 **1.4.16**이다. `contextMenu refresh` → `reload-5 started` → `sessionLoad-6 completed` → `reload-5 completed`까지 정상 완료됐지만, 새 탭은 `busy=true` 상태로 생성됐고 이후 busy=false/탭 재생성 로그가 없다.
- 원인 확인: `_refreshItemManager()`가 reload 전에 `_itemDraftCommandBusy=true`로 설정하고 reload 내부 `_resetTabs()`가 `ItemManage(commandBusy: true)`를 캐시한다. `finally`는 부모 필드만 false로 바꾸고 `_resetTabs()`를 다시 호출하지 않아 화면만 영구 busy 상태로 남는다.
- 구현 방향: reload 성공 여부와 무관하게 mounted 상태에서는 busy를 먼저 false로 해제한 뒤 탭을 재생성한다. 새로고침 시작·reload 결과·실패·finishing/finished와 busy 전후, 탭 수를 디버그 로그에 기록한다.
- `lib/home_page_manager.dart` 편집 완료: `completeItemRefreshCommand`가 busy를 먼저 false로 바꾼 뒤 `_resetTabs()`를 실행한다. `_refreshItemManager()`는 성공·실패 모두 이 완료 경로를 사용하고 시작·reload 완료·실패·finishing·finished 상태를 기록한다.
- `test/home_page_manager_session_test.dart` 회귀 테스트 추가: 새로고침 완료 시 탭이 `busy=false` 상태로 재생성되는 순서를 검증한다.
- `lib/features/item/item_manager_debug_log.dart` 편집 완료: 로그 버전을 `item-manager-debug-v25`로 갱신했다.
- focused 테스트 결과: `item refresh completion clears busy before rebuilding cached tabs` **통과(1/1)**.
- `pubspec.yaml` 편집 완료: 새로고침 UI busy 캐시 버그 수정이므로 PATCH 단계로 `1.4.18`에서 `1.4.19`로 갱신했다.
- Dart formatter 적용 완료: `home_page_manager.dart`, `item_manager_debug_log.dart`, `home_page_manager_session_test.dart`.
- 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/home_page_manager_session_test.dart test/fortune_table_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/home_page_manager.dart lib/features/item/item_manager_debug_log.dart test/home_page_manager_session_test.dart`.
- 관련 테스트 결과: **통과(84/84)**. 새로고침 메뉴 dispatch, busy footer, 완료 순서에 회귀 없음.
- 정적 분석 결과: **통과**, `No issues found` (3개 대상, 종료 코드 0).
- DTD 연결 결과: 실행 중인 Flutter 앱이 없어 hot reload 대상 없음.
- 변경 파일 diagnostics와 `git diff --check` 통과. `home_page_manager.dart` diff는 완료 helper와 `_refreshItemManager` 상태 전이 로그/완료 순서에만 한정된다.
- `_resetTabs()`가 내부에서 `setState`와 탭 컨트롤러 재생성을 수행하므로 busy=false 상태가 새 cached tab과 화면에 반영됨을 확인했다.
- 상태: **완료**. stage/commit 대상은 `lib/home_page_manager.dart`, `lib/features/item/item_manager_debug_log.dart`, `test/home_page_manager_session_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`다.
- 기능 커밋: `d3ed0206074b2ab9f783385d348866cc3faa85ec` (`품목관리 새로고침 무한 로딩 수정`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 현재 작업: 기존 등록 키워드 클라이언트 편집 기본값 복구
- **진행 중**: 1.4.16에서 품명·주원료 외 기존 키워드가 별도 설정 없이 `클라이언트 편집 불가`로 표시되는 제출 화면과 `.tmp/1.4.16로그/품목관리_등록키워드_클라이언트 편집 불가.log`를 처리한다.
- 로그 버전은 **1.4.16**이나 조회 SQL만 있고 반환된 열·품목별 `RICH_EDITABLE` 값과 판정 결과는 기록되지 않았다.
- 원인 확인: 1.3.132 이전 라벨 항목 추가 SQL이 기존 품목 콘텐츠를 `RICH_EDITABLE=0`으로 일괄 생성했다. 1.3.132부터 신규 행은 `1`로 생성하지만 기존 `0`은 그대로 남아 있다.
- 데이터 제약: 과거 자동 생성 `0`과 사용자가 명시한 불가 `0`은 동일한 필드이며 생성일·변경주체·명시 여부 메타데이터가 없다.
- 사용자 선택: 현재 DB에 명시적 불가 설정이 없다는 전제로 **전체 기존 `0`을 `1`로 한 번 교정**한다.
- 구현 방향: 품목 세션 첫 로드 전에 전체 `RICH_EDITABLE=0`을 `1`로 교정하고 성공한 경우에만 로컬 완료 마커를 저장한다. 이후 호출은 건너뛰어 새 명시적 불가 설정을 보존한다.
- 디버그 로그: 교정 시작·완료·건너뜀·실패, 앱/로그 버전, 교정 건수를 기록하고 열·품목별 editable 분포를 세션 조회 로그에 추가한다. 로그 함수에는 비즈니스 로직을 넣지 않는다.
- `lib/features/item/application/item_editable_default_repair.dart` 추가: 일회성 완료 마커를 확인하고 교정 성공 후에만 마커를 저장한다. 동시 호출은 같은 Future를 공유하고 실패 시 다음 세션에서 재시도한다.
- `lib/features/item/data/column_content_dao.dart` 편집 완료: `SET NOCOUNT ON`으로 전체 `RICH_EDITABLE=0`을 `1`로 교정하고 명시적 `NORMALIZED_COUNT` 결과를 반환한다. 조회 후 editable/불가 건수와 불가 column별 분포를 로그로 기록한다.
- `lib/features/item/application/item_manager_session_loader.dart` 편집 완료: 유효한 로그인/거래처 확인 후 일반 품목 데이터 조회 전에 일회성 교정을 실행한다.
- `lib/features/item/item_manager_debug_log.dart` 편집 완료: 로그 버전을 `item-manager-debug-v24`로 갱신했다.
- 테스트 추가: 교정 성공 후 1회만 실행, 실패 시 완료 마커 미저장, UPDATE 범위·NOCOUNT·명시적 교정 건수 반환 계약을 고정했다.
- focused 테스트 결과: `item_editable_default_repair_test.dart`, `item_manager_read_snapshot_test.dart` **통과(8/8)**.
- `pubspec.yaml` 편집 완료: 기존 데이터 기본값 복구 버그 수정이므로 PATCH 단계로 `1.4.17`에서 `1.4.18`로 갱신했다.
- Dart formatter 적용 완료: 변경된 production 4개와 테스트 2개 파일.
- 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/item_editable_default_repair_test.dart test/item_manager_read_snapshot_test.dart test/item_manager_session_loader_test.dart test/item_manager_draft_test.dart test/item_manager_save_dao_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/item/application/item_editable_default_repair.dart lib/features/item/application/item_manager_session_loader.dart lib/features/item/data/column_content_dao.dart lib/features/item/item_manager_debug_log.dart test/item_editable_default_repair_test.dart test/item_manager_read_snapshot_test.dart`.
- 관련 테스트 결과: **통과(51/51)**. 기존값 일회성 복구와 이후 명시적 허용/불가 draft·save 계약을 확인했다.
- 정적 분석 결과: **통과**, `No issues found` (6개 대상, 종료 코드 0).
- DTD 연결 결과: 실행 중인 Flutter 앱이 없어 hot reload 대상 없음.
- 신규 키워드 기본 허용 회귀 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_column_save_test.dart`.
- 신규 키워드 기본 허용 회귀 테스트 결과: **통과(16/16)**. 관련 최종 테스트는 합계 **67/67 통과**다.
- 변경 파일 diagnostics와 `git diff --check` 통과. formatter에 의한 요청 범위 밖 변경 없음.
- 운영 DB 데이터 교정은 앱의 첫 품목 세션 로드에서 실행되며, 이 작업 중 운영 DB UPDATE를 직접 실행하지 않아 실제 교정 건수는 사용자 재현 로그로 확인해야 한다.
- 상태: **완료**. stage/commit 대상은 `lib/features/item/application/item_editable_default_repair.dart`, `lib/features/item/application/item_manager_session_loader.dart`, `lib/features/item/data/column_content_dao.dart`, `lib/features/item/item_manager_debug_log.dart`, `test/item_editable_default_repair_test.dart`, `test/item_manager_read_snapshot_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`다.
- 기능 커밋: `dc59a24fd4810569ed25b4eade2b757a96525d5b` (`기존 키워드 클라이언트 편집 기본값 복구`).
- 기존 사용자 dirty `lib/core/app.dart`는 수정·stage·commit에서 제외한다.

## 현재 작업: 품목 편집 후 가로 스크롤 표시 유지 (1.4.16 재발)
- **진행 중**: 품목관리에서 소비기한을 `365`에서 `360`으로 Enter 확정한 뒤 필요한 가로 스크롤이 사라지는 제출 화면과 `.tmp/1.4.16로그/품목관리_수정진행시_가로스크롤오류.log`를 조사한다.
- 로그 버전은 **1.4.16**이다. 편집 전후 테이블은 `columns=18`, `contentWidth=2023.6`, `viewportWidth=1849.7`, `overflow=true`, `maxExtent=173.9`를 유지해 열 폭이나 overflow 계산 소실은 아니다.
- 편집 완료는 `17:34:48.049`의 `operation=editColumn event=completed`이며 직후 같은 18열로 다시 빌드됐다. State 교체나 overflow=false 전환은 기록되지 않았다.
- 원인 확인: Flutter `RawScrollbar`는 자식 rebuild 중 들어오는 `maxScrollExtent=0` 알림을 받으면 `thumbVisibility=true`여도 fade animation을 reverse한다. 레이아웃 overflow가 계속 true인데 정상 metrics 알림이 다시 오지 않으면 설정값은 true인 채 실제 painter만 사라질 수 있어 기존 테스트가 놓쳤다.
- `third_party/fortune_sheet/lib/src/fortune_table.dart` 편집 완료: 현재 레이아웃이 가로 overflow인 동안 일시적인 horizontal zero-extent 알림을 scrollbar painter에 전달하지 않는다. 정상 가로 metrics와 실제 overflow 해제 알림은 계속 처리한다.
- `lib/features/item/presentation/item_manage.dart` 편집 완료: `FortuneTable` 관측 콜백으로 가로 metrics의 accepted/ignored, notification 종류, 레이아웃 overflow, extent, pixels, viewport, 편집 상태를 중복 억제 후 기록한다.
- `lib/features/item/item_manager_debug_log.dart` 편집 완료: 제출 로그 판별을 위해 버전을 `item-manager-debug-v23`으로 갱신했다. 로그 함수에는 비즈니스 로직을 넣지 않았다.
- 회귀 테스트 추가: overflow 중 zero-extent 알림 차단 계약과 실제 품목관리 `RawScrollbar.notificationPredicate` 연결을 검증한다.
- focused 계약 테스트 결과: `가로 overflow 중 일시적인 zero extent 알림을 무시한다` **통과(1/1)**.
- `pubspec.yaml` 편집 완료: 호환 가능한 스크롤 표시 버그 수정이므로 PATCH 단계로 `1.4.16`에서 `1.4.17`로 갱신했다.
- Dart formatter 적용 완료: `fortune_table.dart`, `item_manage.dart`, `item_manager_debug_log.dart`, `item_manage_horizontal_scroll_test.dart`.
- 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/item_manage_horizontal_scroll_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze third_party/fortune_sheet/lib/src/fortune_table.dart lib/features/item/presentation/item_manage.dart lib/features/item/item_manager_debug_log.dart test/item_manage_horizontal_scroll_test.dart`.
- 관련 테스트 결과: `item_manage_horizontal_scroll_test.dart` **통과(3/3)**. Enter 편집 후 5초 지속 표시, 좌우 스크롤, zero-extent 차단 계약 및 실제 predicate 연결을 확인했다.
- 정적 분석 결과: **통과**, `No issues found` (4개 대상, 종료 코드 0).
- DTD 연결 결과: 실행 중인 Flutter 앱이 없어 hot reload 대상 없음.
- 공용 테이블 회귀 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/fortune_table_test.dart test/item_manage_horizontal_scroll_test.dart`.
- 공용 테이블 회귀 테스트 결과: **통과(79/79)**, 종료 코드 0.
- 변경 파일 diagnostics 및 `git diff --check` 통과. formatter에 의한 요청 범위 밖 변경 없음.
- 상태: **완료**. stage/commit 대상은 `third_party/fortune_sheet/lib/src/fortune_table.dart`, `lib/features/item/presentation/item_manage.dart`, `lib/features/item/item_manager_debug_log.dart`, `test/item_manage_horizontal_scroll_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`다.
- 기능 커밋: `cc4ac5f7de106294b7980677fbe5a446d1624463` (`품목 편집 후 가로 스크롤 표시 유지`).
- 기존 사용자 dirty 파일은 수정·stage·commit에서 제외한다.

## 현재 작업: Windows CMake 경로 자동 인식
- **진행 중**: 다른 PC에서도 CMake Tools가 현재 프로젝트의 Windows 소스를 찾도록 `.vscode/settings.json`의 고정 로컬 경로를 워크스페이스 기준 경로로 변경한다.
- 원인 확인: `cmake.sourceDirectory`가 `C:/Workspace/ITSnG/label_manager/windows`로 고정되어 있었다. `build_windows.ps1`은 파일 경로에는 `$PSScriptRoot`를 사용했지만 버전 생성 명령의 작업 디렉터리는 호출 위치를 따랐다.
- `.vscode/settings.json` 편집 완료: `cmake.sourceDirectory`를 `${workspaceFolder}/windows`로 변경했다.
- `build_windows.ps1` 편집 완료: 버전 생성과 Flutter Windows 빌드를 `Push-Location $ScriptRoot` 범위에서 실행하고 `finally`에서 원래 위치를 복원한다.
- JSONC 및 VS Code 진단 오류 없음. PowerShell parser 구문 오류 0건.
- 빌드 경로 검증 완료: `$ScriptRoot` 계산, 빌드 전 프로젝트 루트 이동, `finally` 원위치 복원, 루트 기준 `flutter.ps1` 해석, 실패 종료 코드 보존을 확인했다.
- 고정 실행 경로 잔존 검색 결과: 설정·빌드 스크립트에는 없음. 테스트 fixture의 Windows 경로 정규화 입력 2건은 실제 빌드 경로가 아니므로 유지한다.
- `git diff --check` 통과. 실제 release 빌드/배포파일 생성은 요청 범위가 아니므로 수행하지 않았다.
- 상태: **완료**. 기존 사용자 dirty `lib/core/app.dart`는 제외했다.
- 기능 커밋: `980174a65a0b52dd22ad670c080509c20b5d82a6` (`Windows 빌드 경로 자동 인식 적용`).

## 현재 작업: 최근 수정 기능 진단 로그 보강
- **진행 중**: 최근 확인·수정·추가한 저장 ID 조회, 관리자 복사/거래처 검색, 품목정보 출력 동기화, 날짜 타입 저장 busy, 사용자 Enter 검색, 공용라벨 키워드 삽입의 다음 재현 분석에 필요한 상태 전이 로그를 추가한다.
- 원칙: 사용자 최신 요청에 따라 진단에 필요한 ID, 입력값, 검색어, 복사 명령 데이터 원문 기록을 허용한다. 로그 함수에는 비즈니스 로직을 포함하지 않는다.
- `lib/utils/regression_debug_log.dart` 추가: 공통 버전 `regression-debug-v1`과 `feature/event/fields` 형식만 담당하는 로그 전용 유틸리티다.
- 포맷 단위 테스트 추가: 버전·기능·이벤트·필드가 일관된 한 줄로 생성되는지 검증한다.
- `lib/features/login/presentation/startup_dialog.dart` 편집 완료: 저장 ID 복원 판단, 사용자 입력 세대, lookup 시작·적용·폐기·오류를 기록한다.
- `lib/widgets/modeless_dropdown_form_field.dart` 편집 완료: 선택적 `debugLabel`과 검색창 열기·검색 결과 수·선택값 로그를 추가했다.
- `lib/features/admin_copy/presentation/admin_copy_dialog.dart` 편집 완료: 원본/대상 거래처 선택과 전체 복사 명령, 완료·실패·commit 불명 결과를 기록한다.
- `lib/features/item/presentation/item_info_dialog.dart` 편집 완료: 품목정보 저장 시작, DB 완료, 메모리 반영, 실패, 최종 busy/dirty 상태를 기록한다.
- `lib/home_page_manager.dart` 편집 완료: 품목정보의 라벨출력 row 동기화 전후와 날짜 설정 저장의 busy 해제·탭 재생성 결과를 기록한다.
- `lib/features/managed_user/presentation/user_manager_dialog.dart` 편집 완료: Enter 검색 시작·일치/불일치와 post-frame 포커스 복원 결과를 기록한다.
- `lib/features/label_sheet/presentation/common_label_manage.dart` 편집 완료: 더블클릭 열·행·키워드·이름과 실제 삽입 성공 여부를 기록한다.
- focused test 결과: 공통 로그 1/1, 로그인 13/13, 공용 드롭다운 3/3, 관리자 복사 8/8, 품목정보·출력 동기화 24/24, 날짜 설정 10/10, 사용자 검색·공용라벨 26/26 통과.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.15`에서 `1.4.16`으로 갱신한다.
- Dart formatter 적용 완료: 변경된 Dart 소스 8개와 테스트 1개를 포맷했다.
- 관련 전체 테스트 결과: 10개 테스트 파일 **통과(85/85)**.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/utils/regression_debug_log.dart lib/features/login/presentation/startup_dialog.dart lib/widgets/modeless_dropdown_form_field.dart lib/features/admin_copy/presentation/admin_copy_dialog.dart lib/features/item/presentation/item_info_dialog.dart lib/home_page_manager.dart lib/features/managed_user/presentation/user_manager_dialog.dart lib/features/label_sheet/presentation/common_label_manage.dart test/regression_debug_log_test.dart`.
- 정적 분석 결과: **통과**, `No issues found` (9개 대상, 종료 코드 0).
- 변경 파일 VS Code 진단 오류 없음.
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. 기존 사용자 dirty `.vscode/settings.json`, `lib/core/app.dart`는 제외했다.
- 기능 커밋: `ffb38062d6afc6b3906261c610cd5b6050d7b049` (`최근 수정 기능 진단 로그 보강`).

## 현재 작업: 공용라벨 이름 열 키워드 삽입
- **진행 중**: 공용라벨관리의 `사용 항목` 표에서 키워드 열은 더블클릭으로 `#키워드`가 삽입되지만 이름 열은 삽입되지 않는 1.3.120 증상을 수정한다.
- 원인 확인: `_CommonLabelTable`의 `FortuneTableColumn.onDoubleTap`이 열 인덱스 `0`(키워드)에만 설정되고 인덱스 `1`(이름)은 null이다.
- 구현 방향: 키워드와 이름 열(`index < 2`)이 동일한 `LabelSheetKeywordInsertController.insertAtCurrentContext('#${row.keyword}')`를 호출하게 한다. 드래그 삽입은 요청 범위가 아니므로 기존 키워드 열에만 유지한다.
- 회귀 테스트 변경: 키워드·이름 열 모두 더블클릭 시 `#SWEIGHT`를 삽입하고, 이름 열 dragData는 계속 null인지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/common_label_manage_test.dart --plain-name "keyword and name columns insert keyword on double tap"`.
- 수정 전 테스트 결과: **실패(예상 일치)**. 이름 열의 `onDoubleTap`이 null이었다.
- `lib/features/label_sheet/presentation/common_label_manage.dart` 편집 완료: 키워드와 이름 열(`index < 2`)에 동일한 `#키워드` 더블클릭 삽입 콜백을 적용했다. 이름 열 드래그 동작은 추가하지 않았다.
- 수정 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/common_label_manage_test.dart --plain-name "keyword and name columns insert keyword on double tap"`.
- 수정 후 focused test 결과: **통과(1/1)**.
- Dart formatter 적용 완료: `common_label_manage.dart`, `common_label_manage_test.dart`.
- 공용라벨관리 전체 테스트 결과: `C:/Flutter/bin/flutter.bat test test/common_label_manage_test.dart` **통과(13/13)**.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.14`에서 `1.4.15`로 갱신했다.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/label_sheet/presentation/common_label_manage.dart test/common_label_manage_test.dart`.
- 정적 분석 결과: **통과**, `No issues found` (종료 코드 0). 변경 파일 VS Code 진단 오류 없음.
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. stage/commit 대상은 `lib/features/label_sheet/presentation/common_label_manage.dart`, `test/common_label_manage_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 커밋 전 `git diff --check`, 변경 파일 및 diff 검토 예정.
- 기능 커밋: `cb1ae938dfdb816eb26c60da265e5c6b1cf2632d` (`공용라벨 이름 열 키워드 삽입 추가`).

## 현재 작업: 사용자 관리 Enter 연속 검색
- **진행 중**: `파일/관리 > 사용자 관리`에서 이름 검색 후 Enter를 다시 눌러도 다음 사용자를 찾지 못하고 돋보기 버튼을 눌러야 하는 1.3.120 증상을 수정한다.
- 원인 가설: `_searchNext()`가 결과 행 선택과 시트 스크롤 후 검색 `TextField` 포커스를 복구하지 않아 다음 Enter가 검색 입력으로 전달되지 않는다.
- 구현 방향: 검색 필드 전용 `FocusNode`를 소유하고, 검색 결과 선택·스크롤이 반영된 다음 프레임에 검색 필드로 포커스를 명시적으로 복원한다. 검색어와 선택 범위는 유지한다.
- 회귀 테스트 추가: 같은 이름의 두 사용자에서 Enter를 두 번 연속 입력해 검색 필드 포커스 유지와 두 번째 사용자 선택을 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/user_manager_dialog_test.dart --plain-name "enter searches repeatedly and restores search field focus"`.
- 수정 전 테스트 결과: **실패(예상 일치)**. 첫 Enter 직후 검색 필드의 `focusNode.hasFocus`가 `false`로 바뀌었다.
- `lib/features/managed_user/presentation/user_manager_dialog.dart` 편집 완료: 검색 전용 `FocusNode`를 추가하고 결과 행 선택·스크롤 다음 프레임에 검색 필드 포커스와 검색어 끝 커서를 복원한다.
- 수정 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/user_manager_dialog_test.dart --plain-name "enter searches repeatedly and restores search field focus"`.
- 수정 후 focused test 결과: **통과(1/1)**. Enter 두 번으로 두 번째 일치 사용자까지 선택되고 검색 필드 포커스가 유지된다.
- Dart formatter 적용 완료: `user_manager_dialog.dart`, `user_manager_dialog_test.dart`.
- 사용자 관리 전체 테스트 결과: `C:/Flutter/bin/flutter.bat test test/user_manager_dialog_test.dart` **통과(13/13)**.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.13`에서 `1.4.14`로 갱신했다.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/managed_user/presentation/user_manager_dialog.dart test/user_manager_dialog_test.dart`.
- 정적 분석 결과: **통과**, `No issues found` (종료 코드 0). 변경 파일 VS Code 진단 오류 없음.
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. stage/commit 대상은 `lib/features/managed_user/presentation/user_manager_dialog.dart`, `test/user_manager_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 커밋 전 `git diff --check`, 변경 파일 및 diff 검토 예정.
- 기능 커밋: `bd90753cc49263c006578fb94934486933eece20` (`사용자 관리 Enter 연속 검색 수정`).

## 현재 작업: 관리자 복사 거래처 검색
- **진행 중**: `파일/관리 > 관리자 복사`의 긴 거래처 목록에서 원본·대상 거래처를 이름으로 검색할 수 있도록 개선한다.
- 권장안: 별도 검색 결과 화면 대신 거래처 드롭다운 메뉴 상단에 검색창을 제공하고, 입력 즉시 공백·대소문자를 무시한 이름 부분 일치로 목록을 필터링한다. 기존 협력업체→거래처→브랜드→라벨 크기 선택 흐름은 유지한다.
- 구현 방향: 공용 `ModelessDropdownFormField`에 선택적 검색 API를 추가하고 관리자 복사의 원본·대상 거래처 선택기에만 활성화한다.
- 회귀 테스트 추가: 공용 드롭다운에서 `대상` 검색 시 대상 거래처만 남고 선택되는지, 관리자 복사의 두 거래처 선택기에 검색 설정이 적용되는지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/modeless_dropdown_form_field_test.dart test/admin_copy_dialog_test.dart`.
- 수정 전 테스트 결과: **실패(예상 일치)**. `ModelessDropdownFormField`에 `searchTextForValue`, `searchHintText` API가 없어 두 테스트 파일이 컴파일 실패했다.
- `lib/widgets/modeless_dropdown_form_field.dart` 편집 완료: 선택적 검색창, 실시간 부분 일치 필터, 검색 결과 없음 상태를 추가했다. 검색을 사용하지 않는 기존 호출 동작은 유지한다.
- `lib/features/admin_copy/presentation/admin_copy_dialog.dart` 편집 완료: 원본·대상 거래처 선택기에 거래처명 검색을 활성화했다.
- 수정 후 focused tests 실행 예정: `C:/Flutter/bin/flutter.bat test test/modeless_dropdown_form_field_test.dart test/admin_copy_dialog_test.dart`.
- 수정 후 focused tests 결과: **통과(11/11)**.
- Dart formatter 적용 완료: `modeless_dropdown_form_field.dart`, `admin_copy_dialog.dart`, 두 관련 테스트 파일.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.12`에서 `1.4.13`으로 갱신했다.
- 포맷 후 관련 테스트 및 공용 드롭다운 사용처 회귀 테스트 실행 예정.
- 공용 드롭다운 사용처 회귀 테스트 결과: **통과(50/50)**. 관리자 복사와 기존 7개 사용 화면의 선택 동작에 회귀 없음.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/widgets/modeless_dropdown_form_field.dart lib/features/admin_copy/presentation/admin_copy_dialog.dart test/modeless_dropdown_form_field_test.dart test/admin_copy_dialog_test.dart`.
- 정적 분석 결과: **통과**, `No issues found` (종료 코드 0). 변경 파일 VS Code 진단 오류 없음.
- 관리자 복사 통합 테스트 보강: 원본 거래처에서 `대상` 검색→필터된 거래처 선택→해당 거래처의 `브랜드 2` 로드까지 검증한다.
- 보강 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/admin_copy_dialog_test.dart --plain-name "source and target customer selectors provide name search"`.
- 보강 후 focused test 결과: **통과(1/1)**.
- 최종 관련 테스트 결과: `modeless_dropdown_form_field_test.dart`, `admin_copy_dialog_test.dart` **통과(11/11)**.
- 최종 정적 분석 결과: **통과**, `No issues found` (종료 코드 0).
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. stage/commit 대상은 `lib/widgets/modeless_dropdown_form_field.dart`, `lib/features/admin_copy/presentation/admin_copy_dialog.dart`, `test/modeless_dropdown_form_field_test.dart`, `test/admin_copy_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 커밋 전 `git diff --check`, 변경 파일 및 diff 검토 예정.
- 기능 커밋: `04752e35a2ee0212da151637028a736e684bc257` (`관리자 복사 거래처 검색 추가`).

## 현재 작업: 날짜 타입 저장 후 무한 처리 중
- **진행 중**: `test / testflutter`의 날짜 타입 설정에서 제조시한을 `12:01`에서 `12시01분`으로 변경해 저장하면 품목관리 하단의 `처리 중`이 계속 표시되고 편집할 수 없는 1.3.120 증상을 수정한다.
- 로그 확인: `LabelSizeDAO.updateDateSetup`의 조회·UPDATE는 정상 완료됐고 `dateSetup updateCompleted`도 기록됐다. 이후 내부 상태 로그는 `busy=false`인데 화면에는 `처리 중`이 남는다.
- 원인 확인: 저장 성공 경로가 `_itemDraftCommandBusy == true`인 상태에서 `_resetTabs()`를 호출해 `_tabs`에 `ItemManage(commandBusy: true)`를 캐시한다. `finally`의 `setState(...false)`는 `_tabs`를 다시 만들지 않아 화면만 영구 busy 상태로 남는다.
- 구현 방향: 날짜 설정 저장 완료 시 `_itemDraftCommandBusy`를 먼저 해제한 다음 `_resetTabs()`로 탭 위젯을 재생성한다. 실패 시에는 기존처럼 busy만 해제한다.
- 회귀 테스트 추가: 날짜 설정 완료 함수가 busy를 먼저 `false`로 바꾼 뒤 탭 재생성 콜백을 호출하는 순서를 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/home_page_manager_session_test.dart --plain-name "date setup completion clears busy before rebuilding cached tabs"`.
- 수정 전 테스트 결과: **실패(예상 일치)**. `completeDateSetupCommand`가 없어 컴파일 실패했고 기존 저장 경로에는 올바른 완료 순서가 없음을 확인했다.
- `lib/home_page_manager.dart` 편집 완료: 날짜 설정 저장 성공 시 `completeDateSetupCommand`가 busy를 먼저 해제하고 `_resetTabs()`를 호출한다. 실패 경로는 busy만 해제한다.
- 수정 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/home_page_manager_session_test.dart --plain-name "date setup completion clears busy before rebuilding cached tabs"`.
- 수정 중 짧은 패치 문맥이 `_flushItemDraftEdits`에 성공 플래그를 잘못 삽입해 focused test가 컴파일 실패했다. 해당 변경을 즉시 제거하고 `_openDateTypeSetupDialog`에 정확히 배치했다.
- 수정 후 focused test 결과: **통과(1/1)**.
- Dart formatter 적용 완료: `lib/home_page_manager.dart`, `test/home_page_manager_session_test.dart`. 소스 diff는 의도한 `completeDateSetupCommand`와 `_openDateTypeSetupDialog`에만 한정됨을 확인했다.
- 관련 테스트 결과: `C:/Flutter/bin/flutter.bat test test/home_page_manager_session_test.dart test/date_type_setup_dialog_test.dart` **통과(10/10)**.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.11`에서 `1.4.12`로 갱신했다.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/home_page_manager.dart test/home_page_manager_session_test.dart test/date_type_setup_dialog_test.dart`.
- 정적 분석 결과: **통과**, `No issues found` (종료 코드 0).
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. stage/commit 대상은 `lib/home_page_manager.dart`, `test/home_page_manager_session_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 커밋 전 `git diff --check`, 변경 파일 및 diff 검토 예정.
- 기능 커밋: `fc802a1e2dc6c908b6fd2e5ce9761ed9d49a1d40` (`날짜 타입 저장 무한 로딩 수정`).

## 현재 작업: 품목별 정보 저장 후 라벨출력 즉시 반영
- **진행 중**: 발행 체크된 품목의 줄간격·기본 발행 수·개별 크기·여백을 `품목별 정보 편집`에서 저장해도 라벨출력 탭에 즉시 반영되지 않고, 발행 체크를 해제 후 재선택해야 반영되는 1.3.120 증상을 수정한다.
- 원인 확인: `_handleItemInfoCommitted`는 최신 `ItemOfMarket.datas`를 저장하고 `_syncLabelPrintRows()`를 호출하지만, `LabelPrintSessionController.syncCheckedItems()`는 이미 체크된 품목의 기존 `LabelPrintRowDraft` 전체를 재사용한다.
- 구현 방향: 동기화 때 최신 baseline row를 생성하고, `sessionEdited` 출처인 라벨출력 직접 수정값만 기존 값으로 유지한다. 품목 정보 및 fallback 출처 값은 최신 baseline으로 교체한다.
- 회귀 테스트 추가: 체크 상태를 유지한 품목의 발행 수·크기·여백·줄간격은 갱신되고, 라벨출력에서 직접 수정한 발행 수와 폭은 유지되는지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_print_session_test.dart --plain-name "checked row refreshes item info while preserving session edits"`.
- 수정 전 테스트 결과: **실패(예상 일치)**. 기존 row가 저장 전 `ItemOfMarket` 인스턴스를 계속 참조해 최신 품목별 설정이 반영되지 않음을 확인했다.
- `lib/features/label_print/domain/label_print.dart` 편집 완료: `LabelPrintRowDraft.preserveSessionEditsFrom`을 추가하고, `syncCheckedItems`가 최신 baseline row에 `sessionEdited` 필드만 병합하도록 변경했다.
- 수정 후 focused test 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_print_session_test.dart --plain-name "checked row refreshes item info while preserving session edits"`.
- 수정 후 focused test 결과: **통과(1/1)**.
- 후속 정리: `syncCheckedItems`가 품목당 baseline row를 한 번만 생성하도록 지역 함수로 정리했다.
- 전체 라벨출력 세션 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/label_print_session_test.dart`.
- 전체 라벨출력 세션 테스트 결과: **통과(24/24)**.
- VS Code 진단 결과: 변경한 `label_print.dart`, `label_print_session_test.dart` 오류 없음.
- `pubspec.yaml` 편집 완료: 앱 버전을 `1.4.10`에서 `1.4.11`로 갱신했다.
- 관련 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/item_info_batch_test.dart test/item_info_dialog_test.dart test/label_print_session_test.dart`.
- 관련 테스트 결과: **통과(29/29)** (Flutter 명령 직접 실행, 종료 코드 0).
- Dart formatter 적용 완료: `lib/features/label_print/domain/label_print.dart`, `test/label_print_session_test.dart`.
- analyzer 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/label_print/domain/label_print.dart test/label_print_session_test.dart lib/home_page_manager.dart lib/features/item/presentation/item_info_dialog.dart`.
- 정적 분석 결과: **통과**, `No issues found` (종료 코드 0).
- DTD 연결 앱 조회 및 hot reload 실행 예정.
- DTD 확인 결과: 연결된 Flutter 앱이 없어 hot reload 대상 없음.
- 상태: **완료**. stage/commit 대상은 `lib/features/label_print/domain/label_print.dart`, `test/label_print_session_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 커밋 전 `git diff --check`, 변경 파일 및 diff 검토 예정.
- 기능 커밋: `04c6ffdea668e4f5205037f0a5cf80e28c4e115c` (`품목별 정보 출력 즉시 반영`).

## 현재 작업: 저장 아이디의 사용자 입력 덮어쓰기
- **진행 중**: 로그인 창에서 저장 ID `3575` 대신 `TESTER1`을 입력한 뒤 비밀번호를 클릭하면 다시 `3575`로 강제 전환되는 1.3.120 증상을 수정한다.
- 로그 확인: `TESTER1` 공지/사용자 조회가 성공한 직후 약 0.16초 내 저장 ID `3575` 공지/사용자 조회가 다시 시작된다.
- 원인 확인: 사용자 조회 결과로 공지 패널이 닫힐 때 `_LoginPanel`이 `Row > Expanded` 아래에서 다이얼로그 루트로 이동하며 State가 재생성되고, `initState`의 `_loadPreferences()`가 저장 ID를 다시 주입한다.
- 구현 방향: `_DialogBodyState`가 소유한 안정적인 `GlobalKey<_LoginPanelState>`를 `_LoginPanel`에 부여해 공지 레이아웃 전환에도 동일 State를 재사용한다.
- 회귀 테스트 추가: 저장 ID `3575`에서 `TESTER1` 입력 후 비밀번호 포커스로 공지 패널이 닫혀도 입력 ID와 조회 순서가 유지되는지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/startup_dialog_test.dart --plain-name "saved id does not replace edited id when notice closes"`.
- 수정 전 회귀 재현 완료: 기대 ID `TESTER1` 대신 실제 ID `3575`로 실패했다(종료 코드 1).
- [`lib/features/login/presentation/startup_dialog.dart`](lib/features/login/presentation/startup_dialog.dart) 편집 완료: `_DialogBodyState`가 소유한 `GlobalKey<_LoginPanelState>`를 `_LoginPanel`에 적용해 공지 표시 전환 시 로그인 State를 보존한다.
- focused 회귀 테스트 통과: 입력 ID가 `TESTER1`로 유지되고 `TESTER1` 조회 이후 저장 ID `3575` 재조회가 발생하지 않는다.
- 버전은 로그인 입력 보존 버그 수정이므로 PATCH 단계로 `1.4.8`에서 `1.4.9`로 갱신했다.
- Dart 포맷 완료: `startup_dialog.dart`, `startup_dialog_test.dart`. 포맷 후 focused 회귀 재검증 **1/1 통과**.
- 전체 관련 검증 통과: `C:/Flutter/bin/flutter.bat test test/startup_dialog_test.dart` (**12/12**, 종료 코드 0).
- 정적 분석 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/login/presentation/startup_dialog.dart test/startup_dialog_test.dart`.
- 정적 분석 통과: `No issues found` (종료 코드 0). 변경 파일 VS Code 진단 오류 없음.
- DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- 상태: **완료**. stage/commit 대상은 `startup_dialog.dart`, `startup_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 최종 보강: 늦게 완료된 `3575` 조회가 사용자 이름 등 조회 결과를 덮지 않고 `name:TESTER1`이 유지되는지 검증한다.
- 보강 후 최종 검증 통과: `startup_dialog_test.dart` **13/13**, focused analyze 오류·경고 0.
- 기능 커밋: `9873e6275600136bc1552dd508426bb8e2753fdd` (`저장 아이디 조회 경합 수정`).
- 최종 보강: 아이디/비밀번호 필드에 안정적인 테스트 key를 추가하고, `TESTER1` 조회 이후 `3575`가 다시 조회되지 않는 조건을 명시적으로 검증한다.
- 보강 후 최종 검증 통과: `startup_dialog_test.dart` **12/12**, focused analyze 오류·경고 0.
- 기능 커밋: `361b4ac8690f94dbfc5871ee49562d958fae901a` (`저장 아이디 입력 덮어쓰기 수정`).

## 현재 작업: 공지 숨김 상태의 저장 아이디 조회 경합
- **진행 중**: 저장 ID `3575`에서 `다음 업데이트까지 이 창 보지 않음`을 저장한 뒤 재로그인하여 `TESTER1`을 입력하면 `3575`로 돌아가는 추가 재현을 처리한다.
- 원인 가설: 저장 ID의 공지 조회가 진행 중일 때 `_LoginPanel._noticeFetchInFlight`가 새 `TESTER1` 조회를 즉시 버리고, 늦게 완료된 `3575` 결과가 현재 로그인 정보로 적용된다.
- 구현 방향: 사용자 ID 입력 변경 시 이전 조회를 무효화하고, 서로 다른 최신 ID 조회는 실행하되 현재 입력과 요청 세대가 일치하는 결과만 적용한다. 비동기 preference 로딩도 사용자가 입력을 시작한 뒤에는 ID를 덮어쓰지 않게 한다.
- 회귀 테스트 추가: 저장 ID `3575` 공지 조회를 지연시킨 상태에서 `TESTER1`로 이동해도 새 조회가 실행되고 입력 ID가 유지되는지 검증한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/startup_dialog_test.dart --plain-name "edited id supersedes saved id lookup in flight"`.
- 수정 전 회귀 재현 완료: 기대 조회 `3575 → TESTER1` 대신 `3575`만 실행되어 실패했다(종료 코드 1).
- [`lib/features/login/presentation/startup_dialog.dart`](lib/features/login/presentation/startup_dialog.dart) 편집 완료: 전역 조회 잠금을 제거하고 ID 입력마다 이전 요청을 무효화한다. 현재 입력 및 최신 요청 세대와 일치하는 조회 결과만 적용하며, 사용자가 편집을 시작한 뒤 완료된 preference 로딩은 저장 ID를 주입하지 않는다.
- 수정 후 focused 회귀 테스트 통과: **1/1**.
- 버전은 저장 ID 비동기 경합 수정이므로 PATCH 단계로 `1.4.9`에서 `1.4.10`으로 갱신했다.
- Dart 포맷 완료: `startup_dialog.dart`, `startup_dialog_test.dart`.
- 전체 관련 검증 통과: `C:/Flutter/bin/flutter.bat test test/startup_dialog_test.dart` (**13/13**, 종료 코드 0).
- 정적 분석 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/login/presentation/startup_dialog.dart test/startup_dialog_test.dart`.
- 정적 분석 통과: `No issues found` (종료 코드 0). 변경 파일 VS Code 진단 오류 없음.
- DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- 상태: **완료**. stage/commit 대상은 `startup_dialog.dart`, `startup_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.

## 현재 작업: 관리자 복사 품목 포함 SQL 512 오류
- **진행 중**: 관리자 복사에서 원본 라벨 `677`을 대상 라벨 `8156`으로 `품목까지 복사`하면 SQL Server 오류 512(스칼라 하위 쿼리 복수행)가 발생하는 1.3.106 로그 증상을 수정한다.
- 로그 확인: `copyItems=1`, `targetFirstMarketId=1`로 실행된 트랜잭션이 `proc_copy_item`과 `proc_copy_item_content`를 포함한 품목 복사 구간에서 실패하고 전체 롤백됐다. 앱이 직접 작성한 품목-지점 INSERT의 하위 쿼리는 이미 `TOP 1`이라 오류 512 대상이 아니다.
- 원인 가설: 구 DB 저장 프로시저 내부가 품목 순번 또는 컬럼 대응을 스칼라 하위 쿼리로 가정해 복수 매칭 데이터에서 실패한다. 프로시저 정의는 저장소에 없으므로 DB 마이그레이션 없이 앱 SQL에서 의존을 제거한다.
- 구현 방향: 원본 품목을 한 건씩 삽입하며 원본→대상 품목 ID를 캡처하고, 원본→대상 컬럼도 정렬 순번으로 1:1 매핑한다. 열 내용은 집합 기반 `UPDATE ... JOIN`과 누락 행 INSERT로 복사하고, 품목-지점 정보는 품목 ID 매핑을 사용한다. `STRING_AGG` 등 compatibility 100 비지원 문법은 사용하지 않는다.
- 수정 예정 파일: `lib/features/admin_copy/data/admin_copy_dao.dart`, `test/admin_copy_dao_test.dart`, `pubspec.yaml`.
- 회귀 테스트 추가: 두 복사 SQL이 구 품목 복사 프로시저를 호출하지 않고 `@ItemMap`/`@ColumnMap`, `ROW_NUMBER`, 집합 기반 내용 UPDATE를 사용하는 계약을 고정한다.
- 수정 전 테스트 실행 예정: `C:/Flutter/bin/flutter.bat test test/admin_copy_dao_test.dart --plain-name "item copy uses explicit item and column mappings"`.
- 수정 전 회귀 재현 완료: 프로시저 대신 품목 ID 캡처를 요구하는 첫 기대값이 실패했다(종료 코드 1).
- [`lib/features/admin_copy/data/admin_copy_dao.dart`](lib/features/admin_copy/data/admin_copy_dao.dart) 편집 완료: `proc_copy_item`/`proc_copy_item_content`를 제거하고, 원본→대상 품목 ID와 컬럼 ID를 명시적으로 매핑한다. 열 내용은 `UPDATE ... JOIN` 후 누락 행만 INSERT하며 품목-지점 연결도 품목 ID 맵을 사용한다.
- 수정 후 focused 회귀 테스트 통과: **1/1**.
- 버전은 관리자 복사 DB 오류 수정이므로 PATCH 단계로 `1.4.7`에서 `1.4.8`로 갱신했다.
- Dart 포맷 완료: `admin_copy_dao.dart`, `admin_copy_dao_test.dart`.
- 포맷 후 focused 회귀 재검증 통과: **1/1**. 변경 파일 VS Code 진단 오류 없음.
- 전체 관련 검증 통과: `C:/Flutter/bin/flutter.bat test test/admin_copy_dao_test.dart test/admin_copy_dialog_test.dart` (**12/12**, 종료 코드 0).
- 정적 분석 실행 예정: `C:/Flutter/bin/flutter.bat analyze lib/features/admin_copy/data/admin_copy_dao.dart test/admin_copy_dao_test.dart`.
- 긴 열 내용 보존: 복사 임시 테이블의 `RICH_COL_CONTENT_DATA`를 `NVARCHAR(MAX)`로 유지하고 회귀 테스트에 고정했다.
- 최종 검증 완료: 관련 테스트 **12/12 통과**, focused analyze **No issues found**, 변경 파일 진단 오류 없음.
- DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다. 운영 DB 데이터 변경 재현은 사용자 승인 없이 수행하지 않아 미검증이다.
- 상태: **완료**. stage/commit 대상은 `admin_copy_dao.dart`, `admin_copy_dao_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 기존 사용자 dirty 파일은 제외한다.
- 기능 커밋: `9f26f98f3260cf4213c19b93ce60351e541c5fb5` (`관리자 품목 포함 복사 오류 수정`).

## 현재 작업: 일반 사용자 라벨 항목 표시 적용
- **완료**: 항목편집에서 제조일자만 `표시`로 저장했지만 일반 사용자 품목관리에 숨김 바코드까지 나타나는 1.3.120 증상을 수정했다.
- 원인 확인 1: Windows ODBC SQL BIT `false`를 `RICH_VISIBLE != 0`으로 판정해 숨김값을 true로 복원한다.
- 원인 확인 2: 품목관리 동적 열 구성은 `TColumn.datas` 전체를 사용하며 `visible`을 적용하지 않는다.
- 구현 방향: 라벨 항목의 SQL BIT 필드를 bool/num/string으로 명시 변환하고, 일반 사용자는 `visible=true` 동적 열만 표시한다. 관리자는 항목 편집을 위해 전체 열을 유지한다.
- [`test/column_mapping_test.dart`](test/column_mapping_test.dart) 테스트 추가: SQL BIT bool과 숫자/문자열 0·1 변환을 검증한다.
- [`test/item_manage_horizontal_scroll_test.dart`](test/item_manage_horizontal_scroll_test.dart) 테스트 추가: 일반 사용자는 표시 열만, 관리자는 표시 여부와 무관하게 전체 열을 사용하는 정책을 검증한다.
- [`lib/features/label_column/data/column_dao.dart`](lib/features/label_column/data/column_dao.dart) 편집 완료: `columnBoolValue`로 라벨 항목의 모든 SQL BIT 필드를 bool/num/string에서 정확히 복원한다.
- [`lib/features/item/presentation/item_manage.dart`](lib/features/item/presentation/item_manage.dart) 편집 완료: `itemManagerColumnsForUser`를 동적 열 구성에 적용해 일반 사용자는 `visible=true` 열만, 관리자는 전체 열을 사용한다.
- focused 검증 완료: SQL BIT 숨김 복원 **1/1**, 일반 사용자 표시 열 정책 **1/1** 통과.
- 버전은 호환 가능한 항목 표시 버그 수정이므로 PATCH 단계로 `1.4.3`에서 `1.4.4`로 갱신했다.
- 전체 검증 완료: `test/column_mapping_test.dart`, `test/item_manage_horizontal_scroll_test.dart` **6/6 통과**, focused analyze **No issues found**.
- formatter, diagnostics, `git diff --check` 통과. DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- stage/commit 대상: `lib/features/label_column/data/column_dao.dart`, `lib/features/item/presentation/item_manage.dart`, `test/column_mapping_test.dart`, `test/item_manage_horizontal_scroll_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `d3ca08d` (`일반 사용자 라벨 항목 표시 적용`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 공용라벨 Ctrl+Z 후 저장 불가
- **완료**: 1.3.120에서 12행을 14·15행에 붙여넣고 15행 붙여넣기를 Ctrl+Z로 취소한 뒤 저장 버튼이 반응하지 않는 증상을 현재 1.4.4 기준으로 검증했다.
- 로그상 첫 저장 callback은 약 51초 뒤 시작해 필수 누락 경고 후 DB 저장까지 완료되며, `SPRICE`는 누락 목록에 없다. 특별항목 필수 해제는 workbench를 다시 dirty로 표시하므로 저장 버튼 활성화 증상과 일치한다.
- 조사 결과 FortuneSheet undo는 workbook `onChange`를 통지하고, `clearSheet` op는 명시적 전체 지우기에서만 생성된다.
- [`test/label_sheet_toolbar_test.dart`](test/label_sheet_toolbar_test.dart) 테스트 추가: 14·15행 범위 변경 후 실제 Ctrl+Z 키 이벤트를 보냈을 때 저장 항목이 활성 상태이고, 저장 payload에는 14행만 남으며 15행은 제거되는지 검증한다.
- focused 회귀 테스트 **1/1 통과**. 1.3.120 이후 dirty/save 및 command-state 변경이 반영된 현재 코드에서는 증상이 재현되지 않아 production 로직은 추가 변경하지 않는다.
- 최종 검증 완료: Ctrl+Z 저장 focused 테스트 **1/1 통과**, `flutter analyze test/label_sheet_toolbar_test.dart` **No issues found**.
- formatter와 `git diff --check` 통과. DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- stage/commit 대상: `test/label_sheet_toolbar_test.dart`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `e661239` (`공용라벨 Ctrl+Z 저장 회귀 검증`).

## 현재 작업: 고정 항목 사용자 정의 text 비활성화
- **완료**: 라벨 항목 편집에서 항목 종류가 `고정(TYPE_FIX)`이면 사용되지 않는 `사용자 정의 text` 입력을 비활성화했다.
- [`lib/features/label_column/presentation/label_column_edit_dialog.dart`](lib/features/label_column/presentation/label_column_edit_dialog.dart) 편집 완료: 고정 항목일 때만 사용자 정의 text의 `TextFormField.enabled`를 false로 설정하고 다른 항목 종류는 기존 입력을 유지한다.
- [`test/label_column_edit_dialog_test.dart`](test/label_column_edit_dialog_test.dart) 테스트 추가: 고정 항목에서 비활성화되고 기본 항목으로 변경하면 다시 활성화되는지 검증한다.
- 버전은 UI 속성 활성화 조건 수정이므로 PATCH 단계로 `1.4.4`에서 `1.4.5`로 갱신했다.
- focused 검증 완료: `fixed column disables user defined text` **1/1 통과**.
- 최종 검증 완료: `test/label_column_edit_dialog_test.dart` 전체 통과, focused analyze **No issues found**.
- formatter, diagnostics, `git diff --check` 통과. DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- stage/commit 대상: `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/label_column_edit_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `2868028` (`고정 항목 사용자 정의 입력 비활성화`).

## 현재 작업: GS1 AI 코드 표시 및 설정 ComboBox
- **완료**: GS1 AI 항목에서 `GS1 code 표시`를 저장해도 품목 출력 미리보기에 AI 코드가 나타나지 않는 1.3.120 증상을 수정하고, AI code와 Format option을 ComboBox로 제공했다.
- 원인 확인: 현재 `itemCodeTokenColumnValue`는 GS1 AI의 `showGs1Code`를 적용하지 않고 원본 값만 반환한다. 레거시는 `(<AI code>)<값>` 형식으로 치환한다.
- 구현 예정: GS1 AI 출력 토큰을 레거시 형식으로 만들고, `Gs1AiDefinitions`의 DB 정의를 AI code ComboBox로 사용한다. `dataFormatType == 2`인 AI만 소수점 `0~9` Format option을 활성화하고 나머지는 `해당 없음(-1)`으로 유지한다.
- 수정 예정 파일: `lib/features/label_print/domain/item_code_data_resolver.dart`, `lib/features/label_column/presentation/label_column_edit_dialog.dart`, 관련 테스트, `pubspec.yaml`.
- [`lib/features/label_print/domain/item_code_data_resolver.dart`](lib/features/label_print/domain/item_code_data_resolver.dart) 편집 완료: GS1 AI의 `showGs1Code`가 켜지면 출력 토큰을 레거시와 같은 `(<AI code>)<값>` 형식으로 반환한다.
- [`lib/features/label_column/presentation/label_column_edit_dialog.dart`](lib/features/label_column/presentation/label_column_edit_dialog.dart) 편집 완료: AI code를 DB 정의 기반 ComboBox로 제공하고, 소수점형 AI는 `0~9`, 일반 AI는 `해당 없음(-1)` Format option ComboBox를 제공한다.
- [`test/item_code_data_resolver_test.dart`](test/item_code_data_resolver_test.dart) 테스트 추가: 표시 해제 시 원본 값, 표시 설정 시 `(01)12341234123412` 출력을 검증한다.
- [`test/label_column_edit_dialog_test.dart`](test/label_column_edit_dialog_test.dart) 테스트 추가: 일반 AI의 Format option 비활성화와 소수점형 AI 선택 후 `0~9` 옵션 활성화를 검증한다.
- 버전은 GS1 AI 출력/UI 버그 수정이므로 PATCH 단계로 `1.4.5`에서 `1.4.6`으로 갱신했다.
- focused 검증 완료: GS1 AI 표시 형식 **1/1**, AI/Format ComboBox 선택 및 `gs1ai=3102`, `formatOption=2` 저장 명령 전달 **1/1** 통과.
- 최종 검증 완료: `test/item_code_data_resolver_test.dart`, `test/label_column_edit_dialog_test.dart` **37/37 통과**, focused analyze **No issues found**.
- formatter, diagnostics, `git diff --check` 통과. DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- stage/commit 대상: `lib/features/label_print/domain/item_code_data_resolver.dart`, `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/item_code_data_resolver_test.dart`, `test/label_column_edit_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `7dc391d` (`GS1 AI 코드 표시와 설정 선택 개선`).

## 현재 작업: GS1바코드 포함 키워드 표시 복원
- **진행 중**: `포함 GS1 AI 키워드`에 `#GS1AI`를 저장한 뒤 재진입하면 관계 테이블의 내부 ID `140792|`가 노출되는 1.3.120 증상을 수정한다.
- 원인 확인: DB 조회의 `containColumns`는 관계 저장용 column ID 목록이며 라벨 항목 편집 폼이 이를 그대로 표시한다. 저장 SQL은 `#키워드`와 숫자 ID를 모두 관계 ID로 해석한다.
- 구현 방향: 저장·출력 모델의 ID 목록은 유지하고, GS1바코드 속성 폼의 표시값만 현재 사용 항목을 기준으로 ID→`#키워드`로 변환한다. 단순 조회 시 dirty 상태는 만들지 않는다.
- 수정 예정 파일: `lib/features/label_column/presentation/label_column_edit_dialog.dart`, `test/label_column_edit_dialog_test.dart`, `pubspec.yaml`.
- 편집 완료: `_gs1ContainKeywords`가 기존 관계 ID를 `#키워드`로 표시하고 `_normalizeGs1ContainColumns`가 속성 적용 시 키워드를 관계 ID로 복원한다. 알 수 없는 키워드는 `입력 확인`으로 적용을 차단한다.
- 테스트 추가: column ID `140792`를 포함한 GS1바코드가 `#GS1AI`로 표시되고 저장 명령에서는 `140792|`를 유지하는 위젯 회귀 테스트를 추가했다.
- 단일 회귀 검증 통과: `C:/Flutter/bin/flutter.bat test test/label_column_edit_dialog_test.dart --plain-name "GS1 barcode shows contain column IDs as keywords"` (종료 코드 0).
- 버전 갱신: `pubspec.yaml`의 앱 버전을 `1.4.6`에서 `1.4.7`로 올렸다.
- Dart 포맷 완료: `label_column_edit_dialog.dart`, `label_column_edit_dialog_test.dart`.
- 포맷 후 단일 회귀 재검증 통과: 1/1.
- 전체 관련 검증 통과: `C:/Flutter/bin/flutter.bat test test/label_column_edit_dialog_test.dart` (28/28, 종료 코드 0).
- 정적 분석 통과: `C:/Flutter/bin/flutter.bat analyze lib/features/label_column/presentation/label_column_edit_dialog.dart test/label_column_edit_dialog_test.dart` (`No issues found`, 종료 코드 0).
- VS Code 진단: 변경한 Dart 파일과 `pubspec.yaml` 모두 오류 없음.
- DTD 연결 확인: 실행 중인 Flutter 앱이 없어 hot reload는 수행하지 못했다.
- 상태: **완료**. stage/commit 대상은 `label_column_edit_dialog.dart`, `label_column_edit_dialog_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`이며 사용자 dirty 파일은 제외한다.
- 기능 커밋: `551511ec219531e79c8871bd30e875ec81e5df31` (`GS1 바코드 포함 키워드 표시 복원`).

## 현재 작업: QR 배율 비례 왜곡 수정
- **완료**: 공용라벨관리에서 QR을 31.75×31.75mm로 삽입할 때 배율 1은 위로 쏠리고 배율 3은 위로 말리는 1.3.120 증상을 수정했다.
- 원인 확인: 120×120px QR 객체에도 선형 바코드용 기본 막대 높이 10mm(약 38px)를 본체 높이로 적용하고, module scale은 인코딩 폭에만 적용한다. 배율 1은 120×38, 배율 3은 40×38 소스를 120×38로 리사이즈해 상단 쏠림과 비대칭 왜곡이 발생한다.
- 구현 방향: QR 등 2D 코드는 지정 객체 높이 전체를 본체에 사용하고 module scale을 인코딩 폭과 높이에 동일 적용한다. 선형 바코드의 막대 높이 동작은 유지한다.
- [`test/label_sheet_toolbar_test.dart`](test/label_sheet_toolbar_test.dart) 테스트 추가: 120×120 QR에서 배율 1은 120×120, 배율 3은 40×40 인코딩 소스를 사용하고 출력 크기는 모두 120×120임을 검증한다.
- [`lib/features/label_sheet/application/label_sheet_barcode_renderer.dart`](lib/features/label_sheet/application/label_sheet_barcode_renderer.dart) 편집 완료: 2D 바코드는 지정 객체 높이 전체를 본체로 사용하고 source width/height에 module scale을 동일 적용한다. 선형 바코드는 기존 가로 해상도와 막대 높이를 유지한다.
- focused 검증 완료: QR 정사각 geometry **1/1**, 선형 바코드 막대 높이 **1/1** 통과.
- 실제 ZXing 생성 테스트는 Windows 테스트 러너가 `flutter_zxing.dll`을 로드하지 못해 실행할 수 없었고, native asset에 의존하지 않는 인코딩 geometry 테스트로 검증했다.
- toolbar 전체 테스트에서 직전 독립 탭 정책과 반대인 구 기대값 1건을 발견해 현재 대상별 차단 위임 계약으로 갱신했다. 한글 ANSI 기대 문자열 1건은 실행 환경 인코딩 차이로 실패하며 QR 변경과 무관하다.
- 버전은 호환 가능한 QR 렌더링 버그 수정이므로 PATCH 단계로 `1.4.2`에서 `1.4.3`으로 갱신했다.
- 전체 검증 완료: `test/label_sheet_toolbar_test.dart` **202/203 통과**. 남은 `item element RTF conversion decodes Korean ANSI hex` 1건은 실행 환경의 기존 한글 ANSI 기대 문자열 차이이며 QR 경로와 무관하다. focused analyze **No issues found**.
- formatter, diagnostics, `git diff --check` 통과. DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- stage/commit 대상: `lib/features/label_sheet/application/label_sheet_barcode_renderer.dart`, `test/label_sheet_toolbar_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `c604c0f` (`QR 배율 비례 왜곡 수정`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 라벨 전환 후 병합 복사 유지
- **완료**: 공용라벨관리에서 병합 영역을 복사한 뒤 다른 라벨로 전환하고 돌아와 붙여넣으면 병합 없이 텍스트만 반복되는 1.3.106 로그 증상을 수정했다.
- 원인 확인: OS 클립보드에는 TSV 텍스트만 기록하고 병합·스타일 payload는 `FortuneSheetCanvas` State에만 저장한다. 라벨 전환으로 canvas가 교체되면 내부 payload가 사라져 일반 TSV 붙여넣기로 처리된다.
- 구현 방향: 일반 복사의 내부 셀 payload를 FortuneSheet 인스턴스 간 공유해 클립보드 텍스트가 유지된 동안 병합·스타일을 복원한다. 원본 삭제 의미가 있는 잘라내기는 기존 canvas State 범위에 유지한다.
- [`third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`](third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart) 테스트 추가: 두 병합 영역 복사 후 canvas를 교체하고 A5에 붙여넣어 병합 범위 복원을 검증한다.
- 재현 테스트 확인: 수정 전 첫 병합 `row`가 `null`로 실패했고, 공용 payload 구현 후 **1/1 통과**했다.
- 기존 workbook prop 교체 테스트도 클립보드가 유지된 동안 내부 스타일을 보존하는 새 계약으로 갱신했다.
- [`third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`](third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart) 편집 완료: 일반 셀 복사의 범위·셀·병합·스타일·테두리·검증·필터·이미지 payload를 canvas 간 공용 슬롯에 저장하고, OS 클립보드 텍스트가 일치할 때 새 canvas에서 재사용한다. 잘라내기와 텍스트 불일치는 공용 payload를 사용하지 않는다.
- focused 검증 완료: canvas 교체, workbook prop 교체, 기존 병합·스타일, CRLF, 상대 수식 테스트 **5/5 통과**. 재현 테스트에서 외부 TSV 변경 시 병합 payload를 무시하는 분기도 통과했다.
- formatter 적용 완료. 포맷 후 묶음 검증은 실행 도구가 두 번째 테스트에서 종료되지 않아 결과에서 제외했으며, 해당 테스트 단독 재실행은 **1/1 통과**했다.
- 최종 focused 검증 완료: canvas 교체 병합, 기존 병합·스타일, 다중행 병합, CRLF, 상대 수식 **5/5 통과**. workbook prop 교체 단독 테스트까지 합쳐 관련 검증 **6/6 통과**했다.
- analyzer는 변경 구간 오류 없이 기존 이미지 레이어 미사용 코드 경고 10건만 보고했다. diagnostics와 `git diff --check`는 통과했다.
- DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- 버전은 호환 가능한 복사/붙여넣기 버그 수정이므로 PATCH 단계로 `1.4.1`에서 `1.4.2`로 갱신했다.
- stage/commit 대상: `third_party/fortune_sheet/lib/src/fortune_sheet_canvas.dart`, `third_party/fortune_sheet/test/fortune_sheet_canvas_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `40e506f` (`라벨 전환 후 병합 복사 유지`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 품목 수정 중 독립 탭 진입
- **완료**: 품명 편집 진입 후 저장 전 공용라벨관리와 라벨출력 탭으로 이동하지 못하는 1.3.120 증상을 수정했다.
- 원인 확인: 탭 클릭 선행 차단과 `_onTabSelection`이 품목 active editor·dirty를 공용라벨/라벨출력에도 전역 적용한다.
- 데이터 소스 확인: 품목 발행 미리보기와 라벨출력 템플릿은 `_effectiveLabelSize.labelSizeCommon` 저장본을 사용하며, 공용라벨 저장 성공 콜백 전에는 `_currentLabelSize`가 교체되지 않는다.
- [`lib/home_page_manager.dart`](lib/home_page_manager.dart) 편집 완료: 선행 품목 탭 차단을 대상별 `_onTabSelection`으로 위임하고, 공용라벨/라벨출력은 품목 draft 상태와 무관하게 진입하며 활성 셀 입력만 draft에 커밋한다. 품목 저장 명령 실행 중 차단과 저울출력의 기존 차단은 유지한다.
- [`test/fortune_table_test.dart`](test/fortune_table_test.dart) 편집 완료: 독립 탭은 품목 active/dirty가 아닌 저장 명령 실행 여부만 차단하고 품목 탭 클릭은 대상별 정책으로 위임하는 회귀 계약을 추가했다.
- focused 검증 완료: `flutter test test/fortune_table_test.dart --plain-name "common label and label print tabs ignore item draft state"`, `flutter test test/fortune_table_test.dart --plain-name "item tab click delegates target-specific blocking"` 각각 통과.
- 전체 검증 완료: `test/fortune_table_test.dart` **76/76 통과**, 저장된 공용라벨 fingerprint focused test **1/1 통과**, focused analyze **No issues found**, diagnostics 통과.
- formatter 적용 후 같은 전체 검증을 재실행해 **76/76**, **1/1**, analyzer **No issues found**를 다시 확인했다.
- DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상이 없었다.
- 버전은 호환 가능한 탭 정책 버그 수정이므로 PATCH 단계로 `1.4.0`에서 `1.4.1`로 갱신했다.
- stage/commit 대상: `lib/home_page_manager.dart`, `test/fortune_table_test.dart`, `pubspec.yaml`, `SESSION_HANDOFF.md`. 기존 사용자 변경은 제외한다.
- 기능 커밋: `cf53e0c` (`품목 편집 중 독립 탭 진입 허용`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 품목관리 엑셀 행 다중 셀 붙여넣기
- **완료**: 엑셀 내보내기 파일의 한 품목 행을 복사해 품목관리 셀에 붙이면 탭 구분 값 전체가 한 셀에 들어가는 1.3.120 증상을 수정했다.
- 원인 확인: 공용 `FortuneTable`에 클립보드 붙여넣기 처리가 없어 편집 중 `EditableText`가 탭 포함 문자열 전체를 단일 셀 값으로 받는다.
- 편집 완료: `FortuneTable.tabSeparatedPasteEnabled` opt-in API를 추가하고 품목관리에서 활성화했다. 선택/편집 셀부터 탭 값을 표시 열 순서대로 소비하며 편집 불가 열은 쓰지 않고 해당 칸만 건너뛴다. 탭 없는 일반 텍스트는 기존 편집기 선택 영역에 붙여넣는다.
- 테스트 추가: 공용 테이블의 탭 값 분배·읽기 전용 열 정렬 보존과 품목관리 활성화 연결을 검증한다.
- 버전은 사용자에게 보이는 새 다중 셀 붙여넣기 기능이므로 MINOR 단계로 `1.3.133`에서 `1.4.0`으로 갱신했다.
- focused 검증 완료: 더블클릭 편집 상태의 `FortuneTable pastes tab-separated values across columns` **1/1 통과**. formatter와 diagnostics도 통과했다.
- 추가 검증 완료: `C:/Flutter/bin/flutter.bat test --no-pub --reporter expanded test/fortune_table_test.dart test/item_manage_horizontal_scroll_test.dart` **76/76 통과**.
- 임시 테스트 로그는 `.tmp/copilot/item_tab_paste_suite.log`에만 생성했으며 Git에 포함하지 않는다.
- focused analyze 완료: **No issues found**(15.8초).
- VS Code DTD에는 실행 중인 Flutter 앱이 없어 hot reload 대상은 없었다.
- 기능 커밋: `6e3caea` (`품목관리 엑셀 행 다중 셀 붙여넣기 지원`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 공용라벨 특별항목 필수등록 복원
- **완료**: `SWEIGHT`, `SPRICE` 필수등록을 해제해 저장한 뒤 재실행하면 다시 체크되는 1.3.120 증상을 수정했다.
- 로그 확인: 저장 payload에 두 키워드 모두 `<checked>0</checked>`가 포함되고 트랜잭션도 성공했다. 재실행 시 동일 라벨크기에서 다시 조회했다.
- 원인 확인 및 편집 완료: Windows ODBC는 SQL `BIT 0`을 Dart `false`로 반환하지만 `SpecialColumnDAO`가 `false != 0`으로 판정해 true로 복원했다. bool/num/string을 명시적으로 변환해 `RICH_CHECK_YN`과 같은 경로의 `RICH_MIN_CHECK`를 올바르게 읽는다.
- 회귀 테스트 추가: SQL BIT `false/true`, 숫자 `0/1`, 문자열 `0/1`의 체크 상태 변환을 고정한다.
- 버전은 호환 가능한 국소 상태 복원 버그 수정이므로 PATCH 단계로 `1.3.132`에서 `1.3.133`으로 갱신했다.
- 검증 완료: `test/special_column_dao_test.dart`, `test/label_size_dao_test.dart`, `test/common_label_manage_test.dart` **19/19 통과**. focused analyze **No issues found**(6.3초), formatter와 diagnostics 통과.
- VS Code DTD는 연결돼 있으나 실행 중인 Flutter 앱이 없어 hot reload 대상은 없었다.
- 기능 커밋: `87c24f4` (`공용라벨 특별항목 필수등록 상태 복원`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 추가 키워드 클라이언트 편집 기본값
- **완료**: 품목관리에서 품명·주원료 외 신규 키워드가 별도 설정 없이 `클라이언트 편집 불가`로 생성되는 1.3.120 증상을 수정했다.
- 원인 확인: `LabelColumnSaveDao._contentInsert(true)`가 신규 키워드의 기존 품목 콘텐츠 행을 만들 때 `RICH_EDITABLE=0`을 명시한다. 누락 행의 UI fallback은 이미 true이므로 생성 SQL이 직접적인 원인이다.
- 편집 완료: 신규 키워드 콘텐츠 생성 기본값을 `RICH_EDITABLE=1`로 변경했다. 사용자가 명시적으로 저장한 기존 불가 상태는 변경하지 않으며 DB 마이그레이션은 수행하지 않는다.
- 회귀 테스트 추가: optional editable 스키마의 생성 SQL이 1을 사용하고 기존 0 구문을 포함하지 않는지 확인한다.
- 버전은 호환 가능한 국소 기본값 수정이므로 PATCH 단계로 `1.3.131`에서 `1.3.132`로 갱신했다.
- 검증 완료: `test/label_column_save_test.dart` **16/16 통과**, focused analyze **No issues found**(7.5초), formatter와 diagnostics 통과.
- VS Code DTD는 연결돼 있으나 실행 중인 Flutter 앱이 없어 hot reload 대상은 없었다.
- 기존 DB의 `RICH_EDITABLE=0`은 사용자가 명시한 불가 설정과 구분할 메타데이터가 없어 자동 변경하지 않는다. DB 마이그레이션 없이 이후 신규 키워드 콘텐츠의 기본 생성값만 바로잡는다.
- 기능 커밋: `beb4721` (`추가 키워드 클라이언트 편집을 기본 허용`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 현재 작업: 품목관리 편집 후 가로 스크롤 소실
- **완료**: 1.3.120 로그에서 소비기한 `365`를 `360`으로 Enter 확정한 뒤 가로 스크롤이 사라진 증상을 수정했다.
- 로그상 편집 전 `overflow=true`, `contentWidth=2023.6`, `viewportWidth=1849.7`이며 편집 후 overflow 변경 로그는 없다. 실제 thumb 페인트 소실 여부를 검증하는 focused widget test를 보강 중이다.
- 편집 완료: 공용 `FortuneTable`은 가로 overflow 동안 `RawScrollbar.thumbVisibility`와 `trackVisibility`를 함께 유지한다. 회귀 테스트는 Enter 편집 직후와 5초 뒤에도 두 표시 속성, overflow, 실제 좌우 이동을 확인한다.
- 버전은 호환 가능한 국소 UI 버그 수정이므로 PATCH 단계로 `1.3.130`에서 `1.3.131`로 갱신했다.
- focused 검증 완료: `test/item_manage_horizontal_scroll_test.dart` **1/1 통과**. 편집 직후와 5초 뒤의 thumb/track 표시, overflow, 좌우 이동을 확인했다.
- 변경 Dart 파일 formatter와 diagnostics를 통과했다. VS Code DTD에는 연결했으나 실행 중인 Flutter 앱이 없어 hot reload 대상은 없었다.
- 추가 검증 완료: `C:/Flutter/bin/flutter.bat test --no-pub --reporter expanded test/item_manage_horizontal_scroll_test.dart test/fortune_table_test.dart` **75/75 통과**(13.5초).
- 임시 테스트 로그는 `.tmp/copilot/item_scroll_tests.log`에만 생성했으며 Git에 포함하지 않는다.
- 기능 커밋: `777227f` (`품목 편집 후 가로 스크롤 표시 유지`).
- 기존 사용자 변경 [`.vscode/settings.json`](.vscode/settings.json), [`lib/core/app.dart`](lib/core/app.dart)는 유지하고 stage/commit에서 제외한다.

## 새 세션 시작 순서
1. 사용자가 새로 제시하는 디버깅 증상을 먼저 조사한다. 증상이 제시되기 전에는 과거 문제를 현재 문제로 가정하지 않는다.
2. 새 디버깅을 마친 뒤 GoDEX G500 역상 흰 획 소실 문제를 재개한다.
3. 인쇄이거나 DB 변경이 필요한 재현은 사용자 승인 없이 실행하지 않는다.

## 현재 기준
- 현재 버전은 **1.4.4**이며 일반 사용자 품목관리는 항목편집에서 `표시`로 저장한 라벨 항목만 동적 열로 보여준다. 인쇄 동작 변경은 없고 직전 인쇄 구현 기준은 **1.3.129**다.
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
