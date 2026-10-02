extends Control

const CampaignStore = preload("res://campaign_store.gd")
const CombatRules = preload("res://combat_rules.gd")
const NPCGen = preload("res://npc/npc_generator.gd")
const BG := Color("10141d")
const PANEL := Color("191f2b")
const PANEL_2 := Color("222a38")
const ACCENT := Color("c89b63")
const TEXT := Color("e9e5dc")
const MUTED := Color("9da8b8")

var data: Dictionary
var tabs: TabContainer
var hero_fields := {}
var inventory_list: ItemList
var relation_list: ItemList
var library_kind: OptionButton
var library_list: ItemList
var library_title: LineEdit
var library_body: TextEdit
var history_body: TextEdit
var toast: Label
var chat_log: TextEdit
var chat_input: TextEdit
var pending_model_request: Dictionary = {}
var roll_rng := RandomNumberGenerator.new()
var stat_fields: Dictionary = {}
var npc_role_select: OptionButton
var npc_request_context: TextEdit
var npc_output: TextEdit

func _ready() -> void:
	_load_data()
	roll_rng.randomize()
	_build_ui()
	_refresh_all()

func _default_data() -> Dictionary:
	return {
		"hero": {"name":"Эллиан", "class":"Следопыт", "race":"Человек", "age":"24", "level":"1", "experience":"0 / 100", "health":"24 / 24", "stamina":"18 / 18", "mana":"—", "aura":"6 / 6", "attributes":"Сила 10 · Ловкость 14 · Разум 12 · Воля 11 · Харизма 9", "stats":{"strength":10, "dexterity":14, "intelligence":12, "attention":12, "charisma":9, "defense":15}, "skills":"Выживание 2 · Стрельба 2 · Скрытность 1"},
		"inventory": ["Охотничий лук", "Колчан (12 стрел)", "Походный плащ", "Фляга с водой"],
		"relations": [{"name":"Мира Вейл", "attitude":"Настороженная", "summary":"Проводница вывела героя к старой дороге. Не доверяет незнакомцам, но держит слово."}],
		"library": [{"kind":"Персонажи", "title":"Мира Вейл", "body":"Роль: проводница\nВнешность: короткие медные волосы, серые глаза, шрам на подбородке.\nХарактер: практичная, наблюдательная, скрывает тревогу за сухими шутками.\nИстория: выросла в приграничье; знает безопасные тропы через Вересковый лес."}, {"kind":"Мир", "title":"Вересковый лес", "body":"Старый лес к северу от тракта. В тумане легко потерять направление. Местные говорят о камнях, которые по ночам светятся холодным синим."}],
		"history": "Герой встретил проводницу Миру Вейл у старого тракта. Она согласилась провести его через Вересковый лес за плату и предупредила о странных огнях среди деревьев.",
		"messages": [{"role":"Рассказчик", "text":"Туман клубится между стволами Верескового леса. Мира останавливается и указывает на слабое синее мерцание в глубине чащи.\n\n«Я обещала довести тебя до старого моста. Но туда светится не просто так. Решай: идём дальше или ищем обход?»"}]
	}

func _load_data() -> void:
	data = CampaignStore.load_campaign(_default_data())
	var defaults := _default_data()
	var hero: Dictionary = data.get("hero", {})
	if not hero.has("stats"):
		hero["stats"] = defaults.hero.stats.duplicate(true)
	data["hero"] = hero
	data.erase("active_target")

func _save_data() -> void:
	CampaignStore.save_campaign(data)

