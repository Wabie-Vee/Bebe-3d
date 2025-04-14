// Applies toon-like quantized shading in screen-space
shader_type canvas_item;
render_mode unshaded;

uniform float levels = 3.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec3 col = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    
    // Convert to grayscale for light intensity
    float brightness = dot(col, vec3(0.299, 0.587, 0.114));
    
    // Quantize brightness to get toon shading
    float shade = floor(brightness * levels) / (levels - 1.0);
    col *= shade / brightness;

    COLOR = vec4(col, 1.0);
}
