class_name interacted_component
extends Node2D

@export var interacted_rage : Area2D = null
var inter_com : interact_component = null

signal interacted
signal be_interactable
signal be_not_interactable

func _ready() -> void:
	if interacted_rage == null :
		print("Automic interacted rage")
		interacted_rage = get_parent()
	
	# 检查并设置碰撞层和碰撞遮罩
	if interacted_rage.collision_layer != 8 or interacted_rage.collision_mask != 7:
		interacted_rage.collision_layer = 8
		interacted_rage.collision_mask = 7
	
	interacted_rage.connect("area_entered", Callable(self, "_inter_com_get_in"))
	interacted_rage.connect("area_exited", Callable(self, "_inter_com_get_out"))
	
func _inter_com_get_in(area: Area2D) -> void:
	var intercom = area.get_child(0)
	if intercom is interact_component :
		inter_com = intercom
		inter_com.connect("interact", Callable(self, "_on_interact"))
		be_interactable.emit()
		#print("interact component get in")
	else :
		print("Can't Find Interact Component")
		return

func _inter_com_get_out(area: Area2D) -> void:
	var intercom = area.get_child(0)
	if intercom is interact_component :
		inter_com.disconnect("interact", Callable(self, "_on_interact"))
		inter_com = null
		print("interact component get out")
		be_not_interactable.emit()
	else :
		print("Can't Find Interact Component")
		return

func _on_interact() -> void:
	print("INTERACTED!!")
	interacted.emit()
