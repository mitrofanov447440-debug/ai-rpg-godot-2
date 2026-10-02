extends Control

const ROOT := "res://data/npc_library/"
var category_select: OptionButton
var editor: TextEdit
var status: Label
var current_file := ""

func _ready() -> void:
	_build()
	_load_categories()

func _build() -> void:
	var layout := VBoxContainer.new(); layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layout.add_theme_constant_override("margin_left", 18); layout.add_theme_constant_override("margin_right", 18); layout.add_theme_constant_override("margin_top", 18); layout.add_theme_constant_override("margin_bottom", 18); add_child(layout)
	var header := HBoxContainer.new(); layout.add_child(header)
	var title := Label.new(); title.text = "Редактор библиотеки НПС"; title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(title)
	category_select = OptionButton.new(); category_select.item_selected.connect(_select_category); header.add_child(category_select)
	var new_category := Button.new(); new_category.text = "Новая категория"; new_category.pressed.connect(_new_category); header.add_child(new_category)
	editor = TextEdit.new(); editor.size_flags_vertical = Control.SIZE_EXPAND_FILL; editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL; layout.add_child(editor)
	var footer := HBoxContainer.new(); layout.add_child(footer)
	var save := Button.new(); save.text = "Сохранить (создать .bak)"; save.pressed.connect(_save); footer.add_child(save)
	var validate := Button.new(); validate.text = "Проверить JSON"; validate.pressed.connect(_validate); footer.add_child(validate)
	status = Label.new(); status.size_flags_horizontal = Control.SIZE_EXPAND_FILL; footer.add_child(status)

func _load_categories() -> void:
	category_select.clear()
	category_select.add_item("Роли · roles.json")
	category_select.add_item("Конфликты · conflicts.json")
	var file := FileAccess.open(ROOT + "categories.json", FileAccess.READ)
	if file:
		var rows = JSON.parse_string(file.get_as_text())
		if rows is Array:
			for row in rows:
				if row is Dictionary: category_select.add_item("%s · %s.json" % [row.get("display_name", row.get("id", "")), row.get("id", "")])
	_select_category(0)

func _select_category(index: int) -> void:
	if index == 0: current_file = "roles.json"
	elif index == 1: current_file = "conflicts.json"
	else: current_file = category_select.get_item_text(index).get_slice("·", 1).strip_edges()
	var file := FileAccess.open(ROOT + current_file, FileAccess.READ)
	editor.text = file.get_as_text() if file else "[]"
	status.text = current_file

func _save() -> void:
	var parsed = JSON.parse_string(editor.text)
	if parsed == null: status.text = "Ошибка JSON — сохранение отменено"; return
	var path := ROOT + current_file
	if FileAccess.file_exists(path):
		var old := FileAccess.open(path, FileAccess.READ)
		if old:
			var backup := FileAccess.open(path + ".bak", FileAccess.WRITE)
			if backup: backup.store_string(old.get_as_text())
	var out := FileAccess.open(path, FileAccess.WRITE)
	if out == null: status.text = "Не удалось записать файл"; return
	out.store_string(JSON.stringify(parsed, "\t")); status.text = "Сохранено: %s" % current_file

func _validate() -> void:
	var parsed = JSON.parse_string(editor.text)
	status.text = "Корректный JSON" if parsed != null else "Ошибка JSON: проверьте запятые и скобки"

func _new_category() -> void:
	var dialog := ConfirmationDialog.new(); dialog.title = "Новая категория"
	var input := LineEdit.new(); input.placeholder_text = "например, pets"; input.custom_minimum_size.x = 300; dialog.add_child(input); add_child(dialog)
	dialog.confirmed.connect(func():
		var key := input.text.strip_edges().to_lower().replace(" ", "_")
		if not key.is_valid_identifier() or key in ["roles", "conflicts", "categories"]: status.text = "Введите допустимый уникальный id"; return
		var rows := FileAccess.open(ROOT + "categories.json", FileAccess.READ); var data = JSON.parse_string(rows.get_as_text()) if rows else []
		if not data is Array: data = []
		for row in data:
			if row.get("id", "") == key: status.text = "Такая категория уже есть"; return
		data.append({"id":key,"display_name":key.capitalize(),"required":false,"chance":0.25,"max_per_npc":1})
		var catalog := FileAccess.open(ROOT + "categories.json", FileAccess.WRITE); catalog.store_string(JSON.stringify(data, "\t"))
		var empty := FileAccess.open(ROOT + key + ".json", FileAccess.WRITE); empty.store_string("[]")
		_load_categories(); status.text = "Создана категория %s" % key
	)
	dialog.popup_centered()
