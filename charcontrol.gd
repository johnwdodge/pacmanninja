
extends CharacterBody3D

# ── Settings ──────────────────────────────────────────
const ACCEL: float = 7.0
const AIR_ACCEL: float = 2
const DECEL: float = 14.0
const MAX_SPEED: float = 15.0
const CROUCH_SPEED: float = 2.5
const JUMP_VELOCITY: float = 10.0
const MOUSE_SENSITIVITY: float = 0.002
const MAX_LOOK_ANGLE: float = 89.0
const SLIDE_DURATION: float = 5.0
const SLIDE_SPEED: float = 20.0
const DASH_SPEED: float = 35.0
const DASH_DURATION: float = 0.15
const HEAD_STAND_HEIGHT: float = 1.8
const HEAD_CROUCH_HEIGHT: float = 1.0
const WALL_JUMP_AWAY_FORCE: float = 10.0

# ── References ────────────────────────────────────────
@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera
@onready var _standing_collision: CollisionShape3D = $StandingCollision
@onready var _crouching_collision: CollisionShape3D = $CrouchingCollision

@onready var _hud: Node = $"../HUD"

# ── State ─────────────────────────────────────────────
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _is_crouching: bool = false
var _dash_timer: float = DASH_DURATION
var _target_head_height: float = HEAD_STAND_HEIGHT
var _trajectory: Vector3 = Vector3.ZERO
var _direction: Vector3 = Vector3.ZERO
var _can_dash: bool = false
var _current_speed: float = 0.0

enum State {move, dash, slide, air, wall, idle}
var state = State.idle
const POWER_DURATION: float = 10.0
var _is_powered: bool = false
var _power_timer: float = 0.0
func change_state(newstate) -> void:
	state = newstate
# ── Ready ─────────────────────────────────────────────

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_crouching_collision.disabled = true



# ── Input ─────────────────────────────────────────────

# ── Physics ───────────────────────────────────────────
func _physics_process(delta: float) -> void:
	match state:
		State.idle:
			_handle_idle()
		State.move:
			_handle_movement(delta)
		State.dash:
			_handle_dash(delta)
		State.slide:
			_handle_slide(delta)
		State.wall:
			_handle_wall_slide(delta)
		State.air:
			_handle_air(delta)
		
	_lerp_head(delta)
	_tick_power(delta)

func _lerp_head(delta: float) -> void:
	_head.position.y = lerp(_head.position.y, _target_head_height, delta * 10.0)

func _apply_gravity(delta: float) -> void:
	velocity.y -= _gravity * delta

# ── Idle ───────────────────────────────────
func _handle_idle() -> void:
	print("idle state")
	if is_on_floor():
		change_state(State.move)
	else:
		change_state(State.air)
	move_and_slide()

# ── Jump / Air Dash ───────────────────────────────────
func _handle_air(delta) -> void:
	print("air state")
	
	if is_on_wall_only():
		_trajectory = get_slide_collision(0).get_normal()
		change_state(State.wall)
	
	if is_on_floor():
		change_state(State.move)
	
	_apply_gravity(delta)
	
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if _direction:
		velocity.x = lerp(velocity.x, _direction.x * MAX_SPEED, AIR_ACCEL * delta)
		velocity.z = lerp(velocity.z, _direction.z * MAX_SPEED, AIR_ACCEL * delta)
	
	move_and_slide()
	

func _handle_jump() -> void:
	if state == State.move:
		velocity.y = JUMP_VELOCITY
		if state == State.wall:
			velocity.y = JUMP_VELOCITY
			velocity.x += _trajectory.x * WALL_JUMP_AWAY_FORCE
			velocity.z += _trajectory.z * WALL_JUMP_AWAY_FORCE
	else:
		return
	change_state(State.air)
	
func _handle_wall_slide(delta) -> void:
	print ("wall state")
	if velocity.y < 0:
		velocity.y = -1
	else: _apply_gravity(delta)
	if is_on_floor():
		change_state(State.idle)
	if Input.is_action_just_pressed("move_back") or Input.is_action_just_pressed("move_forward") or Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		await get_tree().create_timer(0.2).timeout
		change_state(State.idle)
	move_and_slide()




# ── Dash ──────────────────────────────────────────────
func _handle_dash(delta: float) -> void:
	print("dash state")
	if _dash_timer > 0:
		_dash_timer -= delta
		velocity.x = _direction.x * DASH_SPEED
		velocity.z = _direction.z * DASH_SPEED
		velocity.y = 0
	else:
		velocity.x = _direction.x * MAX_SPEED
		velocity.z = _direction.z * MAX_SPEED
		change_state(State.idle)
	move_and_slide()

			

# ── Crouch / Slide ────────────────────────────────────
func _handle_slide(delta: float) -> void:
	print ("slide state")
	_set_crouch(true)
	velocity.x = _direction.x * SLIDE_SPEED
	velocity.z = _direction.z * SLIDE_SPEED
	if Input.is_action_just_released("crouch"):
		change_state(State.idle)
		return
	move_and_slide()
		
func _has_ceiling_obstruction() -> bool:
	if not _is_crouching:
		return false
	_standing_collision.disabled = false
	var overlaps := move_and_collide(Vector3.ZERO, true)
	_standing_collision.disabled = true
	return overlaps != null

func _set_crouch(crouching: bool) -> void:
	if _is_crouching == crouching:
		return
	_is_crouching = crouching
	_standing_collision.disabled = crouching
	_crouching_collision.disabled = not crouching
	_target_head_height = HEAD_CROUCH_HEIGHT if crouching else HEAD_STAND_HEIGHT

# ── Movement ──────────────────────────────────────────
func _handle_accel(accel, current, max) -> float:
	var final: float
	if current >= max:
		final = current - accel
		return final
	else:
		final = current + accel
		return final
	
func _handle_movement(delta: float) -> void:
	print("move state")
	if not is_on_floor():
		change_state(State.idle)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if _is_crouching:
		_current_speed = CROUCH_SPEED
	else:
		if _current_speed > MAX_SPEED:
			_current_speed -= DECEL
		else: _current_speed += ACCEL
			

	if _direction:
		velocity.x = lerp(velocity.x, _direction.x * MAX_SPEED, ACCEL * delta)
		velocity.z = lerp(velocity.z, _direction.z * MAX_SPEED, ACCEL * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECEL * delta)
		velocity.z = lerp(velocity.z, 0.0, DECEL * delta)

	if _has_ceiling_obstruction():
		_set_crouch(true)
	else:
		_set_crouch(false)
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_mouse_look(event)
		return
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_action_pressed("crouch"):
			if state in [State.move, State.dash]:
				if _direction:
					change_state(State.slide)
		if event.is_action_pressed("sprint"):
			if state not in [State.wall, State.slide, State.dash]:
				if _direction:
					_dash_timer = DASH_DURATION
					change_state(State.dash)
		if event.is_action_pressed("jump"):
			_handle_jump()
		if event.is_action_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	_head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
	_head.rotation.x = clamp(_head.rotation.x, -deg_to_rad(MAX_LOOK_ANGLE), deg_to_rad(MAX_LOOK_ANGLE))

func apply_power() -> void:
	_is_powered = true
	_power_timer = POWER_DURATION
	_hud.set_powered(true)

func _tick_power(delta: float) -> void:
	if not _is_powered:
		return
	_power_timer -= delta
	_hud.set_progress(_power_timer, POWER_DURATION)
	if _power_timer <= 0.0:
		_is_powered = false
		_hud.set_powered(false)
