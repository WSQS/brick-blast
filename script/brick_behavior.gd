class_name BrickBehavior
extends Resource
## BrickBehavior — abstract base for brick lifecycle hooks.
##
## Subclasses override on_hit / on_destroy / on_spawn to implement
## special behaviors (explosions, upgrade drops, regeneration, etc.).
##
## `context` is the main game node (duck-typed). It exposes query/spawn
## methods that behaviors may need:
##   - get_bricks_in_radius(center: Vector2, radius: float) -> Array[Node]
##   - spawn_upgrade_token(position: Vector2) -> void
##
## No BrickContext abstract class is introduced (YAGNI).


## Called when the brick is hit but not yet destroyed.
## Returns true to consume the hit (skip remaining behaviors).
func on_hit(_brick: Node, _ball: Node, _context: Node) -> bool:
	return false


## Called when the brick is destroyed (hp reached 0).
func on_destroy(_brick: Node, _context: Node) -> void:
	pass


## Called once after the brick is spawned into the tree.
func on_spawn(_brick: Node, _context: Node) -> void:
	pass
