extends Control

const ACTION_KEYS := ["send_rain", "bless_harvest", "speak_mortal", "do_nothing"]
# Events that read as an active crisis on the map.
const CRISIS_EVENTS := ["drought", "unrest"]
# Monospaced rows: name on the left, power cost right-aligned to this width.
const ACTION_ROW_WIDTH := 34
const PERSON_META_PREFIX := "person:"
const BACK_META := "back"
# Player-readable names for the intentions the decision engine records.
const DECISION_LABELS := {
	"send_aid": "Send aid",
	"warn_ally": "Warn an ally",
	"exploit_weakness": "Exploit a weakness",
	"investigate": "Look into it",
	"wait_and_observe": "Wait and watch"
}

var simulation := WorldSimulation.new()
var action_buttons: Array[Button] = []
# Selection is interface state. It deliberately does not live in WorldState,
# so looking at a place can never change what is true about the world.
var selected_location_id: String = "aster"
var hovered_action_index: int = -1
var hovered_person_id: String = ""
var selected_person_id: String = ""

@onready var year_value: Label = %YearValue
@onready var power_value: Label = %PowerValue
@onready var followers_value: Label = %FollowersValue
@onready var faith_value: Label = %FaithValue
@onready var reputation_value: Label = %ReputationValue
@onready var time_value: Label = %TimeValue
@onready var event_title: Label = %EventTitle
@onready var event_description: Label = %EventDescription
@onready var result_text: RichTextLabel = %ResultText
@onready var action_hint: Label = %ActionHint
@onready var world_map: WorldMapView = %WorldMap
@onready var location_text: RichTextLabel = %LocationText
@onready var history_text: RichTextLabel = %HistoryText
@onready var beliefs_text: RichTextLabel = %BeliefsText
@onready var notable_text: RichTextLabel = %NotableText
@onready var notable_panel: PanelContainer = %NotablePanel
@onready var advance_button: Button = %AdvanceButton


func _ready() -> void:
	action_buttons = [%Action1, %Action2, %Action3, %Action4]
	for index in action_buttons.size():
		action_buttons[index].pressed.connect(_on_action_pressed.bind(index))
		action_buttons[index].mouse_entered.connect(_on_action_hovered.bind(index))
		action_buttons[index].mouse_exited.connect(_on_action_unhovered.bind(index))
	advance_button.pressed.connect(_on_advance_pressed)
	simulation.state_changed.connect(_render)
	var map_locations := {}
	for location_id: String in simulation.state.get_location_ids():
		var location := simulation.state.get_location(location_id)
		map_locations[location_id] = {"name": str(location["name"]), "kind": str(location["kind"])}
	world_map.set_locations(map_locations)
	world_map.location_clicked.connect(_on_location_clicked)
	location_text.meta_clicked.connect(_on_person_clicked)
	location_text.meta_hover_started.connect(_on_person_hover_started)
	location_text.meta_hover_ended.connect(_on_person_hover_ended)
	_render()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_4:
		choose_action(int(event.keycode - KEY_1))
		get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		advance_year()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F1:
		# Development access to raw simulation telemetry, hidden by default.
		notable_panel.visible = not notable_panel.visible
		if notable_panel.visible:
			_render_notable_people()
		get_viewport().set_input_as_handled()


func _on_action_pressed(index: int) -> void:
	choose_action(index)


func _on_advance_pressed() -> void:
	advance_year()


func choose_action(index: int) -> void:
	if index < 0 or index >= ACTION_KEYS.size():
		return
	var result := simulation.resolve_action(ACTION_KEYS[index])
	if not result["ok"]:
		result_text.text = str(result["message"])


func advance_year() -> void:
	var result := simulation.advance_year()
	if not result["ok"]:
		result_text.text = str(result["message"])


func _render() -> void:
	var state := simulation.state
	var event := simulation.get_current_event()
	year_value.text = str(state.year)
	power_value.text = "%d / %d" % [state.divine_power, state.max_divine_power]
	followers_value.text = str(state.followers)
	faith_value.text = "%d%%" % state.faith
	reputation_value.text = state.reputation.to_upper()
	time_value.text = "READY TO ADVANCE" if state.action_taken else "AWAITING CHOICE"
	time_value.modulate = Color("e8be63") if state.action_taken else Color("76c8d5")

	event_title.text = str(event["title"])
	event_description.text = str(event["description"])
	if state.last_result.is_empty():
		result_text.text = "[color=#7f898b]Awaiting divine input.[/color]"
	elif state.last_interpretation.is_empty():
		result_text.text = "[color=#9ca5a4]%s[/color]" % state.last_result
	else:
		result_text.text = (
			"[color=#9ca5a4]%s[/color]\n\n" % state.last_result
			+ "[color=#b38bc4]INTERPRETATION[/color]\n"
			+ "[color=#d7c8dc]\"%s\"[/color]" % state.last_interpretation
		)

	_render_actions()
	_render_map()
	_render_location()
	_render_history()
	_render_beliefs()
	if notable_panel.visible:
		_render_notable_people()
	advance_button.disabled = not state.action_taken


