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
@onready var menu_button: Button = $HUD/MenuButton

var lives: int = START_LIVES
var score: int = 0
var bricks_left: int = 0
var game_over: bool = false
var paused: bool = false

# Combo system (D011)
var combo: int = 0
var max_combo: int = 0
var lives_lost_this_level: int = 0

# Ball stick state (D012): ball waits on paddle until player launches
var ball_stuck: bool = true


func _ready() -> void:
	paddle.bounds = playfield
	ball.bounds = playfield
	_spawn_bricks()
	_reset_ball()
	_update_hud()


func _input(event: InputEvent) -> void:
	if game_over:
		return
	# Launch ball (D012)
	if ball_stuck and (event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed)):
		_launch_ball()
	# Pause (D012)
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()


func _toggle_pause() -> void:
	paused = !paused
	if paused:
		message.text = "PAUSED"
		message.show()
	else:
		message.hide()


func _launch_ball() -> void:
	ball_stuck = false
	var angle: float = randf_range(-PI / 4.0, PI / 4.0) - PI / 2.0
	ball.launch(Vector2(cos(angle), sin(angle)))


func _process(_delta: float) -> void:
	# Keep ball on paddle while stuck
	if ball_stuck and not paused:
		ball.position = Vector2(paddle.position.x, PADDLE_Y - 40.0)


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
	ball_stuck = true
	# Reset combo on ball loss (D011)
	combo = 0
	_update_hud()


func _on_brick_destroyed() -> void:
	# Combo system (D011): +1 per brick, reset on paddle hit
	combo += 1
	max_combo = maxi(max_combo, combo)
	# Score scales with combo
	score += 10 * (1 + combo / 5)
	bricks_left -= 1
	_update_hud()
	if bricks_left <= 0:
		_win()


func _on_paddle_hit() -> void:
	# Combo reset on paddle contact (D011)
	combo = 0
	_update_hud()


func _on_ball_lost() -> void:
	if game_over:
		return
	lives -= 1
	lives_lost_this_level += 1
	_update_hud()
	if lives <= 0:
		_lose()
	else:
		_reset_ball()


func _win() -> void:
	game_over = true
	var stars := _compute_stars()
	message.text = "YOU WIN! %s" % stars
	message.show()
	restart_button.show()
	menu_button.show()


func _compute_stars() -> String:
	# D013: 3-star rating
	var count: int = 1  # 1 star for clearing
	if max_combo >= 10:
		count += 1
	if lives_lost_this_level == 0:
		count += 1
	var s := ""
	for i in count:
		s += "*"
	return s


func _lose() -> void:
	game_over = true
	message.text = "GAME OVER"
	message.show()
	restart_button.show()
	menu_button.show()


func _update_hud() -> void:
	score_label.text = "Score: %d" % score
	lives_label.text = "Lives: %d" % lives
	if combo > 0:
		score_label.text += "  Combo: x%d" % combo


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/menu.tscn")
