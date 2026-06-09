extends CanvasLayer
func _ready() -> void:
	# This runs the exact second your menu boots up on screen
	$MenuMusic.play()

func _on_play_button_pressed() -> void:
	# This exits the menu and opens your top-down grass map!
	get_tree().change_scene_to_file("res://lab.tscn")

func _on_quit_button_pressed() -> void:
	# This closes Variant Zero cleanly when quit is clicked
	get_tree().quit()

func _on_credit_button_pressed() -> void:
	# This prints a message to your debugger console at the bottom
	print("Variant Zero - Developed by Shalom and Dhyanesh!")
	