func _render_actions() -> void:
	var state := simulation.state
	for index in ACTION_KEYS.size():
		var action_id: String = ACTION_KEYS[index]
		var action := simulation.get_action(action_id)
		var cost := int(action["cost"])
		var label := "%d.  %s" % [index + 1, action["title"]]
		var cost_label := "%d Power" % cost
		# The interface font is monospaced, so padding keeps the costs aligned.
		var padding := maxi(ACTION_ROW_WIDTH - label.length() - cost_label.length(), 1)
		action_buttons[index].text = label + " ".repeat(padding) + cost_label
		action_buttons[index].disabled = state.action_taken or state.divine_power < cost
	_render_action_hint()


func _render_action_hint() -> void:
	var state := simulation.state
	if hovered_action_index >= 0 and hovered_action_index < ACTION_KEYS.size():
		var action := simulation.get_action(ACTION_KEYS[hovered_action_index])
		var cost := int(action["cost"])
		if state.action_taken:
			action_hint.text = "%s  ·  already answered this year" % str(action["hint"])
		elif state.divine_power < cost:
			action_hint.text = "%s  ·  needs %d power, you hold %d" % [
				str(action["hint"]), cost, state.divine_power
			]
		else:
			action_hint.text = str(action["hint"])
		return
	action_hint.text = "The year awaits your answer." if not state.action_taken \
		else "Advance the year to see what the world makes of it."


func _on_action_hovered(index: int) -> void:
	hovered_action_index = index
	_render_action_hint()


func _on_action_unhovered(index: int) -> void:
	if hovered_action_index == index:
		hovered_action_index = -1
		_render_action_hint()


func _on_person_clicked(meta) -> void:
	# Inspection only: this never resolves an action or advances time.
	if str(meta) == BACK_META:
		selected_person_id = ""
		hovered_person_id = ""
		_render_location()
		return
	var entity_id := _person_id_from_meta(str(meta))
	if entity_id.is_empty() or simulation.state.get_notable_entity(entity_id).is_empty():
		return
	selected_person_id = entity_id
	_render_location()


func _on_person_hover_started(meta) -> void:
	hovered_person_id = _person_id_from_meta(str(meta))
	_render_location()


func _on_person_hover_ended(_meta) -> void:
	hovered_person_id = ""
	_render_location()


func _person_id_from_meta(meta: String) -> String:
	if not meta.begins_with(PERSON_META_PREFIX):
		return ""
	return meta.substr(PERSON_META_PREFIX.length())


func _on_location_clicked(location_id: String) -> void:
	if simulation.state.get_location(location_id).is_empty():
		return
	selected_location_id = location_id
	# Looking somewhere else closes whoever was open.
	selected_person_id = ""
	hovered_person_id = ""
	_render()


func _render_map() -> void:
	var state := simulation.state
	var markers := {}
	for location_id: String in state.get_location_ids():
		markers[location_id] = {
			"crisis": _location_in_crisis(location_id),
			"divine": _location_is_holy(location_id)
		}
	world_map.set_markers(markers)
	world_map.set_selected_location(selected_location_id)


func _location_in_crisis(location_id: String) -> bool:
	# Only the capital carries simulated conditions in this prototype.
	if not bool(simulation.state.get_location(location_id).get("simulated", false)):
		return false
	return simulation.state.current_event_id in CRISIS_EVENTS


func _location_is_holy(location_id: String) -> bool:
	if not bool(simulation.state.get_location(location_id).get("simulated", false)):
		return false
	return not simulation.state.beliefs.is_empty()


func _render_location() -> void:
	if not selected_person_id.is_empty():
		_render_person()
		return
	var state := simulation.state
	var location := state.get_location(selected_location_id)
	if location.is_empty():
		location_text.text = "[color=#68757c](No location selected.)[/color]"
		return
	var lines: Array[String] = [
		"[color=#e5e1d8]%s[/color]" % str(location["name"]).to_upper(),
		"[color=#68757c]%s[/color]\n" % _location_kind_label(str(location["kind"]))
	]
	if bool(location.get("simulated", false)):
		lines.append_array(_simulated_location_lines())
	else:
		lines.append_array(_placeholder_location_lines(location))
	location_text.text = "\n".join(lines)


