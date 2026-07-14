extends Node2D
## Main — orchestrates the game: spawns bricks, manages score, win/lose state.

const COLS: int = 8
const ROWS: int = 5
const BRICK_W: float = 52.0
const BRICK_H: float = 22.0
const BRICK_GAP: float = 4.0
const BRICK_MARGIN_TOP: float = 80.0

const COLORS: Array[Color] = [
	Color("e94560"),
	Color("f5a623"),
	Color("16c79a"),
	Color("0f3460"),
	Color("7c3aed"),
]

const PADDLE_Y: float = 660.0
const START_LIVES: int = 3

@export var brick_scene: PackedScene

@onready var playfield: Rect2 = _compute_playfield()
@onready var ball: CharacterBody2D = $Ball
@onready var paddle: StaticBody2D = $Paddle
@onready var bricks: Node2D = $Bricks
@onready var score_label: Label = $HUD/ScoreLabel
@onready var lives_label: Label = $HUD/LivesLabel
@onready var message: Label = $HUD/Message
@onready var restart_button: Button = $HUD/RestartButton

var lives: int = START_LIVES
var score: int = 0
var bricks_left: int = 0
var game_over: bool = false


func _ready() -> void:
	paddle.bounds = playfield
	ball.bounds = playfield
	_spawn_bricks()
	_reset_ball()
	_update_hud()


func _compute_playfield() -> Rect2:
	var size := get_viewport_rect().size
	return Rect2(0, 0, size.x, size.y)


func _spawn_bricks() -> void:
	var total_w: float = COLS * BRICK_W + (COLS - 1) * BRICK_GAP
	var start_x: float = (playfield.size.x - total_w) / 2.0

	for row in range(ROWS):
		for col in range(COLS):
			var brick: StaticBody2D = brick_scene.instantiate()
			brick.color = COLORS[row % COLORS.size()]
			brick.position = Vector2(
				start_x + col * (BRICK_W + BRICK_GAP) + BRICK_W / 2.0,
				BRICK_MARGIN_TOP + row * (BRICK_H + BRICK_GAP) + BRICK_H / 2.0,
			)
			brick.add_to_group("brick")
			brick.destroyed.connect(_on_brick_destroyed)
			bricks.add_child(brick)
			bricks_left += 1


func _reset_ball() -> void:
	ball.position = Vector2(playfield.size.x / 2.0, PADDLE_Y - 40.0)
	ball.velocity = Vector2.ZERO
	var angle: float = randf_range(-PI / 4.0, PI / 4.0) - PI / 2.0
	ball.launch(Vector2(cos(angle), sin(angle)))


func _on_brick_destroyed() -> void:
	score += 10
	bricks_left -= 1
	_update_hud()
	if bricks_left <= 0:
		_win()


func _on_ball_lost() -> void:
	if game_over:
		return
	lives -= 1
	_update_hud()
	if lives <= 0:
		_lose()
	else:
		_reset_ball()


func _win() -> void:
	game_over = true
	message.text = "YOU WIN!"
	message.show()
	restart_button.show()


func _lose() -> void:
	game_over = true
	message.text = "GAME OVER"
	message.show()
	restart_button.show()


func _update_hud() -> void:
	score_label.text = "Score: %d" % score
	lives_label.text = "Lives: %d" % lives


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
