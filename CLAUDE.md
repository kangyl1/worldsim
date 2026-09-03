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
6. Broad Intent Model v1 is built. Do not extend it into Actions, Events, or Consequences until the user explicitly asks.
7. The player-facing interface shows a mortal's perspective; Developer Mode shows the machine. Never merge the two. See "Interface rules".

## Project reference

- Repository: `kangyl1/worldsim`
- Current important commit: `f8aaf05c27c3e5c9047625cc6309fcae1217e55f` — `Add Broad Intent Model v1`
- Design revision commit: `9b1ad6ed3102906b35b4adbf590a68d8dbce0568` — `Record the simulation foundation revision in the GDD`
- Decision engine commit: `dcf38771bf1983e2ccbfa36eeda2aed983f93da4` — `Add Decision Engine v1`, superseded in vocabulary by Broad Intent v1
- Original foundation commit: `7b453a8655a6c4a8cea05a0ed3e0ffa2239cf515` — `Add Worldsim social and knowledge foundations`
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
- knowledge generation from existing events, outcome-aware and refreshing stable ids
- a world map interface with clickable settlements and crisis markers
- world -> settlement -> person navigation in one reusable panel
- in-game Developer Mode (DEV button, F1 secondary) exposing raw simulation values, read-only
- a centralised presentation layer turning numbers into qualitative labels
- deterministic tests across eight suites
- a 72-turn regression suite

Current core source files:

| File | Role |
|---|---|
| `scripts/world_state.gd` | stored truth: world values, entities, relationships, knowledge, intents, locations |
| `scripts/world_sim.gd` | simulation behaviour: actions, yearly ticks, event knowledge generation |
| `scripts/knowledge_rules.gd` | rumor transfer scoring and trait effects on information |
| `scripts/interpretation_system.gd` | how mortals interpret divine actions |
| `scripts/intent_rules.gd` | Broad Intent Model v1 scoring and explainability records |
| `scripts/world_map.gd` | map presentation and click hit-testing; reads nothing from the simulation |
| `scripts/presentation_rules.gd` | number -> label bands for the player-facing interface |
| `Main.gd` / `Main.tscn` | interface and player interaction only |

Test suites, all deterministic:

| Suite | Covers |
|---|---|
| `tests/smoke_test.gd` | boot, traits, relationships, 72-turn regression |
| `tests/knowledge_test.gd` | direct knowledge, rumors, traits, falsehood, aging |
| `tests/intent_test.gd` | Broad Intent v1 vocabulary, gating law, direction, intentions-only |
| `tests/event_knowledge_test.gd` | events teaching entities, refresh-not-duplicate, reaching intents |
| `tests/map_model_test.gd` | location model, map hit-testing, simulation boundary |
| `tests/person_view_test.gd` | person navigation and the mortal-perspective filter |
| `tests/developer_mode_test.gd` | Developer Mode toggle, raw exposure, read-only guarantee |
| `tests/presentation_test.gd` | qualitative band mappings |

Do not assume this summary is exhaustive or newer than the code. Inspect the repository first, and use GitHub as the source of truth if anything conflicts.

## Planned system order

`Traits -> Relationships -> Knowledge/Rumors -> Broad Intents -> Actions/Events -> Consequences -> feedback into world state/relationships/knowledge`

Broad Intent Model v1 is complete: it produces recorded intentions only and executes nothing.

`GDD.md` Part II (sections 29-43) revises this. Mortals should pass through a
wider chain: world state -> pressures -> perception -> belief -> interpretation
-> goal -> **broad intent** -> action selection -> consequence -> memory ->
history. Read Part II before designing anything in this area.

The next system is **Mortal Action Selection**, and it must not begin until the
user explicitly asks.

**Goal is a conceptual layer only.** GDD Part II lists Goal between
interpretation and intent. v1 deliberately does not implement it: a goal field
would be derived one-to-one from the intent type and would duplicate what
`knowledge_used` already records. Build it only if a later system needs one
goal to produce several different intents.

Actions/Events execution **MUST NOT be implemented until the user explicitly asks**.

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

