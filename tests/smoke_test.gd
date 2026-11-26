extends Node

## Headless checks for Driftwood. Exits non-zero on any failure.
##
##   godot --headless --path . tests/smoke_test.tscn
##
## It runs as a scene (not with -s) so the autoloads exist before it compiles.
##
## Saves go to user://test_saves/ so real save files are never touched.

## A script error skips the checks after it instead of failing them,
## so the run also fails unless every check reported in.
const EXPECTED_CHECK_COUNT := 79
const TEST_SAVE_FOLDER := "user://test_saves"

var failures: Array[String] = []
var checks_reported := 0
var game: Node


func _ready() -> void:
	call_deferred("run_all_checks")


func run_all_checks() -> void:
	game = get_node("/root/Game")
	DirAccess.make_dir_recursive_absolute(TEST_SAVE_FOLDER)
	game.save_folder = TEST_SAVE_FOLDER
	check_baked_art_follows_palette_rules()
	check_palette_checker_catches_too_many_colours()
	check_every_sprite_and_tile_has_art()
	check_inventory_stacks_and_rots()
	check_merging()
	check_clock_and_seasons()
	check_meters()
	check_map_gates()
	check_save_round_trip()
	check_every_ending_can_be_reached()
	await check_scene_runs("res://scenes/title/title_screen.tscn", "title screen")
	await check_scene_runs("res://scenes/save_select/save_select.tscn", "save select")
	await check_world_walks_and_gathers()
	await check_fire_and_cooking()
	await check_cave_door_and_rooms()
	await check_building_and_comfort()
	await check_farming()
	await check_combat_and_guardian()
	await check_raft()
	for ending_id in Endings.ENDING_IDS:
		Endings.pending_ending = ending_id
		await check_scene_runs("res://scenes/ending/ending.tscn", "the %s ending" % ending_id)
	Endings.pending_ending = ""
	await check_stay_offer()
	await check_radio_ending_flags()

	if checks_reported != EXPECTED_CHECK_COUNT:
		failures.append("%d of %d checks ran - look for script errors above" % [checks_reported, EXPECTED_CHECK_COUNT])
	for failure in failures:
		printerr("FAIL: ", failure)
	print("Smoke test: %d failure(s), %d checks" % [failures.size(), checks_reported])
	get_tree().quit(1 if failures.size() > 0 else 0)


func expect(condition: bool, description: String) -> void:
	checks_reported += 1
	if condition:
		print("ok   ", description)
	else:
		failures.append(description)


# --- Art ------------------------------------------------------------------------

func check_baked_art_follows_palette_rules() -> void:
	var problems := PaletteChecker.check_all_art()
	for problem in problems:
		printerr(problem)
	expect(problems.is_empty(), "baked art follows the Game Boy Color palette rules")


func check_palette_checker_catches_too_many_colours() -> void:
	var image := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	var sand := Palettes.background_colors("sand")
	image.fill(sand[0])
	image.set_pixel(0, 0, sand[1])
	image.set_pixel(1, 0, sand[2])
	image.set_pixel(2, 0, sand[3])
	image.set_pixel(3, 0, Palettes.background_color("water", 1))
	var problems := PaletteChecker.check_image("five colours", image, "background")
	expect(problems.size() == 1, "palette checker rejects a cell with five colours")


func check_every_sprite_and_tile_has_art() -> void:
	var missing := []
	for item_id in ItemCatalog.ITEMS:
		if not ResourceLoader.exists("res://art/sprites/%s.png" % ItemCatalog.sprite_for(item_id)):
			missing.append(item_id)
	for kind in ThingCatalog.THINGS:
		var sprite_name := ThingCatalog.sprite_for(kind)
		if sprite_name != "" and kind != "crop" and not ResourceLoader.exists("res://art/sprites/%s.png" % sprite_name):
			missing.append(kind)
	for kind in Creature.CREATURES:
		if not ResourceLoader.exists("res://art/sprites/%s.png" % kind):
			missing.append(kind)
	expect(missing.is_empty(), "every item, thing and creature has a sprite (missing %s)" % [missing])
	var tile_order := PixelArt.ground_tile_order()
	var missing_tiles := []
	for ground in WorldMaps.GROUND_FOR_CHARACTER.values().filter(func(ground: String) -> bool: return ground != "sand") + ["sand_a", "sand_b", "sand_shade", "soil", "soil_watered", "wood_floor"]:
		if not tile_order.has(ground):
			missing_tiles.append(ground)
	expect(missing_tiles.is_empty(), "every ground on the maps has a tile (missing %s)" % [missing_tiles])
	var unknown_ingredients := []
	for recipe in RecipeBook.RECIPES:
		for item_id in recipe["ingredients"] + [recipe["result"]]:
			if not ItemCatalog.has_item(item_id):
				unknown_ingredients.append(item_id)
	expect(unknown_ingredients.is_empty(), "every recipe uses real items (unknown %s)" % [unknown_ingredients])


