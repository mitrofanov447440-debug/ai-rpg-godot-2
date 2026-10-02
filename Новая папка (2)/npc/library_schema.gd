class_name NPCLibrarySchema
extends RefCounted

static func validate_record(record: Dictionary, category: String) -> PackedStringArray:
	var errors := PackedStringArray()
	if str(record.get("id", "")).strip_edges().is_empty(): errors.append("%s: пустой id" % category)
	if str(record.get("text", "")).strip_edges().is_empty() and category != "roles": errors.append("%s/%s: пустой text" % [category, record.get("id", "?")])
	if category != "roles":
		if int(record.get("weight", 0)) < 0: errors.append("%s/%s: отрицательный weight" % [category, record.get("id", "?")])
		if int(record.get("min_wealth", 0)) > int(record.get("max_wealth", 12)): errors.append("%s/%s: min_wealth больше max_wealth" % [category, record.get("id", "?")])
	return errors
