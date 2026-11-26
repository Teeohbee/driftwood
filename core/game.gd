extends Node

## The running game: which save slot is loaded, and the endings ever seen.
## Autoloaded as "Game".

const SLOT_COUNT := 3
const ENDINGS_PATH := "user://endings.json"

var current := SaveGame.new()
var endings_seen: Array = []
## Set by tests and tools so nothing is written to the player's real saves.
var save_folder := "user://"


func _ready() -> void:
	endings_seen = read_json(ENDINGS_PATH).get("endings", [])


func slot_path(slot_index: int) -> String:
	return save_folder.path_join("slot_%d.json" % slot_index)


func new_game(slot_index: int, look: Dictionary) -> void:
	current = SaveGame.new()
	current.slot_index = slot_index
	current.look = look
	current.plant_seed = randi() % 997 + 1
	current.clock.weather_seed = randi() % 9973 + 1
	var start := WorldMaps.start_cell("overworld")
	current.player_position = Vector2(start.x * 16 + 8, start.y * 16 + 14)


func load_game(slot_index: int) -> bool:
	var data := read_json(slot_path(slot_index))
	if data.is_empty():
		return false
	current = SaveGame.new()
	current.slot_index = slot_index
	current.load_data(data)
	return true


func save_game() -> void:
	write_json(slot_path(current.slot_index), current.to_data())


func delete_slot(slot_index: int) -> void:
	if FileAccess.file_exists(slot_path(slot_index)):
		DirAccess.remove_absolute(slot_path(slot_index))


## {} for an empty slot, otherwise day, season, play time and look.
func slot_summary(slot_index: int) -> Dictionary:
	var data := read_json(slot_path(slot_index))
	if data.is_empty():
		return {}
	var save := SaveGame.new()
	save.load_data(data)
	return save.summary()


func record_ending(ending_id: String) -> void:
	if not endings_seen.has(ending_id):
		endings_seen.append(ending_id)
	write_json(ENDINGS_PATH, {"endings": endings_seen})


func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_warning("Could not read %s; treating it as empty" % path)
	return {}


func write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s (error %d)" % [path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data, "\t"))
