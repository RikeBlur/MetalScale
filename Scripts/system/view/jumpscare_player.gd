class_name JumpScarePlayer
extends Node2D

signal oneshot_finished

@export var animation_array: Array[AnimatedSprite2D] = []
@export var animation_player_array: Array[AnimationPlayer] = []
@export var start_time: float = 0.0
@export var loop: bool = false

var _playing: bool = false
var _active_tween: Tween = null

const DEFAULT_ANIMATION_NAME: StringName = &"default"

func play_oneshot() -> void:
	if _playing:
		return
	_playing = true

	if animation_array.is_empty():
		_setup_default_animation_array()
	if animation_player_array.is_empty():
		_setup_default_animation_player_array()

	await _run_oneshot_timeline()

	_playing = false
	oneshot_finished.emit()


func play_ontshot() -> void:
	play_oneshot()


func _setup_default_animation_array() -> void:
	var default_sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if default_sprite:
		animation_array.append(default_sprite)


func _setup_default_animation_player_array() -> void:
	var default_animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if default_animation_player:
		animation_player_array.append(default_animation_player)


func _run_oneshot_timeline() -> void:
	_active_tween = create_tween().set_parallel(true)
	var has_tweeners := false

	for sprite in animation_array:
		if not sprite or not is_instance_valid(sprite):
			continue

		var start_scale: Vector2 = _get_sprite_value(sprite, "start_scale", sprite.scale)
		var end_scale: Vector2 = _get_sprite_value(sprite, "end_scale", sprite.scale)
		var start_position: Vector2 = _get_sprite_value(sprite, "start_position", sprite.position)
		var end_position: Vector2 = _get_sprite_value(sprite, "end_position", sprite.position)
		var start_rotate: float = _get_sprite_value(sprite, "start_rotate", sprite.rotation)
		var end_rotate: float = _get_sprite_value(sprite, "end_rotate", sprite.rotation)
		var animate_time: float = max(_get_sprite_value(sprite, "animate_time", 0.0), 0.0)
		var wait_time: float = max(_get_sprite_value(sprite, "wait_time", _get_sprite_animation_length(sprite)), 0.0)
		var dissolve_time: float = max(_get_sprite_value(sprite, "dissolve_time", 0.0), 0.0)
		var dissolved_paramater: StringName = _get_sprite_value(sprite, "dissolved_paramater", &"DissolveValue")
		var dissolve_delay := animate_time + wait_time

		_prepare_sprite_material(sprite)
		sprite.scale = start_scale
		sprite.position = start_position
		sprite.rotation = start_rotate
		_set_dissolve(sprite, dissolved_paramater, 0.0)
		sprite.stop()
		sprite.frame = 0
		sprite.play()

		if animate_time <= 0.0:
			sprite.scale = end_scale
			sprite.position = end_position
			sprite.rotation = end_rotate
		else:
			_active_tween.tween_property(sprite, "scale", end_scale, animate_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_active_tween.tween_property(sprite, "position", end_position, animate_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_active_tween.tween_property(sprite, "rotation", end_rotate, animate_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			has_tweeners = true

		if dissolve_time <= 0.0:
			_active_tween.tween_callback(_set_dissolve.bind(sprite, dissolved_paramater, 1.0)).set_delay(dissolve_delay)
		else:
			_active_tween.tween_method(_set_dissolve_tween_value.bind(sprite, dissolved_paramater), 0.0, 1.0, dissolve_time).set_delay(dissolve_delay)
		has_tweeners = true

	for animation_player in animation_player_array:
		if not animation_player or not is_instance_valid(animation_player):
			continue

		var animation_start_time: float = max(float(_get_animation_player_value(animation_player, &"start_time", start_time)), 0.0)
		var animation_loop: bool = bool(_get_animation_player_value(animation_player, &"loop", loop))
		var animation_length: float = _prepare_animation_player(animation_player, animation_loop)
		animation_player.stop()
		_active_tween.tween_callback(_play_default_animation_player.bind(animation_player)).set_delay(animation_start_time)
		_active_tween.tween_interval(animation_start_time + animation_length)
		has_tweeners = true

	if has_tweeners:
		await _active_tween.finished
	else:
		_active_tween.kill()
	_active_tween = null


func _get_sprite_value(sprite: AnimatedSprite2D, property_name: StringName, default_value: Variant) -> Variant:
	if not _has_sprite_property(sprite, property_name):
		return default_value
	var value: Variant = sprite.get(property_name)
	if value == null:
		return default_value
	return value


func _has_sprite_property(sprite: AnimatedSprite2D, property_name: StringName) -> bool:
	for property in sprite.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false


func _get_animation_player_value(animation_player: AnimationPlayer, property_name: StringName, default_value: Variant) -> Variant:
	if _has_animation_player_property(animation_player, property_name):
		var value: Variant = animation_player.get(property_name)
		if value != null:
			return value
	if animation_player.has_meta(String(property_name)):
		return animation_player.get_meta(String(property_name))
	return default_value


func _has_animation_player_property(animation_player: AnimationPlayer, property_name: StringName) -> bool:
	for property in animation_player.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false


func _prepare_animation_player(animation_player: AnimationPlayer, should_loop: bool) -> float:
	if not animation_player.has_animation(DEFAULT_ANIMATION_NAME):
		push_warning("JumpScarePlayer: AnimationPlayer %s missing default animation" % animation_player.name)
		return 0.0

	var animation: Animation = animation_player.get_animation(DEFAULT_ANIMATION_NAME)
	if not animation:
		return 0.0

	animation.loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE
	return max(animation.length, 0.0)


func _play_default_animation_player(animation_player: AnimationPlayer) -> void:
	if not animation_player or not is_instance_valid(animation_player):
		return
	if not animation_player.has_animation(DEFAULT_ANIMATION_NAME):
		return

	animation_player.play(DEFAULT_ANIMATION_NAME)


func _set_dissolve(sprite: AnimatedSprite2D, parameter_name: StringName, value: float) -> void:
	if not sprite.material:
		return
	sprite.material.set("shader_parameter/%s" % String(parameter_name), value)


func _set_dissolve_tween_value(value: float, sprite: AnimatedSprite2D, parameter_name: StringName) -> void:
	_set_dissolve(sprite, parameter_name, value)


func _prepare_sprite_material(sprite: AnimatedSprite2D) -> void:
	if sprite.material:
		sprite.material = sprite.material.duplicate()


func _get_sprite_animation_length(sprite: AnimatedSprite2D) -> float:
	if not sprite.sprite_frames:
		return 0.0

	var animation_name := sprite.animation
	if not sprite.sprite_frames.has_animation(animation_name):
		return 0.0

	var speed := sprite.sprite_frames.get_animation_speed(animation_name)
	if speed <= 0.0:
		return 0.0

	return float(sprite.sprite_frames.get_frame_count(animation_name)) / speed
