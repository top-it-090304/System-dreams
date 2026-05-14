extends TextureButton

var settings_menu_instance: Node = null 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	pass
	
	
func _on_pressed() -> void:
	var pause_scene = load("res://scenes/ui/settings.tscn")

	settings_menu_instance = pause_scene.instantiate()
	get_tree().root.add_child(settings_menu_instance)


func _hide_settings_menu():
	if settings_menu_instance:
		settings_menu_instance.queue_free()
		settings_menu_instance = null
	
