# 06. 테스트·Android 빌드·배포 실행 지침서

**개발 환경:** Mac / Godot 4(Standard + GDScript) / Google Antigravity  
**최초 기기:** Android 중급 이상, 가로 고정, 30FPS 목표. **실제 기기/빌드 결과는 아직 생성·검증되지 않았다.**

## 1. 테스트 원칙과 판정

- 요구사항과 실제 구현은 `07_Requirements_Traceability.md`의 Q##에 대조.
- 모든 케이스는 `PASS`, `FAIL`, `NOT TESTED`, `BLOCKED` 중 하나로 기록. **미검증 ≠ 통과**.
- 가상의 시뮬레이션 FPS나 Mac 에디터 프레임을 Android 30FPS 성능의 근거로 사용하지 않는다.
- 한 단계에서 파일을 생성했다고 테스트가 완료된 것이 아니다. **앱 실행 + 입력 + 상태 전이**를 확인한다.
- 표준 검증(질문 20 확정)이 최종 기준. 출시 단계에서는 오프라인/광고/스토어 위험을 추가 점검한다.

## 2. Mac 최초 실행 환경 점검

### 2.1 필수 설치 체크

1. **Godot 4 안정 버전(Standard)** 설치. https://godotengine.org/download/ (GDScript 사용; C#/.NET 필수 아님).
2. **Google Antigravity** 설치. https://www.antigravity.google/product/antigravity-ide 에서 Mac 아키텍처에 맞는 설치본 확인. 제품의 UI/요금제/접근 권한은 시점별 변경 가능.
3. **Git** 설치 및 저장소 초기화. 프로젝트 안 `builds/`, `.godot/`, `*.keystore`, `*.jks`, 민감한 환경 파일 등 Git 제외 규칙 검토.
4. **Android SDK/Android Platform Tools** 준비. SDK 경로 및 `adb` 실행 확인.
5. **OpenJDK:** 사용 중인 Godot 안정 버전 공식 Android 문서에 맞춤. Godot 4.6 기준 문서는 OpenJDK 17을 권장한다. 추후 Godot 4.8+의 자동 SDK 설치 가능 여부도 별도 확인.
6. **Android USB Debugging:** 테스트 기기에서 개발자 옵션·USB 디버깅 켜고 Mac에 연결. 사용자가 기기 권한을 승인해야 함.
7. **Godot Export Templates:** 사용 중인 엔진 버전과 동일한 내보내기 템플릿 설치.

### 2.2 환경 확인 명령 예시

```bash
# 터미널에서 (실제 설치 경로/명령에 따라 수정)
godot --version
git --version
java -version
adb version
adb devices

# Godot 앱으로 설치했고 PATH에 등록되지 않았다면 경로를 확인:
/Applications/Godot.app/Contents/MacOS/Godot --version
```

Godot 실행 파일의 이름/설치 위치는 실제 환경에 따라 달라진다. Antigravity에는 작업 전 `command -v godot` 또는 앱 번들의 위치를 확인하게 한다.

### 2.3 프로젝트 검사 명령

```bash
# GODOT_BIN은 실제 Mac에서 성공한 명령으로 대체.
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
export PROJECT_DIR="$HOME/Projects/LAST_TRENCH"  # 실제 폴더로 수정

"$GODOT_BIN" --version
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --editor --import
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --quit-after 10
```

`--headless --editor --import`는 씬/리소스 임포트와 파싱 검증을 보조하지만, 모든 UI·게임 로직 버그를 검출하지 못한다. `--quit-after 10`은 시작 씬이 있고 실행 가능한 경우의 간단한 스모크 테스트이며, 실제 테스트 코드가 따로 있어야 기능을 검증할 수 있다.

### 2.4 테스트 스크립트 실행(에이전트가 작성 후)

```bash
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --script res://tests/test_wave_director.gd
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --script res://tests/test_economy.gd
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --script res://tests/test_save_restore.gd
```

**주의:** 위 test 파일은 **향후 Antigravity가 생성할 목표 경로**이며 현재 문서 패키지에는 실제 GDScript 테스트 스크립트가 없다. 각 테스트는 `SceneTree`/`MainLoop`를 올바로 종료하고 오류 발생 시 비정상 종료코드 또는 로그를 남기도록 구현해야 한다.

