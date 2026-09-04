# Worldsim — Claude Code Project Instructions

## Role and authority

Claude Code is the primary coding agent for Worldsim. Inspect and understand the existing Godot project before making changes, preserve working systems, implement requested changes incrementally, test them thoroughly, and keep the architecture clean and extensible.

The user retains authority over game design, project direction, and GitHub publication.

## Mandatory operating rules

1. **NEVER commit or push to GitHub unless the user explicitly approves it first.** A request to implement, fix, test, or verify work is not permission to commit or push.
2. After completing and verifying a meaningful or major implementation, ask the user whether they want the changes committed and pushed. Wait for explicit approval before doing either.
3. If there is **ANY** design ambiguity, design problem, or architecture decision that could affect game behavior, scope, rules, simulation outcomes, or project direction, **STOP and ask the user before deciding**. Do not make autonomous game-design decisions.
4. Small, purely mechanical implementation details may be handled without asking only when they cannot alter design intent. If uncertain, ask.
5. GitHub repository `kangyl1/worldsim` is the source of truth when this document or any handoff summary conflicts with the current committed code. Inspect the repository and history when unsure.
6. Minimal Settlement State v1, Selective Perception v1, Broad Intent v1, Action Selection v1, Action Execution v1 and Consequence Engine v1 are built. Mortals notice different things, want things, try things, attempts have results, and results objectively change the world. **Nothing yet decides what any of it MEANT.** Do not build interpretation of social or divine events, or History generation, until the user explicitly asks.
7. The player-facing interface shows a mortal's perspective; Developer Mode shows the machine. Never merge the two. See "Interface rules".

## Project reference

- Repository: `kangyl1/worldsim`
- Current important commit: `8f97dd72ea5b996b2977cccf6632b145aa2b551a` — `Add Consequence Engine v1`

The mortal causal chain, one commit per layer, oldest first:

- `7b453a8655a6c4a8cea05a0ed3e0ffa2239cf515` — `Add Worldsim social and knowledge foundations`
- `dcf38771bf1983e2ccbfa36eeda2aed983f93da4` — `Add Decision Engine v1`, superseded in vocabulary by Broad Intent v1
- `9b1ad6ed3102906b35b4adbf590a68d8dbce0568` — `Record the simulation foundation revision in the GDD`, which is where Part II came from
- `f8aaf05c27c3e5c9047625cc6309fcae1217e55f` — `Add Broad Intent Model v1` (what mortals want)
- `0bf0141c1d51e0fd3e692e327f59162ecad55ebe` — `Add Mortal Action Selection v1` (what they try)
- `36cddb3a5a642c41f7e41e7e83f397ad1cf2327a` — `Add Mortal Action Execution v1` (what came of the attempt)
- `ddbde279d7140e7e4f3f2ce0107c0c8045485893` — `Add Selective Perception v1` (who could know any of it in the first place)
- `2d503b95dc3bba4149453ae5b1361d6b369f1434` — `Add Minimal Settlement State v1` (where any of it is happening)
- `8f97dd72ea5b996b2977cccf6632b145aa2b551a` — `Add Consequence Engine v1` (what changed in the world, and nothing about what it meant)

- Local project path: `/Users/jamienfam/Documents/ChatGPT/worldsim`
- Tested Godot version: `4.7.1`
- Godot is **not on `PATH`**. Use the full binary path: `/Users/jamienfam/Downloads/Godot.app/Contents/MacOS/Godot`

## Project summary

Worldsim is a systems-driven world simulation intended to produce understandable, emergent history through interacting characters, settlements, factions, relationships, knowledge, decisions, actions, and consequences.

The current foundation includes:

