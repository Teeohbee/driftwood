extends Node2D

## An ending: a little scene over the sunset sea, the story told in a few
## lines, then the credits roll. A returns to the title.

const TITLE_SCENE := "res://scenes/title/title_screen.tscn"
const BACKGROUND_FRAMES := [
	preload("res://art/backgrounds/title_background_1.png"),
	preload("res://art/backgrounds/title_background_2.png"),
]

const STORIES := {
	"signal": {"title": "THE SIGNAL", "lines": ["THE BEACON BURNED ALL NIGHT.", "AT DAWN, A FISHING BOAT", "DROPPED ANCHOR OFF THE BEACH.", "YOU WAVED UNTIL YOUR ARMS HURT."]},
	"radio": {"title": "THE VOICE", "lines": ["THE COASTGUARD CAME AT NOON,", "FOLLOWING THE RADIO'S CALL.", "WREN WAVED FROM THE ISLET", "AND WOULD NOT COME ALONG."]},
	"sail": {"title": "THE VOYAGE", "lines": ["THE SAIL FILLED. THE ISLAND", "SHRANK TO A GREEN DOT.", "THREE DAYS LATER, A HARBOUR.", "YOU KEPT ONE SHELL. ALWAYS."]},
	"stay": {"title": "HOME", "lines": ["SHIPS PASSED. YOU LET THEM.", "THE FIRE, THE GARDEN, THE SEA.", "SOME PLACES FIND YOU.", "THIS ONE DID."]},
}
const CREDITS := [
	"DRIFTWOOD", "", "A HOMAGE TO SURVIVAL KIDS", "(KONAMI, 1999)", "", "WITH LOVE FOR", "LINK'S AWAKENING", "HARVEST MOON", "VALHEIM", "",
	"MADE BY TOBY AND CLAUDE", "", "ART, MUSIC AND CODE", "WRITTEN AS TEXT", "IN GODOT", "", "THANK YOU FOR PLAYING",
]
const CREDIT_LINE_HEIGHT := 12
const CREDIT_SPEED := 14.0

enum Stage { SCENE, STORY, CREDITS, THE_END }

var ending_id := "signal"
var stage := Stage.SCENE
var seconds := 0.0
var dialogue_box: DialogueBox
var credits_offset := 0.0
var castaway: Sprite2D


func _ready() -> void:
	ending_id = Endings.pending_ending if Endings.pending_ending != "" else "signal"
	dialogue_box = DialogueBox.new()
	add_child(dialogue_box)
	dialogue_box.visible = false
	# The story sits at the top so the scene below stays in view.
	dialogue_box.position = Vector2(0, -80)
	castaway = Sprite2D.new()
	castaway.texture = preload("res://art/sprites/hero_down.png")
	castaway.hframes = 2
	castaway.centered = false
	castaway.position = Vector2(56, 100)
	castaway.material = CastawayLook.make_material(Game.current.look)
	castaway.visible = ending_id == "stay"
	add_child(castaway)
	Sound.play_music("ending")


func _process(delta: float) -> void:
	seconds += delta
	queue_redraw()
	match stage:
		Stage.SCENE:
			if seconds > 2.5:
				stage = Stage.STORY
				dialogue_box.show_lines(STORIES[ending_id]["lines"])
				dialogue_box.finished_callback = func() -> void:
					stage = Stage.CREDITS
					credits_offset = 0.0
		Stage.CREDITS:
			credits_offset += delta * CREDIT_SPEED * (4.0 if Input.is_action_pressed("action_a") else 1.0)
			if credits_offset > CREDITS.size() * CREDIT_LINE_HEIGHT + 150:
				stage = Stage.THE_END
				seconds = 0.0
		Stage.THE_END:
			if seconds > 1.0 and (Input.is_action_just_pressed("action_a") or Input.is_action_just_pressed("start")):
				Sound.stop_music()
				Endings.pending_ending = ""
				ScreenFader.change_scene(TITLE_SCENE)
				stage = Stage.SCENE
				seconds = -999.0


func _draw() -> void:
	draw_texture(BACKGROUND_FRAMES[int(seconds / 0.6) % 2], Vector2.ZERO)
	draw_ending_props()
	if stage == Stage.SCENE:
		var title: String = STORIES[ending_id]["title"]
		PixelFont.draw_outlined_text(self, title, Vector2((256 - PixelFont.text_width(title)) / 2, 8), Palettes.sprite_color("logo", 1), UiDraw.ink())
	if stage == Stage.CREDITS:
		draw_rect(Rect2(0, 0, 256, 144), Palettes.background_color("sky", 3))
		for line_index in CREDITS.size():
			var top := 150 + line_index * CREDIT_LINE_HEIGHT - credits_offset
			if top > -10 and top < 150:
				var line: String = CREDITS[line_index]
				PixelFont.draw_text(self, line, Vector2((256 - PixelFont.text_width(line)) / 2, top), UiDraw.paper())
	if stage == Stage.THE_END:
		draw_rect(Rect2(0, 0, 256, 144), Palettes.background_color("sky", 3))
		UiDraw.centred_text(self, "THE END", 56, UiDraw.paper())
		UiDraw.centred_text(self, "ENDINGS FOUND: %d/4" % Game.endings_seen.size(), 72, Palettes.background_color("sky", 1))
		if int(seconds / 0.5) % 2 == 0:
			UiDraw.centred_text(self, "PRESS A", 110, UiDraw.paper())


func draw_ending_props() -> void:
	var dark := Palettes.background_color("sky", 3)
	match ending_id:
		"signal":
			var fire: Texture2D = preload("res://art/sprites/beacon_lit.png")
			var frame := int(seconds / 0.25) % 2
			draw_texture_rect_region(fire, Rect2(80, 46, 32, 16), Rect2(frame * 32, 0, 32, 16))
			var ship_x := 260.0 - minf(seconds, 6.0) * 14.0
			draw_ship(Vector2(ship_x, 86), dark)
		"radio":
			var radio: Texture2D = preload("res://art/sprites/radio_fixed.png")
			draw_texture_rect(radio, Rect2(104, 92, 48, 48), false)
			var pulse := int(seconds * 3.0) % 3
			for ring in 3:
				var radius := 8 + ring * 8 + pulse * 2
				draw_arc(Vector2(128, 96), radius, -PI * 0.8, -PI * 0.2, 6, Palettes.background_color("sky", 0), 1.0)
		"sail":
			var boat: Texture2D = preload("res://art/sprites/sailboat.png")
			var boat_x := -32.0 + minf(seconds, 12.0) * 16.0
			draw_texture(boat, Vector2(roundf(boat_x), 92 + roundf(sin(seconds * 3.0))))
		"stay":
			var fire: Texture2D = preload("res://art/sprites/campfire.png")
			var frame := int(seconds / 0.25) % 2
			draw_texture_rect_region(fire, Rect2(76, 100, 16, 16), Rect2(frame * 16, 0, 16, 16))


func draw_ship(base: Vector2, color: Color) -> void:
	draw_rect(Rect2(base + Vector2(-14, -4), Vector2(28, 4)), color)
	draw_rect(Rect2(base + Vector2(-10, -8), Vector2(16, 4)), color)
	draw_rect(Rect2(base + Vector2(-2, -14), Vector2(3, 6)), color)
