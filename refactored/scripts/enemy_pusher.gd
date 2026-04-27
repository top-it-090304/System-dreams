class_name EnemyPusher
extends CharacterBody2D

# Поведение: подходит к игроку -> толкает собой -> отходит -> повторяет
enum PusherState {
	APPROACH,   # Приближение к игроку
	PUSH,       # Толкание игрока собой
	RETREAT     # Отход назад
}

@export var speed: float = 70.0
@export var health: int = 80
@export var approach_distance: float = 60.0   # Дистанция для начала толкания
@export var retreat_distance: float = 150.0   # Дистанция для отхода
@export var push_duration: float = 2.0        # Время толкания
@export var push_force: float = 100.0         # Сила pushing (просто движение)
@export var exp_scene: PackedScene
@export var heal_scene: PackedScene
@export var heal_drop_chance: float = 0.1

@export var hurt_time: float = 0.1
@export var normal_texture: Texture2D
@export var hurt_texture: Texture2D

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _state_timer: Timer = $StateTimer
@onready var _cross_area: Area2D = $CrossArea  # Область для клика по крестику
@onready var _cross_sprite: Sprite2D = $CrossArea/CrossSprite  # Спрайт крестика

var player: Node2D = null
var current_state: PusherState = PusherState.APPROACH
var _hurt_timer: float = 0.0
var _damage_sfx_player: AudioStreamPlayer

const ENEMY_DAMAGE_SFX_STREAM := preload("res://audio/enemyGetDamage.mp3")
const ENEMY_DEATH_SFX_STREAM := preload("res:///audio/enemyDeath.mp3")
const BUS_ENEMIES_PRIMARY := "Enemies"
const BUS_ENEMIES_FALLBACK := "SFX"
const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
const AUDIO_SETTINGS_SECTION := "audio"
const AUDIO_ENEMIES_KEY := "enemies"

# Уязвимость: получает урон только от клика по крестику
var _is_invulnerable: bool = true

func _ready() -> void:
	_damage_sfx_player = AudioStreamPlayer.new()
	_damage_sfx_player.stream = ENEMY_DAMAGE_SFX_STREAM
	_damage_sfx_player.bus = _resolve_enemy_sfx_bus()
	_damage_sfx_player.volume_db = _get_enemy_sfx_volume_db()
	add_child(_damage_sfx_player)
	
	player = get_tree().get_first_node_in_group("player")
	
	if _state_timer:
		_state_timer.wait_time = push_duration
		_state_timer.timeout.connect(_on_state_timer_timeout)
	
	# Подключаем сигнал клика по крестику (мышь и тач)
	if _cross_area:
		_cross_area.input_event.connect(_on_cross_input_event)
		# Делаем крестик видимым только когда враг активен
		if _cross_sprite:
			_cross_sprite.visible = true

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0 and _sprite and normal_texture:
			_sprite.texture = normal_texture
	
	if player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		
		match current_state:
			PusherState.APPROACH:
				# Приближаемся к игроку
				if distance_to_player <= approach_distance:
					_start_push_state()
				else:
					var direction = (player.global_position - global_position).normalized()
					velocity = direction * speed
					move_and_slide()
			
			PusherState.PUSH:
				# Толкаем игрока собой - просто движемся к нему
				if distance_to_player > retreat_distance:
					_start_retreat_state()
				else:
					# Движемся к игроку с силой push_force, толкая его
					var direction = (player.global_position - global_position).normalized()
					velocity = direction * push_force
					move_and_slide()
			
			PusherState.RETREAT:
				# Отходим назад
				if distance_to_player >= retreat_distance:
					_start_approach_state()
				else:
					var direction = (global_position - player.global_position).normalized()
					velocity = direction * speed
					move_and_slide()

func _start_push_state() -> void:
	current_state = PusherState.PUSH
	if _state_timer:
		_state_timer.start()

func _start_retreat_state() -> void:
	current_state = PusherState.RETREAT

func _start_approach_state() -> void:
	current_state = PusherState.APPROACH

func _on_state_timer_timeout() -> void:
	if current_state == PusherState.PUSH:
		_start_retreat_state()

# Обработка клика по крестику - единственный способ убить врага
# Работает и для мыши, и для тачскрина
func _on_cross_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	# Обрабатываем клик мыши
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		take_damage_from_cross(100)
	# Обрабатываем тач (палец на телефоне)
	elif event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		take_damage_from_cross(100)

# Обычный урон игнорируется (враг неуязвим)
func take_damage(amount: int) -> void:
	# Игнорируем обычный урон
	pass

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


func take_damage_from_cross(amount) -> void:
	health -= amount
	
	if _damage_sfx_player:
		_damage_sfx_player.volume_db = _get_enemy_sfx_volume_db()
		_damage_sfx_player.play()
	
	if _sprite and hurt_texture:
		_sprite.texture = hurt_texture
		_hurt_timer = hurt_time
	
	if health <= 0:
		die()
	pass # Replace with function body.
