extends GutTest
## Tests for brick.gd configure() and on_hit() after the polygon refactor.

const BrickSpec = preload("res://script/brick_spec.gd")
const BrickScene: PackedScene = preload("res://scene/brick.tscn")


func _make_spec(color: Color, hp: int = 1) -> BrickSpec:
	var spec := BrickSpec.new()
	spec.color = color
	spec.hp = hp
	return spec


func _make_rect_polygon(w: float = 52, h: float = 22) -> PackedVector2Array:
	return PackedVector2Array(
		[
			Vector2(-w / 2.0, -h / 2.0),
			Vector2(w / 2.0, -h / 2.0),
			Vector2(w / 2.0, h / 2.0),
			Vector2(-w / 2.0, h / 2.0)
		]
	)


func test_configure_sets_color() -> void:
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	var spec := _make_spec(Color.BLUE)
	brick.configure(spec, _make_rect_polygon())
	assert_eq(brick.color, Color.BLUE, "configure() should set color from spec")


func test_configure_sets_hp() -> void:
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	var spec := _make_spec(Color.RED, 3)
	brick.configure(spec, _make_rect_polygon())
	assert_eq(brick.hp, 3, "configure() should set hp from spec")


func test_configure_creates_polygon2d_node() -> void:
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	brick.configure(_make_spec(Color.RED), _make_rect_polygon())
	assert_true(brick.has_node("Polygon2D"), "configure() should create a Polygon2D node")


func test_configure_replaces_collision_shape() -> void:
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	brick.configure(_make_spec(Color.RED), _make_rect_polygon())
	var col: CollisionShape2D = brick.get_node("CollisionShape2D")
	assert_not_null(col.shape, "Collision shape should be set")
	assert_true(
		col.shape is ConvexPolygonShape2D,
		"Collision shape should be ConvexPolygonShape2D after configure()"
	)


func test_on_hit_decrements_hp() -> void:
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	brick.configure(_make_spec(Color.RED, 2), _make_rect_polygon())
	brick.on_hit(null, null)
	assert_eq(brick.hp, 1, "on_hit should decrement hp from 2 to 1")
	assert_false(brick._destroyed, "Brick should not be destroyed at hp=1")


func test_on_hit_destroys_at_zero_hp() -> void:
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	brick.configure(_make_spec(Color.RED, 1), _make_rect_polygon())
	watch_signals(brick)
	brick.on_hit(null, null)
	assert_signal_emitted(brick, "destroyed", "destroyed signal should fire when hp reaches 0")
	assert_true(brick._destroyed, "Brick should be marked destroyed")


func test_apply_damage_partial_does_not_destroy() -> void:
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	brick.configure(_make_spec(Color.RED, 5), _make_rect_polygon())
	var destroyed: bool = brick.apply_damage(3, null, null)
	assert_false(destroyed, "Partial damage should not destroy")
	assert_eq(brick.hp, 2, "hp 5 - 3 = 2")
	assert_false(brick._destroyed, "Brick should still be alive")


func test_apply_damage_exact_destroys() -> void:
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	brick.configure(_make_spec(Color.RED, 3), _make_rect_polygon())
	watch_signals(brick)
	var destroyed: bool = brick.apply_damage(3, null, null)
	assert_true(destroyed, "Exact damage should destroy")
	assert_true(brick.hp <= 0, "hp should be <= 0")
	assert_signal_emitted(brick, "destroyed", "destroyed should fire on exact damage")


func test_apply_damage_overkill_destroys() -> void:
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	brick.configure(_make_spec(Color.RED, 2), _make_rect_polygon())
	watch_signals(brick)
	var destroyed: bool = brick.apply_damage(5, null, null)
	assert_true(destroyed, "Overkill damage should destroy")
	assert_signal_emitted(brick, "destroyed", "destroyed should fire on overkill")


func test_on_hit_is_noop_when_already_destroyed() -> void:
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	brick.configure(_make_spec(Color.RED, 1), _make_rect_polygon())
	brick.destroy()
	# Second hit should not emit destroyed again
	watch_signals(brick)
	brick.on_hit(null, null)
	assert_signal_not_emitted(brick, "destroyed", "Already-destroyed brick should not re-emit")


func test_destroy_is_idempotent() -> void:
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	watch_signals(brick)
	brick.destroy()
	brick.destroy()
	assert_signal_emit_count(brick, "destroyed", 1, "destroy() should only emit once")


func test_configure_with_empty_polygon_keeps_default_colorrect() -> void:
	# When polygon is empty (e.g. scene-placed brick not yet configured),
	# the default ColorRect + RectangleShape2D should remain.
	var brick := BrickScene.instantiate()
	add_child_autofree(brick)
	# Don't call configure — brick should still work with defaults
	assert_true(brick.has_node("ColorRect"), "Default ColorRect should exist")
	assert_true(brick.has_node("CollisionShape2D"), "Default CollisionShape2D should exist")
