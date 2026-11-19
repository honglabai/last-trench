# LAST TRENCH 캐릭터 모션 및 절차적 애니메이션 개선 계획서

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Godot 4 및 GDScript 기반으로 LAST TRENCH의 모든 캐릭터(보병, 무인기, 4족 보행로봇, 궤도/차량형 지휘병기)의 움직임을 단순 이동에서 관절 기반 스켈레탈 및 물리 절차적 애니메이션(가속·감속·회전 보간, 지면 접촉, 반동, 추락)으로 전면 개선하고 모바일 30FPS 및 15개 동시 적군 환경에서 고성능을 보장한다.

**Architecture:** 기존 `EnemyBase` 및 전투 로직(HP, 피격, 발사체 등)을 100% 보존하면서, 모델·이동 로직·행동 AI·애니메이션을 분리한다. 신규 공통 `CharacterMovementController`를 통해 관성/가속/회전을 보간하고, 유형별 특화 애니메이터(보병 `HumanoidSkeletalAnimator` + `AnimationTree`, 드론 `DroneFlightAnimator`, 4족로봇 `QuadrupedProceduralAnimator`, 차량형 `VehicleTrackAnimator`)를 연결한다.

**Tech Stack:** Godot 4.7.2 (GDScript), Skeleton3D, AnimationPlayer, AnimationTree, RayCast3D, Transform3D Basis Slerp, VisibleOnScreenNotifier3D, Visible LOD System.

**Spec:** 사용자 제공 개발 가이드 PDF (`LAST TRENCH / DEVELOPMENT GUIDE 캐릭터 모션 구현`)

---

## Global Constraints

- **전투 로직 무결성:** 기존 `EnemyBase`, `DamageableComponent`, `EnemyProjectile`, `WaveDirector`의 데미지 판정, 신호(`bullet_fired`, `rocket_fired`, `enemy_died` 등), 레이어(`collision_layer=4`, `mask=1`)를 100% 유지한다.
- **아키텍처 분리:** 이동 물리(Movement Controller), 행동 결정(AI), 시각 렌더링/관절 애니메이션(Animator)을 명확히 분리한다.
- **순수 Godot 4 API & 무과금:** 외부 유료 에셋이나 유료 API에 일체 의존하지 않고, Godot 4 내장 Skeleton3D/AnimationTree 및 GDScript 수학/물리 보간만으로 구현한다.
- **성능 목표:** 동시 활성 적 15개 기준 물리 및 애니메이션 프레임 타임 33.3ms 이내 (Android 모바일 30FPS 이상 고정) 달성 및 거리별 LOD 적용.
- **발 미끄러짐 방지 (Foot Sliding Removal):** 캐릭터의 지면 이동 속도(velocity)와 보행 애니메이션 재생 속도(playback speed)를 1:1 선형 연동한다.

---

## Review Focus

1. **테스트 불변성 보존:** 기존 `test_p05_infantry.gd`, `test_p06_drone.gd`, `test_enemy_weapons_and_projectiles.gd`, `test_wave_expansion_15.gd`가 단 하나의 수정 없이 100% 통과해야 한다.
2. **발 미끄러짐(Foot-sliding) 방지:** 보병 및 4족 로봇이 정지하거나 저속 접근할 때 발이 헛돌지 않고 이동 속도와 발걸음 주기가 정확히 일치하는지 확인.
3. **지형 접촉 및 참호 경사면 반응:** 4족 로봇 및 차량형 로봇이 울퉁불퉁한 참호 둔덕에서도 발이 허공에 뜨지 않고 Raycast3D를 통해 지면 법선(normal)에 맞추어 차체 및 발 높이가 보정되는지 확인.
4. **드론 비행의 유기적 물리감:** 단순 회전이 아닌 가속 시 전방 숙임(Pitch), 선회 시 날개 기울임(Roll), 공중 호버링 시 미세 섭동(Noise), 사망 시 제어 상실 후 나선형 회전 추락(Crash physics)이 매끄럽게 연결되는지 확인.
5. **모바일 CPU 과부하 방지 (LOD):** 15개 적군이 동시 활동 시 50m 이상 원거리 적군은 관절 세부 연산을 건너뛰고 기본 트랜스폼 보간만 수행하여 30FPS를 안정적으로 유지하는지 확인.

---

## File Structure

