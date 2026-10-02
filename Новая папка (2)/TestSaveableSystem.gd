class_name TestSaveableSystem
extends SaveableSystem

var value: int = 0
var ids: Array = []


func get_system_id() -> String:
	return "test_system"


func get_system_version() -> int:
	return 1


func save_data() -> Dictionary:
	return {
		"value": value,
		"ids": ids.duplicate(true)
	}


func load_data(data: Dictionary) -> void:
	if data.has("value"):
		value = int(data["value"])
	if data.has("ids"):
		ids = Array(data["ids"])


func resolve_links() -> void:
	pass


func reset_to_new_game() -> void:
	value = 0
	ids.clear()
