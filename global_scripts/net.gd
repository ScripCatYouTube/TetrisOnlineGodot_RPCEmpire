extends Node

var players = {} # id: {'nickname': 'Name', 'password': 'Password'}
var local_names = []
var banned_plaeyrs = []
var nickname 
var password 
var kick_reason


func get_players_names():
	var names_players = []
	for i in players:
		names_players.append(players[i]['nickname'])
	
	return names_players


func remove_player(_nickname: String):
	for i in Net.players:
		if Net.players[i]['nickname'] == _nickname:
			Net.players.erase(i)


func kick(peer: int, reason: String = 'Reason'):
	if multiplayer.is_server():
		print(2)
		rpc_id(peer, 'self_kick', reason)
	
		await _kick(peer)

func _kick(peer):
	await get_tree().create_timer(0.1).timeout
	multiplayer.multiplayer_peer.disconnect_peer(peer)	


@rpc
func self_kick(reason):
	kick_reason = reason
	print(1)
