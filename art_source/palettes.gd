class_name Palettes
extends RefCounted

## Every colour in Driftwood lives here.
##
## Game Boy Color rules:
## - Colours are 15-bit: each channel is a whole number from 0 to 31.
## - A background tile uses one palette of 4 colours (index 0 lightest, 3 darkest).
## - A sprite uses one palette of 3 colours plus transparent (index 0 is unused).
##
## Palettes are written as [red, green, blue] in 0-31 so it is impossible to
## pick a colour the real hardware could not show.

const BACKGROUND_PALETTES := {
	"sand": [[31, 28, 20], [29, 22, 12], [19, 11, 5], [5, 4, 3]],
	"sand_sprout": [[29, 22, 12], [20, 28, 10], [10, 20, 6], [5, 4, 3]],
	"grass": [[24, 29, 14], [12, 23, 8], [4, 13, 5], [2, 5, 3]],
	"shore": [[29, 22, 12], [30, 31, 31], [9, 20, 29], [4, 10, 21]],
	"water": [[22, 29, 31], [9, 20, 29], [4, 10, 21], [2, 4, 10]],
	"cliff": [[29, 25, 18], [23, 16, 9], [14, 8, 4], [5, 4, 3]],
	"rock_on_sand": [[29, 22, 12], [26, 24, 21], [15, 13, 11], [5, 4, 3]],
	"sky": [[31, 30, 22], [31, 24, 14], [28, 15, 12], [13, 8, 15]],
	"interface": [[31, 31, 30], [22, 22, 20], [11, 11, 10], [3, 3, 3]],
	"pale_sand": [[31, 30, 26], [29, 28, 21], [22, 19, 13], [5, 4, 3]],
	"pale_shore": [[29, 28, 21], [30, 31, 31], [9, 20, 29], [4, 10, 21]],
	"dirt": [[12, 23, 8], [24, 19, 11], [17, 12, 6], [5, 4, 3]],
	"jungle": [[12, 23, 8], [6, 16, 6], [3, 9, 4], [1, 4, 2]],
	"river": [[24, 31, 29], [10, 24, 26], [5, 14, 20], [2, 6, 10]],
	"bridge": [[30, 24, 15], [20, 12, 6], [6, 4, 3], [5, 14, 20]],
	"ruins": [[27, 27, 24], [19, 19, 17], [11, 11, 12], [4, 4, 6]],
	"cave": [[17, 14, 12], [11, 8, 7], [6, 4, 4], [2, 1, 1]],
	"soil": [[22, 17, 9], [15, 10, 5], [9, 6, 3], [4, 3, 2]],
	"wood_floor": [[29, 22, 13], [23, 15, 8], [15, 9, 4], [6, 4, 3]],
}

## Seasons swap whole palettes, the way a GBC game would reload its palette RAM.
## Spring is the base palettes above. Anything not listed keeps its base colours.
const SEASON_BACKGROUND_OVERRIDES := {
	"summer": {
		"grass": [[28, 30, 12], [18, 25, 7], [8, 15, 4], [2, 5, 3]],
		"sand_sprout": [[29, 22, 12], [26, 28, 10], [14, 20, 5], [5, 4, 3]],
		"dirt": [[18, 25, 7], [24, 19, 11], [17, 12, 6], [5, 4, 3]],
	},
	"autumn": {
		"grass": [[29, 25, 12], [22, 19, 6], [13, 11, 4], [5, 4, 2]],
		"sand_sprout": [[29, 22, 12], [28, 20, 8], [18, 11, 4], [5, 4, 3]],
		"dirt": [[22, 19, 6], [24, 19, 11], [17, 12, 6], [5, 4, 3]],
		"jungle": [[22, 19, 6], [12, 14, 5], [6, 8, 3], [2, 3, 1]],
	},
	"winter": {
		"grass": [[26, 29, 25], [16, 22, 16], [8, 13, 9], [3, 5, 4]],
		"sand_sprout": [[29, 22, 12], [22, 26, 20], [12, 17, 12], [5, 4, 3]],
		"dirt": [[16, 22, 16], [22, 18, 13], [15, 11, 8], [5, 4, 3]],
		"jungle": [[16, 22, 16], [8, 15, 9], [4, 9, 6], [1, 4, 3]],
		"water": [[24, 28, 31], [12, 19, 27], [6, 11, 20], [3, 5, 11]],
	},
}

## Seasonal swaps for leafy sprites, applied with the palette-swap shader.
const SEASON_SPRITE_OVERRIDES := {
	"summer": {"foliage": [[], [26, 29, 8], [12, 21, 4], [3, 7, 2]]},
	"autumn": {"foliage": [[], [30, 22, 6], [24, 11, 4], [8, 4, 2]]},
	"winter": {"foliage": [[], [24, 28, 24], [11, 18, 14], [3, 6, 5]]},
}
const SEASONS := ["spring", "summer", "autumn", "winter"]

