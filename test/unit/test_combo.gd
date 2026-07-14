extends GutTest
## Tests for combo system (D011), star rating (D013), and ball stick (D012).

const MainScene: PackedScene = preload("res://scene/main.tscn")

var main: Node2D


func before_each() -> void:
	main = MainScene.instantiate()
	add_child_autofree(main)


# ---------------------------------------------------------------------------
# Combo system (D011)
# ---------------------------------------------------------------------------

func test_combo_starts_at_zero() -> void:
	assert_eq(main.combo, 0, "Combo should start at 0")


func test_combo_increments_on_brick_destroyed() -> void:
	main._on_brick_destroyed()
	main._on_brick_destroyed()
	main._on_brick_destroyed()
	assert_eq(main.combo, 3, "Combo should be 3 after 3 bricks destroyed")


func test_combo_resets_on_paddle_hit() -> void:
	main._on_brick_destroyed()
	main._on_brick_destroyed()
	assert_eq(main.combo, 2, "Combo should be 2")
	main._on_paddle_hit()
	assert_eq(main.combo, 0, "Combo should reset to 0 on paddle hit")


func test_combo_resets_on_ball_lost() -> void:
	main.combo = 5
	main._on_ball_lost()
	assert_eq(main.combo, 0, "Combo should reset to 0 on ball lost")


func test_max_combo_tracked() -> void:
	for i in 5:
		main._on_brick_destroyed()
	main._on_paddle_hit()
	for i in 3:
		main._on_brick_destroyed()
	assert_eq(main.max_combo, 5, "Max combo should be 5 even after reset")


func test_score_scales_with_combo() -> void:
	var score_before: int = main.score
	main._on_brick_destroyed()  # combo=1, score += 10*(1+0) = 10
	assert_eq(main.score - score_before, 10, "First brick: combo 1, base score")
	score_before = main.score
	# Reach combo 5 (need 4 more): combo 2,3,4 = 10 each, combo 5 = 20
	for i in 4:
		main._on_brick_destroyed()
	assert_eq(main.score - score_before, 10 + 10 + 10 + 20, "Score should scale with combo/5")


# ---------------------------------------------------------------------------
# Star rating (D013)
# ---------------------------------------------------------------------------

func test_one_star_for_clearing() -> void:
	main.max_combo = 5
	main.lives_lost_this_level = 1
	assert_eq(main._compute_stars(), 1, "Should be 1 star for clearing with low combo")


func test_two_stars_for_high_combo() -> void:
	main.max_combo = 10
	main.lives_lost_this_level = 1
	assert_eq(main._compute_stars(), 2, "Should be 2 stars for combo >= 10")


func test_three_stars_for_no_lives_lost() -> void:
	main.max_combo = 10
	main.lives_lost_this_level = 0
	assert_eq(main._compute_stars(), 3, "Should be 3 stars for combo >= 10 and no lives lost")


func test_two_stars_for_no_lives_lost_low_combo() -> void:
	main.max_combo = 3
	main.lives_lost_this_level = 0
	assert_eq(main._compute_stars(), 2, "Should be 2 stars for no lives lost even with low combo")


# ---------------------------------------------------------------------------
# Ball stick (D012)
# ---------------------------------------------------------------------------

func test_ball_starts_stuck() -> void:
	assert_true(main.ball_stuck, "Ball should be stuck to paddle at start")


func test_ball_unstuck_on_launch() -> void:
	main.ball_stuck = true
	main._launch_ball()
	assert_false(main.ball_stuck, "Ball should not be stuck after launch")


func test_ball_restucks_on_reset() -> void:
	main.ball_stuck = false
	main._reset_round()
	assert_true(main.ball_stuck, "Ball should be stuck again after reset")
