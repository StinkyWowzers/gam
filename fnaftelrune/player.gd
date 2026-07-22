extends CharacterBody2D

@export var speed := 250.0
@export var jump_velocity := -450.0
@export var gravity := 1200.0
@export var dash_speed := 700.0
@export var dash_time := 0.18

# How long after leaving a platform you can still jump
@export var coyote_time := 0.12

# How long before landing a jump input is remembered
@export var jump_buffer_time := 0.12

@export var wall_jump_x := 350.0
@export var wall_jump_y := -450.0
@export var wall_jump_lock_time := 0.15
@export var max_health := 5
@export var dash_cooldown := 1.0
@export var parry_window := 0.15
@export var parry_knockback := 500.0

var parrying := false
var successful_parry := false
var attacking := false
var dash_cooldown_timer := 0.0

var health := 0
var invincible := false

var wall_jump_lock := 0.0

@onready var sprite = $AnimatedSprite2D
@export var afterimage_scene : PackedScene

var afterimage_timer := 0.0

@export var afterimage_interval := 0.03

@export var ground_pound_speed := 900.0
@export var bounce_velocity := -500.0
@export var ground_pound_cooldown := 0.3

var ground_pound_cooldown_timer := 0.0

var ground_pounding := false

var coyote_timer := 0.0
var jump_buffer_timer := 0.0

var was_on_floor := false

var dead := false
var hurt := false

var is_dashing := false
var can_dash := true
var dash_direction := Vector2.ZERO

func _ready():
	health = max_health

func _physics_process(delta):

	# ---------------- PARRY ----------------

	if Input.is_action_just_pressed("parry") \
	and !dead \
	and !hurt \
	and !attacking \
	and !parrying \
	and !ground_pounding:

		attacking = true
		parrying = true
		successful_parry = false

		sprite.play("attack")

		await get_tree().create_timer(parry_window).timeout

		parrying = false

		if !successful_parry:
			sprite.play("parry_miss")
			await sprite.animation_finished

		attacking = false

	# ---------------- GROUND POUND ----------------
	
	if ground_pound_cooldown_timer > 0:
		ground_pound_cooldown_timer -= delta

	if Input.is_action_just_pressed("down") \
	and !is_on_floor() \
	and !ground_pounding \
	and ground_pound_cooldown_timer <= 0 \
	and !dead \
	and !hurt \
	and !attacking \
	and !is_dashing:

		ground_pounding = true
		ground_pound_cooldown_timer = ground_pound_cooldown

		velocity.x = 0

	# ---------------- DASH COOLDOWN ----------------

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# ---------------- DASH ----------------

	if Input.is_action_just_pressed("dash") \
	and can_dash \
	and !is_dashing \
	and dash_cooldown_timer <= 0 \
	and !hurt \
	and !dead \
	and !attacking \
	and !ground_pounding:

		is_dashing = true
		can_dash = false
		dash_cooldown_timer = dash_cooldown

		var x = Input.get_axis("left", "right")

		if x != 0:
			dash_direction = Vector2(x, 0)
			sprite.flip_h = x < 0
		else:
			dash_direction = Vector2(-1 if sprite.flip_h else 1, 0)

		velocity = dash_direction * dash_speed

		await get_tree().create_timer(dash_time).timeout

		is_dashing = false

	# ---------------- WALL JUMP TIMER ----------------

	if wall_jump_lock > 0:
		wall_jump_lock -= delta

	# ---------------- DEAD ----------------

	if dead:

		if !is_on_floor():
			velocity.y += gravity * delta

		move_and_slide()
		return

	# ---------------- GRAVITY ----------------

	if ground_pounding:

		velocity.x = 0
		velocity.y = ground_pound_speed

	elif !is_dashing and !is_on_floor():

		velocity.y += gravity * delta

	# ---------------- COYOTE ----------------

	if is_on_floor():

		coyote_timer = coyote_time
		can_dash = true

	else:

		coyote_timer -= delta

	# ---------------- JUMP BUFFER ----------------

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# ---------------- JUMP ----------------

	if jump_buffer_timer > 0 \
	and !hurt \
	and !attacking \
	and !ground_pounding:

		if coyote_timer > 0:

			velocity.y = jump_velocity

			jump_buffer_timer = 0
			coyote_timer = 0

		elif is_on_wall():

			var wall_normal = get_wall_normal()

			velocity = Vector2(
				wall_normal.x * wall_jump_x,
				wall_jump_y
			)

			wall_jump_lock = wall_jump_lock_time

			sprite.flip_h = velocity.x < 0

			jump_buffer_timer = 0

	# ---------------- MOVEMENT ----------------

	var direction = Input.get_axis("left", "right")

	if !hurt \
	and !is_dashing \
	and !attacking \
	and !ground_pounding:

		if wall_jump_lock <= 0:
			velocity.x = direction * speed

	if direction != 0 and !is_dashing:
		sprite.flip_h = direction < 0

	# ---------------- AFTERIMAGES ----------------

	if is_dashing or ground_pounding:

		afterimage_timer -= delta

	if afterimage_timer <= 0:

		spawn_afterimage()

		afterimage_timer = afterimage_interval

	# ---------------- MOVE ----------------

	move_and_slide()

	# ---------------- LAND FROM GROUND POUND ----------------

	if ground_pounding and is_on_floor():

		ground_pounding = false
		velocity.y = 0

	# ---------------- ANIMATION ----------------

	update_animation()

	was_on_floor = is_on_floor()

