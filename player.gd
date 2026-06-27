extends CharacterBody2D

@onready var creature_sprite = find_child("CreatureSprite")

var speed: float
var bob_time: float = 0.0
var base_scale: Vector2 = Vector2.ONE
var hunger = 100.0
var thirst = 100.0

var hunger_rate = 1.0
var thirst_rate = 2.0
func _ready():

	speed = GlobalData.current_creature_speed

	var path = "res://generated_creature.png"

	if ResourceLoader.exists(path):

		var tex = ResourceLoader.load(
			path,
			"Texture2D",
			ResourceLoader.CACHE_MODE_REPLACE
		)

		if creature_sprite != null:

			creature_sprite.texture = tex
			creature_sprite.centered = true

			var tex_size = tex.get_size()

			var target_size = 128.0

			var scale_factor = target_size / max(
				tex_size.x,
				tex_size.y
			)

			base_scale = Vector2(
				scale_factor,
				scale_factor
			)

			creature_sprite.scale = base_scale

			creature_sprite.offset.y = -(target_size / 2)

			print("Creature visual texture applied successfully!")

		else:

			print(
				"Error: CreatureSprite node is missing from the hierarchy."
			)
func _physics_process(delta):
	hunger -= hunger_rate * delta
	thirst -= thirst_rate * delta

	hunger = clamp(hunger, 0, 100)
	thirst = clamp(thirst, 0, 100)

	var direction_x = Input.get_axis(
		"ui_left",
		"ui_right"
)

	var direction_y = Input.get_axis(
		"ui_up",
		"ui_down"
)

	var direction = Vector2(
		direction_x,
		direction_y
)

	if direction != Vector2.ZERO:

		direction = direction.normalized()

		velocity = direction * speed

		if creature_sprite != null:

			if direction_x != 0:

				creature_sprite.flip_h = (
					direction_x < 0
			)

		# ==========================
		# WALKING BOB ANIMATION
		# ==========================

			bob_time += delta * (
				speed * 0.05
		)

			var squash = sin(
				bob_time
		) * 0.1

			creature_sprite.scale.x = (
				base_scale.x * (1.0 + squash)
		)

			creature_sprite.scale.y = (
				base_scale.y * (1.0 - squash)
		)

	else:

		velocity = velocity.move_toward(
			Vector2.ZERO,
			speed * 0.2
	)

		if creature_sprite != null:

			creature_sprite.scale.x = move_toward(
				creature_sprite.scale.x,
				base_scale.x,
				delta * 4
		)

			creature_sprite.scale.y = move_toward(
				creature_sprite.scale.y,
				base_scale.y,
				delta * 4
		)

			bob_time = 0.0

	move_and_slide()

	for i in range(get_slide_collision_count()):

		var collision = get_slide_collision(i)

		if collision:

			var collider = collision.get_collider()

			print(collider.name)

			if collider.name == "Lake":

				thirst = 100
				print("DRANK WATER")

	update_needs()
func update_needs():

	$ProgressBar.value = hunger
	$ProgressBar2.value = thirst
	if hunger < 25:
		$ProgressBar.modulate = Color.RED
	else:
		$ProgressBar.modulate = Color.GREEN

	if thirst < 25:
		$ProgressBar2.modulate = Color.RED
	else:
		$ProgressBar2.modulate = Color.CYAN
