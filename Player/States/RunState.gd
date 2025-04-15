extends BaseState
class_name RunState

var footstep_timer := 0.0
var footstep_interval := 0.3

func enter(player):
	footstep_timer = 0.0
	
func handle_input(player, event):
	if event.is_action_pressed("key_crouch"):
		player.state_machine.set_state("CrouchState")

func physics_update(player, delta):
	if player.jump_pressed and player.is_on_floor():
		player.state_machine.set_state("JumpState")
		return

	if not player.is_on_floor():
		player.state_machine.set_state("FallState")
		return

	if player.input_direction.length() <= 0.1:
		player.state_machine.set_state("IdleState")
		return

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

	var target_rotation = atan2(direction.x, direction.z) + PI
	player.mesh.rotation.y = lerp_angle(player.mesh.rotation.y, target_rotation, player.rotation_speed * delta)

	# Footstep sound
