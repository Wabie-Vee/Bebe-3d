extends Node3D

# === Variables ===
var player_ref: Node3D = null
var player_in_range: bool = false

@export var look_speed: float = 4.0

# === Node References ===
@onready var interactable: Interactable = $Interactable
@onready var look_at_default: Marker3D = $LookAtDefault
@onready var look_at_final: Marker3D = $LookAtDefault/LookAtFinal
@onready var look_at_modifier_3d: LookAtModifier3D = $char_grp/rig/Skeleton3D/LookAtModifier3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	animation_player.play("BunnyIdle")
	
# === Physics Loop ===
func _physics_process(delta: float) -> void:
	if player_ref != null:
		look_at_final.global_position = look_at_final.global_position.lerp(
			player_ref.game_camera.global_position,
			look_speed * delta
		)
	else:
		look_at_final.global_position = look_at_final.global_position.lerp(
			look_at_default.global_position,
			look_speed * delta
		)
# === Signal Callbacks ===
func _on_interactable_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("Body Entered")
		player_ref = body
		player_in_range = true

func _on_interactable_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		player_ref = null
