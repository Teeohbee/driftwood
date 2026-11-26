class_name Interactions
extends RefCounted

## What happens when you press A or B. Each button holds an item (or bare
## hands). The order of questions:
##   1. Is a creature in reach?  Feed it, talk to it, or hit it.
##   2. Is a thing in front?     Use the item on it, else bare-hand it.
##   3. Is open ground in front? Fill a cup, fish, till, plant, place.
##   4. Otherwise                Use the item by itself: eat, drink, swing.

var world: World


func _init(owner_world: World) -> void:
	world = owner_world


func save() -> SaveGame:
	return world.save


func inventory() -> Inventory:
	return world.save.inventory


# --- What is in front --------------------------------------------------------

func creature_in_reach() -> Creature:
	var reach := Rect2(world.player.point_in_front() - Vector2(7, 7), Vector2(14, 14))
	for creature in world.creatures:
		if is_instance_valid(creature) and creature.interaction_area().intersects(reach):
			return creature
	return null


func thing_in_front() -> WorldThing:
	return world.things_by_cell.get(world.player.cell_in_front(), null)


## Used for the "!" bubble: something worth pressing A on.
func describe_target() -> String:
	var creature := creature_in_reach()
	if creature != null and not creature.is_hostile():
		return creature.kind
	var thing := thing_in_front()
	if thing != null and thing.kind != "wall" and thing.kind != "rug" and thing.kind != "planter":
		return thing.kind
	return ""


func is_holding_light() -> bool:
	return ItemCatalog.tool_kind(inventory().equipped_a) == "light" or ItemCatalog.tool_kind(inventory().equipped_b) == "light"


## Torches burn down: each hour held in the dark costs one use.
func wear_torch_in_darkness() -> void:
	var is_dark: bool = WorldMaps.map_data(world.map_id)["is_dark"] or world.save.clock.darkness_step() >= 2
	if not is_dark:
		return
	for item_id in [inventory().equipped_a, inventory().equipped_b]:
		if ItemCatalog.tool_kind(item_id) == "light":
			if inventory().wear_tool(item_id):
				world.toast("YOUR TORCH BURNED OUT.")
			return


# --- Pressing a button ---------------------------------------------------------

func press(button: String) -> void:
	var item_id := inventory().equipped(button)
	var creature := creature_in_reach()
	if creature != null:
		use_on_creature(item_id, creature)
		return
	var thing := thing_in_front()
	if thing != null:
		if use_item_on_thing(item_id, thing):
			return
		bare_hands_on_thing(thing)
		return
	if use_on_ground(item_id, world.player.cell_in_front()):
		return
	if item_id == "":
		return
	use_alone(item_id)


func show_got_item(item_id: String, count: int) -> void:
	world.give_item(item_id, count)
	world.toast("+%d %s" % [count, ItemCatalog.display_name(item_id)])
	Sound.play("pickup")


## The Link's Awakening moment: hold a new tool over your head.
func show_new_find(item_id: String, lines: Array) -> void:
	world.player.set_pose("hold", item_id)
	Sound.play("fanfare")
	world.say(lines, func() -> void: world.player.set_pose("normal"))


# --- Creatures ------------------------------------------------------------------

func use_on_creature(item_id: String, creature: Creature) -> void:
	if creature.kind == "hermit":
		Hermit.talk(world, item_id)
		return
	var tame_food: Array = creature.info().get("tame_food", [])
	if tame_food.has(item_id) and not creature.is_tamed:
		feed_creature(item_id, creature)
		return
	if creature.is_tamed or creature.is_companion:
		pet_creature(creature)
		return
	if creature.kind in ["goat", "hen", "monkey"]:
		var wants := ItemCatalog.display_name(tame_food[0])
		world.say(["THE %s EYES YOU WARILY." % creature.kind.to_upper(), "MAYBE IT IS HUNGRY... %s?" % wants])
		return
	attack(item_id, creature)


