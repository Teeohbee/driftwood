extends Node

## Mashes random buttons all over the island at high speed to shake out
## runtime errors. Watch the output for SCRIPT ERROR lines.
##
##   godot --headless --path . tests/soak_test.tscn

const SOAK_SECONDS := 150.0
const ACTIONS := ["move_up", "move_down", "move_left", "move_right", "action_a", "action_b", "start"]

var game: Node
var world: World
var seconds := 0.0
var held_action := ""
var hold_timer := 0.0
var teleport_timer := 0.0
var map_timer := 20.0
var day_timer := 12.0
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.seed = 1234
	game = get_node("/root/Game")
	DirAccess.make_dir_recursive_absolute("user://soak_saves")
	game.save_folder = "user://soak_saves"
	game.new_game(0, CastawayLook.default_look())
	var save: SaveGame = game.current
	save.inventory.grow_to(16)
	for item_id in ["stone_axe", "stone_pick", "spear", "torch", "fishing_rod", "hammer", "hoe", "coconut_cup", "seeds", "wood", "campfire_kit", "raw_fish", "fruit", "pearl", "claw_pick", "cup_water"]:
		save.inventory.add(item_id, 5)
	world = load("res://scenes/world/world.tscn").instantiate()
	add_child(world)
	Engine.time_scale = 4.0


func _process(delta: float) -> void:
	seconds += delta / Engine.time_scale
	if seconds > SOAK_SECONDS:
		Engine.time_scale = 1.0
		print("Soak finished: day %d, map %s, health %d" % [world.save.clock.day(), world.map_id, world.save.meters.health])
		get_tree().quit()
		return
	hold_timer -= delta
	if hold_timer <= 0.0:
		if held_action != "":
			Input.action_release(held_action)
		held_action = ACTIONS[random.randi() % ACTIONS.size()]
		if held_action == "start" and random.randf() < 0.7:
			held_action = "action_a"
		Input.action_press(held_action)
		hold_timer = random.randf_range(0.05, 0.6)
		var inventory := world.save.inventory
		var item_ids := inventory.item_ids()
		if not item_ids.is_empty() and random.randf() < 0.3:
			inventory.equip("a" if random.randf() < 0.5 else "b", item_ids[random.randi() % item_ids.size()])
	map_timer -= delta / Engine.time_scale
	if map_timer <= 0.0 and world.mode == World.Mode.PLAY:
		map_timer = 20.0
		var target := "cave" if world.map_id == "overworld" else "overworld"
		world.go_through_door(target, Vector2i(23, 21) if target == "cave" else Vector2i(37, 12), Vector2i.DOWN)
	day_timer -= delta / Engine.time_scale
	if day_timer <= 0.0 and world.mode == World.Mode.PLAY:
		day_timer = 12.0
		world.save.clock.total_minutes += DayClock.MINUTES_PER_DAY / 2.0
	teleport_timer -= delta
	if teleport_timer <= 0.0 and world.mode == World.Mode.PLAY:
		teleport_timer = 3.0
		teleport_somewhere()
	# Keep the castaway alive so the soak covers more ground.
	world.save.meters.apply({"health": 5, "hunger": 5, "water": 5})


func teleport_somewhere() -> void:
	for attempt in 50:
		var cell := Vector2i(random.randi() % WorldMaps.width_of(world.map_id), random.randi() % WorldMaps.height_of(world.map_id))
		if not world.is_cell_blocked(cell):
			world.player.place_at(Vector2(cell.x * 16 + 8, cell.y * 16 + 14))
			world.current_room = world.room_of(world.player.exact_position) if world.is_room_camera() else world.current_room
			if world.is_room_camera():
				world.camera.position = world.room_centre(world.current_room)
			return
