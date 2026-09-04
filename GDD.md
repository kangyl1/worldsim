# WORLDSIM — GAME DESIGN DOCUMENT
## Version 0.1 — Prototype Scope

Sections 1–28 describe the original prototype design and remain in force.

Sections 29–43 are the **Simulation Foundation Revision**. They extend the
document rather than replace it. Where the revision explicitly supersedes an
earlier statement, it says so.

## 1. High Concept

A text-heavy god simulation game inspired by **Warsim, WorldBox, and Black & White**.

The world develops without the player.

Kingdoms grow, suffer, worship, fight, prosper, collapse, and reinterpret history.

The player is not a king, mayor, or commander.

**The player is the god.**

The core experience is interfering with the world and watching civilizations interpret those actions.

---

## 2. Core Fantasy

The player should feel:

> “These people actually believe I am their god, and what I do changes what they believe about me.”

The player does not directly choose:

- God of War
- God of Harvest
- Evil God
- Merciful God
- God of Death

Instead, the world decides what the player is based on their behaviour.

Example:

The player repeatedly sends rain during droughts.

Eventually:

**The Rain-Bringer**

becomes one interpretation of the player.

Another civilization may experience the player completely differently.

---

## 3. Core Pillar

## Action → Interpretation → Belief → Behaviour → History

Every major divine intervention should potentially create consequences beyond its immediate mechanical effect.

Example:

Player sends rain.

Immediate result:

- crops recover
- famine risk decreases

Interpretation:

- villagers believe collective prayer caused the miracle

Belief created:

- “The God listens when many pray together.”

Behaviour:

- mass prayer ceremonies become common

Long-term consequence:

- priests gain influence
- people may panic if prayers later go unanswered
- another religious group may reject the practice

The game is about these chains.

---

## 4. Player Role

The player exists outside normal civilization.

The player can:

- observe
- intervene
- answer prayers
- ignore prayers
- bless
- curse
- reveal knowledge
- create miracles
- punish
- protect
- influence individuals
- influence settlements
- influence entire civilizations

The player should rarely directly control mortal behaviour.

The god **influences the simulation rather than managing it**.

---

## 5. Core Gameplay Loop

### Step 1 — World Advances

Time passes.

The simulation creates situations such as:

- drought
- famine
- war
- political conflict
- disease
- religious disputes
- successful harvests
- discoveries
- migration
- natural disasters

### Step 2 — Player Observes

The player receives information.

Example:

**Year 38 — Village of Aster**

Population: 418

Food: Critical

Faith: 34%

A drought has lasted three months.

Residents have begun gathering at an abandoned shrine.

Some are asking an unknown god for help.

### Step 3 — Player Chooses

Possible actions:

- Send rain
- Give irrigation knowledge
- Speak through a mortal
- Punish the population
- Ignore them

### Step 4 — Immediate Consequence

The simulation changes.

Example:

Rain:

- Food improves
- Faith increases
- Divine Power decreases

### Step 5 — Mortal Interpretation

The population decides what the intervention means.

They may believe:

- prayer caused it
- sacrifice caused it
- their ruler was chosen
- a prophet caused it
- it was natural
- the god is merciful
- the god is angry

Interpretation is not completely controlled by the player.

### Step 6 — World Continues

Those beliefs begin influencing:

- culture
- religious practice
- politics
- behaviour
- future events

The cycle repeats.

---

## 6. Prototype World

The first playable version should be deliberately small.

### World

1 region

### Civilization

1 kingdom

### Settlements

3 settlements

Example:

- Capital
- Farming village
- Frontier settlement

### Population

Population is simulated primarily as groups.

Do not simulate hundreds of complete individual NPC lives in Version 0.1.

Important characters may exist individually.

Examples:

- ruler
- prophet
- priest
- general
- rebel
- scholar

---

## 7. Core World Statistics

### Kingdom

- Population
- Food
- Stability
- Prosperity
- Military Strength

### Religion

- Faith
- Religious Unity
- Priest Influence

### Divine

- Divine Power
- Reputation
- Known Divine Names

Keep this simple initially.

---

## 8. Divine Power

Divine Power limits intervention.

The player cannot solve every problem.

Power regenerates through:

- time
- worship
- important religious events

Strong miracles cost more.

Example:

Minor sign:

1 Power

Send rain:

2 Power

Heal settlement:

3 Power

Destroy army:

5 Power

Mass resurrection:

Not part of prototype.

The purpose is to force:

> “Do I interfere?”

rather than letting the player click every solution.

---

## 9. Initial God Powers

### 1. Send Rain

Effects:

- improves crops
- reduces drought
- may create rain-related beliefs

### 2. Bless Harvest

Effects:

- increases food
- may make agriculture religiously important

### 3. Divine Revelation

Give knowledge to a mortal.

Examples:

- irrigation
- medicine
- farming
- construction

Potential consequence:

People may eventually credit humans rather than the god.

### 4. Divine Voice

Speak through or directly to a mortal.

Possible result:

- prophet appears
- cult forms
- ruler claims divine approval
- message is misunderstood

### 5. Smite

Destroy or punish a target.

Potential interpretations:

- divine justice
- divine anger
- god demands obedience
- victim becomes martyr

### 6. Silence

Do nothing.

This is an intentional action.

Ignoring prayers can itself influence belief.

Examples:

- faith falls
- philosophy changes
- people believe suffering is a test
- religion becomes less interventionist

---

## 10. Religion System

Religion is not just a percentage.

Each religion contains actual beliefs.

Example:

### Faith of the First Rain

God Names:

- Rain-Bringer
- Listener Above

Beliefs:

- communal prayer attracts divine attention
- rain is sacred
- priests should lead prayers

Practices:

- rain festivals
- public prayer
- water offerings

Faith:

64%

Influence:

Medium

---

## 11. Belief Creation

Beliefs should emerge from events.

Basic rule:

**Repeated or highly memorable events increase the chance of becoming doctrine.**

Example:

Player saves a village from three droughts.

Possible doctrine:

> “The God protects those who pray for rain.”

Player later refuses to help.

Possible theological explanation:

> “The people have angered the God.”

The simulation tries to explain player behaviour.

That is intentional.

---

## 12. Religious Interpretation

Different groups may interpret the exact same divine action differently.

Example:

The player destroys an invading army with lightning.

Settlement A:

> The God protects the faithful.

Settlement B:

> Lightning is sacred.

Enemy kingdom:

> The God is a cruel destroyer.

Survivors:

> The dead were punished for their sins.

This allows multiple identities to form around the same player.

---

## 13. Religious Schisms

Not required for the earliest prototype, but designed into the system.

Religions may split because of conflicting interpretations.

Example:

### Traditionalists

Believe:

Sacrifice caused previous miracles.

### Reformists

Believe:

The God rejects sacrifice.

Both groups worship the same player.

The player can:

- support one
- support both
- punish both
- remain silent

Silence may make the dispute worse.

---

## 14. Important Mortals

Most population remains abstract.

Specific individuals become simulated when they become historically important.

Examples:

### Prophet

Claims communication with the player.

### King

May use religion to justify authority.

### Priest

Interprets divine actions.

### Scholar

May provide natural explanations for miracles.

### Rebel

May reject established religion.

These characters can affect entire civilizations.

---

## 15. Prayer System

Mortals occasionally ask for intervention.

Examples:

- save harvest
- heal ruler
- win war
- punish criminal
- provide child
- protect settlement

The player may:

- answer
- partially answer
- answer differently
- ignore

The game should never guarantee that mortals correctly understand the answer.

---

## 16. History System

Every important event enters the world history.

Example:

**Year 12**

The people of Aster prayed during the Great Drought.

**Year 12**

Rain arrived after seven days of prayer.

**Year 14**

The first Shrine of Rain was constructed.

**Year 27**

Priestess Mara declared rain sacred.

**Year 63**

The Church of the First Rain became the kingdom's official religion.

History provides context for future beliefs.

The player should be able to inspect:

- kingdom history
- religious history
- important people
- divine interventions

---

## 17. Emergent God Identity

The player's reputation is generated from actions.

Possible identities:

- Rain-Bringer
- War God
- Silent God
- Protector
- Destroyer
- Harvest God
- God of Knowledge
- God of Death

These are not classes.

They are historical interpretations.

Several identities may exist simultaneously.

---

## 18. Presentation

Visual direction:

### Text-heavy, not pure terminal.

Use:

- readable panels
- event cards
- icons
- small symbols
- simple kingdom map
- timelines
- relationship indicators
- occasional portraits

Avoid expensive animation.

The world should feel alive through information and consequences rather than graphical spectacle.

---

## 19. Main Screen Concept

Top:

**Year / Population / Faith / Divine Power**

Middle:

Current event or situation.

Example:

> A famine has begun in Westfield.

Player actions appear underneath.

Side or lower panel:

- kingdom status
- settlements
- religion
- history
- important mortals

---

## 20. Time Structure

Prototype uses turn/year progression.

Example:

**Advance Year**

The simulation:

1. processes population
2. processes resources
3. processes kingdom conditions
4. generates events
5. updates religion
6. updates important characters
7. records history

Later versions may allow different time speeds.

---

## 21. Event System

Events should primarily emerge from world state.

Example:

Low Food + Drought:

→ famine

Low Stability + unpopular ruler:

→ rebellion

High Faith + influential priest:

→ major religious movement

Two conflicting beliefs:

→ religious dispute

Player repeatedly blessing one settlement:

→ jealousy from another settlement

Avoid relying entirely on random disconnected events.

---

## 22. Prototype Event Target

First prototype:

20–30 events.

Categories:

- food
- weather
- ruler
- faith
- prophet
- settlement
- conflict
- disease
- discovery

The goal is replayability through combinations rather than hundreds of individually written events.

---

## 23. Failure

There is no conventional Game Over required.

Possible world outcomes:

- kingdom collapses
- religion disappears
- population abandons the player
- new civilization emerges
- another religion replaces the original
- world becomes hostile to divine influence

Failure should generate history rather than simply ending the game.

---

## 24. Player Goals

The game should support self-directed goals.

Examples:

- create a peaceful civilization
- become feared
- create the largest religion
- avoid direct intervention
- become God of War
- destroy your own religion
- create rival religions
- protect one bloodline
- guide civilization toward knowledge

Later versions may include scenarios.

---

## 25. What The Game Is NOT

Not:

- city builder
- RTS
- kingdom management game
- direct population management game
- WorldBox clone
- traditional RPG
- idle clicker

The player influences civilization from above.

Mortals remain autonomous.

---

## 26. Prototype Success Test

The prototype succeeds if players naturally say things like:

> “I didn't mean to create that religion.”

> “They completely misunderstood what I did.”

