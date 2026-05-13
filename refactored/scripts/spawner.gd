extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 200.0
@export var min_spawn_distance_from_player: float = 150.0
@export var max_spawn_position_attempts: int = 12

# Новые типы врагов
@export var nyan_boss_scene: PackedScene
@export var shooter_enemy_scene: PackedScene
@export var pusher_enemy_scene: PackedScene
@export var rps_enemy_scene: PackedScene

# Базовые веса спавна для разных типов врагов
@export var default_weight: int = 50
@export var shooter_weight: int = 20
@export var pusher_weight: int = 15

# боссярик раз в 5 минут спавнится 
@export var nyan_boss_spawn_interval: float = 30.0 
@export var nyan_boss_spawn_radius: float = 400.0

@onready var nyan_timer: Timer = Timer.new() # 

# флаг присутствия босса
var nyan_boss_present: bool = false

# RPS враг спавнится отдельно раз в минуту
@export var rps_spawn_interval: float = 60.0  # 1 минута
@export var rps_spawn_radius: float = 300.0

# Лимиты на количество врагов
@export var max_shooters_active: int = 2  # Максимум 2 шутера одновременно

# Настройки сложности
@export var base_spawn_interval: float = 2.0  # Базовый интервал спавна (уменьшается с уровнем)
@export var min_spawn_interval: float = 0.5  # Минимальный интервал спавна
@export var health_scaling_factor: float = 0.15  # Множитель здоровья за уровень (15%)
@export var enemy_count_increase_rate: int = 1  # Добавление врагов каждые N уровней

@onready var timer = $Timer
@onready var rps_timer: Timer = $RPSTimer

# Отслеживаем наличие RPS врага на карте
var rps_enemy_present: bool = false

# Отслеживаем активных шутеров
var active_shooters: Array = []

# Игровое время в секундах
var game_time: float = 0.0

# Текущий уровень игрока (для масштабирования)
var player_level: int = 1

func _ready():
	timer.timeout.connect(_on_spawn_timer_timeout)
	rps_timer.timeout.connect(_on_rps_spawn_timer_timeout)
	rps_timer.wait_time = rps_spawn_interval
	rps_timer.autostart = true
	
	# Устанавливаем начальный таймер спавна
	timer.wait_time = base_spawn_interval
	timer.start()
	
	add_child(nyan_timer)
	nyan_timer.timeout.connect(_on_nyan_spawn_timer_timeout)
	nyan_timer.wait_time = nyan_boss_spawn_interval
	nyan_timer.start()

func _process(delta):
	if not get_tree().paused:
		game_time += delta
		
		# Обновляем уровень игрока если есть доступ
		var player = get_parent().get_node_or_null("Player")
		if player and player.has_method("get_level"):
			var new_level = player.get_level()
			if new_level != player_level:
				player_level = new_level
				_update_difficulty()

func _on_spawn_timer_timeout():
	spawn_enemy()

func _on_rps_spawn_timer_timeout():
	spawn_rps_enemy()

# Обновление сложности на основе уровня игрока
func _update_difficulty():
	# Уменьшаем интервал спавна с ростом уровня
	var new_interval = base_spawn_interval * pow(0.85, player_level - 1)
	new_interval = max(new_interval, min_spawn_interval)
	timer.wait_time = new_interval
	
	print("Level: ", player_level, " Spawn interval: ", new_interval)

func spawn_enemy():
	var player := get_parent().get_node_or_null("Player")
	
	if player == null:
		return
	
	# Выбираем тип врага на основе весов и ограничений
	var enemy_to_spawn = _select_enemy_type(player)
	
	if enemy_to_spawn == null:
		return
	
	var enemy = enemy_to_spawn.instantiate()
	
	# Масштабируем здоровье врага в зависимости от уровня игрока
	_scale_enemy_stats(enemy, player)
	
	var attempts := 0
	var spawn_pos := global_position
	while attempts < max_spawn_position_attempts:
		attempts += 1
		var random_offset := Vector2(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(-spawn_radius, spawn_radius)
		)
		var candidate := global_position + random_offset
		if candidate.distance_to(player.global_position) >= min_spawn_distance_from_player:
			spawn_pos = candidate
			break
	
	enemy.global_position = spawn_pos
	get_parent().add_child(enemy)
	
	# Если это шутер, добавляем его в список активных
	if enemy is EnemyShooter:
		active_shooters.append(enemy)
		# Подключаемся к сигналу смерти чтобы убрать из списка
		if enemy.has_signal("tree_exited"):
			enemy.tree_exited.connect(_on_shooter_died.bind(enemy))

func spawn_rps_enemy():
	# Проверяем, есть ли уже RPS враг на карте
	if rps_enemy_present:
		return
	
	# Проверяем, прошла ли минимум минута игры
	if game_time < rps_spawn_interval:
		return
	
	var player := get_parent().get_node_or_null("Player")
	
	if rps_enemy_scene == null or player == null:
		return
	
	var enemy = rps_enemy_scene.instantiate()
	
	# Масштабируем здоровье RPS врага
	_scale_enemy_stats(enemy, player)
	
	# Пытаемся найти позицию для спавна
	var attempts := 0
	var spawn_pos := global_position
	while attempts < max_spawn_position_attempts:
		attempts += 1
		var random_offset := Vector2(
			randf_range(-rps_spawn_radius, rps_spawn_radius),
			randf_range(-rps_spawn_radius, rps_spawn_radius)
		)
		var candidate := global_position + random_offset
		if candidate.distance_to(player.global_position) >= min_spawn_distance_from_player:
			spawn_pos = candidate
			break
	
	enemy.global_position = spawn_pos
	get_parent().add_child(enemy)
	
	# Помечаем что RPS враг теперь на карте
	rps_enemy_present = true
	
	# Подключаемся к сигналу смерти врага чтобы сбросить флаг
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(_on_rps_enemy_died)

