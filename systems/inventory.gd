class_name Inventory
extends RefCounted

## The castaway's bag: a row of slots. Stackable items pile up to 9 per slot;
## tools take a slot each and wear out. Food carries "fresh_days" and rots.
## A slot is {} when empty, or {"id": String, "count": int, ...}.

const STARTING_CAPACITY := 8

var capacity := STARTING_CAPACITY
var slots: Array = []
## Item ids on the A and B buttons, like Link's Awakening. "" is bare hands.
var equipped_a := ""
var equipped_b := ""


func _init() -> void:
	resize_slots()


func resize_slots() -> void:
	while slots.size() < capacity:
		slots.append({})


func grow_to(new_capacity: int) -> bool:
	if new_capacity <= capacity:
		return false
	capacity = new_capacity
	resize_slots()
	return true


## Adds as many as fit. Returns how many did not fit.
func add(item_id: String, count := 1, fresh_days := -1) -> int:
	if fresh_days < 0:
		fresh_days = ItemCatalog.rots_in_days(item_id)
	var remaining := count
	if ItemCatalog.is_stackable(item_id):
		for slot in slots:
			if remaining == 0:
				break
			if slot.get("id", "") == item_id and slot["count"] < ItemCatalog.MAXIMUM_STACK:
				var moved := mini(remaining, ItemCatalog.MAXIMUM_STACK - slot["count"])
				slot["count"] += moved
				remaining -= moved
				if slot.has("fresh_days"):
					slot["fresh_days"] = mini(slot["fresh_days"], fresh_days)
	for slot_index in slots.size():
		if remaining == 0:
			break
		if slots[slot_index].is_empty():
			var moved := mini(remaining, ItemCatalog.MAXIMUM_STACK) if ItemCatalog.is_stackable(item_id) else 1
			slots[slot_index] = new_slot(item_id, moved, fresh_days)
			remaining -= moved
	return remaining


func new_slot(item_id: String, count: int, fresh_days: int) -> Dictionary:
	var slot := {"id": item_id, "count": count}
	if ItemCatalog.rots_in_days(item_id) > 0:
		slot["fresh_days"] = fresh_days
	if ItemCatalog.uses(item_id) > 0:
		slot["uses_left"] = ItemCatalog.uses(item_id)
	return slot


func has_room_for(item_id: String) -> bool:
	for slot in slots:
		if slot.is_empty():
			return true
		if ItemCatalog.is_stackable(item_id) and slot["id"] == item_id and slot["count"] < ItemCatalog.MAXIMUM_STACK:
			return true
	return false


func count_of(item_id: String) -> int:
	var total := 0
	for slot in slots:
		if slot.get("id", "") == item_id:
			total += slot["count"]
	return total


func has(item_id: String, count := 1) -> bool:
	return count_of(item_id) >= count


## Removes from the last matching slots first. Returns false (and removes
## nothing) if there are not enough.
func remove(item_id: String, count := 1) -> bool:
	if not has(item_id, count):
		return false
	var remaining := count
	for slot_index in range(slots.size() - 1, -1, -1):
		var slot: Dictionary = slots[slot_index]
		if remaining == 0:
			break
		if slot.get("id", "") != item_id:
			continue
		var taken := mini(remaining, slot["count"])
		slot["count"] -= taken
		remaining -= taken
		if slot["count"] == 0:
			slots[slot_index] = {}
	forget_missing_equipment()
	return true


func remove_from_slot(slot_index: int, count := 1) -> void:
	var slot: Dictionary = slots[slot_index]
	if slot.is_empty():
		return
	slot["count"] -= count
	if slot["count"] <= 0:
		slots[slot_index] = {}
	forget_missing_equipment()


func forget_missing_equipment() -> void:
	if equipped_a != "" and not has(equipped_a):
		equipped_a = ""
	if equipped_b != "" and not has(equipped_b):
		equipped_b = ""


func equip(button: String, item_id: String) -> void:
	if button == "a":
		if equipped_b == item_id:
			equipped_b = equipped_a
		equipped_a = item_id
	else:
		if equipped_a == item_id:
			equipped_a = equipped_b
		equipped_b = item_id


func equipped(button: String) -> String:
	return equipped_a if button == "a" else equipped_b


## Wears a tool down by one use. Returns true if it broke.
func wear_tool(item_id: String) -> bool:
	for slot_index in slots.size():
		var slot: Dictionary = slots[slot_index]
		if slot.get("id", "") == item_id and slot.has("uses_left"):
			slot["uses_left"] -= 1
			if slot["uses_left"] <= 0:
				slots[slot_index] = {}
				forget_missing_equipment()
				return true
			return false
	return false


## Called each morning. Food loses a day; food at zero turns rotten.
## Returns the ids that rotted.
func age_one_day() -> Array:
	var rotted := []
	for slot_index in slots.size():
		var slot: Dictionary = slots[slot_index]
		if not slot.has("fresh_days"):
			continue
		slot["fresh_days"] -= 1
		if slot["fresh_days"] <= 0:
			rotted.append(slot["id"])
			var count: int = slot["count"]
			slots[slot_index] = {}
			add("rotten_food", count)
	forget_missing_equipment()
	return rotted


func is_full() -> bool:
	for slot in slots:
		if slot.is_empty():
			return false
	return true


func item_ids() -> Array:
	var ids := []
	for slot in slots:
		if not slot.is_empty() and not ids.has(slot["id"]):
			ids.append(slot["id"])
	return ids


func to_data() -> Dictionary:
	return {"capacity": capacity, "slots": slots.duplicate(true), "equipped_a": equipped_a, "equipped_b": equipped_b}


func load_data(data: Dictionary) -> void:
	capacity = int(data.get("capacity", STARTING_CAPACITY))
	slots = []
	for slot in data.get("slots", []):
		var clean := {}
		for key in slot:
			clean[key] = slot[key] if key == "id" else int(slot[key])
		slots.append(clean)
	resize_slots()
	equipped_a = data.get("equipped_a", "")
	equipped_b = data.get("equipped_b", "")
