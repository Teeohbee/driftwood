class_name PauseMenu
extends Node2D

## The Start menu. Tabs along the top; up from the content reaches them.
##
## ITEMS   A on an item opens USE / SET ON A / SET ON B / DROP
## MERGE   A picks up to three items, then MERGE! tries them together
## BOOK    every merge you have discovered
## MAP     the island so far
## SYSTEM  the day, save and quit, settings

signal closed
signal use_item_requested(item_id: String)
signal drop_requested(slot_index: int)
signal merge_requested(slot_indices: Array)
signal quit_requested(should_save: bool)
signal settings_requested

const TABS := ["ITEMS", "MERGE", "BOOK", "MAP", "SYSTEM"]
const GRID_COLUMNS := 8
const CELL_SIZE := 20
const GRID_LEFT := 48
const GRID_TOP := 24
const ITEM_ACTIONS := ["USE", "SET ON A", "SET ON B", "DROP"]
const SYSTEM_ACTIONS := ["SAVE AND QUIT", "SETTINGS", "QUIT, NO SAVE", "BACK"]
const BOOK_ROWS_SHOWN := 5

var save: SaveGame
var map_view_data := {}
var tab_index := 0
var is_on_tab_row := false
var grid_index := 0
var item_action_index := -1
var merge_picks: Array = []
var is_on_merge_button := false
var system_index := 0
var book_scroll := 0
var message := ""
var seconds_open := 0.0
## Visited 16x8 screens, "x,y" -> true, filled in by the world.
var visited_screens := {}
var current_map := "overworld"
var player_cell := Vector2i.ZERO


func open(tab_name := "ITEMS") -> void:
	tab_index = TABS.find(tab_name)
	is_on_tab_row = false
	grid_index = 0
	item_action_index = -1
	merge_picks.clear()
	is_on_merge_button = false
	system_index = 0
	message = ""
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	seconds_open += delta
	queue_redraw()
	if Input.is_action_just_pressed("start"):
		close()
		return
	var horizontal := int(Input.is_action_just_pressed("move_right")) - int(Input.is_action_just_pressed("move_left"))
	var vertical := int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("move_up"))
	var pressed_a := Input.is_action_just_pressed("action_a")
	var pressed_b := Input.is_action_just_pressed("action_b")
	if horizontal != 0 or vertical != 0 or pressed_a or pressed_b:
		Sound.play("menu_move" if not (pressed_a or pressed_b) else ("menu_confirm" if pressed_a else "menu_back"))
	if is_on_tab_row:
		handle_tab_row(horizontal, vertical, pressed_a, pressed_b)
		return
	match TABS[tab_index]:
		"ITEMS":
			handle_items(horizontal, vertical, pressed_a, pressed_b)
		"MERGE":
			handle_merge(horizontal, vertical, pressed_a, pressed_b)
		"BOOK":
			handle_book(vertical, pressed_b)
		"MAP":
			if vertical < 0 or pressed_b:
				is_on_tab_row = true
				if pressed_b:
					close()
		"SYSTEM":
			handle_system(vertical, pressed_a, pressed_b)


func handle_tab_row(horizontal: int, vertical: int, pressed_a: bool, pressed_b: bool) -> void:
	if horizontal != 0:
		tab_index = wrapi(tab_index + horizontal, 0, TABS.size())
		merge_picks.clear()
		message = ""
	if vertical > 0 or pressed_a:
		is_on_tab_row = false
	if pressed_b:
		close()


func slot_count() -> int:
	return save.inventory.capacity


func move_in_grid(horizontal: int, vertical: int) -> bool:
	if vertical < 0 and grid_index < GRID_COLUMNS:
		is_on_tab_row = true
		return true
	var column := grid_index % GRID_COLUMNS + horizontal
	var row := grid_index / GRID_COLUMNS + vertical
	var row_count := slot_count() / GRID_COLUMNS
	if row >= row_count:
		return false
	grid_index = clampi(row, 0, row_count - 1) * GRID_COLUMNS + wrapi(column, 0, GRID_COLUMNS)
	return true


func hovered_slot() -> Dictionary:
	return save.inventory.slots[grid_index]


func handle_items(horizontal: int, vertical: int, pressed_a: bool, pressed_b: bool) -> void:
	if item_action_index >= 0:
		if vertical != 0:
			item_action_index = wrapi(item_action_index + vertical, 0, ITEM_ACTIONS.size())
		if pressed_b:
			item_action_index = -1
		if pressed_a:
			run_item_action(ITEM_ACTIONS[item_action_index])
		return
	if horizontal != 0 or vertical != 0:
		move_in_grid(horizontal, vertical)
		message = ""
	if pressed_a and not hovered_slot().is_empty():
		item_action_index = 0
	elif pressed_b:
		close()


