extends CharacterBody3D

@export var move_speed := 8.0
@export var jump_velocity := 10.0
@export var gravity := -24.8
@export var rotation_speed := 8.0  # feel free to tweak
@export var sprint_speed := move_speed * 1.5

@export var mouse_sensitivity := 0.002

@onready var pivot = $Pivot
@onready var cam_pivot = $Pivot/CameraPivot
@onready var mesh = $MeshInstance3D
@onready var sprinting = false
@onready var debug_hud



func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		cam_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-40), deg_to_rad(30))

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	debug_hud = get_tree().get_root().find_child("DebugHUD", true, false)
	debug_hud.set_text("Speed: " + str(velocity.length()))	

func _physics_process(delta: float) -> void:
	var input_direction = Vector3(
		Input.get_axis("move_left", "move_right"),
		0,
		- Input.get_axis("move_forward", "move_back")
	).normalized()
	
	sprinting = Input.is_action_pressed("move_sprint")

	# Get camera-relative basis
	var cam_basis = pivot.global_transform.basis
	var forward = -cam_basis.z
	var right = cam_basis.x

	# Camera-relative movement direction
	var direction = (right * input_direction.x) + (forward * input_direction.z)
	direction.y = 0
	direction = direction.normalized()

	# Apply to velocity (change target velocity based on if sprinting)
	var slide_factor = 5.0  # tweak to your liking

	var target_velocity: Vector3
	if !sprinting:
		target_velocity = direction * move_speed
	else:
		target_velocity = direction * sprint_speed  # <-- Make sure you define sprint_speed!

	velocity.x = lerp(velocity.x, target_velocity.x, slide_factor * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, slide_factor * delta)
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	elif velocity.y < 0:
		velocity.y = 0

	# Jump
	if is_on_floor() and Input.is_action_just_pressed("move_jump"):
		velocity.y = jump_velocity

	move_and_slide()
	
	if direction.length() > 0.1:
		var target_rotation = atan2(direction.x, direction.z) + PI  # 💡 add PI to flip
		var current_rotation = mesh.rotation.y
		var new_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)
		mesh.rotation.y = new_rotation
		