### 신규 생성 파일
- `scripts/combat/character_movement_controller.gd`: 공통 이동 컨트롤러 (가속, 감속, 부드러운 회전 보간, 관성, 속도 벡터 계산)
- `scripts/animation/humanoid_skeletal_animator.gd`: 보병 Skeleton3D 및 절차적/스켈레탈 관절 제어기 (대기, 걷기, 달리기, 조준, 사격 반동, 재장전, 피격 비틀거림, 사망 쓰러짐)
- `scripts/animation/drone_flight_animator.gd`: 무인기 절차적 비행 애니메이터 (로터 고속 회전, 피치/롤 뱅킹 기울기, 호버링 부유, 추락 물리)
- `scripts/animation/quadruped_procedural_animator.gd`: 4족 보행 로봇 4다리 트롯 보행 주기, 관절 굴절, 지면 Raycast 높이 보정
- `scripts/animation/vehicle_track_animator.gd`: 중장갑 궤도/차량형 로봇 차체-포탑 독립 회전, 궤도 회전, 지형 경사 기울기, 사격 충격 반동
- `scripts/animation/character_lod_controller.gd`: 거리 기반 애니메이션 틱레이트 조절 및 가시성 컬링
- `tests/test_character_movement_controller.gd`: 공통 이동 컨트롤러 단위 테스트
- `tests/test_character_animation_systems.gd`: 4개 유형 캐릭터 애니메이션 및 상태 전환 테스트
- `tests/test_character_motion_benchmark.gd`: 동시 15개 적군 성능 및 모바일 30FPS 검증 테스트

### 수정 대상 파일
- `scripts/ai/enemy_base.gd`: CharacterMovementController 연동 인터페이스 및 LOD 지원
- `scripts/ai/infantry_ai.gd`: HumanoidSkeletalAnimator 연동 및 보행 속도-보폭 연동
- `scripts/ai/rpg_infantry_ai.gd`: 견착 RPG 자세 및 사격 반동 연동
- `scripts/ai/drone_ai.gd`: DroneFlightAnimator 연동 및 3D 뱅킹/추락 물리 연동
- `scripts/ai/boss_drone_commander_ai.gd`: 대형 지휘 드론 비행 애니메이션 연동
- `scripts/ai/combat_robot_ai.gd`: QuadrupedProceduralAnimator 연동 및 4족 지면 접촉
- `scripts/ai/boss_armored_robot_ai.gd`: 중장갑 4족 로봇 거대 관절 애니메이션 연동
- `scripts/ai/boss_final_assault_ai.gd`: VehicleTrackAnimator 연동 및 포탑-차체 독립 회전/반동 연동
- `scenes/actors/enemy_infantry.tscn`: 관절 계통 Node3D / Skeleton3D 구조 추가
- `scenes/actors/enemy_rpg.tscn`: RPG 전용 견착 관절 구조 추가
- `scenes/actors/enemy_drone.tscn`: 4개 로터 블레이드 Node3D 계층 추가
- `scenes/actors/boss_drone_commander.tscn`: 다중 로터 및 안테나 관절 추가
- `scenes/actors/enemy_robot.tscn`: 4개 다리(엉덩이, 무릎, 발목) 관절 및 레이캐스트 추가
- `scenes/actors/boss_armored_robot.tscn`: 대형 4족 관절 계층 추가
- `scenes/actors/boss_final_assault.tscn`: 차체 베이스, 독립 포탑, 배터리 포신 구조 추가

---

## Task Decomposition

### Task 1: 공통 Character Movement Controller 개발
- [ ] `scripts/combat/character_movement_controller.gd` 생성
  - 부드러운 가속(acceleration) 및 감속(deceleration) 보간 로직 구현
  - 목표 지향 부드러운 선회(Slerp / `lerp_angle`) 구현
  - 실제 수평 이동 속도 및 이동 방향 벡터 실시간 계산
  - 장애물 및 지면 접촉 감지
- [ ] `tests/test_character_movement_controller.gd` 작성
  - 정지 상태에서 목표 속도까지의 가속 곡선 검증
  - 급격한 방향 전환 시 부드러운 각속도 회전 보간 검증
  - 감속 및 정지 제동 거리 검증
- [ ] Godot 헤드리스로 테스트 실행하여 통과 확인

### Task 2: 보병 Skeleton3D 및 관절 기반 애니메이션 시스템 구현
- [ ] `scripts/animation/humanoid_skeletal_animator.gd` 생성
  - 8대 관절 상태(골반, 척추/상체, 머리, 좌/우 대퇴부, 좌/우 무릎, 좌/우 어깨, 좌/우 팔꿈치, 총기) 프로시저럴 계층 제어
  - 상태 머신 연동: `IDLE`(호흡 미세 흔들림), `WALK`(좌우 교차 보행), `RUN`(전방 숙임 및 빠른 보폭), `AIM`(견착 고정), `FIRE`(상체 뒤로 튕기는 반동), `RELOAD`(탄창 교체 제스처), `HIT`(피격 방향 비틀거림), `DIE`(무릎 꺾이며 전도)
  - 이동 속도 연동 보폭 스케일링: `stride_frequency = current_speed * 3.2`로 발 미끄러짐 원천 차단
- [ ] `scenes/actors/enemy_infantry.tscn` 및 `scenes/actors/enemy_rpg.tscn` 업데이트
  - 기존 스프라이트 외형의 장점을 살리면서 관절별 회전 및 포지션 오프셋이 적용되도록 `Skeleton3D` 및 노드 계층 확장
- [ ] `scripts/ai/infantry_ai.gd` 및 `scripts/ai/rpg_infantry_ai.gd`에 애니메이터 연동
- [ ] `tests/test_p05_infantry.gd` 회귀 테스트 실행하여 기존 100% 동작 보존 확인

