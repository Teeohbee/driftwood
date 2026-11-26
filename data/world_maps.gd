class_name WorldMaps
extends RefCounted

## The island, hand-placed, one character per 16x16 metatile.
## Painted with a scratch script, then tuned by hand; this file is the source.
##
## Ground characters set the tile. Object characters put a thing on the
## metatile and stand on the ground of the nearest ground character to their
## left (or the map's default ground).

const GROUND_FOR_CHARACTER := {
	"~": "water", "=": "shore", ".": "sand", ",": "sand_path", ":": "pale_sand",
	"g": "grass", ";": "dirt", "j": "jungle_floor", "J": "jungle_wall", "#": "cliff",
	"r": "river", "%": "bridge", "u": "ruins_floor", "U": "ruins_wall",
	"c": "cave_floor", "C": "cave_wall", "^": "cave_mouth", "E": "cave_floor",
}

const THING_FOR_CHARACTER := {
	"P": "palm", "T": "tree", "Y": "hardwood_tree", "B": "bush", "v": "vines",
	"w": "tall_grass", "o": "rock", "O": "boulder", "Q": "great_boulder", "R": "copper_rock",
	"k": "stick", "s": "stone", "h": "shell", "d": "driftwood", "f": "fruit",
	"M": "mushroom", "e": "herb", "n": "flint", "y": "clay", "X": "crate",
	"x": "bottle_note", "S": "sign", "Z": "radio", "L": "beacon_site", "W": "hermit_hut",
}

const CREATURE_FOR_CHARACTER := {
	"1": "crab", "2": "boar", "3": "snake", "4": "monkey", "5": "goat",
	"6": "hen", "7": "bat", "8": "guardian", "9": "hermit",
}

const START_CHARACTER := "@"

## Grounds an object never stands on, even if they are its nearest neighbour.
const UNDERFOOT_EXCLUDED := ["water", "shore", "river", "cliff", "jungle_wall", "cave_wall", "ruins_wall", "cave_mouth", "bridge"]

