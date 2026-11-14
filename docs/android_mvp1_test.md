# 최후의 참호 (LAST TRENCH) - MVP 1 Android 실기 검증 가이드

본 문서는 **최후의 참호 (LAST TRENCH)** MVP 1 빌드(`builds/debug/LAST_TRENCH.apk`)를 실제 안드로이드 기기에서 설치하고, 마스터 프롬프트 및 게임 기획서(GDD)의 핵심 불변 규칙(Invariants)과 3웨이브 방어 플레이를 완벽히 검증하기 위한 상세 매뉴얼입니다.

---

## 1. 사전 준비 사항 (Prerequisites)

1. **안드로이드 기기:**
   - 안드로이드 OS 8.0 (API 26) 이상 탑재 기기 (ARM64 또는 ARMv7)
   - 기기 설정 > **개발자 옵션(Developer Options)** > **USB 디버깅(USB Debugging)** 활성화
2. **Mac 개발 환경:**
   - Mac과 안드로이드 기기를 USB 케이블로 연결
   - Android SDK ADB 경로: `~/Library/Android/sdk/platform-tools/adb`
3. **디버그 APK 파일 위치:**
   - `/Users/kobujang/Desktop/cording/LAST_TRENCH/builds/debug/LAST_TRENCH.apk` (용량: ~55MB, v2+v3 서명 완료)

---

## 2. 1-클릭 설치 및 실행 명령어

터미널에서 아래 명령어를 순차적으로 실행합니다:

### 1단계: 연결된 기기 확인
```bash
~/Library/Android/sdk/platform-tools/adb devices
```
> **정상 출력 예시:**
> ```
> List of devices attached
> R58NXXXXXXX    device
> ```
> *(기기 화면에 "이 컴퓨터에서 항상 허용" 팝업이 뜨면 "허용"을 탭하세요)*

### 2단계: APK 설치
```bash
~/Library/Android/sdk/platform-tools/adb install -r /Users/kobujang/Desktop/cording/LAST_TRENCH/builds/debug/LAST_TRENCH.apk
```
> **정상 출력:** `Success`

### 3단계: 게임 실행
```bash
~/Library/Android/sdk/platform-tools/adb shell am start -n com.lasttrench.game/com.godot.game.GodotApp
```
*(또는 기기 앱 서랍에서 **"최후의 참호"** 아이콘 터치)*

### 4단계: 실시간 게임 로그 및 성능 모니터링 (선택)
```bash
~/Library/Android/sdk/platform-tools/adb logcat -s Godot:I
```

---

## 3. MVP 1 실기 검증 체크리스트 (Test Scenarios)

아래 체크리스트를 따라 실제 터치 조작 및 게임 규칙을 확인하십시오:

| 번호 | 검증 항목 | 세부 확인 내용 | 판정 (Pass/Fail) |
| :--- | :--- | :--- | :---: |
| **TC-01** | **가로 모드 고정** | 기기를 180도 돌렸을 때 센서 가로 회전이 자연스럽게 지원되며, 세로로 돌아가지 않는지 확인 | [ ] |
| **TC-02** | **좌측 가상 조이스틱** | 화면 좌측 하단을 터치하여 드래그할 때 병사가 전/후/좌/우 8방향으로 참호 내부를 부드럽게 이동하는지 확인 | [ ] |
| **TC-03** | **우측 시점 드래그** | 화면 우측 빈 공간을 스와이프할 때 카메라 시점(Yaw/Pitch)이 부드럽게 회전하고 크로스헤어가 정렬되는지 확인 | [ ] |
| **TC-04** | **소총 사격 및 재장전** | **[사격]** 버튼 터치 시 즉시 탄약이 소모(30발)되고 반동/사격이 발생하는지, **[재장전]** 버튼 터치 시 1.8초 후 30발 완충되는지 확인 | [ ] |
| **TC-05** | **ADS 견착 조준** | **[조준]** 버튼을 탭했을 때 카메라가 어깨너머로 좁혀지고(FOV 55), 크로스헤어가 좁혀져 정밀 사격 모드가 되는지 확인 | [ ] |
| **TC-06** | **고정 슬롯 포탑 설치** | 참호 좌/우의 **지정 방어 슬롯(DefenseSlot)** 근처(2.5m)로 접근했을 때 우측에 **[포탑 설치]** 버튼이 노출되고, 터치 시 고정 기관총 포탑이 즉시 배치되는지 확인 | [ ] |
| **TC-07** | **자유 배치 방지 규칙** | 이미 포탑이 설치된 슬롯에서는 중복 설치가 차단되고, 참호 바닥 아무 곳이나 임의 배치가 불가능한지(지정 앵커 슬롯 전용) 확인 | [ ] |
| **TC-08** | **포탑 자동 사격/수리** | 설치된 기관총 포탑이 전방에서 다가오는 보병 및 공중 드론을 자동 탐지하여 사격(12 데미지)하는지, 파손 시 접근하여 **[포탑 수리]** 가능한지 확인 | [ ] |
| **TC-09** | **적 전방 스폰 규칙** | 모든 적(보병 및 드론)이 참호 후방(360도)이 아닌 **전방 시야 반구 ($Z \le -15$)**에서만 출현하는지 확인 | [ ] |
| **TC-10** | **필드 활성 적 수 제한** | 적이 대량 스폰되어도 화면 내 활성 적 개체수가 **최대 12마리**로 엄격히 제한되어 렉이 발생하지 않는지 확인 | [ ] |
| **TC-11** | **1회 즉시 자동 부활** | 병사 HP가 0이 되었을 때 즉시 HP 80%로 자동 부활하며, 1.5초간 무적 가드가 작동하고 상단 부활 토큰이 0으로 차감되는지 확인 | [ ] |
| **TC-12** | **복합 패배 조건** | 부활 토큰 소진 후 2차 사망 시 즉시 패배 화면이 나오는지, 혹은 참호 거점(Base) 파괴 시 병사 생존과 무관하게 즉시 패배 화면이 표출되는지 확인 | [ ] |
| **TC-13** | **3-웨이브 승리 화면** | 웨이브 1(보병 4) -> 웨이브 2(보병 5+드론 2) -> 웨이브 3(보병 6+드론 4)를 모두 처치했을 때 **승리(Victory) 결과 패널**이 정확히 표출되는지 확인 | [ ] |
| **TC-14** | **30 FPS 성능 유지** | 모바일 실기에서 전투 진행 및 다수 적 출현 시에도 30 FPS 이상의 쾌적한 반응 속도를 유지하는지 확인 | [ ] |

---

## 4. 문제 발생 시 조치 방법 (Troubleshooting)

1. **`adb: command not found` 오류 발생 시:**
   - 전체 경로 `~/Library/Android/sdk/platform-tools/adb`를 직접 사용하거나, `export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"`를 셸에 추가하세요.
2. **`INSTALL_FAILED_UPDATE_INCOMPATIBLE` 오류 발생 시:**
   - 기존에 다른 서명으로 설치된 앱이 있는 경우입니다:
     ```bash
     ~/Library/Android/sdk/platform-tools/adb uninstall com.lasttrench.game
     ~/Library/Android/sdk/platform-tools/adb install -r /Users/kobujang/Desktop/cording/LAST_TRENCH/builds/debug/LAST_TRENCH.apk
     ```
3. **Google Play 프로텍트 경고 팝업이 뜰 때:**
   - 자체 개발 디버그 서명이므로 **"무시하고 설치(Install anyway)"**를 선택하십시오.
