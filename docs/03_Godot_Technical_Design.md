# 03. Godot 4 상세 기술 설계지침서

**기준일:** 2026-11-13  
**대상:** Mac + Godot 4 안정 버전 + GDScript + Google Antigravity  
**핵심 제약:** Android 중급 기기, 가로 3D, 30FPS, 동시 적 10~15개, 오프라인 게임, 전방 중심 스폰, **지정 슬롯에만 시설 설치**.

## 1. 기술 결정 기록(ADR)

| ADR | 결정 | 이유/검증 |
|---|---|---|
| ADR-01 | Godot 4 안정 버전 Standard + GDScript | 코드 생성·플랫폼 이전·무료 개발. 첫 실행 시 버전 고정 |
| ADR-02 | 렌더러 **Mobile** 출발, 실제 호환성 문제 시 Compatibility 비교 | 목표 Android 중급형/경량 3D. 렌더러별 셰이더·조명 차이 실측 |
| ADR-03 | 3D CharacterBody3D + Camera3D + 터치 UI | TPS 이동·충돌·조준 분리 |
| ADR-04 | 공통 `Session` + 모드별 씬 독립 | 참호↔개활지 인게임 전환 금지, 기능 재사용 |
| ADR-05 | 적 AI = 결정론적 FSM + 경로 웨이포인트/NavigationAgent3D | 첫 단계는 최소 구현, 이후 재현 가능한 적응형 조정 |
| ADR-06 | 시설 = `DefenseSlot` 고정 앵커 | 자유 설치·혼합 배치 금지 |
| ADR-07 | 경제/웨이브/무기 데이터 분리(JSON 또는 Resource) | 바이브 코딩에서 수치 조정 시 로직 안정성 확보 |
| ADR-08 | 영구 `profile.json`과 진행 `active_run.json` 분리 | 영구 해금 보존/런 초기화/이어하기 안전성 |
| ADR-09 | 웨이브 경계 커밋 + 보상 idempotency | 앱 중단 후 보상 중복·런 복구 손상 방지 |
| ADR-10 | 광고 추상 인터페이스 + 실패 허용 | 오프라인 독립성 확보. 출시 직전 호환 SDK 통합 |
| ADR-11 | KO/EN 번역 키 중심 | 두 언어 동시 지원, 문구 하드코딩 최소화 |
| ADR-12 | 에셋은 GDScript 프리미티브 생성 + 교체 가능한 인터페이스 | 초기 무료·경량 3D/외부 에셋 의존 최소화 |

**버전 정책:** Godot 4의 정확한 마이너 버전은 Mac 설치 시 `godot --version`으로 확인해 README와 `docs/dev_environment.md`에 **고정**. 단순히 '최신'을 자동 업그레이드하지 않는다.

## 2. 예상 저장소 구조

```text
LAST_TRENCH/
├── project.godot
├── .gitignore
├── README.md
├── docs/                          # 이 패키지 복사 위치
│   ├── 01_Game_Design_Document.md
│   ├── ...
│   └── development_log.md         # Antigravity 변경 이력
├── scenes/
│   ├── app/main_menu.tscn
│   ├── app/loadout.tscn
│   ├── app/game_root.tscn
│   ├── app/results.tscn
│   ├── maps/trench_map.tscn
│   ├── maps/open_field_map.tscn   # 완성형 단계
│   ├── actors/player.tscn
│   ├── actors/enemy_infantry.tscn
│   ├── actors/enemy_drone.tscn
│   ├── defenses/defense_slot.tscn
│   ├── defenses/mg_turret.tscn
│   ├── ui/battle_hud.tscn
│   ├── ui/touch_controls.tscn
│   └── ui/reward_cards.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_session.gd
│   │   ├── save_manager.gd
│   │   ├── settings_manager.gd
│   │   ├── localization_manager.gd
│   │   └── audio_manager.gd
│   ├── combat/
│   │   ├── player_controller.gd
│   │   ├── third_person_camera.gd
│   │   ├── weapon_component.gd
│   │   ├── damageable_component.gd
│   │   └── projectile_pool.gd
│   ├── ai/
│   │   ├── enemy_base.gd
│   │   ├── infantry_ai.gd
│   │   ├── drone_ai.gd
│   │   ├── target_selector.gd
│   │   └── threat_director.gd
│   ├── defense/
│   │   ├── defense_slot.gd
│   │   ├── turret_controller.gd
│   │   └── destructible_cover.gd
│   ├── systems/
│   │   ├── wave_director.gd
│   │   ├── economy_service.gd
│   │   ├── reward_service.gd
│   │   ├── unlock_service.gd
│   │   ├── run_statistics.gd
│   │   ├── performance_manager.gd
│   │   └── rewarded_ad_provider.gd
│   ├── ui/
│   │   ├── touch_controls.gd
│   │   ├── battle_hud.gd
│   │   └── settings_menu.gd
│   └── tools/
│       └── procedural_assets.gd
├── data/
│   ├── balance.json
│   ├── wave_plan.json
│   ├── unlocks.json
│   └── locale/ko.translation ...   # 프로젝트에 맞춰 형식 선택
├── tests/
│   ├── test_wave_director.gd
│   ├── test_economy.gd
│   ├── test_save_restore.gd
│   └── test_touch_logic.gd
└── builds/                        # Git 제외
```