> “I saved their king and now they think his family is divine.”

> “I ignored them for fifty years and somehow they became even more religious.”

> “I accidentally became their god of war.”

As the mortal simulation deepens, the prototype should also produce stories
about the people themselves:

> “Mara helped a village because she believed a rumor that wasn't even true.”

> “The King became threatened by someone I accidentally made popular.”

> “Nobody scripted this rivalry. It grew out of their decisions.”

> “I can see exactly why this happened.”

> “A tiny event became important because the kingdom was already unstable.”

Those stories are the product.

The last two matter as much as the rest. A world that produces surprising
history the player cannot explain has failed differently from one that
produces no history at all.

---

## 27. Prototype Scope Lock

For Version 0.1, DO NOT add:

- individual simulation for every citizen
- genetics
- family trees for everyone
- detailed economy
- tactical combat
- procedural graphical terrain
- hundreds of items
- complex technology tree
- multiple races
- dozens of kingdoms
- detailed diplomacy
- animated characters

First prove:

**Intervention + interpretation + consequence is fun.**

Everything else comes later.

---

## 28. Core Design Statement

**The world should not simply react to the player's powers.**

**The world should try to understand the player.**

That is the identity of the game.

---

# PART II — SIMULATION FOUNDATION REVISION

Sections 29–43 revise how mortals behave. They do not change what the game is.

Section 3 remains the core pillar, and Section 28 remains the identity of the
game. Everything below exists to give divine intervention a world worth
intervening in.

---

## 29. Why The Mortal Model Is Being Revised

The prototype currently reasons in a short chain:

Knowledge
→ a specific action-like Decision

That chain is too tight. It jumps from what a person knows straight to a named
behaviour, which leaves no room for ordinary life, cooperation, politics,
religion, curiosity, fear, resource pressure, or the slow build toward conflict.

**Decision Engine v1 remains implemented and valid.** It is a working prototype
foundation: deterministic, explainable, and correct in its architecture.

What is expected to change is its **vocabulary**. The current decision types:

- `investigate`
- `warn_ally`
- `send_aid`
- `exploit_weakness`

are useful prototype behaviours, but they are action-specific. They describe
what someone does, not what someone wants. The long-term system needs the
broader layer described in Section 30.

This vocabulary is expected to evolve **before** Mortal Actions are implemented.

**Resolved.** Broad Intent Model v1 replaced that vocabulary with the ten
directions listed in Section 30. The engine's architecture — deterministic
argmax, believed knowledge only, trait and relationship weighting, full
explainability records, bounded yearly work — was preserved intact and moved to
`scripts/intent_rules.gd`. See Section 31 for the gating law that keeps the
layers apart.

---

## 30. The Mortal Simulation Chain

The full causal chain a mortal passes through:

```
World State
  ↓
Pressures / Needs
  ↓
Event or Observation
  ↓
Perception
  ↓
Knowledge / Belief
  ↓
Interpretation
  ↓
Goal
  ↓
Broad Intent
  ↓
Action Selection
  ↓
Action Attempt
  ↓
Immediate Consequence
  ↓
Possible Ripple
  ↓
Memory / Knowledge
  ↓
Relationships / World State
  ↓
History
```

### World State

The objective conditions that currently exist.

Examples:

- low food
- unstable settlement
- dangerous border
- popular ruler
- religious tension

Minimal Settlement State v1 makes these local. Each settlement carries its own
**food**, **stability**, **prosperity** and **population**, and the kingdom's
figures are a view of them rather than a second copy: writing the realm's food
reaches every settlement, and reading it weighs each place by the people living
with the condition. There is one source of truth and it is the settlements.

Not everything became local. The **army, faith, followers and reputation stay
the realm's** — an army is the kingdom's capacity and belief travels, so
neither belongs to a place.

> **Settlements are local state containers that create situations for mortals
> and the god. They are not autonomous political actors, and they are not
> domains the player manages.**

A settlement has conditions, not intentions. It never decides to stockpile
grain, raise a levy, or build anything: mortals decide things, places do not.
There are no taxes, laws, governors, budgets, construction or trade routes, and
none may be added without a design pass of its own. Settlement simulation exists
to support divine gameplay, not to replace it.

The year's weather falls on every settlement; the year's **event** names the one
place where that condition is thinnest, and only that place takes the dramatic
consequences. That split is what lets ordinary life dominate while still
producing something worth noticing, and it is why divine acts now land somewhere
in particular rather than on an average of the realm.

Local conditions also mean local knowledge. A shortage in Westfield is a
different belief from a shortage in Aster, held and spread separately, and
whoever lives elsewhere finds out the way anyone finds out about a distant
place. An event does not need a notable mortal standing in it to be real.

**A settlement's food is not any mortal's to give away.** Ownership is a
separate, unanswered question, and full granaries do not make a villager capable
of handing them out.

### Pressures / Needs

Conditions create motivation. They do not cause outcomes.

Low food may create pressure to:

- acquire food
- conserve food
- share food
- hoard
- trade
- steal
- migrate
- ask for help

The simulation must never hardcode:

Low Food → Theft

The state creates possibilities. Which possibility a person reaches for is
decided further down the chain.

### Event or Observation

Something happens, or something is noticed.

### Perception

Characters react only to information they can perceive or receive.

They do not automatically know global truth. A famine three settlements away
does not exist for someone until word of it arrives.

Selective Perception v1 makes this real. An event happening and a mortal
knowing it happened are separate things, and three layers stay apart:

> **Events** are objective world occurrences.
> **Perception** determines who could notice them.
> **Knowledge** stores what a mortal believes they learned.
> **Interpretation** determines what that knowledge means to them.

Each event says how widely it can be noticed:

| Observability | Who is eligible |
|---|---|
| Direct | Only those who took part |
| Local | Those who live where it happened |
| Public | Everyone in the kingdom |
| Hidden | Nobody, unless they took part |

Eligibility is not certainty. Being in a thing carries it at full clarity;
seeing it locally costs a little; a merely visible event costs more. The event
template is the ceiling on what can be known from it — a mortal may learn that
a settlement lacks food, and never the number underneath.

Mortals carry a `home_location_id`: the settlement they are normally part of.
That is an association and not a position. There is no travel, no distance and
no schedule behind it, and someone with no home notices no local event at all.

**No global distribution of event knowledge remains.** Nothing teaches every
notable entity a fact merely because the fact became true. What a mortal did
not see, they can still come to hear — through rumor, or because somebody
chose to tell them. That gap is where deliberate speech gets its purpose.

Perception produces observations, never meaning. "I saw rain fall after the
prayer" is perception; "the god answered us" is interpretation, and Section 12
owns it. Nothing in the perception layer may reach into theology.

### Knowledge / Belief

Characters reason from what they believe, which includes:

- correct information
- incomplete information
- false rumors
- outdated knowledge
- distorted knowledge

### Interpretation

Characters attach meaning to what they know, based on:

- traits
- relationships
- existing beliefs
- roles
- previous experiences

Two people can hold the same fact and reach opposite meanings.

Its position in this chain is contested. Section 46 argues interpretation also
happens *earlier*, between perception and belief, because "the god answered us"
cannot be stored without having already been interpreted. Both moments are real;
see Section 46 before building this layer.

### Goal

A broader desired outcome.

Examples:

- reduce suffering
- become safer
- preserve status
- understand what happened
- protect someone
- improve livelihood

### Broad Intent

The character chooses a direction, **not yet a concrete action**.

Broad Intent Model v1 settles the vocabulary at ten directions:

| Intent | What the character wants |
|---|---|
| Help | Improve another's condition, where harm is already present |
| Protect | Prevent harm from an identified threat |
| Acquire | Gain something materially or positionally lacking |
| Learn | Reduce uncertainty or improve understanding |
| Influence | Change another's behaviour, belief, support, or decision |
| Connect | Strengthen or create a social bond |
| Distance | Reduce exposure, obligation, or involvement |
| Resolve | End an active quarrel, dispute, or tension |
| Preserve | Hold to an existing condition, role, belief, or order |
| Wait | Choose not to intervene yet |

Two boundaries inside that list carry design weight:

- **Acquire does not cover information.** Wanting to understand is Learn.
- **Protect answers a threat; Preserve answers erosion.** Defending a shrine
  from a mob and maintaining a religious practice are different wants, and the
  presence of an identified threat is what separates them.

**No intent in this list is antagonistic.** There is deliberately no "attack",
"exploit" or "punish" direction. Hostility reaches the world through Acquire,
Influence, Preserve and Distance, and the aggression appears at Action
Selection as an execution style. War is an execution, never a want. This is
what keeps the model from being war-shaped.

### Action Selection

The character chooses an execution, based on:

- available opportunities
- resources
- relationships
- traits
- knowledge
- role
- location
- risk

Example:

Intent:

Help Westfield

Possible actions:

- personally deliver food
- ask the ruler for aid
- persuade merchants
- organise local relief
- teach better farming
- pray
- spread awareness
- do nothing, if unable to act

An intent with no available action is a valid outcome. Wanting something and
being unable to attempt it is part of the simulation, not a failure of it.

Mortal Action Selection v1 keeps the vocabulary small and parameterised, so
that the list above is expressed by combining a verb with a target, a topic and
a resource rather than by naming each behaviour separately:

| Action | What the character attempts |
|---|---|
| Give | Hand over something they control |
| Ask | Request help, resources, or an answer from someone |
| Tell | Pass on something they believe |
| Support | Lend effort, standing, or presence to someone |
| Oppose | Object, refuse support, obstruct — never violence |
| Observe | Look harder without intervening |
| Wait | Attempt nothing this cycle |

**This vocabulary is provisional.** A new verb earns its place only when it
cannot be expressed by combining an existing one with parameters. "Warn",
"preach", "beg", "teach" and "donate" are not actions; they are Tell, Tell,
Ask, Tell and Give wearing different manners, and manner is a later layer.

Two are held back deliberately, because the world has no data to support them
honestly. **Go** needs entities to have locations, and they do not; movement
would have to be invented rather than simulated. **Give** is generated and then
refused every time, because nothing yet models a resource a mortal controls —
kingdom food belongs to the realm, not to any person. Its refusal is the
clearest demonstration in the system that capability filters an action without
touching the want.

Selection is not execution. Choosing to ask the King for grain is not the King
answering, and nothing in the world moves because an attempt was written down.

### Action Attempt

The character tries. Attempts may fail.

Mortal Action Execution v1 resolves every attempt into one of three outcomes,
and the difference between the last two matters:

| Outcome | Meaning |
|---|---|
| Success | It happened and reached its immediate goal |
| Failure | It happened and fell short |
| Blocked | It could not honestly be attempted at all |

