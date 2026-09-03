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

### Immediate Consequence

Actions change the world locally first.

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
| 7 | Mortal Action Execution | **Next** — nothing is attempted yet |
| 8 | Consequence Engine | |
| 9 | Minimal Settlement State | |
| 10 | Event → Perception → Knowledge pipeline | |
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
