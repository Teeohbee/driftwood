extends Node

## Takes screenshots of the game in a batch of set-ups, for checking the look.
## Needs a window (headless Godot cannot render), so it runs everything in one go:
##
##   godot --path . tests/capture.tscn      -> build/captures/*.png (3x)

const OUTPUT_FOLDER := "res://build/captures"
const OUTPUT_SCALE := 3

var game: Node


func _ready() -> void:
	game = get_node("/root/Game")
	DirAccess.make_dir_recursive_absolute("user://capture_saves")
	game.save_folder = "user://capture_saves"
	DirAccess.make_dir_recursive_absolute(OUTPUT_FOLDER)
	call_deferred("capture_everything")


func capture_everything() -> void:
	var title: Node = load("res://scenes/title/title_screen.tscn").instantiate()
	add_child(title)
	await seconds(2.0)
	await snap("01_title")
	title.queue_free()

	var select: Node = load("res://scenes/save_select/save_select.tscn").instantiate()
	add_child(select)
	await seconds(0.3)
	await snap("02_save_select")
	select.look = {"skin": 2, "shirt": 1, "hair": 1}
	select.stage = 3
	select.big_castaway.visible = true
	select.refresh_portraits()
	await seconds(0.3)
	await snap("03_look_picker")
	select.queue_free()

	var world := await new_world()
	await seconds(0.5)
	await snap("04_beach_morning")
	world.say(["THE CRATES MAY HAVE WASHED UP", "FROM THE WRECK."])
	await seconds(1.5)
	await snap("05_dialogue")
	world.dialogue_box.close_box()
	world.set_mode(World.Mode.PLAY)

	var save: SaveGame = world.save
	for item_id in ["stick", "stone", "vine", "sharp_stone", "coconut", "fibre", "raw_fish", "stone_axe"]:
		save.inventory.add(item_id, 3 if item_id == "stick" else 1)
	save.inventory.equip("a", "stone_axe")
	save.inventory.equip("b", "stick")
	save.known_recipes = ["stone+stone", "coconut+sharp_stone", "sharp_stone+stick+vine"]
	world.open_menu()
	await seconds(0.3)
	await snap("06_menu_items")
	world.pause_menu.tab_index = 1
	world.pause_menu.merge_picks = [0, 3, 2]
	await seconds(0.2)
	await snap("07_menu_merge")
	world.pause_menu.tab_index = 2
	await seconds(0.2)
	await snap("08_menu_book")
	world.pause_menu.tab_index = 3
	world.visited_screens = {"1,4": true, "2,4": true, "1,3": true, "2,3": true, "0,4": true}
	await seconds(0.2)
	await snap("09_menu_map")
	world.pause_menu.close()

	world.save.set_state("overworld", Vector2i(25, 37), "piece", "campfire")
	world.save.set_state("overworld", Vector2i(25, 37), "burns_until", 99999.0)
	world.add_thing("campfire", Vector2i(25, 37))
	world.refresh_thing_looks()
	save.clock.total_minutes = 21 * 60 + 30
	await seconds(0.4)
	await snap("10_night_campfire")

	save.clock.total_minutes = 10 * 60
	world.player.place_at(Vector2(30 * 16 + 8, 29 * 16 + 14))
	await seconds(0.4)
	await snap("11_home_meadow")
	for item_id in ["wood", "stone", "leaf", "fibre"]:
		save.inventory.add(item_id, 9)
	save.inventory.grow_to(16)
	Building.place(world, "workbench", Vector2i(32, 28))
	for x in range(28, 32):
		Building.place(world, "wall", Vector2i(x, 27))
	Building.place(world, "bed", Vector2i(28, 28))
	Building.place(world, "floor", Vector2i(29, 28))
	world.builder.open_for(Vector2i(31, 30))
	await seconds(0.4)
	await snap("12_build_mode")
	world.builder.close()

	world.player.place_at(Vector2(12 * 16 + 8, 12 * 16 + 14))
	await seconds(0.4)
	await snap("13_jungle")
	world.player.place_at(Vector2(53 * 16 + 8, 9 * 16 + 14))
	await seconds(0.4)
	await snap("14_hilltop")
	world.player.place_at(Vector2(72 * 16 + 8, 12 * 16 + 14))
	await seconds(0.4)
	await snap("15_ruins_islet")

	save.inventory.add("torch")
	save.inventory.equip("b", "torch")
	await world.go_through_door("cave", Vector2i(23, 21), Vector2i.UP)
	await seconds(0.5)
	await snap("16_cave_torch")
	world.player.place_at(Vector2(38 * 16 + 8, 5 * 16 + 14))
	world.check_room_change()
	await seconds(0.8)
	await snap("17_guardian_room")

	await world.go_through_door("overworld", Vector2i(37, 12), Vector2i.DOWN)
	save.clock.total_minutes += DayClock.MINUTES_PER_DAY * 21
	world.on_new_day()
	await seconds(0.5)
	await snap("18_winter_season_card")
	await seconds(2.5)
	await snap("19_winter")
	world.queue_free()

	Endings.pending_ending = "sail"
	var ending: Node = load("res://scenes/ending/ending.tscn").instantiate()
	add_child(ending)
	await seconds(4.0)
	await snap("20_ending_sail")
	ending.queue_free()
	print("Captures written to build/captures")
	get_tree().quit()


func new_world() -> World:
	game.new_game(0, {"skin": 0, "shirt": 0, "hair": 0})
	game.current.set_flag("intro_done")
	var world: World = load("res://scenes/world/world.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame
	return world


func seconds(duration: float) -> void:
	await get_tree().create_timer(duration).timeout


func snap(capture_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(image.get_width() * OUTPUT_SCALE, image.get_height() * OUTPUT_SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png("%s/%s.png" % [OUTPUT_FOLDER, capture_name])
