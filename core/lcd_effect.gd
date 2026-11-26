extends CanvasLayer

## The optional LCD grid over everything. Autoloaded as "LcdEffect".
## Note: in viewport stretch mode the grid lands between game pixels only
## at integer scales, which is all Driftwood uses.

var screen_rect: ColorRect


func _ready() -> void:
	layer = 99
	screen_rect = ColorRect.new()
	var lcd_material := ShaderMaterial.new()
	lcd_material.shader = preload("res://art/shaders/lcd.gdshader")
	screen_rect.material = lcd_material
	screen_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_rect.visible = false
	add_child(screen_rect)
	screen_rect.visible = Settings.lcd_effect


func set_enabled(is_enabled: bool) -> void:
	if screen_rect != null:
		screen_rect.visible = is_enabled
