extends CharacterBody2D

@onready var creature_sprite = find_child("CreatureSprite")

var speed: float
var bob_time: float = 0.0

func _ready():
	speed = GlobalData.current_creature_speed
	
	var path = "res://generated_creature.png"
	
	if ResourceLoader.exists(path):
		var tex = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE)
		if creature_sprite != null:
			creature_sprite.texture = tex
			creature_sprite.centered = true
			creature_sprite.offset.y = -(tex.get_size().y / 2)
			print("Creature visual texture applied successfully!")
		else:
			print("Error: CreatureSprite node is missing from the hierarchy.")

func _physics_process(delta):
	var direction_x = Input.get_axis("ui_left", "ui_right")
	var direction_y = Input.get_axis("ui_up", "ui_down")
	var direction = Vector2(direction_x, direction_y)
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * speed
		
		if creature_sprite != null:
			if direction_x != 0:
				creature_sprite.flip_h = (direction_x < 0)
				
			bob_time += delta * (speed * 0.05)
			var squash = sin(bob_time) * 0.1
			creature_sprite.scale.x = 1.0 + squash
			creature_sprite.scale.y = 1.0 - squash
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 0.2)
		
		if creature_sprite != null:
			creature_sprite.scale.x = move_toward(creature_sprite.scale.x, 1.0, delta * 4)
			creature_sprite.scale.y = move_toward(creature_sprite.scale.y, 1.0, delta * 4)
			bob_time = 0.0

	move_and_slide()
