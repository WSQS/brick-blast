class_name LevelData
extends Resource
## LevelData — a single level's configuration.
##
## A level is composed of:
##   - metadata (name, etc.)
##   - a layout strategy (encoding) that knows how to parse spatial data
##   - a per-level specs table (char/key -> BrickSpec)
##
## build_bricks() delegates to the encoding strategy, producing a uniform
## list of {polygon, spec} entries that main._spawn_bricks consumes.

@export var name: String = ""
@export var encoding: BrickLayout
@export var specs: Dictionary = {}  # String -> BrickSpec


## Parse this level's layout into a uniform list of brick instances.
## Each entry: {"polygon": PackedVector2Array, "spec": BrickSpec}.
func build_bricks() -> Array[Dictionary]:
	if encoding == null:
		push_error("LevelData '%s' has no encoding" % name)
		return []
	return encoding.build(specs)
