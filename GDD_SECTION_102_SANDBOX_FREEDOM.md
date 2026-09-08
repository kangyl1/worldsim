# WORLDSIM — GDD SECTION 102
## Sandbox Freedom and Player-Directed Play

**Status:** Approved future design direction.

This document is an addendum to `GDD.md` and should be treated as **Section 102** of the Worldsim GDD. It extends Sections 24, 38, 40, 41, 43, 98, 99, 100 and 101. It does **not** alter the implementation order in Section 41.

---

## 102. Sandbox Freedom and Player-Directed Play

Worldsim should feel like a genuine sandbox rather than a sequence of surfaced situations followed by response buttons.

The player should be able to pursue curiosity, personal experiments, long-term obsessions, and self-created stories without waiting for the game to assign a problem.

The core sandbox principle is:

> **The game presents possibilities. The player decides what is worth caring about.**

And the practical test is:

> **A successful Worldsim sandbox lets the player invent an experiment the designer never explicitly authored, while the simulation still produces understandable history from it.**

### Events are invitations, not gates

World events, crises, prayers and notable developments should help the player notice meaningful opportunities. They must not be the only way to access divine gameplay.

The player should not need to wait for:

```text
EVENT APPEARS
  ↓
CHOOSE RESPONSE
  ↓
ADVANCE
```

as the primary play structure.

Instead, the intended sandbox rhythm is closer to:

```text
Inspect world
  ↕
Inspect people / beliefs / history
  ↕
Follow what interests the player
  ↕
Use a divine action on a chosen valid target
  ↓
Advance time
  ↓
Review consequences
  ↓
Choose what to care about next
```

Events remain useful because they surface pressure, opportunity, uncertainty and consequence. They do not gate access to God.

This strengthens Section 98's distinction between **Primary Divine Actions**, which remain persistently available, and **Secondary Divine Actions**, which emerge from current world conditions.

### The player may be proactive

The player should be allowed to intervene before the world explicitly asks for help.

Examples:

- bless a settlement before famine begins
- warn a ruler before a threat becomes public
- favour an unknown farmer
- curse a prosperous city without being provoked
- issue a commandment during a peaceful era
- reveal knowledge nobody requested
- protect a bloodline before it becomes historically important
- remain silent despite having abundant capacity to intervene

The world should respond to what God actually does, not only to contextual event choices offered by the interface.

### Sandbox freedom is not raw state editing

Normal play should preserve the distinction between **being God inside the world's causality** and **being the developer editing simulation variables**.

God may:

- bless
- curse
- command
- reveal
- protect
- punish
- create signs
- perform miracles
- choose or favour targets
- remain silent

God should not normally perform actions such as:

```text
SET trust(Mara, King) = 100
SET Westfield.food = 0
SET Mara.loyal = true
SET religion = militaristic
SPAWN prophet
```

Those bypass the causal simulation and collapse interpretation, choice and consequence.

Raw values, forced states and direct simulation editing belong in **Developer Mode** or an explicitly separate Creative / Cheat surface, not in standard sandbox play.

> **Sandbox freedom means broad freedom to act through the world, not freedom to skip the world.**

### Conditions, not authored outcomes

Future New World or Sandbox setup may allow the player to choose starting **conditions** when those systems exist.

Potential examples:

- world seed
- world size
- number of settlements or civilizations
- population scale
- climate severity
- resource abundance
- disaster frequency
- starting stability
- mortality harshness
- other simulation parameters supported by real systems

These options should create different starting pressures and possibilities.

They should not directly choose historical or cultural outcomes such as:

- starting religion
- peaceful culture
- militaristic culture
- guaranteed prophet
- fanatically loyal population
- predetermined ideology
- chosen historical dynasty

Those are things history should produce.

This preserves Sections 48, 50 and 63: belief, religion, historical figures and cultural identity should emerge from events, interpretation, relationships and accumulated history rather than from setup presets.

### Player-created experiments are valid gameplay

The game should support players inventing their own questions and then using the simulation to discover the answer.

Examples:

> What happens if I protect one ordinary family for four hundred years?

> What happens if I issue one commandment and then never speak again?

> What happens if I only answer prayers from people who publicly deny I exist?

> What happens if I repeatedly save failed rebellions?

> What happens if I bless every ruler who becomes hated?

> What happens if I command one settlement never to kill while neighbouring societies develop normally?

The designer does not need to author a unique scenario for each of these.

The systems should combine to produce consequences that remain understandable in hindsight.

This is one of the strongest tests of whether Worldsim is actually a sandbox rather than a branching event game.

### Watch / Follow — player-defined story threads

A future **Watch / Follow** interaction is approved as a sandbox-oriented UX direction.

The player may mark supported world subjects such as:

- people
- settlements
- bloodlines or families, once modeled
- commandments
- beliefs
- religions
- conflicts
- factions
- institutions
- historical claims
- other persistent simulation threads

