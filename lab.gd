extends Control
var CreatureGen = preload("res://creature_gen.gd").new()
var TraitDatabase = preload("res://traitdatabase.gd").new()
var GeneCard = preload("res://genecard.tscn")

@onready var creature_preview = $CreaturePreview
var selected_traits = []
var genome_sequence = ""
var dna_stages = [
	preload("res://DNA/dna0.png"),
	preload("res://DNA/dna1.png"),
	preload("res://DNA/dna2.png"),
	preload("res://DNA/dna3.png"),
	preload("res://DNA/dna4.png"),
	preload("res://DNA/dna5.png")
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
func make_bar(value: int) -> String:

	var filled = int(value / 10)
	var empty = 10 - filled

	return "■".repeat(filled) + "□".repeat(empty)
func update_stats():

	var mobility = 0
	var defense = 0
	var endurance = 0
	var arid_adaptability = 0
	var cold_resistance = 0
	for trait_id in selected_traits:

		var gameplay = TraitDatabase.TRAIT_DATABASE[trait_id]["gameplay"]

		if gameplay.has("mobility"):
			mobility += gameplay["mobility"]

		if gameplay.has("defense"):
			defense += gameplay["defense"]

		if gameplay.has("endurance"):
			endurance += gameplay["endurance"]

		if gameplay.has("arid_adaptability"):
			arid_adaptability += gameplay["arid_adaptability"]
		if gameplay.has("cold_resistance"):
			cold_resistance += gameplay["cold_resistance"]

	$Console/stats/VBoxContainer/Label.text = \
	"MOBILITY\n" + make_bar(mobility)

	$Console/stats/VBoxContainer/Label2.text = \
	"DEFENSE\n" + make_bar(defense)

	$Console/stats/VBoxContainer/Label3.text = \
	"ENDURANCE\n" + make_bar(endurance)

	$Console/stats/VBoxContainer/Label4.text = \
	"ARID ADAPTABILITY\n" + make_bar(arid_adaptability)
	$Console/stats/VBoxContainer/Label5.text = \
	"COLD RESISTANCE\n" + make_bar(cold_resistance)
func update_dna_visual():

	var stage = selected_traits.size()

	$Console/DNASection/TextureRect.texture = dna_stages[stage]
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
	$Console/DNASection/GenomeSequence.bbcode_enabled = true
	$Console/DNASection/GenomeSequence.text = text

	$Console/DNASection/MutationCount.text = \
	"Traits: %d / 5" % selected_traits.size()
func update_genome():

	genome_sequence = ""

	for trait_id in selected_traits:

		var dna = TraitDatabase.TRAIT_DATABASE[trait_id]["dna"]

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

	var texture = ImageTexture.create_from_image(image)

	creature_preview.texture = texture

	print("Creature Loaded!")
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

	print("Clicked:", trait_id)

	if selected_traits.size() >= 5:
		return

	selected_traits.append(trait_id)
	print(
	CreatureGen.build_prompt(
		"horse",
		selected_traits
	)
)
	update_dna_visual()
	update_genome()
	update_stats()


func _on_button_pressed() -> void:
	print("BUTTON WORKS")
	generate_creature()
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
