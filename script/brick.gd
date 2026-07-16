extends StaticBody2D
## Brick — destructible block. Emits destroyed signal.

signal destroyed

@export var color: Color = Color("e94560"):
	set(v):
		color = v
		if has_node("ColorRect"):
			$ColorRect.color = color


func destroy() -> void:
	destroyed.emit()
	queue_free()