func attack(item_id: String, creature: Creature) -> void:
	world.player.swing(item_id if item_id != "" else "")
	Sound.play("swing")
	save().meters.exert(0.5)
	if not creature.is_vulnerable():
		Sound.play("clang")
		world.toast("CLANG! ITS SHELL IS TOO HARD.")
		return
	var killed := creature.take_hit(ItemCatalog.damage(item_id), world.player.exact_position)
	Sound.play("hit")
	if ItemCatalog.uses(item_id) > 0 and inventory().wear_tool(item_id):
		world.toast("YOUR %s BROKE!" % ItemCatalog.display_name(item_id))
	if killed:
		defeat_creature(creature)


func defeat_creature(creature: Creature) -> void:
	world.creatures.erase(creature)
	creature.queue_free()
	Sound.play("defeat")
	var drops: Dictionary = creature.drops()
	for drop_id in drops:
		world.drop_items_at(creature.spawn_cell if creature.kind == "guardian" else world.cell_at(creature.exact_position), [{"id": drop_id, "count": drops[drop_id]}])
	if creature.kind == "guardian":
		save().set_flag("guardian_defeated")
		Sound.play_music("cave")
		world.say(["THE GUARDIAN CRASHES DOWN!", "IT LEAVES A GREAT CLAW BEHIND.", "MERGE IT WITH HARDWOOD AND ROPE?"])
		return
	var record: Dictionary = save().animals.get(creature.id(), {})
	record["kind"] = creature.kind
	record["dead_until"] = save().clock.day() + 2
	save().animals[creature.id()] = record


func feed_creature(item_id: String, creature: Creature) -> void:
	inventory().remove(item_id)
	var record: Dictionary = save().animals.get(creature.id(), {"kind": creature.kind, "x": creature.spawn_cell.x, "y": creature.spawn_cell.y})
	record["fed"] = int(record.get("fed", 0)) + 1
	Sound.play("eat")
	var needed: int = creature.info()["feeds_to_tame"]
	if record["fed"] >= needed:
		record["tamed"] = true
		record["kind"] = creature.kind
		record["x"] = creature.spawn_cell.x
		record["y"] = creature.spawn_cell.y
		save().animals[creature.id()] = record
		creature.is_tamed = true
		Sound.play("fanfare")
		if creature.kind == "monkey":
			save().companion = {"active": true}
			creature.is_companion = true
			world.say(["THE MONKEY HOPS ONTO YOUR", "SHOULDER. YOU CALL IT BO.", "BO WILL FIND THINGS FOR YOU!"])
		else:
			var product := ItemCatalog.display_name(creature.info()["product"])
			world.say(["THE %s TRUSTS YOU NOW!" % creature.kind.to_upper(), "IT WILL LIVE BY YOUR BED", "AND GIVE %s EACH MORNING." % product])
		return
	save().animals[creature.id()] = record
	world.say(["THE %s GOBBLES IT UP." % creature.kind.to_upper(), "IT SEEMS FRIENDLIER. (%d/%d)" % [record["fed"], needed]])


func pet_creature(creature: Creature) -> void:
	Sound.play("companion")
	match creature.kind:
		"monkey":
			world.say(["BO CHATTERS HAPPILY."])
		"goat":
			world.say(["THE GOAT NUZZLES YOU."])
		"hen":
			world.say(["THE HEN CLUCKS."])
		_:
			world.say(["IT SEEMS CONTENT."])


# --- Things ----------------------------------------------------------------------

## Returns true if the item did something to the thing.
func use_item_on_thing(item_id: String, thing: WorldThing) -> bool:
	if item_id == "":
		return false
	var tool := ItemCatalog.tool_kind(item_id)
	for action in ThingCatalog.tool_actions(thing.kind):
		if action["kind"] == tool:
			use_tool_on_thing(item_id, action, thing)
			return true
	match thing.kind:
		"campfire":
			return Cooking.use_on_fire(world, item_id, thing)
		"kiln":
			return Cooking.use_on_kiln(world, item_id, thing)
		"drying_rack":
			return Cooking.use_on_rack(world, item_id, thing)
		"radio":
			return Endings.use_on_radio(world, item_id)
		"beacon":
			return Endings.use_on_beacon(world, item_id)
		"crop", "planter":
			return Farming.use_on_plot(world, item_id, thing.cell)
	if tool == "hammer":
		world.builder.open_for(thing.cell)
		return true
	return false


