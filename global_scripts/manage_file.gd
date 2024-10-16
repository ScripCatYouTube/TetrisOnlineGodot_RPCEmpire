extends Node


func create_file(filename: String):
	var is_exit = FileAccess.file_exists(filename)
	if is_exit == false:
		var file = FileAccess.open(filename, FileAccess.WRITE)
	
	return is_exit


func rewrite(text, filename: String):
	var file = FileAccess.open(filename, FileAccess.WRITE)
	file.store_line(text)
	file = null


func read(filename: String):
	var file = FileAccess.open(filename, FileAccess.READ)
	var data = file.get_as_text()
	file = null
	
	return data
	

func defualt_write(data, filename: String):
	var is_exit = create_file(filename)
	if is_exit == false:
		rewrite(data, filename)
	

func json_write(dict, filename: String):
	if typeof(dict) == 27:
		dict = JSON.stringify(dict)
	
	rewrite(dict, filename)


func read_json(filename: String):
	var readed = read(filename)
	#print('read json: ' + readed)
	return JSON.parse_string(readed)
	

func rewrite_json(key, data, filename: String):
	var readed = read_json(filename)
	
	readed[key] = data
	
	json_write(readed, filename)


func json_defualt_write(data, filename: String):
	var is_exit = create_file(filename)
	if is_exit == false:
		json_write(data, filename)
	
	
	else:
		#return
		var readed = read(filename).replace(' ', '').replace('\n', '')
		#print('defualt json: ' + readed)
		#print('l:' + readed.left(1) + '; r:' + readed.right(1) + ';')
		#print(str(readed.left(1) != '{') + str(readed.right(1) != '}'))
	
		if readed.left(1) != '{' or readed.right(1) != '}':
			json_write(data, filename)
		
		#elif readed.left(1) != '[' or readed.right(1) != ']':
		#	json_write(data, filename)

	

