class_name environment_manager
extends Node

const world_of_wonder: Environment = preload("res://Style/environment/WorldOfWonder.tres")
const ARRGOING_EFFECT_KEY: String = "arrgoing"
const ARRGOED_EFFECT_KEY: String = "arrgoed"
const ARRGOING_SHADER_PARAMETERS: Array[StringName] = [
	&"scanlines_opacity",
	&"scanlines_width",
	&"grille_opacity"
]
const ARRGOING_PARAMETER_MAX: float = 0.25

@export_file("*.tscn") var arrgoing_scene_path: String = "res://Effect/Shader/crt/arrgoing.tscn"
@export_file("*.tscn") var arrgoed_scene_path: String = "res://Effect/Shader/crt/arrgoed.tscn"
@export var arrgo_effect_layer: int = 4
@export var arrgo_fade_in_duration: float = 0.35
@export var arrgo_fade_out_duration: float = 1.0

var _arrgo_effect_layer: CanvasLayer = null
var _arrgo_effect_nodes: Dictionary = {}
var _arrgo_effect_rects: Dictionary = {}
var _arrgo_effect_fade_targets: Dictionary = {}
var _arrgo_effect_tweens: Dictionary = {}
var _arrgo_effect_scenes: Dictionary = {}

func _ready() -> void:
	SceneManager.player_reseted.connect(set_environment)
	_connect_arrgo_signals()
	_ensure_arrgo_effect_layer()

func _process(_delta: float) -> void:
	_update_arrgoing_material_parameters()

func set_environment() -> void:
	var environment_now := _get_world_environment()
	if not environment_now:
		push_warning("EnvironmentManager: 当前场景未找到 WorldOfWonder")
		return

	environment_now.environment = world_of_wonder
	var lighting_modulate: CanvasModulate = environment_now.get_node_or_null("CanvasModulate")
	if lighting_modulate:
		lighting_modulate.color = GameManager.default_lighting

	_clear_invalid_effect_refs()
	_restore_arrgo_effects_for_current_state()

# =========================== 视效设置 ===============================

func _connect_arrgo_signals() -> void:
	if not GameManager.get_in_arrgo.is_connected(_on_get_in_arrgo):
		GameManager.get_in_arrgo.connect(_on_get_in_arrgo)
	if not GameManager.get_out_arrgo.is_connected(_on_get_out_arrgo):
		GameManager.get_out_arrgo.connect(_on_get_out_arrgo)
	if not GameManager.arrgoed.is_connected(_on_arrgoed):
		GameManager.arrgoed.connect(_on_arrgoed)
	if not GameManager.not_arrgoed.is_connected(_on_not_arrgoed):
		GameManager.not_arrgoed.connect(_on_not_arrgoed)

func _on_get_in_arrgo() -> void:
	_fade_in_arrgo_effect(ARRGOING_EFFECT_KEY)

func _on_get_out_arrgo() -> void:
	_fade_out_arrgo_effect(ARRGOING_EFFECT_KEY)

func _on_arrgoed() -> void:
	_fade_out_arrgo_effect(ARRGOING_EFFECT_KEY)
	_fade_in_arrgo_effect(ARRGOED_EFFECT_KEY)

func _on_not_arrgoed() -> void:
	_fade_out_arrgo_effect(ARRGOED_EFFECT_KEY)

func _fade_in_arrgo_effect(effect_key: String) -> void:
	var effect_node := _get_or_create_arrgo_effect_node(effect_key)
	if not effect_node:
		return

	var fade_target := _get_valid_canvas_item(_arrgo_effect_fade_targets, effect_key)
	if not fade_target:
		return

	var tween := _get_valid_tween(effect_key)
	if tween and tween.is_valid():
		tween.kill()

	fade_target.visible = true
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fade_target, "modulate:a", 1.0, arrgo_fade_in_duration)
	_arrgo_effect_tweens[effect_key] = tween

	if effect_key == ARRGOING_EFFECT_KEY:
		_update_arrgoing_material_parameters()

func _fade_out_arrgo_effect(effect_key: String) -> void:
	var effect_node := _get_valid_node(_arrgo_effect_nodes, effect_key)
	if not effect_node:
		_erase_effect_refs(effect_key)
		return

	var fade_target := _get_valid_canvas_item(_arrgo_effect_fade_targets, effect_key)
	if not fade_target:
		effect_node.queue_free()
		_erase_effect_refs(effect_key)
		return

	var tween := _get_valid_tween(effect_key)
	if tween and tween.is_valid():
		tween.kill()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(fade_target, "modulate:a", 0.0, arrgo_fade_out_duration)
	tween.finished.connect(_on_arrgo_effect_faded_out.bind(effect_key, effect_node))
	_arrgo_effect_tweens[effect_key] = tween

func _on_arrgo_effect_faded_out(effect_key: String, effect_node: Node) -> void:
	if _get_valid_node(_arrgo_effect_nodes, effect_key) == effect_node:
		_erase_effect_refs(effect_key)
	if effect_node and is_instance_valid(effect_node):
		effect_node.queue_free()

func _get_or_create_arrgo_effect_node(effect_key: String) -> Node:
	var existing := _get_valid_node(_arrgo_effect_nodes, effect_key)
	if existing:
		return existing

	var effect_parent := _ensure_arrgo_effect_layer()
	if not effect_parent:
		return null

	var packed_scene := _get_effect_scene(effect_key)
	if not packed_scene:
		return null

	var effect_node := packed_scene.instantiate()
	effect_node.name = "%sEffect" % effect_key.capitalize()
	effect_parent.add_child(effect_node)

	var effect_rect := _find_effect_color_rect(effect_node)
	if not effect_rect:
		push_warning("EnvironmentManager: %s 视效场景根节点或子节点中未找到 ColorRect" % effect_key)
		effect_node.queue_free()
		return null

	_prepare_color_rect(effect_rect)
	var fade_target := _get_fade_target(effect_node, effect_rect)
	fade_target.modulate.a = 0.0
	fade_target.visible = true

	_arrgo_effect_nodes[effect_key] = effect_node
	_arrgo_effect_rects[effect_key] = effect_rect
	_arrgo_effect_fade_targets[effect_key] = fade_target

	return effect_node

