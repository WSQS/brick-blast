extends GutTest
## Tests for AsciiLayout — converts ASCII rows into polygon brick instances.

const BrickSpec = preload("res://script/brick_spec.gd")
const AsciiLayout = preload("res://script/ascii_layout.gd")


func _make_spec(color: Color) -> BrickSpec:
	var spec := BrickSpec.new()
	spec.color = color
	return spec


func _make_layout(rows: Array[String]) -> AsciiLayout:
	var layout := AsciiLayout.new()
	layout.rows = rows
	layout.cell_size = Vector2(10, 10)
	layout.grid_origin = Vector2(0, 0)
	layout.gap = 0.0
	return layout


func test_full_grid_produces_one_brick_per_char() -> void:
	var layout := _make_layout(["RR", "RR"])
	var specs := {"R": _make_spec(Color.RED)}
	var result: Array = layout.build(specs)
	assert_eq(result.size(), 4, "2x2 grid of R should produce 4 bricks")


func test_spaces_are_skipped() -> void:
	var layout := _make_layout(["R R", " R "])
	var specs := {"R": _make_spec(Color.RED)}
	var result: Array = layout.build(specs)
	assert_eq(result.size(), 3, "3 non-space chars should produce 3 bricks")


func test_unknown_chars_are_skipped() -> void:
	var layout := _make_layout(["RXR"])
	var specs := {"R": _make_spec(Color.RED)}
	var result: Array = layout.build(specs)
	assert_eq(result.size(), 2, "Only R chars should produce bricks; X has no spec")


func test_each_entry_has_polygon_and_spec() -> void:
	var layout := _make_layout(["R"])
	var red := _make_spec(Color.RED)
	var result: Array = layout.build({"R": red})
	assert_eq(result.size(), 1, "Single R should produce one entry")
	var entry: Dictionary = result[0]
	assert_true(entry.has("polygon"), "Entry must have polygon key")
	assert_true(entry.has("spec"), "Entry must have spec key")
	assert_same(entry["spec"], red, "Entry spec should be the same BrickSpec instance")


func test_polygon_is_rectangle_with_four_vertices() -> void:
	var layout := _make_layout(["R"])
	layout.cell_size = Vector2(10, 10)
	layout.grid_origin = Vector2(0, 0)
	layout.gap = 0.0
	var result: Array = layout.build({"R": _make_spec(Color.RED)})
	var polygon: PackedVector2Array = result[0]["polygon"]
	assert_eq(polygon.size(), 4, "Rectangle polygon should have 4 vertices")


func test_polygon_position_matches_grid_coordinates() -> void:
	# cell at col=2, row=1, cell_size 10x10, gap 0, origin (0,0)
	# expected center: x = 2*10 + 5 = 25, y = 1*10 + 5 = 15
	var layout := _make_layout(["   ", "  R"])
	var result: Array = layout.build({"R": _make_spec(Color.RED)})
	var polygon: PackedVector2Array = result[0]["polygon"]
	var center := _polygon_centroid(polygon)
	assert_eq(center, Vector2(25, 15), "Polygon center should match grid cell center")


func test_empty_rows_produce_nothing() -> void:
	var layout := _make_layout([])
	var result: Array = layout.build({"R": _make_spec(Color.RED)})
	assert_eq(result.size(), 0, "Empty rows should produce zero bricks")


func test_gap_affects_spacing() -> void:
	# With gap=5, cell_size=10, col=0 center should be at x = 0 + 5 = 5
	# col=1 center should be at x = 1*(10+5) + 5 = 20
	var layout := _make_layout(["RR"])
	layout.cell_size = Vector2(10, 10)
	layout.gap = 5.0
	var result: Array = layout.build({"R": _make_spec(Color.RED)})
	var p0: PackedVector2Array = result[0]["polygon"]
	var p1: PackedVector2Array = result[1]["polygon"]
	assert_eq(_polygon_centroid(p0).x, 5.0, "First cell center x = 5")
	assert_eq(_polygon_centroid(p1).x, 20.0, "Second cell center x = 20 (gap applied)")


func test_full_grid_bounding_box_reveals_right_gap() -> void:
	var layout := AsciiLayout.new()
	layout.rows = ["RRRRRRRR", "OOOOOOOO", "GGGGGGGG", "BBBBBBBB", "PPPPPPPP"]
	layout.cell_size = Vector2(52, 22)
	layout.grid_origin = Vector2(0, 80)
	layout.gap = 4.0
	# target_width not set → no centering, left-aligned
	var specs := {
		"R": _make_spec(Color.RED),
		"O": _make_spec(Color.ORANGE),
		"G": _make_spec(Color.GREEN),
		"B": _make_spec(Color.BLUE),
		"P": _make_spec(Color.PURPLE),
	}
	var result: Array = layout.build(specs)

	var min_x := INF
	var max_x := -INF
	for entry: Dictionary in result:
		var poly: PackedVector2Array = entry["polygon"]
		for v: Vector2 in poly:
			min_x = minf(min_x, v.x)
			max_x = maxf(max_x, v.x)

	var expected_width := 8 * 52.0 + 7 * 4.0  # 444
	assert_almost_eq(max_x - min_x, expected_width, 0.01, "8 columns: total width = 444")
	assert_eq(min_x, 0.0, "Grid starts at x=0 (left-aligned)")
	assert_almost_eq(max_x, 444.0, 0.01, "Grid ends at x=444")
	# Viewport is 480 wide → 36px empty gap on the right
	assert_lt(max_x, 480.0, "Bricks do NOT span full viewport width (480)")
	assert_almost_eq(480.0 - max_x, 36.0, 0.01, "Right gap = 36px")


func test_target_width_centers_grid() -> void:
	var layout := AsciiLayout.new()
	layout.rows = ["RRRRRRRR", "OOOOOOOO", "GGGGGGGG", "BBBBBBBB", "PPPPPPPP"]
	layout.cell_size = Vector2(52, 22)
	layout.grid_origin = Vector2(0, 80)
	layout.gap = 4.0
	layout.target_width = 480.0
	var specs := {
		"R": _make_spec(Color.RED),
		"O": _make_spec(Color.ORANGE),
		"G": _make_spec(Color.GREEN),
		"B": _make_spec(Color.BLUE),
		"P": _make_spec(Color.PURPLE),
	}
	var result: Array = layout.build(specs)

	var min_x := INF
	var max_x := -INF
	for entry: Dictionary in result:
		var poly: PackedVector2Array = entry["polygon"]
		for v: Vector2 in poly:
			min_x = minf(min_x, v.x)
			max_x = maxf(max_x, v.x)

	var expected_width := 8 * 52.0 + 7 * 4.0  # 444
	var expected_padding := (480.0 - expected_width) / 2.0  # 18
	assert_almost_eq(max_x - min_x, expected_width, 0.01, "Grid width still 444")
	assert_almost_eq(min_x, expected_padding, 0.01, "Left padding = 18px")
	assert_almost_eq(max_x, 480.0 - expected_padding, 0.01, "Right padding = 18px")
	assert_almost_eq(min_x, 480.0 - max_x, 0.01, "Symmetric: left padding == right padding")


func _polygon_centroid(polygon: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for v in polygon:
		sum += v
	return sum / float(polygon.size())
