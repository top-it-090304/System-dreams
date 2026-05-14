class_name Player
extends CharacterBody2D

signal health_updated(new_health, new_max_health)
signal level_updated(new_level)
signal xp_updated(current_xp, next_level_xp)

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var move_speed : float = 140.0
var click_position = Vector2()
var target_position = Vector2()
var state : String = "idle"
var level: int = 1
var current_xp: int = 0
var is_alive: bool = true 
var next_level_xp: int = 1
var min_wait_time: float = 0.2

# как сильно пинают котенка
var knockback_force: float = 500.0
var _knockback_timer: float = 0.0

var health: int
var _invincibility_timer: float = 0.0
var _hp_label: Label = null
var _time_label: Label = null
var _xp_label: Label = null
var _run_time: float = 0.0
var bullet_damage_bonus: int = 0

const LEVEL_UP_MENU_SCENE := preload("res://scenes/ui/level_up_menu.tscn")
const DEATH_SCREEN_SCENE := preload("res://scenes/ui/death.tscn")
const DAMAGE_SFX_STREAM := preload("res://audio/playerGetDamage.mp3")
const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
const AUDIO_SETTINGS_SECTION := "audio"
const AUDIO_ENEMIES_KEY := "enemies"

@export var bullet_scene: PackedScene
@export var max_health: int = 100
@export var invincibility_time: float = 0.1
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_timer: Timer = $ShootTimer

var _damage_sfx_player: AudioStreamPlayer

func _ready():
	_damage_sfx_player = AudioStreamPlayer.new()
	_damage_sfx_player.stream = DAMAGE_SFX_STREAM
	_damage_sfx_player.bus = "Master"
	_damage_sfx_player.volume_db = _get_combat_sfx_volume_db()
	add_child(_damage_sfx_player)

	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	if shoot_timer.wait_time == 0:
		shoot_timer.wait_time = 0.25  
	
	health = max_health
	health_updated.emit(health, max_health)
	level_updated.emit(level)
	
	_hp_label = get_tree().root.get_node_or_null("Main/HUD/HPLabel")
	_update_hp_ui()
	
	_time_label = get_tree().root.get_node_or_null("Main/HUD/TimeLabel")
	_xp_label = get_tree().root.get_node_or_null("Main/HUD/XPLabel")
	_update_xp_ui()
	
	shoot_timer.wait_time = 1

func _physics_process(delta):
	# уменьшения таймера неприкосаемости после пинка
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta
	
	# уменьшения таймера для прекращения улета от пинка
	if _knockback_timer > 0.0:
		_knockback_timer -= delta
		move_and_slide()
		_run_time += delta
		_update_time_ui()
		return  
		
	# Чтение ввода с клавиатуры
	var key_input = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	
	# ОПРЕДЕЛЯЕМ НАПРАВЛЕНИЕ в зависимости от типа управления
	if ControlSettings.is_joystick_enabled():
		# Режим джойстика - используем только ввод от джойстика (через Input actions)
		if key_input.length() > 0.1:
			direction = key_input
			click_position = position
		else:
			direction = Vector2.ZERO
	else:
		# Режим touch - используем нажатие на экран
		# Считываем нажатие мыши/тапа
		if Input.is_action_just_pressed("left_click"):
			click_position = get_global_mouse_position()
		
		if key_input.length() > 0.1:
			direction = key_input
			# Сбрасываем click_position, чтобы клик не "тянул" назад после отпускания клавиш
			click_position = position 
		elif position.distance_to(click_position) > 5:
			direction = (click_position - position).normalized()
		else:
			direction = Vector2.ZERO
	
	velocity = direction * move_speed
	
	if SetState() or SetDirection():
		UpdateAnimation()
	
	move_and_slide()
	
	_run_time += delta
	_update_time_ui()
	_update_xp_ui()

func take_damage(amount: int, knockback_direction: Vector2 = Vector2.ZERO) -> void:
	_apply_damage(amount, knockback_direction)

func _apply_damage(amount: int, knockback_direction: Vector2) -> void:
	if _invincibility_timer > 0.0:
		return
	
	health -= amount
	_invincibility_timer = invincibility_time  
	if _damage_sfx_player:
		_damage_sfx_player.volume_db = _get_combat_sfx_volume_db()
		_damage_sfx_player.play()
	_flash_red()                               
	
	if knockback_direction != Vector2.ZERO:
		_knockback_timer = 0.10
		velocity = knockback_direction * knockback_force
	
	_update_hp_ui()
	health_updated.emit(health, max_health)
	
	if health <= 0:
		_on_player_died()

