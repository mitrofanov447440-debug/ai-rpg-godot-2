class_name NPCValidator
extends RefCounted

func validate(card: NPCCard, role: Dictionary, conflicts: Array) -> PackedStringArray:
	var issues := PackedStringArray()
	var tags: Array = card.tags
	for pair in conflicts:
		if pair is Array and pair.size() >= 2 and tags.has(pair[0]) and tags.has(pair[1]): issues.append("Конфликт тегов: %s / %s" % [pair[0], pair[1]])
	for item in card.selected_entries:
		if item is Dictionary:
			for excluded in item.get("excludes", []):
				if tags.has(excluded) or card.selected_entries.any(func(other): return str(other.get("id", "")) == str(excluded)): issues.append("%s исключает %s" % [item.get("id", "?"), excluded])
			for required in item.get("requires", []):
				if not tags.has(required): issues.append("%s требует тег %s" % [item.get("id", "?"), required])
	if card.age < int(role.get("age_range", [0, 120])[0]) or card.age > int(role.get("age_range", [0, 120])[1]): issues.append("Возраст вне диапазона роли")
	if card.personality.is_empty(): issues.append("Нет черты характера")
	if card.speech_style.is_empty(): issues.append("Нет манеры речи")
	if _intersects(tags, role.get("clothing_tags_forbidden", [])): issues.append("Одежда нарушает ограничения роли")
	return issues

func _intersects(a: Array, b: Array) -> bool:
	for v in a:
		if b.has(v): return true
	return false
