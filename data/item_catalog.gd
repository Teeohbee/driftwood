class_name ItemCatalog
extends RefCounted

## Every item in Driftwood. The id is also the sprite name.
##
## name:        shown in menus (keep it under 12 characters)
## about:       one line for the item menu (under 32 characters)
## eat:         {"hunger": n, "water": n, "health": n, "fatigue": n} when used
## leaves:      what using it leaves behind (an empty cup)
## tool:        "axe", "pick", "knife", "hammer", "hoe", "rod", "cup", "light"
## tier:        tool strength; tier 2 breaks what tier 1 cannot
## damage:      hit damage when swung at creatures (hands do 1)
## cooks_into:  what a fire turns it into
## fuel:        in-game minutes it keeps a fire burning
## rots_in:     days before it turns to rotten food
## uses:        how many uses before a tool breaks
## bag_slots:   using it grows the bag to this many slots
## place:       build piece it becomes when used on open ground

const ITEMS := {
	"stick": {"name": "STICK", "about": "MERGE IT WITH THINGS.", "fuel": 60, "damage": 2},
	"stone": {"name": "STONE", "about": "HEAVY AND ROUND.", "damage": 1},
	"flint": {"name": "FLINT", "about": "SPARKS WHEN STRUCK."},
	"sharp_stone": {"name": "SHARP STONE", "about": "CUTS VINES AND GRASS.", "tool": "knife", "tier": 1, "damage": 2, "uses": 40},
	"vine": {"name": "VINE", "about": "TOUGH AND BENDY."},
	"fibre": {"name": "FIBRE", "about": "DRY GRASS. TWIST IT.", "fuel": 20},
	"leaf": {"name": "BIG LEAF", "about": "WIDE AS YOUR ARM."},
	"coconut": {"name": "COCONUT", "about": "HARD SHELL. OPEN IT?", "rots_in": 8},
	"coconut_open": {"name": "OPEN COCONUT", "about": "MILK AND WHITE FLESH.", "eat": {"water": 20, "hunger": 10}, "leaves": "coconut_cup", "rots_in": 2},
	"coconut_cup": {"name": "SHELL CUP", "about": "FILL IT AT FRESH WATER.", "tool": "cup"},
	"cup_water": {"name": "FRESH WATER", "about": "CLEAN AND COLD.", "eat": {"water": 35}, "leaves": "coconut_cup"},
	"cup_seawater": {"name": "SEA WATER", "about": "SALTY. BOIL IT FIRST.", "eat": {"water": 5, "health": -8}, "leaves": "coconut_cup", "cooks_into": "cup_water"},
	"fruit": {"name": "RED FRUIT", "about": "SWEET AND JUICY.", "eat": {"hunger": 12, "water": 6}, "rots_in": 3, "cooks_into": "roast_fruit"},
	"roast_fruit": {"name": "ROAST FRUIT", "about": "STICKY AND WARM.", "eat": {"hunger": 20, "fatigue": 4}, "rots_in": 2},
	"berries": {"name": "BERRIES", "about": "A HANDFUL.", "eat": {"hunger": 6, "water": 3}, "rots_in": 2},
	"mushroom": {"name": "MUSHROOM", "about": "WHO KNOWS?", "rots_in": 3, "cooks_into": "roast_mushroom"},
	"roast_mushroom": {"name": "ROAST SHROOM", "about": "SAFER COOKED.", "eat": {"hunger": 14}, "rots_in": 2},
	"herb": {"name": "HERB", "about": "SMELLS STRONG.", "rots_in": 4},
	"shell": {"name": "SHELL", "about": "IT HUMS IN THE WIND."},
	"pearl": {"name": "PEARL", "about": "THE HERMIT LOVES THESE."},
	"driftwood": {"name": "DRIFTWOOD", "about": "DRY. BURNS WELL.", "fuel": 120},
	"wood": {"name": "WOOD", "about": "FRESH CUT LOG.", "fuel": 150},
	"hardwood": {"name": "HARDWOOD", "about": "DARK AND STRONG.", "fuel": 240},
	"resin": {"name": "RESIN", "about": "STICKY. BURNS BRIGHT.", "fuel": 60},
	"rope": {"name": "ROPE", "about": "TWISTED VINES."},
	"string": {"name": "STRING", "about": "TWISTED FIBRE."},
	"stone_axe": {"name": "STONE AXE", "about": "CHOPS TREES.", "tool": "axe", "tier": 1, "damage": 4, "uses": 60},
	"stone_pick": {"name": "STONE PICK", "about": "BREAKS ROCKS.", "tool": "pick", "tier": 1, "damage": 3, "uses": 60},
	"claw_pick": {"name": "CLAW PICK", "about": "BREAKS ANYTHING.", "tool": "pick", "tier": 2, "damage": 5, "uses": 200},
	"copper_axe": {"name": "COPPER AXE", "about": "CHOPS FAST.", "tool": "axe", "tier": 2, "damage": 6, "uses": 200},
	"hammer": {"name": "HAMMER", "about": "USE IT TO BUILD.", "tool": "hammer", "damage": 2},
	"hoe": {"name": "HOE", "about": "TILLS GRASS FOR SEEDS.", "tool": "hoe", "tier": 1, "damage": 2, "uses": 80},
	"spear": {"name": "SPEAR", "about": "LONG AND POINTY.", "damage": 6, "uses": 80},
	"copper_spear": {"name": "COPPER SPEAR", "about": "BITES DEEP.", "damage": 10, "uses": 200},
	"torch": {"name": "TORCH", "about": "LIGHTS THE DARK.", "tool": "light", "damage": 2, "uses": 3},
	"fishing_rod": {"name": "FISHING ROD", "about": "USE IT ON WATER.", "tool": "rod", "uses": 40},
	"raw_fish": {"name": "RAW FISH", "about": "COOK IT.", "eat": {"hunger": 6, "health": -5}, "rots_in": 2, "cooks_into": "cooked_fish"},
	"cooked_fish": {"name": "COOKED FISH", "about": "FLAKY AND HOT.", "eat": {"hunger": 30, "health": 5}, "rots_in": 2},
	"raw_meat": {"name": "RAW MEAT", "about": "COOK IT.", "eat": {"hunger": 8, "health": -10}, "rots_in": 2, "cooks_into": "cooked_meat"},
	"cooked_meat": {"name": "COOKED MEAT", "about": "FILLING.", "eat": {"hunger": 40, "health": 8}, "rots_in": 3},
	"dried_meat": {"name": "DRIED MEAT", "about": "KEEPS FOREVER.", "eat": {"hunger": 30, "health": 4}},
	"rotten_food": {"name": "ROTTEN FOOD", "about": "PLANTS LIKE IT.", "eat": {"hunger": 3, "health": -12}},
	"campfire_kit": {"name": "CAMPFIRE", "about": "PLACE IT ON OPEN GROUND.", "place": "campfire"},
	"leaf_bag": {"name": "LEAF BAG", "about": "USE IT: BAG HOLDS 12.", "bag_slots": 12},
	"hide_bag": {"name": "HIDE BAG", "about": "USE IT: BAG HOLDS 16.", "bag_slots": 16},
	"hide": {"name": "HIDE", "about": "THICK BOAR SKIN."},
	"feather": {"name": "FEATHER", "about": "LIGHT AS AIR."},
	"egg": {"name": "EGG", "about": "COOK IT.", "eat": {"hunger": 5}, "rots_in": 4, "cooks_into": "cooked_egg"},
	"cooked_egg": {"name": "BOILED EGG", "about": "PERFECT.", "eat": {"hunger": 22, "health": 6}, "rots_in": 3},
	"milk": {"name": "GOAT MILK", "about": "CREAMY.", "eat": {"water": 25, "hunger": 10, "health": 4}, "rots_in": 2, "leaves": "coconut_cup"},
	"seeds": {"name": "WILD SEEDS", "about": "PLANT IN TILLED SOIL.", "place": "crop"},
	"yam": {"name": "YAM", "about": "ROAST IT.", "eat": {"hunger": 10}, "rots_in": 8, "cooks_into": "roast_yam"},
	"roast_yam": {"name": "ROAST YAM", "about": "SOFT AND SWEET.", "eat": {"hunger": 35, "fatigue": 6}, "rots_in": 4},
	"melon": {"name": "MELON", "about": "MOSTLY WATER.", "eat": {"water": 40, "hunger": 10}, "rots_in": 5},
	"squash": {"name": "SQUASH", "about": "ROAST IT.", "eat": {"hunger": 12}, "rots_in": 10, "cooks_into": "roast_squash"},
	"roast_squash": {"name": "ROAST SQUASH", "about": "AUTUMN IN A BITE.", "eat": {"hunger": 38, "health": 6}, "rots_in": 4},
	"beans": {"name": "BEANS", "about": "BOIL THEM.", "eat": {"hunger": 6}, "rots_in": 10, "cooks_into": "bean_stew"},
	"bean_stew": {"name": "BEAN STEW", "about": "WARMS YOU THROUGH.", "eat": {"hunger": 30, "water": 10, "fatigue": 10}, "rots_in": 3},
	"clay": {"name": "CLAY", "about": "FROM THE RIVERBANK."},
	"copper_ore": {"name": "COPPER ORE", "about": "SMELT IT IN A KILN."},
	"copper": {"name": "COPPER", "about": "SHINY METAL BAR."},
	"wire": {"name": "WIRE", "about": "THIN COPPER WIRE."},
	"claw": {"name": "GREAT CLAW", "about": "THE GUARDIAN'S CLAW."},
	"cloth": {"name": "CLOTH", "about": "WOVEN FIBRE. A SAIL?"},
	"battery": {"name": "BATTERY", "about": "SALTWATER AND COPPER."},
	"oil": {"name": "LAMP OIL", "about": "SQUEEZED FROM COCONUT.", "fuel": 300},
	"bottle_note": {"name": "OLD NOTE", "about": "READ IT WITH A."},
}

