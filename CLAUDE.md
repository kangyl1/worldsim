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
6. Minimal Settlement State v1, Selective Perception v1, Broad Intent v1, Action Selection v1, Action Execution v1, Consequence Engine v1, **Interpretation v1** and **Divine Actions in the shared causal pipeline v1** are built. Mortals notice different things, want things, try things, attempts have results, results objectively change the world, and mortals now decide what those results MEANT — which changes what they want later. **Exactly ONE divine power, Send Rain, has been migrated onto that same road**, and the road itself is now generic: `scripts/divine_action_rules.gd` is the single surface that registers how any power enters the world. Bless Harvest and Divine Voice still get one collective meaning from the populace-level `DivineReceptionSystem`. **Historical Selection + Chronicle v1** is also built: the simulation now decides which occurrences mattered enough to become history, and links them causally. **Belief Formation v1** is built on top of that: mortals accumulate durable, revisable, per-mortal beliefs from their own repeated interpretations, and the first divine belief can now bootstrap organically. **Population & Locality Coverage Foundation v1** made the rules generic around the seeded fixtures: no rules file names a settlement or a mortal, so generated places and people can take part by existing in state. **Broader Interpretation Coverage v1** widened what mortals can conclude: the three settlement-condition topics the event cycle produces every year are now interpreted, per observer, by where they live and who they are. **Situational Choices & Theatrical Feedback v1** made that depth visible: a presentation-only layer decides what the player is told each year and how it is worded, reading records and writing nothing. Migrating any further power, designing what its occurrence could MEAN, religion in any form, world generation itself, and the later history systems (myth, decay, competing accounts) must not be built until the user explicitly asks.
7. The player-facing interface shows a mortal's perspective; Developer Mode shows the machine. Never merge the two. See "Interface rules".

## Project reference

