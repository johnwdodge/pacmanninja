extends Node3D

@onready var manager = get_tree().get_first_node_in_group("game_manager")

var timer = 20
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("player")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timer > 0:
		timer -= delta
	else:
		global_position = manager.altars.pick_random().global_position
		timer = 20
	pass
