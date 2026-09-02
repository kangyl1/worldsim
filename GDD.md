# WORLDSIM — GAME DESIGN DOCUMENT
## Version 0.1 — Prototype Scope

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

Those stories are the product.

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
