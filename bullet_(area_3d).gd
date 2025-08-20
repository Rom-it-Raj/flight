extends Area3D

# Bullet properties
var speed = 80.0
var damage = 10
var lifetime = 3.0
var direction = Vector3.FORWARD

func _ready():
	# Automatically delete after lifetime expires
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# Move bullet in its direction
	global_translate(direction * delta)

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()  # Destroy bullet on hit
