# 역상 RichEdit 무출력 회귀 검사

Windows, Visual Studio C++/Windows SDK, CMake와 설치된 `Godex G500` 프린터 큐가 필요하다.
큐의 DC를 참조하지만 `StartDoc`를 호출하지 않아 인쇄 작업을 보내지 않는다.
프린터 설정과 DB는 변경하지 않는다.

```powershell
cmake -S tools/inverse_rich_edit_probe -B .tmp/inverse_probe_build -G "Visual Studio 17 2022" -A x64
cmake --build .tmp/inverse_probe_build --config Debug
ctest --test-dir .tmp/inverse_probe_build -C Debug --output-on-failure
```

CTest는 자체 합성 문자열을 사용한다. 저장된 역상 EMF로 검사하려면:

```powershell
.tmp/inverse_probe_build/Debug/inverse_rich_edit_probe.exe <source.emf> .tmp/inverse_probe
./tools/inspect_inverse_emf.ps1 -Path .tmp/inverse_probe/5.emf
```

EMF 입력 모드는 기록된 텍스트에 합성 숫자 꼬리를 추가한다.
원본에서 미출력된 문자를 복원하지 않는다. 203dpi/620x480 페이지의 긴 역상 한 줄 재현용이다.
검사 결과의 BMP/EMF에는 입력 문구가 포함되며 로컬 출력 디렉터리에만 저장한다.

- 0: v1.3.93 배경/배치 기준, 줄 넘침과 흰 사각형을 재현한다.
- 1~3: 배경 확장/target device 옵션의 비교 기록. 폭 문제를 해결하지 못해 생산 경로에 적용하지 않는다.
- 4: 투명 control로 흰 배경 채우기를 없앤다. 폭 문제는 남는다.
- 5~6: 투명 control과 생산 코드의 `MeasureInverseTextLayout`을 사용한다.
  별도 DC 및 동일 DC 측정/출력에서 전체 문자열 기록, 수용 위치와 흰 사각형 제거를 검사한다.

가로 맞춤은 높이와 세로 좌표를 유지한다. 짧은 문자열, wrap=true, 명시적 개행은 축소하지 않는다.
EMF 재생은 실제 스풀 캡처가 아니며 실물의 획 소실 개선 여부를 보장하지 않는다.