## 3. 요구사항 기반 테스트 케이스

다음은 테스트 **명세**다. 초기 수행 결과는 모두 `NOT TESTED`.

| ID | 테스트 | 절차 | 기대 결과 | 우선 단계 |
|---|---|---|---|---|
| TC-01 | 가로 화면 | 앱 실행/휴대폰 회전 | 가로 유지, 주요 버튼 잘림 없음 | MVP1 |
| TC-02 | TPS 기본 이동 | 좌측 스틱 이동 | 병사 이동, 참호 벽 관통 없음 | MVP1 |
| TC-03 | 카메라/ADS | 우측 드래그→조준 | 넓은 3인칭↔어깨너머 부드럽게 전환 | MVP1 |
| TC-04 | 사격·재장전 | 탄창 소진 후 재장전 | 잔탄·재장전 정확, 중복 피해 없음 | MVP1 |
| TC-05 | 적 2종 | 보병·공격드론 출현 | 지상+전방 상공 구분, 격파 가능 | MVP1 |
| TC-06 | 적 출현 방향 | 3웨이브 반복 | **정면 중심**, 360도 상시 출현 없음 | MVP1 |
| TC-07 | 지정 슬롯 설치 | 빈 슬롯 근접/원격/바깥 클릭 | 근접 설치 가능, 원거리·무허가 위치 설치 불가 | MVP1 |
| TC-08 | 포탑 수리 | 포탑 손상 후 접근 | 수리 가능, 체력 한계 초과 없음 | MVP1/MVP2 |
| TC-09 | 1회 부활 | 병사 HP 0 두 차례 | 첫 회 자동 부활, 두 번째 패배 | MVP1 |
| TC-10 | 거점 패배 | Base HP 0 | 부활 잔여와 관계없이 패배 | MVP1 |
| TC-11 | 웨이브 3개 | 적 전멸/시간·완료 조건 | 1→2→3→승리, 보상 이벤트 중복 없음 | MVP1 |
| TC-12 | 동시 적 수 | 반복 다수 스폰 | 활성 적 수 10~15 목표 cap 준수 | MVP1 |
| TC-13 | 두 자원 분리 | 무기 구매/시설 수리 | 서로 다른 재화만 차감, 잔고 음수 없음 | MVP2 |
| TC-14 | 카드 보상 | 웨이브 완료→3장 표시→연속 탭 | 정확히 1장 적용, 크레딧 1회 지급 | MVP2 |
| TC-15 | 영구 해금 | 장비 해금 후 새 게임 | 해금/업적/최고 기록 유지, 런 재화 초기화 | MVP2 |
| TC-16 | 체크포인트 | 웨이브 종료 후 앱 중단/재실행 | 직전 안전 경계부터 이어하기 | MVP2 |
| TC-17 | 전투 중 종료 | 웨이브 중 강제 종료 | 마지막 완료 체크포인트로 복원 | MVP2 |
| TC-18 | 포기 | 이어하기 화면에서 포기 | active_run만 무효, profile 보존 | MVP2 |
| TC-19 | 손상 저장 복구 | JSON 일부 훼손 테스트 | 백업 또는 신규 출격 안전 경로, crash 없음 | MVP2 |
| TC-20 | 15웨이브/보스 | 정상 난이도로 완주 | 5/10/15 보스 출현, 최종 승리 | 완성형 |
| TC-21 | 독립 모드 | 참호 끝→메뉴→개활지 시작 | 씬/런 분리, 인게임 모드 전환 없음 | 완성형 |
| TC-22 | 난이도 3단계 | 쉬움/보통/어려움 선택 | 적 수·HP 등 데이터 반영, 부활 1회 동일 | 완성형 |
| TC-23 | 환경 이벤트 | 재밍·포격·야간 등 실행 | 경보·정상 복구, 부적절한 입력 잠금 없음 | 완성형 |
| TC-24 | KO/EN | 언어 변경/재실행 | 주요 화면 번역·설정 유지, 버튼 잘림 없음 | 완성형 |
| TC-25 | 조작 설정 | 버튼 위치·크기/보조 강도 변경 | 저장/복원, 버튼 충돌 없음 | 완성형 |
| TC-26 | 30FPS | 실제 중급 Android에서 포탑·적 10~15개 | 측정 FPS와 프레임시간 보고; 기준 미달 시 개선 | 최적화 |
| TC-27 | 오프라인 | Wi-Fi·데이터 끔 | 전투·저장·장비 해금 정상 | 출시 |
| TC-28 | 광고 실패 | 네트워크 끊김·광고 취소 | 진행 차단/재화 손실 없음 | 출시 |
| TC-29 | 광고 성공 1회 | 자발적 시청 완료/중복 콜백 | 완료 보상 한 번만 적용 | 출시 |
| TC-30 | AAB 서명/출시 | 릴리스 빌드 | 서명·버전·패키지 검증, 스토어 업로드 준비 | 출시 |

