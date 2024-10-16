extends CharacterBody2D

@export var texture = "res://assets/ui/buttons/menu/cell/base.png"
var speed = 32
var is_rotate = true

var first_pos 

func _ready():
	load_textures(texture)
	velocity = Vector2()


func _process(_delta):
	if is_loaded(texture) == false:
		load_textures(texture)
		
	if rotation_degrees != 0:
		if (int(abs(rotation_degrees)) % 90 == (int(abs(rotation_degrees) / 90) - int(abs(rotation_degrees) / 90))) == false:
			print('bye, ' + name)
			queue_free()
			
			#print(int(rad_to_deg(abs(self.rotation))), ' ', int(rad_to_deg(self.rotation)) % 90, ' ', int(rad_to_deg(self.rotation)) / 90)
			#self.rotation = deg_to_rad(0)
#func _integrate_forces(state):
#	var xform = state.get_transform().rotated(deg_to_rad(45))
#	state.set_transform(xform)(


func load_textures(texture):
	var loaded_texture = load(texture)
	for i in get_children():
		if i.get_class() == 'RigidBody2D':
			i.get_node('sprite').texture = loaded_texture


func is_loaded(texture):
	var loaded_texture = load(texture)
	for i in get_children():
		if i.get_class() == 'RigidBody2D':
			if i.get_node('sprite').texture != loaded_texture:
				return false
				
	return true

func move():
	first_pos = position
	
	velocity = velocity.normalized() * speed
	move_and_collide(velocity)
	velocity = Vector2()
	
	
	
	print(is_touch_floor())
	

func move_right():
	velocity.x += 1
	move()
	
func move_left():
	velocity.x -= 1	
	move()

func move_up():
	velocity.y -= 1
	move()
	
func move_down():
	velocity.y += 1
	move()


func self_rotate():
	if is_rotate:
		if rotation_degrees >= 360:
			rotation_degrees = 0
			return 
		
		rotation_degrees += 90


func _on_area_2d_body_entered(body):
	if body in get_children() or body == self:
		return

	is_rotate = false
	
	
func _on_area_2d_body_exited(body):
	if body in get_children() or body == self:
		return

	is_rotate = true


func is_touch_floor():
	if abs(position - first_pos) < Vector2(0, 32):
		return true
	return false
