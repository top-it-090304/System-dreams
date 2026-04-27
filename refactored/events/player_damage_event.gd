class_name PlayerDamageEvent extends IEvent

var damage_amount: int
var current_health: int
var max_health: int
var knockback_direction: Vector2


func _init(dmg: int, curr_hp: int, max_hp: int, knockback: Vector2) -> void:
	damage_amount = dmg
	current_health = curr_hp
	max_health = max_hp
	knockback_direction = knockback
