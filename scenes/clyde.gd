extends CharacterBody3D

@onready var astar = get_parent().astar
@onready var player = $"../../charcontrol"
#@onready var MOVE_TIME = get_parent().movetimer
@onready var altars: Node3D = $"../../Altars"
@onready var pellet_altar: Node3D = $"../../Altars/Pellet_Altar"

var pointpath = []
var lastpoint = 0
var scatter = true

func _process(delta: float) -> void:
	if get_parent().movetimer > 0:
		pass
	else:
		_handle_ai_move(delta)

func _handle_ai_move(delta):

	var playerpos = astar.get_closest_point(player.global_position)
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
		if pointpath.size() < 8 and pointpath.size() > 3:
			pointpath = astar.get_point_path(mypos, astar.get_closest_point(pellet_altar.global_position))
		if pointpath.size() > 1:
			astar.set_point_weight_scale(lastpoint, 1.0)
			lastpoint = mypos
			global_position = pointpath[1]
#		movetimer = MOVE_TIME
	else:
		pass
#			movetimer = MOVE_TIME
		
		
