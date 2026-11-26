class_name WeatherOverlay
extends Node2D

## Rain as falling pixel dashes; storms add lightning, one white frame at a time.

const DROP_COUNT := 70
const DROP_SPEED := Vector2(-40, 160)

var weather := "clear"
var drops: Array[Vector2] = []
var lightning_timer := 6.0
var flash_frames := 0


func _ready() -> void:
	for drop_index in DROP_COUNT:
		drops.append(Vector2(randf() * 280, randf() * 128))


func _process(delta: float) -> void:
	visible = weather == "rain" or weather == "storm"
	if not visible:
		return
	for drop_index in drops.size():
		var drop := drops[drop_index] + DROP_SPEED * delta
		if drop.y > 128:
			drop = Vector2(randf() * 280, 0)
		drops[drop_index] = drop
	if weather == "storm":
		lightning_timer -= delta
		if lightning_timer <= 0.0:
			lightning_timer = randf_range(5.0, 12.0)
			flash_frames = 3
	queue_redraw()


func _draw() -> void:
	var rain_color := Palettes.background_color("water", 0)
	for drop in drops:
		var pixel := drop.floor()
		draw_rect(Rect2(pixel, Vector2(1, 3)), rain_color)
	if flash_frames > 0:
		flash_frames -= 1
		if flash_frames % 2 == 0:
			draw_rect(Rect2(0, 0, 256, 128), UiDraw.paper())
