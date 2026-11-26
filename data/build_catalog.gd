class_name BuildCatalog
extends RefCounted

## Everything the hammer can build, Valheim style: most pieces need a
## workbench within reach. "layer" is where it goes: a thing on the metatile,
## a floor under it, or a roof over it. "where" limits the ground.

const WORKBENCH_REACH := 6

const PIECES := {
	"workbench": {"name": "WORKBENCH", "cost": {"wood": 3, "stone": 2}, "layer": "thing", "where": "land", "needs_workbench": false},
	"floor": {"name": "WOOD FLOOR", "cost": {"wood": 1}, "layer": "floor", "where": "land", "needs_workbench": true},
	"wall": {"name": "WALL", "cost": {"wood": 2}, "layer": "thing", "where": "land", "needs_workbench": true},
	"door": {"name": "DOOR", "cost": {"wood": 2, "rope": 1}, "layer": "thing", "where": "land", "needs_workbench": true},
	"roof": {"name": "THATCH ROOF", "cost": {"leaf": 1, "stick": 2}, "layer": "roof", "where": "land", "needs_workbench": true},
	"bed": {"name": "BED", "cost": {"wood": 3, "leaf": 2, "fibre": 3}, "layer": "thing", "where": "land", "needs_workbench": true},
	"chest": {"name": "CHEST", "cost": {"wood": 4, "rope": 1}, "layer": "thing", "where": "land", "needs_workbench": true},
	"table": {"name": "TABLE", "cost": {"wood": 3}, "layer": "thing", "where": "land", "needs_workbench": true},
	"rug": {"name": "RUG", "cost": {"fibre": 4, "berries": 1}, "layer": "thing", "where": "land", "needs_workbench": true},
	"lamp": {"name": "LAMP", "cost": {"stick": 2, "resin": 1}, "layer": "thing", "where": "land", "needs_workbench": true},
	"drying_rack": {"name": "DRYING RACK", "cost": {"stick": 4, "string": 1}, "layer": "thing", "where": "land", "needs_workbench": true},
	"planter": {"name": "PLANTER", "cost": {"wood": 2, "clay": 1}, "layer": "thing", "where": "land", "needs_workbench": true},
	"kiln": {"name": "KILN", "cost": {"clay": 4, "stone": 4}, "layer": "thing", "where": "land", "needs_workbench": true},
	"campfire": {"name": "CAMPFIRE", "cost": {"stick": 2, "stone": 2}, "layer": "thing", "where": "land", "needs_workbench": false},
	"raft": {"name": "RAFT", "cost": {"driftwood": 4, "rope": 2}, "layer": "thing", "where": "water", "needs_workbench": false},
	"beacon": {"name": "SIGNAL BEACON", "cost": {"wood": 6, "hardwood": 2, "resin": 2}, "layer": "thing", "where": "beacon_site", "needs_workbench": false},
	"sailboat": {"name": "SAILBOAT", "cost": {"hardwood": 6, "rope": 4, "cloth": 2, "copper": 2}, "layer": "thing", "where": "water", "needs_workbench": false},
}

const ORDER := ["workbench", "campfire", "floor", "wall", "door", "roof", "bed", "chest", "table", "rug", "lamp", "drying_rack", "planter", "kiln", "raft", "beacon", "sailboat"]


static func piece(piece_id: String) -> Dictionary:
	return PIECES[piece_id]


static func can_afford(inventory: Inventory, piece_id: String) -> bool:
	var cost: Dictionary = PIECES[piece_id]["cost"]
	for item_id in cost:
		if not inventory.has(item_id, cost[item_id]):
			return false
	return true
