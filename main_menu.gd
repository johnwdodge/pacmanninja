# main_menu.gd
extends Node
@onready var _start_button: Button = $CanvasLayer/Button

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start_button.pressed.connect(_on_start_pressed)
	
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_2.tscn")
