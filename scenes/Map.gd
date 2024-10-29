extends TileMap

# RPC calling functions
#
# 'update_cell', tile, pos (tile = -1: clear or tile != -1 set tile, another: team_color)
# 'clear_line', percents_teams, y
#   (percents_teams - dictionary of teams and theirs 
#   contribution in cleared line, if team not have anyone figure in cleared line, 
#   then don't included in dictionary
#   y - y axis position)
# 'team_loose', team
# 'after_update_add_object', team
#



var types = ['square', 'triangle', 'gamma', 'gamma_reversed', 'line']
var teams = {'red': 0, 'blue': 1, 'yellow': 2, 'green': 3, 'pink': 4, 'base': 5}
var colors = [Vector2i(0,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2)]
var back_colors = [Vector2i(2, 0), Vector2i(2, 1), Vector2i(3, 0), Vector2i(3, 1), Vector2i(2, 2), Vector2i(3,2)]

var figures = {
	'square': [Vector2(0, 0), Vector2(0,1), Vector2(1,0), Vector2(1,1)],
	'gamma': [Vector2(1,0), Vector2(0,0), Vector2(0,1), Vector2(2,0)],
	'gamma_reversed': [Vector2(0,0), Vector2(1,0), Vector2(2,0), Vector2(2, 1)],
	'triangle': [Vector2(1,0), Vector2(0,0), Vector2(2,0), Vector2(1, 1)],
	'line': [Vector2(0, 0), Vector2(0,1), Vector2(0,2), Vector2(0,3)]
}

var rects = {
	'square': 
		{
			'up': [Vector2(0, -1), Vector2(1, -1)], 
			'left': [Vector2(-1, 0), Vector2(-1, 1)], 
			'right': [Vector2(2, 0), Vector2(2, 1)], 
			'down': [Vector2(0, 2), Vector2(1,2)]
		},
		
	'gamma': 
		{
			'up': [Vector2(0, -1), Vector2(1, -1), Vector2(2, -1)],
			'left': [Vector2(-1, 0), Vector2(-1, 1)],
			'right': [Vector2(3, 0), Vector2(1, 1)],
			'down': [Vector2(0, 2), Vector2(1, 1), Vector2(2, 1)]	
		},
		
	'gamma_reversed':
		{
			'up': [Vector2(0, -1), Vector2(1, -1), Vector2(2, -1)],
			'left': [Vector2(-1, 0), Vector2(1, 1)],
			'right': [Vector2(3, 0), Vector2(3, 1)],
			'down': [Vector2(0, 1), Vector2(2, 2), Vector2(1, 1)]
		},
		
	'triangle':
		{
			'up': [Vector2(0, -1), Vector2(1, -1), Vector2(2, -1)],#[Vector2(0, -1), Vector2(1, -1), Vector2(2, -1)],
			'left': [Vector2(-1,0), Vector2(0, 1)],
			'right': [Vector2(3, 0), Vector2(2, 1)],
			'down': [Vector2(0, 1), Vector2(1, 2), Vector2(2, 1)]
		},

	'line':
		{
			'up': [Vector2(0, -1)],
			'left': [Vector2(-1, 0), Vector2(-1, 1), Vector2(-1, 2), Vector2(-1, 3)],
			'right': [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(1, 3)],
			'down': [Vector2(0, 4)]
		},
}


var markers = {} # team: [rotate, type, position]
var old_markers = {} # {team: {position: [type, rotate]}}

@export_category("Tests")
@export var is_main = false
@export var is_test_one_object = false
@export var is_test = false
@export var is_rpc_test = false


func _ready():
	if is_rpc_test: rpc_test()
	if is_main or is_test_one_object: $Timer.start(1)
	# test function for testing functions :)
	# WARNING: don't use for release
	if is_test: test()
	if is_test_one_object: add_object(get_random_figure(), Vector2(1,1), 2)
	#await get_tree().create_timer(1).timeout
	#all_move_down()

