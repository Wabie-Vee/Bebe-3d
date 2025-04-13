# Player.gd
extends CharacterBody3D

@export var move_speed := 8.0
@export var sprint_speed := move_speed * 1.5
@export var gravity := -24.8
@export var slide_factor := 5.0
@export var jump_velocity := 10.0
@export var min_jump_time := 0.1
@export var max_jump_hold_time := 0.25
@export var jump_gravity_scale := 0.3
@export var rotation_speed := 8.0
@export var mouse_sensitivity := 0.002

@export var sfx_jump : AudioStream
@export var sfx_footstep : AudioStream

#pickup objects
@onready var hold_point = $Pivot/CameraPivot/CameraRig/HoldPoint
var held_object: Node3D = null

@onready var sfx_footstep_player = $SFXFootstep
@onready var sfx_jump_player = $SFXJump
@onready var sfx_player = $PlayerSFX
@onready var pivot = $Pivot
@onready var cam_pivot = $Pivot/CameraPivot
@onready var game_camera = $Pivot/CameraPivot/CameraRig/GameCamera
@onready var mesh = $MeshInstance3D
@onready var state_machine = preload("res://PlayerStateMachine.gd").new(self)

@onready var debug_hud = get_tree().get_root().find_child("DebugHUD", true, false)
@onready var debug_label = debug_hud.get_node("DebugLabel") if debug_hud else null
@onready var debug_mode = false

#camera settings
@export var base_fov := 75
var max_fov := base_fov + 10
var fov_transition_speed := 10.0

var max_z_speed_for_fov := 10.0  # how fast Bebe can go forward/back

#headbob settings
var headbob_timer := 0.0
var headbob_frequency := 20.0
var headbob_amplitude := 0.1
var headbob_enabled := true
@onready var headbob_origin = game_camera.transform.origin

#camera lean
var camera_lean_angle := 0.0
var max_lean_angle := deg_to_rad(2.5)
var lean_speed := 5.0

var is_jumping := false
var jump_held_time := 0.0

var input_direction := Vector3.ZERO
var jump_pressed := false
var can_double_jump := true
var sprinting := false
var look_delta := Vector2.ZERO

func _ready():
	print("SFX JUMP AT READY:", sfx_jump)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	state_machine._ready()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	state_machine._ready()

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		look_delta = event.relative
	state_machine._unhandled_input(event)

