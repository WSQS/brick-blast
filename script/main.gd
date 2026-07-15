extends Node2D
## Main — orchestrates the game: spawns bricks, manages score, win/lose state.

const UpgradeScript = preload("res://script/upgrade.gd")

# Brick grid
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

# Paddle & ball
const PADDLE_Y: float = 660.0
const BALL_OFFSET: float = 40.0
const START_LIVES: int = 3
const PADDLE_WIDE_FACTOR: float = 1.5
const PADDLE_MAX_WIDTH_RATIO: float = 0.8
const STAR_COMBO_THRESHOLD: int = 10

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
@onready var upgrade_panel: CanvasLayer = $UpgradePanel

var lives: int = START_LIVES
var score: int = 0
var bricks_left: int = 0
var game_over: bool = false
var paused: bool = false

var combo: int = 0
var max_combo: int = 0
var lives_lost_this_level: int = 0

var ball_stuck: bool = true

var upgrades: Dictionary = {}  # UpgradeScript.Type -> stack count
var rounds_cleared: int = 0
var extra_balls: Array[CharacterBody2D] = []


func _ready() -> void:
	paddle.bounds = playfield
	ball.bounds = playfield
	if upgrade_panel and upgrade_panel.has_signal("upgrade_selected"):
		upgrade_panel.upgrade_selected.connect(_on_upgrade_selected)
	_spawn_bricks()
	_reset_round()
	_update_hud()


func _input(event: InputEvent) -> void:
	if game_over or upgrade_panel.visible:
		return
	if not paused and ball_stuck:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
			_launch_ball()
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
	_sync_pierce_count()
	ball.launch(_random_launch_dir())
	for extra in extra_balls:
		if is_instance_valid(extra):
			extra.launch(_random_launch_dir())


func _random_launch_dir() -> Vector2:
	var angle := randf_range(-PI / 4.0, PI / 4.0) - PI / 2.0
	return Vector2(cos(angle), sin(angle))


func _process(_delta: float) -> void:
	if not (ball_stuck and not paused):
		return
	var stick_pos := Vector2(paddle.position.x, PADDLE_Y - BALL_OFFSET)
	ball.position = stick_pos
	for extra in extra_balls:
		if is_instance_valid(extra):
			extra.position = stick_pos


func _compute_playfield() -> Rect2:
	var size := get_viewport_rect().size
	return Rect2(0, 0, size.x, size.y)


func _spawn_bricks() -> void:
	for brick in bricks.get_children():
		brick.queue_free()
	bricks_left = 0
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
	ball.is_active = true
	ball.position = Vector2(playfield.size.x / 2.0, PADDLE_Y - BALL_OFFSET)
	ball.velocity = Vector2.ZERO
	ball_stuck = true
	combo = 0
	_update_hud()


func _on_brick_destroyed() -> void:
	combo += 1
	max_combo = maxi(max_combo, combo)
	score += 10 * (1 + combo / 5)
	bricks_left -= 1
	_update_hud()
	if bricks_left <= 0:
		_win()


func _on_paddle_hit() -> void:
	combo = 0
	_sync_pierce_count()
	_update_hud()


## Sets ball.pierce_count from upgrades (called on launch and paddle hit)
func _sync_pierce_count() -> void:
	ball.pierce_count = upgrades.get(UpgradeScript.Type.PIERCE, 0) * 3


func _on_ball_lost() -> void:
	if game_over:
		return
	# Extra balls still alive — deactivate main ball. Only when all balls
	# are gone do we cost a life and reset.
	if extra_balls.size() > 0:
		ball.is_active = false
		return
	lives -= 1
	lives_lost_this_level += 1
	_update_hud()
	if lives <= 0:
		_game_over()
	else:
		_reset_round()


func _game_over() -> void:
	game_over = true
	message.text = "GAME OVER"
	message.show()
	restart_button.show()
	menu_button.show()


func _win() -> void:
	if upgrade_panel.visible:
		return
	rounds_cleared += 1
	ball_stuck = true
	ball.velocity = Vector2.ZERO
	var stars := "*".repeat(_compute_stars())
	message.text = "ROUND CLEAR! %s" % stars
	message.show()
	await get_tree().create_timer(1.0).timeout
	message.hide()
	upgrade_panel.show_choices()


func _compute_stars() -> int:
	var count := 1  # 1 star for clearing
	if max_combo >= STAR_COMBO_THRESHOLD:
		count += 1
	if lives_lost_this_level == 0:
		count += 1
	return count


func _on_upgrade_selected(upgrade) -> void:
	upgrades[upgrade.id] = upgrades.get(upgrade.id, 0) + 1
	_apply_upgrade(upgrade.id)
	_start_next_round()


func _apply_upgrade(id: int) -> void:
	match id:
		UpgradeScript.Type.PADDLE_WIDE:
			var shape: RectangleShape2D = paddle.get_node("CollisionShape2D").shape
			var max_w: float = playfield.size.x * PADDLE_MAX_WIDTH_RATIO
			var new_w: float = minf(shape.size.x * PADDLE_WIDE_FACTOR, max_w)
			shape.size.x = new_w
			if paddle.has_node("ColorRect"):
				var cr: ColorRect = paddle.get_node("ColorRect")
				cr.size.x = new_w
				cr.position.x = -new_w / 2.0
		UpgradeScript.Type.SLOW_BALL:
			ball.set_speed(ball.get_speed() * 0.8)
		UpgradeScript.Type.EXTRA_LIFE:
			lives += 1
		UpgradeScript.Type.MULTI_BALL:
			pass  # extra balls spawned in _start_next_round
		UpgradeScript.Type.PIERCE:
			pass  # pierce_count synced on launch / paddle hit


func _start_next_round() -> void:
	for extra in extra_balls:
		if is_instance_valid(extra):
			extra.queue_free()
	extra_balls.clear()
	_spawn_bricks()
	_reset_round()
	lives_lost_this_level = 0
	max_combo = 0
	var multi_count: int = upgrades.get(UpgradeScript.Type.MULTI_BALL, 0)
	for i in multi_count:
		_spawn_extra_ball()
	_update_hud()


func _spawn_extra_ball() -> void:
	if not ball_scene:
		return
	var new_ball: CharacterBody2D = ball_scene.instantiate()
	new_ball.bounds = playfield
	new_ball.set_speed(ball.get_speed())
	new_ball.pierce_count = ball.pierce_count
	new_ball.is_extra_ball = true
	add_child(new_ball)
	extra_balls.append(new_ball)
	new_ball.position = Vector2(paddle.position.x, PADDLE_Y - BALL_OFFSET)


func _update_hud() -> void:
	score_label.text = "Score: %d" % score
	lives_label.text = "Lives: %d" % lives
	if combo > 0:
		score_label.text += "  Combo: x%d" % combo


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/menu.tscn")
