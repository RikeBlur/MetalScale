shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D threshold_mask; // 你可以用 hint_black_albedo 或不加 hint
uniform bool monochrome = true;

float get_l(vec4 color){
    // 计算亮度（使用标准亮度公式）
    float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	return luminance;
}

void fragment() {

    // 获取当前像素颜色（来自背景/上一个绘制层）
    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	float luminance = get_l(color);

  	vec2 mask_size = vec2(textureSize(threshold_mask, 0)); // Godot 4 支持

    // 对图案尺寸取模 → 获取在当前图案块中的像素位置
    vec2 pattern_pixel = mod(FRAGCOORD.xy,mask_size);
    // 转换为 [0, 1) 的 UV（+0.5 采样中心，避免边界插值问题）
    vec2 tiled_uv = pattern_pixel / mask_size;
	
    float threshold = texture(threshold_mask, tiled_uv).r; // 假设蒙版是灰度图，取 R 通道

    // 二值化：亮度 > 阈值 → 白，否则 → 黑
    vec3 output_color = (luminance > threshold) ? color.rgb : vec3(0.0);
    
	if (monochrome == true) {
		output_color = (luminance > threshold) ? vec3(1.0) : vec3(0.0);
	}

    // 输出最终颜色（保留原始 alpha）
    COLOR = vec4(output_color, color.a);
	// 查看蒙版平铺
	//COLOR = texture(threshold_mask, tiled_uv);
}