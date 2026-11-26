class_name RecipeBook
extends RefCounted

## Merging, Survival Kids style: pick two or three items and see what happens.
## Order does not matter. "keeps" lists ingredients that are tools and survive.

const RECIPES := [
	{"ingredients": ["stone", "stone"], "result": "sharp_stone"},
	{"ingredients": ["vine", "vine"], "result": "rope"},
	{"ingredients": ["fibre", "fibre"], "result": "string"},
	{"ingredients": ["coconut", "sharp_stone"], "result": "coconut_open", "keeps": ["sharp_stone"]},
	{"ingredients": ["coconut", "stone"], "result": "coconut_open", "keeps": ["stone"]},
	{"ingredients": ["stick", "sharp_stone", "vine"], "result": "stone_axe"},
	{"ingredients": ["stick", "flint", "vine"], "result": "stone_pick"},
	{"ingredients": ["stick", "sharp_stone"], "result": "spear"},
	{"ingredients": ["stick", "resin"], "result": "torch"},
	{"ingredients": ["stick", "string", "shell"], "result": "fishing_rod"},
	{"ingredients": ["stick", "stone", "rope"], "result": "hammer"},
	{"ingredients": ["stick", "shell", "vine"], "result": "hoe"},
	{"ingredients": ["driftwood", "stick", "flint"], "result": "campfire_kit", "keeps": ["flint"]},
	{"ingredients": ["wood", "stick", "flint"], "result": "campfire_kit", "keeps": ["flint"]},
	{"ingredients": ["leaf", "string"], "result": "leaf_bag"},
	{"ingredients": ["hide", "rope"], "result": "hide_bag"},
	{"ingredients": ["fruit", "sharp_stone"], "result": "seeds", "count": 2, "keeps": ["sharp_stone"]},
	{"ingredients": ["melon", "sharp_stone"], "result": "seeds", "count": 3, "keeps": ["sharp_stone"]},
	{"ingredients": ["berries", "stone"], "result": "seeds", "keeps": ["stone"]},
	{"ingredients": ["string", "string", "string"], "result": "cloth"},
	{"ingredients": ["coconut", "coconut", "stone"], "result": "oil", "keeps": ["stone"]},
	{"ingredients": ["hardwood", "claw", "rope"], "result": "claw_pick"},
	{"ingredients": ["hardwood", "copper", "rope"], "result": "copper_axe"},
	{"ingredients": ["hardwood", "copper"], "result": "copper_spear"},
	{"ingredients": ["copper", "copper"], "result": "wire", "count": 2},
	{"ingredients": ["copper", "cup_seawater"], "result": "battery", "leaves": "coconut_cup"},
]


static func key_for(ingredients: Array) -> String:
	var sorted_ingredients := ingredients.duplicate()
	sorted_ingredients.sort()
	return "+".join(sorted_ingredients)


## Returns the recipe for these ingredients, or {} if nothing happens.
static func find(ingredients: Array) -> Dictionary:
	var wanted := key_for(ingredients)
	for recipe in RECIPES:
		if key_for(recipe["ingredients"]) == wanted:
			return recipe
	return {}


static func recipe_key(recipe: Dictionary) -> String:
	return key_for(recipe["ingredients"])
