class_name ArtPainter
extends RefCounted

## Turns the text pixel art in art_source/ into Images.
## Used by tools/bake_art.gd (writes PNGs) and tools/make_look_book.gd.

const TITLE_WIDTH := 256
const TITLE_HEIGHT := 144
const TITLE_HORIZON_Y := 88
const LOGO_TEXT := "DRIFTWOOD"
const LOGO_SCALE := 3


# --- Text grids -------------------------------------------------------------

static func ground_tile_image(tile_name: String) -> Image:
	var base_name := tile_name.trim_suffix("_frame_2")
	var tile: Dictionary = PixelArt.GROUND_TILES[base_name]
	var rows: Array = tile["rows"]
	if tile_name.ends_with("_frame_2"):
		rows = second_frame_rows_for(base_name, rows)
	var colors := Palettes.background_colors(tile["palette"])
	return image_from_rows(tile_name, rows, func(character: String, _row: int) -> Color:
		return colors[int(character)]
	)


## Water ripples drift sideways; on the shore only the foam line moves.
static func second_frame_rows_for(base_name: String, rows: Array) -> Array:
	if base_name == "water":
		return rows_shifted_right(rows, 3, 0, rows.size() - 1)
	if base_name == "shore":
		return rows_shifted_right(rows, 2, 5, 9)
	return rows


static func rows_shifted_right(rows: Array, distance: int, first_row: int, last_row: int) -> Array:
	var shifted_rows := []
	for row_index in rows.size():
		var row: String = rows[row_index]
		if row_index >= first_row and row_index <= last_row:
			row = row.right(distance) + row.left(row.length() - distance)
		shifted_rows.append(row)
	return shifted_rows


static func sprite_frame_image(sprite_name: String, frame_index: int) -> Image:
	var sprite: Dictionary = PixelArt.SPRITES[sprite_name]
	var rows: Array = sprite["frames"][frame_index]
	return image_from_rows(sprite_name, rows, func(character: String, row: int) -> Color:
		if character == ".":
			return Color(0, 0, 0, 0)
		return Palettes.sprite_color(sprite_palette_for_row(sprite, row), int(character))
	)


static func sprite_palette_for_row(sprite: Dictionary, row: int) -> String:
	if sprite.has("palette_bands"):
		return sprite["palette_bands"][row / 8]
	return sprite["palette"]


static func sprite_sheet_image(sprite_name: String) -> Image:
	var frames: Array = PixelArt.SPRITES[sprite_name]["frames"]
	var first_frame := sprite_frame_image(sprite_name, 0)
	var sheet := Image.create_empty(first_frame.get_width() * frames.size(), first_frame.get_height(), false, Image.FORMAT_RGBA8)
	for frame_index in frames.size():
		var frame_image := sprite_frame_image(sprite_name, frame_index)
		sheet.blit_rect(frame_image, Rect2i(Vector2i.ZERO, frame_image.get_size()), Vector2i(frame_index * first_frame.get_width(), 0))
	return sheet


static func image_from_rows(art_name: String, rows: Array, color_for_character: Callable) -> Image:
	var width: int = rows[0].length()
	var height: int = rows.size()
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for row in height:
		var row_text: String = rows[row]
		assert(row_text.length() == width, "%s row %d is %d wide, expected %d" % [art_name, row, row_text.length(), width])
		for column in width:
			image.set_pixel(column, row, color_for_character.call(row_text[column], row))
	return image


# --- Atlases ----------------------------------------------------------------

static func ground_atlas_image() -> Image:
	var tile_size := PixelArt.METATILE_SIZE
	var atlas := Image.create_empty(tile_size * PixelArt.GROUND_TILE_ORDER.size(), tile_size, false, Image.FORMAT_RGBA8)
	for tile_index in PixelArt.GROUND_TILE_ORDER.size():
		var tile_image := ground_tile_image(PixelArt.GROUND_TILE_ORDER[tile_index])
		atlas.blit_rect(tile_image, Rect2i(0, 0, tile_size, tile_size), Vector2i(tile_index * tile_size, 0))
	return atlas


## White glyphs on transparent, 16 per row. Tint them when drawing.
static func font_atlas_image() -> Image:
	var cell := FontGlyphs.CELL_SIZE
	var glyph_count := FontGlyphs.CHARACTERS.length()
	var columns := 16
	var row_count := ceili(float(glyph_count) / columns)
	var atlas := Image.create_empty(columns * cell, row_count * cell, false, Image.FORMAT_RGBA8)
	var ink := Palettes.sprite_color("ink", 1)
	for glyph_index in glyph_count:
		var glyph_rows: Array = FontGlyphs.GLYPHS[FontGlyphs.CHARACTERS[glyph_index]]
		var cell_origin := Vector2i((glyph_index % columns) * cell, (glyph_index / columns) * cell)
		for row in glyph_rows.size():
			for column in glyph_rows[row].length():
				if glyph_rows[row][column] == "#":
					atlas.set_pixelv(cell_origin + Vector2i(column, row), ink)
	return atlas


