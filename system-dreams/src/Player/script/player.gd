class_name Player extends CharacterBody2D



var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var move_speed : float = 140.0
var state : String = "idle"

var level: int = 1
var current_xp: int = 0
var next_level_xp: int = 10

@export var max_health: int = 100
@export var damage_from_enemy: int = 3
@export var invincibility_time: float = 0.3
var health: int
var _invincibility_timer: float = 0.0
var _hp_label: Label = null
@export var bullet_scene: PackedScene
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D
@onready var shoot_timer : Timer = $ShootTimer

# Called when the node enters the scene tree for the first time.
func _ready() :
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	# интервал стрельбы
	if shoot_timer.wait_time == 0:
		shoot_timer.wait_time = 0.25  
	
	health = max_health
	
	_hp_label = get_tree().root.get_node_or_null("Main/HUD/HPLabel")
	_update_hp_ui()
	
	print("Current level: ", level)


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
	
	# таймер неуязвимости после удара
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
	
	_check_enemy_collisions()


func _check_enemy_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemy"):
			_on_hit_by_enemy()
			break


func _on_hit_by_enemy() -> void:
	if _invincibility_timer > 0.0:
		return
	
	_apply_damage(damage_from_enemy)
	_invincibility_timer = invincibility_time


func _apply_damage(amount: int) -> void:
	health -= amount
	_update_hp_ui()
	
	if health <= 0:
		_on_player_died()


func _on_player_died() -> void:
	print("Player died")
	queue_free()
	

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


func add_xp(amount: int) -> void:
	current_xp += amount
	
	while current_xp >= next_level_xp:
		current_xp -= next_level_xp
		level += 1
		next_level_xp *= 2
		_on_level_up()


func _on_level_up() -> void:
	print("Level up! New level: ", level)


func _update_hp_ui() -> void:
	if _hp_label:
		_hp_label.text = "HP: %d/%d" % [health, max_health]
