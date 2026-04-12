extends CharacterBody3D

@onready var astar = get_parent().astar
@onready var player = $"../../../charcontrol"
@onready var manager = $"../../../GameManager"
@onready var anim_player: AnimationPlayer = $Samurai_Animations/AnimationPlayer

var pointpath = []
var lastpoint = 0
var scatter = true
var scatterpath = []
var nextposition = Vector3.ZERO

func _ready() -> void:
	anim_player.play("Walking")

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
	global_position = global_position.lerp(nextposition, .5)
	
	
func _handle_scatter(point):
	var mypos = astar.get_closest_point(global_position)
	if not scatterpath:
		scatterpath = astar.get_id_path(mypos, point)
		scatterpath.remove_at(0)
		_play_anim("Walking")
		var next_pos = astar.get_point_position(scatterpath[0])
		_face_direction(global_position, next_pos)
		nextposition = next_pos
		scatterpath.remove_at(0)
	else:
		var next_pos = astar.get_point_position(scatterpath[0])
		_face_direction(global_position, next_pos)
		nextposition = next_pos
		scatterpath.remove_at(0)
		if scatterpath.size() < 3:
			scatterpath = []
			scatter = false

func _handle_ai_move(delta):
	var active = manager._active_altar
	var playerpos = astar.get_closest_point(player.global_position)
	var mypos = astar.get_closest_point(global_position)
	var options = astar.get_point_connections(mypos)

	if options.size() == 2:
		for i in options:
			if i != lastpoint:
				_play_anim("Walking")
				var next_pos = astar.get_point_position(i)
				_face_direction(global_position, next_pos)
				nextposition = next_pos
				lastpoint = mypos
				break
	elif astar.get_point_path(mypos, playerpos):
		astar.set_point_weight_scale(lastpoint, 100.0)
		pointpath = astar.get_point_path(mypos, playerpos)
		if pointpath.size() > 12:
			pointpath = astar.get_point_path(mypos, astar.get_closest_point(active.global_position))
		if pointpath.size() > 1:
			astar.set_point_weight_scale(lastpoint, 1.0)
			lastpoint = mypos
			var next_pos = pointpath[1]
			_face_direction(global_position, next_pos)
			nextposition = next_pos
		else:
			pointpath = astar.get_point_path(mypos, playerpos)
			if pointpath.size() > 1:
				astar.set_point_weight_scale(lastpoint, 1.0)
				lastpoint = mypos
				var next_pos = pointpath[1]
				_face_direction(global_position, next_pos)
				nextposition = next_pos
				
		if pointpath.size() <= 3:
			_play_anim("Attack")
		else:
			_play_anim("Walking")
	else:
		pass

func die() -> void:
	_play_anim("Death")
	set_process(false)

func _play_anim(anim_name: String) -> void:
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func _face_direction(from: Vector3, to: Vector3) -> void:
	var diff = to - from
	if diff.length() > 0.01:
		var angle = atan2(diff.x, diff.z)
		rotation.y = angle
