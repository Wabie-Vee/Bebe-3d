extends CanvasLayer


@onready var label = $Panel/RichTextLabel


var is_showing = false

func _ready():
	visible = false

func toggle_message(text: String):
	is_showing = !is_showing
	visible = is_showing
	if is_showing:
		label.text = text