func _build_ui() -> void:
	_apply_theme()
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 76
	header.add_theme_constant_override("separation", 14)
	header.add_theme_constant_override("margin_left", 28)
	header.add_theme_constant_override("margin_right", 28)
	header.add_theme_constant_override("margin_top", 12)
	header.add_theme_constant_override("margin_bottom", 10)
	root.add_child(header)
	var brand := VBoxContainer.new()
	header.add_child(brand)
	var title := Label.new(); title.text = "ХРОНИКИ"; title.add_theme_font_size_override("font_size", 22); title.add_theme_color_override("font_color", ACCENT); brand.add_child(title)
	var subtitle := Label.new(); subtitle.text = "ПАМЯТЬ МИРА · ЛИСТ ПЕРСОНАЖА"; subtitle.add_theme_font_size_override("font_size", 10); subtitle.add_theme_color_override("font_color", MUTED); brand.add_child(subtitle)
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(spacer)
	var save_btn := _button("Сохранить", true); save_btn.pressed.connect(func(): _save_data(); _notify("Игра сохранена")); header.add_child(save_btn)
	var rule := ColorRect.new(); rule.custom_minimum_size.y = 1; rule.color = Color("303847"); root.add_child(rule)
	tabs = TabContainer.new(); tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL; tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tabs.add_theme_constant_override("side_margin", 22); root.add_child(tabs)
	_build_chat_tab(); _build_hero_tab(); _build_inventory_tab(); _build_relations_tab(); _build_library_tab(); _build_npc_tab()
	toast = Label.new(); toast.custom_minimum_size.y = 28; toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; toast.add_theme_color_override("font_color", ACCENT); root.add_child(toast)

func _build_npc_tab() -> void:
	var page := _page("НПС")
	var card := _card("Генератор НПС · библиотека тегов"); page.add_child(card)
	var row := HBoxContainer.new(); card.add_child(row)
	npc_role_select = OptionButton.new(); npc_role_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(npc_role_select)
	var generator = NPCGen.new()
	for role_id in generator.library.roles:
		var role: Dictionary = generator.library.roles[role_id]
		npc_role_select.add_item(str(role.get("display_name", role_id)))
		npc_role_select.set_item_metadata(npc_role_select.item_count - 1, role_id)
	var make := _button("Собрать НПС", true); row.add_child(make)
	npc_request_context = TextEdit.new(); npc_request_context.custom_minimum_size.y = 52; npc_request_context.placeholder_text = "Место действия, например: трактир"; card.add_child(npc_request_context)
	npc_output = TextEdit.new(); npc_output.editable = false; npc_output.size_flags_vertical = Control.SIZE_EXPAND_FILL; npc_output.custom_minimum_size.y = 390; card.add_child(npc_output)
	make.pressed.connect(_generate_npc)

func _generate_npc() -> void:
	var generator = NPCGen.new()
	if npc_role_select.item_count == 0: _notify("В библиотеке нет ролей"); return
	var role_id := str(npc_role_select.get_item_metadata(npc_role_select.selected))
	var card: NPCCard = generator.build({"role":role_id,"setting":npc_request_context.text.strip_edges()})
	if card == null: _notify("Не удалось собрать карточку"); return
	NPCRepository.save(card)
	var role: Dictionary = generator.library.roles.get(role_id, {})
	var result := "Имя: %s\nРоль: %s · возраст: %d · достаток: %d/12\nID: %s\nОтношение: %s\n\nВнешность:\n" % [card.name, role.get("display_name", role_id), card.age, card.wealth, card.id, card.disposition]
	for key in card.appearance: result += "• %s: %s\n" % [key, ", ".join(card.appearance[key]) if card.appearance[key] is Array else card.appearance[key]]
	result += "\nОдежда:\n"
	for key in card.clothing: result += "• %s: %s\n" % [key, ", ".join(card.clothing[key]) if card.clothing[key] is Array else card.clothing[key]]
	result += "\nХарактер: %s\nМанера речи: %s\nПривычки: %s\nТеги: %s\n\nИстория и мотивация создаются при начале диалога через AIClient." % [", ".join(card.personality), card.speech_style, ", ".join(card.quirks), ", ".join(card.tags)]
	npc_output.text = result
	_notify("Карточка НПС сохранена: %s" % card.id)

