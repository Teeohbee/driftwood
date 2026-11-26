extends SceneTree

## Composes still mockups of the title screen and the beach from the baked art,
## without opening a window. Writes 4x-scaled PNGs to build/look_book/.
##
##   godot --headless --path . -s tools/make_look_book.gd

const SCREEN_SIZE := Vector2i(256, 144)
const OUTPUT_SCALE := 4
const OUTPUT_FOLDER := "res://build/look_book"
const STATUS_BAR_HEIGHT := 16

var font_atlas: Image
var icon_atlas: Image


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_FOLDER)
	font_atlas = ArtPainter.font_atlas_image()
	icon_atlas = ArtPainter.icon_atlas_image()

	save_scaled("1_title", compose_title_screen())
	save_scaled("2_beach", compose_beach_screen(false))
	save_scaled("3_beach_dialogue", compose_beach_screen(true))
	save_scaled("4_sprites_and_palettes", compose_sprite_sheet())
	quit()


func compose_title_screen() -> Image:
	var screen := ArtPainter.title_background_image(0)
	var logo := ArtPainter.logo_image()
	blend_image(screen, logo, Vector2i((SCREEN_SIZE.x - logo.get_width()) / 2, 14))
	draw_outlined_text_centred(screen, "PRESS START", 112)
	draw_text(screen, "2026 A HOMAGE TO 1999", Vector2i(56, 132), Palettes.sprite_color("ink", 1))
	return screen


func compose_beach_screen(with_dialogue: bool) -> Image:
	var screen := Image.create_empty(SCREEN_SIZE.x, SCREEN_SIZE.y, false, Image.FORMAT_RGBA8)
	var player_metatile := IslandLayout.player_start_metatile()
	var camera_offset := Vector2i(player_metatile.x * 16 - 120, player_metatile.y * 16 - 64)
	var tile_size := PixelArt.METATILE_SIZE

	for row in IslandLayout.height_in_metatiles():
		for column in IslandLayout.width_in_metatiles():
			var tile_image := ArtPainter.ground_tile_image(IslandLayout.ground_tile_at(column, row))
			blend_image(screen, tile_image, Vector2i(column, row) * tile_size - camera_offset)

	# Objects and the hero are drawn bottom-most last, like the game's y-sort.
	var drawables := []
	for row in IslandLayout.height_in_metatiles():
		for column in IslandLayout.width_in_metatiles():
			var object_name := IslandLayout.object_at(column, row)
			if object_name != "":
				drawables.append([row, object_name, Vector2i(column, row)])
	drawables.append([player_metatile.y, "hero_down", player_metatile])
	drawables.sort_custom(func(first: Array, second: Array) -> bool: return first[0] < second[0])
	for drawable in drawables:
		var sprite := ArtPainter.sprite_frame_image(drawable[1], 0)
		var metatile: Vector2i = drawable[2]
		var bottom_centre := Vector2i(metatile.x * tile_size + 8, (metatile.y + 1) * tile_size)
		var top_left := bottom_centre - Vector2i(sprite.get_width() / 2, sprite.get_height())
		blend_image(screen, sprite, top_left - camera_offset)

	var hero_top_left := player_metatile * tile_size - camera_offset
	blend_image(screen, ArtPainter.sprite_frame_image("emote_alert", 0), hero_top_left + Vector2i(0, -17))

	draw_status_bar(screen)
	if with_dialogue:
		draw_dialogue_box(screen, "A NOTE IN A BOTTLE.", "'DAY 41. THE TIDE HIDES IT...'")
	return screen


func draw_status_bar(screen: Image) -> void:
	var paper := Palettes.background_color("interface", 0)
	var ink := Palettes.background_color("interface", 3)
	var bar_top := SCREEN_SIZE.y - STATUS_BAR_HEIGHT
	screen.fill_rect(Rect2i(0, bar_top, SCREEN_SIZE.x, STATUS_BAR_HEIGHT), paper)
	screen.fill_rect(Rect2i(0, bar_top, SCREEN_SIZE.x, 1), ink)
	var meters := [["heart", "64"], ["hunger", "100"], ["water", "42"], ["fatigue", "21"]]
	for meter_index in meters.size():
		var left := 4 + meter_index * 40
		draw_icon(screen, meters[meter_index][0], Vector2i(left, bar_top + 4))
		draw_text(screen, meters[meter_index][1], Vector2i(left + 10, bar_top + 4), ink)
	draw_text(screen, "STICK", Vector2i(196, bar_top + 4), ink)
	screen.fill_rect(Rect2i(236, bar_top + 1, 18, 15), ink)
	screen.fill_rect(Rect2i(237, bar_top + 2, 16, 13), paper)
	var stick := ArtPainter.sprite_frame_image("stick", 0)
	blend_image(screen, stick, Vector2i(237, bar_top))


