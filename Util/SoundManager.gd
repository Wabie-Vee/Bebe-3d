extends Node

enum Bus {
	SFX,
	MUSIC,
	UI
}

var players = {}

# You can preload some reusable sound players if you want
var max_sfx_players := 10
var sfx_players := []

func _ready():
	# Create multiple SFX players so you can overlap sounds
	for i in max_sfx_players:
		var sfx = AudioStreamPlayer.new()
		add_child(sfx)
		sfx.bus = "SFX"
		sfx_players.append(sfx)

	# One player for music
	var music = AudioStreamPlayer.new()
	music.bus = "Music"
	add_child(music)
	players[Bus.MUSIC] = music

	# One for UI
	var ui = AudioStreamPlayer.new()
	ui.bus = "UI"
	add_child(ui)
	players[Bus.UI] = ui

func play_sfx(stream: AudioStream, pitch_randomize := true, volume_db := 0.0):
	for sfx in sfx_players:
		if not sfx.playing:
			sfx.stream = stream
			sfx.volume_db = volume_db
			sfx.pitch_scale = randf_range(0.95, 1.05) if pitch_randomize else 1.0
			sfx.play()
			return
	# fallback (if all are busy)
	var fallback = sfx_players[0]
	fallback.stop()
	fallback.stream = stream
	fallback.volume_db = volume_db
	fallback.pitch_scale = 1.0
	fallback.play()

func play_music(stream: AudioStream, restart := false):
	var music = players[Bus.MUSIC]
	if music.stream != stream or restart:
		music.stop()
		music.stream = stream
		music.play()

func stop_music():
	players[Bus.MUSIC].stop()

func play_ui(stream: AudioStream):
	var ui = players[Bus.UI]
	ui.stream = stream
	ui.play()
