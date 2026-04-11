extends CharacterBody3D

@onready var astar = get_parent().astar
@onready var player = $"../../charcontrol"
@onready var MOVE_TIME = get_parent().MOVE_TIME
@onready var spawn = $"../../Pellet_Altar"
@onready var movetimer = MOVE_TIME
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
			if pointpath.size() < 8 and pointpath.size() > 3:
				pointpath = astar.get_point_path(mypos, astar.get_closest_point(spawn.global_position))
			if pointpath.size() > 1:
				global_position = pointpath[1]
			movetimer = MOVE_TIME
		else:
			movetimer = MOVE_TIME
		
		
