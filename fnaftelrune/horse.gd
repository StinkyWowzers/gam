extends Area2D

@export var speed := 1200.0

@onready var sprite = $AnimatedSprite2D
@onready var horse_sound = $HorseSound

var player
var dying := false


func _ready():

	player = get_tree().get_first_node_in_group("player")

	sprite.play("run")

	horse_sound.play()

	body_entered.connect(_on_body_entered)


func _physics_process(delta):

	if dying:
		return

	if player == null:
		return

	var direction = (
		player.global_position - global_position
	).normalized()

	global_position += direction * speed * delta

	sprite.flip_h = direction.x < 0


func _on_body_entered(body):
	
	if dying:
		return

	if !body.is_in_group("player"):
		return

	# Successful parry
	if body.parrying:

		dying = true

		monitoring = false
		monitorable = false

		Engine.time_scale = 0.05
		await get_tree().create_timer(0.05, true).timeout
		Engine.time_scale = 1.0

		horse_sound.stop()

		sprite.play("death")

		await sprite.animation_finished

		queue_free()

		return

	# Horse always kills
	body.die()
