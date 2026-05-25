class_name ToolData
extends Resource

const TYPE_PERMANENT: int = 0
const TYPE_DURABILITY: int = 1
const TYPE_CONSUMABLE: int = 2

const STATE_UNSELECTED: int = 0
const STATE_SELECTED: int = 1
const STATE_ACTIVE: int = 2
const STATE_BROKEN: int = 3

const USEABLE_FALSE: int = 0
const USEABLE_TRUE: int = 1

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var packed_scene: PackedScene = null
@export var icon: Texture2D = null
@export_range(0, 2, 1) var type: int = TYPE_PERMANENT
@export var durability: float = -1.0
@export var durability_max: float = -1.0
@export var consumption: int = -1
@export var consumption_max: int = -1
@export_range(0, 3, 1) var state: int = STATE_UNSELECTED
@export_range(0, 1, 1) var useable: int = USEABLE_FALSE
@export var cooldown_time: float = -1.0

func has_durability() -> bool:
	return type == TYPE_DURABILITY and durability >= 0.0

func has_consumption() -> bool:
	return type == TYPE_CONSUMABLE and consumption >= 0

func is_useable() -> bool:
	return useable == USEABLE_TRUE

func is_broken() -> bool:
	return state == STATE_BROKEN

func reset_runtime_values() -> void:
	if type == TYPE_DURABILITY:
		durability = durability_max
	elif type == TYPE_CONSUMABLE:
		consumption = consumption_max

	if state == STATE_BROKEN:
		state = STATE_UNSELECTED

func to_dict() -> Dictionary:
	return {
		"display_name": display_name,
		"description": description,
		"packed_scene_path": _resource_to_path(packed_scene),
		"icon_path": _resource_to_path(icon),
		"type": type,
		"durability": durability,
		"durability_max": durability_max,
		"consumption": consumption,
		"consumption_max": consumption_max,
		"state": state,
		"useable": useable,
		"cooldown_time": cooldown_time
	}

func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		return

	display_name = data.get("display_name", "")
	description = data.get("description", "")

	var packed_scene_path: String = data.get("packed_scene_path", "")
	if packed_scene_path != "":
		packed_scene = load(packed_scene_path) as PackedScene

	var icon_path: String = data.get("icon_path", "")
	if icon_path != "":
		icon = load(icon_path) as Texture2D

	type = int(data.get("type", TYPE_PERMANENT))
	durability = float(data.get("durability", -1.0))
	durability_max = float(data.get("durability_max", -1.0))
	consumption = int(data.get("consumption", -1))
	consumption_max = int(data.get("consumption_max", -1))
	state = int(data.get("state", STATE_UNSELECTED))
	useable = int(data.get("useable", USEABLE_FALSE))
	cooldown_time = float(data.get("cooldown_time", -1.0))
	if useable == USEABLE_FALSE:
		cooldown_time = -1.0

func _resource_to_path(resource: Resource) -> String:
	if not resource:
		return ""
	return resource.resource_path