# --- Systems ---------------------------------------------------------------------

func check_inventory_stacks_and_rots() -> void:
	var inventory := Inventory.new()
	var leftover := inventory.add("stick", 12)
	expect(leftover == 0 and inventory.slots[0]["count"] == 9 and inventory.slots[1]["count"] == 3, "sticks stack nine to a slot")
	inventory.add("stone_axe")
	inventory.add("stone_axe")
	expect(inventory.count_of("stone_axe") == 2 and inventory.slots[3]["id"] == "stone_axe", "tools take a slot each")
	for extra in 6:
		inventory.add("shell", 9)
	expect(inventory.add("flint") == 1, "a full bag refuses more")
	expect(inventory.remove("stick", 10) and inventory.count_of("stick") == 2, "removing takes from stacks")
	var fresh := Inventory.new()
	fresh.add("fruit", 2)
	for day in 3:
		fresh.age_one_day()
	expect(fresh.count_of("fruit") == 0 and fresh.count_of("rotten_food") == 2, "fruit rots after three days")
	fresh.add("stone_axe")
	fresh.equip("a", "stone_axe")
	for use in ItemCatalog.uses("stone_axe"):
		fresh.wear_tool("stone_axe")
	expect(fresh.count_of("stone_axe") == 0 and fresh.equipped_a == "", "a worn-out tool breaks and leaves the A button")


func check_merging() -> void:
	var save := SaveGame.new()
	save.inventory.add("stone", 2)
	var result := Merging.merge(save, [0, 0])
	expect(result["success"] and save.inventory.count_of("sharp_stone") == 1 and save.inventory.count_of("stone") == 0, "stone + stone makes a sharp stone")
	save.inventory.add("coconut")
	var coconut_slot := save.inventory.slots.find(save.inventory.slots.filter(func(slot: Dictionary) -> bool: return slot.get("id", "") == "coconut")[0])
	var knife_slot := save.inventory.slots.find(save.inventory.slots.filter(func(slot: Dictionary) -> bool: return slot.get("id", "") == "sharp_stone")[0])
	Merging.merge(save, [coconut_slot, knife_slot])
	expect(save.inventory.count_of("coconut_open") == 1 and save.inventory.count_of("sharp_stone") == 1, "the sharp stone survives opening a coconut")
	save.inventory.add("shell")
	save.inventory.add("feather")
	var shell_slot := save.inventory.slots.find(save.inventory.slots.filter(func(slot: Dictionary) -> bool: return slot.get("id", "") == "shell")[0])
	var feather_slot := save.inventory.slots.find(save.inventory.slots.filter(func(slot: Dictionary) -> bool: return slot.get("id", "") == "feather")[0])
	var failed := Merging.merge(save, [shell_slot, feather_slot])
	expect(not failed["success"] and save.inventory.count_of("shell") == 1, "a bad merge says nothing happens and keeps the items")
	expect(save.known_recipes.size() == 2, "discovered merges go in the book")


func check_clock_and_seasons() -> void:
	var clock := DayClock.new()
	expect(clock.day() == 1 and clock.hour() == 6 and clock.darkness_step() == 0, "day one starts at six in the morning, light")
	clock.advance(15.0 * 60 * DayClock.REAL_SECONDS_PER_GAME_MINUTE)
	expect(clock.hour() == 21 and clock.darkness_step() == 3 and clock.can_sleep(), "nine at night is dark and sleepy")
	clock.sleep_until_morning()
	expect(clock.day() == 2 and clock.hour() == 6, "sleeping wakes you at six the next day")
	clock.total_minutes += DayClock.MINUTES_PER_DAY * 7
	expect(clock.season() == "summer", "day nine is summer")
	var seen := {}
	for day_number in range(2, 60):
		seen[clock.weather_on(day_number)] = true
	expect(seen.size() >= 3, "the weather varies over two months")


