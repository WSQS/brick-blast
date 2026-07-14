extends Area2D
## Ball — bounces off walls, paddle, and bricks.
## Uses sub-stepping to prevent tunneling at high speed.

const SPEED: float = 320.0
const MAX_SPEED: float = 550.0
const SUBSTEPS: int = 4  # split each frame into sub-steps to avoid tunneling

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
	var radius: float = $CollisionShape2D.shape.radius

	if position.x - radius < bounds.position.x:
		position.x = bounds.position.x + radius
		velocity.x = absf(velocity.x)
	elif position.x + radius > bounds.end.x:
		position.x = bounds.end.x - radius
		velocity.x = -absf(velocity.x)

	if position.y - radius < bounds.position.y:
		position.y = bounds.position.y + radius
		velocity.y = absf(velocity.y)


func _check_collisions() -> void:
	for area in get_overlapping_areas():
		if area.is_in_group("brick"):
			_bounce_off_rect(area)
			area.destroy()
			_bounce_lockout = 0.02
			return
		elif area.is_in_group("paddle"):
			_bounce_off_paddle(area)
			# Push ball above paddle to prevent sticking
			var paddle_rect: Rect2 = area.get_rect()
			position.y = paddle_rect.position.y - $CollisionShape2D.shape.radius - 1.0
			_bounce_lockout = 0.02
			return


func _bounce_off_rect(area: Area2D) -> void:
	var ball_center := global_position
	var area_rect: Rect2 = area.get_rect()
	var area_center := area_rect.get_center()
	var radius: float = $CollisionShape2D.shape.radius

	var overlap_x := (radius + area_rect.size.x / 2.0) - absf(ball_center.x - area_center.x)
	var overlap_y := (radius + area_rect.size.y / 2.0) - absf(ball_center.y - area_center.y)

	# Determine bounce axis by the smaller overlap (penetration depth)
	if overlap_x < overlap_y:
		velocity.x = -velocity.x
		# Push ball out of the brick along x
		var push: float = overlap_x + 1.0
		position.x += signf(ball_center.x - area_center.x) * push
	else:
		velocity.y = -velocity.y
		var push: float = overlap_y + 1.0
		position.y += signf(ball_center.y - area_center.y) * push


func _bounce_off_paddle(paddle: Area2D) -> void:
	var paddle_rect: Rect2 = paddle.get_rect()
	var paddle_center_x := paddle_rect.get_center().x
	var offset: float = clampf((global_position.x - paddle_center_x) / (paddle_rect.size.x / 2.0), -1.0, 1.0)

	var angle := offset * deg_to_rad(60.0)
	_speed = minf(_speed * 1.03, MAX_SPEED)
	velocity = Vector2(sin(angle), -cos(angle)) * _speed
