extends Node2D

@export var min_wait := 4.0
@export var max_wait := 10.0

@export var min_stare := 2.0
@export var max_stare := 4.0

@onready var sprite = $AnimatedSprite2D
@onready var timer = $Timer
@onready var player = get_tree().get_first_node_in_group("player")

enum State {
	HIDDEN,
	APPEARING,
	WATCHING,
	LEAVING
}

var state = State.HIDDEN
var attacked := false


func _ready():

	sprite.visible = false

	randomize()

	start_wait()


func start_wait():

	state = State.HIDDEN
	attacked = false

	timer.start(randf_range(min_wait, max_wait))


func _on_timer_timeout():

	begin_watch()


func begin_watch():

	state = State.APPEARING

	sprite.visible = true
	sprite.play("appear")

	await sprite.animation_finished

	await get_tree().create_timer(0.5).timeout

	state = State.WATCHING
	sprite.play("stare")


	await get_tree().create_timer(
		randf_range(min_stare, max_stare)
	).timeout

	state = State.LEAVING

	sprite.play("leave")

	await sprite.animation_finished

	sprite.visible = false

	start_wait()


func _process(delta):

	if state != State.WATCHING:
		return

	if attacked:
		return

	if player == null:
		return

	var moving = (
		Input.get_axis("left", "right") != 0
		or Input.is_action_pressed("jump")
		or Input.is_action_pressed("dash")
		or Input.is_action_pressed("parry")
		or Input.is_action_pressed("down")
	)

	if moving:

		attacked = true

		player.hurt_player(self)
