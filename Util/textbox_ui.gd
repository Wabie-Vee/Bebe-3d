extends CanvasLayer

@onready var label = $Panel/RichTextLabel

func _ready():
	visible = false
	
func show_message(text: String):
	visible = true
	label.text = text
	
func hide_message():
	visible = false
