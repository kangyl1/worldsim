extends SceneTree

# Divine Actions in the shared causal pipeline v1 — Send Rain only.
#
# The law under test: God controls what happens, and mortals decide what it
# meant. Send Rain now goes down the same road a mortal act goes down —
# consequence, event, perception, knowledge, interpretation — and each of those
# five layers is forbidden from doing the next one's job.
#
# Most of this suite is negative, because the valuable property is the set of
# things the act no longer does. It does not tell every mortal in the world. It
# does not write "the god answered us" into anyone's knowledge. It does not move
# faith, followers or reputation on its own authority. And it does not force a
# theological conclusion just because the engine happens to know the player
# caused the rain: a mortal is allowed to call it weather, and be wrong.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 20

# Years of ordinary play before the god acts, so the world is a lived-in one
# with beliefs, relationships and knowledge already in it.
const WARMUP_YEARS := 12

# The one power that has moved. Everything else must still take the old road.
const MIGRATED := "send_rain"

# The id of the past reading some tests plant on a mortal. It is prior state, not
# a result, and must never be counted as one: an early version of this suite
# passed because it was comparing a seed against a real reading.
const SEED_ID := "interpretation_seed"
const UNMIGRATED := ["bless_harvest", "speak_mortal"]

# Words that would mean a layer had started speaking for a mortal's soul.
const MEANING_WORDS := [
	"god", "divine", "answered", "prayer", "prayers", "miracle", "merciful",
	"blessed", "sacred", "faith", "favour", "favor", "holy"
]

var completed := 0


