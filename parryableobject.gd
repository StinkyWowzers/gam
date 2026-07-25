extends Area2D

@export var bounce_force := 500.0

@onready var sprite = $AnimatedSprite2D


func _ready():
	if sprite:
		sprite.play("idle")


func _on_body_entered(body):

	if !body.is_in_group("player"):
		return

	# Only works if the player is currently parrying
	if body.parrying:

		# Tell the player a parry succeeded
		body.successful_parry = true
		body.parrying = false

		# Freeze frame
		Engine.time_scale = 0.05
		await get_tree().create_timer(0.05, true).timeout
		Engine.time_scale = 1.0

		# Launch the player away
		var dir = (body.global_position - global_position).normalized()
		body.launch_timer = body.launch_time
		body.velocity = dir * bounce_force

		# Play the player's parry animation
		body.sprite.play("parry")

		await body.sprite.animation_finished

		body.attacking = false
