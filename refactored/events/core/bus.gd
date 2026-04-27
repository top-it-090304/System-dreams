extends Node
class_name EventBus

var subscribers = {}


func subscribe(event_class: GDScript, function: Callable) -> void:
	var event_type = _get_event_type(event_class)
	
	if not subscribers.has(event_type):
		subscribers[event_type] = []
	
	# Проверка на дубликаты
	if not subscribers[event_type].has(function):
		subscribers[event_type].append(function)


func unsubscribe(event_class: GDScript, function: Callable) -> void:
	var event_type = _get_event_type(event_class)
	
	if subscribers.has(event_type):
		var index = subscribers[event_type].find(function)
		if index != -1:
			subscribers[event_type].remove_at(index)
		
		# Очищаем пустые массивы
		if subscribers[event_type].is_empty():
			subscribers.erase(event_type)


func create_event(event: IEvent) -> void:
	var event_type = _get_event_type(event.get_script())
	
	if not subscribers.has(event_type):
		return
	
	# Копируем массив чтобы избежать проблем при модификации во время итерации
	var event_subscribers = subscribers[event_type].duplicate()
	
	for function in event_subscribers:
		if is_instance_valid(function.get_object()):
			function.call_deferred(event)
		else:
			# Авто-отписка от невалидных объектов
			unsubscribe_by_function(event_type, function)


func unsubscribe_by_function(event_type: String, function: Callable) -> void:
	if subscribers.has(event_type):
		var index = subscribers[event_type].find(function)
		if index != -1:
			subscribers[event_type].remove_at(index)


func _get_event_type(event_class: GDScript) -> String:
	if event_class == null:
		return ""
	return event_class.get_global_name()


func get_subscriber_count(event_class: GDScript) -> int:
	var event_type = _get_event_type(event_class)
	return subscribers.get(event_type, []).size()


func clear_all() -> void:
	subscribers.clear()
