class_name RPSAnimation
extends CanvasLayer

# Анимация для мини-игры "Камень-Ножницы-Бумага"
# Проигрывает спрайтовую анимацию с выбором игрока и врага

signal animation_finished(player_choice: int, enemy_choice: int)

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _player_choice: int = 0
var _enemy_choice: int = 0

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	layer = 25
	visible = false

# Запуск анимации с передачей выборов
func play_animation(player_choice: int, enemy_choice: int) -> void:
	_player_choice = player_choice
	_enemy_choice = enemy_choice
	
	visible = true
	
	# Получаем имя анимации для данной комбинации
	var anim_name = _get_animation_name(player_choice, enemy_choice)
	
	if _animated_sprite and _animated_sprite.sprite_frames and _animated_sprite.sprite_frames.has_animation(anim_name):
		print("[RPSAnimation] Запуск анимации: ", anim_name)
		_animated_sprite.play(anim_name)
		
		# Ждем завершения анимации
		await _animated_sprite.animation_finished
		print("[RPSAnimation] Анимация завершена")
		_finish_animation()
	else:
		print("[RPSAnimation] ОШИБКА: Не найдена анимация ", anim_name)
		# Если анимация не найдена, просто ждем немного и завершаем
		await get_tree().create_timer(1.0).timeout
		_finish_animation()

func _get_animation_name(player: int, enemy: int) -> String:
	# 0 = Камень (rock), 1 = Ножницы (scissors), 2 = Бумага (paper)
	var player_names = ["rock", "scissors", "paper"]
	var enemy_names = ["rock", "scissors", "paper"]
	
	var player_name = player_names[player]
	var enemy_name = enemy_names[enemy]
	
	return "%s_%s" % [player_name, enemy_name]

func _finish_animation() -> void:
	visible = false
	_animated_sprite.stop()
	animation_finished.emit(_player_choice, _enemy_choice)
