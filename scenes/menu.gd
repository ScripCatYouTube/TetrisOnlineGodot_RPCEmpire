extends Node2D

var DEFAULT_IP = '127.0.0.1'
var PORT = 8901
var MAX_CONNECTIONS = 16

var password = null
var file_account = 'res://dont_send_me_nobody.json'

var peer = ENetMultiplayerPeer.new()


@onready var error_label = $server/error
@onready var input_ip = $server/address_server

@onready var name_input = $account/name
@onready var password_input = $account/password

@onready var join_button = $server/join
@onready var create_button = $server/create
@onready var show_password_button = $account/show


func _ready():
	multiplayer.multiplayer_peer = null
	Net.players = {}
	is_kick_reason()
	#var byte_array = PackedByteArray([0,2,3,4,5])
	#print(_resize(byte_array))
	
	defualt_file()
	var json_text = ManageFile.read_json(file_account)
	password = json_text['password']
	password_input.text = json_text['password']
	
	if password != '':
		block_password(true)
	
	
	#print('readed json: ' + str(json_text))
	
	
	name_input.text = json_text['name']
	input_ip.text = json_text['address']
	
	if name_input.text == '' or password == '':
		set_buttons(true)
		return
	
	set_buttons(false)
	
	Net.nickname = null 
	Net.password = null
	
	"""var args = Array(OS.get_cmdline_args())
	if args.has("-s") or args.has('-server'):
		print("starting server...")"""


"""func _resize(byte_array: PackedByteArray):
	print(byte_array.size() )
	print(ceil(32 / byte_array.size()))
	
	for i in ceil(32 / byte_array.size()):
		print(byte_array.slice(i * 32, (i + 1) * 32))"""


func update_connection():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

"""func _on_address_server_text_changed(new_text):
	if new_text == '':
		$join.disabled = true
	
	else:
		$join.disabled = false"""


func _on_join_button_down():
	multiplayer.multiplayer_peer = null
	set_error_text()
	
	var address = input_ip.text
	var port = PORT
	
	if address == '':
		address = DEFAULT_IP

	else:
		var splitted_address = address.split(':')
		if len(splitted_address) == 2:
			address = splitted_address[0]
			port = int(splitted_address[1])
	
	set_error_text('Connecting to ' + address + ':' + str(port))
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	
	if error:
		set_error_text('Error Code: ' + str(error))
		return
		
	
	multiplayer.multiplayer_peer = peer
	update_connection()

	print('joined')
	
	
func _on_create_button_down():
	multiplayer.multiplayer_peer = null
	set_error_text()

	var port = input_ip.text
	
	if port == '':
		port = PORT
		
	else:
		port = int(port)
	
	set_error_text('Hosted ' + DEFAULT_IP + ':' + str(port))
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_CONNECTIONS)
	
	if error:
		set_error_text('Error Code: ' + str(error))
		return
	
	multiplayer.multiplayer_peer = peer
	update_connection()
	
	print('created')
	
	Net.nickname = name_input.text 	
	Net.password = password
	Net.players[multiplayer.get_unique_id()] = {'nickname': Net.nickname}
	
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_connected_ok():
	set_error_text('Successful connected to server')
	
	Net.nickname = name_input.text 	
	Net.password = password
	
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
	

func _on_connected_fail():
	set_error_text('Failed to connect server')
	multiplayer.multiplayer_peer = null
	
	
func _on_server_disconnected():
	set_error_text('Disconnect')
	multiplayer.multiplayer_peer = null


func _on_player_connected(id):
	print('Player ' + str(id) + ' joined')
	
	
func _on_player_disconnected(id):
	print('Player ' + str(id) + ' disconnected')


func set_error_text(text = ''):
	if text == '':
		error_label.text = ''
		error_label.visible = false
		return 
	
	error_label.text = text
	error_label.visible = true
	

func _on_show_pressed():
	if password_input.secret == true:
		password_input.secret = false
	
	else:
		password_input.secret = true


func _on_block_pressed():
	block_password()




func _on_name_text_changed(new_text):
	defualt_file()
	ManageFile.rewrite_json('name', new_text, file_account)
	
	if new_text == '' or password == '':
		set_buttons(true)
		return
	
	set_buttons()


func _on_password_text_changed(new_text):
	defualt_file()
	ManageFile.rewrite_json('password', new_text, file_account)
	
	password = new_text
	
	if new_text == '' or name_input.text == '':
		set_buttons(true)
		return
	
	set_buttons()


func set_buttons(value = false):
	join_button.disabled = value
	create_button.disabled = value


func defualt_file():
	ManageFile.json_defualt_write({'name': '', 'address': '', 'password': ''}, file_account)


func _on_address_server_text_changed(new_text):
	defualt_file()
	ManageFile.rewrite_json('address', new_text, file_account)


func block_password(is_block = null):
	if is_block == null:
			if password_input.flat == false:
				_block_password()
				return
			
			_unblock_password()
	
	elif is_block:
			_block_password()
			return
	
	_unblock_password()


func _block_password():
	password_input.flat = true
	password_input.add_theme_color_override("font_color", Color(1, 0.5, 0, 0))
	password_input.add_theme_font_size_override("font_size", 29)
	password_input.editable = false
	password = password_input.text
	password_input.text = ''
	password_input.placeholder_text = 'BLOCK for unblock'
	show_password_button.disabled = true


func _unblock_password():
	password_input.flat = false
	password_input.remove_theme_color_override("font_color")
	password_input.add_theme_font_size_override("font_size", 33)
	password_input.editable = true
	password_input.text = password	
	password_input.placeholder_text = 'Password'
	password_input.secret = true
	show_password_button.disabled = false
	
	
func is_kick_reason():
	if Net.kick_reason != null:
		$kick.visible = true
		$kick.dialog_text = Net.kick_reason
		Net.kick_reason = null


func _on_kick_confirmed():
	$kick.visible = false


func _on_kick_canceled():
	$kick.visible = false