func _physics_process(delta):
	#pickup object
	if Input.is_action_just_pressed("key_interact"):
		if held_object:
			drop_object()
		else:
			try_pickup()
	
	#debug toggle
	if Input.is_action_just_pressed("key_debug"):
		debug_mode = !debug_mode
	
	#unlock mouse
	if Input.is_action_just_pressed("key_escape"):
		if not (state_machine.current_state is LockedState):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.is_action_just_pressed("mouse_left_click"):
		if not (state_machine.current_state is LockedState):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Handle input
	input_direction = Vector3(
		Input.get_axis("move_left", "move_right"),
		0,
		-Input.get_axis("move_forward", "move_back")
	).normalized()

	jump_pressed = Input.is_action_just_pressed("move_jump")
	sprinting = Input.is_action_pressed("move_sprint")

	# Apply mouse look
	pivot.rotate_y(-look_delta.x * mouse_sensitivity)
	cam_pivot.rotate_x(-look_delta.y * mouse_sensitivity)
	cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	look_delta = Vector2.ZERO

	# Run state logic
	state_machine._physics_process(delta)
	move_and_slide()
	
	# 1. Get strafe direction relative to camera
	var cam_basis = pivot.global_transform.basis
	var local_velocity = cam_basis.inverse() * velocity

	# 2. Get lean value
	var strafe_amount = clamp(local_velocity.x / move_speed, -1.0, 1.0)
	var target_lean = -strafe_amount * max_lean_angle
	camera_lean_angle = lerp(camera_lean_angle, target_lean, lean_speed * delta)

	# 3. Apply clean roll rotation to camera using basis rebuild
	var camera_basis = Basis()
	camera_basis = Basis(Vector3(0, 0, 1), camera_lean_angle) # roll only
	camera_basis = camera_basis.orthonormalized()

	# 4. Combine with the existing transform rotation (pitch/yaw from camera rig)
	game_camera.rotation_degrees.z = rad_to_deg(camera_lean_angle)

	
	# Head bob logic
	if headbob_enabled and is_on_floor() and velocity.length() > 0.1:
		headbob_timer += delta * headbob_frequency

		var bob_offset = Vector3(
			0,
			sin(headbob_timer) * headbob_amplitude,
			0
		)

		var target_pos = headbob_origin + bob_offset
		game_camera.transform.origin = lerp(
			game_camera.transform.origin,
			target_pos,
			10 * delta
		)
	else:
		# Smoothly return to original camera position
		game_camera.transform.origin = lerp(
			game_camera.transform.origin,
			headbob_origin,
			5 * delta
		)
		
		# Get the current horizontal velocity magnitude
	var horizontal_velocity = velocity
	horizontal_velocity.y = 0.0

	var speed = horizontal_velocity.length()

	# Get the camera's basis to find its forward direction
	cam_basis = pivot.global_transform.basis
	var forward_dir = -cam_basis.z.normalized()

	# Project velocity onto the forward direction
	var forward_speed = velocity.dot(forward_dir)

	# Take the absolute value to respond to both forward and backward movement
	var forward_speed_abs = abs(forward_speed)

	# Normalize and clamp it
	var t = clamp(forward_speed_abs / max_z_speed_for_fov, 0.0, 1.0)
	var target_fov = lerp(base_fov, max_fov, t)

	# Smooth transition
	game_camera.fov = lerp(game_camera.fov, target_fov, fov_transition_speed * delta)
	
	if debug_label != null and debug_mode:
		debug_label.text = (
			"FPS: %d\n" % Engine.get_frames_per_second() +
			"Velocity: %.2f\n" % velocity.length() +
			"On Floor: %s\n" % str(is_on_floor()) +
			"Sprinting: %s\n" % str(sprinting) +
			"State: %s\n" % state_machine.current_state.get_script().resource_path.get_file().get_basename()
		)
	else:
		debug_label.text = ""
		
		#pickup objects
func try_pickup():
	
	var space_state = get_world_3d().direct_space_state
	var from = game_camera.global_position
	var to = from + game_camera.global_transform.basis.z * -2  # 2 units forward
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	#query.collision_mask = 1  # Only use this if you're using layers!
	
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result and result.collider.is_in_group("pickable"):
		held_object = result.collider
		held_object.is_held = true
		held_object.sleeping = true
		held_object.freeze = true
		held_object.set_deferred("collision_layer", 0)
		held_object.set_deferred("collision_mask", 0)
		held_object.get_parent().remove_child(held_object)
		hold_point.add_child(held_object)
		held_object.transform = held_object.transform.looking_at(hold_point.global_transform.origin, Vector3.UP)
		held_object.transform.origin = Vector3.ZERO
		
func drop_object():
	held_object.get_parent().remove_child(held_object)
	get_tree().get_root().add_child(held_object)
	held_object.global_transform = hold_point.global_transform
	held_object.sleeping = false
	held_object.freeze = false
	held_object.set_deferred("collision_layer", 1)
	held_object.set_deferred("collision_mask", 1)
	held_object.is_held = false
	held_object = null

	
		

func lock_player():
	state_machine.set_state("LockedState")

func unlock_player():
	state_machine.set_state("IdleState")



func play_jump_sfx():
	if sfx_jump and is_instance_valid(sfx_jump_player):
		sfx_jump_player.stream = sfx_jump
		sfx_jump_player.play()

func play_footstep_sfx():
	if sfx_footstep and not sfx_footstep_player.playing:
		sfx_footstep_player.stream = sfx_footstep
		sfx_footstep_player.play()
 
