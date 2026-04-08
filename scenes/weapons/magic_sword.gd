extends Node3D

signal slash_finished

var _is_slashing := false

@onready var _anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_anim.play("slice")
	_anim.seek(0.0, true)
	_anim.stop()
	_anim.animation_finished.connect(_on_slice_finished)

func slash() -> void:
	if _is_slashing:
		return
	_is_slashing = true
	_anim.stop()
	_anim.play("slice")

func _on_slice_finished(_anim_name: StringName) -> void:
	_is_slashing = false
	slash_finished.emit()
