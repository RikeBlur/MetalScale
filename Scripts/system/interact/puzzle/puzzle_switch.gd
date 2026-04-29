class_name PuzzleSwitch
extends PuzzleContent

@export var target_state: Array[int] = [0, 1, 0, 1]
@export var green_light: Texture2D = null
@export var red_light: Texture2D = null
@export var button_paths: Array[NodePath] = []
@export var light_paths: Array[NodePath] = []
@export var success_sfx: SFXPlayer = null

func judge_function(_states: Array) -> bool:
	var button_states := get_button_state_list()
	_update_lights(button_states)

	if target_state.is_empty():
		return false
	if button_states.size() != target_state.size():
		return false

	for i in range(target_state.size()):
		if button_states[i] != target_state[i]:
			return false
	return true


func reward_function() -> void:
	if success_sfx:
		success_sfx.play_once()
	super.reward_function()


func get_button_state_list() -> Array[int]:
	var buttons := _get_buttons()
	var button_states: Array[int] = []
	for button in buttons:
		button_states.append(1 if button.button_pressed else 0)
	return button_states


func _get_buttons() -> Array[BaseButton]:
	var buttons: Array[BaseButton] = []
	if not button_paths.is_empty():
		for path in button_paths:
			var node := get_node_or_null(path)
			if node is BaseButton:
				buttons.append(node)
		return buttons

	_collect_buttons_recursive(self, buttons)
	return buttons


func _collect_buttons_recursive(node: Node, out: Array[BaseButton]) -> void:
	for child in node.get_children():
		if child is BaseButton:
			out.append(child)
		_collect_buttons_recursive(child, out)


func _update_lights(button_states: Array[int]) -> void:
	var lights := _get_lights()
	for i in range(lights.size()):
		var state := button_states[i] if i < button_states.size() else 0
		var light := lights[i]
		if light is SwitchLight:
			var switch_light := light as SwitchLight
			if green_light and not switch_light.green_light:
				switch_light.green_light = green_light
			if red_light and not switch_light.red_light:
				switch_light.red_light = red_light
			switch_light.set_state(state)
		elif light is Sprite2D:
			(light as Sprite2D).texture = green_light if state == 1 else red_light


func _get_lights() -> Array[Node]:
	var lights: Array[Node] = []
	if not light_paths.is_empty():
		for path in light_paths:
			var node := get_node_or_null(path)
			if node:
				lights.append(node)
		return lights

	_collect_lights_recursive(self, lights)
	return lights


func _collect_lights_recursive(node: Node, out: Array[Node]) -> void:
	for child in node.get_children():
		if child is SwitchLight:
			out.append(child)
		_collect_lights_recursive(child, out)
