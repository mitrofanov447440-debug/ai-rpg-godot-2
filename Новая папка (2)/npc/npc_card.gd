class_name NPCCard
extends Resource

@export var id := ""
@export var role_id := ""
@export var seed: int = 0
@export var name := ""
@export var gender := ""
@export var age: int = 0
@export_range(0, 12) var wealth: int = 1
@export var setting := ""
@export var appearance: Dictionary = {}
@export var clothing: Dictionary = {}
@export var personality: Array[String] = []
@export var speech_style := ""
@export var quirks: Array[String] = []
@export var tags: Array[String] = []
@export var disposition := "peaceful"
@export var combat_capable := false
@export var backstory := ""
@export var motivation := ""
@export var ai_filled := false
@export var portrait_slots: Dictionary = {}
@export var selected_entries: Array[Dictionary] = []

func to_dict() -> Dictionary:
	return {"id":id,"role_id":role_id,"seed":seed,"name":name,"gender":gender,"age":age,"wealth":wealth,"setting":setting,"appearance":appearance,"clothing":clothing,"personality":personality,"speech_style":speech_style,"quirks":quirks,"tags":tags,"disposition":disposition,"combat_capable":combat_capable,"backstory":backstory,"motivation":motivation,"ai_filled":ai_filled,"portrait_slots":portrait_slots,"selected_entries":selected_entries}

static func from_dict(data: Dictionary) -> NPCCard:
	var card := NPCCard.new()
	for key in data:
		if key in ["appearance", "clothing", "portrait_slots"] and data[key] is Dictionary:
			card.set(key, data[key].duplicate(true))
		elif key in ["personality", "quirks", "tags", "selected_entries"] and data[key] is Array:
			card.set(key, data[key].duplicate(true))
		elif key in ["id", "role_id", "seed", "name", "gender", "age", "wealth", "setting", "speech_style", "disposition", "combat_capable", "backstory", "motivation", "ai_filled"]:
			card.set(key, data[key])
	return card
