extends Control
## Variant Zero - Spaced Horizontal Canine Chromosome Map
##
## Layout goal:
## - NO vertical scrolling.
## - ONLY left/right scrolling.
## - 39 canine chromosome PAIRS are split into 13 horizontal frames.
## - Each frame contains MAXIMUM 3 chromosome pairs.
## - Scroll sideways to move from one group of 3 chromosomes to the next.
## - Related chromosome tracks can visually overlap inside their own frame.
## - Added/replaced genes appear in orange at their genomic coordinate.
##
## Scene:
## ChromosomePanel
## └── ScrollContainer
##     └── ChromosomeMap   <- attach this script here
##
## ScrollContainer:
##   Horizontal Scroll Mode = Auto
##   Vertical Scroll Mode   = Disabled

const FRAME_WIDTH := 1080.0
const FRAME_GAP := 36.0
const FRAME_COUNT := 13
var gene_marker_layer: Control
var marker_nodes: Dictionary = {}

const MAP_WIDTH := (FRAME_WIDTH * FRAME_COUNT) + (FRAME_GAP * (FRAME_COUNT - 1))
const MAP_HEIGHT := 155.0

const FRAME_TOP := 24.0
const FRAME_BOTTOM := 8.0

const LABEL_WIDTH := 84.0
const INNER_LEFT := 94.0
const INNER_RIGHT := 36.0

const ROW_HEIGHT := 38.0
const BAR_HEIGHT := 4.0

const BASE_GREEN := Color("#2E8D3A")
const BRIGHT_GREEN := Color("#62C96A")
const DIM_GREEN := Color("#173A1C")
const GRID_GREEN := Color("#0C2A12")
const GRID_STRONG := Color("#16471E")

const FRAME_BORDER := Color("#1D6428")
const FRAME_BORDER_BRIGHT := Color("#2D9839")

const ORANGE := Color("#FF8A22")
const ORANGE_BRIGHT := Color("#FFB05A")

const TEXT_GREEN := Color("#68D76E")
const TEXT_DIM := Color("#398340")
const BACKGROUND := Color("#020703")

# ROS_Cfam_1.0 chromosome lengths.
# 1..38 are autosomes. 39 visually represents the X/Y pair.
const CHROMOSOME_LENGTHS := {
	1: 123313939,
	2: 86187811,
	3: 92870237,
	4: 89007665,
	5: 89573405,
	6: 78268176,
	7: 81039452,
	8: 75260524,
	9: 62002293,
	10: 70361000,
	11: 75541347,
	12: 73497294,
	13: 64037277,
	14: 61043064,
	15: 65200600,
	16: 62021213,
	17: 65471548,
	18: 56883407,
	19: 55265241,
	20: 58896461,
	21: 52140716,
	22: 62106979,
	23: 53282923,
	24: 48838997,
	25: 51941001,
	26: 40674351,
	27: 46248802,
	28: 41862212,
	29: 42049852,
	30: 40414903,
	31: 39518933,
	32: 39023732,
	33: 31649084,
	34: 42263871,
	35: 26942268,
	36: 31065185,
	37: 30932408,
	38: 24102048,
	39: 127069619
}

const SEX_CHROMOSOME_Y_LENGTH := 3937623

# Visual grouping only.
# This controls slight offsets inside each 3-chromosome frame so related
# tracks can overlap without creating a wall of compressed lines.
const GROUP_OFFSETS := {
	1: 0.00,
	2: 0.06,
	3: 0.02,
	4: 0.08,
	5: 0.03,
	6: 0.07,
	7: 0.01,
	8: 0.10,
	9: 0.04,
	10: 0.08,
	11: 0.02,
	12: 0.07,
	13: 0.03,
	14: 0.09,
	15: 0.01,
	16: 0.06,
	17: 0.03,
	18: 0.08,
	19: 0.02,
	20: 0.07,
	21: 0.04,
	22: 0.09,
	23: 0.02,
	24: 0.06,
	25: 0.01,
	26: 0.08,
	27: 0.03,
	28: 0.07,
	29: 0.02,
	30: 0.09,
	31: 0.04,
	32: 0.06,
	33: 0.01,
	34: 0.08,
	35: 0.03,
	36: 0.07,
	37: 0.02,
	38: 0.06,
	39: 0.04
}

