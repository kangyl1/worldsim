extends SceneTree

const PresentationRulesScript = preload("res://scripts/presentation_rules.gd")

const EXPECTED_TESTS := 8
# Every player-facing band set, checked the same way.
const BAND_SETS := {
	"trust": PresentationRulesScript.TRUST_BANDS,
	"fear": PresentationRulesScript.FEAR_BANDS,
	"respect": PresentationRulesScript.RESPECT_BANDS,
	"hostility": PresentationRulesScript.HOSTILITY_BANDS,
	"faith": PresentationRulesScript.FAITH_BANDS,
	"confidence": PresentationRulesScript.CONFIDENCE_BANDS
}

var completed := 0


func _init() -> void:
	_test_bands_are_well_formed()
	_test_every_value_maps_to_exactly_one_label()
	_test_boundaries_land_on_the_right_side()
	_test_values_clamp_safely()
	_test_relationship_axes_are_separate()
	_test_relationship_dispatch_matches_direct_calls()
	_test_confidence_never_claims_truth()
	_test_labels_do_not_leak_numbers()
	if completed != EXPECTED_TESTS:
		push_error("Presentation suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("PRESENTATION TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("PRESENTATION TEST PASSED: every value reads as meaning, with no gaps.")
	quit(0)


func _test_bands_are_well_formed() -> void:
	for band_name in BAND_SETS:
		var bands: Array = BAND_SETS[band_name]
		assert(not bands.is_empty(), "%s needs bands" % band_name)
		var previous := -1
		var seen: Array[String] = []
		for band: Dictionary in bands:
			var maximum := int(band["max"])
			assert(maximum > previous, "%s bands must ascend" % band_name)
			assert(maximum >= 0 and maximum <= 100, "%s bands stay inside 0-100" % band_name)
			var label := str(band["label"])
			assert(not label.strip_edges().is_empty(), "%s has an empty label" % band_name)
			assert(label not in seen, "%s repeats the label '%s'" % [band_name, label])
			seen.append(label)
			previous = maximum
		assert(previous == 100, "%s must cover the top of the range" % band_name)
	completed += 1
	print("  BANDS: %d sets ascend, stay in range, and reach 100." % BAND_SETS.size())


func _test_every_value_maps_to_exactly_one_label() -> void:
	for band_name in BAND_SETS:
		var bands: Array = BAND_SETS[band_name]
		var labels: Array[String] = []
		for value in range(0, 101):
			var label := PresentationRulesScript.label_for(value, bands)
			assert(not label.is_empty(), "%s left %d unlabelled" % [band_name, value])
			if labels.is_empty() or labels[labels.size() - 1] != label:
				# A label may only begin once: bands must not interleave.
				assert(label not in labels, "%s revisits '%s'" % [band_name, label])
				labels.append(label)
		assert(labels.size() == bands.size(), "%s should use each band exactly once" % band_name)
	completed += 1
	print("  COVERAGE: all 101 values map, in order, with no gaps or repeats.")


func _test_boundaries_land_on_the_right_side() -> void:
	# The band edge belongs to the lower band; one past it starts the next.
	for band_name in BAND_SETS:
		var bands: Array = BAND_SETS[band_name]
		for index in bands.size():
			var band: Dictionary = bands[index]
			var edge := int(band["max"])
			assert(PresentationRulesScript.label_for(edge, bands) == str(band["label"]),
				"%s: %d should still be '%s'" % [band_name, edge, band["label"]])
			if index + 1 < bands.size():
				var next_label := str(bands[index + 1]["label"])
				assert(PresentationRulesScript.label_for(edge + 1, bands) == next_label,
					"%s: %d should already be '%s'" % [band_name, edge + 1, next_label])
	assert(PresentationRulesScript.trust_label(54) == "Cautious")
	assert(PresentationRulesScript.trust_label(55) == "Strong")
	assert(PresentationRulesScript.faith_label(44) == "Growing")
	assert(PresentationRulesScript.faith_label(45) == "Strong")
	assert(PresentationRulesScript.confidence_label(79) == "Fairly sure")
	assert(PresentationRulesScript.confidence_label(80) == "Certain of it")
	completed += 1
	print("  BOUNDARIES: every edge and edge+1 lands in the intended band.")


func _test_values_clamp_safely() -> void:
	for band_name in BAND_SETS:
		var bands: Array = BAND_SETS[band_name]
		var lowest := PresentationRulesScript.label_for(0, bands)
		var highest := PresentationRulesScript.label_for(100, bands)
		for below in [-1, -50, -9999]:
			assert(PresentationRulesScript.label_for(int(below), bands) == lowest,
				"%s must clamp %d to its lowest band" % [band_name, below])
		for above in [101, 250, 9999]:
			assert(PresentationRulesScript.label_for(int(above), bands) == highest,
				"%s must clamp %d to its highest band" % [band_name, above])
	completed += 1
	print("  CLAMPING: out-of-range values fall to the nearest band, never blank.")


func _test_relationship_axes_are_separate() -> void:
	# The same number means different things on different axes: 40 is cautious
	# trust but active hostility. Collapsing the axes would lose that.
	assert(PresentationRulesScript.trust_label(40) == "Cautious")
	assert(PresentationRulesScript.fear_label(40) == "Afraid")
	assert(PresentationRulesScript.respect_label(40) == "Moderate")
	assert(PresentationRulesScript.hostility_label(40) == "Hostile")
	var labels := [
		PresentationRulesScript.trust_label(40),
		PresentationRulesScript.fear_label(40),
		PresentationRulesScript.respect_label(40),
		PresentationRulesScript.hostility_label(40)
	]
	assert(labels.size() == 4)
	for label in labels:
		assert(not str(label).is_empty())
	completed += 1
	print("  AXES: one value reads four ways, so the axes stay distinct.")


func _test_relationship_dispatch_matches_direct_calls() -> void:
	for value in range(0, 101, 7):
		assert(PresentationRulesScript.relationship_label("trust", value)
			== PresentationRulesScript.trust_label(value))
		assert(PresentationRulesScript.relationship_label("fear", value)
			== PresentationRulesScript.fear_label(value))
		assert(PresentationRulesScript.relationship_label("respect", value)
			== PresentationRulesScript.respect_label(value))
		assert(PresentationRulesScript.relationship_label("hostility", value)
			== PresentationRulesScript.hostility_label(value))
	assert(PresentationRulesScript.relationship_label("affection", 50).is_empty(),
		"an unknown axis must not invent a label")
	for axis: String in WorldState.RELATIONSHIP_AXES:
		assert(PresentationRulesScript.AXIS_BANDS.has(axis),
			"every simulation axis needs a presentation band: %s" % axis)
	completed += 1
	print("  DISPATCH: axis lookup matches direct calls for all four axes.")


func _test_confidence_never_claims_truth() -> void:
	# Confidence describes how sure someone feels, never whether they are right.
	var forbidden := ["true", "false", "correct", "wrong", "right", "accurate", "mistaken"]
	for value in range(0, 101):
		var label := PresentationRulesScript.confidence_label(value).to_lower()
		for word: String in forbidden:
			assert(not label.split(" ").has(word),
				"confidence label '%s' judges truth" % label)
	assert(PresentationRulesScript.confidence_label(90) == "Certain of it",
		"a strongly held false belief still reads as certainty")
	completed += 1
	print("  TRUTH: confidence wording describes conviction, not correctness.")


func _test_labels_do_not_leak_numbers() -> void:
	for band_name in BAND_SETS:
		var bands: Array = BAND_SETS[band_name]
		for value in range(0, 101):
			var label := PresentationRulesScript.label_for(value, bands)
			for character in label:
				assert(not str(character).is_valid_int(),
					"%s label '%s' exposes a digit" % [band_name, label])
			assert(not label.contains("%"), "%s label '%s' exposes a percentage" % [band_name, label])
	completed += 1
	print("  READABILITY: no label carries a digit or a percent sign.")
