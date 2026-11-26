class_name SeasonSwap
extends RefCounted

## Shared palette-swap materials that recolour foliage for each season.

static var materials_by_season := {}


static func material_for(season: String) -> ShaderMaterial:
	if materials_by_season.has(season):
		return materials_by_season[season]
	var from_colors := PackedVector3Array()
	var to_colors := PackedVector3Array()
	var replacement: Array = Palettes.SEASON_SPRITE_OVERRIDES[season]["foliage"]
	for index in range(1, 4):
		var original := Palettes.sprite_color("foliage", index)
		var swapped := Palettes.five_bit_to_color(replacement[index])
		from_colors.append(Vector3(original.r, original.g, original.b))
		to_colors.append(Vector3(swapped.r, swapped.g, swapped.b))
	var swap_material := ShaderMaterial.new()
	swap_material.shader = CastawayLook.SWAP_SHADER
	swap_material.set_shader_parameter("from_colors", from_colors)
	swap_material.set_shader_parameter("to_colors", to_colors)
	materials_by_season[season] = swap_material
	return swap_material
