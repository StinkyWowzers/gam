extends StaticBody2D

@onready var collision = $CollisionShape2D
@onready var break_sound = $BreakSound
@export var particle_scene : PackedScene

var broken := false


func break_block():

	if broken:
		return

	broken = true

	collision.disabled = true
	visible = false

	# Spawn particles
	if particle_scene:

		var particles = particle_scene.instantiate()

		get_parent().add_child(particles)
		particles.global_position = global_position
		particles.explode()

	# Play sound
	if break_sound:
		break_sound.reparent(get_parent())
		break_sound.global_position = global_position
		break_sound.play()

		await break_sound.finished

		break_sound.queue_free()

	queue_free()
