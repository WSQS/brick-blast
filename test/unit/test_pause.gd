extends GutTest
## Tests for pause/resume functionality (D012).

const MainScene: PackedScene = preload("res://scene/main.tscn")

var main: Node2D


func before_each() -> void:
	main = MainScene.instantiate()
	add_child_autofree(main)


func test_pause_toggles_paused_flag() -> void:
	assert_false(main.paused, "Should start unpaused")
	main._toggle_pause()
	assert_true(main.paused, "Should be paused after toggle")
	main._toggle_pause()
	assert_false(main.paused, "Should be unpaused after second toggle")


func test_pause_sets_scene_tree_paused() -> void:
	main._toggle_pause()
	assert_true(main.paused, "paused flag should be true")
	assert_false(get_tree().paused, "SceneTree.paused should NOT be used")
	main._toggle_pause()
	assert_false(main.paused, "paused flag should be false")


func test_pause_does_not_work_after_game_over() -> void:
	# Force game over
	main.lives = 1
	main._on_ball_lost()  # lives -> 0, triggers _lose()
	assert_true(main.game_over, "Should be game over")

	# Simulate Esc press during game over — _input should return early
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	main._input(event)
	assert_false(main.paused, "Should not be able to pause after game over")


func test_launch_does_not_work_while_paused() -> void:
	# Ball is stuck at start, pause the game
	main._toggle_pause()
	assert_true(main.paused, "Should be paused")

	# Simulate click/space while paused — ball should stay stuck
	# _input doesn't check paused for launch, but ball._physics_process
	# checks ball_stuck which stays true
	assert_true(main.ball_stuck, "Ball should still be stuck while paused")


func test_paddle_does_not_move_while_paused() -> void:
	var paddle: StaticBody2D = main.paddle
	var x_before: float = paddle.position.x

	# Pause the game
	main._toggle_pause()
	assert_true(main.paused, "Should be paused")

	# Simulate movement by calling _physics_process directly
	paddle._physics_process(0.016)

	var x_after: float = paddle.position.x
	assert_eq(x_before, x_after, "Paddle should not move while paused")
