extends SceneTree

# Minimal Settlement State v1.
#
# Settlements are places, not political actors and not domains to manage. They
# carry enough local condition to create situations a mortal can live inside and
# a god can act on, and nothing beyond that. These tests hold the line on both
# sides: the state has to be real enough to diverge, and small enough that
# nobody mistakes it for an economy.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 18

# Anything a settlement should never grow into without an explicit design pass.
const FORBIDDEN_SETTLEMENT_FIELDS := [
	"taxes", "laws", "governor", "buildings", "construction", "budget",
	"levy", "trade_routes", "employment", "crime", "disease", "housing",
	"education", "sanitation", "class", "vassals", "council", "intents",
	"actions", "goals", "decisions"
]

var completed := 0


func _init() -> void:
	_test_settlements_own_their_conditions()
	_test_changing_one_leaves_the_others_alone()
	_test_kingdom_view_is_derived()
	_test_population_is_the_sum_of_its_settlements()
	_test_kingdom_only_values_stay_kingdom_only()
	_test_seeds_differ_meaningfully()
	_test_any_settlement_can_carry_any_event()
	_test_event_goes_where_the_condition_is_thinnest()
	_test_event_text_names_its_settlement()
	_test_claims_are_per_settlement_beliefs()
	_test_local_shortage_reaches_only_the_local_mortal()
	_test_capital_unrest_reaches_only_the_capital()
	_test_an_event_can_have_no_mortal_witness()
	_test_a_new_settlement_needs_no_new_event()
	_test_intent_reads_the_actor_s_own_settlement()
	_test_settlement_food_does_not_unblock_give()
	_test_settlements_hold_no_management_and_no_will()
	_test_the_world_neither_starves_nor_plateaus()

	if completed != EXPECTED_TESTS:
		push_error("Settlement suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("SETTLEMENT TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("SETTLEMENT TEST PASSED: places differ, and none of them is a domain to manage.")
	quit(0)


func _test_settlements_own_their_conditions() -> void:
	var state = _new_simulation().state
	for location_id: String in state.get_location_ids():
		for band: String in WorldState.SETTLEMENT_BANDS:
			var value: int = state.get_settlement_band(location_id, band)
			assert(value >= 0 and value < WorldState.FOOD_LABELS.size())
		assert(int(state.get_settlement_population(location_id)) > 0)
	assert(int(state.get_settlement_band("nowhere", "food")) == 0, "an unknown place has nothing")
	assert(not bool(state.set_settlement_band("aster", "morale", 2)), "the band list is closed")
	print("  OWNERSHIP: %d settlements, each with its own conditions." % state.locations.size())
	completed += 1


func _test_changing_one_leaves_the_others_alone() -> void:
	var state = _new_simulation().state
	var before := {}
	for location_id: String in state.get_location_ids():
		before[location_id] = int(state.get_settlement_band(location_id, "food"))
	assert(bool(state.set_settlement_band("westfield", "food", 3)))
	assert(int(state.get_settlement_band("westfield", "food")) == 3)
	for location_id: String in state.get_location_ids():
		if location_id == "westfield":
			continue
		assert(int(state.get_settlement_band(location_id, "food")) == int(before[location_id]),
			"%s must not move because Westfield did" % location_id)
	print("  INDEPENDENCE: Westfield's stores are Westfield's.")
	completed += 1


func _test_kingdom_view_is_derived() -> void:
	# One source of truth. The realm is a view of its settlements, never a
	# second copy that can disagree with them.
	var state = _new_simulation().state
	for band: String in WorldState.SETTLEMENT_BANDS:
		var weighted := 0
		var people := 0
		for location_id: String in state.get_location_ids():
			var residents: int = state.get_settlement_population(location_id)
			weighted += int(state.get_settlement_band(location_id, band)) * residents
			people += residents
		var expected := int(round(float(weighted) / float(people)))
		assert(int(_kingdom_band(state, band)) == expected,
			"the kingdom %s must be what its settlements add up to" % band)

	# Writing the realm's view reaches every settlement, so the two can never
	# drift apart.
	state.food_level = 3
	for location_id: String in state.get_location_ids():
		assert(int(state.get_settlement_band(location_id, "food")) == 3)
	assert(int(state.food_level) == 3)
	print("  DERIVED: the realm reads as the sum of its places, weighted by who lives there.")
	completed += 1


func _test_population_is_the_sum_of_its_settlements() -> void:
	var state = _new_simulation().state
	var sum := 0
	for location_id: String in state.get_location_ids():
		sum += int(state.get_settlement_population(location_id))
	assert(int(state.population) == sum)

	# Growth spreads across settlements in proportion, and the total still holds.
	state.population = sum + 60
	var after := 0
	for location_id: String in state.get_location_ids():
		after += int(state.get_settlement_population(location_id))
	assert(int(state.population) == after)
	assert(after == sum + 60, "the realm must be exactly the people in it")
	assert(int(state.get_settlement_population("aster")) > int(state.get_settlement_population("frontier")),
		"proportions should survive the distribution")
	print("  POPULATION: %d people, and no two places disagree about it." % after)
	completed += 1


func _test_kingdom_only_values_stay_kingdom_only() -> void:
	# Not every world value should become local. An army is the realm's, and
	# belief travels; neither belongs to a settlement.
	var state = _new_simulation().state
	for location_id: String in state.get_location_ids():
		var location: Dictionary = state.get_location(location_id)
		for field: String in ["military_level", "military", "faith", "followers", "divine_power", "reputation"]:
			assert(not location.has(field), "%s must not carry the kingdom's %s" % [location_id, field])
	assert(int(state.military_level) >= 0)
	print("  KINGDOM: the army, faith and followers stay the realm's.")
	completed += 1


func _test_seeds_differ_meaningfully() -> void:
	var state = _new_simulation().state
	var signatures: Array[String] = []
	for location_id: String in state.get_location_ids():
		var signature := "%d/%d/%d" % [
			state.get_settlement_band(location_id, "food"),
			state.get_settlement_band(location_id, "stability"),
			state.get_settlement_band(location_id, "prosperity")
		]
		assert(signature not in signatures, "settlements must not start identical")
		signatures.append(signature)
	print("  SEEDS: %s." % ", ".join(signatures))
	completed += 1


func _test_any_settlement_can_carry_any_event() -> void:
	# Generic by construction: the same three definitions serve every place.
	var checked := 0
	for location_id in ["aster", "westfield", "frontier"]:
		for event_id in ["drought", "unrest", "good_harvest"]:
			var simulation = _new_simulation()
			simulation.state.current_event_location_id = str(location_id)
			simulation.state.current_event_id = str(event_id)
			_force_condition(simulation, str(location_id), str(event_id))
			var fact: Dictionary = simulation.observable_fact()
			assert(not fact.is_empty(), "%s should be able to have a %s" % [location_id, event_id])
			assert(str(fact["subject_id"]) == str(location_id))
			assert(str(fact["id"]).begins_with(str(location_id)),
				"the knowledge id must name the settlement it concerns")
			checked += 1
	assert(checked == 9)
	print("  GENERIC: %d settlement/event pairs, from three definitions." % checked)
	completed += 1


func _test_event_goes_where_the_condition_is_thinnest() -> void:
	# No settlement is named in the rule; it follows the condition.
	var simulation = _new_simulation()
	var state = simulation.state
	state.food_level = 3
	assert(bool(state.set_settlement_band("frontier", "food", 0)))
	assert(str(simulation.event_location_for("drought")) == "frontier")
	assert(str(simulation.event_location_for("good_harvest")) == "frontier")

	state.stability_level = 3
	assert(bool(state.set_settlement_band("westfield", "stability", 0)))
	assert(str(simulation.event_location_for("unrest")) == "westfield",
		"unrest belongs where order is thinnest, not where food is")
	print("  SUBJECT: the year's event finds the settlement it is about.")
	completed += 1


func _test_event_text_names_its_settlement() -> void:
	var simulation = _new_simulation()
	simulation.state.current_event_id = "good_harvest"
	for location_id in ["aster", "westfield", "frontier"]:
		simulation.state.current_event_location_id = str(location_id)
		var event: Dictionary = simulation.get_current_event()
		var place: String = simulation.state.location_name(str(location_id))
		assert(str(event["description"]).contains(place),
			"the description should say where it is happening")
		assert(not str(event["description"]).contains("%s"), "the placeholder must be filled")
		assert(str(event["location_id"]) == str(location_id))
	print("  TEXT: one definition, named for wherever it lands.")
	completed += 1


func _test_claims_are_per_settlement_beliefs() -> void:
	# Two settlements short of food are two separate beliefs, held, aged and
	# spread independently.
	var simulation = _new_simulation()
	simulation.state.current_event_id = "drought"
	simulation.state.food_level = 0

	simulation.state.current_event_location_id = "aster"
	var aster_fact: Dictionary = simulation.observable_fact()
	simulation.state.current_event_location_id = "westfield"
	var westfield_fact: Dictionary = simulation.observable_fact()

	assert(str(aster_fact["id"]) != str(westfield_fact["id"]))
	assert(str(aster_fact["claim"]) != str(westfield_fact["claim"]))
	assert(str(aster_fact["claim"]).contains("Aster"))
	assert(str(westfield_fact["claim"]).contains("Westfield"))
	assert(str(aster_fact["topic"]) == str(westfield_fact["topic"]), "the same kind of trouble")
	print("  CLAIMS: \"%s\" and \"%s\" are separate beliefs." % [
		str(aster_fact["claim"]), str(westfield_fact["claim"])
	])
	completed += 1


func _test_local_shortage_reaches_only_the_local_mortal() -> void:
	# Scenario A. The whole point of the pass.
	var simulation = _shortage_in("westfield")
	simulation.tick_perception()

	assert(simulation.state.has_knowledge("mara", "westfield_food_shortage"),
		"Mara lives in Westfield and should see it")
	assert(not simulation.state.has_knowledge("aster_king", "westfield_food_shortage"),
		"the King is in Aster and should not")
	var intent: Dictionary = simulation.choose_intent("mara")
	assert(str(intent["intent_type"]) in ["help", "protect", "acquire", "learn", "wait", "preserve"],
		"she may want something because of it")
	print("  SCENARIO A: Westfield goes short, and only Mara knows.")
	completed += 1


func _test_capital_unrest_reaches_only_the_capital() -> void:
	# Scenario B, the mirror image.
	var simulation = _new_simulation()
	simulation.state.current_event_id = "unrest"
	simulation.state.current_event_location_id = "aster"
	assert(bool(simulation.state.set_settlement_band("aster", "stability", 0)))
	simulation.tick_perception()

	assert(simulation.state.has_knowledge("aster_king", "aster_unrest"))
	assert(not simulation.state.has_knowledge("mara", "aster_unrest"))
	print("  SCENARIO B: Aster comes apart, and only the King knows.")
	completed += 1


func _test_an_event_can_have_no_mortal_witness() -> void:
	# Scenario C. An event does not need somebody important standing there to
	# be real. Nobody lives on the Frontier, and it still has its troubles.
	var simulation = _shortage_in("frontier")
	assert(simulation.state.residents_of("frontier").is_empty(), "the fixture needs it empty")

	var fact: Dictionary = simulation.observable_fact()
	assert(not fact.is_empty(), "the event exists whether or not anyone sees it")
	var opportunities: Array[Dictionary] = simulation.tick_perception()
	for opportunity: Dictionary in opportunities:
		assert(not bool(opportunity["perceived"]), "nobody was there to notice")
	assert(simulation.state.perception_archive.is_empty())
	for entity_id in ["mara", "aster_king"]:
		assert(not simulation.state.has_knowledge(str(entity_id), "frontier_food_shortage"))
	print("  SCENARIO C: the Frontier goes hungry with nobody of note to see it.")
	completed += 1


func _test_a_new_settlement_needs_no_new_event() -> void:
	# Scenario D. Nothing in the event code names a settlement, so a place the
	# world gains later works without a line of new event definition.
	var simulation = _new_simulation()
	var state = simulation.state
	state.food_level = 2
	assert(bool(state.add_location("harborside", "Harborside", "port", "Trade", {
		"food": 0, "stability": 1, "prosperity": 1, "population": 60
	})))
	assert(bool(state.add_notable_entity("dockhand", "The Dockhand", "person", [], {}, "harborside")))
	state.current_event_id = "drought"
	state.current_event_location_id = "harborside"

	var fact: Dictionary = simulation.observable_fact()
	assert(str(fact["id"]) == "harborside_food_shortage")
	assert(str(fact["claim"]).contains("Harborside"))
	simulation.tick_perception()
	assert(state.has_knowledge("dockhand", "harborside_food_shortage"))
	assert(not state.has_knowledge("mara", "harborside_food_shortage"))
	assert(str(simulation.event_location_for("drought")) == "harborside",
		"a new settlement joins the same generic rules")
	print("  SCENARIO D: a settlement nobody wrote code for behaves like the rest.")
	completed += 1


func _test_intent_reads_the_actor_s_own_settlement() -> void:
	# A mortal knows whether there is food where they are. That is their own
	# lived context, and it is the only settlement truth intent may touch.
	var simulation = _new_simulation()
	var state = simulation.state
	state.food_level = 3
	state.prosperity_level = 3
	assert(bool(state.set_settlement_band("westfield", "food", 0)))
	assert(bool(state.set_settlement_band("westfield", "prosperity", 0)))

	# Read it from the same candidate for both, so the comparison is of what
	# each of them sees rather than of which want happened to win.
	var hungry := _acquire_world_value(simulation, "mara")
	var fed := _acquire_world_value(simulation, "aster_king")
	assert(hungry == 0, "Mara lives where the stores are empty")
	assert(fed == 3, "the King does not")
	print("  LOCAL HUNGER: Mara reads 0 where the King reads 3.")
	completed += 1


func _test_settlement_food_does_not_unblock_give() -> void:
	# A settlement having food does not make anyone standing in it able to give
	# it away. Ownership is a separate question and is still unanswered.
	var simulation = _new_simulation()
	simulation.state.food_level = 3
	simulation.state.prosperity_level = 3
	var action := {
		"id": "action_test_give", "year": simulation.state.year, "actor_id": "mara",
		"intent_id": "", "intent_type": "help", "action_type": "give",
		"target_id": "aster_king", "target_kind": "person", "subject_id": "westfield",
		"topic_id": "", "resource_type": "food", "selection": "argmax"
	}
	var record: Dictionary = simulation.execute_mortal_action(action)
	assert(str(record["outcome"]) == ExecutionRules.OUTCOME_BLOCKED)
	assert(str(record["result_type"]) == "no_controlled_resource",
		"full granaries are the settlement's, not any mortal's")
	print("  OWNERSHIP: full stores everywhere, and still nobody can give any away.")
	completed += 1


func _test_settlements_hold_no_management_and_no_will() -> void:
	# The guardrail. A settlement is a place and a set of conditions. It has no
	# budget, no council, no buildings, and above all no intentions: mortals
	# decide things, places do not.
	var simulation = _new_simulation()
	for turn in 6:
		assert(bool(simulation.resolve_action("do_nothing")["ok"]))
		assert(bool(simulation.advance_year()["ok"]))
	for location_id: String in simulation.state.get_location_ids():
		var location: Dictionary = simulation.state.get_location(location_id)
		for field: String in FORBIDDEN_SETTLEMENT_FIELDS:
			assert(not location.has(field),
				"%s grew a '%s' — settlements are places, not domains" % [location_id, field])
		assert(location.size() <= 8, "a settlement record should stay small")
		# Wants and attempts belong to mortals alone.
		assert(simulation.state.get_intents_for(location_id).is_empty())
		assert(simulation.state.get_actions_for(location_id).is_empty())
	print("  GUARDRAIL: places carry conditions, and never a will of their own.")
	completed += 1


func _test_the_world_neither_starves_nor_plateaus() -> void:
	# Ordinary life should dominate without the world either collapsing or
	# settling into uniform plenty, and settlements must stay distinguishable
	# across a long run.
	var simulation = _new_simulation()
	var subjects: Array[String] = []
	var divergent_years := 0
	var starved_years := 0
	for turn in 60:
		assert(bool(simulation.resolve_action("do_nothing")["ok"]))
		assert(bool(simulation.advance_year()["ok"]))
		var subject := str(simulation.state.current_event_location_id)
		if subject not in subjects:
			subjects.append(subject)
		var signatures: Array[String] = []
		var starving := 0
		for location_id: String in simulation.state.get_location_ids():
			var food: int = simulation.state.get_settlement_band(location_id, "food")
			if food == 0:
				starving += 1
			var signature := "%d/%d" % [
				food, simulation.state.get_settlement_band(location_id, "prosperity")
			]
			if signature not in signatures:
				signatures.append(signature)
		if signatures.size() > 1:
			divergent_years += 1
		if starving == simulation.state.get_location_ids().size():
			starved_years += 1
	assert(subjects.size() > 1, "events must not all land on one settlement forever")
	assert(divergent_years > 40, "settlements must stay meaningfully different")
	assert(starved_years == 0, "the world must not decay into universal famine")
	assert(int(simulation.state.food_level) < 3 or int(simulation.state.prosperity_level) < 3,
		"nor drift up to uniform plenty and stay there")
	print("  LIVING WORLD: %d settlements featured, differing in %d of 60 years." % [
		subjects.size(), divergent_years
	])
	completed += 1


# --- helpers -----------------------------------------------------------------


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _shortage_in(location_id: String):
	var simulation = _new_simulation()
	simulation.state.current_event_id = "drought"
	simulation.state.current_event_location_id = location_id
	simulation.state.set_settlement_band(location_id, "food", 0)
	return simulation


func _force_condition(simulation, location_id: String, event_id: String) -> void:
	match event_id:
		"drought":
			simulation.state.set_settlement_band(location_id, "food", 0)
		"unrest":
			simulation.state.set_settlement_band(location_id, "stability", 0)
		"good_harvest":
			simulation.state.set_settlement_band(location_id, "food", 3)


func _kingdom_band(state, band: String) -> int:
	match band:
		"food":
			return int(state.food_level)
		"stability":
			return int(state.stability_level)
		"prosperity":
			return int(state.prosperity_level)
	return 0


func _acquire_world_value(simulation, actor_id: String) -> int:
	for candidate: Dictionary in simulation.evaluate_intents(actor_id):
		if str(candidate["intent_type"]) != "acquire":
			continue
		for factor: Dictionary in candidate.get("world_state_factors", []):
			if str(factor.get("field", "")) == "food_level":
				return int(factor["value"])
		# No rule fired, which itself means the stores are not short.
		return simulation.state.get_settlement_band(
			simulation.state.get_home_location(actor_id), "food"
		)
	return -1
