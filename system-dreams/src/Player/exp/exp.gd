extends Area2D

@export var xp_amount: int = 1
@export var magnet_enabled: bool = true
@export var magnet_range: float = 140.0
@export var magnet_speed: float = 320.0
# Чтобы быстрее гарантировать pickup при очень близком расстоянии.
@export var magnet_snap_distance: float = 10.0

var _player: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not magnet_enabled:
		return

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("Player")
		if not _player:
			return

	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()

	# Пока игрок далеко — XP остаётся на месте.
	if dist > magnet_range:
		return

	# Двигаем XP к игроку, чтобы `body_entered` сработал автоматически.
	if dist <= magnet_snap_distance:
		global_position = _player.global_position
	else:
		var dir := to_player / dist
		global_position += dir * magnet_speed * delta


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.add_xp(xp_amount)
		queue_free()
