extends Node3D
var player_ref = null
var player_in_range = false
@onready var interactable: Interactable = $Interactable
@onready var look_at_modifier_3d: LookAtModifier3D = $char_grp/rig/Skeleton3D/LookAtModifier3D

		
func _physics_process(delta: float) -> void:
	if player_ref != null:
		print("Camera rig path:", player_ref.camera_rig)
		look_at_modifier_3d.target_node = player_ref.camera_rig.get_path()
	else:
		look_at_modifier_3d.target_node = NodePath("")
		


func _on_interactable_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("Body Entered")
		player_ref = body
		player_in_range = true



func _on_interactable_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		player_ref = null
		
