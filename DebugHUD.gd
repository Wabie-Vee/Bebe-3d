extends CanvasLayer

@onready var debug_label = $DebugLabel

func _ready():
	print("Label found?", debug_label)

func set_text(text: String) -> void:
	debug_label.text = text
