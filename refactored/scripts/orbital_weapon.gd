extends Node2D

@export var projectile_scene: PackedScene 

@export var projectile_count: int = 0:
	set(value):
		projectile_count = value
		if is_inside_tree():
			spawn_projectiles()
			
@export var orbit_radius: float = 30.0   # расстояние от игрока
@export var rotation_speed: float = 2.0   # скорость вращения (рад/сек)
@export var base_damage: float = 10.0     # урон первого снаряда
@export var damage_decay: float = 0.8     # множитель урона для каждого следующего (80%)

func _ready():
	spawn_projectiles()

func _physics_process(delta):
	rotation += rotation_speed * delta

func spawn_projectiles():
	for child in get_children():
		child.queue_free()

	for i in range(projectile_count):
		var projectile = projectile_scene.instantiate()
		add_child(projectile)
		
		var angle = (PI * 2 / projectile_count) * i
		var pos = Vector2(cos(angle), sin(angle)) * orbit_radius
		projectile.position = pos
		
		# формула: Damage = Base * (Decay ^ i)
		var current_damage = base_damage * pow(damage_decay, i)
		projectile.damage = current_damage
		
