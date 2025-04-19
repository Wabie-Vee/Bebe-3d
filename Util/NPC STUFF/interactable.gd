extends Area3D
class_name Interactable

@export_range(0, 1) var face_threshold := 0.6

@onready var icon = $Control/FingerPoint
@onready var animator = $Control/FingerPoint/AnimationPlayer
@onready var control = $Control
@onready var label = $Control/RichTextLabel
@onready var textbox = $Control/TextureRect/AnimatedSprite2D
@export var voice: AudioStream 
@export var voice_volume : float = 1.0


var player_in_range = false
var player_ref = null
var can_interact = false
var reading = false
var reading_input_cooldown = 0.2  # seconds
var line_skip_cooldown = 0.0

@export var dialog = [
	"[wave]hi there![/wave]",
	"this is the [color=blue]second[/color] textbox!",
	"[shake]okay now this is the last one...[/shake]"
]
var dialog_index = 0
var finished = false
var ui_manager = null
var tween: Tween = null

# NEW: Blip tracking
var visible_char_count = 0
var last_visible_ratio = 0.0

func _ready():
	control.visible = false
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _process(delta):
	if can_interact and player_in_range and not reading:
		if Input.is_action_just_pressed("key_interact"):
			_enter()

	if label.visible_ratio >= 1:
		icon.visible = true
		animator.play("IDLE")
		textbox.play("default")
	else:
		icon.visible = false

	if reading:
		if reading_input_cooldown > 0:
			reading_input_cooldown -= delta
		else:
			if line_skip_cooldown > 0:
				line_skip_cooldown -= delta
			elif Input.is_action_just_pressed("key_interact"):
				if label.visible_ratio < 1:
					if tween:
						tween.kill()
					label.visible_ratio = 1
				else:
					load_dialog()

		# 🔊 Blip trigger logic (every other character)
		var current_char = int(round(label.visible_ratio * visible_char_count))
		var last_char = int(round(last_visible_ratio * visible_char_count))

		if current_char > last_char and current_char % 2 == 0 and voice:
			SoundManager.stop_sfx(voice)
			SoundManager.play_sfx(voice, true, voice_volume)

		last_visible_ratio = label.visible_ratio

func highlight(_player_ref):
	player_ref = _player_ref
	can_interact = true
	print("Highlight called on:", self)

func unhighlight():
	can_interact = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		player_ref = null

func _enter():
	if not player_ref or reading:
		control.visible = true
		return

	ui_manager = get_tree().get_root().find_child("TextboxUI", true, false)
	if ui_manager:
		dialog_index = 0
		reading_input_cooldown = 0.2
		load_dialog()
		player_ref.lock_player()
		if player_ref.has_node("UI"):
			player_ref.UI.visible = false
		reading = true

func load_dialog():
	control.visible = true

	if dialog_index < dialog.size():
		label.visible_ratio = 0.0
		label.bbcode_text = dialog[dialog_index]

		# Strip BBCode for char count
		var regex = RegEx.new()
		regex.compile("\\[.*?\\]")
		var plain_text = regex.sub(dialog[dialog_index], "", true)
		visible_char_count = plain_text.length()

		# Kill previous tween if it's still running
		if tween:
			tween.kill()

		var duration_per_char = 0.05  # seconds per character
		var duration = visible_char_count * duration_per_char

		tween = create_tween()
		tween.tween_property(label, "visible_ratio", 1.0, duration)

		line_skip_cooldown = 0.0

		dialog_index += 1
	else:
		_exit()

func _exit():
	ui_manager.hide_message()
	control.visible = false

	if player_ref:
		player_ref.unlock_player()
		if player_ref.has_node("UI"):
			player_ref.UI.visible = true

	reading = false
