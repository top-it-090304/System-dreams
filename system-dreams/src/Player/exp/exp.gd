extends Area2D

@export var xp_amount: int = 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.add_xp(xp_amount)
		queue_free()
