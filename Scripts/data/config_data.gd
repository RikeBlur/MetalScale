class_name ConfigData
extends Resource

@export var BGM_gain: float = 100.0
@export var SFX_gain: float = 100.0
@export var Gamma: float = 1.0
@export var end_1: bool = false

func from_game_manager(game_manager_node: game_manager) -> void:
	if not game_manager_node:
		push_error("ConfigData: game_manager node is null")
		return

	BGM_gain = game_manager_node.BGM_gain
	SFX_gain = game_manager_node.SFX_gain
	Gamma = game_manager_node.Gamma
	end_1 = game_manager_node.end_1

func apply_to_game_manager(game_manager_node: game_manager, apply_gamma_effect: bool = true) -> void:
	if not game_manager_node:
		push_error("ConfigData: game_manager node is null")
		return

	game_manager_node.BGM_gain = BGM_gain
	game_manager_node.SFX_gain = SFX_gain
	game_manager_node.end_1 = end_1
	if apply_gamma_effect:
		game_manager_node.set_gamma(Gamma)
	else:
		game_manager_node.Gamma = Gamma
