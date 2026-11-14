# 🎖️ 최후의 참호 (LAST TRENCH)

> **"적들의 파상공세를 막아내고 최후의 전선을 사수하라!"**  
> 모바일(Android) 및 웹(WebGL) 크로스 플랫폼 3D 참호 방어 슈팅 게임

---

## 📌 게임 개요 (Overview)
**최후의 참호 (LAST TRENCH)**는 1차 대전풍 참호 거점을 배경으로 밀려오는 적 지상 보병 및 공중 자폭 드론을 소총과 거점 방어 기관총 포탑으로 섬멸하는 3D 전술 디펜스 게임입니다.

- **엔진:** Godot Engine 4.7 Standard (Mobile Renderer)
- **지원 플랫폼:** Android (스마트폰/태블릿) & Web (PC/모바일 웹 브라우저)
- **장르:** 3D TPS 슈팅 & 참호 타워 디펜스 (Trench Defense)

---

## 🎮 핵심 게임 시스템 (Core Mechanics)

1. **지정 방어 슬롯 포탑 설치 (Fixed Defense Slots):**
   - 참호 바닥 임의 배치가 엄격히 차단되며, 참호 좌/우의 지정된 앵커 슬롯(`DefenseSlot`)에서만 포탑 설치 및 수리가 가능합니다.
2. **전방 시야 스폰 규칙 (Front Spawn Only):**
   - 360도 무작위 스폰을 배제하고, 참호 전방 시야 반구($Z \le -15$)에서만 지상 보병과 공중 드론이 체계적으로 접근합니다.
3. **엄격한 필드 적 수 제한 (Active Enemy Cap):**
   - 화면 내 동시 활성 적 개체수를 최대 12마리로 제어하여 모바일 30 FPS 및 웹 60 FPS 성능을 완벽히 보장합니다.
4. **1회 긴급 자동 부활 (1-Time Revive Token):**
   - 병사 체력이 0이 되면 즉시 체력 80%로 자동 부활하며, 1.5초간 무적 가드가 작동합니다.
5. **참호 거점 파괴 시 즉시 패배:**
   - 병사 생존 여부와 관계없이 참호 거점(체력 500)이 파괴되면 즉시 작전 실패로 이어집니다.
6. **3-웨이브 승리 루프:**
   - Wave 1 (보병 4) → Wave 2 (보병 5, 드론 2) → Wave 3 (보병 6, 드론 4) 전멸 시 최종 승리!

---

## 🕹️ 조작 가이드 (Controls)

### 🖥️ PC 웹 브라우저 (Web Controls)
| 액션 | 키 / 입력 | 설명 |
| :--- | :--- | :--- |
| **시점 락 (조준 모드)** | **화면 클릭** | 마우스 커서를 고정하고 360도 TPS 시점 회전 |
| **커서 해제** | **`[ESC]`** | 마우스 커서 잠금 해제 |
| **병사 이동** | **`[W, A, S, D]`** | 참호 내부 8방향 이동 |
| **소총 발사** | **`[마우스 좌클릭]`** | 조준선 방향 히트스캔 사격 |
| **견착 조준 (ADS)** | **`[마우스 우클릭]`** | 카메라 줌인 (FOV 55), 정밀 조준선 |
| **탄약 재장전** | **`[R]`** | 30발 완충 (1.8초 소요) |
| **포탑 설치 / 수리** | **`[E]`** | 거치대 슬롯 2.5m 접근 시 설치 및 파손 수리 |

### 📱 안드로이드 모바일 (Touch Controls)
- **좌측 영역:** 가상 조이스틱 (반경 70px)
- **우측 영역:** 스와이프 시점 회전 + 사격 / 조준 토글 / 재장전 / 상황별 설치 버튼

---

## 🚀 실행 방법 (How to Play)

### 1. 로컬 웹 플레이 (Web)
```bash
python3 tools/serve_web.py
```
> 브라우저에서 `http://127.0.0.1:8080`이 자동으로 열립니다.

### 2. 안드로이드 기기 설치 (Android APK)
```bash
~/Library/Android/sdk/platform-tools/adb install -r builds/debug/LAST_TRENCH.apk
```

---

## 🧪 자동 검증 스위트 (Automated Tests)
본 프로젝트는 11개의 헤드리스 자동화 테스트 스위트를 구비하고 있습니다:
```bash
godot --headless -s tests/test_p01_smoke.gd
godot --headless -s tests/test_p02_map.gd
godot --headless -s tests/test_p03_player.gd
godot --headless -s tests/test_p04_weapon.gd
godot --headless -s tests/test_p05_infantry.gd
godot --headless -s tests/test_p06_drone.gd
godot --headless -s tests/test_p07_turret.gd
godot --headless -s tests/test_p08_wave.gd
godot --headless -s tests/test_p09_session.gd
godot --headless -s tests/test_p10_ui.gd
godot --headless -s tests/test_web_pc_controls.gd
```