## What merging tools can be made into, for the recipe book's order.
const MAXIMUM_STACK := 9


static func has_item(item_id: String) -> bool:
	return ITEMS.has(item_id)


static func item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


static func display_name(item_id: String) -> String:
	return item(item_id).get("name", item_id.to_upper())


static func about(item_id: String) -> String:
	return item(item_id).get("about", "")


static func tool_kind(item_id: String) -> String:
	return item(item_id).get("tool", "")


static func tool_tier(item_id: String) -> int:
	return item(item_id).get("tier", 0)


static func damage(item_id: String) -> int:
	if item_id == "":
		return 1
	return item(item_id).get("damage", 1)


static func is_edible(item_id: String) -> bool:
	return item(item_id).has("eat")


static func is_stackable(item_id: String) -> bool:
	return not item(item_id).has("uses") and not item(item_id).has("tool")


static func rots_in_days(item_id: String) -> int:
	return item(item_id).get("rots_in", 0)


static func uses(item_id: String) -> int:
	return item(item_id).get("uses", 0)


static func fuel_minutes(item_id: String) -> int:
	return item(item_id).get("fuel", 0)


static func cooks_into(item_id: String) -> String:
	return item(item_id).get("cooks_into", "")


## Textures are kept here: menus draw them in _draw(), which holds no
## reference, so an uncached texture would be freed before it is rendered.
static var textures_by_item := {}


static func texture(item_id: String) -> Texture2D:
	if not textures_by_item.has(item_id):
		textures_by_item[item_id] = load("res://art/sprites/%s.png" % sprite_for(item_id))
	return textures_by_item[item_id]


## Roasted mushrooms reuse the roast fruit picture; everything else has its own.
static func sprite_for(item_id: String) -> String:
	const BORROWED_SPRITES := {"roast_mushroom": "roast_fruit", "dried_meat": "cooked_meat", "cooked_egg": "egg", "roast_yam": "yam", "roast_squash": "squash", "bean_stew": "beans", "bottle_note": "bottle_note"}
	return BORROWED_SPRITES.get(item_id, item_id)
