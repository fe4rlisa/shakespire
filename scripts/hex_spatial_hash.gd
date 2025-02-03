extends Node

var spatial_hash: Dictionary = {}
var hex_tile = preload("res://Scenes/Tile.tscn")
var hex_tile_radius: float = 0.0
var hex_width: float = 0.0
var hex_height: float = 0.0
var board_size: Array = [51,51]

func _ready() -> void:
	var tile_instance = hex_tile.instantiate()
	var mesh_instance = tile_instance.get_node("Hextiles")
	init_dimension(mesh_instance.mesh)
	generate_spatial_hash()
	
	#print(spatial_hash[Vector2(3,9)]["position"])
	#print(spatial_hash)
	#print(spatial_hash[Vector2(32,18)])

func init_dimension(mesh: Mesh):
	hex_tile_radius = calculate_radius(mesh)
	hex_width = hex_tile_radius * 2 * 0.9
	hex_height = hex_tile_radius * sqrt(3) * 0.9

func calculate_radius(mesh: Mesh) -> float:
	if mesh is ArrayMesh and mesh.get_surface_count() > 0:
		var arrays = mesh.surface_get_arrays(0)
		var vertices = arrays[Mesh.ARRAY_VERTEX]
		if vertices and vertices.size() > 1:
			var radius = (vertices[0] - vertices[1]).length()
			return radius
	return hex_tile_radius

func calculate_position(x: int, y: int) -> Vector2:
	var x_offset = x * hex_width
	var y_offset = y * hex_height
	if y % 2 == 0:
		x_offset += hex_width / 2
	return Vector2(x_offset, y_offset)

func calculate_vec3(x: int, y:int) -> Vector3:
	var x_offset = x * hex_width
	var y_offset = y * hex_height
	if y % 2 == 0:
		x_offset += hex_width / 2
	return Vector3(x_offset, 0, y_offset)

func generate_spatial_hash():
	spatial_hash.clear()
	var width = board_size[0]
	var height = board_size[1]
	
	for y in range(height):
		for x in range(width):
			spatial_hash[Vector2(x - board_size[0]/2,y - board_size[1]/2)] = {
				"x": x - board_size[0]/2,
				"y": y - board_size[1]/2,
				"value": 0,
				"vec2": calculate_position(x,y),
				"position": calculate_vec3(x,y),
				"is visible": false,
				"tile_instance": null
			}
			
			##    Visualize spatial hash grid
			#var meshinstance3d = MeshInstance3D.new()
			#var sphere_mesh = SphereMesh.new()
			#meshinstance3d.mesh = sphere_mesh
			#meshinstance3d.position = calculate_vec3(x,y)
			#add_child(meshinstance3d)
			######

func add_room(room_instance: Node, door_val: int, floor_val: int, visible: bool):
	for child in room_instance.get_children():
		if child is Node3D:
			var child_pos = child.global_transform.origin
			var closest_key = find_closest_key(child_pos)
			
			if closest_key != null:
				var tile_type = floor_val
				if child.name.contains("Door"):
					tile_type = door_val
				elif child.name.contains("Spawn"):
					tile_type = 3
				if spatial_hash.has(closest_key):
					spatial_hash[closest_key]["value"] = tile_type
					spatial_hash[closest_key]["tile_instance"] = child
					if visible:
						spatial_hash[closest_key]["is visible"] = true
					elif !visible:
						spatial_hash[closest_key]["is visible"] = false

func find_closest_key(world_pos: Vector3) -> Vector2:
	var closest_key: Vector2 = Vector2()
	var closest_distance = INF
	var found = false
	
	for key in spatial_hash.keys():
		var hash_pos = spatial_hash[key]["position"]
		var distance = world_pos.distance_to(hash_pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_key = key
			found = true
	if found:
		return closest_key
	else:
		return Vector2()

func get_neighbors(tile_pos: Vector2) -> Array:
	var offsets = [
		Vector2(1,0),
		Vector2(1,-1),
		Vector2(0,-1),
		Vector2(-1,0),
		Vector2(-1,1),
		Vector2(0,1),
	]
	var neighbors = []
	var seen = {}
	for offset in offsets:
		var neighbor_pos_2d = tile_pos + offset
		if neighbor_pos_2d in HexSpatialHash.spatial_hash and not seen.has(neighbor_pos_2d):
			#var neighbor_pos_3d = HexSpatialHash.spatial_hash[neighbor_pos_2d]["position"]
			neighbors.append(neighbor_pos_2d)
			seen[neighbor_pos_2d] = true
	return neighbors

func find_entries(target_key: String, target_val) -> Array:
	var matching_entries = []
	for key in spatial_hash.keys():
		var entry = spatial_hash[key]
		if entry.has(target_key) and entry[target_key] == target_val:
			matching_entries.append(entry)
	return matching_entries


func offset_distance(a: Vector2, b: Vector2) -> int:
	var ac = offset_to_axial(a)
	var bc = offset_to_axial(b)
	var axial_vector = Vector2(ac.x - bc.x, ac.y - bc.y)
	return (abs(axial_vector.x)
		+ abs(axial_vector.x + axial_vector.y)
		+ abs(axial_vector.y)) / 2

func offset_to_axial(offset_coords: Vector2):
	var x = offset_coords.x
	var y = offset_coords.y
	var q = x - int(y / 2) if y % 2 == 0 else x - int((y + 1) / 2)
	var r = y
	return Vector2(q,r)
