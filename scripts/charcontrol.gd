extends CharacterBody3D

# ── Settings ──────────────────────────────────────────
const ACCEL: float = 9.0
const AIR_ACCEL: float = 4
const AIR_DECEL: float = 1
const DECEL: float = 3.0
const MAX_SPEED: float = 15.0
const CROUCH_SPEED: float = 8.0
const JUMP_VELOCITY: float = 13.0
const MOUSE_SENSITIVITY: float = 0.002
const MAX_LOOK_ANGLE: float = 89.0
const SLIDE_DURATION: float = 5.0
const SLIDE_SPEED: float = 20.0
const SLOPE_ACCEL: float = 1.3
const DASH_SPEED: float = 50.0
const DASH_DURATION: float = 0.125
const WALL_LENIENCE: float = 0.15
const HEAD_STAND_HEIGHT: float = 1.8
const HEAD_CROUCH_HEIGHT: float = 1.0
const WALL_JUMP_AWAY_FORCE: float = 12.0
const POWER_DURATION: float = 10.0
const METER_REFILL: float = 2
const SLIDE_DRAIN: float = 5
const METER_SEGMENT: float = 200
const METER_SIZE: float = 800
const WALLJUMP_TIMEOUT: float = 0.03
const SLAM_UP: float = 0.075
const SLAM_SPEED: float = 80.0
const METER_REFILL_DELAY: float = 0.25
const SWORD_SCENE = preload("res://scenes/weapons/magic_sword.tscn")
const COYOTE_TIME: float = 0.2

# ── References ────────────────────────────────────────

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera
@onready var _standing_collision: CollisionShape3D = $StandingCollision
@onready var _crouching_collision: CollisionShape3D = $CrouchingCollision
@onready var _hud: Node = $"../HUD"
@onready var _attack_hurtbox: Area3D = $Head/AttackHurtbox
@onready var _sword_anchor: Node3D = $Head/SwordAnchor
@onready var hud: Node = $"../HUD"

# ── Variables ─────────────────────────────────────────────

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _is_crouching: bool = false
var _dash_timer: float = DASH_DURATION
var _wall_timer: float = WALL_LENIENCE
var _target_head_height: float = HEAD_STAND_HEIGHT
var _trajectory: Vector3 = Vector3.ZERO
var _direction: Vector3 = Vector3.ZERO
var _current_speed: float = 0.0
var _is_powered: bool = false
var _power_timer: float = 0.0
var _current_meter: float = METER_SIZE
var _slam_timer: float = SLAM_UP
var _walljump_timer: float = WALLJUMP_TIMEOUT
var _sword_instance: Node3D = null
var _meter_refill_delay: float = 0.0
var _temp_vel: Vector3 = Vector3(velocity.x, 0, velocity.z)
var _total_vel = _temp_vel.length()
var _coyote_timer: float = COYOTE_TIME

# ── State ─────────────────────────────────────────────

enum State { move, dash, slide, air, wall, idle, slam, walljump }
var state = State.idle

func change_state(newstate) -> void:
	state = newstate

# ── Ready ─────────────────────────────────────────────

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_crouching_collision.disabled = true
	_attack_hurtbox.monitoring = false
	_attack_hurtbox.monitorable = false
	_attack_hurtbox.body_entered.connect(_on_hurtbox_body_entered)

# ── Physics ───────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_temp_vel = Vector3(velocity.x, 0, velocity.z)
	_total_vel = _temp_vel.length()
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
		State.slam:
			_handle_slam(delta)
		State.walljump:
			_handle_walljump(delta)
	_update_meter(delta)
	print(_total_vel)
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer -= delta
	_lerp_head(delta)
	_tick_power(delta)

func _lerp_head(delta: float) -> void:
	_head.position.y = lerp(_head.position.y, _target_head_height, delta * 10.0)

func _apply_gravity(delta: float) -> void:
	velocity.y -= _gravity * delta
	if velocity.y < 0:
		velocity.y -= _gravity * delta
	if velocity.y < -20:
		velocity.y = -20

# ── Idle ──────────────────────────────────────────────

func _handle_idle() -> void:
	if is_on_floor():
		change_state(State.move)
	else:
		change_state(State.air)
	move_and_slide()

# ── Power ─────────────────────────────────────────────

func apply_power() -> void:
	_is_powered = true
	_power_timer = POWER_DURATION
	_hud.set_powered(true)
	if _sword_instance == null:
		_sword_instance = SWORD_SCENE.instantiate()
		_sword_anchor.add_child(_sword_instance)
		_sword_instance.slash_finished.connect(_on_slash_finished)