**파일 경로는 설계상 제안:** 실제 생성 후 모든 단계 프롬프트는 `docs/development_log.md`에 구현 파일과 설계 대조표를 남긴다. `project.godot`의 autoload 경로/씬 경로는 실제 존재 여부를 검사한다.

## 3. 씬 트리와 책임

### 3.1 `game_root.tscn`

```text
GameRoot (Node)
├── CurrentMap (Node3D: trench/open_field 인스턴스 1개)
├── PlayerSpawn (Marker3D 또는 CurrentMap 제공)
├── Actors (Node3D)
├── EnemyPool (Node3D)
├── DefenseRuntime (Node3D)
├── WaveDirector (Node)
├── EconomyService (Node)
├── RewardService (Node)
├── RunStatistics (Node)
├── CombatUI (CanvasLayer)
│   ├── BattleHUD (Control)
│   ├── TouchControls (Control)
│   ├── PauseOverlay (Control)
│   └── WaveRewardOverlay (Control)
└── AudioManager (autoload 연결)
```

한 시점에 **CurrentMap은 하나**만 실행한다. 거점·스폰 출현·시설 슬롯 정보는 해당 맵이 `GameRoot`에 공급한다.

### 3.2 `trench_map.tscn`

```text
TrenchMap (Node3D, script: map_contract.gd)
├── Ground (StaticBody3D)
├── TrenchWalls (StaticBody3D/CollisionShape3D ...)
├── Cover (DestructibleCover 인스턴스 1+)
├── BaseObjective (Node3D, health component)
├── PlayerStart (Marker3D)
├── FrontSpawnZone (Node3D: 전방 출현 Marker3D 여러 개)
├── AirSpawnZone (Node3D: 전방 상공 Marker3D 여러 개)
├── Waypoints (Node3D)
│   ├── InfantryPathA ...
│   └── DronePathA ...
├── DefenseSlots (Node3D)
│   ├── DefenseSlot_01 ...
│   └── DefenseSlot_0N ...
└── Decor (Node3D: scripted primitive meshes)
```

좌표계/전방의 정의는 맵 설계서에 명시하며, 예시 기준 **적 스폰이 전방 Z<0, 플레이어 거점이 Z>0**. 엔진 좌표 선택은 자유지만 모든 출현 영역이 맵의 *전방* 제약을 준수해야 한다. UI에 숨겨진 360도 스폰이 생기지 않게 테스트.

### 3.3 `player.tscn`

```text
Player (CharacterBody3D)
├── CollisionShape3D
├── VisualRoot (Node3D: 생성형 병사 메시/향후 모델 교체)
├── AimPivot (Node3D)
├── CameraRig (Node3D)
│   └── Camera3D
├── WeaponMount (Marker3D)
├── WeaponComponent (Node)
├── DamageableComponent (Node)
├── AnimationPlayer
└── InteractionDetector (Area3D/RayCast3D)
```

이동 입력 벡터와 카메라 회전 입력은 **하나의 추상 입력 서비스**로 받는다. PC에서 키보드·마우스를 사용해도 모바일 터치 로직과 게임 로직을 중복 구현하지 않는다.

### 3.4 `mg_turret.tscn` / `defense_slot.tscn`

```text
DefenseSlot (Area3D)
├── CollisionShape3D     # 상호작용 범위
├── Anchor (Marker3D)    # 지정 설치 좌표
├── VisualIndicator      # 빈 슬롯/사용 중/파손 상태
└── InteractionPrompt    # UI에서 상태와 비용을 조회

MGTurret (Node3D)
├── BaseMesh
├── BarrelPivot
├── BarrelMesh
├── DetectionArea (Area3D)
├── DamageableComponent
├── ShotTimer
└── VFXMount
```

