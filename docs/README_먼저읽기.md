# 최후의 참호 (LAST TRENCH) — Antigravity 바이브 코딩 개발 패키지

**기준일:** 2026-11-13  
**문서 버전:** 1.0 / 인터뷰 21개 확정안  
**상태:** **개발 설계·프롬프트 패키지 완성**. 실제 Godot 게임 구현·Android 실기기 테스트·스토어 출시는 수행되지 않았음.

## 0. 시작하기 — 5분 가이드

1. Mac에 **Godot 4 안정 버전(Standard/GDScript)**, **Google Antigravity**, **Git**을 설치한다. 설치 시점의 안정 버전을 확인하고 프로젝트 및 실행 로그에 정확한 버전을 기록한다. 가능하면 렌더러는 **Mobile**로 시작하되 Android 호환성에 따라 **Compatibility**와 실측 비교한다.
2. `LAST_TRENCH`라는 **새 폴더**와 빈 Git 저장소를 만든다. 이 패키지 안의 `.md` 파일과 `config_examples`를 `LAST_TRENCH/docs/` 아래에 복사한다. **이 문서 폴더 자체가 실행 가능한 Godot 프로젝트는 아니다.**
3. Antigravity에서 `LAST_TRENCH` 폴더를 연다. 먼저 `04_Antigravity_Master_Prompt.md` 내용을 에이전트에 입력한다. 참조 문서를 읽도록 하고, **1단계씩 구현→검증→승인** 절차를 요청한다.
4. `05_Antigravity_Step_by_Step_Prompts.md`의 **P00**부터 차례대로 입력한다. 각 단계의 Gate를 충족하기 전에 다음 프롬프트를 실행하지 않는다.
5. 첫 성공 목표는 **Android 휴대폰에서 참호 3웨이브를 조작하고 승리/패배 결과를 볼 수 있는 MVP 1**이다. 그 이후 저장·성장(MVP 2), 15웨이브·개활지 모드, 출시 기능을 확장한다.

## 1. 파일 읽는 순서

| 파일 | 용도 |
|---|---|
| `01_Game_Design_Document.md` | 최종 게임의 규칙·콘텐츠·UX와 기획 판단 |
| `02_Development_Roadmap.md` | MVP1→MVP2→완성형→출시, 의존성·Gate·리스크 |
| `03_Godot_Technical_Design.md` | 파일·씬·클래스·상태·저장·AI·최적화 인터페이스 |
| `04_Antigravity_Master_Prompt.md` | Antigravity에 최초 전달할 불변 원칙·작업 계약 |
| `05_Antigravity_Step_by_Step_Prompts.md` | P00~P25: 26개 단계별 실행용 프롬프트 |
| `06_Test_Android_Release_Guide.md` | 테스트 케이스·빌드·서명·배포·오류 대응 |
| `07_Requirements_Traceability.md` | 질문 1~21 확정안 및 구현·검증 추적표 |
| `config_examples/*.json` | **예시값**인 밸런스·웨이브·데이터 명세(검증 후 적용) |

## 2. 흔들리면 안 되는 결정

- **3인칭 3D**, 경량 3D, Android 우선/iOS·PC 순차 확장, 가로 화면 고정.
- **개활지**와 **참호 방어**는 메인 메뉴에서 선택하는 **독립 모드**. 처음에는 참호만 만든다.
- 적은 **정면 중심** 출현. 질문 9의 다방향 복합 위협은 정면 중심 원칙을 해치지 않는 한정 이벤트/전방 부채꼴 측면 변주로 처리한다. **상시 360도 출현 금지**.
- 방어시설 설치는 **미리 정해진 슬롯에만** 가능. 자유 설치/혼합 설치 금지.
- 일부 방어벽·모래주머니 등은 파손·수리 가능. 전면 지형 파괴는 범위 밖.
- 전체 15웨이브·20~30분, **5/10/15 보스**, 게임당 병사 **즉시 부활 1회**, 부활 후 사망 또는 거점 상실 시 패배.
- 두 자원: **전투 크레딧(무기·무기 강화)** / **보급 자원(탄약·시설 설치·수리)**. 웨이브 종료 시 강화 카드 3장 중 1개+추가 크레딧.
- 종료 시 장비 해금·업적·기록은 유지, 전투 자원·웨이브 강화는 초기화. 웨이브 경계 자동 저장 + 이어하기/포기.
- 혼합 터치 조작과 선택형 조준 보조, 표준 HUD, 한국어·영어, 오프라인 게임플레이, 선택형 광고는 출시 단계에서 분리 통합.

## 3. Antigravity를 쓰는 방법

1. `04` 전체를 입력하고 파일 접근 권한·명령 실행 범위를 확인한다.
2. `05`에서 한 단계만 입력한다. **한 에이전트에게 여러 단계의 병렬 코드 변경을 지시하지 않는다.**
3. 출력으로 **변경 파일, 변경 요약, 실행 명령, 실제 로그, 화면에서 수동 확인할 항목, 되돌리는 방법**을 받는다.
4. Godot 프로젝트가 열리고 해당 단계 테스트가 통과해야 Git 커밋을 진행한다. Git에 비밀키, 서명키, 광고 API 비밀정보를 넣지 않는다.
5. 에이전트의 '성공' 보고만으로 승인하지 않는다. Android의 화면·터치·성능은 실제 기기로 확인한다.

## 4. 설계상 미확정값 처리 기준

**확정** = 인터뷰를 통해 선택된 요구사항. **제안 초기값** = 엔진에서 시작할 임시 수치·상태(테스트와 사용자 승인 후 조정). `config_examples`의 체력·가격·난이도 수치, 무기 DPS, 웨이브 구성 등은 전부 **제안 초기값**이다. 프로그래밍 구조를 구현하기 위한 합리적 기본값이며 게임 밸런스가 검증됐다는 뜻이 아니다.

## 5. 외부 문서 / 확인 기준

- Godot Android: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- Godot Android Gradle: https://docs.godotengine.org/en/stable/tutorials/export/android_gradle_build.html
- Godot 프로젝트 CLI: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- Godot 렌더러: https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- Godot 저장: https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html
- Godot iOS: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- Antigravity Agent: https://www.antigravity.google/docs/agent/

**주의:** Godot/Android SDK/Google Play/Antigravity UI와 정책은 버전에 따라 달라질 수 있다. 프로젝트 시작 시 안정 버전과 공식 문서를 재확인하고, 그 변경이 발생하면 문서의 기술 부분을 수정하되 인터뷰에서 확정된 게임 요구사항은 자동 변경하지 않는다.