Mara asking the King and being refused is a **failure**: she tried. Mara having
nothing to hand over is **blocked**: there was nothing to try with. Collapsing
the two would hide the difference between a world that says no and a world that
offers no opening.

An attempt is re-checked against the world before it runs, because selection
was made against an older snapshot. A belief that has gone since blocks the
telling that depended on it, and the intent and the selected action both remain
exactly as they were.

Execution is deliberately near-inert. Only two attempts change anything at all,
and both go through the knowledge system rather than around it: **Tell**
delivers a claim, and **Observe** records something the world is currently
making observable. Everything else — an accepted request, expressed support,
expressed opposition — produces a result and moves nothing. What those results
go on to change is the next section's problem, and the engine that owns it does
not exist yet.

### Immediate Consequence

Actions change the world locally first.

Consequence Engine v1 answers one question and refuses the next:

> **A consequence says what objectively changed or occurred.**
> **It never decides what that meant.**

A refusal is a refusal. It is not a betrayal until somebody decides it was, and
deciding that belongs to interpretation. So the engine records no trust,
hostility, faith or reputation movement, and it must never become a table of
scripted emotional reactions.

The route back into the simulation is deliberately indirect:

```
Execution
  ↓
Consequence          what objectively happened
  ↓
Event                something there was to notice
  ↓
Perception           who was placed to notice it
  ↓
Knowledge            what they took from it
  ↓
Interpretation       what they decide it meant     (later system)
```

That indirection is what keeps a private refusal private, lets it spread later
only if somebody passes it on, and stops a slight becoming a war by itself.

**Mortal and divine acts enter through the same door.** A god who causes rain
produces "rain fell on Westfield" — a thing that happened, with no motive
recorded. One mortal may call it mercy, another weather, another favouritism.
The god acted once; the simulation makes the meaning.

Consequences are conservative. Agreeing to a request is not delivering on it:
an accepted request changes nothing about a hungry settlement. Telling someone
something already moved the knowledge while it was being carried out, so its
consequence is deliberately nothing at all rather than a second route to the
same fact.

Because social occurrences become beliefs, mortals now forget. What goes first
is what could least change what they do next — retracted claims, then stale ones
they were never sure of. That is Section 36 applied to memory rather than to
history.

Consequences may affect:

- settlement state
- relationships
- knowledge
- reputation
- resources
- future opportunities

### Possible Ripple

A consequence expands only if another existing condition gives it somewhere
meaningful to propagate. See Section 35.

### Memory / Knowledge

Only meaningful results persist. See Section 36.

### Relationships / World State

Changes feed back into the conditions the next chain reads.

### History

Important causal chains become historical records.

---

## 31. Intent Is Not Action

**This is a design law.**

An Intent answers:

> What does this person want to accomplish?

An Action answers:

> What do they actually attempt?

Example:

Situation:

Westfield is starving.

Mara:

Goal:

Reduce suffering.

Intent:

Help Westfield.

Possible actions:

- donate food
- ask the King for grain
- organise relief
- persuade merchants
- travel there
- pray for divine help

This distinction must be preserved in all future architecture.

**Do not allow the Intent system to become a list of pre-selected executions.**

If the intent vocabulary starts reading like a list of things people do rather
than things people want, the layer has collapsed and needs to be split again.

### The Gating Law

Settled during Broad Intent Model v1. Three kinds of condition can touch an
intent, and each may act only in one way:

> **Gate on relevance of the evidence.**
> **Weight on disposition.**
> **Never gate on capability.**

**Relevance** is the only hard gate the intent layer permits. A belief about a
surplus cannot produce Help, because the evidence is not about suffering. This
is what stops every intent being evaluated against every fact.

**Disposition** — traits, and directed relationships — changes how strongly a
want is held. It never forbids one. A cruel noble can still want to help; it
simply costs him against a rival want. This restates Section 32 at the level of
scoring.

**Capability** must not reach the intent layer at all. Having no food, no army,
no influence and no way to travel does not stop Mara wanting to help Westfield.
Whether she can do anything about it is Action Selection's question, and
Section 30 already establishes that an intent with no available action is a
valid outcome rather than a failure.

Decision Engine v1 mixed the third kind into the first: `send_aid` required
food in the granary, and `exploit_weakness` required an army. Those were checks
on whether an action could succeed, wearing the shape of a want. Removing them
is what let the intent layer separate from the action layer cleanly.

If a future condition is hard to classify, the test is simple:

> Does this describe what the person **wants**, or whether they **could**?

Only the first belongs here. The second belongs one layer down: at Action
Selection capability becomes a hard gate, and an action refused there leaves
the want standing exactly as it was.

---

## 32. Same Intent, Different Execution

Traits influence **how** an intention is pursued. They do not assign people
predetermined actions.

Intent:

Help Westfield

| Character | Execution |
|---|---|
| Compassionate villager | Gives resources directly |
| Ambitious ruler | Provides aid publicly, and takes credit |
| Cautious merchant | Offers a low-risk grain loan |
| Cruel noble | Provides food in exchange for harsh labour |

Same intent. Different execution.

Traits weight behaviour. They must not become rigid character scripts.

This mirrors the rule already established for Decision Engine v1: traits weight
scores and never hard-gate a choice unless a specific gate is explicitly
approved.

---

## 33. False Beliefs Create Real Consequences

Mortals act according to **believed** reality, not objective reality.

Example:

Reality:

Westfield has enough food.

Mara falsely believes:

Westfield is starving.

Mara may still form the intent:

Help Westfield.

She may send unnecessary supplies. That may create a real shortage somewhere
else.

Therefore:

> **False information may produce objectively real history.**

This is one of Worldsim's core emergent-story principles. The simulation must
never quietly correct a character because the engine knows better.

The player, as a god, may see the truth. The character may not. That gap is
where the best stories come from.

---

## 34. Needs Create Possibilities, Not Automatic Penalties

A need or shortage should create:

- choices
- opportunities
- leverage
- cooperation
- work
- crime
- migration
- conflict
- religious behaviour

rather than only modifying a statistic.

Example:

A food shortage should not only mean:

Population −5

It should create reasons for mortals to act, and reasons for a god to be asked
for help.

A pressure that produces no behaviour is a number, not a simulation.

---

## 35. Consequences Are Local Until Something Amplifies Them

**The bounded ripple rule.**

A small event should normally have a small effect.

Example:

Mara insults the King.

Normal outcome:

- the King's hostility toward Mara increases slightly

**Stop there.**

However, if:

- Mara is already extremely popular
- the King is insecure
- Westfield is already angry
- political stability is low

then the same insult connects to those conditions and escalates:

```
Insult
  ↓
King retaliates
  ↓
Westfield sees persecution
  ↓
existing unrest increases
  ↓
political crisis
```

Rule:

> **A consequence continues only when another meaningful world condition gives
> the chain somewhere to go.**

This keeps emergent history understandable and keeps simulation cost bounded.
It also means dramatic outcomes are readable in hindsight: the conditions that
carried the chain were already visible before it started.

---

## 36. Remember What Can Change Future Behaviour

**The selective memory rule.**

Do not preserve every mundane action forever.

Usually do not store:

- ate bread
- walked home
- saw normal rain

unless context makes them meaningful.

Store things such as:

- a ruler refused aid during famine
- Mara saved Westfield
- a priest accused someone publicly
- a character witnessed a divine miracle
- betrayal
- a major debt
- an important promise

Rule:

> **Long-term memory should justify its existence by being capable of affecting
> future behaviour, belief, relationships, or history.**

This extends Section 16 rather than contradicting it: Section 16 already stores
*important* events. This states the test for importance.

---

## 37. Understandable Normality + Meaningful Variation

Worldsim should not make every year dramatic.

Most simulated behaviour should be ordinary and understandable:

- working
- sharing
- trading
- maintaining relationships
- seeking food
- learning
- helping
- waiting
- travelling
- arguing
- praying

Major behaviour should emerge when pressures and circumstances align:

- betrayal
- rebellion
- religious schism
- assassination
- migration
- war

These matter **because** they are comparatively rare. A world where someone is
betrayed every year contains no betrayals worth remembering.

This is a design philosophy, not a literal probability roll. No fixed ratio is
locked here.

---

## 38. Opportunities, Not Objectives

World situations create opportunities. They do not issue instructions.

Example:

Westfield is starving.

This does **not** mean:

OBJECTIVE: SAVE WESTFIELD

The player may:

- help
- ignore
- exploit
- worsen
- study
- manipulate
- influence indirectly

Mortals are likewise not forced into one predetermined response to a condition.

This applies to interface as much as simulation. The game should show that
something is happening, not tell the player what to do about it.

---

## 39. The Player Relevance Filter

Every simulation system must answer three questions:

1. What can the player **notice** because this exists?
2. What can the player **understand** because this exists?
3. What can the player **do** because this exists?

Avoid complexity that exists only because it is realistic.

Bad justification:

> NPC hunger is realistic.

Better:

> Hunger produces readable pressures, mortal behaviour, prayers, migration,
> conflict, and opportunities for divine intervention.

This protects Worldsim from becoming more interesting to watch than to play.

A system that fails all three questions should be cut, no matter how correct it
is.

---

## 40. Meaning First, Numbers Underneath

The simulation may use exact numbers internally. The normal player interface
should primarily show:

- qualitative states
- readable consequences
- intentions
- beliefs
- trends, when reliable

Exact values remain visible where they genuinely improve decisions:

- Divine Power
- Population
- Followers

Developer Mode may expose:

- raw values
- exact relationships
- confidence numbers
- objective truth
- decision scores
- internal records

Rule:

> **The simulation can be numerical without making the player's experience a
> spreadsheet.**

Developer Mode is also where the mortal-perspective rule is deliberately
broken. The player panel shows what a character believes; Developer Mode shows
what is true. Those two views must never be merged.

---

## 41. System Dependency Order

The current dependency order. This is not an immutable schedule.

| # | System | Status |
|---|---|---|
| 1 | Traits | **Built** |
| 2 | Relationships | **Built** |
| 3 | Knowledge / Rumors | **Built** |
| 4 | Decision Engine v1 | **Built**, then superseded in vocabulary by 5 |
| 5 | Broad Intent Model | **Built** — ten directions, intentions only |
| 6 | Mortal Action Selection | **Built** — seven verbs, selection only |
| 7 | Mortal Action Execution | **Built** — immediate results, no consequences |
| 8 | Consequence Engine | **Built** — objective change only, no reactions |
| 9 | Minimal Settlement State | **Built** — local food, order, wealth, people |
| 10 | Event → Perception → Knowledge pipeline | **Built** — selective, no global teaching |
| 11 | Autonomous Feedback Loop | |
| 12 | Divine Actions integrated into the same causal pipeline | |
| 13 | History / Chronicle generated from causal events | |
| 14 | Deeper religion / interpretation | |
| 15 | Factions / politics | |
| 16 | Multiple kingdoms | |
| 17 | World generation | |
| 18 | Additional races / Create Life | |

