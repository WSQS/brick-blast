extends Node2D
## Main — orchestrates the game: spawns bricks, manages score, win/lose state.

## Upgrade types are accessed via the global Upgrade class (class_name Upgrade).

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
const BALL_SPEED: float = 320.0
const BALL_MAX_SPEED: float = 550.0
const BALL_SPEEDUP: float = 1.03

@export var brick_scene: PackedScene
@export var ball_scene: PackedScene

@onready var playfield: Rect2 = _compute_playfield()
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

var combo: int = 0
var max_combo: int = 0
var lives_lost_this_level: int = 0

var upgrades: Dictionary = {}  # Upgrade.Type -> stack count
var rounds_cleared: int = 0
var balls: Array[CharacterBody2D] = []
var ball_speed: float = BALL_SPEED

enum State { READY, PLAYING, PAUSED, ROUND_CLEAR, GAME_OVER }
var state: State = State.READY
var _state_before_pause: State = State.READY


func _ready() -> void:
	paddle.bounds = playfield
	if upgrade_panel and upgrade_panel.has_signal("upgrade_selected"):
		upgrade_panel.upgrade_selected.connect(_on_upgrade_selected)
	_spawn_ball()
	_spawn_bricks()
	_reset_round()
	state = State.READY


func _input(event: InputEvent) -> void:
	if state == State.GAME_OVER or state == State.ROUND_CLEAR:
		return
	if state == State.READY:
		if (
			event.is_action_pressed("ui_accept")
			or (event is InputEventMouseButton and event.pressed)
		):
			state = State.PLAYING
			_launch_ball()
	if event.is_action_pressed("ui_cancel"):
		if state == State.PAUSED:
			state = _state_before_pause
			message.hide()
		elif state != State.GAME_OVER:
			_state_before_pause = state
			state = State.PAUSED
			message.text = "PAUSED"
			message.show()


## Returns true when the game is actively playing (ball in motion).
func is_playing() -> bool:
	return state == State.PLAYING


## Returns true when the game is paused.
func is_paused() -> bool:
	return state == State.PAUSED


## Connects hit_paddle and lost signals for a ball.
func _connect_ball_signals(b: CharacterBody2D) -> void:
	b.hit_paddle.connect(_on_paddle_hit)
	b.lost.connect(_on_ball_lost)


func _launch_ball() -> void:
	for b in balls:
		_sync_pierce_count(b)
		b.launch(_random_launch_dir())


func _random_launch_dir() -> Vector2:
	var angle := randf_range(-PI / 4.0, PI / 4.0) - PI / 2.0
	return Vector2(cos(angle), sin(angle))


func _process(_delta: float) -> void:
	if state != State.READY:
		return
	var stick_pos := Vector2(paddle.position.x, PADDLE_Y - BALL_OFFSET)
	for b in balls:
		b.position = stick_pos


func _compute_playfield() -> Rect2:
	var size := get_viewport_rect().size
	return Rect2(0, 0, size.x, size.y)


func _spawn_bricks() -> void:
	for brick: Node in bricks.get_children():
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
	for b in balls:
		b.position = Vector2(playfield.size.x / 2.0, PADDLE_Y - BALL_OFFSET)
		b.velocity = Vector2.ZERO
	combo = 0
	_update_hud()


func _on_brick_destroyed() -> void:
	combo += 1
	max_combo = maxi(max_combo, combo)
	score += 10 * (1 + combo / 5)
	bricks_left -= 1
	_update_hud()
	if bricks_left <= 0:
		state = State.ROUND_CLEAR
		_win()


func _on_paddle_hit(hit_ball: CharacterBody2D) -> void:
	combo = 0
	ball_speed = minf(ball_speed * BALL_SPEEDUP, BALL_MAX_SPEED)
	hit_ball.speed = ball_speed
	hit_ball.velocity = hit_ball.velocity.normalized() * ball_speed
	_sync_pierce_count(hit_ball)
	_update_hud()


## Sets pierce_count on a specific ball from the upgrade stack.
func _sync_pierce_count(target: CharacterBody2D) -> void:
	target.pierce_count = upgrades.get(Upgrade.Type.PIERCE, 0) * 3


func _on_ball_lost(lost_ball: CharacterBody2D) -> void:
	if state == State.GAME_OVER:
		return
	balls.erase(lost_ball)
	lost_ball.queue_free()
	# Still have balls in play — no life lost
	if balls.size() > 0:
		return
	lives -= 1
	lives_lost_this_level += 1
	if lives <= 0:
		state = State.GAME_OVER
		_game_over()
		_update_hud()
	else:
		_spawn_ball()
		_reset_round()
		state = State.READY


func _game_over() -> void:
	message.text = "GAME OVER"
	message.show()
	restart_button.show()
	menu_button.show()


func _win() -> void:
	rounds_cleared += 1
	for b in balls:
		b.velocity = Vector2.ZERO
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


func _on_upgrade_selected(upgrade: Upgrade) -> void:
	upgrades[upgrade.id] = upgrades.get(upgrade.id, 0) + 1
	_apply_upgrade(upgrade.id)
	_start_next_round()


func _apply_upgrade(id: Upgrade.Type) -> void:
	match id:
		Upgrade.Type.PADDLE_WIDE:
			var shape: RectangleShape2D = paddle.get_node("CollisionShape2D").shape
			var max_w: float = playfield.size.x * PADDLE_MAX_WIDTH_RATIO
			var new_w: float = minf(shape.size.x * PADDLE_WIDE_FACTOR, max_w)
			shape.size.x = new_w
			if paddle.has_node("ColorRect"):
				var cr: ColorRect = paddle.get_node("ColorRect")
				cr.size.x = new_w
				cr.position.x = -new_w / 2.0
		Upgrade.Type.SLOW_BALL:
			ball_speed *= 0.8
			for b in balls:
				b.speed = ball_speed
		Upgrade.Type.EXTRA_LIFE:
			lives += 1
		Upgrade.Type.MULTI_BALL:
			pass  # extra balls spawned in _start_next_round
		Upgrade.Type.PIERCE:
			pass  # pierce_count synced on launch / paddle hit


func _start_next_round() -> void:
	# Clear all balls, then respawn fresh
	for b in balls:
		b.queue_free()
	balls.clear()
	_spawn_ball()
	_spawn_bricks()
	_reset_round()
	state = State.READY
	lives_lost_this_level = 0
	max_combo = 0
	var multi_count: int = upgrades.get(Upgrade.Type.MULTI_BALL, 0)
	for i in multi_count:
		_spawn_ball()


func _spawn_ball() -> void:
	if not ball_scene:
		return
	var new_ball: CharacterBody2D = ball_scene.instantiate()
	new_ball.bounds = playfield
	new_ball.speed = ball_speed
	add_child(new_ball)
	_connect_ball_signals(new_ball)
	balls.append(new_ball)
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
