extends CanvasLayer

@onready var transition_player: AnimationPlayer = $transition_player

func _ready() -> void:
	GameManager.Preloaded.connect(on_preloaded)
	
func on_preloaded() -> void:
	transition_player.play("disappear")
