extends Node3D
@onready var gridmap = $"../GridMap"      
@onready var pelletcontrol = $"../Altars"  
@onready var player = get_tree().get_first_node_in_group("player")


const AI_SCENES: Dictionary = {
	"blinky":   preload("res://scenes/characters/blinky.tscn"),
	"pinky":    preload("res://scenes/characters/pinky.tscn"),
	"clyde":    preload("res://scenes/characters/clyde.tscn")
}

var SCATTER_TIMER = 160

var astar = AStar3D.new()
var scatter = false
var full = []
var up = false
var down = false
var left = false
var right = false
var movetimer: float = 0.5
var scattertimer = SCATTER_TIMER
var spawntimer: int = 40
var manager = null
var reserved_points: Dictionary = {}

func _ready() -> void:
	_build_array()
#	save_array(full, "res://leveldata")
	manager = get_tree().get_first_node_in_group("game_manager")
#	full = load_array("res://leveldata")
	print("array built")
	_populate_astar()
	print("astar populated")
	_neighbor_find()
	print("neighbors found")

func _process(delta: float) -> void:
	if manager == null:
		return
	if movetimer > 0:
		movetimer -= delta
	else:
		movetimer = manager.get_move_time()
		reserved_points.clear()
		scattertimer -= 1
		spawntimer -= 1
		if not has_node("Blinky"):
			_spawn_ai("blinky")
		elif not has_node("Pinky"):
			_spawn_ai("pinky")
		elif not has_node("Clyde"):
			_spawn_ai("clyde")
	if scattertimer < 1:
		scatter = true
	if scattertimer < 0:
		scatter = false
		scattertimer = SCATTER_TIMER
	if spawntimer < 0:
		spawntimer = manager.get_spawn_timer()
		_spawn_ai(manager.next_ai_type())

func _spawn_ai(type: String) -> void:
	var ai_instance = AI_SCENES[type].instantiate()
	add_child(ai_instance)

func try_reserve(id, ai):
	if reserved_points.has(id):
		return false
	reserved_points[id] = ai
	return true
	
func release_point(id, ai):
	if reserved_points.get(id) == ai:
		reserved_points.erase(id)


#--------- array creation --------------------------------------------------------------

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

func _build_array():
	var grid = gridmap.get_meshes()
	var vectors = []
	var ysort = []
	var zsort = []
	var counter = 0
	print("meshes got")
	for i in range(grid.size()):
		if (i%2) == 0:
			vectors.append([grid[i]])
		else:
			vectors[(i-1)/2].append(grid[i].resource_name)
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

#----- astar shit -----------------------------------------------------------
func rampcheck(tile):
	if tile in ["Pagoda_Ramp_Lower_Cube_019",
"Pagoda_Ramp_Upper_Cube_016",
"2x3_Ramp_Bottom_Cube_024",
"2x3_Ramp_Middle_Cube_028",
"2x3_Ramp_Top_Cube_029"]:
		return false
	return true
	
func _populate_astar():
	var counter = 1
	for i in range(full.size()):
		for j in range(full[i].size()):
			for k in range(full[i][j].size()):
				if full[i][j][k]:
					if (full[i][j][k][1] != "Bound_Wall_Cube_013") and (full[i][j][k][1] != "Pagoda_Wall_Window_Corner_Cube_031"):
						counter += 1
						if full[i][j][k][1] == "Pagoda_Ramp_Lower_Cube_019":
							var temp = full[i][j][k][0].origin
							temp.y += 1.3
							astar.add_point(counter, temp, 1.0)
						elif full[i][j][k][1] == "Pagoda_Ramp_Upper_Cube_016":
							var temp = full[i][j][k][0].origin
							temp.y += 4.5
							astar.add_point(counter, temp, 1.0)
						elif full[i][j][k][1] == "2x3_Ramp_Bottom_Cube_024":
							var temp = full[i][j][k][0].origin
							temp.y += 2.3
							astar.add_point(counter, temp, 1.0)
						elif full[i][j][k][1] == "2x3_Ramp_Middle_Cube_028":
							var temp = full[i][j][k][0].origin
							temp.y += 6.2
							astar.add_point(counter, temp, 1.0)
						elif full[i][j][k][1] == "2x3_Ramp_Top_Cube_029":
							var temp = full[i][j][k][0].origin
							temp.y += 10.1
							astar.add_point(counter, temp, 1.0)
						else:
							astar.add_point(counter, full[i][j][k][0].origin, 1.0)
						full[i][j][k].append(counter)
					else: full[i][j][k].append([])