func _build_chat_tab() -> void:
	var page := _page("История")
	var chat_card := _card("Повествование · API не подключён"); chat_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL; chat_card.size_flags_vertical = Control.SIZE_EXPAND_FILL; page.add_child(chat_card)
	chat_log = TextEdit.new(); chat_log.editable = false; chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL; chat_log.custom_minimum_size.y = 390; chat_log.add_theme_font_size_override("font_size", 16); chat_card.add_child(chat_log)
	var dice_row := HBoxContainer.new(); dice_row.add_theme_constant_override("separation", 8); chat_card.add_child(dice_row)
	var dice_label := Label.new(); dice_label.text = "Бросить:"; dice_label.add_theme_color_override("font_color", MUTED); dice_row.add_child(dice_label)
	for sides in [21, 15, 12, 10, 8, 4]:
		var dice_button := _button("d%d" % sides, sides == 21)
		dice_row.add_child(dice_button)
		dice_button.pressed.connect(_roll_die.bind(sides))
	var compose_row := HBoxContainer.new(); compose_row.add_theme_constant_override("separation", 10); chat_card.add_child(compose_row)
	chat_input = TextEdit.new(); chat_input.custom_minimum_size.y = 92; chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL; chat_input.placeholder_text = "Опишите действие или реплику героя…"; compose_row.add_child(chat_input)
	var send := _button("Отправить", true); send.custom_minimum_size.x = 120; compose_row.add_child(send)
	send.pressed.connect(_send_player_message)

func _build_hero_tab() -> void:
	var page := _page("Герой")
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 18); page.add_child(row)
	var left := _card("Паспорт персонажа"); left.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(left)
	var right := _card("Состояние и развитие"); right.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(right)
	_add_field(left, "Имя", "name"); _add_field(left, "Класс", "class"); _add_field(left, "Раса", "race"); _add_field(left, "Возраст", "age")
	_add_stat_field(left, "Сила", "strength"); _add_stat_field(left, "Ловкость", "dexterity"); _add_stat_field(left, "Интеллект", "intelligence"); _add_stat_field(left, "Внимательность", "attention"); _add_stat_field(left, "Харизма", "charisma"); _add_stat_field(left, "Защита (КД D&D)", "defense")
	_add_field(left, "Навыки", "skills", true)
	_add_field(right, "Уровень", "level"); _add_field(right, "Опыт", "experience"); _add_field(right, "Здоровье", "health"); _add_field(right, "Выносливость", "stamina"); _add_field(right, "Мана (для магов)", "mana"); _add_field(right, "Аура (для бойцов)", "aura")
	var hint := Label.new(); hint.text = "Изменения сохраняются автоматически при потере фокуса поля."; hint.add_theme_color_override("font_color", MUTED); hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; right.add_child(hint)

func _build_inventory_tab() -> void:
	var page := _page("Инвентарь"); var card := _card("Вещи героя"); page.add_child(card)
	var bar := HBoxContainer.new(); card.add_child(bar); var input := LineEdit.new(); input.placeholder_text = "Название предмета…"; input.size_flags_horizontal = Control.SIZE_EXPAND_FILL; bar.add_child(input)
	var add := _button("Добавить", true); bar.add_child(add); inventory_list = ItemList.new(); inventory_list.custom_minimum_size.y = 420; inventory_list.size_flags_vertical = Control.SIZE_EXPAND_FILL; card.add_child(inventory_list)
	var remove := _button("Убрать выбранное"); card.add_child(remove)
	add.pressed.connect(func():
		if input.text.strip_edges() == "":
			return
		data.inventory.append(input.text.strip_edges())
		input.clear()
		_refresh_inventory()
		_save_data()
	)
	remove.pressed.connect(func():
		var selected := inventory_list.get_selected_items()
		if selected.is_empty():
			return
		data.inventory.remove_at(selected[0])
		_refresh_inventory()
		_save_data()
	)