`DefenseSlot.can_install(type, supplies)`가 참이 아닐 때 **설치 버튼 활성화 금지**. 설치 후에도 근접/내부 상태/보급비용에 따라 수리가 가능. 자유 지점 RayCast로 설치 좌표를 선택하는 로직을 만들지 않는다.

## 4. 시스템 상태 전이

### 4.1 전투 세션 상태

`MENU → LOADOUT → PREPARING → SPAWNING → COMBAT → WAVE_CLEAR → REWARD_PENDING → CHECKPOINT_COMMIT → PREPARING(next) → VICTORY/DEFEAT → RESULTS`

**전환 규칙**
- 모든 상태 변경은 `GameSession.transition_to(next_state)` 단일 창구를 경유한다.
- `REWARD_PENDING`에서는 시간/적 AI와 총기 입력을 정지하고 사용자 선택 한 번만 수신한다.
- `CHECKPOINT_COMMIT` 성공 시에만 다음 웨이브 준비로 진행. 저장 실패 시 메시지+재시도 경로 제공.
- `DEFEAT` 처리 시 더 이상 보상 지급/시설 수리 금지, 활성 저장은 무효화.
- 일시중지는 세션 상태가 아닌 오버레이/트리 일시정지로 구현해 승패 전이를 건드리지 않는다.

### 4.2 적군 AI 상태

`SPAWN → ADVANCE → ACQUIRE_TARGET → ATTACK → RECOVER → ADVANCE` / `HIT_REACTION` / `DEAD`.

- **보병:** 맵의 정면 웨이포인트를 따라 거점으로 접근. 플레이어/시설/거점 중 정의된 우선순위로 타깃 선정. 타깃이 없을 때는 거점 이동. 장애물 회피가 필요해질 때 NavigationAgent3D 적용.
- **공격 드론:** 공중 포인트를 따라 전방에서 접근, 목표 발견 시 조준된 게임상 피해 이벤트 발생. 드론을 무장 제조 지침처럼 실제 제어/유도 모델로 구현하지 않는다.
- **보스:** 상위 상태 머신에서 발사 예고/회피 가능 구역/격파 조건 처리. 5/10/15 고정.
- **적응형 위협:** 상한 내 적 조합/생성 빈도만 변화; 정면 출현과 동시 활성 적 상한 유지.

### 4.3 부활과 승패

`revives_remaining=1`로 시작; 체력 0일 때 `revives_remaining>0`이면 즉시 부활, 체력 초기화(설정 비율), 짧은 무적 시간 후 제어 재개. 잔여 0에서 체력 0이면 패배. 거점 체력 0/점령 조건 시 부활과 무관하게 패배. 런 저장에 잔여량을 포함하고 재접속으로 회복되지 않게 한다.

## 5. 핵심 클래스/시그널 API 계약

| 모듈/클래스(예상 경로) | 주요 메서드(계약) | 이벤트/Signal | 참조 |
|---|---|---|---|
| `GameSession` | `start_run(mode,difficulty,loadout)`, `transition_to(state)`, `end_run(result)` | `state_changed`, `run_ended` | 한 런 생명주기 |
| `WaveDirector` | `start_wave(wave_id)`, `spawn_next()`, `resolve_enemy_death(id)`, `finish_wave()` | `wave_started`, `wave_cleared`, `active_count_changed` | 3→15 단계 확장 |
| `PlayerController` | `set_move_input(v)`, `set_look_input(v)`, `set_aiming(b)`, `request_fire()` | `player_died`, `player_revived` | 키보드/터치 공통 |
| `WeaponComponent` | `fire(origin,direction)`, `reload()`, `can_fire()` | `ammo_changed`, `shot_fired`, `hit_confirmed` | MVP 소총, 이후 7계열 |
| `EnemyBase` | `receive_damage(amount,source)`, `set_objective(target)` | `enemy_killed`, `objective_damaged` | 보병/드론 기저 |
| `DefenseSlot` | `can_install()`, `install(defense_id)`, `can_repair()`, `repair()` | `slot_changed` | **지정 슬롯 전용** |
| `EconomyService` | `can_spend(currency,amount)`, `spend()`, `grant_once(tx_id,...)` | `balances_changed` | 두 자원 구분 |
| `RewardService` | `roll_three_cards(seed,inventory)`, `claim_choice(card_id,tx_id)` | `reward_confirmed` | 중복 수령 금지 |
| `SaveManager` | `write_profile(data)`, `save_checkpoint(data)`, `load_active_run()`, `abandon_run()` | `save_finished`, `load_failed` | 스키마 검증/복구 |
| `ThreatDirector` | `choose_variant(wave,difficulty,metrics,seed)` | `variant_selected` | 정면·적 수 상한 유지 |
| `RunStatistics` | `record_shot()`, `record_hit()`, `record_damage()`, `record_kill()` | `stats_changed` | 결과 분석 |
| `PerformanceManager` | `detect_profile()`, `apply_profile()` | `profile_applied` | 실측 우선 |

