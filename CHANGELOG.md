# Changelog

All notable changes to brick-blast will be documented in this file.

## [Unreleased]

### Changed

- HUD refactored to use container-based adaptive layout (MarginContainer, VBoxContainer, HBoxContainer, CenterContainer) instead of manual offset positioning
- `@onready` paths in `main.gd` switched to `%` unique name references for HUD nodes

### Added

- On-screen pause button (top-right "II") for touch devices (Android)
- `toggle_pause()` method on `main.gd` — shared by Esc input, pause button, and back gesture
- Android back gesture handling: `application/config/quit_on_go_back=false` in `project.godot`, `go_back_requested` signal connected to `toggle_pause()` in `main.gd` and `get_tree().quit()` in `menu.gd`
- Android portrait orientation lock (`window/handheld/orientation=1`)
- Fixed viewport stretch settings (`window/stretch/mode="viewport"`, `window/stretch/aspect="keep"`) to prevent adaptive scaling on Android
- CI workflow `deploy-pages.yml`: exports Web + Android, deploys to GitHub Pages for direct APK download
- CI workflow `ci-build.yml`: exports signed Android APK on push/PR as artifact
- Copilot instruction: require explicit user approval before merging any PR

### Changed

- Pause logic refactored from inline `_input()` code back to `toggle_pause()` method, shared by `_input()` (Esc), `_on_pause_pressed()` (button tap), and `_on_go_back_requested()` (Android back gesture)

## [0.1.0] - 2026-07-16

### Added

- State machine: `enum State { READY, PLAYING, PAUSED, ROUND_CLEAR, GAME_OVER }` replaces three independent bools (`game_over`, `paused`, `ball_stuck`), eliminating impossible state combinations
- `is_playing()` / `is_paused()` query methods on `main.gd` for child nodes to check game state
- Ball signals `hit_paddle(ball)` and `lost(ball)` — ball no longer calls parent methods directly
- `LOSE_MARGIN` constant on `ball.gd` (replaces magic number `50`)
- `BUTTON_MIN_SIZE` constant on `upgrade_panel.gd`
- Type annotation on `upgrade_selected` signal (`upgrade: Upgrade`)

### Changed

- Ball `_speed` private variable → `speed` public variable; removed `get_speed()` / `set_speed()` methods
- Ball no longer uses `parent.call()` to invoke main's methods — emits signals instead, main connects them
- Upgrade panel buttons now created dynamically in `_create_buttons()` instead of hardcoded in `.tscn`
- Ball spawning unified: all balls (including the first) are dynamically created via `_spawn_ball()`, no scene-placed Ball node
- `_start_next_round()` simplified: clears all balls uniformly, no longer special-cases the first ball

### Upgrade selection system (D014)

- Upgrade selection system: post-clear 3-choice upgrade panel, restart same level after selection
- 5 upgrades fully implemented: wide paddle (+50%), slow ball (-20%), extra life (+1), multi-ball, pierce (pass through 3 bricks)
- Multi-ball rules: all balls have equal status; no life cost while any ball remains, life lost only when all balls are gone
- Extra balls follow paddle while stuck to it
- New scene `scene/upgrade_panel.tscn`: upgrade selection UI
- New scripts `script/upgrade.gd` (upgrade data model), `script/upgrade_panel.gd` (UI controller)
- 77 unit tests (including 33 upgrade system tests)

### Changed (code review refactoring)

- State transitions centralized: all `state = State.X` assignments moved to event handlers (`_ready`, `_input`, `_on_brick_destroyed`, `_on_ball_lost`, `_start_next_round`); behavior functions no longer mutate state
- `_toggle_pause()` inlined into `_input()` (later refactored back to `toggle_pause()` in Unreleased)
- Redundant `_update_hud()` calls removed from `_ready`, `_start_next_round`, `_on_ball_lost`
- Unnecessary `is_instance_valid()` checks removed (balls array only contains valid nodes)
- Ball speed unified: `ball_speed` variable on `main.gd` is the single source of truth; `_spawn_ball` uses it directly; SLOW_BALL upgrade and paddle-hit acceleration (`*= 1.03`) both update `ball_speed` then sync all balls
- Ball speed acceleration (`*= 1.03`) moved from `ball.gd._physics_process` to `main.gd._on_paddle_hit`
- Type annotations added: `_on_upgrade_selected(upgrade: Upgrade)`, `_apply_upgrade(id: Upgrade.Type)`, brick loop `Node` type, `show_choices(choices: Array[Upgrade])`
- `gdformat` pre-commit hook added (`hooks/pre-commit`, `hooks/install.sh`)

### Fixed (code review refactoring)

- Losing last ball didn't spawn a new ball: `_on_ball_lost` now calls `_spawn_ball()` before `_reset_round()` when lives remain
- Brick `destroyed` signal could fire twice: `queue_free()` is deferred, so two balls hitting the same brick in one frame both called `destroy()`. Added `_destroyed` guard flag to make `destroy()` idempotent

### Fixed (upgrade system)