func test():
	var escape = 0
	var team = 0
	for figure in figures: # cycle for add all figures from list 'figures'
		#print(figure)
		add_object(figure, Vector2(escape + 5, 5), team) # add figure with distance 5 cells(but the size of figure isn't considered)
		rect_draw(team)
		escape += 6
		team += 1
	return
	await get_tree().create_timer(0.5).timeout # timer for 500ms, half of second
	
	"""
	team = 0
	for i in figures: # create collisions lines under all figures for detect a floor
		line_down(team)
		team += 1
		await get_tree().create_timer(0.5).timeout
 	
	await get_tree().create_timer(0.5).timeout
	"""
	
	move(3, Vector2(0, 4)) # moving down the fourth figure for 4 cells 
	#line_down(3) # create a collision line under fourth figure for detect a floor

	for i in range(9): # cycle for rotating the fifth figure 9 times 
		await get_tree().create_timer(0.5).timeout
		
		cw_rotate(4) # rotating the fourth figure clockwise +90 degrees
		# each calling method 'cw_rotate' rotate for 90 degrees but if figure have 360 degrees(that equal 0) replace in the code on 0
		# because the method '_rotate' working with only values 90, 180, 270 and sees other values ​​as 0

func rpc_test():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(8989, 1)

	if error:
		print('RPC_Test Error: ' + error_string(error) + ' ID error: ' + str(error))
		return
		
	
	multiplayer.multiplayer_peer = peer


func _process(delta):
	if is_main or is_test_one_object: clear_lines()

func update_physics():
	await get_tree().create_timer(1).timeout
	all_move_down()


func _on_timer_timeout():
	all_move_down()



func draw(type, pos, team, degrees = 0):
	var r = __rotate(type, degrees)
	for i in r:
		cell(pos + i, team)


func _clear(type, pos, team, degrees):
	for i in __rotate(type, degrees):
		ccell(pos + i)


func update(team, next_pos = null, next_degrees = null):
	var pos = markers[team][2]
	var degrees = markers[team][0]
	
	if next_pos != null:
		pos = next_pos
	if next_degrees != null:
		degrees = next_degrees
	
	var figure = markers[team][1]
		
	_clear(figure, markers[team][2], team, markers[team][0])
	draw(figure, pos, team, degrees)
	
	markers[team] = [degrees, figure, pos]


func move(team: int, direction: Vector2):
	#clear_layer(1)
	#clear_layer(2)
	if markers.has(team):
		var collide = rect_check_collide(team, direction, markers[team][0])
		#print(get_vector_side(direction), direction, collide)
		#print('Collides move ', collide[0], ' ', collide[1],  ' ', get_rotated_sides(markers[team][0])[1])
		if collide['down'] == true:
			update_object(team)
			return
		
		if collide[get_vector_side(direction)] == true:
			return
		#check_under_line(team)
		
		update(team, markers[team][2] + direction, null)
		#rect_draw(team)
		
		
		if collide['down'] == true:
			#print(2)
			update_object(team)
			return


func m_down(team: int):
	move(team, Vector2(0, 1))

func m_up(team: int):
	move(team, Vector2(0, -1))

func m_right(team: int):
	move(team, Vector2(1, 0))

func m_left(team: int):
	move(team, Vector2(-1, 0))


func move_down(pos: Vector2, is_was_moved):
	var p = pos
	p.y += 1
	var cell = get_cell_atlas_coords(0, pos)
	
	var marker = marker_cells(pos)
	if marker[0]:
		if marker[1] not in is_was_moved:
			move(marker[1], Vector2(0,1))
			is_was_moved.append(marker[1])
		return
	
	
	if get_cell_atlas_coords(0, p) == Vector2i(-1, -1) and cell != colors[teams['base']]:
		ccell(pos)
		_cell(p, cell)


func moves_down(y, max_x, is_was_moved):
	#print()
	for i in range(0, max_x + 1):
		#print(i, ' ', y)
		move_down(Vector2(i, y), is_was_moved)


func all_move_down(max_vector: Vector2 = Vector2(34, 20)):
	var is_was_moved = []
	
	for i in range(0, max_vector.y + 1):
		moves_down(max_vector.y - i, max_vector.x, is_was_moved)

	

func marker_cells(vector: Vector2):
	for i in markers:
		for vec in __rotate(markers[i][1], markers[i][0]):
			if vector == markers[i][2] + vec:
				return [true, i]
	return [false, -1]


func cw_rotate(team: int):
	#clear_layer(1)
	if is_collide_matrix(rect_check_collide(team, Vector2(-1, -1), markers[team][0] + 90)): 
		return
	
	#print('cw ', markers[team][0])
	update(team, null, markers[team][0] + 90)
	#markers[team][0] += 90
	
	if markers[team][0] >= 360:
		markers[team][0] = 0
		
	#rect_draw(team)	


func get_rotated_sides(degrees: int):
	var side = ['up', 'down', 'right', 'left']
	if degrees == 90:
		side = ['left', 'right', 'up', 'down']
		
	elif degrees == 180: 
		side = ['down', 'up', 'left', 'right']
	
	elif degrees == 270:
		side = ['right', 'left', 'down', 'up']
	
	return side


