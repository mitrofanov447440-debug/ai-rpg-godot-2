class_name NPCLibraryPicker
extends RefCounted

var rng: RandomNumberGenerator
var loader: NPCLibraryLoader

func _init(source: NPCLibraryLoader, random: RandomNumberGenerator) -> void:
	loader = source; rng = random

func pick(category: String, context: Dictionary, count: int = 1) -> Array:
	var selected: Array = []
	for n in count:
		var candidates: Array = _candidates(category, context, true, true)
		if candidates.is_empty(): candidates = _candidates(category, context, false, true)
		if candidates.is_empty(): candidates = _candidates(category, context, false, false)
		if candidates.is_empty():
			push_warning("Нет совместимых записей для категории %s" % category)
			break
		var total := 0.0
		for entry in candidates: total += maxf(0.001, float(entry.get("weight", 1)) * _preference_multiplier(entry, context))
		var roll := rng.randf() * total
		for entry in candidates:
			roll -= maxf(0.001, float(entry.get("weight", 1)) * _preference_multiplier(entry, context))
			if roll <= 0.0:
				selected.append(entry); context.selected_ids.append(str(entry.id)); context.tags.append_array(entry.get("tags", [])); break
	return selected

func _candidates(category: String, context: Dictionary, preferences: bool, wealth: bool) -> Array:
	var result: Array = []
	var role: Dictionary = context.role_data
	for entry in loader.get_records(category):
		if context.selected_ids.has(str(entry.get("id", ""))): continue
		if _intersects(entry.get("tags", []), context.get("forbidden_tags", [])): continue
		if not entry.get("allowed_roles", []).is_empty() and not entry.allowed_roles.has(context.role): continue
		if entry.get("forbidden_roles", []).has(context.role): continue
		if wealth and (context.wealth < int(entry.get("min_wealth", 0)) or context.wealth > int(entry.get("max_wealth", 12))): continue
		var present: Array = context.tags
		var required: Array = entry.get("requires", [])
		if not required.is_empty() and not _contains_all(present, required): continue
		var excluded: Array = entry.get("excludes", [])
		if _intersects(present, excluded) or _intersects(context.selected_ids, excluded): continue
		if category.begins_with("clothing_") or category in ["footwear", "accessories"]:
			if _intersects(entry.get("tags", []), role.get("clothing_tags_forbidden", [])): continue
			var required_clothes: Array = role.get("clothing_tags_required", [])
			if not required_clothes.is_empty() and not _intersects(entry.get("tags", []), required_clothes): continue
		if category == "personality" and _intersects(entry.get("tags", []), role.get("personality_tags_forbidden", [])): continue
		if not preferences and category == "personality" and _intersects(entry.get("tags", []), role.get("personality_tags_forbidden", [])): continue
		result.append(entry)
	return result

func _preference_multiplier(entry: Dictionary, context: Dictionary) -> float:
	var role: Dictionary = context.role_data
	var preferred: Array = role.get("personality_tags_preferred", []) if context.category == "personality" else []
	return 3.0 if _intersects(entry.get("tags", []), preferred) else 1.0

func _contains_all(source: Array, required: Array) -> bool:
	for value in required:
		if not source.has(value): return false
	return true

func _intersects(a: Array, b: Array) -> bool:
	for value in a:
		if b.has(value): return true
	return false
