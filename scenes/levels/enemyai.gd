extends CharacterBody3D

var astar = get_parent().astar
@onready var player = $"../../charcontrol"


func _process(delta: float) -> void:
	

func _handle_ai_move(delta):
	if movetimer > 0:
		movetimer -= delta
	else:
		var playerpos = astar.get_closest_point(player.global_position)
		var mypos = astar.getclosest_point(global_position)
		var nextpoint = astar.get_point_path(mypos, playerpos)[1]
		
		
