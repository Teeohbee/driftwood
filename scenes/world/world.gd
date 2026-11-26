class_name World
extends Node2D

## The playing field. Builds the current map from WorldMaps plus the save's
## changes, runs the clock and meters, and hands button presses to
## Interactions. One World node lives for the whole session; walking through
## a door rebuilds the map in place.

const TILE_SIZE := 16
const SCREEN_SIZE_IN_CELLS := Vector2i(16, 8)
const TITLE_SCENE := "res://scenes/title/title_screen.tscn"
const ENDING_SCENE := "res://scenes/ending/ending.tscn"
const ROOM_SLIDE_SECONDS := 0.5
const SECONDS_BETWEEN_COMPANION_FINDS := 75.0
const BLOCKING_GROUND := ["water", "shore", "cliff", "jungle_wall", "river", "ruins_wall", "cave_wall"]
const WATER_GROUND := ["water", "shore", "river"]

enum Mode { PLAY, DIALOGUE, MENU, FISHING, ROOM_SLIDE, SLEEPING, BUILD, CHEST, CUTSCENE }

var save: SaveGame
var map_id := ""
var mode := Mode.PLAY
var interactions: Interactions
var builder: BuildMode

var ground: TileMapLayer
var floors: TileMapLayer
var world_objects: Node2D
var roofs: Node2D
var player: Player
var camera: Camera2D
var emote: Sprite2D
var things_by_cell := {}
var roofs_by_cell := {}
var creatures: Array[Creature] = []

var hud_layer: CanvasLayer
var status_bar: StatusBar
var toasts: Toasts
var dialogue_box: DialogueBox
var pause_menu: PauseMenu
var night_overlay: NightOverlay
var weather_overlay: WeatherOverlay
var chest_menu: ChestMenu
var settings_menu: SettingsMenu

var day_seen := 0
var season_seen := ""
var current_room := Vector2i.ZERO
var fishing_timer := 0.0
var fishing_bite_window := 0.0
var fishing_cell := Vector2i.ZERO
var companion_find_timer := SECONDS_BETWEEN_COMPANION_FINDS
var seconds_alive := 0.0
var visited_screens := {}
var last_hour_seen := -1


func _ready() -> void:
	save = Game.current
	interactions = Interactions.new(self)
	builder = BuildMode.new()
	builder.world = self
	build_interface()
	load_map(save.map_id, save.player_position)
	day_seen = save.clock.day()
	season_seen = save.clock.season()
	Sound.play_music(map_music())
	if not save.flag("intro_done"):
		play_intro()


# --- Building the map --------------------------------------------------------

func load_map(new_map_id: String, player_feet: Vector2) -> void:
	for child in get_children():
		if child != hud_layer:
			child.queue_free()
	things_by_cell.clear()
	roofs_by_cell.clear()
	creatures.clear()
	map_id = new_map_id
	save.map_id = map_id
	visited_screens = save.flags.get("visited_%s" % map_id, {})

	ground = TileMapLayer.new()
	ground.tile_set = make_ground_tile_set(save.clock.season())
	add_child(ground)
	floors = TileMapLayer.new()
	floors.tile_set = ground.tile_set
	add_child(floors)
	world_objects = Node2D.new()
	world_objects.y_sort_enabled = true
	add_child(world_objects)
	roofs = Node2D.new()
	roofs.z_index = 10
	add_child(roofs)

	paint_ground()
	spawn_things()
	spawn_creatures()
	spawn_player(player_feet)
	refresh_floors()
	refresh_roofs()
	apply_season_to_things()


func make_ground_tile_set(season: String) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = load("res://art/backgrounds/ground_atlas_%s.png" % season)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var tile_order := PixelArt.ground_tile_order()
	for atlas_column in tile_order.size():
		var tile_name: String = tile_order[atlas_column]
		if tile_name.ends_with("_frame_2"):
			continue
		var coordinates := Vector2i(atlas_column, 0)
		source.create_tile(coordinates)
		var next_index := atlas_column + 1
		var has_second_frame: bool = next_index < tile_order.size() and tile_order[next_index] == tile_name + "_frame_2"
		if has_second_frame:
			source.set_tile_animation_frames_count(coordinates, 2)
			source.set_tile_animation_frame_duration(coordinates, 0, 0.5)
			source.set_tile_animation_frame_duration(coordinates, 1, 0.5)
	tile_set.add_source(source, 0)
	return tile_set


func atlas_coordinates(tile_name: String) -> Vector2i:
	return Vector2i(PixelArt.ground_tile_order().find(tile_name), 0)


