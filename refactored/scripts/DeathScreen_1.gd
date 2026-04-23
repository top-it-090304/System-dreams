extends CanvasLayer

class_name DeathScreen

signal restart_requested
signal menu_requested

@onready var restart_btn: Button = $Control/CenterContainer/VBoxContainer/GameOver/RestartButton
@onready var menu_btn: Button = $Control/CenterContainer/VBoxContainer/GameOver/MenuButton

@onready var time_label: Label = $Control/CenterContainer/VBoxContainer/Records/TimeLabel
@onready var level_label: Label = $Control/CenterContainer/VBoxContainer/Records/LevelLabel
@onready var max_level_label: Label = $Control/CenterContainer/VBoxContainer/Records/MaxLevelLabel
var session_time: float = 0.0
var final_level: int = 1
var max_level_ever: int = 1

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	layer = 20
	
	max_level_ever = _load_max_level()
	
	
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)
	

func init_stats(time: float, level: int) -> void:
	print("init_stats called with time=", time, " level=", level)
	session_time = time
	final_level = level
	
	if final_level > max_level_ever:
		max_level_ever = final_level
		save_max_level(max_level_ever)

	_update_stats_ui()

func _update_stats_ui() -> void:
	print("Updating UI: time_label=", time_label, " level_label=", level_label, " max_label=", max_level_label)
	if time_label:
		var minutes = int(session_time) / 60
		var seconds = int(session_time) % 60
		var new_text = " Время: %02d:%02d" % [minutes, seconds]
		print("Setting time text to: ", new_text)
		time_label.text = new_text
	
	if level_label:
		level_label.text = " Уровень: %d" % final_level
		print("Level label updated: ", level_label.text)  
	
	if max_level_label:
		max_level_label.text = " Рекорд: %d" % max_level_ever
		print("Max level label updated: ", max_level_label.text)  


func _load_max_level() -> int:
	var config = ConfigFile.new()
	var err = config.load("user://savegame.dat")
	if err == OK:
		return config.get_value("stats", "max_level", 1)
	return 1


func save_max_level(new_level: int) -> void:
	var config = ConfigFile.new()
	config.load("user://savegame.dat")
	config.set_value("stats", "max_level", new_level)
	config.save("user://savegame.dat")


func _on_restart_pressed() -> void:
	restart_requested.emit()
	queue_free()


func _on_menu_pressed() -> void:
	menu_requested.emit()
	queue_free()


func _on_restart_button_pressed() -> void:
	pass # Replace with function body.


func _on_menu_button_pressed() -> void:
	pass # Replace with function body.
