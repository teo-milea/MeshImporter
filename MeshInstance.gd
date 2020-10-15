extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var speed = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var x = 0
	var y = 0
	var z = 0
	if Input.is_action_pressed("ui_left"):
		x -= speed*delta;
	elif Input.is_action_pressed("ui_right"):
		x += speed*delta;
	elif Input.is_action_pressed("ui_down"):
		y -= speed*delta
	elif Input.is_action_pressed("ui_up"):
		y += speed*delta
	elif Input.is_action_pressed("ui_high"):
		z -= speed*delta
	elif Input.is_action_pressed("ui_low"):
		z += speed*delta
		
	translate(Vector3(x,y,z))