func check_meters() -> void:
	var meters := SurvivalMeters.new()
	meters.hunger = 0.0
	meters.tick(60, false)
	expect(meters.health < 100.0, "starving hurts")
	meters.load_data({})
	meters.sleep(true, 3)
	expect(meters.fatigue == 100.0 and meters.is_rested() and meters.rested_minutes == 7 * 60, "sleeping sheltered rests you, longer with comfort")
	var water_before := meters.water
	meters.tick(60, false)
	var rested_drop := water_before - meters.water
	meters.rested_minutes = 0.0
	water_before = meters.water
	meters.tick(60, false)
	expect(absf(rested_drop * 2.0 - (water_before - meters.water)) < 0.01, "rested meters drain at half speed")


## The island must be beatable: each gate opens the next region.
func check_map_gates() -> void:
	var reachable := reachable_cells(["vines", "boulder", "great_boulder"])
	expect(not reachable.has(Vector2i(18, 8)) and reachable.has(Vector2i(37, 11)), "jungle is shut until vines are cut; the cave mouth is open")
	reachable = reachable_cells(["boulder", "great_boulder"])
	expect(reachable.has(Vector2i(18, 10)) and not reachable.has(Vector2i(53, 7)), "cutting vines opens the jungle, not the hill")
	reachable = reachable_cells(["great_boulder"])
	expect(reachable.has(Vector2i(53, 8)), "breaking the boulders opens the hill to the beacon site")


func reachable_cells(closed_kinds: Array) -> Dictionary:
	var start := WorldMaps.start_cell("overworld")
	var seen := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var cell: Vector2i = todo.pop_back()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if seen.has(next) or not WorldMaps.is_inside("overworld", next):
				continue
			if World.BLOCKING_GROUND.has(WorldMaps.ground_at("overworld", next)):
				continue
			var kind := WorldMaps.thing_at("overworld", next)
			seen[next] = true
			var is_closed := closed_kinds.has(kind) or (ThingCatalog.blocks(kind) and not ["vines", "boulder", "great_boulder"].has(kind))
			if not is_closed:
				todo.append(next)
	return seen


## Works out everything a player could ever get, starting empty-handed on the
## beach: what they can reach depends on their tools, and new tools come from
## what they can reach. Then checks each ending's needs are in that set.
func check_every_ending_can_be_reached() -> void:
	var have := obtainable_items()
	expect(have.has("stone_axe") and have.has("stone_pick") and have.has("torch"), "first tools can be made from the beach and jungle")
	expect(have.has("claw_pick") and have.has("copper"), "the guardian's claw leads to copper")
	expect(have.has("wire") and have.has("battery"), "the radio parts can be made")
	var beacon_ok := ["wood", "hardwood", "resin"].all(func(item_id: String) -> bool: return have.has(item_id))
	var boat_ok := ["hardwood", "rope", "cloth", "copper"].all(func(item_id: String) -> bool: return have.has(item_id))
	expect(beacon_ok and boat_ok and have.has("fibre") and have.has("leaf"), "the beacon, the sailboat and a bed can be built")


