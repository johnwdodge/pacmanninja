# main_menu.gd
extends Node
@onready var manager = get_tree().get_first_node_in_group("game_manager")
@onready var _start_button: Button = $CanvasLayer/Button
@onready var options = $CanvasLayer/Button2
@onready var readme = $CanvasLayer/Button3
@onready var exit = $CanvasLayer/Button4

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start_button.pressed.connect(manager.level_select)
	options.pressed.connect(manager.open_options)
	exit.pressed.connect(get_tree().quit)