- a working Godot shell and UI
- world-state and simulation architecture
- Traits
- directed Relationships with `trust`, `fear`, `respect`, and `hostility`
- Knowledge and Rumors with confidence, truth, source, aging, distortion, and transmission
- bounded yearly rumor spreading
- trait and relationship effects
- mortal interpretation of divine actions, feeding beliefs and reputation
- Broad Intent Model v1: ten wants, deterministic argmax, full explainability records
- Mortal Action Selection v1: seven parameterised verbs, capability-gated, selection only
- Mortal Action Execution v1: success/failure/blocked, two-phase ticks, immediate results only
- Selective Perception v1: events offer claims, only eligible mortals notice, no global teaching
- Minimal Settlement State v1: settlements own food, stability, prosperity and population; the kingdom view derives from them
- Consequence Engine v1: objective occurrence and state change only, routed back through events and perception
- knowledge generation from existing events, outcome-aware and refreshing stable ids
- a world map interface with clickable settlements and crisis markers
- world -> settlement -> person navigation in one reusable panel
- in-game Developer Mode (DEV button, F1 secondary) exposing raw simulation values, read-only
- a centralised presentation layer turning numbers into qualitative labels
- deterministic tests across thirteen suites
- a 72-turn regression suite

Current core source files:

| File | Role |
|---|---|
| `scripts/world_state.gd` | stored truth: settlement conditions, entities, relationships, knowledge, intents, actions |
| `scripts/world_sim.gd` | simulation behaviour: actions, yearly ticks, event knowledge generation |
| `scripts/knowledge_rules.gd` | rumor transfer scoring and trait effects on information |
| `scripts/interpretation_system.gd` | how mortals interpret divine actions |
| `scripts/intent_rules.gd` | Broad Intent Model v1 scoring and explainability records |
| `scripts/action_rules.gd` | Mortal Action Selection v1: intent -> viable attempt, never executed |
| `scripts/execution_rules.gd` | Mortal Action Execution v1: attempt -> immediate result, no consequences |
| `scripts/perception_rules.gd` | Selective Perception v1: who could notice an event, and how clearly |
| `scripts/consequence_rules.gd` | Consequence Engine v1: what objectively happened, never what it meant |
| `scripts/world_map.gd` | map presentation and click hit-testing; reads nothing from the simulation |
| `scripts/presentation_rules.gd` | number -> label bands for the player-facing interface |
| `Main.gd` / `Main.tscn` | interface and player interaction only |

Test suites, all deterministic:

| Suite | Covers |
|---|---|
| `tests/smoke_test.gd` | boot, traits, relationships, 72-turn regression |
| `tests/knowledge_test.gd` | direct knowledge, rumors, traits, falsehood, aging |
| `tests/intent_test.gd` | Broad Intent v1 vocabulary, gating law, direction, intentions-only |
| `tests/action_test.gd` | action vocabulary, capability gates, no-viable-action, selection-only |
| `tests/execution_test.gd` | outcome kinds, TELL through knowledge, ASK direction, effect boundary |
| `tests/perception_test.gd` | observability modes, eligibility, pathway clarity, no global teaching |
| `tests/settlement_test.gd` | local ownership, derived kingdom view, generic events, god-game guardrails |
| `tests/consequence_test.gd` | objective occurrence, no reactions, private events, no double effects |
| `tests/event_knowledge_test.gd` | what events make perceivable, conditions, refresh-not-duplicate |
| `tests/map_model_test.gd` | location model, map hit-testing, simulation boundary |
| `tests/person_view_test.gd` | person navigation and the mortal-perspective filter |
| `tests/developer_mode_test.gd` | Developer Mode toggle, raw exposure, read-only guarantee |
| `tests/presentation_test.gd` | qualitative band mappings |

Do not assume this summary is exhaustive or newer than the code. Inspect the repository first, and use GitHub as the source of truth if anything conflicts.

## Planned system order

`Settlement state -> Events -> Perception -> Knowledge/Rumors -> Broad Intents -> Action Selection -> Action Execution -> Consequences -> feedback into settlement state/relationships/knowledge`