func obtainable_items() -> Dictionary:
	var have := {}
	var changed := true
	while changed:
		changed = false
		var closed := []
		if not has_tool(have, "knife", 1):
			closed.append("vines")
		if not has_tool(have, "pick", 1):
			closed.append("boulder")
		if not has_tool(have, "pick", 2):
			closed.append("great_boulder")
		var reachable := reachable_cells(closed)
		var gains := []
		var can_raft := have.has("driftwood") and have.has("rope")
		for map_id in ["overworld", "cave"]:
			var is_cave: bool = map_id == "cave"
			if is_cave and not have.has("torch"):
				continue
			for row in WorldMaps.height_of(map_id):
				for column in WorldMaps.width_of(map_id):
					var cell := Vector2i(column, row)
					var on_islet: bool = map_id == "overworld" and column >= 64
					if map_id == "overworld" and not reachable.has(cell) and not (on_islet and can_raft):
						continue
					gains.append_array(gains_from_thing(WorldMaps.thing_at(map_id, cell), have))
					var creature := WorldMaps.creature_at(map_id, cell)
					if creature != "":
						gains.append_array(Creature.CREATURES[creature]["drops"].keys())
					if WorldMaps.thing_at(map_id, cell) == "crate":
						gains.append_array(WorldMaps.map_data(map_id)["crates"].get(cell, []))
		if have.has("coconut_cup"):
			gains.append_array(["cup_water", "cup_seawater"])
		if have.has("pearl"):
			for reward in Hermit.PEARL_REWARDS:
				gains.append(reward[0])
		if have.has("copper_ore") and have.has("clay") and have.has("stone"):
			gains.append("copper")
		for item_id in have.keys():
			if ItemCatalog.cooks_into(item_id) != "":
				gains.append(ItemCatalog.cooks_into(item_id))
		for recipe in RecipeBook.RECIPES:
			if recipe["ingredients"].all(func(item_id: String) -> bool: return have.has(item_id)):
				gains.append(recipe["result"])
				if recipe.has("leaves"):
					gains.append(recipe["leaves"])
		for item_id in gains:
			if not have.has(item_id):
				have[item_id] = true
				changed = true
	return have


func has_tool(have: Dictionary, kind: String, tier: int) -> bool:
	for item_id in have:
		if ItemCatalog.tool_kind(item_id) == kind and ItemCatalog.tool_tier(item_id) >= tier:
			return true
	return false


func gains_from_thing(kind: String, have: Dictionary) -> Array:
	if kind == "":
		return []
	var info := ThingCatalog.thing(kind)
	var gains := []
	if info.has("pickup"):
		gains.append(info["pickup"]["item"])
	if info.has("harvest"):
		gains.append(info["harvest"]["item"])
		gains.append(info["harvest"].get("otherwise", info["harvest"]["item"]))
	for action in ThingCatalog.tool_actions(kind):
		if has_tool(have, action["kind"], action["tier"]):
			gains.append_array(action["gives"].keys())
			gains.append_array(action.get("bonus", {}).keys())
	return gains


func check_save_round_trip() -> void:
	game.new_game(2, {"skin": 1, "shirt": 2, "hair": 3})
	var save: SaveGame = game.current
	save.inventory.add("rope", 2)
	save.inventory.equip("b", "rope")
	save.set_state("overworld", Vector2i(3, 4), "floor", "soil")
	save.known_recipes.append("stone+stone")
	save.clock.total_minutes += 3000
	game.save_game()
	expect(game.load_game(2), "a saved slot loads")
	var loaded: SaveGame = game.current
	var matches: bool = loaded.inventory.count_of("rope") == 2 and loaded.inventory.equipped_b == "rope" and loaded.state_at("overworld", Vector2i(3, 4)).get("floor", "") == "soil" and loaded.look["hair"] == 3 and loaded.clock.day() == save.clock.day()
	expect(matches, "bag, world changes, look and day survive saving")
	expect(game.slot_summary(2)["day"] == save.clock.day() and game.slot_summary(1).is_empty(), "the save select sees used and empty slots")
	game.delete_slot(2)


# --- Scenes ------------------------------------------------------------------------

func check_scene_runs(path: String, label: String) -> void:
	var scene: Node = load(path).instantiate()
	get_tree().root.add_child(scene)
	for frame in 30:
		await get_tree().process_frame
	expect(is_instance_valid(scene), "%s runs for 30 frames" % label)
	scene.queue_free()
	await get_tree().process_frame


func new_world() -> World:
	game.new_game(0, CastawayLook.default_look())
	game.current.set_flag("intro_done")
	var world: World = load("res://scenes/world/world.tscn").instantiate()
	get_tree().root.add_child(world)
	await get_tree().process_frame
	return world


func free_world(world: World) -> void:
	world.queue_free()
	await get_tree().process_frame


