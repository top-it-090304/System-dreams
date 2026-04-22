extends Area2D

@export var heal_amount: int = 30

# Если игрок близко — дроп притягивается к нему, чтобы подбор был “магнитным”.
@export var magnet_enabled: bool = true
@export var magnet_range: float = 200.0
@export var magnet_speed: float = 320.0
@export var magnet_snap_distance: float = 10.0

var _player: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if not magnet_enabled:
		return

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if not _player:
			return

	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()

	if dist > magnet_range:
		return

	if dist <= magnet_snap_distance:
		global_position = _player.global_position
	else:
		var dir := to_player / dist
		global_position += dir * magnet_speed * delta


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.heal(heal_amount)
		queue_free()
