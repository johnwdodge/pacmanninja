extends Node

@onready var _powered_label: Label = $CanvasLayer/Label
@onready var player = $"../charcontrol"
@onready var head = $"../charcontrol/Head/Camera"
@onready var _progress_bar: ProgressBar = $CanvasLayer/ProgressBar
@onready var _death_screen: Control = $CanvasLayer/DeathScreen
@onready var _combo_label: Label = $CanvasLayer/ComboLabel
@onready var cam1 = $CanvasLayer/cameras/cam1/fancycam
@onready var cam2 = $CanvasLayer/cameras/cam2/fancycam2
@onready var _score: Label = $CanvasLayer/Score

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
			get_tree().get_first_node_in_group("player").respawn()
	_camera_fun()
#	if player.is_powered:
		

func show_death_screen() -> void:
	_death_screen.show()
func hide_death_screen() -> void:
	_death_screen.hide()
	
func _camera_fun():
	cam1.global_position.lerp(head.global_position, .01)
#	cam1.basis.lerp(head.basis, .1)
	cam2.global_position.lerp(head.global_position, .015)
#	cam2.basis.lerp(head.basis, .15)