func run_item_action(action: String) -> void:
	var slot := hovered_slot()
	item_action_index = -1
	if slot.is_empty():
		return
	var item_id: String = slot["id"]
	match action:
		"USE":
			use_item_requested.emit(item_id)
		"SET ON A":
			save.inventory.equip("a", item_id)
			message = "%s IS ON A." % ItemCatalog.display_name(item_id)
		"SET ON B":
			save.inventory.equip("b", item_id)
			message = "%s IS ON B." % ItemCatalog.display_name(item_id)
		"DROP":
			drop_requested.emit(grid_index)


func handle_merge(horizontal: int, vertical: int, pressed_a: bool, pressed_b: bool) -> void:
	if is_on_merge_button:
		if vertical < 0:
			is_on_merge_button = false
		if pressed_a:
			merge_requested.emit(merge_picks.duplicate())
			merge_picks.clear()
			is_on_merge_button = false
		if pressed_b:
			is_on_merge_button = false
		return
	if horizontal != 0 or vertical != 0:
		var moved := move_in_grid(horizontal, vertical)
		if not moved and vertical > 0 and merge_picks.size() >= 2:
			is_on_merge_button = true
	if pressed_a:
		pick_for_merge(grid_index)
	elif pressed_b:
		if merge_picks.is_empty():
			close()
		else:
			merge_picks.pop_back()


func pick_for_merge(slot_index: int) -> void:
	var slot: Dictionary = save.inventory.slots[slot_index]
	if slot.is_empty():
		return
	var times_picked := merge_picks.count(slot_index)
	if times_picked < slot["count"] and merge_picks.size() < 3:
		merge_picks.append(slot_index)
	else:
		merge_picks = merge_picks.filter(func(picked: int) -> bool: return picked != slot_index)
	message = ""


## Merge recipes found so far (cooking discoveries are kept separately).
func known_merges() -> Array:
	return save.known_recipes.filter(func(key: String) -> bool: return not key.begins_with("cook:"))


func handle_book(vertical: int, pressed_b: bool) -> void:
	if vertical < 0 and book_scroll == 0:
		is_on_tab_row = true
	elif vertical != 0:
		book_scroll = clampi(book_scroll + vertical, 0, maxi(known_merges().size() - BOOK_ROWS_SHOWN, 0))
	if pressed_b:
		close()


func handle_system(vertical: int, pressed_a: bool, pressed_b: bool) -> void:
	if vertical < 0 and system_index == 0:
		is_on_tab_row = true
		return
	if vertical != 0:
		system_index = clampi(system_index + vertical, 0, SYSTEM_ACTIONS.size() - 1)
	if pressed_b:
		close()
	if pressed_a:
		match SYSTEM_ACTIONS[system_index]:
			"SAVE AND QUIT":
				quit_requested.emit(true)
			"SETTINGS":
				settings_requested.emit()
			"QUIT, NO SAVE":
				quit_requested.emit(false)
			"BACK":
				close()


# --- Drawing ------------------------------------------------------------------

func _draw() -> void:
	if not visible or save == null:
		return
	draw_rect(Rect2(0, 0, 256, 144), UiDraw.paper())
	draw_tabs()
	match TABS[tab_index]:
		"ITEMS":
			draw_grid(false)
			draw_item_details()
		"MERGE":
			draw_grid(true)
			draw_merge_tray()
		"BOOK":
			draw_book()
		"MAP":
			draw_map()
		"SYSTEM":
			draw_system()
	if message != "":
		UiDraw.box(self, Rect2(4, 118, 248, 22))
		UiDraw.text(self, message, Vector2(12, 126))


func draw_tabs() -> void:
	var left := 6.0
	for index in TABS.size():
		var tab_name: String = TABS[index]
		var width := PixelFont.text_width(tab_name) + 8
		if index == tab_index:
			draw_rect(Rect2(left - 2, 2, width, 12), UiDraw.ink())
			UiDraw.text(self, tab_name, Vector2(left + 2, 4), UiDraw.paper())
			if is_on_tab_row:
				UiDraw.cursor(self, Rect2(left - 2, 2, width, 12), seconds_open)
		else:
			UiDraw.text(self, tab_name, Vector2(left + 2, 4), UiDraw.dim())
		left += width + 4
	draw_rect(Rect2(0, 15, 256, 1), UiDraw.ink())


func grid_cell_rect(slot_index: int) -> Rect2:
	var column := slot_index % GRID_COLUMNS
	var row := slot_index / GRID_COLUMNS
	return Rect2(GRID_LEFT + column * CELL_SIZE, GRID_TOP + row * CELL_SIZE, 18, 18)


