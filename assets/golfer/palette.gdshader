shader_type canvas_item;
render_mode unshaded;

uniform vec4 shirt_color : source_color = vec4(0.286, 0.839, 0.812, 1.0);

void fragment() {
	// One sample per internal pixel keeps the atlas crisp at 2x and 4x.
	vec2 grid = vec2(352.0, 576.0);
	vec2 pixel_uv = (floor(UV * grid) + vec2(0.5)) / grid;
	vec4 ink = texture(TEXTURE, pixel_uv);
	// Key out Imagegen's backdrop before recoloring the turquoise shirt.
	if (ink.r > 0.05 && ink.b > 0.05 && ink.g < min(ink.r, ink.b) * 0.6) {
		ink = vec4(0.0);
	} else if (ink.g > ink.r * 1.5 && ink.b > ink.r * 1.5 && ink.g > ink.b * 0.72 && ink.g > 0.18) {
		float shade = ink.g > 0.65 ? 1.0 : (ink.g > 0.4 ? 0.78 : 0.54);
		ink.rgb = shirt_color.rgb * shade;
	}
	COLOR = ink;
}