Everything in that chain is built. What is missing is the layer after it:
nothing yet decides what any of it MEANT.

`GDD.md` Part II (sections 29-43) revises this. Mortals should pass through a
wider chain: world state -> pressures -> perception -> belief -> interpretation
-> goal -> **broad intent** -> action selection -> consequence -> memory ->
history. Read Part II before designing anything in this area.

`GDD.md` **Part III (sections 44-54) is long-term direction and is NOT the
roadmap.** It records where the simulation is eventually going — pressure,
interpretation, historical consequence, and the limits on ecological and
planetary systems — so that near-term decisions do not foreclose it. Nothing in
Part III is scheduled or scoped, and none of it may be implemented without an
explicit request. Read it before designing, never as a work queue. If a Part III
idea starts to feel urgent, that is a signal to finish the layer in progress.

The next system is **Interpretation of social and divine events** — what a
mortal decides an occurrence meant, and how that changes their relationships,
beliefs and future wants. It must not begin until the user explicitly asks.
Consequences now produce objective occurrences nobody has yet reacted to.

**Known issue, not yet addressed.** Ambient rumor spreading runs before intents
form, so it usually carries a fact before anyone deliberately chooses to tell
it: roughly 18 rumor deliveries to 1 deliberate telling across 40 autonomous
years. Deliberate speech works and is reachable, but it is rarely the route by
which anything travels. Fixing it means reordering or rate-limiting
`tick_knowledge()`, which changes an existing system's semantics and needs its
own design pass.

**Known issue, not yet addressed.** Mortals now forget. Social occurrences add
one belief per interaction, so `MAX_KNOWLEDGE_PER_ENTITY` bounds what anyone
carries, and pruning drops retracted claims first and stale low-confidence ones
next. A mortal can therefore forget something that mattered. The cap is tuned,
not derived, and the rule has no notion of significance beyond confidence and
age.

**Known issue, not yet addressed.** Only two of the three settlements host
events across a long run, because an event goes where its condition is thinnest
and that tends to settle on the same place. The Frontier is quiet. Nothing is
wrong with the rule; the world is simply small.

**Goal is a conceptual layer only.** GDD Part II lists Goal between
interpretation and intent. v1 deliberately does not implement it: a goal field
would be derived one-to-one from the intent type and would duplicate what
`knowledge_used` already records. Build it only if a later system needs one
goal to produce several different intents.

Interpretation of social events, and History generation, **MUST NOT be implemented until the user explicitly asks**.

Broad Intent Model v1 constraints, settled with the user and to be preserved:

- intents are `help`, `protect`, `acquire`, `learn`, `influence`, `connect`, `distance`, `resolve`, `preserve`, `wait`
- an intent names what someone *wants*; naming one after something someone *does* collapses the layer (GDD section 31)
- no intent is antagonistic; war is an execution of a want, never a want itself
- `acquire` never covers information, and `learn` never covers goods or standing
- `protect` answers an identified threat; `preserve` answers erosion without one
- the gating law: gate on relevance of the evidence, weight on disposition, never gate on capability (GDD section 31)
- selection is deterministic argmax; no randomness
- traits weight intent scores and must never hard-gate an intent unless the user explicitly approves a specific gate
- intents read believed knowledge and never consult `objective_truth_state`
- outdated or distorted beliefs lose weight but never disappear
- `wait` can be chosen on merit as well as reached as the fallback, and the record's `selection` field must keep the two distinguishable
- intents are intentions only and must not change world state, relationships, or knowledge

Mortal Action Selection v1 constraints, settled with the user and to be preserved
(the verb list is provisional; everything else is durable):

