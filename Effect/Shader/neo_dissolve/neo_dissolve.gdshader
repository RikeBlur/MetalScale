shader_type canvas_item;

// 溶解参数：0.0 = 完全显示，1.0 = 完全消失
uniform float DissolveValue: hint_range(0.0, 1.0) = 0.0;

// 噪声纹理（用于控制溶解图案）
uniform sampler2D noise_texture : hint_default_white;

// 噪声缩放（控制溶解颗粒度）
// 值越大，颗粒越细腻；值越小，颗粒越粗糙
uniform float noise_scale : hint_range(0.1, 10.0) = 1.0;

// 边缘颜色（溶解边缘的发光颜色）
uniform vec4 edge_color : source_color = vec4(0.83, 0.0, 0.0, 1.0);

// 边缘宽度
uniform float edge_width : hint_range(0.0, 0.5) = 0.1;

// 边缘亮度增强
uniform float edge_intensity : hint_range(0.0, 5.0) = 2.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// 获取原始纹理颜色
	vec4 tex_color = texture(TEXTURE, UV);

	// 如果 DissolveValue <= 0.0，完全不应用溶解效果
	if (DissolveValue <= 0.0) {
		COLOR = tex_color;
	}
	// 如果 DissolveValue >= 1.0，完全透明
	else if (DissolveValue >= 1.0) {
		discard;
	}
	// 正常溶解范围 (0 < DissolveValue < 1)
	else {
		// 采样噪声纹理（使用红色通道）
		// 通过 noise_scale 缩放UV来控制颗粒度
		float noise = texture(noise_texture, UV * noise_scale).r;

		// 根据dissolve值和噪声值决定是否丢弃片段
		// 当noise < dissolve时，该像素被溶解（丢弃）
		if (noise < DissolveValue) {
			discard;
		}

		// 计算边缘效果
		// 边缘区域：dissolve <= noise < (DissolveValue + edge_width)
		float edge_threshold = DissolveValue + edge_width;

		if (noise < edge_threshold) {
			// 在边缘区域，计算边缘渐变因子
			// edge_factor: 1.0（最靠近溶解边界）-> 0.0（远离边界）
			float edge_factor = 1.0 - (noise - DissolveValue) / edge_width;
			edge_factor = clamp(edge_factor, 0.0, 1.0);

			// 应用平滑曲线让边缘效果更自然
			edge_factor = smoothstep(0.0, 1.0, edge_factor);

			// 混合原始颜色和边缘颜色（叠加发光效果）
			vec4 glow = edge_color * edge_intensity * edge_factor;
			COLOR = tex_color + glow;
			COLOR.a = tex_color.a; // 保持原始透明度
		} else {
			// 非边缘区域，正常显示
			COLOR = tex_color;
		}
	}
}
