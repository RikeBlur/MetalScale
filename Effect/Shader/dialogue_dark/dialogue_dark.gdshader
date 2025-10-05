shader_type canvas_item;

// 输入参数
uniform float brightness : hint_range(0.0, 1.0) = 0.1; // 明度控制 (0.0为最暗，1.0为原始亮度)
uniform float contrast : hint_range(0.0, 1.0) = 0.99; // 对比度控制 (0.0为无对比度，1.0为原始对比度)

void vertex() {
	// 传递顶点位置和UV坐标
	VERTEX = VERTEX;
}

void fragment() {
	// 获取原始纹理颜色
	vec4 original_color = texture(TEXTURE, UV);

	// 保持原始颜色，只调整明度和对比度
	vec3 adjusted_color = original_color.rgb;

	// 降低明度
	adjusted_color = adjusted_color * brightness;

	// 降低对比度
	// 对比度公式：new_color = (color - 0.5) * contrast + 0.5
	adjusted_color = (adjusted_color - 0.5) * contrast + 0.5;

	// 确保颜色值在有效范围内
	adjusted_color = clamp(adjusted_color, 0.0, 1.0);

	// 保持原始透明度
	COLOR = vec4(adjusted_color, original_color.a);
}
