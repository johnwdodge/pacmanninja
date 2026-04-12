extends CharacterBody3D

@onready var astar = get_parent().astar
@onready var player = $"../../charcontrol"
@onready var MOVE_TIME = get_parent().MOVE_TIME
@onready var movetimer = MOVE_TIME
var pointpath = []
var lastpoint = 0
var scatter = true

func _process(delta: float) -> void:
	if get_parent().movetimer > 0:
		pass
	else:
		_handle_ai_move(delta)

func _handle_ai_move(delta):
	var playerspot = player.global_position
	var playerbasis = (-player.basis.z.normalized()) * 18
	playerspot += playerbasis
	var playerpos = astar.get_closest_point(playerspot)
	var mypos = astar.get_closest_point(global_position)
	var options = astar.get_point_connections(mypos)
	if options.size() == 2:
		for i in options:
			if i != lastpoint:
				global_position = astar.get_point_position(i)
				lastpoint = mypos
#				movetimer = MOVE_TIME
				break
	elif astar.get_point_path(mypos, playerpos):
		astar.set_point_weight_scale(lastpoint, 100.0)
		pointpath = astar.get_point_path(mypos, playerpos)
		if pointpath.size() > 1:
			astar.set_point_weight_scale(lastpoint, 1.0)
			lastpoint = mypos
			global_position = pointpath[1]
#			movetimer = MOVE_TIME
		else:
			for i in options:
				if i != lastpoint:
					global_position = astar.get_point_position(i)
					lastpoint = mypos
#					movetimer = MOVE_TIME
					break
	else:
#		movetimer = MOVE_TIME
		pass
		
		