func stand_facing(world: World, cell: Vector2i, facing: Vector2i) -> void:
	var feet := Vector2(cell.x * 16 + 8, cell.y * 16 + 14) - Vector2(facing) * 16
	world.player.place_at(feet)
	world.player.face_towards(Vector2(facing))


func check_world_walks_and_gathers() -> void:
	var world := await new_world()
	var player := world.player
	var start_x := player.exact_position.x
	for step in 10:
		player.walk(Vector2.RIGHT, 0.1)
	expect(player.exact_position.x > start_x + 40, "castaway walks right on the beach")
	for step in 100:
		player.walk(Vector2.DOWN, 0.1)
	expect(player.exact_position.y < 42 * 16, "the sea stops the castaway")
	for frame in 20:
		await get_tree().process_frame
	expect(world.mode == World.Mode.PLAY, "the world runs in play mode")

	stand_facing(world, Vector2i(26, 36), Vector2i.UP)
	world.interactions.press("a")
	expect(world.save.inventory.count_of("stick") == 1 and not world.things_by_cell.has(Vector2i(26, 36)), "pressing A picks up a stick")
	expect(world.save.state_at("overworld", Vector2i(26, 36)).get("gone", -1) == world.save.clock.day() + 2, "the stick grows back in two days")

	stand_facing(world, Vector2i(20, 39), Vector2i.RIGHT)
	world.interactions.press("a")
	expect(world.save.inventory.count_of("rope") == 1 and world.save.state_at("overworld", Vector2i(20, 39)).get("opened", false), "the wreck crate gives rope")
	world.dialogue_box.close_box()
	world.player.set_pose("normal")
	world.set_mode(World.Mode.PLAY)

	world.save.inventory.add("sharp_stone")
	world.save.inventory.equip("a", "sharp_stone")
	stand_facing(world, Vector2i(27, 31), Vector2i.UP)
	world.interactions.press("a")
	expect(world.save.inventory.count_of("fibre") >= 2, "a sharp stone cuts tall grass for fibre")
	free_world(world)
	await get_tree().process_frame


func check_fire_and_cooking() -> void:
	var world := await new_world()
	var fire_cell := Vector2i(25, 39)
	stand_facing(world, fire_cell, Vector2i.RIGHT)
	world.save.inventory.add("campfire_kit")
	world.save.inventory.equip("a", "campfire_kit")
	world.interactions.press("a")
	expect(world.things_by_cell.has(fire_cell) and world.is_fire_lit(fire_cell), "a campfire kit places a lit fire")
	world.dialogue_box.close_box()
	world.set_mode(World.Mode.PLAY)
	world.save.inventory.add("raw_fish")
	world.save.inventory.equip("a", "raw_fish")
	world.interactions.press("a")
	expect(world.save.inventory.count_of("cooked_fish") == 1, "raw fish cooks on the fire")
	world.save.inventory.add("driftwood")
	world.save.inventory.equip("b", "driftwood")
	var before := float(world.save.state_at("overworld", fire_cell)["burns_until"])
	world.interactions.press("b")
	expect(float(world.save.state_at("overworld", fire_cell)["burns_until"]) == before + 120, "driftwood keeps the fire burning two more hours")
	world.save.clock.total_minutes += 400
	expect(not world.is_fire_lit(fire_cell), "a fire burns out when left")
	world.save.inventory.add("cooked_fish")
	var hunger_before := world.save.meters.hunger
	world.interactions.use_alone("cooked_fish")
	expect(world.save.meters.hunger > hunger_before, "eating cooked fish fills you")
	world.save.clock.total_minutes = float(DayClock.MINUTES_PER_DAY + 20 * 60)
	await world.sleep(false)
	expect(world.save.clock.day() == 3 and game.slot_summary(0).get("day", 0) == 3, "sleeping moves to morning and saves")
	world.dialogue_box.close_box()
	free_world(world)
	await get_tree().process_frame