func paint_ground() -> void:
	for row in WorldMaps.height_of(map_id):
		for column in WorldMaps.width_of(map_id):
			var cell := Vector2i(column, row)
			ground.set_cell(cell, 0, atlas_coordinates(WorldMaps.ground_tile_at(map_id, cell)))


func refresh_floors() -> void:
	floors.clear()
	for cell in save.cells_with(map_id, "floor"):
		floors.set_cell(cell, 0, atlas_coordinates(save.state_at(map_id, cell)["floor"]))


func refresh_roofs() -> void:
	for roof in roofs.get_children():
		roof.queue_free()
	roofs_by_cell.clear()
	for cell in save.cells_with(map_id, "roof"):
		var roof := Sprite2D.new()
		roof.texture = load("res://art/sprites/roof.png")
		roof.centered = false
		roof.position = Vector2(cell * TILE_SIZE) - Vector2(0, 8)
		roofs.add_child(roof)
		roofs_by_cell[cell] = roof


func spawn_things() -> void:
	var today := save.clock.day()
	for row in WorldMaps.height_of(map_id):
		for column in WorldMaps.width_of(map_id):
			var cell := Vector2i(column, row)
			var kind := WorldMaps.thing_at(map_id, cell)
			if kind == "":
				continue
			var state := save.state_at(map_id, cell)
			if state.has("gone"):
				var regrow_day := int(state["gone"])
				if regrow_day == 0 or today < regrow_day:
					continue
				save.set_state(map_id, cell, "gone", null)
			if kind == "crate" and state.get("opened", false):
				add_thing("crate", cell).show_sprite("crate_open")
				continue
			add_thing(kind, cell)
	for cell in save.cells_with(map_id, "piece"):
		add_thing(save.state_at(map_id, cell)["piece"], cell)
	for cell in save.cells_with(map_id, "items"):
		add_dropped_thing(cell)
	refresh_thing_looks()


func add_thing(kind: String, cell: Vector2i) -> WorldThing:
	remove_thing_node(cell)
	var thing := WorldThing.new()
	thing.setup(kind, cell)
	world_objects.add_child(thing)
	things_by_cell[cell] = thing
	return thing


func add_dropped_thing(cell: Vector2i) -> void:
	var items: Array = save.state_at(map_id, cell)["items"]
	if items.is_empty():
		return
	var thing := add_thing("dropped", cell)
	thing.show_sprite("fallen_bag" if items.size() > 1 else ItemCatalog.sprite_for(items[0]["id"]))


func remove_thing_node(cell: Vector2i) -> void:
	if things_by_cell.has(cell):
		things_by_cell[cell].queue_free()
		things_by_cell.erase(cell)


## Shows ripe fruit, lit fires, open doors and grown crops.
func refresh_thing_looks() -> void:
	for cell in things_by_cell:
		refresh_thing_look(things_by_cell[cell])


func refresh_thing_look(thing: WorldThing) -> void:
	var state := save.state_at(map_id, thing.cell)
	var info := ThingCatalog.thing(thing.kind)
	if info.has("harvest"):
		thing.show_overlay(info["harvest"].get("overlay", "") if interactions.is_harvest_ready(thing) else "")
	match thing.kind:
		"campfire":
			thing.show_sprite("campfire" if is_fire_lit(thing.cell) else "campfire_out")
		"door":
			thing.sprite.frame = 1 if state.get("open", false) else 0
		"beacon":
			if save.flag("beacon_lit"):
				thing.show_sprite("beacon_lit")
		"radio":
			if save.flag("radio_fixed"):
				thing.show_sprite("radio_fixed")
		"crop":
			thing.show_sprite(Farming.sprite_for_crop(state.get("crop", {}), save.clock.day()))


func apply_season_to_things() -> void:
	var season := save.clock.season()
	for cell in things_by_cell:
		things_by_cell[cell].apply_season(season)


