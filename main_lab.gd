extends Control

# Reference interaction buttons

@onready var button_splice: TextureButton = $main/ButtonSplice
@onready var desk_button: Button = $Button

func _ready() -> void:
	# Hide all interaction buttons when the scene starts
	
	button_splice.hide()
	desk_button.hide()

# ==========================================
# PROFESSOR / DOC INTERACTION
# ==========================================


func _on_button_professor_pressed() -> void:
	get_tree().change_scene_to_file("res://chat_bot.tscn")	
# ==========================================
# GENE SPLICING INTERACTION (splice)
# ==========================================
func _on_splice_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		button_splice.show()

func _on_splice_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		button_splice.hide()

func _on_button_splice_pressed() -> void:
	get_tree().change_scene_to_file("res://lab.tscn")

# ==========================================
# DESK ZONE INTERACTION
# ==========================================
func _on_desk_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		desk_button.show()

func _on_desk_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		desk_button.hide()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://lab.tscn")
