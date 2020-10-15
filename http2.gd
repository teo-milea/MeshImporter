# Credit: https://github.com/KOBUGE-Games/godot-httpd/blob/master/httpd.gd
# file serving http server using godot
# execute this using godot -s httpd.gd
# and open http://localhost:40004 in a browser
# set data_dir to what you desire, it points at
# the directory served to the public

extends Spatial
var json_parser = JSON
var srv = TCP_Server.new()
var init_world = false
var obj_dict = {}

var data_dir # data_dir is set below in the _init() method.

func write_str(con, stri):
	#print(str("writing string ", stri))
	return con.put_data(stri.to_utf8())

func recv_str(con):
	return con.get_data()

# reads (and blocks) until the first \n, and perhaps more.
# you can feed the "more" part to the startstr arg
# of subsequent calls
func read_line(con, startstr):
	var first = true
	var pdata
	var pdatastr
	var retstr = startstr
	#if (startstr.find("\n") != -1):
	#	return startstr
	var flag = 0
	while true:
		#print(con.get_data(4096))
		pdata = con.get_partial_data(64)
		#print(pdata[0], pdata[1].get_string_from_ascii())
		if(pdata[1].size() != 0):
			if (pdata[0] != OK):
				return false
			pdatastr = pdata[1].get_string_from_ascii()
		else:
			pdata = con.get_data(64) # force block
			if (pdata[0] != OK):
				return false
			pdatastr = pdata[1].get_string_from_ascii()
			#print(pdata[1].get_string_from_ascii())
		if pdatastr == null:
			return false
		retstr = str(retstr, pdatastr)
		
		if (pdatastr.find("\n\n") != -1):
			break
	#print(retstr)
	return retstr

# returns the path and method if no error, sends error and false if error
func parse_request(con):
	var st_line = read_line(con, "")
	if (not st_line):
		return false
	var lines = st_line.split(" ")
	var arr = lines[0].split(" ")
	var mth = arr[0]
	return st_line

func move_objects(json_data):
	var index 
	index = json_data[json_data.size() - 1]["val"]
		
	print("MSG INDEX:", index)
	
	for obj in json_data:
		#var index 	
		
		if obj["node_type"] != "index" and obj["name"] in obj_dict.keys():
			
			var trans = obj["translation"]
			var rot = obj["rotation"]
			print("MSG INDEX:", index,  obj["name"], trans, rot)
			#print(rot)
			#obj_dict[obj["name"]].translation = Vector3(trans[0], trans[1], trans[2])
			#var t = Transform(Quat(rot[1], rot[2], rot[3], rot[0]))
			#t.scaled(obj_dict[obj["name"]].scale)
			#print("SANITY CHECK\n")
			var t = Transform()#.translated(-obj_dict[obj['name']]['translation'])
			t = Transform(Basis ( Vector3(rot[2][2], rot[1][2], rot[0][2]), Vector3(rot[2][1], rot[1][1], rot[0][1]), Vector3(rot[2][0], rot[1][0], rot[1][0])), Vector3(-trans[2], trans[1], trans[0])) * t
			#t = t.scaled(Vector3(-1, 1, 1))
			#t = t.translated(Vector3(-trans[2], trans[1], trans[0]))
			#t = t
			#print("SANITY CHECK2\n")
			#print("old:", t)
			#print("new:",obj_dict[obj["name"]].global_transform)
			var c_t = obj_dict[obj["name"]]["node"].get_transform()
			#obj_dict[obj["name"]]["node"].set_transform(t)
			obj_dict[obj["name"]]["node"].set_transform(t)
			if obj['name'] == 'solid7':
				print(obj_dict[obj['name']]['transform'])
			#obj_dict[obj["name"]]["node"].set_translation(Vector3(trans[0], trans[1], trans[2]))
			#print("CEV PLM:", obj_dict[obj["name"]].get_scale())
			#obj_dict[obj["name"]].set_scale(Vector3(1,1,1))
			#obj_dict[obj["name"]].force_update_transform()
			#
			#obj_dict[obj["name"]].global_rotate(Vector3(rot[1], rot[2], rot[3]), rot[0])
			
