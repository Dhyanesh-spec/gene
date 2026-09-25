extends TileMap

# =========================================================
# CONFIG
# =========================================================

@export var player: Node2D

const CHUNK_WIDTH := 282
const CHUNK_HEIGHT := 256

const SOURCE_ID := 0
const RENDER_RADIUS := 5        # Increased to ensure viewports never hit chunk limits
const CULL_RADIUS := 9

var world_seed := 12345

# 5x3 Atlas Mapping based on your TileSet dock
var chunk_sockets := {
	# Row 0: Paths & Grass
	Vector2i(0, 0): {"N": "grass", "E": "grass", "S": "grass", "W": "grass"},  # Plain Grass
	Vector2i(1, 0): {"N": "grass", "E": "path",  "S": "grass", "W": "path"},   # Horizontal Path
	Vector2i(2, 0): {"N": "path",  "E": "path",  "S": "path",  "W": "path"},   # 4-Way Cross Path
	Vector2i(3, 0): {"N": "path",  "E": "grass", "S": "grass", "W": "grass"},  # Vertical Path End
	Vector2i(4, 0): {"N": "path",  "E": "grass", "S": "path",  "W": "grass"},  # Vertical Path Straight

	# Row 1: Additional Paths & Grass
	Vector2i(0, 1): {"N": "grass", "E": "path",  "S": "grass", "W": "path"},   # Alt Horizontal
	Vector2i(1, 1): {"N": "path",  "E": "path",  "S": "path",  "W": "path"},   # Alt Cross
	Vector2i(2, 1): {"N": "grass", "E": "path",  "S": "grass", "W": "path"},   # Alt Straight
	Vector2i(3, 1): {"N": "grass", "E": "grass", "S": "grass", "W": "grass"},  # Alt Grass 1
	Vector2i(4, 1): {"N": "grass", "E": "grass", "S": "grass", "W": "grass"},  # Alt Grass 2

	# Row 2: Water Coastlines
	Vector2i(0, 2): {"N": "grass", "E": "path",  "S": "grass", "W": "grass"},  # Shore Left
	Vector2i(1, 2): {"N": "path",  "E": "path",  "S": "grass", "W": "grass"},  # Shore Mid
	Vector2i(2, 2): {"N": "path",  "E": "grass", "S": "grass", "W": "grass"},  # Shore Right
	Vector2i(3, 2): {"N": "grass", "E": "grass", "S": "grass", "W": "grass"},  # Water Corner 1
	Vector2i(4, 2): {"N": "grass", "E": "grass", "S": "grass", "W": "grass"},  # Water Corner 2
}

# =========================================================
# STATE
# =========================================================

var generated_coords := {}
var last_player_chunk := Vector2i(999999, 999999)
var rng := RandomNumberGenerator.new()
var biome_noise := FastNoiseLite.new()

# =========================================================
# LIFECYCLE
# =========================================================

func _ready() -> void:
	biome_noise.seed = world_seed
	biome_noise.frequency = 0.03

	if player == null:
		print("ERROR: Player is null! Assign Player in the Inspector.")
		return

	await get_tree().process_frame
	
	var player_chunk = world_pos_to_chunk(player.global_position)
	last_player_chunk = player_chunk
	generate_chunks_around(player_chunk)


func _process(_delta: float) -> void:
	if player == null:
		return

	var player_chunk = world_pos_to_chunk(player.global_position)

	if player_chunk != last_player_chunk:
		last_player_chunk = player_chunk
		generate_chunks_around(player_chunk)
		cull_far_chunks(player_chunk)


func generate_chunks_around(center_chunk: Vector2i) -> void:
	var coords_to_gen: Array[Vector2i] = []
	
	for x in range(-RENDER_RADIUS, RENDER_RADIUS + 1):
		for y in range(-RENDER_RADIUS, RENDER_RADIUS + 1):
			coords_to_gen.append(center_chunk + Vector2i(x, y))

	# Generate inside-out around player position
	coords_to_gen.sort_custom(func(a, b): 
		return a.distance_squared_to(center_chunk) < b.distance_squared_to(center_chunk)
	)

	for coord in coords_to_gen:
		generate_chunk(coord)


