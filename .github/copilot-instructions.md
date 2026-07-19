# brick-blast — Copilot Instructions

## Project Overview

Breakout/brick-breaker game built with Godot 4.7 (GL Compatibility renderer).
Targets Windows + Android + Web.

## Tech Stack

- **Engine**: Godot 4.7 (Steam)
  - Windows: `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`
  - Linux: `~/.local/share/Steam/steamapps/common/Godot Engine/godot.x11.opt.tools.64`
- **Language**: GDScript
- **Testing**: GUT (Godot Unit Test) v9.6.1, installed at `addons/gut/`
- **Resolution**: 480×720 (portrait)

## Roles

| Role | Who | Responsibility |
|------|-----|----------------|
| Developer | Copilot | Implement features, fix bugs, refactor, write tests, sync docs. Proactively find and fix issues without waiting for step-by-step instructions. |
| Reviewer | User | Review code delivered by Copilot. Make decisions on design direction, product choices, and priority trade-offs. |

**Workflow**:
- Copilot owns this project — improving and advancing it is its responsibility. Do what can be done well without waiting for instructions.
- Adopt an **autonomous, batch-delivery** model: Copilot completes multiple changes in a row, runs tests to ensure they pass, and User reviews in batches at their convenience.
- Only seek User's help when a decision is needed (design direction, product trade-offs, external dependencies).
- User reviews code periodically; every piece of code Copilot delivers is its assignment.

## Architecture

| Node | Type | Role |
|------|------|------|
| Ball | `CharacterBody2D` | `move_and_collide()` for CCD, velocity-based bouncing. Emits `hit_paddle` / `lost` signals |
| Brick | `StaticBody2D` | Destructible block, emits `destroyed` signal |
| Paddle | `StaticBody2D` | Mouse/keyboard controlled, angle-based reflection |
| UpgradePanel | `CanvasLayer` | 3-choice upgrade selection UI (layer=10), buttons created dynamically |
| Upgrade | `Resource` (class_name) | Data model for power-up types |
| Menu | `Control` | Title screen with Start / Quit buttons |

Collision is handled by the **physics engine** (`move_and_collide` returns immediate collision info). Pure math helpers (wall bounce, paddle angle) are static methods on `ball.gd` for unit testing.

Game state is managed by a **State enum** on `main.gd`: `READY` (ball stuck to paddle) → `PLAYING` (ball in motion) → `PAUSED` / `ROUND_CLEAR` / `GAME_OVER`. Child nodes query state via `is_playing()` / `is_paused()` methods.

## Critical Godot Gotchas (learned the hard way)

### 1. `.tscn` groups don't survive `instantiate() + add_child()`

`groups = ["brick"]` in a `.tscn` file is **NOT preserved** when the scene is instantiated via `PackedScene.instantiate()` and added to the tree with `add_child()`. You MUST call `add_to_group("brick")` explicitly in code (e.g., `main.gd._spawn_bricks()`).

### 2. GUT tests need `force_update_transform()` before `move_and_collide()`

GUT's test runner does not step `PhysicsServer2D` between test calls. Before calling `move_and_collide()` in a test, call `force_update_transform()` on all physics bodies to sync their positions into the physics space.

### 3. `queue_free()` is deferred

In synchronous tests, `is_instance_valid(node)` returns `true` even after `destroy()` (which calls `queue_free()`). Use GUT's `watch_signals()` + `assert_signal_emitted()` to verify destruction instead.

### 4. GDScript type inference fails on static method returns

`var result := BallScript.calc_wall_bounce(...)` fails with "Cannot infer type". Use explicit types: `var result: Array = ...` or `var bounced: Vector2 = ...`.

### 5. CanvasLayer.visible is independent of child Control.visible

`CanvasLayer.visible = false` hides the entire layer. If you only call `child.show()`, the layer stays hidden. You must set **both** `canvas_layer.visible = true` and `child.visible = true` to show content.

### 6. `.tscn` script binding must use `script = ExtResource()`

Declaring `[ext_resource type="Script" ...]` is not enough — the root node must have `script = ExtResource("id")` to actually bind it. Without this, custom signals and methods won't exist at runtime.

### 7. Android back gesture quits the app by default

