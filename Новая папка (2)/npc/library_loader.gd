class_name NPCLibraryLoader
extends RefCounted

const ROOT := "res://data/npc_library/"
const Schema = preload("res://npc/library_schema.gd")
var categories: Dictionary = {}
var roles: Dictionary = {}
var conflicts: Array = []
var errors: PackedStringArray = []

func load_all() -> bool:
	categories.clear(); roles.clear(); conflicts.clear(); errors.clear()
	var catalog = _read_json(ROOT + "categories.json", [])
	if not catalog is Array:
		errors.append("categories.json должен содержать массив")
		return false
	for category in catalog:
		if not category is Dictionary: continue
		var key := str(category.get("id", ""))
		if key.is_empty(): continue
		var rows = _read_json(ROOT + key + ".json", [])
		if not rows is Array:
			errors.append("%s.json должен содержать массив" % key); continue
		categories[key] = rows
		var seen := {}
		for row in rows:
			if not row is Dictionary: errors.append("%s: запись не объект" % key); continue
			for issue in Schema.validate_record(row, key): errors.append(issue)
			var rid := str(row.get("id", ""))
			if seen.has(rid): errors.append("%s: повтор id %s" % [key, rid])
			seen[rid] = true
	var role_rows = _read_json(ROOT + "roles.json", [])
	if role_rows is Array:
		for role in role_rows:
			if role is Dictionary:
				roles[str(role.get("id", ""))] = role
				for issue in Schema.validate_record(role, "roles"): errors.append(issue)
	else: errors.append("roles.json должен содержать массив")
	var conflict_rows = _read_json(ROOT + "conflicts.json", [])
	if conflict_rows is Array: conflicts = conflict_rows
	else: errors.append("conflicts.json должен содержать массив")
	return errors.is_empty()

func get_records(category: String) -> Array:
	return categories.get(category, [])

func _read_json(path: String, fallback):
	if not FileAccess.file_exists(path):
		errors.append("Файл не найден: %s" % path); return fallback
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: errors.append("Не удалось прочитать %s" % path); return fallback
	var parsed = JSON.parse_string(file.get_as_text().trim_prefix("\uFEFF"))
	if parsed == null: errors.append("Некорректный JSON: %s" % path); return fallback
	return parsed
