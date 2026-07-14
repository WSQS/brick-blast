extends GutTest
## Integration tests for ball-brick collision using the real physics engine.
## Ball is CharacterBody2D — move_and_collide() returns immediate collision info.
##
## Key technique: GUT's test runner does not step PhysicsServer2D between
## calls, so we must:
##   1. force_update_transform() to sync body positions into the physics space
##   2. call move_and_collide() in a manual loop (sub-stepping)

const BallScene: PackedScene = preload("res://scene/ball.tscn")
const BrickScene: PackedScene = preload("res://scene/brick.tscn")
const PaddleScene: PackedScene = preload("res://scene/paddle.tscn")

var ball: CharacterBody2D
var brick: StaticBody2D
var paddle: StaticBody2D


func before_each() -> void:
	ball = BallScene.instantiate()
	brick = BrickScene.instantiate()
	paddle = PaddleScene.instantiate()
	ball.bounds = Rect2(-9999, -9999, 19999, 19999)
	add_child_autofree(ball)
	add_child_autofree(brick)
	add_child_autofree(paddle)
	ball.set_physics_process(true)
	# Groups from .tscn may not persist in test context — add explicitly
	if not brick.is_in_group("brick"):
		brick.add_to_group("brick")
	if not paddle.is_in_group("paddle"):
		paddle.add_to_group("paddle")


func _on_ball_lost() -> void:
	pass


## Moves the ball toward a target direction in small sub-steps.
## Returns the first collision found, or null.
func _move_until_collision(steps: int, step_vec: Vector2) -> KinematicCollision2D:
	# Sync all physics bodies into the physics space before testing
	ball.force_update_transform()
	brick.force_update_transform()
	paddle.force_update_transform()

	for i in steps:
		ball.force_update_transform()
		var col := ball.move_and_collide(step_vec)
		if col:
			return col
	return null


# ---------------------------------------------------------------------------
# Ball-brick collision
# ---------------------------------------------------------------------------

func test_ball_destroys_brick_from_top() -> void:
	brick.position = Vector2(200, 200)
	ball.position = Vector2(200, 180)
	ball.launch(Vector2(0, 1))  # moving down

	var col := _move_until_collision(30, Vector2(0, 2.0))

	assert_not_null(col, "Should detect collision with brick")
	if col:
		var collider = col.get_collider()
		assert_eq(collider, brick, "Collider should be the brick")
		# Simulate the bounce the ball would do
		var bounced: Vector2 = ball.velocity.bounce(col.get_normal())
		assert_true(bounced.y < 0, "Bounced velocity should be upward (negative y)")
		# Verify brick would be destroyed (signal fires immediately, queue_free is deferred)
		watch_signals(brick)
		brick.destroy()
		assert_signal_emitted(brick, "destroyed", "Brick destroyed signal should fire")


func test_ball_bounces_off_brick_left_edge() -> void:
	brick.position = Vector2(200, 200)
	ball.position = Vector2(165, 200)  # left of brick
	ball.launch(Vector2(1, 0))  # moving right

	var col := _move_until_collision(30, Vector2(2.0, 0))

	assert_not_null(col, "Should detect collision with brick edge")
	if col:
		var bounced := ball.velocity.bounce(col.get_normal())
		assert_true(bounced.x < 0, "Bounced velocity should be leftward (negative x)")


# ---------------------------------------------------------------------------
# Ball-paddle collision
# ---------------------------------------------------------------------------

func test_ball_bounces_up_off_paddle_center() -> void:
	paddle.position = Vector2(200, 600)
	ball.position = Vector2(200, 580)
	ball.launch(Vector2(0, 1))  # moving down

	var col := _move_until_collision(30, Vector2(0, 2.0))

	assert_not_null(col, "Should detect collision with paddle")
	if col:
		var collider = col.get_collider()
		assert_eq(collider, paddle, "Collider should be the paddle")
		# Simulate the paddle bounce (angle-based, not normal-based)
		var bounced: Vector2 = ball.bounce_off_paddle(ball.global_position, paddle.get_rect(), 320.0)
		assert_true(bounced.y < 0, "Should bounce up after center paddle hit")
		assert_almost_eq(bounced.x, 0.0, 5.0, "Center hit should produce near-zero horizontal velocity")


func test_ball_bounces_right_off_paddle_right_edge() -> void:
	paddle.position = Vector2(200, 600)
	ball.position = Vector2(240, 580)  # right portion of paddle
	ball.launch(Vector2(0, 1))

	var col := _move_until_collision(30, Vector2(0, 2.0))

	assert_not_null(col, "Should detect collision with paddle")
	if col:
		var bounced: Vector2 = ball.bounce_off_paddle(ball.global_position, paddle.get_rect(), 320.0)
		assert_true(bounced.y < 0, "Should bounce up")
		assert_true(bounced.x > 0, "Right-edge hit should push ball right")