### 3.1 실제 테스트 결과 기록 양식

```markdown
### TC-XX [테스트명]
- Test build / Git commit: 
- Godot version / renderer: 
- Android model / OS / RAM: 
- Steps performed: 
- Expected / Actual: 
- Result: PASS | FAIL | NOT TESTED | BLOCKED
- Screenshot/video/log reference: 
- FPS / frame time when relevant: 
- Issue ID and severity: 
- Tester / date: 
```

## 4. FPS·메모리·발열 측정 기준

**인터뷰에서 확정된 값:** 중급형 Android, 30FPS, 동시 활성 적 10~15개, 자동 최적화.

1. 테스트 기기의 모델/칩셋/RAM/Android 버전/해상도/주사율을 기록한다.
2. 장치 온도/배터리 상태 등 시작 조건을 가능하면 동일하게 하고 앱을 2회 이상 반복 실행한다.
3. '참호 웨이브 2~3', '다수 드론/포탑', '폭발·포격', '15웨이브 보스', '개활지'를 각각 **실제 장치에서** 측정한다.
4. 최소 평균 FPS, 1% 저속 프레임, 프레임 시간(ms), 앱 메모리 사용량/크래시 여부를 로그에 기록. 30FPS의 이론적 프레임 시간은 약 33.3ms이지만 목표는 화면 경험에서 확인한다.
5. 기기 감지 기반 그래픽 프로필(기본 낮음/보통/높음)을 적용하되, 자동 판단이 틀리면 사용자가 직접 변경 가능하도록 한다.
6. 목표 미달 시 동시 적 수 규칙 위반 여부, AI 연산, 드로우콜, 이펙트, 투명 파티클, 동적 조명, 과도한 물리 충돌을 순서대로 점검.
7. 최종 보고서에는 **측정값만** 사용하고 임의 추정 FPS를 쓰지 않는다.

## 5. Android 디버그 APK 빌드 — 단계별

공식 참고: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

### 5.1 Godot에 SDK 연결

1. Godot 프로젝트를 열고 **Editor > Manage Export Templates**에서 현재 버전에 맞는 템플릿을 설치.
2. 설치한 Godot 버전의 공식 Android 문서에 따라 JDK 및 Android SDK 준비. Mac의 SDK 경로는 보통 `$HOME/Library/Android/sdk`이나 설치 방식에 따라 다르므로 직접 검사.
3. Godot **Editor Settings > Export > Android** 등 버전별 메뉴에 Java SDK Path, Android SDK Path를 지정. 해당 SDK 디렉터리에 `platform-tools/adb`가 존재하는지 확인.
4. 프로젝트의 **Project > Export > Add > Android** Export Preset을 만든다. 패키지 ID는 사용자 소유 도메인/개발자 식별자에 맞춰 **출시 전 확정**. 문서 예제 ID를 그대로 출시하지 않는다.
5. Android 가로 화면/터치/권한(최소) 설정, 아이콘/스플래시 설정. 개발 초기는 **Debug** 빌드.
6. Export Project에서 `.apk` 출력. 성공 로그 확인, 실제 파일 존재와 크기 확인.

### 5.2 터미널 빌드(Export Preset을 설정한 이후)

