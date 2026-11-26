extends Node2D

## Three save files. A on an empty file opens the look picker; A on a used
## file offers CONTINUE or DELETE. B goes back to the title.

const WORLD_SCENE := "res://scenes/world/world.tscn"
const TITLE_SCENE := "res://scenes/title/title_screen.tscn"
const CARD_HEIGHT := 36
const FILE_ACTIONS := ["CONTINUE", "DELETE", "BACK"]
const LOOK_ROWS := ["SKIN", "SHIRT", "HAIR", "START"]

enum Stage { CHOOSING_FILE, FILE_ACTIONS, CONFIRM_DELETE, PICKING_LOOK, LEAVING }

var stage := Stage.CHOOSING_FILE
var file_index := 0
var action_index := 0
var look_row := 0
var look := CastawayLook.default_look()
var summaries: Array = []
var portraits: Array[Sprite2D] = []
var big_castaway: Sprite2D
var seconds := 0.0


func _ready() -> void:
	refresh_summaries()
	for slot_index in Game.SLOT_COUNT:
		var portrait := Sprite2D.new()
		portrait.texture = preload("res://art/sprites/hero_down.png")
		portrait.hframes = 2
		portrait.centered = false
		portrait.position = Vector2(20, card_top(slot_index) + 10)
		add_child(portrait)
		portraits.append(portrait)
	big_castaway = Sprite2D.new()
	big_castaway.texture = preload("res://art/sprites/hero_down.png")
	big_castaway.hframes = 2
	big_castaway.scale = Vector2(4, 4)
	big_castaway.position = Vector2(64, 70)
	big_castaway.visible = false
	add_child(big_castaway)
	refresh_portraits()
	Sound.play_music("title")


func refresh_summaries() -> void:
	summaries.clear()
	for slot_index in Game.SLOT_COUNT:
		summaries.append(Game.slot_summary(slot_index))


func refresh_portraits() -> void:
	for slot_index in Game.SLOT_COUNT:
		var summary: Dictionary = summaries[slot_index]
		portraits[slot_index].visible = not summary.is_empty() and stage != Stage.PICKING_LOOK
		if not summary.is_empty():
			portraits[slot_index].material = CastawayLook.make_material(summary["look"])
	big_castaway.material = CastawayLook.make_material(look)


func card_top(slot_index: int) -> float:
	return 18.0 + slot_index * (CARD_HEIGHT + 4)


func _process(delta: float) -> void:
	seconds += delta
	queue_redraw()
	big_castaway.frame = int(seconds / 0.4) % 2
	var vertical := int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("move_up"))
	var horizontal := int(Input.is_action_just_pressed("move_right")) - int(Input.is_action_just_pressed("move_left"))
	var pressed_a := Input.is_action_just_pressed("action_a") or Input.is_action_just_pressed("start")
	var pressed_b := Input.is_action_just_pressed("action_b")
	if vertical != 0 or horizontal != 0:
		Sound.play("menu_move")
	match stage:
		Stage.CHOOSING_FILE:
			if vertical != 0:
				file_index = wrapi(file_index + vertical, 0, Game.SLOT_COUNT)
			if pressed_a:
				Sound.play("menu_confirm")
				if summaries[file_index].is_empty():
					look = CastawayLook.default_look()
					look_row = 0
					stage = Stage.PICKING_LOOK
					big_castaway.visible = true
					refresh_portraits()
				else:
					action_index = 0
					stage = Stage.FILE_ACTIONS
			elif pressed_b:
				Sound.play("menu_back")
				leave_to(TITLE_SCENE)
		Stage.FILE_ACTIONS:
			if vertical != 0:
				action_index = wrapi(action_index + vertical, 0, FILE_ACTIONS.size())
			if pressed_b:
				stage = Stage.CHOOSING_FILE
			elif pressed_a:
				match FILE_ACTIONS[action_index]:
					"CONTINUE":
						if Game.load_game(file_index):
							Sound.play("menu_confirm")
							leave_to(WORLD_SCENE)
					"DELETE":
						action_index = 1
						stage = Stage.CONFIRM_DELETE
					"BACK":
						stage = Stage.CHOOSING_FILE
		Stage.CONFIRM_DELETE:
			if vertical != 0:
				action_index = 1 - action_index
			if pressed_b:
				stage = Stage.FILE_ACTIONS
			elif pressed_a:
				if action_index == 0:
					Game.delete_slot(file_index)
					Sound.play("collapse")
					refresh_summaries()
					refresh_portraits()
				stage = Stage.CHOOSING_FILE
		Stage.PICKING_LOOK:
			process_look_picker(vertical, horizontal, pressed_a, pressed_b)


