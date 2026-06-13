extends Control
var CreatureGen = preload("res://creature_gen.gd").new()
var TraitDatabase = preload("res://traitdatabase.gd").new()
var GeneCard = preload("res://genecard.tscn")

@onready var creature_preview = $CreaturePreview
var selected_traits = []
var genome_sequence = ""
var dna_stages = [
	preload("res://dna_stable.png"),
	preload("res://dna_midlyunstable.png"),
	preload("res://dna_modified.png"),
	preload("res://dna_unstable.png"),
	preload("res://dna_severecorruption.png"),
	preload("res://dna_severecorruption.png"),
]
func _ready():

	for trait_id in TraitDatabase.TRAIT_DATABASE.keys():

		var data = TraitDatabase.TRAIT_DATABASE[trait_id]

		var card = GeneCard.instantiate()

		card.setup(
			data["name"],
			data["description"],
			data["icon"],
			trait_id
)
		card.gene_selected.connect(add_gene)
		$Genes/Scroller/genelist.add_child(card)
func load_generated_creature():

	var image = Image.new()

	var err = image.load("D:/Shalom Essentials/Game development/gene/generated_creature.png")

	if err != OK:
		print("Failed to load image")
		return

	var texture = ImageTexture.create_from_image(image)

	creature_preview.texture = texture

	print("Creature Loaded!")
func update_radar():

	var mobility = 0
	var defense = 0
	var endurance = 0
	var fat_reserve = 0
	var thermoregulation = 0

	for trait_id in selected_traits:

		var gameplay = TraitDatabase.TRAIT_DATABASE[trait_id]["gameplay"]

		mobility += gameplay.get("mobility", 0)
		defense += gameplay.get("defense", 0)
		endurance += gameplay.get("endurance", 0)
		fat_reserve += gameplay.get("fat_storage", 0)
		thermoregulation += gameplay.get("thermoregulation", 0)

	var radar = $Console/stats/VBoxContainer2/RadarChart

	radar.values = [
		mobility,
		defense,
		endurance,
		fat_reserve,
		thermoregulation
	]

	radar.queue_redraw()
func update_stats():

	var musculoskeletal = 0
	var integumentary = 0
	var respiratory = 0
	var thermoregulation = 0
	var fat_storage = 0
	for trait_id in selected_traits:

		var gameplay = TraitDatabase.TRAIT_DATABASE[trait_id]["gameplay"]

		if gameplay.has("mobility"):
			musculoskeletal += gameplay["mobility"]

		if gameplay.has("defense"):
			integumentary += gameplay["defense"]

		if gameplay.has("endurance"):
			respiratory += gameplay["endurance"]

		if gameplay.has("thermoregulation"):
			thermoregulation += gameplay["thermoregulation"]
		if gameplay.has("fat_storage"):
			fat_storage += gameplay["fat_storage"]

	$Console/stats/VBoxContainer2/VBoxContainer/Label.text = \
"Musculoskeletal: %d%%" % musculoskeletal

	$Console/stats/VBoxContainer2/VBoxContainer/Label2.text = \
"Respiratory: %d%%" % respiratory

	$Console/stats/VBoxContainer2/VBoxContainer/Label3.text = \
"Integumentary: %d%%" % integumentary

	$Console/stats/VBoxContainer2/VBoxContainer/Label5.text = \
"Thermoregulation: %d%%" % thermoregulation
	$Console/stats/VBoxContainer2/VBoxContainer/Label4.text = \
"Fat Reaserve: %d%%" % fat_storage
	update_radar()
func update_dna_visual():

	var stage = clamp(selected_traits.size(), 0, 6)

	$Console/DNASection/ScrollContainer/VBoxContainer2/TextureRect.texture = dna_stages[stage]
	match stage:

		0:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = "GENOME STABLE"

		1:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = "MINOR MUTATIONS"

		2:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = "GENOME MODIFIED"

		3:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = "GENOME UNSTABLE"

		4:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = "SEVERE DEGRADATION"

		5:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = "CRITICAL GENOME FAILURE"
		5:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = "GENE BREAKDOWN ACTIVATED"
