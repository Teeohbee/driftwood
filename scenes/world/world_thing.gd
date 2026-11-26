class_name WorldThing
extends Node2D

## One thing standing on one metatile: a palm, a rock, a campfire, a wall.
## Position is the bottom middle of its metatile, so y-sorting works.

const FLASH_SECONDS := 0.24

var kind := ""
var cell := Vector2i.ZERO
var sprite: Sprite2D
var overlay: Sprite2D
var hits_taken := 0
var animation_seconds := 0.0
var flash_seconds := 0.0
## Which sprite is showing, so a campfire can swap between lit and out.
var sprite_name := ""


func setup(thing_kind: String, thing_cell: Vector2i) -> void:
	kind = thing_kind
	cell = thing_cell
	name = "%s_%d_%d" % [kind, cell.x, cell.y]
	position = Vector2(cell.x * 16 + 8, (cell.y + 1) * 16)
	sprite = Sprite2D.new()
	sprite.centered = false
	add_child(sprite)
	show_sprite(ThingCatalog.sprite_for(kind))


func show_sprite(new_sprite_name: String) -> void:
	sprite_name = new_sprite_name
	if new_sprite_name == "":
		sprite.texture = null
		return
	var texture: Texture2D = load("res://art/sprites/%s.png" % new_sprite_name)
	var frame_count: int = PixelArt.sprite(new_sprite_name)["frames"].size()
	sprite.texture = texture
	sprite.hframes = frame_count
	sprite.frame = 0
	var frame_width := texture.get_width() / frame_count
	sprite.offset = Vector2(-frame_width / 2, -texture.get_height())


func show_overlay(overlay_sprite_name: String) -> void:
	if overlay_sprite_name == "":
		if overlay != null:
			overlay.visible = false
		return
	if overlay == null:
		overlay = Sprite2D.new()
		overlay.centered = false
		add_child(overlay)
	var texture: Texture2D = load("res://art/sprites/%s.png" % overlay_sprite_name)
	overlay.texture = texture
	overlay.offset = Vector2(-texture.get_width() / 2, -texture.get_height())
	overlay.visible = true


## Seasonal leaves: palette-swap the foliage colours.
func apply_season(season: String) -> void:
	var sprite_info: Dictionary = PixelArt.all_sprites().get(sprite_name, {})
	var uses_foliage: bool = sprite_info.get("palette", "") == "foliage" or sprite_info.get("palette_bands", []).has("foliage")
	var overrides: Dictionary = Palettes.SEASON_SPRITE_OVERRIDES.get(season, {})
	if not uses_foliage or not overrides.has("foliage"):
		sprite.material = null
		return
	sprite.material = SeasonSwap.material_for(season)


func _process(delta: float) -> void:
	if sprite.hframes > 1:
		animation_seconds += delta
		sprite.frame = int(animation_seconds / 0.25) % sprite.hframes
	if flash_seconds > 0.0:
		flash_seconds -= delta
		sprite.visible = int(flash_seconds / 0.06) % 2 == 0 or flash_seconds <= 0.0


## A tool hit: the thing shakes by blinking.
func flash() -> void:
	flash_seconds = FLASH_SECONDS
