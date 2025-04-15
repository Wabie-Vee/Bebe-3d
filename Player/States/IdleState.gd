# res://states/IdleState.gd
extends BaseState
class_name IdleState
func physics_update(player, delta):
	if player.jump_pressed and player.is_on_floor():
		player.state_machine.set_state("JumpState")
		return

	if not player.is_on_floor():
		player.state_machine.set_state("FallState")
		return

	if player.input_direction.length() > 0.1:
		player.state_machine.set_state("RunState")
		return

	player.velocity.x = 0
	player.velocity.z = 0
