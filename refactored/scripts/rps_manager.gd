class_name RPSManager
extends Node

# Менеджер для обработки мини-игры "Камень-Ножницы-Бумага"
# Связывает EnemyRPS с UI окном

# Путь к сцене окна КНБ (PackedScene)
var rps_window_scene: PackedScene
var current_rps_enemy: EnemyRPS = null
# Переменная для экземпляра окна, инициализируется как null
var rps_window_instance: RPSWindow = null

const RPS_WINDOW_SCENE_PATH := "res://scenes/ui/rps_window.tscn"

func _ready() -> void:
	print("[RPSManager] _ready вызван!")
	# Загружаем сцену окна КНБ как PackedScene
	rps_window_scene = load(RPS_WINDOW_SCENE_PATH) as PackedScene
	print("[RPSManager] Окно КНБ загружено: ", rps_window_scene != null)
	
	# Подключаемся ко всем будущим врагам RPS через сигнал спавнера
	# Используем enter_tree чтобы подключаться к уже существующим и будущим врагам
	var tree = get_tree()
	if tree:
		print("[RPSManager] Подключение к node_added сигналу")
		tree.node_added.connect(_on_node_added)
	
	# Также проверяем уже существующих врагов в сцене
	_for_each_existing_enemy(tree)
	print("[RPSManager] Проверка существующих врагов завершена")

func _for_each_existing_enemy(tree: SceneTree) -> void:
	if not tree:
		return
	
	var enemies = tree.get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy is EnemyRPS:
			_on_node_added(enemy)

func _on_node_added(node: Node) -> void:
	if node is EnemyRPS:
		print("[RPSManager] Найден EnemyRPS, подключаем сигналы")
		node.rps_contact_started.connect(_on_rps_contact_started)
		node.rps_contact_ended.connect(_on_rps_contact_ended)

func _on_rps_contact_started(enemy: EnemyRPS) -> void:
	print("[RPSManager] _on_rps_contact_started вызван!")
	if current_rps_enemy != null:
		print("[RPSManager] Уже идет игра с другим врагом, выходим")
		return  # Уже идет игра с другим врагом
	
	current_rps_enemy = enemy
	print("[RPSManager] Текущий враг установлен: ", enemy)
	
	# Создаем и показываем окно КНБ
	if rps_window_scene:
		print("[RPSManager] Создание экземпляра окна КНБ")
		# Инициализируем экземпляр через instantiate() и приводим к типу RPSWindow
		var instance = rps_window_scene.instantiate()
		
		if instance == null:
			print("[RPSManager] ОШИБКА: Не удалось создать экземпляр сцены!")
			return
		
		rps_window_instance = instance as RPSWindow
		
		if rps_window_instance == null:
			print("[RPSManager] ОШИБКА: Созданный экземпляр не является RPSWindow! Тип: ", instance.get_class())
			return
		
		get_tree().root.add_child(rps_window_instance)
		print("[RPSManager] Окно КНБ добавлено в сцену! Instance: ", rps_window_instance)
		print("[RPSManager] Тип окна: ", rps_window_instance.get_class())
		
		# Подключаемся к сигналу выбора
		if rps_window_instance.has_signal("option_chosen"):
			print("[RPSManager] Подключение к сигналу option_chosen")
			rps_window_instance.option_chosen.connect(_on_rps_option_chosen)
		else:
			print("[RPSManager] ОШИБКА: Окно не имеет сигнала option_chosen")
			print("[RPSManager] Доступные сигналы: ", rps_window_instance.get_signal_list())
	else:
		print("[RPSManager] ОШИБКА: rps_window_scene не загружен!")

func _on_rps_option_chosen(choice: int) -> void:
	if current_rps_enemy and is_instance_valid(current_rps_enemy):
		# Передаем выбор игрока врагу для разрешения результата
		# resolve_rps_result снимет паузу и восстановит видимость игрока
		current_rps_enemy.resolve_rps_result(choice)
	
	# Сбрасываем ссылку на окно, т.к. оно уже закрыто
	rps_window_instance = null

func _on_rps_contact_ended() -> void:
	# Сбрасываем текущего врага при завершении контакта
	current_rps_enemy = null
	rps_window_instance = null