메서드 명칭은 **설계 인터페이스**다. 실제 GDScript 코드에 생성될 때 인수·타입·signal 정확성을 검증하고, 변경 시 문서와 호출부를 함께 수정해야 한다.

## 6. 게임 데이터 계약

### 6.1 데이터와 코드 구분

전투 수치/가격/스폰 구성은 `data/*.json` 또는 Godot `.tres` 리소스에서 로드. `config_examples/balance_v0.json`, `wave_plan_v0.json`은 **아이디어 초기값**이며 실제 데이터로 복사하기 전 타입/범위 검증이 필요하다.

- 모든 적·시설·무기는 문자열 `id`로 참조: `infantry_basic`, `drone_attack`, `turret_mg`.
- 모드: `trench`, `open_field`; 난이도: `easy`, `normal`, `hard`.
- 금액은 정수>=0; 체력/대미지 유한한 양수; 웨이브 `wave_id`는 1..15.
- 데이터 계약의 가장 중요한 검증: **MVP wave 1~3은 보병·드론만**, 보스는 5,10,15로 **고정**, spawn zone은 `front_*`, 최대 활성 적 한도 유지.

### 6.2 예시 balance 계약

```json
{
  "schema_version": 1,
  "target_fps": 30,
  "active_enemy_cap": 12,
  "difficulty": {
    "easy": {"enemy_hp": 0.8, "enemy_damage": 0.75, "spawn_count": 0.8},
    "normal": {"enemy_hp": 1.0, "enemy_damage": 1.0, "spawn_count": 1.0},
    "hard": {"enemy_hp": 1.2, "enemy_damage": 1.15, "spawn_count": 1.2}
  },
  "starting_resources": {"credits": 0, "supplies": 150},
  "revive_tokens": 1
}
```

위 수치는 **확정 밸런스가 아님**. 스폰 상한 적용 후 웨이브 길이/적 수는 성능 예산에서 적절히 분배한다.

## 7. 저장 설계 — 분리·원자성·복구

### 7.1 파일 위치

- `user://profile.json` : 장비 해금, 업적, 최고 기록, 설정/조작 보정, 언어.
- `user://active_run.json` : 현재 모드/난이도/웨이브 진행, 플레이어/시설/거점 상태, `revives_remaining`, 자원, 임시 강화, 보상 거래ID 및 난수 시드.
- `user://active_run.backup.json` : 이전 정상 스냅샷(백업). 파일 사용과 경로는 런타임 파일 API 검증 후 구현.

### 7.2 JSON 예시

```json
{
  "schema_version": 1,
  "run_id": "local-unique-run-id",
  "mode": "trench",
  "difficulty": "normal",
  "next_wave": 3,
  "checkpoint_phase": "READY_FOR_WAVE",
  "credits": 120,
  "supplies": 80,
  "revives_remaining": 1,
  "player": {"hp": 100, "weapon_id": "rifle_basic", "ammo_in_mag": 24, "reserve_ammo": 90},
  "base": {"hp": 750},
  "defense_slots": [{"slot_id": "trench_slot_01", "defense_id": "turret_mg", "hp": 90}],
  "temporary_upgrades": ["rifle_reload_1"],
  "completed_reward_tx": ["runX-wave1", "runX-wave2"],
  "rng_state": 12345
}
```

**저장/복구 알고리즘**
1. 인메모리 상태를 사본 딕셔너리로 정규화→필수 필드/범위/타입 검증.
2. `active_run.tmp`에 JSON 직렬화→파일 flush/close→다시 읽어 검증(가능한 범위).
3. 정상 이전 파일을 백업한 후 temp를 활성 파일로 교체. `DirAccess.rename_absolute()` 등의 실제 API/리턴값은 엔진 버전에 맞춰 에이전트가 확인.
4. 복구 시 active→backup 순서로 읽고, 둘 다 실패할 때는 '이어하기 불가' 안내 및 안전한 신규 게임 경로 제공. **영구 프로필은 지우지 않는다**.
5. `run_id + wave_id`를 보상 거래ID로 사용하고, 중복 수령을 검사하여 크레딧 및 카드 적용이 **한 번만 발생**하도록 한다.
6. 런 종료(승리/패배/포기) 시 active 런만 정리하고 프로필의 최고기록/해금은 보존한다.

