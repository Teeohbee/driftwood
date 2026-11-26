class_name CastawayLook
extends RefCounted

## The look picker: skin, shirt and hair are palette swaps of the "hero"
## sprite palette (index 1 skin, 2 shirt, 3 hair and outline).
## A look is a Dictionary like {"skin": 0, "shirt": 2, "hair": 1}.

const SWAP_SHADER := preload("res://art/shaders/palette_swap.gdshader")

const OPTIONS := {
	"skin": [[31, 25, 19], [28, 20, 14], [22, 14, 9], [15, 9, 5]],
	"shirt": [[8, 16, 29], [27, 8, 5], [8, 20, 8], [28, 22, 4]],
	"hair": [[3, 3, 5], [10, 5, 2], [14, 4, 3], [5, 5, 13]],
}
## Which hero palette index each part replaces.
const PALETTE_INDEX_FOR_PART := {"skin": 1, "shirt": 2, "hair": 3}
const PARTS := ["skin", "shirt", "hair"]


static func default_look() -> Dictionary:
	return {"skin": 0, "shirt": 0, "hair": 0}


static func option_count(part: String) -> int:
	return OPTIONS[part].size()


static func color_for(look: Dictionary, part: String) -> Color:
	return Palettes.five_bit_to_color(OPTIONS[part][look.get(part, 0)])


static func make_material(look: Dictionary) -> ShaderMaterial:
	var from_colors := PackedVector3Array()
	var to_colors := PackedVector3Array()
	for part in PARTS:
		var original := Palettes.sprite_color("hero", PALETTE_INDEX_FOR_PART[part])
		var replacement := color_for(look, part)
		from_colors.append(Vector3(original.r, original.g, original.b))
		to_colors.append(Vector3(replacement.r, replacement.g, replacement.b))
	var swap_material := ShaderMaterial.new()
	swap_material.shader = SWAP_SHADER
	swap_material.set_shader_parameter("from_colors", from_colors)
	swap_material.set_shader_parameter("to_colors", to_colors)
	return swap_material
