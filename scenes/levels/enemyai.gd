extends CharacterBody3D

@onready var astar = get_parent().astar
@onready var player = $"../../charcontrol"
const MOVE_TIME = 0.5
var movetimer = MOVE_TIME
var pointpath = []

func _process(delta: float) -> void:
	_handle_ai_move(delta)

func _handle_ai_move(delta):
	if movetimer > 0:
		movetimer -= delta
	else:
		var playerpos = astar.get_closest_point(player.global_position)
		var mypos = astar.get_closest_point(global_position)
		
		if astar.get_point_path(mypos, playerpos):
			pointpath = astar.get_point_path(mypos, playerpos)
			if pointpath.size() > 1:
				global_position = pointpath[1]
			movetimer = MOVE_TIME
		
		
