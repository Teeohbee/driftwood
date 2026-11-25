extends Node2D

## The look-book beach. Builds itself from art_source/island_layout.gd:
## ground tiles, y-sorted objects, the castaway, a crab, the status bar and
## the dialogue box. Walk about, press A on things.

const TILE_SIZE := 16
const GROUND_ATLAS := preload("res://art/backgrounds/ground_atlas.png")
const EMOTE_TEXTURE := preload("res://art/sprites/emote_alert.png")
const ANIMATION_FRAME_SECONDS := 0.5
const TITLE_SCENE := "res://scenes/title/title_screen.tscn"

## What pressing A on each thing does. Lines are at most 32 characters.
const INTERACTIONS := {
	"fruit": {"lines": ["A RIPE RED FRUIT.", "YOU EAT IT. HUNGER +15."], "hunger": 15, "removes": true},
	"stick": {"lines": ["YOU FOUND A STICK.", "IT MIGHT MERGE WITH SOMETHING."], "holds": "STICK", "removes": true},
	"shell": {"lines": ["A SPIRAL SHELL.", "IT HUMS WHEN THE WIND BLOWS."], "holds": "SHELL", "removes": true},
	"driftwood": {"lines": ["A LOG OF DRIFTWOOD.", "GOOD FOR A FIRE, OR A RAFT."], "holds": "DRIFTWOOD", "removes": true},
	"bottle": {"lines": ["A NOTE IN A BOTTLE.", "'DAY 41. THE TIDE HIDES IT...'", "THE REST HAS WASHED AWAY."]},
	"campfire": {"lines": ["THE FIRE CRACKLES.", "YOU REST A MOMENT. FATIGUE +10."], "rest": 10},
	"crab": {"lines": ["THE CRAB CLICKS ITS CLAWS.", "IT DOES NOT WANT TO BE DINNER."]},
	"bush": {"lines": ["A THICK BUSH.", "NOTHING IN IT. YET."]},
	"palm": {"lines": ["A TALL PALM.", "COCONUTS, TOO HIGH TO REACH."]},
}

var meters := SurvivalMeters.new()
var ground: TileMapLayer
var world_objects: Node2D
var player: Player
var crab: Crab
var emote: Sprite2D
var status_bar: StatusBar
var dialogue_box: DialogueBox
## Metatile -> {"name": String, "node": Node2D}
var objects_by_metatile := {}
var seconds_alive := 0.0


func _ready() -> void:
	build_ground()
	build_objects()
	build_player()
	build_interface()


# --- Building the beach -------------------------------------------------------

func build_ground() -> void:
	ground = TileMapLayer.new()
	ground.tile_set = make_ground_tile_set()
	add_child(ground)
	for row in IslandLayout.height_in_metatiles():
		for column in IslandLayout.width_in_metatiles():
			var tile_name := IslandLayout.ground_tile_at(column, row)
			var atlas_column := PixelArt.GROUND_TILE_ORDER.find(tile_name)
			ground.set_cell(Vector2i(column, row), 0, Vector2i(atlas_column, 0))


## One atlas source; a tile followed by its "_frame_2" becomes a 2-frame animation.
func make_ground_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = GROUND_ATLAS
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for atlas_column in PixelArt.GROUND_TILE_ORDER.size():
		var tile_name: String = PixelArt.GROUND_TILE_ORDER[atlas_column]
		if tile_name.ends_with("_frame_2"):
			continue
		var coordinates := Vector2i(atlas_column, 0)
		source.create_tile(coordinates)
		var next_index := atlas_column + 1
		var has_second_frame: bool = next_index < PixelArt.GROUND_TILE_ORDER.size() and PixelArt.GROUND_TILE_ORDER[next_index] == tile_name + "_frame_2"
		if has_second_frame:
			source.set_tile_animation_frames_count(coordinates, 2)
			source.set_tile_animation_frame_duration(coordinates, 0, ANIMATION_FRAME_SECONDS)
			source.set_tile_animation_frame_duration(coordinates, 1, ANIMATION_FRAME_SECONDS)
	tile_set.add_source(source, 0)
	return tile_set


func build_objects() -> void:
	world_objects = Node2D.new()
	world_objects.y_sort_enabled = true
	add_child(world_objects)
	for row in IslandLayout.height_in_metatiles():
		for column in IslandLayout.width_in_metatiles():
			var object_name := IslandLayout.object_at(column, row)
			if object_name == "":
				continue
			var metatile := Vector2i(column, row)
			var feet_position := Vector2(column * TILE_SIZE + 8, (row + 1) * TILE_SIZE)
			if object_name == "crab":
				crab = Crab.new()
				crab.position = feet_position
				world_objects.add_child(crab)
				continue
			var sprite := make_object_sprite(object_name)
			sprite.position = feet_position
			world_objects.add_child(sprite)
			objects_by_metatile[metatile] = {"name": object_name, "node": sprite}


