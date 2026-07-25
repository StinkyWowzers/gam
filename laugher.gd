extends Area2D

@export var horse_scene: PackedScene
@export var horse_spawn_offset := Vector2(0, -50)

@onready var sprite = $AnimatedSprite2D
@onready var laugh_sound = $LaughSound

var activated := false


func _ready():

	sprite.play("idle")

	body_entered.connect(_on_body_entered)


func _on_body_entered(body):

	if activated:
		return

	if !body.is_in_group("player"):
		return

	activated = true

	sprite.play("start-up")

	await sprite.animation_finished

	sprite.play("laughing")

	# Play the loud laugh
	laugh_sound.play()

	spawn_horse()

	await get_tree().create_timer(1.0).timeout

	queue_free()


func spawn_horse():

	if horse_scene == null:
		return

	var horse = horse_scene.instantiate()

	get_parent().add_child(horse)

	horse.global_position = global_position + horse_spawn_offset
