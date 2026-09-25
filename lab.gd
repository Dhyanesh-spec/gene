extends Control
var CreatureGen = preload("res://creature_gen.gd").new()
var TraitDatabase = preload("res://traitdatabase.gd").new()
var GeneCard = preload("res://genecard.tscn")
var flicker_speed = 0
@onready var professor = $ProfessorChat
var synthesizing = false
var alarm_acknowledged = false
var loading_progress = 0.0
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
	$Console/LoadingBar.visible = false
	$Console/LoadingLabel.visible = false
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
func update_professor_context() -> void:

	var traits := []

	var mobility := 0
	var defense := 0
	var endurance := 0
	var fat_storage := 0
	var thermoregulation := 0

	for trait_id in selected_traits:

		var data = TraitDatabase.TRAIT_DATABASE[trait_id]

		traits.append(data["name"])

		var gameplay = data["gameplay"]

		mobility += gameplay.get("mobility", 0)
		defense += gameplay.get("defense", 0)
		endurance += gameplay.get("endurance", 0)
		fat_storage += gameplay.get("fat_storage", 0)
		thermoregulation += gameplay.get("thermoregulation", 0)


	var context := {
		"selected_traits": traits,
		"genome": genome_sequence,
		"trait_count": selected_traits.size(),

		"mobility": mobility,
		"defense": defense,
		"endurance": endurance,
		"fat_storage": fat_storage,
		"thermoregulation": thermoregulation,

		"instability_level": selected_traits.size()
	}

	professor.set_lab_context(context)
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
	$Console/LoadingBar.value = 100

	await get_tree().create_timer(0.3).timeout


	var image = Image.new()

	var err = image.load(
		"res://generated_creature.png"
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
	loading_progress = 0

	$Console/LoadingBar.visible = true
	$Console/LoadingBar.value = 0
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
	await get_tree().create_timer(2.0).timeout
	clear_status()
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

	$Console/ScrollContainer2/VBoxContainer/Label.text = \
		"Species = " + data["species_name"]

	$Console/ScrollContainer2/VBoxContainer/Label2.text = \
		"Scientific Name = " + data["scientific_name"]

	$Console/ScrollContainer/RichTextLabel.text = \
		"Description = " + data["description"]
	$Console/ScrollContainer2/VBoxContainer/Label4.text = \
		"Habitat = " + data["habitat"]

	print("Metadata Loaded")
func update_instability():

	var count = selected_traits.size()

	match count:

		0,1,2:

			flicker_speed = 0
			$Console/StatusLabel.visible = false

		3:

			if !alarm_acknowledged:

				flicker_speed = 1
				$Console/StatusLabel.visible = true
				$Console/StatusLabel.text = \
				"WARNING: GENOME INSTABILITY DETECTED"

		4:

			if !alarm_acknowledged:

				flicker_speed = 2
				$Console/StatusLabel.visible = true
				$Console/StatusLabel.text = \
				"CRITICAL: GENOME DEGRADATION"

		5:

			if !alarm_acknowledged:

				flicker_speed = 3
				$Console/StatusLabel.visible = true
				$Console/StatusLabel.text = \
				"CATASTROPHIC FAILURE RISK"
func _process(delta):

	if flicker_speed > 0 and not synthesizing:

		$ColorRect.visible = \
		sin(Time.get_ticks_msec() * 0.01 * flicker_speed) > 0

	else:

		$ColorRect.visible = false
	if synthesizing:

		loading_progress += delta * 20

		loading_progress = min(
			loading_progress,
			95
		)

		$Console/LoadingBar.value = loading_progress

		if loading_progress < 20:

			$Console/LoadingLabel.text = \
			"SEQUENCING GENOME..."

		elif loading_progress < 40:

			$Console/LoadingLabel.text = \
			"ANALYZING DNA..."

		elif loading_progress < 60:

			$Console/LoadingLabel.text = \
			"STABILIZING MUTATIONS..."

		elif loading_progress < 80:

			$Console/LoadingLabel.text = \
			"CONSTRUCTING ORGANISM..."

		elif loading_progress < 90:

			$Console/LoadingLabel.text = \
			"SYNTHESIZING LIFEFORM..."
		else:

			$Console/LoadingLabel.text = \
			""
			$Console/LoadingBar.visible = false
			
func remove_background(image: Image):

	image.convert(Image.FORMAT_RGBA8)

	for y in range(image.get_height()):
		for x in range(image.get_width()):

			var c = image.get_pixel(x, y)

			if c.r > 0.8 and c.g < 0.3 and c.b > 0.8:
				c.a = 0

			image.set_pixel(x, y, c)
func generate_creature():
	alarm_acknowledged = true
	flicker_speed = 0
	$ColorRect.visible = false
	synthesizing = true
	alarm_acknowledged = true


	print("SYNTHESIZE PRESSED")
	$Console/StatusLabel.visible = true
	$Console/StatusLabel.text = "SYNTHESIS IN PROGRESS..."
	$Console/Button.disabled = true
	var failure_chance = 0
	match selected_traits.size():

		0:
			failure_chance = 0

		1:
			failure_chance = 0

		2:
			failure_chance = 10

		3:
			failure_chance = 25

		4:
			failure_chance = 50

		5:
			failure_chance = 75
	var prompt = CreatureGen.build_prompt(
		"horse",
		selected_traits
	)

	print(prompt)

	var output = []
	if randi() % 100 < failure_chance:

		$Console/StatusLabel.visible = true
		$Console/StatusLabel.text = "GENOME COLLAPSE\nSYNTHESIS FAILED"

		$CreaturePreview.texture = null

		synthesizing = false
		$Console/Button.disabled = false

		return
	OS.execute(
		"python",
		[
			"generate_creature.py",
			prompt
		],
		output,
		true
	)
	loading_progress = 0

	$Console/LoadingBar.visible = true
	$Console/LoadingLabel.visible = true
	loaded_generated_creature()

	$Console/Button.disabled = false

	$Console/StatusLabel.text = ""

	await get_tree().create_timer(2.0).timeout

	clear_status()
func clear_status():

	$Console/StatusLabel.text = ""
	$Console/StatusLabel.visible = false
func add_gene(trait_id):

	if selected_traits.size() >= 5:
		return

	selected_traits.append(trait_id)

	var dna = TraitDatabase.TRAIT_DATABASE[trait_id]["dna"]

	await animate_dna_addition(dna)
	update_dna_visual()
	update_instability()
	update_stats()
	
	update_sources()
	update_professor_context()




func _on_button_pressed() -> void:
	print("BUTTON WORKS")
	generate_creature()
	
func _on_play_pressed() -> void:
	var total_mobility = 0
	
	for trait_id in selected_traits:
		var gameplay = TraitDatabase.TRAIT_DATABASE[trait_id]["gameplay"]
		if gameplay.has("mobility"):
			total_mobility += gameplay["mobility"]
	
	GlobalData.current_creature_speed = 200.0 + (total_mobility * 10.0)
	get_tree().change_scene_to_file("res://main.tscn")
