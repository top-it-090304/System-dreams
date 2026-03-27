extends CanvasLayer

class_name DeathScreen

signal restart_requested
signal menu_requested

@onready var restart_btn: Button = $Control/GameOver/RestartButton
@onready var menu_btn: Button = $Control/GameOver/MenuButton

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	layer = 20
	

	# Подключаем сигналы
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)


func _on_restart_pressed() -> void:
	print("Restart pressed!")
	restart_requested.emit()
	queue_free()


func _on_menu_pressed() -> void:
	print("Menu pressed!")
	menu_requested.emit()
	queue_free()
