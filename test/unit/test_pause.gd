extends GutTest
## Tests for pause/resume functionality (D012).

const MainScene: PackedScene = preload("res://scene/main.tscn")

var main: Node2D


func before_each() -> void:
	main = MainScene.instantiate()
	add_child_autofree(main)


func _press_esc() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	main._input(event)


func test_pause_toggles_paused_flag() -> void:
	assert_eq(main.state, main.State.READY, "Should start in READY state")
	_press_esc()
	assert_eq(main.state, main.State.PAUSED, "Should be paused after toggle")
	_press_esc()
	assert_eq(main.state, main.State.READY, "Should be READY again after second toggle")


func test_pause_sets_scene_tree_paused() -> void:
	_press_esc()
	assert_eq(main.state, main.State.PAUSED, "state should be PAUSED")
	assert_false(get_tree().paused, "SceneTree.paused should NOT be used")
	_press_esc()
	assert_ne(main.state, main.State.PAUSED, "state should not be PAUSED")


func test_pause_does_not_work_after_game_over() -> void:
	# Force game over
	main.lives = 1
	main._on_ball_lost(main.balls[0])  # lives -> 0, triggers _game_over()
	assert_eq(main.state, main.State.GAME_OVER, "Should be game over")

	# Simulate Esc press during game over — _input should return early
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	main._input(event)
	assert_eq(main.state, main.State.GAME_OVER, "Should not be able to pause after game over")


func test_launch_does_not_work_while_paused() -> void:
	# Ball is stuck at start (READY), pause the game
	_press_esc()
	assert_eq(main.state, main.State.PAUSED, "Should be paused")

	# Simulate Space press while paused — state should stay PAUSED
	var event := InputEventAction.new()
	event.action = "ui_accept"
	event.pressed = true
	main._input(event)
	assert_eq(main.state, main.State.PAUSED, "Launch input should be ignored while paused")


func test_paddle_does_not_move_while_paused() -> void:
	var paddle: StaticBody2D = main.paddle
	var x_before: float = paddle.position.x

	# Pause the game
	_press_esc()
	assert_eq(main.state, main.State.PAUSED, "Should be paused")

	# Simulate movement by calling _physics_process directly
	paddle._physics_process(0.016)

	var x_after: float = paddle.position.x
	assert_eq(x_before, x_after, "Paddle should not move while paused")
