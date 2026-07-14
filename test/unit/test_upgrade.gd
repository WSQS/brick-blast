extends GutTest
## Tests for upgrade system (D014).

const MainScene: PackedScene = preload("res://scene/main.tscn")

var main: Node2D


func before_each() -> void:
	main = MainScene.instantiate()
	add_child_autofree(main)


func test_upgrade_panel_hidden_on_ready() -> void:
	var panel = main.get_node_or_null("UpgradePanel")
	assert_not_null(panel, "UpgradePanel should exist")
	var overlay: ColorRect = panel.get_node_or_null("Overlay")
	assert_not_null(overlay, "Overlay should exist")
	assert_false(overlay.visible, "UpgradePanel overlay should be hidden on game start")


func test_upgrade_panel_overlay_hidden_on_ready() -> void:
	var overlay: ColorRect = main.get_node_or_null("UpgradePanel/Overlay")
	assert_not_null(overlay, "Overlay should exist")
	assert_false(overlay.visible, "Overlay should be hidden on game start")


func test_upgrade_panel_shown_after_win() -> void:
	# Clear all bricks to trigger _win
	main.bricks_left = 1
	main._on_brick_destroyed()
	await wait_seconds(1.5)
	var overlay: ColorRect = main.get_node("UpgradePanel/Overlay")
	assert_true(overlay.visible, "UpgradePanel should be shown after winning")
