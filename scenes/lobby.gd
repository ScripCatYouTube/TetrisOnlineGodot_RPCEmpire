extends Node2D

@onready var dialog = $back/dialog_back

var max_players = 2
var choosed_player 


func _ready():
	$back/nickname.text = Net.nickname
	
	var admin_name = null 
	if multiplayer.is_server():
		admin_name = Net.nickname
		
	
	if Net.nickname == null or Net.password == null:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	
	multiplayer.server_disconnected.connect(
		func():
			Net.kick_reason = 'Host disconnected'
			get_tree().change_scene_to_file("res://scenes/menu.tscn")
	)
	
	multiplayer.peer_connected.connect(
		func(new_peer):
			if 	Net.players.size() >= max_players:
				print('disconected ' + str(new_peer))
				Net.kick(new_peer, 'Maxium players in server')
	)
	
	multiplayer.peer_disconnected.connect(
		func (old_peer):
				for peer in Net.players:
					if peer == old_peer:
						var nickname = Net.players[peer]['nickname']
						rpc('remove_user', nickname)
						delete_player(nickname)
	)
	
	rpc('get_info', Net.nickname, Net.password)
	
	$count_players/server.visible = multiplayer.is_server()
	$count_players/server/count.text = str(max_players)
	$count_players/server/HSlider.value = max_players
	
	if multiplayer.is_server():
		$start_buttons/ready.visible = false 
	
	else:
		$start_buttons/start.visible = false
	
	await get_tree().create_timer(0.5).timeout
	
	add_previously_connected_players({'admin': admin_name, 'players': Net.get_players_names()})
		
	

func _on_back_button_up():
	dialog.visible = true


func _on_confirmation_dialog_canceled():
	dialog.visible = false


func _on_confirmation_dialog_confirmed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

@rpc
func add_newly_connected_player(nickname, peer_id):
	add_player(nickname, peer_id)

@rpc
func add_previously_connected_players(names):
	print('Peers: ' + str(names))
	if names['admin'] != null: add_player(names['admin'], true)
	
	for _name in names['players']:
		add_player(_name)

@rpc 
func add_new_message(text, user):
	add_message(text, user)


@rpc 
func remove_user(nickname):
	delete_player(nickname)
	

@rpc 
func change_ready(nickname):
	trigger_ready(nickname)
	

@rpc
func press_start():
	get_local_names()
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://scenes/game.tscn")	
	

func trigger_ready(nickname):
	var ii = 1
	for i in $list_players.get_children():
		if i.text == nickname:
			
			if $players_status.get_node(str(ii)).visible == true:
				$players_status.get_node(str(ii)).visible = false
				$players_status.get_node('a' + str(ii)).visible = true
				
			else:
				$players_status.get_node(str(ii)).visible = true
				$players_status.get_node(str(ii)).texture = load('res://assets/ui/buttons/menu/ready.png')
				$players_status.get_node('a' + str(ii)).visible = false
			
			
		ii += 1	

func add_player(nickname, is_admin = false):
	#print('get value: ' + str(Net.players.get(peer_id)) + ' peer: ' + str(peer_id))
	for i in $list_players.get_children():
		if i.text == nickname: return
		
	
	#Net.players[peer_id] = {'nickname': nickname}
	
	var name_peer = str(nickname)
	var ii = 0
	for i in $list_players.get_children():
		if i.text == '':
			i.text = name_peer
			i.visible = true
			
		
			
			if is_admin == false: 
				if multiplayer.get_unique_id() == 1: $access_players.get_children()[ii].visible = true
				
				$players_status.get_node(str(ii + 1)).visible = false
				$players_status.get_node('a' + str(ii + 1)).visible = true
				
			else:
				$players_status.get_node(str(ii + 1)).texture = load("res://assets/ui/buttons/menu/admin.png")
				
				$players_status.get_node(str(ii + 1)).visible = true
				$players_status.get_node('a' + str(ii + 1)).visible = false
				
			return
			
		ii += 1
 
	multiplayer.multiplayer_peer.close()


func add_message(text, user):
	var label = Label.new()
	label.text = user + ': ' + text
	
	label.visible_characters = 40
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(472, 25)
	
	$chat/ScrollContainer/VBoxContainer.add_child(label)


func _on_input_text_submitted(new_text):
	$chat/input.text = ''
	if multiplayer.is_server(): rpc('server_chat_from_user', new_text)
	else: rpc('chat_from_user', new_text)
	
	#rpc('get_info', Net.nickname, Net.password)
	print('texted')


func _on_h_slider_drag_ended(_value_changed):
	if multiplayer.is_server():
		rpc('change_max_players', $count_players/server/HSlider.value)


func delete_player(nickname):
	Net.remove_player(nickname)
		
	var ii = 1
	for i in $list_players.get_children():
		if i.text == nickname:
			i.text = ''
			i.visible = false	
			$access_players.get_children()[ii - 1].visible = false
			$players_status.get_node(str(ii)).visible = false
			$players_status.get_node('a' + str(ii)).visible = false
		
		ii += 1


