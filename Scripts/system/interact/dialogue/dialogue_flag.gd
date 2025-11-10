class_name dialogue_flag
extends Resource

@export var flag : bool = false
@export var only_once : bool = true
@export var double : bool = false

@export var style : Array[int]
@export var start : Array[int]
@export var end :Array[int]

@export var a_index :Array[int]
@export var b_index :Array[int]

var triggered : bool = false
