# Tactical HUD Gauge Integration, Weapon Shop System & Settings Normalization Plan

> **Goal**: 
> 1. Deduplicate HUD: Clean pre-baked static gauge fills/numbers from the tactical HUD overlay, embedding live animated Godot progress bars & labels directly into the tactical frames.
> 2. Align crosshair, iron sights, muzzle, and bullet trajectory across all aspect ratios (especially mobile landscape).
> 3. Implement full Armory Weapon Shop system with real-world national firearms (K2C1, M4A1, HK416, FN SCAR-H, K14), weapon levels & stat upgrades, credit rewards, and live visual 1st-person viewmodel switching.
> 4. Fix settings dialog: add Master, BGM, and SFX volume sliders, aim sensitivity adjustment, isolate touch inputs when settings are open, and ensure immediate real-time effect.

---

## 1. File Structure & Responsibilities

| File | Responsibility |
|---|---|
| `scripts/autoload/game_settings.gd` | Persistent user settings: aim sensitivity (0.2~2.0), master volume (0~100%), bgm volume (0~100%), sfx volume (0~100%), fullscreen. |
| `scripts/autoload/audio_manager.gd` | Audio playback & live volume control for BGM and SFX voice pools. |
| `scripts/autoload/game_session.gd` | Session progression, credits/combat points management, owned weapon catalog, weapon levels, and equipped weapon state. |
| `data/weapons.json` | Extended catalog of national firearms with stats across Levels 1–5, costs, country of origin, and asset paths. |
| `scripts/combat/weapon_component.gd` | Dynamic weapon configuration loading from `weapons.json` by weapon ID and level. |
| `scripts/ui/fps_viewmodel.gd` | Dynamic screen-center anchoring of iron sights post across arbitrary aspect ratios (16:9, 20:9), texture switching per weapon. |
| `scenes/ui/battle_hud.tscn` | Refactored HUD: live progress bars embedded into tactical frames, removed duplicate floating top-left container, added Shop & Settings dialogs on dedicated top layer (layer 25). |
| `scripts/ui/battle_hud.gd` | Synchronizes live health, durability, ammo, and wave status directly into the tactical frames; manages settings & armory shop dialogs. |
| `scenes/ui/armory_shop.tscn` & `.gd` | Armory shop interface showing national firearms, weapon stats, level upgrade buttons, purchase/equip buttons, and player combat credits. |
| `scenes/app/main_menu.tscn` & `.gd` | Main menu updated with Armory Shop button and enhanced Settings modal (volume + sensitivity). |
| `scripts/ui/touch_controls.gd` | Pauses/disables input handling when settings or shop modal is active, preventing background drag or firing. |

---

## 2. Step-by-Step Implementation

### Task 1: Settings System Overhaul & Touch Isolation
- Update `GameSettings` with audio volume fields, save/load, and getters/setters.
- Update `AudioManager` with live volume adjustment (`set_master_volume`, `set_bgm_volume`, `set_sfx_volume`).
- Refactor `SettingsDialog` into a dedicated CanvasLayer (layer 25) with sliders for Aim Sensitivity, Master Volume, BGM Volume, SFX Volume, and Fullscreen toggle.
- When `SettingsDialog` is open, disable `TouchControls` touch capture so sliders can be dragged freely without camera rotation.
- Write unit test `tests/test_settings.gd` to verify persistence and real-time updates.

### Task 2: Iron Sights, Crosshair & Trajectory Laser-Alignment
- In `scripts/ui/fps_viewmodel.gd`:
  - Calculate `viewport_center = get_viewport_rect().size * 0.5`.
  - Position `rifle_rect` so local sight post `(640, 322)` aligns with `viewport_center` when ADS/ready.
  - Fix responsive scaling on mobile ultra-wide aspect ratios (e.g. 20:9).
- In `scripts/combat/player_controller.gd`:
  - Position muzzle tracer origin so bullet starts from realistic gun barrel forward of camera towards exact raycast target.
- Verify in `test_p11_viewmodel_and_obstacles.gd`.

### Task 3: HUD Deduplication & Live Tactical Gauge Integration
- Process `assets/ui/hud_tactical_overlay.png` to remove static pre-baked numbers ("78%", "100/100", "30/120") and filled gauge pixels, leaving empty tactical cyber frames.
- In `scenes/ui/battle_hud.tscn`:
  - Reposition `PlayerHPBar` and `BaseHPBar` directly inside the top-left tactical frames.
  - Reposition `Ammo` label and bar inside the right-hand tactical ammo slot.
  - Reposition `Wave` and `Score/Credits` in the top-right tactical slot.
  - Remove duplicate floating `TopLeft` container.
- Update `scripts/ui/battle_hud.gd` to smoothly animate and format the embedded gauges.
- Verify `tests/test_p10_ui.gd`.

### Task 4: Real-World National Firearms & Armory Shop System
- Expand `data/weapons.json` with 5 national firearms:
  1. `k2c1_rifle` (대한민국) - Balanced, Lv 1-5
  2. `m4a1_carbine` (미국) - Fast fire rate, Lv 1-5
  3. `hk416_elite` (독일) - High precision & damage, Lv 1-5
  4. `scar_h_battle` (벨기에) - High caliber 7.62mm heavy damage, Lv 1-5
  5. `k14_sniper` (대한민국) - Anti-materiel sniper piercing damage, Lv 1-5
- Generate weapon viewmodel textures and icons matching the tactical style.
- Implement credits reward: +25 for infantry kill, +40 for drone kill, +200 for wave clear.
- Implement `scenes/ui/armory_shop.tscn` & `scripts/ui/armory_shop.gd`:
  - Weapon select list with nationality tags, 3D renders, stat bars (공격력, 연사속도, 장탄수, 재장전).
  - Purchase, Level Upgrade (Lv.1 -> Lv.5), and Equip buttons.
- Connect Armory Shop in `main_menu.tscn` and in `battle_hud.tscn`.
- When equipped, `FPSViewModel` updates texture and `WeaponComponent` loads the corresponding weapon data and level.
- Write unit test `tests/test_weapons_and_shop.gd`.

### Task 5: Full Verification, Web & Android Export, Git Push & Live Deploy
- Run all 12+ test suites to ensure 100% PASS with 0 errors.
- Export Web release to `public/` and `builds/web/`.
- Export Android debug APK to `builds/debug/LAST_TRENCH.apk`.
- Git commit & push (`honglabai <honglabai@gmail.com>`).
- Verify live deployment on Vercel (`https://last-trench.vercel.app`).
