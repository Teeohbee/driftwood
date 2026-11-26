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

const TEXTURE_FOR_FACING := {
	"down": preload("res://art/sprites/hero_down.png"),
	"up": preload("res://art/sprites/hero_up.png"),
	"side": preload("res://art/sprites/hero_side.png"),
}

## Called with a feet rectangle; returns true if the island blocks it.
var is_area_blocked: Callable
var exact_position := Vector2.ZERO
var facing := Vector2i.DOWN
var is_walking := false
var walk_frame_timer := 0.0
var sprite: Sprite2D
## Skin, shirt and hair choices from the look picker.
var look := CastawayLook.default_look()


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-8, -16)
	sprite.hframes = 2
	sprite.material = CastawayLook.make_material(look)
	add_child(sprite)
	exact_position = position
	show_facing()


func walk(input_direction: Vector2, delta: float) -> void:
	is_walking = input_direction != Vector2.ZERO
	if not is_walking:
		sprite.frame = 0
		return

	face_towards(input_direction)
	var step := input_direction.normalized() * WALK_SPEED * delta
	# Each axis moves separately so the castaway slides along walls.
	try_move(Vector2(step.x, 0))
	try_move(Vector2(0, step.y))
	position = exact_position.round()
	animate_walk(delta)


func try_move(step: Vector2) -> void:
	var destination := exact_position + step
	if not is_area_blocked.call(feet_rectangle_at(destination)):
		exact_position = destination


func feet_rectangle_at(feet_position: Vector2) -> Rect2:
	return Rect2(feet_position - Vector2(FEET_SIZE.x / 2, FEET_SIZE.y), FEET_SIZE)


func face_towards(input_direction: Vector2) -> void:
	if absf(input_direction.x) > absf(input_direction.y):
		facing = Vector2i.RIGHT if input_direction.x > 0 else Vector2i.LEFT
	else:
		facing = Vector2i.DOWN if input_direction.y > 0 else Vector2i.UP
	show_facing()


func show_facing() -> void:
	if facing == Vector2i.UP:
		sprite.texture = TEXTURE_FOR_FACING["up"]
	elif facing == Vector2i.DOWN:
		sprite.texture = TEXTURE_FOR_FACING["down"]
	else:
		sprite.texture = TEXTURE_FOR_FACING["side"]
	sprite.flip_h = facing == Vector2i.LEFT


func animate_walk(delta: float) -> void:
	walk_frame_timer += delta
	if walk_frame_timer >= WALK_FRAME_SECONDS:
		walk_frame_timer = 0.0
		sprite.frame = 1 - sprite.frame


## The point just in front of the castaway's feet, used to find what they face.
func point_in_front() -> Vector2:
	return exact_position + Vector2(facing) * 10 + Vector2(0, -4)
