class_name Player extends CharacterBody2D



var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var move_speed : float = 100.0
var state : String = "idle"

@export var bullet_scene: PackedScene
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D
@onready var shoot_timer : Timer = $ShootTimer

# Called when the node enters the scene tree for the first time.
func _ready() :
	# Подключаем сигнал таймера к функции стрельбы
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	# интервал стрельбы
	if shoot_timer.wait_time == 0:
		shoot_timer.wait_time = 0.25  


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process( delta )  :
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	velocity = direction * move_speed
	if SetState() == true || SetDirection() == true:
		UpdateAnimation()
	pass
	
	
	
	
func _physics_process ( delta ):
	move_and_slide()
	

func SetDirection() -> bool:
	var new_dir : Vector2 = cardinal_direction
	if direction == Vector2.ZERO:
		return false
		
	if direction.y == 0:
		new_dir  = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_dir = Vector2.UP if direction.y < 0 else Vector2.DOWN
		
	if new_dir == cardinal_direction:
		return false
		
	cardinal_direction = new_dir
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1 # это нужно будет поменять если заходим чтобы оружие приповороле игрока оставалось на месте
	return true
	
	
func SetState() -> bool:
	var new_state : String = "idle" if direction == Vector2.ZERO else "walk"
	if new_state == state:
		return false
	state = new_state
	return true
		
	
	return true
	
	
func UpdateAnimation() -> void:
	animation_player.play(state + "_" + AnimDirection())
	
	pass
	
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
