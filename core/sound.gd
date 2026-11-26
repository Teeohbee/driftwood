extends Node

## Sound effects and music, baked by tools/bake_audio.gd into res://audio/.
## Autoloaded as "Sound". Missing sounds are silently skipped.

const PLAYER_COUNT := 6

var effect_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var next_effect_player := 0
var current_music := ""
var streams := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		add_child(player)
		effect_players.append(player)
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	# Loops by replaying, so it works however the importer treats loop points.
	music_player.finished.connect(func() -> void:
		if current_music != "":
			music_player.play())
	refresh_volumes()


func refresh_volumes() -> void:
	var settings := get_node_or_null("/root/Settings")
	var sound_level: int = settings.sound_volume if settings != null else 8
	var music_level: int = settings.music_volume if settings != null else 7
	for player in effect_players:
		player.volume_db = settings.volume_db(sound_level) if settings != null else 0.0
	music_player.volume_db = (settings.volume_db(music_level) if settings != null else 0.0) - 4.0


func stream(sound_name: String) -> AudioStream:
	if not streams.has(sound_name):
		var path := "res://audio/%s.wav" % sound_name
		streams[sound_name] = load(path) if ResourceLoader.exists(path) else null
	return streams[sound_name]


func play(sound_name: String) -> void:
	var sound_stream := stream(sound_name)
	if sound_stream == null:
		return
	var player := effect_players[next_effect_player]
	next_effect_player = (next_effect_player + 1) % PLAYER_COUNT
	player.stream = sound_stream
	player.play()


func play_music(music_name: String) -> void:
	if music_name == current_music and music_player.playing:
		return
	current_music = music_name
	var music_stream := stream("music_%s" % music_name)
	if music_stream == null:
		music_player.stop()
		return
	music_player.stream = music_stream
	music_player.play()


func stop_music() -> void:
	current_music = ""
	music_player.stop()
