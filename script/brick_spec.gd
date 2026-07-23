class_name BrickSpec
extends Resource
## BrickSpec — describes a brick *type* (visual + stats + behaviors).
##
## Position is NOT part of a spec; positions are decided by the level layout.
## Multiple brick instances can share the same BrickSpec.

@export var color: Color = Color.WHITE
@export var hp: int = 1
@export var behaviors: Array[BrickBehavior] = []