func rotate_side(side: String, degrees: int):
	var sides = ['up', 'down', 'right', 'left']
	var index = sides.find(side)
	
	#print('ri: ', index, ' ', side)
	
	if index != -1:
		return get_rotated_sides(degrees)[index]


func rotate_rect_sides(matrix: Dictionary, degrees: int):
	var new_matrix = {}
	var sides = get_rotated_sides(degrees)
	var num_side = 0 
	
	#print('\n\n', degrees)
	for i in matrix:
		#print(i, ' ', sides[num_side])
		new_matrix[sides[num_side]] = matrix[i]
		num_side += 1
		
	return new_matrix
	


func add_object(type: String, pos: Vector2, team: int):
	#print(type, ' ', pos, ' ', team)
	markers[team] = [0, type, pos]
	draw(type, pos, team)	


func _rotate(matrix: Array, degrees: int): # rotation clockwise
	var new_matrix = []
	
	for i in matrix:
		var cords = i
		if degrees == 90:
			cords.x = i.y
			cords.y = -i.x
		
		elif degrees == 180:
			cords = -i
		
		elif degrees == 270:
			cords.x = -i.y
			cords.y = i.x
		
		new_matrix.append(cords)
	
	return new_matrix

func __rotate(type, degrees):
	#return _rotate(matrix, degrees)
	
	var matrix = type
	if typeof(matrix) == 4:
		matrix = figures[type]
	
	elif degrees == 0 or degrees == -90:
		return matrix

	
	return _rotate(matrix, degrees)


func rotate_rect(matrix_rect, degrees):
	#print(degrees)
	var new_matrix_rect = {}
	var rotated_sides = get_rotated_sides(degrees)
	var sides = ['up', 'down', 'right', 'left']
	
	#print(rotated_sides)
	var ii = 0
	for i in sides:
		#print(i, ' ', ii, ' ', rotated_sides[ii])
		new_matrix_rect[rotated_sides[ii]] = __rotate(matrix_rect[i], degrees)
		ii += 1
	#var rotated_sides = rotate_rect_sides(matrix_rect, degrees)
	#for side in rotated_sides:
	#	print(side,' ',rotate_side(side, degrees))
	#	new_matrix_rect[side] = __rotate(matrix_rect[side], degrees)
	
	#print(new_matrix_rect)
	return new_matrix_rect
	

func _cell(pos, tile):
	if typeof(tile) == 2:
		erase_cell(0, pos)
	else:
		set_cell(0, pos, 1, tile)
		
	if multiplayer.multiplayer_peer.get_class() == 'ENetMultiplayerPeer' and multiplayer.is_server():
		get_parent().get_parent().rpc('update_cell', tile, pos)
		#get_parent().get_parent().rpc('u')

func cell(pos, team):
	_cell(pos, colors[team])

func ccell(pos):
	_cell(pos, -1)


func is_collide(team: int, pos: Vector2, degrees: int):
	var figure = __rotate(markers[team][1], degrees)
	var original_figure = __rotate(markers[team][1], markers[team][0])
	#print(degrees, ' ', markers[team][0])
	
	return _is_collide(pos, figure, markers[team][2], original_figure)


func _is_collide(pos: Vector2, matrix: PackedVector2Array, original_pos: Vector2, original_matrix: PackedVector2Array):
	var ii = 0
	#print(matrix, ' ', original_matrix)
	#print(pos, ' ', original_pos)
	for i in matrix:
		var cell = get_cell_atlas_coords(0, i + pos)
		#print(original_matrix[ii] + original_pos, ' ', i+pos, ' ', cell != Vector2i(-1, -1))
		if cell != Vector2i(-1, -1) and original_matrix[ii] + original_pos == i + pos: 
			pass
			#set_cell(2, i + pos, 1, Vector2i(1,1))
			#return true
		#if cell != Vector2i(-1, -1):
		#	set_cell(2, i + pos, 1, Vector2i(1,1))
		#	#if i + pos == back_matrix[ii] + pos:
		#	return true
			
		ii += 1
	
	return false 	


func __is_collide(x: Array, y: Array):
	for i in x:
		if y.has(i): return true
	return false
	


