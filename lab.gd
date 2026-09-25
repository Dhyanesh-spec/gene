extends Control

# ============================================================
# VARIANT ZERO - LAB CORE
#
# Lab responsibilities:
#   1. Receive gene selections from GeneTree
#   2. Keep track of selected traits
#   3. Send real genomic loci to ChromosomeMap
#
# NOT handled here:
#   - Creature generation
#   - Creature preview
#   - Metadata
#   - Loading bars
#   - Synthesis
#   - Old DNA UI
#   - Old GeneCard UI
#   - Organism generation
# ============================================================

var gene_context_panel: Control = null
var TraitDatabase = preload("res://traitdatabase.gd").new()

var gene_tree: Tree
var chromosome_map: Node

var selected_traits: Array[String] = []
@onready var creature_preview: TextureRect = find_child(
	"CreaturePreview",
	true,
	false
) as TextureRect


@onready var generate_button: BaseButton = find_child(
	"GenerateButton",
	true,
	false
)

func _ready() -> void:

	gene_tree = find_child(
		"GeneTree",
		true,
		false
	) as Tree

	chromosome_map = find_child(
		"ChromosomeMap",
		true,
		false
	)



	generate_button = find_child(
		"TextureButton",
		true,
		false
	) as BaseButton


	# -----------------------------
	# GENE TREE
	# -----------------------------

	if gene_tree == null:

		push_error(
			"LAB ERROR: GeneTree NOT FOUND"
		)

	else:

		print(
			"LAB: GeneTree FOUND"
		)

		if gene_tree.has_signal(
			"gene_selected"
		):

			var gene_callback := Callable(
				self,
				"_on_gene_selected"
			)

			if not gene_tree.is_connected(
				"gene_selected",
				gene_callback
			):

				gene_tree.connect(
					"gene_selected",
					gene_callback
				)

			print(
				"LAB: GeneTree signal connected"
			)

		else:

			push_error(
				"LAB ERROR: GeneTree has no gene_selected signal"
			)


	# -----------------------------
	# CHROMOSOME MAP
	# -----------------------------

	if chromosome_map == null:

		push_error(
			"LAB ERROR: ChromosomeMap NOT FOUND"
		)

	else:

		print(
			"LAB: ChromosomeMap FOUND"
		)


	# -----------------------------
	# GENERATE BUTTON
	# -----------------------------

	if generate_button == null:

		push_error(
			"LAB ERROR: TextureButton NOT FOUND"
		)

	else:

		print(
			"LAB: TextureButton FOUND"
		)

		var button_callback := Callable(
			self,
			"_on_generate_pressed"
		)

		if not generate_button.is_connected(
			"pressed",
			button_callback
		):

			generate_button.connect(
				"pressed",
				button_callback
			)

			print(
				"LAB: Generate button connected"
			)


	print(
		"========== LAB CORE READY =========="
	)
func _on_generate_pressed() -> void:

	print("")
	print("========================================")
	print("GENERATE BUTTON PRESSED")
	print("========================================")

	print(
		"Selected genes: ",
		selected_traits
	)

	if selected_traits.is_empty():
		print("FAILURE: NO GENES SELECTED")
		push_error(
			"Cannot generate creature: no genes selected."
		)
		return

	print("Building creature prompt...")

	var prompt := build_creature_prompt()

	print("")
	print("------------- FINAL PROMPT -------------")
	print(prompt)
	print("----------------------------------------")
	print("")

	var output := []

	print("Calling generate_creature.py...")

	var exit_code := OS.execute(
		"python",
		[
			"generate_creature.py",
			prompt
		],
		output,
		true
	)

	print("Python exit code: ", exit_code)
	print("Python output: ", output)

	if exit_code != 0:
		push_error(
			"CREATURE GENERATION FAILED"
		)

		print(
			"ERROR: generate_creature.py returned ",
			exit_code
		)

		return

	print("CREATURE GENERATION SUCCESSFUL")
	print("Loading generated creature...")

	load_generated_creature()

	print("========================================")
