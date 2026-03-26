extends CanvasLayer

class_name DeathScreen

signal restart_requested
signal menu_requested

@onready var restart_btn := $VBoxContainer/RestartButton
@onready var menu_btn := $VBoxContainer/MenuButton

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	layer = 20
	
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

func _on_restart_pressed() -> void:
	restart_requested.emit()
	queue_free()


func _on_menu_pressed() -> void:
	menu_requested.emit()
	queue_free()
