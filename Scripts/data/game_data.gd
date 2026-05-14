class_name GameData
extends Resource

@export var switch_on: bool = false
@export var player_arrgo: int = 0
@export var arrgo_in_threshold: float = 10.0
@export var default_lighting: Color = Color(0.21, 0.157, 0.157, 1.0)
@export var chasing_1_prepare: bool = false


func from_game_manager(game_manager_node: game_manager) -> void:
	if not game_manager_node:
		push_error("GameData: game_manager node is null")
		return

	switch_on = game_manager_node.switch_on
	player_arrgo = game_manager_node.player_arrgo
	arrgo_in_threshold = game_manager_node.arrgo_in_threshold
	default_lighting = game_manager_node.default_lighting
	chasing_1_prepare = game_manager_node.chasing_1_prepare


func apply_to_game_manager(game_manager_node: game_manager) -> void:
	if not game_manager_node:
		push_error("GameData: game_manager node is null")
		return

	game_manager_node.switch_on = switch_on
	game_manager_node.player_arrgo = player_arrgo
	game_manager_node.arrgo_in_threshold = arrgo_in_threshold
	game_manager_node.default_lighting = default_lighting
	game_manager_node.chasing_1_prepare = chasing_1_prepare


func to_dict() -> Dictionary:
	return {
		"switch_on": switch_on,
		"player_arrgo": player_arrgo,
		"arrgo_in_threshold": arrgo_in_threshold,
		"default_lighting": {
			"r": default_lighting.r,
			"g": default_lighting.g,
			"b": default_lighting.b,
			"a": default_lighting.a
		},
		"chasing_1_prepare": chasing_1_prepare
	}


func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		return

	if data.has("switch_on"):
		switch_on = bool(data["switch_on"])
	if data.has("player_arrgo"):
		player_arrgo = int(data["player_arrgo"])
	if data.has("arrgo_in_threshold"):
		arrgo_in_threshold = float(data["arrgo_in_threshold"])
	if data.has("default_lighting"):
		default_lighting = _color_from_variant(data["default_lighting"], default_lighting)
	if data.has("chasing_1_prepare"):
		chasing_1_prepare = bool(data["chasing_1_prepare"])


func _color_from_variant(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value

	if value is Dictionary:
		var color_dict: Dictionary = value
		return Color(
			float(color_dict.get("r", fallback.r)),
			float(color_dict.get("g", fallback.g)),
			float(color_dict.get("b", fallback.b)),
			float(color_dict.get("a", fallback.a))
		)

	return fallback
