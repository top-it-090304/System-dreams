extends CanvasLayer

const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
const AUDIO_SECTION := "audio"
const BUS_MASTER := "Master"
const BUS_ENEMIES_PRIMARY := "Enemies"
const BUS_ENEMIES_FALLBACK := "SFX"

@onready var _master_slider: HSlider = $Control/CenterContainer/VBoxContainer/HSlider2
@onready var _enemies_slider: HSlider = $Control/CenterContainer/VBoxContainer/HSlider
@onready var _music_slider: HSlider = $Control/CenterContainer/VBoxContainer/HSlider3
@onready var _joy_stick_check: CheckBox = $Control/CenterContainer/VBoxContainer/controll_options/joy_stick_option/Joy_stick_Check
@onready var _touch_check: CheckBox = $Control/CenterContainer/VBoxContainer/controll_options/touch_screen_option/Touch_Check

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	process_mode = PROCESS_MODE_ALWAYS 
	layer = 30
	MusicManager.play_menu_music()
	$Control/settings_back.pressed.connect(_on_settings_back_pressed)
	$Control/CenterContainer/VBoxContainer/reset_progress.pressed.connect(_on_reset_progress_pressed)
	_setup_sliders()
	_load_audio_settings_to_sliders()
	_apply_audio_settings_from_sliders()
	_connect_slider_signals()
	_setup_control_checkboxes()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_reset_progress_pressed() -> void:
	print("dklfk")
	_restore_music_after_close()
	queue_free()


func _on_settings_back_pressed() -> void:
	print("араро")
	_restore_music_after_close()
	queue_free()
	
	
	
func _restore_music_after_close() -> void:
	var current_scene := get_tree().current_scene
	if current_scene and current_scene.scene_file_path == "res://src/Scenes/main.tscn":
		MusicManager.play_gameplay_music()
	else:
		MusicManager.play_menu_music()


func _setup_sliders() -> void:
	for slider in [_master_slider, _enemies_slider, _music_slider]:
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01


func _load_audio_settings_to_sliders() -> void:
	var config := ConfigFile.new()
	var err := config.load(AUDIO_SETTINGS_PATH)

	var master_value := 1.0
	var enemies_value := 1.0
	var music_value := 1.0

	if err == OK:
		master_value = float(config.get_value(AUDIO_SECTION, "master", 1.0))
		enemies_value = float(config.get_value(AUDIO_SECTION, "enemies", 1.0))
		music_value = float(config.get_value(AUDIO_SECTION, "music", 1.0))

	_master_slider.value = clampf(master_value, 0.0, 1.0)
	_enemies_slider.value = clampf(enemies_value, 0.0, 1.0)
	_music_slider.value = clampf(music_value, 0.0, 1.0)


func _connect_slider_signals() -> void:
	_master_slider.value_changed.connect(_on_master_slider_changed)
	_enemies_slider.value_changed.connect(_on_enemies_slider_changed)
	_music_slider.value_changed.connect(_on_music_slider_changed)


func _on_master_slider_changed(value: float) -> void:
	_apply_master_volume(value)
	_save_audio_settings()


func _on_enemies_slider_changed(value: float) -> void:
	_apply_enemies_volume(value)
	_save_audio_settings()


func _on_music_slider_changed(value: float) -> void:
	MusicManager.set_music_volume_linear(value)
	_save_audio_settings()


func _apply_audio_settings_from_sliders() -> void:
	_apply_master_volume(_master_slider.value)
	_apply_enemies_volume(_enemies_slider.value)
	MusicManager.set_music_volume_linear(_music_slider.value)


func _apply_master_volume(value: float) -> void:
	_apply_bus_linear(BUS_MASTER, value)


func _apply_enemies_volume(value: float) -> void:
	if _has_bus(BUS_ENEMIES_PRIMARY):
		_apply_bus_linear(BUS_ENEMIES_PRIMARY, value)
	elif _has_bus(BUS_ENEMIES_FALLBACK):
		_apply_bus_linear(BUS_ENEMIES_FALLBACK, value)


func _apply_bus_linear(bus_name: String, value: float) -> void:
	if not _has_bus(bus_name):
		return

	var bus_idx := AudioServer.get_bus_index(bus_name)
	var linear := clampf(value, 0.0, 1.0)
	var db := linear_to_db(linear) if linear > 0.0 else -80.0
	AudioServer.set_bus_volume_db(bus_idx, db)


func _has_bus(bus_name: String) -> bool:
	return AudioServer.get_bus_index(bus_name) != -1


func _save_audio_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(AUDIO_SECTION, "master", _master_slider.value)
	config.set_value(AUDIO_SECTION, "enemies", _enemies_slider.value)
	config.set_value(AUDIO_SECTION, "music", _music_slider.value)
	config.save(AUDIO_SETTINGS_PATH)


func _on_h_slider_2_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_h_slider_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_h_slider_3_value_changed(value: float) -> void:
	pass # Replace with function body.


func _setup_control_checkboxes() -> void:
	# Подключаем сигналы от чекбоксов
	_joy_stick_check.toggled.connect(_on_joy_stick_check_toggled)
	_touch_check.toggled.connect(_on_touch_check_toggled)
	
	# Устанавливаем состояние чекбоксов в соответствии с сохраненными настройками
	_update_checkbox_states()
	
	# Подписываемся на изменения типа управления
	ControlSettings.control_type_changed.connect(_on_control_type_changed)


func _update_checkbox_states() -> void:
	# Обновляем состояние чекбоксов в зависимости от текущего типа управления
	if ControlSettings.is_joystick_enabled():
		_joy_stick_check.button_pressed = true
		_touch_check.button_pressed = false
	else:
		_joy_stick_check.button_pressed = false
		_touch_check.button_pressed = true


func _on_control_type_changed(new_type: int) -> void:
	# Обновляем UI при изменении типа управления из другого места
	_update_checkbox_states()


func _on_joy_stick_check_toggled(toggled_on: bool) -> void:
	if toggled_on:
		# Если включили джойстик, выключаем touch
		_touch_check.button_pressed = false
		ControlSettings.set_control_type(ControlSettings.ControlType.JOYSTICK)
	else:
		# Если выключили джойстик, включаем touch
		if not _touch_check.button_pressed:
			_touch_check.button_pressed = true


func _on_touch_check_toggled(toggled_on: bool) -> void:
	if toggled_on:
		# Если включили touch, выключаем джойстик
		_joy_stick_check.button_pressed = false
		ControlSettings.set_control_type(ControlSettings.ControlType.TOUCH)
	else:
		# Если выключили touch, включаем джойстик
		if not _joy_stick_check.button_pressed:
			_joy_stick_check.button_pressed = true
