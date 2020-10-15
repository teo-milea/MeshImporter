extends Node2D
var playerScene = preload("res://Node3D.tscn");
var playerSceneInstance;
var camera_top = null
var camera_bottom = null
var camera_right = null
var camera_left = null

var viewport_sprite_top = null
var viewport_sprite_bottom = null
var viewport_sprite_right = null
var viewport_sprite_left = null

const MAX_FRAME_FOR_SPRITE = 4
const FRAME_SWITCH_TIME = 0.2
const CAMERA_MOVEMENT = 5
const DISTANCE_TO_CAMERA = 50

var x = 0
var y = 0
var z = 0

var camera_modes = ["free_mode", "following_mode"]
var current_camera_mode = 0

var hologram_on = true
 
onready var defaultSize = OS.get_window_size()
onready var CurrentSize = OS.get_window_size()
onready var Scale = CurrentSize / defaultSize
onready var PreviousSize = CurrentSize
 
var ignore_Y = false
var ignore_X = false

func init_viewports():
	playerSceneInstance = playerScene.instance();
	# playerSceneInstance2 = playerScene2.instance();
	self.add_child(playerSceneInstance);
	# Get the cameras
	camera_top = playerSceneInstance.get_node("Viewport_neg_z/Camera")
	camera_bottom = playerSceneInstance.get_node("Viewport_poz_z/Camera")
	camera_right = playerSceneInstance.get_node("Viewport_poz_x/Camera")
	camera_left = playerSceneInstance.get_node("Viewport_neg_x/Camera")
	
	# Assign the sprite's texture to the viewport texture
	camera_top.get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	camera_bottom.get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	camera_right.get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	camera_left.get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	
	viewport_sprite_top = get_node("Sprite")
	viewport_sprite_bottom = get_node("Sprite2")
	viewport_sprite_right = get_node("Sprite3")
	viewport_sprite_left = get_node("Sprite4")
	
	viewport_sprite_top.texture = camera_top.get_viewport().get_texture()
	viewport_sprite_bottom.texture = camera_bottom.get_viewport().get_texture()
	viewport_sprite_right.texture = camera_right.get_viewport().get_texture()
	viewport_sprite_left.texture = camera_left.get_viewport().get_texture()
	
	var output_rect = get_node("MeshInstance2D")
	var output_rect_mat = output_rect.get_material()
	print(output_rect_mat)
	output_rect_mat.set_shader_param("top", viewport_sprite_top.texture)
	output_rect_mat.set_shader_param("right", viewport_sprite_right.texture)
	output_rect_mat.set_shader_param("bottom", viewport_sprite_bottom.texture)
	output_rect_mat.set_shader_param("left", viewport_sprite_left.texture)

func _ready():
	# Get the 2D sprite
	# Get a shared player scene instance
	init_viewports()


func _process(_delta):
	CurrentSize = OS.get_window_size()
	Scale = CurrentSize / defaultSize
 
	if CurrentSize.x != PreviousSize.x && ignore_X == false:#Tests if the window is being resized in the x axis and not the y
		OS.set_window_size(Vector2(CurrentSize.x, defaultSize.y * Scale.x))#Scales the y axis by the same factor as x
		ignore_Y = true#Makes sure both pieces of code dont run at the same time
	elif CurrentSize.x == PreviousSize.x && ignore_X == true:#Stops ignoring X
		ignore_X = false
 
	if CurrentSize.y != PreviousSize.y && ignore_Y == false:#Tests if the window is being resized in the y axis and not the x
		OS.set_window_size(Vector2(defaultSize.x * Scale.y, CurrentSize.y))#Scales the x axis by the same factor as y
		ignore_X = true#Makes sure both pieces of code dont run at the same time
	elif CurrentSize.y == PreviousSize.y && ignore_Y == true:#Stops ignoring Y
		ignore_Y = false
 
	if OS.get_window_position().y < 0:#Prevents the title bar from going off screen
		OS.set_window_position(Vector2(OS.get_window_position().x, 0))
 
	if CurrentSize < defaultSize / 4:#Prevents the window from being too small
		OS.set_window_size(defaultSize / 4)
 
	PreviousSize = CurrentSize #This line MUST go at the end
	
	if not hologram_on:
		init_viewports()
		
	camera_top = playerSceneInstance.get_node("Viewport_neg_z/Camera")
	camera_bottom = playerSceneInstance.get_node("Viewport_poz_z/Camera")
	camera_right = playerSceneInstance.get_node("Viewport_poz_x/Camera")
	camera_left = playerSceneInstance.get_node("Viewport_neg_x/Camera")
	
	if Input.is_action_just_pressed("ui_select"):
		current_camera_mode = (current_camera_mode + 1) % len(camera_modes)
	
	if Input.is_action_pressed("camera_front"):
		z = CAMERA_MOVEMENT 
	elif Input.is_action_pressed("camera_back"):
		z = -CAMERA_MOVEMENT
	else:
		z = 0

	if Input.is_action_pressed("camera_up"):
		y = CAMERA_MOVEMENT
	elif Input.is_action_pressed("camera_down"):
		y = -CAMERA_MOVEMENT
	else:
		y = 0
	#	v.x = lerp(v.x, 0, 0.1)
	if Input.is_action_pressed("camera_left"):
		x = -CAMERA_MOVEMENT
	elif Input.is_action_pressed("camera_right"):
		x = CAMERA_MOVEMENT
	else:
		x = 0
	
	if Input.is_action_just_pressed("ui_accept"):
		print("in hologram scene")
		get_tree().change_scene("res://Hologram.scn")
			
	camera_top.translate(Vector3(x,y,z) * _delta)
	camera_bottom.translate(Vector3(x,-y,-z) * _delta)
	camera_right.translate(Vector3(y,-z,-x) * _delta)
	camera_left.translate(Vector3(-y,-z,x) * _delta)
	
	#print(move * delta)
	
	