func check_cave_door_and_rooms() -> void:
	var world := await new_world()
	await world.go_through_door("cave", Vector2i(23, 21), Vector2i.UP)
	expect(world.map_id == "cave" and world.is_room_camera(), "the cave mouth leads to the cave rooms")
	world.player.place_at(Vector2(23 * 16 + 8, 18 * 16 + 14))
	world.check_room_change()
	expect(world.current_room == Vector2i(1, 2), "the camera knows which cave room you are in")
	world.player.place_at(Vector2(23 * 16 + 8, 15 * 16 + 14))
	world.check_room_change()
	expect(world.current_room == Vector2i(1, 1) and world.mode == World.Mode.ROOM_SLIDE, "walking north slides to the next room")
	free_world(world)
	await get_tree().process_frame


func check_building_and_comfort() -> void:
	var world := await new_world()
	var save := world.save
	save.inventory.grow_to(16)
	save.inventory.add("wood", 9)
	save.inventory.add("stone", 2)
	save.inventory.add("leaf", 3)
	save.inventory.add("fibre", 3)
	world.player.place_at(Vector2(40 * 16 + 8, 35 * 16 + 14))
	var near := Vector2i(41, 35)
	expect(Building.placement_problem(world, "wall", near) == "BUILD A WORKBENCH NEARBY FIRST.", "walls need a workbench nearby")
	var problem := Building.placement_problem(world, "workbench", near)
	expect(problem == "", "a workbench fits on open grass (%s)" % problem)
	Building.place(world, "workbench", near)
	expect(save.inventory.count_of("wood") == 6 and world.things_by_cell.has(near), "building spends materials and places the piece")
	Building.place(world, "bed", Vector2i(40, 37))
	expect(Building.comfort_around(world, Vector2i(40, 37)) == 2, "comfort counts the bed and workbench")
	var stick_cell := Vector2i(26, 36)
	save.set_state("overworld", stick_cell, "gone", save.clock.day() + 1)
	world.remove_thing_node(stick_cell)
	save.clock.sleep_until_morning()
	world.on_new_day()
	expect(world.things_by_cell.has(stick_cell), "a picked stick grows back the next morning")
	var fire_cell := Vector2i(43, 36)
	save.inventory.add("stick", 2)
	Building.place(world, "campfire", fire_cell)
	save.clock.weather_seed = find_rainy_seed(save.clock.day())
	world.douse_fires_in_rain()
	expect(not world.is_fire_lit(fire_cell), "rain puts out a fire with no roof")
	var taken := Building.dismantle(world, near)
	expect(taken == "workbench" and save.inventory.count_of("wood") >= 2, "taking down gives half the cost back")
	free_world(world)
	await get_tree().process_frame


func find_rainy_seed(day_number: int) -> int:
	var clock := DayClock.new()
	for seed in range(1, 500):
		clock.weather_seed = seed
		if clock.weather_on(day_number) == "rain":
			return seed
	return 1


func check_farming() -> void:
	var world := await new_world()
	var save := world.save
	var plot := Vector2i(28, 29)
	save.inventory.add("hoe")
	save.inventory.add("seeds", 2)
	save.inventory.add("cup_water")
	Farming.use_on_ground(world, "hoe", plot)
	expect(save.state_at("overworld", plot).get("floor", "") == "soil", "a hoe tills grass")
	Farming.use_on_ground(world, "seeds", plot)
	expect(save.state_at("overworld", plot).has("crop") and world.things_by_cell.has(plot), "seeds plant a crop")
	for day in Farming.GROWTH_TO_RIPEN:
		save.set_state("overworld", plot, "watered", save.clock.day())
		save.clock.sleep_until_morning()
		Farming.new_day(save, world)
	expect(Farming.is_ripe(save.state_at("overworld", plot)["crop"]), "watered every day, a crop ripens")
	Farming.use_on_plot(world, "", plot)
	expect(save.inventory.count_of("yam") == 2, "spring seeds grow yams")
	save.clock.total_minutes += DayClock.MINUTES_PER_DAY * 14
	save.inventory.add("seeds")
	Farming.use_on_ground(world, "seeds", plot)
	expect(save.state_at("overworld", plot)["crop"]["kind"] == "squash", "autumn seeds grow squash")

	var hen := world.add_creature("hen", Vector2i(30, 36))
	hen.player = world.player
	save.inventory.add("seeds", 2)
	world.interactions.feed_creature("seeds", hen)
	world.dialogue_box.close_box()
	world.interactions.feed_creature("seeds", hen)
	world.dialogue_box.close_box()
	expect(hen.is_tamed and save.animals[hen.id()]["tamed"], "two handfuls of seeds tame a hen")
	save.home = {"map": "overworld", "x": 40, "y": 36}
	Farming.give_animal_gifts(save, world)
	var gift_cell := world.free_cell_near(Vector2i(40, 37))
	var gifts: Array = save.state_at("overworld", gift_cell).get("items", [])
	expect(gifts.any(func(entry: Dictionary) -> bool: return entry["id"] == "egg"), "a tamed hen lays an egg by your bed each morning")
	free_world(world)
	await get_tree().process_frame


