class_name trail_component
extends Node2D

@export var sprite : Sprite2D = null
@export var attached : Node2D = null 
@export var timer : Timer = null 

var velocity : Vector2 = Vector2.ZERO
var can_trail : bool = false

func _ready() -> void:
	timer.timeout.connect(_on_trail_timer_timeout)

# 生成残影
func _on_trail_timer_timeout() -> void:
	if not can_trail:
		return
	# 残影特效场景加载
	var trail = preload("res://Effect/Trail/trail.tscn").instantiate()
	attached.get_parent().add_child(trail)
	
	var properties = [
		"hframes" ,
		"vframes" ,
		"frame" ,
		"texture" ,
		"global_position" ,
		"flip_h" ,
		"scale" ,
		"modulate.a",
		"modulate",
		"scale"
	]
	for name in properties :
		trail.set(name , sprite.get(name))
