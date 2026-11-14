# 1인칭 고정 참호 방어 (FPS Stationary Defense) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the player camera and controls into a 1st-person stationary trench defense shooter where the character stays anchored in the trench bunker and the reticle/view rotates to target approaching enemies.

**Architecture:** Switch `CameraRig` to 1st-person (`spring_length = 0`), hide player body mesh in 1st-person, disable feet walking during stationary defense mode (`velocity.x = 0, velocity.z = 0`), extend slot interaction range to 5.0m with look-direction targeting, enable full-screen touch aiming, and update HUD and regression tests.

**Tech Stack:** Godot 4 (GDScript), WebGL / HTML5, Android GLES3/Vulkan.

**Spec:** `docs/superpowers/specs/2026-11-14-fps-stationary-defense-design.md`

## Global Constraints
- Must maintain single-threaded WebGL and mobile memory budgets (<8MB VRAM, <2MB bundle).
- Keep fixed defense slot anchors only (no arbitrary turret placement).
- Maintain 3 waves, 12 active enemy limit, 1-time revive guard, base objective defeat.
- All 11 headless tests must pass with 0 errors.

## Review Focus
- 1st-person camera clipping into player head mesh.
- Stationary defense clamping player position while allowing full yaw/pitch look.
- Left and right defense slots targeting based on look direction without physical walking.
- Mobile touch swipe aiming smoothly controlling reticle without jitter.
- PC mouse lock and E key turret interaction functioning from bunker station.

---

### Task 1: 1st-Person Camera & Player Stationary Defense Mode

**Files:**
- Modify: `scripts/combat/third_person_camera.gd:1-67`
- Modify: `scenes/actors/player.tscn:1-68`
- Modify: `scripts/combat/player_controller.gd:1-141`
- Test: `tests/test_p03_player.gd`

**Interfaces:**
- Produces:
  - `ThirdPersonCamera.is_first_person: bool = true`
  - `ThirdPersonCamera.normal_arm_length = 0.0`
  - `PlayerController.stationary_defense_mode: bool = true`
  - Firing raycast originates directly from camera eye position.

- [ ] **Step 1: Update `scripts/combat/third_person_camera.gd` for 1st-person mode**
  - Set default `normal_arm_length = 0.0` and `aim_arm_length = 0.0` when in 1st person.
  - Set `aim_fov = 50.0` and `normal_fov = 75.0`.
  - Ensure `camera.position` aligns with eye height `(0, 0, 0)` on the rig.
  - Keep camera forward vector logic unchanged.

- [ ] **Step 2: Update `scenes/actors/player.tscn` to hide 1st-person body mesh**
  - Set `VisualMesh.visible = false` in 1st-person mode so the capsule and visor mesh do not clip into camera view.
  - Position `CameraRig` at eye level `(0, 1.5, 0)`.

- [ ] **Step 3: Update `scripts/combat/player_controller.gd` for stationary defense**
  - Add `@export var stationary_defense_mode: bool = true`.
  - When `stationary_defense_mode` is active, horizontal velocities `velocity.x` and `velocity.z` remain anchored to 0 (no foot movement).
  - Look input directly rotates `camera_rig` yaw and pitch.
  - Firing raycast starts at `camera_rig.camera.global_position` towards `camera_rig.get_camera_forward()`.

- [ ] **Step 4: Update and verify `tests/test_p03_player.gd`**
  - Verify 1st-person camera arm length (`spring_length == 0.0`) and FOV transition during ADS.
  - Verify stationary anchoring and rotation.
  - Run: `godot --headless -s tests/test_p03_player.gd`
  - Expected: PASS with 0 errors.

- [ ] **Step 5: Commit Task 1**
  ```bash
  git add scenes/actors/player.tscn scripts/combat/third_person_camera.gd scripts/combat/player_controller.gd tests/test_p03_player.gd
  git commit -m "feat(player): implement 1st-person camera and stationary defense mode"
  ```

---

### Task 2: Stationary Bunker Turret Interaction System

**Files:**
- Modify: `scripts/defense/defense_slot.gd:1-80`
- Modify: `scripts/app/game_root.gd:105-197`
- Test: `tests/test_p07_turret.gd`