# Example canine loci for testing.
# Set SHOW_DEMO_GENES to true if you want orange markers immediately.
const SHOW_DEMO_GENES := false

const DEMO_DOG_GENES := {
	"MC1R": {
		"name": "MC1R",
		"chromosome": 5,
		"start": 63922271,
		"end": 63923224,
		"mode": "addition"
	},
	"IGF1R": {
		"name": "IGF1R",
		"chromosome": 3,
		"start": 42203106,
		"end": 42506274,
		"mode": "addition"
	},
	"IGF1": {
		"name": "IGF1",
		"chromosome": 15,
		"start": 41855737,
		"end": 41930681,
		"mode": "addition"
	}
}

var added_genes: Array[Dictionary] = []
var hovered_gene_index := -1
var selected_gene_index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

	gene_marker_layer = get_node_or_null(
		"GeneMarkerLayer"
	) as Control

	if gene_marker_layer == null:
		push_error(
			"GeneMarkerLayer was not found under ChromosomeMap."
		)
		return

	custom_minimum_size = Vector2(
		MAP_WIDTH,
		MAP_HEIGHT
	)

	queue_redraw()

func _draw() -> void:
	draw_rect(
		Rect2(Vector2.ZERO, size),
		BACKGROUND
	)

	draw_global_header()
	draw_frames()
# ============================================================
# GLOBAL HEADER
# ============================================================

func draw_global_header() -> void:
	draw_string(
		ThemeDB.fallback_font,
		Vector2(16, 14),
		"CANINE GENOME // ROS_Cfam_1.0",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		11,
		TEXT_GREEN
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(MAP_WIDTH - 170, 14),
		"39 CHROMOSOME PAIRS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		8,
		TEXT_DIM
	)


# ============================================================
# 13 FRAMES × 3 CHROMOSOMES
# ============================================================

func draw_frames() -> void:
	for frame_index in range(FRAME_COUNT):
		draw_frame(frame_index)


func draw_frame(frame_index: int) -> void:
	var frame_x: float = frame_index * (FRAME_WIDTH + FRAME_GAP)

	var frame_rect := Rect2(
		frame_x,
		FRAME_TOP,
		FRAME_WIDTH,
		MAP_HEIGHT - FRAME_TOP - FRAME_BOTTOM
	)

	# Frame background.
	draw_rect(
		frame_rect,
		Color("#020A04")
	)

	# Frame border.
	draw_rect(
		frame_rect,
		FRAME_BORDER_BRIGHT if frame_index == 0 else FRAME_BORDER,
		false,
		1.0
	)

	# Frame title.
	var first_chr: int = (frame_index * 3) + 1
	var last_chr: int = min(first_chr + 2, 39)

	var title := "CHROMOSOMES %02d–%02d" % [first_chr, last_chr]

	if first_chr == 37:
		title = "CHROMOSOMES 37–39 // SEX CHROMOSOME GROUP"

	draw_string(
		ThemeDB.fallback_font,
		Vector2(
			frame_x + 14,
			FRAME_TOP + 13
		),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		9,
		TEXT_GREEN
	)

	# Tiny frame number.
	draw_string(
		ThemeDB.fallback_font,
		Vector2(
			frame_x + FRAME_WIDTH - 40,
			FRAME_TOP + 13
		),
		"%02d" % (frame_index + 1),
		HORIZONTAL_ALIGNMENT_LEFT,
		25,
		8,
		TEXT_DIM
	)

	# Three chromosome rows maximum.
	for local_row in range(3):
		var chromosome_number: int = first_chr + local_row

		if chromosome_number > 39:
			continue

		draw_chromosome_row(
			frame_x,
			local_row,
			chromosome_number
		)