func spawn_creatures() -> void:
	var today := save.clock.day()
	for row in WorldMaps.height_of(map_id):
		for column in WorldMaps.width_of(map_id):
			var cell := Vector2i(column, row)
			var kind := WorldMaps.creature_at(map_id, cell)
			if kind == "":
				continue
			var creature_id := "%s_%d_%d" % [kind, cell.x, cell.y]
			var animal: Dictionary = save.animals.get(creature_id, {})
			if kind == "guardian" and save.flag("guardian_defeated"):
				continue
			if today < int(animal.get("dead_until", 0)):
				continue
			if animal.get("tamed", false) and not save.home.is_empty():
				continue
			if kind == "monkey" and save.companion.get("active", false):
				continue
			add_creature(kind, cell)
	# Tamed animals live by the home bed; the companion follows you.
	if not save.home.is_empty() and save.home.get("map", "") == map_id:
		var home_cell := Vector2i(int(save.home["x"]), int(save.home["y"]))
		var offset := 0
		for creature_id in save.animals:
			var animal: Dictionary = save.animals[creature_id]
			if not animal.get("tamed", false) or animal.get("kind", "") == "monkey":
				continue
			var creature := add_creature(animal["kind"], home_cell + Vector2i(2 + offset % 3, 1 + offset / 3))
			creature.spawn_cell = Vector2i(int(animal["x"]), int(animal["y"]))
			creature.is_tamed = true
			offset += 1


func add_creature(kind: String, cell: Vector2i) -> Creature:
	var creature := Creature.new()
	creature.setup(kind, cell)
	creature.is_area_blocked = is_area_blocked_for_creature
	creature.hurt_player.connect(on_player_hurt)
	world_objects.add_child(creature)
	creatures.append(creature)
	return creature


func spawn_player(feet_position: Vector2) -> void:
	player = Player.new()
	player.look = save.look
	player.position = feet_position
	player.is_area_blocked = is_area_blocked
	world_objects.add_child(player)
	for creature in creatures:
		creature.player = player
	if save.companion.get("active", false):
		var monkey := add_creature("monkey", Vector2i(floori(feet_position.x / 16) - 1, floori(feet_position.y / 16)))
		monkey.is_companion = true
		monkey.player = player

	camera = Camera2D.new()
	camera.offset = Vector2(0, StatusBar.HEIGHT / 2)
	if is_room_camera():
		add_child(camera)
		current_room = room_of(player.exact_position)
		camera.position = room_centre(current_room)
	else:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = WorldMaps.width_of(map_id) * TILE_SIZE
		camera.limit_bottom = WorldMaps.height_of(map_id) * TILE_SIZE + StatusBar.HEIGHT
		player.add_child(camera)
	camera.make_current()

	emote = Sprite2D.new()
	emote.texture = preload("res://art/sprites/emote_alert.png")
	emote.centered = false
	emote.position = Vector2(-8, -34)
	emote.visible = false
	player.add_child(emote)


func is_room_camera() -> bool:
	return WorldMaps.map_data(map_id)["camera"] == "rooms"


func room_of(feet_position: Vector2) -> Vector2i:
	return Vector2i(floori(feet_position.x / (SCREEN_SIZE_IN_CELLS.x * TILE_SIZE)), floori((feet_position.y - 4) / (SCREEN_SIZE_IN_CELLS.y * TILE_SIZE)))


func room_centre(room: Vector2i) -> Vector2:
	return Vector2(room.x * 256 + 128, room.y * 128 + 64)


func map_music() -> String:
	return WorldMaps.map_data(map_id)["music"]


# --- Interface ----------------------------------------------------------------

func build_interface() -> void:
	var night_layer := CanvasLayer.new()
	night_layer.layer = 1
	night_overlay = NightOverlay.new()
	night_layer.add_child(night_overlay)
	weather_overlay = WeatherOverlay.new()
	night_layer.add_child(weather_overlay)

	hud_layer = CanvasLayer.new()
	hud_layer.layer = 2
	add_child(hud_layer)
	hud_layer.add_child(night_layer)
	status_bar = StatusBar.new()
	status_bar.save = save
	hud_layer.add_child(status_bar)
	toasts = Toasts.new()
	hud_layer.add_child(toasts)
	hud_layer.add_child(builder)
	dialogue_box = DialogueBox.new()
	dialogue_box.visible = false
	hud_layer.add_child(dialogue_box)

	var menu_layer := CanvasLayer.new()
	menu_layer.layer = 3
	hud_layer.add_child(menu_layer)
	pause_menu = PauseMenu.new()
	pause_menu.save = save
	pause_menu.visible = false
	pause_menu.closed.connect(func() -> void: set_mode(Mode.PLAY))
	pause_menu.use_item_requested.connect(on_menu_use_item)
	pause_menu.drop_requested.connect(on_menu_drop)
	pause_menu.merge_requested.connect(on_menu_merge)
	pause_menu.quit_requested.connect(on_quit_requested)
	pause_menu.settings_requested.connect(open_settings)
	menu_layer.add_child(pause_menu)
	chest_menu = ChestMenu.new()
	chest_menu.visible = false
	chest_menu.closed.connect(func() -> void: set_mode(Mode.PLAY))
	menu_layer.add_child(chest_menu)
	settings_menu = SettingsMenu.new()
	settings_menu.visible = false
	settings_menu.closed.connect(func() -> void: pause_menu.visible = true)
	menu_layer.add_child(settings_menu)


