class_name SelfTalkManager
extends Node2D

enum SelfTalkType {
	DEFAULT,
	TRIGGER
}

enum TriggerCondition {
	NONE,
	HAS_ELECTRONIC_SCREEN,
	FIX_SWITCH,
	MEET_SLAYER,
	SULFUR_SCENE_SWITCH_ON
}

const SULFUR_SCENE_KEYS: Array[String] = ["1-1", "1-2", "1-4", "1-0", "1-8", "1-7"]
const TALK_TEXT_KEY: String = "text"
const TALK_TYPE_KEY: String = "type"
const TALK_PROBABILITY_KEY: String = "probability"
const TALK_CONDITION_KEY: String = "condition"

@export var player_now: player = null
@export var self_talk_update_time: float = 3.0
@export var self_talk_list: Array[Dictionary] = [
	{
		"text": "好黑，看不清窗外的景色啊...是深夜吗。",
		"type": SelfTalkType.DEFAULT,
		"probability": 0.33333334,
		"condition": TriggerCondition.NONE
	},
	{
		"text": "空气里有种怀念的感觉。",
		"type": SelfTalkType.DEFAULT,
		"probability": 0.33333333,
		"condition": TriggerCondition.NONE
	},
	{
		"text": "能听到不像人类的脚步声。果然还是在做梦吗...",
		"type": SelfTalkType.DEFAULT,
		"probability": 0.33333333,
		"condition": TriggerCondition.NONE
	},
	{
		"text": "电力似乎出问题了，但这些屏幕为什么还亮着...",
		"type": SelfTalkType.TRIGGER,
		"probability": 0.25,
		"condition": TriggerCondition.HAS_ELECTRONIC_SCREEN
	},
	{
		"text": "修好了！真的假的...",
		"type": SelfTalkType.TRIGGER,
		"probability": 1.00,
		"condition": TriggerCondition.FIX_SWITCH
	},
	{
		"text": "好浓的血腥。",
		"type": SelfTalkType.TRIGGER,
		"probability": 0.90,
		"condition": TriggerCondition.MEET_SLAYER
	},
	{
		"text": "闻起来像...硫磺",
		"type": SelfTalkType.TRIGGER,
		"probability": 0.90,
		"condition": TriggerCondition.SULFUR_SCENE_SWITCH_ON
	}
]

var current_self_talk_index: int = -1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _time_since_last_check: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_initialize_player()
	_connect_scene_manager()
	initialize_default_self_talk()


func _process(delta: float) -> void:
	if not _has_valid_player():
		_initialize_player()
		if not _has_valid_player():
			return

	var safe_update_time: float = max(self_talk_update_time, 0.1)
	_time_since_last_check += delta
	if _time_since_last_check < safe_update_time:
		return

	_time_since_last_check = 0.0
	_try_apply_trigger_self_talk()


func setup(target_player: player) -> void:
	if target_player and is_instance_valid(target_player):
		player_now = target_player
	_connect_scene_manager()
	if current_self_talk_index < 0:
		initialize_default_self_talk()


func initialize_default_self_talk() -> void:
	if not _has_valid_player():
		_initialize_player()
	if not _has_valid_player():
		return

	var default_index: int = _pick_default_self_talk_index()
	if default_index >= 0:
		_apply_self_talk(default_index)
	_time_since_last_check = 0.0


func _initialize_player() -> void:
	if _has_valid_player():
		return

	var parent_node: Node = get_parent()
	if parent_node is player:
		player_now = parent_node as player
		return

	if GameManager and GameManager.has_method("get_player"):
		player_now = GameManager.get_player()


func _connect_scene_manager() -> void:
	if not SceneManager:
		return

	var reset_callable: Callable = Callable(self, "_on_player_reseted")
	if not SceneManager.player_reseted.is_connected(reset_callable):
		SceneManager.player_reseted.connect(reset_callable)


func _on_player_reseted() -> void:
	_initialize_player()
	initialize_default_self_talk()