- actions are `give`, `ask`, `tell`, `support`, `oppose`, `observe`, `wait`
- actions are parameterised: a verb plus target, subject, topic and resource, never one type per behaviour
- a new verb is justified only when parameters cannot express it; "warn", "preach", "beg", "teach" and "donate" are not actions
- capability is a hard gate HERE, and only here; a refused action must leave the intent exactly as it was
- an intent with no viable action is a valid outcome, recorded as `wait` with `selection: "fallback_no_viable_action"`
- three roads to `wait` stay distinguishable: `intended_wait`, `fallback_no_viable_action`, and an ordinary `argmax` win
- `go` is deferred: entities have no location, and movement must not be faked
- `give` is generated and refused every time, because nothing models a resource a mortal controls; it goes live when settlement or personal resources exist
- role weighting is deferred: entities carry only `kind`, which is `person` for everyone
- `tell` requires a believed, still-held topic and a target who does not already know it better
- actions read believed knowledge and never consult `objective_truth_state`
- selection is deterministic argmax; no randomness
- selection records an attempt and executes nothing: no resource moves, no relationship changes, no knowledge spreads, no event fires
- intent and action records stay separate, in storage and in Developer Mode; why someone wanted something and why they chose that way of pursuing it are two questions

Mortal Action Execution v1 constraints, settled with the user and to be preserved:

- outcomes are `success`, `failure` and `blocked`; blocked means the attempt could not honestly be made, and is never merged with failure
- execution re-checks only the minimum conditions, and never re-runs Action Selection
- a blocked or failed attempt must leave the intent and action records exactly as they were
- the tick runs in two phases: every attempt is decided against the world as it stood when the year's executions began, then effects are applied together, so nobody gains from sorting first
- the ONLY immediate effects permitted are `knowledge_delivered` and `observation_recorded`, both through the knowledge system; anything else is a consequence
- no relationship, statistic, flag, or history entry may change during execution
- `ask` reads the TARGET's view of the actor (`target -> actor`), because the target is deciding; selection reads the other edge, and the two must not be confused
- a successful `ask` records that the request was accepted and grants nothing; the execution archive is the state a Consequence Engine will read
- an `ask` to someone with no recorded view of the actor is a FAILURE (`no_standing_with_target`), not a block: a missing edge means no relationship, not a neutral one
- `tell` reuses the knowledge system with willingness skipped, because Action Selection already settled whether to speak; ambient rumor spreading keeps its own willingness gate
- `tell` succeeding means the words arrived, never that the target believes them
- `observe` may only see what `observable_fact()` is currently showing; it must never read `objective_truth_state`
- `give` executes as BLOCKED `no_controlled_resource` until a resource model exists
- `support` and `oppose` succeed as expression and apply nothing; opposing is objecting or refusing, never violence
- three roads to a WAIT result stay distinguishable: `deliberately_waited`, `unable_to_act`, and the selection modes behind them
- intent, action and execution records stay separate in storage and in Developer Mode; why someone wanted something, why they chose that way, and what came of it are three questions

Selective Perception v1 constraints, settled with the user and to be preserved:

- an event happening is NOT a mortal knowing it happened; events, perception, knowledge and interpretation are four layers
- observability is `direct`, `local`, `public` or `hidden`; keep the vocabulary this small
- **no global event-knowledge distribution remains.** Nothing may teach every notable entity a fact because the fact became true
- `home_location_id` is an association, not a position: no travel, distance, coordinates or schedules may be built on it without a design pass
- an entity with no home perceives no local event, and that is the honest answer rather than defaulting them into the capital
- taking part in something beats being near it: a participant perceives whatever they were party to, at any observability
- the event template is the ceiling on what can be known; world statistics the event did not expose must never leak into a claim
- clarity follows the pathway: direct 1.0, local 0.9, public 0.7, and the pathway may only reduce, never raise
- perception supplies the observation; the knowledge system still owns storage, ageing, distortion and transmission
- seeing something (`source_type: "direct"`) and being told it (`"rumor"`) must stay distinguishable
- perception must never produce meaning; "I saw rain after the prayer" is perception, "the god answered" is interpretation (GDD 12 and 26)
- observers are judged against one world snapshot, then knowledge is applied; one observer learning must never change whether another could see it
- missed chances are kept for the current year only (`last_perceptions`); the archive keeps only perceptions that happened
- seeded homes: the King is in Aster, Mara is in Westfield. That divergence is what makes their informational worlds differ
- no hallucination or misperception yet; false beliefs still arise through rumor distortion

