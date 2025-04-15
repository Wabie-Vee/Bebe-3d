extends Area3D

@export var message: String = "[b][wave amp = 50 freq=2]heyyy[/wave] somebody forgot to put some [shake][color=red]dialogue[/color][/shake] hereeee!!"
@export_range(0,1) var face_threshold := 0.6
@onready var icon = $InteractIcon
@onready var animator = $AnimationPlayer

var player_in_range = false
var ui_manager  # We'll set this later (where the textbox lives)
var player_ref  # Cached reference to the player
var reading_sign = false
var can_interact = false

func _ready():
	icon.visible = false
	animator.stop()
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	ui_manager = get_tree().get_root().find_child("TextboxUI", true, false)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body
		#icon.visible = true
		#animator.play("Bounce")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		player_ref = null
		#icon.visible = false
		#animator.stop()

func _process(_delta):
	# Allow exiting reading mode from anywhere, even if not looking at the sign
	if reading_sign and (Input.is_action_just_pressed("key_escape") or Input.is_action_just_pressed("key_interact")):
		_exit_reading()
		return

	# Normal sign detection logic
	if player_in_range and player_ref != null:
		var player_forward = -player_ref.camera_rig.global_transform.basis.z.normalized()
		var to_sign = (global_position - player_ref.camera_rig.global_position).normalized()
		var dot = player_forward.dot(to_sign)

		if dot > face_threshold:
			if not icon.visible:
				icon.visible = true
				animator.play("Bounce")
			can_interact = true
		else:
			if icon.visible:
				icon.visible = false
				animator.stop()
			can_interact = false
	else:
		if icon.visible:
			icon.visible = false
			animator.stop()
		can_interact = false

	# Only allow entering reading mode if not already reading
	if can_interact and not reading_sign and Input.is_action_just_pressed("key_interact"):
		_enter_reading()


func _enter_reading():
	if ui_manager and player_ref:
		ui_manager.toggle_message(message)
		player_ref.lock_player()
		if player_ref.has_node("UI"):
			player_ref.UI.visible = false
		reading_sign = true


func _exit_reading():
	ui_manager.toggle_message("")

	if player_ref != null:
		player_ref.unlock_player()
		if player_ref.has_node("UI"):
			player_ref.UI.visible = true

	reading_sign = false
