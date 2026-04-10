extends Node3D

@onready var hud = $HUD
@onready var gridmap = $GridMap
@onready var minimap = $MiniCam
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var grid = gridmap.get_meshes()
	var vectors = []
	var ysort = []
	var zsort = []
	var full = []
	var counter = 0
	for i in range(grid.size()):
		if (i%2) == 0:
			vectors.append([grid[i]])
		else:
			vectors[(i-1)/2].append(grid[i])
	for i in range(vectors.size()):
		vectors.sort_custom(sorty)
	for i in range(vectors.size()):
		if i == 0:
			ysort.append([vectors[i]])
		else:
			if ysort[counter][0][0].origin.y != vectors[i][0].origin.y:
				counter += 1
				ysort.append([vectors[i]])
			else:
				ysort[counter].append(vectors[i])
	for j in range(ysort.size()):
		zsort.append([])
		ysort[j].sort_custom(sortz)
		counter = 0

		for i in range(ysort[j].size()):
			if i == 0:
				zsort[j].append([ysort[j][i]])
			else:
				if not zsort[j][counter]:
					counter += 1
					zsort[j].append([ysort[j][i]])
				elif zsort[j][counter][0][0].origin.z != ysort[j][i][0].origin.z:
					if abs(ysort[j][i][0].origin.z - zsort[j][counter][0][0].origin.z) > 6:
						var blanks = (abs(ysort[j][i][0].origin.z - zsort[j][counter][0][0].origin.z) / 6) - 1
						for k in blanks:
							counter += 1
							zsort[j].append([])
					else:
						counter += 1
						zsort[j].append([ysort[j][i]])
				else:
					zsort[j][counter].append(ysort[j][i])
	
	for i in range(zsort.size()):
		print(zsort[i].size())
	print("i am gay and done")
	for i in range(zsort[0].size()):
		print(zsort[0][i].size())
		
	
	minimap.size = 90
	hud.display_camera(minimap)
	hud.camerahide()
	pass # Replace with function body.
func sorty(a, b):
	if a[0].origin.y < b[0].origin.y:
		return true
	return false

func sortz(a,b):
	if a[0].origin.z < b[0].origin.z:
		return true
	return false
	
func sortx(a,b):
	if a[0].origin.x < b[0].origin.x:
		return true
	return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		hud.camerashow()
	if event.is_action_released("map"):
		hud.camerahide()
	
