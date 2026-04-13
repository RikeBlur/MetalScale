class_name EnemyEye
extends npc

signal toPursue
signal toPatrol

@export var detector_range: float = 300.0
@export var lose_track_time: float = 3.0
@export var ambient_light_pos_by_direction: Dictionary = {
	"front": Vector2(0.0, -63.0),
	"front_left": Vector2(-16.0, -63.0),
	"front_right": Vector2(16.0, -63.0),
	"left": Vector2(-22.0, -71.0),
	"right": Vector2(22.0, -71.0),
	"back": Vector2(0.0, -98.0),
	"back_left": Vector2(-22.0, -86.0),
	"back_right": Vector2(22.0, -86.0),
}

@onready var breakin: SFXPlayer = $SFXManager/breakin
@onready var hiss: SFXPlayer = $SFXManager/hiss
@onready var ambient_light: PointLight2D = $ambient_light

var arrgoing: bool = false
var _player_in_range: bool = false
var _lose_track_timer: float = 0.0

func _ready() -> void:
	breakin.play_once()
	hiss.play_start()
	_update_ambient_light_position()

func _physics_process(delta: float) -> void:
	_update_player_detection(delta)
	_update_ambient_light_position()

func _update_player_detection(delta: float) -> void:
	var player_now: Node2D = GameManager.player_instance
	if not player_now or not is_instance_valid(player_now):
		_player_in_range = false
		return

	var distance: float = global_position.distance_to(player_now.global_position)
	var was_in_range: bool = _player_in_range
	_player_in_range = distance <= detector_range

	# 玩家进入探测范围，且当前是 patrol 状态 → 切换到 pursue
	if _player_in_range and not was_in_range and state == 0:
		state = 1
		emit_signal("toPursue")

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

func _update_ambient_light_position() -> void:
	if not is_instance_valid(ambient_light):
		return

	var direction_key: String = _get_8dir_key(npc_direction)
	var ambient_light_pos: Vector2 = ambient_light_pos_by_direction.get(direction_key, ambient_light.position)
	ambient_light.position = ambient_light_pos

func _get_8dir_key(direction: Vector2) -> String:
	if direction == Vector2.ZERO:
		return "front"

	var snapped_angle: float = snappedf(direction.angle(), PI / 4.0)
	match snapped_angle:
		0.0:
			return "right"
		PI / 4.0:
			return "front_right"
		PI / 2.0:
			return "front"
		3.0 * PI / 4.0:
			return "front_left"
		-PI / 4.0:
			return "back_right"
		-PI / 2.0:
			return "back"
		-3.0 * PI / 4.0:
			return "back_left"
		_:
			return "left"