**체크포인트 기준:** '완료한 웨이브의 보상 선택이 반영된 다음 웨이브 준비 상태'를 저장한다. 앱이 중간 전투 도중 꺼진 경우 이미 지급된 마지막 체크포인트의 자원·시설·부활 상태로 복원한다. 게임 종료를 막아 전투 결과를 복제하는 허점을 줄이기 위해 전이와 거래ID를 기록한다.

## 8. 입력·카메라·UI 구현 지침

### 8.1 입력 계층

**Godot InputMap actions:** `move_left/right/forward/back`, `look`, `aim`, `fire`, `reload`, `interact`, `pause`. 실제 모바일 UI는 액션을 직접 전달하되 **터치 ID**를 추적하여 왼쪽 조이스틱과 오른쪽 카메라 스와이프의 이벤트 충돌을 방지한다. UI에 소비된 입력은 불필요하게 카메라로 전달되지 않도록 `mouse_filter`, `_gui_input()`/`_unhandled_input()` 흐름을 시험.

- PC 테스트: WASD/마우스/키보드에 동등한 매핑을 제공. PC 출시는 후속 단계.
- 모바일: 가로 고정, 플랫폼 SafeArea 반영, 스틱 고정/가변 선택은 실제 UX 테스트로 결정.
- 카메라 보간: 넓은 시야 ↔ ADS를 0.1~0.3초 수준의 **제안값**으로 부드럽게 전환. 벽 관통/클리핑 방지용 충돌 검사는 별도.
- 보조 조준: 후보 표적 필터→화면 중심/거리별 우선순위→설정 강도에 따라 카메라/크로스헤어 보정. 사용자 사격 액션이 기본이며 자동 표적은 별도 설정.

### 8.2 HUD 레이어

`Control`은 앵커+컨테이너/안전 영역 기반. 상단 좌측 체력, 상단 중앙 웨이브/거점, 상단 우측 크레딧·보급·탄약, 하단 좌측 스틱, 우측 사격/조준/재장전, 근처 슬롯 시 인터랙트 버튼. 상대 해상도와 aspect ratio 변화 시 버튼이 화면 밖으로 나가지 않도록 한다. 한국어/영어 줄바꿈 테스트.

## 9. 경제·강화·해금 시스템 기술 명세

- `EconomyService`는 두 개의 정수 잔고를 한곳에서 관리. 다른 시스템이 `credits -= n`처럼 임의 변경하지 못하도록 `spend(currency, amount, reason)` 인터페이스 사용.
- `RewardService`는 보상 후보 카드의 `id` 목록, 가중치, 선행 조건, 중복 규칙을 정렬된 입력과 seed를 통해 생성. 매번 3장 중 1장, 가능한 카드가 3장 미만이면 정해진 `fallback_supply`/`fallback_credit` 옵션을 제공.
- `UnlockService`는 영구 프로필을 소유. 웨이브·업적 트리거로 해금하고 `profile`에 저장. 영구 전투력 강화는 기본 범위에서 **제외**.
- 초기 크레딧/보급 밸런스는 `balance_v0.json`. 구매 메뉴는 계열별로 적절한 통화만 사용.
- 웨이브 종료 절차에서 보상 거래ID 검증→크레딧 부여→카드 확정→스냅샷 커밋. 선택 도중 강제 종료 시에도 카드 중복 지급이 발생하지 않게 보상 결산 상태/ID를 관리.

## 10. 적응형 AI와 웨이브 성능

**입력:** 난이도/현재 웨이브, 최근 2웨이브 피해량·명중률·거점 체력, 활성 포탑 수, 보급상태. **출력:** 정해진 구성 프리셋 중 하나 + 스폰 간격 조절. **안전 가드:** 동시 적 10~15 목표(기본 cap 12), 정면 출현, 보스 고정, 웨이브당 상한, 보스 회피 가능 시간 확보.

