extends Node

@onready var _powered_label: Label = $CanvasLayer/Label
@onready var _progress_bar: TextureProgressBar = $CanvasLayer/TextureProgressBar

func _ready() -> void:
	set_powered(false)

func set_powered(powered: bool) -> void:
	_powered_label.visible = powered

func set_progress(value: float, max_value: float) -> void:
	_progress_bar.max_value = max_value
	_progress_bar.value = value
