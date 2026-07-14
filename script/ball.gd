extends Area2D
## Ball — bounces off walls, paddle, and bricks.
## Uses sub-stepping to prevent tunneling at high speed.
## Collision math is in pure static methods for easy unit testing.

const SPEED: float = 320.0
const MAX_SPEED: float = 550.0
const SUBSTEPS: int = 4  # split each frame into sub-steps to avoid tunneling
const RADIUS: float = 8.0

var velocity: Vector2 = Vector2.ZERO
var _speed: float = SPEED

# Playfield bounds (set by main on ready)
var bounds: Rect2 = Rect2(0, 0, 480, 720)

# Cooldown to avoid re-triggering the same brick/paddle in consecutive frames
var _bounce_lockout: float = 0.0


func launch(direction: Vector2) -> void:
	velocity = direction.normalized() * _speed


func _physics_process(delta: float) -> void:
	_bounce_lockout = maxf(0.0, _bounce_lockout - delta)

	var step_dt: float = delta / float(SUBSTEPS)
	for i in SUBSTEPS:
		position += velocity * step_dt
		_handle_walls()
		if _bounce_lockout <= 0.0:
			_check_collisions()
		# Check fall each sub-step
		if position.y > bounds.end.y + 50:
			get_parent()._on_ball_lost()
			return


func _handle_walls() -> void:
	var result := calc_wall_bounce(position, velocity, RADIUS, bounds)
	position = result[0]
	velocity = result[1]


func _check_collisions() -> void:
	for area in get_overlapping_areas():
		if area.is_in_group("brick"):
			var r := bounce_off_rect(position, velocity, area.get_rect(), RADIUS)
			position = r[0]
			velocity = r[1]
			area.destroy()
			_bounce_lockout = 0.02
			return
		elif area.is_in_group("paddle"):
			var paddle_rect: Rect2 = area.get_rect()
			velocity = bounce_off_paddle(position, paddle_rect, _speed)
			_speed = minf(_speed * 1.03, MAX_SPEED)
			velocity = velocity.normalized() * _speed
			# Push ball above paddle to prevent sticking
			position.y = paddle_rect.position.y - RADIUS - 1.0
			_bounce_lockout = 0.02
			return


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


## Returns [new_pos, new_vel] after bouncing off a rectangle (brick).
## Determines bounce axis by penetration depth and pushes ball out.
static func bounce_off_rect(pos: Vector2, vel: Vector2, rect: Rect2, radius: float) -> Array:
	var rect_center := rect.get_center()
	var overlap_x := (radius + rect.size.x / 2.0) - absf(pos.x - rect_center.x)
	var overlap_y := (radius + rect.size.y / 2.0) - absf(pos.y - rect_center.y)

	var new_pos := pos
	var new_vel := vel

	if overlap_x < overlap_y:
		new_vel.x = -vel.x
		new_pos.x = pos.x + signf(pos.x - rect_center.x) * (overlap_x + 1.0)
	else:
		new_vel.y = -vel.y
		new_pos.y = pos.y + signf(pos.y - rect_center.y) * (overlap_y + 1.0)

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

