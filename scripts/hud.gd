extends Node

@onready var _powered_label: Label = $CanvasLayer/Label
@onready var _progress_bar: ProgressBar = $CanvasLayer/ProgressBar
@onready var _subviewport: SubViewport = $CanvasLayer/MapContainer/MapPort
@onready var _viewport: SubViewportContainer = $CanvasLayer/MapContainer
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

func display_camera(camera: Camera3D) -> void:
	camera.reparent(_subviewport)
	
func camerahide() -> void:
	_viewport.hide()
func camerashow() -> void:
	_viewport.show()
