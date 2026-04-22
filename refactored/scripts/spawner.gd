extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 200.0
@export var min_spawn_distance_from_player: float = 150.0
@export var max_spawn_position_attempts: int = 12

@onready var timer = $Timer

func _ready():
	timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	if enemy_scene:
		spawn_enemy()

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	var player := get_parent().get_node_or_null("Player")

	var attempts := 0
	var spawn_pos := global_position
	while attempts < max_spawn_position_attempts:
		attempts += 1
		var random_offset := Vector2(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(-spawn_radius, spawn_radius)
		)
		var candidate := global_position + random_offset
		if player == null:
			spawn_pos = candidate
			break
		if candidate.distance_to(player.global_position) >= min_spawn_distance_from_player:
			spawn_pos = candidate
			break

	enemy.global_position = spawn_pos
	get_parent().add_child(enemy)
