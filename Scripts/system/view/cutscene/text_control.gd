class_name TextControl
extends Control

## 当前控制节点内所有 RichTextLabel 依次播放完毕后发出（过场局部结束）
signal cutscene_finished_partly

# —— 与 DialogueText / dialogue_base._text_resource 对齐的可配置项 ——
@export var speaker_sprite: AnimatedSprite2D = null
@export var text_sound: AudioStreamPlayer2D = null
@export var default_text_sound: AudioStream = null
@export var text_volume_db: int = 0
@export_range(0.1, 30.0, 0.1) var text_speed: float = 8.0
@export var text_volume_pitch_min: float = 0.85
@export var text_volume_pitch_max: float = 1.15
@export var sprite_animation_name: String = "idle"

## 两条 RichTextLabel 播完之间的间隔（秒），到点自动进入下一条；最后一条播完后不等待
@export_range(0.0, 120.0, 0.05) var label_time: float = 2.0

## 进入场景后是否自动开始按顺序播放
@export var autoplay: bool = true

## 进入场景后等待多少秒再开始播放
@export_range(0.0, 60.0, 0.05) var setup_time: float = 0.0

var _rich_text_labels: Array[RichTextLabel] = []
var _playing: bool = false


func _ready() -> void:
	_collect_rich_text_labels(self, _rich_text_labels)
	if autoplay:
		call_deferred("start_playback")


func start_playback() -> void:
	if _playing:
		return
	if _rich_text_labels.is_empty():
		cutscene_finished_partly.emit()
		return
	_playing = true
	for lbl in _rich_text_labels:
		lbl.visible_characters = 0
	if setup_time > 0.0:
		await get_tree().create_timer(setup_time).timeout
	await _run_sequence()
	_playing = false


func _collect_rich_text_labels(node: Node, out: Array[RichTextLabel]) -> void:
	for child in node.get_children():
		if child is RichTextLabel:
			out.append(child as RichTextLabel)
		_collect_rich_text_labels(child, out)


func _run_sequence() -> void:
	for lbl in _rich_text_labels:
		lbl.visible_characters = 0
	var n: int = _rich_text_labels.size()
	for i in range(n):
		var label: RichTextLabel = _rich_text_labels[i]
		await _play_text_resource(label)
		label.visible_characters = -1
		if i < n - 1 and label_time > 0.0:
			await _wait_inter_label_delay()
	cutscene_finished_partly.emit()


func _play_text_resource(label: RichTextLabel) -> void:
	if text_sound and default_text_sound:
		text_sound.stream = default_text_sound
		text_sound.volume_db = text_volume_db

	if speaker_sprite and sprite_animation_name != "":
		speaker_sprite.play(sprite_animation_name)

	label.visible_characters = 0
	var plain: String = label.text
	var text_without_square_brackets: String = _text_without_square_brackets(plain)
	var total_character: int = text_without_square_brackets.length()
	if total_character == 0:
		return

	var character_timer: float = 0.0

	while label.visible_characters < total_character:
		if Input.is_action_just_pressed("skip"):
			label.visible_characters = total_character
			break

		character_timer += get_process_delta_time()

		if character_timer >= (1.0 / text_speed) or text_without_square_brackets[label.visible_characters] == "":
			var character = text_without_square_brackets[label.visible_characters]
			label.visible_characters += 1
			if character != "" and text_sound and default_text_sound:
				text_sound.pitch_scale = randf_range(text_volume_pitch_min, text_volume_pitch_max)
				text_sound.play()
			character_timer = 0.0

		await get_tree().process_frame


func _wait_inter_label_delay() -> void:
	var elapsed: float = 0.0
	while elapsed < label_time:
		if Input.is_action_just_pressed("skip"):
			break
		elapsed += get_process_delta_time()
		await get_tree().process_frame


func _text_without_square_brackets(text: String) -> String:
	var result: String = ""
	var inside_bracket: bool = false

	for ch in text:
		if ch == "[":
			inside_bracket = true
			continue
		if ch == "]":
			inside_bracket = false
			continue
		if not inside_bracket:
			result += ch

	return result
