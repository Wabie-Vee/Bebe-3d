extends Area3D
class_name Interactable

@export_range(0, 1) var face_threshold := 0.6

@onready var icon = $InteractIcon
@onready var animator = $AnimationPlayer

var player_in_range = false
var player_ref = null
var can_interact = false
var reading = false
var reading_input_cooldown = 0.2  # seconds


@export var dialog = [
	"hi there!",
	"this is the second textbox!",
	"okay now this is the last one..."
]
var dialog_index = 0
var ui_manager = null



func _ready():
	icon.visible = false
	animator.stop()
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	
func _enter():
	if not player_ref or reading:
		return

	ui_manager = get_tree().get_root().find_child("TextboxUI", true, false)
	if ui_manager:
		dialog_index = 0
		reading_input_cooldown = 0.2  # prevent input immediately after entering
		_show_next_line()
		player_ref.lock_player()
		if player_ref.has_node("UI"):
			player_ref.UI.visible = false
		reading = true
	
func _process(delta):
	if reading:
		if reading_input_cooldown > 0:
			reading_input_cooldown -= delta
		elif Input.is_action_just_pressed("key_interact"):
			_show_next_line()

func highlight(_player_ref):
	if not icon.visible:
		icon.visible = true
		animator.play("Bounce")
	player_ref = _player_ref
	can_interact = true
	
	print("Highlight called on:", self)

func unhighlight():
	if icon.visible:
		icon.visible = false
		animator.stop()
	can_interact = false

func _hide_icon():
	if icon.visible:
		icon.visible = false
		animator.stop()
	can_interact = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		player_ref = null
		_hide_icon()


func _show_next_line():
	if dialog_index < dialog.size():
		ui_manager.show_message(dialog[dialog_index])
		dialog_index += 1
	else:
		_exit()

func _exit():
	ui_manager.hide_message()
	if player_ref:
		player_ref.unlock_player()
		if player_ref.has_node("UI"):
			player_ref.UI.visible = true
	reading = false
