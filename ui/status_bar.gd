class_name StatusBar
extends Node2D

## The white strip along the bottom: four meters as numbers like the bottom
## row of Survival Kids, the time, and the A and B items like Link's Awakening.

const SCREEN_WIDTH := 256
const HEIGHT := 16
const TOP := 144 - HEIGHT
const METER_SPACING := 36

var save: SaveGame


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var paper := UiDraw.paper()
	var ink := UiDraw.ink()
	draw_rect(Rect2(0, TOP, SCREEN_WIDTH, HEIGHT), paper)
	draw_rect(Rect2(0, TOP, SCREEN_WIDTH, 1), ink)
	if save == null:
		return
	var meters := save.meters
	var readings := [
		["heart", meters.health],
		["hunger", meters.hunger],
		["water", meters.water],
		["fatigue", meters.fatigue],
	]
	var blink_on := int(Time.get_ticks_msec() / 300) % 2 == 0
	for reading_index in readings.size():
		var left := 3 + reading_index * METER_SPACING
		var value: int = meters.shown(readings[reading_index][1])
		var is_low: bool = value <= 20
		if is_low and not blink_on:
			continue
		PixelFont.draw_icon(self, readings[reading_index][0], Vector2(left, TOP + 4))
		PixelFont.draw_text(self, str(value), Vector2(left + 9, TOP + 4), ink)
	if meters.is_rested():
		PixelFont.draw_text(self, "*", Vector2(146, TOP + 4), ink)
	PixelFont.draw_text(self, save.clock.time_text(), Vector2(154, TOP + 4), ink)

	draw_slot("B", save.inventory.equipped_b, 196)
	draw_slot("A", save.inventory.equipped_a, 226)


func draw_slot(letter: String, item_id: String, left: float) -> void:
	var ink := UiDraw.ink()
	PixelFont.draw_text(self, letter, Vector2(left, TOP + 4), ink)
	var box := Rect2(left + 8, TOP + 1, 18, 15)
	draw_rect(box, ink)
	draw_rect(box.grow(-1), UiDraw.paper())
	if item_id != "":
		draw_texture_rect_region(ItemCatalog.texture(item_id), Rect2(box.position.x + 1, TOP, 16, 16), Rect2(0, 0, 16, 16))
		var count := save.inventory.count_of(item_id)
		if count > 1 and ItemCatalog.is_stackable(item_id):
			PixelFont.draw_outlined_text(self, str(count), Vector2(box.end.x - 7, TOP + 8), UiDraw.paper(), ink)
