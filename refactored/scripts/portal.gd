extends Area2D

var _player: Node2D = null

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var anim_normal: String = "default"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if _sprite:
		_sprite.play(anim_normal)
	
	
func _on_body_entered(body: Node) -> void:
	if body is Player:
		queue_free()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
