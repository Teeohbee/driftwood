extends CanvasLayer

## Game Boy style scene changes: the screen whitens in a few hard steps,
## the scene swaps, then it steps back. No smooth alpha fades.

const STEP_SECONDS := 0.07
const WHITENESS_STEPS := [0.0, 0.35, 0.7, 1.0]
const FADE_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float whiteness = 0.0;
uniform vec3 fade_color = vec3(1.0);
void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	COLOR = vec4(mix(screen_color.rgb, fade_color, whiteness), 1.0);
}
"""

var fade_rectangle: ColorRect
var is_changing_scene := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shader := Shader.new()
	shader.code = FADE_SHADER
	var fade_material := ShaderMaterial.new()
	fade_material.shader = shader
	fade_rectangle = ColorRect.new()
	fade_rectangle.material = fade_material
	fade_rectangle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rectangle.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rectangle.visible = false
	add_child(fade_rectangle)


func change_scene(scene_path: String) -> void:
	if is_changing_scene:
		return
	is_changing_scene = true
	await step_through(WHITENESS_STEPS)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	var steps_back := WHITENESS_STEPS.duplicate()
	steps_back.reverse()
	await step_through(steps_back)
	is_changing_scene = false


## Fades to white (or black, for sleep) and stays there until fade_in().
func fade_out(to_black := false) -> void:
	var fade_color := Vector3(0.03, 0.03, 0.1) if to_black else Vector3(1, 1, 1)
	fade_rectangle.material.set_shader_parameter("fade_color", fade_color)
	await step_through(WHITENESS_STEPS)


func fade_in() -> void:
	var steps_back := WHITENESS_STEPS.duplicate()
	steps_back.reverse()
	await step_through(steps_back)
	fade_rectangle.material.set_shader_parameter("fade_color", Vector3(1, 1, 1))


func step_through(whiteness_steps: Array) -> void:
	fade_rectangle.visible = true
	for whiteness in whiteness_steps:
		fade_rectangle.material.set_shader_parameter("whiteness", whiteness)
		await get_tree().create_timer(STEP_SECONDS).timeout
	if whiteness_steps.back() == 0.0:
		fade_rectangle.visible = false