Item 12 matters more than its position suggests. Divine actions should
eventually run through the same causal pipeline as mortal actions, rather than
existing as a separate special case. The god should be an actor in the world's
causality, not an exception to it.

**This table is the whole roadmap.** Part III records long-term direction and
adds nothing to it: no section from 44 to 72 appears here, and none should be
read as scheduled work. If a Part III idea starts to feel urgent, that is a
reason to finish the layer currently in progress.

---

## 42. Foundation Milestone — The Autonomous Story Test

Before major scope expansion, the simulation must pass one test.

Without player intervention, advance the world for several decades.

The simulation succeeds when:

- mortals perceive changing conditions
- they form understandable goals and intents
- they attempt actions
- actions create bounded consequences
- relationships and knowledge change
- those changes affect later behaviour
- important events become history
- the resulting story is understandable
- Developer Mode can explain why important outcomes occurred

The exact number of years is not a mechanical requirement.

The point is:

> **The world should be capable of producing a coherent causal story without
> requiring scripted player intervention.**

The final condition is the strict one. A world that produces events nobody can
explain has not passed; it has only produced noise.

Only after this loop works do the following become priorities:

- multiple kingdoms
- detailed politics
- large world generation
- new races
- Create Life

---

## 43. The God Remains The Game

This revision must not turn Worldsim into an NPC life simulator with a
spectator attached.

The core pillar stands unchanged:

## Action → Interpretation → Belief → Behaviour → History

**The mortal simulation exists to make divine intervention more meaningful.**

A richer causal chain gives the player more places to interfere, and makes each
interference more legible in hindsight.

Example:

```
Famine
  ↓
Mara decides to help
  ↓
King blocks her
  ↓
resentment rises
```

At any point in that chain, the god may:

- bless Westfield
- reveal the King's refusal
- send Mara a dream
- support the King
- remain silent

Every one of those produces a different history, and silence is a real choice
with real consequences.

The player remains the god, interacting with an autonomous world.

Section 28 still has the last word:

**The world should not simply react to the player's powers.**

**The world should try to understand the player.**

---

# PART III — FUTURE SIMULATION DIRECTION
## Meaning, Belief, History, and Divine Influence

> **This part is direction, not roadmap.**
>
> Nothing in Part III is current work. None of it is scheduled, none of it is
> scoped, and none of it may be implemented without an explicit request. The
> milestone order in Section 41 is unchanged by anything written here.
>
> Part II describes how mortals behave today. Part III describes what that
> behaviour is eventually for. It exists so that near-term decisions do not
> quietly foreclose the long-term shape of the game — not to add work.
>
> Where a principle here disagrees with a Part I or Part II section, the
> disagreement is stated rather than smoothed over. Part II governs what is
> built; Part III governs where it is going. Three such tensions are recorded:
> Sections 46, 56 and 50.

---

## 44. The Chain, and the Law Beneath It

The chain Worldsim should increasingly follow:

```
Objective event
  ↓
Perception              who could notice it
  ↓
Interpretation          what they take it to mean
  ↓
Knowledge / Belief      what they now hold
  ↓
Sharing / Distortion    what reaches other people
  ↓
Decision
  ↓
Social / world consequence
  ↓
Recorded history
  ↓
Later interpretation
```

**The engine knows what objectively happened. Entities may not.** That gap is
not a limitation to be engineered away; it is the material the game is made of.

Two laws follow, and both are load-bearing:

> **The player controls their actions and words. They do not control what
> history says those actions and words meant.**

> **The player creates conditions and possibilities. Intelligent beings create
> institutions and meaning.**

The identity that emerges from those, recorded as an internal design principle
and **not** as finished marketing copy:

> **The player changes the world. People decide what those changes mean. Those
> meanings shape decisions. Those decisions become history.**

Or shorter:

> **The player creates the world. Life creates history.**

This extends Section 3 rather than replacing it. Action → Interpretation →
Belief → Behaviour → History is the same loop from the player's end; this is the
same loop from the world's.

---

## 45. Conditions, Not Outcomes

The player's input to the loop is conditions. Avoid direct commands that name an
outcome:

- Create Kingdom
- Create Religion
- Create Prophet
- Select Culture
- Make Civilization Peaceful
- Make Civilization Militaristic

Prefer instead: alter conditions, communicate, reveal information, provide
knowledge, intervene, protect, withhold help, create pressure, create
opportunity.

Example:

The player causes heavy rainfall. The player does **not** choose:

> Village becomes prosperous.

Rain enters a world that already has a state, and what it becomes there depends
on that state: crops, food, migration, trade, disease, belief, relationships,
political decisions, or conflict. The same rain falling on two settlements is
not the same event.

The existing powers in Section 9 already follow this shape — rain, harvest,
revelation, voice, smite, silence are all conditions or communications, never
outcomes. That is worth protecting when powers are added.

---

## 46. Interpretation Is a Layer

Every important event should be capable of carrying two things at once:

**Objective reality** — what actually happened.
**Interpretation** — what an observer takes it to mean.

Example. Objective event: the player causes rain. Possible interpretations:

- God answered our prayer.
- The king has divine favour.
- God is warning us.
- This was natural weather.
- Another group caused it.
- We do not know why it happened.

Interpretation should eventually draw on perception, existing knowledge,
confidence, traits, relationships, beliefs, previous experience, social
influence, and historical precedent.

### Recorded tension: where interpretation sits

Section 30 places Interpretation **after** Knowledge/Belief: you hold a fact,
then you decide what it means. This part places it **between** Perception and
Knowledge/Belief: you cannot store "the god answered us" without having already
interpreted the rain.

Both are true, because they are different moments:

- **Interpretation on perception** — turning something witnessed into something
  believed. "Rain fell" and "the god answered" are different beliefs formed from
  one observation.
- **Interpretation on belief** — standing back and asking what the things you
  already hold add up to. This is where doctrine, grievance and political claim
  come from.

Neither section is wrong and neither is being edited. Reconciling them is a
design task for whoever builds the interpretation layer, not something to settle
in a direction document. What must survive either way is the existing law:
perception reports what was seen and never what it meant.

---

## 47. Disagreement Is Preserved

One event must not automatically produce one universal explanation.

A flood destroys a settlement. Possible interpretations, held simultaneously by
different people:

- God punished us.
- Our ruler failed us.
- Foreigners caused this.
- It was a natural disaster.
- The prophet warned us.
- Nobody knows.

Those differences should go on to shape different decisions. A simulation in
which everyone reaches the same conclusion has thrown away the reason for having
interpretation at all.

---

## 48. Belief Accumulates From Interpretation

Religions and belief systems should be neither randomly generated nor picked
from a list by the player. A belief may form along:

```
Event → Interpretation → Repeated belief → Sharing
      → Followers → Tradition → Doctrine → Institution
```

**Do not build a religion system yet.** The foundations come first, and most of
them exist: knowledge, rumor, perception, interpretation, decisions, historical
memory. A religion system built before those are deep enough would have to
invent its own versions of all of them.

Note what this makes possible: **one real god can produce many religions.** The
same divine act may generate gratitude, fear, doubt, a rational explanation,
political exploitation and competing theology, with no second god required
anywhere. Disagreement about a god does not need more gods to disagree about.

---

## 49. Unanswered Questions Drive Culture

Societies may accumulate questions they cannot settle:

- Why do we die?
- Why does suffering exist?
- Why does God help some people and not others?
- What happens after death?
- Who has the right to rule?
- What makes someone a person?
- Is God still present?
- What makes an action moral?

Different people may hold competing answers, and the disagreement itself may
become the shape of a culture.

**Do not build a standalone Question System.** Questions should eventually be
represented through what already exists: knowledge topics, unresolved claims,
belief topics, competing interpretations.

---

## 50. Figures Emerge, They Are Not Placed

There should be no **Spawn Prophet** mechanic. Prophets, philosophers and
founders should arise when circumstances align — surviving an important event,
holding an unusual interpretation, curiosity, conviction, charisma, reputation,
social position, followers, relationships, a perceived divine experience.

**Their importance comes from whether other people believe and repeat them.** A
prophet nobody listens to is a person with an unusual opinion.

### Recorded tension: Divine Voice

Section 9's Divine Voice lists "prophet appears" among its possible results, and
the implementation sets a `mara_is_prophet` flag. That is the closest thing in
the game to placing a prophet directly.

It is closer to right than it looks: the same power also lists "message is
misunderstood", so the outcome is already contingent. The direction is to make
that contingency real rather than to remove the power — speaking through a
mortal should create the *opportunity* for prophethood, and whether it takes
should depend on who heard it and what they made of it.

---

## 51. Miracles Become Myths

An important event should be able to change as it is transmitted:

```
Event → Memory → Story → Myth → Doctrine
```

Objective event: the player saves one child during a flood.

- Later memory: "God saved the child."
- Later story: "The child was chosen by God."
- Later myth: "The child walked untouched through the flood."
- Later doctrine: "The First Prophet was protected by God from the waters."

**The engine retains the objective truth throughout.** Cultural memory drifts;
the record of what happened does not. This builds directly on the existing
knowledge and rumor architecture, which already carries confidence, distortion,
transmission count and an objective truth state the mortal cannot see.

---

## 52. Storage Changes Persistence, Not Truth

Cultural knowledge storage may eventually develop through oral memory, art and
symbols, writing, archives, and mass copying.

Better storage increases **persistence, reach and transmission reliability.** It
does not increase truth.

> **A written falsehood can outlive a true thing somebody once said.**

That asymmetry is the interesting part. Writing does not make a society more
correct; it makes it more consistent, including in its errors.

---

## 53. Records Preserve Perspectives

Four things that may all differ, and should be able to coexist:

**Objective event** — what happened.
**Witness knowledge** — what someone perceived.
**Recorded history** — what someone chose to preserve.
**Cultural memory** — what later generations believe.

Example. Objective: the player causes rain because crops are failing.

- Religious chronicle: "God answered the king."
- Royal record: "The king saved the nation."
- Common oral tradition: "The heavens returned."
- Later scholarly interpretation: "An unusual climate event occurred."

None of those is the event, and the simulation should hold all of them at once.
Note that the royal record is not a lie so much as a claim — which is what makes
it useful to whoever inherits it.

---

## 54. Institutional Memory

