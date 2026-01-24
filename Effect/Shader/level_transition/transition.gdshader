shader_type canvas_item;

// 转场进度：0.0 = 完全显示（黑屏），1.0 = 完全透明（游戏画面可见）
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Noise纹理，用于创建溶解效果
uniform sampler2D noise_texture : repeat_enable;

// Noise的UV缩放，控制噪声的密度
uniform vec2 noise_scale = vec2(1.0, 1.0);

// 溶解边缘的软化程度，值越大边缘越柔和
uniform float edge_softness : hint_range(0.0, 0.5) = 0.1;

// 转场颜色（默认纯黑）
uniform vec4 transition_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	// 边界条件：progress = 0 时完全显示，progress = 1 时完全透明
	if (progress <= 0.0) {
		// 完全黑屏
		COLOR = transition_color;
	}
	else if (progress >= 1.0) {
		// 完全透明
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
	else {
		// 采样noise纹理
		vec2 noise_uv = UV * noise_scale;
		float noise_value = texture(noise_texture, noise_uv).r;
		
		// 根据progress和noise计算alpha值
		// progress = 0: 完全显示黑屏（alpha = 1）
		// progress = 1: 完全透明（alpha = 0）
		float alpha = smoothstep(progress - edge_softness, progress + edge_softness, noise_value);
		
		// 输出最终颜色
		COLOR = transition_color;
		COLOR.a *= alpha;
	}
}