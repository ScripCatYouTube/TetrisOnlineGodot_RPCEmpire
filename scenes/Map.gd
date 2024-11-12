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
	'square': [Vector2(-1, -1), Vector2(-1, 0), Vector2(0, -1), Vector2(0, 0)],
	'gamma': [Vector2(0, -1), Vector2(-1, -1), Vector2(-1, 0), Vector2(1, -1)],
	'gamma_reversed': [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(1, 0)],
	'triangle': [Vector2(0, -1), Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0)],
	'line': [Vector2(0, -2), Vector2(0, -1), Vector2(0, 0), Vector2(0, 1)]
}

var rects = {
	'square': 
		{ 
			"up": [Vector2(-1, -2), Vector2(0, -2)], 
			"left": [Vector2(-2, -1), Vector2(-2, 0)], 
			"right": [Vector2(1, -1), Vector2(1, 0)], 
			"down": [Vector2(-1, 1), Vector2(0, 1)] 
		},
		
	 'gamma': 
		{ 
			"up": [Vector2(-1, -2), Vector2(0, -2), Vector2(1, -2)], 
			"left": [Vector2(-2, -1), Vector2(-2, 0)], 
			"right": [Vector2(2, -1), Vector2(0, 0)], 
			"down": [Vector2(-1, 1), Vector2(0, 0), Vector2(1, 0)] 
		},
		
	'gamma_reversed':
		{
			'up': [Vector2(-1, -2), Vector2(0, -2), Vector2(1, -2)],
			'left': [Vector2(-2, -1), Vector2(0, 0)],
			'right': [Vector2(2, -1), Vector2(2, 0)],
			'down': [Vector2(-1, 0), Vector2(1, 1), Vector2(0, 0)]
		},
		
	'triangle':
		{ 
			"up": [Vector2(-1, -2), Vector2(0, -2), Vector2(1, -2)], 
			"left": [Vector2(-1, 0), Vector2(-2, -1)], 
			"right": [Vector2(1, 0), Vector2(2, -1)], 
			"down": [Vector2(-1, 0), Vector2(0, 1), Vector2(1, 0)] 
		},

	'line':
		{ 
			"up": [Vector2(0, -3)], 
			"left": [Vector2(-1, -2), Vector2(-1, -1), Vector2(-1, 0), Vector2(-1, 1)], 
			"right": [Vector2(1, -2), Vector2(1, -1), Vector2(1, 0), Vector2(1, 1)], 
			"down": [Vector2(0, 2)] 
		}
}


var markers = {} # team: [rotate, type, position]
var old_markers = {} # {position: [rotate, figure, team]}

@export_category("Tests")
@export var is_main = false
@export var is_test_one_object = false
@export var is_test = false
@export var is_rpc_test = false


func _ready():
	#generate_figures_and_rect()
	#print(get_modified_figure(__rotate('gamma', 90)))
	
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


func _process(_delta):
	#if is_main or is_test_one_object: clear_lines()
	if is_main: print_label()
	

func update_physics():
	await get_tree().create_timer(1).timeout
	all_move_down()


func _on_timer_timeout():
	all_move_down()
	clear_lines()


func draw(type, pos, team, degrees = 0):
	var r = __rotate(type, degrees)
	for i in r:
		cell(pos + i, team)


func _clear(type, pos, team, degrees):
	for i in __rotate(type, degrees):
		ccell(pos + i)


func update(team, next_pos = null, next_degrees = null):
	var data_figure = _update(
		markers[team][2], 
		markers[team][0], 
		markers[team][1], 
		next_pos, 
		next_degrees, 
		team
	)
	
	markers[team] = data_figure


func _update(old_pos: Vector2, old_degrees: int, figure, pos = null, degrees = null, team: int = 0):		
	if pos == null:
		pos = old_pos
		
	if degrees == null:
		degrees = old_degrees
	
	_clear(figure, old_pos, team, old_degrees)
	draw(figure, pos, team, degrees)
	
	return [degrees, figure, pos]


func move(team: int, direction: Vector2):
	if markers.has(team):
		
		var collide = rect_check_collide(team, direction, markers[team][0])
		if collide['down'] == true:
			update_object(team)
			return
		
		if collide[get_vector_side(direction)] == true:
			return
		
		update(team, markers[team][2] + direction, null)
		
		clear_layer(1)
		rect_draw(team)
		
		if collide['down'] == true:
			update_object(team)
			return


func m_down(team: int):
	move(team, Vector2(0, 1))

func m_up(team: int):
	move(team, Vector2(0, -1))

func m_right(team: int):
	#print('right')
	move(team, Vector2(1, 0))

func m_left(team: int):
	#print('left')
	move(team, Vector2(-1, 0))


