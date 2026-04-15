# menu_blinky.gd
extends CharacterBody3D

@onready var anim_player: AnimationPlayer = $Samurai_Animations/AnimationPlayer

@export var walk_speed: float = 3.0

var _points: Array = []
var _current_index: int = 0

func _ready() -> void:
	for child in get_parent().get_children():
		if child is Marker3D:
			_points.append(child)
	anim_player.play("Walking")

func _process(delta: float) -> void:
	if _points.is_empty():
		return

	var target: Vector3 = _points[_current_index].global_position
	var diff: Vector3 = target - global_position
	diff.y = 0.0

	if diff.length() < 0.2:
		_current_index = (_current_index + 1) % _points.size()
	else:
		global_position += diff.normalized() * walk_speed * delta
		rotation.y = atan2(diff.x, diff.z)