func draw_chromosome_row(
	frame_x: float,
	local_row: int,
	chromosome_number: int
) -> void:

	var row_y: float = FRAME_TOP + 30.0 + (local_row * ROW_HEIGHT)

	# Very subtle horizontal guide.
	draw_line(
		Vector2(frame_x + 10, row_y + 17),
		Vector2(frame_x + FRAME_WIDTH - 10, row_y + 17),
		GRID_GREEN,
		1.0
	)

	var label := "CHR %02d" % chromosome_number

	if chromosome_number == 39:
		label = "CHR X/Y"

	draw_string(
		ThemeDB.fallback_font,
		Vector2(
			frame_x + 12,
			row_y + 9
		),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		LABEL_WIDTH,
		8,
		TEXT_GREEN
	)

	var available_width: float = FRAME_WIDTH - INNER_LEFT - INNER_RIGHT
	var start_x: float = frame_x + INNER_LEFT

	var offset_factor: float = float(GROUP_OFFSETS.get(
		chromosome_number,
		0.0
	))

	var offset_x: float = offset_factor * 220.0

	if chromosome_number == 39:
		draw_sex_chromosomes(
			frame_x,
			row_y,
			start_x + offset_x,
			available_width
		)
		return

	var chromosome_length: int = CHROMOSOME_LENGTHS[
		chromosome_number
	]

	var chromosome_width: float = normalized_width(
		chromosome_length,
		available_width
	)

	var bar_a := Rect2(
		start_x + offset_x,
		row_y + 4,
		chromosome_width,
		BAR_HEIGHT
	)

	# Homolog B slightly displaced to create the layered look.
	var bar_b := Rect2(
		start_x + offset_x + 28,
		row_y + 9,
		chromosome_width * 0.985,
		BAR_HEIGHT
	)

	draw_chromosome_bar(bar_a)
	draw_chromosome_bar(bar_b)


func draw_sex_chromosomes(
	frame_x: float,
	row_y: float,
	start_x: float,
	available_width: float
) -> void:

	var x_width := normalized_width(
		CHROMOSOME_LENGTHS[39],
		available_width
	)

	var y_width := normalized_width(
		SEX_CHROMOSOME_Y_LENGTH,
		available_width
	)

	var x_bar := Rect2(
		start_x,
		row_y + 4,
		x_width,
		BAR_HEIGHT
	)

	var y_bar := Rect2(
		start_x + 30,
		row_y + 9,
		y_width,
		BAR_HEIGHT
	)

	draw_chromosome_bar(x_bar)
	draw_chromosome_bar(y_bar)


func normalized_width(
	length_bp: int,
	available_width: float
) -> float:

	# Chromosome 1 is ~123.3 Mb and is the longest.
	var longest := 123313939.0

	return max(
		105.0,
		(float(length_bp) / longest)
		* available_width
		* 0.94
	)


func draw_chromosome_bar(rect: Rect2) -> void:
	draw_rect(
		rect,
		BASE_GREEN
	)

	draw_rect(
		rect,
		BRIGHT_GREEN,
		false,
		1.0
	)

	# Simple banding makes the bar feel like a genome track.
	var band_count: int = clampi(
	int(rect.size.x / 110.0),
	3,
	12
)
	

	var band_width: float = rect.size.x / float(band_count * 2)

	for i in range(band_count):
		var bx := rect.position.x + (
			i * band_width * 2.0
		)

		draw_rect(
			Rect2(
				bx,
				rect.position.y,
				band_width,
				rect.size.y
			),
			DIM_GREEN
		)


# ============================================================
# ORANGE GENE INSERTIONS / REPLACEMENTS
# ============================================================

func draw_gene_markers() -> void:
	for i in range(added_genes.size()):
		draw_gene_marker(
			added_genes[i],
			i
		)


