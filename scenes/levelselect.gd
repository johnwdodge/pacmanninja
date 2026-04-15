extends Node

@onready var lvl1 = $CanvasLayer/Button
@onready var lvl2 = $CanvasLayer/Button2
@onready var back = $CanvasLayer/back
@onready var label = $Label
@onready var manager = get_tree().get_first_node_in_group("game_manager")
var level1 = "res://scenes/levels/level_2.tscn"
var level2 = preload("res://scenes/levels/Level_1.tscn")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if manager.max_score < 50:
		lvl2.visible = false
	else: label.visible = false
	lvl1.pressed.connect(lvl1launch)
	lvl2.pressed.connect(lvl2launch)
	back.pressed.connect(manager.open_main_menu)
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func lvl1launch():
	manager._load_level(preload("res://scenes/levels/level_2.tscn"))
	
func lvl2launch():
	manager._load_level(level2)
