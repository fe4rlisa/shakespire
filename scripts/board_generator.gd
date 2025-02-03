extends Node3D

var start_room = preload("res://Maps/StartMaps/Room0.tscn")
var available_rooms = []
var room_select_range = 0

var placed_rooms = []
var used_doors = []

func _ready():
	load_rooms("res://Maps/MapOut/")
	generate_board()

func load_rooms(folder_path: String) -> void:
	var dir = DirAccess.open(folder_path)
	if not dir:
		push_error("invalid dir: " + folder_path)

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !file_name.begins_with(".") and !file_name.ends_with(".import"):
			var full_path = folder_path + file_name
			available_rooms.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
	room_select_range = len(available_rooms)

func generate_board():
	var instance = start_room.instantiate()
	add_child(instance)
	rand_rotation(instance)
	align_room(instance, Vector2(randi_range(-4,4),randi_range(-4,4)))
	HexSpatialHash.add_room(instance, 2, 1, true)
	placed_rooms.append(instance)
	
	for num in range(5):
		var room_instance = load(random_room()).instantiate()
		add_child(room_instance)
		rand_rotation(room_instance)
		var random_pos = get_random_pos(placed_rooms)
		place_room_randomly(room_instance, random_pos, used_doors)
		placed_rooms.append(room_instance)
	
	pass

func random_room() -> String:
	var random_index = randi_range(0, available_rooms.size()-1)
	return available_rooms[random_index]

func place_room_randomly(room_instance: Node, target_pos: Vector2, used_doors: Array) -> bool:
	var max_attempts = 6
	var success = false
	while max_attempts > 0 and not success:
		if not intersecting(room_instance, target_pos):
			align_room(room_instance, target_pos)
			HexSpatialHash.add_room(room_instance,2,1,false)
			success = true
		else:
			print("room intersects!")
			max_attempts -= 1
			target_pos = get_random_pos(placed_rooms)
	return success

func get_random_pos(placed_rooms: Array) -> Vector2:
	var room = placed_rooms[randi_range(0,placed_rooms.size() - 1)]
	var room_pos = HexSpatialHash.find_closest_key(room.global_transform.origin)
	var radius = 3
	var random_offset = Vector2(randi_range(-radius, radius), randi_range(-radius,radius))
	return room_pos + random_offset

func get_door(used_doors: Array) -> Vector2:
	var doors = HexSpatialHash.find_entries("value", 2)
	var available_doors = []
	
	for door in doors:
		var pos = Vector2(door["x"], door["y"])
		if pos not in used_doors:
			available_doors.append(pos)
	
	var random = randi_range(0, available_doors.size() - 1)
	var selected_door = available_doors[random]
	doors.erase(random)
	return selected_door


func rand_rotation(room_instance: Node):
	var random = randi_range(1,6)
	var rotation_amount = random * 60
	room_instance.rotate_y(deg_to_rad(rotation_amount))

func align_room(room_instance: Node, target_pos: Vector2):
	for child in room_instance.get_children():
		if child is Node3D:
			var tile_pos = child.global_transform.origin
			
			var target_pos_world = HexSpatialHash.spatial_hash[target_pos]["position"]
			var pos_diff = target_pos_world - tile_pos
			room_instance.global_transform.origin += pos_diff
			tile_pos = child.global_transform.origin

			var closest_key = HexSpatialHash.find_closest_key(tile_pos)
			if closest_key in HexSpatialHash.spatial_hash:
				var closest_position = HexSpatialHash.spatial_hash[closest_key]["position"]
				child.global_transform.origin = closest_position

func place_room(room_instance: Node, door_pos: Vector2) -> bool:
	var max_attempts = 6
	while max_attempts > 0:
		if not intersecting(room_instance, door_pos):
			align_room(room_instance, door_pos)
			HexSpatialHash.add_room(room_instance, 2, 1, false)
			return true
		print("room intersects!")
		room_instance.rotate_y(deg_to_rad(60))
		print("couldn't place, rotating...")
		max_attempts -= 1
	return false

func intersecting(room_instance: Node, target_pos: Vector2) -> bool:
	var used_tiles = HexSpatialHash.find_entries("value", 1)
	used_tiles += HexSpatialHash.find_entries("value", 2)
	
	var neighbors_to_check = []
	var all_checked_tiles = []
	
	var buffer_distance = 2
	
	for placed_room in placed_rooms:
		if placed_room != room_instance:
			var distance = placed_room.global_transform.origin.distance_to(room_instance.global_transform.origin)
			if distance < 0.1:
				return true
	
	for tile in used_tiles:
		if "position" in tile:
			var tile_pos_2d = HexSpatialHash.find_closest_key(tile["position"])
			var neighbors = HexSpatialHash.get_neighbors(tile_pos_2d)
			for neighbor in neighbors:
				neighbors_to_check.append(neighbor)
	
	for child in room_instance.get_children():
		if child is Node3D and child.name.contains("Floor") or child.name.contains("Door"):
			var tile_world_pos = child.to_global(Vector3.ZERO)
			
			var tile_pos_2d = child.global_transform.origin
			var target_pos_world = HexSpatialHash.spatial_hash[target_pos]["position"]
			var pos_diff = target_pos_world - tile_pos_2d
			tile_pos_2d = child.global_transform.origin + pos_diff
			tile_pos_2d = HexSpatialHash.find_closest_key(tile_pos_2d)
			
			for tile in used_tiles:
				if "position" in tile:
					var used_pos = tile["position"]
					if used_pos.distance_to(tile_world_pos) < 0.1:
						return true
			for neighbor_pos in neighbors_to_check:
				if tile_pos_2d == neighbor_pos:
					return true
	return false
