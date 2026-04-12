extends CharacterBody3D

@onready var astar = get_parent().astar
@onready var player = $"../../charcontrol"
@onready var MOVE_TIME = get_parent().MOVE_TIME
@onready var movetimer = MOVE_TIME
var pointpath = []
var lastpoint = 0

func _process(delta: float) -> void:
	_handle_ai_move(delta)

func _handle_ai_move(delta):
	if movetimer > 0:
		movetimer -= delta
	else:
		var playerpos = astar.get_closest_point(player.global_position)
		var mypos = astar.get_closest_point(global_position)
		var options = astar.get_point_connections(mypos)
		if options.size() == 2:
			for i in options:
				if i != lastpoint:
					global_position = astar.get_point_position(i)
					lastpoint = mypos
					movetimer = MOVE_TIME
					break
		elif astar.get_point_path(mypos, playerpos):
			astar.set_point_weight_scale(lastpoint, 100.0)
			pointpath = astar.get_point_path(mypos, playerpos)
			if pointpath.size() > 1:
				astar.set_point_weight_scale(lastpoint, 1.0)
				lastpoint = mypos
				global_position = pointpath[1]
				movetimer = MOVE_TIME
		else:
			movetimer = MOVE_TIME
		
		
