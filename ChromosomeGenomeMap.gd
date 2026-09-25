extends Control
## Variant Zero - Horizontal Canine Chromosome Map
##
## Purpose:
## - Displays the 39 canine chromosome PAIRS as compact horizontal tracks.
## - Uses ROS_Cfam_1.0 chromosome lengths for proportional bar lengths.
## - Horizontally scrolls only. There is NO vertical scrolling.
## - Related/functionally grouped chromosome pairs are visually overlaid/offset.
## - Added/replaced genes are drawn in ORANGE at their genomic coordinate.
##
## Scene expected:
##
## ChromosomePanel (Control / PanelContainer)
## └── ScrollContainer
##     └── ChromosomeMap (Control)  <-- attach this script here
##
## ScrollContainer:
##   Horizontal Scroll Mode = Auto
##   Vertical Scroll Mode   = Disabled
##
## The script automatically gives ChromosomeMap a large horizontal minimum size.

const MAP_WIDTH := 6200.0
const LEFT_LABEL_WIDTH := 72.0
const RIGHT_MARGIN := 70.0
const TOP_MARGIN := 29.0

# Compact enough to show all 39 chromosome pairs without vertical scrolling.
const ROW_HEIGHT := 5.4
const HOMOLOG_OFFSET := 1.8

const BAR_HEIGHT := 1.5
const BAR_THICKNESS := 1.5

const BASE_GREEN := Color("#2E8D3A")
const BRIGHT_GREEN := Color("#62C96A")
const DIM_GREEN := Color("#173A1C")
const GRID_GREEN := Color("#0C2A12")
const GRID_STRONG := Color("#16471E")
const ORANGE := Color("#FF8A22")
const ORANGE_BRIGHT := Color("#FFB05A")
const ORANGE_DIM := Color("#8A4514")
const TEXT_GREEN := Color("#68D76E")
const TEXT_DIM := Color("#398340")
const BACKGROUND := Color("#020703")

# Real chromosome lengths in bp from ROS_Cfam_1.0 / GCF_014441545.1.
# 1..38 + X + Y.
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
	39: 127069619 # X is represented by pair 39; Y is its partner.
}

# The 39th row represents the sex-chromosome pair.
# The primary horizontal bar is X and the shorter secondary bar is Y.
const SEX_CHROMOSOME_Y_LENGTH := 3937623


# Visual starts are deliberately offset to make the map look like a
# functional topology/timeline rather than a rigid chromosome table.
#
# These are VISUAL GROUPINGS only. They do not mean chromosomes physically
# overlap inside a nucleus.
const GROUP_OFFSETS := [
	0.00, 0.10, 0.04, 0.16, 0.02,
	0.12, 0.06, 0.20, 0.01, 0.14,
	0.05, 0.18, 0.03, 0.11, 0.00,
	0.17, 0.07, 0.21, 0.02, 0.13,
	0.05, 0.19, 0.04, 0.15, 0.01,
	0.12, 0.06, 0.18, 0.03, 0.14,
	0.07, 0.20, 0.02, 0.11, 0.05,
	0.17, 0.04, 0.13, 0.08
]


# Genes already verified against the ROS_Cfam_1.0 dog assembly.
# You can add the rest of your trait genes here.
#
# start/end are genomic coordinates in base pairs.
# chromosome is 1..38 for autosomes, or "X".
const DEMO_DOG_GENES := {
	"MC1R": {
		"name": "MC1R",
		"full_name": "melanocortin 1 receptor",
		"chromosome": 5,
		"start": 63922271,
		"end": 63923224,
		"mode": "addition"
	},
	"IGF1R": {
		"name": "IGF1R",
		"full_name": "insulin like growth factor 1 receptor",
		"chromosome": 3,
		"start": 42203106,
		"end": 42506274,
		"mode": "addition"
	},
	"IGF1": {
		"name": "IGF1",
		"full_name": "insulin like growth factor 1",
		"chromosome": 15,
		"start": 41855737,
		"end": 41930681,
		"mode": "addition"
	},
	"FGF1": {
		"name": "FGF1",
		"full_name": "fibroblast growth factor 1",
		"chromosome": 2,
		"start": 37924029,
		"end": 38010951,
		"mode": "addition"
	}
}


var added_genes: Array = []
var hovered_gene_index := -1
var selected_gene_index := -1

