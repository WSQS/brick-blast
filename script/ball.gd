extends Area2D
## Ball — bounces off walls, paddle, and bricks.

const SPEED: float = 360.0
const MAX_SPEED: float = 600.0

var velocity: Vector2 = Vector2.ZERO
var _speed: float = SPEED

# Playfield bounds (set by main on ready)
var bounds: Rect2 = Rect2(0, 0, 480, 720)


func launch(direction: Vector2) -> void:
	velocity = direction.normalized() * _speed


func _physics_process(delta: float) -> void:
	position += velocity * delta

	var radius: float = $CollisionShape2D.shape.radius

	# Wall collisions (left / right / top)
	if position.x - radius < bounds.position.x:
		position.x = bounds.position.x + radius
		velocity.x = absf(velocity.x)
	elif position.x + radius > bounds.end.x:
		position.x = bounds.end.x - radius
		velocity.x = -absf(velocity.x)

	if position.y - radius < bounds.position.y:
		position.y = bounds.position.y + radius
		velocity.y = absf(velocity.y)

	# Fell below paddle — notify main
	if position.y > bounds.end.y + 50:
		get_parent()._on_ball_lost()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("brick"):
		_bounce_off_rect(area)
		area.destroy()
	elif area.is_in_group("paddle"):
		_bounce_off_paddle(area)


func _bounce_off_rect(area: Area2D) -> void:
	var ball_center := global_position
	var area_rect: Rect2 = area.get_rect()
	var area_center := area_rect.get_center()
	var radius: float = $CollisionShape2D.shape.radius

	var overlap_x := (radius + area_rect.size.x / 2.0) - absf(ball_center.x - area_center.x)
	var overlap_y := (radius + area_rect.size.y / 2.0) - absf(ball_center.y - area_center.y)

	if overlap_x < overlap_y:
		velocity.x = -velocity.x
	else:
		velocity.y = -velocity.y


func _bounce_off_paddle(paddle: Area2D) -> void:
	var paddle_rect: Rect2 = paddle.get_rect()
	var paddle_center_x := paddle_rect.get_center().x
	var offset: float = clampf((global_position.x - paddle_center_x) / (paddle_rect.size.x / 2.0), -1.0, 1.0)

	var angle := offset * deg_to_rad(60.0)
	_speed = minf(_speed * 1.02, MAX_SPEED)
	velocity = Vector2(sin(angle), -cos(angle)) * _speed