func world_pos_to_chunk(pos: Vector2) -> Vector2i:
	return local_to_map(to_local(pos))

# =========================================================
# GENERATION LOGIC
# =========================================================

func generate_chunk(coord: Vector2i) -> void:
	if generated_coords.has(coord):
		return

	var need_n = get_neighbor_edge(coord, Vector2i(0, -1), "S")
	var need_w = get_neighbor_edge(coord, Vector2i(-1, 0), "E")
	var need_s = get_neighbor_edge(coord, Vector2i(0, 1), "N")
	var need_e = get_neighbor_edge(coord, Vector2i(1, 0), "W")

	# 1. Strict Socket Matching
	var candidates: Array[Vector2i] = []
	for atlas_coord in chunk_sockets.keys():
		var s = chunk_sockets[atlas_coord]
		if (need_n == null or s["N"] == need_n) \
		and (need_e == null or s["E"] == need_e) \
		and (need_s == null or s["S"] == need_s) \
		and (need_w == null or s["W"] == need_w):
			candidates.append(atlas_coord)

	# 2. Soft Fallback: Match highest count of neighbor edges
	if candidates.is_empty():
		var max_matches = 0
		var match_map := {}

		for atlas_coord in chunk_sockets.keys():
			var s = chunk_sockets[atlas_coord]
			var match_count = 0
			if need_n != null and s["N"] == need_n: match_count += 1
			if need_e != null and s["E"] == need_e: match_count += 1
			if need_s != null and s["S"] == need_s: match_count += 1
			if need_w != null and s["W"] == need_w: match_count += 1
			
			if match_count > max_matches:
				max_matches = match_count

			if not match_map.has(match_count):
				match_map[match_count] = []
			match_map[match_count].append(atlas_coord)

		if max_matches > 0:
			candidates.assign(match_map[max_matches])

	# 3. Ultimate Fallback: Default to Plain Grass Vector2i(0, 0) so no empty spaces occur
	if candidates.is_empty():
		candidates = [Vector2i(0, 0)]

	rng.seed = hash(str(world_seed, "_", coord.x, "_", coord.y))

	var chosen: Vector2i = select_weighted_candidate(coord, candidates, [need_n, need_e, need_s, need_w])

	# Render directly to TileMap layer 0
	set_cell(0, coord, SOURCE_ID, chosen)
	generated_coords[coord] = chosen


func select_weighted_candidate(coord: Vector2i, candidates: Array[Vector2i], neighbor_edges: Array) -> Vector2i:
	if candidates.size() == 1:
		return candidates[0]

	var weights: Array[float] = []
	var total_weight: float = 0.0
	var noise_val: float = biome_noise.get_noise_2d(coord.x, coord.y)

	for cand in candidates:
		var sockets = chunk_sockets[cand]
		var weight: float = 1.0
		var water_count: int = 0

		for dir in ["N", "E", "S", "W"]:
			if sockets[dir] == "water":
				water_count += 1

		if "water" in neighbor_edges and water_count > 0:
			weight += 10.0 * water_count

		if noise_val < -0.1:
			weight += (water_count * 4.0)
		else:
			weight += ((4 - water_count) * 2.0)

		weights.append(weight)
		total_weight += weight

	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0

	for i in range(candidates.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return candidates[i]

	return candidates[0]


func get_neighbor_edge(coord: Vector2i, dir: Vector2i, side: String):
	var n_coord = coord + dir
	
	if not generated_coords.has(n_coord):
		return null

	var n_atlas: Vector2i = generated_coords[n_coord]
	if not chunk_sockets.has(n_atlas):
		return null

	return chunk_sockets[n_atlas][side]

# =========================================================
# CULLING
# =========================================================

func cull_far_chunks(center: Vector2i) -> void:
	var to_remove := []
	for coord in generated_coords.keys():
		if abs(coord.x - center.x) > CULL_RADIUS or abs(coord.y - center.y) > CULL_RADIUS:
			to_remove.append(coord)

	for coord in to_remove:
		erase_cell(0, coord)
		generated_coords.erase(coord)
