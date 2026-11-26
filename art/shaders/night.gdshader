shader_type canvas_item;

// Night without alpha: an ordered 4x4 dither of solid black pixels.
// darkness is 0 (day) to 1 (pitch black). Each light carves a stepped
// circle out of the dark, brightest in the middle.

uniform float darkness = 0.0;
uniform int light_count = 0;
uniform vec3 lights[16];   // x, y in screen pixels, z = radius
uniform vec3 night_color = vec3(0.03, 0.03, 0.1);

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec2 pixel = floor(FRAGCOORD.xy);
	float here = darkness;
	for (int index = 0; index < 16; index++) {
		if (index >= light_count) {
			break;
		}
		float distance_to_light = distance(pixel, lights[index].xy);
		float radius = lights[index].z;
		float lit = 1.0 - smoothstep(radius * 0.45, radius, distance_to_light);
		lit = floor(lit * 4.0) / 4.0;
		here = min(here, darkness * (1.0 - lit));
	}
	int bayer_index = int(mod(pixel.x, 4.0)) + int(mod(pixel.y, 4.0)) * 4;
	float threshold = (BAYER[bayer_index] + 0.5) / 16.0;
	if (here > threshold) {
		COLOR = vec4(night_color, 1.0);
	} else {
		COLOR = vec4(0.0);
	}
}