- Repository: `kangyl1/worldsim`
- Current important commit: `PENDING_FEEDBACK_COMMIT` — `Add Situational Choices and Theatrical Feedback v1`, which made the simulation visible in normal play

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
- `00205742da26112ba9b36f9e534465f89b111246` — `Add Interpretation v1` (what one mortal decided it meant, and how that changes what they want next)
- `0f6cd1aa86b33ec18513e4c86731e201123dba45` — `Add Divine Actions in the shared causal pipeline v1` (the god acts, and mortals — not the act — decide what it was)
- `a8037fc44678056d6b7f8c2e4b670fa9297990cc` — `Add Generic Divine Action Pipeline Foundation` (one road, registered in one place, that any power can walk)
- `f382ad8ae2a58ff5f8b3fd196f9c86cf89ac25a8` — `Add Historical Selection and Chronicle v1` (of everything that happened, what shaped the world — and what caused what)
- `c7f2571306313e4ce781d2fe09cc037d73f3b840` — `Add Belief Formation v1` (what one mortal came to accept, from their own repeated conclusions)
- `0529b3543f1aac1e98ba353ef7f8334076af23b6` — `Add Population and Locality Coverage Foundation v1` (the rules stopped knowing which settlements and people happen to exist)
- `da5abee821793741e9b9d636bb2102e8e5dd71bd` — `Add Broader Interpretation Coverage v1` (the world's own conditions became things a mortal can have an opinion about)
- `PENDING_FEEDBACK_COMMIT` — `Add Situational Choices and Theatrical Feedback v1` (the player can finally see what the simulation had been doing all along)

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
- populace-level reception of divine actions, feeding beliefs and reputation (`DivineReceptionSystem`)
- Broad Intent Model v1: ten wants, deterministic argmax, full explainability records
- Mortal Action Selection v1: seven parameterised verbs, capability-gated, selection only
- Mortal Action Execution v1: success/failure/blocked, two-phase ticks, immediate results only
- Selective Perception v1: events offer claims, only eligible mortals notice, no global teaching
- Minimal Settlement State v1: settlements own food, stability, prosperity and population; the kingdom view derives from them
- Consequence Engine v1: objective occurrence and state change only, routed back through events and perception
- Interpretation v1: what one mortal decided a social occurrence meant, per observer, feeding a small directed relationship change and therefore later intents
- Divine Actions in the shared causal pipeline v1: Send Rain records what the god DID, changes the world objectively, and lets each mortal reach their own conclusion — including that it was only weather
- Generic Divine Action Pipeline Foundation: one registration surface decides how any divine power enters the world, so migrating the next one is a flag and an effect rather than new plumbing
- Historical Selection + Chronicle v1: deterministic importance scoring over records the world already wrote, keeping a small fraction as objective history with causal links between entries
- Belief Formation v1: durable per-mortal propositions accumulated from a mortal's own interpretations, revisable by contradiction, biasing later interpretation and intent without forcing either
- Population & Locality Coverage Foundation v1: a small locality API, no rules file naming a settlement or a mortal, and empty locations represented honestly rather than filled in
- Broader Interpretation Coverage v1: the yearly settlement conditions are interpreted per observer by locality, traits, confidence and belief, with a coverage diagnostic naming the topics nobody has designed meanings for
- Situational Choices & Theatrical Feedback v1: deterministic templates turn existing records into at most three player-facing developments a year, in three voices, with every line grounded in state the simulation actually holds
- knowledge generation from existing events, outcome-aware and refreshing stable ids
- a world map interface with clickable settlements and crisis markers
- world -> settlement -> person navigation in one reusable panel
- in-game Developer Mode (DEV button, F1 secondary) exposing raw simulation values, read-only
- a centralised presentation layer turning numbers into qualitative labels
- deterministic tests across twenty-one suites
- a 72-turn regression suite

Current core source files:

| File | Role |
|---|---|
| `scripts/world_state.gd` | stored truth: settlement conditions, entities, relationships, knowledge, intents, actions |
| `scripts/world_sim.gd` | simulation behaviour: actions, yearly ticks, event knowledge generation, divine action records |
| `scripts/knowledge_rules.gd` | rumor transfer scoring and trait effects on information |
| `scripts/divine_action_rules.gd` | THE registration surface: which road each divine power takes, and what anyone present could see |
| `scripts/divine_reception_system.gd` | how the POPULACE receives a divine act: one collective meaning, belief pressure, reputation |
| `scripts/interpretation_rules.gd` | Interpretation v1: what ONE mortal decided a social occurrence meant |
| `scripts/intent_rules.gd` | Broad Intent Model v1 scoring and explainability records |
| `scripts/action_rules.gd` | Mortal Action Selection v1: intent -> viable attempt, never executed |
| `scripts/execution_rules.gd` | Mortal Action Execution v1: attempt -> immediate result, no consequences |
| `scripts/perception_rules.gd` | Selective Perception v1: who could notice an event, and how clearly |
| `scripts/consequence_rules.gd` | Consequence Engine v1: what objectively happened, never what it meant |
| `scripts/chronicle_rules.gd` | Chronicle v1: which occurrences mattered enough to become history, and why |
| `scripts/belief_rules.gd` | Belief Formation v1: what one mortal came to accept, and on what evidence |
| `scripts/feedback_rules.gd` | presentation only: what the player is told each year, in which voice, and why |
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
| `tests/interpretation_test.gd` | Interpretation v1: divergence, bounded effects, and everything the layer refuses to do |
| `tests/divine_action_test.gd` | Send Rain end to end, and the twelve things a divine act must no longer do |
| `tests/divine_pipeline_test.gd` | the road is generic: one routing surface, and an unforeseen power can walk it |
| `tests/chronicle_test.gd` | historical selection, causal links, and the Autonomous Story Test (GDD 42) |
| `tests/belief_test.gd` | the divine bootstrap, gradual formation, contradiction, and everything belief must not do |
| `tests/locality_test.gd` | invented settlements and mortals take part; empty places stay empty and stay valid |
| `tests/interpretation_coverage_test.gd` | the yearly conditions mean something, differently to different people, without inventing motive |
| `tests/feedback_test.gd` | the player is told the truth, theatrically, boundedly, and presentation changes nothing |

Do not assume this summary is exhaustive or newer than the code. Inspect the repository first, and use GitHub as the source of truth if anything conflicts.

## Planned system order

`Settlement state -> Events -> Perception -> Knowledge/Rumors -> Broad Intents -> Action Selection -> Action Execution -> Consequences -> feedback into settlement state/relationships/knowledge`

Everything in that chain is built, and so is the layer after it: mortals now
decide what an occurrence MEANT, and that decision changes what they want in
later years. Roadmap item 12 is PARTLY done — Send Rain travels the mortal road,
three other powers do not — but the road is now generic, so the remaining
migrations are design work rather than plumbing. Roadmap item 13 now has its
objective half: history is SELECTED and CAUSALLY LINKED. What remains unbuilt is
everything after that — myth, competing accounts, cultural memory and gradual
forgetting.

**The Autonomous Story Test (GDD section 42) now passes**, on all ten of its
conditions, asserted by `tests/chronicle_test.gd`.

`GDD.md` Part II (sections 29-43) revises this. Mortals should pass through a
wider chain: world state -> pressures -> perception -> belief -> interpretation
-> goal -> **broad intent** -> action selection -> consequence -> memory ->
history. Read Part II before designing anything in this area.

`GDD.md` **Part III (sections 44-72) is long-term direction and is NOT the
roadmap.** It records where the simulation is eventually going — meaning,
belief, history, divine influence, and the limits on ecological and planetary
systems — so that near-term decisions do not foreclose it. Nothing in Part III
is scheduled or scoped, and none of it may be implemented without an explicit
request. Read it before designing, never as a work queue. If a Part III idea
starts to feel urgent, that is a signal to finish the layer in progress.

Part III records three deliberate tensions with what is built, rather than
silently resolving them: where interpretation sits in the chain (section 46
against section 30), whether Divine Power or consequence is the primary
constraint on intervention (section 56 against section 8), and how directly
Divine Voice creates a prophet (section 50 against section 9).

The FIRST is now half-settled by construction, and only half. Interpretation v1
implements section 30's placement — interpretation ON BELIEF, after a fact is
held. Section 46's other moment, interpretation ON PERCEPTION (you cannot store
"the god answered us" without having already interpreted the rain), remains
unbuilt, and the GDD is deliberately not edited. Building it is the divine
interpretation pass, not a correction to this one. The other two tensions are
untouched.

