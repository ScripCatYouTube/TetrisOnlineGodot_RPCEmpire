extends Node

#var crypto_path = '-----BEGIN RSA PRIVATE KEY-----\n' + str(str(Time.get_date_dict_from_system()['year']) + OS.get_name() + OS.get_unique_id()).sha256_text().repeat(16) + '\n' + '-----END RSA PRIVATE KEY-----' 
var crypto = Crypto.new()
var key = CryptoKey.new()


#func _ready():
#	pass


func enscrypt(data: String):
	return crypto.encrypt(key, data.to_utf8_buffer()).get_string_from_utf8()

func descrypt(data: String):
	return crypto.decrypt(key, data.to_utf8_buffer()).get_string_from_utf8()


