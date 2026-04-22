extends Node

const MENU_MUSIC_PATH := "res://audio/MainMenuLoop.mp3"
const GAMEPLAY_MUSIC_PATH := "res://audio/gameplayLoop.mp3"
const AUDIO_SETTINGS_PATH := "user://audio_settings.cfg"
const BUS_MASTER := "Master"
const BUS_ENEMIES_PRIMARY := "Enemies"
const BUS_ENEMIES_FALLBACK := "SFX"

var _player: AudioStreamPlayer
var _menu_stream: AudioStream
var _gameplay_stream: AudioStream

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.process_mode = PROCESS_MODE_ALWAYS
	_player.bus = "Master"
	_player.autoplay = false
	_player.finished.connect(_on_player_finished)
	add_child(_player)

	_menu_stream = load(MENU_MUSIC_PATH)
	_gameplay_stream = load(GAMEPLAY_MUSIC_PATH)
	apply_saved_audio_settings()

func play_menu_music() -> void:
	_play_looped(_menu_stream)

func play_gameplay_music() -> void:
	_play_looped(_gameplay_stream)

func set_music_volume_linear(value: float) -> void:
	var linear := clampf(value, 0.0, 1.0)
	_player.volume_db = linear_to_db(linear) if linear > 0.0 else -80.0

func apply_saved_audio_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(AUDIO_SETTINGS_PATH)

	var master_value := 1.0
	var enemies_value := 1.0
	var music_value := 1.0

	if err == OK:
		master_value = float(config.get_value("audio", "master", 1.0))
		enemies_value = float(config.get_value("audio", "enemies", 1.0))
		music_value = float(config.get_value("audio", "music", 1.0))

	_apply_bus_linear(BUS_MASTER, master_value)
	_apply_enemies_bus_linear(enemies_value)
	set_music_volume_linear(music_value)

func _play_looped(stream: AudioStream) -> void:
	if stream == null:
		return

	if _player.stream == stream and _player.playing:
		return

	_player.stop()
	_player.stream = stream
	_player.stream_paused = false
	_player.play()

func _on_player_finished() -> void:
	# MP3 may not have loop flag enabled in import settings, so loop explicitly.
	if _player.stream != null:
		_player.play()

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