func _tick_power(delta: float) -> void:
	if not _is_powered:
		return
	_power_timer -= delta
	_hud.set_progress(_power_timer, POWER_DURATION)
	if _power_timer <= 0.0:
		_is_powered = false
		_hud.set_powered(false)
		_attack_hurtbox.monitoring = false
		_attack_hurtbox.monitorable = false
		if _sword_instance:
			_sword_instance.queue_free()
			_sword_instance = null

# ── Attack ────────────────────────────────────────────

func _on_slash_finished() -> void:
	_attack_hurtbox.monitoring = false
	_attack_hurtbox.monitorable = false

func _on_hurtbox_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage()

# ── Meter ─────────────────────────────────────────────

func _consume_meter(amount: float) -> void:
	_current_meter -= amount
	_meter_refill_delay = METER_REFILL_DELAY

func _update_meter(delta: float) -> void:
	if _meter_refill_delay > 0.0 and not _is_powered:
		_meter_refill_delay -= delta
		_hud.set_meter(_current_meter, METER_SIZE)
		return
	if _current_meter < METER_SIZE:
		if _is_powered:
			_current_meter += METER_REFILL * 2
		else:
			_current_meter += METER_REFILL
	_hud.set_meter(_current_meter, METER_SIZE)

# ── Jump / Air ────────────────────────────────────────

func _handle_air(delta) -> void:
	if is_on_wall_only():
		_wall_timer = WALL_LENIENCE
		_trajectory = get_slide_collision(0).get_normal()
		change_state(State.wall)
	if is_on_floor():
		change_state(State.move)
	if Input.is_action_just_pressed("crouch"):
		_slam_timer = SLAM_UP
		change_state(State.slam)
	_apply_gravity(delta)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if _direction:
		if _total_vel < MAX_SPEED:
			velocity.x = lerp(velocity.x, _direction.x * MAX_SPEED, AIR_ACCEL * delta)
			velocity.z = lerp(velocity.z, _direction.z * MAX_SPEED, AIR_ACCEL * delta)
		else:
			velocity.x = lerp(velocity.x, _direction.x * MAX_SPEED, AIR_DECEL * delta)
			velocity.z = lerp(velocity.z, _direction.z * MAX_SPEED, AIR_DECEL * delta)
	move_and_slide()

func _handle_jump() -> void:
	if _coyote_timer > 0:
		_coyote_timer = 0
		velocity.y = JUMP_VELOCITY
		if state == State.dash:
			change_state(State.idle)
	if state == State.wall:
		if _current_meter > METER_SEGMENT:
			_consume_meter(METER_SEGMENT)
			velocity.y = JUMP_VELOCITY
			velocity.x += _trajectory.x * WALL_JUMP_AWAY_FORCE
			velocity.z += _trajectory.z * WALL_JUMP_AWAY_FORCE
			_walljump_timer = WALLJUMP_TIMEOUT
			change_state(State.walljump)
			return
		else:
			return
	else:
		return
	
func _handle_walljump(delta) -> void:
	if _walljump_timer > 0:
		_walljump_timer -= delta
		_apply_gravity(delta)
		move_and_slide()
	else:
		change_state(State.air)
		move_and_slide()

# ── Wall Slide ────────────────────────────────────────

func _handle_wall_slide(delta) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if velocity.y < 0:
		velocity.y = -1
	else:
		_apply_gravity(delta)
	if is_on_wall_only():
		_wall_timer = WALL_LENIENCE
		_trajectory = get_slide_collision(0).get_normal()
	if _direction:
		if _total_vel < MAX_SPEED:
			velocity.x = lerp(velocity.x, _direction.x * MAX_SPEED, ACCEL * delta)
			velocity.z = lerp(velocity.z, _direction.z * MAX_SPEED, ACCEL * delta)
		else:
			velocity.x = lerp(velocity.x, _direction.x * MAX_SPEED, DECEL * delta)
			velocity.z = lerp(velocity.z, _direction.z * MAX_SPEED, DECEL * delta)
		if not is_on_wall_only():
			_wall_timer -= delta
	else:
		_wall_timer -= delta
	if _wall_timer <= 0:
		change_state(State.idle)
	if is_on_floor():
		change_state(State.idle)
	move_and_slide()

# ── Dash ──────────────────────────────────────────────

func _handle_dash(delta: float) -> void:
	if _dash_timer > 0:
		_dash_timer -= delta
		velocity.x = _direction.x * DASH_SPEED
		velocity.z = _direction.z * DASH_SPEED
		velocity.y = 0
	else:
		velocity.x = _direction.x * (MAX_SPEED + 7)
		velocity.z = _direction.z * (MAX_SPEED + 7)
		change_state(State.idle)
	move_and_slide()

