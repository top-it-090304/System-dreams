extends Area2D

var damage: float = 0

func _process(_delta):
	$Sprite2D.global_rotation = 0

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
