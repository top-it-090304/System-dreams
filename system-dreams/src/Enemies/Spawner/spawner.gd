extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 200.0

@onready var timer = $Timer

func _ready():
	timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	if enemy_scene:
		spawn_enemy()

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	
	# случайная позиция в радиусе
	var random_offset = Vector2(
		randf_range(-spawn_radius, spawn_radius),
		randf_range(-spawn_radius, spawn_radius)
	)
	
	enemy.global_position = global_position + random_offset
	
	get_parent().add_child(enemy)