func draw_grid(show_merge_picks: bool) -> void:
	for slot_index in slot_count():
		var area := grid_cell_rect(slot_index)
		draw_rect(area, UiDraw.shade())
		var slot: Dictionary = save.inventory.slots[slot_index]
		if not slot.is_empty():
			UiDraw.item_icon(self, slot["id"], area.position + Vector2(1, 1), slot["count"])
			if not show_merge_picks:
				if save.inventory.equipped_a == slot["id"]:
					PixelFont.draw_outlined_text(self, "A", area.position + Vector2(-2, -2), UiDraw.paper(), UiDraw.ink())
				elif save.inventory.equipped_b == slot["id"]:
					PixelFont.draw_outlined_text(self, "B", area.position + Vector2(-2, -2), UiDraw.paper(), UiDraw.ink())
		if show_merge_picks and merge_picks.has(slot_index):
			draw_rect(area, UiDraw.ink(), false, 1.0)
			PixelFont.draw_outlined_text(self, str(merge_picks.count(slot_index)), area.position + Vector2(-2, -2), UiDraw.paper(), UiDraw.ink())
	var is_grid_focused := not is_on_tab_row and item_action_index < 0 and not is_on_merge_button
	if is_grid_focused:
		UiDraw.cursor(self, grid_cell_rect(grid_index), seconds_open)
	var rows_used := slot_count() / GRID_COLUMNS
	UiDraw.text(self, "BAG %d" % slot_count(), Vector2(6, GRID_TOP + 4), UiDraw.dim())
	if rows_used < 2:
		pass


func details_top() -> float:
	return GRID_TOP + (slot_count() / GRID_COLUMNS) * CELL_SIZE + 6


func draw_item_details() -> void:
	var slot := hovered_slot()
	var top := details_top()
	if not slot.is_empty():
		var item_id: String = slot["id"]
		UiDraw.text(self, ItemCatalog.display_name(item_id), Vector2(8, top))
		UiDraw.text(self, ItemCatalog.about(item_id), Vector2(8, top + 10), UiDraw.dim())
		var detail := ""
		if slot.has("fresh_days"):
			detail = "FRESH FOR %d DAYS" % slot["fresh_days"]
		elif slot.has("uses_left"):
			detail = "%d USES LEFT" % slot["uses_left"]
		if detail != "":
			UiDraw.text(self, detail, Vector2(8, top + 20), UiDraw.dim())
	if item_action_index >= 0:
		var menu_area := Rect2(160, top - 4, 92, 52)
		UiDraw.box(self, menu_area)
		for index in ITEM_ACTIONS.size():
			var line_top := menu_area.position.y + 6 + index * 11
			UiDraw.text(self, ITEM_ACTIONS[index], Vector2(menu_area.position.x + 14, line_top))
			if index == item_action_index:
				UiDraw.text(self, ">", Vector2(menu_area.position.x + 5, line_top))


func draw_merge_tray() -> void:
	var top := details_top()
	if merge_picks.is_empty():
		UiDraw.text(self, "PICK TWO OR THREE THINGS.", Vector2(8, top))
		UiDraw.text(self, "A: PICK   B: PUT BACK", Vector2(8, top + 10), UiDraw.dim())
		return
	var left := 8.0
	for pick_index in merge_picks.size():
		var slot: Dictionary = save.inventory.slots[merge_picks[pick_index]]
		UiDraw.item_icon(self, slot["id"], Vector2(left, top))
		left += 18
		if pick_index < merge_picks.size() - 1:
			UiDraw.text(self, "+", Vector2(left, top + 4))
			left += 10
	if merge_picks.size() >= 2:
		var button := Rect2(left + 12, top, 64, 16)
		draw_rect(button, UiDraw.ink() if is_on_merge_button else UiDraw.shade())
		UiDraw.text(self, "MERGE!", button.position + Vector2(10, 4), UiDraw.paper() if is_on_merge_button else UiDraw.ink())
		if not is_on_merge_button:
			UiDraw.text(self, "DOWN TO MERGE", Vector2(8, top + 22), UiDraw.dim())


