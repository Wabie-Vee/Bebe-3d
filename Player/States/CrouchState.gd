extends BaseState

@export var crouch_height := 1
@export var crouch_speed := 3.0
@export var camera_offset := Vector3(0, -0.3, 0)

var footstep_timer := 0.0
var footstep_interval := 0.4
var original_height := 0.0
var original_camera_offset := Vector3.ZERO

func enter(player):
	var collider = player.get_node("CollisionShape3D")
	var tween = player.create_tween()

	original_height = collider.shape.height
	original_camera_offset = player.camera_rig.position

	var new_camera_position = original_camera_offset
	new_camera_position.z += camera_offset.z  # Only modify Z

	tween.set_parallel()
	tween.tween_property(collider.shape, "height", crouch_height, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(player.camera_rig, "position", new_camera_position, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	player.move_speed = crouch_speed

func exit(player):
	var collider = player.get_node("CollisionShape3D")
	var tween = player.create_tween()

	tween.set_parallel()
	tween.tween_property(collider.shape, "height", original_height, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	tween.tween_property(player.camera_rig, "position", original_camera_offset, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	player.move_speed = player.original_move_speed

func physics_update(player, delta):
	if player.jump_pressed and player.is_on_floor():
		player.state_machine.set_state("JumpState")
		return

	if not player.is_on_floor():
		player.state_machine.set_state("FallState")
		return


	var cam_basis = player.pivot.global_transform.basis
	var forward = -cam_basis.z
	var right = cam_basis.x
	var direction = (right * player.input_direction.x) + (forward * player.input_direction.z)
	direction = direction.normalized()

	var speed = player.move_speed
	if player.sprinting:
		player.state_machine.set_state("RunState")

	player.velocity.x = lerp(player.velocity.x, direction.x * speed, player.slide_factor * delta)
	player.velocity.z = lerp(player.velocity.z, direction.z * speed, player.slide_factor * delta)

	var target_rotation = atan2(direction.x, direction.z) + PI
	player.mesh.rotation.y = lerp_angle(player.mesh.rotation.y, target_rotation, player.rotation_speed * delta)



	
func handle_input(player, event):
	if Input.is_action_just_pressed("key_crouch") and player.can_stand():
		player.state_machine.set_state("IdleState")
	
	
