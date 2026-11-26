class_name SettingsMenu
extends Node2D

## Scale, fullscreen, volumes and the LCD effect. Left/right changes a value.

signal closed

const ROWS := ["WINDOW SCALE", "FULLSCREEN", "MUSIC", "SOUNDS", "LCD EFFECT", "DONE"]

## The button press that opened this must not also act inside it.
var opened_on_frame := -1
var row_index := 0
var seconds_open := 0.0


func open() -> void:
	opened_on_frame = Engine.get_process_frames()
	row_index = 0
	visible = true


func _process(delta: float) -> void:
	if not visible:
		return
	seconds_open += delta
	queue_redraw()
	if Engine.get_process_frames() == opened_on_frame:
		return
	var horizontal := int(Input.is_action_just_pressed("move_right")) - int(Input.is_action_just_pressed("move_left"))
	var vertical := int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("move_up"))
	if vertical != 0:
		row_index = wrapi(row_index + vertical, 0, ROWS.size())
		Sound.play("menu_move")
	if horizontal != 0:
		change(ROWS[row_index], horizontal)
		Sound.play("menu_move")
	var pressed_a := Input.is_action_just_pressed("action_a")
	if pressed_a and ROWS[row_index] != "DONE":
		change(ROWS[row_index], 1)
	if Input.is_action_just_pressed("action_b") or Input.is_action_just_pressed("start") or (pressed_a and ROWS[row_index] == "DONE"):
		Settings.save_settings()
		visible = false
		closed.emit()


func change(row: String, direction: int) -> void:
	match row:
		"WINDOW SCALE":
			var index := Settings.SCALES.find(Settings.window_scale)
			Settings.window_scale = Settings.SCALES[wrapi(index + direction, 0, Settings.SCALES.size())]
		"FULLSCREEN":
			Settings.is_fullscreen = not Settings.is_fullscreen
		"MUSIC":
			Settings.music_volume = clampi(Settings.music_volume + direction, 0, 10)
			Sound.refresh_volumes()
		"SOUNDS":
			Settings.sound_volume = clampi(Settings.sound_volume + direction, 0, 10)
			Sound.refresh_volumes()
		"LCD EFFECT":
			Settings.lcd_effect = not Settings.lcd_effect
	Settings.apply()


func value_text(row: String) -> String:
	match row:
		"WINDOW SCALE":
			return "AUTO" if Settings.window_scale == 0 else "%dX" % Settings.window_scale
		"FULLSCREEN":
			return "ON" if Settings.is_fullscreen else "OFF"
		"MUSIC":
			return "%d" % Settings.music_volume
		"SOUNDS":
			return "%d" % Settings.sound_volume
		"LCD EFFECT":
			return "ON" if Settings.lcd_effect else "OFF"
	return ""


func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(0, 0, 256, 144), UiDraw.paper())
	UiDraw.centred_text(self, "SETTINGS", 10)
	for index in ROWS.size():
		var top := 32.0 + index * 14
		UiDraw.text(self, ROWS[index], Vector2(32, top))
		UiDraw.text(self, value_text(ROWS[index]), Vector2(170, top))
		if index == row_index:
			UiDraw.text(self, ">", Vector2(20, top))
	UiDraw.text(self, "LEFT/RIGHT TO CHANGE", Vector2(32, 128), UiDraw.dim())
