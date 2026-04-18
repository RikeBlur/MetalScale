shader_type canvas_item;

// 工具箱状态常量
// 0 = 未选取
// 1 = 选取
// 2 = 激活
// 3 = 损坏
uniform int state : hint_range(0, 3) = 0;

// 激活状态 - 辉光参数
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.3;  // 辉光强度
uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.6, 1.0);  // 辉光颜色（暖黄色）
uniform float glow_size : hint_range(0.0, 10.0) = 2.0;  // 辉光扩散范围

// 未激活状态 - 明度参数
uniform float inactive_brightness : hint_range(0.0, 1.0) = 0.5;  // 未激活时的明度系数
uniform float inactive_saturation : hint_range(0.0, 1.0) = 0.6;  // 未激活时的饱和度系数

// 损坏状态 - 暗红色参数
uniform vec4 broken_tint : source_color = vec4(0.6, 0.2, 0.2, 1.0);  // 损坏时的暗红色调
uniform float broken_blend : hint_range(0.0, 1.0) = 0.7;  // 损坏色调的混合强度
uniform float broken_brightness : hint_range(0.0, 1.0) = 0.4;  // 损坏时的整体明度

// 时间动画参数
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;  // 脉冲速度（用于激活状态的呼吸效果）

// RGB转HSV
vec3 rgb_to_hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV转RGB
vec3 hsv_to_rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	// 获取原始纹理颜色
	vec4 original_color = texture(TEXTURE, UV);
	vec4 final_color = original_color;
	
	// 只处理非透明像素
	if (original_color.a > 0.01) {
		if (state == 1) {
			// ===== 激活状态：微弱辉光效果 =====
			// 创建呼吸效果：使用sin函数制作脉冲动画
			float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;  // 0.0 到 1.0 之间振荡
			float dynamic_glow = glow_intensity * (0.7 + pulse * 0.3);  // 70%-100%强度变化
			
			// 计算辉光：在原色基础上混合辉光颜色
			vec3 glowing = original_color.rgb + glow_color.rgb * dynamic_glow;
			
			// 对边缘增强辉光效果
			float edge_factor = 1.0 - abs(UV.x - 0.5) * 2.0;  // 中心强，边缘弱
			edge_factor *= 1.0 - abs(UV.y - 0.5) * 2.0;
			edge_factor = pow(edge_factor, 0.5);  // 平滑过渡
			
			final_color.rgb = mix(original_color.rgb, glowing, edge_factor * 0.6);
			
		} else if (state == 2) {
			float pulse = sin(TIME * pulse_speed * 1.4) * 0.5 + 0.5;
			vec3 activated = original_color.rgb + vec3(0.45, 0.75, 1.0) * glow_intensity * (0.9 + pulse * 0.4);
			final_color.rgb = mix(original_color.rgb, activated, 0.75);

		} else if (state == 0) {
			// ===== 未激活状态：降低明度和饱和度 =====
			// 转换到HSV色彩空间进行调整
			vec3 hsv = rgb_to_hsv(original_color.rgb);
			
			// 降低饱和度（S通道）和明度（V通道）
			hsv.y *= inactive_saturation;  // 降低饱和度
			hsv.z *= inactive_brightness;  // 降低明度
			
			// 转换回RGB
			final_color.rgb = hsv_to_rgb(hsv);
			
		} else if (state == 3) {
			// ===== 损坏状态：暗红色调 =====
			// 首先降低整体明度
			vec3 darkened = original_color.rgb * broken_brightness;
			
			// 混合暗红色调
			final_color.rgb = mix(darkened, broken_tint.rgb, broken_blend);
			
			// 添加微弱的闪烁效果以表示故障
			float flicker = sin(TIME * 3.0) * 0.5 + 0.5;
			flicker = pow(flicker, 3.0);  // 使闪烁更加尖锐
			final_color.rgb *= (0.85 + flicker * 0.15);  // 85%-100%之间轻微闪烁
		}
	}
	
	// 保持原始透明度
	final_color.a = original_color.a;
	COLOR = final_color;
}
