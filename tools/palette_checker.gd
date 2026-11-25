class_name PaletteChecker
extends RefCounted

## Enforces the Game Boy Color rules on every PNG under art/.
##
## art/backgrounds/: every 8x8 cell is opaque and uses at most 4 colours,
##                   all from one background palette.
## art/sprites/:     every 8x8 cell uses at most 3 opaque colours,
##                   all from one sprite palette.
## Everywhere:       every colour is 15-bit (whole 0-31 per channel).

const BACKGROUNDS_FOLDER := "res://art/backgrounds"
const SPRITES_FOLDER := "res://art/sprites"
const CELL_SIZE := 8


## Returns a list of human-readable problems. Empty means everything passes.
static func check_all_art() -> Array[String]:
	var problems: Array[String] = []
	for path in png_paths_in(BACKGROUNDS_FOLDER):
		problems.append_array(check_image(path, image_at(path), "background"))
	for path in png_paths_in(SPRITES_FOLDER):
		problems.append_array(check_image(path, image_at(path), "sprite"))
	return problems


## Imported PNGs load as textures; freshly baked ones have not been imported yet.
static func image_at(path: String) -> Image:
	if ResourceLoader.exists(path):
		var texture: Texture2D = load(path)
		return texture.get_image()
	return Image.load_from_file(path)


static func check_image(label: String, image: Image, kind: String) -> Array[String]:
	var problems: Array[String] = []
	var palettes := palettes_as_color_sets(kind)
	for cell_y in range(0, image.get_height(), CELL_SIZE):
		for cell_x in range(0, image.get_width(), CELL_SIZE):
			var problem := check_cell(image, Vector2i(cell_x, cell_y), kind, palettes)
			if problem != "":
				problems.append("%s cell (%d, %d): %s" % [label, cell_x, cell_y, problem])
	return problems


static func check_cell(image: Image, cell_origin: Vector2i, kind: String, palettes: Dictionary) -> String:
	var colors_in_cell := {}
	for y in range(cell_origin.y, mini(cell_origin.y + CELL_SIZE, image.get_height())):
		for x in range(cell_origin.x, mini(cell_origin.x + CELL_SIZE, image.get_width())):
			var color := image.get_pixel(x, y)
			if color.a < 1.0:
				if kind == "background":
					return "background pixels must be opaque"
				continue
			if not is_fifteen_bit(color):
				return "colour #%s is not a 15-bit colour" % color.to_html(false)
			colors_in_cell[five_bit_key(color)] = true

	var colour_limit := 4 if kind == "background" else 3
	if colors_in_cell.size() > colour_limit:
		return "uses %d colours, limit is %d" % [colors_in_cell.size(), colour_limit]
	if colors_in_cell.is_empty():
		return ""
	for palette_name in palettes:
		var palette_colors: Dictionary = palettes[palette_name]
		if palette_contains_all(palette_colors, colors_in_cell):
			return ""
	return "colours %s do not all come from one %s palette" % [colors_in_cell.keys(), kind]


static func palette_contains_all(palette_colors: Dictionary, colors_in_cell: Dictionary) -> bool:
	for color_html in colors_in_cell:
		if not palette_colors.has(color_html):
			return false
	return true


static func palettes_as_color_sets(kind: String) -> Dictionary:
	var color_sets := {}
	if kind == "background":
		for palette_name in Palettes.BACKGROUND_PALETTES:
			color_sets[palette_name] = five_bit_set(Palettes.background_colors(palette_name))
	else:
		for palette_name in Palettes.SPRITE_PALETTES:
			color_sets[palette_name] = five_bit_set(Palettes.sprite_colors(palette_name))
	return color_sets


static func five_bit_set(colors: Array[Color]) -> Dictionary:
	var set := {}
	for color in colors:
		set[five_bit_key(color)] = true
	return set


## Colours are compared in 5-bit space, so 8-bit rounding in PNGs cannot cause
## false mismatches.
static func five_bit_key(color: Color) -> Vector3i:
	return Vector3i(roundi(color.r * 31.0), roundi(color.g * 31.0), roundi(color.b * 31.0))


static func is_fifteen_bit(color: Color) -> bool:
	for channel in [color.r, color.g, color.b]:
		var eight_bit_value: float = channel * 255.0
		var nearest_five_bit_value := roundf(channel * 31.0)
		var expected_eight_bit_value := nearest_five_bit_value * 255.0 / 31.0
		# PNGs store 8 bits per channel, so a 15-bit colour lands within one step.
		if absf(eight_bit_value - expected_eight_bit_value) > 1.0:
			return false
	return true


static func png_paths_in(folder: String) -> Array[String]:
	var paths: Array[String] = []
	for file_name in DirAccess.get_files_at(folder):
		if file_name.ends_with(".png"):
			paths.append(folder.path_join(file_name))
	return paths
