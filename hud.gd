extends Node

@onready var _powered_label: Label = $CanvasLayer/Label
@onready var _progress_bar: ProgressBar = $CanvasLayer/ProgressBar

func _ready() -> void:
	set_powered(false)
	_progress_bar.max_value = 1.0
	_progress_bar.value = 1.0

func set_powered(powered: bool) -> void:
	_powered_label.visible = powered

func set_meter(value: float, max_value: float) -> void:
	_progress_bar.value = value / max_value  # normalized 0–1

func set_progress(value: float, max_value: float) -> void:
	_powered_label.text = "POWERED  %.1fs" % value
