extends Control

var CreatureGen = preload("res://creature_gen.gd").new()
var TraitDatabase = preload("res://traitdatabase.gd").new()

var flicker_speed := 0
var synthesizing := false
var alarm_acknowledged := false
var loading_progress := 0.0

@onready var professor = $ProfessorChat
@onready var creature_preview = $CreaturePreview

var gene_tree: Tree = null
var chromosome_map: Node = null

var selected_traits: Array[String] = []
var genome_sequence := ""

var dna_stages = [
	preload("res://dna_stable.png"),
	preload("res://dna_midlyunstable.png"),
	preload("res://dna_modified.png"),
	preload("res://dna_unstable.png"),
	preload("res://dna_severecorruption.png"),
	preload("res://dna_severecorruption.png"),
]


func _ready() -> void:
	# Find these nodes anywhere under the Lab scene.
	# This avoids hard-coding the exact position of the panels.
	gene_tree = find_child("GeneTree", true, false) as Tree
	chromosome_map = find_child("ChromosomeMap", true, false)

	if gene_tree:
		if gene_tree.has_signal("gene_selected"):
			gene_tree.gene_selected.connect(_on_gene_selected)
	else:
		push_warning("GeneTree node was not found.")

	if chromosome_map == null:
		push_warning("ChromosomeMap node was not found.")


# ============================================================
# GENE SELECTION -> DNA + CHROMOSOME MAP
# ============================================================

func _on_gene_selected(trait_id: String, gene_data: Dictionary) -> void:
	add_gene(trait_id, gene_data)


func add_gene(
	trait_id: String,
	gene_data: Dictionary = {}
) -> void:

	if selected_traits.size() >= 5:
		print("Maximum of 5 genes/traits reached.")
		return

	if not TraitDatabase.TRAIT_DATABASE.has(trait_id):
		print("TraitDatabase does not contain: ", trait_id)
		return

	# Prevent the same gene/trait from being added twice.
	if trait_id in selected_traits:
		print("Already selected: ", trait_id)
		return

	selected_traits.append(trait_id)

	var dna = TraitDatabase.TRAIT_DATABASE[trait_id].get("dna", "")

	if dna != "":
		await animate_dna_addition(dna)

	update_dna_visual()
	update_instability()
	update_stats()
	update_sources()

	# Send the selected gene to the horizontal chromosome map.
	# The map only displays a marker when real genomic coordinates exist.
	_add_gene_to_chromosome_map(trait_id, gene_data)

	if professor and professor.has_method("set_lab_context"):
		update_professor_context()


func _add_gene_to_chromosome_map(
	trait_id: String,
	gene_data: Dictionary
) -> void:

	if chromosome_map == null:
		return

	if not chromosome_map.has_method("add_gene"):
		push_warning(
			"ChromosomeMap does not have add_gene()."
		)
		return

	var loci := _extract_gene_loci(
		trait_id,
		gene_data
	)

	for locus in loci:
		chromosome_map.call(
			"add_gene",
			locus
		)


func _extract_gene_loci(
	trait_id: String,
	gene_data: Dictionary
) -> Array[Dictionary]:

	var loci: Array[Dictionary] = []

	var data := gene_data

	if data.is_empty():
		data = TraitDatabase.TRAIT_DATABASE.get(
			trait_id,
			{}
		)

	# Preferred format:
	# "genomic_loci": [
	#   {
	#     "name": "MC1R",
	#     "chromosome": 5,
	#     "start": 63922271,
	#     "end": 63923224
	#   }
	# ]
	if data.has("genomic_loci"):
		var genomic_loci = data["genomic_loci"]

		if genomic_loci is Array:
			for locus in genomic_loci:
				if locus is Dictionary:
					loci.append(
						_normalize_locus(
							locus,
							trait_id
						)
					)

		return loci

	# Alternative format:
	# "loci": [...]
	if data.has("loci"):
		var raw_loci = data["loci"]

		if raw_loci is Array:
			for locus in raw_loci:
				if locus is Dictionary:
					loci.append(
						_normalize_locus(
							locus,
							trait_id
						)
					)

		return loci

	# Single-locus format.
	if (
		data.has("chromosome")
		and data.has("start")
	):

		loci.append(
			_normalize_locus(
				data,
				trait_id
			)
		)

	return loci


func _normalize_locus(
	locus: Dictionary,
	trait_id: String
) -> Dictionary:

	var result := locus.duplicate(true)

	if not result.has("name"):
		result["name"] = str(
			result.get(
				"gene_symbol",
				trait_id
			)
		)

	if not result.has("mode"):
		result["mode"] = "addition"

	return result


# ============================================================
# DNA
# ============================================================

func animate_dna_addition(dna: String) -> void:
	for letter in dna:
		genome_sequence += letter
		update_genome_display()
		await get_tree().create_timer(0.05).timeout


func update_genome() -> void:
	genome_sequence = ""

	for trait_id in selected_traits:
		var data = TraitDatabase.TRAIT_DATABASE[trait_id]
		var dna = str(data.get("dna", ""))

		if dna == "":
			continue

		if genome_sequence != "":
			genome_sequence += "|"

		genome_sequence += dna

	update_genome_display()


