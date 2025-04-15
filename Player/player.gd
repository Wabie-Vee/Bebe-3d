extends CharacterBody3D

#region === UI ===
@onready var reticle = $UI/TextureRect

@export var default_reticle: Texture2D
@export var hover_reticle: Texture2D
#endregion

#region === CONFIGURATION ===
@export var original_move_speed := 8.0
@onready var move_speed := original_move_speed
@onready var sprint_speed := move_speed * 1.5
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
@export_range(75,120) var base_fov := 75
#endregion

#region === INTERNAL VARS ===
@onready var hold_point = $Pivot/CameraPivot/CameraRig/HoldPoint
@onready var sfx_footstep_player = $SFXFootstep
@onready var sfx_jump_player = $SFXJump
@onready var sfx_player = $PlayerSFX
@onready var pivot = $Pivot
@onready var cam_pivot = $Pivot/CameraPivot
@onready var camera_rig = $Pivot/CameraPivot/CameraRig
@onready var game_camera = $Pivot/CameraPivot/CameraRig/GameCamera
@onready var mesh = $MeshInstance3D
@onready var UI = $UI
@onready var pickup_handler = $PickupHandler
@onready var state_machine = preload("res://Player/PlayerStateMachine.gd").new(self)
@onready var debug_hud = $DebugHUD
@onready var debug_label = debug_hud.get_node("DebugLabel") if debug_hud else null

var debug_mode := false

var max_fov := base_fov + 10
var fov_transition_speed := 10.0
var max_z_speed_for_fov := 10.0

var headbob_timer := 0.0
var headbob_frequency := 15.0
var headbob_amplitude := 0.1
var headbob_enabled := true
@onready var headbob_origin = game_camera.transform.origin

var camera_lean_angle := 0.0
var max_lean_angle := deg_to_rad(2.5)
var lean_speed := 5.0

var is_grabbing_smoothly := false

var is_jumping := false
var jump_held_time := 0.0
var input_direction := Vector3.ZERO
var jump_pressed := false
var can_double_jump := true
var sprinting := false
var look_delta := Vector2.ZERO
#endregion

#region === READY ===
func _ready():
	print("SFX JUMP AT READY:", sfx_jump)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	state_machine._ready()
#endregion

#region === INPUT ===
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		look_delta = event.relative
	state_machine._unhandled_input(event)
#endregion

#region === PHYSICS PROCESS ===
func _physics_process(delta):
	
	
	var space_state = get_world_3d().direct_space_state
	var from = game_camera.global_position
	var to = from + game_camera.global_transform.basis.z * -2

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]  # or player

	var result = space_state.intersect_ray(query)

	if result and result.collider.is_in_group("pickable") and pickup_handler.held_object == null:
		reticle.texture = hover_reticle
	else:
		reticle.texture = default_reticle
	handle_inputs()


	handle_camera_look()
	state_machine._physics_process(delta)
	move_and_slide()
	apply_camera_lean(delta)
	handle_headbob(delta)
	update_fov(delta)
	update_debug_text()
#endregion

#region === INPUT HANDLING ===
func handle_inputs():
	if Input.is_action_just_pressed("key_interact"):
		if pickup_handler.held_object:
			pickup_handler.drop_object()
		else:
			var grabbed = pickup_handler.try_pickup(self)
			if grabbed:
				is_grabbing_smoothly = true
				await pickup_handler.smooth_grab(grabbed)
				is_grabbing_smoothly = false

	if Input.is_action_just_pressed("key_debug"):
		debug_mode = !debug_mode

	if Input.is_action_just_pressed("key_escape"):
		if not (state_machine.current_state is LockedState):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.is_action_just_pressed("mouse_left_click"):
		if not (state_machine.current_state is LockedState):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	input_direction = Vector3(
		Input.get_axis("move_left", "move_right"),
		0,
		-Input.get_axis("move_forward", "move_back")
	).normalized()

	jump_pressed = Input.is_action_just_pressed("move_jump")
	sprinting = Input.is_action_pressed("move_sprint")
	
	if Input.is_action_just_pressed("key_restart"):
		var current_scene = get_tree().current_scene
		var scene_path = current_scene. scene_file_path
		get_tree().change_scene_to_file(scene_path)
	
#endregion

#region === CAMERA ===
func handle_camera_look():
	pivot.rotate_y(-look_delta.x * mouse_sensitivity)
	cam_pivot.rotate_x(-look_delta.y * mouse_sensitivity)
	cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	look_delta = Vector2.ZERO

func apply_camera_lean(delta):
	var cam_basis = pivot.global_transform.basis
	var local_velocity = cam_basis.inverse() * velocity
	var strafe_amount = clamp(local_velocity.x / move_speed, -1.0, 1.0)
	var target_lean = -strafe_amount * max_lean_angle
	camera_lean_angle = lerp(camera_lean_angle, target_lean, lean_speed * delta)
	game_camera.rotation_degrees.z = rad_to_deg(camera_lean_angle)

func update_fov(delta):
	var forward_dir = -pivot.global_transform.basis.z.normalized()
	var forward_speed = velocity.dot(forward_dir)
	var t = clamp(abs(forward_speed) / max_z_speed_for_fov, 0.0, 1.0)
	var target_fov = lerp(base_fov, max_fov, t)
	game_camera.fov = lerp(game_camera.fov, target_fov, fov_transition_speed * delta)
#endregion

#region === HEADBOB ===
func handle_headbob(delta):
	if headbob_enabled and is_on_floor() and velocity.length() > 0.1:
		headbob_timer += delta * headbob_frequency
		var bob_offset = Vector3(0, sin(headbob_timer) * headbob_amplitude, 0)
		var target_pos = headbob_origin + bob_offset
		game_camera.transform.origin = lerp(game_camera.transform.origin, target_pos, 10 * delta)
	else:
		game_camera.transform.origin = lerp(game_camera.transform.origin, headbob_origin, 5 * delta)
#endregion

#region === CAN STAND ===
func can_stand() -> bool:
	var from = global_transform.origin
	var to = from + Vector3.UP * 1.0  # Adjust height as needed

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]

	var result = get_world_3d().direct_space_state.intersect_ray(query)
	return result.is_empty()
#endregion

#region === DEBUG ===
func update_debug_text():
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
#endregion

#region === STATE LOCK/UNLOCK ===
func lock_player():
	state_machine.set_state("LockedState")

func unlock_player():
	state_machine.set_state("IdleState")
#endregion

#region === AUDIO ===
func play_jump_sfx():
	if sfx_jump and is_instance_valid(sfx_jump_player):
		sfx_jump_player.stream = sfx_jump
		sfx_jump_player.play()

func play_footstep_sfx():
	if sfx_footstep and not sfx_footstep_player.playing:
		sfx_footstep_player.stream = sfx_footstep
		sfx_footstep_player.play()
#endregion
