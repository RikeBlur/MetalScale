extends Node

@export var camera : Camera2D = null
@export var paritcle : GPUParticles2D = null
@export var animated_sprite : AnimatedSprite2D = null 
var cameraShakeNoise : FastNoiseLite #用于采样噪声

var max_shake_intensity : float = 5.0 
var min_shake_intensity : float = 1.0
var shake_time : float = 0.5 #摄像机震动时间

func _ready() -> void:
	cameraShakeNoise = FastNoiseLite.new()
	
func _on_hurt() -> void:
	#摄像机震动
	var camera_tween = get_tree().create_tween()
	camera_tween.tween_method(StartCameraShake, max_shake_intensity, min_shake_intensity, shake_time)
	
	#粒子效果
	paritcle.restart()
	paritcle.emitting = true
	
	
func _process(delta: float) -> void:
	#溶解效果
	animated_sprite.material.set_shader_parameter("DissolveValue", sin(Time.get_ticks_msec()*0.001)+0.5)
	
	
func StartCameraShake(intensity : float):
	var cameraOffset = cameraShakeNoise.get_noise_1d(Time.get_ticks_msec()) * intensity # 获取时间相关的随机偏移量
	camera.offset.x = cameraOffset
	camera.offset.y = cameraOffset