func draw_gene_marker(
	gene: Dictionary,
	index: int
) -> void:

	var chromosome = gene.get(
		"chromosome",
		-1
	)

	if chromosome is String:
		if chromosome.to_upper() == "X":
			chromosome = 39
		else:
			return

	var chromosome_index: int = int(chromosome)

	if chromosome_index < 1 or chromosome_index > 39:
		return

	var frame_index: int = int(
		(chromosome_index - 1) / 3
	)

	var local_row: int = (
		chromosome_index - 1
	) % 3

	var frame_x: float = float(
		frame_index * (
			FRAME_WIDTH + FRAME_GAP
		)
	)

	var row_y: float = (
		FRAME_TOP
		+ 30.0
		+ float(local_row) * ROW_HEIGHT
	)

	var available_width: float = (
		FRAME_WIDTH
		- INNER_LEFT
		- INNER_RIGHT
	)

	var start_x: float = (
		frame_x + INNER_LEFT
	)

	var offset_factor: float = float(
		GROUP_OFFSETS.get(
			chromosome_index,
			0.0
		)
	)

	var offset_x: float = (
		offset_factor * 220.0
	)

	var chromosome_length: float

	if chromosome_index == 39:
		chromosome_length = float(
			CHROMOSOME_LENGTHS[39]
		)
	else:
		chromosome_length = float(
			CHROMOSOME_LENGTHS[
				chromosome_index
			]
		)

	var chromosome_width: float = normalized_width(
		int(chromosome_length),
		available_width
	)

	var gene_start: float = float(
		gene.get(
			"start",
			0
		)
	)

	var gene_end: float = float(
		gene.get(
			"end",
			gene_start
		)
	)

	var center_bp: float = (
		gene_start + gene_end
	) * 0.5

	var normalized_position: float = clamp(
		center_bp / chromosome_length,
		0.0,
		1.0
	)

	var marker_x: float = (
		start_x
		+ offset_x
		+ normalized_position * chromosome_width
	)

	var mode: String = str(
		gene.get(
			"mode",
			"addition"
		)
	)

	var marker_width: float = 8.0

	if mode == "replacement":
		marker_width = 18.0

	var marker_rect: Rect2 = Rect2(
		marker_x - marker_width * 0.5,
		row_y + 1.0,
		marker_width,
		13.0
	)

	var selected: bool = (
		index == selected_gene_index
	)

	var hovered: bool = (
		index == hovered_gene_index
	)

	draw_rect(
		marker_rect,
		ORANGE_BRIGHT
		if selected
		else ORANGE
	)

	draw_line(
		Vector2(
			marker_x,
			row_y - 2.0
		),
		Vector2(
			marker_x,
			row_y + 18.0
		),
		ORANGE_BRIGHT,
		1.0
	)

	if hovered or selected:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(
				marker_x + 7.0,
				row_y - 1.0
			),
			str(
				gene.get(
					"name",
					"GENE"
				)
			),
			HORIZONTAL_ALIGNMENT_LEFT,
			100,
			8,
			ORANGE_BRIGHT
		)
func position_gene_marker(
	marker: Control,
	gene: Dictionary
) -> void:

	var chromosome: int = int(
		gene["chromosome"]
	)

	var frame_index: int = int(
		(chromosome - 1) / 3
	)

	var local_row: int = (
		chromosome - 1
	) % 3

	var frame_x: float = (
		frame_index
		* (FRAME_WIDTH + FRAME_GAP)
	)

	var row_y: float = (
		FRAME_TOP
		+ 30.0
		+ float(local_row) * ROW_HEIGHT
	)

	var available_width: float = (
		FRAME_WIDTH
		- INNER_LEFT
		- INNER_RIGHT
	)

	var start_x: float = (
		frame_x
		+ INNER_LEFT
	)

	var offset_factor: float = float(
		GROUP_OFFSETS.get(
			chromosome,
			0.0
		)
	)

	var offset_x: float = (
		offset_factor * 220.0
	)

	var chromosome_length: float = float(
		CHROMOSOME_LENGTHS[
			chromosome
		]
	)

	var chromosome_width: float = (
		normalized_width(
			int(chromosome_length),
			available_width
		)
	)

	var gene_start: float = float(
		gene.get(
			"start",
			0
		)
	)

	var gene_end: float = float(
		gene.get(
			"end",
			gene_start
		)
	)

	var gene_center: float = (
		gene_start
		+ gene_end
	) * 0.5

	var normalized_position: float = clamp(
		gene_center
		/ chromosome_length,
		0.0,
		1.0
	)

	var marker_x: float = (
		start_x
		+ offset_x
		+ normalized_position
		* chromosome_width
	)

	marker.position = Vector2(
		marker_x - 7.0,
		row_y - 2.0
	)

	marker.size = Vector2(
		14.0,
		18.0
	)

	var orange_bar := (
		marker.get_node(
			"OrangeMarker"
		) as ColorRect
	)

	if orange_bar != null:
		orange_bar.position = Vector2(
			0,
			0
		)

		orange_bar.size = Vector2(
			14.0,
			18.0
		)

		# Replacements are wider.
		if str(
			gene.get(
				"mode",
				"addition"
			)
		) == "replacement":

			orange_bar.size.x = 22.0

