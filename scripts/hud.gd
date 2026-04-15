extends Node

@onready var _powered_label: Label = $CanvasLayer/Label
@onready var player = $"../charcontrol"
@onready var manager = get_parent()
@onready var head = $"../charcontrol/Head/Camera"
@onready var _progress_bar: ProgressBar = $CanvasLayer/ProgressBar
@onready var _death_screen: Control = $CanvasLayer/DeathScreen
@onready var _combo_label: Label = $CanvasLayer/ComboLabel
@onready var cam1 = $CanvasLayer/cameras/cam1/fancycam
@onready var cam2 = $CanvasLayer/cameras2/cam2/fancycam2
@onready var _score: Label = $CanvasLayer/Score
@onready var overlay = $CanvasLayer/TextureRect
@onready var cameras = $CanvasLayer/cameras
@onready var cameras2 = $CanvasLayer/cameras2
@onready var light = $"../charcontrol/Head/DirectionalLight3D"

func _ready() -> void:
	add_to_group("hud")
	set_powered(false)
	_progress_bar.max_value = 1.0
	_progress_bar.value = 1.0
	set_score(0)
	

func set_powered(powered: bool) -> void:
	_powered_label.visible = powered

func set_combo(multiplier: int) -> void:
	if multiplier <= 1:
		_combo_label.visible = false
	else:
		_combo_label.visible = true
		_combo_label.text = "%dX" % multiplier
func set_meter(value: float, max_value: float) -> void:
	_progress_bar.value = value / max_value  # normalized 0–1

func set_progress(value: float, max_value: float) -> void:
	_powered_label.text = "POWERED  %.1fs" % value

func set_score(value: int) -> void:
	_score.text = "SCORE: %d" % value


func _process(_delta: float) -> void:
	if _death_screen != null and _death_screen.visible:
		if Input.is_action_just_pressed("respawn"):
			manager._respawn()
	
	
	if player._is_powered:
		if manager.fancy == true:
			_camera_fun()
			cameras.visible = true
			cameras2.visible = true
		head.cull_mask = 25
		overlay.visible = true
		light.visible = true

	else:
		head.cull_mask = 5
		overlay.visible = false
		light.visible = false
		cameras.visible = false
		cameras2.visible = false

func show_death_screen() -> void:
	_death_screen.show()
func hide_death_screen() -> void:
	_death_screen.hide()
	
func _camera_fun() -> void:
	cam1.global_position = cam1.global_position.lerp(head.global_position, .15)
	cam1.global_basis = cam1.global_basis.slerp(head.global_basis, .35)
	cam2.global_basis = cam2.global_basis.slerp(head.global_basis, .45)
	cam2.global_position = cam2.global_position.lerp(head.global_position, .25)
