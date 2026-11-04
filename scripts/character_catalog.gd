extends RefCounted
class_name CharacterCatalog

const CHARACTERS := {
	"noam": {
		"name": "נועם",
		"subtitle": "המאוזן",
		"shirt": Color("#2876a8"),
		"pants": Color("#303947"),
		"skin": Color("#d9a27d")
	},
	"lior": {
		"name": "ליאור",
		"subtitle": "הזריז",
		"shirt": Color("#b65c37"),
		"pants": Color("#34333e"),
		"skin": Color("#e4b38d")
	},
	"amit": {
		"name": "עמית",
		"subtitle": "החזק",
		"shirt": Color("#477d5c"),
		"pants": Color("#242f36"),
		"skin": Color("#bd8969")
	}
}

static func get_character(character_id: String) -> Dictionary:
	return CHARACTERS.get(character_id, CHARACTERS["noam"])

static func ids() -> Array:
	return CHARACTERS.keys()
