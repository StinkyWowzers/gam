extends Area2D

@export var acceleration := 350.0
@export var max_speed := 250.0
@export var friction := 0.98

var velocity := Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $AnimatedSprite2D


func _ready():
	sprite.play("default") # Replace "move" with your animation name


func _physics_process(delta):

	if player == null:
		return

	var direction = (player.global_position - global_position).normalized()

	# Accelerate toward the player
	velocity += direction * acceleration * delta

	# Ice physics
	velocity *= friction

	# Cap speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	global_position += velocity * delta

	# Face the player
	sprite.flip_h = player.global_position.x < global_position.x

func _on_body_entered(body):

	if body.is_in_group("player"):

		if body.ground_pounding:

			# Freeze frame
			body.velocity.x = 0
			body.velocity.y = body.bounce_velocity
			body.ground_pounding = false

			Engine.time_scale = 0.05
			await get_tree().create_timer(0.05, true).timeout
			Engine.time_scale = 1.0

		else:

			body.hurt_player(self)
