class_name Hermit
extends RefCounted

## Wren, who washed up forty years ago and wrote every sign on the island.
## Trades pearls for help, and always has a hint.

const PEARL_REWARDS := [["seeds", 5], ["hide_bag", 1], ["battery", 1], ["oil", 2]]


static func talk(world: World, item_id: String) -> void:
	var save := world.save
	if not save.flag("met_wren"):
		save.set_flag("met_wren")
		world.say(["OH! A VISITOR! FORTY YEARS AND", "NOT ONE. I'M WREN.", "I WROTE THOSE SIGNS. AND THE", "NOTE IN THE BOTTLE, LONG AGO.", "BRING ME PEARLS. THE SEA HIDES", "THEM. I'LL MAKE IT WORTH IT."])
		return
	if item_id == "pearl":
		trade_pearl(world)
		return
	world.say(hint_for(save))


static func trade_pearl(world: World) -> void:
	var save := world.save
	var trades := int(save.flags.get("wren_trades", 0))
	save.inventory.remove("pearl")
	var reward: Array = PEARL_REWARDS[mini(trades, PEARL_REWARDS.size() - 1)]
	save.flags["wren_trades"] = trades + 1
	world.give_item(reward[0], reward[1])
	world.interactions.show_new_find(reward[0], ["A PEARL! LOVELY. HERE,", "TAKE THIS: %s." % ItemCatalog.display_name(reward[0])])


static func hint_for(save: SaveGame) -> Array:
	if not save.flag("guardian_defeated"):
		return ["THE OLD CRAB IN THE CAVE?", "ITS SHELL IS IRON. LET IT CHARGE", "INTO A WALL, THEN STRIKE!", "A SPEAR HITS HARDEST."]
	if not save.flag("radio_fixed"):
		return ["THE RUINS HAVE A RADIO. I NEVER", "HAD THE COPPER TO FIX IT.", "SMELT ORE IN A KILN, MERGE", "COPPER WITH COPPER FOR WIRE."]
	return ["SHIPS, RADIOS, BOATS...", "ME? I'M STAYING. THE ISLAND", "GROWS ON YOU. LIKE MOSS."]
