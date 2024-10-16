extends Node2D


@onready var dialog_window = $back_menu/back_dialog


func _ready():
	print('users: ' + str(Net.get_players_names()))
	print(Net.local_names)
	
	if multiplayer.is_server():
		load_players(Net.get_players_names())
	
	else:
		load_players(Net.local_names)
	
	multiplayer.server_disconnected.connect(
		func():
			Net.kick_reason = 'Host disconnected'
			get_tree().change_scene_to_file("res://scenes/menu.tscn")
	)
	
	multiplayer.peer_disconnected.connect(
		func (old_peer):
				for peer in Net.players:
					if peer == old_peer:
						var nickname = Net.players[peer]['nickname']
						rpc('remove_user', nickname)
						delete_player(nickname)
	)
	
	multiplayer.peer_connected.connect(
		func(new_peer):
			Net.kick(new_peer, 'The game is started and you can\'t to join.')
	)

func load_players(players):
	for player in players:
		for i in $players.get_children():
			if i.text == player:
				break
			
			if i.text == '':
				i.text = player
				break


func delete_player(nickname):
	Net.remove_player(nickname)
		
	var ii = 1
	for i in $players.get_children():
		if i.text == nickname:
			i.text = ''

		ii += 1


func show_dialog_exit():
	dialog_window.visible = true
	$back_menu/back.disabled = true


func count_players():
	var players = 0
	for i in $players.get_children():
		if i.text != '':
			players += 1
	
	return players

func _on_back_button_down():
	var amount_players = count_players()
	#print('amount pl: ', str(amount_players))
	
	if multiplayer.is_server():
		if amount_players == 1:
			dialog_window.dialog_text = 'Do you want to leave?\n\nYes! Let\'s go to touch grass and find friends!'
			show_dialog_exit()
			
		else:
			dialog_window.dialog_text = 'Do you want to leave?\n\nThe game will be ended. \nDo you want break life\'s your friends (or someones, idk)?'
			show_dialog_exit()
	
	else:
		if amount_players == 2:
			dialog_window.dialog_text = 'Do you want to leave?\n\nWhy you leaving? Don\'t leave your friend!'
			show_dialog_exit()
			
		else:
			dialog_window.dialog_text = 'Do you want to leave?\n\nYou\'re leaving the party.'
			show_dialog_exit()
	
	


func _on_back_dialog_confirmed():
	$back_menu/back.disabled = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_back_dialog_canceled():
	$back_menu/back.disabled = false
	

@rpc 
func remove_user(nickname):
	delete_player(nickname)
	
@rpc("authority", "call_local", 'reliable')
func fall_down_figures():
	for i in $figures.get_children():
		i.move_down()

@rpc('authority', 'call_local', 'reliable')
func update_position_figures():
	pass