**Interpretation v1 is built** for social occurrences AND for one divine one.
A mortal decides what an occurrence meant, and that decision moves one
relationship axis (social) or weights a later want (rain), which intents already
read. What has NOT been built: per-mortal interpretation of Bless Harvest,
Divine Voice or Do Nothing, and History generation. Neither may begin until the
user explicitly asks.

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

**Not a defect — a represented world state.** Only two of the three settlements
host events a mortal ever notices, because the Frontier has no notable resident.
An event there is real, is recorded, and is witnessed by nobody. Locality v1
made that visible rather than mysterious: the Developer Mode LOCALITY section
names dead zones, and nothing redirects events away from them or invents people
to fill them. It still limits how often the divine bootstrap can occur, which is
a world-SIZE question for world generation rather than a rules problem.

**Goal is a conceptual layer only.** GDD Part II lists Goal between
interpretation and intent. v1 deliberately does not implement it: a goal field
would be derived one-to-one from the intent type and would duplicate what
`knowledge_used` already records. Build it only if a later system needs one
goal to produce several different intents.

Religion in every form, belief transmission between mortals, myth, cultural memory, competing historical accounts, historical forgetting, and the migration of any FURTHER divine power onto the shared pipeline, **MUST NOT be implemented until the user explicitly asks**.

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
- `apply()` keeps the occurrence's own `claim` on the record after handing the fact to perception, so a consequence can describe itself later. `pending_fact` is still erased, so this is not a second route to the fact — nobody can LEARN it from the record
- the divine layer still moves faith, followers and reputation directly inside `resolve_action` for every UNMIGRATED power. Send Rain no longer does; see the divine pipeline constraints below
- `MAX_KNOWLEDGE_PER_ENTITY` bounds what a mortal carries, since social occurrences accumulate one belief per interaction. Forgetting drops retracted claims first, then stale low-confidence ones, and never anything learned this year
- the bounded ripple law holds: no automatic cascade from a refusal to hostility to rebellion. Each step needs a real system and a real condition

Interpretation v1 constraints, settled with the user and to be preserved:

- **a consequence says what happened; an interpretation says what one mortal took it to mean.** The relationship change belongs to the SECOND. `consequence_rules.gd` must never grow a `request_refused -> trust -10` table, and a test greps its executable lines for the axis names
- interpretation reads the OBSERVER'S OWN knowledge record and their own state, and nothing else. It never touches `objective_truth_state`, never consults the consequence archive, and a test asserts the rules cannot even name them
- a false or distorted belief produces a sincere interpretation of something that did not happen. The engine knowing better must never quietly correct the mortal, and a test proves a false belief reads identically to a true one
- **the fact is never overwritten with its meaning.** They are two records in two stores: knowledge keeps the claim exactly as learned, `interpretation_archive` keeps what was made of it
- v1 covers four social occurrences, all of which already existed as consequence topics: `request_accepted`, `request_refused`, `support_given`, `opposition_given`. No new occurrence, intent, or action verb was invented, and a test asserts the vocabularies are unchanged
- selection is deterministic argmax over candidates keyed by **topic x role** (`actor` / `target` / `bystander`), role taken from the claim's own `participants`. Ties break by declaration order, so the plainer reading beats the dramatic one. No randomness — a test greps for `randi`, `randf` and `RandomNumberGenerator`
- scoring factors may only read what the mortal legitimately has: their trust and hostility toward the other party, their traits, their confidence in the report, and whether they were present. Every point of the score names its source in `factors`, and `considered` keeps the rejected alternatives
- **effects are bounded**: ONE axis, at most +/-3, clamped at apply time so no future table entry can exceed it, and one conclusion per mortal per occurrence. `has_interpretation()` is what stops a still-held belief being re-interpreted every year and grinding a relationship down forever
- an interpretation moves only the OBSERVER'S OWN directed edge. Mara concluding something about the King says nothing about what he thinks of her; he was there too and reached his own conclusion
- a bystander notes the occurrence and changes no relationship. Third-party politics is a later system, not a side effect of this one
- a missing relationship edge means no relationship, not a neutral one, and yields `effect_reason: "no_relationship_edge"` — the same rule `ask` applies. An overheard quarrel must not invent a tie between strangers
- low confidence in the underlying report reaches `unclear_what_happened` and moves nothing, which is how a distorted rumor stops short of changing a relationship
- **interpretation runs LAST in the yearly tick**, after perception. A conclusion drawn this year changes what someone wants NEXT year and must never reach a want already formed. The order is asserted structurally AND behaviourally, because a behavioural test alone did not catch the tick being reordered
- interpretations are stored as records only. They do not enter the knowledge system, so a MEANING cannot yet spread by rumor — only the fact can. Reconsider if a later system needs meanings to travel
- anyone who newly holds a social fact interprets it, however it arrived. A third party who hears by rumor years later interprets then, at their own lower confidence
- `scripts/divine_reception_system.gd` (formerly `interpretation_system.gd`) is NOT this layer. It is populace-level, divine-only, and still writes reputation and world effects straight from a divine action, which this architecture forbids. Migrating it is roadmap item 12 and needs its own pass. The state fields `last_interpretation`, `last_interpretation_id` and `interpretation_history` still belong to it, not to the mortal layer — a naming overlap left deliberately, because renaming them reaches into the player-facing panel and `smoke_test`

