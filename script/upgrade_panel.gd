extends CanvasLayer
## UpgradePanel — 3-choice upgrade selection UI shown after clearing all bricks.

signal upgrade_selected(upgrade)

const CHOICE_COUNT: int = 3

@onready var overlay: ColorRect = $Overlay
@onready var buttons: Array[Button] = [
	$Overlay/CenterContainer/VBoxContainer/Choice0,
	$Overlay/CenterContainer/VBoxContainer/Choice1,
	$Overlay/CenterContainer/VBoxContainer/Choice2,
]


func _ready() -> void:
	for i in buttons.size():
		buttons[i].pressed.connect(_on_choice_pressed.bind(i))
	_hide_panel()


func show_choices() -> void:
	var choices: Array = Upgrade.random_choices(CHOICE_COUNT)
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
