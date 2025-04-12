extends Area3D

@export var message: String = "[b][wave amp = 50 freq=2]heyyy[/wave] somebody forgot to put some [shake][color=red]dialogue[/color][/shake] hereeee!!"
@onready var icon = $InteractIcon
@onready var animator = $AnimationPlayer

var player_in_range = false
var ui_manager  # We'll set this later (where the textbox lives)
var player_ref  # Cached reference to the player
var reading_sign = false

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
		icon.visible = true
		animator.play("Bounce")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		player_ref = null
		icon.visible = false
		animator.stop()

func _process(_delta):
	if player_in_range and player_ref != null and ui_manager != null:
		
		# 🔓 ESCAPE cancels reading
		if reading_sign and Input.is_action_just_pressed("key_escape"):
			_exit_reading()

		# 🪧 INTERACT toggles reading
		if Input.is_action_just_pressed("key_interact"):
			if reading_sign:
				_exit_reading()
			else:
				_enter_reading()


func _enter_reading():
	ui_manager.toggle_message(message)
	player_ref.lock_player()
	reading_sign = true


func _exit_reading():
	ui_manager.toggle_message("")  # Or use a hide/close method
	player_ref.unlock_player()
	reading_sign = false