func update_genome_display() -> void:
	var text := ""

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

	var dna_label = $Console/DNASection/ScrollContainer/VBoxContainer2/RichTextLabel
	dna_label.bbcode_enabled = true
	dna_label.text = text

	$Console/DNASection/ScrollContainer/VBoxContainer2/Label.text = \
		"Traits: %d / 5" % selected_traits.size()

	update_dna_visual()
	update_sources()


func update_dna_visual() -> void:
	var stage: int = clamp(
		selected_traits.size(),
		0,
		dna_stages.size() - 1
	)

	$Console/DNASection/ScrollContainer/VBoxContainer2/TextureRect.texture = \
		dna_stages[stage]

	match stage:
		0:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = \
				"GENOME STABLE"
		1:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = \
				"MINOR MUTATIONS"
		2:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = \
				"GENOME MODIFIED"
		3:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = \
				"GENOME UNSTABLE"
		4:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = \
				"SEVERE DEGRADATION"
		5:
			$Console/DNASection/ScrollContainer/VBoxContainer2/Label2.text = \
				"CRITICAL GENOME FAILURE"


func update_sources() -> void:
	var text := "Sources:\n"

	for trait_id in selected_traits:
		var data = TraitDatabase.TRAIT_DATABASE[trait_id]
		var sources = data.get("source_animals", [])

		if sources is Array and not sources.is_empty():
			text += str(sources[0]) + "\n"

	$Console/DNASection/ScrollContainer/VBoxContainer2/VBoxContainer/Label.text = text


# ============================================================
# STATS
# ============================================================

func update_radar() -> void:
	var mobility := 0
	var defense := 0
	var endurance := 0
	var fat_reserve := 0
	var thermoregulation := 0

	for trait_id in selected_traits:
		var gameplay = TraitDatabase.TRAIT_DATABASE[trait_id].get(
			"gameplay",
			{}
		)

		mobility += gameplay.get("mobility", 0)
		defense += gameplay.get("defense", 0)
		endurance += gameplay.get("endurance", 0)
		fat_reserve += gameplay.get("fat_storage", 0)
		thermoregulation += gameplay.get(
			"thermoregulation",
			0
		)

	var radar = $Console/stats/VBoxContainer2/RadarChart

	radar.values = [
		mobility,
		defense,
		endurance,
		fat_reserve,
		thermoregulation
	]

	radar.queue_redraw()


func update_stats() -> void:
	var musculoskeletal := 0
	var integumentary := 0
	var respiratory := 0
	var thermoregulation := 0
	var fat_storage := 0

	for trait_id in selected_traits:
		var gameplay = TraitDatabase.TRAIT_DATABASE[trait_id].get(
			"gameplay",
			{}
		)

		musculoskeletal += gameplay.get("mobility", 0)
		integumentary += gameplay.get("defense", 0)
		respiratory += gameplay.get("endurance", 0)
		thermoregulation += gameplay.get(
			"thermoregulation",
			0
		)
		fat_storage += gameplay.get(
			"fat_storage",
			0
		)

	$Console/stats/VBoxContainer2/VBoxContainer/Label.text = \
		"Musculoskeletal: %d%%" % musculoskeletal

	$Console/stats/VBoxContainer2/VBoxContainer/Label2.text = \
		"Respiratory: %d%%" % respiratory

	$Console/stats/VBoxContainer2/VBoxContainer/Label3.text = \
		"Integumentary: %d%%" % integumentary

	$Console/stats/VBoxContainer2/VBoxContainer/Label4.text = \
		"Fat Reserve: %d%%" % fat_storage

	$Console/stats/VBoxContainer2/VBoxContainer/Label5.text = \
		"Thermoregulation: %d%%" % thermoregulation

	update_radar()


func update_professor_context() -> void:
	if professor == null:
		return

	var traits: Array[String] = []

	var mobility := 0
	var defense := 0
	var endurance := 0
	var fat_storage := 0
	var thermoregulation := 0

	for trait_id in selected_traits:
		var data = TraitDatabase.TRAIT_DATABASE[trait_id]
		traits.append(str(data.get("name", trait_id)))

		var gameplay = data.get(
			"gameplay",
			{}
		)

		mobility += gameplay.get("mobility", 0)
		defense += gameplay.get("defense", 0)
		endurance += gameplay.get("endurance", 0)
		fat_storage += gameplay.get("fat_storage", 0)
		thermoregulation += gameplay.get(
			"thermoregulation",
			0
		)

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

	if professor.has_method("set_lab_context"):
		professor.set_lab_context(context)


# ============================================================
# CREATURE / METADATA
# ============================================================

func load_generated_creature() -> void:
	var image := Image.new()

	var err = image.load(
		"D:/Shalom Essentials/Game development/gene/generated_creature.png"
	)

	if err != OK:
		print("Failed to load image")
		return

	var texture := ImageTexture.create_from_image(image)

	$Console/LoadingBar.visible = false
	$Console/LoadingLabel.visible = false
	creature_preview.texture = texture

	print("Creature Loaded!")