As societies grow more complex, belief and history may come to be preserved by
institutions: priesthoods, royal archives, schools, oral keepers, temples, legal
codes, sacred texts, philosophical traditions.

**Do not build these yet.** First make information itself able to persist,
distort, spread and change decisions. An institution is a thing that holds
information in a particular shape; without the information behaving properly, an
institution is a label.

---

## 55. What the Player Says Outlives Them

A clear divine statement should eventually become durable knowledge, and then
stop belonging to the player.

> "This valley will belong to your descendants."

That sentence may later affect migration, territorial claims, diplomacy, war,
succession, religion and legitimacy — long after the circumstances that prompted
it are gone.

The system should distinguish **the original statement** from **the remembered
version**, and let the two diverge.

**Anything the player says may be reused by anyone.** "Protect the weak" can
become:

| Who | What they take it to mean |
|---|---|
| Priest | We must provide charity |
| King | Subjects require our protection |
| General | We must conquer weaker neighbours, for their own safety |
| Rebel | The rulers are violating God's command |

The same is true of prophecy. "The prophet's child shall rule" may be read as a
literal son, direct descendants, spiritual descendants, symbolic successors, or
a claim invented later — and opposing factions may cite the same tradition
against each other.

**The player cannot control later interpretation.** This is the long-term
consequence of communicating at all, and it should be treated as one of the most
significant things a god can do.

---

## 56. The Cost of Divine Influence Is Consequence

Divine power should not primarily be balanced by an abstract resource. The
interesting cost is what the act does to the world:

- saving one region may harm another
- feeding a population may deepen future dependence
- preventing one disaster may create a different pressure
- repeated protection may encourage recklessness
- resurrection may transform what people believe about death
- guaranteed rescue may reduce local problem-solving

**The player should stay powerful. Power should not be consequence-free.**

### Recorded tension: Divine Power

Section 8 establishes Divine Power as a spending limit, and it is built and
working. This section says consequence, not cost, should be the *primary*
constraint.

Resolution: Divine Power stays. It is doing a real near-term job — pacing a turn,
forcing a choice between this year's problems, and making silence a live option
rather than a wasted move. What changes over time is emphasis: as consequences
become richer, the question the player weighs should shift from "can I afford
this?" toward "what will this become?". Neither replaces the other, and removing
Divine Power before consequences can carry that weight would leave nothing
constraining intervention at all.

**Do not implement intervention-cost mechanics.**

---

## 57. Repeated Help Creates Expectation

Repeated intervention should be able to change what people expect: stronger
faith, greater reliance, political claims of divine favour, reduced local
initiative, resentment when help stops, fear of punishment, greater willingness
to take risks.

It may also weaken independent development. Repeated food miracles reduce the
pressure that produces better farming; repeated protection reduces defensive
adaptation; repeated answers reduce independent inquiry.

**This is not a penalty.** Societies should differ. One may grow dependent;
another may treat divine help as breathing room and use it to build something.
Which happens should follow from traits, institutions, knowledge and history.

**Do not build a Divine Dependency meter.** No counter, no hidden slider. This
should emerge from what the world already records — historical precedent,
belief, knowledge, relationships, decisions. If it cannot emerge from those, the
answer is that those systems are not deep enough yet.

---

## 58. Silence Is an Act

Not intervening should be able to become historically meaningful.

**Do not build an "Age of Silence" mode.** Instead, people should eventually be
able to compare what they remember with what they are living through:

> Past: God usually intervened.
> Now: God no longer intervenes.

And reach different conclusions:

- God abandoned us.
- God is testing us.
- God is angry.
- God never existed.
- The old stories were exaggerated.
- We must solve our own problems.

Doing nothing is already a choice the game supports. It should also be a choice
the world can be *about*.

---

## 59. Saving Something Changes It

Preservation is itself an intervention and should alter what it preserves:

- a settlement repeatedly given aid becomes economically dependent
- a ruler repeatedly protected becomes politically untouchable
- a faction repeatedly rescued becomes reckless
- a population isolated for its protection develops beliefs and traditions
  unlike those it was separated from

> **Survival is not the same as preserving the previous state.**

What continues to exist because the player kept intervening is not what would
have existed otherwise, and the difference is a story rather than a failure.

---

## 60. Legitimacy Has Many Sources

A ruler's authority should rest on facts in the simulation rather than on a
single legitimacy score. Possible sources: ancestry, religious approval, popular
support, military support, legal or institutional recognition, achievements,
resource control, prophecy, succession custom, historical claims.

**Do not build a bar for each.** Prefer deriving political stability from state
that already exists — relationships, beliefs, settlement conditions, history.

Belief should be able to work in both directions. It can legitimise:

- the ruler is divinely chosen
- a prophet supports the ruler
- a sacred lineage
- a religious institution recognises a succession
- a victory read as divine favour

And it can dissolve:

> "The king has violated God's law."

That two-sidedness is what lets religion and politics entangle without any
particular political model being hardcoded.

---

## 61. History Is a Political Resource

Past events should not sit as flavour text. Actors should be able to reach for
them to justify rule, rebellion, war, land claims, religious authority,
succession, persecution and diplomacy.

An event becomes politically useful precisely when it is remembered imperfectly:
a fact everyone agrees on settles an argument, and a fact people remember
differently *is* the argument.

---

## 62. Religions Contain Disagreement

A religion should not behave as one unified object. It should be able to hold
disputed doctrines, competing interpretations, reform movements, traditionalists,
philosophers, and political factions using the same tradition for opposite ends.

> **One historical source can support opposing ideologies.**

This matters more than it sounds: a religion that cannot disagree with itself
cannot schism, and cannot be used — which removes most of what makes belief
interesting to a god who is watching.

---

## 63. Identity Comes From Remembered Events

Civilizations should develop identity from what happened to them rather than
from fixed culture tags. Surviving a flood, crossing mountains, receiving divine
aid, surviving famine, escaping persecution, winning a defensive war, settling a
promised homeland — any of these may become a founding story, a sacred memory, a
political identity, a tradition, or a territorial claim.

**Avoid culture selectors** such as Religious / Militaristic / Peaceful. Culture
should be a residue of history, not an attribute chosen at creation.

Migration should do more than move population. A large movement can create
founding myths, territorial claims, new relationships, new enemies, trade routes,
religious interpretation, cultural separation and mixed populations. Detailed
migration simulation remains future scope; what matters near-term is that
movement is capable of *meaning* something later.

---

## 64. Disasters Do Not Overwrite Society

A famine, plague, storm, migration wave or resource collapse must interact with
the society it lands on, never impose one generic response.

Faced with the same disaster, different societies may cooperate, hoard, migrate,
blame outsiders, turn toward religion, overthrow their leaders, exploit weaker
groups, send aid, isolate themselves, spread misinformation, or adapt
successfully.

Which happens should follow from what was already there: traits, institutions,
knowledge, relationships, needs, resources, history.

Existing belief should be part of that. A flood strikes a people who believe
their land was divinely promised to them; they may refuse to leave, read it as a
test, reinterpret the promise, blame their leadership, migrate behind a prophecy,
or lose faith. **The same physical pressure produces different histories.**

This is Section 34 at a larger scale. A disaster with one outcome everywhere is a
cutscene wearing a system's clothes.

---

## 65. Catastrophes Create History

A large disaster should normally open a new historical era rather than end the
simulation: migrations, population loss, political collapse, new factions, new
settlements, cultural change, changed beliefs, resource redistribution, new
alliances and rivalries, long-term memory.

A catastrophe can destroy much of a world while creating the conditions for
something else. The interesting question after a collapse is not whether the
player lost, but what grew in the gap.

Section 23 already establishes that there is no conventional Game Over and that
failure should generate history. The stronger form:

> **The worst thing that can happen to a world is not that it ends, but that it
> stops producing history.**

---

## 66. Civilization Stays Inside Nature

Political and cultural development must not make the environment irrelevant.
Mature civilizations still face disease, famine, predators, drought, floods,
resource shortage, environmental collapse and migration pressure.

**Civilization changes how a problem is handled. It does not remove the
problem.** Detailed ecology remains future scope.

---

## 67. Intelligence, Language, and Discovery

Long-term guidance only. **Do not build a biological intelligence system.**

**Intelligence and civilization are separate.** Culture must not appear because
an intelligence value crossed a threshold. Cultural development may instead
depend on breakthroughs: self-awareness, symbolic communication, naming, shared
memory, abstraction, teaching, social rules, institutions, recorded knowledge.
Biological intelligence and cultural intelligence are different things.

**Language creates concepts.** Naming lets a people cut reality into shared
pieces — home, enemy, death, god, justice, property, family, ruler, nation, law,
soul, duty. A future knowledge system may need to hold shared *concepts* and not
only factual claims. A society without a word for property cannot have a dispute
about it.

**Discovery should belong to the world, not the player.** As societies mature,
agriculture, husbandry, trade, transport, law, writing, political institutions
and military organisation should increasingly come from the people themselves.
The player must not remain the only source of progress.

**Discoveries should create chains, not bonuses.** Avoid technology as a flat
modifier:

```
Domestication → more reliable food → population growth
  → grazing pressure → changing land use → property matters
  → inequality → livestock theft becomes worthwhile
  → raiding changes → warfare changes
```

One discovery should be able to move many systems over time. Detailed economy
and ecology simulation remains future scope.

---

## 68. Ecological and Planetary Simulation

Recorded as long-term possibilities **only**: climate eras, migration pressure,
ecological change, species adaptation, extinction, behavioural adaptation,
protected refuges, artificial habitats, planetary causality, deeper biological
simulation.

**None of this is on the implementation roadmap.** It may be explored only after
the existing people, knowledge, decision and history simulation is proven fun.
Section 42's Autonomous Story Test is the gate, and it has not been passed.

**Worldsim is not becoming an evolution simulator.** Ecology, if it ever arrives,
arrives as pressure on societies — a reason for people to move, argue, believe
and decide — not as a subject in its own right. The moment a planetary system
stops producing human consequences it has failed Section 39 and should be cut,
however correct it is.

---

## 69. The Player Does Not See Every Belief

Future religious and ideological information need not be fully transparent. The
player might reliably see the dominant belief, major doctrines, public rituals
and known disputes, while some of what people actually think stays uncertain.

A society would then be learned partly by watching: behaviour, documents,
rituals, conversations, political decisions.

**Do not implement hidden-belief UI.** Recorded as future UX direction. Note that
this is a change from today, where player-facing belief is shown in full, and it
does not touch Developer Mode — Developer Mode shows the machine and always will
(Section 40).

---

## 70. No Additional Gods

**The player is the only actual god-level actor.**

Do not add rival gods, creator gods, competing divine entities, hidden deity
characters, or player-equivalent supernatural actors.

