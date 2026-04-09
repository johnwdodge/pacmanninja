extends Node3D

@onready var hud = $HUD
@onready var minimap = $MiniCam
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	minimap.size = 90
	hud.display_camera(minimap)
	hud.camerahide()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		hud.camerashow()
	if event.is_action_released("map"):
		hud.camerahide()
	