func loaded_generated_creature() -> void:
	$Console/LoadingBar.value = 100

	await get_tree().create_timer(0.3).timeout

	var image := Image.new()

	var err = image.load(
		"res://generated_creature.png"
	)

	if err != OK:
		print("Failed to load image")
		synthesizing = false
		return

	remove_background(image)

	var texture := ImageTexture.create_from_image(image)

	creature_preview.texture = texture

	print("Creature Loaded!")

	generate_metadata()
	load_metadata()

	synthesizing = false


func generate_metadata() -> void:
	loading_progress = 0

	$Console/LoadingBar.visible = true
	$Console/LoadingBar.value = 0

	var trait_string := ""

	for trait_id in selected_traits:
		trait_string += \
			str(TraitDatabase.TRAIT_DATABASE[trait_id]["name"]) + ", "

	var output := []

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


func load_metadata() -> void:
	var file := FileAccess.open(
		"metadata.json",
		FileAccess.READ
	)

	if file == null:
		print("metadata.json not found")
		return

	var text := file.get_as_text()
	var data = JSON.parse_string(text)

	if data == null:
		print("JSON parse failed")
		print(text)
		return

	$Console/ScrollContainer2/VBoxContainer/Label.text = \
		"Species = " + str(data.get("species_name", ""))

	$Console/ScrollContainer2/VBoxContainer/Label2.text = \
		"Scientific Name = " + str(data.get("scientific_name", ""))

	$Console/ScrollContainer/RichTextLabel.text = \
		"Description = " + str(data.get("description", ""))

	$Console/ScrollContainer2/VBoxContainer/Label4.text = \
		"Habitat = " + str(data.get("habitat", ""))

	print("Metadata Loaded")


# ============================================================
# INSTABILITY / PROCESS
# ============================================================

func update_instability() -> void:
	var count := selected_traits.size()

	match count:
		0, 1, 2:
			flicker_speed = 0
			$Console/StatusLabel.visible = false

		3:
			if not alarm_acknowledged:
				flicker_speed = 1
				$Console/StatusLabel.visible = true
				$Console/StatusLabel.text = \
					"WARNING: GENOME INSTABILITY DETECTED"

		4:
			if not alarm_acknowledged:
				flicker_speed = 2
				$Console/StatusLabel.visible = true
				$Console/StatusLabel.text = \
					"CRITICAL: GENOME DEGRADATION"

		5:
			if not alarm_acknowledged:
				flicker_speed = 3
				$Console/StatusLabel.visible = true
				$Console/StatusLabel.text = \
					"CATASTROPHIC FAILURE RISK"


func _process(delta: float) -> void:
	if flicker_speed > 0 and not synthesizing:
		$ColorRect.visible = \
			sin(Time.get_ticks_msec() * 0.01 * flicker_speed) > 0
	else:
		$ColorRect.visible = false

	if synthesizing:
		loading_progress += delta * 20
		loading_progress = min(
			loading_progress,
			95.0
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
			$Console/LoadingLabel.text = ""
			$Console/LoadingBar.visible = false


func remove_background(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var c = image.get_pixel(x, y)

			if c.r > 0.8 and c.g < 0.3 and c.b > 0.8:
				c.a = 0

			image.set_pixel(
				x,
				y,
				c
			)


# ============================================================
# SYNTHESIS
# ============================================================

func generate_creature() -> void:
	alarm_acknowledged = true
	flicker_speed = 0
	$ColorRect.visible = false
	synthesizing = true

	print("SYNTHESIZE PRESSED")

	$Console/StatusLabel.visible = true
	$Console/StatusLabel.text = \
		"SYNTHESIS IN PROGRESS..."

	$Console/Button.disabled = true

	var failure_chance := 0

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

	var output := []

	if randi() % 100 < failure_chance:
		$Console/StatusLabel.visible = true
		$Console/StatusLabel.text = \
			"GENOME COLLAPSE\nSYNTHESIS FAILED"

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

	await loaded_generated_creature()

	$Console/Button.disabled = false
	$Console/StatusLabel.text = ""

	await get_tree().create_timer(2.0).timeout
	clear_status()


func clear_status() -> void:
	$Console/StatusLabel.text = ""
	$Console/StatusLabel.visible = false


# ============================================================
# BUTTONS
# ============================================================

func _on_button_pressed() -> void:
	print("BUTTON WORKS")
	generate_creature()


func _on_play_pressed() -> void:
	var total_mobility := 0

	for trait_id in selected_traits:
		var gameplay = TraitDatabase.TRAIT_DATABASE[trait_id].get(
			"gameplay",
			{}
		)

		if gameplay.has("mobility"):
			total_mobility += gameplay["mobility"]

	GlobalData.current_creature_speed = (
		200.0 + (total_mobility * 10.0)
	)

	get_tree().change_scene_to_file(
		"res://main.tscn"
	)
