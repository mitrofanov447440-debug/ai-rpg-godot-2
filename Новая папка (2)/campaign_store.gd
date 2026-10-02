extends RefCounted

const SAVE_PATH := "user://campaign.json"

static func load_campaign(default_data: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		save_campaign(default_data)
		return default_data.duplicate(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_data.duplicate(true)
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return default_data.duplicate(true)
	var campaign: Dictionary = parsed
	for key in default_data:
		if not campaign.has(key):
			campaign[key] = default_data[key].duplicate(true) if default_data[key] is Array or default_data[key] is Dictionary else default_data[key]
	return campaign

static func save_campaign(campaign: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(campaign, "  "))

static func build_compact_context(campaign: Dictionary) -> String:
	var hero: Dictionary = campaign.get("hero", {})
	var lines := PackedStringArray()
	lines.append("ГЕРОЙ: %s, %s, %s, %s лет, ур. %s." % [hero.get("name", ""), hero.get("race", ""), hero.get("class", ""), hero.get("age", ""), hero.get("level", "")])
	lines.append("СОСТОЯНИЕ: Здоровье %s; выносливость %s; мана %s; аура %s; опыт %s." % [hero.get("health", ""), hero.get("stamina", ""), hero.get("mana", ""), hero.get("aura", ""), hero.get("experience", "")])
	var stats: Dictionary = hero.get("stats", {})
	lines.append("ХАРАКТЕРИСТИКИ: Сила %s; Ловкость %s; Интеллект %s; Внимательность %s; Харизма %s; защита %s." % [stats.get("strength", ""), stats.get("dexterity", ""), stats.get("intelligence", ""), stats.get("attention", ""), stats.get("charisma", ""), stats.get("defense", "")])
	lines.append("НАВЫКИ: %s" % hero.get("skills", ""))
	var inventory_names := PackedStringArray()
	for item in campaign.get("inventory", []):
		inventory_names.append(str(item))
	lines.append("ИНВЕНТАРЬ: %s" % ", ".join(inventory_names))
	lines.append("ОТНОШЕНИЯ:")
	for relation in campaign.get("relations", []):
		lines.append("- %s (%s): %s" % [relation.get("name", ""), relation.get("attitude", ""), relation.get("summary", "")])
	lines.append("ПАМЯТЬ СОБЫТИЙ: %s" % campaign.get("history", ""))
	lines.append("ЗАПИСИ БИБЛИОТЕКИ:")
	for entry in campaign.get("library", []):
		lines.append("- [%s] %s: %s" % [entry.get("kind", ""), entry.get("title", ""), entry.get("body", "")])
	lines.append("ПОСЛЕДНИЕ РЕПЛИКИ:")
	var messages: Array = campaign.get("messages", [])
	var first_recent: int = maxi(0, messages.size() - 8)
	for index in range(first_recent, messages.size()):
		var message: Dictionary = messages[index]
		lines.append("%s: %s" % [message.get("role", ""), message.get("text", "")])
	return "\n".join(lines)

static func build_model_request(campaign: Dictionary) -> Dictionary:
	var conversation: Array = []
	var messages: Array = campaign.get("messages", [])
	var first_recent: int = maxi(0, messages.size() - 8)
	for index in range(first_recent, messages.size()):
		var message: Dictionary = messages[index]
		var role := "user"
		if message.get("role", "") == "Рассказчик":
			role = "assistant"
		elif message.get("role", "") == "Система":
			role = "system"
		conversation.append({"role":role, "content":message.get("text", "")})
	return {
		"system_context": build_compact_context(campaign),
		"messages": conversation
	}
