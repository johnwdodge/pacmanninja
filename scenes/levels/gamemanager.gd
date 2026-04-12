extends Node

# --- Scene References ---
@onready var pelletcontrol = $"../Altars"
@onready var player = $"../charcontrol"
var altars: Array = []
var _active_altar: Node = null

# --- Score ---
var score: int = 0

# --- Difficulty Tiers ---
const SCORE_THRESHOLDS: Array  = [0, 5, 10, 20, 35, 50]
const MOVE_TIME_BY_TIER: Array  = [0.50, 0.45, 0.40, 0.35, 0.28, 0.22]
const SPAWN_TIMER_BY_TIER: Array = [40,   35,   28,   22,   16,   10  ]
const HEALTH_BY_TIER: Array      = [1,    1,    1,    2,    2,    3   ]

# --- Equal-distribution spawn queue ---
const AI_TYPES: Array = ["blinky", "pinky", "clyde"]
var _spawn_queue: Array = []

func _ready() -> void:
	altars = pelletcontrol.get_children()
	_refill_queue()
	_hide_all_pellets()
	_activate_random_pellet()
	for altar in altars:
		var pellet = altar.get_node("PowerPellet")
		pellet.pellet_collected.connect(_on_pellet_collected.bind(altar))

func _process(_delta: float) -> void:
	if not player._is_powered:
		var active_pellet = _active_altar.get_node("PowerPellet")
		if active_pellet._is_hidden:
			_activate_random_pellet()
	# Next pellet activates once player power expires (checked in _process)
# --- Pellet Management ---
func _hide_all_pellets() -> void:
	for altar in altars:
		var pellet = altar.get_node("PowerPellet")
		pellet._hide_pellet()

func _activate_random_pellet() -> void:
	var available = altars.filter(func(a): return not a.get_node("PowerPellet")._is_hidden)
	# All hidden — pick a random one and force-show it
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
