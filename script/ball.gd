extends CharacterBody2D
## Ball — bounces off walls, paddle, and bricks.
## Uses CharacterBody2D.move_and_collide() for CCD (no tunneling).
## Collision info is returned immediately by the physics engine.

const SPEED: float = 320.0
const MAX_SPEED: float = 550.0
const RADIUS: float = 8.0

var _speed: float = SPEED

# Playfield bounds (set by main on ready)
var bounds: Rect2 = Rect2(0, 0, 480, 720)


func launch(direction: Vector2) -> void:
	velocity = direction.normalized() * _speed


func _physics_process(delta: float) -> void:
	# Skip physics when ball is stuck to paddle (D012)
	var parent := get_parent()
	if parent and parent.get("ball_stuck") == true:
		return

	var collision := move_and_collide(velocity * delta)

	# Wall collisions (left / right / top) via bounds check
	_handle_walls()

	if collision:
		var collider := collision.get_collider()
		if collider:
			if collider.is_in_group("brick"):
				velocity = velocity.bounce(collision.get_normal())
				collider.destroy()
			elif collider.is_in_group("paddle"):
				velocity = bounce_off_paddle(global_position, collider.get_rect(), _speed)
				_speed = minf(_speed * 1.03, MAX_SPEED)
				velocity = velocity.normalized() * _speed
				# Notify main to reset combo (D011)
				if parent and parent.has_method("_on_paddle_hit"):
					parent._on_paddle_hit()

	# Fell below paddle — notify main
	if global_position.y > bounds.end.y + 50:
		get_parent()._on_ball_lost()


func _handle_walls() -> void:
	var result := calc_wall_bounce(global_position, velocity, RADIUS, bounds)
	global_position = result[0]
	velocity = result[1]


# ---------------------------------------------------------------------------
# Pure collision math — testable without physics engine
# ---------------------------------------------------------------------------

## Returns [new_pos, new_vel] after wall collision.
static func calc_wall_bounce(pos: Vector2, vel: Vector2, radius: float, playfield: Rect2) -> Array:
	var new_pos := pos
	var new_vel := vel

	if pos.x - radius < playfield.position.x:
		new_pos.x = playfield.position.x + radius
		new_vel.x = absf(vel.x)
	elif pos.x + radius > playfield.end.x:
		new_pos.x = playfield.end.x - radius
		new_vel.x = -absf(vel.x)

	if pos.y - radius < playfield.position.y:
		new_pos.y = playfield.position.y + radius
		new_vel.y = absf(vel.y)

	return [new_pos, new_vel]


## Returns new velocity after bouncing off the paddle.
## Angle depends on where the ball hits: center = straight up, edges = angled.
static func bounce_off_paddle(pos: Vector2, paddle_rect: Rect2, speed: float) -> Vector2:
	var paddle_center_x := paddle_rect.get_center().x
	var offset: float = clampf((pos.x - paddle_center_x) / (paddle_rect.size.x / 2.0), -1.0, 1.0)
	var angle := offset * deg_to_rad(60.0)
	return Vector2(sin(angle), -cos(angle)) * speed


## Checks whether a circle (center, radius) overlaps a rect.
static func circle_overlaps_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(
		clampf(center.x, rect.position.x, rect.end.x),
		clampf(center.y, rect.position.y, rect.end.y),
	)
	return center.distance_squared_to(closest) <= radius * radius
