extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS 
	layer = 30
	$Control/VBoxContainer/settings_back.pressed.connect(_on_settings_back_pressed)
	$Control/VBoxContainer/reset_progress.pressed.connect(_on_reset_progress_pressed)
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_reset_progress_pressed() -> void:
	queue_free()
	
	
	pass # Replace with function body.


func _on_settings_back_pressed() -> void:
	queue_free()
	
	
	