func set_mode(new_mode: Mode) -> void:
	mode = new_mode


func say(lines: Array, on_closed := Callable()) -> void:
	dialogue_box.show_lines(lines)
	set_mode(Mode.DIALOGUE)
	Sound.play("blip")
	dialogue_box.finished_callback = on_closed


func ask(lines: Array, choices: Array, on_answer: Callable) -> void:
	dialogue_box.show_question(lines, choices, on_answer)
	set_mode(Mode.DIALOGUE)
	Sound.play("blip")


func toast(text: String) -> void:
	toasts.show_message(text)


func hint_once(hint_id: String, lines: Array) -> void:
	if save.hints_seen.has(hint_id) or mode != Mode.PLAY:
		return
	save.hints_seen[hint_id] = true
	say(lines)


# --- The loop -----------------------------------------------------------------

func _process(delta: float) -> void:
	seconds_alive += delta
	match mode:
		Mode.PLAY:
			process_play(delta)
		Mode.DIALOGUE:
			player.walk(Vector2.ZERO, delta)
			emote.visible = false
			if not dialogue_box.is_open:
				set_mode(Mode.PLAY)
		Mode.FISHING:
			process_fishing(delta)
		Mode.BUILD:
			advance_time(delta)
		Mode.ROOM_SLIDE, Mode.MENU, Mode.SLEEPING, Mode.CHEST, Mode.CUTSCENE:
			pass
	update_night()
	update_roof_visibility()
	update_visited_screen()
	pause_menu.current_map = map_id
	pause_menu.player_cell = player.cell()
	pause_menu.visited_screens = visited_screens


func process_play(delta: float) -> void:
	advance_time(delta)
	if mode != Mode.PLAY:
		return
	if Input.is_action_just_pressed("start"):
		open_menu()
		return
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.speed_factor = 0.5 if save.meters.is_exhausted() else (1.1 if save.meters.is_rested() else 1.0)
	if not player.is_hurt():
		player.walk(input_direction, delta)
	check_doors()
	check_room_change()
	check_raft_landing()

	var target_name := interactions.describe_target()
	emote.visible = target_name != ""
	emote.position.y = -34 - (int(seconds_alive / 0.3) % 2)
	if Input.is_action_just_pressed("action_a"):
		interactions.press("a")
	elif Input.is_action_just_pressed("action_b"):
		interactions.press("b")
	process_companion(delta)


func advance_time(delta: float) -> void:
	save.play_seconds += delta
	save.clock.advance(delta)
	var minutes := delta / DayClock.REAL_SECONDS_PER_GAME_MINUTE
	save.meters.tick(minutes, player.is_walking)
	if save.clock.day() != day_seen:
		on_new_day()
	if save.clock.hour() != last_hour_seen:
		last_hour_seen = save.clock.hour()
		on_new_hour()
	if save.meters.is_dead() and mode == Mode.PLAY:
		collapse()
		return
	check_meter_hints()


func on_new_hour() -> void:
	douse_fires_in_rain()
	refresh_thing_looks()
	weather_overlay.weather = save.clock.weather() if not WorldMaps.map_data(map_id)["is_dark"] else "clear"
	interactions.wear_torch_in_darkness()
	if save.clock.hour() == DayClock.DUSK_HOUR:
		hint_once("first_dusk", ["THE SUN IS GOING DOWN.", "A FIRE WOULD KEEP THE DARK BACK.", "SLEEP BY IT WHEN YOU ARE TIRED."])


func on_new_day() -> void:
	day_seen = save.clock.day()
	var rotted := save.inventory.age_one_day()
	if not rotted.is_empty():
		toast("SOME FOOD WENT BAD.")
	Farming.new_day(save, self)
	regrow_things()
	if save.clock.season() != season_seen:
		season_seen = save.clock.season()
		ground.tile_set = make_ground_tile_set(season_seen)
		floors.tile_set = ground.tile_set
		apply_season_to_things()
		show_season_card()
	refresh_thing_looks()


