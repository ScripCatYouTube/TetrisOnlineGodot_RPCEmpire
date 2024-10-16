extends Node2D

signal pressed(name, id)

@export var ID = 0

func _on_kick_pressed():
	emit_signal("pressed", 'kick', ID)


func _on_ban_pressed():
	emit_signal("pressed", 'ban', ID)


func _on_set_owner_pressed():
	emit_signal("pressed", 'set_owner', ID)
