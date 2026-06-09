extends PanelContainer

signal gene_selected(trait_id)

@export var gene_name : String = ""
@export var description : String = ""
@export var trait_id : String = ""
@export var icon_texture : Texture2D

@onready var icon_rect = $TextureRect/TextureRect2
@onready var name_label = $TextureRect/Label
@onready var desc_label = $TextureRect/Label2

func _ready():

	custom_minimum_size = Vector2(300, 120)

	name_label.text = gene_name
	desc_label.text = description

	if icon_texture:
		icon_rect.texture = icon_texture

	mouse_entered.connect(_hover)
	mouse_exited.connect(_unhover)


func setup(name_text, desc_text, texture = null, id = ""):

	gene_name = name_text
	description = desc_text
	trait_id = id

	if texture:
		icon_texture = texture

	# Update immediately after setup
	if is_node_ready():

		name_label.text = gene_name
		desc_label.text = description

		if icon_texture:
			icon_rect.texture = icon_texture


func _hover():

	scale = Vector2(1.03, 1.03)

	# Slight glow effect
	modulate = Color(1.1, 1.1, 1.1)


func _unhover():

	scale = Vector2.ONE
	modulate = Color.WHITE


func _gui_input(event):

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			gene_selected.emit(trait_id)
