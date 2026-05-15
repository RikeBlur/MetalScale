class_name LightSource
extends Node2D

# 射线采样类
class SampleRay:
	var ray_id: int
	var angle_start: float
	var angle_end: float
	var is_occluded: bool = false
	var ray_length: float = 0.0
	
	func _init(id: int, start_angle: float, end_angle: float):
		ray_id = id
		angle_start = start_angle
		angle_end = end_angle

var sample_rays: Array[SampleRay] = []
var occlusion_points: Array[Vector2] = []

# 逻辑遮挡会把每个光源的采样射线与大量遮挡点做匹配，复杂度很高。
# 默认关闭，只保留兼容入口；需要调试旧系统时可在具体光源上手动开启。
@export var use_occlusion: bool = false

# 检测器发现阈值（当光强超过此值时，认为照射到了检测器）
@export var find_detector_threshold: float = 0.05

# 标记是否照射到了检测器
var find_detector: bool = false

func calculate_intensity(angle: float, length: float) -> float:
	return 1.0

func update_ray_collisions():
	pass
