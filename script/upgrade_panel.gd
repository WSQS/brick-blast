extends CanvasLayer
## UpgradePanel — 3-choice upgrade selection UI shown after clearing all bricks.

signal upgrade_selected(upgrade: Upgrade)

const CHOICE_COUNT: int = 3
const BUTTON_MIN_SIZE: Vector2 = Vector2(280, 60)

@onready var overlay: ColorRect = $Overlay
@onready var vbox: VBoxContainer = $Overlay/CenterContainer/VBoxContainer

var buttons: Array[Button] = []


func _ready() -> void:
	_create_buttons()
	_hide_panel()


func _create_buttons() -> void:
	for i in CHOICE_COUNT:
		var btn: Button = Button.new()
		btn.custom_minimum_size = BUTTON_MIN_SIZE
		btn.pressed.connect(_on_choice_pressed.bind(i))
		vbox.add_child(btn)
		buttons.append(btn)


func show_choices() -> void:
	var choices: Array = Upgrade.random_choices(buttons.size())
	for i in choices.size():
		buttons[i].text = "%s\n%s" % [choices[i].display_name, choices[i].description]
		buttons[i].set_meta("upgrade", choices[i])
	_show_panel()


func _on_choice_pressed(index: int) -> void:
	if not visible:
		return
	var upgrade = buttons[index].get_meta("upgrade")
	_hide_panel()
	upgrade_selected.emit(upgrade)


func _show_panel() -> void:
	visible = true
	overlay.show()


func _hide_panel() -> void:
	overlay.hide()
	visible = false
