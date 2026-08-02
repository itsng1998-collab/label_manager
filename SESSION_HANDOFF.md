# 현재 작업 상태

## 완료: 네이티브 프린터 다이얼로그 선택 유지 v1.0.27
- 원인: `PrintDlgW` 호출 시 현재 프린터의 `hDevNames`를 전달하지 않아 Windows 기본 프린터로 매번 초기화된다.
- `raw_printer_win32.dart`: `showPrinterSetupDialog(initialPrinterName:)`가 현재 프린터의 장치명과 포트를 조회해 `DEVNAMES` 초기값을 구성한다.
- `label_print_settings_dialog.dart`: 현재 `printerName`을 네이티브 다이얼로그 초기값으로 전달한다.
- `label_sheet_workbench.dart`: 현재 `_printSelectedPrinterName`을 네이티브 다이얼로그 초기값으로 전달한다.
- 검증 완료: `raw_printer_win32_test.dart` 1건, 프린터 설정 widget test 2건 통과.
- 변경한 production 파일 3개 analyzer 및 diagnostics 통과.
- 버전은 호환 가능한 국소 버그 수정으로 `1.0.26`에서 `1.0.27`로 PATCH 증가했다.
- Windows Debug 빌드는 실행 중인 `label_manager.exe`(PID 13484)가 출력 EXE를 잠가 `LNK1168`로 실패했다. 코드 컴파일 오류는 확인되지 않았다.
- Microsoft `PRINTDLGW`/`DEVNAMES` 계약과 movable global memory, 문자 단위 offset, `wDeviceOffset` 초기화 방식을 대조했다.
- `git diff --check` 통과, 버전 생성 결과 `1.0.27`.
- stage 대상: `SESSION_HANDOFF.md`, `raw_printer_win32.dart`, 두 UI 호출부, `pubspec.yaml`; 사용자 변경 `lib/core/app.dart` 제외.

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