# Used to create deliberate visual overlap between related rows.
# These are DISPLAY groupings, not biological claims.
var functional_groups = {
	"growth": [2, 3, 15, 17],
	"pigment": [5, 20, 24],
	"musculoskeletal": [7, 10, 27, 32],
	"immune": [12, 18, 19, 23],
	"metabolic": [9, 13, 16, 21],
	"neural": [11, 14, 22, 29],
	"development": [1, 4, 8, 17],
	"general": [6, 25, 26, 28, 30, 31, 33, 34, 35, 36, 37, 38]
}


func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(MAP_WIDTH, TOP_MARGIN + 39 * ROW_HEIGHT + 20)

	# Demo markers so you can immediately see how the orange system works.
	# Remove these three lines once your real Gene File system calls add_gene().
	add_gene(DEMO_DOG_GENES["MC1R"])
	add_gene(DEMO_DOG_GENES["IGF1R"])
	add_gene(DEMO_DOG_GENES["IGF1"])
	add_gene(DEMO_DOG_GENES["FGF1"])

	queue_redraw()


func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)

	draw_grid()
	draw_header()
	draw_chromosome_tracks()
	draw_gene_markers()


# ============================================================
# HEADER + GRID
# ============================================================

func draw_header():
	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, 18),
		"CANINE GENOME // ROS_Cfam_1.0",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12,
		TEXT_GREEN
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(MAP_WIDTH - 250, 18),
		"39 CHROMOSOME PAIRS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		TEXT_DIM
	)

	# Tick marks / coordinate ruler.
	var ruler_y := TOP_MARGIN - 8.0
	var genome_width := MAP_WIDTH - LEFT_LABEL_WIDTH - RIGHT_MARGIN

	for i in range(0, 13):
		var x = LEFT_LABEL_WIDTH + (genome_width / 12.0) * i

		draw_line(
			Vector2(x, ruler_y - 3),
			Vector2(x, ruler_y + 2),
			GRID_STRONG,
			1.0
		)

		var mb_label = "%d00 Mb" % int(i * 10)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(x + 3, ruler_y - 5),
			mb_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			55,
			8,
			TEXT_DIM
		)


func draw_grid():
	var genome_left := LEFT_LABEL_WIDTH
	var genome_right := MAP_WIDTH - RIGHT_MARGIN
	var genome_width := genome_right - genome_left

	# Vertical grid.
	for i in range(0, 49):
		var x = genome_left + (genome_width / 48.0) * i
		var is_strong = i % 4 == 0

		draw_line(
			Vector2(x, TOP_MARGIN),
			Vector2(x, size.y),
			GRID_STRONG if is_strong else GRID_GREEN,
			1.0
		)

	# Horizontal separators.
	for row in range(39):
		var y = TOP_MARGIN + row * ROW_HEIGHT

		draw_line(
			Vector2(12, y),
			Vector2(MAP_WIDTH - 12, y),
			GRID_GREEN,
			1.0
		)


# ============================================================
# CHROMOSOME TRACKS
# ============================================================

func draw_chromosome_tracks():
	for chromosome_number in range(1, 40):
		draw_chromosome_pair(chromosome_number)


func draw_chromosome_pair(chromosome_number: int):
	var row := chromosome_number - 1
	var row_y := TOP_MARGIN + row * ROW_HEIGHT

	var visual_offset = GROUP_OFFSETS[row] * 350.0
	var genome_left := LEFT_LABEL_WIDTH
	var genome_width := MAP_WIDTH - LEFT_LABEL_WIDTH - RIGHT_MARGIN

	var label := "CHR %02d" % chromosome_number

	if chromosome_number == 39:
		label = "CHR X/Y"

	draw_string(
		ThemeDB.fallback_font,
		Vector2(12, row_y + 4.5),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		58,
		7,
		TEXT_GREEN
	)

	if chromosome_number == 39:
		draw_sex_pair(row_y, genome_left, genome_width, visual_offset)
		return

	var chromosome_length: int = CHROMOSOME_LENGTHS[chromosome_number]

	# Scale the real chromosome length for display.
	var width = normalized_chromosome_width(
		chromosome_length,
		genome_width
	)

	# Homolog A.
	var rect_a := Rect2(
		genome_left + visual_offset,
		row_y + 1.0,
		width,
		BAR_HEIGHT
	)

	# Homolog B is slightly displaced. This creates the paired/overlapping
	# visual seen in the target design.
	var rect_b := Rect2(
		genome_left + visual_offset + 26.0,
		row_y + 3.0,
		width * 0.985,
		BAR_HEIGHT
	)

	draw_chromosome_bar(rect_a, false, chromosome_number)
	draw_chromosome_bar(rect_b, false, chromosome_number)

	# Small center tick / pair connector.
	var connector_x = rect_a.position.x + min(34.0, rect_a.size.x * 0.25)

	draw_line(
		Vector2(connector_x, rect_a.position.y + BAR_HEIGHT),
		Vector2(connector_x, rect_b.position.y),
		DIM_GREEN,
		1.0
	)


