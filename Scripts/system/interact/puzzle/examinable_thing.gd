class_name ExaminableThing
extends PuzzleContent

@onready var click: Area2D = get_node_or_null("click") as Area2D
@onready var dialogue: DialogueComponent = get_node_or_null("dialogue") as DialogueComponent

var _dialogue_running: bool = false


func _ready() -> void:
	super._ready()
	_connect_signals()
	_keep_puzzle_state_interactable()


func setup_puzzle(component: Node, current_state: int = 1) -> void:
	super.setup_puzzle(component, current_state)
	_keep_puzzle_state_interactable()


func set_puzzle_state(_current_state: int) -> void:
	_keep_puzzle_state_interactable()


func reward_function() -> void:
	_keep_puzzle_state_interactable()


func _connect_signals() -> void:
	if click and not click.input_event.is_connected(_on_click_input_event):
		click.input_event.connect(_on_click_input_event)


func _on_click_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _dialogue_running:
		return
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	examinable_interact()


func _gui_input(event: InputEvent) -> void:
	if _dialogue_running:
		return
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if not _is_point_inside_click_area(mouse_event.position):
		return

	accept_event()
	examinable_interact()


func examinable_interact() -> void:
	_keep_puzzle_state_interactable()
	_play_dialogue()


func _play_dialogue() -> void:
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
	_keep_puzzle_state_interactable()


func _dialogue_has_active_instance() -> bool:
	if not dialogue.canvas_layer or not is_instance_valid(dialogue.canvas_layer):
		return false
	return dialogue.canvas_layer.get_child_count() > 0


func _keep_puzzle_state_interactable() -> void:
	if not puzzle_component or not is_instance_valid(puzzle_component):
		return
	if not ("state" in puzzle_component):
		return
	if puzzle_component.state == 1:
		return
	if puzzle_component.has_method("set_puzzle_state"):
		puzzle_component.call("set_puzzle_state", 1, true)
	else:
		puzzle_component.state = 1


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