**성능 실천 지침**
- 드론·탄피·이펙트·발사체는 가능하면 풀링/재사용. 히트스캔 소총은 필요 시 RayCast3D로 최소 생성.
- AI 갱신은 매 프레임 전체 탐색 대신 일정 간격/타겟 캐싱으로 제어. 불필요한 3D 조명, 고가 파티클, 복잡한 물리 충돌 제한.
- 빈번한 `get_nodes_in_group()` 전체 호출, 프레임마다 새 메시/머티리얼 생성 금지.
- 낮음/보통/높음(조건부) 그래픽 프리셋 자동 적용. 자동 탐지로 오판 시 설정 화면에서 변경 가능하게 설계.
- 게임 중 실제 30FPS 달성 여부는 Android 실기기 반복 테스트에서 확인. Mac에서 30FPS는 모바일 성공 증거가 아니다.

## 11. 간이 3D 에셋 생성 표준

- `procedural_assets.gd`에서 `BoxMesh`/`CapsuleMesh`/`CylinderMesh`/`SphereMesh`/`PlaneMesh` 등으로 가상 병사, 드론, 기관총 포탑, 토루/모래주머니를 제작.
- 재질(StandardMaterial3D)·메시 리소스는 캐시/공유하여 인스턴스마다 반복 생성하지 않는다.
- 애니메이션은 최초 이동·조준·사격·피격·사망 5종만. 방어시설 수리는 별도의 간단 UI/타이머로 시작할 수 있다.
- 시각 메시와 물리/AI 히트박스를 분리해 향후 GLB 에셋 교체 시 기존 로직을 보존한다.
- 상황별 효과음·BGM은 무료 라이선스 또는 자체 제작된 파일만 사용. 없는 초기 단계에서는 음향 없이도 주요 전투가 작동해야 한다.

## 12. 테스트 아키텍처

- **유닛/무화면 테스트:** 경제 중복 지출, 보상 단일 적용, 웨이브 상태 전이, 부활 1회, 저장 JSON/스키마 검증. Godot의 headless 옵션으로 실행 가능한 테스트 스크립트 작성.
- **씬 스모크 테스트:** project import, 씬 인스턴싱/Autoload 정상 작동, 3웨이브까지 자동 시나리오(가능한 경우).
- **Android 수동/E2E:** 터치 조이스틱/카메라, 30FPS, 가로 화면, 화면 잠금·앱 종료·이어하기, 볼륨/진동.
- **게임 품질:** 적 스폰 전방 확인, 포탑 슬롯 이외 설치 방지, 두 언어, 오프라인.

CI 없는 개발 초기에는 Antigravity 에이전트가 명령을 실행하고 결과를 `docs/development_log.md`에 기록한다. **테스트를 만들었다는 것과 테스트를 실제 통과했다는 것은 구분**한다.

## 13. Android·스토어·광고 기술 이관

- Android Export Templates 설치, JDK/SDK 경로 확인, Godot Export Preset `Android` 구성. 구체 패키지 버전은 사용 중 Godot 안정 버전의 공식 매뉴얼을 따른다.
- 디버그 APK로 실기기 검증. Google Play는 정식 서명 키와 AAB가 필요하며, AAB 생성 시 Gradle 빌드 템플릿 설정을 확인한다.
- 서명 keystore 및 암호는 저장소/Antigravity 대화/로그에 절대 출력·커밋 금지. 사용자 로컬 비공개 저장을 기본으로 한다.
- 광고 모듈 `RewardedAdProvider`는 `request_ad`, `is_available`, `show`, `completed(reward_token)`, `failed(reason)` 같은 계약만 노출. 실제 SDK 선정은 현재 호환성·정책 검증 후 진행하고, 설치 실패 시 기능 플래그로 비활성.
- iOS로 옮길 때 Mac Xcode 설치, iOS Export Preset, Bundle ID/Team ID, iOS 실기기 확인 필요. PC는 키/마우스·UI 대응 후 확장.

## 14. 에이전트 개발 금지·가드레일

1. 지정 슬롯 이외 시설 배치 로직 생성 금지.
2. 360도 상시 스폰 또는 개활지/참호 실시간 모드 전환 구현 금지.
3. MVP1에 광고 SDK, 온라인 계정, 멀티플레이, 15웨이브 전체를 동시에 도입 금지.
4. `profile.json`을 새 런 시작/패배/포기로 초기화 금지.
5. 검증되지 않은 성능 수치를 **달성**했다고 보고 금지.
6. Android APK/AAB가 생성되지 않았는데 생성했다고 보고 금지.
7. 사용자 승인 없이 유료 서비스 도입/서명키 삭제/파일 전체 리팩터링/스토어 업로드 금지.
8. 실제 군용 무기 제조·운용 노하우 수집 없이 가상 게임 메커닉으로 구현.