func process_look_picker(vertical: int, horizontal: int, pressed_a: bool, pressed_b: bool) -> void:
	if vertical != 0:
		look_row = wrapi(look_row + vertical, 0, LOOK_ROWS.size())
	var row: String = LOOK_ROWS[look_row]
	if horizontal != 0 and row != "START":
		var part := row.to_lower()
		look[part] = wrapi(look[part] + horizontal, 0, CastawayLook.option_count(part))
		refresh_portraits()
	if pressed_b:
		stage = Stage.CHOOSING_FILE
		big_castaway.visible = false
		refresh_portraits()
	elif pressed_a and row == "START":
		Sound.play("fanfare")
		Game.new_game(file_index, look)
		Game.save_game()
		leave_to(WORLD_SCENE)
	elif pressed_a:
		look_row += 1


func leave_to(scene_path: String) -> void:
	stage = Stage.LEAVING
	if scene_path == WORLD_SCENE:
		Sound.stop_music()
	ScreenFader.change_scene(scene_path)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 256, 144), Palettes.background_color("sky", 3))
	if stage == Stage.PICKING_LOOK or (stage == Stage.LEAVING and big_castaway.visible):
		draw_look_picker()
		return
	PixelFont.draw_outlined_text(self, "CHOOSE A FILE", Vector2(8, 4), UiDraw.paper(), UiDraw.ink())
	for slot_index in Game.SLOT_COUNT:
		var area := Rect2(8, card_top(slot_index), 240, CARD_HEIGHT)
		UiDraw.box(self, area)
		var summary: Dictionary = summaries[slot_index]
		UiDraw.text(self, "FILE %d" % (slot_index + 1), area.position + Vector2(44, 6))
		if summary.is_empty():
			UiDraw.text(self, "NEW CASTAWAY", area.position + Vector2(44, 18), UiDraw.dim())
		else:
			var seconds_played := int(summary["play_seconds"])
			UiDraw.text(self, "DAY %d  %s" % [summary["day"], String(summary["season"]).to_upper()], area.position + Vector2(44, 18))
			UiDraw.text(self, "%d:%02d" % [seconds_played / 3600, (seconds_played / 60) % 60], area.position + Vector2(196, 6), UiDraw.dim())
		if slot_index == file_index and stage == Stage.CHOOSING_FILE:
			UiDraw.cursor(self, area.grow(-1), seconds)
	if stage == Stage.FILE_ACTIONS or stage == Stage.CONFIRM_DELETE:
		var options := FILE_ACTIONS if stage == Stage.FILE_ACTIONS else ["YES, DELETE", "NO"]
		var area := Rect2(140, card_top(file_index) + 8, 104, options.size() * 11 + 10)
		UiDraw.box(self, area)
		for index in options.size():
			var top := area.position.y + 6 + index * 11
			UiDraw.text(self, options[index], Vector2(area.position.x + 14, top))
			if index == action_index:
				UiDraw.text(self, ">", Vector2(area.position.x + 5, top))
	var endings_text := "ENDINGS FOUND: %d/4" % Game.endings_seen.size()
	PixelFont.draw_outlined_text(self, endings_text, Vector2(8, 134), UiDraw.paper(), UiDraw.ink())


func draw_look_picker() -> void:
	PixelFont.draw_outlined_text(self, "WHO WASHED UP?", Vector2(8, 4), UiDraw.paper(), UiDraw.ink())
	UiDraw.box(self, Rect2(24, 22, 80, 96))
	UiDraw.box(self, Rect2(116, 22, 132, 96))
	for index in LOOK_ROWS.size():
		var top := 34.0 + index * 18
		var row: String = LOOK_ROWS[index]
		UiDraw.text(self, row, Vector2(136, top))
		if row != "START":
			var part := row.to_lower()
			draw_rect(Rect2(204, top - 1, 9, 9), UiDraw.ink())
			draw_rect(Rect2(205, top, 7, 7), CastawayLook.color_for(look, part))
			UiDraw.text(self, "<", Vector2(194, top))
			UiDraw.text(self, ">", Vector2(216, top))
		if index == look_row:
			UiDraw.text(self, ">", Vector2(124, top))
	PixelFont.draw_outlined_text(self, "LEFT/RIGHT CHANGES. B: BACK", Vector2(8, 128), UiDraw.paper(), UiDraw.ink())
