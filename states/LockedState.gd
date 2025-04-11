# res://states/LockedState.gd
extends BaseState
class_name LockedState

func physics_update(player, delta):
	player.velocity = Vector3.ZERO
