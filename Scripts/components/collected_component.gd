# 被收集物体（道具，武器，补给，可交互场景） 可挂在该组件
class_name collected_component #假如这行报错不要管！！
extends Node2D

signal be_collected

func _ready() -> void:
	be_collected.connect(_on_collected)


func _on_collected(collector_area: Area2D) -> void:
	print("COLLECT!")
