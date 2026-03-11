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
		"icon": preload("res://dropUi/hpUp.png")
	},
	{
		"id": "move",
		"icon": preload("res://dropUi/moveUp.png")
	},
	{
		"id": "shoot",
		"icon": preload("res://dropUi/shootUp.png")
	},
	{
		"id": "dmg",
		"icon": preload("res://dropUi/dmgUp.png")
	},
]


func _ready() -> void:
	#process_mode, 2 == PROCESS_MODE_WHEN_PAUSED
	process_mode = 2
	_randomize_and_apply_options()


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
		
		# Подключаем сигнал нажатия к обработчику, передавая id опции
		if not btn.pressed.is_connected(_on_option_pressed):
			btn.pressed.connect(_on_option_pressed.bind(data["id"]))


func _on_option_pressed(option_id: String) -> void:
	option_chosen.emit(option_id)
	queue_free()