## Picked and chopped things come back on their regrow day, even if you
## never left the map.
func regrow_things() -> void:
	var today := save.clock.day()
	for cell in save.cells_with(map_id, "gone"):
		var regrow_day := int(save.state_at(map_id, cell)["gone"])
		if regrow_day == 0 or today < regrow_day or things_by_cell.has(cell):
			continue
		save.set_state(map_id, cell, "gone", null)
		var kind := WorldMaps.thing_at(map_id, cell)
		if kind != "":
			add_thing(kind, cell).apply_season(save.clock.season())


## Rain puts out any fire without a roof over it.
func douse_fires_in_rain() -> void:
	if not save.clock.is_raining() or WorldMaps.map_data(map_id)["is_dark"]:
		return
	var doused := false
	for cell in things_by_cell:
		if things_by_cell[cell].kind == "campfire" and is_fire_lit(cell) and not roofs_by_cell.has(cell):
			save.set_state(map_id, cell, "burns_until", save.clock.total_minutes)
			doused = true
	if doused:
		toast("THE RAIN PUT OUT A FIRE.")
		hint_once("rain_fire", ["THE RAIN HISSES ON THE EMBERS.", "A ROOF OVER A FIRE KEEPS IT", "BURNING IN BAD WEATHER."])


func show_season_card() -> void:
	var card := SeasonCard.new()
	card.season = save.clock.season()
	card.year = save.clock.year()
	hud_layer.add_child(card)
	Sound.play("season")


func check_meter_hints() -> void:
	var meters := save.meters
	if meters.water < 30:
		hint_once("thirsty", ["YOUR THROAT IS DRY.", "THE RIVER IS FRESH. SEA WATER", "IS NOT. OPEN A COCONUT?"])
	elif meters.hunger < 30:
		hint_once("hungry", ["YOUR STOMACH GROWLS.", "FRUIT, FISH, BERRIES...", "COOKED FOOD FILLS YOU MORE."])
	elif meters.fatigue < 20:
		hint_once("tired", ["YOUR LEGS ARE HEAVY.", "SLEEP SOON. BY A FIRE AT NIGHT,", "OR IN A BED."])


func open_menu() -> void:
	set_mode(Mode.MENU)
	pause_menu.open()
	Sound.play("menu_open")


func open_settings() -> void:
	pause_menu.visible = false
	settings_menu.open()


func process_companion(delta: float) -> void:
	if not save.companion.get("active", false):
		return
	companion_find_timer -= delta
	if companion_find_timer > 0.0:
		return
	companion_find_timer = SECONDS_BETWEEN_COMPANION_FINDS
	const FINDS := ["stick", "fibre", "berries", "stone", "flint", "shell", "vine", "fruit", "mushroom"]
	var found: String = FINDS[randi() % FINDS.size()]
	if map_id == "cave":
		found = "copper_ore" if randf() < 0.3 else "stone"
	give_item(found)
	toast("BO FOUND %s!" % ItemCatalog.display_name(found))
	Sound.play("companion")


# --- Night, roofs and the map -------------------------------------------------

func update_night() -> void:
	var darkness := 0.0
	if WorldMaps.map_data(map_id)["is_dark"]:
		darkness = 1.0
	else:
		darkness = NightOverlay.DARKNESS_FOR_STEP[save.clock.darkness_step()]
		if save.clock.weather() == "storm" and darkness < 0.3:
			darkness = 0.3
	var lights := []
	var canvas := get_viewport().get_canvas_transform()
	if darkness > 0.0:
		for cell in things_by_cell:
			var thing: WorldThing = things_by_cell[cell]
			var radius := ThingCatalog.light_radius(thing.sprite_name)
			if radius > 0 and (thing.kind != "campfire" or is_fire_lit(cell)):
				var screen_position := canvas * (thing.position - Vector2(0, 8))
				if Rect2(-100, -100, 456, 344).has_point(screen_position):
					lights.append(Vector3(screen_position.x, screen_position.y, radius))
		var player_screen := canvas * (player.position - Vector2(0, 8))
		var torch_radius := 60 if interactions.is_holding_light() else 14
		lights.append(Vector3(player_screen.x, player_screen.y, torch_radius))
	night_overlay.show_darkness(darkness, lights)


func is_fire_lit(cell: Vector2i) -> bool:
	return save.clock.total_minutes < float(save.state_at(map_id, cell).get("burns_until", 0))


## Roofs hide while you stand under them, like walking into a house.
func update_roof_visibility() -> void:
	if roofs_by_cell.is_empty():
		return
	var is_inside := roofs_by_cell.has(player.cell())
	for cell in roofs_by_cell:
		roofs_by_cell[cell].visible = not is_inside