func spawn_afterimage():

	if afterimage_scene == null:
		return

	var ghost = afterimage_scene.instantiate()

	get_parent().add_child(ghost)

	ghost.global_position = global_position

	ghost.texture = sprite.sprite_frames.get_frame_texture(
		sprite.animation,
		sprite.frame
	)

	ghost.flip_h = sprite.flip_h
	ghost.scale = sprite.scale

func update_animation():
	
	if ground_pounding:
		if sprite.animation != "ground_pound":
			sprite.play("ground_pound")
		return

	if dead:
		if sprite.animation != "die":
			sprite.play("die")
		return

	if hurt:
		if sprite.animation != "hurt":
			sprite.play("hurt")
		return

	if attacking or parrying:
		return

	if is_dashing:
		if sprite.animation != "dash":
			sprite.play("dash")
		return

	if is_on_floor() and !was_on_floor:
		sprite.play("land")
		return

	if !is_on_floor():

		if velocity.y < 0:
			if sprite.animation != "jump":
				sprite.play("jump")
		else:
			if sprite.animation != "fall":
				sprite.play("fall")

		return

	if abs(velocity.x) > 0:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")


func hurt_player(attacker):

	if parrying:

		successful_parry = true
		parrying = false

		Engine.time_scale = 0.05
		await get_tree().create_timer(0.05, true).timeout
		Engine.time_scale = 1.0

		var dir = (global_position - attacker.global_position).normalized()

		velocity = dir * parry_knockback

		if "velocity" in attacker:
			attacker.velocity = -dir * parry_knockback

		sprite.play("parry")

		await sprite.animation_finished

		attacking = false

		return

	if dead or hurt or invincible:
		return

	print(health - 1, "/", max_health)

	health -= 1

	if health <= 0:
		die()
		return

	hurt = true
	invincible = true

	sprite.modulate.a = 0.5

	sprite.play("hurt")

	await sprite.animation_finished

	hurt = false

	await get_tree().create_timer(0.75).timeout

	invincible = false
	sprite.modulate.a = 1.0


func die():

	if dead:
		return

	dead = true

	# Stop horizontal movement, but keep vertical velocity
	velocity.x = 0

	sprite.play("die")

	await sprite.animation_finished

	get_tree().reload_current_scene()
