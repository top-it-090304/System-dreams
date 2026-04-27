extends CharacterBody2D

@export var exp_scene: PackedScene
@export var heal_scene: PackedScene
@export var heal_drop_chance: float = 0.1

func _ready():
	add_to_group("tap_enemy")
	# физическое тело не должно двигаться
	set_physics_process(false)

## Вызывается из Player, когда обнаружен клик по врагу
func on_tap():
	die()

func die():
	# звук смерти можно оставить
	# дроп опыта/хилки
	if heal_scene and randf() < heal_drop_chance:
		var heal = heal_scene.instantiate()
		heal.global_position = global_position
		get_parent().add_child(heal)
	elif exp_scene:
		var exp = exp_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)
	queue_free()
