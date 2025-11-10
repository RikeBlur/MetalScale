class_name waving_back
extends Sprite2D

# 获取ShaderMaterial的引用
@onready var shader_material: ShaderMaterial = self.material as ShaderMaterial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if shader_material == null:
		print("警告: 未找到ShaderMaterial!")

# 修改波动速度
func set_wave_speed(speed: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("wave_speed", speed)
		print("波动速度设置为: ", speed)

# 修改噪声缩放
func set_noise_scale(scale: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("noise_scale", scale)
		print("噪声缩放设置为: ", scale)

# 修改波动幅度
func set_wave_amplitude(amplitude: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("wave_amplitude", amplitude)
		print("波动幅度设置为: ", amplitude)

# 修改基础颜色（色调）
func set_base_color(color: Color) -> void:
	if shader_material:
		shader_material.set_shader_parameter("base_color", color)
		print("基础颜色设置为: ", color)

# 修改色调（通过HSV）
func set_hue(hue: float) -> void:
	if shader_material:
		var current_color = shader_material.get_shader_parameter("base_color") as Color
		if current_color != null:
			var new_color = Color.from_hsv(hue, current_color.s, current_color.v, current_color.a)
			shader_material.set_shader_parameter("base_color", new_color)
			print("色调设置为: ", hue, " 新颜色: ", new_color)

# 修改饱和度
func set_saturation(saturation: float) -> void:
	if shader_material:
		var current_color = shader_material.get_shader_parameter("base_color") as Color
		if current_color != null:
			var new_color = Color.from_hsv(current_color.h, saturation, current_color.v, current_color.a)
			shader_material.set_shader_parameter("base_color", new_color)
			print("饱和度设置为: ", saturation)

# 修改亮度
func set_brightness(brightness: float) -> void:
	if shader_material:
		var current_color = shader_material.get_shader_parameter("base_color") as Color
		if current_color != null:
			var new_color = Color.from_hsv(current_color.h, current_color.s, brightness, current_color.a)
			shader_material.set_shader_parameter("base_color", new_color)
			print("亮度设置为: ", brightness)

# 修改透明度乘数
func set_alpha_multiplier(alpha: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("alpha_multiplier", alpha)
		print("透明度乘数设置为: ", alpha)
		
func set_color_mix(mix: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("color_mix", mix)
		print("透明度乘数设置为: ", mix)

# 修改时间偏移
func set_time_offset(offset: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("time_offset", offset)
		print("时间偏移设置为: ", offset)

# 切换是否使用渐变纹理
func toggle_gradient(use_gradient: bool) -> void:
	if shader_material:
		shader_material.set_shader_parameter("use_gradient", use_gradient)
		print("使用渐变纹理: ", use_gradient)

# 设置渐变纹理
func set_gradient_texture(texture: Texture2D) -> void:
	if shader_material:
		shader_material.set_shader_parameter("gradient_texture", texture)
		print("渐变纹理已更新")

# 预设颜色函数
func set_color_red() -> void:
	set_base_color(Color.RED)

func set_color_blue() -> void:
	set_base_color(Color.BLUE)

func set_color_green() -> void:
	set_base_color(Color.GREEN)

func set_color_purple() -> void:
	set_base_color(Color.PURPLE)

func set_color_orange() -> void:
	set_base_color(Color.ORANGE)

# 动画化修改色调（循环变化）
func animate_hue_cycle(duration: float = 5.0) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_method(set_hue, 0.0, 1.0, duration)

# 动画化修改波动速度
func animate_wave_speed(from_speed: float, to_speed: float, duration: float) -> void:
	var tween = create_tween()
	tween.tween_method(set_wave_speed, from_speed, to_speed, duration)

# 脉冲效果（透明度变化）
func pulse_effect(duration: float = 2.0) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_method(set_alpha_multiplier, 1.0, 0.3, duration / 2.0)
	tween.tween_method(set_alpha_multiplier, 0.3, 1.0, duration / 2.0)

# 获取当前shader参数值
func get_current_parameters() -> Dictionary:
	if shader_material:
		return {
			"wave_speed": shader_material.get_shader_parameter("wave_speed"),
			"noise_scale": shader_material.get_shader_parameter("noise_scale"),
			"wave_amplitude": shader_material.get_shader_parameter("wave_amplitude"),
			"base_color": shader_material.get_shader_parameter("base_color"),
			"alpha_multiplier": shader_material.get_shader_parameter("alpha_multiplier"),
			"time_offset": shader_material.get_shader_parameter("time_offset"),
			"use_gradient": shader_material.get_shader_parameter("use_gradient")
		}
	return {}
