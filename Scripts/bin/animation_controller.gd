class_name AnimationController
extends AnimatedSprite2D

const MOVEMENT_TO_IDLE = {
	"front_walk": "front_idle",
	"back_walk": "back_idle",
	"left_walk": "left_idle",
	"right_walk": "right_idle",
}

const ATTACK_TO_IDLE = {
	"front_attack": "front_idle",
	"back_attack": "back_idle",
	"left_attack": "left_idle",
	"right_attack": "right_idle",
}

const ATTACK_ANIMATIONS = [
	"front_attack",
	"back_attack",
	"left_attack",
	"right_attack",
]

func play_movement_animation(velocity: Vector2):
	if velocity.x < 0:
		play("left_walk")
	elif velocity.x > 0:
		play("right_walk")
	
	if velocity.y < 0 and velocity.x == 0:
		play("back_walk")
	elif velocity.y > 0 and velocity.x == 0:
		play("front_walk")

func play_idle_animation():
	# 从移动状态到闲置状态
	if MOVEMENT_TO_IDLE.keys().has(animation):
		play(MOVEMENT_TO_IDLE[animation])
	# 从攻击状态到闲置状态
	elif ATTACK_TO_IDLE.keys().has(animation):
		play(ATTACK_TO_IDLE[animation])

# 使用自定义方法进行安全播放，而不是覆盖原始play方法
func play_safe(anim_name: String):
	# 检查动画是否存在
	if has_animation(anim_name):
		play(anim_name)
	else:
		push_warning("动画 '" + anim_name + "' 不存在")
		
# 辅助方法：检查是否有特定动画
func has_animation(anim_name: String) -> bool:
	return get_sprite_frames() != null and get_sprite_frames().has_animation(anim_name)
