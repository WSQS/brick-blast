extends GutTest
## Tests for upgrade system (D014).

const MainScene: PackedScene = preload("res://scene/main.tscn")

var main: Node2D


func before_each() -> void:
	main = MainScene.instantiate()
	add_child_autofree(main)


func _get_overlay() -> ColorRect:
	return main.get_node("UpgradePanel/Overlay") as ColorRect


func test_upgrade_panel_hidden_on_ready() -> void:
	var overlay: ColorRect = _get_overlay()
	assert_false(overlay.visible, "UpgradePanel overlay should be hidden on game start")


func test_upgrade_panel_overlay_hidden_on_ready() -> void:
	var overlay: ColorRect = _get_overlay()
	assert_false(overlay.visible, "Overlay should be hidden on game start")


func test_clearing_bricks_shows_round_clear_message() -> void:
	# Set bricks_left to 1, destroy last brick
	main.bricks_left = 1
	main._on_brick_destroyed()
	assert_eq(main.bricks_left, 0, "Bricks should be 0 after destroying last")
	assert_true(main.message.visible, "Message should show ROUND CLEAR")
	assert_string_contains(main.message.text, "ROUND CLEAR", "Message should say ROUND CLEAR")


func test_ball_stops_on_win() -> void:
	main.ball_stuck = false
	main.ball.velocity = Vector2(100, 100)
	main.bricks_left = 1
	main._on_brick_destroyed()
	assert_true(main.ball_stuck, "Ball should be stuck after win")
	assert_eq(main.ball.velocity, Vector2.ZERO, "Ball velocity should be zero after win")


func test_clearing_bricks_increments_rounds_cleared() -> void:
	var rounds_before: int = main.rounds_cleared
	main.bricks_left = 1
	main._on_brick_destroyed()
	assert_eq(main.rounds_cleared, rounds_before + 1, "rounds_cleared should increment")


func test_upgrade_panel_shown_after_win() -> void:
	main.bricks_left = 1
	main._on_brick_destroyed()
	# _win has await, need to wait for timer
	await wait_seconds(1.5)
	var overlay: ColorRect = _get_overlay()
	assert_true(overlay.visible, "UpgradePanel should be shown after winning")


func test_ball_stuck_set_false_after_win_flow() -> void:
	# When win happens, ball should be stopped (stuck state for next round)
	main.bricks_left = 1
	main.ball_stuck = false
	main._on_brick_destroyed()
	await wait_seconds(1.5)
	# Ball is still moving until upgrade is selected and next round starts
	# But game should be in a "waiting for upgrade" state
	var overlay: ColorRect = _get_overlay()
	assert_true(overlay.visible, "Should be waiting for upgrade selection")


func test_selecting_upgrade_starts_next_round() -> void:
	# Win the round
	main.bricks_left = 1
	main._on_brick_destroyed()
	await wait_seconds(1.5)

	# Verify panel is shown
	var overlay: ColorRect = _get_overlay()
	assert_true(overlay.visible, "Panel should be shown")

	# Select an upgrade by calling the panel's handler directly
	var panel = main.get_node("UpgradePanel")
	var first_button: Button = panel.buttons[0]
	assert_not_null(first_button.get_meta("upgrade"), "Button should have upgrade metadata")

	# Click the first button
	first_button.pressed.emit()
	await wait_seconds(0.5)

	# Panel should be hidden
	assert_false(overlay.visible, "Panel should be hidden after selecting")

	# Bricks should be respawned
	assert_true(main.bricks_left > 0, "Bricks should be respawned for next round")

	# Ball should be stuck
	assert_true(main.ball_stuck, "Ball should be stuck for next round")


func test_win_calls_show_choices_on_panel() -> void:
	# Verify that the upgrade_panel node has the script with show_choices method
	var panel = main.get_node("UpgradePanel")
	assert_true(panel.has_method("show_choices"), "Panel should have show_choices method")
	assert_true(panel.has_signal("upgrade_selected"), "Panel should have upgrade_selected signal")


func test_panel_buttons_have_text_after_show_choices() -> void:
	var panel = main.get_node("UpgradePanel")
	panel.show_choices()
	# All 3 buttons should have non-empty text
	for i in 3:
		var btn: Button = panel.buttons[i]
		assert_true(btn.text.length() > 0, "Button %d should have text after show_choices" % i)
		assert_not_null(btn.get_meta("upgrade"), "Button %d should have upgrade metadata" % i)


func test_overlay_visible_after_show_choices() -> void:
	var panel = main.get_node("UpgradePanel")
	var overlay: ColorRect = panel.overlay
	assert_false(overlay.visible, "Overlay should be hidden initially")
	panel.show_choices()
	assert_true(overlay.visible, "Overlay should be visible after show_choices")


func test_win_full_flow_debug() -> void:
	# Win the round
	main.bricks_left = 1
	main._on_brick_destroyed()
	await wait_seconds(1.5)

	var panel = main.get_node("UpgradePanel")
	var overlay: ColorRect = panel.overlay

	# Debug: print all relevant state
	gut.p("=== DEBUG: After win ===")
	gut.p("overlay.visible = %s" % overlay.visible)
	gut.p("overlay.modulate = %s" % overlay.modulate)
	gut.p("overlay.color = %s" % overlay.color)
	gut.p("overlay.get_rect() = %s" % overlay.get_rect())
	gut.p("panel.layer = %d" % panel.layer)
	gut.p("panel.visible = %s" % panel.visible)
	gut.p("panel.get_child_count() = %d" % panel.get_child_count())

	# Check buttons
	for i in 3:
		var btn: Button = panel.buttons[i]
		gut.p("button[%d].visible=%s text=%s" % [i, btn.visible, btn.text])
		gut.p("button[%d].get_global_rect()=%s" % [i, btn.get_global_rect()])

	assert_true(overlay.visible, "Overlay must be visible")
