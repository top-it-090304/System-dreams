extends CanvasLayer

class_name HUD

@onready var pause_button: Button = $Container/PauseButton  
@onready var level_label: Label = $Container/LevelLabel
@onready var health_bar: TextureProgressBar = $Container/HealthBar


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
	print("HUD: _connect_signals called, player = ", player)
	if player:
		player.health_updated.connect(_on_health_updated)
		player.level_updated.connect(_on_level_updated)
		_on_health_updated(player.health, player.max_health)
		_on_level_updated(player.level)
	else:
		print("HUD: player is null, cannot connect")
		
func _on_health_updated(new_health: int, new_max_health: int):
	health_bar.max_value = new_max_health
	health_bar.value = new_health
	
func _on_level_updated(new_level: int):
	print("HUD: _on_level_updated -> ", new_level)
	level_label.text = str(new_level)
	
func _on_pause_pressed():
	get_tree().paused = !get_tree().paused
	print("Paused: ", get_tree().paused)
