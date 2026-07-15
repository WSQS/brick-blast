extends Node2D
## Main — orchestrates the game: spawns bricks, manages score, win/lose state.

const UpgradeScript = preload("res://script/upgrade.gd")

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
const BALL_OFFSET: float = 40.0
const START_LIVES: int = 3

@export var brick_scene: PackedScene
@export var ball_scene: PackedScene

@onready var playfield: Rect2 = _compute_playfield()
@onready var ball: CharacterBody2D = $Ball
@onready var paddle: StaticBody2D = $Paddle
@onready var bricks: Node2D = $Bricks
@onready var score_label: Label = $HUD/ScoreLabel
@onready var lives_label: Label = $HUD/LivesLabel
@onready var message: Label = $HUD/Message
@onready var restart_button: Button = $HUD/RestartButton
@onready var menu_button: Button = $HUD/MenuButton
@onready var upgrade_panel = $UpgradePanel

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

# Upgrade state (D014)
var upgrades: Dictionary = {}  # UpgradeScript.Type -> count
var rounds_cleared: int = 0
var extra_balls: Array[CharacterBody2D] = []  # Multi-ball upgrade (D014)


func _ready() -> void:
	paddle.bounds = playfield
	ball.bounds = playfield
	if upgrade_panel and upgrade_panel.has_signal("upgrade_selected"):
		upgrade_panel.upgrade_selected.connect(_on_upgrade_selected)
	_spawn_bricks()
	_reset_round()
	_update_hud()


func _input(event: InputEvent) -> void:
	if game_over:
		return
	# Launch ball (D012) — only when not paused
	if not paused and ball_stuck and (event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed)):
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
	# Launch any extra balls with different angles (D014)
	for extra in extra_balls:
		if is_instance_valid(extra):
			var ext_angle: float = randf_range(-PI / 4.0, PI / 4.0) - PI / 2.0
			extra.launch(Vector2(cos(ext_angle), sin(ext_angle)))


func _launch_extra_ball(extra: CharacterBody2D) -> void:
	# Position at paddle and launch immediately
	extra.position = Vector2(paddle.position.x, PADDLE_Y - BALL_OFFSET)
	var angle: float = randf_range(-PI / 4.0, PI / 4.0) - PI / 2.0
	extra.launch(Vector2(cos(angle), sin(angle)))


func _process(_delta: float) -> void:
	# Keep ball on paddle while stuck
	if ball_stuck and not paused:
		ball.position = Vector2(paddle.position.x, PADDLE_Y - BALL_OFFSET)


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


func _reset_round() -> void:
	ball.position = Vector2(playfield.size.x / 2.0, PADDLE_Y - BALL_OFFSET)
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
		_reset_round()


func _win() -> void:
	rounds_cleared += 1
	# Stop ball immediately
	ball_stuck = true
	ball.velocity = Vector2.ZERO
	var star_count := _compute_stars()
	var star_str := ""
	for i in star_count:
		star_str += "*"
	message.text = "ROUND CLEAR! %s" % star_str
	message.show()
	# Show upgrade choices (D014)
	await get_tree().create_timer(1.0).timeout
	message.hide()
	upgrade_panel.show_choices()


func _compute_stars() -> int:
	# D013: 3-star rating
	var count: int = 1  # 1 star for clearing
	if max_combo >= 10:
		count += 1
	if lives_lost_this_level == 0:
		count += 1
	return count


func _lose() -> void:
	_end_game("GAME OVER")


func _end_game(text: String) -> void:
	game_over = true
	message.text = text
	message.show()
	restart_button.show()
	menu_button.show()


func _on_upgrade_selected(upgrade) -> void:
	upgrades[upgrade.id] = upgrades.get(upgrade.id, 0) + 1
	_apply_upgrade(upgrade.id)
	_start_next_round()


func _apply_upgrade(id: int) -> void:
	match id:
		UpgradeScript.Type.PADDLE_WIDE:
			var shape: RectangleShape2D = paddle.get_node("CollisionShape2D").shape
			shape.size.x *= 1.5
		UpgradeScript.Type.SLOW_BALL:
			ball._speed *= 0.8
		UpgradeScript.Type.EXTRA_LIFE:
			lives += 1
		UpgradeScript.Type.MULTI_BALL:
			if ball_scene:
				var new_ball: CharacterBody2D = ball_scene.instantiate()
				new_ball.bounds = playfield
				new_ball._speed = ball._speed
				new_ball.pierce_count = ball.pierce_count
				add_child(new_ball)
				extra_balls.append(new_ball)
				_launch_extra_ball(new_ball)
		UpgradeScript.Type.PIERCE:
			ball.pierce_count += 3


func _start_next_round() -> void:
	# Clear extra balls from previous round
	for extra in extra_balls:
		if is_instance_valid(extra):
			extra.queue_free()
	extra_balls.clear()
	# Reset per-round state but keep upgrades
	bricks_left = 0
	_spawn_bricks()
	_reset_round()
	lives_lost_this_level = 0
	max_combo = 0
	_update_hud()


func _update_hud() -> void:
	score_label.text = "Score: %d" % score
	lives_label.text = "Lives: %d" % lives
	if combo > 0:
		score_label.text += "  Combo: x%d" % combo


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/menu.tscn")
