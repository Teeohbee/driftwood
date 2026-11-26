extends Node

## Player settings, saved to user://settings.json. Autoloaded as "Settings".

const PATH := "user://settings.json"
const SCALES := [0, 2, 3, 4, 5, 6]

var window_scale := 0
var is_fullscreen := false
var music_volume := 7
var sound_volume := 8
var lcd_effect := false


func _ready() -> void:
	var data := Game.read_json(PATH)
	window_scale = int(data.get("window_scale", 0))
	is_fullscreen = data.get("is_fullscreen", false)
	music_volume = int(data.get("music_volume", 7))
	sound_volume = int(data.get("sound_volume", 8))
	lcd_effect = data.get("lcd_effect", false)
	apply()


func apply() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if window_scale > 0:
			DisplayServer.window_set_size(Vector2i(256, 144) * window_scale)
	LcdEffect.set_enabled(lcd_effect)


func save_settings() -> void:
	Game.write_json(PATH, {"window_scale": window_scale, "is_fullscreen": is_fullscreen, "music_volume": music_volume, "sound_volume": sound_volume, "lcd_effect": lcd_effect})
	apply()


func volume_db(level: int) -> float:
	if level <= 0:
		return -80.0
	return linear_to_db(level / 10.0)
