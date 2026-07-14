extends GutTest
## Tests for game-over state: ball lost should not keep decrementing lives.

const MainScene: PackedScene = preload("res://scene/main.tscn")

var main: Node2D


func before_each() -> void:
	main = MainScene.instantiate()
	add_child_autofree(main)


## Reproduces: after game over, _on_ball_lost keeps firing and lives
## keeps decrementing into negative numbers.
func test_lives_do_not_decrease_after_game_over() -> void:
	# Force game over by calling _on_ball_lost enough times
	main.lives = 1
	main._on_ball_lost()  # lives -> 0, triggers _lose()
	assert_eq(main.lives, 0, "Lives should be 0 after last ball lost")

	# Simulate ball continuing to fall and calling _on_ball_lost again
	main._on_ball_lost()
	main._on_ball_lost()
	main._on_ball_lost()

	assert_eq(main.lives, 0, "Lives should stay at 0 after game over, not go negative")
