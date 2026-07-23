class_name BrickLayout
extends Resource
## BrickLayout — abstract strategy for parsing a level's spatial data.
##
## Subclasses (AsciiLayout, PolygonLayout, ...) override build() to turn
## their encoding-specific data into a uniform list of brick instances.
##
## Output contract: each entry is a Dictionary
##   { "polygon": PackedVector2Array, "spec": BrickSpec }
##
## main._spawn_bricks() consumes this list and does not know which layout
## produced it.


## Parse this layout's data into a uniform list of brick instances.
## Each entry: {"polygon": PackedVector2Array, "spec": BrickSpec}.
func build(_specs: Dictionary) -> Array[Dictionary]:
	assert(false, "BrickLayout.build() must be overridden by subclass")
	return []