func is_collide_down_line(team: int):
	var sizex = size_x(markers[team][1], markers[team][0])
	var sizey = size_y(markers[team][1], markers[team][0])
	
	#print(sizex, ' x:y ', sizey)
	
	for x in range(sizex[0]):
		var position_cell = math_line_down(markers[team][2], sizey[0], x, markers[team][0], sizex[1])
		#set_cell(1, position_cell, 1, Vector2i(1,2))
		
		if get_cell_atlas_coords(0,position_cell) != Vector2i(-1, -1):
			return true 
	
	return false 


func size_x(figure: String, degrees: int):
	var x_axis = []
	var min_value = 0
	for i in __rotate(figure, degrees):
		if i.x not in x_axis:
			x_axis.append(i.x)
			
			if i.x < min_value:
				min_value = i.x
				
	
	return [len(x_axis), min_value]


func size_y(figure: String, degrees: int):
	var y_axis = []
	var min_value = 0
	for i in __rotate(figure, degrees):
		if i.y not in y_axis:
			y_axis.append(i.y)

			if i.y > min_value:
				min_value = i.y
				
	
	return [len(y_axis), min_value]


func math_line_down(pos: Vector2, sizey: int, count_x: int, deggress: int = 0, minx: int = 0):
	#var 
	#print('minx: ', minx)
	return Vector2((pos.x + count_x - 1), pos.y + sizey)


func _draw_line_down(pos: Vector2, sizex: int, sizey: int, tile: Vector2 = Vector2i(2,2), is_erase: bool = false): 
	for x in range(sizex):
		var position_cell = math_line_down(pos, sizey, x)
		
		if is_erase == false:
			_cell(position_cell, tile)
			
		else:
			ccell(position_cell)


func line_down(team: int):
	var sizex = size_x(markers[team][1], markers[team][0])
	var sizey = size_y(markers[team][1], markers[team][0])
	
	_draw_line_down(markers[team][2], sizex, sizey, colors[5], true)
	_draw_line_down(markers[team][2], sizex, sizey, colors[5], false)


func rect_draw(team: int):
	var rect = rotate_rect(rects[markers[team][1]], markers[team][0])
	for i in rect:
		var tile = back_colors[0]
		
		if i == 'up':
			tile = back_colors[0]
		elif i == 'down':
			tile = back_colors[1]
		elif i == 'right':
			tile = back_colors[2]
		elif i == 'left':
			tile = back_colors[3]
		
		for cell in rect[i]:
			set_cell(1, markers[team][2] + cell, 1, tile)


func func_cell_rotate_not_in(cell, sides, is_rotate, atlas_coords, team_color):
	if team_color != -1:
		return colors[team_color] != atlas_coords or cell in sides
		
	if is_rotate: return cell in sides
	return cell not in sides



func _rect_check_collide(matrix: Dictionary, old_matrix: Dictionary, pos: Vector2, side, is_rotate: bool = false, team_color: int = -1):
	var colliders = {'up': false, 'down': false, 'right': false, 'left': false}
	
	var sides = []

	var old_sides = old_matrix['up'] + old_matrix['down'] + old_matrix['right'] + old_matrix['left']
	for _side in matrix:
		
		var x = 0
		for cell in matrix[_side]:
			#print(get_cell_atlas_coords(0, pos + cell) != Vector2i(-1,-1), ' ', cell, ' ', func_cell_rotate_not_in(cell, old_sides, is_rotate))
			#print(cell, ' ', get_cell_atlas_coords(0, pos + cell) != Vector2i(-1,-1))
			var atlas_coords = get_cell_atlas_coords(0, pos + cell)
			if (atlas_coords != Vector2i(-1,-1)) and func_cell_rotate_not_in(cell, old_sides, is_rotate, atlas_coords, team_color):#func_cell_rotate_not_in(cell, old_sides, false):
				colliders[_side] = true
	
	return colliders


func rect_check_collide(team: int, vector: Vector2 = Vector2(-1, -1), degrees: int = -1):
	var rot = markers[team][0]
	var is_rotate = false
	if degrees != -1:
		rot = degrees
		is_rotate = true
	
	var rect = rotate_rect(rects[markers[team][1]], rot)
	
	var side = get_vector_side(vector)
		
	#print('rot: ', rot, ' side: ', side)
	return _rect_check_collide(rect, rotate_rect(rects[markers[team][1]], markers[team][0]), markers[team][2], side, is_rotate, team)


func is_collide_matrix(matrix_collide: Dictionary):
	for i in matrix_collide:
		if matrix_collide[i] == true: return true
	return false


