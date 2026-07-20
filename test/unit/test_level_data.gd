extends GutTest
## Tests for LevelData — delegates brick building to its encoding strategy.

const BrickSpec = preload("res://script/brick_spec.gd")
const LevelData = preload("res://script/level_data.gd")
const AsciiLayout = preload("res://script/ascii_layout.gd")
const PolygonLayout = preload("res://script/polygon_layout.gd")


func _make_spec(color: Color) -> BrickSpec:
	var spec := BrickSpec.new()
	spec.color = color
	return spec


func _make_ascii_level(rows: Array[String], specs: Dictionary) -> LevelData:
	var level := LevelData.new()
	level.name = "test"
	level.encoding = AsciiLayout.new()
	(level.encoding as AsciiLayout).rows = rows
	(level.encoding as AsciiLayout).cell_size = Vector2(10, 10)
	(level.encoding as AsciiLayout).grid_origin = Vector2(0, 0)
	(level.encoding as AsciiLayout).gap = 0.0
	level.specs = specs
	return level


func test_build_bricks_delegates_to_encoding() -> void:
	var level := _make_ascii_level(["RR"], {"R": _make_spec(Color.RED)})
	var result: Array = level.build_bricks()
	assert_eq(result.size(), 2, "LevelData should delegate to AsciiLayout")


func test_build_bricks_with_no_encoding_returns_empty() -> void:
	var level := LevelData.new()
	level.name = "empty"
	var result: Array = level.build_bricks()
	assert_eq(result.size(), 0, "No encoding should produce zero bricks")
	assert_push_error("has no encoding")


func test_build_bricks_with_polygon_encoding() -> void:
	var level := LevelData.new()
	level.name = "poly"
	var poly_layout := PolygonLayout.new()
	poly_layout.bricks = [
		{
			"polygon": PackedVector2Array([Vector2.ZERO, Vector2(10, 0), Vector2(5, 10)]),
			"spec_key": "T"
		}
	]
	level.encoding = poly_layout
	level.specs = {"T": _make_spec(Color.BLUE)}
	var result: Array = level.build_bricks()
	assert_eq(result.size(), 1, "PolygonLayout should be dispatched correctly")


func test_name_is_stored() -> void:
	var level := LevelData.new()
	level.name = "Diamond"
	assert_eq(level.name, "Diamond", "Name should be stored and retrievable")