**Known issue, not yet addressed.** A claim can read "The King refused Mara's
request concerning The King" when the intent's subject happens to be the target.
The wording comes from intent and action selection, not from interpretation, and
was noticed while tracing a causal chain.

**Observed, not a defect.** Relationship drift over a long run is dominated by
the trait effects in `tick_relationships()`, not by interpretation. Control run
across 24 autonomous years: Mara's trust toward the King reaches 93 with
interpretation disabled and 87 with it enabled, because her readings of refusals
pull against the drift. Interpretation is a bounded modifier on top of an
existing trend.

Divine Actions in the shared causal pipeline v1 constraints, settled with the
user and to be preserved:

- **God controls what happens. Mortals decide what it means.** A divine act
  records WHAT was done; every question about what it MEANT belongs to a mortal,
  later, and may be answered differently by two people or not at all
- the migration surface is exactly one file: `scripts/divine_action_rules.gd`.
  Flipping a power's `pipeline` there is a design decision and needs its own
  approved pass
- **both roads must never run for one act.** `resolve_action` branches: a
  migrated power returns with empty `interpretation`, `belief_tag` and
  `reputation_hint` and never reaches `divine_reception_system`; an unmigrated
  one is untouched. A test asserts each side of the branch
- the divine action record (`id`, `year`, `action_type`, `target_id`,
  `subject_id`, `parameters`, `power_cost`, `result`, `consequence_id`,
  `pipeline`) is written for BOTH pipelines, because it is about the ACT. It is
  the one place the engine's knowledge of the player's aim is allowed to live,
  and NOTHING downstream may read it — perception, knowledge, interpretation and
  intent all work from the mortal's own records
- Send Rain no longer writes `faith` or `followers`. It changes food and
  stability, and stops. **Limitation:** faith and reputation remain wired to
  `DivineReceptionSystem`, so a migrated power currently feeds neither. The
  behavioural feedback runs instead through `INTENT_INTERPRETATION_RULES` in
  `intent_rules.gd`: a mortal's OWN `rain_divine_help` reading weights `learn`,
  counted once per distinct interpretation type and recorded in
  `interpretation_factors`. Redesigning faith to accept per-mortal belief is a
  later pass, not a silent one
- **no relationship effect for a world occurrence.** Rain has no mortal
  counterpart to move an edge toward, and inventing one (a relationship *with the
  god*) would be a new system. The empty `effect` in `WORLD_CANDIDATES` is
  deliberate
- the History Log may carry the objective claim ("Rain fell on Aster") and
  nothing else. The generated chronicle of roadmap item 13 is a different system
  and is still unbuilt
- rain readings are keyed by **topic x stance**, where stance is `witness` (the
  occurrence happened where you live) or `distant`. Candidates are
  `rain_natural_weather`, `rain_divine_help`, `rain_divine_favour`, plus the
  existing `unclear_what_happened`
- **the naturalistic reading is not a wrong answer the simulation tolerates.**
  For a mortal with no history of divine events it wins on score, 50 to 48. The
  god must be able to act and go unnoticed as a cause, and mortals must be able
  to be wrong about God's actual involvement in either direction
- what tips someone toward a divine reading is the CIRCUMSTANCE (rain arriving
  while their own wells were dry), their traits, their own prior divine reading,
  and what they have come to believe. No priest role, no theology stat, no
  religious education, no hidden faith archetype was invented.
  **Changed by Belief Formation v1:** `home_was_helped` was removed from the
  divine candidate, because rain falling where you live is not evidence that
  anything answered you — rain falling where you live WHILE YOU NEEDED IT is,
  and that is `home_was_in_crisis` (+22). `prior_divine_reading` dropped from 20
  to 8 for the reason in the belief constraints below
- `intervention_counts` and `action_counts` still tally a migrated act. They
  count the ACT, only Developer Mode reads them, and no belief pressure follows —
  which is asserted rather than assumed
- Developer Mode keeps **six** separate sections: DIVINE ACTIONS, CONSEQUENCES,
  PERCEPTIONS, KNOWLEDGE, INTERPRETATIONS and the rest. The divine section points
  at the other four rather than restating them, and names the `occurrence_topic`
  that links the act to what mortals were offered. Merging them would hide the
  exact gap this layer exists to show
- divine acts land on `current_event_location_id`, so a test that wants the act
  observed must aim it at a settlement somebody lives in. Aimed at the Frontier,
  nobody perceives it and nobody interprets it — that is the observability rules
  working, not a defect

Generic Divine Action Pipeline Foundation constraints, settled with the user and
to be preserved:

- **`scripts/divine_action_rules.gd` is the ONE place that says how a divine
  power enters the world.** No other file may branch on an action id to decide
  which road it takes, and a test greps `consequence_rules.gd`,
  `perception_rules.gd` and `interpretation_rules.gd` for every power's name
- a registry entry holds a `pipeline` and, if the act leaves anything to notice,
  an `occurrence` (`topic`, `claim`, `observability`, `confidence`). There is
  deliberately NO field for faith, belief, reputation or meaning: an entry that
  wanted one would be a power deciding its own reception again
