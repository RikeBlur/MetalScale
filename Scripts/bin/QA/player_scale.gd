class_name player_scale
extends Node2D

# MBTI性格特质属性
@export var Introverted: float = 0.0      # 内向型
@export var Extraverted: float = 0.0      # 外向型
@export var Observant: float = 0.0        # 观察型 (Sensing)
@export var Intuitive: float = 0.0        # 直觉型
@export var Thinking: float = 0.0         # 思考型
@export var Feeling: float = 0.0          # 情感型
@export var Judging: float = 0.0          # 判断型
@export var Prospecting: float = 0.0      # 探索型 (Perceiving)

# 可选：设置数值变化的范围限制
@export var min_value: float = -100.0
@export var max_value: float = 100.0
@export var default_change_amount: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("玩家量表系统初始化完成")
	print_current_scales()

# 内向型数值改变
func change_I(amount: float = default_change_amount) -> void:
	Introverted = clamp(Introverted + amount, min_value, max_value)
	print("内向型数值变化: +", amount, " 当前值: ", Introverted)

# 外向型数值改变
func change_E(amount: float = default_change_amount) -> void:
	Extraverted = clamp(Extraverted + amount, min_value, max_value)
	print("外向型数值变化: +", amount, " 当前值: ", Extraverted)

# 观察型数值改变 (Sensing)
func change_S(amount: float = default_change_amount) -> void:
	Observant = clamp(Observant + amount, min_value, max_value)
	print("观察型数值变化: +", amount, " 当前值: ", Observant)

# 直觉型数值改变
func change_N(amount: float = default_change_amount) -> void:
	Intuitive = clamp(Intuitive + amount, min_value, max_value)
	print("直觉型数值变化: +", amount, " 当前值: ", Intuitive)

# 思考型数值改变
func change_T(amount: float = default_change_amount) -> void:
	Thinking = clamp(Thinking + amount, min_value, max_value)
	print("思考型数值变化: +", amount, " 当前值: ", Thinking)

# 情感型数值改变
func change_F(amount: float = default_change_amount) -> void:
	Feeling = clamp(Feeling + amount, min_value, max_value)
	print("情感型数值变化: +", amount, " 当前值: ", Feeling)

# 判断型数值改变
func change_J(amount: float = default_change_amount) -> void:
	Judging = clamp(Judging + amount, min_value, max_value)
	print("判断型数值变化: +", amount, " 当前值: ", Judging)

# 探索型数值改变 (Perceiving)
func change_P(amount: float = default_change_amount) -> void:
	Prospecting = clamp(Prospecting + amount, min_value, max_value)
	print("探索型数值变化: +", amount, " 当前值: ", Prospecting)

# 获取当前所有量表数值
func get_all_scales() -> Dictionary:
	return {
		"Introverted": Introverted,
		"Extraverted": Extraverted,
		"Observant": Observant,
		"Intuitive": Intuitive,
		"Thinking": Thinking,
		"Feeling": Feeling,
		"Judging": Judging,
		"Prospecting": Prospecting
	}

# 打印当前所有量表数值
func print_current_scales() -> void:
	print("=== 当前玩家量表数值 ===")
	print("内向型 (I): ", Introverted)
	print("外向型 (E): ", Extraverted)
	print("观察型 (S): ", Observant)
	print("直觉型 (N): ", Intuitive)
	print("思考型 (T): ", Thinking)
	print("情感型 (F): ", Feeling)
	print("判断型 (J): ", Judging)
	print("探索型 (P): ", Prospecting)
	print("========================")

# 重置所有量表数值
func reset_all_scales() -> void:
	Introverted = 0.0
	Extraverted = 0.0
	Observant = 0.0
	Intuitive = 0.0
	Thinking = 0.0
	Feeling = 0.0
	Judging = 0.0
	Prospecting = 0.0
	print("所有量表数值已重置")

# 计算MBTI倾向结果
func get_mbti_result() -> String:
	var result = ""
	
	# E/I 维度
	result += "E" if Extraverted > Introverted else "I"
	
	# S/N 维度
	result += "S" if Observant > Intuitive else "N"
	
	# T/F 维度
	result += "T" if Thinking > Feeling else "F"
	
	# J/P 维度
	result += "J" if Judging > Prospecting else "P"
	
	return result

# 获取维度差值（用于分析倾向强度）
func get_dimension_differences() -> Dictionary:
	return {
		"E_I_diff": Extraverted - Introverted,
		"S_N_diff": Observant - Intuitive,
		"T_F_diff": Thinking - Feeling,
		"J_P_diff": Judging - Prospecting
	}
