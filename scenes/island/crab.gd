class_name Crab
extends Node2D

## Scuttles sideways along the sand, back and forth, clicking its claws.

const TEXTURE := preload("res://art/sprites/crab.png")
const SPEED := 14.0
const WANDER_DISTANCE := 20.0
const FRAME_SECONDS := 0.2
const PAUSE_SECONDS := 1.2

var home_x := 0.0
var direction := 1.0
var exact_x := 0.0
var frame_timer := 0.0
var pause_timer := 0.0
var sprite: Sprite2D


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.hframes = 2
	sprite.centered = false
	sprite.offset = Vector2(-8, -16)
	add_child(sprite)
	home_x = position.x
	exact_x = position.x


func _process(delta: float) -> void:
	frame_timer += delta
	if frame_timer >= FRAME_SECONDS:
		frame_timer = 0.0
		sprite.frame = 1 - sprite.frame

	if pause_timer > 0.0:
		pause_timer -= delta
		return
	exact_x += direction * SPEED * delta
	if absf(exact_x - home_x) >= WANDER_DISTANCE:
		exact_x = home_x + direction * WANDER_DISTANCE
		direction = -direction
		pause_timer = PAUSE_SECONDS
	position.x = roundf(exact_x)


func interaction_area() -> Rect2:
	return Rect2(position - Vector2(8, 16), Vector2(16, 16))