func run_thrd(params):
	var con = params.con
	while true:
		var req = parse_request(con)
		var json_data = req
		var results = json_parser.parse(json_data)
		#print(results.result)
		if not init_world:
			var transform = Transform()
			parse_tree(results.result, transform, Vector3(0,0,0))
			for o in obj_dict:
				get_tree().get_root().get_child(0).add_child(obj_dict[o]["node"])
				obj_dict[o]["node"].set_transform(obj_dict[o]["transform"])
			init_world = true
			print(obj_dict)
			var file = File.new()
			file.open("json.json", File.WRITE)
			file.store_string(json_data)
			file.close()
			print("GATA LUMEA")
		else:
			move_objects(results.result)
			#print(results)
		#write_ok(con, path)
			
	con.disconnect_from_host()

	# hack to free the thread reference after it has exited
	# godot has no native protection here, and can
	# free a running thread if all references are lost
	# The call below saves the reference until the method
	# can be called, and gives additional safety by calling
	# wait_to_finish and not some arbitrary method, to account for
	# the engine or the OS doing other tasks on the thread
	# before actually declaring a thread to be "finished"
	params.thread.call_deferred("wait_to_finish")
	
func _server(params):
	while (true):
		while (!srv.is_connection_available()): # TODO replace this with actual blocking
			OS.delay_msec(100)
		var cn = srv.take_connection()
		cn.set_no_delay(true)
		print(cn)
		var thread = Thread.new()
		thread.start(self, "run_thrd", {con=cn, thread=thread})

var json_dict
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# One dimension flatten
func flatten(array):
	var arr = []
	for a in array:
		#for e in a.:
		arr.append(a[0]) 
		arr.append(a[1]) 
		arr.append(a[2]) 
	return arr

func print_objs(node1, node2):
	var properties = node1.get_property_list()

	for i in range(properties.size()):
		print(properties[i].name + ", val1: " + str(node1.get(properties[i].name)) + " ---- " + str(node2.get(properties[i].name)))

func parse_mesh(mesh_json):
	print("Mesh:", name)
	var mesh = ArrayMesh.new()
	var mesh_instance = MeshInstance.new()
	
	var arr = parse_array_mesh(mesh_json['geometry'])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr) 
	mesh_instance.mesh = mesh
	
	var appearance = mesh_json["appearance"]
	mesh_instance.material_override = parse_appearance(appearance)

	return mesh_instance

func parse_array_mesh(geometry_json):
	var verts = PoolVector3Array()
	var uvs = PoolVector2Array() # TODO UVS
	var normals = PoolVector3Array()
	var indices = PoolIntArray()
	var colors = PoolColorArray()
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	
	print(geometry_json.keys())
	
	for v in geometry_json['vertices']:
		verts.push_back(Vector3(v[2], v[1], v[0]))  # TODO(luca) this is backwards, note the ccw parameter in shape (send it)
		
	for i in flatten(geometry_json['faces']):
		indices.push_back(i)
	
	if 'uvs' in geometry_json.keys():
		for i in geometry_json['uvs']:
			uvs.push_back(Vector2(i[0], -i[1]))
		
		arr[Mesh.ARRAY_TEX_UV] = uvs 
	# generate normals
	if 'normals' in geometry_json:
		for v in geometry_json['normals']:
			normals.push_back(Vector3(-v[2], v[1], v[0]))
	else:
		var new_normals = []
		new_normals.resize(verts.size())
		for i in range(new_normals.size()):
			new_normals[i] = Vector3(0, 0, 0)
		
		# credit: https://computergraphics.stackexchange.com/questions/4031/programmatically-generating-vertex-normals
		for face in geometry_json['faces']:
			var A = verts[face[2]]
			var B = verts[face[1]]
			var C = verts[face[0]]
			
			var p = (B - A).cross(C - A)
			new_normals[face[0]] += p
			new_normals[face[1]] += p
			new_normals[face[2]] += p
			
		for i in range(new_normals.size()):
			normals.push_back(new_normals[i].normalized())
	
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_INDEX] = indices
	return arr 