func add_gene(gene: Dictionary) -> void:
	if not gene.has("chromosome"):
		push_warning(
			"Gene has no chromosome: " + str(gene)
		)
		return

	var gene_to_add: Dictionary = gene.duplicate(true)

	# Convert X to visual chromosome 39.
	var chromosome_value = gene_to_add.get(
		"chromosome",
		-1
	)

	if chromosome_value is String:
		if str(chromosome_value).to_upper() == "X":
			chromosome_value = 39
		else:
			push_warning(
				"Unknown chromosome: " + str(chromosome_value)
			)
			return

	var chromosome_number: int = int(
		chromosome_value
	)

	if chromosome_number < 1 or chromosome_number > 39:
		push_warning(
			"Chromosome out of range: " + str(chromosome_number)
		)
		return

	gene_to_add["chromosome"] = chromosome_number

	# Temporary fallback if real genomic coordinates
	# have not been added to the gene yet.
	if not gene_to_add.has("start"):
		var chromosome_length: int = int(
			CHROMOSOME_LENGTHS[chromosome_number]
		)

		var midpoint: int = int(
			chromosome_length / 2
		)

		gene_to_add["start"] = midpoint
		gene_to_add["end"] = midpoint

	if not gene_to_add.has("end"):
		gene_to_add["end"] = gene_to_add["start"]

	if not gene_to_add.has("name"):
		gene_to_add["name"] = "GENE"

	if not gene_to_add.has("mode"):
		gene_to_add["mode"] = "addition"

	# Prevent duplicates.
	var gene_name: String = str(
		gene_to_add["name"]
	)

	for existing in added_genes:
		if str(
			existing.get("name", "")
		) == gene_name:
			print(
				"Gene already on chromosome map: ",
				gene_name
			)
			return

	added_genes.append(
		gene_to_add
	)

	print(
		"CHROMOSOME MARKER ADDED: ",
		gene_name,
		" | CHR ",
		chromosome_number
	)

	queue_redraw()

	var new_index: int = (
		added_genes.size() - 1
	)

	call_deferred(
		"focus_gene",
		new_index
	)
func create_gene_marker(
	gene: Dictionary
) -> Control:

	var marker := Control.new()

	var gene_name: String = str(
		gene.get(
			"name",
			"GENE"
		)
	)

	# This is the node you'll actually see in Remote.
	marker.name = (
		"GeneMarker_"
		+ gene_name.replace(" ", "_")
	)

	marker.mouse_filter = (
		Control.MOUSE_FILTER_PASS
	)

	marker.tooltip_text = (
		gene_name
		+ "\nChromosome: "
		+ str(gene["chromosome"])
	)

	gene_marker_layer.add_child(
		marker
	)

	# --------------------------------------------------------
	# ORANGE MARKER
	# --------------------------------------------------------

	var orange_bar := ColorRect.new()

	orange_bar.name = "OrangeMarker"

	orange_bar.color = ORANGE

	orange_bar.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	marker.add_child(
		orange_bar
	)


	# --------------------------------------------------------
	# GENE LABEL
	# --------------------------------------------------------

	var label := Label.new()

	label.name = "GeneLabel"

	label.text = gene_name

	label.position = Vector2(
		9,
		-12
	)

	label.add_theme_font_size_override(
		"font_size",
		9
	)

	label.add_theme_color_override(
		"font_color",
		ORANGE_BRIGHT
	)

	label.visible = false

	label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	marker.add_child(
		label
	)


	# Hover behavior.
	marker.mouse_entered.connect(
		func():
			label.visible = true
	)

	marker.mouse_exited.connect(
		func():
			label.visible = false
	)

	# Position the marker.
	position_gene_marker(
		marker,
		gene
	)

	return marker

func focus_gene(
	gene: Dictionary,
	_index: int
) -> void:

	var chromosome: int = int(
		gene["chromosome"]
	)

	var frame_index: int = int(
		(chromosome - 1) / 3
	)

	var target_x: float = (
		frame_index
		* (FRAME_WIDTH + FRAME_GAP)
	)

	var scroll := get_parent()

	if scroll is ScrollContainer:

		scroll.scroll_horizontal = int(
			target_x
		)