### Task 3: 무인기(드론) 절차적 비행 애니메이션 구현
- [ ] `scripts/animation/drone_flight_animator.gd` 생성
  - 4개 로터 고속 회전 (상승/고속 시 RPM 가속)
  - 속도 및 가속도에 따른 전방 기울기(Pitch, 최대 25도) 연동
  - 좌우 선회 각속도에 따른 롤(Roll, 최대 30도) 뱅킹 연동
  - 정지 호버링 시 Perlin/Sin 3D 미세 부유 흔들림
  - 피격 시 기체 흔들림 및 사망 시 추락(엔진 정지, 나선 회전, 중력 낙하, 지면 충돌 폭발)
- [ ] `scenes/actors/enemy_drone.tscn` 및 `scenes/actors/boss_drone_commander.tscn` 로터 노드 보강
- [ ] `scripts/ai/drone_ai.gd` 및 `boss_drone_commander_ai.gd` 연동
- [ ] `tests/test_p06_drone.gd` 회귀 테스트 실행하여 고도 유지 및 이동 로직 확인

### Task 4: 4족 보행 전투로봇 관절 및 지형 반응 구현
- [ ] `scripts/animation/quadruped_procedural_animator.gd` 생성
  - 4개 다리(전좌/전우/후좌/후우)의 대각선 트롯(Trot) 보행 주기 구현
  - 각 다리의 힙-무릎-발목 2관절 역기구학(IK) 보행 호(arc) 계산
  - 지면 접촉 RayCast3D를 통한 경사면 발 높이 보정
  - 걸음걸이에 맞춘 차체(몸체)의 상하 피칭 및 롤링 무게감 연출
- [ ] `scenes/actors/enemy_robot.tscn` 및 `boss_armored_robot.tscn`에 4족 관절 노드 구조 구성
- [ ] `scripts/ai/combat_robot_ai.gd` 및 `boss_armored_robot_ai.gd` 연동
- [ ] 회귀 테스트 및 발 접촉 검증

### Task 5: 차량형/궤도형 지휘병기 독립 포탑 및 궤도 회전 구현
- [ ] `scripts/animation/vehicle_track_animator.gd` 생성
  - 차체(Chassis)와 포탑(Turret)의 독립 회전 (차체는 전진 방향, 포탑은 플레이어 추적)
  - 이동 속도에 비례한 궤도/바퀴 회전 애니메이션
  - 지형 경사면에 맞춘 차체 피치/롤 정렬
  - 대구경 포탑 사격 시 강력한 포신 후퇴 및 차체 서스펜션 반동(Kickback & Suspension recovery)
- [ ] `scenes/actors/boss_final_assault.tscn` 차체/포탑/포신 노드 분리 및 계층화
- [ ] `scripts/ai/boss_final_assault_ai.gd` 연동

### Task 6: 애니메이션 타이밍 무작위화 및 개체별 다양성 부여
- [ ] 적 인스턴스 생성 시 고유 난수 시드(`randf() * TAU`) 기반 애니메이션 시작 위상 분산
- [ ] 보폭 주기(±8%) 및 차체 높이 미세 변량 부여로 군집 이동 시 "로봇 복제인간" 현상 제거
- [ ] 사망 쓰러짐 방향 및 피격 반응 각도 무작위 보간

### Task 7: 거리별 LOD 시스템 및 모바일 성능 최적화
- [ ] `scripts/animation/character_lod_controller.gd` 생성
  - 카메라와의 거리에 따른 3단계 품질 자동 조절:
    - LOD 0 (< 25m): 60 FPS 전체 관절 및 지면 레이캐스트 갱신
    - LOD 1 (25m ~ 50m): 30 FPS 격프레임 갱신 및 간이 IK
    - LOD 2 (> 50m): 기본 트랜스폼 및 위치 보간만 수행 (미세 관절 생략)
  - `VisibleOnScreenNotifier3D`를 통해 화면 밖 적군의 불필요한 관절 계산 완전 절전(Sleep)
- [ ] 모든 적군 베이스에 LOD 컨트롤러 부착

### Task 8: 종합 검증 및 모바일 30FPS 성능 벤치마크
- [ ] `tests/test_character_animation_systems.gd` 작성 및 실행
  - 4종 캐릭터의 모든 상태별 애니메이션 매개변수 및 관절 회전 각도 유효성 검증
- [ ] `tests/test_character_motion_benchmark.gd` 작성 및 실행
  - 동시 15개 적군(보병 6, 드론 4, 4족로봇 3, 지휘병기 2) 소환 후 600 물리 프레임 스트레스 테스트
  - 평균 프레임 소요 시간 측정 (목표: < 33.3ms, Android 30FPS 이상 고정 검증)
- [ ] 전체 기존 회귀 테스트 재실행:
  - `test_p05_infantry.gd`
  - `test_p06_drone.gd`
  - `test_enemy_weapons_and_projectiles.gd`
  - `test_wave_expansion_15.gd`
  - `test_p10_ui.gd`
- [ ] Web 빌드 패키징 및 최종 검증
