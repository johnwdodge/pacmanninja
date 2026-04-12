extends CharacterBody3D
@onready var astar = get_parent().astar
@onready var ai = get_parent()
@onready var player = $"../../../charcontrol"
@onready var manager = $"../../../GameManager"
@onready var anim_player: AnimationPlayer = $Samurai_Animations/AnimationPlayer
@export var max_health: int = 1
@onready var collision_shape_3d: CollisionShape3D = $Samurai_Animations/Armature/Skeleton3D/Base_002/StaticBody3D/CollisionShape3D
var pointpath = []
var lastpoint = 0
var scatter = true
var scatterpath = []
var nextposition = Vector3.ZERO
var _health: int

func _ready() -> void:
	anim_player.play("Walking")
	_health = max_health

func take_damage() -> void:
	_health -= 1
	if _health <= 0:
		_die()

func _die() -> void:
	_play_anim("Death")
	set_process(false)
	collision_shape_3d.set_deferred("disabled", true)
	await anim_player.animation_finished
	queue_free()

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
		_play_anim("Walking")
		var next_pos = astar.get_point_position(scatterpath[0])
		_face_direction(global_position, next_pos)
		if ai.try_reserve(next_pos, self):
			nextposition = next_pos
		scatterpath.remove_at(0)
	else:
		var next_pos = astar.get_point_position(scatterpath[0])
		_face_direction(global_position, next_pos)
		if ai.try_reserve(next_pos, self):
			nextposition = next_pos
		scatterpath.remove_at(0)
		if scatterpath.size() < 3:
			scatterpath = []
			scatter = false

func _handle_ai_move(delta):
	var playerspot = player.global_position
	var playerbasis = (-player.basis.z.normalized()) * 24
	var playerpos = astar.get_closest_point(player.global_position)
	playerspot += playerbasis
	var playerlook = astar.get_closest_point(playerspot)
	var mypos = astar.get_closest_point(global_position)
	if astar.get_point_path(mypos, playerlook):
		astar.set_point_weight_scale(lastpoint, 8.0)
		pointpath = astar.get_point_path(mypos, playerlook)
		if pointpath.size() > 5:
			astar.set_point_weight_scale(lastpoint, 1.0)
			lastpoint = mypos
			var next_pos = pointpath[1]
			_face_direction(global_position, next_pos)
			if ai.try_reserve(next_pos, self):
				nextposition = next_pos
		else:
			pointpath = astar.get_point_path(mypos, playerpos)
			if pointpath.size() > 1:
				astar.set_point_weight_scale(lastpoint, 1.0)
				lastpoint = mypos
				var next_pos = pointpath[1]
				_face_direction(global_position, next_pos)
				if ai.try_reserve(next_pos, self):
					nextposition = next_pos

		if pointpath.size() <= 1:
			_play_anim("Attack")
		else:
			_play_anim("Walking")
	else:
		ai.try_reserve(mypos, self)

func _play_anim(anim_name: String) -> void:
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func _face_direction(from: Vector3, to: Vector3) -> void:
	var diff = to - from
	if diff.length() > 0.01:
		var angle = atan2(diff.x, diff.z)
		rotation.y = angle