`SceneTree.quit_on_go_back` defaults to `true`, causing the Android system back gesture to immediately close the app. Set `application/config/quit_on_go_back=false` in `project.godot`, then connect `get_tree().root.go_back_requested` to handle it (e.g., call `toggle_pause()` in-game, `get_tree().quit()` in menus).

## Running Tests

```powershell
# Linux — run all tests
"~/path/to/godot" --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit 2>&1

# Linux — run a single test file
"~/path/to/godot" --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_physics_collision.gd -gexit 2>&1

# Windows — run all tests
cmd /c '"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless -s addons\gut\gut_cmdln.gd -gdir=res://test/unit -gexit 2>&1'

# Windows — run a single test file
cmd /c '"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless -s addons\gut\gut_cmdln.gd -gtest=res://test/unit/test_physics_collision.gd -gexit 2>&1'

# After changing scripts, clear cache and reimport
Remove-Item .godot -Recurse -Force
cmd /c '"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --import 2>&1'
```

## Running the Game

```powershell
# Headless (no window)
cmd /c '"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --quit-after 300 2>&1'

# With editor
Start-Process "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" -ArgumentList "--editor", "C:\Users\wsqsy\Documents\game\brick-blast\project.godot"
```

## Language Convention

- **All project content must be in English.** This includes code, comments, commit messages, PR titles/bodies, documentation (`docs/`, `README.md`), `CHANGELOG.md`, and any other project files.
- No Chinese or mixed-language content in any committed file.

## Code Conventions

- Use tabs for indentation (Godot default)
- **Formatting**: `gdformat` runs automatically via pre-commit hook (`hooks/pre-commit`). First-time setup: `sh hooks/install.sh`
- Static helper methods prefixed with `calc_` / `bounce_` on `ball.gd`
- Collision layer/mask: ball on layer 2 mask 1 (balls don't collide with each other); paddle/brick/wall on layer 1 mask 1
- Scene scripts go in `script/`, scene files in `scene/`, tests in `test/unit/`
- Update `CHANGELOG.md` for notable changes

## Git Merge Convention

- **Always ask the User before merging any PR.** Never merge without explicit approval.
- **Always use `--merge` (not `--squash`)** when merging PRs.
- **Use `merge` (not `rebase`)** when resolving conflicts with the base branch.
- Preserve the full commit history and the merge commit.
- Example: `gh pr merge <N> --merge --delete-branch`
- Example: `git merge origin/master` (not `git rebase`)

## Git Commit Convention (Angular)

Follow the [Angular commit convention](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit). Format:

```
<type>(<scope>): <short subject in lowercase>

<optional body, wrap at 72 chars>

<optional footer>
```

### Types

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or modifying tests |
| `docs` | Documentation only changes |
| `style` | Formatting, no code change |
| `chore` | Build, tooling, dependencies, CI |

### Rules

- Subject line: lowercase, no period, imperative mood (e.g. "add", not "added")
- Scope: optional, single word for the affected area (e.g. `ball`, `brick`, `menu`, `test`)
- Body: explain **what** and **why**, not how
- Breaking changes: add `BREAKING CHANGE:` in footer
- Use multiple `-m` flags if needed, but keep the structure

### Examples

```
feat(menu): add main menu with start and quit buttons
fix(ball): bounce off brick surface instead of sticking
refactor(physics): migrate ball from area2d to characterbody2d
test(collision): add game-over regression test
docs: update changelog with architecture decision
```

## Bug Fix Workflow

When fixing a bug, follow this process:

1. **Write a failing test that reproduces the bug** before making any code changes. The test should assert the expected (correct) behavior and fail because of the bug.
2. **Fix the code** so the test passes.
3. **Keep the test** — it serves as regression protection. Place it in `test/unit/` alongside existing tests.
4. **Document the root cause** in the test comments and/or `CHANGELOG.md`.

This ensures every bug fix is backed by a test that prevents regression. See the "groups lost on instantiation" fix as a reference example.

## Roadmap (see docs/roadmap.md)

Current: upgrade system with 5 power-ups (wide paddle, slow ball, extra life, multi-ball, pierce), Android portrait lock, on-screen pause button, Android back gesture handling, GitHub Pages deployment for direct APK download
Next: rarity system, star-rating influence on choices, level evolution direction