func use_tool_on_thing(item_id: String, action: Dictionary, thing: WorldThing) -> void:
	world.player.swing(item_id)
	if ItemCatalog.tool_tier(item_id) < action["tier"]:
		Sound.play("clang")
		world.toast("TOO HARD FOR A %s." % ItemCatalog.display_name(item_id))
		return
	if save().meters.is_exhausted():
		world.toast("TOO TIRED. SLEEP FIRST.")
		return
	if action.get("keeps", false) and action.has("every"):
		var ready_day := int(save().state_at(world.map_id, thing.cell).get("tool_day", 0))
		if save().clock.day() < ready_day:
			world.toast("NOTHING MORE TODAY.")
			return
	Sound.play("chop" if action["kind"] == "axe" else ("mine" if action["kind"] == "pick" else "cut"))
	save().meters.exert(1.0)
	thing.flash()
	thing.hits_taken += 1
	if thing.hits_taken < action["hits"]:
		return
	thing.hits_taken = 0
	if inventory().wear_tool(item_id):
		world.toast("YOUR %s BROKE!" % ItemCatalog.display_name(item_id))
	var gives: Dictionary = action["gives"]
	for given_id in gives:
		show_got_item(given_id, gives[given_id])
	var bonus: Dictionary = action.get("bonus", {})
	for bonus_id in bonus:
		if randi() % 100 < bonus[bonus_id]:
			show_got_item(bonus_id, 1)
	if action.get("keeps", false):
		if action.has("every"):
			save().set_state(world.map_id, thing.cell, "tool_day", save().clock.day() + int(action["every"]))
		return
	remove_thing_for_days(thing, int(action.get("regrow", 0)))


func remove_thing_for_days(thing: WorldThing, regrow_days: int) -> void:
	var regrow_day := 0 if regrow_days == 0 else save().clock.day() + regrow_days
	save().set_state(world.map_id, thing.cell, "gone", regrow_day)
	world.remove_thing_node(thing.cell)


func bare_hands_on_thing(thing: WorldThing) -> void:
	var info := ThingCatalog.thing(thing.kind)
	var state := save().state_at(world.map_id, thing.cell)
	match thing.kind:
		"dropped":
			pick_up_dropped(thing)
			return
		"crate":
			open_crate(thing)
			return
		"sign":
			Sound.play("blip")
			world.say(WorldMaps.map_data(world.map_id)["signs"].get(thing.cell, ["THE WRITING HAS WORN AWAY."]))
			return
		"bottle_note":
			remove_thing_for_days(thing, 0)
			world.give_item("bottle_note")
			show_new_find("bottle_note", ["A NOTE IN A BOTTLE!"] + WorldMaps.NOTE_LINES)
			return
		"campfire":
			Cooking.rest_at_fire(world, thing)
			return
		"bed":
			if save().clock.can_sleep() or save().meters.fatigue < 40:
				world.ask(["SLEEP UNTIL MORNING?"], ["YES", "NO"], func(answer: int) -> void:
					if answer == 0:
						world.sleep(true))
			else:
				world.say(["IT IS TOO EARLY TO SLEEP."])
			return
		"door":
			var is_open: bool = state.get("open", false)
			save().set_state(world.map_id, thing.cell, "open", not is_open)
			world.refresh_thing_look(thing)
			Sound.play("door")
			return
		"chest":
			world.set_mode(World.Mode.CHEST)
			world.chest_menu.open(save(), world.map_id, thing.cell)
			return
		"workbench":
			world.say(["A STURDY WORKBENCH.", "USE A HAMMER NEARBY TO BUILD."])
			return
		"crop", "planter":
			Farming.use_on_plot(world, "", thing.cell)
			return
		"kiln", "drying_rack":
			Cooking.collect(world, thing)
			return
		"raft":
			board_raft(thing)
			return
		"sailboat":
			Endings.board_sailboat(world)
			return
		"radio":
			Endings.examine_radio(world)
			return
		"beacon", "beacon_site":
			Endings.examine_beacon(world, thing)
			return
	if info.has("pickup"):
		var pickup: Dictionary = info["pickup"]
		var item_id: String = pickup["item"]
		if not inventory().has_room_for(item_id):
			world.toast("YOUR BAG IS FULL.")
			return
		show_got_item(item_id, pickup.get("count", 1))
		remove_thing_for_days(thing, pickup.get("regrow", 0))
		if not save().hints_seen.has("first_pickup"):
			save().hints_seen["first_pickup"] = true
			world.toast("START: OPEN BAG")
		return
	if info.has("harvest"):
		harvest(thing, info["harvest"])
		return
	Sound.play("blip")
	world.say(info.get("examine", ["NOTHING HAPPENS."]))


