extends Node
@onready var graphics = $CanvasLayer/graphics
@onready var volume = $CanvasLayer/volume
@onready var fullscreen = $CanvasLayer/fullscreen
@onready var _return: Button = $CanvasLayer/Return
@onready var manager = get_tree().get_first_node_in_group("game_manager")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	fullscreen.toggled.connect(_on_fullscreen_toggled)
	graphics.toggled.connect(_on_graphics_toggled)
	volume.value_changed.connect(_audio_changed)
	_return.pressed.connect(manager.open_main_menu)
	pass
	

	
func _audio_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("music"), linear_to_db(value))


func _on_graphics_toggled(state) -> void:
	manager.fancy = state

func _on_fullscreen_toggled(state) -> void:
	var mode := DisplayServer.window_get_mode()
	var is_window: bool = mode != DisplayServer.WINDOW_MODE_FULLSCREEN
	if state:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