func is_player_sheltered() -> bool:
	return roofs_by_cell.has(player.cell())


func update_visited_screen() -> void:
	var cell := player.cell()
	var key := "%d,%d" % [cell.x / SCREEN_SIZE_IN_CELLS.x, cell.y / SCREEN_SIZE_IN_CELLS.y]
	if not visited_screens.has(key):
		visited_screens[key] = true
		save.flags["visited_%s" % map_id] = visited_screens


# --- Doors, rooms and the raft --------------------------------------------------

func check_doors() -> void:
	var doors: Dictionary = WorldMaps.map_data(map_id)["doors"]
	var cell := Vector2i(floori(player.exact_position.x / TILE_SIZE), floori((player.exact_position.y - 1) / TILE_SIZE))
	if doors.has(cell):
		var door: Dictionary = doors[cell]
		go_through_door(door["map"], door["arrive"], door["facing"])


func go_through_door(target_map: String, arrive_cell: Vector2i, facing: Vector2i) -> void:
	set_mode(Mode.CUTSCENE)
	Sound.play("door")
	await ScreenFader.fade_out()
	load_map(target_map, Vector2(arrive_cell.x * TILE_SIZE + 8, arrive_cell.y * TILE_SIZE + 14))
	player.face_towards(Vector2(facing))
	Sound.play_music(map_music())
	await ScreenFader.fade_in()
	set_mode(Mode.PLAY)
	if map_id == "cave":
		if not interactions.is_holding_light():
			hint_once("dark_cave", ["IT IS PITCH BLACK IN HERE.", "PUT A TORCH ON A OR B."])


func check_room_change() -> void:
	if not is_room_camera():
		return
	var room := room_of(player.exact_position)
	if room == current_room:
		return
	var direction := room - current_room
	current_room = room
	set_mode(Mode.ROOM_SLIDE)
	var slide := create_tween()
	slide.tween_property(camera, "position", room_centre(room), ROOM_SLIDE_SECONDS)
	slide.parallel().tween_method(func(progress: float) -> void:
		player.place_at(player.exact_position + Vector2(direction) * 0.4), 0.0, 1.0, ROOM_SLIDE_SECONDS)
	slide.tween_callback(func() -> void: set_mode(Mode.PLAY))


func check_raft_landing() -> void:
	if not save.flag("on_raft"):
		return
	var ground_here := ground_name_at(player.cell())
	if not WATER_GROUND.has(ground_here):
		save.set_flag("on_raft", false)
		player.sprite.offset = Vector2(-8, -16)
		toast("YOU STEP ASHORE.")
		if things_by_cell.has(player.cell()):
			return
		var behind := player.cell() - player.facing
		if WATER_GROUND.has(ground_name_at(behind)) and not things_by_cell.has(behind):
			save.set_state(map_id, behind, "piece", "raft")
			add_thing("raft", behind)


# --- Fishing ------------------------------------------------------------------

func start_fishing(cell: Vector2i) -> void:
	fishing_cell = cell
	fishing_timer = randf_range(1.5, 4.5)
	fishing_bite_window = 0.0
	set_mode(Mode.FISHING)
	player.swing("fishing_rod")
	toast("YOU CAST THE LINE...")
	Sound.play("splash")


func process_fishing(delta: float) -> void:
	player.walk(Vector2.ZERO, delta)
	player.swing_timer = 0.2
	player.swing_sprite.visible = true
	if fishing_timer > 0.0:
		fishing_timer -= delta
		emote.visible = false
		if fishing_timer <= 0.0:
			fishing_bite_window = 0.7
			Sound.play("bite")
		elif Input.is_action_just_pressed("action_a") or Input.is_action_just_pressed("action_b"):
			end_fishing("TOO SOON. THE FISH SWAM OFF.")
		return
	emote.visible = true
	fishing_bite_window -= delta
	if Input.is_action_just_pressed("action_a") or Input.is_action_just_pressed("action_b"):
		var catch_id := "raw_fish"
		var roll := randf()
		if ground_name_at(fishing_cell) != "river":
			if roll < 0.08:
				catch_id = "pearl"
			elif roll < 0.18:
				catch_id = "shell"
			elif roll < 0.25:
				catch_id = "driftwood"
		save.inventory.wear_tool("fishing_rod")
		end_fishing("")
		interactions.show_got_item(catch_id, 1)
	elif fishing_bite_window <= 0.0:
		end_fishing("IT GOT AWAY.")


