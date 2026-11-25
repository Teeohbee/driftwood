extends SceneTree

## Headless checks for the look book. Exits non-zero on any failure.
##
##   godot --headless --path . -s tests/smoke_test.gd

## A script error skips the checks after it instead of failing them,
## so the run also fails unless every check reported in.
const EXPECTED_CHECK_COUNT := 8

var failures: Array[String] = []
var checks_reported := 0


func _initialize() -> void:
	call_deferred("run_all_checks")


func run_all_checks() -> void:
	check_baked_art_follows_palette_rules()
	check_palette_checker_catches_too_many_colours()
	await check_title_screen_runs()
	await check_castaway_walks_and_is_stopped_by_the_cliff()
	await check_resting_at_the_campfire_opens_dialogue()

	if checks_reported != EXPECTED_CHECK_COUNT:
		failures.append("only %d of %d checks ran - look for script errors above" % [checks_reported, EXPECTED_CHECK_COUNT])
	for failure in failures:
		printerr("FAIL: ", failure)
	print("Smoke test: %d failure(s)" % failures.size())
	quit(1 if failures.size() > 0 else 0)


func expect(condition: bool, description: String) -> void:
	checks_reported += 1
	if condition:
		print("ok   ", description)
	else:
		failures.append(description)


func check_baked_art_follows_palette_rules() -> void:
	var problems := PaletteChecker.check_all_art()
	for problem in problems:
		printerr(problem)
	expect(problems.is_empty(), "baked art follows the Game Boy Color palette rules")


func check_palette_checker_catches_too_many_colours() -> void:
	var image := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	var sand := Palettes.background_colors("sand")
	image.fill(sand[0])
	image.set_pixel(0, 0, sand[1])
	image.set_pixel(1, 0, sand[2])
	image.set_pixel(2, 0, sand[3])
	image.set_pixel(3, 0, Palettes.background_color("water", 1))
	var problems := PaletteChecker.check_image("five colours", image, "background")
	expect(problems.size() == 1, "palette checker rejects a cell with five colours")


func check_title_screen_runs() -> void:
	var title: Node = load("res://scenes/title/title_screen.tscn").instantiate()
	root.add_child(title)
	for frame in 30:
		await process_frame
	expect(is_instance_valid(title), "title screen runs for 30 frames")
	title.queue_free()
	await process_frame


func check_castaway_walks_and_is_stopped_by_the_cliff() -> void:
	var island: Node = load("res://scenes/island/island.tscn").instantiate()
	root.add_child(island)
	await process_frame
	var player: Player = island.player
	var start_x := player.exact_position.x

	for step in 10:
		player.walk(Vector2.RIGHT, 0.1)
	expect(player.exact_position.x > start_x + 40, "castaway walks right")

	for step in 200:
		player.walk(Vector2.LEFT, 0.1)
	var cliff_right_edge := 2 * 16
	expect(player.exact_position.x - Player.FEET_SIZE.x / 2 >= cliff_right_edge, "castaway stops at the cliff")
	island.queue_free()
	await process_frame


func check_resting_at_the_campfire_opens_dialogue() -> void:
	var island: Node = load("res://scenes/island/island.tscn").instantiate()
	root.add_child(island)
	await process_frame
	var player: Player = island.player
	# Stand just below the campfire (metatile 14, 6) and face it.
	player.exact_position = Vector2(14 * 16 + 8, 7 * 16 + 12)
	player.face_towards(Vector2.UP)
	var fatigue_before: int = island.meters.fatigue

	var faced_thing: String = island.thing_in_front_of_player()
	expect(faced_thing == "campfire", "castaway faces the campfire (saw '%s')" % faced_thing)
	island.interact_with(faced_thing)
	expect(island.dialogue_box.is_open, "campfire opens the dialogue box")
	expect(island.meters.fatigue == mini(fatigue_before + 10, 100), "resting at the campfire restores fatigue")
	island.queue_free()
	await process_frame
