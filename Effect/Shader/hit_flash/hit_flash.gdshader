shader_type canvas_item;  //shader类型

uniform vec4 hit_flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); //闪光颜色（全白）
uniform float hit_flash_intensity = 0.0; //闪光程度

void fragment() {
	vec4 sprite_color = texture(TEXTURE, UV);
	vec3 final_rgb = mix(sprite_color.rgb, hit_flash_color.rgb, hit_flash_intensity); //按照强度混合原色rgb和闪光rgb
	COLOR = vec4(final_rgb, sprite_color.a); //rgb加上a，得到呈现在画面的颜色
}
