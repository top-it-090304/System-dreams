extends Area2D

const WIN_SCREEN_SCENE := preload("res://scenes/ui/win.tscn")

var _player: Node2D = null

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var anim_normal: String = "default"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if _sprite:
		_sprite.play(anim_normal)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		var final_time = body._run_time
		var final_level = body.level
		
		get_tree().paused = true
		
		var win_screen = WIN_SCREEN_SCENE.instantiate()
		
		get_tree().root.add_child(win_screen)
		
		if win_screen.has_method("init_stats"):
			win_screen.init_stats(final_time, final_level)
		
		queue_free()
