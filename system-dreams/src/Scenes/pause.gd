extends CanvasLayer

class_name Pause

var settings_menu_instance: Node = null 

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED  
	layer = 20
	
	$Control/VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$Control/VBoxContainer/settings.pressed.connect(_on_settings_pressed)
	$Control/VBoxContainer/menu.pressed.connect(_on_menu_pressed)

func _on_resume_pressed() -> void:
	queue_free()
	get_tree().paused = false

func _on_settings_pressed() -> void:
	if settings_menu_instance == null:
		_show_settings_menu()
	else:
		_hide_settings_menu()
		
func _show_settings_menu():
	var pause_scene = load("res://src/Scenes/Settings.tscn")  
	if pause_scene == null:
		print("Ошибка: не удалось загрузить сцену настроек! Проверьте путь.")
		return
		
		
	settings_menu_instance = pause_scene.instantiate()
	get_tree().root.add_child(settings_menu_instance)
	get_tree().paused = true


func _hide_settings_menu():
	if settings_menu_instance:
		settings_menu_instance.queue_free()
		settings_menu_instance = null
		
		
func _on_menu_pressed() -> void:
	queue_free()
	get_tree().paused = false
	MusicManager.play_menu_music()
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
