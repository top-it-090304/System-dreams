extends CanvasLayer

class_name Pause

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED  # вместо 2
	layer = 20
	
	# Используем правильные имена узлов
	$Control/VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$Control/VBoxContainer/settings.pressed.connect(_on_settings_pressed)
	$Control/VBoxContainer/menu.pressed.connect(_on_menu_pressed)

func _on_resume_pressed() -> void:
	queue_free()
	get_tree().paused = false

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://src/Scenes/Settings.tscn")
	queue_free()
	get_tree().paused = false
	
func _on_menu_pressed() -> void:
	queue_free()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
