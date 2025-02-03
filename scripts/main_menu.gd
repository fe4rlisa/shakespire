extends Control

func _ready():
	pass


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Testing/test_rooms.tscn")




func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Options.tscn")




func _on_quit_pressed() -> void:
	get_tree().quit()
