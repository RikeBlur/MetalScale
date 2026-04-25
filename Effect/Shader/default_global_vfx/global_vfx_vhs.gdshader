shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float effect_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float row_jitter_px : hint_range(0.0, 4.0) = 0.65;
uniform float band_jitter_px : hint_range(0.0, 8.0) = 1.2;
uniform float chroma_offset_px : hint_range(0.0, 4.0) = 0.85;
uniform float luma_smear_px : hint_range(0.0, 4.0) = 1.25;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.18;
uniform float grille_opacity : hint_range(0.0, 1.0) = 0.1;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.22;
uniform float saturation : hint_range(0.0, 1.5) = 0.9;
uniform float contrast : hint_range(0.5, 1.5) = 1.04;
uniform float black_lift : hint_range(0.0, 0.08) = 0.004;
uniform float highlight_rolloff : hint_range(0.5, 1.0) = 0.92;
uniform float shadow_protection_start : hint_range(0.0, 0.3) = 0.03;
uniform float shadow_protection_end : hint_range(0.05, 0.5) = 0.15;
uniform float shadow_effect_floor : hint_range(0.0, 1.0) = 0.25;

float hash1(float n) {
	return fract(sin(n * 127.1 + 311.7) * 43758.5453123);
}

vec2 get_distorted_uv(vec2 uv, vec2 pixel_size) {
	float row_index = floor(uv.y / pixel_size.y);
	float band_index = floor(row_index / 14.0);

	float row_shift = (hash1(row_index + 3.7) - 0.5) * row_jitter_px * pixel_size.x;
	float band_shift = (hash1(band_index + 19.4) - 0.5) * band_jitter_px * pixel_size.x;

	vec2 shifted_uv = uv + vec2(row_shift + band_shift, 0.0);
	return clamp(shifted_uv, vec2(0.0), vec2(1.0));
}

vec3 apply_vhs_grade(vec3 color) {
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 graded = mix(vec3(luma), color, saturation);
	graded = (graded - 0.5) * contrast + 0.5;
	graded = max(graded, vec3(black_lift));
	graded = min(graded, vec3(highlight_rolloff));
	return graded;
}

void fragment() {
	vec2 pixel_size = SCREEN_PIXEL_SIZE;
	vec3 original = texture(screen_texture, SCREEN_UV).rgb;
	float original_luma = dot(original, vec3(0.299, 0.587, 0.114));
	float shadow_factor = smoothstep(shadow_protection_start, shadow_protection_end, original_luma);
	float effect_factor = mix(shadow_effect_floor, 1.0, shadow_factor);

	vec2 uv = get_distorted_uv(SCREEN_UV, pixel_size);
	uv = mix(SCREEN_UV, uv, effect_factor);

	float chroma_offset = chroma_offset_px * pixel_size.x * effect_factor;
	float smear_offset = luma_smear_px * pixel_size.x * mix(0.35, 1.0, shadow_factor);

	vec3 center = texture(screen_texture, uv).rgb;
	vec3 left_1 = texture(screen_texture, clamp(uv - vec2(smear_offset, 0.0), vec2(0.0), vec2(1.0))).rgb;
	vec3 left_2 = texture(screen_texture, clamp(uv - vec2(smear_offset * 2.0, 0.0), vec2(0.0), vec2(1.0))).rgb;

	vec3 vhs_color;
	vhs_color.r = texture(screen_texture, clamp(uv + vec2(chroma_offset, 0.0), vec2(0.0), vec2(1.0))).r;
	vhs_color.g = center.g;
	vhs_color.b = texture(screen_texture, clamp(uv - vec2(chroma_offset, 0.0), vec2(0.0), vec2(1.0))).b;

	vec3 smeared = center * 0.66 + left_1 * 0.24 + left_2 * 0.10;
	vhs_color = mix(vhs_color, smeared, 0.45);
	vhs_color = apply_vhs_grade(vhs_color);
	vhs_color = mix(original, vhs_color, effect_factor);

	float row_index = floor(SCREEN_UV.y / pixel_size.y);
	float column_index = floor(SCREEN_UV.x / pixel_size.x);

	float scanline_mask = 1.0 - mod(row_index, 2.0) * scanline_opacity * effect_factor;
	float grille_mask = 1.0 - mod(column_index, 3.0) * grille_opacity * 0.5 * effect_factor;

	float vignette_x = SCREEN_UV.x * (1.0 - SCREEN_UV.x);
	float vignette_y = SCREEN_UV.y * (1.0 - SCREEN_UV.y);
	float vignette = pow(max(vignette_x * vignette_y * 16.0, 0.0), 0.32);
	float vignette_mask = mix(1.0 - vignette_strength, 1.0, vignette);

	float shadow_vignette_mix = mix(1.0, vignette_mask, mix(0.4, 1.0, shadow_factor));
	vhs_color *= scanline_mask * grille_mask * shadow_vignette_mix;

	COLOR = vec4(mix(original, vhs_color, effect_opacity * effect_factor), 1.0);
}
