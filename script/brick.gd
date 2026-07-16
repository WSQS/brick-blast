extends StaticBody2D
## Brick — destructible block. Emits destroyed signal.

signal destroyed

@export var color: Color = Color("e94560"):
	set(v):
		color = v
		if has_node("ColorRect"):
			$ColorRect.color = color

var _destroyed: bool = false


func destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	destroyed.emit()
	queue_free()
