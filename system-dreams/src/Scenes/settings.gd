extends CanvasLayer

const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
const BUS_MASTER := "Master"
const BUS_ENEMIES_PRIMARY := "Enemies"
const BUS_ENEMIES_FALLBACK := "SFX"

@onready var _master_slider: HSlider = $Control/VBoxContainer/HSlider2
@onready var _enemies_slider: HSlider = $Control/VBoxContainer/HSlider
@onready var _music_slider: HSlider = $Control/VBoxContainer/HSlider3

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 30
	_restore_music_for_context()
	_setup_sliders()
	_load_audio_settings()

	$Control/VBoxContainer/settings_back.pressed.connect(_on_settings_back_pressed)
	$Control/VBoxContainer/reset_progress.pressed.connect(_on_reset_progress_pressed)

func _process(_delta: float) -> void:
	pass

func _setup_sliders() -> void:
	for slider in [_master_slider, _enemies_slider, _music_slider]:
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01

	_master_slider.value_changed.connect(_on_master_volume_changed)
	_enemies_slider.value_changed.connect(_on_enemies_volume_changed)
	_music_slider.value_changed.connect(_on_music_volume_changed)

func _load_audio_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(AUDIO_SETTINGS_PATH)

	var master_value := 1.0
	var enemies_value := 1.0
	var music_value := 1.0

	if err == OK:
		master_value = float(config.get_value("audio", "master", 1.0))
		enemies_value = float(config.get_value("audio", "enemies", 1.0))
		music_value = float(config.get_value("audio", "music", 1.0))

	_master_slider.set_value_no_signal(clampf(master_value, 0.0, 1.0))
	_enemies_slider.set_value_no_signal(clampf(enemies_value, 0.0, 1.0))
	_music_slider.set_value_no_signal(clampf(music_value, 0.0, 1.0))

	_apply_all_audio_values()

func _apply_all_audio_values() -> void:
	_apply_bus_linear(BUS_MASTER, _master_slider.value)
	_apply_enemies_bus_linear(_enemies_slider.value)
	MusicManager.set_music_volume_linear(_music_slider.value)

func _on_master_volume_changed(value: float) -> void:
	_apply_bus_linear(BUS_MASTER, value)
	_save_audio_settings()

func _on_enemies_volume_changed(value: float) -> void:
	_apply_enemies_bus_linear(value)
	_save_audio_settings()

func _on_music_volume_changed(value: float) -> void:
	MusicManager.set_music_volume_linear(value)
	_save_audio_settings()

func _apply_enemies_bus_linear(value: float) -> void:
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
	config.set_value("audio", "master", _master_slider.value)
	config.set_value("audio", "enemies", _enemies_slider.value)
	config.set_value("audio", "music", _music_slider.value)
	config.save(AUDIO_SETTINGS_PATH)

func _on_reset_progress_pressed() -> void:
	_restore_music_for_context()
	queue_free()

func _on_settings_back_pressed() -> void:
	_restore_music_for_context()
	queue_free()

func _restore_music_for_context() -> void:
	var current_scene := get_tree().current_scene
	if current_scene and current_scene.scene_file_path == "res://src/Scenes/main.tscn":
		MusicManager.play_gameplay_music()
	else:
		MusicManager.play_menu_music()
