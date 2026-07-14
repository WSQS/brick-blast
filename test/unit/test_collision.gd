extends GutTest
## Tests for ball collision math (pure static methods).
## These test the collision logic directly, no physics engine needed.

const BallScript = preload("res://script/ball.gd")
const RADIUS: float = 8.0

# A typical brick rect centered at (100, 50), size 52×22
const BRICK_RECT: Rect2 = Rect2(100 - 26, 50 - 11, 52, 22)
# A typical paddle rect centered at (240, 660), size 96×14
const PADDLE_RECT: Rect2 = Rect2(240 - 48, 660 - 7, 96, 14)


# ---------------------------------------------------------------------------
# Wall collision
# ---------------------------------------------------------------------------

func test_wall_left_bounces_right() -> void:
	var result := BallScript.calc_wall_bounce(Vector2(5, 360), Vector2(-1, 0), RADIUS, Rect2(0, 0, 480, 720))
	assert_true(result[1].x > 0, "Should bounce right off left wall")
	assert_almost_eq(result[0].x, RADIUS, 0.1, "Should be clamped to wall + radius")


func test_wall_right_bounces_left() -> void:
	var result := BallScript.calc_wall_bounce(Vector2(475, 360), Vector2(1, 0), RADIUS, Rect2(0, 0, 480, 720))
	assert_true(result[1].x < 0, "Should bounce left off right wall")
	assert_almost_eq(result[0].x, 480.0 - RADIUS, 0.1, "Should be clamped to wall - radius")


func test_wall_top_bounces_down() -> void:
	var result := BallScript.calc_wall_bounce(Vector2(240, 3), Vector2(0, -1), RADIUS, Rect2(0, 0, 480, 720))
	assert_true(result[1].y > 0, "Should bounce down off top wall")


func test_wall_no_collision_keeps_velocity() -> void:
	var result := BallScript.calc_wall_bounce(Vector2(240, 360), Vector2(1, 1), RADIUS, Rect2(0, 0, 480, 720))
	assert_eq(result[1], Vector2(1, 1), "Velocity unchanged when not touching wall")


# ---------------------------------------------------------------------------
# Ball-brick collision: vertical (top/bottom)
# ---------------------------------------------------------------------------

func test_brick_top_hit_bounces_up() -> void:
	# Ball just touching brick top, moving down
	var pos := Vector2(100, 50 - 11 - RADIUS + 1)  # slightly overlapping from above
	var vel := Vector2(0, 1)
	var result := BallScript.bounce_off_rect(pos, vel, BRICK_RECT, RADIUS)
	assert_true(result[1].y < 0, "Should bounce upward (negative y) after top hit")
	assert_true(result[0].y < 50 - 11, "Ball should be pushed above the brick")


func test_brick_bottom_hit_bounces_down() -> void:
	# Ball just touching brick bottom, moving up
	var pos := Vector2(100, 50 + 11 + RADIUS - 1)  # slightly overlapping from below
	var vel := Vector2(0, -1)
	var result := BallScript.bounce_off_rect(pos, vel, BRICK_RECT, RADIUS)
	assert_true(result[1].y > 0, "Should bounce downward (positive y) after bottom hit")


# ---------------------------------------------------------------------------
# Ball-brick collision: horizontal (left/right edges)
# ---------------------------------------------------------------------------

func test_brick_right_edge_bounces_right() -> void:
	# Ball approaching from the right
	var pos := Vector2(100 + 26 + RADIUS - 1, 50)  # overlapping right edge
	var vel := Vector2(-1, 0)
	var result := BallScript.bounce_off_rect(pos, vel, BRICK_RECT, RADIUS)
	assert_true(result[1].x > 0, "Should bounce right off brick right edge")


func test_brick_left_edge_bounces_left() -> void:
	# Ball approaching from the left
	var pos := Vector2(100 - 26 - RADIUS + 1, 50)  # overlapping left edge
	var vel := Vector2(1, 0)
	var result := BallScript.bounce_off_rect(pos, vel, BRICK_RECT, RADIUS)
	assert_true(result[1].x < 0, "Should bounce left off brick left edge")


# ---------------------------------------------------------------------------
# Ball-brick collision: position correction
# ---------------------------------------------------------------------------

func test_brick_pushes_ball_out() -> void:
	var pos := Vector2(100, 50 - 11 - RADIUS + 2)  # 2px overlap from above
	var result := BallScript.bounce_off_rect(pos, Vector2(0, 1), BRICK_RECT, RADIUS)
	# After correction, ball should not overlap brick
	assert_false(BallScript.circle_overlaps_rect(result[0], RADIUS, BRICK_RECT), "Ball should be pushed out of brick")


# ---------------------------------------------------------------------------
# Circle-rect overlap detection
# ---------------------------------------------------------------------------

func test_circle_overlaps_rect_true_when_inside() -> void:
	assert_true(BallScript.circle_overlaps_rect(Vector2(100, 50), RADIUS, BRICK_RECT), "Center of rect should overlap")


func test_circle_overlaps_rect_true_when_touching_edge() -> void:
	assert_true(BallScript.circle_overlaps_rect(Vector2(100 + 26 + RADIUS - 1, 50), RADIUS, BRICK_RECT), "Just touching edge should overlap")


func test_circle_overlaps_rect_false_when_far() -> void:
	assert_false(BallScript.circle_overlaps_rect(Vector2(300, 300), RADIUS, BRICK_RECT), "Far away should not overlap")


func test_circle_overlaps_rect_false_when_gap() -> void:
	# Gap between circle and rect edge
	assert_false(BallScript.circle_overlaps_rect(Vector2(100 + 26 + RADIUS + 5, 50), RADIUS, BRICK_RECT), "Clear gap should not overlap")


# ---------------------------------------------------------------------------
# Ball-paddle collision
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

