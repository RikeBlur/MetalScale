shader_type canvas_item;

// 描边参数
uniform float outline_width = 1.0;  // 描边宽度
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // 描边颜色

// 闪光参数
uniform vec4 hit_flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);  // 闪光颜色
uniform float hit_flash_intensity : hint_range(0.0, 1.0) = 0.0;  // 闪光强度

void fragment() {
	vec2 uv = UV;

	// ===== 内描边计算 =====
	// 与外描边采样方向相同，但判断逻辑相反：
	// 当前像素不透明 且 存在更透明的邻居 → 当前像素处于内边缘
	vec2 uv_up    = uv + vec2(0.0,                TEXTURE_PIXEL_SIZE.y) * outline_width;
	vec2 uv_down  = uv + vec2(0.0,               -TEXTURE_PIXEL_SIZE.y) * outline_width;
	vec2 uv_left  = uv + vec2( TEXTURE_PIXEL_SIZE.x, 0.0) * outline_width;
	vec2 uv_right = uv + vec2(-TEXTURE_PIXEL_SIZE.x, 0.0) * outline_width;

	float a_up    = texture(TEXTURE, uv_up).a;
	float a_down  = texture(TEXTURE, uv_down).a;
	float a_left  = texture(TEXTURE, uv_left).a;
	float a_right = texture(TEXTURE, uv_right).a;

	vec4 original_color = texture(TEXTURE, uv);

	// 取四邻居中最小的 alpha
	float min_neighbor = min(min(a_up, a_down), min(a_left, a_right));

	// 当前像素不透明 且 存在比自身更透明的邻居 → 内边缘
	bool is_inner_edge = (original_color.a > 0.0) && (min_neighbor < original_color.a);

	vec4 base_color;
	if (is_inner_edge) {
		// 内边缘：覆盖为描边颜色，保留原图 alpha
		base_color = vec4(outline_color.rgb, original_color.a);
	} else {
		base_color = original_color;
	}

	// ===== 应用闪光效果到整体 =====
	vec3 final_rgb = mix(base_color.rgb, hit_flash_color.rgb, hit_flash_intensity);

	COLOR = vec4(final_rgb, base_color.a);
}
