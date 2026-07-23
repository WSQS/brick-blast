extends GutTest
## Tests for PolygonLayout — passes pre-defined polygons through to brick instances.

const BrickSpec = preload("res://script/brick_spec.gd")
const PolygonLayout = preload("res://script/polygon_layout.gd")


func _make_spec(color: Color) -> BrickSpec:
	var spec := BrickSpec.new()
	spec.color = color
	return spec


func _make_triangle() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(5, 10)])


func _make_quad() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])


func test_each_brick_entry_produces_output_entry() -> void:
	var layout := PolygonLayout.new()
	layout.bricks = [
		{"polygon": _make_triangle(), "spec_key": "T"},
		{"polygon": _make_quad(), "spec_key": "Q"},
	]
	var specs := {"T": _make_spec(Color.RED), "Q": _make_spec(Color.BLUE)}
	var result: Array = layout.build(specs)
	assert_eq(result.size(), 2, "Two brick entries should produce two output entries")


func test_output_preserves_polygon_and_spec() -> void:
	var layout := PolygonLayout.new()
	var tri := _make_triangle()
	layout.bricks = [{"polygon": tri, "spec_key": "T"}]
	var red := _make_spec(Color.RED)
	var result: Array = layout.build({"T": red})
	assert_eq(result.size(), 1)
	var entry: Dictionary = result[0]
	assert_eq(entry["polygon"], tri, "Polygon should be passed through unchanged")
	assert_same(entry["spec"], red, "Spec should be the looked-up BrickSpec instance")


func test_unknown_spec_key_is_skipped() -> void:
	var layout := PolygonLayout.new()
	layout.bricks = [
		{"polygon": _make_triangle(), "spec_key": "T"},
		{"polygon": _make_quad(), "spec_key": "MISSING"},
	]
	var result: Array = layout.build({"T": _make_spec(Color.RED)})
	# Asserting the push_error also marks it as expected (not a test failure)
	assert_push_error("unknown spec_key 'MISSING'")
	assert_eq(result.size(), 1, "Entry with unknown spec_key should be skipped")


func test_empty_bricks_produces_empty_output() -> void:
	var layout := PolygonLayout.new()
	layout.bricks = []
	var result: Array = layout.build({"T": _make_spec(Color.RED)})
	assert_eq(result.size(), 0, "Empty bricks should produce empty output")


func test_multi_char_spec_key_is_supported() -> void:
	# Unlike AsciiLayout (single-char grid cells), PolygonLayout keys may be any string.
	var layout := PolygonLayout.new()
	layout.bricks = [{"polygon": _make_quad(), "spec_key": "explosive_hard"}]
	var spec := _make_spec(Color.YELLOW)
	var result: Array = layout.build({"explosive_hard": spec})
	assert_eq(result.size(), 1, "Multi-char spec_key should resolve correctly")
	assert_same(result[0]["spec"], spec, "Multi-char key should look up the correct spec")
