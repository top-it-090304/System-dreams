extends Area2D

@export var xp_amount: int = 1

func _ready() -> void:
	# Подписываемся на сигнал, когда кто-то входит в зону опыта
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	# Опыт подбирает только игрок
	if body is Player:
		body.add_xp(xp_amount)
		queue_free()

