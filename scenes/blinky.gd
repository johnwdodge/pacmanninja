extends CharacterBody3D

@onready var astar = get_parent().astar
@onready var player = $"../../charcontrol"
@onready var MOVE_TIME = get_parent().MOVE_TIME
@onready var movetimer = MOVE_TIME
var pointpath = []
var lastpoint = 0
var scatter = true
var scatterpath = []

func _process(delta: float) -> void:
	if get_parent().movetimer > 0:
		pass
	else:
		if get_parent().scatter:
			scatter = true
		if scatter:
			_handle_scatter(astar.get_closest_point(get_parent().altars.pick_random().global_position))
		else:
			_handle_ai_move(delta)
			

func _handle_scatter(point):
	var mypos = astar.get_closest_point(global_position)
	if not scatterpath:
		scatterpath = astar.get_id_path(mypos, point)
		scatterpath.remove_at(0)
		global_position = astar.get_point_position(scatterpath[0])
		scatterpath.remove_at(0)
	else:
		global_position = astar.get_point_position(scatterpath[0])
		scatterpath.remove_at(0)
		if scatterpath.size() < 3:
			scatterpath = []
			scatter = false
		
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
		if pointpath.size() > 1:
			astar.set_point_weight_scale(lastpoint, 1.0)
			lastpoint = mypos
			global_position = pointpath[1]
#			movetimer = MOVE_TIME
	else:
#		movetimer = MOVE_TIME
		pass
		
		