- an UNREGISTERED power answers `legacy`. Legacy is the behaviour that already
  existed, and an unknown power must never be silently granted the new road
- **an act may register no occurrence at all.** `do_nothing` does: it changes
  nothing anyone can point at and offers nobody anything. That is a real option,
  not a missing template
- the divine action record and the mortal-facing fact are two records with two
  wordings. The record may say the god caused rain in Aster; the fact says rain
  fell on Aster. **Mortals must not learn the actor was God unless the
  occurrence itself makes that objectively observable**
- `consequence_rules.plan_divine()` is handed the occurrence rather than looking
  the power up. The consequence layer no longer knows any divine power exists,
  and must not learn again
- interpretation derives its world topics from the registry instead of keeping a
  second list. **A registered topic with no candidates designed yet is held as a
  fact and left uninterpreted** — reaching for `unclear_what_happened` there
  would be inventing a conclusion to fill a gap in the DESIGN rather than
  because a mortal was actually unsure. `harvest_yield` and `mortal_speech` are
  observable and uninterpreted today, and that is correct
- **two tables describe a power, on purpose.** `world_sim.ACTIONS` holds title,
  cost and hint — how the power is offered and priced, an economy and interface
  question. The registry holds pipeline and occurrence — how the act enters the
  world. Neither belongs in the other. Consequence: MIGRATING a power touches
  the registry alone; adding a BRAND NEW one touches both. If that split ever
  stops earning its keep, merging them is a design decision, not a tidy-up
- `DivineActionRules.register()` and `WorldSimulation.offer_action()` exist so a
  test can send a power the simulation has never heard of down the road and
  prove no branch names it. **They are test seams, not a plugin system**, and
  must not grow into one — a real power belongs in the declared table
- migrating a power should cost TWO files: flip `pipeline` in the registry, and
  strip the faith/follower writes from that power's own resolver in
  `world_sim.gd`. Interpretation candidates are optional and come later. If a
  migration ever needs edits across five unrelated files again, the abstraction
  has come undone

Historical Selection + Chronicle v1 constraints, settled with the user and to be
preserved:

- **history answers a different question from every other layer.** The rest of
  the simulation answers what happened; the chronicle answers which of it
  SHAPED THE WORLD. Its whole value is in what it leaves out, and a chronicle
  that recorded everything would be the event log with extra steps
- the test is GDD section 36, and it is about the future rather than about
  drama: a memory earns its place by being capable of affecting later behaviour,
  belief, relationships or history. Reference run: **27 entries from 40 years**,
  against 254 records the world produced
- **history is a RECORD layer and steers nothing.** Nothing outside
  `chronicle_rules.gd` may read `state.chronicle`, and a test greps every other
  rules file for it. Two identical runs produce identical intents whether or not
  a chronicle exists
- it runs LAST in the yearly tick, after interpretation, so everything it reads
  has settled and nothing it writes can reach a decision already made
- **it consumes existing records and invents no occurrence.** Four sources:
  settlement conditions, divine actions, execution consequences, interpretations.
  Conditions are read from the settlement bands directly, because the yearly
  cycle and world drift move them without ever writing a consequence
- **the source record is never touched.** History points back with
  `source_record_type` + `source_record_id` and never edits or copies what it
  points at; a test compares source records before and after chronicling
- scoring is deterministic, threshold **50**, and every point names its own
  source in `factors`. A test asserts each record's factors sum exactly to its
  importance. Developer Mode must be able to answer BOTH "why is this history"
  and "why is that not" — rejections are kept for the current year only, because
  keeping them forever rebuilds the log this layer exists to avoid
- **history states occurrences, never verdicts.** "The King refused Mara's
  request" is history; "the cruel King betrayed Westfield" is what somebody
  decided, and lives in `interpretation_archive` where it can be disagreed with.
  A test greps summaries for judgement words and asserts no interpretation's
  `meaning` text was ever copied into a summary
- **a divine act is not history for being divine.** It needs objective impact:
  `divine_impact` requires the consequence to have actually changed state, and an
  act that changed nothing scores ZERO and is refused by name. Reference run: 7
  of 40 acts recorded
- **an interpretation enters only through its EFFECT**, and the record says what
  the reading DID rather than that it was right. Relationship movement qualifies
  only by crossing an existing `PresentationRules` band — no new threshold was
  invented, and bare relationship ticks are never a history source
- causal links are **id pairs, both directions, one strongest parent**. Not every
  record has a parent: 15 of 27 in the reference run are roots, and forcing a
  parent onto them would invent causality
- **`during_open_crisis` is both a scoring factor and the causal link.** What
  makes an occurrence important and what makes it part of a story are the same
  fact: a ruler refusing aid during a famine is history, and the same refusal in
  a fed and quiet year is two people disagreeing
- **the chronicle is uncapped, immutable and permanent in v1**, unlike every
  other archive. The others are working memory that forgets cheaply; this one
  would leave dangling causal links if it dropped its oldest entries. The single
  permitted mutation is `led_to` growing as later records name an earlier one.
  GDD 96 wants fading to be gradual and legible one day — a record carrying its
  own year, source and links can be faded, contested or half-remembered later
  without any of this being rewritten
