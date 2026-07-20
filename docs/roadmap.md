# Roadmap

Version planning and feature roadmap. Organized by version number, with themes as secondary. No time estimates, only confirmed items.

---

## v0.0.1 ✅ (2026-07-14)

**Theme: MVP — Playable Core Loop**

### Gameplay

- Core loop: launch → bounce → break bricks → clear/fail → restart/return to menu
- Combo system (D011): consecutive breaks accumulate combo, reset on paddle hit / ball loss, score scales with combo
- Ball sticks to paddle (D012): ball starts stuck to paddle, launch with Space/click
- Star rating (D013): ⭐ clear · ⭐⭐ combo≥10 · ⭐⭐⭐ no lives lost
- Pause (D012): Esc to pause/resume, custom `paused` variable (not `get_tree().paused`)

### Engineering

- GUT v9.6.1 test framework, 40 unit tests
- CharacterBody2D + move_and_collide (CCD prevents tunneling)
- Full scene loop: main menu → game → end
- CI/CD: GitHub Actions auto-build Windows/Linux/Android/Web, tag triggers draft release, GitHub Pages deploys Web + APK on push to master
- Android back gesture handling (`quit_on_go_back=false`, `go_back_requested` → pause/quit)
- 40/40 tests passing (total now 77, see v0.1)

---

## v0.1.0 ✅ (2026-07-16)

**Theme: Roguelike-style growth loop (second step of D010 plan)**

**Design intent** (D010): star rating → upgrade selection → stronger → continue pursuing high stars = positive loop

### Completed

- ✅ Upgrade selection UI (`scene/upgrade_panel.tscn`)
- ✅ Upgrade data model (`script/upgrade.gd`, 5 types)
- ✅ Clear level → show stars → pop up 3-choice → apply upgrade → restart same level
- ✅ All 5 upgrades implemented: wide paddle, slow ball, extra life, multi-ball, pierce
- ✅ Multi-ball rules: extra balls don't collide with each other; no life cost while balls remain
- ✅ 33 upgrade system unit tests (77 total)

### TODO

- [ ] Star rating affects upgrade choice quantity/quality

### Completed (post v0.1.0)

- ✅ Level system architecture (D016): BrickSpec / BrickBehavior / BrickLayout / LevelData Resource types with strategy-pattern layouts. See [design/level-system.md](design/level-system.md).
- ✅ 5 levels migrated to `.tres` files with per-level specs tables (full_grid, diamond, checker, frame, pillars).
- ✅ Polygon-based brick rendering and collision (rectangles are 4-vertex polygons).
- ✅ Behavior lifecycle hooks infrastructure (`on_hit` / `on_destroy` / `on_spawn`); no concrete behaviors yet.

### Candidate Upgrades (need playtest validation)

| Upgrade | Effect | Type |
|---------|--------|------|
| Multi-ball | Spawn 1 extra ball | Offense |
| Pierce | Ball passes through bricks without bouncing (limit N) | Offense |
| Wide paddle | Paddle width +50% | Defense |
| Slow ball | Ball speed -20% | Defense |
| Extra life | +1 life | Defense |

### Pending Decisions

- **P002**: Specific upgrade pool, rarity, how stars affect choices
- All upgrades are permanent (last entire run), no longer a pending decision
- Level direction: static multi-level vs dynamic levels (see "Level Evolution Direction" below)

### Level Evolution Direction

v0.1 doesn't commit to a single level approach — both paths can serve as upgrade carriers:

| Direction | Description | Upgrade Fit |
|-----------|-------------|-------------|
| **Static multi-level** | Fixed layouts, switch to next level after clearing | Upgrades affect next level's starting state |
| **Dynamic levels** | Bricks change during play (fall/regenerate/advance/split) | Upgrades provide countermeasures, each run is different → choices more meaningful |

The two are not mutually exclusive and can be combined. Need playtest to determine which direction is more fun.

Dynamic level candidate mechanics:

| Mechanic | Effect | Urgency Source |
|----------|--------|----------------|
| Brick descent | Entire grid shifts down one row every N seconds | Reaching bottom = failure |
| Brick regeneration | Destroyed bricks respawn on timer | Must clear quickly |
| Brick advance | New bricks continuously added from top | Never fully clearable, pursue high score |
| Brick split | Destroying one creates two smaller ones | Board becomes increasingly complex |

### Prerequisites

- No hard prerequisites — single-level upgrades (infinite mode) can validate gameplay first

---

## Open Areas

The following directions have not been decided yet, listed for future discussion:

### Multi-Level (P003)

- **Problem**: Currently only one level, upgrade selection needs a "next level" to be meaningful
- **TBD**: Level data format (JSON / .tres / array)
- **Dependency**: Upgrade system (v0.1) progress will expose actual needs

### Special Bricks

- Candidates: hard bricks (multi-hit), explosive bricks (chain reaction), power-up bricks (drop upgrades)
- **Status**: Undecided, wait for upgrade system to settle first

### Audio & Art

- Currently no audio, no art assets (solid color blocks)
- **Status**: Must be done before v1.0, but priority after gameplay

---

## Architecture Debt

Known tech debt, not tied to versions, resolved opportunistically during related feature development:

### main.gd God Object — Partially Addressed

- **Problem**: main.gd handles many responsibilities (brick spawning, ball spawning, input, pause, score, win/lose, HUD)
- **Progress**: State enum replaced 3 independent bools (`game_over`, `paused`, `ball_stuck`); ball decoupled via signals; ball spawning unified to dynamic creation
- **Remaining**: main.gd still owns multiple responsibilities; further decomposition possible
- **Key file**: [script/main.gd](../script/main.gd)

### Ball Responsibility Overreach — ✅ Resolved

- **Problem**: ball.gd's `_physics_process` contained game rules (brick destruction, combo reset, ball acceleration) and used `parent.call()` to invoke main's methods
- **Resolution**: Ball now emits `hit_paddle` and `lost` signals; main connects them. Ball no longer knows about main's game rules.
- **Key file**: [script/ball.gd](../script/ball.gd)

### Inconsistent Wall Collision Mechanism

- **Problem**: Walls use manual bounds checking, bricks/paddle use physics engine
- **Priority**: Low, currently works fine

---

## Pending Decision List

| ID | Topic | Status | Notes |
|----|-------|--------|-------|
| P002 | Upgrade selection details | Pending | Upgrade pool, rarity, star influence |
| P003 | Level data format | Pending | JSON / .tres / array, depends on multi-level decision |
| - | Special bricks | Undiscussed | Wait for upgrade system to settle |
| - | Audio & art | Undiscussed | Must before v1.0 |
