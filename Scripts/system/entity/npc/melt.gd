class_name EnemyMelt
extends npc

signal toPursue
signal toPatrol

@export var detector_range: float = 300.0
@export var reaction_time: float = 1.0
@export var lose_track_time: float = 3.0

@onready var react_sfx: SFXPlayer = $SFXManager/react
@onready var hiss: SFXPlayer = $SFXManager/hiss
@onready var react_reminder: AnimatedSprite2D = $react_reminder

var arrgoing: bool = false
var _player_in_range: bool = false
var _lose_track_timer: float = 0.0
var is_reacting_to_pursue: bool = false
var _reaction_timer: float = 0.0

func _ready() -> void:
	_set_react_reminder_visible(false)
	hiss.play_start()

func _physics_process(delta: float) -> void:
	_update_reaction_timer(delta)
	_update_player_detection(delta)

func _update_reaction_timer(delta: float) -> void:
	if not is_reacting_to_pursue:
		return

	velocity = Vector2.ZERO

	if not _player_in_range:
		is_reacting_to_pursue = false
		_reaction_timer = 0.0
		_set_react_reminder_visible(false)
		return

	_reaction_timer = max(_reaction_timer - delta, 0.0)
	if _reaction_timer > 0.0:
		return

	is_reacting_to_pursue = false
	_set_react_reminder_visible(false)
	state = 1
	emit_signal("toPursue")

func _update_player_detection(delta: float) -> void:
	var player_now = GameManager.player_instance
	if not player_now or not is_instance_valid(player_now):
		_player_in_range = false
		is_reacting_to_pursue = false
		_reaction_timer = 0.0
		_set_react_reminder_visible(false)
		return

	var distance: float = global_position.distance_to(player_now.global_position)
	var was_in_range: bool = _player_in_range
	_player_in_range = distance <= detector_range

	# 玩家进入探测范围，且当前是 patrol 状态 → 切换到 pursue
	if _player_in_range and not was_in_range and state == 0 and not is_reacting_to_pursue:
		is_reacting_to_pursue = true
		_reaction_timer = max(reaction_time, 0.0)
		velocity = Vector2.ZERO
		_play_react_sfx()
		_set_react_reminder_visible(true)
		if _reaction_timer <= 0.0:
			is_reacting_to_pursue = false
			_set_react_reminder_visible(false)
			state = 1
			emit_signal("toPursue")
		return

	if is_reacting_to_pursue:
		if not _player_in_range:
			is_reacting_to_pursue = false
			_reaction_timer = 0.0
			_set_react_reminder_visible(false)
		return

	# 玩家在范围内 → 重置失踪计时器
	if _player_in_range:
		_lose_track_timer = 0.0
	# 玩家不在范围内，且当前是 pursue 状态，且不在 arrgoing 模式
	elif state == 1 and not arrgoing:
		_lose_track_timer += delta
		if _lose_track_timer >= lose_track_time:
			state = 0
			emit_signal("toPatrol")
			_lose_track_timer = 0.0

func _play_react_sfx() -> void:
	if react_sfx.one_shot:
		react_sfx.play_once()
	else:
		react_sfx.play_start()

func _set_react_reminder_visible(is_visible: bool) -> void:
	react_reminder.visible = is_visible
