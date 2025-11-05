extends Node2D


func _ready() -> void:
	"""
	初始化开场场景
	
	功能:
		- 读取 player 和 camera 场景资源
		- 将场景资源传递给 GameManager
	"""
	# 加载 Player 场景
	var player_scene: PackedScene = load("res://System/RPG/entity/controllable/player_Oni.tscn")
	if player_scene:
		GameManager.packed_player = player_scene
		print("Opening: Player 场景已加载并传递给 GameManager")
	else:
		push_error("Opening: 无法加载 Player 场景")
	
	# 加载 Camera 场景
	var camera_scene: PackedScene = load("res://System/RPG/entity/camera.tscn")
	if camera_scene:
		GameManager.packed_camera = camera_scene
		print("Opening: Camera 场景已加载并传递给 GameManager")
	else:
		push_error("Opening: 无法加载 Camera 场景")
