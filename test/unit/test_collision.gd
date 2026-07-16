extends GutTest
## Tests for ball collision math (pure static methods).
## Brick collision is now handled by physics engine (velocity.bounce),
## so only wall, paddle, and overlap functions are tested here.

const BallScript = preload("res://script/ball.gd")
const RADIUS: float = 8.0

# A typical brick rect centered at (100, 50), size 52×22
const BRICK_RECT: Rect2 = Rect2(100 - 26, 50 - 11, 52, 22)
# A typical paddle rect centered at (240, 660), size 96×14
const PADDLE_RECT: Rect2 = Rect2(240 - 48, 660 - 7, 96, 14)


# Migrated from ball.gd — only used in tests now
static func circle_overlaps_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(
		clampf(center.x, rect.position.x, rect.end.x),
		clampf(center.y, rect.position.y, rect.end.y),
	)
	return center.distance_squared_to(closest) <= radius * radius


# ---------------------------------------------------------------------------
# Wall collision (calc_wall_bounce)
# ---------------------------------------------------------------------------


func test_wall_left_bounces_right() -> void:
	var result: Array = BallScript.calc_wall_bounce(
		Vector2(5, 360), Vector2(-1, 0), RADIUS, Rect2(0, 0, 480, 720)
	)
	assert_true(result[1].x > 0, "Should bounce right off left wall")
	assert_almost_eq(result[0].x, RADIUS, 0.1, "Should be clamped to wall + radius")


func test_wall_right_bounces_left() -> void:
	var result: Array = BallScript.calc_wall_bounce(
		Vector2(475, 360), Vector2(1, 0), RADIUS, Rect2(0, 0, 480, 720)
	)
	assert_true(result[1].x < 0, "Should bounce left off right wall")
	assert_almost_eq(result[0].x, 480.0 - RADIUS, 0.1, "Should be clamped to wall - radius")


func test_wall_top_bounces_down() -> void:
	var result: Array = BallScript.calc_wall_bounce(
		Vector2(240, 3), Vector2(0, -1), RADIUS, Rect2(0, 0, 480, 720)
	)
	assert_true(result[1].y > 0, "Should bounce down off top wall")


func test_wall_no_collision_keeps_velocity() -> void:
	var result: Array = BallScript.calc_wall_bounce(
		Vector2(240, 360), Vector2(1, 1), RADIUS, Rect2(0, 0, 480, 720)
	)
	assert_eq(result[1], Vector2(1, 1), "Velocity unchanged when not touching wall")


# ---------------------------------------------------------------------------
# Ball-paddle collision (bounce_off_paddle)
# ---------------------------------------------------------------------------


func test_paddle_center_bounces_straight_up() -> void:
	var vel := BallScript.bounce_off_paddle(Vector2(240, 660), PADDLE_RECT, 320.0)
	assert_true(vel.y < 0, "Should bounce up")
	assert_almost_eq(vel.x, 0.0, 1.0, "Center hit should produce ~0 horizontal velocity")


func test_paddle_right_edge_bounces_right() -> void:
	var vel := BallScript.bounce_off_paddle(Vector2(240 + 40, 660), PADDLE_RECT, 320.0)
	assert_true(vel.y < 0, "Should bounce up")
	assert_true(vel.x > 0, "Right-edge hit should push ball right")


func test_paddle_left_edge_bounces_left() -> void:
	var vel := BallScript.bounce_off_paddle(Vector2(240 - 40, 660), PADDLE_RECT, 320.0)
	assert_true(vel.y < 0, "Should bounce up")
	assert_true(vel.x < 0, "Left-edge hit should push ball left")


func test_paddle_speed_preserved() -> void:
	var vel := BallScript.bounce_off_paddle(Vector2(240, 660), PADDLE_RECT, 320.0)
	assert_almost_eq(vel.length(), 320.0, 0.5, "Speed should be preserved")


# ---------------------------------------------------------------------------
# Circle-rect overlap detection (circle_overlaps_rect)
# ---------------------------------------------------------------------------


func test_circle_overlaps_rect_true_when_inside() -> void:
	assert_true(
		circle_overlaps_rect(Vector2(100, 50), RADIUS, BRICK_RECT), "Center of rect should overlap"
	)


func test_circle_overlaps_rect_true_when_touching_edge() -> void:
	assert_true(
		circle_overlaps_rect(Vector2(100 + 26 + RADIUS - 1, 50), RADIUS, BRICK_RECT),
		"Just touching edge should overlap"
	)


func test_circle_overlaps_rect_false_when_far() -> void:
	assert_false(
		circle_overlaps_rect(Vector2(300, 300), RADIUS, BRICK_RECT), "Far away should not overlap"
	)


func test_circle_overlaps_rect_false_when_gap() -> void:
	assert_false(
		circle_overlaps_rect(Vector2(100 + 26 + RADIUS + 5, 50), RADIUS, BRICK_RECT),
		"Clear gap should not overlap"
	)