- **Chronicle v1 is Developer Mode only.** The existing prose History Log panel
  is untouched. Whether the chronicle deserves the player-facing panel is a
  presentation decision to make after seeing real output, not now

Belief Formation v1 constraints, settled with the user and to be preserved:

- **three layers, never merged.** Knowledge is what a mortal thinks HAPPENED, an
  interpretation is what they made of ONE occurrence, and a belief is what they
  have come to accept about the WORLD. The belief is the first thing here not
  tied to a single event, and the only one that outlives its evidence
- **beliefs are per-mortal and never spread.** No realm belief, no shared creed,
  no membership, no conversion. Facts travel and the receiver reaches their own
  conclusion; convictions do not travel at all, and a test asserts the rules
  cannot even name `share`, `spread`, `transmit`, `convert` or `teach`
- the proposition vocabulary is FOUR, and every one is something the existing
  interpretation types can already produce: `divine_intervention_exists`,
  `divine_help_follows_need`, `is_supportive` and `is_unreliable`. The last two
  are subject-scoped. Two world-level and two person-level on purpose, so the
  layer is not shaped around Send Rain. **No speculative ontology** — a
  proposition with no interpretation type feeding it does not belong
- interpretation -> proposition mappings live in ONE table each (`SUPPORTS`,
  `CONTRADICTS`) in `belief_rules.gd`. A future interpretation type is one entry,
  not a check scattered through the simulation
- **absence of evidence is never contradiction.** `rain_natural_weather`
  contradicts the divine propositions because deciding the weather was weather is
  a real conclusion; a crisis that went unanswered contradicts nothing, because
  the mortal never interpreted anything. Building that in would be inference this
  layer has no business doing
- **belief formation reads interpretation records and NOTHING else.** Not the
  divine action archive, not `objective_truth_state`, not the consequence
  archive, not the realm's `faith`/`followers`/`beliefs`. A test greps the rules
  file for every one of those names. The engine knows the player caused the rain;
  no conviction may be founded on that
- formation is gradual and bounded: movement is `weight x reading confidence`,
  damped by how much room is left, capped at +/-20 per piece of evidence and
  clamped 0-100. Established at 45, below which a belief is recorded and
  influences nothing. Gradualness is protected by the weights AND the cap
  independently — a mutation test had to remove both to break it
- **beliefs bias, never force.** An established belief is an interpretation
  factor worth 12, and a believer must still be able to look at ordinary rain and
  call it ordinary. A test asserts exactly that
- **the theology lock-in this refuses.** `prior_divine_reading` and the belief
  factor are the SAME evidence in two forms, and at full strength they stacked
  into a lock where a believer read every later rain as divine. The fix was
  cutting `prior_divine_reading` to 8 and giving `rain_natural_weather` the
  factor `home_was_not_in_crisis` (+18): rain that arrived when nothing was wrong
  is unremarkable. Do not raise either without re-checking the lock-in test
- **the double-count rule.** Once a belief is established, the interpretation
  types supporting it stop contributing to intent scoring. Recent conclusion or
  settled conviction, never both for the same proposition — the belief outlasts
  the reading, which is the point of having it
- a belief weights a want that already has evidence behind it. **The gating law
  is untouched:** a belief may not conjure an intent from nothing, and one that
  seems to need to is a belief being asked to do action selection's job
- **beliefs are durable and stored apart from knowledge**, because knowledge is
  capped and pruned and the FACTS behind a belief will be forgotten. Somebody who
  concluded that something intervenes does not stop believing it because they can
  no longer recall which year it rained. No passive decay in v1
- **belief is not a Chronicle source.** Updates are frequent, history is not, and
  a test asserts the chronicle rules cannot name the belief store
- `state.mortal_beliefs` is named apart from the legacy realm `state.beliefs`
  string list, and `_developer_mortal_belief_lines()` apart from the legacy
  `_developer_belief_lines()`. Two different things called belief: one is a
  kingdom-wide doctrine string the old divine path appends to, the other is what
  individual people accept. They must never be joined
- tick order is `... perception -> interpretation -> BELIEF -> chronicle`. A
  belief formed this year reaches next year's wants and never one already chosen

Broader Interpretation Coverage v1 constraints, settled with the user and to be
preserved:

- coverage for another existing topic is **one entry in `WORLD_CANDIDATES`** and
  nothing else. `is_world_topic()` answers true for any topic with a candidate
  family OR any registered divine occurrence, so adding meanings needs no edit
  to the interpretation tick
- the three yearly condition topics — `food_shortage`, `danger_unrest`,
  `surplus` — are covered by **stance**, not by role: a shortage at home and a
  shortage somewhere else are different questions about the same fact, and
  neither reading is more correct
- **world conditions move no relationship, and cannot.** A settlement running
  short is not something one person did to another. The guarantee is STRUCTURAL
  rather than a matter of leaving the table empty: `other_id` is empty for an
  occurrence with no participants, so no effect is planned whatever a candidate
  declares. A mutation that gave a world reading a real effect changed nothing
- **a faint report supports a fainter conclusion.** Every world candidate carries
  `confidence_below UNCERTAIN_CONFIDENCE -> -30`, because without it a
  well-disposed mortal reached a confident reading from a rumour they barely
  credited, and the existing uncertainty candidate could not win
