class_name NPCGenerator
extends RefCounted

const Card = preload("res://npc/npc_card.gd")
const Loader = preload("res://npc/library_loader.gd")
const Picker = preload("res://npc/library_picker.gd")
const Validator = preload("res://npc/npc_validator.gd")
var library: NPCLibraryLoader

func _init() -> void:
	library = Loader.new(); library.load_all()

func build(request: Dictionary) -> NPCCard:
	var role_id := str(request.get("role", ""))
	if not library.roles.has(role_id): push_error("Неизвестная роль НПС: %s" % role_id); return null
	var role: Dictionary = library.roles[role_id]
	var seed_value: int = int(request.get("seed", randi()))
	var rng := RandomNumberGenerator.new(); rng.seed = seed_value
	var wealth_range: Array = role.get("default_wealth", [1, 2])
	var wealth: int = clampi(int(request.get("wealth", rng.randi_range(int(wealth_range[0]), int(wealth_range[1])))), 0, 12)
	var gender := str(request.get("gender", ""))
	if gender.is_empty():
		var bias: Dictionary = role.get("gender_bias", {"female":0.5,"male":0.5})
		gender = _pick_weighted(bias, rng, "male")
	var disposition := str(request.get("disposition", ""))
	if disposition.is_empty():
		var disp_bias = role.get("disposition_bias", null)
		if disp_bias is Dictionary and not disp_bias.is_empty():
			disposition = _pick_weighted(disp_bias, rng, "peaceful")
		elif role.get("default_disposition") is Dictionary:
			disposition = _pick_weighted(role.get("default_disposition"), rng, "peaceful")
		else:
			disposition = str(role.get("default_disposition", "peaceful"))
	var age_range: Array = role.get("age_range", [18, 60])
	var card := Card.new(); card.role_id = role_id; card.seed = seed_value; card.gender = gender; card.age = rng.randi_range(int(age_range[0]), int(age_range[1])); card.wealth = wealth; card.setting = str(request.get("setting", "")); card.id = "npc_%s_%d" % [role_id, abs(hash("%s|%s|%d|%s|%s" % [role_id, card.setting, seed_value, gender, wealth]))]; card.disposition = disposition; card.combat_capable = bool(role.get("combat_capable", false))
	var context := {"role":role_id,"role_data":role,"wealth":wealth,"tags":[],"selected_ids":[],"forbidden_tags":request.get("forbidden_tags", []),"category":""}
	var picker := Picker.new(library, rng)
	var gender_category := "names_female" if gender == "female" else "names_male"
	var first := _pick_one(picker, gender_category, context); var surname := _pick_one(picker, "surnames", context)
	card.name = (str(first.get("text", "Безымянный")) + " " + str(surname.get("text", ""))).strip_edges()
	var categories: Array = ["body_build", "hair", "eyes", "skin_marks", "clothing_top", "clothing_bottom", "clothing_outer", "footwear", "accessories", "personality", "speech_style", "quirks"]
	for required_category in role.get("required_categories", []):
		if not categories.has(required_category): categories.append(required_category)
	for category in categories:
		var count := 1
		if category == "skin_marks" or category == "quirks": count = rng.randi_range(0, 2)
		if category == "accessories": count = rng.randi_range(0, 1)
		if category == "clothing_outer": count = 1 if rng.randf() < 0.6 else 0
		if category == "quirks" and not role.get("required_categories", []).has(category): count = 0
		context.category = category
		var chosen: Array = picker.pick(category, context, count)
		for entry in chosen:
			card.selected_entries.append(entry.duplicate(true)); _add_tags(card.tags, entry.get("tags", []))
			if not ["body_build", "hair", "eyes", "skin_marks", "clothing_top", "clothing_bottom", "clothing_outer", "footwear", "accessories", "personality", "speech_style", "quirks"].has(category):
				card.portrait_slots[category] = entry.text
			match category:
				"body_build": card.appearance["build"] = entry.text
				"hair": card.appearance["hair"] = entry.text
				"eyes": card.appearance["eyes"] = entry.text
				"skin_marks":
					if not card.appearance.has("marks"): card.appearance["marks"] = []
					card.appearance["marks"].append(entry.text)
				"clothing_top": card.clothing["top"] = entry.text
				"clothing_bottom": card.clothing["bottom"] = entry.text
				"clothing_outer": card.clothing["outer"] = entry.text
				"footwear": card.clothing["footwear"] = entry.text
				"accessories":
					if not card.clothing.has("accessories"): card.clothing["accessories"] = []
					card.clothing["accessories"].append(entry.text)
				"personality": card.personality.append(entry.text)
				"speech_style": card.speech_style = entry.text
				"quirks": card.quirks.append(entry.text)
	card.tags.append_array(request.get("must_have_tags", [])); _unique(card.tags)
	var issues := Validator.new().validate(card, role, library.conflicts)
	if not issues.is_empty(): push_warning("Карточка %s: %s" % [card.id, "; ".join(issues)])
	return card

func _pick_one(picker, category: String, context: Dictionary) -> Dictionary:
	context.category = category
	var rows: Array = picker.pick(category, context, 1)
	if rows.is_empty(): return {"text":""}
	return rows[0]

func _add_tags(target: Array, values: Array) -> void:
	for value in values:
		if not target.has(str(value)): target.append(str(value))

func _unique(values: Array) -> void:
	var clean: Array = []
	for value in values:
		if not clean.has(value): clean.append(value)
	values.assign(clean)

func _pick_weighted(bias: Dictionary, rng: RandomNumberGenerator, fallback: String = "") -> String:
	if bias.is_empty(): return fallback
	var total := 0.0
	for value in bias.values(): total += float(value)
	if total <= 0.0: return fallback
	var roll := rng.randf() * total
	for key in bias:
		roll -= float(bias[key])
		if roll <= 0.0: return str(key)
	return str(bias.keys()[0])

