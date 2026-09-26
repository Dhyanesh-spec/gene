extends CharacterBody2D

@export var speed: float = 120.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	# Read movement inputs (WASD or Arrow Keys)
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * speed
	move_and_slide()

	update_animation(input_dir)

func update_animation(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		animated_sprite.stop()
		return

	# Play walking animation and flip sprite horizontally when moving left
	animated_sprite.play("walk_right")
	if dir.x != 0:
		animated_sprite.flip_h = (dir.x < 0)
