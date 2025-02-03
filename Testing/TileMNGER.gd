extends Node3D

@export var json_file_paths: Array = [
	"res://Maps/newmapset/map0.json",
	"res://Maps/newmapset/map1.json",
	"res://Maps/newmapset/map2.json",
	"res://Maps/newmapset/map3.json",
	"res://Maps/newmapset/map4.json",
	"res://Maps/newmapset/map5.json",
	"res://Maps/newmapset/map6.json",
	"res://Maps/newmapset/map7.json",
	]
@export var tile_scene: Dictionary = {
	1: preload("res://Scenes/Tile.tscn"),
	2: preload("res://Scenes/DoorTile.tscn"),
	3: preload("res://Scenes/SpawnTile.tscn"),
	4: preload("res://Scenes/Tile.tscn")
}

@export var map_display_horizontal = false

var Room: Node3D
var tile_radius: float = 1.0
var grid_width: int
var grid_height: int
var tile_x = 0
var tile_y = 0

func _ready():
	
	#functions for loading board if no board is found
	for index in range(json_file_paths.size()):
		var room = Node3D.new()
		room.name = "Room" + str(index)
		add_child(room)
		load_json(json_file_paths[index], room)
		var scene_name = room.name
		var scene_path = "res://Maps/MapOut/" + scene_name + ".tscn"
		save_scene(scene_path, room)
		
		
	if Global.DebugPrint:
		print_tree_pretty()

	
func load_json(json_file_path: String, room: Node3D):
	var file = FileAccess.open(json_file_path, FileAccess.READ)
	if file:
		var data = file.get_as_text()
		var grid_data = JSON.parse_string(data)
		file.close()

		grid_width = grid_data["settings"]["grid_width"]
		grid_height = grid_data["settings"]["grid_height"]
		if Global.DebugPrint:
			print("Grid ", grid_width,"x", grid_height)

		for tile in grid_data["tiles"]:
			var x = int(tile["x"])
			var y = int(tile["y"])
			var value = int(tile["value"])

			if value == 0:
				continue
			
			if value in tile_scene:
				var tile_instance = tile_scene[value].instantiate()
				var mesh_instance = tile_instance.get_node("Hextiles")
				if mesh_instance and mesh_instance.mesh:
					tile_radius = calculate_radius(mesh_instance.mesh)
					tile_instance.transform.origin = calculate_position(x,y)
					
					if value == 1:
						tile_instance.name = "Floor_%d_%d" % [x,y]
					elif value == 2:
						tile_instance.name = "Door_%d_%d" % [x,y]
					elif value == 3:
						tile_instance.name = "Spawn_%d_%d" % [x,y]
					if value == 4:
						tile_instance.name = "Floor_%d_%d" % [x,y]
						tile_instance.set_meta("center", true)
						tile_instance.set_meta("lw", Vector2(grid_data["settings"]["grid_width"], grid_data["settings"]["grid_height"]))
					
					room.add_child(tile_instance)
					if Global.DebugPrint:
						print("Added tile at: (", x, ",", y, ")")
				elif Global.DebugPrint:
					print("no tile mesh")
			elif Global.DebugPrint:
				print("Unknown tile value: ", value)
	elif Global.DebugPrint:
		print("Couldn't open JSON file: ", json_file_path)


func calculate_position(x: int, y: int) -> Vector3:
	var hex_width = (tile_radius * 2) * 0.9
	var hex_height = (tile_radius * sqrt(3)) * 0.9
	
	var grid_x_pos = x * hex_width
	var grid_y_pos = y * hex_height
	if y % 2 == 0:
		grid_x_pos += hex_width / 2
	return Vector3(grid_x_pos, 0, grid_y_pos)

func calculate_radius(mesh: Mesh) -> float:
	if mesh is ArrayMesh and mesh.get_surface_count() > 0:
		var arrays = mesh.surface_get_arrays(0)
		var vertices = arrays[Mesh.ARRAY_VERTEX]
		if vertices and vertices.size() > 1:
			var radius = (vertices[0] - vertices[1]).length()
			return radius
	if Global.DebugPrint:
		print("Failed to calculate radius. Using default")
	return tile_radius
	
func save_scene(save_path: String, room: Node3D):
	if room.get_child_count() == 0:
		if Global.DebugPrint:
			print("Warning: tiles_parent has no children")
		return
	elif Global.DebugPrint:
		print("Room children: ", room.get_child_count())
		
	for child in room.get_children():
		child.set_owner(room)
		
	var scene = PackedScene.new()
	var result = scene.pack(room)
	if result == OK:
		var error = ResourceSaver.save(scene, save_path)
		if error == OK:
			if Global.DebugPrint:
				print("Scene saved to ", save_path)
		elif error != OK:
			if Global.DebugPrint:
				print("Couldn't save scene to ", save_path, "Error code: ", error)
	elif Global.DebugPrint:
		print("Failed to pack scene")
