class_name water_sign
extends PuzzleContent

@export var fade_out_time: float = 0.6

@onready var click: Area2D = $click
@onready var watersign_white: Sprite2D = $watersign_white
@onready var watersign_red: Sprite2D = $watersign_red
@onready var use_or_not: Control = $use_or_not
@onready var yes_button: Button = $use_or_not/Panel/Container/MarginContainer/VBoxContainer/choices/yes
@onready var no_button: Button = $use_or_not/Panel/Container/MarginContainer/VBoxContainer/choices/no
@onready var dialogue: DialogueComponent = $dialogue
@onready var sfx_player: Node = $SFXPlayer

var solved: int = 0
var _dialogue_running: bool = false
var _white_fade_tween: Tween = null


func _ready() -> void:
	super._ready()
	_connect_signals()
	_apply_initial_state()

func _on_click_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if solved == 1 or _dialogue_running:
		return
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	watersign_interact()


func _gui_input(event: InputEvent) -> void:
	if solved == 1 or _dialogue_running:
		return
	if use_or_not and use_or_not.visible:
		return
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if not _is_point_inside_click_area(mouse_event.position):
		return

	accept_event()
	watersign_interact()


func watersign_interact() -> void:
	print("WaterSign Interacted!")
	if solved == 1 or _dialogue_running:
		return

	if _is_have_bloodywater():
		if use_or_not:
			use_or_not.visible = true
	else:
		_play_no_bloodywater_dialogue()


func _on_yes_pressed() -> void:
	if solved == 1:
		return
	if not _is_have_bloodywater():
		if use_or_not:
			use_or_not.visible = false
		_play_no_bloodywater_dialogue()
		return

	if use_or_not:
		use_or_not.visible = false
	_consume_bloodywater()
	await _fade_out_white_sign()
	_complete_water_sign()


func _on_no_pressed() -> void:
	if use_or_not:
		use_or_not.visible = false


func _is_have_bloodywater() -> bool:
	var player_node := GameManager.get_player()
	if not player_node or not is_instance_valid(player_node):
		return false

	if not player_node.tool_available.has(ToolManager.Tool.BOOLDYWATER):
		return false

	var tool_manager := player_node.get_node_or_null("ToolManager") as ToolManager
	if not tool_manager:
		return true

	var consumption := tool_manager.get_tool_consumption(ToolManager.Tool.BOOLDYWATER)
	return consumption != 0


func _consume_bloodywater() -> void:
	var player_node := GameManager.get_player()
	if not player_node or not is_instance_valid(player_node):
		return

	var tool_manager := player_node.get_node_or_null("ToolManager") as ToolManager
	if tool_manager:
		tool_manager.consumption_changed(ToolManager.Tool.BOOLDYWATER, -1)
		return

	var tool_index := player_node.tool_available.find(ToolManager.Tool.BOOLDYWATER)
	if tool_index >= 0:
		player_node.tool_available[tool_index] = ToolManager.Tool.NONE


func _fade_out_white_sign() -> void:
	if not watersign_white or not is_instance_valid(watersign_white):
		return

	if _white_fade_tween and _white_fade_tween.is_valid():
		_white_fade_tween.kill()

	watersign_white.visible = true
	watersign_white.modulate.a = 1.0
	_white_fade_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_white_fade_tween.tween_property(watersign_white, "modulate:a", 0.0, max(fade_out_time, 0.0))
	await _white_fade_tween.finished

	if watersign_white and is_instance_valid(watersign_white):
		watersign_white.visible = false
	_white_fade_tween = null


func _complete_water_sign() -> void:
	solved = 1
	if click:
		click.input_pickable = false
		click.monitoring = false
		click.monitorable = false

	if sfx_player and sfx_player.has_method("play_once"):
		sfx_player.call("play_once")
	elif sfx_player and sfx_player.has_method("play"):
		sfx_player.call("play")

	if puzzle_component and is_instance_valid(puzzle_component) and puzzle_component.has_method("set_puzzle_state"):
		puzzle_component.call("set_puzzle_state", 3, true)


func _play_no_bloodywater_dialogue() -> void:
	if not dialogue or not is_instance_valid(dialogue):
		return
	_dialogue_running = true
	dialogue.trigger_dialogue()
	_wait_for_dialogue_finished()


func _wait_for_dialogue_finished() -> void:
	await get_tree().process_frame
	while dialogue and is_instance_valid(dialogue) and _dialogue_has_active_instance():
		await get_tree().process_frame
	_dialogue_running = false


func _dialogue_has_active_instance() -> bool:
	if not dialogue.canvas_layer or not is_instance_valid(dialogue.canvas_layer):
		return false
	return dialogue.canvas_layer.get_child_count() > 0


func _is_point_inside_click_area(viewport_point: Vector2) -> bool:
	if not click or not is_instance_valid(click):
		return false

	var click_local_point := click.get_global_transform_with_canvas().affine_inverse() * viewport_point
	for child in click.get_children():
		var collision_shape := child as CollisionShape2D
		if not collision_shape or collision_shape.disabled or not collision_shape.shape:
			continue

		var shape_local_point := collision_shape.transform.affine_inverse() * click_local_point
		if _shape_contains_point(collision_shape.shape, shape_local_point):
			return true

	return false


func _shape_contains_point(shape: Shape2D, local_point: Vector2) -> bool:
	if shape is RectangleShape2D:
		var rectangle_shape := shape as RectangleShape2D
		return Rect2(-rectangle_shape.size * 0.5, rectangle_shape.size).has_point(local_point)
	if shape is CircleShape2D:
		var circle_shape := shape as CircleShape2D
		return local_point.length() <= circle_shape.radius
	return false
	
# ============================== 工具函数 =============================

func setup_puzzle(component: Node, current_state: int = 1) -> void:
	super.setup_puzzle(component, current_state)
	_apply_state(current_state)


func set_puzzle_state(current_state: int) -> void:
	_apply_state(current_state)


func _connect_signals() -> void:
	if click and not click.input_event.is_connected(_on_click_input_event):
		click.input_event.connect(_on_click_input_event)
	if yes_button and not yes_button.pressed.is_connected(_on_yes_pressed):
		yes_button.pressed.connect(_on_yes_pressed)
	if no_button and not no_button.pressed.is_connected(_on_no_pressed):
		no_button.pressed.connect(_on_no_pressed)


func _apply_initial_state() -> void:
	var current_state := 1
	if puzzle_component and is_instance_valid(puzzle_component) and "state" in puzzle_component:
		current_state = puzzle_component.state
	_apply_state(current_state)


func _apply_state(current_state: int) -> void:
	solved = 1 if current_state == 3 else 0
	if current_state != 1 and current_state != 3:
		solved = 0

	if use_or_not:
		use_or_not.visible = false

	if watersign_white:
		watersign_white.visible = solved == 0
		watersign_white.modulate.a = 1.0 if solved == 0 else 0.0

	if click:
		click.input_pickable = solved == 0
		click.monitoring = solved == 0
		click.monitorable = solved == 0