func _build_relations_tab() -> void:
	var page := _page("Отношения"); var card := _card("Персонажи, связанные с героем"); page.add_child(card)
	var split := HBoxContainer.new(); split.add_theme_constant_override("separation", 16); card.add_child(split)
	relation_list = ItemList.new(); relation_list.custom_minimum_size = Vector2(250, 430); split.add_child(relation_list)
	var form := VBoxContainer.new(); form.size_flags_horizontal = Control.SIZE_EXPAND_FILL; split.add_child(form)
	var name_in := LineEdit.new(); name_in.placeholder_text = "Имя персонажа"; form.add_child(name_in); var attitude := LineEdit.new(); attitude.placeholder_text = "Отношение к герою"; form.add_child(attitude); var summary := TextEdit.new(); summary.placeholder_text = "Короткая сводка знакомства и общей истории"; summary.custom_minimum_size.y = 260; form.add_child(summary)
	var buttons := HBoxContainer.new(); form.add_child(buttons); var save := _button("Сохранить персонажа", true); buttons.add_child(save); var delete := _button("Удалить"); buttons.add_child(delete)
	relation_list.item_selected.connect(func(i: int):
		var relation: Dictionary = data.relations[i]
		name_in.text = relation.get("name", "")
		attitude.text = relation.get("attitude", "")
		summary.text = relation.get("summary", "")
	)
	save.pressed.connect(func():
		if name_in.text.strip_edges() == "":
			return
		var relation := {"name":name_in.text.strip_edges(), "attitude":attitude.text.strip_edges(), "summary":summary.text.strip_edges()}
		var selected := relation_list.get_selected_items()
		if selected.size() > 0:
			data.relations[selected[0]] = relation
		else:
			data.relations.append(relation)
		_refresh_relations()
		_save_data()
	)
	delete.pressed.connect(func():
		var selected := relation_list.get_selected_items()
		if selected.is_empty():
			return
		data.relations.remove_at(selected[0])
		_refresh_relations()
		_save_data()
	)

func _build_library_tab() -> void:
	var page := _page("Библиотека")
	var split := HBoxContainer.new(); split.add_theme_constant_override("separation", 16); page.add_child(split)
	var left := _card("Знания кампании"); left.custom_minimum_size.x = 310; split.add_child(left)
	var filter := OptionButton.new(); filter.add_item("Персонажи"); filter.add_item("Мир"); left.add_child(filter); library_kind = filter
	library_list = ItemList.new(); library_list.custom_minimum_size.y = 450; library_list.size_flags_vertical = Control.SIZE_EXPAND_FILL; left.add_child(library_list)
	var new_btn := _button("＋ Новая запись", true); left.add_child(new_btn)
	var right := _card("Карточка / краткая история"); right.size_flags_horizontal = Control.SIZE_EXPAND_FILL; split.add_child(right)
	library_title = LineEdit.new(); library_title.placeholder_text = "Название записи"; right.add_child(library_title)
	library_body = TextEdit.new(); library_body.placeholder_text = "История, внешность, характер, места, правила мира и другие заметки…"; library_body.size_flags_vertical = Control.SIZE_EXPAND_FILL; library_body.custom_minimum_size.y = 285; right.add_child(library_body)
	var actions := HBoxContainer.new(); right.add_child(actions); var save := _button("Сохранить запись", true); actions.add_child(save); var delete := _button("Удалить", false); actions.add_child(delete)
	var history_title := Label.new(); history_title.text = "Краткая история событий — контекст для повествования"; history_title.add_theme_color_override("font_color", ACCENT); right.add_child(history_title)
	history_body = TextEdit.new(); history_body.custom_minimum_size.y = 115; history_body.placeholder_text = "Кратко фиксируйте важные события, решения и последствия…"; right.add_child(history_body)
	var hist_save := _button("Обновить сводку", false); right.add_child(hist_save)
	filter.item_selected.connect(func(_i): _refresh_library(); library_title.clear(); library_body.clear())
	library_list.item_selected.connect(_select_library)
	new_btn.pressed.connect(func(): library_list.deselect_all(); library_title.clear(); library_body.clear())
	save.pressed.connect(_save_library_entry)
	delete.pressed.connect(_delete_library_entry)
	hist_save.pressed.connect(func(): data.history = history_body.text.strip_edges(); _save_data(); _notify("Сводка истории сохранена"))

