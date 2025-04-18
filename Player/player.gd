extends CharacterBody3D

#region === UI ===
@onready var reticle = $UI/TextureRect

@export var default_reticle: Texture2D
@export var hover_reticle: Texture2D
#endregion

#region === CONFIGURATION ===
@export var original_move_speed := 6
@export var sprint_multiplier := 1.4
@onready var move_speed := original_move_speed
@onready var sprint_speed := move_speed * sprint_multiplier
@onready var bebe_anim = $BebePivot/BebeBear/AnimationPlayer
@onready var anim_tree = $BebePivot/BebeBear/AnimationTree
@onready var animation_tree = $BebePivot/BebeBear/AnimationTree
@onready var move_blend_path := "parameters/MoveBlend/blend_position"
@onready var anim_speed = original_move_speed
var current_anim_state := ""
@export var gravity := -24.8
@export var slide_factor := 5.0
@export var jump_velocity := 5.0
@export var min_jump_time := 0.1
@export var max_jump_hold_time := 0.25
@export var jump_gravity_scale := 0.3
@export var rotation_speed := 8.0
@export var mouse_sensitivity := 0.002
@export var turn_threshold := 5.0
@export var turn_speed := 5.0

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
@onready var bebe_mesh = $BebePivot/BebeBear
@onready var bebe_pivot = $BebePivot
@onready var UI = $UI
@onready var pickup_handler = $PickupHandler
@onready var state_machine = preload("res://Player/PlayerStateMachine.gd").new(self)
@onready var debug_hud = $DebugHUD
@onready var debug_label = debug_hud.get_node("DebugLabel") if debug_hud else null

@onready var debug_raycast: Node3D = null

enum CursorState{
	NONE,
	TALK,
	GRAB
}

var cursor_state = CursorState.NONE
@onready var reticle_sprite = $UI/TextureRect

var debug_mode := false

var vertical_look_angle := 0.0 # Put this in your internal vars section

var max_fov := base_fov + 10
var fov_transition_speed := 10.0
var max_z_speed_for_fov := 10.0

var headbob_timer := 0.0
@onready var headbob_amplitude := 0.05
var headbob_enabled := true

var last_headbob_value := 0.0
var footstep_played_this_cycle := false

@onready var headbob_origin = game_camera.transform.origin

#=== RAYCAST ===
@onready var raycast = $Pivot/CameraPivot/CameraRig/GameCamera/RayCast3D
var current_target = null

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
	can_double_jump = false;
	
	var space_state = get_world_3d().direct_space_state
	var from = game_camera.global_position
	var to = from + game_camera.global_transform.basis.z * -2

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]  # or player

	var result = space_state.intersect_ray(query)

	
	handle_inputs()
	handle_raycast()
	update_cursor_state()
	handle_camera_look()
	handle_bebe_pivot(delta)
	state_machine._physics_process(delta)
	move_and_slide()
	apply_camera_lean(delta)
	handle_headbob(delta)
	update_fov(delta)
	update_debug_text()
	var move_speed = velocity.length()
	
	
	if animation_tree:
		animation_tree.set("parameters/MoveBlend/blend_position", velocity.length())
	else:
		print("⚠️ AnimationTree is null! Check the node path.")
		
	anim_speed = move_speed # adjust divisor to match "normal" walk speed

	animation_tree.set("parameters/MoveBlend/Walk/time_scale", anim_speed)
#endregion



func handle_bebe_pivot(delta):
	var pivot_yaw = wrapf(pivot.rotation_degrees.y, 0, 360)
	var bebe_yaw = wrapf(bebe_pivot.rotation_degrees.y, 0, 360)
	var angle_diff = abs(pivot_yaw - bebe_yaw)
	
	if angle_diff > turn_threshold:
		# Convert degrees to radians since .rotation uses radians
		var target_yaw = deg_to_rad(pivot_yaw)
		var current_yaw = bebe_pivot.rotation.y
		bebe_pivot.rotation.y = lerp_angle(current_yaw, target_yaw, delta * turn_speed)
	

		
