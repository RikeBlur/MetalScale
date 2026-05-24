# 伤害接收（受伤）组件
class_name hurted_component #假如这行报错不要管！！
extends Node2D

signal npc_kill_player(damage_source: npc)

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

@export var entity : CharacterBody2D = null
@export var invisible: bool = false
# 当前血量
var health_max : float = 100
var health : float = 100

var is_died : bool = false
var invincible: bool = false

func _ready() -> void:
	_resolve_required_nodes()
	if not _validate_required_nodes():
		set_process(false)
		return

	health_max = entity.health_max
	health = health_max
	# 受击闪烁特效
	if not hit_flash_player :
		hit_flash_player = entity.find_child("FlashAnimation", true, false) as AnimationPlayer
	
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
	if health_bar and entity and not is_died :
		_update_health_bar_position()
	
	
# 更新HealthBar位置
func _update_health_bar_position() -> void:
	if not entity or not health_bar:
		return

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
func _on_hurt(amount : float, damage_source: CharacterBody2D = null) -> void:
	if invisible or invincible or not entity:
		return

	if (health - amount) > 0:
		health -= amount
		entity.health_now = health
		# 播放粒子特效
		_play_hurted_feedback()
		if health_bar: health_bar.change_value(health)
		print("health:",health)
	elif not is_died :
		if _try_start_chasing_1_special_death(damage_source):
			return
		print("DIED")
		on_died(damage_source)
	#如果有收击闪烁，则播放受击闪烁
	if hit_flash_player :
		# 停止当前动画并重新播放
		hit_flash_player.stop()
		hit_flash_player.play("hit")
		# 或者使用以下方式强制播放
		 #hit_flash_player.play("hit", -1, 1.0, true)
	_emit_entity_hurted()


func set_invincible(value: bool) -> void:
	invincible = value


func sync_health_from_entity() -> void:
	if not entity:
		return
	health_max = entity.health_max
	health = clamp(entity.health_now, 0.0, health_max)
	is_died = entity.is_died
	if health_bar:
		health_bar.change_value(health)


func _try_start_chasing_1_special_death(damage_source: CharacterBody2D = null) -> bool:
	if not (entity is player):
		return false
	if not GameManager.chasing_1_prepare:
		return false
	if not (damage_source is EnemyEye):
		return false

	var preserved_health: float = health
	entity.health_now = preserved_health
	entity.is_died = false
	is_died = false
	if health_bar:
		health_bar.change_value(health)
	if GameManager.has_method("notify_chasing_1_eye_caught_player"):
		GameManager.notify_chasing_1_eye_caught_player(entity, damage_source, preserved_health)
	_emit_entity_hurted()
	return true
		
# 死亡处理
func on_died(damage_source: CharacterBody2D = null) -> void:
	is_died = true
	entity.health_now = 0.0
	health = 0.0
	if health_bar:
		health_bar.change_value(health)
	_play_die_feedback()
	if entity is player and entity.has_method("player_died"):
		if damage_source is npc:
			npc_kill_player.emit(damage_source)
		entity.player_died()
		return
	entity.is_died = true
	# 没做死亡特效，暂时先用受伤特效，否则最后击杀目标后没有任何特效
	#_hurted_effect()
	# -------------------------------------------------播放死亡特效------------------------------------------------       
	# -------------------------------------------------播放死亡特效------------------------------------------------   
	entity.queue_free()
	
		
		
func _resolve_required_nodes() -> void:
	if not entity:
		entity = get_parent() as CharacterBody2D
	if not hurted_area:
		for child in get_children():
			if child is Area2D:
				hurted_area = child
				break


func _validate_required_nodes() -> bool:
	var is_valid := true
	if not hurted_area:
		push_error("%s needs a Hurted Area (Area2D child or exported value)." % name)
		is_valid = false
	if not entity:
		push_error("%s needs an Entity (CharacterBody2D parent or exported value)." % name)
		is_valid = false
	return is_valid


func _emit_entity_hurted() -> void:
	if entity and entity.has_signal("player_hurted"):
		entity.emit_signal("player_hurted")


func _play_hurted_feedback() -> void:
	if hurted_audio:
		hurted_audio.play()
	if hurted_effect:
		_spawn_particle_effect(hurted_effect)


func _play_die_feedback() -> void:
	if die_effect:
		_spawn_particle_effect(die_effect)
	if die_audio:
		_play_detached_audio(die_audio)


func _spawn_particle_effect(effect: GPUParticles2D) -> void:
	var effect_instance := effect.duplicate() as GPUParticles2D
	if not effect_instance:
		return
	get_tree().root.add_child(effect_instance)
	effect_instance.global_position = effect.global_position
	effect_instance.z_index = 3
	effect_instance.one_shot = true
	effect_instance.restart()
	var timer := get_tree().create_timer(effect_instance.lifetime + 0.1)
	timer.timeout.connect(func():
		if is_instance_valid(effect_instance):
			effect_instance.queue_free()
	)


func _play_detached_audio(audio: AudioStreamPlayer2D) -> void:
	var audio_instance := audio.duplicate() as AudioStreamPlayer2D
	if not audio_instance:
		return
	get_tree().root.add_child(audio_instance)
	audio_instance.global_position = audio.global_position
	audio_instance.play()
	audio_instance.finished.connect(audio_instance.queue_free)


func _hurted_effect() -> void:
	if hurted_effect:
		_spawn_particle_effect(hurted_effect)
	
