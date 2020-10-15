extends VehicleBody

export var MAX_ENGINE_FORCE = 150.0
export var MAX_BRAKE_FORCE = 5.0
export var MAX_STEER_ANGLE = 0.5

export var steer_speed = 1.0

var steer_target = 0.0
var steer_angle = 0.0


var current_speed_mps = 0.0
var had_throttle_or_brake_input = false
var is_reverse = false
var last_pos = Vector3(0.0, 0.0, 0.0)


export var joy_steering = JOY_ANALOG_LX
export var steering_mult = -1.0
export var joy_throttle = JOY_ANALOG_R2
export var throttle_mult = 1.0
export var joy_brake = JOY_ANALOG_L2
export var brake_mult = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	current_speed_mps = (translation - last_pos).length() / delta
	
	var steer_val = steering_mult * Input.get_joy_axis(0, joy_steering)
	var throttle_val = throttle_mult * Input.get_joy_axis(0, joy_throttle)
	var brake_val = brake_mult * Input.get_joy_axis(0, joy_brake)
	
	if (throttle_val < 0.0):
		throttle_val = 0.0
	
	if (brake_val < 0.0):
		brake_val = 0.0
		
	if Input.is_action_pressed("ui_up"):
		throttle_val = 1.0
	if Input.is_action_pressed("ui_down"):
		brake_val = 1.0
	if Input.is_action_pressed("ui_left"):
		steer_val = 1.0
	elif Input.is_action_pressed("ui_right"):
		steer_val = -1.0
	
	# check if we need to be in reverse
	if (had_throttle_or_brake_input == false and brake_val > 0.0 and current_speed_mps < 1.0):
		print("Reversing")
		had_throttle_or_brake_input = true
		is_reverse = true
	elif (throttle_val > 0.0 or brake_val > 0.0):
		had_throttle_or_brake_input = true
	else:
		is_reverse = false
		had_throttle_or_brake_input = false
	
	# are we in reverse?
	if (is_reverse):
		var swap = throttle_val
		throttle_val = -brake_val
		brake_val = -swap
	elif (throttle_val == 0.0 and brake_val == 0.0 and current_speed_mps < 3.0):
		# if no throttle input, brake lightly
		brake_val = 0.1
	
	engine_force = throttle_val * MAX_ENGINE_FORCE
	brake = brake_val * MAX_BRAKE_FORCE
		
	steer_target = steer_val * MAX_STEER_ANGLE
	if (steer_target < steer_angle):
		steer_angle -= steer_speed * delta
		if (steer_target > steer_angle):
			steer_angle = steer_target
	elif (steer_target > steer_angle):
		steer_angle += steer_speed * delta
		if (steer_target < steer_angle):
			steer_angle = steer_target
			
	steering = steer_angle
	last_pos = translation
	
	
