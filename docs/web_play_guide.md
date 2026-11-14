# 최후의 참호 (LAST TRENCH) - Web 브라우저 플레이 가이드

본 문서는 기존 Android MVP 1 버전의 코드 및 빌드 산출물(`builds/debug/LAST_TRENCH.apk`, Git 태그 `android-mvp1`)을 **100% 안전하게 보존**하면서, 데스크톱 PC 및 모바일 웹 브라우저에서 즉시 플레이할 수 있도록 구축된 WebGL 버전을 실행하고 즐기기 위한 안내서입니다.

---

## 1. 버전 보존 현황 (Version Preservation)

- **Android MVP 1 보존:**
  - Git 태그: `android-mvp1`
  - APK 바이너리: `/Users/kobujang/Desktop/cording/LAST_TRENCH/builds/debug/LAST_TRENCH.apk` (55MB)
  - Android 익스포트 프리셋: `export_presets.cfg` (`[preset.0]` Android 유지)
  - P01~P10 전체 회귀 테스트 스위트 100% 통과 유지

---

## 2. 1-클릭 웹 실행 방법 (How to Play)

터미널에서 아래 명령어를 실행하면 전용 로컬 서버가 시작되고 **기본 웹 브라우저(Chrome, Safari, Edge 등)가 자동으로 열립니다**:

```bash
python3 /Users/kobujang/Desktop/cording/LAST_TRENCH/tools/serve_web.py
```

또는 직접 원하는 포트에서 실행할 경우:
```bash
# 브라우저에서 직접 접속: http://127.0.0.1:8080/
```

> **참고:** Godot 4 WebGL/WASM 구동에 필요한 보안 헤더(`Cross-Origin-Opener-Policy`, `Cross-Origin-Embedder-Policy`)가 `tools/serve_web.py`에 자동 내장되어 있어, 브라우저 호환성 문제 없이 즉시 로드됩니다.

---

## 3. 조작 매뉴얼 (Controls Guide)

### 🖥️ 데스크톱 PC (마우스 & 키보드)
| 액션 | 키 / 입력 | 세부 설명 |
| :--- | :--- | :--- |
| **시점 조준 모드 진입** | **게임 화면 클릭** | 마우스 커서가 화면 중앙에 잠기며(Pointer Lock), 자유로운 360도 TPS 시점 회전이 활성화됩니다. |
| **마우스 잠금 해제** | **[ESC]** 키 | 마우스 커서가 다시 보여 브라우저 다른 창으로 이동할 수 있습니다. |
| **병사 이동** | **[W, A, S, D]** | 참호 내부를 전후좌우 8방향으로 자유롭게 이동합니다. |
| **소총 발사** | **[마우스 좌클릭]** | 조준선 방향으로 히트스캔 소총을 발사합니다. (연사 간격 0.12초) |
| **ADS 견착 조준** | **[마우스 우클릭]** | 카메라가 어깨 너머로 좁혀지고 FOV 55로 확대되며, 크로스헤어가 정밀 모드로 좁혀집니다. |
| **탄약 재장전** | **[R]** 키 | 탄창(30발)을 1.8초간 재장전합니다. |
| **포탑 설치 / 수리** | **[E]** 키 | 참호 좌/우의 **지정 방어 슬롯(DefenseSlot)** 2.5m 이내에서 누르면 포탑이 즉시 설치되거나 수리됩니다. |

### 📱 모바일 / 태블릿 브라우저 (터치스크린)
- 스마트폰이나 태블릿 브라우저로 접속 시 **가상 조이스틱**과 **온스크린 사격/조준/재장전/인터랙션 버튼**이 자동으로 작동합니다.

---

## 4. 웹 빌드 갱신 방법 (Build from Source)

GDScript나 맵 데이터를 수정한 후 웹 빌드를 다시 생성하려면 아래 CLI 명령어를 실행합니다:

```bash
godot --headless --path /Users/kobujang/Desktop/cording/LAST_TRENCH --export-release "Web" builds/web/index.html
```

---

## 5. 핵심 게임플레이 규칙 (Game Invariants)

1. **지정 슬롯 전용 포탑 설치:** 포탑은 참호 바닥 아무 곳이나 임의 설치할 수 없으며, 좌/우 2곳의 지정 슬롯에서만 `[E]` 키로 설치됩니다.
2. **전방 시야 스폰 ($Z \le -15$):** 모든 지상 보병과 공중 드론은 플레이어 전방 시야 반구에서만 스폰됩니다.
3. **최대 활성 적 12마리 제한:** 필드에 동시에 존재하는 적은 최대 12마리로 제어되어 웹 브라우저에서도 부드러운 60 FPS 프레임을 유지합니다.
4. **1회 자동 부활:** 병사 체력이 0이 되면 즉시 체력 80%로 자동 부활하며 1.5초간 무적 가드가 발동합니다.
5. **승리/패배 루프:** 3개 웨이브(보병 15마리, 드론 6마리)를 전멸시키면 승리하며, 2차 사망 또는 참호 거점(체력 500) 파괴 시 패배합니다.
