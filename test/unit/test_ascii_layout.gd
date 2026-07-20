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


func _polygon_centroid(polygon: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for v in polygon:
		sum += v
	return sum / float(polygon.size())