# Выбор типа врага на основе весов и ограничений
func _select_enemy_type(player: Node2D) -> PackedScene:
	# Проверяем сколько сейчас активных шутеров
	_cleanup_inactive_shooters()
	var current_shooter_count = active_shooters.size()
	
	# Если уже макс шутеров, временно убираем их из пула спавна
	var available_shooter_weight = shooter_weight if current_shooter_count < max_shooters_active else 0
	
	# Шутер появляется редко - примерно раз в 7 уровней
	# Используем модulo от уровня чтобы определить можно ли спавнить шутера
	var can_spawn_shooter = (player_level % 7 == 0) or available_shooter_weight > 0
	
	# Если не время для шутера и у нас уже есть шутеры, сильно снижаем вес
	if not can_spawn_shooter and current_shooter_count > 0:
		available_shooter_weight = 0
	
	var total_weight = default_weight + available_shooter_weight + pusher_weight
	var random_value = randi() % total_weight
	
	# Собираем все доступные сцены в массив
	var scenes = []
	var weights = []
	
	# Добавляем дефолтного врага если он назначен
	if enemy_scene:
		scenes.append(enemy_scene)
		weights.append(default_weight)
	
	# Добавляем шутера если он доступен
	if shooter_enemy_scene and available_shooter_weight > 0:
		scenes.append(shooter_enemy_scene)
		weights.append(available_shooter_weight)
	
	if pusher_enemy_scene:
		scenes.append(pusher_enemy_scene)
		weights.append(pusher_weight)
	
	# Если нет ни одной сцены, возвращаем null
	if scenes.is_empty():
		return null
	
	# Выбираем сцену на основе весов
	var cumulative_weight = 0
	for i in range(scenes.size()):
		cumulative_weight += weights[i]
		if random_value < cumulative_weight:
			return scenes[i]
	
	# По умолчанию возвращаем последнюю сцену
	return scenes[-1]

# Масштабирование характеристик врага
func _scale_enemy_stats(enemy: Node, player: Node2D):
	if enemy == null:
		return
	
	# Базовый множитель сложности
	var difficulty_multiplier = 1.0 + ((player_level - 1) * health_scaling_factor)
	
	# Применяем к здоровью если у врага есть такое свойство
	if enemy.has_method("set_health_multiplier"):
		enemy.set_health_multiplier(difficulty_multiplier)
	elif "health" in enemy:
		var base_health = enemy.health
		enemy.health = int(base_health * difficulty_multiplier)
	
	# Можно добавить масштабирование других характеристик при необходимости

func _on_rps_enemy_died() -> void:
	rps_enemy_present = false

func _on_shooter_died(shooter: Node) -> void:
	active_shooters.erase(shooter)

func _cleanup_inactive_shooters():
	# Удаляем из списка шутеров которые больше не активны
	for shooter in active_shooters:
		if not is_instance_valid(shooter) or not shooter.is_inside_tree():
			active_shooters.erase(shooter)
			
			
func _on_nyan_spawn_timer_timeout():
	spawn_nyan_boss()

func spawn_nyan_boss():
	# проверяем лимит (1 враг) и наличие сцены
	if nyan_boss_present or nyan_boss_scene == null:
		return
		
	var player := get_parent().get_node_or_null("Player")
	if player == null:
		return

	var boss = nyan_boss_scene.instantiate()
	
	_scale_enemy_stats(boss, player)
	
	# Поиск позиции
	var attempts := 0
	var spawn_pos := global_position
	while attempts < max_spawn_position_attempts:
		attempts += 1
		var random_offset := Vector2.from_angle(randf() * TAU) * nyan_boss_spawn_radius
		var candidate: Vector2 = player.global_position + random_offset
		if candidate.distance_to(player.global_position) >= min_spawn_distance_from_player:
			spawn_pos = candidate
			break
			
	boss.global_position = spawn_pos
	get_parent().add_child(boss)
	
	nyan_boss_present = true
	
	if boss.has_signal("tree_exited"):
		boss.tree_exited.connect(func(): nyan_boss_present = false)
	
	get_parent().add_child(boss)
	nyan_boss_present = true

	var hud_nodes = get_tree().get_nodes_in_group("hud_group")
	if hud_nodes.size() > 0:
		var hud = hud_nodes[0]
		
		if "fire_sprite" in hud:
			hud.fire_sprite.visible = true
			hud.fire_sprite.play("default")
		
		if hud.has_method("show_boss_bar"):
			hud.show_boss_bar(boss.health)
		
		if boss.has_signal("health_updated"): 
			boss.health_updated.connect(hud.update_boss_bar)

		boss.tree_exited.connect(func():
			nyan_boss_present = false
			if is_instance_valid(hud):
				hud.hide_boss_bar()
				if "fire_sprite" in hud:
					hud.fire_sprite.visible = false
		)
