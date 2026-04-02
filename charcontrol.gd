
extends CharacterBody3D

# ── Settings ──────────────────────────────────────────
const ACCEL: float = 4.0
const SPEED: float = 6.0
const CROUCH_SPEED: float = 2.5
const JUMP_VELOCITY: float = 10.0
const MOUSE_SENSITIVITY: float = 0.002
const MAX_LOOK_ANGLE: float = 89.0
const SLIDE_DURATION: float = 0.6
const SLIDE_SPEED: float = 12.0
const DASH_SPEED: float = 18.0
const DASH_DURATION: float = 20.0
const HEAD_STAND_HEIGHT: float = 1.8
const HEAD_CROUCH_HEIGHT: float = 1.0
const WALL_JUMP_AWAY_FORCE: float = 10.0

# ── References ────────────────────────────────────────
@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera
@onready var _standing_collision: CollisionShape3D = $StandingCollision
@onready var _crouching_collision: CollisionShape3D = $CrouchingCollision

# ── State ─────────────────────────────────────────────
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _is_crouching: bool = false
var _is_sliding: bool = false
var _is_dashing: bool = false
var _is_wall_sliding: bool = false
var _dash_timer: float = DASH_DURATION
var _dash_velocity: Vector3 = Vector3.ZERO
var _target_head_height: float = HEAD_STAND_HEIGHT
var _trajectory: Vector3 = Vector3.ZERO
var _direction: Vector3 = Vector3.ZERO
# ── Ready ─────────────────────────────────────────────

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_crouching_collision.disabled = true



# ── Input ─────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_mouse_look(event)
		return
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_action_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	_head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
	_head.rotation.x = clamp(_head.rotation.x, -deg_to_rad(MAX_LOOK_ANGLE), deg_to_rad(MAX_LOOK_ANGLE))

# ── Physics ───────────────────────────────────────────
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_handle_jump()
	_handle_slide(delta)
	if Input.is_action_just_pressed("sprint"):
		_dash_timer = DASH_DURATION
		_handle_dash(delta)
	_handle_wall_slide(delta)
	if Input.is_action_just_pressed("jump") and _is_wall_sliding:
		_handle_wall_jump()
	_handle_movement(delta)
	_lerp_head(delta)
	move_and_slide()

func _lerp_head(delta: float) -> void:
	_head.position.y = lerp(_head.position.y, _target_head_height, delta * 10.0)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor() and not _is_wall_sliding:
		velocity.y -= _gravity * delta



# ── Jump / Air Dash ───────────────────────────────────
func _handle_jump() -> void:
		velocity.y = JUMP_VELOCITY

func _handle_wall_slide(delta) -> void:
	if is_on_wall_only() and velocity.y < 0:
		_is_wall_sliding = true
		velocity.y = -1
	else:
		_is_wall_sliding = false
	

func _handle_wall_jump() -> void:
	_trajectory = get_slide_collision(0).get_normal()
	velocity.y = JUMP_VELOCITY
	velocity.x += _trajectory.x * WALL_JUMP_AWAY_FORCE
	velocity.z += _trajectory.z * WALL_JUMP_AWAY_FORCE

# ── Dash ──────────────────────────────────────────────
func _handle_dash(delta: float) -> void:
	if not _is_dashing:
		return
	if _dash_timer >= 0.0:
		_is_dashing = true
		velocity.x = _direction.x * DASH_SPEED
		velocity.z = _direction.z * DASH_SPEED
		velocity.y = 0
		_dash_timer -= delta
	else:
		_is_dashing = false
		_dash_velocity = Vector3.ZERO

			

# ── Crouch / Slide ────────────────────────────────────
func _handle_slide(delta: float) -> void:
	if Input.is_action_pressed("crouch"):
		if _is_sliding == false:
			_is_sliding = true
			_set_crouch(true)
		if _is_sliding and _direction:
			velocity.x = _direction.x * SLIDE_SPEED
			velocity.z = _direction.z * SLIDE_SPEED
			return
	else:
		_is_sliding = false

	if _has_ceiling_obstruction():
		_set_crouch(true)
	else:
		_set_crouch(false)

func _has_ceiling_obstruction() -> bool:
	if not _is_crouching:
		return false
	_standing_collision.disabled = false
	var overlaps := move_and_collide(Vector3.ZERO, true)
	_standing_collision.disabled = true
	return overlaps != null



func _stop_slide() -> void:
	_is_sliding = false

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
	if _is_sliding or _is_dashing:
		return
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed: float
	if _is_crouching:
		current_speed = CROUCH_SPEED
	else:
		current_speed = SPEED

	if _direction:
		velocity.x = _direction.x * current_speed
		velocity.z = _direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
