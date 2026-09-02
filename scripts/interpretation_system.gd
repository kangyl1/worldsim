class_name InterpretationSystem
extends RefCounted

const ACTION_ORDER := ["send_rain", "bless_harvest", "speak_mortal", "do_nothing"]
const EVENT_ORDER := ["drought", "good_harvest", "unrest"]

# Each result describes mortal meaning, not the divine action itself. Mechanical
# adjustments here represent behaviour caused by that interpretation.
const CANDIDATES := {
	"send_rain": [
		{
			"id": "rain_answered_prayer",
			"weight": 5,
			"interpretation": "The people believe their prayers were answered.",
			"belief_tag": "answered_prayer",
			"belief_strength": 2,
			"reputation_hint": "Merciful",
			"history_text": "Rain followed the people's prayers, and many called it a merciful answer."
		},
		{
			"id": "rain_royal_favor",
			"weight": 2,
			"interpretation": "The king claims his devotion convinced the god.",
			"belief_tag": "answered_prayer",
			"belief_strength": 1,
			"reputation_hint": "Protector",
			"history_text": "When rain returned, the king declared that his devotion had won divine favour.",
			"flags": ["king_claims_divine_favor"]
		},
		{
			"id": "rain_maras_miracle",
			"weight": 2,
			"interpretation": "Mara is credited with bringing the miracle.",
			"belief_tag": "chosen_mortal",
			"belief_strength": 2,
			"reputation_hint": "Teacher",
			"history_text": "Rain came after Mara addressed the shrine, strengthening her claim to speak for the god.",
			"requires_flag": "mara_is_prophet"
		},
		{
			"id": "rain_coincidence",
			"weight": 2,
			"interpretation": "Some scholars call the rain a coincidence.",
			"belief_tag": "naturalism",
			"belief_strength": 2,
			"reputation_hint": "Unpredictable",
			"history_text": "Rain broke the dry season, though Aster's scholars argued that weather, not worship, explained it."
		},
		{
			"id": "rain_is_sacred",
			"weight": 3,
			"interpretation": "Farmers begin treating water itself as sacred.",
			"belief_tag": "sacred_rain",
			"belief_strength": 2,
			"reputation_hint": "Protector",
			"history_text": "The returning rain saved the fields, and farmers began leaving offerings beside every well."
		}
	],
	"bless_harvest": [
		{
			"id": "harvest_blessed_land",
			"weight": 5,
			"interpretation": "Farmers believe the land itself has been blessed.",
			"belief_tag": "blessed_land",
			"belief_strength": 2,
			"reputation_hint": "Merciful",
			"history_text": "The fields yielded beyond expectation, and farmers said a blessing had entered the soil."
		},
		{
			"id": "harvest_rewarded_obedience",
			"weight": 3,
			"interpretation": "Priests claim obedience has been rewarded.",
			"belief_tag": "answered_prayer",
			"belief_strength": 1,
			"reputation_hint": "Teacher",
			"history_text": "After the rich harvest, priests taught that obedience had earned Aster divine reward."
		},
		{
			"id": "harvest_better_methods",
			"weight": 3,
			"interpretation": "Villagers credit improved farming methods instead.",
			"belief_tag": "naturalism",
			"belief_strength": 2,
			"reputation_hint": "Teacher",
			"history_text": "The harvest flourished, but villagers credited new irrigation channels rather than a miracle.",
			"flags": ["irrigation_known"],
			"effects": {"prosperity": 1, "population_growth_bonus": 2}
		},
		{
			"id": "harvest_shared_labour",
			"weight": 2,
			"interpretation": "The village decides cooperation, not divine favour, saved the crop.",
			"belief_tag": "self_reliance",
			"belief_strength": 2,
			"reputation_hint": "Silent",
			"history_text": "A plentiful harvest followed months of shared labour, teaching Aster to trust its neighbours."
		}
	],
	"speak_mortal": [
		{
			"id": "mara_accepted",
			"weight": 5,
			"interpretation": "Mara is accepted as a prophet.",
			"belief_tag": "chosen_mortal",
			"belief_strength": 2,
			"reputation_hint": "Teacher",
			"history_text": "Mara spoke words she could not have known, and the crowd accepted her as a prophet.",
			"flags": ["mara_is_prophet"]
		},
		{
			"id": "mara_accused",
			"weight": 2,
			"interpretation": "Mara is accused of inventing the divine message.",
			"belief_tag": "naturalism",
			"belief_strength": 2,
			"reputation_hint": "Unpredictable",
			"history_text": "Mara claimed a god had spoken, but sceptics accused her of exploiting a frightened crowd.",
			"effects": {"faith": -3, "stability": -1}
		},
		{
			"id": "mara_royal_support",
			"weight": 2,
			"interpretation": "The ruler supports Mara for political reasons.",
			"belief_tag": "chosen_mortal",
			"belief_strength": 1,
			"reputation_hint": "Protector",
			"history_text": "The king endorsed Mara's revelation, binding the throne to her growing religious authority.",
			"flags": ["king_claims_divine_favor", "mara_is_prophet"]
		},
		{
			"id": "mara_feared",
			"weight": 2,
			"interpretation": "People fear that Mara is cursed rather than chosen.",
			"belief_tag": "divine_silence",
			"belief_strength": 1,
			"reputation_hint": "Harsh",
			"history_text": "Mara's voice changed before the crowd, and fear of a curse spread faster than her message.",
			"effects": {"faith": 2, "stability": -1}
		},
		{
			"id": "mara_calms_square",
			"weight": 2,
			"interpretation": "Mara tells the crowd that restraint is the god's command.",
			"belief_tag": "chosen_mortal",
			"belief_strength": 2,
			"reputation_hint": "Protector",
			"history_text": "As unrest mounted, Mara invoked the god's command and persuaded the crowd to disperse.",
			"events": ["unrest"],
			"effects": {"stability": 1},
			"flags": ["mara_is_prophet"]
		}
	],
	"do_nothing": [
		{
			"id": "silence_builds_wells",
			"weight": 5,
			"interpretation": "The villagers decide they must solve the drought themselves.",
			"belief_tag": "self_reliance",
			"belief_strength": 2,
			"reputation_hint": "Teacher",
			"history_text": "After the god remained silent during the drought, farmers dug new wells and learned to share their water.",
			"events": ["drought"],
			"flags": ["wells_built"],
			"effects": {"food": 1, "prosperity": 1, "faith": -2, "stability": 1},
			"useful_silence": true
		},
		{
			"id": "silence_improves_farming",
			"weight": 5,
			"interpretation": "Farmers experiment instead of waiting for a miracle.",
			"belief_tag": "naturalism",
			"belief_strength": 2,
			"reputation_hint": "Teacher",
			"history_text": "Without divine instruction, farmers improved their channels and claimed the next harvest as their own achievement.",
			"events": ["good_harvest"],
			"flags": ["irrigation_known"],
			"effects": {"prosperity": 1, "population_growth_bonus": 3, "faith": -2},
			"useful_silence": true
		},
		{
			"id": "silence_local_council",
			"weight": 5,
			"interpretation": "Local leaders settle the crisis without a divine sign.",
			"belief_tag": "self_reliance",
			"belief_strength": 2,
			"reputation_hint": "Teacher",
			"history_text": "When no sign came during the unrest, local elders opened the stores and restored order themselves.",
			"events": ["unrest"],
			"flags": ["local_council_empowered"],
			"effects": {"stability": 2, "prosperity": 1, "faith": -2},
			"useful_silence": true
		},
		{
			"id": "silence_divine_test",
			"weight": 3,
			"interpretation": "The silence is interpreted as a divine test.",
			"belief_tag": "divine_silence",
			"belief_strength": 2,
			"reputation_hint": "Silent",
			"history_text": "No answer came, yet the faithful called the silence a test and endured without abandoning the shrine.",
			"effects": {"faith": 2, "followers": 4, "stability": 1},
			"useful_silence": true
		},
		{
			"id": "silence_natural_answer",
			"weight": 2,
			"interpretation": "A natural explanation becomes more popular.",
			"belief_tag": "naturalism",
			"belief_strength": 2,
			"reputation_hint": "Silent",
			"history_text": "The god gave no sign, and scholars gained listeners by explaining events through weather and human choices.",
			"effects": {"faith": -3}
		},
		{
			"id": "silence_unanswered",
			"weight": 4,
			"interpretation": "Faith falls after the prayers go unanswered.",
			"belief_tag": "naturalism",
			"belief_strength": 1,
			"reputation_hint": "Harsh",
			"history_text": "Prayers went unanswered, and some families quietly stopped visiting the old shrine.",
			"effects": {"faith": -4, "followers": -12, "stability": -1}
		}
	]
}