Mortals may misunderstand natural events, player actions, or each other as gods,
spirits or divine forces, and may build entire religions on that mistake. That is
the point of Sections 11, 12 and 48, and nothing here restricts it.

What must not exist is a second *real* god. The player's uniqueness is not a
balance decision: a world where any unexplained event might have been another
god's doing is a world where the player cannot be credited, blamed, or
understood.

Where outside research features multiple gods, take the underlying principles —
competing religions, conflicting origin stories, ideological division, differing
conceptions of divinity, the political use of religion — and leave the extra gods
behind. Every one of those effects is achievable with one god and many
interpreters, which is Section 48.

Section 17's emergent identities are interpretations mortals hold about the
player, never separate beings.

---

## 71. Development Priority Is Unchanged

The current priority stands exactly as Section 41 describes it:

```
Entities → Relationships → Knowledge and Rumors → Perception
  → Decisions → Events → Player Actions → Consequences
  → Historical memory
```

Nothing in Part III may reorder that. Interpretation is the important future
bridge — Section 46 — but stable systems must not be restructured for it before
the current foundation is proven.

Planetary, ecological and evolutionary systems sit behind all of it, and behind
the Autonomous Story Test.

If a Part III idea starts to feel urgent, that is a signal to finish the layer in
progress, not to reorder the list.

---

## 72. Scope Rule

> **Worldsim should simulate enough underlying reality to produce meaningful
> beliefs, decisions, relationships, consequences and history. It should not
> simulate complexity for realism's own sake.**

Before adding a subsystem, ask whether it creates meaningful:

- decisions
- interpretations
- relationships
- consequences
- history
- player choices

If not, it does not belong in Worldsim yet.

**Do not add complexity because it is realistic.** Realism is not a
justification. A system that models something correctly while producing nothing
anyone would notice is worse than the same system absent: it costs attention,
invites more of its own kind, and makes the interesting parts harder to see.

This restates Section 39's three questions as a rule for Part III specifically. A
proposed system that cannot answer them should be recorded here as a possibility
and left unbuilt.

---

## 73. Morality Is Made by Societies

Worldsim should not use one universal civilization-level **Good ↔ Evil** axis.
Moral frameworks should emerge from material life, history, institutions,
religion, hierarchy and survival pressure.

A hierarchical society may call obedience, loyalty and role-fulfilment good. A
freedom-focused society may value autonomy and resistance to coercion. A society
under constant existential pressure may treat preservation of the group as its
highest obligation.

These are not culture presets. They are conclusions societies reach about how
people *ought* to behave.

The player is not identical with morality. A divine act has an objective effect;
mortals supply the moral meaning. The same flood may be understood as punishment,
a test, cruelty, necessary sacrifice, or ordinary nature.

---

## 74. Crisis Attribution Turns Pressure Into Politics

A crisis does not only hurt. People ask **why it happened** and **who is
responsible**.

Possible attributions include a ruler, foreign group, minority, heresy,
environmental damage, social disorder, God, natural causes, themselves, or no
known cause.

The important chain is:

```
Crisis → Interpretation / Attribution → Response
```

A plague believed to be contagious may produce isolation. The same plague
believed to be divine punishment may produce ritual reform. Believed sabotage
may produce persecution or war. Believed royal incompetence may produce
rebellion.

**Do not hardcode a disaster response.** Existing belief decides what the crisis
becomes politically.

---

## 75. Public Claim, Private Belief, and Practice Can Diverge

An individual may eventually need three distinguishable layers:

- **Public claim** — what they say they believe.
- **Private belief** — what they actually hold to be true.
- **Practice** — what they actually do.

A king may publicly support an official religion while privately doubting it
because that religion legitimises the throne. A merchant may publicly follow a
local faith while privately adopting a foreign one because open conversion would
cost relationships or trade.

**Do not implement this now.** It is future direction for making belief social
rather than merely internal.

Conversion should likewise have causes, not a single strength contest. Possible
causes include witnessed events, marriage, political pressure, social advantage,
philosophy, fear, gratitude, trauma, conquest, belonging and genuine conviction.

---

## 76. Intelligence Does Not Guarantee Rational Behaviour

Cognitive capacity and collective rationality are different things.

A highly intelligent person or advanced society can still act through fear,
anger, loyalty, ideology, propaganda, misinformation, trauma and social
pressure. A less technologically developed society can still reach a sensible
conclusion from the information available to it.

Never encode:

> high intelligence → correct decision

Reason is a capability. It does not erase motive or belief.

This strengthens Section 33: false beliefs can create real history precisely
because intelligent people can reason coherently from bad premises.

---

## 77. Information Propagation Creates Social Distance From Truth

As societies grow, fewer people personally witness important events. They hear
about them through travellers, rulers, priests, messengers, merchants, rumors,
prophecies and documents.

Example:

```
Actual: a strange light descends over one village.
Village: "A divine messenger appeared."
Town: "The messenger warned of famine."
Capital: "God declared the king legitimate."
```

This is not a separate information engine. It is the long-term use of the
existing Knowledge / Rumor architecture plus Section 51's distortion and Section
52's storage rules.

Distance in a social network should eventually matter because every additional
handoff creates another opportunity for selection, omission and reinterpretation.

---

## 78. First Contact Is a Worldview Event

When Worldsim eventually supports multiple civilizations or rational species,
first contact should not be reduced to:

> Relations: Neutral

It may create biological shock, theological shock, philosophical challenge,
economic opportunity, disease risk, political fear, language problems and
cultural fascination at the same time.

A people who believe only they possess souls may have to respond when another
rational species appears. Possible responses include reinterpretation, denial,
reform, heresy, conversion, violence, accommodation or syncretism.

**First contact should attack assumptions as well as borders.**

This remains behind the roadmap gates for multiple kingdoms and additional
races in Section 41.

---

## 79. Different Origin Stories Need No Additional Gods

Different peoples may possess incompatible creation stories, sacred histories
and explanations of rational life without any of those stories being
objectively true.

A second civilization may sincerely believe another god created it. That belief
is cultural data, **not evidence that another god exists**.

The engine should preserve the difference between:

- objective origin
- remembered origin
- religious origin story
- political use of the origin story

This gives multi-species theology depth without violating Section 70.

---

## 80. Historical Individuals Are Hinge Points

Most citizens should remain abstract, as Section 14 already requires. But some
individuals become historically important because circumstances place them at a
junction where their action carries farther than normal.

Possible examples:

- first explorer
- first-contact intermediary
- prophet
- diplomat
- reformer
- ruler
- conqueror
- scientist
- survivor
- poet
- heretic
- assassin

Historical importance should be **earned by consequence**, not assigned because
a character was spawned as a hero.

The first person to meet an unknown people may bias relations for generations.
A kind encounter can become evidence that the outsiders are trustworthy; a
violent one can become the founding proof that they are monsters. The same two
civilizations can therefore develop completely different histories depending on
who met first.

---

## 81. Authority Comes From Competing Sources

Section 60 establishes that legitimacy has many sources. The stronger political
form is that **authority itself may be distributed**.

A civilization may recognise overlapping sources such as:

- royal authority
- religious authority
- legal authority
- popular authority
- military authority
- customary authority
- economic power
- historical legitimacy

Do not immediately turn these into eight bars. They should come from real
relationships, offices, beliefs, control and historical claims.

Religion and state can support each other or undermine each other. A priesthood
may confirm succession, or declare a ruler illegitimate. A ruler may control an
institution, or attempt to suppress it. A miracle believed to contradict the
king can move obedience away from the throne without the player ever clicking
"reduce royal authority".

---

## 82. Religious Claims Are Actions in Politics

Mortals may claim:

- God chose me.
- God ordered this war.
- God cursed our enemy.
- God gave us this land.
- God supports this ruler.
- God demands this law.

Such claims may be true, misinterpreted, fabricated, or impossible for mortals
to verify.

The player may know what they actually said or did. The population does not get
that access for free.

**Do not add a “correct religion” percentage.** Religions are mixtures of
remembered events, interpretation, values, doctrine and political use. One may
preserve a true event and draw a false conclusion; another may reject the event
but reach a moral rule the player approves of. Accuracy is claim-specific, not a
score attached to an entire religion.

---

## 83. Ideology Is Belief About How Society Should Work

Do not begin with a giant predefined ideology catalogue.

Treat ideology as the point where beliefs become normative:

- All rational beings are equal.
- Hierarchy is sacred.
- Kings rule by divine favour.
- Freedom is God's law.
- Order matters more than liberty.

Such ideas should grow from moral frameworks, historical experience, economy,
institutions, crisis attribution and religion.

A useful distinction:

> **Belief says what is true. Ideology says what society should do about it.**

Ideology belongs downstream of interpretation, not beside it as an unrelated
system.

---

## 84. Narrative Is History Used to Explain Identity

Do not build a standalone narrative generator first.

A social narrative is a connected interpretation of historical events that
explains who a group believes it is.

Example:

> "We survived because God chose us."

That narrative may influence identity, diplomacy, succession, war, migration,
religion and law.

The important progression is:

```
Event → remembered event → connected story → group identity → political use
```

Section 63's founding narratives are the early form of this. The new rule is
that narratives may be actively used against other narratives.

> **People can weaponize interpretation against each other.**

A genuine belief can be politically useful. A sincere prophet can be quoted by
later rulers. A true event can still become propaganda.

---

## 85. Reform Changes Institutions, Not Minds Instantly

A religious or ideological reform should not be:

> Religion upgraded.

A reform may change priesthood structure, accepted moral rules, relation to the
state, legal norms, membership rules, treatment of outsiders or doctrine.
Different regions and people may accept, reject, partially adopt, or combine the
change with older practice.

That naturally permits old faiths, reformed faiths, regional variants and
sects to coexist.

**Do not build a procedural reform engine yet.** First ensure belief, history and
institutions can differ without being overwritten globally.

---

## 86. Succession Is a Causal Chain, Not a Replacement Operation

A ruler's death should eventually ask more than who is next in a list.

Relevant conditions may include inheritance custom, legal recognition,
religious approval, army support, elite support, rival claimants, prophecy,
bloodline, foreign interference, assassination and remembered promises.

Example:

```
Prince assassinated
  ↓
Succession disputed
  ↓
Religious institution backs Claimant A
  ↓
Army backs Claimant B
  ↓
Civil war
  ↓
Neighbour intervenes
  ↓
Dynasty collapses
```

One death can reshape centuries because it connects to conditions already in the
world. That makes succession an application of Section 35's bounded ripple rule,
not a special scripted drama system.

---

## 87. Assassination Can Become a Historical Hinge

