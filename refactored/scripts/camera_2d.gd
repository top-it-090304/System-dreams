extends Camera2D

@export var target: CharacterBody2D
@export var deadzone_size: Vector2 = Vector2(180, 120)  # Маленькая зона
@export var follow_speed: float = 12.0  # Быстрая реакция

var deadzone_rect: Rect2

func _ready():
	if not target:
		target = get_tree().get_first_node_in_group("player")

func _process(delta):
	if target:
		update_deadzone()
		move_camera(delta)

func update_deadzone():
	deadzone_rect = Rect2(
		global_position - deadzone_size / 2,
		deadzone_size
	)

func move_camera(delta):
	var target_pos = target.global_position
	
	if not deadzone_rect.has_point(target_pos):
		var new_pos = global_position
		
		if target_pos.x < deadzone_rect.position.x:
			new_pos.x = target_pos.x + deadzone_size.x / 2
		elif target_pos.x > deadzone_rect.end.x:
			new_pos.x = target_pos.x - deadzone_size.x / 2
		
		if target_pos.y < deadzone_rect.position.y:
			new_pos.y = target_pos.y + deadzone_size.y / 2
		elif target_pos.y > deadzone_rect.end.y:
			new_pos.y = target_pos.y - deadzone_size.y / 2
		
		global_position = global_position.lerp(new_pos, follow_speed * delta)
