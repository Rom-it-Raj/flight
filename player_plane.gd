extends RigidBody3D

# Player 1 Controls - Primary Systems
var p1_thrust_key = KEY_W
var p1_brake_key = KEY_S
var p1_roll_left = KEY_A
var p1_roll_right = KEY_D
var p1_pitch_up = KEY_Q
var p1_pitch_down = KEY_E

# Player 2 Controls - Secondary Systems
var p2_throttle_up = KEY_UP
var p2_throttle_down = KEY_DOWN
var p2_yaw_left = KEY_LEFT
var p2_yaw_right = KEY_RIGHT
var p2_flaps_up = KEY_PAGEUP
var p2_flaps_down = KEY_PAGEDOWN

# Weapon Controls (Interdependent - both must press)
var p1_fire_key = KEY_SPACE
var p2_fire_key = KEY_ENTER

# Physics Properties
var max_thrust = 80.0
var current_thrust = 0.0
var brake_power = 40.0
var roll_torque = 15.0
var pitch_torque = 10.0
var yaw_torque = 8.0
var flaps_lift_boost = 1.5
var current_flaps_factor = 1.0
var max_speed = 120.0

# Rotation Stabilization
var stability_torque = 5.0
var max_rotation_speed = 2.0

# Bullet System
var bullet_scene = preload("res://Bullet.tscn")
var fire_rate = 0.2
var last_fire_time = 0.0
var muzzle_speed = 100.0
var bullet_damage = 10

func _ready():
	mass = 2.0
	linear_damp = 0.1
	angular_damp = 0.5

func _physics_process(delta):
	process_input(delta)
	update_systems(delta)
	apply_movement(delta)
	apply_rotation_stabilization(delta)
	limit_speed()
	process_firing(delta)

func process_input(delta):
	# Player 1 controls
	var p1_thrust = Input.is_key_pressed(p1_thrust_key)
	var p1_brake = Input.is_key_pressed(p1_brake_key)
	
	# Player 2 throttle control (requires P1 to engage thrust)
	var p2_throttle_up = Input.is_key_pressed(p2_throttle_up)
	var p2_throttle_down = Input.is_key_pressed(p2_throttle_down)
	
	# Thrust control (interdependent)
	if p1_thrust:
		if p2_throttle_up and current_thrust < max_thrust:
			current_thrust += 40.0 * delta
		elif p2_throttle_down and current_thrust > 0.0:
			current_thrust -= 40.0 * delta
	else:
		current_thrust = max(0.0, current_thrust - 50.0 * delta)
	
	# Braking system with flaps assist
	if p1_brake:
		var brake_multiplier = 1.3 if Input.is_key_pressed(p2_flaps_down) else 1.0
		apply_central_force(-linear_velocity.normalized() * brake_power * brake_multiplier)
	
	# Flaps control
	if Input.is_key_pressed(p2_flaps_up) and current_flaps_factor < flaps_lift_boost:
		current_flaps_factor += 0.5 * delta
	elif Input.is_key_pressed(p2_flaps_down) and current_flaps_factor > 0.7:
		current_flaps_factor -= 0.5 * delta

func update_systems(delta):
	# Roll (Player 1)
	var roll_input = int(Input.is_key_pressed(p1_roll_right)) - int(Input.is_key_pressed(p1_roll_left))
	if roll_input != 0:
		apply_torque_impulse(-transform.basis.x * roll_input * roll_torque * delta)
	
	# Pitch (Player 1)
	var pitch_input = int(Input.is_key_pressed(p1_pitch_up)) - int(Input.is_key_pressed(p1_pitch_down))
	if pitch_input != 0:
		apply_torque_impulse(transform.basis.z * pitch_input * pitch_torque * delta)
	
	# Yaw (Player 2)
	var yaw_input = int(Input.is_key_pressed(p2_yaw_right)) - int(Input.is_key_pressed(p2_yaw_left))
	if yaw_input != 0:
		apply_torque_impulse(transform.basis.y * yaw_input * yaw_torque * delta)
	
	# Lift system (affected by flaps)
	var lift_force = Vector3.UP * current_flaps_factor * min(current_thrust, max_thrust) * 0.5
	if lift_force.length() > 0:
		apply_central_force(lift_force.rotated(transform.basis.x, rotation.x))

func apply_movement(delta):
	# Apply thrust in forward direction
	if current_thrust > 0.0:
		apply_central_force(-transform.basis.z * current_thrust)

func apply_rotation_stabilization(delta):
	# Auto-level the plane when not actively rolling
	var roll_input = int(Input.is_key_pressed(p1_roll_right)) - int(Input.is_key_pressed(p1_roll_left))
	if roll_input == 0:
		# Apply counter-torque to reduce roll
		var roll_stabilization = -rotation.x * stability_torque
		apply_torque_impulse(-transform.basis.x * roll_stabilization * delta)
	
	# Limit rotation speed
	if angular_velocity.length() > max_rotation_speed:
		angular_velocity = angular_velocity.normalized() * max_rotation_speed

func limit_speed():
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func process_firing(delta):
	last_fire_time += delta
	# Require both players to press fire buttons simultaneously
	if Input.is_key_pressed(p1_fire_key) and Input.is_key_pressed(p2_fire_key):
		if last_fire_time >= fire_rate:
			fire_bullet()
			last_fire_time = 0.0

func fire_bullet():
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		
		# Position bullet at plane's nose (use Marker3D or approximate position)
		var muzzle_offset = Vector3(0, 0, -2)  # Adjust based on your plane model
		bullet.global_position = global_position + -transform.basis.z * 2.0
		
		# Set bullet direction to plane's forward vector with added velocity
		bullet.direction = -transform.basis.z.normalized() * muzzle_speed + linear_velocity
		bullet.damage = bullet_damage
		
		# Add to scene
		get_tree().root.add_child(bullet)

# Optional: Damage system for the plane itself
func take_damage(amount):
	# Add your damage handling logic here
	print("Plane took ", amount, " damage!")
	# Example: reduce thrust capability, visual damage, etc.
