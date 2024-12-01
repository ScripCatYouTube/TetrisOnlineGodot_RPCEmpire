extends Node2D

# RPC calling functions(Map.gd)
#
# 'update_cell', tile, pos (tile - -1: clear, another: team_color)
# 'clear_line', percents_teams, y
#   (percents_teams - dictionary of teams and theirs 
#   contribution in cleared line, if team not have anyone figure in cleared line, 
#   then don't included in dictionary
#   y - y axis position)
# 'team_loose', team

var teams = {} # name: [team, is_free_timer]
var cooldown_response_keys = 0.05

@onready var dialog_window = $back_menu/back_dialog
@onready var map = $figures/Map

var rng = RandomNumberGenerator.new()

func _ready():
	rng.seed = 3450543958210
	rng.randomize()
	
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
	
	load_teams()
	load_figures()


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
			
		else:
			dialog_window.dialog_text = 'Do you want to leave?\n\nThe game will be ended. \nDo you want break life\'s your friends (or someones, idk)?'
	
	else:
		if amount_players == 2:
			dialog_window.dialog_text = 'Do you want to leave?\n\nWhy you leaving? Don\'t leave your friend!'
			
		else:
			dialog_window.dialog_text = 'Do you want to leave?\n\nYou\'re leaving the party.'

	show_dialog_exit()	
	

func _input(event):
	if Input.is_action_just_pressed('ui_up'): rpc('cw_rotate')
	if Input.is_action_pressed('ui_down'): rpc('move_down')
	if Input.is_action_pressed('ui_right'): rpc('move_right')
	if Input.is_action_pressed('ui_left'): rpc('move_left')


func get_team(id_sender):
	#print(Net.players)
	
	if Net.players.has(id_sender):
		var nickname = Net.players[id_sender]['nickname']
		var id_team = teams[nickname][0]
		if id_team == null:
			return
		
		return [id_team, nickname]


func _on_back_dialog_confirmed():
	$back_menu/back.disabled = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_back_dialog_canceled():
	$back_menu/back.disabled = false




func print_event(text: String):
	var node = load("res://scenes/LabelEvent.tscn").instance()
	node.text = text
	node.position = $events/pos.position
	
	$events.add_child(node)
	node.start()


func get_random_team_number():
	rng.randomize()
	return rng.randi_range(0, map.teams.size() - 2)


func get_random_color():
	var rnum = get_random_team_number()
	if rnum not in teams.keys():
		return rnum
		
	return max(teams.keys())

	
func load_teams():
	print("1 Teams loaded: ", teams)
	
	for i in Net.players:
		var nickname = Net.players[i]["nickname"]
		if nickname not in teams.keys():
			var random_color = get_random_color()
			
			teams[nickname] = [random_color, true]
			
	print("2 Teams loaded: ", teams)


func load_figure(team: int):
	print('Preload figure. Team\'s ', team)
	map.add_object(
		map.get_random_figure(), 
		map.local_to_map(get_node("positions_figures/" + str(team)).position), 
		team
	)	
	
	await get_tree().create_timer(2).timeout
	
	#map.is_loose(team)


func load_figures():
	for i in teams:
		load_figure(teams[i][0])


@rpc
func team_loose(team: int):
	var nickname_loosed = get_team(team)[1]
	
	print_event(nickname_loosed + ' Loose!')
	teams.erase(nickname_loosed)


@rpc 
func remove_user(nickname):
	delete_player(nickname)
	
	
@rpc("call_local", "any_peer", "reliable")
func cw_rotate():
	movement(multiplayer.get_remote_sender_id(), "rotate_cw")

@rpc("call_local", "any_peer", "reliable")
func move_down():
	movement(multiplayer.get_remote_sender_id(), "m_down")


@rpc("call_local", "any_peer", "reliable")
func move_right():
	movement(multiplayer.get_remote_sender_id(), "m_right")
	

@rpc("call_local", "any_peer", "reliable")
func move_left():
	movement(multiplayer.get_remote_sender_id(), "m_left")


func movement(sender_id: int, function_move: String):
	var team_sender = get_team(sender_id)
	
	if team_sender != null:
		var team_nickname = team_sender[1]
		
		if teams[team_nickname][1] == false:
			#print('Team, ' + str(team_sender) + ', stop spamming right!')
			return
		
		teams[team_nickname][1] = false
		var callable = Callable(self, function_move)
		callable.call(team_sender[0])
		
		await get_tree().create_timer(cooldown_response_keys).timeout
		
		teams[team_nickname][1] = true
	
	
func rotate_cw(team: int):
	map.cw_rotate(team)

func m_right(team: int):
	map.m_right(team)
	
func m_left(team: int):
	map.m_left(team)
	
func m_down(team: int):
	map.m_down(team)

@rpc#('any_peer', 'call_local')
func update_cell(tile, pos):
	if typeof(tile) == 2:
		map.erase_cell(0, pos)
	else:
		map.set_cell(0, pos, 1, tile)

@rpc('call_local')
func after_update_add_object(team):
	load_figure(team)

@rpc('call_local')
func clear_line(percents_teams, y): pass
