# WORLDSIM — GDD SECTION 101
## Divine Commandments and the Full God-Action Vocabulary

**Status:** Approved future design direction.

This document is an addendum to `GDD.md` and should be treated as **Section 101** of the Worldsim GDD. It extends Sections 43, 44, 55, 70, 91, 98, 99 and 100. It does **not** alter the implementation order in Section 41.

---

## 101. Divine Commandments and the Full God-Action Vocabulary

Worldsim should allow the player to behave as an active god through more than miracles alone. **Commandments are an approved Primary Divine Action**, alongside the other ways God can communicate with or alter the world.

The important distinction is:

> **God may state what should be done. God does not directly author mortal obedience.**

A commandment is an explicit divine instruction. It enters the same causal simulation as every other divine act rather than becoming a global rule that forces behaviour.

### Full divine-action direction

The long-term divine vocabulary may include:

- **Commandment** — explicitly state a rule, prohibition, duty, value, or instruction.
- **Sign / Omen** — communicate indirectly through an ambiguous event or symbol.
- **Revelation** — give knowledge or a message to selected mortals.
- **Blessing** — improve conditions, capability, fortune, protection, or opportunity.
- **Curse / Punishment** — deliberately impose harm, loss, restriction, or danger.
- **Miracle** — directly alter reality beyond ordinary expectation.
- **Chosen / Favor** — deliberately mark, support, or repeatedly favour a person, lineage, group, settlement, or other valid target.
- **Silence** — deliberately refrain from answering or intervening.

These categories are not required to become eight isolated subsystems. They describe player-facing ways of acting. Underneath, they should reuse Worldsim's existing event, perception, knowledge, interpretation, intent, action, consequence, memory, and history architecture wherever possible.

### Commandments are communication, not mind control

A commandment such as:

> Protect the innocent.

must **not** resolve as:

`all_mortals.obey("protect_the_innocent")`

Instead, the original divine statement becomes an objective event/message that can enter the world:

```text
God issues commandment
  ↓
Who receives or perceives it?
  ↓
What do they believe God actually said?
  ↓
What do they think the words mean?
  ↓
Do they accept God's authority?
  ↓
What intent does that interpretation create?
  ↓
What action do they attempt?
  ↓
What actually happens?
  ↓
How do other people perceive those actions?
  ↓
Doctrine / law / dispute / ritual / rebellion / history may emerge
```

Mortals may:

- obey
- partially obey
- refuse
- misunderstand
- reinterpret
- argue over meaning
- selectively apply the commandment
- claim somebody else violated it
- use it to justify political authority
- use it to challenge political authority
- turn it into law or custom
- preserve only part of it
- distort it through transmission
- forget it
- rediscover an older version later

None of these outcomes should be guaranteed merely because God spoke.

### The original commandment remains objective truth

Worldsim should preserve a difference between:

1. **Original divine statement** — what the player actually said.
2. **Received statement** — what a witness thinks they heard.
3. **Remembered statement** — what survives in memory or record.
4. **Interpretation** — what someone thinks the statement means.
5. **Doctrine / social truth** — what a group later accepts it to mean.
6. **Public use** — how people quote or weaponize it in society.

The original statement should never silently mutate in the engine. Mortal versions may.

Example:

Original:

> Protect the weak.

Later interpretations may include:

- Priest: provide charity to people in need.
- King: rulers are obligated to protect their subjects.
- General: weaker neighbours should be conquered so they can be protected.
- Rebel: the ruler has violated God's command by exploiting the poor.
- Scholar: the ancient phrase referred only to one historical crisis.

The player owns the first sentence. The simulation owns what happens to it afterward.

### Commandments can become durable cultural objects

A miracle normally begins as an event. A commandment begins as a **statement capable of persisting**.

Over time it may become:

```text
Divine Statement
  ↓
Witnessed Teaching
  ↓
Repeated Teaching
  ↓
Tradition
  ↓
Doctrine
  ↓
Law / Ritual / Institution / Ideology
  ↓
Dispute / Reform / Schism / Political Claim
```

This should not happen automatically. Persistence depends on transmission, memory, records, institutions, importance, repetition, political usefulness, and historical circumstances as those systems eventually exist.

A commandment may also die out completely.

### Commandment creation — approved hybrid direction

The approved long-term interface is **structured composition plus optional free text**.

The structured system should come first because the simulation needs machine-readable meaning it can reliably reason about.

A future structured commandment might be assembled from concepts such as:

- obligation / prohibition / permission
- action or principle
- target class
- condition
- exception
- scope

