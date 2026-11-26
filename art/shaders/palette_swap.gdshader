shader_type canvas_item;

// Game Boy Color style palette swap: each of a sprite's 3 colours is
// replaced by another 15-bit colour. Used for the castaway look picker.

uniform vec3 from_colors[3];
uniform vec3 to_colors[3];

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	for (int index = 0; index < 3; index++) {
		if (distance(pixel.rgb, from_colors[index]) < 0.02) {
			pixel.rgb = to_colors[index];
		}
	}
	COLOR = pixel;
}