func parse_appearance(appearance_json):
	var material = SpatialMaterial.new()
	
	if appearance_json['node_type'] == 'PBRAppearance':
		var albedo = appearance_json['baseColor']
		var emission = appearance_json['emissiveColor']
		
		material.albedo_color = Color(albedo[0], albedo[1], albedo[2], 1 - appearance_json['transparency']) # TODO transparency
		material.flags_transparent = appearance_json['transparency'] != 0 # always on
		if appearance_json["baseColorMap"] != null:
			var albedo_texture = ImageTexture.new()
			var enc_image = Image.new()
			var marshall = Marshalls
			enc_image.load_png_from_buffer(marshall.base64_to_raw(appearance_json["baseColorMap"]))
			albedo_texture.create_from_image(enc_image)
			material.albedo_texture = albedo_texture
		else:
			material.albedo_texture = null # TODO baseColorMap	
		
		material.roughness = appearance_json['roughness']
		material.roughness_texture = null # TODO roughnessMap
		material.roughness_texture_channel = 0 # TODO ???
		
		material.metallic = appearance_json['metalness']
		material.metallic_specular = 0.5 # TODO ???
		material.metallic_texture = null # TODO metalnessMap
		material.metallic_texture_channel = 0 # TODO ???
		
		material.normal_scale = appearance_json['normalMapFactor']
		material.normal_texture = null
		
		material.ao_light_affect = appearance_json['occlusionMapStrength']
		material.ao_enabled = false # always on
		material.ao_on_uv2 = false # TODO hardcoded
		material.ao_texture = null # TODO occlusionMap
		
		material.emission = Color(emission[0], emission[1], emission[2], 1)
		material.emission_enabled = true # always on
		material.emission_energy = appearance_json['emissiveIntensity']
		
	elif appearance_json['node_type'] == 'Appearance':
		var albedo = appearance_json['material']['diffuseColor']
		var emission = appearance_json['material']['emissiveColor']
		var specular = appearance_json['material']['specularColor']
		
		material.albedo_color = Color(albedo[0], albedo[1], albedo[2]) # TODO transparency	
		material.emission = Color(emission[0], emission[1], emission[2])
		material.flags_transparent = appearance_json['material']['transparency'] != 0
		material.metallic = appearance_json['material']['shininess']
		
	return material
	
func parse_tree(n, transform, translation):
	if n['node_type'] in ['Group', 'Transform', 'Solid', 'Robot']:
		var t = Transform()
		var spatial = Spatial.new()
		var tr = [0,0,0]
		if n["node_type"] in ['Transform', 'Solid', 'Robot']:
			
			var r = n["rotation"]
			tr = n["translation"]
			var s = n["scale"]
			#t = t.scaled(Vector3(s[2], s[1], s[0]))
			#t = t.rotated(Vector3(r[2], r[1], -r[0]), r[3])
			#t = t.translated(Vector3(tr[0], tr[1], tr[2]))
		for c in n['children']:
			print(c["node_type"])
			if c["node_type"] in ['Group', 'Transform', 'Solid', 'Robot']:
				parse_tree(c, t*transform, translation + Vector3(tr[2], tr[1], -tr[0]))
			else:
				if c["node_type"] == "Shape":
					spatial.add_child(parse_mesh(c))
					
					obj_dict[n["name"]] = {"node": spatial, "transform": t * transform, "translation": translation}

func _ready():
	var port = 40005
	srv.listen(port)
	print(str("Server listening at http://localhost:", port))
	data_dir = "." # has to end with an "/"

	var thread = Thread.new()
	thread.start(self, "_server", {})
