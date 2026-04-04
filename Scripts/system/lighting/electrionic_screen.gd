class_name ElectronicScreen
extends Node2D

var player_now: CharacterBody2D = null
var activated: bool = false

@export var normal_color_content : Color = Color(0.26, 0.26, 0.26, 1.0)
@export var arrgo_color_content : Color = Color(0.79, 0.103, 0.103, 1.0)
@export var normal_color : Color = Color(0.665, 0.665, 0.665, 1.0)
@export var arrgo_color : Color = Color(0.82, 0.115, 0.115, 1.0)
@export var color_tween_duration: float = 0.4

var _color_tween: Tween = null

@onready var point_light: PointLight2D = $LightSource/PointLight2D
@onready var screen_content: Sprite2D = $ScreenContent
@onready var jiu: Sprite2D = $JIU

var fix: bool = false


func _ready() -> void:
	player_now = GameManager.get_player()
	point_light.color = normal_color
	# 确保屏幕内容有独立材质，并初始化 basecolor
	if screen_content and screen_content.material:
		screen_content.material = screen_content.material.duplicate(true)
		screen_content.material.set("shader_parameter/basecolor", normal_color_content)
	# jiu 初始不可见
	if jiu:
		jiu.modulate.a = 0.0
		jiu.visible = false
	_connect_arrgo_signals()

func _process(_delta: float) -> void:
	# 持续从 GameManager 同步玩家仇恨状态
	activated = GameManager.player_arrgo

func _connect_arrgo_signals() -> void:
	"""连接 GameManager 的 arrgo 信号，控制灯光颜色平滑切换"""
	if not GameManager.get_in_arrgo.is_connected(on_get_in_arrgo):
		GameManager.get_in_arrgo.connect(on_get_in_arrgo)
	if not GameManager.get_out_arrgo.is_connected(on_get_out_arrgo):
		GameManager.get_out_arrgo.connect(on_get_out_arrgo)
	if not GameManager.arrgoed.is_connected(on_arrgoed):
		GameManager.arrgoed.connect(on_arrgoed)
	if not GameManager.not_arrgoed.is_connected(on_not_arrgoed):
		GameManager.not_arrgoed.connect(on_not_arrgoed)


func _tween_both_colors(light_color: Color, content_color: Color, show_jiu: bool) -> void:
	"""将 point_light 颜色、screen_content basecolor、jiu 的 modulate.a 同时平滑过渡"""
	if _color_tween and _color_tween.is_valid():
		_color_tween.kill()
	_color_tween = create_tween()
	_color_tween.set_trans(Tween.TRANS_CUBIC)
	_color_tween.set_ease(Tween.EASE_IN_OUT)
	_color_tween.set_parallel(true)
	_color_tween.tween_property(point_light, "color", light_color, color_tween_duration)
	if screen_content and screen_content.material:
		var mat = screen_content.material
		var from_c = mat.get("shader_parameter/basecolor")
		if from_c == null:
			from_c = normal_color_content
		_color_tween.tween_method(
			func(v: Color) -> void:
				if is_instance_valid(screen_content) and screen_content.material:
					screen_content.material.set("shader_parameter/basecolor", v),
			from_c,
			content_color,
			color_tween_duration
		)
	# jiu 平滑淡入/淡出（与灯光、屏幕同 duration 同步）
	if jiu and is_instance_valid(jiu):
		if show_jiu:
			jiu.visible = true
		var from_mod := jiu.modulate
		var to_mod := Color(from_mod.r, from_mod.g, from_mod.b, 1.0 if show_jiu else 0.0)
		_color_tween.tween_property(jiu, "modulate", to_mod, color_tween_duration)
		if not show_jiu:
			_color_tween.set_parallel(false)  # 回调必须在淡出动画结束后执行，否则 visible=false 会立刻生效
			_color_tween.tween_callback(func() -> void:
				if is_instance_valid(jiu):
					jiu.visible = false
			)


func on_get_in_arrgo() -> void:
	"""get_in_arrgo 时：灯光和屏幕内容颜色平滑变至 arrgo 色，jiu 平滑显示"""
	_tween_both_colors(arrgo_color, arrgo_color_content, true)


func on_get_out_arrgo() -> void:
	"""get_out_arrgo 时：灯光和屏幕内容颜色平滑变至 normal 色，jiu 平滑隐藏"""
	if fix:
		return
	_tween_both_colors(normal_color, normal_color_content, false)


func on_arrgoed() -> void:
	_tween_both_colors(arrgo_color, arrgo_color_content, true)
	fix = true


func on_not_arrgoed() -> void:
	_tween_both_colors(normal_color, normal_color_content, false)
	fix = false
