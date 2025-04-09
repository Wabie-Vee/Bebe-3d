extends CharacterBody3D

#region Movement Config
@export var move_speed := 8.0
@export var sprint_speed := move_speed * 1.5
@export var gravity := -24.8
@export var slide_factor := 5.0
#endregion

#region Jump Config
@export var jump_velocity := 10.0
@export var min_jump_time := 0.1
@export var max_jump_hold_time := 0.25
@export var jump_gravity_scale := 0.3
var jump_held_time := 0.0
var is_jumping := false
#endregion

#region Camera Config
@export var rotation_speed := 8.0
@export var mouse_sensitivity := 0.002
#endregion

#region State
@onready var sprinting = false
var debug_mode := false
var debug_text := ""
#endregion

#region Node References
@onready var pivot = $Pivot
@onready var cam_pivot = $Pivot/CameraPivot
@onready var mesh = $MeshInstance3D
@onready var debug_hud
#endregion


#region Input Handling
func _unhandled_input(event):
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		cam_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-40), deg_to_rad(30))

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#endregion


#region Ready Setup
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	debug_hud = get_tree().get_root().find_child("DebugHUD", true, false)
	if debug_hud != null:
		debug_hud.set_text("Debug HUD ready")
	else:
		print("⚠️ Could not find DebugHUD")
#endregion


#region Physics Processing
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("mouse_left_click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	var input_direction = Vector3(
		Input.get_axis("move_left", "move_right"),
		0,
		-Input.get_axis("move_forward", "move_back")
	).normalized()

	sprinting = Input.is_action_pressed("move_sprint")

	# toggle debug mode
	if Input.is_action_just_pressed("key_debug"):
		debug_mode = !debug_mode
		print("Debug mode toggled:", debug_mode)

	# Camera-relative movement
	var cam_basis = pivot.global_transform.basis
	var forward = -cam_basis.z
	var right = cam_basis.x
	var direction = (right * input_direction.x) + (forward * input_direction.z)
	direction.y = 0
	direction = direction.normalized()

	# Target movement velocity
	var target_velocity: Vector3
	if sprinting:
		target_velocity = direction * sprint_speed
	else:
		target_velocity = direction * move_speed
	velocity.x = lerp(velocity.x, target_velocity.x, slide_factor * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, slide_factor * delta)

	# Gravity
	if not is_on_floor():
		# Apply reduced gravity if jump is held
		if is_jumping and Input.is_action_pressed("move_jump") and jump_held_time < max_jump_hold_time:
			velocity.y += gravity * jump_gravity_scale * delta
			jump_held_time += delta
		else:
			velocity.y += gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0
		is_jumping = false

	# Jump Start
	if is_on_floor() and Input.is_action_just_pressed("move_jump"):
		velocity.y = jump_velocity
		is_jumping = true
		jump_held_time = 0.0

	# Apply Movement
	move_and_slide()

	# Rotate Mesh
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z) + PI
		var current_rotation = mesh.rotation.y
		var new_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)
		mesh.rotation.y = new_rotation

	# Debug HUD Update
	debug_text = (
		"FPS: %d\n" % Engine.get_frames_per_second() +
		"Velocity: %.2f\n" % velocity.length() +
		"On Floor: %s\n" % str(is_on_floor()) +
		"Sprinting: %s" % str(sprinting)
	)

	if debug_hud != null and debug_mode:
		debug_hud.set_text(debug_text)
	elif debug_hud != null:
		debug_hud.set_text("")
		
#endregion
