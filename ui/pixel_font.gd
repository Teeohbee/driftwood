class_name PixelFont
extends RefCounted

## Draws text with the baked 8x8 font. Call from a CanvasItem's _draw().

const FONT_TEXTURE := preload("res://art/sprites/font.png")
const ICON_TEXTURE := preload("res://art/sprites/icons.png")
const ATLAS_COLUMNS := 16


static func text_width(text: String) -> int:
	if text.is_empty():
		return 0
	return text.length() * FontGlyphs.GLYPH_ADVANCE - 1


static func draw_text(canvas: CanvasItem, text: String, top_left: Vector2, color: Color) -> void:
	var cell := FontGlyphs.CELL_SIZE
	for letter_index in text.length():
		var glyph_index := FontGlyphs.CHARACTERS.find(text[letter_index].to_upper())
		if glyph_index == -1:
			continue
		var source := Rect2((glyph_index % ATLAS_COLUMNS) * cell, (glyph_index / ATLAS_COLUMNS) * cell, cell, cell)
		var destination := Rect2(top_left + Vector2(letter_index * FontGlyphs.GLYPH_ADVANCE, 0), Vector2(cell, cell))
		canvas.draw_texture_rect_region(FONT_TEXTURE, destination, source, color)


## Dark outline all round, then the text on top, like the title screen prompt.
static func draw_outlined_text(canvas: CanvasItem, text: String, top_left: Vector2, color: Color, outline_color: Color) -> void:
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x != 0 or offset_y != 0:
				draw_text(canvas, text, top_left + Vector2(offset_x, offset_y), outline_color)
	draw_text(canvas, text, top_left, color)


static func draw_icon(canvas: CanvasItem, icon_name: String, top_left: Vector2) -> void:
	var icon_index := PixelArt.ICONS.keys().find(icon_name)
	canvas.draw_texture_rect_region(ICON_TEXTURE, Rect2(top_left, Vector2(8, 8)), Rect2(icon_index * 8, 0, 8, 8))