Minimal Settlement State v1 constraints, settled with the user and to be preserved:

- **Do not expand settlement state into CK-style management, detailed economy, governance, or settlement AI without explicit approval.** This is a hard project guardrail, not a preference
- settlements are places with conditions, never actors: a settlement has no intentions, no budget, no council, no buildings, and makes no decisions. Mortals decide things
- no taxes, laws, governors, construction, levies, trade routes, vassals or succession; the god is not a ruler and must not be given a domain to administer
- a settlement field must pass all three of: can the player notice it, understand it, act on it. If it exists only because a real society would have one, it does not belong
- settlements own `food`, `stability`, `prosperity` and `population`; the kingdom's `food_level`, `stability_level`, `prosperity_level` and `population` are DERIVED views with broadcast setters, never a second copy
- **never use `+=` on a derived kingdom band.** It reads the aggregate, adds, and writes the result back to every settlement, flattening the world. Use `change_settlement_band()`
- `military_level`, `faith`, `followers` and `reputation` stay kingdom-level; not every world stat should become local
- events are settlement-generic: no code may name a settlement. The claim is a format string, the knowledge id is built from the settlement, and a new settlement needs no new event definition
- the yearly cycle is weather and falls on every settlement; the event names the one place the condition is thinnest, and only that place takes the extras
- divine actions land on the current event's settlement, not on the whole realm
- intent may read the actor's OWN home settlement as directly-lived context; anything about another settlement must still reach them as belief
- a settlement's food is NOT any mortal's to give: `give` stays blocked, and ownership remains a separate unanswered question
- `POPULATION_PER_PROSPERITY` is the one invented constant: roughly how many people a place keeps fed at its means. Without it a fed settlement climbs to plenty and stays there forever

Consequence Engine v1 constraints, settled with the user and to be preserved:

- **a consequence says what objectively changed or occurred, and never what it meant.** No trust, hostility, fear, respect, faith or reputation delta may EVER be written by this layer
- **`scripts/consequence_rules.gd` must not become a table of scripted emotional reactions.** If a consequence seems to need one, the reaction belongs to interpretation
- relationship, faith, reputation and theological reactions emerge through perception and interpretation, never from a consequence
- the route back into the simulation is Consequence -> Event -> Perception -> Knowledge -> Interpretation. Do not shortcut it by mutating subjective state directly
- mortal and divine acts enter the same consequence pipeline; a divine act records what happened ("rain fell on Westfield") and never why
- claims describe occurrences, never judgements: "%s refused %s's request" is allowed, "%s abandoned %s" is not
- social occurrences are DIRECT: only the participants perceive them. There is no visibility model that would honestly say otherwise
- TELL and OBSERVE resolve to `no_effect` because execution already moved the knowledge; never add a second route to the same fact
- agreeing is not delivering: an accepted request changes no settlement state, and creates no new intent in the same tick
- consequences are perceived the same year and answered the next; the tick order already guarantees this, and no same-year Intent -> Action -> Consequence recursion may be introduced
- state changes record `subject_id`, `field`, `before` and `after`, never a bare delta
- the divine layer still moves faith, followers and reputation directly inside `resolve_action`. That migration is deliberately deferred and needs its own pass
- `MAX_KNOWLEDGE_PER_ENTITY` bounds what a mortal carries, since social occurrences accumulate one belief per interaction. Forgetting drops retracted claims first, then stale low-confidence ones, and never anything learned this year
- the bounded ripple law holds: no automatic cascade from a refusal to hostility to rebellion. Each step needs a real system and a real condition

## Design rules