func move_down(pos: Vector2, is_was_moved: Array, old_is_was_moved: Array):
	var p = pos
	p.y += 1
	var cell = get_cell_atlas_coords(0, pos)
	
	var marker = marker_cells(pos)
	if marker[0]:
		if marker[1] not in is_was_moved:
			move(marker[1], Vector2(0,1))
			is_was_moved.append(marker[1])
		return
	
	if old_markers.has(pos):
		if pos not in old_is_was_moved:
			var rect = get_modified_figure(old_markers[pos][1])
			
			if _rect_check_collide(rect, rect, pos, 'down', false, old_markers[pos][2])['down'] == false:
				_update(pos, old_markers[pos][0], old_markers[pos][1], p, null, old_markers[pos][2])
			
	#if get_cell_atlas_coords(0, p) == Vector2i(-1, -1) and cell != colors[teams['base']]:
	#	ccell(pos)
	#	_cell(p, cell)


func moves_down(y, max_x, is_was_moved, old_is_was_moved):
	for i in range(0, max_x + 1):
		move_down(Vector2(i, y), is_was_moved, old_is_was_moved)


func all_move_down(max_vector: Vector2 = Vector2(34, 20)):
	var is_was_moved = []
	var old_is_was_moved = []
	
	for i in range(0, max_vector.y + 1):
		moves_down(max_vector.y - i, max_vector.x, is_was_moved, old_is_was_moved)

	

func marker_cells(vector: Vector2):
	for i in markers:
		for vec in __rotate(markers[i][1], markers[i][0]):
			if vector == markers[i][2] + vec:
				return [true, i]
	return [false, -1]


func cw_rotate(team: int):
	clear_layer(1)
	rect_draw(team)
	#print('rotate')
	if markers.has(team):
		if is_collide_matrix(rect_check_collide(team, Vector2(-1, -1), markers[team][0] + 90)): 
			return
		#print(1)
		
		update(team, null, markers[team][0] + 90)
		
		if markers[team][0] >= 360:
			markers[team][0] = 0


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
	
	if index != -1:
		return get_rotated_sides(degrees)[index]


func rotate_rect_sides(matrix: Dictionary, degrees: int):
	var new_matrix = {}
	var sides = get_rotated_sides(degrees)
	var num_side = 0 

	for i in matrix:
		new_matrix[sides[num_side]] = matrix[i]
		num_side += 1
		
	return new_matrix
	


func add_object(type: String, pos: Vector2, team: int):
	print('Added object "', type, '" team\'s ', team)
	
	markers[team] = [0, type, pos]
	draw(type, pos, team)	


func get_center_figure(matrix: Array):
	var new_matrix = []
	var max_x = float(get_x_lenght_figure(matrix)[1])
	var max_y = float(get_y_lenght_figure(matrix)[1])
	
	var m_x = 0
	var m_y = 0
	
	if max_x != 0:
		m_x = ceil(max_x / 2)
	
	if max_y != 0:
		m_y = ceil(max_y / 2)
	
	for i in matrix:
		var _in = i
		_in.x -= m_x
		_in.y -= m_y 
		
		new_matrix.append(_in) 
	
	return new_matrix
	

func get_center_rect(rect: Dictionary):
	var new_rect = {}
	
	for i in rect:
		new_rect[i] = get_center_figure(rect[i])
	
	return new_rect
	

func generate_figures_and_rect():
	for i in figures:
		print("'",i,"'")
		print("    ", str(get_center_figure(figures[i])))	
		print("    ", get_center_rect(rects[i]))	
		print()


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
	var matrix = type
	if typeof(matrix) == 4:
		matrix = figures[type]
	
	elif degrees == 0 or degrees == -90:
		return matrix#get_center_figure(matrix)

	return _rotate(matrix, degrees)


func rotate_rect(matrix_rect, degrees):
	var new_matrix_rect = {}
	var rotated_sides = get_rotated_sides(degrees)
	var sides = ['up', 'down', 'right', 'left']

	var ii = 0
	for i in sides:
		new_matrix_rect[rotated_sides[ii]] = __rotate(matrix_rect[i], degrees)
		ii += 1 
		
	return new_matrix_rect
	

func _cell(pos, tile):
	if typeof(tile) == 2:
		erase_cell(0, pos)
	else:
		set_cell(0, pos, 1, tile)
		
	if multiplayer.multiplayer_peer.get_class() == 'ENetMultiplayerPeer' and multiplayer.is_server():
		get_parent().get_parent().rpc('update_cell', tile, pos)


func cell(pos, team):
	_cell(pos, colors[team])

func ccell(pos):
	_cell(pos, -1)


func is_collide(team: int, pos: Vector2, degrees: int):
	var figure = __rotate(markers[team][1], degrees)
	var original_figure = __rotate(markers[team][1], markers[team][0])
	
	return _is_collide(pos, figure, markers[team][2], original_figure)


