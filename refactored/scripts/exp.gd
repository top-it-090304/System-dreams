extends Area2D

@export var xp_amount: int = 1
@export var magnet_enabled: bool = true
@export var magnet_range: float = 200.0
@export var magnet_speed: float = 320.0
# Чтобы быстрее гарантировать pickup при очень близком расстоянии.
@export var magnet_snap_distance: float = 10.0

var _player: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_find_player()

func _find_player() -> void:
	# Ищем именно узел Player (CharacterBody2D), а не его дочерние элементы в группе
	var all_players = get_tree().get_nodes_in_group("player")
	for node in all_players:
		if node is CharacterBody2D and node.has_method("add_xp"):
			_player = node
			print("EXP: Player found: ", _player.name)
			return
	
	_player = null
	print("EXP: Player not found in group 'player'")

func _physics_process(delta: float) -> void:
	if not magnet_enabled:
		return

	if not is_instance_valid(_player):
		_find_player()
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
		print("EXP: Collected by player, adding ", xp_amount, " XP")
		body.add_xp(xp_amount)
		queue_free()