func _get_effect_scene(effect_key: String) -> PackedScene:
	var scene_path := _get_effect_scene_path(effect_key)
	if scene_path == "":
		push_warning("EnvironmentManager: %s 视效场景路径未设置" % effect_key)
		return null

	if _arrgo_effect_scenes.has(effect_key):
		return _arrgo_effect_scenes[effect_key] as PackedScene

	if not ResourceLoader.exists(scene_path):
		push_warning("EnvironmentManager: %s 视效场景不存在: %s" % [effect_key, scene_path])
		return null

	var packed_scene := load(scene_path) as PackedScene
	if not packed_scene:
		push_warning("EnvironmentManager: %s 视效场景不是 PackedScene: %s" % [effect_key, scene_path])
		return null

	_arrgo_effect_scenes[effect_key] = packed_scene
	return packed_scene

func _get_effect_scene_path(effect_key: String) -> String:
	match effect_key:
		ARRGOING_EFFECT_KEY:
			return arrgoing_scene_path
		ARRGOED_EFFECT_KEY:
			return arrgoed_scene_path
	return ""

func _find_effect_color_rect(node: Node) -> ColorRect:
	if node is ColorRect:
		return node

	for child in node.get_children():
		var result := _find_effect_color_rect(child)
		if result:
			return result

	return null

func _prepare_color_rect(rect: ColorRect) -> void:
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = true

	if rect.material:
		rect.material = rect.material.duplicate(true)

func _get_fade_target(effect_node: Node, effect_rect: ColorRect) -> CanvasItem:
	if effect_node is CanvasItem:
		return effect_node as CanvasItem
	return effect_rect

func _update_arrgoing_material_parameters() -> void:
	var rect := _get_valid_color_rect(_arrgo_effect_rects, ARRGOING_EFFECT_KEY)
	if not rect:
		return

	var material := rect.material as ShaderMaterial
	if not material:
		return

	var target_value := _get_arrgoing_parameter_value()
	for parameter_name in ARRGOING_SHADER_PARAMETERS:
		material.set_shader_parameter(parameter_name, target_value)

func _get_arrgoing_parameter_value() -> float:
	var player_node := GameManager.get_player()
	if not player_node or not is_instance_valid(player_node):
		return 0.0
	if not ("aggro_value" in player_node):
		return 0.0

	return clamp(player_node.aggro_value / 100.0, 0.0, 1.0) * ARRGOING_PARAMETER_MAX

func _restore_arrgo_effects_for_current_state() -> void:
	if GameManager.player_arrgo == 2:
		_fade_in_arrgo_effect(ARRGOED_EFFECT_KEY)
	elif GameManager.player_arrgo > 0:
		_fade_in_arrgo_effect(ARRGOING_EFFECT_KEY)

func _clear_invalid_effect_refs() -> void:
	for effect_key in _arrgo_effect_nodes.keys():
		if not _is_valid_instance(_arrgo_effect_nodes.get(effect_key)):
			_erase_effect_refs(effect_key)

func _erase_effect_refs(effect_key: String) -> void:
	var tween := _get_valid_tween(effect_key)
	if tween and tween.is_valid():
		tween.kill()
	_arrgo_effect_nodes.erase(effect_key)
	_arrgo_effect_rects.erase(effect_key)
	_arrgo_effect_fade_targets.erase(effect_key)
	_arrgo_effect_tweens.erase(effect_key)

func _ensure_arrgo_effect_layer() -> CanvasLayer:
	if _arrgo_effect_layer and is_instance_valid(_arrgo_effect_layer):
		_arrgo_effect_layer.layer = arrgo_effect_layer
		return _arrgo_effect_layer

	_arrgo_effect_layer = get_node_or_null("ArrgoEffectLayer") as CanvasLayer
	if not _arrgo_effect_layer:
		_arrgo_effect_layer = CanvasLayer.new()
		_arrgo_effect_layer.name = "ArrgoEffectLayer"
		add_child(_arrgo_effect_layer)

	_arrgo_effect_layer.layer = arrgo_effect_layer
	return _arrgo_effect_layer

func _get_valid_node(source: Dictionary, key: String) -> Node:
	var value = source.get(key)
	if not _is_valid_instance(value):
		return null
	return value as Node

func _get_valid_canvas_item(source: Dictionary, key: String) -> CanvasItem:
	var value = source.get(key)
	if not _is_valid_instance(value):
		return null
	return value as CanvasItem

func _get_valid_color_rect(source: Dictionary, key: String) -> ColorRect:
	var value = source.get(key)
	if not _is_valid_instance(value):
		return null
	return value as ColorRect

func _get_valid_tween(effect_key: String) -> Tween:
	var value = _arrgo_effect_tweens.get(effect_key)
	if not _is_valid_instance(value):
		return null
	return value as Tween

func _is_valid_instance(value: Variant) -> bool:
	return value != null and is_instance_valid(value)

func _get_world_environment() -> WorldEnvironment:
	var current_scene := get_tree().current_scene
	if not current_scene:
		return null
	return current_scene.get_node_or_null("WorldOfWonder") as WorldEnvironment

# ==================================================================
