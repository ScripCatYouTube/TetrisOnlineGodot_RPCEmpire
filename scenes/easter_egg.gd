extends Node2D

var inputed = false
@onready var player_figure = $Square

func _input(_event):
	if Input.is_action_just_pressed('ui_right'):
		if turn_on(): return
		player_figure.move_right()
	
	if Input.is_action_just_pressed('ui_left'):
		if turn_on(): return
		player_figure.move_left()
	
	if Input.is_action_just_pressed("ui_up"):
		if turn_on(): return
		player_figure.self_rotate()

	if Input.is_action_just_pressed("ui_down"):
		if turn_on(): return
		player_figure.move_down()


func turn_on():
	if inputed  == false:
		$Square.visible = true
		$Line.visible = true
		inputed = true
		return true
	
	return false
