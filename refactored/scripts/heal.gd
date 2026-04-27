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
	_find_player()

func _find_player() -> void:
	# Ищем именно узел Player (CharacterBody2D), а не его дочерние элементы в группе
	var all_players = get_tree().get_nodes_in_group("player")
	for node in all_players:
		if node is CharacterBody2D and node.has_method("heal"):
			_player = node
			print("HEAL: Player found: ", _player.name)
			return
	
	_player = null
	print("HEAL: Player not found in group 'player'")

func _physics_process(delta: float) -> void:
	if not magnet_enabled:
		return

	if not is_instance_valid(_player):
		_find_player()
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
		print("HEAL: Collected by player, healing ", heal_amount)
		body.heal(heal_amount)
		queue_free()
