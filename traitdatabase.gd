extends Node

var TRAIT_DATABASE = {
	"digitigrade_locomotion": {
		"name": "Digitigrade Locomotion",
		"category": "Mobility",
		"icon": preload("res://Cat.png.png"),
		"dna":"ATGCCGTA",
		"description": "Locomotion based on toe-walking posture, increasing stride length and movement efficiency.",
		"gameplay": {
			"mobility": 15,
			
		},

		"source_animals": [
			"Gray Wolf",
			"Cheetah",
			"Red Fox",
            "African Wild Dog"
		],

		"image_prompt": "wolf-like digitigrade legs, raised heel posture, longer lower legs, agile predator limb structure",

	},

	"dermal_armor": {
		"name": "Dermal Armor",
		"category": "Defense",
		"icon": preload("res://dillo.png"),
		"description": "Reinforced skin supported by bony plates or thick keratinized structures.",
		"dna": "GGTTAACC",

		"gameplay": {
			"defense": 25,
			
		},

		"source_animals": [
			"Armadillo",
			"Saltwater Crocodile",
			"Pangolin",
            "Alligator Snapping Turtle"
		],

		"image_prompt": "armadillo-like armor plates along back and shoulders, segmented protective shell, thick armored skin",

	},

	"efficient_oxygen_exchange": {
		"name": "Efficient Oxygen Exchange",
		"category": "Metabolism",
		"icon": preload("res://Bird.png"),
		"description": "Enhanced respiratory structures improve endurance during prolonged activity.",
		"dna": "CCGATGGA" ,
		"gameplay": {
			
			"endurance": 15
		},

		"source_animals": [
			"Bar-Headed Goose",
			"Peregrine Falcon",
			"Pronghorn",
            "Albatross"
		],

		"image_prompt": "bird-like expanded chest, larger ribcage, athletic body build, streamlined endurance runner anatomy",
	},

	"fat_reserve_manipulation": {
		"name": "Fat Reserve Manipulation",
		"category": "Metabolism",
		"icon": preload("res://Camel.png"),
		"description": "Specialized fat utilization allow survival during periods of scarcity.",
		"dna": "TTAAGCCG" ,
		"gameplay": {
			"fat_storage": 25,
			
		},

		"source_animals": [
			"Dromedary Camel",
			"Emperor Penguin",
			"Brown Bear",
            "Elephant Seal"
		],

		"image_prompt": "camel-like fat hump, thicker body reserves, enlarged back storage tissue",
	},

	"thermoregulatory_insulation": {
		"name": "Thermoregulatory Insulation",
		"category": "Environmental",
		"icon": preload("res://Artic_fox.png"),
		"description": "Dense insulating layers improve survival in extreme cold.",
		"dna": "CGGATATC" ,
		"gameplay": {
			"thermoregulation": 30,
			
		},

		"source_animals": [
			"Polar Bear",
			"Arctic Fox",
			"Musk Ox",
            "Emperor Penguin"
		],

		"image_prompt": "thick arctic fur coat, dense fluffy neck fur, winter-adapted insulation, cold climate mammal appearance",
	}
}
