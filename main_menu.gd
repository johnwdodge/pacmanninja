# main_menu.gd
extends Node
var manager = null
@onready var _start_button: Button = $CanvasLayer/Button
@onready var options = $CanvasLayer/Button2
@onready var readme = $CanvasLayer/Button3
@onready var exit = $CanvasLayer/Button4
@onready var goback = $CanvasLayer/Button5
@onready var high_score = $CanvasLayer/HighScore


func _ready() -> void:
	manager = get_parent()
	if manager.current_level:
		goback.visible = true
	else: goback.visible = false
	if manager.max_score == 0:
		high_score.visible = false
	else:
		high_score.visible = true
		show_score()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start_button.pressed.connect(manager.level_select)
	options.pressed.connect(manager.open_options)
	exit.pressed.connect(get_tree().quit)
	goback.pressed.connect(manager.unpause)
	readme.pressed.connect(manager.open_readme)

func show_score():
	high_score.text = "HIGH SCORE: %d" % manager.max_score
