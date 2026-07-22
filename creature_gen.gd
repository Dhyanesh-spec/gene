extends Node

var TraitDatabase = preload("res://traitdatabase.gd").new()

func build_prompt(base_animal, traits):

	var prompt = ""

	prompt += "Pixel art creature, "
	prompt += base_animal + ", "
	prompt += "Pixel art creature sprite, single creature, solid black background (#000000), no light, no shadows"
	for trait_id in traits:

		var data = TraitDatabase.TRAIT_DATABASE[trait_id]

		prompt += data["image_prompt"] + ", "
		prompt += data["source_animals"][0] + ", "



	return prompt
