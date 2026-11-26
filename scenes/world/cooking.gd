class_name Cooking
extends RefCounted

## Fires, the kiln and the drying rack.
## A fire stores the minute it burns out ("burns_until"), so it keeps burning
## down while you are away.

const KILN_MINUTES := 120
const DRYING_DAYS := 1


static func use_on_fire(world: World, item_id: String, fire: WorldThing) -> bool:
	var save := world.save
	var fuel := ItemCatalog.fuel_minutes(item_id)
	var cooked := ItemCatalog.cooks_into(item_id)
	if cooked != "" and world.is_fire_lit(fire.cell):
		save.inventory.remove(item_id)
		world.give_item(cooked)
		if item_id == "cup_seawater":
			world.toast("YOU BOIL IT CLEAN.")
		else:
			world.toast("SIZZLE! %s" % ItemCatalog.display_name(cooked))
		Sound.play("sizzle")
		if not save.known_recipes.has("cook:" + item_id):
			save.known_recipes.append("cook:" + item_id)
		return true
	if fuel > 0 and not ItemCatalog.is_edible(item_id) and ItemCatalog.tool_kind(item_id) == "":
		save.inventory.remove(item_id)
		var burns_until := maxf(save.clock.total_minutes, float(save.state_at(world.map_id, fire.cell).get("burns_until", 0)))
		save.set_state(world.map_id, fire.cell, "burns_until", burns_until + fuel)
		world.refresh_thing_look(fire)
		Sound.play("fire")
		world.toast("THE FIRE BURNS ON. (%dH LEFT)" % ceili((burns_until + fuel - save.clock.total_minutes) / 60.0))
		return true
	if cooked != "":
		world.toast("LIGHT THE FIRE FIRST. ADD WOOD.")
		return true
	return false


static func rest_at_fire(world: World, fire: WorldThing) -> void:
	var save := world.save
	if not world.is_fire_lit(fire.cell):
		world.say(["THE FIRE HAS GONE OUT.", "FEED IT STICKS OR WOOD TO", "LIGHT IT AGAIN."])
		return
	var hours_left := ceili((float(save.state_at(world.map_id, fire.cell)["burns_until"]) - save.clock.total_minutes) / 60.0)
	if save.clock.can_sleep() or save.meters.fatigue < 40:
		world.ask(["THE FIRE CRACKLES. (%dH LEFT)" % hours_left, "SLEEP BY IT UNTIL MORNING?"], ["YES", "NO"], func(answer: int) -> void:
			if answer == 0:
				world.sleep(false))
		return
	world.say(["THE FIRE CRACKLES. (%dH LEFT)" % hours_left, "USE RAW FOOD OR WOOD ON IT."])


static func use_on_kiln(world: World, item_id: String, kiln: WorldThing) -> bool:
	var save := world.save
	var state := save.state_at(world.map_id, kiln.cell)
	if item_id == "copper_ore" or item_id == "clay":
		if state.has("smelting"):
			world.toast("THE KILN IS BUSY.")
			return true
		save.inventory.remove(item_id)
		save.set_state(world.map_id, kiln.cell, "smelting", {"item": "copper" if item_id == "copper_ore" else "coconut_cup", "ready": save.clock.total_minutes + KILN_MINUTES})
		Sound.play("fire")
		world.toast("INTO THE KILN. READY IN 2 HOURS.")
		return true
	return false


static func use_on_rack(world: World, item_id: String, rack: WorldThing) -> bool:
	var save := world.save
	if item_id != "raw_meat" and item_id != "raw_fish":
		return false
	if save.state_at(world.map_id, rack.cell).has("drying"):
		world.toast("THE RACK IS FULL.")
		return true
	save.inventory.remove(item_id)
	save.set_state(world.map_id, rack.cell, "drying", {"item": "dried_meat", "ready_day": save.clock.day() + DRYING_DAYS})
	world.toast("HUNG UP TO DRY UNTIL TOMORROW.")
	return true


static func collect(world: World, thing: WorldThing) -> void:
	var save := world.save
	var state := save.state_at(world.map_id, thing.cell)
	if thing.kind == "kiln":
		if not state.has("smelting"):
			world.say(["A CLAY KILN. USE COPPER ORE", "ON IT TO SMELT COPPER."])
			return
		var smelting: Dictionary = state["smelting"]
		if save.clock.total_minutes < float(smelting["ready"]):
			world.toast("STILL SMELTING...")
			return
		save.set_state(world.map_id, thing.cell, "smelting", null)
		world.interactions.show_got_item(smelting["item"], 1)
		return
	if not state.has("drying"):
		world.say(["A DRYING RACK. HANG RAW MEAT", "OR FISH ON IT. DRIED FOOD", "NEVER ROTS."])
		return
	var drying: Dictionary = state["drying"]
	if save.clock.day() < int(drying["ready_day"]):
		world.toast("NOT DRY YET. TOMORROW.")
		return
	save.set_state(world.map_id, thing.cell, "drying", null)
	world.interactions.show_got_item(drying["item"], 1)