func is_harvest_ready(thing: WorldThing) -> bool:
	var harvest_info: Dictionary = ThingCatalog.thing(thing.kind).get("harvest", {})
	if harvest_info.is_empty():
		return false
	var seasons: Array = harvest_info.get("seasons", Palettes.SEASONS)
	if not seasons.has(save().clock.season()):
		return false
	var ready_day := int(save().state_at(world.map_id, thing.cell).get("harvest_day", 0))
	return save().clock.day() >= ready_day


func harvest(thing: WorldThing, harvest_info: Dictionary) -> void:
	thing.flash()
	Sound.play("rustle")
	if is_harvest_ready(thing):
		show_got_item(harvest_info["item"], harvest_info.get("count", 1))
		save().set_state(world.map_id, thing.cell, "harvest_day", save().clock.day() + int(harvest_info["every"]))
		world.refresh_thing_look(thing)
		return
	var fallback: String = harvest_info.get("otherwise", "")
	var fallback_day := int(save().state_at(world.map_id, thing.cell).get("fallback_day", 0))
	if fallback != "" and save().clock.day() >= fallback_day:
		save().set_state(world.map_id, thing.cell, "fallback_day", save().clock.day() + 1)
		show_got_item(fallback, 1)
		return
	world.toast(harvest_info.get("empty", "NOTHING THERE.") if fallback == "" else "NOTHING MORE TODAY.")


func open_crate(thing: WorldThing) -> void:
	var state := save().state_at(world.map_id, thing.cell)
	if state.get("opened", false):
		world.say(["AN EMPTY CRATE."])
		return
	save().set_state(world.map_id, thing.cell, "opened", true)
	thing.show_sprite("crate_open")
	Sound.play("open")
	var contents: Array = WorldMaps.map_data(world.map_id)["crates"].get(thing.cell, ["stick"])
	for item_id in contents:
		world.give_item(item_id)
	var first: String = contents[0]
	var names := []
	for item_id in contents:
		names.append(ItemCatalog.display_name(item_id))
	show_new_find(first, ["THE CRATE CREAKS OPEN.", "YOU FOUND: %s!" % ", ".join(names)])


func pick_up_dropped(thing: WorldThing) -> void:
	var items: Array = save().state_at(world.map_id, thing.cell).get("items", [])
	var left_behind := []
	for entry in items:
		var leftover := inventory().add(entry["id"], int(entry["count"]))
		if leftover < int(entry["count"]):
			world.toast("+%d %s" % [int(entry["count"]) - leftover, ItemCatalog.display_name(entry["id"])])
		if leftover > 0:
			left_behind.append({"id": entry["id"], "count": leftover})
	Sound.play("pickup")
	world.remove_thing_node(thing.cell)
	save().set_state(world.map_id, thing.cell, "items", null if left_behind.is_empty() else left_behind)
	if not left_behind.is_empty():
		world.add_dropped_thing(thing.cell)
		world.toast("YOUR BAG IS FULL.")


func board_raft(thing: WorldThing) -> void:
	save().set_flag("on_raft")
	save().set_state(world.map_id, thing.cell, "piece", null)
	world.remove_thing_node(thing.cell)
	world.player.place_at(Vector2(thing.cell.x * 16 + 8, thing.cell.y * 16 + 14))
	Sound.play("splash")
	world.toast("ALL ABOARD! PADDLE TO A SHORE.")


# --- Open ground -------------------------------------------------------------------

