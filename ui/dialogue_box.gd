class_name DialogueBox
extends Node2D

## Two lines of text that type themselves out. A finishes the typing, then
## the next A closes the box (or shows the next page).

signal closed

const BOX := Rect2(8, 96, 240, 40)
const CHARACTERS_PER_SECOND := 40.0
const LINES_PER_PAGE := 2

var pages: Array = []
var page_index := 0
var visible_character_count := 0.0
var seconds_open := 0.0
var is_open := false


func show_lines(lines: Array) -> void:
	pages.clear()
	for first_line in range(0, lines.size(), LINES_PER_PAGE):
		pages.append(lines.slice(first_line, first_line + LINES_PER_PAGE))
	page_index = 0
	visible_character_count = 0.0
	is_open = true
	visible = true


func advance() -> void:
	if not is_page_fully_typed():
		visible_character_count = characters_on_page()
		return
	page_index += 1
	visible_character_count = 0.0
	if page_index >= pages.size():
		is_open = false
		visible = false
		closed.emit()


func _process(delta: float) -> void:
	if not is_open:
		return
	seconds_open += delta
	visible_character_count = minf(visible_character_count + CHARACTERS_PER_SECOND * delta, characters_on_page())
	queue_redraw()


func characters_on_page() -> int:
	var count := 0
	for line in pages[page_index]:
		count += line.length()
	return count


func is_page_fully_typed() -> bool:
	return int(visible_character_count) >= characters_on_page()


func _draw() -> void:
	if not is_open:
		return
	var paper := Palettes.background_color("interface", 0)
	var shade := Palettes.background_color("interface", 1)
	var ink := Palettes.background_color("interface", 3)
	draw_rect(BOX, ink)
	draw_rect(BOX.grow(-1), paper)
	draw_rect(BOX.grow(-2), shade)
	draw_rect(BOX.grow(-3), paper)

	var characters_left := int(visible_character_count)
	var lines: Array = pages[page_index]
	for line_index in lines.size():
		var line: String = lines[line_index]
		var shown := line.left(characters_left)
		characters_left = maxi(characters_left - line.length(), 0)
		PixelFont.draw_text(self, shown, BOX.position + Vector2(8, 10 + line_index * 12), ink)

	var arrow_is_lit := int(seconds_open / 0.4) % 2 == 0
	if is_page_fully_typed() and arrow_is_lit:
		PixelFont.draw_icon(self, "more_text", BOX.end - Vector2(14, 10))
