extends BaseState
class_name JumpState

func enter(player):

	SoundManager.play_sfx(player.sfx_jump, true)
	player.velocity.y = player.jump_velocity
	player.is_jumping = true
	player.jump_held_time = 0.0

func physics_update(player, delta):
	# 💫 Double jump
	if player.jump_pressed and player.can_double_jump:
		player.can_double_jump = false
		player.state_machine.set_state("JumpState")
		return # Don't run the rest of this frame's physics

	# 🧭 Directional movement in air
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

	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z) + PI
		player.mesh.rotation.y = lerp_angle(player.mesh.rotation.y, target_rotation, player.rotation_speed * delta)

	# ☁️ Variable jump height
	if player.is_jumping and Input.is_action_pressed("move_jump") and player.jump_held_time < player.max_jump_hold_time:
		player.velocity.y += player.gravity * player.jump_gravity_scale * delta
		player.jump_held_time += delta
	else:
		player.velocity.y += player.gravity * delta

	# 💥 Transition to falling when upward momentum is gone
	if player.velocity.y <= 0:
		player.state_machine.set_state("FallState")