@rpc("any_peer", "call_remote", 'reliable')
func get_info(nickname, password):
	if nickname in Net.banned_plaeyrs or nickname in Net.get_players_names():
		Net.kick(multiplayer.get_remote_sender_id(), 'You are banned or another reason')
	
	
	Net.players[multiplayer.get_remote_sender_id()] = {'nickname': nickname}
	
	print('Is server: ' + str(multiplayer.is_server()) + ' nickname: ' + nickname + ' password: ' + password + ' id: ' + str(multiplayer.get_remote_sender_id()) + ' master id: ' + str(multiplayer.get_unique_id()))
	
	var text_send = {'admin': Net.nickname, 'players': Net.get_players_names()}
	
	add_previously_connected_players(text_send)
	rpc('add_previously_connected_players', text_send)


@rpc("authority", "call_local", 'reliable')
func remove_player(nickname):
	rpc('remove_user', nickname)


@rpc("any_peer", "call_local", 'reliable')
func chat_from_user(text):
	print(text)
	print(1)
	if len(text) > 256: return
	
	print('dict: ' + str(Net.players) + ' ID: ' + str(multiplayer.get_remote_sender_id()))
	var user = Net.players[multiplayer.get_remote_sender_id()]['nickname']
	
	print('server get \'' + text + '\' from user ' + user)
	add_message(text, user)
	rpc('add_new_message', text, user)


@rpc("authority", "call_local", 'reliable')
func server_chat_from_user(text):
	print(text)
	print(1)
	if len(text) > 256: return
	
	print('dict: ' + str(Net.players) + ' ID: ' + str(multiplayer.get_remote_sender_id()))
	var user = Net.players[multiplayer.get_remote_sender_id()]['nickname']
	
	print('server get \'' + text + '\' from user ' + user)
	add_message(text, user)
	rpc('add_new_message', text, user)	


@rpc("authority", 'reliable')
func change_max_players(count):
	max_players = count
	$count_players/server/count.text = str(count)


@rpc("any_peer", "call_remote", 'reliable')
func pressed_ready(): 
	var nickname = Net.players[multiplayer.get_remote_sender_id()]['nickname']
	
	rpc('change_ready', nickname)
	trigger_ready(nickname)


@rpc("authority", "call_local", 'reliable')
func pressed_start():
	get_local_names()
	rpc('press_start')
	
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	

func _on_access_buttons_pressed(_name, id):
	var nickname = $'list_players'.get_children()[id]
	var access = $'access_players'.get_children()[id]
	choosed_player = null
	
	if nickname.text == '' and access.visible == true:
		access.visible = false
		return
		
	elif nickname.text != '' and access.visible == false:
		access.visible = true
		return	
	
	choosed_player = nickname.text
	
	if name == 'kick':
		$back/kick.dialog_text = 'Do you want to kick \'' + choosed_player + '\'?'
		$back/kick.visible = true
	
	elif name == 'ban':
		$back/ban.dialog_text = 'Do you want to ban \'' + choosed_player + '\'?\nThis player will never be able to join your server.'
		$back/ban.visible = true
		
	elif name == 'set_owner':
		$back/set_owner.dialog_text = 'Do you want to ban \'' + choosed_player + '\'?\nThis player will never be able to join your server.'
		$back/set_owner.visible = true



func _on_kick_canceled():
	$back/kick.visible = false


func _on_kick_confirmed():
	for i in Net.players:
		if Net.players[i]['nickname'] == choosed_player:
			Net.kick(i, 'By ' + Net.nickname)
	
	$back/kick.visible = false


func _on_ban_canceled():
	$back/ban.visible = false


func _on_ban_confirmed():
	if choosed_player != null:
		for i in Net.players:
			if Net.players[i]['nickname'] == choosed_player:
				
				# BAN
				Net.banned_plaeyrs.append(choosed_player)
				Net.kick(i, 'You\'re banned by ' + Net.nickname)
	
		choosed_player = null 
		
	$back/kick.visible = false


func _on_set_owner_canceled():
	$back/set_owner.visible = false


func _on_set_owner_confirmed():
	for i in Net.players:
		if Net.players[i]['nickname'] == choosed_player:
			# set owner
			pass
	
	$back/set_owner.visible = false


func _on_ready_pressed():
	rpc('pressed_ready')
	
	await get_tree().create_timer(1).timeout
	get_local_names()
	
	var ii = 1
	for i in $list_players.get_children():
		if i.text == Net.nickname:
			if $players_status.get_node('a' + str(ii)).visible == false:
				$start_buttons/ready.text = 'READY'
			
			else:
				$start_buttons/ready.text = 'CANCEL'
				
				
		ii += 1


func _on_start_pressed():
	var ii = 1

	if len(Net.players) == 1:
		$back/one_player.visible = true
		$start_buttons/start.disabled = true
		return
	
	for i in $list_players.get_children():
		if $players_status.get_node('a' + str(ii)).visible == true:
			$start_buttons/not_all_ready.visible = true
			$start_buttons/start.disabled = true
			return
		
		ii += 1
	
	rpc('pressed_start')


func _on_not_all_ready_confirmed():
	$start_buttons/start.disabled = false
	$start_buttons/not_all_ready.visible = false
	rpc('pressed_start')


func _on_not_all_ready_canceled():
	$start_buttons/not_all_ready.visible = false
	$start_buttons/start.disabled = false


func _on_one_player_confirmed():
	print('one player')
	rpc('pressed_start')


func _on_one_player_canceled():
	$back/one_player.visible = false
	$start_buttons/start.disabled = false


func get_local_names():
	for i in $list_players.get_children():
		if i.text != '':
			Net.local_names.append(i.text)
	
	
