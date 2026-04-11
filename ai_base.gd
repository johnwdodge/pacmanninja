extends Node3D
@onready var gridmap = $"../GridMap"
@onready var player = $"../charcontrol"
var astar = AStar3D.new()
var full = []
var up = false
var down = false
var left = false
var right = false
var MOVE_TIME = 0.5
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_build_array()
	_populate_astar()
	_neighbor_find()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	
	pass


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
	print(grid)
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
	if tile.resource_name in ["Pagoda_Ramp_Lower_Cube_019",
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
					if (full[i][j][k][1].resource_name != "Bound_Wall_Cube_013") and (full[i][j][k][1].resource_name != "Pagoda_Wall_Window_Corner_Cube_031"):
						counter += 1
						#1.3 and 4.5
						if full[i][j][k][1].resource_name == "Pagoda_Ramp_Lower_Cube_019":
							var temp = full[i][j][k][0].origin
							temp.y += 1.3
							astar.add_point(counter, temp, 1.0)
						elif full[i][j][k][1].resource_name == "Pagoda_Ramp_Upper_Cube_016":
							var temp = full[i][j][k][0].origin
							temp.y += 4.5
							astar.add_point(counter, temp, 1.0)
						else:
							astar.add_point(counter, full[i][j][k][0].origin, 1.0)
						full[i][j][k].append(counter)
						print(full[i][j][k][1].resource_name)
#						print(counter)
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
						if current[1].resource_name == "Floor_Tile_Cube":
#							print(current)
							#down
							if down and rampcheck(down[1]):
								astar.connect_points(current[2], down[2])
							#up
							if up and rampcheck(up[1]):
								astar.connect_points(current[2], up[2])
							#right
							if right and rampcheck(right[1]):
								astar.connect_points(current[2], right[2])
							#left
							if left:
								astar.connect_points(current[2], left[2])
						if current[1].resource_name == "Single_Wall_Tile_Cube_006":
							if current[0].basis.z.x > 0:
								#down left and right
								if down and rampcheck(down[1]):
									astar.connect_points(current[2], down[2])
								if left and rampcheck(left[1]):
									astar.connect_points(current[2], left[2])
								if up and rampcheck(up[1]):
									astar.connect_points(current[2], up[2])
							elif current[0].basis.z.x < 0:
								#up right left
								if up and rampcheck(up[1]):
									astar.connect_points(current[2], up[2])
								if right and rampcheck(right[1]):
									astar.connect_points(current[2], right[2])
								if down and rampcheck(down[1]):
									astar.connect_points(current[2], down[2])
							elif current[0].basis.z.z > 0:
								#down up right
								if left and rampcheck(left[1]):
									astar.connect_points(current[2], left[2])
								if up and rampcheck(up[1]):
									astar.connect_points(current[2], up[2])
								if right and rampcheck(right[1]):
									astar.connect_points(current[2], right[2])
							elif current[0].basis.z.z < 0:
								#down up left
								if down and rampcheck(down[1]):
									astar.connect_points(current[2], down[2])
								if right and rampcheck(right[1]):
									astar.connect_points(current[2], right[2])
								if left and rampcheck(left[1]):
									astar.connect_points(current[2], left[2])
							else:
								print("YOU HAVE FUCKED UP")
						if current[1].resource_name == "Corridor_Tile_Cube_003":
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
						if current[1].resource_name in ["Corner_Tile_Cube_002", "Corner_Hole_One_Cube_002", "Corner_Hole_Two_Cube_005"]:
							if current[0].basis.z.z > 0:
								#up and left
								if up and rampcheck(up[1]):
									astar.connect_points(current[2], up[2])
								if left and rampcheck(left[1]):
									astar.connect_points(current[2], left[2])
							elif current[0].basis.z.z < 0:
								#down left
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
							
						if current[1].resource_name in ["Pagoda_Ramp_Lower_Cube_019", "2x3_Ramp_Bottom_Cube_024, 2x3_Ramp_Middle_Cube_028"]:
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
						if current[1].resource_name == "Pagoda_Ramp_Upper_Cube_016":
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
#----- AI functions --------------------------------------------------
