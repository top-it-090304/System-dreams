class_name EnemyKilledEvent extends IEvent

var enemy_type: String
var enemy_health: int
var exp_reward: int
var drop_type: String  # "exp" или "heal"


func _init(type: String, health: int, exp: int, drop: String) -> void:
	enemy_type = type
	enemy_health = health
	exp_reward = exp
	drop_type = drop