An important killing may affect legitimacy, martyrdom, rebellion, succession,
religion, foreign policy, myth and civil war.

The event itself remains objective: one person killed another. Everything after
that depends on who knew, who was blamed, what the victim represented, and what
political conditions were already unstable.

This is exactly the kind of event that deserves selective long-term memory under
Section 36.

---

## 88. Civilizations Are Allowed to End

A civilization is not a permanent map object that must be protected from
collapse.

Distinguish:

**Species / population survival** from **civilization / state survival**.

A kingdom can disappear while its people continue as successor states,
refugees, diaspora, conquered populations, nomads, religious communities or
regional cultures.

Collapse should therefore create continuity as well as loss.

This strengthens Sections 23 and 65: failure creates history.

---

## 89. Civilizations Have Descendants

A fallen state may produce several successors, each preserving a different piece
of the old order.

Example:

- Northern successor preserves the old religion.
- Eastern successor adopts foreign customs.
- Southern successor becomes a merchant state.
- Royal remnant retains the original dynastic claim.

All may sincerely claim:

> "We are the true continuation."

Those competing claims can become future diplomacy, legitimacy disputes,
religious arguments and wars.

Long-term, Worldsim should treat civilizations as historical processes that can
rise, fragment, reform, merge, migrate, collapse and continue culturally without
continuing politically.

---

## 90. Inclusion and Exclusion Are Historical Beliefs

Societies may classify outsiders in ways such as chosen people, accepted equals,
tolerated foreigners, lesser beings, dangerous others or abominations.

These categories must not be hardcoded racial truths. They are social beliefs
that can change through first contact, philosophy, reform, war, intermarriage,
shared disaster or the actions of famous individuals.

This keeps species difference from becoming a fixed morality table and gives
first contact somewhere to propagate socially.

---

## 91. Messages Change Through Mortal Intermediaries

Outside research may feature angels or lesser divine beings carrying messages.
Worldsim does **not** need those entities to gain the useful mechanic.

Use mortal intermediaries:

```
Player speaks
  ↓
Witness / prophet interprets
  ↓
Priest or ruler repeats
  ↓
Scribe records
  ↓
Population receives
```

Every handoff may preserve, omit, exaggerate or reinterpret part of the message.
The player can speak clearly and still lose control of what the world eventually
hears.

Do not add autonomous supernatural agents, angelic factions, divine bureaucracies
or heavenly politics.

---

## 92. The One-God Rule Is Stronger Than the Source Material

Research may contain minor gods, angels, divine covenants or multiple beings
called gods. Worldsim deliberately does not inherit that literal structure.

**The player remains the only actual god-level actor.**

Do not add:

- minor gods
- rival gods
- hidden creator gods
- divine factions
- divine diplomacy
- autonomous godlike agents
- player-equivalent supernatural entities

Mortals may invent any of those concepts. They may worship nonexistent gods,
misidentify creatures or natural phenomena, or claim that another being created
them. Those beliefs are allowed precisely because objective reality remains
separate from social truth.

The useful theme is not “many real gods.” It is:

> **Many people can build incompatible explanations around one reality.**

---

## 93. Four Truth Layers

Future social simulation should preserve four distinct layers where useful:

1. **Objective truth** — what actually happened.
2. **Social truth** — what a group currently accepts as true.
3. **Private belief** — what an individual personally believes.
4. **Public claim** — what the individual says publicly.

These layers may agree or conflict.

This is not a demand for four new databases. It is a conceptual requirement: do
not design future belief systems in a way that makes these distinctions
impossible.

---

## 94. Chapters 61–120 Do Not Change the Roadmap

Everything in Sections 73–93 is **future direction**.

Do not move morality, ideology, public/private belief, first contact, advanced
religion, succession, reform, successor civilizations or multi-species theology
ahead of the current dependency order in Section 41.

The near-term work remains the autonomous causal foundation. These ideas matter
now only because the existing architecture should avoid making them impossible
later.

Where possible, future behaviour should be derived from facts, perception,
interpretation, knowledge, relationships, history, intents, actions and
institutions rather than implemented as isolated special-case systems.

The rule from Section 72 applies especially strongly here:

> **Translate an interesting concept into Worldsim's causal architecture before
> creating a new subsystem for it.**

---

## 95. Long-Term Social Identity

The direction after Chapters 1–120 can be stated as one extended loop:

```
Reality happens once.
  ↓
Minds perceive only part of it.
  ↓
Minds interpret it differently.
  ↓
Shared interpretations become beliefs and narratives.
  ↓
Beliefs become norms, ideologies and institutions.
  ↓
Institutions and individuals make decisions.
  ↓
Decisions alter the world.
  ↓
History preserves competing versions of what happened.
  ↓
Later people inherit those versions and act again.
```

The player's special position is not that they control every layer. It is that
they are the only god and can act directly on reality while watching meaning
escape their control.

Preserve these internal principles:

> **The player controls what they do. They do not control what history says they
> did.**

> **The player changes the world. People decide what those changes mean.**

> **Reality happens once. History does not.**

---

## 96. Historical Forgetting Must Be Gradual and Legible

History may fade, fragment, and eventually be forgotten, but it must never feel
like the simulation randomly deleted data.

The intended long-term progression is gradual:

```
Living memory
  ↓
Recorded memory
  ↓
Traditional account
  ↓
Fragmented account
  ↓
Uncertain / contested account
  ↓
Forgotten
```

Important history should not jump abruptly from **known** to **gone** simply
because enough years passed.

A major event should leave intermediate traces as it weakens. For example:

- people remember the event directly while witnesses still live
- later generations know it through parents, teachers, ritual, or records
- later still, only institutions or regional traditions preserve it
- surviving accounts may become contradictory or incomplete
- eventually only inscriptions, ruins, phrases, rituals, names, or fragments may
  remain
- complete forgetting is possible only when the channels preserving the event
  are actually gone

### Records and belief decay separately

Evidence surviving and people believing it are different things.

A written record may survive for centuries after a population stops caring about
or believing it. Conversely, a story may remain widely believed after every
original record has disappeared.

Worldsim should therefore be able to produce states such as:

> **Widely believed, poorly evidenced.**

or:

> **Well documented, culturally forgotten.**

This strengthens Sections 52 and 53: preservation affects access to claims, not
the truth of those claims.

### Forgetting should have causes

Decay should depend on what actually preserves or damages a memory, not only on
time.

Factors that may preserve history include:

- living witnesses
- repeated teaching
- ritual repetition
- cultural importance
- connection to group identity
- writing and archives
- active institutions
- monuments or physical evidence

Factors that may accelerate loss include:

- death of witnesses
- failed transmission
- institutional collapse
- archive destruction
- war or disaster
- deliberate suppression
- language change
- competing narratives replacing attention

These are future design factors, not a request for a full memory-decay system
now.

### Rediscovery can reactivate old history

Forgotten or marginal history may become relevant again when evidence returns:

```
Event
  → Memory
  → Record / Tradition
  → Distortion
  → Fragmentation
  → Forgetting
  → Rediscovery
  → New Interpretation
```

A ruined inscription, reopened archive, recovered ritual, or excavated sacred
site may revive an old religious doctrine, political claim, territorial dispute,
or philosophical argument.

The rediscovered interpretation does not need to match the original one.
Rediscovery creates another perception-and-interpretation event in the present.

### Player trust rule

> **Historical forgetting must be gradual, visible, and causally explainable.
> The player should never feel that important history vanished because the
> simulation deleted it.**

When this system eventually exists, Developer Mode should be able to explain why
a memory weakened or survived — for example: the last witness died, an archive
was destroyed, a ritual kept the account alive, or only one regional tradition
still preserves it.

This is future direction only. It does not change the implementation roadmap in
Section 41.

---

## 97. Gameplay Presentation — Terminal Identity, Modern Mobile Navigation

Worldsim should keep the **terminal as its personality**, while using **modern
mobile-first information architecture** for navigation and readability.

The presentation target is not a pure terminal and not a generic management
dashboard. It is a hybrid:

> **The world speaks through a terminal. The player studies the world through a
> modern interface.**

References such as mobile life simulators and modern category-based web apps are
useful for interaction clarity: large touch targets, grouped categories, clean
cards, drill-down screens, readable hierarchy, and a clear "what needs attention"
entry point. These are usability references only; Worldsim should not copy their
visual identity, content structure, or scripted-event model.

### Two presentation layers

#### Play layer — atmospheric and event-focused

The main play screen remains the most terminal-like surface. It should focus on
what is happening **now**:

- current year and key world status
- recent or important events
- prayers and requests
- notable mortal actions
- emerging crises or opportunities
- concise interpretations when relevant
- divine actions available to the player
- Advance / continue control

The player should be able to open the game, understand the important situation,
make or decline an intervention, advance time, and leave without navigating a
complex management interface.

A situation may be presented as a focused event card or terminal panel, for
example:

```text
YEAR 126

WESTFIELD — FOOD CRISIS

Harvest stores have fallen below sustainable levels.
Mara has asked the capital for assistance.

KNOWN INTERPRETATIONS
> Mara: The capital can help.
> Aster King: The shortage is temporary.

PRAYERS
2 requests awaiting response.

[OBSERVE] [INTERVENE] [SPEAK] [IGNORE]
```

This is presentation only. The situation must still come from simulation state,
not from a fixed sequence of prewritten choice cards.

#### Information layer — modern, categorized, drill-down

When the player wants to understand the world more deeply, information should be
organized like a modern mobile app or compact webpage rather than a raw terminal
log.

Possible top-level categories:

- **World** — settlements, conditions, crises, population, map
- **People** — rulers, prophets, scholars, rebels, historical figures
- **Beliefs** — beliefs, religions, interpretations, disputes
- **History** — timeline, eras, major events, divine interventions, contested
  accounts
- **Divine** — prayers, player actions, promises, known names, how mortals
  interpret the player
- **Society** — institutions, authority, factions and ideology when those systems
  eventually exist
- **Developer** — objective truth and simulation internals

The exact categories are not locked. They should grow only when the underlying
simulation justifies them.

### Start Here / Needs Attention

A prominent entry area may summarize what deserves the player's attention now:

- worsening famine
- unanswered prayer
- ruler succession crisis
- new religious dispute
- important historical figure in danger
- newly discovered information

This should be a convenience layer, **not an objective list**. It must not tell
the player what they are supposed to solve. Section 38 still applies: the world
creates opportunities, not quests.

A situation may be marked as important because it has high consequence,
uncertainty, direct relevance to the player, or a pending request — never because
the UI decided that helping is the correct choice.

### Drill-down instead of information overload

Worldsim will eventually contain more information than should fit on one screen.
The player should move from summary → category → detail.

Example:

