class_name Player
extends CharacterBody2D

var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var move_speed: float = 100.0
var state: String = "idle"

@export var bullet_scene: PackedScene
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_timer: Timer = $ShootTimer

func _ready():
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	if shoot_timer.wait_time == 0:
		shoot_timer.wait_time = 0.25
@onready var joystick = $JoystickUI/JoystickArea  # или как назвали

func _physics_process(_delta):
	# Получаем ввод от джойстика
	var joy_input = joystick.get_input_vector() if joystick else Vector2.ZERO
	
	# Получаем ввод от клавиатуры (для тестов на ПК)
	var key_input = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down"))
	
	# Используем джойстик если активен, иначе клавиатуру
	if joy_input.length() > 0.1:
		direction = joy_input
	else:
		direction = key_input
	
	velocity = direction * move_speed
	move_and_slide()
	SetDirection()
	SetState()
	UpdateAnimation()

func SetDirection() -> bool:
	if direction == Vector2.ZERO:
		return false
	
	var new_dir: Vector2 = cardinal_direction
	if direction.y == 0:
		new_dir = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_dir = Vector2.UP if direction.y < 0 else Vector2.DOWN
	
	if new_dir == cardinal_direction:
		return false
	
	cardinal_direction = new_dir
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

func SetState() -> bool:
	var new_state: String = "idle" if direction == Vector2.ZERO else "walk"
	if new_state == state:
		return false
	state = new_state
	return true

func UpdateAnimation() -> void:
	var anim_name: String = state + "_" + AnimDirection()
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"

func _on_shoot_timer_timeout():
	var target = find_closest_enemy()
	if target:
		shoot(target)

func find_closest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return null
	
	var closest_enemy = enemies[0]
	var min_dist = global_position.distance_to(closest_enemy.global_position)
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			closest_enemy = enemy
	
	return closest_enemy

func shoot(target):
	if not bullet_scene:
		print("Ошибка: bullet_scene не назначен!")
		return
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = $Marker2D.global_position
	bullet.direction = (target.global_position - global_position).normalized()
	get_parent().add_child(bullet)
