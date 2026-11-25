class_name IslandLayout
extends RefCounted

## The look-book beach, one character per 16x16 metatile.
## A stopgap until maps are painted in the Godot editor.

const ROWS := [
	"PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP",
	"PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP",
	"##PPPPPPPPP..PPPPPPPPPPPPPPPPPPP",
	"##PPP.PPPP.,,.PPPP.PPPPP.PPPPPPP",
	"##P...P..P.,,..P....P...P..BPPPP",
	"##.ww.....,,......k........f.PPP",
	"#o.ww..o..,,..F.......ggggg...PP",
	"##..B....,,....@....gggggggg..PP",
	"##........,,..d......gggggg.ww.P",
	"...h........,,......c.....o..b..",
	"================================",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
]

## Character -> ground tile name. Objects stand on plain sand unless listed here.
const GROUND_FOR_CHARACTER := {
	".": "sand",
	",": "sand_path",
	"g": "grass",
	"w": "sand_sprout",
	"#": "cliff",
	"o": "boulder",
	"~": "water",
	"=": "shore",
	"P": "sand_shade",
}

## Character -> object sprite placed on that metatile.
const OBJECT_FOR_CHARACTER := {
	"P": "palm",
	"B": "bush",
	"f": "fruit",
	"k": "stick",
	"h": "shell",
	"b": "bottle",
	"d": "driftwood",
	"F": "campfire",
	"c": "crab",
}

const BLOCKING_GROUND := ["cliff", "boulder", "water", "shore"]
const BLOCKING_OBJECTS := ["palm", "bush", "campfire", "driftwood"]
const PLAYER_START_CHARACTER := "@"


static func width_in_metatiles() -> int:
	return ROWS[0].length()


static func height_in_metatiles() -> int:
	return ROWS.size()


static func character_at(column: int, row: int) -> String:
	return ROWS[row][column]


## Plain sand alternates between two variants so the beach does not look tiled.
static func ground_tile_at(column: int, row: int) -> String:
	var character := character_at(column, row)
	var ground_name: String = GROUND_FOR_CHARACTER.get(character, "sand")
	if ground_name == "sand":
		var variant_seed := (column * 7 + row * 13) % 5
		if variant_seed == 0:
			return "sand_b"
		return "sand_a"
	return ground_name


static func object_at(column: int, row: int) -> String:
	return OBJECT_FOR_CHARACTER.get(character_at(column, row), "")


static func player_start_metatile() -> Vector2i:
	for row in height_in_metatiles():
		var column: int = ROWS[row].find(PLAYER_START_CHARACTER)
		if column != -1:
			return Vector2i(column, row)
	return Vector2i(1, 1)
