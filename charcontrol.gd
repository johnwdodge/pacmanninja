
extends CharacterBody3D

# ── Settings ──────────────────────────────────────────
const ACCEL: float = 4.0
const SPEED: float = 9.0
const SPRINT_SPEED: float = 18.0
const CROUCH_SPEED: float = 2.5
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.002
const MAX_LOOK_ANGLE: float = 89.0
const SLIDE_DURATION: float = 0.6
const SLIDE_SPEED: float = 12.0
const DASH_SPEED: float = 18.0
const DASH_DURATION: float = 0.15
const HEAD_STAND_HEIGHT: float = 1.8
const HEAD_CROUCH_HEIGHT: float = 1.0
const WALL_RUN_SPEED: float = 8.0
const WALL_RUN_DURATION: float = 1.8
const WALL_JUMP_VELOCITY: float = 5.0
const WALL_JUMP_AWAY_FORCE: float = 6.0

# ── References ────────────────────────────────────────
@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera
@onready var _standing_collision: CollisionShape3D = $StandingCollision
@onready var _crouching_collision: CollisionShape3D = $CrouchingCollision

# ── State ─────────────────────────────────────────────
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _is_crouching: bool = false
var _is_sliding: bool = false
var _slide_timer: float = 0.0
var _can_air_dash: bool = true
var _is_dashing: bool = false
var _is_wall_sliding: bool = false
var _dash_timer: float = 0.0
var _dash_velocity: Vector3 = Vector3.ZERO
var _target_head_height: float = HEAD_STAND_HEIGHT
var _is_wall_running: bool = false
var _wall_run_timer: float = 0.0
var _wall_normal: Vector3 = Vector3.ZERO
var _wall_run_direction: Vector3 = Vector3.ZERO
var _was_sprinting: bool = false
var _current_weapon: Node3D = null
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
	_handle_jump()
	_handle_slide(delta)
	_handle_dash(delta)
	_handle_wall_slide(delta)
	_handle_movement()
	_lerp_head(delta)
	move_and_slide()

func _lerp_head(delta: float) -> void:
	_head.position.y = lerp(_head.position.y, _target_head_height, delta * 10.0)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor() and not _is_wall_sliding:
		velocity.y -= _gravity * delta



# ── Jump / Air Dash ───────────────────────────────────
func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_can_air_dash = true

func _handle_wall_slide(delta) -> void:
	if is_on_wall_only():
		_is_wall_sliding = true
		velocity.y -= (_gravity * 0.25) * delta
	

func _handle_wall_jump() -> void:
	if Input.is_action_just_pressed("jump") and _is_wall_sliding:
		velocity.y = JUMP_VELOCITY
		velocity.x += _wall_normal.x * WALL_JUMP_AWAY_FORCE
		velocity.z += _wall_normal.z * WALL_JUMP_AWAY_FORCE

# ── Dash ──────────────────────────────────────────────
func _handle_dash(delta: float) -> void:
	if not _is_dashing:
		return
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_is_dashing = false
		_dash_velocity = Vector3.ZERO
	else:
		velocity.x = _dash_velocity.x
		velocity.z = _dash_velocity.z
		velocity.y = 0

# ── Crouch / Slide ────────────────────────────────────
func _handle_slide(delta: float) -> void:

	if Input.is_action_pressed("crouch") and is_on_floor() and velocity.length() > SPEED:
		_start_slide()
		return

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

func _start_slide() -> void:
	_is_sliding = true
	_set_crouch(true)
	var forward := -transform.basis.z.normalized()
	velocity.x = forward.x * SLIDE_SPEED
	velocity.z = forward.z * SLIDE_SPEED

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
	
func _handle_movement() -> void:
	if _is_sliding or _is_dashing:
		return

	if is_on_floor():
		_was_sprinting = Input.is_action_pressed("sprint")

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed: float
	if _is_crouching:
		current_speed = CROUCH_SPEED
	elif Input.is_action_pressed("sprint") and is_on_floor():
		current_speed = SPRINT_SPEED
	elif not is_on_floor() and _was_sprinting:
		current_speed = SPRINT_SPEED
	else:
		current_speed = SPEED

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
