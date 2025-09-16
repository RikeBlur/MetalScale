extends Node
@onready var game_screen: CanvasLayer = $GameScreen
@onready var opening_ui: CanvasLayer = $OpeningUi

func _ready() -> void:
	game_screen.layer = -1
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("exit") :
		game_screen.layer = -1
		opening_ui.visible = true
	