func handle_raycast():
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		var found_interactable = null
		var possible = hit

		# Search up to 5 levels of parents and their children
		for i in range(5):
			if possible == null:
				break

			# Check if current node is an Interactable
			if possible is Interactable:
				found_interactable = possible
				break

			# Recursive child search (inlined)
			var stack = possible.get_children()
			while not stack.is_empty():
				var child = stack.pop_back()
				if child is Interactable:
					found_interactable = child
					break
				stack += child.get_children()

			if found_interactable != null:
				break

			# Move up to the parent
			possible = possible.get_parent()

		# Handle interaction logic
		if found_interactable and found_interactable.player_in_range:
			if current_target and current_target != found_interactable:
				current_target.unhighlight()

			current_target = found_interactable
			current_target.highlight(self)

			if Input.is_action_just_pressed("key_interact") and not current_target.reading:
				if cursor_state == CursorState.TALK:
					current_target._enter()
		else:
			if current_target:
				current_target.unhighlight()
				current_target = null
	else:
		if current_target:
			current_target.unhighlight()
			current_target = null

#region === INPUT HANDLING ===

func update_cursor_state():
	var new_state = CursorState.NONE

	if raycast.is_colliding():
		var hit = raycast.get_collider()
		var possible = hit
		for i in range(5):
			if possible == null:
				break
			if possible.is_in_group("interactable"):
				new_state = CursorState.TALK
				break
			elif possible.is_in_group("pickable"):
				new_state = CursorState.GRAB
				break
			possible = possible.get_parent()

	if new_state != cursor_state:
		cursor_state = new_state
		update_reticle_sprite()
		
func update_reticle_sprite():
	match cursor_state:
		CursorState.NONE:
			reticle_sprite.texture = preload("res://Textures/UI/Cursor.png")
		CursorState.TALK:
			reticle_sprite.texture = preload("res://Textures/UI/CursorSpeak.png")
		CursorState.GRAB:
			reticle_sprite.texture = preload("res://Textures/UI/CursorSelect.png")

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
	
	vertical_look_angle += -look_delta.y * mouse_sensitivity
	vertical_look_angle = clamp(vertical_look_angle, deg_to_rad(-80), deg_to_rad(80))
	
	game_camera.rotation.x = vertical_look_angle
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
	var headbob_frequency
	if !sprinting:
		headbob_frequency = move_speed * 4
	else:
		headbob_frequency = move_speed * 10
	if headbob_enabled and is_on_floor() and velocity.length() > 0.1:
		headbob_timer += delta * headbob_frequency
		var bob_value = sin(headbob_timer)
		var y_offset = bob_value * headbob_amplitude
		var current_pos = cam_pivot.transform.origin
		var target_y = headbob_origin.y + y_offset
		current_pos.y = lerp(current_pos.y, target_y, 10 * delta)
		cam_pivot.transform.origin = current_pos

		# === Footstep sync logic ===
		# Detect when sine wave is coming *up* from its lowest point
		if last_headbob_value < -0.95 and bob_value >= last_headbob_value and not footstep_played_this_cycle:
			SoundManager.play_sfx(sfx_footstep, true)
			footstep_played_this_cycle = true

		# Reset once sine wave has gone back above 0 (cycle complete)
		if bob_value > 0.1:
			footstep_played_this_cycle = false

		last_headbob_value = bob_value
	else:
		var current_pos = cam_pivot.transform.origin
		current_pos.y = lerp(current_pos.y, headbob_origin.y, 5 * delta)
		cam_pivot.transform.origin = current_pos

		# Reset footstep cycle if we stop moving
		last_headbob_value = 0.0
		footstep_played_this_cycle = false

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
			"State: %s\n" % state_machine.current_state.get_script().resource_path.get_file().get_basename() +
			"Looking At: %s" % debug_raycast
			
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
