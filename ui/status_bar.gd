class_name StatusBar
extends Node2D

## The white strip along the bottom: four meters as numbers, then the
## held item's name and picture, like the bottom rows of Survival Kids.

const SCREEN_WIDTH := 256
const HEIGHT := 16
const TOP := 144 - HEIGHT
const METER_SPACING := 40

var meters: SurvivalMeters
var held_item_name := ""
var held_item_texture: Texture2D


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var paper := Palettes.background_color("interface", 0)
	var ink := Palettes.background_color("interface", 3)
	draw_rect(Rect2(0, TOP, SCREEN_WIDTH, HEIGHT), paper)
	draw_rect(Rect2(0, TOP, SCREEN_WIDTH, 1), ink)

	if meters != null:
		var readings := [
			["heart", meters.health],
			["hunger", meters.hunger],
			["water", meters.water],
			["fatigue", meters.fatigue],
		]
		for reading_index in readings.size():
			var left := 4 + reading_index * METER_SPACING
			PixelFont.draw_icon(self, readings[reading_index][0], Vector2(left, TOP + 4))
			PixelFont.draw_text(self, str(readings[reading_index][1]), Vector2(left + 10, TOP + 4), ink)

	var box := Rect2(SCREEN_WIDTH - 20, TOP + 1, 18, 15)
	draw_rect(box, ink)
	draw_rect(box.grow(-1), paper)
	if held_item_texture != null:
		draw_texture_rect_region(held_item_texture, Rect2(box.position.x + 1, TOP, 16, 16), Rect2(0, 0, 16, 16))
		var name_left := box.position.x - 4 - PixelFont.text_width(held_item_name)
		PixelFont.draw_text(self, held_item_name, Vector2(name_left, TOP + 4), ink)
