extends Node
class_name GAME_MANAGER

signal scene_changed(new_scene_name)

var current_level_name := ""
var is_game_paused := false

func _ready():
	get_tree().paused = false
	current_level_name = get_tree().current_scene.name
	print("GAME_MANAGER booted in scene: ", current_level_name)
	
func toggle_pause():
	is_game_paused = !is_game_paused
	get_tree().paused = is_game_paused
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if is_game_paused else Input.MOUSE_MODE_CAPTURED)
	
func load_scene(scene_path: String):
	if ResourceLoader.exists(scene_path):
		var packed_scene = load(scene_path)
		get_tree().change_scene_to_packed(packed_scene)
		current_level_name = scene_path.get_file().get_basename()
		emit_signal("scene_changed", current_level_name)
	else:
		push_error("scene does not exist: " + scene_path)