func _is_collide(pos: Vector2, matrix: PackedVector2Array, original_pos: Vector2, original_matrix: PackedVector2Array):
	var ii = 0
	
	for i in matrix:
		var cell = get_cell_atlas_coords(0, i + pos)
		if cell != Vector2i(-1, -1) and original_matrix[ii] + original_pos == i + pos: 
			pass
			
		ii += 1
	
	return false 	


func __is_collide(x: Array, y: Array):
	for i in x:
		if y.has(i): return true
	return false
	


func is_collide_down_line(team: int):
	var sizex = size_x(markers[team][1], markers[team][0])
	var sizey = size_y(markers[team][1], markers[team][0])
	
	for x in range(sizex[0]):
		var position_cell = math_line_down(markers[team][2], sizey[0], x, markers[team][0], sizex[1])
		
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
	if markers.has(team):
		var rect = rotate_rect(rects[markers[team][1]], markers[team][0])
		for i in rect:
			var tile = back_colors[teams['base']]
			
			if i == 'up':
				tile = back_colors[teams['red']]
			elif i == 'down':
				tile = back_colors[teams['yellow']]
			elif i == 'right':
				tile = back_colors[teams['blue']]
			elif i == 'left':
				tile = back_colors[teams['green']]
			
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

	var col = _rect_check_collide(rect, rotate_rect(rects[markers[team][1]], markers[team][0]), markers[team][2], side, is_rotate, team)
	#print('Collide Team:', team, ' : ', col)
	return col
	

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



func get_x_lenght_figure(figure: Array):
	var min_x: int = 0
	var max_x: int = 0
	for i in figure:
		if i.x > max_x:
			max_x = i.x
		
		elif i.x < min_x:
			min_x = i.x
	
	return [min_x, max_x]


func get_y_lenght_figure(figure: Array):
	var min_y: int = 0
	var max_y: int = 0
	for i in figure:
		if i.y > max_y:
			max_y = i.y
		
		elif i.y < min_y:
			min_y = i.y
	
	return [min_y, max_y]


func get_modified_figure(figure: Array):
	var rect = {'up': [], 'down': [], 'right': [], 'left': []}
	var _x = get_x_lenght_figure(figure)
	
	for side in [Vector2.UP, Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT]:
		var _side = get_vector_side(side)
		
		for i in figure:
			var cordinate = i + side
			if not figure.has(cordinate):
				rect[_side].append(cordinate) 
	
	return rect


func get_random_figure():
	randomize()
	return types[randi() % types.size()]


func check_under_line(team: int):
	if is_collide_down_line(team):
		markers.erase(team)
		add_object(get_random_figure(), Vector2(1,1), team)
		return


func update_object(team: int):
	#print(13, ' ', markers[team][1])
	
	if markers.has(team):
		old_markers[markers[team][2]] = [markers[team][0], __rotate(figures[markers[team][1]], markers[team][0]), team, markers[team][1]]
		markers.erase(team)
		if multiplayer.multiplayer_peer.get_class() == 'ENetMultiplayerPeer' and multiplayer.is_server():
			get_parent().get_parent().rpc('after_update_add_object', team)
	
	await get_tree().create_timer(1).timeout
	
	if markers.has(team):
		await get_tree().create_timer(1.5).timeout
		is_loose(team)
		
		
func is_loose(team):
	if markers.has(team):
		var collide = rect_check_collide(team, Vector2(-1, -1), markers[team][0] + 90)
		if collide['down']:
			print('u lose :(, '+ str(team))
			_clear(markers[team][1], markers[team][2], team, markers[team][0])
			markers.erase(team)
			
			if multiplayer.multiplayer_peer.get_class() == 'ENetMultiplayerPeer':
				get_parent().get_parent().rpc('team_loose', team)
			
			return
	


func update_line(cords: Vector2i = Vector2i(26, 0)): # max x = 20, y = 26
	var base_color =  colors[teams['base']]
	var contribution_teams = {}
	
	for ii in range(1, cords.x + 1):
		var coords = Vector2i(ii, cords.y)
		
		var atlas_coords = get_cell_atlas_coords(0, coords) 
		
		if atlas_coords == Vector2i(-1, -1) or atlas_coords == base_color:
			return 
		
		var id_team = get_id_team_from_atlas_cords(atlas_coords)
		
		if contribution_teams.has(id_team) == false:
			contribution_teams[id_team] = 1
		else:
			contribution_teams[id_team] += 1
	
	for i in range(1, cords.x + 1):
		ccell(Vector2(i, cords.y))
	
	if multiplayer.multiplayer_peer.get_class() == 'ENetMultiplayerPeer':
		get_parent().get_parent().rpc('clear_line', get_percents_teams_contribution(contribution_teams), cords.y)


func print_dict(dictionary):
	print()
	for i in dictionary:
		print('  ', i, ': ', dictionary[i])