func _location_kind_label(kind: String) -> String:
	match kind:
		"capital":
			return "Capital of the Kingdom"
		"farming_village":
			return "Farming village of the Kingdom"
		"frontier_settlement":
			return "Frontier settlement of the Kingdom"
	return "Settlement of the Kingdom"


func _simulated_location_lines() -> Array[String]:
	# Every value below is read from the simulation. Nothing is stored here.
	var state := simulation.state
	var lines: Array[String] = [
		"[color=#68757c]POPULATION[/color]   %d" % state.population,
		"[color=#68757c]FOOD[/color]         %s" % _status_colour(state.food_name(), state.food_level),
		"[color=#68757c]STABILITY[/color]    %s" % _status_colour(state.stability_name(), state.stability_level),
		"[color=#68757c]PROSPERITY[/color]   %s" % _status_colour(state.prosperity_name(), state.prosperity_level),
		"[color=#68757c]MILITARY[/color]     %s" % _status_colour(state.military_name(), state.military_level),
		""
	]
	if _location_in_crisis(selected_location_id):
		lines.append("[color=#d66a5e]! %s[/color]" % str(simulation.get_current_event()["title"]))
	else:
		lines.append("[color=#68757c]Current situation:[/color] [color=#9ca5a4]%s[/color]" % str(
			simulation.get_current_event()["title"]
		))
	lines.append("")
	lines.append("[color=#68757c]IMPORTANT PEOPLE[/color]")
	var entity_ids := _sorted_entity_ids()
	if entity_ids.is_empty():
		lines.append("[color=#68757c](none)[/color]")
	for entity_id: String in entity_ids:
		lines.append(_person_row(entity_id))
	return lines


# The person view shows what this mortal believes and intends. It deliberately
# never reads objective_truth_state, distortion, or transmission counts: the
# player is a god, but this panel is not the god's omniscient readout.
func _render_person() -> void:
	var state := simulation.state
	var entity := state.get_notable_entity(selected_person_id)
	if entity.is_empty():
		selected_person_id = ""
		_render_location()
		return
	var traits: Array = entity.get("traits", [])
	var trait_names: Array[String] = []
	for trait_value in traits:
		trait_names.append(str(trait_value).capitalize())
	var lines: Array[String] = [
		"[color=#e5e1d8]%s[/color]" % str(entity.get("name", selected_person_id)).to_upper(),
		"[color=#68757c]%s[/color]" % str(entity.get("kind", "person")).capitalize(),
		"[color=#9ca5a4]%s[/color]\n" % (
			" · ".join(trait_names) if not trait_names.is_empty() else "No recorded traits"
		)
	]
	lines.append_array(_person_intention_lines())
	lines.append("")
	lines.append_array(_person_relationship_lines())
	lines.append("")
	lines.append_array(_person_knowledge_lines())
	lines.append("")
	var location := state.get_location(selected_location_id)
	lines.append("[url=%s][color=#76c8d5]<-  BACK TO %s[/color][/url]" % [
		BACK_META, str(location.get("name", "the map")).to_upper()
	])
	location_text.text = "\n".join(lines)


func _person_intention_lines() -> Array[String]:
	var lines: Array[String] = ["[color=#68757c]CURRENT INTENTION[/color]"]
	var records: Array[Dictionary] = simulation.state.get_decisions_for(selected_person_id)
	if records.is_empty():
		lines.append("[color=#73627f]None recorded.[/color]")
		return lines
	# The archive appends chronologically, so the last record is the newest.
	var latest: Dictionary = records.back()
	var decision_type := str(latest["decision_type"])
	lines.append("[color=#e8be63]%s[/color]" % str(
		DECISION_LABELS.get(decision_type, decision_type.capitalize())
	))
	var target_name := _display_name_for(str(latest["target_id"]))
	if not target_name.is_empty():
		lines.append("[color=#68757c]Toward:[/color] [color=#9ca5a4]%s[/color]" % target_name)
	lines.append("[color=#68757c]Formed in year %d.[/color]" % int(latest["year"]))
	return lines


