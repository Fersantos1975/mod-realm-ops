# RealmOps Roadmap

> This roadmap describes direction and maturity, not guaranteed delivery dates.

RealmOps is developed around operational needs, framework stability, and test results. Priorities may change when AzerothCore compatibility, architecture, or real-world usage reveals a better order of work.

---

## Maturity Levels

| Status | Meaning |
|---|---|
| 🟢 Stable | Implemented and considered dependable for the current development stage |
| 🟡 Active Development | Currently being designed, implemented, or tested |
| 🔵 Planned | Accepted direction, but not yet implemented |
| ⚪ Exploration | An idea requiring validation before it becomes planned work |

A feature listed as stable may still receive fixes and improvements.

---

## Current Foundation

### 🟢 Project Identity

- RealmOps name and purpose
- Motto: **Inspect. Diagnose. Resolve.**
- Repository structure
- Project documentation
- Initial module and addon packaging
- Version and protocol identification

### 🟢 Quest Inspector

Current foundation includes quest-focused inspection capabilities developed from the original module.

Ongoing improvements may include:

- clearer eligibility explanations
- quest-chain context
- requirement summaries
- starter and ender information
- status consistency
- better report formatting

### 🟢 Instance Inspector

Current foundation includes instance and lockout-focused diagnostics.

Ongoing improvements may include:

- clearer access blockers
- group and raid eligibility summaries
- lockout explanations
- instance-state details
- consistent handling of unsupported cases

---

## Active Development

### 🟡 RealmOps Identity and Documentation

- complete project documentation
- consistent terminology
- cross-links between documents
- accurate feature descriptions
- installation and testing guidance
- real screenshots after the addon is running

### 🟡 Shared Diagnostic Framework

Goal: define a reusable model for diagnostic checks.

Expected responsibilities:

- diagnostic identity
- status or severity
- summary
- supporting evidence
- blocking and non-blocking outcomes
- consistent formatting
- predictable error handling

### 🟡 Shared Inspector Framework

Goal: provide a common structure for all Inspectors.

Expected responsibilities:

- Inspector registration
- input validation
- diagnostic execution
- report creation
- consistent lifecycle
- compatibility with the addon protocol

### 🟡 Character Inspector

Goal: provide a central operational view of a character.

Potential areas include:

- identity and basic state
- quests
- reputations
- achievements
- spells
- instance and raid state
- group context
- diagnostic summaries

The first version should remain focused and should not attempt to expose every character value.

---

## Planned Inspectors

### 🔵 Reputation Inspector

Questions it should help answer:

- What is the character's current standing?
- Which reputation requirement is blocking content?
- What source or rule requires the standing?
- Is the required faction or threshold identifiable?

### 🔵 Achievement Inspector

Questions it should help answer:

- Has the achievement completed?
- Which criteria remain incomplete?
- Is progress stored and visible?
- Is an expected condition missing?

### 🔵 Spell Inspector

Questions it should help answer:

- Does the character know the spell?
- Is the spell learnable?
- Which level, skill, class, race, quest, or prerequisite blocks it?
- Is a trainer or source relevant?

### 🔵 NPC Inspector

Questions it should help answer:

- Does the creature exist in the expected context?
- Is it spawned, phased, or event-controlled?
- Which conditions affect visibility or behavior?
- Is the NPC associated with quests, gossip, or events?

### 🔵 Item Inspector

Questions it should help answer:

- What is the item's source and intended use?
- Which requirements affect use or acquisition?
- Is it tied to a quest, spell, class, level, or reputation?
- Does the character currently possess or qualify for it?

---

## Platform Work

### 🔵 Report Framework

Goal: organize Inspector findings consistently.

Planned concepts:

- report title and context
- observations
- passed checks
- warnings
- findings
- blockers
- errors
- supporting evidence
- optional recommendations

### 🔵 Export Framework

Goal: allow diagnostic results to leave the immediate addon view in a controlled format.

Potential formats may include:

- copyable plain text
- structured addon output
- saved variables
- future machine-readable formats

Export capabilities will be added only after the report structure is stable.

### 🔵 Protocol Improvements

- shared protocol versioning
- compatibility checks
- clear unsupported-version messages
- stable message structure
- safer handling of partial or malformed responses

### 🔵 User Interface Consistency

- shared Inspector layout
- consistent controls and status presentation
- filters and search
- improved minimization behavior
- settings integration
- clearer empty, loading, and error states

### 🔵 Testing and Compatibility

- repeatable manual test plans
- AzerothCore update checks
- Playerbots integration checks
- protocol regression testing
- module and addon version verification
- known-issues documentation

---

## Exploration

The following ideas are not commitments.

They require evidence that they solve real RealmOps problems without expanding the project beyond its purpose.

### ⚪ Character Comparison

Compare selected diagnostic state between two characters.

### ⚪ Group Diagnostics

Summarize shared blockers and differences across a party or raid.

### ⚪ Saved Diagnostic History

Retain selected reports for later comparison or support.

### ⚪ Web-Friendly Reports

Produce reports suitable for viewing outside the game.

### ⚪ External API

Expose selected diagnostic capabilities through a controlled interface.

### ⚪ Remote Monitoring

Provide limited operational information without requiring an in-game session.

These ideas will not move to planned status until their scope, security, maintenance cost, and operational value are understood.

---

## Out of Scope

RealmOps is not currently planned to become:

- a complete Game Master command suite
- a database editor
- a general web administration panel
- an unattended automatic repair system
- a replacement for server logs or debugging tools
- a collection of unrelated convenience features

---

## How Priorities Are Chosen

Work should be prioritized using these questions:

1. Does it answer a real administrator question?
2. Is the required server information available?
3. Can the result be explained reliably?
4. Can the capability be reused?
5. Does it fit the RealmOps architecture?
6. Can it be tested?
7. Does it improve understanding without creating unsafe side effects?

---

## Near-Term Focus

The immediate direction is:

1. complete the core documentation
2. verify the current module and addon baseline
3. define the shared Diagnostic model
4. define the shared Inspector structure
5. begin the Character Inspector
6. improve reporting consistency
7. capture real screenshots after the UI is running

---

## Release Direction

The following names describe development stages and may be refined as implementation progresses.

### 0.1.x — Foundation

Original instance and quest audit capabilities.

### 0.2.x — Identity

RealmOps naming, purpose, documentation, terminology, and repository organization.

### 0.3.x — Character

Shared foundations and the first Character Inspector capabilities.

### 0.4.x — Expansion

Additional Inspectors and broader reusable Diagnostics.

### 1.0.0 — Stable Platform

A documented, tested, and maintainable RealmOps platform with a stable user-facing foundation.

No date is promised for 1.0.0. Stability will be based on quality, not the calendar.

---

## Contributing to the Roadmap

Feature proposals are welcome.

A useful proposal should explain:

- the operational question
- the affected administrator workflow
- the evidence RealmOps can inspect
- the expected diagnosis
- the value of the result
- possible risks or side effects

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidance.
