extends Resource
class_name Tools

# -----[ 1. 基础工具类型 ]-----
# 定义了所有工具共有的基础类别

# 基础工具父类
class Tool:
	enum Type { PERMANENT, DURABILITY, CONSUMABLE }
	var type: Type

# 永久工具：无限制使用
class PermanentTool extends Tool:
	func _init():
		type = Type.PERMANENT

# 耐久工具：有耐久度限制
class DurabilityTool extends Tool:
	var durability: float = 100.0
	func _init():
		type = Type.DURABILITY

# 消耗品：有使用次数限制
class ConsumableTool extends Tool:
	var amount: int = 1
	func _init():
		type = Type.CONSUMABLE


# -----[ 2. 具体工具实现 ]-----
# 继承自上面的基础类型，定义游戏中的实际工具

# 空工具
class NoneTool extends PermanentTool:
	func _init():
		super()

# 应急灯 (原 EmergenceLight)
class EmergencyLight extends DurabilityTool:
	func _init(p_durability: float = 100.0):
		super()
		durability = p_durability

# 肾上腺素 (原 Adreanaline)
class Adrenaline extends ConsumableTool:
	func _init(p_amount: int = 1):
		super()
		amount = p_amount 