```bash
mkdir -p "$PROJECT_DIR/builds/debug"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-debug "Android" "$PROJECT_DIR/builds/debug/last_trench_debug.apk"
ls -lh "$PROJECT_DIR/builds/debug/last_trench_debug.apk"
```

- 실제 `export_presets.cfg`의 프리셋 명칭이 "Android"가 아니면 정확한 명칭으로 바꿔야 한다.
- Export Templates 및 SDK 설정을 완료하지 않은 상태에서는 실패하는 것이 정상일 수 있다.
- APK 성공을 보고하기 전에 파일 존재와 명령 종료코드를 확인한다.

### 5.3 Android 기기 설치·실행

```bash
adb devices
adb install -r "$PROJECT_DIR/builds/debug/last_trench_debug.apk"
adb logcat -c
# 기기에서 게임을 직접 열어 테스트
adb logcat -d -t 300 > "$PROJECT_DIR/builds/debug/android_last_logcat.txt"
```

ADB 설치 중 동일 package name이지만 서로 다른 서명키로 설치된 앱 때문에 오류가 나면 기존 설치를 식별하고, 사용자 저장 데이터 보존 여부를 확인한 뒤 수동 제거 여부를 승인받는다. **무조건 삭제하지 말 것**.

## 6. 정식 Google Play 서명 AAB

공식 참고: https://docs.godotengine.org/en/stable/tutorials/export/android_gradle_build.html

1. Android 핵심 게임 기능과 표준 회귀가 먼저 통과해야 함.
2. Export Templates, JDK/SDK, Gradle Build Template 설정. Google Play 제출용 신규 앱은 **AAB**를 사용하고, Godot 공식 문서에 맞춰 **Gradle 빌드 활성화**.
3. 서명용 **비공개 Release Keystore** 생성/관리. `keytool` 사용은 가능하나 키 암호/경로는 사용자의 안전한 위치에 보관. **Antigravity 대화/로그/ GitHub/ZIP으로 키파일이나 암호를 전달하지 않는다.**
4. Export Preset의 Release Keystore Path, alias, password를 사용자 로컬에서 지정. 화면 공유 및 로그 기록 시 비밀값 마스킹.
5. 릴리스 빌드(디버그 체크 해제)로 `last_trench_release.aab` 생성. 앱 패키지·버전 코드·서명·권한 점검.
6. Google Play Console에서 개발자 등록/인증/비공개 테스트·앱 콘텐츠·개인정보처리방침·광고 선언·콘텐츠 등급·연령/지역 정책 등 **출시 당시의 최신 요건**을 확인. 사용자 승인 없이 제출하지 않는다.
7. 테스트 트랙 검증 후 단계별 출시, 크래시/ANR/성능/사용자 평가 모니터링.

```bash
mkdir -p "$PROJECT_DIR/builds/release"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "Android" "$PROJECT_DIR/builds/release/last_trench_release.aab"
ls -lh "$PROJECT_DIR/builds/release/last_trench_release.aab"
```

**중요:** 위 명령만으로 AAB 서명·Google Play 적합성이 자동 보장되지는 않는다. Gradle Export Preset 구성, 서명, 앱 번들 검사 후 실제 제출 가능 여부를 판단한다.

## 7. 보상형 광고 검증 (출시 단계)

- 핵심 전투는 **오프라인에서 완전 실행**.
- 광고 버튼은 희망 시 탭. 광고 재고/연결이 없으면 해당 버튼을 비활성화하고 현 상태 안내. 강제 팝업 금지.
- 정상 완료 → 광고 SDK가 제공하는 신뢰 가능한 완료 이벤트를 수신해 **transaction_id 중복 검사 후 한 번만 보상**.
- 취소/실패/비행기모드/중복 콜백/앱 백그라운드 중단/광고 후 복귀 실패 시 무손실 처리.
- 광고 보상은 게임의 **필수 진행 조건이 아니고** 영구 해금 독점 경로를 만들지 않음.
- Godot 내장 기능만으로 특정 광고 사업자의 SDK가 자동 연결되는 것은 아니므로, **현재 호환 플러그인** 및 Android·iOS 정책을 출시 시점에 검증해야 함.