static func icon_atlas_image() -> Image:
	var icon_names := PixelArt.ICONS.keys()
	var atlas := Image.create_empty(8 * icon_names.size(), 8, false, Image.FORMAT_RGBA8)
	for icon_index in icon_names.size():
		var rows: Array = PixelArt.ICONS[icon_names[icon_index]]
		var icon_image := image_from_rows(icon_names[icon_index], rows, func(character: String, _row: int) -> Color:
			if character == ".":
				return Color(0, 0, 0, 0)
			return Palettes.sprite_color("ink", int(character))
		)
		atlas.blit_rect(icon_image, Rect2i(0, 0, 8, 8), Vector2i(icon_index * 8, 0))
	return atlas


# --- Title screen -----------------------------------------------------------

## The logo is the font blown up 3x: yellow face, orange lower third,
## dark outline and a drop shadow. Three colours, so it works as sprites.
static func logo_image() -> Image:
	var scale := LOGO_SCALE
	var glyph_height := 7 * scale
	var face_width := (LOGO_TEXT.length() * FontGlyphs.GLYPH_ADVANCE - 1) * scale
	var margin := 1
	var shadow_offset := 2
	var image := Image.create_empty(face_width + margin * 2 + shadow_offset, glyph_height + margin * 2 + shadow_offset, false, Image.FORMAT_RGBA8)

	var face_pixels := {}
	for letter_index in LOGO_TEXT.length():
		var glyph_rows: Array = FontGlyphs.GLYPHS[LOGO_TEXT[letter_index]]
		var letter_left := margin + letter_index * FontGlyphs.GLYPH_ADVANCE * scale
		for row in glyph_rows.size():
			for column in glyph_rows[row].length():
				if glyph_rows[row][column] != "#":
					continue
				for block_y in scale:
					for block_x in scale:
						face_pixels[Vector2i(letter_left + column * scale + block_x, margin + row * scale + block_y)] = true

	var yellow := Palettes.sprite_color("logo", 1)
	var orange := Palettes.sprite_color("logo", 2)
	var dark := Palettes.sprite_color("logo", 3)

	for pixel in face_pixels:
		var shadow_pixel: Vector2i = pixel + Vector2i(shadow_offset, shadow_offset)
		image.set_pixelv(shadow_pixel, dark)
	for pixel in face_pixels:
		for neighbour_y in range(-1, 2):
			for neighbour_x in range(-1, 2):
				var neighbour: Vector2i = pixel + Vector2i(neighbour_x, neighbour_y)
				if not face_pixels.has(neighbour):
					image.set_pixelv(neighbour, dark)
	for pixel in face_pixels:
		var depth_in_letter: int = pixel.y - margin
		var is_lower_third: bool = depth_in_letter >= glyph_height * 2 / 3
		var is_grain_line: bool = depth_in_letter == 4 and (pixel.x / 4) % 3 == 1
		if is_lower_third or is_grain_line:
			image.set_pixelv(pixel, orange)
		else:
			image.set_pixelv(pixel, yellow)
	return image


## A sunset over the sea: banded sky with checker dithering, a backlit island
## and palms in the sky's darkest colour, and a sea that sparkles.
## Two frames so the sea can shimmer.
static func title_background_image(frame_index: int) -> Image:
	var image := Image.create_empty(TITLE_WIDTH, TITLE_HEIGHT, false, Image.FORMAT_RGBA8)
	paint_sunset_sky(image)
	paint_sun(image, Vector2i(160, TITLE_HORIZON_Y), 26)
	paint_island_silhouette(image)
	paint_sea(image, frame_index)
	return image


static func paint_sunset_sky(image: Image) -> void:
	var sky := Palettes.background_colors("sky")
	# Each band: [first row, darker index, lighter index]. Equal indices are solid.
	var bands := [
		[0, 3, 3],
		[24, 3, 2],
		[32, 2, 2],
		[52, 2, 1],
		[60, 1, 1],
	]
	for y in TITLE_HORIZON_Y:
		var band: Array = bands[0]
		for candidate in bands:
			if y >= candidate[0]:
				band = candidate
		for x in TITLE_WIDTH:
			var use_lighter := (x + y) % 2 == 0
			var palette_index: int = band[2] if use_lighter else band[1]
			image.set_pixel(x, y, sky[palette_index])