Illustrative examples only:

```text
PROTECT → CHILDREN
DO NOT HARM → SURRENDERED ENEMIES
HONOUR → THE DEAD
SHARE → FOOD → DURING FAMINE
DO NOT WORSHIP → RULERS
```

The exact grammar is **not locked**.

Optional free-text expression may later let the player phrase the same commandment naturally, for example:

> Let no surrendered enemy be killed.

Free text must not become a separate magic system. Where possible, it should resolve onto structured semantic content so the simulation knows what concepts mortals are interpreting.

> **Structured meaning is authoritative for simulation. Free text is the player's expression of that meaning.**

Do not make AI-generated prose a requirement for this mechanic to function.

### Commandment scope — approved

The player should eventually be able to choose who receives the original divine communication, subject to supported world targets.

Potential scopes include:

- **Individual** — one named person.
- **Group** — a family, faction, religion, institution, army, profession, or other supported group.
- **Settlement** — one local population.
- **Civilization** — one kingdom or civilization.
- **Universal** — everyone God chooses to address.

Scope controls **initial delivery**, not permanent ownership of the message.

A commandment given privately to Mara can later spread to an entire civilization if Mara tells others and people believe her. A universal commandment can later fragment into incompatible local traditions.

The same words delivered at different scopes should be capable of producing different histories.

### Wider revelation does not guarantee uniform understanding

A civilization-wide or universal commandment should not bypass perception and interpretation merely because God chose a broad scope.

Greater divine precision may make it clearer that a message came from God, but it must not guarantee agreement about:

- what the words mean
- how they apply to a new situation
- which rule takes priority when commandments conflict
- whether a historical exception still applies
- who has authority to interpret the commandment

A perfectly heard sentence can still create centuries of disagreement.

### Commandments can conflict with later divine behaviour

The player is allowed to contradict, amend, clarify, revoke, ignore, or appear to violate an earlier commandment.

The simulation should not silently reconcile this for mortals.

Example:

Earlier commandment:

> Do not kill prisoners.

Years later, God destroys a captured enemy leader.

Possible mortal conclusions include:

- the commandment has an exception
- God may do what mortals may not
- the old commandment was misunderstood
- the victim was not truly a prisoner
- God contradicted God's own law
- the new act supersedes the old commandment
- the event was not divine
- the priesthood has been lying about the original words

That contradiction is not necessarily a design error. It is material for interpretation and history.

### Commandments can be weaponized without being false

A person does not need to fabricate scripture to use it politically.

A true commandment may be sincerely interpreted and still become a political weapon.

Example:

> Protect the weak.

A rebel movement may use the authentic commandment as evidence against a ruler. The ruler may use the exact same commandment to argue that rebellion endangers the weak and must be suppressed.

This directly extends Sections 61, 82, 83 and 84: history and belief are political resources.

### Relationship to Divine Tokens

Commandments are not automatically expensive simply because they are important.

Their eventual divine cost, if any, should follow Section 98's existing logic:

- **precision**
- **scale**
- **impossibility**

Speaking privately to one person and unmistakably addressing an entire civilization may therefore carry different costs.

The exact prices are not locked.

The more important long-term cost remains consequence: what the world does with God's words.

### Relationship to Signs, miracles, and silence

Commandments should work best because they coexist with less explicit forms of divine behaviour.

God may say:

> Protect Westfield.

Then later:

- bless Westfield
- allow Westfield to fall
- strike somebody attacking Westfield
- save one child but not the settlement
- remain silent
- issue a new commandment

Mortals can compare **what God said** with **what God later did**.

This allows theology and divine identity to emerge from both explicit instruction and observed precedent.

A commandment is therefore not the whole religion system. It is one source of evidence inside it.

### Design law

The divine gameplay direction can be summarized as:

> **God can command, signal, reveal, bless, punish, perform miracles, choose favourites, or remain silent. Every one of those enters a world of autonomous interpreters.**

And specifically for commandments:

> **God controls the message. Mortals control whether, how, and why they live by it.**

### Scope status

This section records approved long-term direction only.

It does **not** move Commandments, free-text interpretation, doctrine generation, religious law, institutions, schisms, Divine Token balancing, or universal revelation ahead of Section 41's current implementation order.

When Divine Actions are integrated into the causal pipeline, the first commandment prototype should favour a **small structured vocabulary and limited target scopes** over a large language-generation system.

The purpose of the first implementation will be to prove one thing:

> **Can one clear instruction from God produce multiple understandable mortal responses without scripted outcomes?**
