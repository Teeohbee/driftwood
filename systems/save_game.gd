class_name SaveGame
extends RefCounted

## Everything one save slot remembers. Saved as JSON in user://slot_N.json.
##
## World changes are kept per map and per metatile, as small dictionaries:
##   "gone": day it grows back (0 = never)     "opened": true (crates)
##   "piece": built piece id                    "fuel": fire minutes left
##   "floor": "soil", "soil_watered" or "wood_floor"
##   "roof": true                               "crop": {...}
##   "items": [{"id", "count"}] dropped on the ground
##   "harvest_day": day a palm, tree or bush can give again

const VERSION := 1

var slot_index := 0
var look := CastawayLook.default_look()
var meters := SurvivalMeters.new()
var inventory := Inventory.new()
var clock := DayClock.new()
var map_id := "overworld"
var player_position := Vector2.ZERO
var home := {}
var changes := {}
var known_recipes: Array = []
var hints_seen := {}
var flags := {}
var play_seconds := 0.0
var plant_seed := 1
var companion := {}
var animals := {}


static func cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


static func key_cell(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


func state_at(on_map: String, cell: Vector2i) -> Dictionary:
	return changes.get(on_map, {}).get(cell_key(cell), {})


func set_state(on_map: String, cell: Vector2i, key: String, value: Variant) -> void:
	if not changes.has(on_map):
		changes[on_map] = {}
	var map_changes: Dictionary = changes[on_map]
	var cell_state: Dictionary = map_changes.get(cell_key(cell), {})
	if value == null:
		cell_state.erase(key)
	else:
		cell_state[key] = value
	if cell_state.is_empty():
		map_changes.erase(cell_key(cell))
	else:
		map_changes[cell_key(cell)] = cell_state


func cells_with(on_map: String, key: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for key_text in changes.get(on_map, {}):
		if changes[on_map][key_text].has(key):
			cells.append(key_cell(key_text))
	return cells


func flag(name: String) -> bool:
	return flags.get(name, false)


func set_flag(name: String, value := true) -> void:
	flags[name] = value


## Mushrooms and herbs do something different in every new game, as in
## Survival Kids. Raw effects are dealt from this list by the save's seed.
const RAW_PLANT_EFFECTS := [
	{"effects": {"health": 15, "hunger": 4}, "line": "YOU FEEL STRONGER. HEALTH +15."},
	{"effects": {"health": -12}, "line": "BLEURGH. POISONOUS! HEALTH -12."},
	{"effects": {"fatigue": 25}, "line": "YOUR HEAD CLEARS. FATIGUE +25."},
	{"effects": {"water": 15}, "line": "JUICY INSIDE. WATER +15."},
]


func raw_plant_effect(item_id: String) -> Dictionary:
	var plant_index := ["mushroom", "herb"].find(item_id)
	var effect_index := (plant_seed + plant_index * 3) % RAW_PLANT_EFFECTS.size()
	if plant_index == 1 and effect_index == (plant_seed) % RAW_PLANT_EFFECTS.size():
		effect_index = (effect_index + 1) % RAW_PLANT_EFFECTS.size()
	return RAW_PLANT_EFFECTS[effect_index]


func to_data() -> Dictionary:
	return {
		"version": VERSION,
		"look": look,
		"meters": meters.to_data(),
		"inventory": inventory.to_data(),
		"clock_minutes": clock.total_minutes,
		"weather_seed": clock.weather_seed,
		"map_id": map_id,
		"player_position": [player_position.x, player_position.y],
		"home": home,
		"changes": changes,
		"known_recipes": known_recipes,
		"hints_seen": hints_seen,
		"flags": flags,
		"play_seconds": play_seconds,
		"plant_seed": plant_seed,
		"companion": companion,
		"animals": animals,
	}


func load_data(data: Dictionary) -> void:
	look = {}
	for part in data.get("look", {}):
		look[part] = int(data["look"][part])
	if look.is_empty():
		look = CastawayLook.default_look()
	meters.load_data(data.get("meters", {}))
	inventory.load_data(data.get("inventory", {}))
	clock.total_minutes = data.get("clock_minutes", clock.total_minutes)
	clock.weather_seed = int(data.get("weather_seed", 1))
	map_id = data.get("map_id", "overworld")
	var position_pair: Array = data.get("player_position", [0, 0])
	player_position = Vector2(position_pair[0], position_pair[1])
	home = data.get("home", {})
	changes = data.get("changes", {})
	known_recipes = data.get("known_recipes", [])
	hints_seen = data.get("hints_seen", {})
	flags = data.get("flags", {})
	play_seconds = data.get("play_seconds", 0.0)
	plant_seed = int(data.get("plant_seed", 1))
	companion = data.get("companion", {})
	animals = data.get("animals", {})


func summary() -> Dictionary:
	return {
		"day": clock.day(),
		"season": clock.season(),
		"play_seconds": play_seconds,
		"look": look,
	}
