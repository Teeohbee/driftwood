shader_type canvas_item;

// Optional "LCD" look: a faint grid between the big pixels, like a GBC
// screen. Works on whole screen pixels, so it never blurs the art.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec2 game_size = vec2(256.0, 144.0);

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	vec2 within_pixel = fract(SCREEN_UV * game_size);
	float edge = step(0.86, max(within_pixel.x, within_pixel.y));
	COLOR = vec4(screen_color.rgb * (1.0 - edge * 0.18), 1.0);
}
