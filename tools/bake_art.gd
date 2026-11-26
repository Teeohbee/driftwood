extends SceneTree

## Bakes the text pixel art in art_source/ into PNGs under art/, then runs
## the palette checker.
##
##   godot --headless --path . -s tools/bake_art.gd


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://art/backgrounds")
	DirAccess.make_dir_recursive_absolute("res://art/sprites")

	save("res://art/backgrounds/ground_atlas.png", ArtPainter.ground_atlas_image())
	for season in Palettes.SEASONS:
		save("res://art/backgrounds/ground_atlas_%s.png" % season, ArtPainter.ground_atlas_image(season))
	save("res://art/backgrounds/title_background_1.png", ArtPainter.title_background_image(0))
	save("res://art/backgrounds/title_background_2.png", ArtPainter.title_background_image(1))

	for sprite_name in PixelArt.all_sprites():
		save("res://art/sprites/%s.png" % sprite_name, ArtPainter.sprite_sheet_image(sprite_name))
	save("res://art/sprites/font.png", ArtPainter.font_atlas_image())
	save("res://art/sprites/icons.png", ArtPainter.icon_atlas_image())
	save("res://art/sprites/logo.png", ArtPainter.logo_image())

	var problems := PaletteChecker.check_all_art()
	for problem in problems:
		printerr(problem)
	print("Palette check: %d problem(s)" % problems.size())
	quit(1 if problems.size() > 0 else 0)


func save(path: String, image: Image) -> void:
	var error := image.save_png(path)
	if error != OK:
		printerr("Could not save %s (error %d)" % [path, error])
	else:
		print("Baked %s" % path)
