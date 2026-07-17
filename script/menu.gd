extends Control
## Main menu — title screen with Start and Quit buttons.

signal start_pressed


func _ready() -> void:
	get_tree().root.go_back_requested.connect(_on_go_back_requested)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_go_back_requested() -> void:
	get_tree().quit()
