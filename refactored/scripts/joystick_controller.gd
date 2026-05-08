extends Node2D

@export var joystick_scene: PackedScene
@onready var joystick_instance: Node2D = $JoystickInstance

var _joystick_visible: bool = false

func _ready() -> void:
	# Скрываем джойстик при старте, если не выбран режим джойстика
	_update_joystick_visibility()
	
	# Подписываемся на изменения типа управления
	if ControlSettings:
		ControlSettings.control_type_changed.connect(_on_control_type_changed)

func _on_control_type_changed(new_type: int) -> void:
	_update_joystick_visibility()

func _update_joystick_visibility() -> void:
	if not joystick_instance:
		return
	
	if ControlSettings.is_joystick_enabled():
		joystick_instance.show()
		_joystick_visible = true
	else:
		joystick_instance.hide()
		_joystick_visible = false
