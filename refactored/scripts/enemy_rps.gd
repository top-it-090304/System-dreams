class_name EnemyRPS
extends CharacterBody2D

# Враг "Камень-Ножницы-Бумага"
# При касании игрока запускается мини-игра

@export var speed: float = 90.0
@export var health: int = 50
@export var exp_scene: PackedScene
@export var heal_scene: PackedScene
@export var heal_drop_chance: float = 0.1
@export var attack_range: float = 70.0

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var player: Node2D = null
var _damage_sfx_player: AudioStreamPlayer
var _is_contact_active: bool = false
var _original_player_visible: bool = true
var _is_dead: bool = false

const ENEMY_DAMAGE_SFX_STREAM := preload("res://audio/enemyGetDamage.mp3")
const ENEMY_DEATH_SFX_STREAM := preload("res:///audio/enemyDeath.mp3")
const BUS_ENEMIES_PRIMARY := "Enemies"
const BUS_ENEMIES_FALLBACK := "SFX"
const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
const AUDIO_SETTINGS_SECTION := "audio"
const AUDIO_ENEMIES_KEY := "enemies"

# Сигнал для открытия UI окна КНБ
signal rps_contact_started(enemy)
signal rps_contact_ended()

func _ready() -> void:
	_damage_sfx_player = AudioStreamPlayer.new()
	_damage_sfx_player.stream = ENEMY_DAMAGE_SFX_STREAM
	_damage_sfx_player.bus = _resolve_enemy_sfx_bus()
	_damage_sfx_player.volume_db = _get_enemy_sfx_volume_db()
	add_child(_damage_sfx_player)
	
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	
	if _is_dead:
		# Враг уже мертв, не обрабатываем логику
		return
	
	if _is_contact_active:
		# Во время контакта не двигаемся
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player > attack_range:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
			
			if not _is_contact_active:
				_start_rps_contact()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _is_contact_active and not _is_dead:
		_start_rps_contact()

func _start_rps_contact() -> void:
	if _is_dead:
		# Враг уже мертв, не запускаем контакт
		return
	
	print("[EnemyRPS] _start_rps_contact вызван!")
	_is_contact_active = true
	velocity = Vector2.ZERO
	
	# Отключаем коллизию чтобы игрок не получал урон от столкновения
	if _collision_shape:
		_collision_shape.set_deferred("disabled", true)
	
	# Сохраняем текущую видимость игрока и делаем его невидимым
	if player and is_instance_valid(player):
		_original_player_visible = player.is_visible()
		player.visible = false
	
	# Скрываем обычный спрайт и показываем анимированный
	if _animated_sprite:
		_animated_sprite.visible = true
	
	# Останавливаем игру на время проигрывания анимации
	print("[EnemyRPS] Остановка игры (paused = true)")
	get_tree().paused = true
	
	# Проигрываем анимацию finded через AnimatedSprite2D
	if _animated_sprite and _animated_sprite.sprite_frames and _animated_sprite.sprite_frames.has_animation("finded"):
		print("[EnemyRPS] Запуск анимации 'finded'")
		_animated_sprite.play("finded")
		# Ждем завершения анимации с таймаутом на случай проблем с однокадровой анимацией
		# Таймеры create_timer по умолчанию работают во время паузы (time_paused=false)
		var timer = get_tree().create_timer(0.5)
		await timer.timeout
		print("[EnemyRPS] Анимация 'finded' завершена (или таймаут)")
	else:
		print("[EnemyRPS] Анимация 'finded' не найдена, пропускаем")
		# Небольшая задержка даже если нет анимации
		var timer = get_tree().create_timer(0.3)
		await timer.timeout
	
	# После завершения анимации открываем UI
	# Эмитим сигнал для открытия UI окна КНБ
	print("[EnemyRPS] Эмит сигнала rps_contact_started")
	rps_contact_started.emit(self)

# Метод вызывается из UI после выбора игрока
func resolve_rps_result(player_choice: int) -> void:
	# 0 = Камень, 1 = Ножницы, 2 = Бумага
	var enemy_choice = randi() % 3
	
	var result = _determine_winner(player_choice, enemy_choice)
	
	print("[EnemyRPS] resolve_rps_result вызван! Результат: ", result)
	
	# Сначала снимаем паузу и восстанавливаем видимость игрока
	_is_contact_active = false
	get_tree().paused = false
	
	# Восстанавливаем видимость игроку перед обработкой результата
	if player and is_instance_valid(player):
		player.visible = _original_player_visible
	
	# Восстанавливаем видимость анимированного спрайта
	if _animated_sprite:
		_animated_sprite.visible = false
	
	# Теперь обрабатываем результат
	match result:
		"win":
			# Победа игрока - сначала убиваем текущего врага, потом всех остальных
			print("[EnemyRPS] ПОБЕДА! Убиваем текущего врага и всех остальных")
			die()
			_kill_all_enemies()
		"draw":
			# Ничья - умирает только этот враг (без урона игроку)
			print("[EnemyRPS] НИЧЬЯ! Умирает только этот враг")
			die()
		"lose":
			# Проигрыш - игрок получает 30 урона, этот враг умирает
			print("[EnemyRPS] ПРОИГРЫШ! Игрок получает 30 урона")
			if player and is_instance_valid(player) and player.has_method("take_damage"):
				player.take_damage(30, Vector2.ZERO)
			die()
	
	# Эмитим сигнал о завершении контакта
	rps_contact_ended.emit()

func _determine_winner(player_choice: int, enemy_choice: int) -> String:
	# 0 = Камень, 1 = Ножницы, 2 = Бумага
	if player_choice == enemy_choice:
		return "draw"
	
	# Камень бьет ножницы, ножницы бьют бумагу, бумага бьет камень
	if (player_choice == 0 and enemy_choice == 1) or \
	   (player_choice == 1 and enemy_choice == 2) or \
	   (player_choice == 2 and enemy_choice == 0):
		return "win"
	
	return "lose"

func _kill_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		# Пропускаем самого себя, т.к. мы уже умерли в die()
		if enemy == self:
			continue
		if enemy.has_method("die"):
			enemy.die()
		elif enemy.has_method("queue_free"):
			# Если у врага нет метода die, просто удаляем
			# Но сначала пытаемся дропнуть лут
			if enemy.has_method("_play_death_sfx"):
				enemy._play_death_sfx()
			enemy.queue_free()

func take_damage(amount: int) -> void:
	if _is_contact_active:
		# Во время контакта КНБ враг неуязвим
		return
	
	health -= amount
	
	if _damage_sfx_player:
		_damage_sfx_player.volume_db = _get_enemy_sfx_volume_db()
		_damage_sfx_player.play()
	
	if health <= 0:
		die()

func die() -> void:
	if _is_dead:
		# Уже мертв, не обрабатываем смерть повторно
		return
	
	_is_dead = true
	print("[EnemyRPS] Враг помечен как мертвый (_is_dead = true)")
	
	_play_death_sfx()
	
	# Возвращаем видимость игроку при смерти врага
	if player and is_instance_valid(player):
		player.visible = _original_player_visible
	
	# Восстанавливаем видимость анимированного спрайта
	if _animated_sprite:
		_animated_sprite.visible = false
	
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
