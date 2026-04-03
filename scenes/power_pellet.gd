extends Node3D

signal pellet_collected

func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("apply_power"):
		body.apply_power()
		emit_signal("pellet_collected")
		queue_free()
