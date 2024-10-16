@tool
extends EditorPlugin


func _enter_tree():
	print('Hello World!')
	add_autoload_singleton('PluginCipher', "res://addons/cipher/cipher_global.gd")


func _exit_tree():
	print('Bye')
	remove_autoload_singleton('PluginCipher')
