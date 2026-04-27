extends Node2D

@export  
var event_name: String

func _ready() -> void:
	Bus.subscribe(TestEvent, test_call)


func test_call(event: TestEvent) -> void:
	print("value is " + str(event.value))
