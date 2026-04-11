extends Node3D

@onready var hud = $HUD
@onready var gridmap = $GridMap
@onready var minimap = $MiniCam
var full = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var grid = gridmap.get_meshes()
	var vectors = []
	var ysort = []
	var zsort = []
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
				if zsort[j][counter][0][0].origin.z != ysort[j][i][0].origin.z:
						counter += 1
						zsort[j].append([ysort[j][i]])
				else:
					zsort[j][counter].append(ysort[j][i])

	for k in range(zsort.size()):
		counter = 0
		full.append([])
		for j in range(zsort[k].size()):
			full[k].append([])
			zsort[k][j].sort_custom(sortx)
			counter = 0
			#################################################
			for i in range(zsort[k][j].size()):
				if i == 0:
					full[k][j].append(zsort[k][j][i])
				else:
					if not full[k][j].back():
						full[k][j].append(zsort[k][j][i])
					elif abs(zsort[k][j][i][0].origin.x - full[k][j].back()[0].origin.x) > 6:
						var blanks = (abs(zsort[k][j][i][0].origin.x - full[k][j].back()[0].origin.x) / 6) - 1
						for l in blanks:
							full[k][j].append([])
						full[k][j].append(zsort[k][j][i])
					else:
						full[k][j].append(zsort[k][j][i])
	
	print(full[4])
#	for i in range(full.size()):
#		print(zsort[i].size())
#	print("i am gay and done")
#	for i in range(full.size()):
#		for j in range(full[i].size()):
#			print(full[i].size())
		
	
	minimap.size = 90
	hud.display_camera(minimap)
	hud.camerahide()
#	var gay = []
#	print(gay[1])
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
	