func _add_field(parent: VBoxContainer, label: String, key: String, multiline := false) -> void:
	var wrap := VBoxContainer.new(); wrap.add_theme_constant_override("separation", 4); parent.add_child(wrap)
	var l := Label.new(); l.text = label; l.add_theme_color_override("font_color", MUTED); wrap.add_child(l)
	var input: Control
	if multiline:
		var edit := TextEdit.new(); edit.custom_minimum_size.y = 74; edit.placeholder_text = label; input = edit
	else:
		var line := LineEdit.new(); input = line
	wrap.add_child(input); hero_fields[key] = input
	input.text = str(data.hero.get(key, ""))
	if input is LineEdit:
		input.text_submitted.connect(func(_value): _commit_hero())
	input.focus_exited.connect(_commit_hero)

func _add_stat_field(parent: VBoxContainer, label: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var caption := Label.new()
	caption.text = label
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.add_theme_color_override("font_color", MUTED)
	row.add_child(caption)
	var value := SpinBox.new()
	value.min_value = 0
	value.max_value = 40
	value.step = 1
	value.custom_minimum_size.x = 100
	value.value = int(data.hero.get("stats", {}).get(key, 10))
	row.add_child(value)
	stat_fields[key] = value
	value.value_changed.connect(func(_new_value): _commit_hero())

func _commit_hero() -> void:
	for key in hero_fields: data.hero[key] = hero_fields[key].text
	var stats: Dictionary = data.hero.get("stats", {})
	for key in stat_fields: stats[key] = int(stat_fields[key].value)
	data.hero["stats"] = stats
	_save_data()

func _roll_die(sides: int) -> void:
	var value := CombatRules.roll_die(roll_rng, sides)
	data.messages.append({"role":"Система", "text":"🎲 d%d: %d" % [sides, value]})
	_save_data()
	_refresh_chat()

func _refresh_all() -> void:
	for key in hero_fields: hero_fields[key].text = str(data.hero.get(key, ""))
	for key in stat_fields: stat_fields[key].value = int(data.hero.get("stats", {}).get(key, 10))
	_refresh_inventory(); _refresh_relations(); _refresh_library()
	if history_body:
		history_body.text = str(data.get("history", ""))
	_refresh_chat()

func _refresh_chat() -> void:
	if not chat_log:
		return
	var lines := PackedStringArray()
	for message in data.get("messages", []):
		lines.append("[%s]\n%s" % [message.get("role", "Рассказчик"), message.get("text", "")])
		lines.append("")
	chat_log.text = "\n".join(lines)
	chat_log.scroll_vertical = 1000000

func _send_player_message() -> void:
	var message := chat_input.text.strip_edges()
	if message.is_empty():
		return
	data.messages.append({"role":"Игрок", "text":message})
	chat_input.clear()
	pending_model_request = CampaignStore.build_model_request(data)
	_save_data()
	_refresh_chat()
	_notify("Реплика сохранена. Подключите API, чтобы получить ответ повествователя.")

func _refresh_inventory() -> void:
	if not inventory_list:
		return
	inventory_list.clear()
	for item in data.inventory: inventory_list.add_item(str(item))

func _refresh_relations() -> void:
	if not relation_list:
		return
	relation_list.clear()
	for r in data.relations: relation_list.add_item(str(r.get("name", "Без имени")) + "  ·  " + str(r.get("attitude", "")))

func _refresh_library() -> void:
	if not library_list:
		return
	library_list.clear()
	var kind := library_kind.get_item_text(library_kind.selected) if library_kind else "Персонажи"
	for i in data.library.size():
		var entry: Dictionary = data.library[i]
		if entry.get("kind", "Персонажи") == kind:
			library_list.add_item(str(entry.get("title", "Без названия")))

func _select_library(index: int) -> void:
	var kind := library_kind.get_item_text(library_kind.selected); var entries := _entries_for_kind(kind)
	if index < entries.size():
		library_title.text = str(entries[index].get("title", ""))
		library_body.text = str(entries[index].get("body", ""))

func _entries_for_kind(kind: String) -> Array:
	var result: Array = []
	for entry in data.library:
		if entry.get("kind", "Персонажи") == kind:
			result.append(entry)
	return result

func _save_library_entry() -> void:
	if library_title.text.strip_edges() == "":
		_notify("Укажите название записи")
		return
	var kind := library_kind.get_item_text(library_kind.selected); var entries := _entries_for_kind(kind); var selected := library_list.get_selected_items(); var record := {"kind":kind, "title":library_title.text.strip_edges(), "body":library_body.text.strip_edges()}
	if selected.size() > 0 and selected[0] < entries.size():
		var target: Dictionary = entries[selected[0]]; target.title = record.title; target.body = record.body
	else: data.library.append(record)
	_save_data(); _refresh_library(); _notify("Запись библиотеки сохранена")

func _delete_library_entry() -> void:
	var selected := library_list.get_selected_items()
	if selected.is_empty():
		return
	var entries := _entries_for_kind(library_kind.get_item_text(library_kind.selected)); var target: Dictionary = entries[selected[0]]; data.library.erase(target); library_title.clear(); library_body.clear(); _save_data(); _refresh_library()

func _page(name: String) -> VBoxContainer:
	var page := VBoxContainer.new(); page.name = name; page.add_theme_constant_override("separation", 14); page.add_theme_constant_override("margin_left", 26); page.add_theme_constant_override("margin_right", 26); page.add_theme_constant_override("margin_top", 20); page.add_theme_constant_override("margin_bottom", 20); tabs.add_child(page); return page

func _card(title_text: String) -> VBoxContainer:
	var card := VBoxContainer.new(); card.add_theme_constant_override("separation", 11); card.add_theme_constant_override("margin_left", 18); card.add_theme_constant_override("margin_right", 18); card.add_theme_constant_override("margin_top", 16); card.add_theme_constant_override("margin_bottom", 16)
	var style := StyleBoxFlat.new(); style.bg_color = PANEL; style.set_corner_radius_all(10); style.set_border_width_all(1); style.border_color = Color("303847"); card.add_theme_stylebox_override("panel", style); card.add_child(_panel_title(title_text)); return card

func _panel_title(t: String) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_font_size_override("font_size", 17); l.add_theme_color_override("font_color", ACCENT); return l

func _button(text_value: String, primary := false) -> Button:
	var b := Button.new(); b.text = text_value; b.custom_minimum_size.y = 38
	var s := StyleBoxFlat.new(); s.bg_color = ACCENT if primary else PANEL_2; s.set_corner_radius_all(6); s.content_margin_left = 14; s.content_margin_right = 14; b.add_theme_stylebox_override("normal", s)
	var h := s.duplicate(); h.bg_color = Color("dbb17a") if primary else Color("303a4b"); b.add_theme_stylebox_override("hover", h); b.add_theme_color_override("font_color", Color("171a20") if primary else TEXT); return b

func _apply_theme() -> void:
	var theme := Theme.new(); theme.default_font_size = 14; theme.set_color("font_color", "Label", TEXT); theme.set_color("font_color", "LineEdit", TEXT); theme.set_color("font_color", "TextEdit", TEXT); theme.set_color("font_color", "ItemList", TEXT); theme.set_color("font_color", "Button", TEXT)
	var input_style := StyleBoxFlat.new(); input_style.bg_color = Color("111722"); input_style.set_corner_radius_all(5); input_style.set_border_width_all(1); input_style.border_color = Color("394456"); input_style.content_margin_left = 9; input_style.content_margin_right = 9; input_style.content_margin_top = 7; input_style.content_margin_bottom = 7
	for type_name in ["LineEdit", "TextEdit"]: theme.set_stylebox("normal", type_name, input_style)
	theme.set_stylebox("panel", "TabContainer", _flat(PANEL)); theme.set_color("font_hover_color", "TabBar", ACCENT); theme.set_color("font_selected_color", "TabBar", ACCENT); theme.set_color("font_unselected_color", "TabBar", MUTED); theme.set_stylebox("selected", "TabBar", _flat(PANEL)); theme.set_stylebox("tab_selected", "TabBar", _flat(PANEL)); theme.set_stylebox("tab_unselected", "TabBar", _flat(BG)); theme.set_stylebox("background", "TabContainer", _flat(BG)); self.theme = theme

func _flat(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = color; s.set_corner_radius_all(5); return s

func _notify(message: String) -> void:
	if toast: toast.text = message
