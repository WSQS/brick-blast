# Decision Log

All significant design and architecture decisions, with context and rationale.

Newest and pending at the top.

---

## Pending Decisions

### P002: Upgrade Selection System Details
D014 established the single-level infinite mode direction. All 5 upgrades are implemented (wide paddle, slow ball, extra life, multi-ball, pierce).
Remaining questions: rarity mechanism, how star rating affects choice quantity/quality.
**Status**: Core gameplay complete, see [roadmap.md](roadmap.md) v0.1.

### P003: Level Data Format
- JSON files
- Godot Resource (.tres)
- 2D array / string
**Status**: Deferred. D014 established single-level infinite mode, so multi-level data format is not needed yet. Revisit when level evolution direction is decided (see roadmap.md).

---

## Resolved Decisions

### D014: Upgrade Selection System — Single-Level Infinite Mode (2026-07-14)

**Context**: The upgrade selection system needs a "next level" to be meaningful. Multi-level (P003) is undecided, but upgrade gameplay can be validated within a single level first.

**Decision**: Single-level infinite mode — clear level → choose upgrade → restart same level with upgrade state. No difficulty scaling for now, first validate whether upgrades are fun.

**Initial upgrades** (5):
- Wide paddle (+50%), slow ball (-20%), extra life (+1), multi-ball (+1 ball), pierce (pass through bricks without bouncing, limited to N bricks)

**Trigger**: 3-choice panel appears after each level clear.

**Rationale**: Single-level upgrades bypass the P003 decision dependency, enabling quick validation of Outwit gameplay. Once confirmed fun, decide on multi-level / dynamic level direction.

### D013: Outcome — Star Rating Framework (2026-07-14)

**Context**: Current outcome is binary win/lose. D010 decided on star rating but didn't define criteria.
**Decision**:
- ⭐ Clear level
- ⭐⭐ Clear level + max combo ≥ threshold (initial: 10, adjust after playtest)
- ⭐⭐⭐ Clear level + no lives lost
**Rationale**: Stars = combo performance + perfection. Specific values not locked, adjust after playtest.

---

### D012: Procedures — Ball Sticks to Paddle + Pause, Level Transition Deferred (2026-07-14)

**Context**: Ball auto-launches, player lacks control; no pause; no level transition.
**Decisions**:
1. Ball sticks to paddle (do): ball attaches to paddle and follows it, launch with click/Space. Pairs with combo system — player chooses starting position and launch timing, making combo skill-based rather than random
2. Pause (do, minimal): Esc, on-screen pause button (top-right), or Android back gesture to pause, show Pause + Resume button + Menu button. Back gesture handled via `quit_on_go_back=false` + `go_back_requested` signal
3. Level transition (defer to Phase 2): design when upgrade system starts
**Priority**: Ball sticks + combo system together; pause added alongside; level transition deferred

---

### D011: Resources — Combo System (Option A: Reset on Paddle Hit) (2026-07-14)

**Context**: Current resources are only Lives and Score (with no spending outlet). Objectives decision (D010) requires a combo system to drive star rating.
**Options considered**:
- A. Brick combo: +1 per brick hit, reset on paddle hit
- B. No-miss combo: +1 per brick hit, reset only on ball loss
- C. Consecutive hits: +1 per brick hit, reset on wall/paddle without brick hit
**Decision**: Option A.
**Rules**:
- Ball hits brick → combo += 1
- Ball hits paddle → combo = 0 (catching = end of round)
- Ball hits wall → combo unaffected
- Ball lost → combo = 0
**Rationale**:
- A introduces a Dilemma at the catch moment: "risk one more brick vs safe catch", also resolves Conflict gap
- B too lenient, combo lacks tension
- C too harsh, wall bouncing is normal gameplay, punishment feels arbitrary; Breakout 71 uses C but has many power-ups to compensate
- Higher combo → higher score multiplier → better stars → more upgrade choices

---

### D010: Objectives — Construction + Forbidden Act, Outwit Layered Later (2026-07-14)

**Context**: Game objective is pure Construction (clear bricks), binary win/lose, lacks depth. Need to determine secondary objective direction.
**Options considered**:
- A. Capture (coins / power-up drops)
- B. Outwit (upgrade selection)
- C. Forbidden Act (challenge conditions + star rating)
**Decision**: Do C first, then layer B on top.
**Rationale**:
- C is foundational: turns binary win/lose into tiered rating (stars), providing a "performance metric" for all subsequent systems
- C → B creates a positive loop: higher stars → more/better upgrades → stronger next level → continue pursuing high stars
- Challenge conditions primarily combo-based but not locked, can adjust later (time limit, no lives lost, etc.)
- References Breakout 71's "perform well → more choices" mechanic
**Phases**:
1. Phase 1: Combo system + star rating (Forbidden Act)
2. Phase 2: Inter-level upgrade selection (Outwit), stars affect choice quantity