A Watch entry means:

> **Surface meaningful future changes involving this subject because the player has chosen to care about it.**

It must not mean:

> **Make the simulation treat this subject as mechanically more important.**

Watching Mara does not improve Mara's survival, importance, confidence, influence, event frequency or decision weight.

It changes **attention and presentation only**.

This creates player-defined storylines without converting them into quests or objectives.

### Watchlist presentation

The player may eventually receive concise updates such as:

```text
WATCHED THREADS

Mara — relationship with the crown has deteriorated.
Westfield — food conditions continue to worsen.
"Protect the Weak" — two groups now disagree about who the commandment applies to.
House of Aster — a new heir has become politically relevant.
```

Only meaningful changes should surface.

Do not turn Watch into a stream of every simulation tick, every action, or every numerical fluctuation.

The Watch system exists to preserve continuity in a long simulation and help the player create their own narrative focus.

### Free exploration between time advances

The player should be allowed to browse the living world without advancing time.

They may move between:

- World
- People
- Prayers
- Divine
- Beliefs
- History
- Archive
- watched subjects
- supported future Society systems

and inspect available information before deciding whether to intervene or advance.

This extends Sections 97–100: the interface should support exploration of one continuous simulation, not present isolated event cards as separate pieces of content.

### No correct use of divine power

A divine action should not carry a built-in moral judgment from the game merely because of its label.

Blessing is not automatically good.
Punishment is not automatically evil.
Silence is not automatically neglect.
Answering a prayer is not automatically correct.

Meaning comes from:

- context
- consequences
- mortal interpretation
- historical precedent
- competing beliefs
- later outcomes

The game may show suffering, harm, gratitude, fear, anger and other reactions clearly. It should not convert those reactions into a universal designer-approved morality score.

This is consistent with Section 73's rule that morality is made by societies.

### Destructive play remains valid

Players may intentionally destabilise, damage or transform the world.

Possible player-created directions include:

- repeatedly supporting unpopular rulers
- allowing a kingdom to collapse
- creating contradictory commandments
- punishing prosperous settlements
- favouring one lineage obsessively
- abandoning a religion after centuries of support
- resurrecting a historically hated figure
- protecting a faction from every consequence it would normally suffer

These should produce new conditions and history rather than a conventional failure screen whenever the simulation can continue.

Section 23 remains in force: collapse and failure should generate history.

### Long-term experiments need long-term feedback

Worldsim's sandbox should support experiments spanning decades or centuries.

The player therefore needs ways to understand what became of an earlier intervention without reading every year manually.

Long-term feedback may eventually draw from:

- Watch / Follow
- History
- Archive
- remembered divine interventions
- changed beliefs
- changed relationships
- doctrine and political claims
- historical summaries
- rediscovery

The purpose is not to compress the simulation into a result screen. It is to let the player understand causal change across long timescales.

### Creative / Cheat Mode may exist separately

A future optional Creative, Developer or Cheat-oriented mode may allow looser constraints such as:

- unlimited Divine Tokens
- extreme world-generation parameters
- accelerated testing
- direct inspection of objective truth
- simulation debugging tools
- possibly direct state editing, if useful for testing or experimentation

If such a mode exists, it should be clearly separate from the default god-sandbox rules.

Standard play should preserve consequence, uncertainty, interpretation and limited precision because those are part of what makes divine action meaningful.

Creative freedom must not quietly redefine the normal game into a debug interface.

### Do not replace attention with generic automation

The player should not receive a generic out-of-world automation language that says things like:

```text
IF famine THEN send rain automatically
IF Mara endangered THEN heal Mara
```

as the default way to manage the world.

That would bypass the intended importance of divine attention and turn God into a policy engine.

Persistent or delegated intent should preferably exist through **in-world causal mechanisms** such as:

- commandments
- promises
- future Apostles
- institutions reacting to divine precedent
- mortals acting on remembered teachings

These can fail, distort, reinterpret or produce unintended consequences.

That makes delegation part of the simulation rather than an exception to it.

### Sandbox identity

The intended identity can be summarized as:

> **The world does not wait for the player to create stories. The player does not wait for the world to assign one.**

Worldsim continuously produces conditions, people, beliefs, crises, relationships and history.

The player chooses which threads to follow and where God intervenes.

The strongest player stories should often begin with:

> **"I wanted to see what would happen if..."**

and end with a consequence the player did not explicitly script but can understand.

### Scope status

This section records approved design direction.

It does **not** move Watch / Follow, advanced world-generation controls, Creative Mode, additional divine powers, bloodline simulation, religion, factions, institutions, multiple kingdoms, or other future systems ahead of Section 41's dependency order.

Near-term development remains focused on the existing simulation foundation.

When sandbox-oriented features begin entering implementation, the first priority should be to make existing divine actions and existing world information freely targetable and explorable before adding large new simulation systems.
