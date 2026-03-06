class_name EnemyEye
extends npc

signal toPursue
signal toPatrol

@onready var breakin: SFXPlayer = $SFXManager/breakin
@onready var hiss: SFXPlayer = $SFXManager/hiss

func _ready() -> void:
	breakin.play_once()
	hiss.play_start()