func end_fishing(line: String) -> void:
	emote.visible = false
	player.swing_sprite.visible = false
	set_mode(Mode.PLAY)
	if line != "":
		toast(line)


# --- Items in and out -------------------------------------------------------------

## Puts items in the bag; whatever does not fit lands at the castaway's feet.
func give_item(item_id: String, count := 1) -> void:
	var leftover := save.inventory.add(item_id, count)
	if leftover > 0:
		drop_items_at(player.cell(), [{"id": item_id, "count": leftover}])
		toast("BAG FULL. DROPPED %s." % ItemCatalog.display_name(item_id))


func drop_items_at(cell: Vector2i, items: Array) -> void:
	var target := free_cell_near(cell)
	var existing: Array = save.state_at(map_id, target).get("items", [])
	existing.append_array(items)
	save.set_state(map_id, target, "items", existing)
	add_dropped_thing(target)


func free_cell_near(cell: Vector2i) -> Vector2i:
	for radius in 4:
		for offset_y in range(-radius, radius + 1):
			for offset_x in range(-radius, radius + 1):
				var candidate := cell + Vector2i(offset_x, offset_y)
				var holds_items: bool = things_by_cell.has(candidate) and things_by_cell[candidate].kind == "dropped"
				if holds_items or (not things_by_cell.has(candidate) and not is_cell_blocked_ground(candidate)):
					return candidate
	return cell


func on_menu_use_item(item_id: String) -> void:
	pause_menu.close()
	interactions.use_alone(item_id)


func on_menu_drop(slot_index: int) -> void:
	var slot: Dictionary = save.inventory.slots[slot_index]
	if slot.is_empty():
		return
	var dropped := slot.duplicate()
	save.inventory.slots[slot_index] = {}
	save.inventory.forget_missing_equipment()
	drop_items_at(player.cell_in_front() if not is_cell_blocked(player.cell_in_front()) else player.cell(), [{"id": dropped["id"], "count": dropped["count"]}])
	pause_menu.message = "DROPPED %s." % ItemCatalog.display_name(dropped["id"])


func on_menu_merge(slot_indices: Array) -> void:
	var result := Merging.merge(save, slot_indices)
	pause_menu.message = result["message"]
	if result.get("leftover", 0) > 0:
		drop_items_at(player.cell(), [{"id": result["result"], "count": result["leftover"]}])
	Sound.play("merge" if result["success"] else "merge_fail")


func on_quit_requested(should_save: bool) -> void:
	if should_save:
		save.player_position = player.exact_position
		Game.save_game()
	set_mode(Mode.CUTSCENE)
	pause_menu.visible = false
	Sound.stop_music()
	ScreenFader.change_scene(TITLE_SCENE)


# --- Sleep and collapse -----------------------------------------------------------

func sleep(is_in_bed: bool) -> void:
	set_mode(Mode.SLEEPING)
	player.set_pose("sleep")
	Sound.play("sleep")
	Sound.stop_music()
	await get_tree().create_timer(0.6).timeout
	await ScreenFader.fade_out(true)
	var sheltered := is_in_bed and is_player_sheltered()
	var comfort := Building.comfort_around(self, player.cell()) if sheltered else 0
	save.meters.sleep(sheltered or is_in_bed, comfort)
	save.clock.sleep_until_morning()
	save.home = {"map": map_id, "x": player.cell().x, "y": player.cell().y}
	save.player_position = player.exact_position
	if save.clock.day() != day_seen:
		on_new_day()
	last_hour_seen = -1
	Game.save_game()
	await get_tree().create_timer(0.8).timeout
	player.set_pose("normal")
	player.face_towards(Vector2.DOWN)
	await ScreenFader.fade_in()
	Sound.play_music(map_music())
	set_mode(Mode.PLAY)
	var morning_lines := ["DAY %d. %s." % [save.clock.day(), save.clock.weather_on(save.clock.day()).to_upper()], "THE GAME WAS SAVED."]
	if sheltered:
		morning_lines.insert(1, "YOU SLEPT WELL. RESTED! (%d COMFORT)" % comfort)
	say(morning_lines, func() -> void: Endings.check_stay_offer(self))