func check_combat_and_guardian() -> void:
	var world := await new_world()
	var boar := world.add_creature("boar", Vector2i(30, 37))
	boar.player = world.player
	var killed := false
	for hit in 5:
		boar.hurt_timer = 0.0
		killed = boar.take_hit(ItemCatalog.damage("spear"), world.player.exact_position)
	expect(killed, "a spear kills a boar")
	var guardian := world.add_creature("guardian", Vector2i(34, 37))
	expect(not guardian.take_hit(50, world.player.exact_position) and guardian.health == 30, "the guardian shrugs off hits unless stunned")
	guardian.state = "stunned"
	guardian.take_hit(6, world.player.exact_position)
	expect(guardian.health == 24, "a stunned guardian takes damage")
	world.interactions.defeat_creature(guardian)
	expect(world.save.flag("guardian_defeated"), "beating the guardian is remembered")
	free_world(world)
	await get_tree().process_frame


func check_raft() -> void:
	var world := await new_world()
	var save := world.save
	save.inventory.add("driftwood", 4)
	save.inventory.add("rope", 2)
	var water_cell := Vector2i(64, 30)
	world.player.place_at(Vector2(63 * 16 + 8, 30 * 16 + 14))
	expect(Building.placement_problem(world, "raft", water_cell) == "", "a raft can be built on the sea by the east shore")
	Building.place(world, "raft", water_cell)
	world.interactions.board_raft(world.things_by_cell[water_cell])
	expect(save.flag("on_raft") and not world.is_cell_blocked(Vector2i(65, 30)), "aboard the raft, the sea is open")
	world.player.place_at(Vector2(69 * 16 + 8, 18 * 16 + 14))
	world.player.face_towards(Vector2.LEFT)
	world.check_raft_landing()
	expect(not save.flag("on_raft"), "stepping onto the islet's sand leaves the raft")
	free_world(world)
	await get_tree().process_frame


func check_stay_offer() -> void:
	var world := await new_world()
	var save := world.save
	save.clock.total_minutes = float((Endings.STAY_EARLIEST_DAY - 1) * DayClock.MINUTES_PER_DAY + 7 * 60)
	save.home = {"map": "overworld", "x": 40, "y": 36}
	world.player.place_at(Vector2(40 * 16 + 8, 36 * 16 + 14))
	var comfy_pieces := ["bed", "workbench", "chest", "table", "rug", "lamp"]
	for piece_index in comfy_pieces.size():
		var cell := Vector2i(38 + piece_index, 34)
		save.set_state("overworld", cell, "piece", comfy_pieces[piece_index])
		world.add_thing(comfy_pieces[piece_index], cell)
	Endings.check_stay_offer(world)
	expect(world.dialogue_box.is_open and world.dialogue_box.choices == ["STAY", "NOT YET"], "after a year in a comfy home, you are offered to stay")
	world.dialogue_box.close_box()
	free_world(world)
	await get_tree().process_frame


func check_radio_ending_flags() -> void:
	var world := await new_world()
	var save := world.save
	save.inventory.add("wire", 2)
	save.inventory.add("battery")
	Endings.use_on_radio(world, "wire")
	Endings.use_on_radio(world, "battery")
	expect(not save.flag("radio_fixed"), "one wire is not enough")
	Endings.use_on_radio(world, "wire")
	expect(save.flag("radio_fixed") and save.inventory.count_of("wire") == 0, "two wires and a battery fix the radio")
	free_world(world)
	await get_tree().process_frame
