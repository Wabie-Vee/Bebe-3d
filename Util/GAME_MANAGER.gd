extends Node
class_name GAME_MANAGER

signal scene_changed(new_scene_name)

var current_level_name := ""
var is_game_paused := false

var talked_to := {}  # { "Penumbra": true, ... }
var quest_flags := {}  # { "found_capsule": true, ... }
var quests := {
	"capsule_quest": {
		"stage": 0,
		"completed": false
	}
}

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
		
func has_talked_to(npc_name: String) -> bool:
	return talked_to.get(npc_name, false)

func set_talked_to(npc_name: String):
	talked_to[npc_name] = true

func set_quest_flag(flag: String, value: bool = true):
	quest_flags[flag] = value

func get_quest_flag(flag: String) -> bool:
	return quest_flags.get(flag, false)
	
func register_quest(id: String, initial_stage := 0):
	if not quests.has(id):
		quests[id] = {
			"stage": initial_stage,
			"completed": false
		}

func get_quest_stage(id: String) -> int:
	return quests.get(id, {}).get("stage", -1)

func set_quest_stage(id: String, stage: int):
	if quests.has(id):
		quests[id]["stage"] = stage

func complete_quest(id: String):
	if quests.has(id):
		quests[id]["completed"] = true

func is_quest_complete(id: String) -> bool:
	return quests.get(id, {}).get("completed", false)
