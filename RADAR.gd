extends Control

var values = [7, 5, 2, 1, 1]
var max_value = 30.0

func _draw():
	var center = size / 2
	var radius = 45

	# Draw grid rings
	for ring in range(1, 6):
		var ring_points = []

		for i in range(5):
			var angle = deg_to_rad(-90 + i * 72)

			ring_points.append(
				center + Vector2(
					cos(angle),
					sin(angle)
				) * radius * ring / 5.0
			)

		for i in range(5):
			draw_line(
				ring_points[i],
				ring_points[(i + 1) % 5],
				Color(0, 1, 0),
				1
			)

	# Draw radial spokes
	for i in range(5):
		var angle = deg_to_rad(-90 + i * 72)

		var end = center + Vector2(
			cos(angle),
			sin(angle)
		) * radius

		draw_line(center, end, Color.GREEN, 1)

	# Creature stats polygon
	var stat_points = []

	for i in range(5):
		var angle = deg_to_rad(-90 + i * 72)

		var length = radius * values[i] / max_value

		stat_points.append(
			center + Vector2(
				cos(angle),
				sin(angle)
			) * length
		)

	# Fill
	draw_colored_polygon(
		stat_points,
		Color(0, 1, 1, 0.3)
	)

	# Outline
	for i in range(5):
		draw_line(
			stat_points[i],
			stat_points[(i + 1) % 5],
			Color.CYAN,
			2
		)
