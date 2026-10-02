extends Node

const Card = preload("res://npc/npc_card.gd")
const SAVE_DIR := "user://saves/npc/"
var cache: Dictionary = {}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))

func get_card(npc_id: String) -> NPCCard:
	if cache.has(npc_id): return cache[npc_id]
	var path := SAVE_DIR + npc_id + ".json"
	if not FileAccess.file_exists(path): return null
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		var card := Card.from_dict(parsed); cache[npc_id] = card; return card
	return null

func exists(npc_id: String) -> bool:
	return cache.has(npc_id) or FileAccess.file_exists(SAVE_DIR + npc_id + ".json")

func save(card: NPCCard) -> bool:
	if card == null or card.id.is_empty(): return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	var file := FileAccess.open(SAVE_DIR + card.id + ".json", FileAccess.WRITE)
	if file == null: push_error("Не удалось сохранить НПС %s" % card.id); return false
	file.store_string(JSON.stringify(card.to_dict(), "\t")); cache[card.id] = card
	return true