### D009: Git Commit Convention — Angular Convention (2026-07-14)

**Context**: Commit history needs standardization.
**Decision**: Use Angular commit convention (type(scope): subject).
**Types**: feat / fix / refactor / test / docs / style / chore
**Rationale**: Industry standard, clear structure, easy to track change types.

---

### D008: No Large-Scale Design Docs for Now (2026-07-14)

**Context**: Search results suggested building a full docs/ directory structure (vision.md, pillars.md, core-loop.md, etc.).
**Decision**: Don't create all docs at once, add as needed.
**Rationale**: Avoid premature documentation. Currently have copilot-instructions.md and CHANGELOG.md, add corresponding docs at necessary milestones.

---

### D007: Design Methodology — Playcentric Design + Formal Elements (2026-07-14)

**Context**: As a programmer transitioning to game design, need a systematic design approach.
**Decision**: Adopt Fullerton's *Game Design Workshop* Playcentric Design as the main process, use Formal Elements (Ch 3) framework for periodic design review.
**Rationale**: Playcentric emphasizes "set experience goals → prototype → test → iterate", aligning with the current small-step iterative development approach.
**Status**: Used Formal Elements to analyze the current game, identified three weak points:
1. Resources too sparse (only Lives and Score, Score has no spending outlet)
2. Insufficient Conflict/Dilemmas (player has no decisions to weigh)
3. Procedures lack transitions (ball auto-launches, no sense of control)

---

### D006: Game Entry — Main Menu (2026-07-14)

**Context**: Game lacks a complete loop (opens directly into game, can only Restart after finishing).
**Decision**: Add main menu scene (menu.tscn) as game entry, with Start / Quit buttons.
**Rationale**: Establishes complete loop Menu → Playing → Game Over/Win → Menu/Restart. Prepares for future multi-mode selection.

---

### D005: Testing Strategy — GUT + Pure Functions + Physics Integration (2026-07-14)

**Context**: Need to verify collision logic correctness.
**Decision**:
- Pure function tests: wall/paddle/overlap detection math logic (no physics engine dependency)
- Physics integration tests: force_update_transform + move_and_collide to verify real collision behavior
- Bug fix workflow: write failing test to reproduce bug first, then fix
**Rationale**: Two-layer test coverage — math correctness + physics engine interaction correctness.
**Key findings**: GUT doesn't step PhysicsServer2D; .tscn groups lost after instantiate(); queue_free is deferred.

---

### D004: Collision Math Extracted as Pure Static Methods (2026-07-14)

**Context**: Need to unit test collision logic, but physics engine behavior is hard to drive in GUT test environment.
**Decision**: Extract collision math (wall bounce, brick bounce, paddle angle, circle-rect overlap) as static funcs on ball.gd.
**Rationale**: Pure functions don't depend on physics engine, can be directly unit tested. Physics integration tests separately verify move_and_collide behavior.

---

### D003: Physics Approach — CharacterBody2D + move_and_collide (2026-07-14)

**Context**: Ball originally used Area2D + manual position movement. Area2D collision detection (get_overlapping_areas / intersect_shape) is updated by PhysicsServer2D at physics step start, always one frame behind. High-speed ball tunneled through bricks.
**Options considered**:
1. Area2D + manual collision detection — one frame behind, tunneling
2. RigidBody2D — physics engine driven, bounce angle uncontrollable
3. CharacterBody2D + move_and_collide — CCD, collision returned immediately, velocity controllable
**Decision**: CharacterBody2D.
**Rationale**:
- Breakout bouncing is rule-driven, not physics simulation
- Paddle angle reflection needs precise control (hit position → exit angle)
- Future power-ups (pierce, sticky ball, curve) easier to implement
- move_and_collide has built-in CCD, no tunneling
- Reference project Brick Blast uses custom physics (equivalent approach)

---

### D002: Engine Choice — Godot 4.7 (2026-07-14)

**Context**: Need to choose a game engine, target platforms Windows + Android + Web.
**Decision**: Use Godot 4.7 (Steam version), GL Compatibility renderer.
**Rationale**: Existing Godot experience from godot-little-games; GL Compatibility supports all platforms; free and open source.

---

### D001: Project Positioning — A Real Game Project (2026-07-14)

**Context**: Distinct from godot-little-games (a gameplay lab), create a game with a complete gameplay loop.
**Decision**: Brick-breaker theme, referencing Brick Blast (Kotlin/Android, F-Droid).
**Rationale**: Brick-breaker mechanics are simple and clear, suitable as a first complete game project. Core loop is clear: control paddle → bounce ball → destroy bricks.
