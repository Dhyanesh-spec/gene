extends Control

var values = [0,0,0,0,0]

func _draw():

	var center = size / 2
	var radius = 70

	var points = []

	for i in range(5):

		var angle = deg_to_rad(-90 + i * 72)

		var length = radius * values[i] / 30.0

		points.append(
			center + Vector2(
				cos(angle),
				sin(angle)
			) * length
		)

	# Draw grid
	for i in range(5):

		var angle = deg_to_rad(-90 + i * 72)

		var end = center + Vector2(
			cos(angle),
			sin(angle)
		) * radius

		draw_line(center, end, Color.GREEN, 1)

	# Draw creature profile
	draw_polygon(
		points,
		[
			Color(0,1,1,0.5),
			Color(0,1,1,0.5),
			Color(0,1,1,0.5),
			Color(0,1,1,0.5),
			Color(0,1,1,0.5)
		]
	)
