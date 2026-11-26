extends SceneTree

## Lays every sprite and ground tile out on one sheet at 3x, for reviewing art.
##
##   godot --headless --path . -s tools/preview_art.gd   -> build/art_sheet.png

const SHEET_WIDTH := 400
const SCALE := 3


func _initialize() -> void:
	var sprite_names := PixelArt.all_sprites().keys()
	var sheet := Image.create_empty(SHEET_WIDTH, 900, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.55, 0.5, 0.45))
	sheet.blit_rect(ArtPainter.ground_atlas_image(), Rect2i(0, 0, SHEET_WIDTH, 16), Vector2i(2, 2))
	var atlas := ArtPainter.ground_atlas_image()
	if atlas.get_width() > SHEET_WIDTH - 4:
		sheet.blit_rect(atlas, Rect2i(SHEET_WIDTH - 4, 0, atlas.get_width(), 16), Vector2i(2, 20))
	var cursor := Vector2i(2, 40)
	var row_height := 0
	for sprite_name in sprite_names:
		var image := ArtPainter.sprite_sheet_image(sprite_name)
		if cursor.x + image.get_width() > SHEET_WIDTH - 2:
			cursor = Vector2i(2, cursor.y + row_height + 2)
			row_height = 0
		sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), cursor)
		cursor.x += image.get_width() + 2
		row_height = maxi(row_height, image.get_height())
	var used := sheet.get_region(Rect2i(0, 0, SHEET_WIDTH, cursor.y + row_height + 2))
	used.resize(used.get_width() * SCALE, used.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	DirAccess.make_dir_recursive_absolute("res://build")
	used.save_png("res://build/art_sheet.png")
	print("Wrote build/art_sheet.png with %d sprites" % sprite_names.size())
	quit()
