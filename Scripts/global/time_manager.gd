class_name TimeManager
extends Node

signal time_changed(hour: int, minute: int)
signal day_changed(day: int)
signal game_time(time : float)

const SECONDS_PER_MINUTE = 1  # 游戏内1秒 = 现实1分钟
const MINUTES_PER_HOUR = 60
const HOURS_PER_DAY = 24
const START_HOUR = 6  # 游戏开始时间为早上6点

var current_second: float = 0
var current_minute: int = 0
var current_hour: int = START_HOUR
var current_day: int = 1

var time_scale: float = 1.0  # 时间流速倍率
var time : float = 0.0


func _ready() -> void:
	set_initial_time()

func set_initial_time() :
	time = 0.0
	current_day = 1
	current_minute = 0
	current_hour = 6
	current_second = 0.0
	

func _process(delta: float) -> void:
	time += delta * time_scale
	current_second += delta * time_scale
	
	if current_second >= SECONDS_PER_MINUTE:
		current_second = 0
		current_minute += 1
		
		if current_minute >= MINUTES_PER_HOUR:
			current_minute = 0
			current_hour += 1
			
			if current_hour >= HOURS_PER_DAY:
				current_hour = 0
				current_day += 1
			day_changed.emit(current_day)

		time_changed.emit(current_minute,current_hour)
	
	game_time.emit(time)

func set_time_scale(scale: float) -> void:
	time_scale = scale

func get_current_time() -> Dictionary:
	return {
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute,
		"second": current_second
	}
