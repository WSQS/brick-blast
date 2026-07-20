extends GutTest
## Tests for the migrated level data — verifies all 5 .tres files load and
## produce the expected number of bricks.

const MainScene: PackedScene = preload("res://scene/main.tscn")


func _count_bricks(layout_rows: Array) -> int:
	var count := 0
	for row in layout_rows:
		for ch in row:
			if ch != " ":
				count += 1
	return count


func test_main_has_5_levels_configured() -> void:
	var main := MainScene.instantiate()
	add_child_autofree(main)
	assert_eq(main.levels.size(), 5, "Main scene should have 5 levels wired")


func test_full_grid_produces_40_bricks() -> void:
	var main := MainScene.instantiate()
	add_child_autofree(main)
	main.current_level = 0
	main._spawn_bricks()
	# Full Grid = 8 cols × 5 rows = 40 bricks
	assert_eq(main.bricks_left, 40, "Full Grid should have 40 bricks")


func test_diamond_produces_18_bricks() -> void:
	# Diamond layout: 2 + 4 + 6 + 4 + 2 = 18
	var main := MainScene.instantiate()
	add_child_autofree(main)
	main.current_level = 1
	main._spawn_bricks()
	assert_eq(main.bricks_left, 18, "Diamond should have 18 bricks (2+4+6+4+2)")


func test_checker_produces_40_bricks() -> void:
	# Checker: 8 rows × 5 cols but alternating — every cell filled in this variant
	# rows: "RORORORO" (8), "OROROROR" (8), ... 5 × 8 = 40
	var main := MainScene.instantiate()
	add_child_autofree(main)
	main.current_level = 2
	main._spawn_bricks()
	assert_eq(main.bricks_left, 40, "Checker should have 40 bricks")


func test_frame_produces_24_bricks() -> void:
	# Frame: row 0 = 8, row 4 = 8, rows 1-3 = 2 each → 8 + 2 + 2 + 2 + 8 = 22
	var main := MainScene.instantiate()
	add_child_autofree(main)
	main.current_level = 3
	main._spawn_bricks()
	assert_eq(main.bricks_left, 22, "Frame should have 22 bricks")


func test_pillars_produces_15_bricks() -> void:
	# Pillars: 3 bricks per row × 5 rows = 15
	var main := MainScene.instantiate()
	add_child_autofree(main)
	main.current_level = 4
	main._spawn_bricks()
	assert_eq(main.bricks_left, 15, "Pillars should have 15 bricks")


func test_advance_level_loops() -> void:
	var main := MainScene.instantiate()
	add_child_autofree(main)
	main.current_level = 4  # last level
	main._advance_level()
	assert_eq(main.current_level, 0, "Advancing past last level should loop to 0")


func test_advance_level_normal() -> void:
	var main := MainScene.instantiate()
	add_child_autofree(main)
	main.current_level = 0
	main._advance_level()
	assert_eq(main.current_level, 1, "Advancing level 0 → 1")


func test_hud_shows_level_number() -> void:
	var main := MainScene.instantiate()
	add_child_autofree(main)
	main.current_level = 2  # 3rd level
	main._update_hud()
	# Lv.%d uses 1-based display, so level index 2 = "Lv.3"
	assert_string_contains(main.score_label.text, "Lv.3", "HUD should show level number (1-based)")
