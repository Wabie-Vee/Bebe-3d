extends CanvasLayer

@onready var debug_label = $DebugLabel

func set_text(text: String) -> void:
	if debug_label != null:
		debug_label.text = text