- Upgrade panel invisible: CanvasLayer.visible must be toggled together with overlay.visible
- Ball not stopped on win: `_win()` now immediately sets `state = ROUND_CLEAR` + `velocity=ZERO`
- Losing a ball cost a life during multi-ball: changed to no life cost while balls remain
- Main ball loss froze all balls during multi-ball: `_on_ball_lost` no longer resets state, extra balls continue moving
- Extra balls didn't follow paddle while stuck: `_process` now syncs extra ball positions
- Clicking during upgrade panel launched ball: `_input` now checks `state == ROUND_CLEAR` guard
- Pierce not reset on paddle hit: `_on_paddle_hit` now restores `pierce_count`
- Paddle widening only updated CollisionShape: now syncs ColorRect size and position too

## [0.0.1] - 2026-07-14

### Added

- Combo system (D011): consecutive brick breaks accumulate combo, score scales with combo
- Ball sticks to paddle (D012): ball starts stuck to paddle, launch with Space / click
- Star rating (D013): post-clear 1-3 stars based on combo and lives
- Pause feature (D012): Esc to pause/resume, shows PAUSED indicator
- Main menu scene (`scene/menu.tscn`): title + Start + Quit buttons
- Game entry changed to menu (`run/main_scene = res://scene/menu.tscn`)
- Menu button shown after game over to return to main menu
- Complete game loop: Menu → Playing → Game Over / Win → Menu / Restart

### Changed

- **Paddle group mechanism removed**: paddle is a unique node, no group lookup needed.
  ball.gd collision detection changed from `collider.is_in_group("paddle")` to `collider == parent.paddle`.
  Removed paddle.gd `_ready()` group registration and paddle.tscn `groups` declaration.
- **main.gd refactor**: `_reset_ball()` renamed to `_reset_round()`; `_compute_stars()` returns int instead of String;
  extracted `_win`/`_lose` duplicate code to `_end_game(text)`; magic number `40.0` extracted to `BALL_OFFSET` constant.
- **paddle.gd**: mouse tracking now only active when mouse actually moves (prevents paddle jumping to mouse position after keyboard release).
- **brick.gd**: removed unused `get_rect()` method.
- **ball.gd**: removed dead code `circle_overlaps_rect` (migrated to test_collision.gd); added null guard to `_on_ball_lost` call.

### Fixed

- **Paddle still movable after pause**: original approach used `get_tree().paused` + `PROCESS_MODE_ALWAYS`,
  `process_mode` inheritance caused paddle/ball to still run during pause.
  Changed to custom `paused` variable, each node explicitly checks `parent.paused`,
  no longer relies on engine global pause mechanism.
- **Ball launchable during pause**: `_input` missing `not paused` guard, pressing Space during pause would set `ball_stuck = false`.

### Architecture Decision: CharacterBody2D (2026-07-14)

**Problem**: Ball used `Area2D`, moving via manual `position += velocity` in `_physics_process`.
`Area2D` collision detection (`get_overlapping_areas()` / `intersect_shape()`) is updated by `PhysicsServer2D`
at the start of the physics step, always one frame behind. Result: high-speed ball movement caused collision detection to fail completely (tunneling through bricks).

**Decision**: Changed Ball from `Area2D` to `CharacterBody2D`.

| Component | Old Type | New Type | Reason |
|-----------|----------|----------|--------|
| Ball | Area2D | CharacterBody2D | `move_and_collide()` has built-in CCD, collision results returned immediately |
| Brick | Area2D | StaticBody2D | Static collision body for `move_and_collide` detection |
| Paddle | Area2D | StaticBody2D (or AnimatableBody2D) | Same as above |

**Why CharacterBody2D over RigidBody2D**:
- Breakout bouncing is rule-driven, not physics simulation
- Paddle angle reflection needs precise control (hit position → exit angle)
- Future power-ups (pierce, sticky ball, curve) are easier on CharacterBody2D
- Reference project Brick Blast also uses custom physics (equivalent to CharacterBody2D approach)

### Added

- GUT (Godot Unit Test) v9.6.1 test framework
- 17 pure-function collision math unit tests (wall/brick/paddle/overlap detection)
- Physics collision integration tests (based on `wait_physics_frames` driving the real physics engine)

### Fixed

- **Ball doesn't bounce off bricks (critical bug)**: `groups = ["brick"]` declared in `.tscn` is **not preserved** after `PackedScene.instantiate() + add_child()`. Collision check `collider.is_in_group("brick")` always returned false, collision handling code was skipped, ball stuck on brick surface.
  - Fix: `main.gd._spawn_bricks()` explicitly calls `brick.add_to_group("brick")`
  - Fix: `paddle.gd._ready()` explicitly calls `add_to_group("paddle")`
- ball.gd: fixed `_check_collisions` collision detection lagging one frame causing tunneling
- ball.gd: fixed `area_entered` edge trigger missing collisions at high speed
- ball.gd: added position correction (push ball out of object surface after collision)
- main.gd: fixed `COLORS[row % COLORS.size()]` expression corruption
- main.gdc: fixed `brick_scene` @export assignment order (script must precede export properties)
- brick.gd: fixed `var s :=` type inference failure
