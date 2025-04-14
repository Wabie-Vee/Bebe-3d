shader_type spatial;
render_mode unshaded, depth_draw_always, cull_disabled;

uniform vec4 color : hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_strength = 1.0;

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
	EMISSION = color.rgb * glow_strength;
}