- **`episode` distinguishes one spell of a recurring condition from the next.**
  World facts carry a stable id per settlement and are refreshed while the
  condition holds, so one conclusion per knowledge id meant one conclusion per
  LIFETIME. A gap in the refreshes is a new spell; an unbroken run is one
  situation, and concluding about it once is still the point of the rule. Social
  occurrences already carry the year in their id and are untouched
- **no motive is invented.** `leader_failed_to_protect_us` was deliberately not
  built: it needs a model of who is responsible for a settlement, which does not
  exist. Neither was "unable to help" — nothing models capacity. If the world
  does not know why somebody acted, no reading may state a reason as fact
- `harvest_yield` and `mortal_speech` stay observable and uninterpreted. They
  belong to unmigrated divine powers, and designing what they MEAN is that
  power's migration pass
- `coverage_report()` answers which topics are in play, which have families, and
  which do not. Developer Mode prints `NO INTERPRETATION DESIGNED` per gap, so a
  content gap cannot be mistaken for the system choosing uncertainty. It is a
  plain report over current state — **not telemetry**, and nothing accumulates
- Chronicle moved from 71 to 89 entries across forty autonomous years, entirely
  through `changes_later_behaviour` on the new readings. **The threshold and both
  relevant factor weights are asserted unchanged** — more mental activity may
  reach history only through the rules as they already stood, never by lowering
  the bar
- tests must name the topic and settlement they mean. Selecting a reading by
  position was unambiguous when a mortal interpreted one thing per tick, and two
  existing tests had to be made more precise when that stopped being true

Situational Choices & Theatrical Feedback v1 constraints, settled with the user
and to be preserved:

- **`scripts/feedback_rules.gd` is presentation and nothing else.** It reads
  records the simulation already wrote and decides only WHAT to show and HOW to
  word it. It writes no state, and a test runs five full passes and asserts the
  world is byte-for-byte identical. A mutation that made it call `add_history()`
  is caught
- the governing rules are GDD Section 40 (**hide machinery, not drama**) and
  Section 97 (**a legend being written in real time**). Exact trust values,
  belief arithmetic, intent weights and interpretation scores stay in Developer
  Mode; what a mortal CONCLUDED, came to believe, or changed their mind about
  goes in front of the player
- **it is not a second decision engine.** Two identical worlds behave
  identically whether or not anybody asks what to show, and a test asserts the
  intent archives match
- **it is not a second history.** It may READ the Chronicle to judge
  significance and writes nothing back. Chronicle asks "was this historically
  important"; feedback asks "should the player notice this now", and the two are
  allowed to disagree
- **deterministic templates only.** No randomness, no generated prose, no LLM. A
  line the state does not support must not exist: a test asserts every character
  line maps to a reading the world can actually produce, every belief sentence
  to a real proposition, and every "notable" reading to a line it can say
- **exaggeration may amplify; it may never fabricate.** The load-bearing case is
  "%s no longer expects his help", which appears ONLY when that mortal holds
  `is_unreliable` about that person at established confidence. A test runs the
  identical refusal history with and without the belief
- **the feed is capped at three a year**, deduped one item per subject per
  category, and a quiet year is allowed to produce nothing. The bound is
  asserted against a LITERAL as well as the constant — checking only
  `<= MAX_DEVELOPMENTS` is self-referential, and a mutation raising the constant
  proved it
- relationship news requires crossing an existing `PresentationRules` band.
  A movement inside a band is noise; a test asserts 50 -> 52 stays silent, and a
  mutation surfacing every tick is caught
- belief news requires crossing `BeliefRules.ESTABLISHED_CONFIDENCE` in either
  direction. Drift within the band is not news
- **no score, delta or truth flag may reach the player.** Divine feedback is
  qualitative — a test rejects any digit in it — and a grep asserts the layer
  cannot even name `objective_truth_state`, `truth_state`, the divine action
  archive or the intent archive
- three voices, all presentation: CHARACTER (one mortal's own words, keyed by
  interpretation type so no mortal is hardcoded as believer or sceptic),
  CHRONICLER (short narration), WORLD (collective texture). **World Voice is
  declared and deliberately unused** — nothing models collective knowledge, and
  inventing crowd opinion would be the fabrication this layer forbids
- `label_for_action()` phrases a primitive without adding one. The seven verbs
  are unchanged, and a test asserts the presentation table names no verb the
  simulation lacks. Repetition wording comes from counting real executions in
  the archive — no arbitrary stages
- **identical parameters must produce identical wording.** Different words must
  mean a different world, or the variety is cosmetic
- the player-facing surface is the existing central text region. No new panels,
  no fake-phone work, and the prose History Log and Developer-Mode-only
  Chronicle are both untouched

**Known limitation.** The LEGACY feedback horizon of GDD Section 97 is not
built. Nothing models an event's later reputation — the Chronicle has
`caused_by`/`led_to` but no notion of what an event came to be remembered AS —
so "the rains of Year 22 are still remembered as…" has no state behind it and
was not faked.

