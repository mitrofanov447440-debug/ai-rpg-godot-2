extends RefCounted

static func roll_die(rng: RandomNumberGenerator, sides: int) -> int:
	return rng.randi_range(1, maxi(1, sides))

static func defense_die(defense: int) -> int:
	# Mapping keeps the stated examples: AC 8 -> d12, AC 15 -> d21.
	if defense <= 4:
		return 4
	if defense <= 6:
		return 8
	if defense == 7:
		return 10
	if defense <= 9:
		return 12
	if defense <= 14:
		return 15
	return 21

static func roll_attack(rng: RandomNumberGenerator, actor_defense: int, target_defense: int, strength: int, target_dexterity: int) -> Dictionary:
	return roll_contest(rng, defense_die(actor_defense), defense_die(target_defense), strength, target_dexterity)

static func roll_social(rng: RandomNumberGenerator, charisma: int, target_intelligence: int) -> Dictionary:
	return roll_contest(rng, 12, 12, charisma, target_intelligence)

static func roll_stealth(rng: RandomNumberGenerator, dexterity: int, target_attention: int) -> Dictionary:
	return roll_contest(rng, 12, 12, dexterity, target_attention)

static func roll_contest(rng: RandomNumberGenerator, actor_sides: int, target_sides: int, actor_bonus: int, target_bonus: int) -> Dictionary:
	var actor_roll := rng.randi_range(1, actor_sides)
	var target_roll := rng.randi_range(1, target_sides)
	var actor_total := actor_roll + actor_bonus
	var target_total := target_roll + target_bonus
	var margin := actor_total - target_total
	return {
		"actor_sides": actor_sides,
		"actor_roll": actor_roll,
		"actor_bonus": actor_bonus,
		"actor_total": actor_total,
		"target_sides": target_sides,
		"target_roll": target_roll,
		"target_bonus": target_bonus,
		"target_total": target_total,
		"margin": margin,
		"outcome": outcome_for_margin(margin),
		"initiator_wins": margin >= 0
	}

static func outcome_for_margin(margin: int) -> String:
	if margin >= 13:
		return "Критический успех"
	if margin >= 9:
		return "Великий успех"
	if margin >= 4:
		return "Большой успех"
	if margin >= 0:
		return "Обычный успех"
	if margin <= -13:
		return "Критический крах"
	if margin <= -9:
		return "Великий крах"
	if margin <= -4:
		return "Большой крах"
	return "Обычный крах"
