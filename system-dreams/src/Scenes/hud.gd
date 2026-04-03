extends CanvasLayer

class_name HUD

@onready var pause_button: Button = $Container/PauseButton   # прозрачная кнопка поверх текстуры
@onready var health_bar: TextureRect = $Container/HealthBar
@onready var level_label: Label = $Container/LevelLabel

var player: Player

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	player = get_tree().get_first_node_in_group("player")
	if not player:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("player")
	if player:
		_connect_signals()
	else:
		print("HUD: Player not found!")
	pause_button.pressed.connect(_on_pause_pressed)

func _connect_signals():
	player.health_updated.connect(_on_health_updated)
	player.level_updated.connect(_on_level_updated)
	_on_health_updated(player.health, player.max_health)
	_on_level_updated(player.level)

func _on_health_updated(new_health: int, new_max_health: int):
	var full_width = 60
	var new_width = max(0, int(full_width * new_health / float(new_max_health)))
	health_bar.region_enabled = true
	var tex_height = health_bar.texture.get_height()
	health_bar.region_rect = Rect2(0, 0, new_width, tex_height)

func _on_level_updated(new_level: int):
	level_label.text = "Level: " + str(new_level)

func _on_pause_pressed():
	get_tree().paused = !get_tree().paused
