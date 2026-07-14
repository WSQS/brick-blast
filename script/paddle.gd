extends Area2D
## Paddle — moves horizontally, follows mouse / touch / arrow keys.

const MOVE_SPEED: float = 600.0

var bounds: Rect2 = Rect2(0, 0, 480, 720)


func _physics_process(delta: float) -> void:
	var target_x := position.x

	# Keyboard input
	var dir: float = Input.get_axis("ui_left", "ui_right")
	if dir != 0.0:
		target_x += dir * MOVE_SPEED * delta
	else:
		# Mouse / touch follow
		var mouse_x := get_global_mouse_position().x
		if mouse_x > 0.0 and mouse_x < bounds.size.x:
			target_x = mouse_x

	# Clamp within bounds
	var half_w: float = $CollisionShape2D.shape.size.x / 2.0
	target_x = clampf(target_x, bounds.position.x + half_w, bounds.end.x - half_w)
	position.x = target_x
