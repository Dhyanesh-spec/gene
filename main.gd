extends Node2D

func _ready() -> void:
	# Optional: Set camera limits or start game audio here if needed
	pass

# Optional: Add general game inputs (e.g. Pause Menu or Quit)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Escape key by default
		get_tree().quit() # Or toggle pause menu
