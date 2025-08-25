# 伤害造成组件
class_name damage_component #假如这行报错不要管！！
extends Node2D

# hit box
@export var damage_area : Area2D = null
@export var entity : CharacterBody2D = null

# 目标组（只对此组造成伤害，如"enemy"或"player"）
@export var target_group : String = ""

# 伤害增益因子
@export var damage_factor : float = 1.0
# 最小伤害阈值
@export var min_damage : float = 1.0
# 最大伤害上限
@export var max_damage : float = 100.0
# 伤害基数
@export var base_damage_num : float = 10.0

# 冷却时间（秒）
@export var damage_cooldown : float = 0.0
# 区域冷却时间字典，为每个区域单独计算冷却时间
var area_cooldowns : Dictionary = {}


func _ready() -> void:
	assert(damage_area != null, "伤害组件需要一个伤害判定区域DamageArea")
	# 获取Rigid
	if not entity:
		entity = Tools._find_character_body_parent(damage_area)
	# 连接信号
	if damage_area:
		damage_area.area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	# 减少每个区域的冷却时间
	var areas_to_remove = []
	for area_id in area_cooldowns.keys():
		area_cooldowns[area_id] -= delta
		# 如果冷却时间结束，移除该区域的冷却计时
		if area_cooldowns[area_id] <= 0:
			areas_to_remove.append(area_id)
	
	# 移除已完成冷却的区域
	for area_id in areas_to_remove:
		area_cooldowns.erase(area_id)


# 当damage_area与其他Area2D接触时调用
func _on_area_entered(area: Area2D) -> void:
	# 避免自身碰撞
	if area != damage_area:
		# 检查父节点是否是hurted_component
		var parent = area.get_parent()
		
		if parent and parent is hurted_component:
			var hurted_comp = parent
			var hurted_entity = Tools._find_character_body_parent(area)
			
			# 检查目标组
			if target_group != "" and hurted_entity and not hurted_entity.is_in_group(target_group):
				return  # 如果设置了目标组但实体不在该组中，则忽略
			
			# 获取区域的唯一标识符
			var area_id = area.get_instance_id()
			
			# 确保不是自身实体且该特定区域不在冷却中
			if hurted_entity != entity and (not area_id in area_cooldowns or area_cooldowns[area_id] <= 0):
				# 计算伤害值
				var damage_amount = calculate_damage(base_damage_num)
				
				# 如果伤害值大于最小阈值，应用伤害
				if damage_amount > min_damage:
					# 对hurt_component应用伤害
					hurted_comp._on_hurt(damage_amount)
					# 设置该区域的冷却计时器
					area_cooldowns[area_id] = damage_cooldown
					# 可选：添加打击感效果或音效
					# play_hit_effect()


# 计算伤害值
func calculate_damage(base_num : float) -> float:
	# 基础伤害计算公式：伤害基数 × 伤害因子
	var damage = base_num * damage_factor 
	# 限制在最小和最大伤害范围内
	damage = clamp(damage, min_damage, max_damage)
	return damage


# 可选：添加打击效果（抖动、粒子等）
func play_hit_effect() -> void:
	pass