func get_vector_side(vector: Vector2):
	var side = null
	if vector == Vector2.UP:
		side = 'up'
	
	elif vector == Vector2.DOWN:
		side = 'down'
	
	elif vector == Vector2.RIGHT:
		side = 'right'

	elif vector == Vector2.LEFT:
		side = 'left'
	
	return side


func get_random_figure():
	randomize()
	return types[randi() % types.size()]


func check_under_line(team: int):
	if is_collide_down_line(team):
		markers.erase(team)
		add_object(get_random_figure(), Vector2(1,1), team)
		#clear_layer(1)
		#clear_layer(2)
		return


func update_object(team: int):
	old_markers[team] = {markers[team][2]: [markers[team][1], markers[team][0]]}
	markers.erase(team)
	
	#await get_tree().create_timer(0.5).timeout
	
	#add_object(get_random_figure(), Vector2(1,1), team)
	if multiplayer.multiplayer_peer.get_class() == 'ENetMultiplayerPeer' and multiplayer.is_server():
		get_parent().get_parent().rpc('after_update_add_object', team)
	
	await get_tree().create_timer(0.4).timeout
	
	if markers.has(team):
		var collide = rect_check_collide(team, Vector2(-1, -1), markers[team][0] + 90)
		#print(collide)
		if collide['down']:
			print('u lose :(, '+ str(team))
			_clear(markers[team][1], markers[team][2], team, markers[team][0])
			markers.erase(team)
			
			if multiplayer.multiplayer_peer.get_class() == 'ENetMultiplayerPeer':
				get_parent().get_parent().rpc('team_loose', team)


func update_line(cords: Vector2i = Vector2i(26, 0)): # max x = 20, y = 26
	var base_color =  colors[teams['base']]
	
	var contribution_teams = {}
	#print(cords)
	for ii in range(1, cords.x + 1):
		#print(ii)
		var coords = Vector2i(ii, cords.y)
		
		var atlas_coords = get_cell_atlas_coords(0, coords) 
		
		if atlas_coords == Vector2i(-1, -1) or atlas_coords == base_color:
			return 
		
		var id_team = get_id_team_from_atlas_cords(atlas_coords)
		
		if contribution_teams.has(id_team) == false:
			contribution_teams[id_team] = 1
		else:
			contribution_teams[id_team] += 1
		#set_cell(2, coords, 1, Vector2i(2,1))
	
	for i in range(1, cords.x + 1):
		#erase_cell(2, Vector2i(i, cords.y))
		ccell(Vector2(i, cords.y))
	
	if multiplayer.multiplayer_peer.get_class() == 'ENetMultiplayerPeer':
		get_parent().get_parent().rpc('clear_line', get_percents_teams_contribution(contribution_teams), cords.y)


func clear_lines(cords: Vector2i = Vector2i(34, 20)):
	#clear_layer(2)
	for i in range(1, cords.y + 1):
		update_line(Vector2i(cords.x, cords.y - i))


func get_id_team_from_atlas_cords(atlas_coords: Vector2i):
	var team = 0
	for i in colors + back_colors:
		if i == atlas_coords:
			return team
		
		team += 1


func get_percents_teams_contribution(contribution_teams: Dictionary):
	var percents_teams = {}
	var summ = contribution_teams.values().reduce(sum_reduce)
	
	for i in contribution_teams:
		var percents = contribution_teams[i] / summ * 100
		percents_teams[i] = percents - percents % percents
	
	return percents_teams


func _input(event):
	if is_test_one_object:
		var team = 2
		if markers.has(team):
			if Input.is_action_just_pressed('ui_up'): cw_rotate(team)
			if Input.is_action_pressed('ui_down'): m_down(team)
			if Input.is_action_pressed('ui_right'): m_right(team)
			if Input.is_action_pressed('ui_left'): m_left(team)

func sum_reduce(accum: int, element: int) -> int:
	return accum + element


"""
@rpc('any_peer')
func update_cell(tile, pos):
	if typeof(tile) == 2:
		erase_cell(0, pos)
	else:
		set_cell(0, pos, 1, tile)
	if is_rpc_test: print('Cell ' + str(tile) + ' on position ' + str(pos))
	if is_main: 
	
@rpc('call_local')
func clear_line(percents_teams, y):
	if is_rpc_test: print('Cleared line on ' + str(y) + ' contribution teams: ' + str(percents_teams))

@rpc('call_local')
func team_loose(team):
	if is_rpc_test: print('Eliminated team ' + str(team))

@rpc('call_local')
func after_update_add_object(team):
	print(2)"""
