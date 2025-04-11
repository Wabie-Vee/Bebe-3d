extends Area3D

@export var message: String = "This is a sign. 👀"

var player_in_range = false
var ui_manager  # We'll set this later (where the textbox lives)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	ui_manager = get_tree().get_root().find_child("TextboxUI", true, false)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("PLAYER IN RANGE (via group)!")
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		print("PLAYER LEFT RANGE")
		player_in_range = false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("key_interact"):
		print("Interacted!")
		if ui_manager != null:
			ui_manager.toggle_message(message)
