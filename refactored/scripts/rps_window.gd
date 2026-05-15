class_name RPSWindow
extends CanvasLayer

# Окно мини-игры "Камень-Ножницы-Бумага"
# Открывается при контакте с EnemyRPS

signal option_chosen(choice: int, enemy_choice: int)  # choice: 0 = Камень, 1 = Ножницы, 2 = Бумага

@onready var _rock_button: Button = $Control/RockButton
@onready var _scissors_button: Button = $Control/ScissorsButton
@onready var _paper_button: Button = $Control/PaperButton
@onready var _result_label: Label = $Control/ResultLabel
@onready var _animated_sprite: AnimatedSprite2D = $Control/AnimatedSprite2D

# TODO: Assign sprites for RPS buttons here
@export var rock_sprite: Texture2D
@export var scissors_sprite: Texture2D
@export var paper_sprite: Texture2D

var _is_choice_made: bool = false

# Ссылка на окно результата
var _rps_result_window: RPSResultWindow = null
var _current_player_choice: int = 0
var _current_enemy_choice: int = 0

func _ready() -> void:
	print("[RPSWindow] _ready вызван!")
	process_mode = PROCESS_MODE_WHEN_PAUSED
	layer = 30  # Поверх всех UI элементов
	print("[RPSWindow] Окно готово, process_mode=WHEN_PAUSED, layer=30")
	
	# Устанавливаем спрайты на кнопки (если назначены)
	_set_button_sprites()
	
	# Скрываем результат до выбора
	if _result_label:
		_result_label.visible = false
	
	# Создаем окно результата после добавления в дерево сцены
	await get_tree().process_frame
	await get_tree().process_frame
	_create_result_window()

func _create_result_window() -> void:
	# Загружаем и создаем окно результата
	var result_scene = load("res://scenes/ui/rps_result_window.tscn")
	if result_scene:
		_rps_result_window = result_scene.instantiate() as RPSResultWindow
		if _rps_result_window == null:
			print("[RPSWindow] ОШИБКА: instantiate() вернул null!")
			return
		
		# Добавляем окно результата в корень сцены, т.к. это CanvasLayer
		get_tree().root.add_child(_rps_result_window)
		
		# Проверяем что сигнал существует перед подключением
		if _rps_result_window.has_signal("result_confirmed"):
			_rps_result_window.result_confirmed.connect(_on_result_confirmed)
			print("[RPSWindow] Окно результата создано и добавлено в root")
		else:
			print("[RPSWindow] ОШИБКА: У окна результата нет сигнала result_confirmed!")
	else:
		print("[RPSWindow] ОШИБКА: Не удалось загрузить сцену окна результата!")

func _set_button_sprites() -> void:
	# TODO: If using texture buttons instead of regular buttons, assign textures here
	pass


func _make_choice(player_choice: int) -> void:
	if _is_choice_made:
		return
	
	_is_choice_made = true
	_current_player_choice = player_choice
	
	# Генерируем выбор врага
	_current_enemy_choice = randi() % 3
	
	# Скрываем кнопки выбора, но оставляем окно видимым для анимации
	_rock_button.visible = false
	_scissors_button.visible = false
	_paper_button.visible = false
	$Control/InstructionLabel.visible = false
	
	# Запускаем анимацию на встроенном AnimatedSprite2D
	if _animated_sprite and _animated_sprite.sprite_frames:
		_play_animation(player_choice, _current_enemy_choice)
	else:
		# Если нет анимации, сразу показываем результат
		_show_result(_determine_winner(player_choice, _current_enemy_choice))

func _play_animation(player_choice: int, enemy_choice: int) -> void:
	# Получаем имя анимации для данной комбинации
	var anim_name = _get_animation_name(player_choice, enemy_choice)
	
	if _animated_sprite.sprite_frames.has_animation(anim_name):
		print("[RPSWindow] Запуск анимации: ", anim_name)
		_animated_sprite.play(anim_name)
		
		# Ждем завершения анимации
		await _animated_sprite.animation_finished
		print("[RPSWindow] Анимация завершена")
		_on_animation_finished(player_choice, enemy_choice)
	else:
		print("[RPSWindow] ОШИБКА: Не найдена анимация ", anim_name)
		# Если анимация не найдена, просто ждем немного и завершаем
		await get_tree().create_timer(1.0).timeout
		_on_animation_finished(player_choice, enemy_choice)

func _get_animation_name(player: int, enemy: int) -> String:
	# 0 = Камень (rock), 1 = Ножницы (scissors), 2 = Бумага (paper)
	var player_names = ["rock", "scissors", "paper"]
	var enemy_names = ["rock", "scissors", "paper"]
	
	var player_name = player_names[player]
	var enemy_name = enemy_names[enemy]
	
	return "%s_%s" % [player_name, enemy_name]

func _on_animation_finished(player_choice: int, enemy_choice: int) -> void:
	# После завершения анимации показываем результат
	var result = _determine_winner(player_choice, enemy_choice)
	_show_result(result)

func _show_result(result: String) -> void:
	if _rps_result_window:
		var result_text = ""
		match result:
			"win":
				result_text = "Ты победил!"
			"lose":
				result_text = "Ты проиграл!"
			"draw":
				result_text = "Ничья!"
		_rps_result_window.show_result(result_text)

func _on_result_confirmed() -> void:
	# Эмитим сигнал с выбором игрока и врага (для обработки в enemy_rps)
	option_chosen.emit(_current_player_choice, _current_enemy_choice)
	
	# Очищаем ресурсы
	if _rps_result_window:
		_rps_result_window.queue_free()
		_rps_result_window = null
	
	# Сбрасываем анимацию
	if _animated_sprite:
		_animated_sprite.stop()
		_animated_sprite.frame = 0
	
	# Восстанавливаем видимость кнопок для следующего использования
	_rock_button.visible = true
	_scissors_button.visible = true
	_paper_button.visible = true
	$Control/InstructionLabel.visible = true
	
	# Закрываем окно
	queue_free()
	
	# После закрытия окна RPSManager обработает сигнал и вызовет resolve_rps_result,
	# который снимет паузу и восстановит видимость игрока

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


func _on_paper_button_pressed() -> void:
	_make_choice(2)



func _on_scissors_button_pressed() -> void:
	_make_choice(1)



func _on_rock_button_pressed() -> void:
	_make_choice(0)
