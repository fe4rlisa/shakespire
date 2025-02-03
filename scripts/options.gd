extends Control


func _ready() -> void:
	if Global.DebugPrint:
		$Print.text = "Debug Print: ON"
	else:
		$Print.text = "Debug Print: OFF"



func _on_settings_pressed() -> void:
	pass # Replace with function body.



func _on_print_pressed() -> void:
	Global.DebugPrint = not Global.DebugPrint
	if Global.DebugPrint:
		$Print.text = "Debug Print: ON"
	else:
		$Print.text = "Debug Print: OFF"



func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")