const MAPS := {
	"overworld": {
		"name": "THE ISLAND",
		"default_ground": "sand",
		"camera": "scroll",
		"is_dark": false,
		"music": "island",
		"rows": [
			"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
			"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
			"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#################~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
			"~~~~~JJJJJJJJJJJJJJJJJJJJJJg###################~~~#######~~~~~~~~~~~~~~~~~~~~~~~",
			"~~~~jJjJJjjjjjjjJJJjjjjJjJJg###################~#####g#####~~~~~~~~~~~~~:~~~~~~~",
			"~~~JjjjjJjjjJjJjjjjjjjjYjjJ#######################ggggggg###~~~~~~~~~~:::::~~~~~",
			"~~JJjjJjjJJjjjjjjJjYjjjjjjJg#####################ggggggggg###~~~~~~~~:::::::~~~~",
			"~~JJjjJJjjjjjJjJjjjjjJjjjjJg####################gggggLggggg##~~~~~~~:UUUUUUU:~~~",
			"~~JJjjjjjJjJjjjJJJYjjJjjJjJgg###################ggggggggggg###~~~~~::UuuuuuU::~~",
			"~~JJJJJjJJjjjJjjjjjjjJjjjjJggg#################ggggggggggggg##~~~~~::UuuuuuU::~~",
			"~~JJjjJjjjM3ejjjjjjjMjjJJjJggggg###########gg###ggggggggggg###~~~~~::UuuZuuU::~~",
			"~~JJjjjjjjjjjjjjjjjjjjJjJjJgggggggggg^ggggggg###ggggggggggg###~~~~~::UuuuuuU::~~",
			"~~JJjjJJjYjjJJjJjJejjjjJjjJgggggggrgS;ggggTgg####ggggggggg####~~~~:::UuXuuuU:::~",
			"~~JJjjjjjjJjjjjJjjjjjjJjjjJjTgggggrgg;gggggggg####ggggggg####~~~~~~::UuuuuuU::~~",
			"~~JJjjjjjjJjjjejjJjjjjjjJjJgggggggryg;gg5ggggg######,,#######~~~~~~::UuuuuuU::~~",
			"~~JJjJJjMjjjJj4jjjjjjjjjjjJgggggggrgo;ggggggggT#####,,######g~~~~~~::UUUuUUU::~~",
			"~~JJjjjjjjjjjjjYjjjjJJTJjjJggggggyrgg;fgwwgg2ggg####,,#####..~..~~~:::::::::::~~",
			"~~JjjjjjYjjJjjjjJjjjjjJjjjJggg5gggrgg;gggggggggggg##gg###g......~~~~::::h::P:~~~",
			"~~JjjjjjXjjjjjjjjjjSjjjjjjv;;;;;;;%;;;ggggggggggggggOOgggg......~~~~~:P:::::~~~~",
			"~~JjjjjjjeJJjjjjjjjjjjjJJJvjgg;gggrgggggggggBgggggggSggggg......~~~~~~:::::~~~~~",
			"~~JJJjjjjjjjjjj3MjjjjJJJJJJgggwwggrggggBgggggggggggg;ggggg......~~~~~~~~:~~~~~~~",
			"~~~JJJjjjjjjjjjjjjjjJjjJJJJggg;gggrgggggggoggggggggg;ggggg......~~~~~~~~~~~~~~~~",
			"~~JJjjjjjjjjJjJjJJjjTjjJJJJgTg;gggr;;;;;;;;;;;;;;;;;;ggggg......~~~~~~~~~~~~~~~~",
			"~~~JjjjjjjjjjJjjjjjjJjjJJJJggg;gggrggggggggggggggggggggggg......~~~~~~~~~~~~~~~~",
			"~~~JjjjjjjjjjjjjjjJjjjjJJJJggo;gggrggsgggggggwwggggggggggg..d...~~~~~~~~~~~~~~~~",
			"~~JJJJJJJJJJJJJJJJJJJJJJJJJggg;gggrgggggggTggggggggggggggg......~~~~~~~~~~~~~~~~",
			"~~~gggggggggrrrrrrrrrrrrrrrrrr%rrrrgggggggggggBggggggggggg......~~~~~~~~~~~~~~~~",
			"~~~gggggggggrgggTggggggg;;;;;6;gggggggggBggggggogggggggggg..S...~~~~~~~~~~~~~~~~",
			"~~~~gggggggyrggggg6ggggg;ggggSgBgggggggggggggsggTggggggggg...~..~~~~~~~~~~~~~~~~",
			"~~~~ggggggggrgggggggTggg;gggggsggggwwgTggggkgggggggggggggg...~..~~~~~~~~~~~~~~~~",
			"~~~~~gggggggrygggggggggg;gkggTgggggngggggggggggg2ggggggggg..~~..~~~~~~~~~~~~~~~~",
			"~~~~~~ggggggrggggTggggBg;ggwgggggTggggogggggTggggggggggggg.~~~..~~~~~~~~~~~~~~~~",
			"~~~~~~~gggggrggggggggogg;gggwwggggggBggggggggggggggggggggg~~~~..~~~~~~~~~~~~~~~~",
			"~~~~......P.ry....Pww...;.P.....k.P......ww.......P..........~..~~~~~~~~~~~~~~~~",
			"~~~~..P.....r.P.......P.;.....P.......P.......P.......P......~~~~~~~~~~:~~~~~~~~",
			"~~~~........r...........;....................................~~~~~~~:::::::~~~~~",
			"~~~~........r..d........;.k...........k...............s....d.~~~~~:::W:::::P:~~~",
			"~~~~........%...........;.S....k..........s.....k............~~~~~:::::9:::::~~~",
			"~~~....s....r...k.......@....s.....d....................d.....~~~:::::::::::::~~",
			"~~~~......n.r.......X......d................d........1.......~~~~~::P:::::h::~~~",
			"~~~~.....d..r.....d...........X.....n...x....1....d.......h..~~~~~::::::h::::~~~",
			"~~~...h.....r.........h.....1....h............h.....h.........~~~~~~:::::::~~~~~",
			"~~~=========r=================================================~~~~~~~~~:~~~~~~~~",
			"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
			"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
			"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
			"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
			"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
		],
		"doors": {
			Vector2i(37, 11): {"map": "cave", "arrive": Vector2i(23, 21), "facing": Vector2i.UP},
		},
		"signs": {
			Vector2i(26, 37): ["DRIFTWOOD BEACH.", "PRESS START TO OPEN YOUR BAG.", "PICK TWO THINGS AND MERGE.", "SOMETIMES SOMETHING HAPPENS. - W."],
			Vector2i(29, 28): ["HOME MEADOW.", "FLAT, DRY GROUND BY THE RIVER.", "A GOOD PLACE TO BUILD. - W."],
			Vector2i(36, 12): ["THE DARK CAVE.", "BRING A TORCH. - W."],
			Vector2i(52, 19): ["LOOKOUT HILL.", "SHIPS PASS ON CLEAR NIGHTS.", "A FIRE UP THERE WOULD SHOW. - W."],
			Vector2i(19, 18): ["THE DEEP JUNGLE.", "HARDWOOD AND RESIN.", "SNAKES. WATCH YOUR STEP. - W."],
			Vector2i(60, 27): ["THE EAST SHORE.", "TWO ISLETS ON THE HORIZON.", "A RAFT WOULD REACH THEM. - W."],
		},
		"crates": {
			Vector2i(20, 39): ["rope"],
			Vector2i(30, 40): ["coconut_cup"],
			Vector2i(8, 18): ["leaf_bag"],
			Vector2i(71, 12): ["wire"],
		},
	},
	"cave": {
		"name": "THE DARK CAVE",
		"default_ground": "cave_floor",
		"camera": "rooms",
		"is_dark": true,
		"music": "cave",
		"rows": [
			"CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC",
			"CccccccccccccccCCccccccccccccccCCccccccccccccccCCccccccccccccccC",
			"CccccccccccccccCCccccccccccccccCCccccccccccccccCCccccccccccccccC",
			"CcccccccXcccccccccccCccccccCcccCCcccccccccccccccccccCccccccccccC",
			"Cccccccccc7ccccccccccccccccccccCCccccccc8ccccccccccccccccccCcccC",
			"CccccccccccccccCCccccccccccccccCCccccccccccccccCCccccccccccccccC",
			"CccccccQQccccccCCccccccccccccccCCccccccccccccccCCccccccccccccccC",
			"CCCCCCCccCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCccCCCCCCCCCCCCCCccCCCCCCC",
			"CCCCCCCccCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCccCCCCCCCCCCCCCCccCCCCCCC",
			"CcccccRccccccccCCccccccccccccccCCccccccccccccccCCccccccccccccccC",
			"CcccCcccccccRccCCccccccccc7ccccCCccccccc7ccccccCCccccccccRcccccC",
			"CcccccccccccccccccccccccccccccccccccCccccccccccCCccccccccccccccC",
			"CccRccccccccccccccoccccccccccccccccccccccccCcccCCcccccc7ccccRccC",
			"CcccRcccMccCcccCCccccccccccccccCCcocccccccoccccCCccccRccccCccccC",
			"CccccccccccccccCCccccccccccccccCCccccccccccccccCCccccccccccccccC",
			"CCCCCCCCCCCCCCCCCCCCCCCccCCCCCCCCCCCCCCccCCCCCCCCCCCCCCccCCCCCCC",
			"CCCCCCCCCCCCCCCCCCCCCCCccCCCCCCCCCCCCCCccCCCCCCCCCCCCCCccCCCCCCC",
			"CcccccccccccyccCCccccccccccccccCCccccccccccccccCCccccccccccccXcC",
			"CcccyccccccccccCCccccccccccc7ccCCcccyccccccccccCCcccccCccccccccC",
			"CccccCcccccccccccccccccccccccccCCcccccCccccccccCCcccccccccccRccC",
			"CcccccccccCcccccccccScccccccccMCCcccccccccccMccCCcRccccccRcccccC",
			"CccccccccccccccCCccccccccccccccCCcccccccyccccccCCccccccccccccccC",
			"CccccccccccccccCCccccccccccccccCCccccccccccccccCCccccccccccccccC",
			"CCCCCCCCCCCCCCCCCCCCCCCEECCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC",
		],
		"doors": {
			Vector2i(23, 23): {"map": "overworld", "arrive": Vector2i(37, 12), "facing": Vector2i.DOWN},
			Vector2i(24, 23): {"map": "overworld", "arrive": Vector2i(37, 12), "facing": Vector2i.DOWN},
		},
		"signs": {
			Vector2i(20, 20): ["SOMETHING BIG LIVES IN HERE.", "IT GUARDS THE COPPER.", "IT HATES FIRE. - W."],
		},
		"crates": {
			Vector2i(8, 3): ["pearl", "pearl", "cloth"],
			Vector2i(61, 17): ["cloth", "oil"],
		},
	},
}

