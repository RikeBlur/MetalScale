# 玩家角色或其他可以收集道具的个体 挂载该组件
class_name collecting_component #假如这行报错不要管！！
extends Node2D

# 收集物体特效
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var collect_effect: GPUParticles2D = $"CollectEffect"

# 收集探测器
@export var detector_area : Area2D = null

func _ready() -> void:
	detector_area.area_entered.connect(_on_collect_detector_entered)


func _on_collect_detector_entered(area: Area2D) -> void:
	if area.is_in_group("collectable") and area != self:  # 确保不是自己
		var body = Tools._find_rigid_body_parent(area)
		var collected = area.find_child("CollectedComponent")
		if collected and collected is collected_component:
		# 将 被收集探测器 的 可收集属性 移除，避免反复收集
			area.remove_from_group("collectable")
			collected.be_collected.emit(detector_area)
		# 播放 收集特效
		play_effect(self, body)
	else:
		return


# 收集特效
func play_effect(node1 : Node2D, node2 : Node2D) -> void:
	audio_player.play()
	# 将特效位置设置在 收集者 和 被收集者 之间
	var pos = (node1.get("global_position") + node2.get("global_position"))/2
	collect_effect.set("global_position", pos)
	collect_effect.restart()
