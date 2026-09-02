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
6. Do not implement the Decision Engine until the user explicitly asks for it.

## Project reference

- Repository: `kangyl1/worldsim`
- Current important commit: `7b453a8655a6c4a8cea05a0ed3e0ffa2239cf515` — `Add Worldsim social and knowledge foundations`
- Local project path: `/Users/jamienfam/Documents/ChatGPT/worldsim`
- Tested Godot version: `4.7.1`

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
- deterministic tests
- a 72-turn regression suite

Current core source and test files:

- `scripts/world_state.gd`
- `scripts/world_sim.gd`
- `scripts/knowledge_rules.gd`
- `tests/smoke_test.gd`
- `tests/knowledge_test.gd`

Do not assume this summary is exhaustive or newer than the code. Inspect the repository first, and use GitHub as the source of truth if anything conflicts.

## Planned system order

`Traits -> Relationships -> Knowledge/Rumors -> Decisions -> Actions/Events -> Consequences -> feedback into world state/relationships/knowledge`

Decision Engine v1 is the next planned system, but it **MUST NOT be implemented until the user explicitly asks**.

## Design rules

- Build systems first; avoid feature work that is only surface presentation.
- Do not redesign the UI unless the user specifically requests it or approves a necessary design change.
- Knowledge should change decisions; it should not grant direct stat buffs.
- Preserve stable entity and record IDs.
- Prefer data-driven rules over scattered hard-coded behavior.
- Use deterministic or seeded randomness so behavior can be reproduced and tested.
- Keep simulation work bounded; avoid unbounded propagation, growth, or per-turn cost.
- Extend the existing architecture instead of rewriting it unnecessarily.
- Do not remove, bypass, dilute, or weaken tests to make a change pass.
- Preserve explainability: future decisions should record why they happened, including the relevant inputs or causes.
- Preserve cause and effect across systems so simulation outcomes can be inspected and understood.

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

