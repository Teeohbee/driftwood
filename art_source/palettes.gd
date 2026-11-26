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
}

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
}


static func five_bit_to_color(channels: Array) -> Color:
	var red := float(channels[0]) / 31.0
	var green := float(channels[1]) / 31.0
	var blue := float(channels[2]) / 31.0
	return Color(red, green, blue, 1.0)


static func background_color(palette_name: String, index: int) -> Color:
	return five_bit_to_color(BACKGROUND_PALETTES[palette_name][index])


static func sprite_color(palette_name: String, index: int) -> Color:
	if index == 0:
		return Color(0, 0, 0, 0)
	return five_bit_to_color(SPRITE_PALETTES[palette_name][index])


static func background_colors(palette_name: String) -> Array[Color]:
	var colors: Array[Color] = []
	for index in 4:
		colors.append(background_color(palette_name, index))
	return colors


static func sprite_colors(palette_name: String) -> Array[Color]:
	var colors: Array[Color] = []
	for index in range(1, 4):
		colors.append(sprite_color(palette_name, index))
	return colors
