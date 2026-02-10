class_name ElectronicScreen
extends Node2D

var player_now: CharacterBody2D = null
var activated: bool = false

func _ready() -> void:
	player_now = GlobalFunction.get_player()
	_connect_arrgobar_signals()

func _process(_delta: float) -> void:
	# 持续从 GameManager 同步玩家仇恨状态
	activated = GameManager.player_arrgo

func _connect_arrgobar_signals() -> void:
	"""连接玩家 ArrgoComponent 的信号"""
	if not player_now or not is_instance_valid(player_now):
		return
	
	var arrgo = player_now.get_node_or_null("arrgo_component")
	if not arrgo or not (arrgo is ArrgoComponent):
		return
	
	# 连接信号：get_caught 时显示，get_uncaught 时隐藏
	if not arrgo.get_caught.is_connected(_on_player_get_caught):
		arrgo.get_caught.connect(_on_player_get_caught)
	if not arrgo.get_uncaught.is_connected(_on_player_get_uncaught):
		arrgo.get_uncaught.connect(_on_player_get_uncaught)


func _on_player_get_caught() -> void:
	"""玩家被发现时"""
	pass


func _on_player_get_uncaught() -> void:
	"""玩家脱离视线"""
	pass
