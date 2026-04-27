class_name RPSResultWindow
extends CanvasLayer

# Окно результата мини-игры "Камень-Ножницы-Бумага"
# Показывает результат (победа/поражение/ничья) после анимации

signal result_confirmed  # Сигнал нажатия кнопки OK

@onready var _result_label: Label = $Control/VBoxContainer/ResultLabel
@onready var _ok_button: Button = $Control/VBoxContainer/OKButton

var _current_result: String = ""

func _ready() -> void:
	process_mode = PROCESS_MODE_WHEN_PAUSED
	layer = 30
	visible = false
	
	if _ok_button:
		_ok_button.pressed.connect(_on_ok_pressed)

func show_result(result_text: String) -> void:
	_current_result = result_text
	if _result_label:
		_result_label.text = result_text
	visible = true

func _on_ok_pressed() -> void:
	visible = false
	result_confirmed.emit()
