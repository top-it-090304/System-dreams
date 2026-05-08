extends Node

## Путь к файлу настроек управления
const CONTROL_SETTINGS_PATH := "user://control_settings.cfg"
const CONTROL_SECTION := "control"
const CONTROL_TYPE_KEY := "control_type"

## Типы управления
enum ControlType {
	TOUCH,    # Управление нажатием на экран
	JOYSTICK  # Управление джойстиком
}

## Текущий тип управления
var current_control_type: ControlType = ControlType.TOUCH

signal control_type_changed(new_type: ControlType)

func _ready() -> void:
	_load_control_settings()

## Установить тип управления
func set_control_type(type: ControlType) -> void:
	if current_control_type == type:
		return
	
	current_control_type = type
	_save_control_settings()
	control_type_changed.emit(type)
	print("Control type changed to: ", ControlType.keys()[type])

## Получить текущий тип управления
func get_control_type() -> ControlType:
	return current_control_type

## Проверка, используется ли джойстик
func is_joystick_enabled() -> bool:
	return current_control_type == ControlType.JOYSTICK

## Проверка, используется ли touch управление
func is_touch_enabled() -> bool:
	return current_control_type == ControlType.TOUCH

## Сохранить настройки
func _save_control_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(CONTROL_SECTION, CONTROL_TYPE_KEY, int(current_control_type))
	var err := config.save(CONTROL_SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save control settings: %s" % err)

## Загрузить настройки
func _load_control_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONTROL_SETTINGS_PATH)
	
	if err == OK:
		var saved_type: int = config.get_value(CONTROL_SECTION, CONTROL_TYPE_KEY, int(ControlType.TOUCH))
		current_control_type = saved_type as ControlType
	else:
		# По умолчанию ставим TOUCH при первом запуске
		current_control_type = ControlType.TOUCH
		_save_control_settings()
	
	print("Loaded control type: ", ControlType.keys()[current_control_type])
