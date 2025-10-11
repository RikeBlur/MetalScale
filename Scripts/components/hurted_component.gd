# 伤害接收（受伤）组件
class_name hurted_component #假如这行报错不要管！！
extends Node2D

# 受击box
@export var hurted_area : Area2D = null
@export var hit_flash_player : AnimationPlayer = null

# 受击特效
@export var hurted_audio: AudioStreamPlayer2D = null
@export var hurted_effect: GPUParticles2D = null

# 血条
@export var health_bar: HealthBar = null

# 死亡特效
@export var die_audio: AudioStreamPlayer2D = null
@export var die_effect: GPUParticles2D = null

# 依附 Rigid
var entity : CharacterBody2D = null
# 当前血量
var health_max : float = 100
var health : float = 100

var is_died : bool = false

func _ready() -> void:
	entity = Tools._find_character_body_parent(hurted_area)
	health_max = entity.health_max
	health = health_max
	# 受击闪烁特效
	if not hit_flash_player :
		hit_flash_player = self.get_parent().find_child("FlashAnimation")
	
	if health_bar :
		# 将HealthBar设置为top_level，使其不受父节点变换影响
		health_bar.top_level = true
		health_bar._setup_health_bar(health)
		# z_index设高，避免血条被盖住
		health_bar.z_index = 2
		
		# 初始血条位置同步
		_update_health_bar_position()


# 添加_process函数来更新HealthBar位置
func _process(_delta: float) -> void:
	if health_bar and not is_died :
		_update_health_bar_position()
	
		
# 更新HealthBar位置
func _update_health_bar_position() -> void:
	# 计算health_bar应该在的全局位置
	var global_pos = entity.global_position 
	# 应用血条位置偏移（可根据需要调整）
	global_pos.y -= 10
	global_pos.x -= 7
	# 设置全局位置
	health_bar.global_position = global_pos
	# 始终保持0旋转
	health_bar.rotation_degrees = 0


# 受伤处理	
func _on_hurt(amount : float) -> void:
	if (health - amount) > 0:
		health -= amount
		entity.health_now = health
		# 播放粒子特效
		_hurted_effect()
		health_bar.change_value(health)
		print("health:",health)
	elif not is_died :
		print("DIED")
		on_died()
	#如果有收击闪烁，则播放受击闪烁
	if hit_flash_player :
		# 停止当前动画并重新播放
		hit_flash_player.stop()
		hit_flash_player.play("hit")
		# 或者使用以下方式强制播放
		 #hit_flash_player.play("hit", -1, 1.0, true)

		
# 死亡处理
func on_died() -> void:
	is_died = true
	entity.is_died = true
	# 没做死亡特效，暂时先用受伤特效，否则最后击杀目标后没有任何特效
	_hurted_effect()
	# -------------------------------------------------播放死亡特效------------------------------------------------       
	# 保存当前位置用于特效播放
	if die_effect and die_audio: 
		var effect_pos = die_effect.global_position
		var effect_instance = die_effect.duplicate()
		var audio_instance = die_audio.duplicate()	
		# 将特效添加到场景树
		get_tree().root.add_child(effect_instance)
		get_tree().root.add_child(audio_instance)
		# 设置特效位置并播放
		effect_instance.global_position = effect_pos
		effect_instance.z_index = 3
		effect_instance.restart()
		audio_instance.play()
		# 设置特效和音频完成后自动销毁
		effect_instance.one_shot = true  # 确保只播放一次
		var timer = get_tree().create_timer(effect_instance.lifetime + 0.1)
		timer.timeout.connect(func(): effect_instance.queue_free())
		audio_instance.finished.connect(audio_instance.queue_free)
	# -------------------------------------------------播放死亡特效------------------------------------------------   
	entity.queue_free()
	
		
		
func _hurted_effect() -> void:
	# 音频部分先空着
	var effect_pos = hurted_effect.global_position
	var effect_instance = hurted_effect.duplicate()
	#var audio_instance = die_audio.duplicate()	
	# 将特效添加到场景树
	get_tree().root.add_child(effect_instance)
	#get_tree().root.add_child(audio_instance)
	# 设置特效位置并播放
	effect_instance.global_position = effect_pos
	effect_instance.z_index = 3
	effect_instance.restart()
	#audio_instance.play()
	# 设置特效和音频完成后自动销毁
	effect_instance.one_shot = true  # 确保只播放一次
	var timer = get_tree().create_timer(effect_instance.lifetime + 0.1)
	timer.timeout.connect(func(): effect_instance.queue_free())
	#audio_instance.finished.connect(audio_instance.queue_free)
	
