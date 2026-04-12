# game_manager.gd
# Attach to a Node in Level_1 named "GameManager"

extends Node

# ─────────────────────────────────────────────
# Signals
# ─────────────────────────────────────────────
signal score_changed(new_score: int)
signal wave_started(wave_number: int)

# ─────────────────────────────────────────────
# Scene references
# ─────────────────────────────────────────────
@onready var altars_root: Node3D = $"../Altars"
@onready var spawn_area: Node3D  = $"../ziggurat/Spawn_Area"

# ─────────────────────────────────────────────
# Score
# ─────────────────────────────────────────────
var score: int = 0

func add_kill(points: int = 1) -> void:
	score += points
	emit_signal("score_changed", score)
	print("Score: ", score)

# ─────────────────────────────────────────────
# AI Scenes
# ─────────────────────────────────────────────
const AI_SCENES: Dictionary = {
	"base":   preload("res://scenes/base_ai.tscn"),
}

# ─────────────────────────────────────────────
# Wave definitions
#   ai_type  : key from AI_SCENES
#   count    : enemies to spawn this wave
#   interval : seconds between each spawn
# ─────────────────────────────────────────────
var wave_definitions: Array[Dictionary] = [
	{ "ai_type": "simple", "count": 3, "interval": 3.0 },
	{ "ai_type": "simple", "count": 5, "interval": 2.5 },
	{ "ai_type": "base",   "count": 4, "interval": 2.0 },
	{ "ai_type": "base",   "count": 6, "interval": 1.5 },
]

var current_wave: int              = -1
var active_enemies: Array          = []
var _spawn_timer: float            = 0.0
var _spawns_remaining: int         = 0
var _current_wave_data: Dictionary = {}
var _spawning: bool                = false
var _wave_just_ended: bool         = false

# ─────────────────────────────────────────────
# Pellet system
# ─────────────────────────────────────────────
var _active_altar: Node3D         = null
var _pellet_poll_timer: float     = 0.0
const PELLET_POLL_RATE: float     = 0.5

# ─────────────────────────────────────────────
# Ready
# ─────────────────────────────────────────────
func _ready() -> void:
	for altar in altars_root.get_children():
		var pellet = altar.get_node_or_null("PowerPellet")
		if pellet and pellet.has_signal("pellet_collected"):
			pellet.pellet_collected.connect(_on_pellet_collected)
		_deactivate_pellet(altar)

	start_next_wave()

# ─────────────────────────────────────────────
# Process
# ─────────────────────────────────────────────
func _process(delta: float) -> void:
	_tick_spawner(delta)
	_tick_pellet_lighting(delta)
	_check_wave_complete()

# ─────────────────────────────────────────────
# Spawner
# ─────────────────────────────────────────────
func start_next_wave() -> void:
	current_wave += 1
	if current_wave >= wave_definitions.size():
		print("=== All waves complete! Final score: %d ===" % score)
		return

	_current_wave_data = wave_definitions[current_wave]
	_spawns_remaining  = _current_wave_data.get("count", 1)
	_spawn_timer       = 0.0
	_spawning          = true
	_wave_just_ended   = false
	emit_signal("wave_started", current_wave)
	print("Wave %d started — type: %s  count: %d" % [
		current_wave + 1,
		_current_wave_data["ai_type"],
		_spawns_remaining
	])

func _tick_spawner(delta: float) -> void:
	if not _spawning:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _spawns_remaining > 0:
		_spawn_one_enemy()
		_spawns_remaining -= 1
		_spawn_timer = _current_wave_data.get("interval", 2.0)
		if _spawns_remaining <= 0:
			_spawning = false

func _spawn_one_enemy() -> void:
	var points: Array = spawn_area.get_children()
	if points.is_empty():
		push_warning("GameManager: No children found under Spawn_Area!")
		return

	var spawn_node: Node3D = points[randi() % points.size()]
	var ai_key: String     = _current_wave_data.get("ai_type", "simple")

	if not AI_SCENES.has(ai_key):
		push_warning("GameManager: Unknown ai_type '%s'" % ai_key)
		return

	var enemy: Node = AI_SCENES[ai_key].instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_node.global_position

	enemy.tree_exiting.connect(_on_enemy_died.bind(enemy))
	active_enemies.append(enemy)

	print("Spawned '%s' at %s" % [ai_key, spawn_node.name])

func _on_enemy_died(enemy: Node) -> void:
	active_enemies.erase(enemy)
	add_kill(1)

func _check_wave_complete() -> void:
	if _spawning or _wave_just_ended:
		return
	if active_enemies.is_empty() and current_wave >= 0:
		_wave_just_ended = true
		print("Wave %d cleared!" % (current_wave + 1))
		await get_tree().create_timer(3.0).timeout
		start_next_wave()

# ─────────────────────────────────────────────
# Pellet / Lighting
# ─────────────────────────────────────────────
func _tick_pellet_lighting(delta: float) -> void:
	_pellet_poll_timer -= delta
	if _pellet_poll_timer > 0.0:
		return
	_pellet_poll_timer = PELLET_POLL_RATE

	# If no pellet is currently active, pick a random altar and light it
	if _active_altar == null:
		var altars = altars_root.get_children()
		if altars.is_empty():
			return
		var chosen: Node3D = altars[randi() % altars.size()]
		_activate_pellet(chosen)
		_active_altar = chosen

func _get_light(altar: Node3D) -> Node:
	for child in altar.get_children():
		if child is OmniLight3D or child is SpotLight3D:
			return child
	return null

func _get_pellet(altar: Node3D) -> Node:
	return altar.get_node_or_null("PowerPellet")

func _activate_pellet(altar: Node3D) -> void:
	var pellet = _get_pellet(altar)
	if pellet == null:
		return
	var col  = pellet.get_node_or_null("Area3D/CollisionShape3D")
	var mesh = pellet.get_node_or_null("Area3D/MeshInstance3D")
	var light = _get_light(altar)
	if col:   col.disabled = false
	if mesh:  mesh.visible = true
	if light: light.visible = true
	if pellet.get("_is_hidden") != null:
		pellet._is_hidden = false
	print("Pellet ACTIVE  → %s" % altar.name)

func _deactivate_pellet(altar: Node3D) -> void:
	var pellet = _get_pellet(altar)
	if pellet == null:
		return
	var col  = pellet.get_node_or_null("Area3D/CollisionShape3D")
	var mesh = pellet.get_node_or_null("Area3D/MeshInstance3D")
	var light = _get_light(altar)
	if col:   col.disabled = true
	if mesh:  mesh.visible = false
	if light: light.visible = false
	if pellet.get("_is_hidden") != null:
		pellet._is_hidden = true
	print("Pellet INACTIVE → %s" % altar.name)

func _on_pellet_collected() -> void:
	_active_altar = null
	print("Pellet collected — scanning for next lit altar")
	_pellet_poll_timer = 0.0