**Known limitation.** World Voice has no data source, as above. Refusals are
also rare in autonomous runs, so the repeated-refusal escalation almost never
fires on its own and the tests construct it. And only about one year in thirty
is quiet, because the seeded world is in near-constant crisis — the contrast GDD
Section 37 wants is thinner than intended, which is a world-size question rather
than a feedback one.

Population & Locality Coverage Foundation v1 constraints, settled with the user
and to be preserved:

- **no rules file may name a settlement or a mortal.** A test greps the
  executable lines of all ten rules files, plus `world_sim.gd`, for the literal
  ids of the seeded fixtures. Seed data, tests and presentation are judged
  separately; anything that decides what the simulation DOES is not
- the seeded laboratory stays: Aster, Westfield, Frontier, the King and Mara are
  deterministic test content and are not to be deleted. The milestone made the
  rules generic AROUND them
- the locality API is six helpers on `world_state.gd`: `resident_count`,
  `has_residents`, `locations_with_residents`, `locations_without_residents`,
  `has_local_perception_coverage`, `locality_coverage`, beside the existing
  `residents_of` and `get_home_location`. **Do not grow this into a location ECS
  or a world-query framework** — if a few helpers remove the assumption, that is
  the whole job
- **"resident" means a NOTABLE entity**, one the simulation holds a record for.
  A settlement's `population` is a count of people it does not model
  individually, and the two are deliberately different questions. A place with
  four hundred people and no notable resident has nobody who can perceive, want,
  act or believe
- **every settlement does NOT need a notable mortal.** An empty location keeps
  its conditions and its place in the world; a local event there produces a
  divine record and a consequence, reaches nobody, and generates no knowledge
  and no interpretation. That is a legitimate world state, not a fault
- **nothing redirects events away from empty places, and nothing invents people
  to fill them.** No `ensure_resident`, `spawn_notable` or `generate_person`,
  and the event selector must never consult who lives where — a test asserts
  both, because either would be forcing a story the world did not produce
- `LOCATION_ORDER` is gone; `get_location_ids()` returns insertion order. This
  is not cosmetic: `settlement_with_lowest()` breaks ties by taking the first it
  meets, so ordering decides where events land. It must stay stable and
  deterministic
- `home_location_id` remains an ASSOCIATION and not a position. No travel, no
  coordinates, no current-position state, and a test greps for `current_location`,
  `travel_to`, `move_entity` and `distance_between`
- presentation may still key on a location's `kind`. `_location_is_holy()` now
  tests for `kind == "capital"` rather than the literal id `aster`, so a world
  assembled differently has a capital too — and one assembled with none simply
  has no holy site

**Known limitation for world generation.** `scripts/world_map.gd` holds
hand-authored anchors and a `DRAW_ORDER` for the three seeded settlements, so a
generated settlement would be invisible and unclickable on the map. This is the
one subsystem that cannot yet consume generated locations. Where settlements sit
on a hand-drawn coastline is a design question, not a refactor, and it was left
alone deliberately.

**What world generation will need to populate**, and nothing more from the
simulation layer: locations, settlement state, entities, `home_location_id`,
traits and relationships — all through the existing public calls
`add_location()`, `add_notable_entity()` and `set_relationship()`, which is
exactly what `locality_test.gd` does. Beyond that it needs a map placement
decision (above) and a choice of which settlement carries `kind: "capital"`.

**Known issue, not yet addressed.** The divine bootstrap needs a famine a
notable mortal actually lives through, and the autonomous world rarely produces
one where anybody lives — the Frontier starves and nobody is there. In a pure
autonomous run no divine belief forms. `belief_test.gd` manufactures the
CIRCUMSTANCE (a lived Westfield famine the god answers) and injects no belief and
no reading. This is the "only two of three settlements host events" issue showing
up again, and fixing it is a world-size question rather than a belief question.

**Observed, not a defect.** `BeliefRules.MAX_SINGLE_MOVE` is not currently
load-bearing: the evidence weights bind first. It is kept as a second, independent
guarantee that no single interpretation can create a conviction.

**Solved by Belief Formation v1.** The divine loop used to have no bootstrap:
`rain_divine_help` needed a PRIOR divine reading and nothing could produce the
first one. The circumstance is the evidence now — rain arriving while the
mortal's own wells were dry — so a first divine reading can arise from what they
actually lived through. See the Belief Formation constraints below, including
the limitation that still remains.

**Known issue, not yet addressed.** Chronicle summaries carry raw topic ids
(`support_given`) and inherit the "request concerning The King" wording problem
from action selection. Acceptable while the chronicle is Developer Mode only;
both would need addressing before it faces the player.

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

- **Poll for the process to exit; never guard a suite with a fixed `sleep`.**
  The guard is needed because a script that fails to parse hangs headless forever
  rather than failing, but a fixed sleep pays the worst case every time. All
  eighteen suites finish in about 22 seconds when polled, and took roughly 28
  minutes with a 95-second sleep apiece:

  ```
  "$GODOT" --headless --path . --script "tests/$1_test.gd" > out.txt 2>&1 &
  pid=$!; i=0
  while kill -0 $pid 2>/dev/null && [ $i -lt 120 ]; do sleep 1; i=$((i+1)); done
  kill $pid 2>/dev/null
  ```

  Report the elapsed seconds, so a genuine hang is visible as a suite that burned
  the whole bound.
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

