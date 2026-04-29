extends CanvasLayer

class_name LevelUpMenu

signal option_chosen(option_id: String)

@onready var option_buttons := [
	$Control/VBoxContainer/Option1,
	$Control/VBoxContainer/Option2,
	$Control/VBoxContainer/Option3,
]

var _options_data := [
	{
		"id": "hp",
		"icon": preload("res://sprites/ui/hpUp.png")
	},
	{
		"id": "move",
		"icon": preload("res://sprites/ui/moveUp.png")
	},
	{
		"id": "shoot",
		"icon": preload("res://sprites/ui/shootUp.png")
	},
	{
		"id": "dmg",
		"icon": preload("res://sprites/ui/dmgUp.png")
	},
	{
		"id": "dvd",
		"icon": preload("res://sprites/ui/orbital.png")
	}
]


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 20 
	
	_randomize_and_apply_options()
	_prevent_misclick(0.3) # защита на 0.3 секунды


func _prevent_misclick(duration: float) -> void:
	for btn in option_buttons:
		btn.disabled = true
		
	await get_tree().create_timer(duration, true, false, true).timeout

	for btn in option_buttons:
		btn.disabled = false
		btn.modulate.a = 1.0


func _randomize_and_apply_options() -> void:
	var shuffled := _options_data.duplicate()
	shuffled.shuffle()
	
	for i in range(option_buttons.size()):
		var btn = option_buttons[i]
		var data = shuffled[i]
		
		if btn.has_node("Icon"):
			var icon_node = btn.get_node("Icon")
			if icon_node is TextureRect:
				icon_node.texture = data["icon"]
		
		# Очищаем старые связи, если они были, чтобы избежать дублирования
		if btn.pressed.is_connected(_on_option_pressed):
			btn.pressed.disconnect(_on_option_pressed)
			
		btn.pressed.connect(_on_option_pressed.bind(data["id"]))


func _on_option_pressed(option_id: String) -> void:
	option_chosen.emit(option_id)
	get_tree().paused = false 
	queue_free()
