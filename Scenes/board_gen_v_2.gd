extends Node3D

var start_room = preload("res://Maps/StartMaps/Room0.tscn")
var available_rooms = []
var room_select_range = 0

@export var number_of_rooms = 14
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
	align_room(instance, Vector2(0,0))
	
	
	for num in number_of_rooms:
		instance = load(get_rand_room()).instantiate()
		add_child(instance)
		align_room(instance, random_room_pos(instance))
		
		pass
	pass

func room_middle(room_instance: Node) -> NodePath:
	for child in room_instance.get_children():
		if child.has_meta("center") and child.get_meta("center") == true:
			print("found center: ", child.get_path())
			return child.get_path()
	print("Couldn't find center, make sure it's set!")
	return NodePath()
func room_door(room_instance: Node) -> Array:
	var doors = []
	for child in room_instance.get_children():
		if child.name.contains("Door"):
			doors += child.get_path()
	return doors

func get_rand_room() -> String:
	var random_index = randi_range(0, room_select_range - 1)
	return available_rooms[random_index]
func random_room_pos(room_instance: Node) -> Vector2:
	for child in room_instance.get_children():
		if child.has_meta("lw"):
			var room_x = HexSpatialHash.board_size[0] / 2
			var room_y = HexSpatialHash.board_size[1] / 2
			var node_x = child.get_meta("lw")[0]  # /2  ???
			var node_y = child.get_meta("lw")[1]  # /2  ???
			var room_pos = Vector2(randi_range((room_x * -1) + node_x, room_x - node_x), randi_range((room_y * -1) + node_y, room_y - node_x))
			return room_pos
	print("didn't find a position!!!")
	return Vector2()

func align_room(room_instance: Node, target_position_2d: Vector2):
	var middle_node_path = room_middle(room_instance)
	var middle_node = room_instance.get_node(middle_node_path)
	var middle_position = middle_node.global_transform.origin
	
	var target_position = HexSpatialHash.spatial_hash[target_position_2d]["position"]
	var position_difference = target_position - middle_position
	room_instance.global_transform.origin += position_difference
	
	for child in room_instance.get_children():
		if child is Node3D:

			#Get closest grid position and snap room to grid
			var child_position = child.global_transform.origin
			var closest_key = HexSpatialHash.find_closest_key(child_position)
			if closest_key in HexSpatialHash.spatial_hash:
				var closest_position = HexSpatialHash.spatial_hash[closest_key]["position"]
				child.global_transform.origin = closest_position
				
	if intersecting(room_instance):
		print("intersecting room, removing ", room_instance.name)
		room_instance.queue_free()
	else:
		print("adding room...")
		HexSpatialHash.add_room(room_instance, 2, 1, false)
 
func intersecting(room_instance: Node) -> bool:
	var filled_tiles = HexSpatialHash.find_entries("value", 1)
	filled_tiles += HexSpatialHash.find_entries("value", 2)
	
	var child_2D
	
	for child in room_instance.get_children():
		if child is Node3D:
			var child_position = child.global_transform.origin
			child_2D = HexSpatialHash.find_closest_key(child_position)
			
	for tile in filled_tiles:
		if child_2D == Vector2(tile["x"], tile["y"]):
			print("Intersecting tiles at ", child_2D)
			return true
	return false
