extends Node

# Singleton для доступа к шине событий из любого места
# Автоматически добавляется в сцену как autoload


static var _instance: EventBus = null


static func get_instance() -> EventBus:
	if _instance == null:
		# Пытаемся найти через autoload (если зарегистрирован)
		_instance = Engine.get_singleton("Bus") if Engine.has_singleton("Bus") else null
		
		# Если не нашли через Engine, пытаемся найти в сцене
		if _instance == null and Engine.get_main_loop():
			var root = Engine.get_main_loop().root
			for child in root.get_children():
				if child is EventBus:
					_instance = child
					break
	
	return _instance


static func subscribe(event_class: GDScript, function: Callable) -> void:
	var instance = get_instance()
	if instance:
		instance.subscribe(event_class, function)


static func unsubscribe(event_class: GDScript, function: Callable) -> void:
	var instance = get_instance()
	if instance:
		instance.unsubscribe(event_class, function)


static func create_event(event: IEvent) -> void:
	var instance = get_instance()
	if instance:
		instance.create_event(event)
