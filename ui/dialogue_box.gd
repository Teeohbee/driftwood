class_name DialogueBox
extends Node2D

## Two lines of text that type themselves out. A finishes the typing, then
## the next A shows the next page or closes the box. A question shows its
## choices on the last page; up/down picks, A answers.

signal closed

const BOX := Rect2(8, 88, 240, 40)
const CHARACTERS_PER_SECOND := 40.0
const LINES_PER_PAGE := 2

## The button press that opened this must not also act inside it.
var opened_on_frame := -1
var pages: Array = []
var page_index := 0
var visible_character_count := 0.0
var seconds_open := 0.0
var is_open := false
var choices: Array = []
var choice_index := 0
var answer_callback := Callable()
## Called once when the box closes (not for questions).
var finished_callback := Callable()
var blip_timer := 0.0


func show_lines(lines: Array) -> void:
	opened_on_frame = Engine.get_process_frames()
	pages.clear()
	for first_line in range(0, lines.size(), LINES_PER_PAGE):
		pages.append(lines.slice(first_line, first_line + LINES_PER_PAGE))
	page_index = 0
	visible_character_count = 0.0
	choices = []
	answer_callback = Callable()
	finished_callback = Callable()
	is_open = true
	visible = true


func show_question(lines: Array, question_choices: Array, on_answer: Callable) -> void:
	show_lines(lines)
	choices = question_choices
	choice_index = 0
	answer_callback = on_answer


func is_on_last_page() -> bool:
	return page_index == pages.size() - 1


func advance() -> void:
	if not is_page_fully_typed():
		visible_character_count = characters_on_page()
		return
	if is_on_last_page() and not choices.is_empty():
		var callback := answer_callback
		var answer := choice_index
		close_box()
		callback.call(answer)
		return
	page_index += 1
	visible_character_count = 0.0
	if page_index >= pages.size():
		var callback := finished_callback
		close_box()
		if callback.is_valid():
			callback.call()


func close_box() -> void:
	is_open = false
	visible = false
	choices = []
	closed.emit()


func _process(delta: float) -> void:
	if not is_open:
		return
	seconds_open += delta
	var before := int(visible_character_count)
	visible_character_count = minf(visible_character_count + CHARACTERS_PER_SECOND * delta, characters_on_page())
	if int(visible_character_count) != before and int(visible_character_count) % 3 == 0:
		Sound.play("type")
	if is_on_last_page() and not choices.is_empty() and is_page_fully_typed():
		var vertical := int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("move_up"))
		if vertical != 0:
			choice_index = wrapi(choice_index + vertical, 0, choices.size())
			Sound.play("menu_move")
	var is_new_this_frame := Engine.get_process_frames() == opened_on_frame
	if not is_new_this_frame and (Input.is_action_just_pressed("action_a") or (Input.is_action_just_pressed("action_b") and choices.is_empty())):
		advance()
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
	UiDraw.box(self, BOX)
	var ink := UiDraw.ink()
	var characters_left := int(visible_character_count)
	var lines: Array = pages[page_index]
	for line_index in lines.size():
		var line: String = lines[line_index]
		var shown := line.left(characters_left)
		characters_left = maxi(characters_left - line.length(), 0)
		PixelFont.draw_text(self, shown, BOX.position + Vector2(8, 10 + line_index * 12), ink)

	if is_on_last_page() and not choices.is_empty() and is_page_fully_typed():
		var height := choices.size() * 11 + 8
		var area := Rect2(BOX.end.x - 72, BOX.position.y - height - 2, 72, height)
		UiDraw.box(self, area)
		for index in choices.size():
			var top := area.position.y + 5 + index * 11
			PixelFont.draw_text(self, choices[index], Vector2(area.position.x + 14, top), ink)
			if index == choice_index:
				PixelFont.draw_text(self, ">", Vector2(area.position.x + 5, top), ink)
		return
	var arrow_is_lit := int(seconds_open / 0.4) % 2 == 0
	if is_page_fully_typed() and arrow_is_lit:
		PixelFont.draw_icon(self, "more_text", BOX.end - Vector2(14, 10))
