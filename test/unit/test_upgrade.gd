extends GutTest
## Tests for upgrade system (D014).

const Upgrade = preload("res://script/upgrade.gd")

const MainScene: PackedScene = preload("res://scene/main.tscn")

var main: Node2D


func before_each() -> void:
	main = MainScene.instantiate()
	add_child_autofree(main)
	# GUT viewport is tiny (64x64); set realistic playfield for physics tests
	main.playfield = Rect2(0, 0, 480, 720)
	for b in main.balls:
		b.bounds = main.playfield


func _get_ball() -> CharacterBody2D:
	return main.balls[0]


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
	var ball := _get_ball()
	main.state = main.State.PLAYING
	ball.velocity = Vector2(100, 100)
	main.bricks_left = 1
	main._on_brick_destroyed()
	assert_eq(main.state, main.State.ROUND_CLEAR, "State should be ROUND_CLEAR after win")
	assert_eq(ball.velocity, Vector2.ZERO, "Ball velocity should be zero after win")


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
	# When win happens, ball should be stopped (waiting for upgrade)
	main.bricks_left = 1
	main.state = main.State.PLAYING
	main._on_brick_destroyed()
	await wait_seconds(1.5)
	# Game should be in ROUND_CLEAR state waiting for upgrade selection
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

	# Ball should be stuck (READY for next round)
	assert_eq(main.state, main.State.READY, "Ball should be READY for next round")


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


# ---------------------------------------------------------------------------
# Piercing upgrade tests (D014)
# ---------------------------------------------------------------------------


func test_pierce_upgrade_adds_pierce_count() -> void:
	var ball := _get_ball()
	assert_eq(ball.pierce_count, 0, "Ball should start with 0 pierce")
	main.upgrades[Upgrade.Type.PIERCE] = 1
	main._sync_pierce_count(ball)
	assert_eq(ball.pierce_count, 3, "Ball should have 3 pierce after upgrade")


func test_pierce_upgrade_stacks() -> void:
	var ball := _get_ball()
	main.upgrades[Upgrade.Type.PIERCE] = 2
	main._sync_pierce_count(ball)
	assert_eq(ball.pierce_count, 6, "Pierce should stack to 6")


func test_pierce_zero_means_normal_bounce() -> void:
	var ball := _get_ball()
	assert_eq(ball.pierce_count, 0, "No pierce by default")


func test_pierce_resets_on_paddle_hit() -> void:
	var ball := _get_ball()
	main.upgrades[Upgrade.Type.PIERCE] = 1
	main._sync_pierce_count(ball)
	assert_eq(ball.pierce_count, 3, "Should have 3 pierce after upgrade")
	# Consume 2 pierce charges
	ball.pierce_count = 1
	main._on_paddle_hit(ball)
	assert_eq(ball.pierce_count, 3, "Pierce should reset to full on paddle hit")


func test_pierce_resets_on_paddle_hit_with_multiple_upgrades() -> void:
	var ball := _get_ball()
	main.upgrades[Upgrade.Type.PIERCE] = 2
	main._sync_pierce_count(ball)
	ball.pierce_count = 1
	main._on_paddle_hit(ball)
	assert_eq(ball.pierce_count, 6, "Pierce should reset to 6 (2 upgrades * 3)")


func test_pierce_stays_zero_on_paddle_hit_without_upgrade() -> void:
	var ball := _get_ball()
	main._on_paddle_hit(ball)
	assert_eq(ball.pierce_count, 0, "Pierce should remain 0 without upgrade")


# ---------------------------------------------------------------------------
# Multi-ball upgrade tests (D014)
# ---------------------------------------------------------------------------


func test_multi_ball_creates_extra_ball() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	# 1 original + 1 from multi-ball = 2 total
	assert_eq(main.balls.size(), 2, "Should have 2 balls (1 original + 1 extra)")


func test_multi_ball_extra_is_valid_node() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	assert_true(is_instance_valid(main.balls[1]), "Extra ball should be valid")


func test_multi_ball_extra_has_velocity() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	main.state = main.State.PLAYING
	main._launch_ball()
	await wait_seconds(0.1)
	assert_gt(main.balls.size(), 1, "Extra ball should still exist after launch")
	if main.balls.size() > 1:
		var extra: CharacterBody2D = main.balls[1]
		assert_true(extra.velocity != Vector2.ZERO, "Extra ball should have velocity after launch")


func test_start_next_round_clears_extra_balls() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	assert_eq(main.balls.size(), 2, "Should have 2 balls")
	# Start another round — old extra balls cleared, new one spawned (persistent)
	main._start_next_round()
	assert_eq(main.balls.size(), 2, "Extra ball persists across rounds")


func test_extra_ball_follows_paddle_while_stuck() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	assert_eq(main.state, main.State.READY, "Ball should be READY after round start")
	var extra: CharacterBody2D = main.balls[1]
	# Move paddle to a new position
	main.paddle.position.x = 300.0
	# Run _process to sync ball positions
	main._process(0.016)
	# Both balls should be at paddle x
	var expected_x: float = main.paddle.position.x
	var ball0: CharacterBody2D = main.balls[0]
	assert_eq(round(ball0.position.x), round(expected_x), "First ball follows paddle")
	assert_eq(
		round(extra.position.x),
		round(expected_x),
		"Extra ball should also follow paddle while stuck"
	)


# ---------------------------------------------------------------------------
# Bug reproduction tests
# ---------------------------------------------------------------------------


func test_multi_ball_not_destroyed_by_next_round() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	assert_eq(main.balls.size(), 2, "Multi-ball should spawn in _start_next_round")


