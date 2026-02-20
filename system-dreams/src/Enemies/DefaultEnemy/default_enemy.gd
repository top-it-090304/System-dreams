extends CharacterBody2D

@export var speed: float = 20
@export var health: int = 100

var player: Node2D = null

func _ready():
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		
		move_and_slide()

func take_damage(amount: int):
	health -= amount
	
	if health <= 0:
		die()

func die():
	queue_free()
