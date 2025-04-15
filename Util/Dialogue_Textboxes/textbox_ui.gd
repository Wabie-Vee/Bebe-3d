extends CanvasLayer

@onready var panel = $Panel
@onready var label = $Panel/RichTextLabel

var tween : Tween
var is_showing := false
var full_text := ""
var current_index := 0
var parsed_chunks := []

func _ready():
	visible = false
	panel.scale = Vector2(0, 0)
	label.bbcode_enabled = true

func toggle_message(text: String):
	is_showing = !is_showing

	if is_showing:
		full_text = text
		visible = true
		panel.scale = Vector2(0, 0)
		label.text = ""

		parsed_chunks = _build_bbcode_frames(full_text)
		current_index = 0

		tween = create_tween()
		tween.tween_property(panel, "scale", Vector2(1, 1), 0.25)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		await tween.finished
		start_typewriter()
	else:
		tween = create_tween()
		tween.tween_property(panel, "scale", Vector2(0, 0), 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await tween.finished
		visible = false

func start_typewriter():
	if current_index >= parsed_chunks.size():
		return

	label.text = parsed_chunks[current_index]
	current_index += 1
	await get_tree().create_timer(0.03).timeout
	start_typewriter()

func _build_bbcode_frames(text: String) -> Array:
	var frames := []
	var open_tags := []
	var current_text := ""
	var i = 0

	while i < text.length():
		if text[i] == "[":
			var end = text.find("]", i)
			if end == -1:
				break
			var tag = text.substr(i, end - i + 1)
			current_text += tag

			if tag.begins_with("[/"):
				if open_tags.size() > 0:
					open_tags.pop_back()
			else:
				open_tags.append(tag)

			i = end + 1
		else:
			var temp = current_text + text[i]
			for j in range(open_tags.size() - 1, -1, -1):
				temp += open_tags[j].replace("[", "[/")
			frames.append(temp)
			current_text += text[i]
			i += 1

	return frames