func _neighbor_find():
	for i in range(full.size()):
		for j in range(full[i].size()):
			for k in range(full[i][j].size()):
				var current = full[i][j][k]
				if j != 0:
					if full[i][j-1][k] and full[i][j-1][k][2]:
						up = full[i][j-1][k]
					else: up = false
				else: up = false
				if j < full[i].size() -1:
					if full[i][j+1][k] and full[i][j+1][k][2]:
						down = full[i][j+1][k]
					else: down = false
				else: down = false
				if k != 0:
					if full[i][j][k-1] and full[i][j][k-1][2]:
						left = full[i][j][k-1]
					else: left = false
				else: left = false
				if k < full[i][j].size() -1:
					if full[i][j][k+1] and full[i][j][k+1][2]:
						right = full[i][j][k+1]
					else: right = false
				else: right = false
				if current:
					if current[2]:
						if current[1] == "Floor_Tile_Cube":
							if down and rampcheck(down[1]):
								astar.connect_points(current[2], down[2])
							if up and rampcheck(up[1]):
								astar.connect_points(current[2], up[2])
							if right and rampcheck(right[1]):
								astar.connect_points(current[2], right[2])
							if left:
								astar.connect_points(current[2], left[2])
						if current[1] == "Single_Wall_Tile_Cube_006":
							if current[0].basis.z.x > 0:
								if down and rampcheck(down[1]):
									astar.connect_points(current[2], down[2])
								if left and rampcheck(left[1]):
									astar.connect_points(current[2], left[2])
								if up and rampcheck(up[1]):
									astar.connect_points(current[2], up[2])
							elif current[0].basis.z.x < 0:
								if up and rampcheck(up[1]):
									astar.connect_points(current[2], up[2])
								if right and rampcheck(right[1]):
									astar.connect_points(current[2], right[2])
								if down and rampcheck(down[1]):
									astar.connect_points(current[2], down[2])
							elif current[0].basis.z.z > 0:
								if left and rampcheck(left[1]):
									astar.connect_points(current[2], left[2])
								if up and rampcheck(up[1]):
									astar.connect_points(current[2], up[2])
								if right and rampcheck(right[1]):
									astar.connect_points(current[2], right[2])
							elif current[0].basis.z.z < 0:
								if down and rampcheck(down[1]):
									astar.connect_points(current[2], down[2])
								if right and rampcheck(right[1]):
									astar.connect_points(current[2], right[2])
								if left and rampcheck(left[1]):
									astar.connect_points(current[2], left[2])
							else:
								print("YOU HAVE FUCKED UP")
						if current[1] == "Corridor_Tile_Cube_003":
							if abs(current[0].basis.z.x) > 0:
								if up:
									astar.connect_points(current[2], up[2])
								if down:
									astar.connect_points(current[2], down[2])
							elif abs(current[0].basis.z.z) > 0:
								if left:
									astar.connect_points(current[2], left[2])
								if right:
									astar.connect_points(current[2], right[2])
							else:
								print("YOU HAVE FUCKED UP")
						if current[1] in ["Corner_Tile_Cube_002", "Corner_Hole_One_Cube_002", "Corner_Hole_Two_Cube_005"]:
							if current[0].basis.z.z > 0:
								if up and rampcheck(up[1]):
									astar.connect_points(current[2], up[2])
								if left and rampcheck(left[1]):
									astar.connect_points(current[2], left[2])
							elif current[0].basis.z.z < 0:
								if down and rampcheck(down[1]):
									astar.connect_points(current[2], down[2])
								if right and rampcheck(right[1]):
									astar.connect_points(current[2], right[2])
							elif current[0].basis.z.x > 0:
								if down and rampcheck(down[1]):
									astar.connect_points(current[2], down[2])
								if left and rampcheck(left[1]):
									astar.connect_points(current[2], left[2])
							elif current[0].basis.z.x < 0:
								if up and rampcheck(up[1]):
									astar.connect_points(current[2], up[2])
								if right and rampcheck(right[1]):
									astar.connect_points(current[2], right[2])
							else:
								print("YOU HAVE FUCKED UP")
						if current[1] in ["Pagoda_Ramp_Lower_Cube_019", "2x3_Ramp_Bottom_Cube_024", "2x3_Ramp_Middle_Cube_028"]:
							if abs(current[0].basis.z.z) > 0:
								if up:
									astar.connect_points(current[2], up[2], true)
								if down:
									astar.connect_points(current[2], down[2], true)
							elif abs(current[0].basis.z.x) > 0:
								if left:
									astar.connect_points(current[2], left[2], true)
								if right:
									astar.connect_points(current[2], right[2], true)
							else:
								print("YOU HAVE FUCKED UP")
						if current[1] == "Pagoda_Ramp_Upper_Cube_016":
							if current[0].basis.z.z > 0:
								astar.connect_points(current[2], full[i+1][j+1][k][2])
							elif current[0].basis.z.z < 0:
								astar.connect_points(current[2], full[i+1][j-1][k][2])
							elif current[0].basis.z.x > 0:
								astar.connect_points(current[2], full[i+1][j][k+1][2])
							elif current[0].basis.z.x < 0:
								astar.connect_points(current[2], full[i+1][j][k-1][2])
							else:
								print("YOU HAVE FUCKED UP")
						if current[1] == "2x3_Ramp_Top_Cube_029":
							if current[0].basis.z.z > 0:
								astar.connect_points(current[2], full[i+2][j+1][k][2])
							elif current[0].basis.z.z < 0:
								astar.connect_points(current[2], full[i+2][j-1][k][2])
							elif current[0].basis.z.x > 0:
								astar.connect_points(current[2], full[i+2][j][k+1][2])
							elif current[0].basis.z.x < 0:
								astar.connect_points(current[2], full[i+2][j][k-1][2])
							else:
								print("YOU HAVE FUCKED UP")
func save_array(my_array: Array, path: String):
	# Open the file for writing (creates it if it doesn't exist)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_var(my_array) # Stores the entire array in binary format
		file.close()

func load_array(path: String) -> Array:
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var my_array = file.get_var()
		file.close()
		return my_array
	return []