func _pick_default_self_talk_index() -> int:
	var candidate_indices: Array[int] = []
	var total_probability: float = 0.0

	for i in range(self_talk_list.size()):
		var talk: Dictionary = self_talk_list[i]
		if _get_talk_type(talk) != SelfTalkType.DEFAULT:
			continue

		var probability: float = _get_probability(talk)
		if probability <= 0.0:
			continue

		candidate_indices.append(i)
		total_probability += probability

	if candidate_indices.is_empty():
		return -1

	if total_probability <= 0.0:
		return candidate_indices[0]

	var roll: float = _rng.randf() * total_probability
	var accumulated_probability: float = 0.0
	for index in candidate_indices:
		var talk: Dictionary = self_talk_list[index]
		accumulated_probability += _get_probability(talk)
		if roll <= accumulated_probability:
			return index

	return candidate_indices[candidate_indices.size() - 1]


func _try_apply_trigger_self_talk() -> void:
	var candidate_indices: Array[int] = []
	var total_probability: float = 0.0

	for i in range(self_talk_list.size()):
		if i == current_self_talk_index:
			continue

		var talk: Dictionary = self_talk_list[i]
		if _get_talk_type(talk) != SelfTalkType.TRIGGER:
			continue
		if not _is_trigger_condition_met(_get_trigger_condition(talk)):
			continue

		var probability: float = _get_probability(talk)
		if probability <= 0.0:
			continue

		candidate_indices.append(i)
		total_probability += probability

	if candidate_indices.is_empty() or total_probability <= 0.0:
		return

	var normalization: float = total_probability if total_probability > 1.0 else 1.0
	var roll: float = _rng.randf()
	var accumulated_probability: float = 0.0
	for index in candidate_indices:
		var talk: Dictionary = self_talk_list[index]
		accumulated_probability += _get_probability(talk) / normalization
		if roll <= accumulated_probability:
			_apply_self_talk(index)
			return


func _apply_self_talk(index: int) -> void:
	if index < 0 or index >= self_talk_list.size():
		return
	if not _has_valid_player():
		return

	var talk: Dictionary = self_talk_list[index]
	player_now.self_talk = str(talk.get(TALK_TEXT_KEY, ""))
	player_now.self_talk_index = index
	current_self_talk_index = index


func _is_trigger_condition_met(condition: int) -> bool:
	match condition:
		TriggerCondition.HAS_ELECTRONIC_SCREEN:
			return _current_scene_has_electronic_screen()
		TriggerCondition.FIX_SWITCH:
			return _is_switch_on_in_scene("3-7")
		TriggerCondition.MEET_SLAYER:
			return _is_switch_on_in_scene("3-6")
		TriggerCondition.SULFUR_SCENE_SWITCH_ON:
			return _is_switch_on_in_sulfur_scene()
		_:
			return false


func _current_scene_has_electronic_screen() -> bool:
	var current_scene: Node = get_tree().current_scene
	if not current_scene:
		return false

	return _node_has_electronic_screen(current_scene)


func _node_has_electronic_screen(root: Node) -> bool:
	if root is ElectronicScreen:
		return true

	for child in root.get_children():
		if _node_has_electronic_screen(child):
			return true

	return false


func _is_switch_on_in_sulfur_scene() -> bool:
	if not GameManager.switch_on:
		return false

	var scene_key: String = SceneManager.get_current_scene_key() if SceneManager else ""
	return SULFUR_SCENE_KEYS.has(scene_key)


func _is_switch_on_in_scene(target_scene_key: String) -> bool:
	if not GameManager.switch_on:
		return false

	var scene_key: String = SceneManager.get_current_scene_key() if SceneManager else ""
	return scene_key == target_scene_key


func _has_valid_player() -> bool:
	return player_now != null and is_instance_valid(player_now)


func _get_talk_type(talk: Dictionary) -> int:
	return int(talk.get(TALK_TYPE_KEY, SelfTalkType.DEFAULT))


func _get_probability(talk: Dictionary) -> float:
	return clamp(float(talk.get(TALK_PROBABILITY_KEY, 0.0)), 0.0, 1.0)


func _get_trigger_condition(talk: Dictionary) -> int:
	return int(talk.get(TALK_CONDITION_KEY, TriggerCondition.NONE))
