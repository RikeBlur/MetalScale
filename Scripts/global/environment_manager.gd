class_name environment_manager
extends Node

const world_of_wonder: Environment = preload("res://Style/environment/WorldOfWonder.tres")

func _ready() -> void:
	SceneManager.player_reseted.connect(set_environment)

func set_environment() -> void:
	var environment_now: WorldEnvironment = get_tree().current_scene.get_node("WorldOfWonder")
	environment_now.environment = world_of_wonder
	var lighting_modulate: CanvasModulate = environment_now.get_node("CanvasModulate")
	lighting_modulate.color = GameManager.default_lighting