**Interfaces:**
- Consumes: `trench_map.get_defense_slots()`, `player.camera_rig.get_camera_forward()`
- Produces: Look-direction based turret slot selection within 5.0m range.

- [ ] **Step 1: Update `scripts/defense/defense_slot.gd` interaction radius**
  - Update `@export var interaction_distance: float = 5.0` (covering both left & right slots from the central trench bunker).

- [ ] **Step 2: Update `scripts/app/game_root.gd` targeting logic**
  - In `_physics_process()`, calculate dot product between `player.camera_rig.get_camera_forward()` and vector from player to each defense slot.
  - Assign `active_slot_nearby` to the slot currently being looked at by the player.
  - Update HUD / Touch interaction button label with "좌측 포탑 설치/수리 [E]" or "우측 포탑 설치/수리 [E]".

- [ ] **Step 3: Update and verify `tests/test_p07_turret.gd`**
  - Verify 5.0m interaction range and slot installation.
  - Run: `godot --headless -s tests/test_p07_turret.gd`
  - Expected: PASS with 0 errors.

- [ ] **Step 4: Commit Task 2**
  ```bash
  git add scripts/defense/defense_slot.gd scripts/app/game_root.gd tests/test_p07_turret.gd
  git commit -m "feat(defense): add look-targeted turret interaction for stationary defense"
  ```

---

### Task 3: Touch Controls & Battle HUD 1st-Person Updates

**Files:**
- Modify: `scripts/ui/touch_controls.gd:1-176`
- Modify: `scenes/ui/touch_controls.tscn:1-125`
- Modify: `scenes/ui/battle_hud.tscn:1-350`
- Modify: `scripts/ui/battle_hud.gd:1-187`
- Test: `tests/test_p10_ui.gd`

**Interfaces:**
- Produces:
  - Swipe anywhere on left/center screen to rotate 1st-person reticle.
  - Updated BattleHUD PC help text for stationary 1st-person defense.

- [ ] **Step 1: Update `scripts/ui/touch_controls.gd` for screen-wide touch look**
  - Convert left touch drag to also emit `look_delta_produced` for smooth reticle movement across the screen.
  - Maintain `joystick_base` and `joystick_knob` compatibility for unit tests.

- [ ] **Step 2: Update `scenes/ui/battle_hud.tscn` help label**
  - Set text to: `"[화면 클릭] 조준 모드 | [마우스] 시점 및 과녁 조준 | [좌클릭] 사격 | [우클릭] 견착 조준 | [R] 재장전 | [E] 포탑 설치·수리 | [ESC] 커서 해제"`

- [ ] **Step 3: Run `tests/test_p10_ui.gd` and `tests/test_web_pc_controls.gd`**
  - Run: `godot --headless -s tests/test_p10_ui.gd`
  - Run: `godot --headless -s tests/test_web_pc_controls.gd`
  - Expected: PASS with 0 errors.

- [ ] **Step 4: Commit Task 3**
  ```bash
  git add scripts/ui/touch_controls.gd scenes/ui/touch_controls.tscn scenes/ui/battle_hud.tscn tests/test_p10_ui.gd tests/test_web_pc_controls.gd
  git commit -m "feat(ui): update touch controls and HUD guide for 1st-person aim defense"
  ```

---

### Task 4: Full Regression Testing & Build Re-export

**Files:**
- Modify: `public/*`, `builds/debug/LAST_TRENCH.apk`
- Test: All 11 test suites

- [ ] **Step 1: Execute all 11 test suites**
  - Run: `for t in tests/*.gd; do godot --headless -s "$t" || exit 1; done`
  - Expected: All 11 pass with 0 errors.

- [ ] **Step 2: Re-export Web release build**
  - Run: `godot --headless --path . --export-release "Web" public/index.html`
  - Sync to `builds/web/`: `cp public/* builds/web/`

- [ ] **Step 3: Re-export Android debug build**
  - Run: `godot --headless --path . --export-debug "Android" builds/debug/LAST_TRENCH.apk`

- [ ] **Step 4: Commit and Push to GitHub**
  ```bash
  git add -A
  git commit -m "release: 1st-person stationary trench defense with full web and mobile builds"
  git push origin main
  ```
