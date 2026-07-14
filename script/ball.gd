extends Area2D
## Ball — bounces off walls, paddle, and bricks.

const SPEED: float = 360.0
const MAX_SPEED: float = 600.0

var velocity: Vector2 = Vector2.ZERO
var _speed: float = SPEED

# Playfield bounds (set by main on ready)
var bounds: Rect2 = Rect2(0, 0, 480, 720)

# Mask of bodies to detect (paddle / bricks connect via collision_layer)
const HIT_LAYER := 1  # paddle + bricks


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func launch(direction: Vector2) -> void:
	velocity = direction.normalized() * _speed


func _physics_process(delta: float) -> void:
	position += velocity * delta

	# Wall collisions (left / right / top)
	if position.x - $Shape.shape.radius < bounds.position.x:
		position.x = bounds.position.x + $Shape.shape.radius
		velocity.x = absf(velocity.x)
	elif position.x + $Shape.shape.radius > bounds.end.x:
		position.x = bounds.end.x - $Shape.shape.radius
		velocity.x = -absf(velocity.x)

	if position.y - $Shape.shape.radius < bounds.position.y:
		position.y = bounds.position.y + $Shape.shape.radius
		velocity.y = absf(velocity.y)

	# Fell below paddle — notify main
	if position.y > bounds.end.y + 50:
		get_parent()._on_ball_lost()


func _on_area_entered(area: Area2D) -> void:	_bounce_off(area)


func _bounce_off(area: Area2D) -> void:	if area.is_in_group("brick"):
		_bounce_off(area)
		area.destroy()
	elif area.is_in_group("paddle"):
		_bounce_off_paddle(area)


func _on_body_entered(_body: Node) -> void:
	pass


func _bounce_off(brick: Area2D) -> void:
	# Determine if collision is more horizontal or vertical
	var ball_center := global_position
	var brick_rect := brick.get_rect()
	var brick_center := brick_rect.get_center()

	var overlap_x := ($Shape.shape.radius + brick_rect.size.x / 2.0) - absf(ball_center.x - brick_center.x)
	var overlap_y := ($Shape.shape.radius + brick_rect.size.y / 2.0) - absf(ball_center.y - brick_center.y)

	if overlap_x < overlap_y:
		velocity.x = -velocity.x
	else:
		velocity.y = -velocity.y


func _bounce_off_paddle(paddle: Area2D) -> void:
	# Reflect with an angle based on where the ball hits the paddle
	var paddle_rect := paddle.get_rect()
	var paddle_center_x := paddle_rect.get_center().x
	var offset: float = clampf((global_position.x - paddle_center_x) / (paddle_rect.size.x / 2.0), -1.0, 1.0)

	var angle := offset * deg_to_rad(60.0)  # max 60° from vertical
	_speed = minf(_speed * 1.02, MAX_SPEED)
	velocity = Vector2(sin(angle), -cos(angle)) * _speed
