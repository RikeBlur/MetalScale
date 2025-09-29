class_name interactable_label_component
extends Label

@export var connected_area: Area2D
@export var hoven_color: Color = Color(0.88,0.88,0.88,1)
@export var clicked_color: Color = Color(0.45,0.45,0.45,1)

var click_player: AudioStreamPlayer2D = null
var hoven_player: AudioStreamPlayer2D = null
var entered: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material.set_shader_parameter("outline_width", 0)
	material.set_shader_parameter("all_color", Vector4(1,1,1,1))
	if connected_area:
		_connect_area_signals()
	click_player = get_child(1)
	hoven_player = get_child(0)

# 连接Area2D的信号
func _connect_area_signals() -> void:
	if connected_area.has_signal("mouse_entered_signal"):
		connected_area.mouse_entered_signal.connect(_on_mouse_entered)
	if connected_area.has_signal("mouse_exited_signal"):
		connected_area.mouse_exited_signal.connect(_on_mouse_exited)
	if connected_area.has_signal("click_recover"):
		connected_area.click_recover.connect(_on_click_recover)
	if connected_area.has_signal("click_start_siganl"):
		connected_area.click_start_siganl.connect(_on_click_start)
	if connected_area.has_signal("clicked_signal"):
		connected_area.clicked_signal.connect(_on_clicked)

# 鼠标进入时执行
func _on_mouse_entered() -> void:
	material.set_shader_parameter("outline_width", 1.2)
	material.set_shader_parameter("all_color", hoven_color)
	if entered == false:
		hoven_player.play()
		entered = true
	
# 鼠标离开时执行
func _on_mouse_exited() -> void:
	material.set_shader_parameter("outline_width", 0)
	material.set_shader_parameter("all_color", Vector4(1,1,1,1))
	
# 鼠标按下时执行
func _on_click_start() -> void:
	material.set_shader_parameter("outline_width", 0)
	material.set_shader_parameter("all_color", clicked_color)
	click_player.play()
	

# 按钮恢复时执行
func _on_click_recover() -> void:
	material.set_shader_parameter("outline_width", 1.2)
	material.set_shader_parameter("all_color", hoven_color)

# 点击时执行
func _on_clicked() -> void:
	pass

func change_color(color_hoven: Color, color_click: Color) -> void:
	hoven_color = color_hoven
	clicked_color = color_click
