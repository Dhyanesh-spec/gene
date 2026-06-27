extends Node2D

func _ready():

	var bg_size = $TextureRect.size
	var viewport = get_viewport_rect().size

	$MapColliders.scale = Vector2(1.6545138, 1.438271)


func _on_bush_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