func draw_book() -> void:
	var total := RecipeBook.RECIPES.size()
	var merges := known_merges()
	UiDraw.text(self, "FOUND %d OF %d MERGES" % [merges.size(), total], Vector2(8, 20), UiDraw.dim())
	if merges.is_empty():
		UiDraw.text(self, "NOTHING YET. TRY MERGING!", Vector2(8, 40))
		return
	for row in BOOK_ROWS_SHOWN:
		var recipe_index := book_scroll + row
		if recipe_index >= merges.size():
			break
		var recipe := recipe_by_key(merges[recipe_index])
		if recipe.is_empty():
			continue
		var top := 32.0 + row * 20
		var left := 8.0
		var ingredients: Array = recipe["ingredients"]
		for ingredient_index in ingredients.size():
			UiDraw.item_icon(self, ingredients[ingredient_index], Vector2(left, top))
			left += 17
			UiDraw.text(self, "+" if ingredient_index < ingredients.size() - 1 else ">", Vector2(left, top + 4))
			left += 8
		UiDraw.item_icon(self, recipe["result"], Vector2(left, top), recipe.get("count", 1))
		UiDraw.text(self, ItemCatalog.display_name(recipe["result"]), Vector2(left + 20, top + 4))
	if merges.size() > BOOK_ROWS_SHOWN:
		UiDraw.text(self, "UP/DOWN TO SCROLL", Vector2(8, 134), UiDraw.dim())


func recipe_by_key(key: String) -> Dictionary:
	for recipe in RecipeBook.RECIPES:
		if RecipeBook.recipe_key(recipe) == key:
			return recipe
	return {}


const MAP_COLOR_FOR_GROUND := {
	"water": ["water", 1], "shore": ["water", 0], "sand": ["sand", 1], "sand_path": ["sand", 0],
	"pale_sand": ["pale_sand", 0], "grass": ["grass", 1], "dirt": ["dirt", 1], "jungle_floor": ["jungle", 1],
	"jungle_wall": ["jungle", 2], "cliff": ["cliff", 2], "river": ["river", 1], "bridge": ["bridge", 1],
	"ruins_floor": ["ruins", 0], "ruins_wall": ["ruins", 2], "cave_floor": ["cave", 0], "cave_wall": ["cave", 3],
	"cave_mouth": ["cliff", 3],
}


func draw_map() -> void:
	var map_id := current_map
	var width := WorldMaps.width_of(map_id)
	var height := WorldMaps.height_of(map_id)
	var scale := 2.0
	var origin := Vector2(roundf((256 - width * scale) / 2), 20)
	UiDraw.text(self, WorldMaps.map_data(map_id)["name"], Vector2(8, 20), UiDraw.dim())
	origin.y = 30
	draw_rect(Rect2(origin - Vector2(1, 1), Vector2(width, height) * scale + Vector2(2, 2)), UiDraw.ink(), false, 1.0)
	for row in height:
		for column in width:
			var screen_key := "%d,%d" % [column / 16, row / 8]
			var color := UiDraw.shade()
			if visited_screens.has(screen_key):
				var entry: Array = MAP_COLOR_FOR_GROUND.get(WorldMaps.ground_at(map_id, Vector2i(column, row)), ["interface", 1])
				color = Palettes.background_color(entry[0], entry[1])
			draw_rect(Rect2(origin + Vector2(column, row) * scale, Vector2(scale, scale)), color)
	if int(seconds_open / 0.25) % 2 == 0:
		draw_rect(Rect2(origin + Vector2(player_cell) * scale - Vector2(1, 1), Vector2(4, 4)), Palettes.sprite_color("emote", 2))
	if not save.home.is_empty() and save.home.get("map", "") == map_id:
		var home_cell := Vector2(save.home["x"], save.home["y"])
		draw_rect(Rect2(origin + home_cell * scale - Vector2(1, 1), Vector2(4, 4)), UiDraw.ink())


func draw_system() -> void:
	var clock := save.clock
	UiDraw.text(self, "DAY %d   %s   %s" % [clock.day(), clock.season().to_upper(), clock.weather().to_upper()], Vector2(8, 22))
	UiDraw.text(self, "YEAR %d   DAY %d OF %d   %s" % [clock.year(), clock.day_of_season(), DayClock.DAYS_PER_SEASON, clock.time_text()], Vector2(8, 32), UiDraw.dim())
	var seconds := int(save.play_seconds)
	UiDraw.text(self, "PLAYED %d:%02d" % [seconds / 3600, (seconds / 60) % 60], Vector2(8, 42), UiDraw.dim())
	UiDraw.text(self, "MERGES %d/%d   ENDINGS %d/4" % [known_merges().size(), RecipeBook.RECIPES.size(), Game.endings_seen.size()], Vector2(8, 52), UiDraw.dim())
	for index in SYSTEM_ACTIONS.size():
		var top := 70.0 + index * 12
		UiDraw.text(self, SYSTEM_ACTIONS[index], Vector2(24, top))
		if index == system_index and not is_on_tab_row:
			UiDraw.text(self, ">", Vector2(12, top))
