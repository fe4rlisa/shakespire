extends MeshInstance3D

var rotation_speed: float = 1.0


func _process(delta):
	var rotation_angle = rotation_speed * delta
	
	rotation_degrees.y += rotation_angle * 180.0 / PI  # Convert from radians to degrees
	rotation_degrees.x += (rotation_angle * 0.4) * 180.0 / PI  # Convert from radians to degrees
