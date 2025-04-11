# res://states/FallState.gd
extends BaseState
class_name FallState

var has_double_jumped = false

func physics_update(player, delta):
	var cam_basis = player.pivot.global_transform.basis
	var forward = -cam_basis.z
	var right = cam_basis.x
	var direction = (right * player.input_direction.x) + (forward * player.input_direction.z)
	direction = direction.normalized()

	var speed = player.move_speed
	if player.sprinting:
		speed = player.sprint_speed

	player.velocity.x = lerp(player.velocity.x, direction.x * speed, player.slide_factor * delta)
	player.velocity.z = lerp(player.velocity.z, direction.z * speed, player.slide_factor * delta)

	player.velocity.y += player.gravity * delta
	
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z) + PI
		player.mesh.rotation.y = lerp_angle(player.mesh.rotation.y, target_rotation, player.rotation_speed * delta)
		
	if player.jump_pressed and player.can_double_jump:
		player.can_double_jump = false
		player.state_machine.set_state("JumpState")
	

	if player.is_on_floor():
		player.can_double_jump = true
		player.velocity.y = 0
		player.state_machine.set_state("IdleState")