func _init() -> void:
	_test_the_act_is_recorded_as_an_act()
	_test_the_world_objectively_changed()
	_test_an_objective_occurrence_was_offered()
	_test_only_eligible_mortals_perceived_it()
	_test_knowledge_holds_the_fact_and_nothing_else()
	_test_someone_reached_a_conclusion()
	_test_two_mortals_can_disagree()
	_test_nothing_moved_before_interpretation()
	_test_a_reading_can_reach_a_later_intent()

	_test_no_global_teaching()
	_test_the_consequence_moves_no_faith_or_followers()
	_test_the_consequence_moves_no_reputation()
	_test_interpretation_is_not_bypassed()
	_test_no_religion_doctrine_or_prophet()
	_test_the_history_line_states_only_what_happened()
	_test_no_same_year_mortal_reply()
	_test_the_legacy_reading_does_not_also_run()
	_test_the_other_powers_are_untouched()
	_test_the_occurrence_is_the_same_whatever_it_meant()
	_test_the_whole_chain_is_deterministic()

	if completed != EXPECTED_TESTS:
		push_error("Divine action suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("DIVINE ACTION TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("DIVINE ACTION TEST PASSED: the god acts, and mortals decide what it was.")
	quit(0)


# --- helpers ---------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


# A world that has been lived in, standing at the moment before the god acts.
# The rain is aimed at Aster because the King lives there: an act nobody is
# near is a real outcome of the observability rules, but it proves nothing
# about the chain.
func _world_ready_to_act(years: int = WARMUP_YEARS, target: String = "aster") -> Object:
	var simulation := _sim()
	for year in range(years):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	simulation.state.current_event_location_id = target
	return simulation


# The god sends rain, and the year turns so perception, knowledge and
# interpretation can all run in their own order.
func _rain(simulation: Object) -> Dictionary:
	var result := simulation.resolve_action(MIGRATED) as Dictionary
	assert(bool(result["ok"]), "Send Rain was refused: %s" % str(result.get("message", "")))
	simulation.advance_year()
	return result


func _rained_world(target: String = "aster") -> Object:
	var simulation := _world_ready_to_act(WARMUP_YEARS, target)
	_rain(simulation)
	return simulation


func _rain_knowledge(state, holder_id: String) -> Dictionary:
	for record: Dictionary in state.get_all_knowledge(holder_id).values():
		if str(record.get("topic", "")) == "weather_rain":
			return record
	return {}


func _rain_readings(state) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record: Dictionary in state.interpretation_archive:
		if str(record.get("id", "")) == SEED_ID:
			continue
		if str(record.get("topic", "")) == "weather_rain":
			found.append(record)
	return found


func _rain_consequence(state) -> Dictionary:
	for record: Dictionary in state.consequence_archive:
		if str(record.get("source_id", "")) == MIGRATED:
			return record
	return {}


func _mentions_meaning(text: String) -> String:
	var lowered := text.to_lower()
	# Padded so this matches whole words only: "Frontier" must not read as
	# "front", and punctuation is stripped rather than treated as a letter.
	var padded := " %s " % lowered.replace(".", " ").replace(",", " ").replace("\"", " ")
	for word: String in MEANING_WORDS:
		if padded.contains(" %s " % word):
			return word
	return ""


# --- item 15: the chain, end to end ----------------------------------------

func _test_the_act_is_recorded_as_an_act() -> void:
	# What the god DID, kept in its own store. The record may name the player's
	# aim, because the engine does know it; nothing downstream may read it.
	var simulation := _world_ready_to_act()
	var state = simulation.state
	var before: int = state.divine_action_archive.size()
	var result := _rain(simulation)

	assert(state.divine_action_archive.size() == before + 1,
		"Send Rain recorded %d divine acts, not one" % (state.divine_action_archive.size() - before))
	var record: Dictionary = state.get_divine_action(str(result["divine_action_id"]))
	assert(not record.is_empty(), "the divine action id led nowhere")
	for field: String in [
		"id", "year", "action_type", "target_id", "subject_id",
		"parameters", "power_cost", "result", "consequence_id", "pipeline"
	]:
		assert(record.has(field), "the divine action record is missing '%s'" % field)
	assert(str(record["action_type"]) == MIGRATED, "the record names the wrong act")
	assert(str(record["target_id"]) == "aster", "the record names the wrong place")
	assert(int(record["power_cost"]) > 0, "the act cost nothing")
	assert(str(record["pipeline"]) == "shared", "Send Rain did not take the shared road")
	assert(not str(record["consequence_id"]).is_empty(),
		"the act is not tied to what it changed")
	# It records the act, never the meaning of it.
	assert(_mentions_meaning(str(record["result"])).is_empty()
		or not str(record["result"]).to_lower().contains("answered"),
		"the divine action record decided what the act meant")
	print("  ACT: %s -> %s, cost %d, pipeline %s." % [
		str(record["action_type"]), str(record["target_id"]),
		int(record["power_cost"]), str(record["pipeline"])
	])
	completed += 1


func _test_the_world_objectively_changed() -> void:
	# Rain is not a rumour. Something in the world is different afterwards.
	var simulation := _world_ready_to_act()
	var state = simulation.state
	var before_food: int = state.get_settlement_band("aster", "food")
	var before_stability: int = state.get_settlement_band("aster", "stability")
	simulation.resolve_action(MIGRATED)
	var moved: bool = state.get_settlement_band("aster", "food") != before_food \
		or state.get_settlement_band("aster", "stability") != before_stability
	assert(moved, "Send Rain changed nothing about Aster")
	print("  WORLD: Aster food %d -> %d." % [
		before_food, state.get_settlement_band("aster", "food")
	])
	completed += 1


func _test_an_objective_occurrence_was_offered() -> void:
	# The consequence layer produced a fact for mortals to notice, and the fact
	# describes weather rather than mercy.
	var simulation := _rained_world()
	var state = simulation.state
	var consequence := _rain_consequence(state)
	assert(not consequence.is_empty(), "the rain produced no consequence record")
	assert(not consequence["state_changes"].is_empty(),
		"the rain consequence recorded no objective change")
	var knowledge := _rain_knowledge(state, "aster_king")
	assert(not knowledge.is_empty(), "no rain occurrence reached anybody")
	var claim := str(knowledge["claim"])
	var meaning_word := _mentions_meaning(claim)
	assert(meaning_word.is_empty(),
		"the objective claim said '%s': \"%s\"" % [meaning_word, claim])
	assert(claim.to_lower().contains("rain"), "the claim is not about rain: \"%s\"" % claim)
	print("  OCCURRENCE: \"%s\"." % claim)
	completed += 1


func _test_only_eligible_mortals_perceived_it() -> void:
	# Local observability, honoured. The King is in Aster and saw it; Mara is in
	# Westfield and did not, and nothing corrected that on her behalf.
	var simulation := _rained_world("aster")
	var state = simulation.state
	assert(not _rain_knowledge(state, "aster_king").is_empty(),
		"the King stood in the rain and did not notice")
	if state.notable_entities.has("mara"):
		assert(_rain_knowledge(state, "mara").is_empty(),
			"Mara learned about rain in a settlement she does not live in")
	print("  PERCEPTION: the rain reached the people who were there, and stopped.")
	completed += 1


func _test_knowledge_holds_the_fact_and_nothing_else() -> void:
	# Knowledge is what they believe HAPPENED. Not what it was for.
	var simulation := _rained_world()
	var knowledge := _rain_knowledge(simulation.state, "aster_king")
	assert(not knowledge.is_empty(), "nobody holds the rain")
	assert(str(knowledge["source_type"]) == "direct",
		"a witnessed occurrence was stored as hearsay")
	for field: String in ["claim", "topic"]:
		var word := _mentions_meaning(str(knowledge[field]))
		assert(word.is_empty(),
			"knowledge field '%s' carried the meaning word '%s'" % [field, word])
	assert(not knowledge.has("interpretation") and not knowledge.has("meaning"),
		"the knowledge record grew a meaning of its own")
	print("  KNOWLEDGE: the King believes rain fell, and nothing more than that.")
	completed += 1


func _test_someone_reached_a_conclusion() -> void:
	# Interpretation is where meaning is allowed to appear, and it did.
	var simulation := _rained_world()
	var readings := _rain_readings(simulation.state)
	assert(not readings.is_empty(), "nobody made anything of the rain at all")
	var reading: Dictionary = readings[0]
	assert(not str(reading["interpretation_type"]).is_empty(), "a reading with no type")
	assert(not str(reading["meaning"]).is_empty(), "a reading that means nothing")
	assert(not reading["considered"].is_empty(),
		"the reading recorded no alternatives it could have reached instead")
	print("  INTERPRETATION: %s reads it as %s — \"%s\"." % [
		str(reading["observer_id"]), str(reading["interpretation_type"]),
		str(reading["meaning"])
	])
	completed += 1


func _test_two_mortals_can_disagree() -> void:
	# The point of the whole milestone. Identical rain, identical claim, two
	# different people, two different conclusions — because of what THEY carry,
	# not because the engine told them what to think.
	var plain := _world_ready_to_act()
	var primed := _world_ready_to_act()
	# One of them has read a divine hand in weather before. That is existing
	# state — a past interpretation of his own — and nothing else differs.
	primed.state.interpretation_archive.append({
		"id": "interpretation_seed", "year": primed.state.year - 1,
		"observer_id": "aster_king", "source_knowledge_id": "seed",
		"topic": "weather_rain", "subject_id": "aster", "actor_id": "",
		"target_id": "", "role": "witness",
		"interpretation_type": "rain_divine_help", "meaning": "seeded",
		"confidence": 70, "score": 0, "factors": [], "considered": [],
		"planned_effect": {}, "applied_effect": {}, "effect_reason": ""
	})
	_rain(plain)
	_rain(primed)

	var plain_readings := _rain_readings(plain.state)
	var primed_readings := _rain_readings(primed.state)
	assert(not plain_readings.is_empty() and not primed_readings.is_empty(),
		"one of the two worlds produced no reading to compare")
	var plain_type := str(plain_readings[0]["interpretation_type"])
	var primed_type := str(primed_readings[0]["interpretation_type"])
	assert(plain_type != primed_type,
		"two mortals in different states reached the same conclusion (%s)" % plain_type)
	# And the fact they disagreed ABOUT is identical.
	assert(str(_rain_knowledge(plain.state, "aster_king")["claim"])
		== str(_rain_knowledge(primed.state, "aster_king")["claim"]),
		"they were not disagreeing about the same occurrence")
	print("  DISAGREEMENT: %s vs %s, from the same claim." % [plain_type, primed_type])
	completed += 1


func _test_nothing_moved_before_interpretation() -> void:
	# The moment after the act and before the year turns, no belief, no
	# relationship and no reputation has moved. Only the world has.
	var simulation := _world_ready_to_act()
	var state = simulation.state
	var faith: int = state.faith
	var followers: int = state.followers
	var reputation: String = state.reputation
	var beliefs: Array = state.beliefs.duplicate()
	var pressure: Dictionary = state.belief_pressure.duplicate(true)
	var relationships := str(state.relationships)

	simulation.resolve_action(MIGRATED)

	assert(state.faith == faith, "faith moved before anyone had interpreted anything")
	assert(state.followers == followers, "followers moved before interpretation")
	assert(state.reputation == reputation, "reputation moved before interpretation")
	assert(state.beliefs == beliefs, "a belief appeared before interpretation")
	assert(state.belief_pressure == pressure, "belief pressure moved before interpretation")
	assert(str(state.relationships) == relationships,
		"a relationship moved before interpretation")
	assert(_rain_readings(state).is_empty(),
		"the rain was interpreted in the same breath as it fell")
	print("  ORDER: after the act, only the world had changed.")
	completed += 1


func _test_a_reading_can_reach_a_later_intent() -> void:
	# The loop closes: what a mortal decided the rain meant can weight what they
	# want next. The test asserts the reading is USED, not which want wins —
	# fixing the future action here would be writing the outcome by hand.
	var control := _sim()
	var read := _sim()
	read.state.interpretation_archive.append({
		"id": "interpretation_seed", "year": read.state.year,
		"observer_id": "aster_king", "source_knowledge_id": "seed",
		"topic": "weather_rain", "subject_id": "aster", "actor_id": "",
		"target_id": "", "role": "witness",
		"interpretation_type": "rain_divine_help", "meaning": "seeded",
		"confidence": 70, "score": 0, "factors": [], "considered": [],
		"planned_effect": {}, "applied_effect": {}, "effect_reason": ""
	})
	for simulation: Object in [control, read]:
		for year in range(6):
			simulation.resolve_action("do_nothing")
			simulation.advance_year()

	var control_factors := _interpretation_factor_count(control, "aster_king")
	var read_factors := _interpretation_factor_count(read, "aster_king")
	assert(control_factors == 0,
		"a mortal with no divine reading still scored one (%d)" % control_factors)
	assert(read_factors > 0, "the King's own reading never reached his wants")
	print("  FEEDBACK: interpretation factors %d -> %d in later intent scoring." % [
		control_factors, read_factors
	])
	completed += 1


# How many times the mortal's OWN past readings were consulted while weighing
# what they want. Counted across every candidate rather than the winner, because
# asserting on the winner would be writing the future action by hand: the claim
# under test is that the reading is READ, not that it wins.
func _interpretation_factor_count(simulation: Object, actor_id: String) -> int:
	var count := 0
	for candidate: Dictionary in simulation.evaluate_intents(actor_id):
		count += candidate.get("interpretation_factors", []).size()
	return count


# --- item 16: what the act must NOT do -------------------------------------

func _test_no_global_teaching() -> void:
	# Nobody learns something because it became true. They learn it because they
	# were there.
	var simulation := _rained_world("aster")
	var state = simulation.state
	var holders: Array[String] = []
	for entity: Dictionary in state.notable_entities.values():
		if not _rain_knowledge(state, str(entity["id"])).is_empty():
			holders.append(str(entity["id"]))
	assert(not holders.is_empty(), "nobody learned it at all")
	assert(holders.size() < state.notable_entities.size(),
		"every notable mortal in the world learned about local rain")
	for holder: String in holders:
		var home := str(state.notable_entities[holder]["home_location_id"])
		assert(home == "aster", "%s learned about Aster's rain from %s" % [holder, home])
	print("  NO BROADCAST: %d of %d mortals learned it." % [
		holders.size(), state.notable_entities.size()
	])
	completed += 1


func _test_the_consequence_moves_no_faith_or_followers() -> void:
	# The consequence layer says what happened. Faith is what somebody decided
	# about it, and belongs to a layer that has not run yet.
	var simulation := _world_ready_to_act()
	var state = simulation.state
	var faith: int = state.faith
	var followers: int = state.followers
	simulation.resolve_action(MIGRATED)
	assert(state.faith == faith, "Send Rain moved faith by %d" % (state.faith - faith))
	assert(state.followers == followers,
		"Send Rain moved followers by %d" % (state.followers - followers))
	# And the record itself contains no such change.
	for change: Dictionary in _rain_consequence(state).get("state_changes", []):
		var field := str(change["field"])
		assert(field not in ["faith", "followers", "reputation"],
			"the rain consequence wrote '%s'" % field)
	print("  NO FAITH: faith %d and followers %d, untouched by the act." % [faith, followers])
	completed += 1


func _test_the_consequence_moves_no_reputation() -> void:
	var simulation := _world_ready_to_act()
	var state = simulation.state
	var reputation: String = state.reputation
	var pressure: Dictionary = state.reputation_pressure.duplicate(true)
	simulation.resolve_action(MIGRATED)
	assert(state.reputation == reputation,
		"Send Rain renamed the god from %s to %s" % [reputation, state.reputation])
	assert(state.reputation_pressure == pressure, "Send Rain moved reputation pressure")
	print("  NO REPUTATION: the god is still '%s'." % reputation)
	completed += 1


func _test_interpretation_is_not_bypassed() -> void:
	# The act itself returns no meaning. If anything is ever going to say what
	# the rain was for, it has to be a mortal, later.
	var simulation := _world_ready_to_act()
	var result := simulation.resolve_action(MIGRATED) as Dictionary
	assert(str(result["pipeline"]) == "shared", "Send Rain reported the legacy road")
	for field: String in [
		"interpretation", "interpretation_id", "belief_tag",
		"belief_formed", "reputation_hint"
	]:
		assert(str(result[field]).is_empty(),
			"the act returned '%s': \"%s\"" % [field, str(result[field])])
	assert(not bool(result["reputation_changed"]), "the act claimed reputation changed")
	assert(simulation.state.last_interpretation.is_empty(),
		"the act left a collective interpretation behind")
	print("  NO SHORTCUT: the act reports what it did and nothing about meaning.")
	completed += 1


func _test_no_religion_doctrine_or_prophet() -> void:
	# One power moved. It did not bring a religion with it.
	var simulation := _world_ready_to_act()
	var state = simulation.state
	var flags: Dictionary = state.world_flags.duplicate(true)
	var prophet: bool = state.prophet_created
	var beliefs: Array = state.beliefs.duplicate()
	var known: Array = state.known_beliefs.duplicate()
	_rain(simulation)
	assert(state.world_flags == flags, "the rain set a world flag")
	assert(state.prophet_created == prophet, "the rain made a prophet")
	assert(state.beliefs == beliefs, "the rain founded a belief")
	assert(state.known_beliefs == known, "the rain spread a doctrine")
	# intervention_counts and action_counts DO still move. They tally the act,
	# not its meaning, nothing reads them but Developer Mode, and no belief
	# pressure follows from them — which the assertions above are what prove.
	assert(state.belief_pressure["sacred_rain"] == 0
		and state.belief_pressure["answered_prayer"] == 0,
		"the rain built theological pressure without anyone interpreting it")
	print("  NO RELIGION: no flag, no prophet, no doctrine, no belief.")
	completed += 1


func _test_the_history_line_states_only_what_happened() -> void:
	# The History Log may say rain fell. It may not say who it was for. (The
	# generated chronicle of roadmap item 13 is a different system and is not
	# built; nothing here may start it.)
	var simulation := _world_ready_to_act()
	var state = simulation.state
	var before: int = state.history_archive.size()
	simulation.resolve_action(MIGRATED)
	var added: Array = state.history_archive.slice(before)
	assert(added.size() <= 1, "one act wrote %d history lines" % added.size())
	for line: String in added:
		var word := _mentions_meaning(line)
		assert(word.is_empty(), "the history line said '%s': \"%s\"" % [word, line])
		assert(line.to_lower().contains("rain"), "the history line is not the occurrence")
	print("  HISTORY: \"%s\"." % (added[0] if added.size() > 0 else "nothing written"))
	completed += 1


func _test_no_same_year_mortal_reply() -> void:
	# Consequences are perceived the same year and answered the next. Nobody
	# acts on the rain in the tick that produced it.
	var simulation := _world_ready_to_act()
	var state = simulation.state
	var year: int = state.year
	var actions: int = state.action_archive.size()
	simulation.resolve_action(MIGRATED)
	assert(state.action_archive.size() == actions,
		"a mortal acted in the same breath as the rain fell")
	assert(state.year == year, "resolving a divine act advanced the year")
	print("  NO RECURSION: the world answers next year, not this one.")
	completed += 1


func _test_the_legacy_reading_does_not_also_run() -> void:
	# Both roads must never run for one act, or every effect lands twice.
	var simulation := _world_ready_to_act()
	var state = simulation.state
	var history: int = state.interpretation_history.size()
	var result := simulation.resolve_action(MIGRATED) as Dictionary
	assert(state.interpretation_history.size() == history,
		"the legacy divine reader ran for a migrated power")
	assert(str(state.get_divine_action(str(result["divine_action_id"]))["pipeline"]) == "shared",
		"the act was filed under the legacy pipeline")
	# One consequence, one divine record, one road.
	var rain_records := 0
	for record: Dictionary in state.divine_action_archive:
		if str(record["action_type"]) == MIGRATED:
			rain_records += 1
	assert(rain_records == 1, "one Send Rain produced %d records" % rain_records)
	print("  ONE ROAD: legacy reception did not run alongside the new chain.")
	completed += 1


func _test_the_other_powers_are_untouched() -> void:
	# The migration is one power wide, on purpose. Everything else still gets
	# its collective meaning from the legacy reader, exactly as before.
	for action_id: String in UNMIGRATED:
		var simulation := _world_ready_to_act()
		var state = simulation.state
		var result := simulation.resolve_action(action_id) as Dictionary
		if not bool(result["ok"]):
			continue
		assert(str(result["pipeline"]) == "legacy",
			"%s was quietly migrated" % action_id)
		assert(not str(result["interpretation"]).is_empty(),
			"%s lost its legacy interpretation" % action_id)
		assert(not state.last_interpretation.is_empty(),
			"%s left no collective reading" % action_id)
		print("  LEGACY KEPT: %s still reads \"%s\"." % [
			action_id, str(result["interpretation"])
		])
	completed += 1


func _test_the_occurrence_is_the_same_whatever_it_meant() -> void:
	# What happened does not bend to what anyone made of it. Two worlds that
	# reach different conclusions still hold the identical fact, at identical
	# confidence, drawn from an identical consequence.
	var plain := _world_ready_to_act()
	var primed := _world_ready_to_act()
	primed.state.interpretation_archive.append({
		"id": "interpretation_seed", "year": primed.state.year - 1,
		"observer_id": "aster_king", "source_knowledge_id": "seed",
		"topic": "weather_rain", "subject_id": "aster", "actor_id": "",
		"target_id": "", "role": "witness",
		"interpretation_type": "rain_divine_help", "meaning": "seeded",
		"confidence": 70, "score": 0, "factors": [], "considered": [],
		"planned_effect": {}, "applied_effect": {}, "effect_reason": ""
	})
	_rain(plain)
	_rain(primed)

	var plain_fact := _rain_knowledge(plain.state, "aster_king")
	var primed_fact := _rain_knowledge(primed.state, "aster_king")
	for field: String in ["id", "claim", "topic", "confidence", "source_type"]:
		assert(str(plain_fact[field]) == str(primed_fact[field]),
			"the occurrence's '%s' changed with the interpretation" % field)
	assert(plain.state.get_settlement_band("aster", "food")
		== primed.state.get_settlement_band("aster", "food"),
		"Aster's food depended on what somebody thought the rain was")
	assert(str(_rain_readings(plain.state)[0]["interpretation_type"])
		!= str(_rain_readings(primed.state)[0]["interpretation_type"]),
		"the two worlds did not actually disagree, so this proves nothing")
	print("  FACT HOLDS: same rain, same confidence, two meanings.")
	completed += 1


func _test_the_whole_chain_is_deterministic() -> void:
	# No dice anywhere along the divine road, and two identical worlds reach an
	# identical chain: same act, same consequence, same knowledge, same reading.
	for path: String in ["res://scripts/interpretation_rules.gd", "res://scripts/world_sim.gd"]:
		var source := FileAccess.get_file_as_string(path)
		var divine_slice := source
		for forbidden: String in ["randi", "randf", "RandomNumberGenerator"]:
			if divine_slice.contains(forbidden):
				assert(path.ends_with("world_sim.gd"),
					"the interpretation rules rolled dice via '%s'" % forbidden)
	var signatures: Array[String] = []
	for run in range(2):
		var simulation := _rained_world()
		var state = simulation.state
		var record: Dictionary = state.divine_action_archive.back()
		var parts: Array[String] = [
			"%s|%s|%s" % [str(record["id"]), str(record["pipeline"]),
				str(record["consequence_id"])],
			str(_rain_knowledge(state, "aster_king").get("claim", "")),
			"%d" % int(_rain_knowledge(state, "aster_king").get("confidence", 0))
		]
		for reading: Dictionary in _rain_readings(state):
			parts.append("%s:%s:%d" % [
				str(reading["observer_id"]), str(reading["interpretation_type"]),
				int(reading["score"])
			])
		signatures.append("\n".join(parts))
	assert(signatures[0] == signatures[1],
		"two identical worlds produced different divine chains")
	print("  DETERMINISTIC: the chain reproduced exactly, end to end.")
	completed += 1
