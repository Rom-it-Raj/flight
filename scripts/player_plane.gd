extends CharacterBody3D

@export var MAX_SPEED := 80.0
@export var MIN_SPEED := 20.0
@export var acceleration := 15.5
@export var decceleration := 10.5
@export var current_speed := 50.0

@export var yaw_speed := 45.0
@export var pitch_speed := 45.0
@export var roll_speed := 45.0

@onready var prop = $plane_model/engine_left
@onready var prop2 = $plane_model/engine_right
@onready var plane_mesh = $plane_model

var turn_input =  Vector2()

func _ready() -> void:
	pitch_speed = deg_to_rad(pitch_speed)
	yaw_speed = deg_to_rad(yaw_speed)
	roll_speed = deg_to_rad(roll_speed)


func _physics_process(delta: float) -> void:
	var input = Input.get_vector("ui_left","ui_right","ui_down","ui_up")
	var roll = Input.get_axis("roll_left","roll_right")
	var power = Input.get_axis("ui_page_down", "ui_page_up")
	if power > 0 and current_speed < MAX_SPEED:
		current_speed += acceleration * delta
	elif power < 0 and current_speed > MIN_SPEED:
		current_speed -= decceleration * delta
	velocity = basis.z * current_speed
	move_and_slide()
	var turn_dir = Vector3(-input.y,-input.x,-roll)
	apply_rotation(turn_dir,delta)
	spin_propellor(delta)

func apply_rotation(vector,delta):
	rotate(basis.z,vector.z * roll_speed * delta)
	rotate(basis.x,vector.x * pitch_speed * delta)
	rotate(basis.y,vector.y * yaw_speed * delta)
	#lean mesh
	if vector.y < 0:
		plane_mesh.rotation.z = lerp_angle(plane_mesh.rotation.z, deg_to_rad(-45)*-vector.y,delta)
	elif vector.y > 0:
		plane_mesh.rotation.z = lerp_angle(plane_mesh.rotation.z, deg_to_rad(45)*vector.y,delta)
	else:
		plane_mesh.rotation.z = lerp_angle(plane_mesh.rotation.z, 0,delta)


func spin_propellor(delta):
	var m = current_speed/MAX_SPEED
	prop.rotate_z(150*delta*m)
	if prop.rotation.z > TAU:
		prop.rotation.z = 0
