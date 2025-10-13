shader_type canvas_item;

// 描边参数
uniform float outline_width = 1.0;  // 描边宽度
uniform vec4 outline_color : source_color = vec4(0, 0, 0, 1);  // 描边颜色

// 闪光参数（从hit_flash融入）
uniform vec4 hit_flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // 闪光颜色（全白）
uniform float hit_flash_intensity : hint_range(0.0, 1.0) = 0.0;  // 闪光强度

void fragment() {
	vec2 uv = UV;
	
	// ===== 描边计算 =====
	vec2 uv_up = uv + vec2(0, TEXTURE_PIXEL_SIZE.y) * outline_width;
	vec2 uv_down = uv + vec2(0, -TEXTURE_PIXEL_SIZE.y) * outline_width;
	vec2 uv_left = uv + vec2(TEXTURE_PIXEL_SIZE.x, 0) * outline_width;
	vec2 uv_right = uv + vec2(-TEXTURE_PIXEL_SIZE.x, 0) * outline_width;
	
	vec4 color_up = texture(TEXTURE, uv_up);
	vec4 color_down = texture(TEXTURE, uv_down);
	vec4 color_left = texture(TEXTURE, uv_left);
	vec4 color_right = texture(TEXTURE, uv_right);
	
	vec4 outline = color_up + color_down + color_left + color_right;
	outline.rgb = outline_color.rgb;
	outline.a = min(outline.a, 1.0);
	
	vec4 original_color = texture(TEXTURE, UV);
	
	// 混合原图和描边
	vec4 base_color = mix(outline, original_color, original_color.a);
	
	// ===== 应用闪光效果到整体（包括原图和描边） =====
	vec3 final_rgb = mix(base_color.rgb, hit_flash_color.rgb, hit_flash_intensity);
	
	COLOR = vec4(final_rgb, base_color.a);
}
