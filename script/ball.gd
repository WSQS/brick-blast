extends CharacterBody2D
## Ball — bounces off walls, paddle, and bricks.
## Uses CharacterBody2D.move_and_collide() for CCD (no tunneling).
## Collision info is returned immediately by the physics engine.

const SPEED: float = 320.0
const MAX_SPEED: float = 550.0
const RADIUS: float = 8.0
const LOSE_MARGIN: float = 50.0

var speed: float = SPEED
var pierce_count: int = 0

var bounds: Rect2 = Rect2(0, 0, 480, 720)

## Emitted when the ball hits the paddle. Parameter: this ball.
signal hit_paddle(ball: CharacterBody2D)
## Emitted when the ball falls below the playfield. Parameter: this ball.
signal lost(ball: CharacterBody2D)


func launch(direction: Vector2) -> void:
	velocity = direction.normalized() * speed


func _physics_process(delta: float) -> void:
	var parent: Node = get_parent()
	# If parent implements is_playing(), only move when game is actively playing.
	# Otherwise (e.g. standalone in tests), always process.
	if parent != null and parent.has_method("is_playing") and not parent.is_playing():
		return

	var collision := move_and_collide(velocity * delta)
	_handle_walls()

	if collision:
		var collider := collision.get_collider()
		if collider and collider.is_in_group("brick"):
			if pierce_count > 0:
				pierce_count -= 1
				# Move ball through the brick by the remaining distance
				global_position += collision.get_remainder()
				# Pierce destroys immediately (bypasses hp/behaviors)
				collider.destroy()
			else:
				velocity = velocity.bounce(collision.get_normal())
				collider.on_hit(self, parent)
		elif collider == parent.get("paddle"):
			if global_position.y < collider.global_position.y:
				# Ball hits paddle from above — normal paddle bounce
				velocity = bounce_off_paddle(global_position, collider.get_rect(), speed)
				hit_paddle.emit(self)
			else:
				# Ball is below paddle (paddle slid over it) — bounce downward
				# to prevent the ball from getting stuck against the paddle underside
				velocity.y = absf(velocity.y)

	if global_position.y > bounds.end.y + LOSE_MARGIN:
		lost.emit(self)


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