## Health hit zero: drop the bag where you fell (Valheim style) and wake up
## at your last bed the next morning.
func collapse() -> void:
	set_mode(Mode.SLEEPING)
	Sound.play("collapse")
	Sound.stop_music()
	player.set_pose("sleep")
	await get_tree().create_timer(1.0).timeout
	var lost_items := []
	for slot_index in save.inventory.slots.size():
		var slot: Dictionary = save.inventory.slots[slot_index]
		if slot.is_empty():
			continue
		if slot["id"] == save.inventory.equipped_a or slot["id"] == save.inventory.equipped_b:
			continue
		lost_items.append({"id": slot["id"], "count": slot["count"]})
		save.inventory.slots[slot_index] = {}
	if not lost_items.is_empty():
		drop_items_at(player.cell(), lost_items)
		save.set_flag("bag_lost_on_%s" % map_id)
	await ScreenFader.fade_out(true)
	save.clock.sleep_until_morning()
	save.meters.load_data({"health": 50.0, "hunger": 50.0, "water": 50.0, "fatigue": 70.0})
	var wake_map := "overworld"
	var wake_cell := WorldMaps.start_cell("overworld")
	if not save.home.is_empty():
		wake_map = save.home["map"]
		wake_cell = Vector2i(int(save.home["x"]), int(save.home["y"]))
	if save.clock.day() != day_seen:
		on_new_day()
	load_map(wake_map, Vector2(wake_cell.x * TILE_SIZE + 8, wake_cell.y * TILE_SIZE + 14))
	Game.save_game()
	await ScreenFader.fade_in()
	Sound.play_music(map_music())
	set_mode(Mode.PLAY)
	say(["YOU WAKE UP, ACHING ALL OVER.", "YOUR BAG IS WHERE YOU FELL." if not lost_items.is_empty() else "YOU LOST A WHOLE DAY."])


func on_player_hurt(amount: int, from_position: Vector2) -> void:
	if player.is_hurt() or mode != Mode.PLAY:
		return
	save.meters.hurt(amount)
	player.take_hit(from_position)
	Sound.play("hurt")
	toast("OUCH! HEALTH -%d" % amount)


# --- Intro --------------------------------------------------------------------------

func play_intro() -> void:
	set_mode(Mode.CUTSCENE)
	player.set_pose("sleep")
	await get_tree().create_timer(1.2).timeout
	say(["...", "THE STORM. THE BOAT...", "WHERE... AM I?"], func() -> void:
		player.set_pose("normal")
		player.face_towards(Vector2.DOWN)
		save.set_flag("intro_done")
		say(["THE CRATES MAY HAVE WASHED UP", "FROM THE WRECK. PRESS A TO", "LOOK AT THINGS. START OPENS", "YOUR BAG."]))


# --- Collision ----------------------------------------------------------------------

func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / TILE_SIZE), floori(point.y / TILE_SIZE))


func ground_name_at(cell: Vector2i) -> String:
	if not WorldMaps.is_inside(map_id, cell):
		return "water"
	return WorldMaps.ground_at(map_id, cell)


func is_cell_blocked_ground(cell: Vector2i) -> bool:
	if not WorldMaps.is_inside(map_id, cell):
		return true
	return BLOCKING_GROUND.has(ground_name_at(cell))


func is_cell_blocked(cell: Vector2i) -> bool:
	if save.flag("on_raft"):
		if not WorldMaps.is_inside(map_id, cell):
			return true
		var ground_here := ground_name_at(cell)
		if not WATER_GROUND.has(ground_here) and ground_here != "sand" and ground_here != "pale_sand":
			return true
	elif is_cell_blocked_ground(cell):
		return true
	if things_by_cell.has(cell):
		var thing: WorldThing = things_by_cell[cell]
		if thing.kind == "door":
			return not save.state_at(map_id, cell).get("open", false)
		return ThingCatalog.blocks(thing.kind)
	return false


func is_area_blocked(area: Rect2) -> bool:
	var corners := [area.position, Vector2(area.end.x - 0.01, area.position.y), Vector2(area.position.x, area.end.y - 0.01), area.end - Vector2(0.01, 0.01)]
	for corner in corners:
		if is_cell_blocked(cell_at(corner)):
			return true
	return false


func is_area_blocked_for_creature(area: Rect2) -> bool:
	var corners := [area.position, Vector2(area.end.x - 0.01, area.position.y), Vector2(area.position.x, area.end.y - 0.01), area.end - Vector2(0.01, 0.01)]
	for corner in corners:
		var cell := cell_at(corner)
		if is_cell_blocked_ground(cell):
			return true
		if things_by_cell.has(cell) and ThingCatalog.blocks(things_by_cell[cell].kind):
			return true
	return false
