class_name ThingCatalog
extends RefCounted

## What every thing in the world is and does. A thing stands on one metatile.
##
## sprite:    sprite name (default: the thing's own name)
## blocks:    true if the castaway cannot walk through it
## examine:   lines shown when there is nothing better to do with it
## pickup:    {"item": id, "count": n, "regrow": days (0 = never)}
## harvest:   bare hands give "item" every "every" days; "overlay" shows when ready
## tool:      {"kind": "axe", "tier": 1, "hits": n, "gives": {id: n}, "regrow": days,
##             "bonus": {id: chance 0-100}, "keeps": true to leave the thing}
## second_tool: a second tool that works on it (a knife on a hardwood tree)
## light:     radius in pixels when lit (fires and lamps)
## comfort:   points towards home comfort
## frames:    animation frames (default 1)

const THINGS := {
	"palm": {"blocks": true, "examine": ["A TALL PALM.", "SHAKE IT? PRESS A."],
		"harvest": {"item": "coconut", "every": 3, "overlay": "palm_coconuts", "empty": "NO COCONUTS. COME BACK LATER."},
		"tool": {"kind": "axe", "tier": 1, "hits": 4, "gives": {"wood": 2, "leaf": 1}, "regrow": 0}},
	"tree": {"blocks": true, "examine": ["A LEAFY TREE."],
		"harvest": {"item": "fruit", "every": 2, "overlay": "tree_fruit", "seasons": ["spring", "summer", "autumn"], "empty": "YOU FIND A STICK.", "otherwise": "stick"},
		"tool": {"kind": "axe", "tier": 1, "hits": 3, "gives": {"wood": 2, "stick": 1}, "regrow": 0}},
	"hardwood_tree": {"blocks": true, "examine": ["A HUGE DARK TREE.", "AN AXE COULD FELL IT."],
		"tool": {"kind": "axe", "tier": 1, "hits": 5, "gives": {"hardwood": 2, "wood": 1}, "regrow": 0},
		"second_tool": {"kind": "knife", "tier": 1, "hits": 1, "gives": {"resin": 1}, "keeps": true, "every": 1}},
	"bush": {"blocks": true, "examine": ["A THICK BUSH."],
		"harvest": {"item": "berries", "count": 2, "every": 2, "overlay": "bush_berries", "seasons": ["spring", "summer", "autumn"], "empty": "YOU PULL OUT A VINE.", "otherwise": "vine"},
		"tool": {"kind": "knife", "tier": 1, "hits": 1, "gives": {"leaf": 1, "vine": 1}, "keeps": true, "every": 1}},
	"vines": {"blocks": true, "examine": ["A WALL OF THICK VINES.", "SOMETHING SHARP WOULD CUT THEM."],
		"tool": {"kind": "knife", "tier": 1, "hits": 2, "gives": {"vine": 2}, "regrow": 0}},
	"tall_grass": {"blocks": false, "frames": 2, "examine": ["TALL GRASS."],
		"pickup": {"item": "fibre", "count": 1, "regrow": 2},
		"tool": {"kind": "knife", "tier": 1, "hits": 1, "gives": {"fibre": 2}, "bonus": {"seeds": 20}, "regrow": 2}},
	"rock": {"blocks": true, "examine": ["A ROCK.", "A PICK WOULD BREAK IT UP."],
		"tool": {"kind": "pick", "tier": 1, "hits": 2, "gives": {"stone": 2}, "bonus": {"flint": 50}, "regrow": 5}},
	"boulder": {"blocks": true, "examine": ["A BIG BOULDER.", "A PICK MIGHT CRACK IT."],
		"tool": {"kind": "pick", "tier": 1, "hits": 5, "gives": {"stone": 3, "flint": 1}, "regrow": 0}},
	"great_boulder": {"blocks": true, "examine": ["A MASSIVE BOULDER.", "STONE TOOLS JUST BOUNCE OFF."],
		"tool": {"kind": "pick", "tier": 2, "hits": 4, "gives": {"stone": 3}, "regrow": 0}},
	"copper_rock": {"blocks": true, "examine": ["ROCK WITH GREEN-ORANGE VEINS.", "TOO HARD FOR STONE TOOLS."],
		"tool": {"kind": "pick", "tier": 2, "hits": 3, "gives": {"copper_ore": 2}, "regrow": 7}},
	"stick": {"pickup": {"item": "stick", "regrow": 2}},
	"stone": {"pickup": {"item": "stone", "regrow": 4}},
	"shell": {"pickup": {"item": "shell", "regrow": 2}},
	"driftwood": {"pickup": {"item": "driftwood", "regrow": 2}},
	"fruit": {"pickup": {"item": "fruit", "regrow": 0}},
	"mushroom": {"pickup": {"item": "mushroom", "regrow": 2}},
	"herb": {"pickup": {"item": "herb", "regrow": 3}},
	"flint": {"pickup": {"item": "flint", "regrow": 4}},
	"clay": {"sprite": "clay", "pickup": {"item": "clay", "regrow": 2}},
	"bottle_note": {"sprite": "bottle"},
	"crate": {"blocks": true},
	"sign": {"blocks": true},
	"radio": {"blocks": true},
	"beacon_site": {"sprite": "", "blocks": false, "examine": ["A FLAT ROCK WITH A VIEW OF", "THE WHOLE SEA. A GOOD SPOT FOR", "A BIG FIRE."]},
	"hermit_hut": {"blocks": true, "examine": ["A SMALL HUT. IT SMELLS OF FISH", "AND PIPE SMOKE."]},
	"fallen_bag": {"blocks": false},
	# Built pieces. Their costs live in BuildCatalog.
	"campfire": {"blocks": true, "frames": 2, "light": 56, "comfort": 1},
	"workbench": {"blocks": true, "comfort": 1},
	"wall": {"blocks": true},
	"door": {"blocks": true, "frames": 2},
	"bed": {"blocks": true, "comfort": 1},
	"chest": {"blocks": true, "comfort": 1},
	"drying_rack": {"blocks": true},
	"planter": {"blocks": false},
	"kiln": {"blocks": true, "light": 24},
	"rug": {"blocks": false, "comfort": 1},
	"table": {"blocks": true, "comfort": 1},
	"lamp": {"blocks": true, "frames": 2, "light": 48, "comfort": 1},
	"beacon": {"blocks": true},
	"beacon_lit": {"blocks": true, "frames": 2, "light": 96},
	"raft": {"blocks": false},
	"sailboat": {"blocks": true},
	"crop": {"sprite": "crop_sprout", "blocks": false},
	"dropped": {"sprite": "fallen_bag", "blocks": false},
}


static func thing(kind: String) -> Dictionary:
	return THINGS.get(kind, {})


static func sprite_for(kind: String) -> String:
	return thing(kind).get("sprite", kind)


static func blocks(kind: String) -> bool:
	return thing(kind).get("blocks", false)


static func frame_count(kind: String) -> int:
	return thing(kind).get("frames", 1)


static func light_radius(kind: String) -> int:
	return thing(kind).get("light", 0)


static func comfort(kind: String) -> int:
	return thing(kind).get("comfort", 0)


## Tool actions this thing accepts, in order.
static func tool_actions(kind: String) -> Array:
	var actions := []
	for key in ["tool", "second_tool"]:
		if thing(kind).has(key):
			actions.append(thing(kind)[key])
	return actions