func _on_player_died() -> void:
	is_alive = false
	velocity = Vector2.ZERO
	direction = Vector2.ZERO
	state = "death"
	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		SetDirection()
		SetState()
		UpdateAnimation()
		get_tree().paused = true
		animation_player.process_mode = AnimationPlayer.PROCESS_MODE_ALWAYS
		await animation_player.animation_finished
		var death_screen = DEATH_SCREEN_SCENE.instantiate()
		get_tree().root.add_child(death_screen)
		if death_screen:
			death_screen.init_stats(_run_time, level)
			death_screen.restart_requested.connect(_on_death_screen_restart)
			death_screen.menu_requested.connect(_on_death_screen_menu)

func _on_death_screen_restart() -> void:
	get_tree().paused = false
	MusicManager.play_gameplay_music()
	get_tree().reload_current_scene()

func _on_death_screen_menu() -> void:
	get_tree().paused = false
	MusicManager.play_menu_music()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func SetDirection() -> bool:
	if direction == Vector2.ZERO:
		return false
	
	var new_dir: Vector2 = cardinal_direction
	
	if abs(direction.x) > abs(direction.y):
		new_dir = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	else:
		new_dir = Vector2.UP if direction.y < 0 else Vector2.DOWN
	
	if new_dir == cardinal_direction:
		return false
	
	cardinal_direction = new_dir
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true
	
func SetState() -> bool:
	var new_state: String = "idle" if direction == Vector2.ZERO else "walk"
	if is_alive == false:
		new_state = "death"
	if new_state == state:
		return false
	state = new_state
	return true
		
		
func UpdateAnimation() -> void:
	var anim_name: String
	if state == "death":
		anim_name = "death"
	else:
		anim_name = state + "_" + AnimDirection()
	
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
		return
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = $Marker2D.global_position
	bullet.direction = (target.global_position - global_position).normalized()
	bullet.damage += bullet_damage_bonus
	get_parent().add_child(bullet)

func add_xp(amount: int) -> void:
	current_xp += amount
	_update_xp_ui()
	emit_signal("xp_updated", current_xp, next_level_xp)
	while current_xp >= next_level_xp:
		current_xp -= next_level_xp
		level += 1
		next_level_xp += 1.5
		_update_xp_ui()
		emit_signal("xp_updated", current_xp, next_level_xp)
		level_updated.emit(level)
		_on_level_up()

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	_update_hp_ui()
	health_updated.emit(health, max_health)

func _on_level_up() -> void:
	level_updated.emit(level)
	if not LEVEL_UP_MENU_SCENE: return
	
	var menu = LEVEL_UP_MENU_SCENE.instantiate()
	if menu:
		if menu.has_signal("option_chosen"):
			menu.option_chosen.connect(_on_level_up_option_chosen)
		get_tree().root.add_child(menu)
		get_tree().paused = true

func _on_level_up_option_chosen(option_id: String) -> void:
	match option_id:
		"hp":
			max_health += 20
			health = max_health
			_update_hp_ui()
			health_updated.emit(health, max_health) 
		"move":
			move_speed += 20.0
		"shoot":
			shoot_timer.wait_time = lerp(shoot_timer.wait_time, min_wait_time, 0.15)
		"dmg":
			bullet_damage_bonus += 10.0 / sqrt(level)
		"dvd":
			$OrbitalWeapon.projectile_count += 1
	get_tree().paused = false

func _update_hp_ui() -> void:
	if _hp_label:
		_hp_label.text = "HP: %d/%d" % [health, max_health]

func _update_time_ui() -> void:
	if _time_label:
		_time_label.text = "				%.2f" % _run_time

func _update_xp_ui() -> void:
	if _xp_label:
		_xp_label.text = "XP: %d/%d" % [current_xp, next_level_xp]

# Метод для получения текущего уровня (используется спавнером)
func get_level() -> int:
	return level

func _flash_red() -> void:
	if sprite:
		sprite.modulate = Color(1.0, 0.2, 0.2, 1.0)
		var tween := get_tree().create_tween()
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _get_combat_sfx_volume_db() -> float:
	var config := ConfigFile.new()
	var err := config.load(AUDIO_SETTINGS_PATH)
	var linear := 1.0
	if err == OK:
		linear = float(config.get_value(AUDIO_SETTINGS_SECTION, AUDIO_ENEMIES_KEY, 1.0))
	linear = clampf(linear, 0.0, 1.0)
	return linear_to_db(linear) if linear > 0.0 else -80.0
