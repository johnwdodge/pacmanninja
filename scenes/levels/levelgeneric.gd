extends Node3D

@onready var hud = $HUD
@onready var minimap = $MiniCam
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hud.display_camera(minimap)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
