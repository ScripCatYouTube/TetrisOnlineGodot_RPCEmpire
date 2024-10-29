extends Label

@export_category('Label Event')
#@export var start_position: Vector2 = Vector2(0,0) 
@export var end_position: Vector2 = Vector2(0,0)
@export var time_move: float = 0.4

var start_position
var time
var is_started = false

func _ready():
	#test()
	pass
	
func test():
	text = 'Hello!'
	position = Vector2(500, 500)
	end_position = Vector2(500, 0)
	
	start()
	

func _physics_process(_delta):
	if is_started:
		time += _delta * time_move
		modulate.a = 1 - time
		position = start_position.lerp(end_position, time)		
		
		#if time >= 1:
		#	is_started = false


func start():
	start_position = position
	var time_per_step = abs(end_position - start_position) / time_move
	time = 0
	is_started = true