- Build systems first; avoid feature work that is only surface presentation.
- Do not redesign the UI unless the user specifically requests it or approves a necessary design change.
- Knowledge should change intents; it should not grant direct stat buffs.
- Preserve stable entity and record IDs.
- Prefer data-driven rules over scattered hard-coded behavior.
- Use deterministic or seeded randomness so behavior can be reproduced and tested.
- Keep simulation work bounded; avoid unbounded propagation, growth, or per-turn cost.
- Extend the existing architecture instead of rewriting it unnecessarily.
- Do not remove, bypass, dilute, or weaken tests to make a change pass.
- Preserve explainability: future intents and actions should record why they happened, including the relevant inputs or causes.
- Preserve cause and effect across systems so simulation outcomes can be inspected and understood.

## Interface rules

The interface is presentation. It reads simulation state and never owns it.

- **Two audiences, never merged.** The player-facing interface shows what a
  mortal believes and stays inside their perspective. Developer Mode shows exact
  values, raw ids, and objective truth. A field that would tell the player their
  character is wrong belongs only in Developer Mode.
- **Meaning first, numbers underneath.** Player-facing values go through
  `scripts/presentation_rules.gd`. Exact numbers stay where they aid a decision:
  Divine Power, Population, Followers, Year. Developer Mode never routes through
  the presentation layer.
- **Presentation is one-way.** Number -> label. A label must never be read back
  into simulation logic.
- **Interface state stays in the interface.** Selected location, selected person,
  and Developer Mode live in `Main.gd`. `WorldState` must never learn what the
  player is looking at.
- **Developer Mode is read-only.** It has no cheats and writes nothing. Adding
  simulation controls is a separate approved task.
- **Layout budget.** The window is 1280x720, so `Margin/MainColumn` must fit
  within roughly 1244 x 688. Measure `get_combined_minimum_size()` after layout
  changes; content-driven minimums (button text especially) often exceed what the
  scene file declares.

## Running and verifying

Godot is not on `PATH`:

```
GODOT=/Users/jamienfam/Downloads/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path . --script tests/<suite>.gd     # run a suite
"$GODOT" --headless --path . --quit-after 240              # boot the main scene
"$GODOT" --headless --path . --import                      # refresh the class cache
```

- Run `--import` after adding a script with a new `class_name`, or the class will
  not resolve in tests. It also generates the `.gd.uid` files, which are
  committed alongside their scripts.
- **A failed `assert()` does not stop a suite.** It aborts only the enclosing
  function; `_init` or `_process` continues and the final `PASSED` line still
  prints. New suites must count completed tests and `quit(1)` on a shortfall, as
  the newer suites do. `smoke_test` and `knowledge_test` predate
  this and still lack the guard.
- Scene-level behaviour is tested by instantiating `Main.tscn` inside a
  `SceneTree` script and driving it across frames. See `person_view_test.gd`.
- Headless has no framebuffer, so rendering cannot be verified. Geometry, hit
  testing, fonts and layout minimums can be. Say plainly what was not visually
  checked rather than implying the interface was seen.

## Workflow for every task

1. Inspect the existing code, relevant tests, and repository state before changing anything.
2. Summarize what already exists and how the requested work fits the current architecture.
3. If any design choice is required, stop and ask the user before implementation. Do not silently choose game behavior, scope, rules, outcomes, or direction.
4. Implement the smallest clean change that fulfills the explicit request and preserves existing behavior.
5. Add or update tests for the change without weakening existing coverage.
6. Run the affected tests and relevant regression suites.
7. Boot the main scene when appropriate to verify that the project still starts and behaves correctly.
8. Report:
   - files changed
   - behavior added or changed
   - tests added or updated
   - verification performed and results
   - deferred items, open questions, or known limitations
9. After a meaningful or major implementation has been completed and verified, ask whether the user wants the changes committed and pushed. Do not commit or push until the user explicitly approves.