func make_object_sprite(object_name: String) -> Sprite2D:
	var texture: Texture2D = load("res://art/sprites/%s.png" % object_name)
	var frame_count: int = PixelArt.SPRITES[object_name]["frames"].size()
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.hframes = frame_count
	sprite.centered = false
	sprite.offset = Vector2(-8, -texture.get_height())
	return sprite


func build_player() -> void:
	player = Player.new()
	var start := IslandLayout.player_start_metatile()
	player.position = Vector2(start.x * TILE_SIZE + 8, (start.y + 1) * TILE_SIZE - 2)
	player.is_area_blocked = is_area_blocked
	world_objects.add_child(player)

	var camera := Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = IslandLayout.width_in_metatiles() * TILE_SIZE
	# The status bar covers the bottom 16 pixels, so let the camera see past the map edge by that much.
	camera.limit_bottom = IslandLayout.height_in_metatiles() * TILE_SIZE + StatusBar.HEIGHT
	camera.offset = Vector2(0, StatusBar.HEIGHT / 2)
	player.add_child(camera)

	emote = Sprite2D.new()
	emote.texture = EMOTE_TEXTURE
	emote.centered = false
	emote.position = Vector2(-8, -34)
	emote.visible = false
	player.add_child(emote)


func build_interface() -> void:
	var interface_layer := CanvasLayer.new()
	add_child(interface_layer)
	status_bar = StatusBar.new()
	status_bar.meters = meters
	interface_layer.add_child(status_bar)
	dialogue_box = DialogueBox.new()
	dialogue_box.visible = false
	interface_layer.add_child(dialogue_box)


# --- Playing ------------------------------------------------------------------

func _process(delta: float) -> void:
	seconds_alive += delta
	animate_object_frames()

	if Input.is_action_just_pressed("start") and not dialogue_box.is_open:
		ScreenFader.change_scene(TITLE_SCENE)
		return

	if dialogue_box.is_open:
		player.walk(Vector2.ZERO, delta)
		emote.visible = false
		if Input.is_action_just_pressed("action_a"):
			dialogue_box.advance()
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.walk(input_direction, delta)
	meters.tick(delta, player.is_walking)

	var faced_thing := thing_in_front_of_player()
	emote.visible = faced_thing != ""
	emote.position.y = -34 - (int(seconds_alive / 0.3) % 2)
	if faced_thing != "" and Input.is_action_just_pressed("action_a"):
		interact_with(faced_thing)


func animate_object_frames() -> void:
	var frame_index := int(seconds_alive / 0.2) % 2
	for metatile in objects_by_metatile:
		var sprite: Sprite2D = objects_by_metatile[metatile]["node"]
		if sprite.hframes > 1:
			sprite.frame = frame_index


## Returns the name of whatever the castaway faces, or "" for nothing.
func thing_in_front_of_player() -> String:
	var point := player.point_in_front()
	if crab != null and crab.interaction_area().has_point(point):
		return "crab"
	var metatile := metatile_at(point)
	if objects_by_metatile.has(metatile):
		return objects_by_metatile[metatile]["name"]
	return ""


func interact_with(thing_name: String) -> void:
	var interaction: Dictionary = INTERACTIONS.get(thing_name, {})
	if interaction.is_empty():
		return
	if interaction.has("hunger"):
		meters.eat(interaction["hunger"])
	if interaction.has("rest"):
		meters.rest(interaction["rest"])
	if interaction.has("holds"):
		status_bar.held_item_name = interaction["holds"]
		status_bar.held_item_texture = load("res://art/sprites/%s.png" % thing_name)
	if interaction.get("removes", false):
		remove_object_at(metatile_at(player.point_in_front()))
	dialogue_box.show_lines(interaction["lines"])


func remove_object_at(metatile: Vector2i) -> void:
	if not objects_by_metatile.has(metatile):
		return
	objects_by_metatile[metatile]["node"].queue_free()
	objects_by_metatile.erase(metatile)


# --- Collision ----------------------------------------------------------------

func metatile_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / TILE_SIZE), floori(point.y / TILE_SIZE))


func is_area_blocked(area: Rect2) -> bool:
	var corners := [area.position, Vector2(area.end.x - 0.01, area.position.y), Vector2(area.position.x, area.end.y - 0.01), area.end - Vector2(0.01, 0.01)]
	for corner in corners:
		if is_metatile_blocked(metatile_at(corner)):
			return true
	return false


func is_metatile_blocked(metatile: Vector2i) -> bool:
	var is_outside_map := metatile.x < 0 or metatile.y < 0 or metatile.x >= IslandLayout.width_in_metatiles() or metatile.y >= IslandLayout.height_in_metatiles()
	if is_outside_map:
		return true
	if IslandLayout.BLOCKING_GROUND.has(IslandLayout.ground_tile_at(metatile.x, metatile.y)):
		return true
	if objects_by_metatile.has(metatile):
		return IslandLayout.BLOCKING_OBJECTS.has(objects_by_metatile[metatile]["name"])
	return false
