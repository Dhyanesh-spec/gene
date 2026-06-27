extends Area2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var timer = $Timer

func _on_body_entered(body):

	if body.name == "Player":

		body.hunger = min(body.hunger + 25, 100)

		sprite.visible = false
		collision.disabled = true

		timer.start()

func _on_timer_timeout():

	sprite.visible = true
	collision.disabled = false
