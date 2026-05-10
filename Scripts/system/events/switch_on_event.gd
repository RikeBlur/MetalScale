class_name SwitchOnEvent
extends GameEvents

@export var puzzle_component_path_1: NodePath = NodePath("")
@export var puzzle_component_path_2: NodePath = NodePath("")
@export var puzzle_component_path_3: NodePath = NodePath("")

var puzzle_component_1: PuzzleComponent = null
var puzzle_component_2: PuzzleComponent = null
var puzzle_component_3: PuzzleComponent = null


func _ready() -> void:
	one_shot = true
	super._ready()
	_resolve_puzzle_components()


func trigger_condition() -> bool:
	if triggered_already:
		return false
	if not _all_puzzle_components_valid():
		return false

	return (
		_is_puzzle_completed(puzzle_component_1)
		and _is_puzzle_completed(puzzle_component_2)
		and _is_puzzle_completed(puzzle_component_3)
	)


func trigger_effect() -> void:
	print("沉重大门打开的声音")


func _resolve_puzzle_components() -> void:
	puzzle_component_1 = _resolve_puzzle_component(puzzle_component_path_1, "puzzle_component_path_1")
	puzzle_component_2 = _resolve_puzzle_component(puzzle_component_path_2, "puzzle_component_path_2")
	puzzle_component_3 = _resolve_puzzle_component(puzzle_component_path_3, "puzzle_component_path_3")


func _resolve_puzzle_component(component_path: NodePath, path_name: String) -> PuzzleComponent:
	if component_path == NodePath(""):
		push_warning("SwitchOnEvent: %s is empty." % path_name)
		return null

	var component := get_node_or_null(component_path) as PuzzleComponent
	if component == null:
		push_warning("SwitchOnEvent: %s does not point to a PuzzleComponent: %s" % [path_name, component_path])
		return null

	return component


func _all_puzzle_components_valid() -> bool:
	return (
		puzzle_component_1 != null and is_instance_valid(puzzle_component_1)
		and puzzle_component_2 != null and is_instance_valid(puzzle_component_2)
		and puzzle_component_3 != null and is_instance_valid(puzzle_component_3)
	)


func _is_puzzle_completed(component: PuzzleComponent) -> bool:
	return component != null and is_instance_valid(component) and (component.state == 2 or component.state == 3)
