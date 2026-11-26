class_name UiDraw
extends RefCounted

## Shared drawing for menus: boxes, item icons with counts, colours.


static func paper() -> Color:
	return Palettes.background_color("interface", 0)


static func shade() -> Color:
	return Palettes.background_color("interface", 1)


static func dim() -> Color:
	return Palettes.background_color("interface", 2)


static func ink() -> Color:
	return Palettes.background_color("interface", 3)


## A double-ruled box like the dialogue box.
static func box(canvas: CanvasItem, area: Rect2) -> void:
	canvas.draw_rect(area, ink())
	canvas.draw_rect(area.grow(-1), paper())
	canvas.draw_rect(area.grow(-2), shade())
	canvas.draw_rect(area.grow(-3), paper())


static func item_icon(canvas: CanvasItem, item_id: String, top_left: Vector2, count := 1) -> void:
	if item_id == "":
		return
	canvas.draw_texture(ItemCatalog.texture(item_id), top_left)
	if count > 1:
		var text := str(count)
		var text_left := top_left.x + 17 - PixelFont.text_width(text)
		PixelFont.draw_outlined_text(canvas, text, Vector2(text_left, top_left.y + 9), paper(), ink())


static func text(canvas: CanvasItem, words: String, top_left: Vector2, color := Color.TRANSPARENT) -> void:
	PixelFont.draw_text(canvas, words, top_left, ink() if color == Color.TRANSPARENT else color)


static func centred_text(canvas: CanvasItem, words: String, top: float, color := Color.TRANSPARENT, width := 256.0, left := 0.0) -> void:
	text(canvas, words, Vector2(left + roundf((width - PixelFont.text_width(words)) / 2), top), color)


static func cursor(canvas: CanvasItem, area: Rect2, seconds: float) -> void:
	if int(seconds / 0.3) % 2 == 0:
		canvas.draw_rect(area.grow(1), ink(), false, 1.0)
		canvas.draw_rect(area.grow(2), paper(), false, 1.0)