func draw_dialogue_box(screen: Image, first_line: String, second_line: String) -> void:
	var paper := Palettes.background_color("interface", 0)
	var shade := Palettes.background_color("interface", 1)
	var ink := Palettes.background_color("interface", 3)
	var box := Rect2i(8, 96, 240, 40)
	screen.fill_rect(box, ink)
	screen.fill_rect(box.grow(-1), paper)
	screen.fill_rect(box.grow(-2), shade)
	screen.fill_rect(box.grow(-3), paper)
	draw_text(screen, first_line, Vector2i(16, 106), ink)
	draw_text(screen, second_line, Vector2i(16, 118), ink)
	draw_icon(screen, "more_text", Vector2i(234, 126))


func compose_sprite_sheet() -> Image:
	var sheet := Image.create_empty(SCREEN_SIZE.x, SCREEN_SIZE.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Palettes.background_color("interface", 1))
	var atlas := ArtPainter.ground_atlas_image()
	blend_image(sheet, atlas, Vector2i(4, 4))
	var cursor := Vector2i(4, 26)
	for sprite_name in PixelArt.SPRITES:
		var sprite_sheet := ArtPainter.sprite_sheet_image(sprite_name)
		if cursor.x + sprite_sheet.get_width() > SCREEN_SIZE.x - 4:
			cursor = Vector2i(4, cursor.y + 34)
		blend_image(sheet, sprite_sheet, cursor)
		cursor.x += sprite_sheet.get_width() + 4
	var swatch_left := 4
	for palette_name in Palettes.BACKGROUND_PALETTES:
		for index in 4:
			sheet.fill_rect(Rect2i(swatch_left + index * 4, 128, 4, 12), Palettes.background_color(palette_name, index))
		swatch_left += 18
	return sheet


# --- Drawing helpers ---------------------------------------------------------

func draw_text(screen: Image, text: String, position: Vector2i, color: Color) -> void:
	var cell := FontGlyphs.CELL_SIZE
	for letter_index in text.length():
		var glyph_index := FontGlyphs.CHARACTERS.find(text[letter_index].to_upper())
		if glyph_index == -1:
			continue
		var glyph_origin := Vector2i((glyph_index % 16) * cell, (glyph_index / 16) * cell)
		for y in cell:
			for x in cell:
				if font_atlas.get_pixel(glyph_origin.x + x, glyph_origin.y + y).a > 0.5:
					set_pixel_if_inside(screen, position + Vector2i(letter_index * FontGlyphs.GLYPH_ADVANCE + x, y), color)


func draw_outlined_text_centred(screen: Image, text: String, top: int) -> void:
	var width := text.length() * FontGlyphs.GLYPH_ADVANCE - 1
	var left := (SCREEN_SIZE.x - width) / 2
	var dark := Palettes.sprite_color("ink", 3)
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			draw_text(screen, text, Vector2i(left + offset_x, top + offset_y), dark)
	draw_text(screen, text, Vector2i(left, top), Palettes.sprite_color("ink", 1))


func draw_icon(screen: Image, icon_name: String, position: Vector2i) -> void:
	var icon_index := PixelArt.ICONS.keys().find(icon_name)
	var icon := icon_atlas.get_region(Rect2i(icon_index * 8, 0, 8, 8))
	blend_image(screen, icon, position)


func blend_image(target: Image, source: Image, position: Vector2i) -> void:
	target.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), position)


func set_pixel_if_inside(image: Image, position: Vector2i, color: Color) -> void:
	if Rect2i(Vector2i.ZERO, image.get_size()).has_point(position):
		image.set_pixelv(position, color)


func save_scaled(file_name: String, image: Image) -> void:
	var scaled := image.duplicate() as Image
	scaled.resize(image.get_width() * OUTPUT_SCALE, image.get_height() * OUTPUT_SCALE, Image.INTERPOLATE_NEAREST)
	var path := OUTPUT_FOLDER.path_join(file_name + ".png")
	scaled.save_png(path)
	print("Wrote ", ProjectSettings.globalize_path(path))
