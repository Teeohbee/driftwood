class_name ChestMenu
extends Node2D

## Moves things between the bag (top) and a chest (bottom). A moves the
## whole stack under the cursor across; B or Start closes.

signal closed

const CHEST_SLOTS := 16
const COLUMNS := 8

## The button press that opened this must not also act inside it.
var opened_on_frame := -1
var save: SaveGame
var chest_map := ""
var chest_cell := Vector2i.ZERO
var cursor := 0
var seconds_open := 0.0


func open(owner_save: SaveGame, on_map: String, cell: Vector2i) -> void:
	opened_on_frame = Engine.get_process_frames()
	save = owner_save
	chest_map = on_map
	chest_cell = cell
	cursor = 0
	visible = true
	Sound.play("open")


func contents() -> Array:
	return save.state_at(chest_map, chest_cell).get("contents", [])


func bag_size() -> int:
	return save.inventory.capacity


func _process(delta: float) -> void:
	if not visible:
		return
	seconds_open += delta
	queue_redraw()
	if Engine.get_process_frames() == opened_on_frame:
		return
	if Input.is_action_just_pressed("action_b") or Input.is_action_just_pressed("start"):
		visible = false
		closed.emit()
		return
	var horizontal := int(Input.is_action_just_pressed("move_right")) - int(Input.is_action_just_pressed("move_left"))
	var vertical := int(Input.is_action_just_pressed("move_down")) - int(Input.is_action_just_pressed("move_up"))
	var total := bag_size() + CHEST_SLOTS
	if horizontal != 0 or vertical != 0:
		cursor = clampi(cursor + horizontal + vertical * COLUMNS, 0, total - 1)
		Sound.play("menu_move")
	if Input.is_action_just_pressed("action_a"):
		move_under_cursor()


func move_under_cursor() -> void:
	var stored := contents().duplicate(true)
	if cursor < bag_size():
		var slot: Dictionary = save.inventory.slots[cursor]
		if slot.is_empty() or stored.size() >= CHEST_SLOTS:
			return
		stored.append(slot.duplicate())
		save.inventory.slots[cursor] = {}
		save.inventory.forget_missing_equipment()
	else:
		var chest_index := cursor - bag_size()
		if chest_index >= stored.size():
			return
		var entry: Dictionary = stored[chest_index]
		var leftover := save.inventory.add(entry["id"], int(entry["count"]), int(entry.get("fresh_days", -1)))
		if leftover == int(entry["count"]):
			return
		if leftover > 0:
			entry["count"] = leftover
		else:
			stored.remove_at(chest_index)
	save.set_state(chest_map, chest_cell, "contents", stored)
	Sound.play("pickup")


func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(0, 0, 256, 144), UiDraw.paper())
	UiDraw.text(self, "BAG", Vector2(8, 6))
	UiDraw.text(self, "CHEST", Vector2(8, 66))
	for slot_index in bag_size():
		var area := Rect2(48 + (slot_index % COLUMNS) * 20, 4 + (slot_index / COLUMNS) * 20, 18, 18)
		draw_rect(area, UiDraw.shade())
		var slot: Dictionary = save.inventory.slots[slot_index]
		if not slot.is_empty():
			UiDraw.item_icon(self, slot["id"], area.position + Vector2(1, 1), slot["count"])
		if cursor == slot_index:
			UiDraw.cursor(self, area, seconds_open)
	var stored := contents()
	for chest_index in CHEST_SLOTS:
		var area := Rect2(48 + (chest_index % COLUMNS) * 20, 64 + (chest_index / COLUMNS) * 20, 18, 18)
		draw_rect(area, UiDraw.shade())
		if chest_index < stored.size():
			UiDraw.item_icon(self, stored[chest_index]["id"], area.position + Vector2(1, 1), int(stored[chest_index]["count"]))
		if cursor == bag_size() + chest_index:
			UiDraw.cursor(self, area, seconds_open)
	UiDraw.text(self, "A: MOVE ACROSS   B: CLOSE", Vector2(8, 130), UiDraw.dim())
	UiDraw.text(self, "CHESTS KEEP FOOD FRESH.", Vector2(8, 110), UiDraw.dim())
