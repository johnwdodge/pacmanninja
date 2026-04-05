extends Node3D

signal pellet_collected
var _is_hidden: bool = false

func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("apply_power") and not _is_hidden:
		body.apply_power()
		emit_signal("pellet_collected")
		_hide_pellet()

func _hide_pellet() -> void:
	_is_hidden = true
	$Area3D/CollisionShape3D.disabled = true
	$Area3D/MeshInstance3D.visible = false
	print("Pellet hidden, waiting 30s...")
	await get_tree().create_timer(10.0).timeout
	print("Timer done, respawning")
	_respawn()

func _respawn() -> void:
	$Area3D/CollisionShape3D.disabled = false
	$Area3D/MeshInstance3D.visible = true
	_is_hidden = false
