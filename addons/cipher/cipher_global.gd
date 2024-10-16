class_name Cipher extends Node

var key
var aes = AESContext.new()

func _init(string_key = 'some_key'):
	update_key(string_key)


func enscrypt(text: String):
	aes.start(AESContext.MODE_ECB_ENCRYPT, key)
	var bytes = text.to_utf8_buffer()
	#var enscrypted = aes.update(text)


func descrypt(text: String):
	pass


func format_key(key: String = 'VerySecretKey'):
	var byte_key = key
	if typeof(key) == 4:
		byte_key = key.to_utf8_buffer()
		
	byte_key.resize(64)
	return byte_key	
	

func update_key(key_string: String):
	key = format_key(key_string)
		

func get_count_nul_bytes(lenght: int, max_c: int = 16):
	return abs(lenght - (ceil(lenght / max_c) * max_c))


func resize(byte_array: PackedByteArray):
	
	for i in ceil(32 / byte_array.size()):
		print(byte_array.slice(i * 32, (i + 1) * 32))

