class_name PlayerDeathEvent extends IEvent

var player_level: int
var run_time: float
var score: int


func _init(level: int, time: float, score_val: int = 0) -> void:
	player_level = level
	run_time = time
	score = score_val
