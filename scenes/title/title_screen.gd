extends Node2D

## Title: the sea shimmers, the logo drops in and bounces, then PRESS START
## blinks. Pressing start blinks it fast, then whitens into the beach.

const BACKGROUND_FRAMES := [
	preload("res://art/backgrounds/title_background_1.png"),
	preload("res://art/backgrounds/title_background_2.png"),
]
const LOGO_TEXTURE := preload("res://art/sprites/logo.png")
const BEACH_SCENE := "res://scenes/island/island.tscn"
const LOGO_RESTING_Y := 14
const PROMPT_TEXT := "PRESS START"
const PROMPT_TOP := 112
const SEA_FRAME_SECONDS := 0.6
const PROMPT_ON_SECONDS := 0.6
const PROMPT_OFF_SECONDS := 0.3

enum Stage { LOGO_DROPPING, WAITING_FOR_START, STARTING }

var stage := Stage.LOGO_DROPPING
var background: Sprite2D
var logo: Sprite2D
var seconds_on_stage := 0.0
var sea_frame_timer := 0.0
var sea_frame_index := 0


func _ready() -> void:
	background = Sprite2D.new()
	background.texture = BACKGROUND_FRAMES[0]
	background.centered = false
	add_child(background)

	logo = Sprite2D.new()
	logo.texture = LOGO_TEXTURE
	logo.centered = false
	logo.position = Vector2((256 - LOGO_TEXTURE.get_width()) / 2, -LOGO_TEXTURE.get_height())
	add_child(logo)

	var drop := create_tween()
	drop.tween_property(logo, "position:y", LOGO_RESTING_Y, 0.9).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	drop.tween_callback(func() -> void: enter_stage(Stage.WAITING_FOR_START))


func _process(delta: float) -> void:
	seconds_on_stage += delta
	animate_sea(delta)
	# Keep the logo on whole pixels while it bounces.
	logo.position = logo.position.round()

	var start_pressed := Input.is_action_just_pressed("start") or Input.is_action_just_pressed("action_a")
	if start_pressed and stage == Stage.LOGO_DROPPING:
		skip_logo_drop()
	elif start_pressed and stage == Stage.WAITING_FOR_START:
		enter_stage(Stage.STARTING)
		get_tree().create_timer(0.6).timeout.connect(func() -> void: ScreenFader.change_scene(BEACH_SCENE))
	queue_redraw()


func skip_logo_drop() -> void:
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	logo.position.y = LOGO_RESTING_Y
	enter_stage(Stage.WAITING_FOR_START)


func enter_stage(new_stage: Stage) -> void:
	stage = new_stage
	seconds_on_stage = 0.0


func animate_sea(delta: float) -> void:
	sea_frame_timer += delta
	if sea_frame_timer >= SEA_FRAME_SECONDS:
		sea_frame_timer = 0.0
		sea_frame_index = 1 - sea_frame_index
		background.texture = BACKGROUND_FRAMES[sea_frame_index]


func _draw() -> void:
	if is_prompt_visible():
		var left := (256 - PixelFont.text_width(PROMPT_TEXT)) / 2
		PixelFont.draw_outlined_text(self, PROMPT_TEXT, Vector2(left, PROMPT_TOP), Palettes.sprite_color("ink", 1), Palettes.sprite_color("ink", 3))
	var credit := "A HOMAGE TO 1999"
	PixelFont.draw_text(self, credit, Vector2((256 - PixelFont.text_width(credit)) / 2, 132), Palettes.sprite_color("ink", 1))


func is_prompt_visible() -> bool:
	if stage == Stage.LOGO_DROPPING:
		return false
	if stage == Stage.STARTING:
		return int(seconds_on_stage / 0.06) % 2 == 0
	var blink_length := PROMPT_ON_SECONDS + PROMPT_OFF_SECONDS
	return fmod(seconds_on_stage, blink_length) < PROMPT_ON_SECONDS