func load_generated_creature() -> void:

	if creature_preview == null:
		push_error(
			"CreaturePreview node was not found."
		)
		return

	var image := Image.new()

	var error := image.load(
		"res://generated_creature.png"
	)

	if error != OK:
		push_error(
			"Could not load res://generated_creature.png"
		)
		print(
			"Image load error code: ",
			error
		)
		return

	print(
		"Generated image loaded successfully."
	)

	# Remove the magenta background if your generator
	# still produces it.
	remove_background(image)

	var texture := ImageTexture.create_from_image(
		image
	)

	creature_preview.texture = texture

	print(
		"CreaturePreview updated successfully."
	)
func remove_background(
	image: Image
) -> void:

	image.convert(
		Image.FORMAT_RGBA8
	)

	for y in range(
		image.get_height()
	):

		for x in range(
			image.get_width()
		):

			var pixel := image.get_pixel(
				x,
				y
			)

			if (
				pixel.r > 0.8
				and pixel.g < 0.3
				and pixel.b > 0.8
			):

				pixel.a = 0.0

			image.set_pixel(
				x,
				y,
				pixel
			)
func build_creature_prompt() -> String:

	var prompt := ""

	prompt += """
Create one pixel art of biologically coherent organism based on a domestic dog.

The organism must integrate all selected genetic traits into
one anatomically and physiologically consistent body.

SELECTED GENETIC TRAITS:
"""


	for i in range(
		selected_traits.size()
	):

		var trait_id := selected_traits[i]

		if not TraitDatabase.TRAIT_DATABASE.has(
			trait_id
		):
			continue

		var data: Dictionary = (
			TraitDatabase.TRAIT_DATABASE[
				trait_id
			]
		)


		var name := str(
			data.get(
				"name",
				trait_id
			)
		)

		var description := str(
			data.get(
				"description",
				""
			)
		)


		prompt += "\n"

		prompt += (
			"Trait "
			+ str(i + 1)
			+ ": "
			+ name
			+ "\n"
		)


		if description != "":

			prompt += (
				"Biological effect: "
				+ description
				+ "\n"
			)


		var gameplay: Dictionary = (
			data.get(
				"gameplay",
				{}
			)
		)


		if not gameplay.is_empty():

			prompt += (
				"Functional effects: "
			)

			var effects: Array[String] = []

			for key in gameplay.keys():

				var value = gameplay[key]

				if value != 0:

					effects.append(
						str(key)
						+ " "
						+ str(value)
					)

			prompt += (
				", ".join(effects)
				+ "\n"
			)


	prompt += """

BIOLOGICAL RULES:

- Produce one single organism.
- Preserve canine anatomy as the base.
- Integrate every selected trait.
- Do not paste unrelated animal body parts onto the dog.
- Avoid duplicate limbs or impossible anatomy.
- Make skeletal, muscular, respiratory and integumentary systems
  internally consistent.
- Every selected trait must have a visible or physiological effect.
- The final organism must look biologically coherent.
"""

	return prompt
func _on_gene_selected(
	trait_id: String,
	gene_data: Dictionary
) -> void:

	add_gene(
		trait_id,
		gene_data
	)


func add_gene(
	trait_id: String,
	gene_data: Dictionary
) -> void:

	if selected_traits.size() >= 5:
		return

	if trait_id in selected_traits:
		return

	if not TraitDatabase.TRAIT_DATABASE.has(
		trait_id
	):
		return

	selected_traits.append(
		trait_id
	)

	var trait_data: Dictionary = (
		TraitDatabase.TRAIT_DATABASE[
			trait_id
		]
	)

	var gene_name := str(
		trait_data.get(
			"name",
			trait_id
		)
	)

	print(
		"GENE ADDED: ",
		gene_name
	)

	# Orange marker
	if chromosome_map != null:
		if chromosome_map.has_method(
			"show_gene_marker"
		):
			chromosome_map.show_gene_marker()

	# Separate information panel
	update_gene_context(
		trait_id,
		gene_data
	)
