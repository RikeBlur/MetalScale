class_name HealthBar #假如这行报错不要管！！
extends ProgressBar

# 子血条 用来实现假血效果
@onready var progress_bar: ProgressBar = $ProgressBar
# 血条自动隐藏计时
@onready var timer: Timer = $Timer

var change_value_tween : Tween
var opacity_tween : Tween


# 生成血条
func _setup_health_bar(max_health : float) -> void:
	modulate.a = 0.0
	value = max_health
	max_value = max_health
	progress_bar.value = max_health
	progress_bar.max_value = max_health
	
	
# 修改血量
func change_value(new_amount : float) -> void:
	_change_opacity(1.0)
	
	value = new_amount
	
	if change_value_tween:
		change_value_tween.kill()
	change_value_tween = create_tween()
	change_value_tween.finished.connect(timer.start)
	change_value_tween.tween_property(progress_bar, "value", new_amount, 0.5).set_trans(Tween.TRANS_SINE)
	
	
# 修改可视度
func _change_opacity(new_amount : float) -> void:
	if opacity_tween :
		opacity_tween.kill()
	opacity_tween = create_tween()
	opacity_tween.tween_property(self, "modulate:a", new_amount, 0.2).set_trans(Tween.TRANS_SINE)


# 自动隐藏
func _on_timer_timeout() -> void:
	_change_opacity(0.0)