static func paint_sun(image: Image, centre: Vector2i, radius: int) -> void:
	var sky := Palettes.background_colors("sky")
	for y in range(centre.y - radius, centre.y):
		for x in range(centre.x - radius, centre.x + radius + 1):
			var distance_squared := (x - centre.x) * (x - centre.x) + (y - centre.y) * (y - centre.y)
			var is_inside := distance_squared <= radius * radius
			var is_rim := distance_squared > (radius - 2) * (radius - 2)
			if is_inside and not (is_rim and (x + y) % 2 == 0):
				image.set_pixel(x, y, sky[0])


static func paint_island_silhouette(image: Image) -> void:
	var silhouette := Palettes.background_color("sky", 3)
	for x in range(40, 200):
		var big_hill := 24.0 * exp(-pow((x - 96.0) / 30.0, 2.0))
		var small_hill := 13.0 * exp(-pow((x - 136.0) / 20.0, 2.0))
		var beach := 3.0 if x > 50 and x < 186 else 1.0
		var height := int(big_hill + small_hill + beach)
		for y in range(TITLE_HORIZON_Y - height, TITLE_HORIZON_Y):
			image.set_pixel(x, y, silhouette)
	paint_palm_silhouette(image, Vector2i(58, 86), 34, -10, silhouette)
	paint_palm_silhouette(image, Vector2i(70, 85), 26, -4, silhouette)
	paint_palm_silhouette(image, Vector2i(176, 86), 30, 12, silhouette)


static func paint_palm_silhouette(image: Image, base: Vector2i, height: int, lean: int, color: Color) -> void:
	var top := base
	for step in height:
		var progress := float(step) / height
		var x := base.x + int(round(lean * progress * progress))
		var y := base.y - step
		set_pixel_if_inside(image, x, y, color)
		set_pixel_if_inside(image, x + 1, y, color)
		if progress < 0.15:
			set_pixel_if_inside(image, x - 1, y, color)
		top = Vector2i(x, y)
	# Fronds: [direction, length, rise per pixel, droop]
	var fronds := [
		[-1, 18, 0.8, 0.09],
		[1, 18, 0.8, 0.09],
		[-1, 13, 1.2, 0.15],
		[1, 14, 1.2, 0.14],
		[-1, 8, 1.6, 0.08],
		[1, 8, 1.6, 0.08],
	]
	for frond in fronds:
		var direction: int = frond[0]
		var length: int = frond[1]
		var rise: float = frond[2]
		var droop: float = frond[3]
		for distance in length:
			var x: int = top.x + direction * distance
			var y: int = top.y - int(round(rise * distance - droop * distance * distance))
			set_pixel_if_inside(image, x, y, color)
			set_pixel_if_inside(image, x, y + 1, color)
			if distance < length / 2:
				set_pixel_if_inside(image, x, y - 1, color)
			if distance > 2 and distance % 2 == 0:
				set_pixel_if_inside(image, x, y + 2, color)
				set_pixel_if_inside(image, x - direction, y + 3, color)


static func paint_sea(image: Image, frame_index: int) -> void:
	var water := Palettes.background_colors("water")
	for y in range(TITLE_HORIZON_Y, TITLE_HEIGHT):
		var depth := y - TITLE_HORIZON_Y
		for x in TITLE_WIDTH:
			var palette_index := 1
			if depth >= 36:
				palette_index = 2
			elif depth >= 24 and (x + y) % 2 == 0:
				palette_index = 2
			image.set_pixel(x, y, water[palette_index])
		paint_wave_dashes(image, y, depth, frame_index, water)
		paint_reflections(image, y, depth, frame_index, water)


static func paint_wave_dashes(image: Image, y: int, depth: int, frame_index: int, water: Array[Color]) -> void:
	if y % 3 != 0:
		return
	var drift := frame_index * 2 * (1 if (y / 3) % 2 == 0 else -1)
	var dash_color := water[0] if depth < 30 else water[1]
	for x in TITLE_WIDTH:
		var cell := (x + drift + y * 7) / 6
		var is_dash := (cell * 37 + y * 11) % 9 == 0
		if is_dash:
			image.set_pixel(x, y, dash_color)


static func paint_reflections(image: Image, y: int, depth: int, frame_index: int, water: Array[Color]) -> void:
	if depth % 2 == 1:
		return
	var sun_half_width := 20 - depth / 2
	if sun_half_width > 0:
		var wobble := (frame_index + depth / 2) % 2 * 2 - 1
		for x in range(160 - sun_half_width + wobble, 160 + sun_half_width + wobble):
			if (x / 3 + depth / 2) % 3 != 0:
				image.set_pixel(x, y, water[0])
	if depth < 8:
		for x in range(60 + depth * 4, 176 - depth * 4):
			if (x / 5 + depth / 2 + frame_index) % 3 == 0:
				image.set_pixel(x, y, water[2])


static func set_pixel_if_inside(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x, y, color)
