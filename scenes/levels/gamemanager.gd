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

# ─────────────────────────────────────────────
# Process
# ─────────────────────────────────────────────
func _process(delta: float) -> void:
	_tick_pellet_lighting(delta)

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
