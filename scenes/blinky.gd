extends CharacterBody3D

@onready var astar = get_parent().astar
@onready var player = $"../../../charcontrol"
@onready var ai = get_parent()
@onready var MOVE_TIME = get_parent().MOVE_TIME
@onready var movetimer = MOVE_TIME
var pointpath = []
var lastpoint = 0
var scatter = true
var scatterpath = []
var nextposition = Vector3.ZERO

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
	global_position = global_position.lerp(nextposition, .1)
			

func _handle_scatter(point):
	var mypos = astar.get_closest_point(global_position)
	if not scatterpath:
		scatterpath = astar.get_id_path(mypos, point)
		if scatterpath.size() > 1:
			scatterpath.remove_at(0)
		if ai.try_reserve(astar.get_point_position(scatterpath[0]), self):
				nextposition = astar.get_point_position(scatterpath[0])
		scatterpath.remove_at(0)
	else:
		if ai.try_reserve(astar.get_point_position(scatterpath[0]), self):
				nextposition = astar.get_point_position(scatterpath[0])
		scatterpath.remove_at(0)
		if scatterpath.size() < 3:
			scatterpath = []
			scatter = false
		
func _handle_ai_move(delta):
	var playerpos = astar.get_closest_point(player.global_position)
	var mypos = astar.get_closest_point(global_position)
	if astar.get_point_path(mypos, playerpos):
		astar.set_point_weight_scale(lastpoint, 8.0)
		pointpath = astar.get_point_path(mypos, playerpos)
		if pointpath.size() > 1:
			astar.set_point_weight_scale(lastpoint, 1.0)
			lastpoint = mypos
			if ai.try_reserve(pointpath[1], self):
				nextposition = pointpath[1]
#			movetimer = MOVE_TIME
	else:
		ai.try_reserve(mypos, self)
		
		
