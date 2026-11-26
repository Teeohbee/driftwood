class_name Merging
extends RefCounted

## Tries merging the items in the given bag slots. Consumes ingredients only
## on success (tools listed in "keeps" survive). Returns
## {"success", "message", "result", "leftover"}; the caller drops any leftover.

static func merge(save: SaveGame, slot_indices: Array) -> Dictionary:
	var inventory := save.inventory
	var ingredients := []
	for slot_index in slot_indices:
		var slot: Dictionary = inventory.slots[slot_index]
		if slot.is_empty():
			return {"success": false, "message": "NOTHING HAPPENS.", "result": ""}
		ingredients.append(slot["id"])
	if ingredients.size() < 2:
		return {"success": false, "message": "PICK AT LEAST TWO THINGS.", "result": ""}
	var recipe := RecipeBook.find(ingredients)
	if recipe.is_empty():
		return {"success": false, "message": "NOTHING HAPPENS.", "result": ""}
	var kept: Array = recipe.get("keeps", [])
	for ingredient in ingredients:
		if not kept.has(ingredient):
			inventory.remove(ingredient)
	var result_id: String = recipe["result"]
	var count: int = recipe.get("count", 1)
	var leftover := inventory.add(result_id, count)
	if recipe.has("leaves"):
		inventory.add(recipe["leaves"])
	var key := RecipeBook.recipe_key(recipe)
	var is_new := not save.known_recipes.has(key)
	if is_new:
		save.known_recipes.append(key)
	var message := "YOU MADE %s!" % ItemCatalog.display_name(result_id)
	if count > 1:
		message = "YOU MADE %d %s!" % [count, ItemCatalog.display_name(result_id)]
	if leftover > 0:
		message = "BAG FULL! IT IS AT YOUR FEET."
	elif is_new:
		message += " (NEW)"
	return {"success": true, "message": message, "result": result_id, "leftover": leftover}
