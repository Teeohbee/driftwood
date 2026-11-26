class_name Player
extends Node2D

## The castaway. Position is the middle of the feet, so y-sorting puts them
## behind a palm when they walk above its trunk.
##
## Moves in 8 directions like Link's Awakening, faces in 4, and lands on whole
## pixels every frame so nothing shimmers.

const WALK_SPEED := 56.0
const WALK_FRAME_SECONDS := 0.16
const FEET_SIZE := Vector2(10, 5)
const SWING_SECONDS := 0.18
const HURT_SECONDS := 0.8

const TEXTURE_FOR_FACING := {
	"down": preload("res://art/sprites/hero_down.png"),
	"up": preload("res://art/sprites/hero_up.png"),
	"side": preload("res://art/sprites/hero_side.png"),
}
const HOLD_TEXTURE := preload("res://art/sprites/hero_hold.png")
const SLEEP_TEXTURE := preload("res://art/sprites/hero_sleep.png")

## Called with a feet rectangle; returns true if the island blocks it.
var is_area_blocked: Callable
var exact_position := Vector2.ZERO
var facing := Vector2i.DOWN
var is_walking := false
var walk_frame_timer := 0.0
var sprite: Sprite2D
var swing_sprite: Sprite2D
var held_sprite: Sprite2D
var raft_sprite: Sprite2D
var swing_timer := 0.0
var hurt_timer := 0.0
var knockback := Vector2.ZERO
var speed_factor := 1.0
var pose := "normal"
## Skin, shirt and hair choices from the look picker.
var look := CastawayLook.default_look()


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-8, -16)
	sprite.hframes = 2
	sprite.material = CastawayLook.make_material(look)
	add_child(sprite)
	swing_sprite = Sprite2D.new()
	swing_sprite.visible = false
	add_child(swing_sprite)
	raft_sprite = Sprite2D.new()
	raft_sprite.texture = preload("res://art/sprites/raft.png")
	raft_sprite.position = Vector2(0, -2)
	raft_sprite.z_index = -1
	raft_sprite.visible = false
	add_child(raft_sprite)
	held_sprite = Sprite2D.new()
	held_sprite.visible = false
	held_sprite.position = Vector2(0, -26)
	add_child(held_sprite)
	exact_position = position
	show_facing()


func set_look(new_look: Dictionary) -> void:
	look = new_look
	if sprite != null:
		sprite.material = CastawayLook.make_material(look)


func _process(delta: float) -> void:
	if swing_timer > 0.0:
		swing_timer -= delta
		if swing_timer <= 0.0:
			swing_sprite.visible = false
	if hurt_timer > 0.0:
		hurt_timer -= delta
		sprite.visible = int(hurt_timer / 0.08) % 2 == 0 or hurt_timer <= 0.0
		if knockback != Vector2.ZERO:
			try_move(Vector2(knockback.x * delta, 0))
			try_move(Vector2(0, knockback.y * delta))
			knockback = knockback.move_toward(Vector2.ZERO, 400 * delta)
			position = exact_position.round()


func walk(input_direction: Vector2, delta: float) -> void:
	is_walking = input_direction != Vector2.ZERO and pose == "normal"
	if not is_walking:
		if pose == "normal":
			sprite.frame = 0
		return

	face_towards(input_direction)
	var step := input_direction.normalized() * WALK_SPEED * speed_factor * delta
	# Each axis moves separately so the castaway slides along walls.
	try_move(Vector2(step.x, 0))
	try_move(Vector2(0, step.y))
	position = exact_position.round()
	animate_walk(delta)


func try_move(step: Vector2) -> void:
	var destination := exact_position + step
	if not is_area_blocked.call(feet_rectangle_at(destination)):
		exact_position = destination


func place_at(feet_position: Vector2) -> void:
	exact_position = feet_position
	position = feet_position.round()


func feet_rectangle_at(feet_position: Vector2) -> Rect2:
	return Rect2(feet_position - Vector2(FEET_SIZE.x / 2, FEET_SIZE.y), FEET_SIZE)


func face_towards(input_direction: Vector2) -> void:
	if absf(input_direction.x) > absf(input_direction.y):
		facing = Vector2i.RIGHT if input_direction.x > 0 else Vector2i.LEFT
	else:
		facing = Vector2i.DOWN if input_direction.y > 0 else Vector2i.UP
	show_facing()


func show_facing() -> void:
	if pose != "normal":
		return
	sprite.hframes = 2
	sprite.offset = Vector2(-8, -16)
	if facing == Vector2i.UP:
		sprite.texture = TEXTURE_FOR_FACING["up"]
	elif facing == Vector2i.DOWN:
		sprite.texture = TEXTURE_FOR_FACING["down"]
	else:
		sprite.texture = TEXTURE_FOR_FACING["side"]
	sprite.flip_h = facing == Vector2i.LEFT


## "normal", "hold" (item over head, Link's Awakening style) or "sleep".
func set_pose(new_pose: String, held_item_id := "") -> void:
	pose = new_pose
	held_sprite.visible = false
	if pose == "hold":
		sprite.texture = HOLD_TEXTURE
		sprite.hframes = 1
		sprite.frame = 0
		sprite.flip_h = false
		if held_item_id != "":
			held_sprite.texture = ItemCatalog.texture(held_item_id)
			held_sprite.visible = true
	elif pose == "sleep":
		sprite.texture = SLEEP_TEXTURE
		sprite.hframes = 1
		sprite.frame = 0
		sprite.offset = Vector2(-8, -12)
	else:
		show_facing()


func animate_walk(delta: float) -> void:
	walk_frame_timer += delta
	if walk_frame_timer >= WALK_FRAME_SECONDS:
		walk_frame_timer = 0.0
		sprite.frame = 1 - sprite.frame


## Shows the item poking out in front for a moment.
func swing(item_id: String) -> void:
	if item_id == "":
		return
	swing_sprite.texture = ItemCatalog.texture(item_id)
	swing_sprite.visible = true
	swing_sprite.position = Vector2(facing) * 12 + Vector2(0, -8)
	swing_sprite.flip_h = facing == Vector2i.LEFT
	swing_sprite.rotation = 0.0 if facing.y == 0 else (PI / 2 if facing == Vector2i.DOWN else -PI / 2)
	swing_sprite.z_index = -1 if facing == Vector2i.UP else 1
	swing_timer = SWING_SECONDS


func is_hurt() -> bool:
	return hurt_timer > 0.0


func take_hit(from_position: Vector2) -> void:
	hurt_timer = HURT_SECONDS
	knockback = (exact_position - from_position).normalized() * 120.0


## The point just in front of the castaway's feet, used to find what they face.
func point_in_front() -> Vector2:
	if facing == Vector2i.UP:
		return exact_position + Vector2(0, -16)
	if facing == Vector2i.DOWN:
		return exact_position + Vector2(0, 6)
	return exact_position + Vector2(facing) * 10 + Vector2(0, -4)


func cell_in_front() -> Vector2i:
	var point := point_in_front()
	return Vector2i(floori(point.x / 16), floori(point.y / 16))


func cell() -> Vector2i:
	return Vector2i(floori(exact_position.x / 16), floori((exact_position.y - 2) / 16))
