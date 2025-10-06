class_name light_source
extends PointLight2D

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

func calculate_intensity(angle: float, length: float) -> float:
	return -1
