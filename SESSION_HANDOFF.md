# 현재 작업 상태

## 구현 완료·실물 검증 대기: Godex G500 편집 크기·출력 품질 일치 v1.0.28
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
- 남은 검증: 동일 80×60 라벨을 Godex G500으로 재출력해 편집 위치/크기와 작은 한글 획을 실물 비교한다.

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