func replace_gene(
	gene: Dictionary
) -> void:

	var copy := gene.duplicate(
		true
	)

	copy["mode"] = "replacement"

	var name := str(
		copy.get(
			"name",
            ""
		)
	)

	for i in range(
		added_genes.size()
	):
		if str(
			added_genes[i].get(
				"name",
                ""
			)
		) == name:

			added_genes[i] = copy
			queue_redraw()
			return

	added_genes.append(copy)
	queue_redraw()


func remove_gene(
	gene_name: String
) -> void:

	for i in range(
		added_genes.size() - 1,
		-1,
		-1
	):

		if str(
			added_genes[i].get(
				"name",
                ""
			)
		) == gene_name:

			added_genes.remove_at(i)

	selected_gene_index = -1
	hovered_gene_index = -1

	queue_redraw()


func clear_gene_markers() -> void:
	added_genes.clear()

	selected_gene_index = -1
	hovered_gene_index = -1

	queue_redraw()


# ============================================================
# INTERACTION
# ============================================================

func _gui_input(
	event: InputEvent
) -> void:

	if event is InputEventMouseMotion:

		var new_hover := (
			find_gene_at_position(
				event.position
			)
		)

		if new_hover != hovered_gene_index:

			hovered_gene_index = new_hover
			queue_redraw()

	elif event is InputEventMouseButton:

		if (
			event.button_index
			== MOUSE_BUTTON_LEFT
			and event.pressed
		):

			var clicked := (
				find_gene_at_position(
					event.position
				)
			)

			if clicked != -1:

				selected_gene_index = clicked

				var gene: Dictionary = (
					added_genes[
						clicked
					]
				)

				print(
					"Selected gene: ",
					gene.get(
						"name",
                        "GENE"
					),
					" | chromosome: ",
					gene.get(
						"chromosome",
                        "?"
					),
					" | start: ",
					gene.get(
						"start",
						0
					),
					" | end: ",
					gene.get(
						"end",
						0
					)
				)

				queue_redraw()


func find_gene_at_position(
	mouse_position: Vector2
) -> int:

	for i in range(
		added_genes.size()
	):

		var gene: Dictionary = (
			added_genes[i]
		)

		var chromosome = gene.get(
			"chromosome",
			-1
		)

		if chromosome is String:
			if chromosome.to_upper() == "X":
				chromosome = 39
			else:
				continue

		var chromosome_index: int = int(
			chromosome
		)

		if chromosome_index < 1 or chromosome_index > 39:
			continue

		var frame_index: int = int(
			(chromosome_index - 1) / 3
		)

		var local_row: int = (
			chromosome_index - 1
		) % 3

		var frame_x: float = float(
			frame_index * (
				FRAME_WIDTH + FRAME_GAP
			)
		)

		var row_y: float = (
			FRAME_TOP
			+ 30.0
			+ float(local_row) * ROW_HEIGHT
		)

		var available_width: float = (
			FRAME_WIDTH
			- INNER_LEFT
			- INNER_RIGHT
		)

		var start_x: float = (
			frame_x + INNER_LEFT
		)

		var offset_factor: float = float(
			GROUP_OFFSETS.get(
				chromosome_index,
				0.0
			)
		)

		var offset_x: float = (
			offset_factor * 220.0
		)

		var chromosome_length: float

		if chromosome_index == 39:
			chromosome_length = float(
				CHROMOSOME_LENGTHS[39]
			)
		else:
			chromosome_length = float(
				CHROMOSOME_LENGTHS[
					chromosome_index
				]
			)

		var chromosome_width: float = normalized_width(
			int(chromosome_length),
			available_width
		)

		var gene_start: float = float(
			gene.get(
				"start",
				0
			)
		)

		var gene_end: float = float(
			gene.get(
				"end",
				gene_start
			)
		)

		var center_bp: float = (
			gene_start + gene_end
		) * 0.5

		var normalized_position: float = clamp(
			center_bp / chromosome_length,
			0.0,
			1.0
		)

		var marker_x: float = (
			start_x
			+ offset_x
			+ normalized_position * chromosome_width
		)

		var hit_rect: Rect2 = Rect2(
			marker_x - 10.0,
			row_y - 4.0,
			20.0,
			22.0
		)

		if hit_rect.has_point(
			mouse_position
		):
			return i

	return -1
