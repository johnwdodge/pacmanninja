extends CharacterBody3D

@export var move_speed: float = 10
@export var gravity: float = 9.8
@export var stopping_distance: float = 2.0


@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var player: CharacterBody3D
var _path_timer: float = 0.0
const PATH_UPDATE_RATE: float = 0.2

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	NavigationServer3D.map_changed.connect(_on_map_ready)
	nav_agent.velocity_computed.connect(_on_velocity_computed)

func _on_map_ready(map_rid: RID) -> void:
	NavigationServer3D.map_changed.disconnect(_on_map_ready)
	var map = nav_agent.get_navigation_map()
	var closest = NavigationServer3D.map_get_closest_point(map, global_position)
	print("AI pos: ", global_position)
	print("Closest navmesh point: ", closest)

func _physics_process(delta: float) -> void:
	_path_timer -= delta
	if _path_timer <= 0.0:
		nav_agent.target_position = player.global_position
		_path_timer = PATH_UPDATE_RATE
	if not is_on_floor():
		velocity.y -= gravity * delta
	if player == null:
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= stopping_distance:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	nav_agent.target_position = player.global_position
	if nav_agent.is_navigation_finished():
		return
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = (next_pos - global_position).normalized()
	# Rotation
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length() > 0.1:
		var target_basis = Basis.looking_at(flat_direction)
		basis = basis.slerp(target_basis, delta * 8.0)
	var desired_velocity := direction * move_speed
	desired_velocity.y = velocity.y
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(desired_velocity)
	else:
		velocity = desired_velocity
		move_and_slide()

		

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	safe_velocity.y = velocity.y 
	velocity = safe_velocity
	move_and_slide()
