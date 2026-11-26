class_name Farming
extends RefCounted

## Tilled soil, crops, planters and the animals' morning gifts.
## A crop grows one stage each morning it was watered (rain counts).
## What grows depends on the season you plant in.

const CROP_FOR_SEASON := {"spring": "yam", "summer": "melon", "autumn": "squash", "winter": "beans"}
const GROWTH_TO_RIPEN := 4
const TILLABLE_GROUND := ["grass", "dirt", "sand_sprout"]


static func sprite_for_crop(crop: Dictionary, _today: int) -> String:
	if crop.is_empty():
		return "crop_sprout"
	var growth := int(crop.get("growth", 0))
	if growth >= GROWTH_TO_RIPEN:
		return "crop_%s" % crop["kind"]
	if growth >= 2:
		return "crop_growing"
	return "crop_sprout"


static func is_ripe(crop: Dictionary) -> bool:
	return int(crop.get("growth", 0)) >= GROWTH_TO_RIPEN


## Hoe on grass tills it; seeds on soil plant; water on soil waters.
static func use_on_ground(world: World, item_id: String, cell: Vector2i) -> bool:
	var save := world.save
	var state := save.state_at(world.map_id, cell)
	var floor_name: String = state.get("floor", "")
	if ItemCatalog.tool_kind(item_id) == "hoe":
		if floor_name != "" or world.things_by_cell.has(cell):
			return false
		if not TILLABLE_GROUND.has(world.ground_name_at(cell)):
			world.toast("TOO HARD TO TILL. TRY GRASS.")
			return true
		world.player.swing(item_id)
		save.set_state(world.map_id, cell, "floor", "soil")
		world.refresh_floors()
		Sound.play("dig")
		save.meters.exert(0.5)
		if save.inventory.wear_tool(item_id):
			world.toast("YOUR HOE BROKE!")
		world.hint_once("first_till", ["SOIL! PLANT WILD SEEDS HERE,", "THEN WATER IT WITH A CUP.", "WHAT GROWS DEPENDS ON THE SEASON."])
		return true
	if floor_name.begins_with("soil"):
		return use_on_plot(world, item_id, cell)
	return false


## Works for crops in tilled soil and in planters.
static func use_on_plot(world: World, item_id: String, cell: Vector2i) -> bool:
	var save := world.save
	var state := save.state_at(world.map_id, cell)
	var crop: Dictionary = state.get("crop", {})
	var thing: WorldThing = world.things_by_cell.get(cell, null)
	if item_id == "cup_water":
		save.inventory.remove("cup_water")
		world.give_item("coconut_cup")
		save.set_state(world.map_id, cell, "watered", save.clock.day())
		if state.get("floor", "").begins_with("soil"):
			save.set_state(world.map_id, cell, "floor", "soil_watered")
			world.refresh_floors()
		Sound.play("splash")
		world.toast("WATERED.")
		return true
	if item_id == "seeds" and crop.is_empty():
		save.inventory.remove("seeds")
		var kind: String = CROP_FOR_SEASON[save.clock.season()]
		save.set_state(world.map_id, cell, "crop", {"kind": kind, "growth": 0})
		if thing == null:
			save.set_state(world.map_id, cell, "piece", "crop")
			thing = world.add_thing("crop", cell)
		refresh_plot(world, cell)
		Sound.play("dig")
		world.toast("PLANTED %s SEEDS." % ItemCatalog.display_name(kind))
		return true
	if item_id == "" or item_id == "seeds" or item_id == "cup_water":
		if crop.is_empty():
			world.say(["EMPTY SOIL. PLANT WILD SEEDS."])
			return true
		if is_ripe(crop):
			harvest(world, cell, crop)
			return true
		world.say(["A YOUNG %s PLANT." % ItemCatalog.display_name(crop["kind"]), "WATER IT EVERY DAY. (%d/%d)" % [int(crop["growth"]), GROWTH_TO_RIPEN]])
		return true
	return false


static func harvest(world: World, cell: Vector2i, crop: Dictionary) -> void:
	var save := world.save
	world.interactions.show_got_item(crop["kind"], 2)
	if randf() < 0.6:
		world.give_item("seeds")
	save.set_state(world.map_id, cell, "crop", null)
	if save.state_at(world.map_id, cell).get("piece", "") == "crop":
		save.set_state(world.map_id, cell, "piece", null)
		world.remove_thing_node(cell)
	else:
		refresh_plot(world, cell)


static func refresh_plot(world: World, cell: Vector2i) -> void:
	var thing: WorldThing = world.things_by_cell.get(cell, null)
	if thing == null:
		return
	var crop: Dictionary = world.save.state_at(world.map_id, cell).get("crop", {})
	if thing.kind == "planter":
		thing.show_overlay("" if crop.is_empty() else sprite_for_crop(crop, 0))
	else:
		thing.show_sprite(sprite_for_crop(crop, 0))


## Each morning: watered crops grow, soil dries, tamed animals leave gifts.
static func new_day(save: SaveGame, world: World) -> void:
	var yesterday := save.clock.day() - 1
	var rained := save.clock.weather_on(yesterday) == "rain" or save.clock.weather_on(yesterday) == "storm"
	for plot_map in save.changes.keys():
		for cell in save.cells_with(plot_map, "crop"):
			var state := save.state_at(plot_map, cell)
			var crop: Dictionary = state["crop"].duplicate()
			var was_watered := rained or int(state.get("watered", -1)) >= yesterday
			if was_watered and not is_ripe(crop):
				crop["growth"] = int(crop.get("growth", 0)) + 1
				save.set_state(plot_map, cell, "crop", crop)
		for cell in save.cells_with(plot_map, "floor"):
			if save.state_at(plot_map, cell)["floor"] == "soil_watered":
				save.set_state(plot_map, cell, "floor", "soil")
	if world != null:
		world.refresh_floors()
		for cell in save.cells_with(world.map_id, "crop"):
			refresh_plot(world, cell)
	give_animal_gifts(save, world)


static func give_animal_gifts(save: SaveGame, world: World) -> void:
	if save.home.is_empty():
		return
	var gifts := []
	for creature_id in save.animals:
		var animal: Dictionary = save.animals[creature_id]
		if not animal.get("tamed", false):
			continue
		var product: String = Creature.CREATURES[animal["kind"]].get("product", "")
		if product != "":
			gifts.append({"id": product, "count": 1})
	if gifts.is_empty():
		return
	var home_cell := Vector2i(int(save.home["x"]), int(save.home["y"])) + Vector2i(0, 1)
	if world != null and world.map_id == save.home["map"]:
		world.drop_items_at(home_cell, gifts)
		world.toast("YOUR ANIMALS LEFT GIFTS!")
	else:
		var existing: Array = save.state_at(save.home["map"], home_cell).get("items", [])
		existing.append_array(gifts)
		save.set_state(save.home["map"], home_cell, "items", existing)
