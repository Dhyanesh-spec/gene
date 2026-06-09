extends Node

var TraitDatabase = preload("res://traitdatabase.gd").new()

func build_prompt(base_animal, traits):

	var prompt = ""

	prompt += "Pixel art creature, "
	prompt += base_animal + ", "

	for trait_id in traits:

		var data = TraitDatabase.TRAIT_DATABASE[trait_id]

		prompt += data["image_prompt"] + ", "

	prompt += "transparent background"

	return prompt
