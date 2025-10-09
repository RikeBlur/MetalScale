extends LimboHSM

func _dispatch_target_detected() -> void:
	dispatch("target_detected")
	
func _dispatch_target_lost() -> void:
	dispatch("target_lost")
	
func _dispatch_light_detected() -> void:
	dispatch("light_detected")

func _dispatch_light_lost() -> void:
	dispatch("light_lost")
