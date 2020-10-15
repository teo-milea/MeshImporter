extends Node

var parser = JSON
var json_dict
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# One dimension flatten
func flatten(array):
	var arr = []
	for a in array:
		for e in a:
			arr.append(e) 
	return arr

func print_objs(node1, node2):
	var properties = node1.get_property_list()

	for i in range(properties.size()):
		print(properties[i].name + ", val1: " + str(node1.get(properties[i].name)) + " ---- " + str(node2.get(properties[i].name)))

func parse_mesh(mesh_json):
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
	
	for v in geometry_json['vertices']:
		verts.push_back(Vector3(v[2], v[1], v[0]))  # TODO(luca) this is backwards, note the ccw parameter in shape (send it)
		
	for i in flatten(geometry_json['faces']):
		indices.push_back(i)
		
	# generate normals
	if 'normals' in geometry_json:
		for v in geometry_json['normals']:
			normals.push_back(Vector3(v[0], v[1], v[2]))
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
	#arr[Mesh.ARRAY_TEX_UV] = uvs 
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
		material.ao_enabled = true # always on
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
	
func parse_tree(n):
	if n['node_type'] == 'Group':
		var spatial = Spatial.new()
		for c in n['children']:
			spatial.add_child(parse_tree(c))
		return spatial
	else:
		return parse_mesh(n)

# Called when the node enters the scene tree for the first time.
func _ready():
	var file = File.new()
	file.open("res://webots_output1.json", File.READ)
	var content = file.get_as_text()

	var result = parser.parse(content)
	json_dict = result.result

	var s = parse_tree(json_dict)
	get_tree().get_root().get_child(0).add_child(s)
