class_name NightOverlay
extends ColorRect

## Dithered darkness over the world. The world passes in the darkness level
## and light positions in screen pixels each frame.

const SHADER := preload("res://art/shaders/night.gdshader")
const DARKNESS_FOR_STEP := [0.0, 0.3, 0.55, 0.8]
const MAXIMUM_LIGHTS := 16


func _ready() -> void:
	var night_material := ShaderMaterial.new()
	night_material.shader = SHADER
	material = night_material
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(256, 144 - StatusBar.HEIGHT)


func show_darkness(darkness: float, lights: Array) -> void:
	visible = darkness > 0.0
	if not visible:
		return
	var packed := []
	for light in lights.slice(0, MAXIMUM_LIGHTS):
		packed.append(Vector3(light.x, light.y, light.z))
	while packed.size() < MAXIMUM_LIGHTS:
		packed.append(Vector3.ZERO)
	material.set_shader_parameter("darkness", darkness)
	material.set_shader_parameter("light_count", mini(lights.size(), MAXIMUM_LIGHTS))
	material.set_shader_parameter("lights", PackedVector3Array(packed))
