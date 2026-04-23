extends CharacterBody2D
@export var speed = 20;
@export var speed_variants: Array[float]= [100.0, 200.0 ,70.0, 85.0]
@export var health: int = 100
@export var health_variants: Array[int]= [100, 10, 50, 66, 200]
@export var exp_scene: PackedScene
@export var heal_scene: PackedScene
@export var heal_drop_chance: float = 0.1
@export var normal_texture: Texture2D
@export var normal_texture_variants: Array[Texture2D] = []
@export var hurt_texture: Texture2D
@export var hurt_time: float = 0.1
@export var attack_range: float = 70.0
@export var attack_cooldown: float = 0.8
@onready var _sprite: Sprite2D = $Sprite2D
@export var damage: int = 10
const ENEMY_DAMAGE_SFX_STREAM := preload("res://audio/enemyGetDamage.mp3")
const ENEMY_DEATH_SFX_STREAM := preload("res:///audio/enemyDeath.mp3")
const BUS_ENEMIES_PRIMARY := "Enemies"
const BUS_ENEMIES_FALLBACK := "SFX"
const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
const AUDIO_SETTINGS_SECTION := "audio"
const AUDIO_ENEMIES_KEY := "enemies"

var _attack_timer: float = 0.0
var _hurt_timer: float = 0.0
var player: Node2D = null
var _damage_sfx_player: AudioStreamPlayer

func _ready() -> void:
	_damage_sfx_player = AudioStreamPlayer.new()
	_damage_sfx_player.stream = ENEMY_DAMAGE_SFX_STREAM
	_damage_sfx_player.bus = _resolve_enemy_sfx_bus()
	_damage_sfx_player.volume_db = _get_enemy_sfx_volume_db()
	add_child(_damage_sfx_player)

	player = get_tree().get_first_node_in_group("player")
	#рандомизация врагов по цвету, hp и скорости
	if not speed_variants.is_empty():
		speed = speed_variants[randi() % speed_variants.size()]
	if not health_variants.is_empty():
		health = health_variants[randi() % health_variants.size()]
	if not normal_texture_variants.is_empty():
		normal_texture = normal_texture_variants[randi() % normal_texture_variants.size()]
	if _sprite and normal_texture:
		_sprite.texture = normal_texture

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return

	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player > attack_range:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
			
			if _attack_timer <= 0.0:
				attack()
				_attack_timer = attack_cooldown
			else:
				_attack_timer -= delta
	
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0 and _sprite and normal_texture:
			_sprite.texture = normal_texture
			
func attack() -> void:
	if player and player.has_method("take_damage"):
		var direction_to_player = (player.global_position - global_position).normalized()
		
		player.take_damage(damage, direction_to_player)
		
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

	# иногда вместо опыта падает хилка
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