func choose(state: WorldState, action_id: String, event_id: String) -> Dictionary:
	var options: Array[Dictionary] = []
	for template: Dictionary in CANDIDATES[action_id]:
		var contextual_weight := _contextual_weight(state, template, action_id, event_id)
		if contextual_weight <= 0:
			continue
		var option: Dictionary = template.duplicate(true)
		option["selected_weight"] = contextual_weight
		options.append(option)

	var total_weight := 0
	for option: Dictionary in options:
		total_weight += int(option["selected_weight"])
	var selector := posmod(_context_seed(state, action_id, event_id), total_weight)
	for option: Dictionary in options:
		selector -= int(option["selected_weight"])
		if selector < 0:
			return option
	return options.back()


func _contextual_weight(state: WorldState, candidate: Dictionary, action_id: String, event_id: String) -> int:
	if candidate.has("events") and event_id not in candidate["events"]:
		return 0
	if candidate.has("requires_flag") and not bool(state.world_flags.get(candidate["requires_flag"], false)):
		return 0

	var weight := int(candidate["weight"])
	var candidate_id := str(candidate["id"])
	var tag := str(candidate["belief_tag"])
	var pressure := int(state.belief_pressure.get(tag, 0))

	# Existing ideas make compatible explanations easier to accept.
	weight += mini(pressure / 2, 4)
	if state.previous_action_id == action_id:
		weight += 1

	match candidate_id:
		"rain_answered_prayer":
			if event_id == "drought": weight += 4
			if state.faith >= 55: weight += 4
		"rain_royal_favor":
			if state.stability_level <= 1: weight += 3
			if state.world_flags["king_claims_divine_favor"]: weight += 2
		"rain_maras_miracle":
			if state.faith >= 45: weight += 4
		"rain_coincidence":
			if state.faith <= 35: weight += 4
			if state.belief_pressure["naturalism"] >= 3: weight += 4
		"rain_is_sacred":
			if event_id == "drought" and state.food_level <= 1: weight += 4
		"harvest_blessed_land", "harvest_rewarded_obedience":
			if state.faith >= 50: weight += 4
		"harvest_better_methods", "harvest_shared_labour":
			if state.belief_pressure["naturalism"] >= 3: weight += 4
			if state.world_flags["irrigation_known"]: weight += 3
		"mara_accepted", "mara_calms_square":
			if state.faith >= 45: weight += 4
			if state.stability_level <= 1: weight += 3
		"mara_accused", "mara_feared":
			if state.faith <= 35: weight += 4
		"mara_royal_support":
			if state.world_flags["king_claims_divine_favor"]: weight += 4
		"silence_builds_wells":
			if state.food_level == 0: weight += 6
			if state.world_flags["wells_built"]: weight -= 4
		"silence_improves_farming":
			if state.prosperity_level <= 1: weight += 5
			if state.world_flags["irrigation_known"]: weight -= 3
		"silence_local_council":
			if state.stability_level <= 1: weight += 6
			if state.world_flags["local_council_empowered"]: weight -= 3
		"silence_divine_test":
			if state.faith >= 50: weight += 6
		"silence_natural_answer":
			if state.belief_pressure["naturalism"] >= 3: weight += 4
		"silence_unanswered":
			if event_id == "drought" and not state.world_flags["wells_built"]: weight += 3
			if state.faith <= 25: weight += 3
	return maxi(weight, 1)


func _context_seed(state: WorldState, action_id: String, event_id: String) -> int:
	var action_index := maxi(ACTION_ORDER.find(action_id), 0)
	var event_index := maxi(EVENT_ORDER.find(event_id), 0)
	var previous_index := maxi(ACTION_ORDER.find(state.previous_action_id), 0)
	return (
		state.year
		+ int(state.action_counts[action_id]) * 5
		+ state.faith
		+ state.stability_level * 3
		+ action_index * 7
		+ event_index * 11
		+ previous_index * 13
	)