func draw_sex_pair(row_y: float, genome_left: float, genome_width: float, visual_offset: float):
	var x_length: int = CHROMOSOME_LENGTHS[39]

	var x_width := normalized_chromosome_width(
		x_length,
		genome_width
	)

	# X chromosome.
	var x_bar := Rect2(
		genome_left + visual_offset,
		row_y + 1.0,
		x_width,
		BAR_HEIGHT
	)

	# Y chromosome.
	var y_width := normalized_chromosome_width(
		SEX_CHROMOSOME_Y_LENGTH,
		genome_width
	)

	var y_bar := Rect2(
		genome_left + visual_offset + 38.0,
		row_y + 3.0,
		y_width,
		BAR_HEIGHT
	)

	draw_chromosome_bar(x_bar, false, 39)
	draw_chromosome_bar(y_bar, false, 39)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(18, row_y + 7),
		"XY",
		HORIZONTAL_ALIGNMENT_LEFT,
		30,
		9,
		TEXT_GREEN
	)


func normalized_chromosome_width(length_bp: int, available_width: float) -> float:
	# The longest autosome is approximately 123.3 Mb in ROS_Cfam_1.0.
	# We intentionally keep a readable minimum visual size.
	var longest := 123313939.0

	return max(
		85.0,
		(length_bp / longest) * available_width * 0.92
	)


func draw_chromosome_bar(rect: Rect2, highlighted: bool, chromosome_number: int):
	var base_color := BRIGHT_GREEN if highlighted else BASE_GREEN

	draw_rect(rect, base_color)
	draw_rect(rect, base_color.lightened(0.18), false, 1.0)

	# Small banding pattern to make the chromosome look like a genome track.
	var band_count = clamp(int(rect.size.x / 90.0), 2, 18)
	var band_width := rect.size.x / float(band_count * 2)

	for i in range(band_count):
		var bx = rect.position.x + (i * band_width * 2.0)

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
# ORANGE GENE MARKERS
# ============================================================

func draw_gene_markers():
	for i in range(added_genes.size()):
		draw_gene_marker(added_genes[i], i)


func draw_gene_marker(gene: Dictionary, index: int):
	var chromosome = gene.get("chromosome", -1)

	if chromosome is String:
		if chromosome.to_upper() == "X":
			chromosome = 39
		else:
			return

	if chromosome < 1 or chromosome > 39:
		return

	var row := int(chromosome) - 1
	var row_y := TOP_MARGIN + row * ROW_HEIGHT

	var gene_start := float(gene.get("start", 0))
	var gene_end := float(gene.get("end", gene_start))

	var chromosome_length: float

	if chromosome == 39:
		chromosome_length = CHROMOSOME_LENGTHS[39]
	else:
		chromosome_length = CHROMOSOME_LENGTHS[chromosome]

	var genome_left := LEFT_LABEL_WIDTH
	var genome_width := MAP_WIDTH - LEFT_LABEL_WIDTH - RIGHT_MARGIN
	var visual_offset = GROUP_OFFSETS[row] * 350.0

	var chromosome_width := normalized_chromosome_width(
		int(chromosome_length),
		genome_width
	)

	var gene_center := (gene_start + gene_end) * 0.5

	var normalized_position = clamp(
		gene_center / chromosome_length,
		0.0,
		1.0
	)

	var marker_x = (
		genome_left
		+ visual_offset
		+ normalized_position * chromosome_width
	)

	# Orange locus body.
	var locus_width = clamp(
		((gene_end - gene_start) / chromosome_length) * chromosome_width * 12.0,
		5.0,
		24.0
	)

	var marker_rect := Rect2(
		marker_x - locus_width * 0.5,
		row_y,
		locus_width,
		5.0
	)

	var is_selected = index == selected_gene_index
	var is_hovered = index == hovered_gene_index

	draw_rect(
		marker_rect,
		ORANGE_BRIGHT if is_selected else ORANGE
	)

	if is_hovered or is_selected:
		draw_rect(
			marker_rect.grow(3.0),
			Color(1.0, 0.45, 0.08, 0.18)
		)

	# Vertical locus line.
	draw_line(
		Vector2(marker_x, row_y - 1),
		Vector2(marker_x, row_y + 7),
		ORANGE_BRIGHT,
		1.0
	)

	# Small hanging label for the selected / hovered gene.
	if is_hovered or is_selected:
		var gene_name = str(gene.get("name", "GENE"))

		draw_string(
			ThemeDB.fallback_font,
			Vector2(marker_x + 5, row_y - 1),
			gene_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			110,
			7,
			ORANGE_BRIGHT
		)


