extends Node3D

@onready var player = get_node("/root/Player")
@onready var player_start = $PlayerStart

func _ready():
	player.global_transform.origin = player_start.global_transform.origin
	player.look_at(player_start.global_transform.origin + Vector3.FORWARD)
