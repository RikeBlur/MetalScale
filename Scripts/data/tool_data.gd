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
