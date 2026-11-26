class_name Endings
extends RefCounted

## The four ways the story ends: light the beacon, fix the radio, sail away,
## or choose to stay. Each one is recorded in the endings gallery.

const ENDING_SCENE := "res://scenes/ending/ending.tscn"
const STAY_EARLIEST_DAY := 29
const STAY_COMFORT_NEEDED := 6
const ENDING_IDS := ["signal", "radio", "sail", "stay"]

static var pending_ending := ""


static func examine_beacon(world: World, thing: WorldThing) -> void:
	if thing.kind == "beacon_site":
		world.say(ThingCatalog.thing("beacon_site")["examine"] + ["BUILD A BEACON HERE: USE A", "HAMMER. (6 WOOD, 2 HARDWOOD,", "2 RESIN)"])
		return
	world.say(["THE BEACON IS STACKED HIGH.", "LIGHT IT WITH A TORCH, ON A", "CLEAR NIGHT WHEN SHIPS PASS."])


static func use_on_beacon(world: World, item_id: String) -> bool:
	if ItemCatalog.tool_kind(item_id) != "light":
		return false
	var clock := world.save.clock
	if not clock.is_night():
		world.say(["IN THIS LIGHT NO SHIP WOULD", "SEE IT. WAIT FOR NIGHTFALL."])
		return true
	if clock.is_raining():
		world.say(["THE RAIN SOAKS THE WOOD.", "TRY ANOTHER NIGHT."])
		return true
	world.save.set_flag("beacon_lit")
	world.refresh_thing_looks()
	Sound.play("fire")
	world.say(["WHOOMPH! THE BEACON ROARS.", "...", "FAR OUT AT SEA, A SHIP'S HORN", "ANSWERS. THEY HAVE SEEN YOU!"], func() -> void: finish(world, "signal"))
	return true


static func examine_radio(world: World) -> void:
	var save := world.save
	if save.flag("radio_fixed"):
		world.say(["THE RADIO HUMS."])
		return
	var wires := int(save.flags.get("radio_wires", 0))
	var lines := ["AN OLD RADIO SET. A NOTE SAYS:", "'NEEDS 2 WIRE AND A BATTERY. - W.'"]
	lines.append("WIRE FITTED: %d/2. BATTERY: %s." % [wires, "YES" if save.flag("radio_battery") else "NO"])
	world.say(lines)


static func use_on_radio(world: World, item_id: String) -> bool:
	var save := world.save
	if save.flag("radio_fixed"):
		return false
	if item_id == "wire" and int(save.flags.get("radio_wires", 0)) < 2:
		save.inventory.remove("wire")
		save.flags["radio_wires"] = int(save.flags.get("radio_wires", 0)) + 1
		Sound.play("build")
		world.toast("WIRE FITTED. (%d/2)" % save.flags["radio_wires"])
	elif item_id == "battery" and not save.flag("radio_battery"):
		save.inventory.remove("battery")
		save.set_flag("radio_battery")
		Sound.play("build")
		world.toast("BATTERY FITTED.")
	else:
		return false
	if int(save.flags.get("radio_wires", 0)) >= 2 and save.flag("radio_battery"):
		save.set_flag("radio_fixed")
		world.refresh_thing_looks()
		world.say(["THE DIAL GLOWS... STATIC...", "'...COASTGUARD... WE READ YOU...'", "'...HOLD ON. WE ARE COMING.'"], func() -> void: finish(world, "radio"))
	return true


static func board_sailboat(world: World) -> void:
	world.ask(["THE SAILBOAT IS READY.", "SAIL AWAY FOR GOOD?"], ["SAIL", "NOT YET"], func(answer: int) -> void:
		if answer == 0:
			finish(world, "sail"))


## Offered after a good night's sleep at a comfy home late in the game.
static func check_stay_offer(world: World) -> void:
	var save := world.save
	if save.clock.day() < STAY_EARLIEST_DAY or save.home.is_empty():
		return
	if int(save.flags.get("stay_asked_day", 0)) == save.clock.day():
		return
	if Building.comfort_around(world, world.player.cell()) < STAY_COMFORT_NEEDED:
		return
	save.flags["stay_asked_day"] = save.clock.day()
	world.ask(["A WHOLE YEAR ON THE ISLAND.", "THIS PLACE FEELS LIKE HOME NOW.", "STAY FOR GOOD?"], ["STAY", "NOT YET"], func(answer: int) -> void:
		if answer == 0:
			finish(world, "stay"))


static func finish(world: World, ending_id: String) -> void:
	world.set_mode(World.Mode.CUTSCENE)
	world.save.set_flag("ending_%s" % ending_id)
	world.save.player_position = world.player.exact_position
	Game.record_ending(ending_id)
	Game.save_game()
	pending_ending = ending_id
	Sound.stop_music()
	ScreenFader.change_scene(ENDING_SCENE)
