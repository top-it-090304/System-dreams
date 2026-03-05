extends CharacterBody2D

@export var speed: float = 20
@export var health: int = 100
@export var exp_scene: PackedScene
@export var normal_texture: Texture2D
@export var hurt_texture: Texture2D
@export var hurt_time: float = 0.1

var player: Node2D = null
var _hurt_timer: float = 0.0
@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

	if _sprite and normal_texture:
		_sprite.texture = normal_texture


func _physics_process(_delta: float) -> void:
	if player:
		var direction := (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	
	if _hurt_timer > 0.0:
		_hurt_timer -= _delta
		if _hurt_timer <= 0.0 and _sprite and normal_texture:
			_sprite.texture = normal_texture


func take_damage(amount: int) -> void:
	health -= amount
	
	if _sprite and hurt_texture:
		_sprite.texture = hurt_texture
		_hurt_timer = hurt_time
	
	if health <= 0:
		die()


func die() -> void:
	if exp_scene:
		var exp = exp_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)
	
	queue_free()
