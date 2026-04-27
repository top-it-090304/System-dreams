class_name EnemyShooter
extends CharacterBody2D

@export var speed: float = 80.0
@export var health: int = 60
@export var stop_distance: float = 500.0  # Дистанция, на которой враг останавливается для атаки
@export var shoot_cooldown: float = 10.0  # Стреляет раз в 10 секунд
@export var exp_scene: PackedScene
@export var heal_scene: PackedScene
@export var heal_drop_chance: float = 0.1

@export var damage: int = 15
@export var hurt_time: float = 0.1
@export var normal_texture: Texture2D
@export var hurt_texture: Texture2D

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shoot_timer: Timer = $ShootTimer
@onready var _hurt_timer: float = 0.0

var player: Node2D = null
var _attack_timer: float = 0.0
var _damage_sfx_player: AudioStreamPlayer

const ENEMY_DAMAGE_SFX_STREAM := preload("res://audio/enemyGetDamage.mp3")
const ENEMY_DEATH_SFX_STREAM := preload("res:///audio/enemyDeath.mp3")
const BUS_ENEMIES_PRIMARY := "Enemies"
const BUS_ENEMIES_FALLBACK := "SFX"
const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
const AUDIO_SETTINGS_SECTION := "audio"
const AUDIO_ENEMIES_KEY := "enemies"

# Сцены для разных типов пуль (для удобной настройки в редакторе)
@export var i_bullet_scene: PackedScene  # I-фигура
@export var o_bullet_scene: PackedScene  # O-фигура
@export var t_bullet_scene: PackedScene  # T-фигура
@export var l_bullet_scene: PackedScene  # L-фигура
@export var z_bullet_scene: PackedScene  # Z-фигура

func _ready() -> void:
	_damage_sfx_player = AudioStreamPlayer.new()
	_damage_sfx_player.stream = ENEMY_DAMAGE_SFX_STREAM
	_damage_sfx_player.bus = _resolve_enemy_sfx_bus()
	_damage_sfx_player.volume_db = _get_enemy_sfx_volume_db()
	add_child(_damage_sfx_player)
	
	player = get_tree().get_first_node_in_group("player")
	
	if _shoot_timer:
		_shoot_timer.wait_time = shoot_cooldown
		_shoot_timer.timeout.connect(_on_shoot_timer_timeout)
		_shoot_timer.start()

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0 and _sprite and normal_texture:
			_sprite.texture = normal_texture
	
	# Враг всегда остается на месте - движение отключено

func _on_shoot_timer_timeout() -> void:
	if player and is_instance_valid(player):
		shoot_at_player()
		# Перезапускаем таймер
		_shoot_timer.start()

func shoot_at_player() -> void:
	# Собираем все доступные сцены пуль в массив
	var bullet_scenes = []
	
	if i_bullet_scene:
		bullet_scenes.append(i_bullet_scene)
	if o_bullet_scene:
		bullet_scenes.append(o_bullet_scene)
	if t_bullet_scene:
		bullet_scenes.append(t_bullet_scene)
	if l_bullet_scene:
		bullet_scenes.append(l_bullet_scene)
	if z_bullet_scene:
		bullet_scenes.append(z_bullet_scene)
	
	# Если нет ни одной сцены, выходим
	if bullet_scenes.is_empty():
		return
	
	# Выбираем случайную пулю из доступных
	var selected_bullet_scene = bullet_scenes[randi() % bullet_scenes.size()]
	
	# Создаем и запускаем выбранную пулю
	var bullet = selected_bullet_scene.instantiate()
	bullet.global_position = global_position
	
	# Направляем пулю в сторону игрока
	var direction_to_player = (player.global_position - global_position).normalized()
	bullet.direction = direction_to_player
	
	get_parent().add_child(bullet)

func take_damage(amount: int) -> void:
	health -= amount
	
	if _damage_sfx_player:
		_damage_sfx_player.volume_db = _get_enemy_sfx_volume_db()
		_damage_sfx_player.play()
	
	if _sprite and hurt_texture:
		_sprite.texture = hurt_texture
		_hurt_timer = hurt_time
	
	if health <= 0:
		die()

func die() -> void:
	_play_death_sfx()
	
	# Иногда вместо опыта падает хилка
	if heal_scene and randf() < heal_drop_chance:
		var heal = heal_scene.instantiate()
		heal.global_position = global_position
		get_parent().add_child(heal)
	elif exp_scene:
		var exp = exp_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)
	
	queue_free()

func _resolve_enemy_sfx_bus() -> String:
	if AudioServer.get_bus_index(BUS_ENEMIES_PRIMARY) != -1:
		return BUS_ENEMIES_PRIMARY
	if AudioServer.get_bus_index(BUS_ENEMIES_FALLBACK) != -1:
		return BUS_ENEMIES_FALLBACK
	return "Master"

func _play_death_sfx() -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = ENEMY_DEATH_SFX_STREAM
	audio.bus = _resolve_enemy_sfx_bus()
	audio.volume_db = _get_enemy_sfx_volume_db()
	get_tree().root.add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()

func _get_enemy_sfx_volume_db() -> float:
	var config := ConfigFile.new()
	var err := config.load(AUDIO_SETTINGS_PATH)
	var linear := 1.0
	
	if err == OK:
		linear = float(config.get_value(AUDIO_SETTINGS_SECTION, AUDIO_ENEMIES_KEY, 1.0))
	
	linear = clampf(linear, 0.0, 1.0)
	return linear_to_db(linear) if linear > 0.0 else -80.0
