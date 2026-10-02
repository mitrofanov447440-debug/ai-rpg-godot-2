class_name NPCBackstoryRequest
extends RefCounted

const MAX_BACKSTORY := 300
const MAX_MOTIVATION := 180

func build_prompt(card: NPCCard, context: Dictionary) -> String:
	var role_name := str(context.get("role_name", card.role_id))
	var setting := str(context.get("setting", card.setting))
	var wealth_names := ["нищий", "крайне бедный", "бедный", "малоимущий", "скромный", "неприхотливый", "средний", "зажиточный", "обеспеченный", "богатый", "очень богатый", "знатный", "аристократический"]
	var wealth_desc: String = wealth_names[clampi(card.wealth, 0, 12)]
	return "Роль: %s. Место: %s. Возраст: %d. Достаток: %s.\nТеги: %s.\nЗадача: напиши историю ровно в 2 коротких предложениях и мотивацию в 1 предложении. Учитывай только указанные теги, не добавляй внешность и не меняй роль.\nОтвет строго в JSON: {\"backstory\": \"...\", \"motivation\": \"...\"}" % [role_name, setting, card.age, wealth_desc, ", ".join(card.tags)]

func apply_response(card: NPCCard, response_text: String) -> bool:
	var parsed = JSON.parse_string(response_text.strip_edges())
	if not parsed is Dictionary: return false
	var story := str(parsed.get("backstory", "")).strip_edges()
	var motivation := str(parsed.get("motivation", "")).strip_edges()
	if story.is_empty() or motivation.is_empty() or story.length() > MAX_BACKSTORY or motivation.length() > MAX_MOTIVATION: return false
	card.backstory = story; card.motivation = motivation; card.ai_filled = true
	return true

func fallback(card: NPCCard, role_name: String = "") -> void:
	var title := role_name if not role_name.is_empty() else card.role_id
	card.backstory = "%s живёт своей привычной жизнью и старается сохранить независимость." % title
	card.motivation = "Сейчас для него важнее всего добиться своей ближайшей цели." 
	card.ai_filled = false

func request_lazy(card: NPCCard, context: Dictionary, client: Object, needs_backstory: bool) -> bool:
	if not needs_backstory or card.ai_filled or client == null or not client.has_method("request"): return false
	var prompt := build_prompt(card, context)
	var response: String = await client.request(prompt)
	if apply_response(card, response): return true
	response = await client.request(prompt + "\nИсправь формат: верни только JSON с двумя непустыми строками.")
	if apply_response(card, response): return true
	fallback(card, str(context.get("role_name", card.role_id)))
	return false