const NOTE_LINES := ["DAY 41. THE TIDE HIDES IT ALL.", "THE OLD CRAB GUARDS THE COPPER.", "LIGHT THE HILL, FIX THE RADIO,", "OR SAIL. OR STAY, LIKE ME. - W."]


static func map_data(map_id: String) -> Dictionary:
	return MAPS[map_id]


static func width_of(map_id: String) -> int:
	return MAPS[map_id]["rows"][0].length()


static func height_of(map_id: String) -> int:
	return MAPS[map_id]["rows"].size()


static func character_at(map_id: String, cell: Vector2i) -> String:
	if not is_inside(map_id, cell):
		return "~"
	return MAPS[map_id]["rows"][cell.y][cell.x]


static func is_inside(map_id: String, cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width_of(map_id) and cell.y < height_of(map_id)


## The ground tile name under any character. Object characters stand on the
## nearest walkable ground to their left, or else to their right.
static func ground_at(map_id: String, cell: Vector2i) -> String:
	var row: String = MAPS[map_id]["rows"][cell.y]
	if GROUND_FOR_CHARACTER.has(row[cell.x]):
		return GROUND_FOR_CHARACTER[row[cell.x]]
	for direction in [-1, 1]:
		var column: int = cell.x + direction
		while column >= 0 and column < row.length():
			var character := row[column]
			if GROUND_FOR_CHARACTER.has(character):
				var ground: String = GROUND_FOR_CHARACTER[character]
				if not UNDERFOOT_EXCLUDED.has(ground):
					return ground
				break
			column += direction
	return MAPS[map_id]["default_ground"]


## Plain sand and grass alternate variants so big areas do not look tiled.
static func ground_tile_at(map_id: String, cell: Vector2i) -> String:
	var ground := ground_at(map_id, cell)
	if ground == "sand":
		var thing: String = THING_FOR_CHARACTER.get(character_at(map_id, cell), "")
		if thing == "palm":
			return "sand_shade"
		return "sand_b" if (cell.x * 7 + cell.y * 13) % 5 == 0 else "sand_a"
	return ground


static func thing_at(map_id: String, cell: Vector2i) -> String:
	return THING_FOR_CHARACTER.get(character_at(map_id, cell), "")


static func creature_at(map_id: String, cell: Vector2i) -> String:
	return CREATURE_FOR_CHARACTER.get(character_at(map_id, cell), "")


static func start_cell(map_id: String) -> Vector2i:
	var rows: Array = MAPS[map_id]["rows"]
	for row_index in rows.size():
		var column: int = rows[row_index].find(START_CHARACTER)
		if column != -1:
			return Vector2i(column, row_index)
	return Vector2i(1, 1)
