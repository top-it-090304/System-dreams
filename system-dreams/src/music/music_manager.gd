extends Node

const MENU_MUSIC_PATH := "res://src/music/MainMenuLoop.mp3"
const GAMEPLAY_MUSIC_PATH := "res://src/music/gameplayLoop.mp3"

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

func play_menu_music() -> void:
	_play_looped(_menu_stream)

func play_gameplay_music() -> void:
	_play_looped(_gameplay_stream)

func set_music_volume_linear(value: float) -> void:
	var linear := clampf(value, 0.0, 1.0)
	_player.volume_db = linear_to_db(linear) if linear > 0.0 else -80.0

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
