class_name durability_process_bar
extends ProgressBar

@export var bar_color: Color = Color.GREEN
@export var low_color: Color = Color.YELLOW
@export var critical_color: Color = Color.RED

func _ready():
	var background = StyleBoxFlat.new()
	background.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	background.corner_radius_top_left = 2
	background.corner_radius_top_right = 2
	background.corner_radius_bottom_left = 2
	background.corner_radius_bottom_right = 2

	var fill = StyleBoxFlat.new()
	fill.bg_color = bar_color
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2

	add_theme_stylebox_override("background", background)
	add_theme_stylebox_override("fill", fill)
	update_color()

func update_color():
	var percent = (value / max_value) * 100.0
	var fill = get_theme_stylebox("fill") as StyleBoxFlat
	if fill:
		fill.bg_color = critical_color if percent <= 10 else low_color if percent <= 30 else bar_color