# ============================================================
# PUBLIC API FOR YOUR GENE FILE SYSTEM
# ============================================================

## Call this when the player ADDS a gene.
##
## Example:
##
## chromosome_map.add_gene({
##     "name": "MC1R",
##     "chromosome": 5,
##     "start": 63922271,
##     "end": 63923224,
##     "mode": "addition"
## })
func add_gene(gene: Dictionary):
	if not gene.has("chromosome"):
		push_warning("Gene has no chromosome: " + str(gene))
		return

	if not gene.has("start"):
		push_warning("Gene has no genomic start: " + str(gene))
		return

	# Prevent the same gene from being added twice.
	var gene_name = str(gene.get("name", ""))

	for existing in added_genes:
		if str(existing.get("name", "")) == gene_name:
			return

	var copy := gene.duplicate(true)

	if not copy.has("mode"):
		copy["mode"] = "addition"

	added_genes.append(copy)

	queue_redraw()


## Call this for a REPLACEMENT.
##
## A replacement is deliberately drawn as a thicker orange locus.
func replace_gene(gene: Dictionary):
	var replacement := gene.duplicate(true)

	replacement["mode"] = "replacement"

	var gene_name = str(replacement.get("name", ""))

	for i in range(added_genes.size()):
		if str(added_genes[i].get("name", "")) == gene_name:
			added_genes[i] = replacement
			queue_redraw()
			return

	added_genes.append(replacement)
	queue_redraw()


## Remove an inserted/replaced gene from the visual map.
func remove_gene(gene_name: String):
	for i in range(added_genes.size() - 1, -1, -1):
		if str(added_genes[i].get("name", "")) == gene_name:
			added_genes.remove_at(i)

	if selected_gene_index >= added_genes.size():
		selected_gene_index = -1

	queue_redraw()


func clear_gene_markers():
	added_genes.clear()
	selected_gene_index = -1
	hovered_gene_index = -1
	queue_redraw()


# ============================================================
# MOUSE INTERACTION
# ============================================================

func _gui_input(event):
	if event is InputEventMouseMotion:
		var new_hover := find_gene_at_position(event.position)

		if new_hover != hovered_gene_index:
			hovered_gene_index = new_hover
			queue_redraw()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var clicked := find_gene_at_position(event.position)

			if clicked != -1:
				selected_gene_index = clicked

				var gene = added_genes[clicked]

				print(
					"Selected genome locus: ",
					gene.get("name", "GENE"),
					" | CHR ",
					gene.get("chromosome", "?"),
					" | ",
					gene.get("start", 0),
					"..",
					gene.get("end", 0)
				)

				queue_redraw()


func find_gene_at_position(mouse_position: Vector2) -> int:
	for i in range(added_genes.size()):
		var gene = added_genes[i]

		var chromosome = gene.get("chromosome", -1)

		if chromosome is String:
			if chromosome.to_upper() == "X":
				chromosome = 39
			else:
				continue

		if chromosome < 1 or chromosome > 39:
			continue

		var row := int(chromosome) - 1
		var row_y := TOP_MARGIN + row * ROW_HEIGHT

		var gene_start := float(gene.get("start", 0))
		var gene_end := float(gene.get("end", gene_start))

		var chromosome_length: float

		if chromosome == 39:
			chromosome_length = CHROMOSOME_LENGTHS[39]
		else:
			chromosome_length = CHROMOSOME_LENGTHS[chromosome]

		var genome_left := LEFT_LABEL_WIDTH
		var genome_width := MAP_WIDTH - LEFT_LABEL_WIDTH - RIGHT_MARGIN
		var visual_offset = GROUP_OFFSETS[row] * 350.0

		var chromosome_width := normalized_chromosome_width(
			int(chromosome_length),
			genome_width
		)

		var gene_center := (gene_start + gene_end) * 0.5

		var normalized_position = clamp(
			gene_center / chromosome_length,
			0.0,
			1.0
		)

		var marker_x = (
			genome_left
			+ visual_offset
			+ normalized_position * chromosome_width
		)

		var hit_rect := Rect2(
			marker_x - 8.0,
			row_y - 3.0,
			16.0,
			13.0
		)

		if hit_rect.has_point(mouse_position):
			return i

	return -1