const SPRITE_PALETTES := {
	"hero": [[], [31, 25, 19], [8, 16, 29], [3, 3, 5]],
	"foliage": [[], [20, 27, 8], [8, 19, 6], [2, 7, 3]],
	"trunk": [[], [30, 24, 15], [20, 12, 6], [6, 4, 3]],
	"crab": [[], [31, 22, 15], [27, 8, 5], [8, 2, 2]],
	"fruit": [[], [31, 25, 22], [27, 6, 6], [8, 2, 2]],
	"fire": [[], [31, 30, 12], [31, 15, 4], [10, 3, 2]],
	"emote": [[], [31, 26, 26], [27, 7, 7], [8, 2, 2]],
	"shell": [[], [31, 30, 28], [29, 21, 22], [12, 6, 8]],
	"glass": [[], [30, 31, 31], [16, 26, 24], [4, 10, 12]],
	"logo": [[], [31, 29, 9], [30, 20, 2], [6, 4, 3]],
	"ink": [[], [31, 31, 31], [22, 22, 20], [3, 3, 3]],
	"stone": [[], [26, 24, 21], [15, 13, 11], [5, 4, 3]],
	"berry": [[], [25, 14, 28], [14, 5, 18], [5, 2, 8]],
	"fish": [[], [26, 28, 30], [11, 16, 22], [3, 5, 9]],
	"meat": [[], [31, 22, 20], [24, 9, 9], [9, 3, 3]],
	"cooked": [[], [29, 20, 9], [18, 9, 4], [6, 3, 2]],
	"boar": [[], [22, 16, 12], [13, 8, 6], [4, 3, 2]],
	"goat": [[], [31, 31, 29], [22, 20, 17], [6, 5, 5]],
	"hen": [[], [31, 30, 26], [30, 8, 6], [8, 5, 3]],
	"monkey": [[], [30, 23, 16], [18, 10, 5], [5, 3, 2]],
	"snake": [[], [26, 28, 8], [12, 20, 4], [3, 6, 2]],
	"bat": [[], [24, 18, 26], [12, 8, 14], [3, 2, 4]],
	"copper": [[], [31, 24, 16], [25, 13, 6], [9, 4, 2]],
	"cloth": [[], [31, 30, 26], [24, 22, 17], [8, 7, 6]],
	"straw": [[], [30, 28, 16], [22, 18, 8], [8, 6, 2]],
	"hermit": [[], [29, 22, 16], [24, 24, 22], [5, 4, 4]],
	"guardian": [[], [31, 24, 12], [24, 10, 4], [7, 3, 2]],
	"water_drop": [[], [26, 30, 31], [9, 20, 29], [3, 7, 15]],
	"shadow": [[], [12, 10, 9], [8, 6, 5], [4, 3, 2]],
	"earth": [[], [22, 17, 9], [15, 10, 5], [4, 3, 2]],
}


static func five_bit_to_color(channels: Array) -> Color:
	var red := float(channels[0]) / 31.0
	var green := float(channels[1]) / 31.0
	var blue := float(channels[2]) / 31.0
	return Color(red, green, blue, 1.0)


static func background_color(palette_name: String, index: int, season := "spring") -> Color:
	return five_bit_to_color(background_palette(palette_name, season)[index])


static func background_palette(palette_name: String, season := "spring") -> Array:
	var overrides: Dictionary = SEASON_BACKGROUND_OVERRIDES.get(season, {})
	return overrides.get(palette_name, BACKGROUND_PALETTES[palette_name])


## Every background palette a baked image may use, seasonal ones included.
static func all_background_palettes() -> Dictionary:
	var palettes := BACKGROUND_PALETTES.duplicate()
	for season in SEASON_BACKGROUND_OVERRIDES:
		for palette_name in SEASON_BACKGROUND_OVERRIDES[season]:
			palettes["%s_%s" % [palette_name, season]] = SEASON_BACKGROUND_OVERRIDES[season][palette_name]
	return palettes


static func sprite_color(palette_name: String, index: int) -> Color:
	if index == 0:
		return Color(0, 0, 0, 0)
	return five_bit_to_color(SPRITE_PALETTES[palette_name][index])


static func background_colors(palette_name: String, season := "spring") -> Array[Color]:
	var colors: Array[Color] = []
	for index in 4:
		colors.append(background_color(palette_name, index, season))
	return colors


static func sprite_colors(palette_name: String) -> Array[Color]:
	var colors: Array[Color] = []
	for index in range(1, 4):
		colors.append(sprite_color(palette_name, index))
	return colors
