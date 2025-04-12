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
	cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-40), deg_to_rad(30))
	look_delta = Vector2.ZERO

	# Run state logic
	state_machine._physics_process(delta)
	move_and_slide()
	
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