func use_on_ground(item_id: String, cell: Vector2i) -> bool:
	var ground_name := world.ground_name_at(cell)
	var tool := ItemCatalog.tool_kind(item_id)
	var is_water := World.WATER_GROUND.has(ground_name)
	if is_water and tool == "cup":
		inventory().remove("coconut_cup")
		var filled := "cup_water" if ground_name == "river" else "cup_seawater"
		world.give_item(filled)
		world.toast("YOU FILL THE CUP: %s" % ItemCatalog.display_name(filled))
		Sound.play("splash")
		return true
	if is_water and item_id == "" and ground_name == "river":
		save().meters.apply({"water": 10})
		world.toast("YOU CUP YOUR HANDS AND DRINK. +10")
		Sound.play("drink")
		return true
	if is_water and tool == "rod":
		world.start_fishing(cell)
		return true
	if Farming.use_on_ground(world, item_id, cell):
		return true
	if tool == "hammer":
		world.builder.open_for(cell)
		return true
	var place: String = ItemCatalog.item(item_id).get("place", "")
	if place == "campfire":
		if world.is_cell_blocked(cell) or world.things_by_cell.has(cell):
			world.toast("NO ROOM THERE.")
			return true
		inventory().remove(item_id)
		save().set_state(world.map_id, cell, "piece", "campfire")
		save().set_state(world.map_id, cell, "burns_until", save().clock.total_minutes + 120)
		world.add_thing("campfire", cell)
		world.refresh_thing_look(world.things_by_cell[cell])
		Sound.play("fire")
		world.say(["THE FIRE CATCHES!", "FEED IT WOOD TO KEEP IT GOING.", "USE RAW FOOD ON IT TO COOK."])
		return true
	return false


# --- An item on its own -----------------------------------------------------------

func use_alone(item_id: String) -> void:
	var info := ItemCatalog.item(item_id)
	if item_id == "mushroom" or item_id == "herb":
		eat_wild_plant(item_id)
		return
	if info.has("eat"):
		eat(item_id)
		return
	if info.has("bag_slots"):
		if inventory().grow_to(info["bag_slots"]):
			inventory().remove(item_id)
			Sound.play("fanfare")
			world.say(["YOUR BAG NOW HOLDS %d THINGS!" % info["bag_slots"]])
		else:
			world.say(["YOUR BAG IS ALREADY BIG ENOUGH."])
		return
	if item_id == "bottle_note":
		world.say(WorldMaps.NOTE_LINES)
		return
	if info.has("place"):
		if not use_on_ground(item_id, world.player.cell_in_front()):
			world.toast("FACE OPEN GROUND TO PLACE IT.")
		return
	if ItemCatalog.tool_kind(item_id) == "hammer":
		world.builder.open_for(world.player.cell_in_front())
		return
	if info.get("damage", 1) > 1 or info.has("tool"):
		world.player.swing(item_id)
		Sound.play("swing")
		return
	world.toast("NOTHING HAPPENS.")


func eat(item_id: String) -> void:
	var info := ItemCatalog.item(item_id)
	var effects: Dictionary = info["eat"]
	inventory().remove(item_id)
	save().meters.apply(effects)
	if info.has("leaves"):
		world.give_item(info["leaves"])
	Sound.play("drink" if effects.has("water") and effects["water"] > effects.get("hunger", 0) else "eat")
	world.toast(effects_text(ItemCatalog.display_name(item_id), effects))


func eat_wild_plant(item_id: String) -> void:
	var effect := save().raw_plant_effect(item_id)
	inventory().remove(item_id)
	save().meters.apply(effect["effects"])
	Sound.play("eat")
	var learned_key := "learned_%s" % item_id
	save().hints_seen[learned_key] = true
	world.say(["YOU EAT THE %s RAW." % ItemCatalog.display_name(item_id), effect["line"]])


func effects_text(food_name: String, effects: Dictionary) -> String:
	var parts := []
	for key in ["hunger", "water", "health", "fatigue"]:
		if effects.has(key):
			var amount: int = effects[key]
			parts.append("%s%s%d" % [key.left(1).to_upper(), "+" if amount >= 0 else "", amount])
	return "%s: %s" % [food_name, " ".join(parts)]
