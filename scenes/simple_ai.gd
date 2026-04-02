extends CharacterBody3D

@export var move_speed: float = 3.5
@export var gravity: float = 9.8
@export var stopping_distance: float = 2.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var player: CharacterBody3D
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	print("AI pos: ", global_position)
	print("Next pos: ", nav_agent.get_next_path_position())
	print("Distance to next: ", global_position.distance_to(nav_agent.get_next_path_position()))
	# Wait for the nav map to be ready before querying
	NavigationServer3D.map_changed.connect(_on_map_ready)

func _on_map_ready(map_rid: RID) -> void:
	# Disconnect so it only runs once
	NavigationServer3D.map_changed.disconnect(_on_map_ready)
	var map = nav_agent.get_navigation_map()
	var closest = NavigationServer3D.map_get_closest_point(map, global_position)
	print("AI pos: ", global_position)
	print("Closest navmesh point: ", closest)

func _physics_process(delta: float) -> void:
	print("Nav finished: ", nav_agent.is_navigation_finished())
	print("Next pos: ", nav_agent.get_next_path_position())
	print("Velocity: ", velocity)
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)
	if dist <= stopping_distance:
		# Close enough, stop moving horizontally
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	# Update the navigation target every frame
	nav_agent.target_position = player.global_position

	if nav_agent.is_navigation_finished():
		return

	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = (next_pos - global_position).normalized()

	var desired_velocity = direction * move_speed
	desired_velocity.y = velocity.y  # preserve gravity

	# Use avoidance if enabled on NavigationAgent3D
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(desired_velocity)
	else:
		velocity = desired_velocity
		move_and_slide()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	# Called by avoidance system with a safe velocity
	velocity = safe_velocity
	move_and_slide()