func update_gene_context(
	trait_id: String,
	gene_data: Dictionary
) -> void:

	if gene_context_panel == null:
		return

	var data: Dictionary = gene_data

	if data.is_empty():
		data = TraitDatabase.TRAIT_DATABASE.get(
			trait_id,
			{}
		)

	var name := str(
		data.get(
			"name",
			trait_id
		)
	)

	var description := str(
		data.get(
			"description",
			"No description available."
		)
	)

	var category := str(
		data.get(
			"category",
			"GENETIC TRAIT"
		)
	)

	var chromosome := str(
		data.get(
			"chromosome",
			"Unmapped"
		)
	)

	var source_text := "Unknown"

	var sources = data.get(
		"source_animals",
		[]
	)

	if sources is Array and not sources.is_empty():
		source_text = str(
			sources[0]
		)

	var name_label = gene_context_panel.find_child(
		"GeneName",
		true,
		false
	)

	var description_label = gene_context_panel.find_child(
		"GeneDescription",
		true,
		false
	)

	var category_label = gene_context_panel.find_child(
		"GeneFunction",
		true,
		false
	)

	var chromosome_label = gene_context_panel.find_child(
		"GeneChromosome",
		true,
		false
	)

	var source_label = gene_context_panel.find_child(
		"GeneSource",
		true,
		false
	)

	if name_label:
		name_label.text = name

	if description_label:
		description_label.text = description

	if category_label:
		category_label.text = (
			"FUNCTION: " + category
		)

	if chromosome_label:
		chromosome_label.text = (
			"CHROMOSOME: " + chromosome
		)

	if source_label:
		source_label.text = (
			"SOURCE: " + source_text
		)

# ============================================================
# CHROMOSOME MAP
# ============================================================

func send_gene_to_chromosome_map(
	trait_id: String,
	gene_data: Dictionary
) -> void:

	if chromosome_map == null:
		return

	if not chromosome_map.has_method(
		"add_gene"
	):
		push_error(
			"ChromosomeMap is missing add_gene()."
		)
		return

	var loci := get_gene_loci(
		trait_id,
		gene_data
	)

	for locus in loci:
		chromosome_map.call(
			"add_gene",
			locus
		)


# ============================================================
# GET REAL GENOMIC LOCATIONS
#
# Supported TraitDatabase formats:
#
# OPTION 1 - multiple genes:
#
# "genomic_loci": [
#     {
#         "name": "MC1R",
#         "chromosome": 5,
#         "start": 63922271,
#         "end": 63923224,
#         "mode": "addition"
#     }
# ]
#
# OPTION 2 - one gene:
#
# "chromosome": 5,
# "start": 63922271,
# "end": 63923224
# ============================================================

func get_gene_loci(
	trait_id: String,
	gene_data: Dictionary
) -> Array[Dictionary]:

	var loci: Array[Dictionary] = []

	var data: Dictionary = gene_data

	if data.is_empty():
		data = TraitDatabase.TRAIT_DATABASE.get(
			trait_id,
			{}
		)

	# TEST: MC1R
	if trait_id == "mc1r":

		loci.append({
			"name": "MC1R",
			"chromosome": 5,
			"start": 63922271,
			"end": 63923224,
			"mode": "addition"
		})

		return loci

	if data.has("genomic_loci"):

		var raw_loci = data["genomic_loci"]

		if raw_loci is Array:

			for raw_locus in raw_loci:

				if raw_locus is Dictionary:

					loci.append(
						normalize_locus(
							raw_locus,
							trait_id
						)
					)

		return loci

	if data.has("loci"):

		var raw_loci = data["loci"]

		if raw_loci is Array:

			for raw_locus in raw_loci:

				if raw_locus is Dictionary:

					loci.append(
						normalize_locus(
							raw_locus,
							trait_id
						)
					)

		return loci

	if (
		data.has("chromosome")
		and data.has("start")
	):

		loci.append(
			normalize_locus(
				data,
				trait_id
			)
		)

	return loci
# ============================================================
# NORMALIZE GENE DATA
# ============================================================

func normalize_locus(
	locus: Dictionary,
	trait_id: String
) -> Dictionary:

	var result: Dictionary = (
		locus.duplicate(true)
	)

	# Give the locus a display name.
	if not result.has(
		"name"
	):

		result["name"] = str(
			result.get(
				"gene_symbol",
				trait_id
			)
		)

	# Default = orange addition marker.
	if not result.has(
		"mode"
	):

		result["mode"] = "addition"

	return result