# ── Crouch / Slide ────────────────────────────────────

func _handle_slide(delta: float) -> void:
	if _current_meter > 0:
		if not _is_powered:
			_consume_meter(SLIDE_DRAIN)
		_apply_gravity(delta)
		_set_crouch(true)
		var floornorm = get_floor_normal()
		floornorm.y = 0
		if floornorm:
			floornorm = floornorm.normalized()
			if floornorm.dot(velocity.normalized()) > -0.1:
				velocity.x = _direction.x * (SLIDE_SPEED * SLOPE_ACCEL)
				velocity.z = _direction.z * (SLIDE_SPEED * SLOPE_ACCEL)
			else:
				velocity.x = _direction.x * (SLIDE_SPEED / SLOPE_ACCEL)
				velocity.z = _direction.z * (SLIDE_SPEED / SLOPE_ACCEL)
		if _total_vel < SLIDE_SPEED:
			velocity.x = _direction.x * SLIDE_SPEED
			velocity.z = _direction.z * SLIDE_SPEED
		else:
			velocity.x = lerp(velocity.x, _direction.x * SLIDE_SPEED, AIR_DECEL * delta)
			velocity.z = lerp(velocity.z, _direction.z * SLIDE_SPEED, AIR_DECEL * delta)
		if Input.is_action_just_released("crouch"):
			change_state(State.idle)
			return
		move_and_slide()
	else:
		change_state(State.idle)
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

# ── Ground Slam ───────────────────────────────────────

func _handle_slam(delta) -> void:
	if _slam_timer >= 0:
		velocity.y = 10
		_slam_timer -= delta
	else:
		velocity.y = -SLAM_SPEED
		if is_on_floor():
			if Input.is_action_pressed("crouch"):
				var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
				_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
				if _direction:
					change_state(State.slide)
				else:
					change_state(State.move)
			else:
				change_state(State.move)
	move_and_slide()

# ── Movement ──────────────────────────────────────────

func _handle_movement(delta: float) -> void:
	if not is_on_floor():
		change_state(State.idle)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if _is_crouching:
		_current_speed = CROUCH_SPEED
	else:
		if _current_speed > MAX_SPEED:
			_current_speed -= DECEL
		else:
			_current_speed += ACCEL
	if _direction:
			if _direction.dot(-global_transform.basis.z.normalized()) > -0.1:
				if _total_vel < MAX_SPEED:
					velocity.x = lerp(velocity.x, _direction.x * MAX_SPEED, ACCEL * delta)
					velocity.z = lerp(velocity.z, _direction.z * MAX_SPEED, ACCEL * delta)
				else:
					velocity.x = lerp(velocity.x, _direction.x * MAX_SPEED, DECEL * delta)
					velocity.z = lerp(velocity.z, _direction.z * MAX_SPEED, DECEL * delta)
			else:
				if _total_vel < (MAX_SPEED * 0.8):
					velocity.x = lerp(velocity.x, _direction.x * (MAX_SPEED * 0.8), ACCEL * delta)
					velocity.z = lerp(velocity.z, _direction.z * (MAX_SPEED * 0.8), ACCEL * delta)
				else:
					velocity.x = lerp(velocity.x, _direction.x * (MAX_SPEED * 0.8), DECEL * delta)
					velocity.z = lerp(velocity.z, _direction.z * (MAX_SPEED * 0.8), DECEL * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, ACCEL * delta)
		velocity.z = lerp(velocity.z, 0.0, ACCEL * delta)
	if _has_ceiling_obstruction():
		_set_crouch(true)
	else:
		_set_crouch(false)
	move_and_slide()

# ── Input ─────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_mouse_look(event)
		return
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_action_pressed("crouch"):
			if is_on_floor() and _direction and _current_meter > METER_SEGMENT:
				change_state(State.slide)
		if event.is_action_pressed("sprint"):
			if state not in [State.wall, State.slide, State.dash]:
				if _direction and _current_meter > METER_SEGMENT:
					_consume_meter(METER_SEGMENT)
					_dash_timer = DASH_DURATION
					change_state(State.dash)
		if event.is_action_pressed("jump"):
			_handle_jump()
		if event.is_action_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if event.is_action_pressed("attack"):
			if _sword_instance != null:
				_attack_hurtbox.monitoring = true
				_attack_hurtbox.monitorable = true
				_sword_instance.slash()

func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	_head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
	_head.rotation.x = clamp(_head.rotation.x, -deg_to_rad(MAX_LOOK_ANGLE), deg_to_rad(MAX_LOOK_ANGLE))
