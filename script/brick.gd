extends Area2D
## Brick — destructible block. Emits destroyed signal.

signal destroyed

@export
var color: Color = Color("e94560"):
	set(v):
		color = v
		if has_node("ColorRect"):
			$ColorRect.color = color


func destroy() -> void:
	destroyed.emit()
	queue_free()


func get_rect() -> Rect2:
	var s: Vector2 = $CollisionShape2D.shape.size
	return Rect2(global_position - s / 2.0, s)