func update_genome_display():

	var text = ""

	for letter in genome_sequence:

		match letter:

			"A":
				text += "[color=green]A[/color]"

			"T":
				text += "[color=red]T[/color]"

			"G":
				text += "[color=cyan]G[/color]"

			"C":
				text += "[color=yellow]C[/color]"

			"|":
				text += "[color=white] | [/color]"

	$Console/DNASection/ScrollContainer/VBoxContainer2/RichTextLabel.bbcode_enabled = true
	$Console/DNASection/ScrollContainer/VBoxContainer2/RichTextLabel.text = text

	$Console/DNASection/ScrollContainer/VBoxContainer2/Label.text = \
	"Traits: %d / 5" % selected_traits.size()

	update_dna_visual()
	update_sources()
func update_sources():

	var text = "Sources:\n"

	for trait_id in selected_traits:

		var data = TraitDatabase.TRAIT_DATABASE[trait_id]

		text += data["source_animals"][0] + "\n"

	$Console/DNASection/ScrollContainer/VBoxContainer2/VBoxContainer/Label.text = text

func animate_dna_addition(dna):

	for letter in dna:

		genome_sequence += letter

		update_genome_display()

		await get_tree().create_timer(0.05).timeout
func update_genome():

	genome_sequence = ""

	for trait_id in selected_traits:

		var dna = TraitDatabase.TRAIT_DATABASE[trait_id]["dna"]

		if genome_sequence != "":
			genome_sequence += "|"

		genome_sequence += dna

	update_genome_display()
func loaded_generated_creature():

	var image = Image.new()

	var err = image.load(
		"D:/Shalom Essentials/Game development/gene/generated_creature.png"
	)

	if err != OK:
		print("Failed to load image")
		return
	remove_background(image)
	var texture = ImageTexture.create_from_image(image)

	creature_preview.texture = texture

	print("Creature Loaded!")
	generate_metadata()
	load_metadata()
func generate_metadata():

	var trait_string = ""

	for trait_id in selected_traits:

		trait_string += \
		TraitDatabase.TRAIT_DATABASE[trait_id]["name"] + ", "

	var output = []

	OS.execute(
		"python",
		[
			"generate_metadata.py",
			trait_string
		],
		output,
		true
	)

	print(output)
func load_metadata():

	var file = FileAccess.open(
		"metadata.json",
		FileAccess.READ
	)

	if file == null:
		print("metadata.json not found")
		return

	var text = file.get_as_text()

	var data = JSON.parse_string(text)

	if data == null:
		print("JSON parse failed")
		print(text)
		return

	$Console/VBoxContainer/Label.text = \
		"Species = " + data["species_name"]

	$Console/VBoxContainer/Label2.text = \
		"Scientific Name = " + data["scientific_name"]

	$Console/ScrollContainer/RichTextLabel.text = \
		"Description = " + data["description"]
	$Console/VBoxContainer/Label4.text = \
		"Habitat = " + data["habitat"]

	print("Metadata Loaded")
func remove_background(image: Image):

	image.convert(Image.FORMAT_RGBA8)

	for y in range(image.get_height()):
		for x in range(image.get_width()):

			var c = image.get_pixel(x, y)

			if c.r > 0.8 and c.g < 0.3 and c.b > 0.8:
				c.a = 0

			image.set_pixel(x, y, c)
func generate_creature():

	print("SYNTHESIZE PRESSED")

	var prompt = CreatureGen.build_prompt(
		"horse",
		selected_traits
	)

	print(prompt)

	var output = []

	OS.execute(
		"python",
		[
			"generate_creature.py",
			prompt
		],
		output,
		true
	)

	print(output)

	loaded_generated_creature()
func add_gene(trait_id):

	if selected_traits.size() >= 5:
		return

	selected_traits.append(trait_id)

	var dna = TraitDatabase.TRAIT_DATABASE[trait_id]["dna"]

	await animate_dna_addition(dna)
	update_dna_visual()

	update_stats()
	update_sources()



func _on_button_pressed() -> void:
	print("BUTTON WORKS")
	generate_creature()
	
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
