class_name PlayerLevelUpEvent extends IEvent

var player_level: int
var previous_level: int


func _init(new_level: int, old_level: int) -> void:
	player_level = new_level
	previous_level = old_level
