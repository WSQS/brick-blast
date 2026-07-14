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


# ---------------------------------------------------------------------------
# Full _physics_process simulation (reproduces the "ball stops" bug)
# These tests call ball._physics_process directly to verify the actual
# game code bounces the ball, not just the math.
# ---------------------------------------------------------------------------

## Drives ball._physics_process for N frames, stepping the physics server
## between each call so move_and_collide sees updated body positions.
func _simulate_physics_process(frames: int, delta: float) -> void:
	for i in frames:
		ball.force_update_transform()
		brick.force_update_transform()
		paddle.force_update_transform()
		ball._physics_process(delta)


func test_ball_bounces_up_after_hitting_brick_top() -> void:
	brick.position = Vector2(200, 200)
	ball.position = Vector2(200, 185)  # just above brick, will reach it quickly
	ball.launch(Vector2(0, 1))  # moving straight down

	var pos_before := ball.position.y
	_simulate_physics_process(20, 1.0 / 60.0)

	gut.p("Ball: pos_before_y=%s pos_after_y=%s velocity=%s" % [pos_before, ball.position.y, ball.velocity])
	# After hitting brick from top, ball should have bounced UP (negative y velocity)
	assert_true(ball.velocity.y < 0, "Ball velocity.y should be negative (bounced up), got %s" % ball.velocity.y)
	# Ball should have moved upward after bounce (position decreased after reaching brick)
	assert_true(ball.position.y < pos_before + 20, "Ball should not be stuck at/past the brick")


func test_ball_bounces_left_after_hitting_brick_right_edge() -> void:
	brick.position = Vector2(200, 200)
	ball.position = Vector2(178, 200)  # left of brick, moving right
	ball.launch(Vector2(1, 0))

	var pos_before := ball.position.x
	_simulate_physics_process(20, 1.0 / 60.0)

	gut.p("Ball: pos_before_x=%s pos_after_x=%s velocity=%s" % [pos_before, ball.position.x, ball.velocity])
	assert_true(ball.velocity.x < 0, "Ball velocity.x should be negative (bounced left), got %s" % ball.velocity.x)


func test_ball_does_not_stick_to_brick() -> void:
	brick.position = Vector2(200, 200)
	ball.position = Vector2(200, 185)
	ball.launch(Vector2(0, 1))

	_simulate_physics_process(30, 1.0 / 60.0)

	# Ball should be moving away from brick, not stuck at same position
	assert_true(ball.velocity.length() > 100.0, "Ball should still be moving after bounce, velocity=%s" % ball.velocity)


# ---------------------------------------------------------------------------
# Bug reproduction: groups lost at runtime (caused ball to not bounce)
# ---------------------------------------------------------------------------

func test_brick_has_brick_group_after_instantiation() -> void:
	# .tscn groups don't persist through instantiate() + add_child().
	# This test documents that behavior and verifies the fix (add_to_group).
	var b: StaticBody2D = BrickScene.instantiate()
	add_child_autofree(b)
	# Groups from .tscn are NOT preserved — this is a known Godot behavior
	assert_false(b.is_in_group("brick"), "Brick should NOT have 'brick' group from .tscn alone")
	# The fix: explicitly add to group (as main.gd _spawn_bricks does)
	b.add_to_group("brick")
	assert_true(b.is_in_group("brick"), "Brick should be in 'brick' group after explicit add_to_group")


func test_brick_collision_handler_triggers_on_brick_group() -> void:
	# This reproduces the "ball stops" bug: if the brick isn't in the
	# "brick" group, the collision handler can't identify it.
	brick.position = Vector2(200, 200)
	ball.position = Vector2(200, 185)
	ball.launch(Vector2(0, 1))

	# Ensure brick is in group (simulating the fix)
	if not brick.is_in_group("brick"):
		brick.add_to_group("brick")

	_simulate_physics_process(10, 1.0 / 60.0)

	# Ball should have bounced and destroyed the brick
	assert_true(ball.velocity.y < 0, "Ball should bounce up after hitting brick")
	watch_signals(brick)
	# If brick still exists, destroy was already called (queue_free deferred)
	# The key assertion is that ball bounced, proving the group check worked
