extends CanvasLayer
func _ready() -> void:
	# This runs the exact second your menu boots up on screen
	$MenuMusic.play()

func _on_play_button_pressed() -> void:
	var scene_path = "res://lab.tscn"

	print("Exists:", FileAccess.file_exists(scene_path))

	var err = get_tree().change_scene_to_file(scene_path)
	print("Error:", err)
func _on_quit_button_pressed() -> void:
	# This closes Variant Zero cleanly when quit is clicked
	get_tree().quit()

func _on_credit_button_pressed() -> void:
	# This prints a message to your debugger console at the bottom
	print("Variant Zero - Developed by Shalom and Dhyanesh!")
	