# ---------------------------------------------------------------------------
# Multi-ball design rules (D014):
# 1. All balls are equal — losing any ball while others remain = no life cost
# 2. Extra balls persist — respawned every round as long as upgrade is owned
# 3. Losing a ball doesn't reduce ball count next round
# ---------------------------------------------------------------------------


func test_multi_ball_persists_across_rounds() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	assert_eq(main.balls.size(), 2, "Should have 2 balls in first round")
	main._start_next_round()
	assert_eq(main.balls.size(), 2, "Extra ball should persist across rounds")


func test_multi_ball_persists_after_losing_extra_ball() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	main.state = main.State.PLAYING
	var extra: CharacterBody2D = main.balls[1]
	extra.force_update_transform()
	extra.global_position.y = main.playfield.end.y + 100
	extra._physics_process(0.016)
	assert_eq(main.balls.size(), 1, "Extra ball removed after falling")
	# Next round — extra ball should come back
	main._start_next_round()
	assert_eq(main.balls.size(), 2, "Extra ball should respawn next round")


func test_ball_lost_does_not_cost_life_with_others_present() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	main.state = main.State.PLAYING
	var extra: CharacterBody2D = main.balls[1]
	var lives_before: int = main.lives
	extra.force_update_transform()
	extra.global_position.y = main.playfield.end.y + 100
	extra._physics_process(0.016)
	assert_eq(main.lives, lives_before, "Losing one ball while another remains = no life cost")


func test_first_ball_lost_no_life_cost_with_others_present() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	main.state = main.State.PLAYING
	var lives_before: int = main.lives
	var ball0: CharacterBody2D = main.balls[0]
	ball0.force_update_transform()
	ball0.global_position.y = main.playfield.end.y + 100
	ball0._physics_process(0.016)
	assert_eq(main.lives, lives_before, "Losing first ball while another alive = no life cost")


func test_other_ball_keeps_moving_after_one_lost() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	main.state = main.State.PLAYING
	var ball0: CharacterBody2D = main.balls[0]
	var extra: CharacterBody2D = main.balls[1]
	var extra_vel_before: Vector2 = extra.velocity
	ball0.force_update_transform()
	ball0.global_position.y = main.playfield.end.y + 100
	ball0._physics_process(0.016)
	assert_ne(main.state, main.State.READY, "State should NOT be READY while another ball is alive")
	assert_eq(extra.velocity, extra_vel_before, "Remaining ball velocity should be unchanged")


func test_all_balls_lost_costs_life() -> void:
	main.upgrades[Upgrade.Type.MULTI_BALL] = 1
	main._start_next_round()
	main.state = main.State.PLAYING
	var lives_before: int = main.lives
	# Lose one ball first
	var ball0: CharacterBody2D = main.balls[0]
	ball0.force_update_transform()
	ball0.global_position.y = main.playfield.end.y + 100
	ball0._physics_process(0.016)
	assert_eq(main.lives, lives_before, "Losing one: another still alive, no life cost")
	# Now lose the last ball — all balls gone → life cost
	var last_ball: CharacterBody2D = main.balls[0]
	last_ball.force_update_transform()
	last_ball.global_position.y = main.playfield.end.y + 100
	last_ball._physics_process(0.016)
	assert_eq(main.lives, lives_before - 1, "All balls gone → lose a life")


func test_paddle_wide_updates_visual_rect() -> void:
	# Ensure playfield is wide enough for paddle to widen (test env may be small)
	main.playfield = Rect2(0, 0, 480, 720)
	var paddle = main.paddle
	var color_rect: ColorRect = paddle.get_node_or_null("ColorRect")
	assert_not_null(color_rect, "Paddle should have ColorRect")
	var collision_shape: CollisionShape2D = paddle.get_node("CollisionShape2D")
	# Reset to known baseline to avoid shared resource state across tests
	collision_shape.shape.size.x = 96.0
	if paddle.has_node("ColorRect"):
		var cr0: ColorRect = paddle.get_node("ColorRect")
		cr0.size.x = 96.0
		cr0.position.x = -48.0
	main._apply_upgrade(Upgrade.Type.PADDLE_WIDE)
	# Both collision and visual should be 96 * 1.5 = 144 (well under 80% cap)
	assert_almost_eq(collision_shape.shape.size.x, 144.0, 0.01, "Collision shape should widen")
	assert_almost_eq(color_rect.size.x, 144.0, 0.01, "ColorRect should also widen")


func test_paddle_wide_has_max_limit() -> void:
	# Selecting PADDLE_WIDE many times should cap at screen width
	main.playfield = Rect2(0, 0, 480, 720)
	var collision_shape: CollisionShape2D = main.paddle.get_node("CollisionShape2D")
	# Apply 10 times — way more than needed to exceed screen
	for i in 10:
		main._apply_upgrade(Upgrade.Type.PADDLE_WIDE)
	var final_w: float = collision_shape.shape.size.x
	assert_true(
		final_w <= main.playfield.size.x,
		"Paddle width (%f) should not exceed screen width (%f)" % [final_w, main.playfield.size.x]
	)


func test_upgrade_panel_click_does_not_launch_ball() -> void:
	# Win the round to show upgrade panel
	main.bricks_left = 1
	main._on_brick_destroyed()
	await wait_seconds(1.5)
	# Panel is shown, state is ROUND_CLEAR
	assert_eq(
		main.state, main.State.ROUND_CLEAR, "State should be ROUND_CLEAR while panel is shown"
	)
	# Simulate a mouse click (as if clicking a button)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	main._input(click)
	assert_eq(
		main.state,
		main.State.ROUND_CLEAR,
		"State should still be ROUND_CLEAR — click must not launch ball"
	)


# Helper
func _make_upgrade(type: int) -> Upgrade:
	var u := Upgrade.new()
	u.id = type
	u.display_name = "Test"
	u.description = "Test"
	return u
