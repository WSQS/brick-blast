class_name PolygonLayout
extends BrickLayout
## PolygonLayout — encodes bricks as explicit polygon vertices.
##
## Each entry in `bricks` is a Dictionary:
##   { "polygon": PackedVector2Array, "spec_key": String }
##
## spec_key is looked up in the level's specs table. Unlike AsciiLayout
## (which is constrained to single-char keys by the grid), spec_key here
## may be any string.

@export var bricks: Array[Dictionary] = []


func build(specs: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in bricks:
		var key: String = entry.get("spec_key", "")
		if not specs.has(key):
			push_error("PolygonLayout: unknown spec_key '%s'" % key)
			continue
		var polygon: PackedVector2Array = entry.get("polygon", PackedVector2Array())
		result.append({"polygon": polygon, "spec": specs[key]})
	return result
