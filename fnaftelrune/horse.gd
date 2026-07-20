extends Area2D

@export var speed := 1200.0

@onready var sprite = $AnimatedSprite2D

var player


func _ready():

	player = get_tree().get_first_node_in_group("player")

	sprite.play("run")

	body_entered.connect(_on_body_entered)


func _physics_process(delta):

	if player == null:
		return

	var direction = (
		player.global_position - global_position
	).normalized()

	global_position += direction * speed * delta

	sprite.flip_h = direction.x < 0


func _on_body_entered(body):

	if !body.is_in_group("player"):
		return

	# Only parry can stop the horse
	if body.parrying:

		# Small impact freeze
		Engine.time_scale = 0.05
		await get_tree().create_timer(0.05, true).timeout
		Engine.time_scale = 1.0

		queue_free()

		return


	body.die()