func check_pos_old_marker_update_line(pos):
	for old_marker in old_markers:
		for i in old_markers[old_marker][1]:
			#print(Vector2(i) + Vector2(old_marker), ' : ', pos)
			if Vector2(Vector2(i) + Vector2(old_marker)) == pos:
				#print(true)
				return [true, old_marker]
	
	return [false]


func delete_y_cords(pos: Vector2, base_pos: Vector2, line_color: Vector2i):
	var new_figure = old_markers[pos][1]
	#clear_layer(2)
	
	for i in old_markers[pos][1]:
		#set_cell(2, base_pos, 1, line_color)	
		if i.y == pos.y:		
			new_figure.erase(i.y)
	
	#print('F:  ', old_markers[pos][1])
	#print('NF: ', new_figure)
	
	old_markers[pos][1] = new_figure
	#var posold = old_markers[pos]
	#posold[1] = new_figure
	#old_markers[pos] = posold


func _update_line(cords: Vector2i = Vector2i(26, 0)): # max x = 20, y = 26
	clear_layer(2)
	
	await get_tree().create_timer(1).timeout
	
	var base_color =  colors[teams['base']]
	var line_color = back_colors[teams['yellow']]
	var contribution_teams = {}
	
	for ii in range(1, cords.x + 1):
		#clear_layer(2)
		var iterable_cords = Vector2i(ii, cords.y)
		var old_marker = check_pos_old_marker_update_line(iterable_cords)
		
		if old_marker[0]:
			var coords = old_marker[1]
			var atlas_coords = get_cell_atlas_coords(0, coords) 
			var id_team = get_id_team_from_atlas_cords(atlas_coords)
			
			if atlas_coords == Vector2i(-1, -1) or atlas_coords == base_color:
				return 
			
			
			if contribution_teams.has(id_team) == false:
				contribution_teams[id_team] = 1
			else:
				contribution_teams[id_team] += 1
			
			delete_y_cords(coords, iterable_cords, line_color)
	
	await get_tree().create_timer(1).timeout
			#var rect = get_modified_figure(old_markers[coords][1])
		
			#if _rect_check_collide(rect, rect, coords, 'down', false, old_markers[coords][2])['down'] == false:
			#	_update(coords, old_markers[coords][0], old_markers[coords][1], coords + Vector2.DOWN, null, old_markers[coords][2])
	
	
	#for i in range(1, cords.x + 1):
	#	var pos = Vector2(i, cords.y)
	#	var rect = get_modified_figure(old_markers[pos][1])
	#	
	#	if _rect_check_collide(rect, rect, pos, 'down', false, old_markers[pos][2])['down'] == false:
	#		_update(pos, old_markers[pos][0], old_markers[pos][1], pos + Vector2.DOWN, null, old_markers[pos][2])
	
	if multiplayer.multiplayer_peer.get_class() == 'ENetMultiplayerPeer' and multiplayer.is_server() != null:
		get_parent().get_parent().rpc('clear_line', get_percents_teams_contribution(contribution_teams), cords.y)


func __update_line(max_cords: Vector2i = Vector2i(26, 0), base_color: Vector2i = colors[teams['base']]): # max x = 20, y = 26
	#clear_layer(2)
	for i in range(1, max_cords.x):
		#await get_tree().create_timer(0.4).timeout
		
		var tile_cords = Vector2(i, max_cords.y)
		var atlas_cords = get_cell_atlas_coords(0, tile_cords)
		
		if atlas_cords == Vector2i(-1, -1):#or atlas_cords == base_color:
			return
		
		var checked_figure = check_pos_old_marker_update_line(tile_cords)
		
		#set_cell(2, tile_cords, 1, base_color)
		#print(tile_cords)
		
		if checked_figure[0]:
			#var cords = checked_figure[1]
			
			#print('f')
			#print(cords, ' c : tc ', tile_cords)
			#if cords == tile_cords:
			#var atlas_cords = get_cell_atlas_coords(0, tile_cords)
			#print(atlas_cords)
			#print()
			#set_cell(2, tile_cords, 0, back_colors[teams['base']])
				
			#if atlas_cords == Vector2i(-1, -1) or atlas_cords == base_color:
			#	break
			
			#if tile_cords.x >= max_cords.x:
			#	print(1)
			set_cell(2, tile_cords, 1, base_color)
				#set_cell(2, tile_cords, 0, back_colors[teams['yellow']])
		print(1)

func clear_lines(cords: Vector2i = Vector2i(34, 20)):
	#clear_layer(2)
	for i in range(1, cords.y - 1):
		#clear_layer(2)
		__update_line(Vector2i(cords.x + 1, cords.y - i))
		await get_tree().create_timer(0.5).timeout


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

func print_label():
	$Label.text = str(local_to_map(get_global_mouse_position()))
