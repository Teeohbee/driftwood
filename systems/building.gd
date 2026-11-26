class_name Building
extends RefCounted

## The rules for placing pieces, kept apart from the build menu so they can
## be tested. Returns "" when the piece fits, else the reason it does not.

const COMFORT_RADIUS := 5


static func placement_problem(world: World, piece_id: String, cell: Vector2i) -> String:
	var piece := BuildCatalog.piece(piece_id)
	var save := world.save
	if not BuildCatalog.can_afford(save.inventory, piece_id):
		return "NOT ENOUGH MATERIALS."
	if piece["needs_workbench"] and not is_near_workbench(world, cell):
		return "BUILD A WORKBENCH NEARBY FIRST."
	if cell == world.player.cell():
		return "YOU ARE STANDING THERE."
	var ground_name := world.ground_name_at(cell)
	var thing: WorldThing = world.things_by_cell.get(cell, null)
	match piece["where"]:
		"water":
			if not World.WATER_GROUND.has(ground_name) or ground_name == "river":
				return "BUILD IT ON THE SEA."
			if thing != null:
				return "SOMETHING IS IN THE WAY."
			return ""
		"beacon_site":
			if thing == null or thing.kind != "beacon_site":
				return "IT NEEDS A HIGH, OPEN SPOT."
			return ""
	if world.is_cell_blocked_ground(cell):
		return "YOU CANNOT BUILD THERE."
	match piece["layer"]:
		"floor":
			if save.state_at(world.map_id, cell).has("floor"):
				return "THERE IS A FLOOR THERE."
		"roof":
			if save.state_at(world.map_id, cell).has("roof"):
				return "THERE IS A ROOF THERE."
		"thing":
			if thing != null:
				return "SOMETHING IS IN THE WAY."
	return ""


static func is_near_workbench(world: World, cell: Vector2i) -> bool:
	for thing_cell in world.things_by_cell:
		var thing: WorldThing = world.things_by_cell[thing_cell]
		if thing.kind == "workbench" and absi(thing_cell.x - cell.x) <= BuildCatalog.WORKBENCH_REACH and absi(thing_cell.y - cell.y) <= BuildCatalog.WORKBENCH_REACH:
			return true
	return false


static func place(world: World, piece_id: String, cell: Vector2i) -> void:
	var piece := BuildCatalog.piece(piece_id)
	var save := world.save
	var cost: Dictionary = piece["cost"]
	for item_id in cost:
		save.inventory.remove(item_id, cost[item_id])
	match piece["layer"]:
		"floor":
			save.set_state(world.map_id, cell, "floor", "wood_floor")
			world.refresh_floors()
		"roof":
			save.set_state(world.map_id, cell, "roof", true)
			world.refresh_roofs()
		"thing":
			save.set_state(world.map_id, cell, "piece", piece_id)
			if piece_id == "campfire":
				save.set_state(world.map_id, cell, "burns_until", save.clock.total_minutes + 120)
			world.add_thing(piece_id, cell)
			world.refresh_thing_look(world.things_by_cell[cell])


## Takes a built piece down and gives back half its cost (rounded up).
static func dismantle(world: World, cell: Vector2i) -> String:
	var save := world.save
	var state := save.state_at(world.map_id, cell)
	var piece_id := ""
	if state.has("roof"):
		piece_id = "roof"
		save.set_state(world.map_id, cell, "roof", null)
		world.refresh_roofs()
	elif state.has("piece") and BuildCatalog.PIECES.has(state["piece"]):
		piece_id = state["piece"]
		if piece_id == "chest" and not state.get("contents", []).is_empty():
			return ""
		save.set_state(world.map_id, cell, "piece", null)
		save.set_state(world.map_id, cell, "burns_until", null)
		world.remove_thing_node(cell)
	elif state.get("floor", "") == "wood_floor":
		piece_id = "floor"
		save.set_state(world.map_id, cell, "floor", null)
		world.refresh_floors()
	if piece_id == "":
		return ""
	var cost: Dictionary = BuildCatalog.piece(piece_id)["cost"]
	for item_id in cost:
		world.give_item(item_id, ceili(cost[item_id] / 2.0))
	return piece_id


## Comfort is one point for each different comfy piece near the bed, plus
## one for sleeping on a wooden floor.
static func comfort_around(world: World, cell: Vector2i) -> int:
	var kinds_found := {}
	for thing_cell in world.things_by_cell:
		var thing: WorldThing = world.things_by_cell[thing_cell]
		if ThingCatalog.comfort(thing.kind) <= 0:
			continue
		if absi(thing_cell.x - cell.x) <= COMFORT_RADIUS and absi(thing_cell.y - cell.y) <= COMFORT_RADIUS:
			kinds_found[thing.kind] = true
	var comfort := kinds_found.size()
	for offset in [Vector2i.ZERO, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
		if world.save.state_at(world.map_id, cell + offset).get("floor", "") == "wood_floor":
			comfort += 1
			break
	return comfort
