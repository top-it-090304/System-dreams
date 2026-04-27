class_name EnemyBullet
extends Area2D

# Типы пуль врага - теперь это фигуры тетриса
enum BulletType {
	NORMAL,     # I-фигура (палка) - длинная узкая коллизия, средняя скорость, средний урон
	FAST,       # O-фигура (квадрат) - квадратная коллизия, высокая скорость, маленький урон, пробивает
	HEAVY,      # T-фигура - треугольная форма коллизии, низкая скорость, высокий урон
	L_SHAPE,    # L-фигура - угловая коллизия, средняя скорость, средний урон, небольшой отскок
	Z_SHAPE     # Z-фигура - зигзаг коллизия, вращается при полете, средний урон
}

@export var bullet_type: BulletType = BulletType.NORMAL
@export var damage: int = 10
@export var speed: float = 600.0
@export var lifetime: float = 5.0
@export var pierce_count: int = 0  # Сколько целей может пробить пуля (0 = не пробивает)
@export var rotation_speed: float = 0.0  # Скорость вращения для некоторых типов пуль

var direction: Vector2 = Vector2.ZERO
var _lifetime_timer: float = 0.0
var player: Node2D = null
var _hit_targets: Array = []  # Для отслеживания уже пораженных целей (для пробивающих пуль)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var normal_sprite: Texture2D
@export var fast_sprite: Texture2D
@export var heavy_sprite: Texture2D
@export var l_shape_sprite: Texture2D
@export var z_shape_sprite: Texture2D

func _ready() -> void:
	_lifetime_timer = lifetime
	player = get_tree().get_first_node_in_group("player")
	
	# Устанавливаем спрайт и коллизию в зависимости от типа пули
	_set_bullet_sprite()
	_set_collision_shape()
	
	# Настраиваем параметры в зависимости от типа
	match bullet_type:
		BulletType.NORMAL:
			speed = 600.0
			damage = 15
			pierce_count = 0
			rotation_speed = 0.0
		BulletType.FAST:
			speed = 950.0
			damage = 5
			pierce_count = 1
			rotation_speed = 0.0
		BulletType.HEAVY:
			speed = 400.0
			damage = 30
			pierce_count = 0
			rotation_speed = 0.0
		BulletType.L_SHAPE:
			speed = 700.0
			damage = 12
			pierce_count = 0
			rotation_speed = 0.0
		BulletType.Z_SHAPE:
			speed = 650.0
			damage = 18
			pierce_count = 0
			rotation_speed = 360.0  # Вращается при полете

func _set_bullet_sprite() -> void:
	if not sprite:
		return
	
	match bullet_type:
		BulletType.NORMAL:
			if normal_sprite:
				sprite.texture = normal_sprite
		BulletType.FAST:
			if fast_sprite:
				sprite.texture = fast_sprite
		BulletType.HEAVY:
			if heavy_sprite:
				sprite.texture = heavy_sprite
		BulletType.L_SHAPE:
			if l_shape_sprite:
				sprite.texture = l_shape_sprite
		BulletType.Z_SHAPE:
			if z_shape_sprite:
				sprite.texture = z_shape_sprite

func _set_collision_shape() -> void:
	if not collision_shape:
		return
	
	match bullet_type:
		BulletType.NORMAL:
			# I-фигура: длинный узкий прямоугольник
			var rect_shape = RectangleShape2D.new()
			rect_shape.size = Vector2(60, 8)  # Длинная и узкая
			collision_shape.shape = rect_shape
			collision_shape.rotation = 0.0
			
		BulletType.FAST:
			# O-фигура: квадрат
			var rect_shape = RectangleShape2D.new()
			rect_shape.size = Vector2(20, 20)  # Квадрат
			collision_shape.shape = rect_shape
			collision_shape.rotation = 0.0

		BulletType.HEAVY:
			# T-фигура: используем комбинацию или больший прямоугольник с поворотом
			var rect_shape = RectangleShape2D.new()
			rect_shape.size = Vector2(35, 25)  # Более массивная
			collision_shape.shape = rect_shape
			collision_shape.rotation = 0.0

		BulletType.L_SHAPE:
			# L-фигура: прямоугольник с смещением
			var rect_shape = RectangleShape2D.new()
			rect_shape.size = Vector2(30, 15)
			collision_shape.shape = rect_shape
			collision_shape.position = Vector2(10, 5)  # Смещение для L-формы
			collision_shape.rotation = 0.0
			
		BulletType.Z_SHAPE:
			# Z-фигура: прямоугольник под углом
			var rect_shape = RectangleShape2D.new()
			rect_shape.size = Vector2(40, 12)
			collision_shape.shape = rect_shape
			collision_shape.rotation = deg_to_rad(45)  # Начальный угол

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	
	_lifetime_timer -= delta
	if _lifetime_timer <= 0.0:
		queue_free()
		return
	
	# Движение пули
	position += direction * speed * delta
	
	# Вращение для Z-фигуры и других вращающихся пуль
	if rotation_speed != 0.0:
		rotation += deg_to_rad(rotation_speed * delta)

func _on_body_entered(body: Node2D) -> void:
	# Проверяем, не поражали ли мы уже эту цель (для пробивающих пуль)
	if _hit_targets.has(body):
		return
	
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, direction)
		
		# Если пуля пробивающая, добавляем цель в список пораженных
		if pierce_count > 0:
			_hit_targets.append(body)
			pierce_count -= 1
			# Визуальный эффект попадания (можно добавить позже)
		else:
			queue_free()
	elif body.is_in_group("enemy") or body.is_in_group("obstacle"):
		# Пуля исчезает при попадании в препятствие или другого врага
		if pierce_count <= 0:
			queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
