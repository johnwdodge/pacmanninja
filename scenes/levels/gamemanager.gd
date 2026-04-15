extends Node

# --- Scene References ---
@onready var player = $"charcontrol"
@onready var breaks = $breakbeats
@onready var hardcore = $hardcore
@onready var siren = $siren
@onready var tapestop = $"tape stop"

const PELLET_DELAY = 3
var _pellet_timer = PELLET_DELAY
var altars: Array = []
var _active_altar: Node = null
var fancy = false
var current_level = null

# --- Score ---
var score: int = 0

# --- Difficulty Tiers ---
const SCORE_THRESHOLDS: Array  = [0, 10, 20, 35, 50, 70, 100, 150]
const MOVE_TIME_BY_TIER: Array  = [0.60, 0.55, 0.50, 0.45, 0.40, 0.35, 0.3, 0.25]
const SPAWN_TIMER_BY_TIER: Array = [50,   45,   40,   35,   30,  20,  10,  5]
const HEALTH_BY_TIER: Array      = [1,    1,    1,    1,    1,    1,   1,   1]

# --- Equal-distribution spawn queue ---
const AI_TYPES: Array = ["blinky", "pinky", "clyde"]
var _spawn_queue: Array = []
var playerspawn = null
var _current_menu = null
var level2 = preload("res://scenes/levels/level_2.tscn")
var mainmenu = preload("res://scenes/main_menu.tscn")


func _ready() -> void:
	add_to_group("game_manager")
	_load_level(level2)

func _process(_delta: float) -> void:
	if current_level:
		if not player._is_powered and not player._invin:
			var active_pellet = _active_altar.get_node("PowerPellet")
			if active_pellet._is_hidden:
				if _pellet_timer <= 0:
					_activate_random_pellet()
					_pellet_timer = PELLET_DELAY 
				else:
					_pellet_timer -= _delta
	
	if player._power_timer <= 1.5 and player._power_timer > 0:
		hardcore.stop()
		if not tapestop.is_playing():
			tapestop.play()
	if player._is_powered == false:
		if not breaks.is_playing():
			breaks.play()
	if player._is_powered == true:
		if not hardcore.is_playing() and not tapestop.is_playing():
			hardcore.play()
	if player._invin == true:
		breaks.stop()
		if not siren.is_playing():
			siren.play()
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Fullscreen"):
		var mode := DisplayServer.window_get_mode()
		var is_window: bool = mode != DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if is_window else DisplayServer.WINDOW_MODE_WINDOWED)

# --- Pellet Management ---
func open_main_menu() -> void:
	if _current_menu:
		_current_menu.queue_free()
	current_level.queue_free()
	_current_menu = mainmenu.instantiate()
	add_child(_current_menu)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _load_level(level):
	if current_level:
		current_level.queue_free()
	current_level = level.instantiate()
	add_child(current_level)
	playerspawn = get_tree().get_first_node_in_group("spawnpoint")
	player.global_position = playerspawn.global_position
	var altar_container = get_tree().get_first_node_in_group("altars")
	altars = altar_container.get_children()
	_active_altar = altars[0]
	_refill_queue()
	_hide_all_pellets()
	_activate_random_pellet()
	for altar in altars:
		var pellet = altar.get_node("PowerPellet")
		pellet.pellet_collected.connect(_on_pellet_collected.bind(altar))
	
	
func _hide_all_pellets() -> void:
	for altar in altars:
		var pellet = altar.get_node("PowerPellet")
		pellet._hide_pellet()

func _activate_random_pellet() -> void:
	var available = altars.filter(func(a): return not a.get_node("PowerPellet")._is_hidden)
	var candidates = altars.duplicate()
	if _active_altar != null:
		candidates.erase(_active_altar)
	var chosen = candidates.pick_random()
	_active_altar = chosen
	var pellet = chosen.get_node("PowerPellet")
	pellet._respawn()

func _on_pellet_collected(_altar: Node) -> void:
	for a in altars:
		if a != _altar:
			a.get_node("PowerPellet")._hide_pellet()



# --- Difficulty helpers ---
func get_tier() -> int:
	var tier = 0
	for i in range(SCORE_THRESHOLDS.size()):
		if score >= SCORE_THRESHOLDS[i]:
			tier = i
	return tier

func get_move_time() -> float:
	return MOVE_TIME_BY_TIER[get_tier()]

func get_spawn_timer() -> int:
	return SPAWN_TIMER_BY_TIER[get_tier()]

func get_ai_health() -> int:
	return HEALTH_BY_TIER[get_tier()]

# --- Score ---
func add_score(amount: int = 1) -> void:
	score += amount
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.set_score(score)

# --- Spawn queue ---
func next_ai_type() -> String:
	if _spawn_queue.is_empty():
		_refill_queue()
	return _spawn_queue.pop_front()

func _refill_queue() -> void:
	_spawn_queue = AI_TYPES.duplicate()
	_spawn_queue.shuffle()
