extends Tree

signal gene_selected(
	trait_id: String,
	gene_data: Dictionary
)

var TraitDatabase = preload(
	"res://traitdatabase.gd"
).new()


func _ready() -> void:
	hide_root = true
	columns = 1

	populate_gene_tree()

	item_selected.connect(
		_on_item_selected
	)


func populate_gene_tree() -> void:
	clear()

	var root := create_item()

	var categories: Dictionary = {}

	for trait_id in TraitDatabase.TRAIT_DATABASE.keys():

		var data: Dictionary = (
			TraitDatabase.TRAIT_DATABASE[trait_id]
		)

		var category_name: String = str(
			data.get(
				"category",
				"GENERAL"
			)
		)

		if not categories.has(category_name):

			var category: TreeItem = (
				create_item(root)
			)

			category.set_text(
				0,
				category_name
			)

			category.set_metadata(
				0,
				{
					"type": "folder",
					"category": category_name
				}
			)

			# Folder/category rows are not themselves selectable.
			category.set_selectable(
				0,
				false
			)

			categories[category_name] = (
				category
			)

		var file: TreeItem = create_item(
			categories[category_name]
		)

		file.set_text(
			0,
			str(
				data.get(
					"name",
					trait_id
				)
			)
		)

		file.set_metadata(
			0,
			{
				"type": "gene",
				"trait_id": str(trait_id),
				"data": data
			}
		)


func _on_item_selected() -> void:
	var item: TreeItem = get_selected()

	if item == null:
		return

	var metadata = item.get_metadata(0)

	if metadata == null:
		return

	if not metadata is Dictionary:
		return

	if metadata.get("type", "") != "gene":
		return

	var trait_id := str(
		metadata.get(
			"trait_id",
			""
		)
	)

	var gene_data = metadata.get(
		"data",
		{}
	)

	if trait_id == "":
		return

	if not gene_data is Dictionary:
		gene_data = {}

	gene_selected.emit(
		trait_id,
		gene_data
	)
