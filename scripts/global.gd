extends Node

var DebugPrint: bool = true

var Paused: bool = false

const CFG_PATH = "user://settings.cfg"

func _ready() -> void:
	#load_globals()
	pass

func save_globals() -> void:
	var config = ConfigFile.new()
	config.set_value("settings", "DebugPrint", DebugPrint)
	config.save(CFG_PATH)
		
func load_globals() -> void:
	var config = ConfigFile.new()
	if config.load(CFG_PATH) == OK:
		DebugPrint = config.get_value("settings", "DebugPrint", false)



func _on_tree_exiting() -> void:
	#save_globals()
	pass