## 8. 한국어·영어 현지화/접근성 테스트

- 모든 화면 텍스트는 번역 키 사용, KO/EN 둘 다 표시될 것.
- 긴 영어 문자열과 한글 글꼴을 최소/최대 텍스트 크기에서 확인.
- 색상만으로 '위험/안전/설치 가능'을 구분하지 않고 아이콘/텍스트 병행.
- 터치 버튼 사용자 크기·위치, Safe Area, 카메라 흔들림/진동 옵션의 저장·복구 확인.

## 9. 배포 전 보안/저작권/정책 체크

- 타인의 군사 장비 영상/모델/효과음을 무단 포함하지 않음. 코드 생성 기본 메시 사용; 외부에셋 도입 시 이용허락 증빙 기록.
- 특허/상표가 붙은 무기나 실제 단체 상표를 오인할 수 있게 사용하지 않음.
- 키스토어·릴리스 비밀번호·광고 키·개발자 계정 정보 버전 관리 금지.
- 광고·개인정보·연령등급·스토어 콘텐츠 정책은 **해당 시점의 공식 문서**로 확인.
- 자동으로 외부 서버에 게임 로그·개인 데이터를 전송하지 않음. 로그는 로컬 중심, 사용자 동의 없는 수집 없음.

## 10. 오류 해결 대응표

| 증상 | 우선 확인 | 다음 행동 |
|---|---|---|
| `Parse Error` / `Invalid get index` | GDScript 클래스/타입, NodePath, Autoload 등록 | 원인 파일부터 수정하고 headless 재검사 |
| 장면 검은 화면 | main scene, Camera3D current, WorldEnvironment, 조명 | 임시 단색 씬으로 시야 확인 |
| Android 빌드 실패 | Godot 버전과 Export Templates, SDK/JDK/NDK, Preset | 공식 문서 따라 일치시킨 후 재빌드 |
| 설치 실패 | ADB 승인, 패키지명·서명 불일치 | 기존 설치/데이터를 확인하고 안전 조치 |
| 터치 조작 튐 | 터치 index, Control mouse_filter, UI/시야 입력 경합 | 멀티터치/오른쪽 UI 소비 테스트 |
| 장비 구매 중복 | 클릭 중복, 거래 ID, 저장 경계 | 거래 멱등성 테스트 추가 |
| 이어하기 오류 | active_run schema/version, backup, 파일 교체 시점 | 프로필 보존, active 스냅샷 복구 |
| FPS 급락 | AI 동시 수, VFX, 조명, draw call | 프로파일링/풀링/LOD/그래픽 프로필 |
| 광고 시청 후 게임 멈춤 | 백그라운드 포커스/SDK 콜백/게임 일시정지 | 광고 실패해도 게임 복귀하도록 분리 |

## 11. 최종 사용자 승인 체크리스트

- [ ] Android 가로 실행 및 터치/ADS/사격 정상
- [ ] 참호/개활지 모드 독립 실행(완성형)
- [ ] 지정된 시설 슬롯에서만 설치 가능
- [ ] 적 정면 중심 출현, 보스 5·10·15
- [ ] 1회 자동 부활, 거점 상실 시 패배
- [ ] 크레딧/보급 자원 정확 및 카드 보상 1회
- [ ] 저장·이어하기·포기·영구 해금 정상
- [ ] KO/EN 및 접근성 설정 보존
- [ ] 중급 Android 30FPS **실측 근거 확보**
- [ ] 인터넷 없이 전투 정상, 광고 취소/실패 무손실
- [ ] S0/S1 0건, APK/AAB 실제 파일 검증, 서명·비밀키 보호
- [ ] 스토어 최신 등록·콘텐츠·개인정보·광고 정책 확인

모든 항목은 **개발/검증 시 체크**하는 것이며 현재 체크된 항목은 없다.

## 12. 공식 문서 링크

- Godot CLI: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- Android export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- Android Gradle: https://docs.godotengine.org/en/stable/tutorials/export/android_gradle_build.html
- Project export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html
- iOS export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- Godot save system: https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html
- Godot renderers: https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- Antigravity Agent: https://www.antigravity.google/docs/agent/