func _person_relationship_lines() -> Array[String]:
	# Directed: this person's view of others. Mara -> the King is not the same
	# record as the King -> Mara, and the two are never merged here.
	var state := simulation.state
	var lines: Array[String] = ["[color=#68757c]RELATIONSHIPS[/color]"]
	var found := false
	for target_id: String in _sorted_entity_ids():
		if target_id == selected_person_id:
			continue
		var record := state.get_relationship(selected_person_id, target_id)
		if record.is_empty():
			continue
		found = true
		lines.append("[color=#9ca5a4]%s[/color]" % _display_name_for(target_id))
		lines.append("[color=#8d989d]   Trust     %3d      Fear       %3d[/color]" % [
			int(record["trust"]), int(record["fear"])
		])
		lines.append("[color=#8d989d]   Respect   %3d      Hostility  %3d[/color]" % [
			int(record["respect"]), int(record["hostility"])
		])
	if not found:
		lines.append("[color=#73627f]No notable relationships.[/color]")
	return lines


func _person_knowledge_lines() -> Array[String]:
	var state := simulation.state
	var lines: Array[String] = ["[color=#68757c]KNOWN INFORMATION[/color]"]
	var stored := state.get_all_knowledge(selected_person_id)
	var knowledge_ids: Array = stored.keys()
	knowledge_ids.sort()
	var shown := 0
	for knowledge_id_value in knowledge_ids:
		var record: Dictionary = stored[str(knowledge_id_value)]
		if bool(record.get("invalidated", false)):
			continue
		var claim := str(record.get("claim", "")).strip_edges()
		if claim.is_empty():
			continue
		var confidence := int(record["confidence"])
		lines.append("[color=#9ca5a4]\"%s\"[/color]" % claim)
		lines.append("[color=#68757c]   %s (%d%%)[/color]" % [_certainty_label(confidence), confidence])
		var source_id := str(record.get("source_id", ""))
		if source_id.is_empty() or source_id == selected_person_id:
			lines.append("[color=#68757c]   Witnessed it directly.[/color]")
		else:
			lines.append("[color=#68757c]   Heard from %s.[/color]" % _display_name_for(source_id))
		# Staleness from the mortal's side: when they last had word of it.
		var age := maxi(state.year - int(record.get("last_updated_year", state.year)), 0)
		if age == 0:
			lines.append("[color=#68757c]   Word of it came this year.[/color]")
		else:
			lines.append("[color=#68757c]   Last word of it %d year%s ago.[/color]" % [
				age, "" if age == 1 else "s"
			])
		shown += 1
	if shown == 0:
		lines.append("[color=#73627f]None recorded.[/color]")
	return lines


func _certainty_label(confidence: int) -> String:
	# How sure the mortal feels, not how true the claim is.
	if confidence >= 75:
		return "Certain of it"
	if confidence >= 50:
		return "Fairly sure"
	if confidence >= 25:
		return "Unsure"
	return "Barely credits it"


func _display_name_for(target_id: String) -> String:
	if target_id.is_empty():
		return ""
	var entity := simulation.state.get_notable_entity(target_id)
	if not entity.is_empty():
		return str(entity.get("name", target_id))
	var location := simulation.state.get_location(target_id)
	if not location.is_empty():
		return str(location.get("name", target_id))
	return target_id


func _person_row(entity_id: String) -> String:
	# Rows are already selectable so the next pass can open a person view.
	var entity := simulation.state.get_notable_entity(entity_id)
	var name_text := str(entity.get("name", entity_id))
	var colour := "#8d989d"
	var marker := " "
	if entity_id == selected_person_id:
		colour = "#e8be63"
		marker = ">"
	elif entity_id == hovered_person_id:
		colour = "#e5e1d8"
		marker = ">"
	var detail := ""
	if entity_id == selected_person_id:
		var traits: Array = entity.get("traits", [])
		detail = "\n     [color=#68757c]%s[/color]" % (
			", ".join(traits) if not traits.is_empty() else "no traits recorded"
		)
	return "[url=%s%s][color=%s]%s  %s[/color][/url]%s" % [
		PERSON_META_PREFIX, entity_id, colour, marker, name_text, detail
	]


func _placeholder_location_lines(location: Dictionary) -> Array[String]:
	return [
		"[color=#68757c]Primary role:[/color] [color=#9ca5a4]%s[/color]" % str(location.get("role", "Unknown")),
		"",
		"[color=#68757c]Detailed settlement simulation:[/color]",
		"[color=#73627f]Not yet implemented.[/color]",
		"",
		"[color=#68757c]Kingdom-wide conditions are shown under the capital.[/color]"
	]


func _status_colour(value: String, level: int) -> String:
	var colours := ["#d66a5e", "#d99a54", "#e8be63", "#71b892"]
	return "[color=%s]%s[/color]" % [colours[clampi(level, 0, 3)], value.to_upper()]


