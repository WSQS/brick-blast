# Level System Design

Status: **Implemented** (2026-07-20, PR #37) — shipped in `feat/level-data-architecture`.

This document specifies the architecture for level data, brick specs, and brick behaviors. It is the authoritative design reference; `decisions.md` (D016) records the decision to adopt it.

---

## Goals

- Support multiple levels with different brick layouts (ASCII grid and arbitrary polygons).
- Allow per-level brick definitions (color, hp, special behaviors) without cross-level coupling.
- Be extensible to future encodings (path layout, procedural generation, etc.) without modifying consumer code.
- Keep the runtime (spawn, collision) decoupled from the level encoding format.

---

## Architecture Overview

```
LevelData (Resource)
├── name: String
├── encoding: BrickLayout         ← strategy object (subclasses below)
│   ├── AsciiLayout               ← parses ASCII rows to polygons
│   └── PolygonLayout             ← reads pre-defined polygons
└── specs: Dictionary             ← char/key -> BrickSpec (per-level)

BrickSpec (Resource)
├── color: Color
├── hp: int
└── behaviors: Array[BrickBehavior]

BrickBehavior (Resource, abstract)
└── on_hit / on_destroy / on_spawn hooks
    ├── ExplodeBehavior (future)
    └── DropUpgradeBehavior (future)
```

**Data flow**:

```
LevelData.build_bricks()
  → encoding.build(specs)          ← polymorphic dispatch
  → Array[Dictionary]              ← each entry: {polygon, spec}
  → main._spawn_bricks() consumes this uniform list
```

`main.gd` does not know whether the level is ASCII or polygon. It only consumes `[{polygon, spec}, ...]`.

---

## Core Types

### BrickSpec

A brick **type** (color + stats + behaviors). Does **not** contain position — position is decided by the layout.

```gdscript
# script/brick_spec.gd
class_name BrickSpec
extends Resource

@export var color: Color = Color.WHITE
@export var hp: int = 1
@export var behaviors: Array[BrickBehavior] = []
```

**Reuse policy**: each LevelData declares its own `specs` table. No cross-level sharing. Rationale: levels are independent design units; sharing introduces debug friction (override chains) and evolution rigidity (a shared spec change ripples to all levels). See decision D in the decision log below.

### BrickBehavior

Hook into brick lifecycle events. Subclassed per behavior type.

```gdscript
# script/brick_behavior.gd
class_name BrickBehavior
extends Resource

## Called when the brick is hit but not yet destroyed.
## Returns true to consume the hit (skip remaining behaviors).
func on_hit(brick: Node, ball: Node, context: Node) -> bool:
    return false

## Called when the brick is destroyed (hp reached 0).
func on_destroy(brick: Node, context: Node) -> void:
    pass

## Called once after the brick is spawned into the tree.
func on_spawn(brick: Node, context: Node) -> void:
    pass
```

`context` is `main.gd` (duck-typed). It provides query/spawn methods behaviors may need:

- `get_bricks_in_radius(center: Vector2, radius: float) -> Array[Node]`
- `spawn_upgrade_token(position: Vector2) -> void`
- (others added as needed)

No `BrickContext` abstract class is introduced (YAGNI). If multiple context implementations emerge, promote later.

### BrickLayout (abstract strategy)

```gdscript
# script/brick_layout.gd
class_name BrickLayout
extends Resource

## Parse this layout's data into a uniform list of brick instances.
## Each entry: {"polygon": PackedVector2Array, "spec": BrickSpec}
func build(specs: Dictionary) -> Array[Dictionary]:
    assert(false, "BrickLayout.build() must be overridden")
    return []
```

The base asserts on direct call to catch missing overrides at development time.

The base holds **no data fields** — each subclass owns its own data. This is pure strategy, not template method.

### AsciiLayout

```gdscript
# script/ascii_layout.gd
class_name AsciiLayout
extends BrickLayout

@export var rows: Array[String] = []
@export var cell_size: Vector2 = Vector2(52, 22)
@export var grid_origin: Vector2 = Vector2(0, 80)
@export var gap: float = 4.0

func build(specs: Dictionary) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for row_idx in rows.size():
        var row: String = rows[row_idx]
        for col_idx in row.length():
            var ch: String = row[col_idx]
            if not specs.has(ch):
                continue
            var polygon := _cell_polygon(col_idx, row_idx)
            result.append({"polygon": polygon, "spec": specs[ch]})
    return result

func _cell_polygon(col: int, row: int) -> PackedVector2Array:
    # Axis-aligned rectangle (4 vertices). A rectangle is a polygon specialization.
    var x: float = grid_origin.x + col * (cell_size.x + gap) + cell_size.x / 2.0
    var y: float = grid_origin.y + row * (cell_size.y + gap) + cell_size.y / 2.0
    var hx: float = cell_size.x / 2.0
    var hy: float = cell_size.y / 2.0
    return PackedVector2Array([
        Vector2(x - hx, y - hy),
        Vector2(x + hx, y - hy),
        Vector2(x + hx, y + hy),
        Vector2(x - hx, y + hy),
    ])
```

**Design note**: ASCII is treated as a **layout strategy that emits rectangles**, not as the native representation. The output is the same `[{polygon, spec}]` shape that PolygonLayout emits. This unification is what lets `main.gd` stay encoding-agnostic.

### PolygonLayout

```gdscript
# script/polygon_layout.gd
class_name PolygonLayout
extends BrickLayout

## Each entry: {"polygon": PackedVector2Array, "spec_key": String}
@export var bricks: Array[Dictionary] = []

func build(specs: Dictionary) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for entry in bricks:
        var key: String = entry.get("spec_key", "")
        if not specs.has(key):
            push_error("PolygonLayout: unknown spec_key '%s'" % key)
            continue
        result.append({
            "polygon": entry["polygon"],
            "spec": specs[key],
        })
    return result
```

`spec_key` may be any string (multi-char allowed). ASCII keys are limited to single chars by the grid nature; polygon keys are not constrained.

### LevelData

```gdscript
# script/level_data.gd
class_name LevelData
extends Resource

@export var name: String = ""
@export var encoding: BrickLayout
@export var specs: Dictionary = {}  # String -> BrickSpec

func build_bricks() -> Array[Dictionary]:
    if encoding == null:
        push_error("LevelData '%s' has no encoding" % name)
        return []
    return encoding.build(specs)
```

---

## Brick Node Changes

### Scene structure (`scene/brick.tscn`)

Before:
- `ColorRect` (visual) + `CollisionShape2D` with `RectangleShape2D` (collision)

After:
- `Polygon2D` (visual) — replaced ColorRect
- `CollisionShape2D` with `ConvexPolygonShape2D` (collision) — shape built at runtime from the polygon

All bricks use the polygon path regardless of shape. Rectangles (4 axis-aligned vertices) are not special-cased; the physics engine handles them efficiently anyway (decision B1).

### Script (`script/brick.gd`)

```gdscript
extends StaticBody2D

signal destroyed

var spec: BrickSpec
var polygon: PackedVector2Array
var hp: int
var _destroyed: bool = false

func configure(s: BrickSpec, poly: PackedVector2Array) -> void:
    spec = s
    polygon = poly
    hp = s.hp
    _rebuild_visual()
    _rebuild_collision()

## Trigger on_spawn lifecycle hooks. Call after configure() and add_child().
func trigger_on_spawn(context: Node) -> void:
    if spec:
        for b in spec.behaviors:
            b.on_spawn(self, context)

func on_hit(ball: Node, context: Node) -> void:
    if _destroyed:
        return
    hp -= 1
    if spec:
        for b in spec.behaviors:
            if b.on_hit(self, ball, context):
                break  # behavior consumed the hit; skip remaining
    if hp <= 0:
        if spec:
            for b in spec.behaviors:
                b.on_destroy(self, context)
        destroy()

func destroy() -> void:
    if _destroyed:
        return
    _destroyed = true
    destroyed.emit()
    queue_free()

func _rebuild_visual() -> void:
    var poly_node: Polygon2D = $Polygon2D
    poly_node.polygon = polygon
    poly_node.color = spec.color

func _rebuild_collision() -> void:
    var shape := ConvexPolygonShape2D.new()
    shape.points = polygon  # PackedVector2Array → points
    var col: CollisionShape2D = $CollisionShape2D
    col.shape = shape
```

**Note on position**: bricks keep their existing positioning convention (node `position` is the polygon's origin, polygon vertices are relative to it). `AsciiLayout._cell_polygon` returns absolute coordinates; `_spawn_bricks` will subtract the polygon centroid to get the node position and re-center the polygon. This keeps the existing brick `position`-relative coordinate system.

### Ball collision (`script/ball.gd`)

```gdscript
# Before:
collider.destroy()

# After:
collider.on_hit(self, get_parent())
```

The ball no longer calls `destroy()` directly; it calls `on_hit()`, which decrements hp, triggers behaviors, and destroys when hp reaches 0. For a 1-hp brick this is equivalent to the old behavior.

---

## Main Scene Integration

### `script/main.gd`

Replaces the current `LEVELS`/`LEVEL_CHAR_MAP` constants with:

```gdscript
@export var levels: Array[LevelData] = []
var current_level: int = 0

func _current_level() -> LevelData:
    return levels[current_level]

func _spawn_bricks() -> void:
    for child in bricks.get_children():
        child.queue_free()
    bricks_left = 0
    var pending: Array[Dictionary] = _current_level().build_bricks()
    for entry in pending:
        var poly: PackedVector2Array = entry["polygon"]
        var spec: BrickSpec = entry["spec"]
        var brick: StaticBody2D = brick_scene.instantiate()
        var node_pos: Vector2 = _polygon_centroid(poly)
        var local_poly: PackedVector2Array = _recenter_polygon(poly, node_pos)
        brick.position = node_pos
        brick.configure(spec, local_poly)
        brick.add_to_group("brick")
        brick.destroyed.connect(_on_brick_destroyed)
        bricks.add_child(brick)
        bricks_left += 1

func _advance_level() -> void:
    current_level = (current_level + 1) % levels.size()
```

The `_start_next_round()` method calls `_advance_level()` instead of mutating a flat `current_level` expression, so the progression rule is in one place (future-proof for non-looping progressions).

### `scene/main.tscn`

The `levels` array is wired via the scene file (not via `const` / `preload`):

```tres
[ext_resource type="Resource" path="res://levels/full_grid.tres" id="level_01"]
[ext_resource type="Resource" path="res://levels/diamond.tres" id="level_02"]
...

[node name="Main" type="Node2D"]
script = ExtResource("main_script")
levels = [ExtResource("level_01"), ExtResource("level_02"), ...]
```

**Rationale**: Godot's dependency tracking and export pipeline are driven by `ext_resource` declarations in `.tscn` files. Wiring via scene properties ensures all level `.tres` files are included when the game is exported, and the dependency graph is visible in the editor.

---

## Level File Format

Each level is a `.tres` file under `res://levels/`. Example (ASCII):

```tres
[gd_resource type="Resource" script_class="LevelData" load_steps=4]

[ext_resource type="Script" path="res://script/level_data.gd" id="1"]
[ext_resource type="Script" path="res://script/ascii_layout.gd" id="2"]
[ext_resource type="Script" path="res://script/brick_spec.gd" id="3"]

[sub_resource type="Resource" id="red_spec"]
script = ExtResource("3")
color = Color(0.913, 0.27, 0.376, 1)
hp = 1

[sub_resource type="Resource" id="layout"]
script = ExtResource("2")
rows = ["   RR   ",
        "  RRRR  ",
        " RRRRRR ",
        "  RRRR  ",
        "   PP   "]

[resource]
script = ExtResource("1")
name = "Diamond"
encoding = SubResource("layout")
specs = {
    "R": SubResource("red_spec")
}
```

Migration plan: the existing 5 levels (`full_grid`, `diamond`, `checker`, `frame`, `pillars`) from the abandoned `feat/multi-level` branch are re-encoded in this format.

---

## Decision Log

### A. Strategy pattern for encodings (vs enum + switch)

**Decision**: `BrickLayout` is an abstract base class; each encoding is a subclass.

**Rationale**: Adding a new encoding (e.g., `PathLayout`, `HexGridLayout`) is a purely additive change — a new file, no edits to existing layouts or to `main.gd`. An enum + switch would require touching every switch site when a new encoding is added.

### B. Unified polygon representation (vs rectangle fast-path)

**Decision**: All bricks (including axis-aligned rectangles from ASCII) are represented as polygons. Rendering uses `Polygon2D`; collision uses `ConvexPolygonShape2D`.

**Rationale**: Single code path, no rectangle special case to maintain. Godot's physics engine handles convex polygons efficiently; the performance difference is negligible for this game's brick count. A rectangle is mathematically a polygon with 4 vertices — we treat it as such.

### C. Resource (`.tres`) as the level carrier

**Decision**: `LevelData`, `BrickSpec`, `BrickLayout`, `BrickBehavior` all extend `Resource`. Levels are `.tres` files.

**Rationale**: Future-proof for Inspector editing, runtime construction (procedural generation), and serialization. A `RefCounted` starting point would force a migration when these needs arrive; `Resource` has the same in-memory ergonomics with no downside.

### D. Per-level `specs` table (no cross-level reuse)

**Decision**: Each `LevelData` declares its own `specs` dictionary. Shared brick types are duplicated per level, not referenced from a global table.

**Rationale**:
- Levels are independent design units; brick specs are part of a level's identity.
- Cross-level sharing introduces debug friction (override chains) and evolution rigidity (a spec change ripples to all levels).
- The apparent redundancy (5 levels each declaring "red 1-hp brick") is **controlled redundancy** — each file is self-contained, readable, and modifiable in isolation.
- If reuse ever becomes painful, a `BASE_SPECS` fallback mechanism can be added later as a purely additive feature (LevelData empty specs → fall back to global table). Starting without it is the safe direction.

### E. Behavior strategy (D2 in earlier discussion)

**Decision**: Brick behaviors are `BrickBehavior` Resources composed in a `behaviors` array on `BrickSpec`.

**Rationale**: Open-closed principle. Adding a behavior (Explode, DropUpgrade, Regenerate) is a new Resource file; existing behaviors and `brick.gd` are not modified. Behaviors are composable — a brick can be both explosive and drop an upgrade by listing both in the array. Each behavior's parameters (radius, drop chance) are per-instance, not global constants.

### F. `context` parameter is `main.gd` (duck-typed)

**Decision**: Behavior hooks take `context: Node`. The actual argument is `main.gd`. No `BrickContext` abstract class.

**Rationale**: YAGNI. There is only one context implementation today. Introducing an abstract class now would be speculative. If multiple contexts emerge (e.g., boss-arena vs normal-play), the parameter type can be tightened then.

### G. Level list wired via scene property (not `const` / `preload`)

**Decision**: `@export var levels: Array[LevelData]` on `main.gd`, populated via `main.tscn` ext_resource references.

**Rationale**: Godot's dependency tracking and export pipeline key off `.tscn` ext_resource declarations. Wiring levels through the scene guarantees the export includes all level files and makes the dependency graph editor-visible. `const` arrays of `preload` calls work but bypass this mechanism in some edge cases.

### H. Abstract base asserts (not runtime error)

**Decision**: `BrickLayout.build()` calls `assert(false, "must be overridden")` instead of returning an empty array with `push_error`.

**Rationale**: Forgetting to override `build()` is a development-time error. Asserts fail fast at first invocation; `push_error` + empty return would silently produce a broken level. Headless test runs and editor play both catch the assert immediately.

### I. Return type is `Array[Dictionary]` (not a `BrickInstance` Resource)

**Decision**: `build()` returns `Array[Dictionary]`, each entry `{"polygon": PackedVector2Array, "spec": BrickSpec}`.

**Rationale**: YAGNI. A dedicated `BrickInstance` Resource would add type safety (no key typos) but also adds a class and instantiation overhead for a transient value. If Dictionary-key typos become a real source of bugs, promote to `BrickInstance` later — the change is localized to `build()` implementations and `_spawn_bricks`.

---

## Non-Goals

The following are explicitly out of scope for this design:

- **Cross-level BrickSpec reuse** (see decision D).
- **Level metadata** beyond `name` (difficulty, background, win condition) — added when a concrete need appears.
- **Dynamic level generation** — the design supports it (LevelData can be constructed in code) but no generator is included.
- **Level editor UI** — polygon levels are currently authored by hand or by code; a visual editor is a separate future project.
- **Special behavior implementations** (Explode, DropUpgrade) — the infrastructure ships first; concrete behaviors follow as demand appears.

---

## Migration Plan

The implementation was split into steps, each ending with all tests green and the game bootable headless. All steps shipped in PR #37 (`feat/level-data-architecture`).

1. **Step 1**: Add `BrickSpec` + `BrickBehavior` base classes. No consumers yet.
2. **Step 2**: Add `BrickLayout` base + `AsciiLayout` + `PolygonLayout`. Unit tests for both.
3. **Step 3**: Add `LevelData`. Unit test for `build_bricks()`.
4. **Step 4**: Refactor `brick.gd` and `brick.tscn` to the polygon model. Update `ball.gd` to call `on_hit()`. Migrate affected existing tests.
5. **Step 5**: Create 5 level `.tres` files. Rewrite `main.gd` to consume `LevelData`. Wire `main.tscn`. Add level data integrity tests.
6. **Step 6**: Sync documentation (`CHANGELOG.md`, `decisions.md` D016, `roadmap.md`, `copilot-instructions.md`).

Post-merge review added: `trigger_on_spawn(context)` on `brick.gd`, invoked by `_spawn_bricks()` after `configure()` — completes the `on_spawn` lifecycle wiring.

Future PRs (not yet started):
- First concrete `BrickBehavior` (e.g., ExplodeBehavior) when a design need appears.
- Multi-hp brick gameplay validation.

---

## Open Questions

None blocking implementation. Potential future refinements:

- Whether to introduce a `BrickContext` abstraction if a second context type emerges.
- Whether to add a `BASE_SPECS` fallback if per-level duplication becomes painful in practice.
- Whether to promote `Array[Dictionary]` to a typed `BrickInstance` Resource if key typos cause bugs.
