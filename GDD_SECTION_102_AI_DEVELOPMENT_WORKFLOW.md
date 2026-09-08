# WORLDSIM — GDD SECTION 102
## AI-Assisted Development Workflow

**Status:** Approved development-process direction.

This document is an addendum to `GDD.md` and should be treated as **Section 102** of the Worldsim GDD. It governs how AI tools are used to design, implement, review, and maintain Worldsim. It does **not** change any game rule, simulation dependency, scope lock, or implementation order in Section 41.

The purpose is simple: use each tool for the work it is best at instead of making every model do every job.

---

## 102. AI-Assisted Development Workflow

Worldsim should use a three-role workflow:

```text
YOU — Game Director / Final Authority
  ↓
GPT-5.6 Sol — Design, system reasoning, review, specifications
  ↓
CLAUDE CODE — Primary day-to-day implementation agent
  ↓
GPT-6 Astra — Heavy architecture / large refactors / difficult end-to-end work
  ↓
SOL REVIEW
  ↓
YOU — Approve, reject, revise, continue
```

The tools are not interchangeable. The project should deliberately assign different kinds of work to different agents.

### 102.1 Player / creator role

The creator remains the final authority over Worldsim.

AI tools may:

- propose
- critique
- implement
- test
- refactor
- document
- identify risks

They do not decide the game's identity independently.

Major design choices should still be explicitly approved by the creator before they are treated as locked design.

### 102.2 GPT-5.6 Sol — design and review role

GPT-5.6 Sol is the preferred tool for reasoning about what Worldsim should become.

Use it for:

- system design
- mechanic comparison
- finding contradictions in the GDD
- challenging weak ideas
- deciding simulation rules
- architecture discussion before implementation
- scope control
- identifying dependencies
- turning approved ideas into precise implementation specifications
- reviewing Claude Code or Astra output
- deciding what should be worked on next

Typical examples:

- Should Commandments be treated as communication or forced rules?
- How should belief interact with Perception and Knowledge?
- Does a proposed system create meaningful history or only extra simulation complexity?
- What is the smallest implementation that proves the mechanic works?

Sol should normally answer **what should be built and why** before another tool is asked to build it.

### 102.3 Claude Code — primary implementation role

Claude Code is the default day-to-day coding agent for Worldsim.

Use it for the majority of normal implementation work, including:

- reading the repository
- implementing approved features
- editing multiple related files
- adding or updating tests
- running tests
- debugging ordinary regressions
- updating comments and documentation
- keeping implementation aligned with the GDD
- reporting files changed and behaviour added

Typical examples:

- add one new action primitive
- extend Perception with an approved observability rule
- expose a new Developer Mode section
- implement a small Commandment prototype after the design is locked
- add deterministic tests for an existing simulation rule

Claude Code should remain the **primary engineer** unless the task clearly exceeds normal implementation scope.

### 102.4 GPT-6 Astra — escalation role

GPT-6 Astra should be reserved for unusually difficult development work rather than used for every task.

Use Astra when a change is likely to require substantial cross-system reasoning, such as:

- major architectural restructuring
- large refactors touching many interconnected systems
- difficult repository-wide bugs
- migrations where old behaviour must remain compatible
- changes spanning many files and simulation layers
- end-to-end feature work where implementation, tests, integration, and cleanup must all be coordinated
- deep audits of the repository and GDD for structural problems

Example:

A small Commandment prototype belongs with Claude Code.

A later Commandment system that simultaneously requires changes to:

- Knowledge
- Perception
- Interpretation
- Intent
- Execution
- Consequences
- Relationships
- Events
- Historical Memory
- Developer Mode
- persistence

may justify escalation to Astra.

Astra should therefore be treated as a **heavy-duty implementation / architecture agent**, not as the default answer to every coding problem.

Availability, model names, limits, and subscription access may change over time. The durable rule is the role split: **design/review → normal implementation → heavy escalation**.

### 102.5 Default task-routing rule

Use the smallest tool capable of doing the job well.

```text
Design question?
  → Sol

Approved normal implementation?
  → Claude Code

Large interconnected implementation or refactor?
  → Astra

Implementation finished?
  → Sol review

Design or implementation decision still uncertain?
  → Return to creator
```

Do not escalate a task simply because a stronger model exists.

A tool change adds coordination cost. If Claude Code can safely implement the feature, keep the work there.

### 102.6 Example — Divine Commandments

Recommended workflow for Section 101:

```text
1. Creator decides the desired player fantasy.

2. Sol designs the Commandment rules and checks them against
   Knowledge, Perception, Intent, Execution, Consequence and History.

3. Sol produces a strict implementation contract.

4. Claude Code builds the smallest viable Commandment version,
   updates tests, and reports the result.

5. Sol reviews the implementation against the GDD.

6. Creator approves or revises it.

7. Astra is introduced only if Commandments later require a
   substantial simulation-foundation refactor.
```

This prevents Worldsim from turning every design discussion into immediate code and prevents a powerful coding model from implementing a poorly defined mechanic extremely well.

### 102.7 Repository discipline

AI-assisted development must preserve the existing Worldsim repository workflow.

Before coding, the implementation agent should:

- read the relevant GDD sections
- inspect the current implementation rather than assuming architecture
- reuse existing systems where possible
- avoid parallel duplicate systems
- preserve deterministic and explainable simulation behaviour where already established

After coding, the implementation agent should:

- run the relevant tests
- report failures honestly
- state what files changed
- state what behaviour changed
- identify unresolved design questions separately from implementation bugs
- avoid silently expanding scope

### 102.8 Commit and push rule

The creator controls when work is pushed.

The normal workflow remains:

```text
Implement
  ↓
Report result
  ↓
Ask whether to push
  ↓
Push only after approval
```

Do not treat successful tests as automatic permission to push unrelated or newly expanded work.

### 102.9 CLAUDE.md role

`CLAUDE.md` should remain the repository-facing implementation guide for Claude Code.

It should point back to the GDD as the design authority and contain practical repository rules, coding constraints, testing expectations, and current implementation guidance.

The GDD answers:

> What is Worldsim supposed to be?

`CLAUDE.md` answers:

> How should an implementation agent work safely inside this repository?

Do not duplicate the entire GDD into `CLAUDE.md`.

### 102.10 Final development principle

> **Use Sol to decide what deserves to exist. Use Claude Code to build most of it. Use Astra when the engineering problem becomes genuinely large. Then review the result before moving on.**

The goal is not to use the most powerful model as often as possible.

The goal is to keep Worldsim coherent while increasing development speed.