```text
HISTORY
  ↓
The Westfield Famine
  ↓
Year 126 · Major Event · Strongly Remembered
  ↓
Known interpretations / people involved / later consequences
```

Likewise, a Person card should show only the information that helps recognition
and decision-making first, with deeper beliefs, relationships, knowledge and
history available after opening the profile.

The normal UI should never require reading giant debug-style tables to play.

### Visual identity

Use modern layout logic without adopting a soft corporate dashboard aesthetic.
Worldsim should retain its own atmosphere through:

- dark or near-black surfaces
- off-white / gray primary text
- restrained terminal-style accent colors
- monospace or semi-monospace typography where readable
- thin borders and dividers
- sparse icons and symbols
- selective ASCII / terminal language
- minimal animation
- strong hierarchy through spacing rather than decoration

Cards and panels exist to organize information, not to turn every value into a
separate widget.

### Mobile-first interaction

The interface should be designed so the same conceptual structure works on a
phone:

- vertical navigation is acceptable
- touch targets should be generous
- important information should not depend on hover
- categories should open into focused screens rather than squeeze into many
  columns
- the player should be able to complete a meaningful observe / intervene /
  advance loop quickly

Desktop may show more panels simultaneously, but it should not require a
different game structure.

### Reference rule

The useful lesson from mobile life simulators is **clarity of interaction**, not
their event-generation model.

Worldsim must not become:

> prewritten card appears → choose A/B/C → next prewritten card

Instead:

> simulation creates a situation → UI packages it clearly → player chooses
> whether and how to respond → simulation continues

That distinction is load-bearing.

### Presentation principle

> **Warsim underneath; modern mobile usability in navigation; terminal identity
> in presentation.**

This section refines Sections 18 and 19. It does not change the simulation
roadmap in Section 41 and does not require immediate UI reconstruction.

---

## 98. Divine Action Economy — Attention, Precision, Prayer, and Delegation

The player should feel enormously powerful without being able to resolve every
mortal problem continuously. Divine limits should create **choice about where God
places attention**, not make God feel like an ordinary spellcaster waiting for
cooldowns.

The long-term divine interaction model has two visible action layers:

### Primary Divine Actions — persistent capabilities

Primary actions are things the player can deliberately reach for regardless of a
particular event being active. Their exact final vocabulary is not locked, but the
category should include capabilities such as:

- observe
- speak
- reveal
- bless
- curse
- protect
- create
- wait / remain silent

Where an action needs a target, the player should normally be allowed to choose
one: a known person, settlement, group, location, or other supported world
object. God should not be forced to bless a random person simply because the UI
surfaced one.

### Secondary Divine Actions — opportunities created by the world

Secondary actions exist only because the current simulation makes them
meaningful. A drought may expose **Send Rain**, a sickness may expose **Heal**,
a war may expose **Protect Army**, and a prayer may expose a response that would
not otherwise deserve its own permanent button.

These are not quest choices. They must be derivable from current state, events,
relationships, beliefs, requests, or targets.

> **Primary actions express what God can generally do. Secondary actions expose
> what the current world gives God a meaningful opportunity to do.**

### Divine search and attention

The world should not need thousands of fully simulated citizens merely so the
player can search for one interesting person.

A future **Find Person / Divine Search** interaction may let the player specify
criteria such as location, role, age, trait, belief, or other supported qualities.
For example:

> Find an adult in Westfield with very high honesty.

The engine should search already-instantiated people first. If the relevant
population is still abstract, it may surface a generated representative whose
attributes are valid for that population and satisfy the requested constraints.
Once God meaningfully interacts with that person, the person may become a
persistent tracked individual.

This is not retroactive creation of the requested trait. It represents God
placing precise attention on someone who can plausibly exist inside the abstract
population.

If no valid person can exist under the requested constraints, the game should say
so rather than fabricate an impossible combination.

### Divine Tokens — accumulated capacity for precision and great miracles

**Divine Tokens are not AI credits and are not payment for freeform text.** They
represent limited divine capacity for unusually precise, certain, large, or
reality-breaking intervention.

Tokens regenerate with game time and **unused Tokens accumulate**. They should
not normally expire at the end of a month or turn.

The exact regeneration rate, prices, and maximum reserve are deliberately not
locked yet. A prototype example such as ten Tokens per month may be useful for
balancing, but it is not a design constant.

Ordinary divine interaction should remain accessible enough that the player does
not become afraid to touch the world. Token cost should increasingly matter when
an intervention adds one or more of these properties:

1. **Precision** — forcing the effect onto an exact target or narrow condition.
2. **Scale** — affecting a large population, region, army, or physical area.
3. **Impossibility** — strongly violating the world's ordinary causal rules.

Examples of actions that may deserve meaningful Token cost include:

- finding a very specific kind of person through divine search
- blessing or cursing one exact target with unusual certainty
- deliberately killing one named person by divine action
- stopping a major disaster outright
- reshaping significant terrain
- resurrecting a specific dead person
- mass resurrection
- creating intelligent life
- creating a persistent supernatural servant such as an Apostle

A broad natural-looking intervention may sometimes cost less than an extremely
precise one. Causing rain over a farming region can be less demanding than making
rain fall on one exact individual while leaving everyone beside them untouched.

> **The more precise, large, or impossible the intervention, the more stored
> divine capacity it may require.**

### Accumulation enables impossible-scale miracles

Saving Tokens should be a legitimate play style. A player may remain relatively
quiet for years or decades, allowing unused divine capacity to accumulate for a
miracle far beyond ordinary intervention.

That creates a meaningful tradeoff. While the player saves:

- prayers may go unanswered
- people die
- crises resolve without God
- kingdoms change
- expectations of divine intervention change
- silence itself may acquire religious meaning under Section 58

The eventual miracle can therefore be mechanically enormous **and** historically
enormous.

A mass resurrection should not resolve as merely `Population +N`. It may change
beliefs about death, burial, war, salvation, prophecy, divine favour, political
legitimacy, and whether later generations expect the dead to return again.

> **Great miracles require stored divine capacity; their deeper cost is the
> history they create.**

This extends rather than cancels Section 56. Consequence remains the more
interesting long-term cost of divine power. Divine Tokens provide pacing and
scarcity; they do not replace consequence as the reason the player hesitates.
The earlier instruction in Section 56 not to implement intervention-cost
mechanics remains a near-term scope warning: this section records the intended
future shape and does not move a Token economy ahead of Section 41's roadmap.

### Prayer and wishes

Mortals should be able to pray, ask, beg, wish, or otherwise direct requests
toward God. **Hearing a prayer does not itself need to cost Divine Tokens.** The
cost comes from what the player chooses to do about it.

Requests may include:

- heal my child
- save our harvest
- send rain
- protect our village
- punish my enemy
- let me become ruler
- bring someone back from the dead
- give me a sign
- make another person love or obey me

The request states what the mortal wants. It does **not** grant the player a
button that bypasses Worldsim's causal rules.

The player may eventually respond by:

- granting the request directly when the requested effect is a valid divine act
- partially granting it
- answering in a different way
- communicating instead of changing reality
- ignoring it
- acting against the request

Token cost is based on the **actual divine intervention performed**, not on the
importance the praying mortal assigns to the wish.

For example, a parent praying for a sick child may be free to hear. Accelerating
recovery might be cheap; a certain miraculous cure might cost more; resurrecting
the child after death may require a far larger accumulated reserve.

A prayer such as:

> Make me king.

must not directly set the political outcome. God may bless the claimant, protect
them, reveal information, publicly support them, strike an opponent, or remain
silent. Whether the person becomes ruler remains a social and political result.

Likewise:

> Make her love me.

must not directly overwrite another mind. The player can communicate, create an
experience, bless circumstances, or refuse the request, but interpretation and
choice remain outside direct divine authorship.

### Prayer volume should become pressure, not busywork

As populations grow, the number of prayers may become enormous. The normal play
screen should therefore surface requests selectively:

- urgent prayers
- repeated or widespread prayers
- unusual prayers
- prayers connected to major events
- prayers from historically relevant people
- prayers whose consequences could be significant

A deeper Divine / Prayers category may allow browsing beyond the surfaced set.
The game should create the feeling that **many people want something from God**
without requiring the player to clear an inbox of thousands of requests.

Answered and unanswered prayer should feed history. Frequent answers may create
expectation, ritual, dependence, political claims, or more prayer. Long silence
may create doubt, intensified devotion, reinterpretation, or independent
problem-solving. Section 57 and Section 58 govern those consequences.

### Apostles — delegated divine agents

Far in the future, the player may spend a very large accumulated Token reserve to
**create an Apostle**: a persistent created servant capable of acting on God's
behalf.

An Apostle is **not a god**.

It may be supernatural, powerful, long-lived, immortal, winged, or later called
an angel by mortals, but it remains a created entity operating inside the world.
It is never equal to the player and does not weaken Sections 70 and 92.

The player may give an Apostle a standing directive such as:

- protect this bloodline
- watch over Westfield
- spread this message
- find people with a particular quality
- protect persecuted followers
- warn me when a specified condition appears

An Apostle should then pursue that directive through actions inside the causal
simulation. Delegation must not become a hidden cheat that guarantees the desired
outcome.

Long-term conceptual chain:

```
Player gives directive
  ↓
Apostle interprets current conditions
  ↓
Apostle forms intent / chooses action
  ↓
Action creates objective consequence
  ↓
Mortals perceive the Apostle or its actions
  ↓
Interpretation / belief / history
```

An Apostle can therefore act intelligently while still producing unintended
consequences. "Protect my followers" might cause one Apostle to shelter a rebel
movement because those rebels satisfy the directive. The player gave the higher
purpose; the player did not manually choose every execution.

Apostles need not be written as disloyal or destined to rebel. The important
uncertainty can come from **interpretation and execution of instructions**, not
from mandatory betrayal.

The player may eventually constrain an Apostle's authority — for example which
powers it can use, whether lethal action is permitted, where it may act, or how
much autonomy it has. These details are future design questions, not current
systems.

Mortals remain free to interpret the created being however they like:

- angel
- God's child
- messenger
- prophet
- demon
- God in another form
- unknown creature

Those labels are social beliefs. Objectively, the Apostle remains created life
serving the one actual God: the player.

> **God may delegate action, but not authorship of meaning.**

### Player-facing principle

The final divine-power model should aim for this feeling:

> **God can always pay attention. God can often intervene. God cannot intervene
> everywhere with perfect precision all the time. Patience can accumulate into
> miracles that reshape history.**

This section is future direction. It does not add Divine Tokens, prayer
aggregation, population search, Create Life, or Apostles to the current
implementation roadmap. Section 41 remains authoritative.