func _render_history() -> void:
	var lines: Array[String] = []
	for index in simulation.state.history.size():
		var colour := "#e5e1d8" if index == 0 else "#8d989d"
		lines.append("[color=%s]%s[/color]" % [colour, simulation.state.history[index]])
	history_text.text = "\n\n".join(lines)


func _render_beliefs() -> void:
	if simulation.state.beliefs.is_empty():
		beliefs_text.text = "[color=#73627f](None)[/color]\n\n[color=#68757c]Interpretations may become doctrine.[/color]"
		return
	var lines: Array[String] = []
	for belief in simulation.state.beliefs:
		lines.append("[color=#b38bc4]◆  %s[/color]" % belief)
	beliefs_text.text = "\n\n".join(lines)


# Debug inspection only: this panel reads simulation data and never changes it.
func _render_notable_people() -> void:
	var state := simulation.state
	var entity_ids := _sorted_entity_ids()
	if entity_ids.is_empty():
		notable_text.text = "[color=#68757c](No notable people.)[/color]"
		return
	var blocks: Array[String] = []
	for entity_id: String in entity_ids:
		blocks.append(_notable_entity_block(entity_id, entity_ids))
	notable_text.text = "\n\n".join(blocks)


func _sorted_entity_ids() -> Array[String]:
	# Sorted by display name, then id, so the panel never reorders itself.
	var entries: Array[Dictionary] = []
	for entity_id_value in simulation.state.notable_entities.keys():
		var entity_id := str(entity_id_value)
		var entity := simulation.state.get_notable_entity(entity_id)
		if entity.is_empty():
			continue
		entries.append({"id": entity_id, "name": str(entity.get("name", entity_id))})
	entries.sort_custom(func(a, b):
		if str(a["name"]) == str(b["name"]):
			return str(a["id"]) < str(b["id"])
		return str(a["name"]) < str(b["name"])
	)
	var sorted_ids: Array[String] = []
	for entry: Dictionary in entries:
		sorted_ids.append(str(entry["id"]))
	return sorted_ids


func _notable_entity_block(entity_id: String, entity_ids: Array[String]) -> String:
	var state := simulation.state
	var entity := state.get_notable_entity(entity_id)
	var traits: Array = entity.get("traits", [])
	var traits_text := ", ".join(traits) if not traits.is_empty() else "(none)"
	var lines: Array[String] = [
		"[color=#e5e1d8]%s[/color]  [color=#68757c](%s)[/color]" % [
			str(entity.get("name", entity_id)).to_upper(), str(entity.get("kind", "unknown"))
		],
		"[color=#68757c]Traits:[/color]  [color=#9ca5a4]%s[/color]" % traits_text,
		"[color=#68757c]Relationships:[/color]"
	]
	lines.append_array(_relationship_lines(entity_id, entity_ids))
	lines.append("[color=#68757c]Knowledge:[/color]  [color=#9ca5a4]%d[/color]" % state.get_all_knowledge(entity_id).size())
	lines.append("[color=#68757c]Decision:[/color]  %s" % _latest_decision_text(entity_id))
	return "\n".join(lines)


func _relationship_lines(entity_id: String, entity_ids: Array[String]) -> Array[String]:
	# Directed: this entity's view of others only. King -> Mara is not Mara -> King.
	var lines: Array[String] = []
	for target_id: String in entity_ids:
		if target_id == entity_id:
			continue
		var record := simulation.state.get_relationship(entity_id, target_id)
		if record.is_empty():
			continue
		var target := simulation.state.get_notable_entity(target_id)
		lines.append("    [color=#9ca5a4]-> %s[/color]" % str(target.get("name", target_id)))
		lines.append(
			"       [color=#8d989d]Trust %d / Fear %d / Respect %d / Hostility %d[/color]" % [
				int(record["trust"]), int(record["fear"]), int(record["respect"]), int(record["hostility"])
			]
		)
	if lines.is_empty():
		lines.append("    [color=#68757c](none)[/color]")
	return lines


func _latest_decision_text(entity_id: String) -> String:
	var records: Array[Dictionary] = simulation.state.get_decisions_for(entity_id)
	if records.is_empty():
		return "[color=#68757c]-[/color]"
	# The archive appends chronologically, so the last record is the newest.
	var latest: Dictionary = records.back()
	var target_id := str(latest["target_id"])
	return "[color=#e8be63]%s[/color]  [color=#8d989d]· target %s · score %d · year %d[/color]" % [
		str(latest["decision_type"]),
		"none" if target_id.is_empty() else target_id,
		int(latest["score"]),
		int(latest["year"])
	]
