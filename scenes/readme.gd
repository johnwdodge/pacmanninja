extends Node

@onready var return_button: Button = $CanvasLayer/Button5

func _ready() -> void:
	var manager = get_parent()
	return_button.pressed.connect(manager.open_main_menu)
