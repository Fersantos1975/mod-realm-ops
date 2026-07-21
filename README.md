# RealmOps

> **Inspect. Diagnose. Resolve.**

**RealmOps** is an operational diagnostics platform for **AzerothCore** that helps administrators inspect, understand, troubleshoot, and resolve gameplay and server issues.

Unlike traditional Game Master tools that focus on executing commands, RealmOps focuses on answering a more important question:

> **Why?**

---

# Why RealmOps?

Every server administrator has encountered situations like these:

- Why can't this player enter Icecrown Citadel?
- Why isn't this quest available?
- Why can't this spell be learned?
- Why isn't this NPC spawning?
- Why did this achievement fail to complete?
- Why can't this event start?

Finding the answer often requires checking databases, searching logs, reading source code, or executing multiple GM commands.

RealmOps brings that information together into one place.

Instead of forcing administrators to investigate blindly, RealmOps explains **why** something happens and provides the information needed to resolve it.

---

# Philosophy

RealmOps is built around three simple principles.

## 🔍 Inspect

Collect relevant information from the server.

## 🧠 Diagnose

Analyze the collected information and explain why something happens.

## ✅ Resolve

Present clear findings and recommendations that help administrators solve the problem.

Every feature in RealmOps follows these three principles.

---

# What RealmOps Is

RealmOps is an operational toolkit designed specifically for AzerothCore.

It combines diagnostics, inspections, and reporting into a single platform that helps administrators understand the state of their server.

RealmOps focuses on information rather than commands.

Its purpose is not to replace Game Master tools.

Its purpose is to make Game Masters more effective.

---

# Current Inspectors

Current functionality includes:

- Quest Inspector
- Instance Inspector

---

# Planned Inspectors

RealmOps is designed as a platform that can grow over time.

Planned inspectors include:

- Character Inspector
- Reputation Inspector
- Achievement Inspector
- Spell Inspector
- NPC Inspector
- Item Inspector
- Account Inspector
- Guild Inspector
- Mail Inspector

Each inspector follows the same design philosophy and user experience.

---

# Diagnostics

Inspectors are powered by reusable diagnostics.

Diagnostics investigate individual aspects of the game and explain their findings.

Examples include:

- Eligibility Diagnostics
- Lockout Diagnostics
- Quest Requirement Diagnostics
- Reputation Diagnostics
- Achievement Diagnostics
- Spell Requirement Diagnostics

This modular design keeps RealmOps consistent and extensible.

---

# Reports

RealmOps can present findings in a structured format.

Reports are designed to provide administrators with clear, organized information that can be shared, exported, or used during troubleshooting.

Future versions will include export capabilities and improved reporting options.

---

# Design Principles

RealmOps follows a small set of principles that guide every feature.

- Explain instead of guessing.
- Investigate instead of assuming.
- Keep diagnostics reusable.
- Maintain a consistent user experience.
- Prefer clarity over complexity.
- Build features that solve real operational problems.

Every new feature should help administrators understand their server better.

---

# Documentation

If you're new to RealmOps, we recommend reading the documentation in the following order.

| Document | Purpose |
|----------|---------|
| 📖 README | What is RealmOps? |
| 🎯 VISION | Where is the project going? |
| 📜 MANIFESTO | Why does RealmOps exist? |
| 🗺 ROADMAP | What comes next? |
| 🤝 CONTRIBUTING | How can I help? |
| 🏗 ARCHITECTURE | How is RealmOps built? |

---

# Compatibility

RealmOps currently supports:

- AzerothCore
- Wrath of the Lich King (3.3.5a)
- Playerbots

Support for additional modules may be added in future releases.

---

# Roadmap

RealmOps is under active development.

Current priorities include:

- Character Inspector
- Shared Diagnostics Framework
- Shared Report Engine
- Unified Inspector Architecture
- Export Framework

See **ROADMAP.md** for additional details.

---

# Contributing

Contributions are always welcome.

Whether you're reporting bugs, suggesting ideas, improving documentation, or writing code, every contribution helps improve RealmOps.

Before contributing, please read **CONTRIBUTING.md**.

---

# Project History

RealmOps began as **AAC – Instance Audit**, a module created to simplify instance eligibility diagnostics.

As development progressed, the project expanded beyond instance diagnostics into a broader operational toolkit capable of inspecting many different aspects of an AzerothCore server.

This evolution became **RealmOps**.

---

# License

RealmOps is released under the **GNU General Public License v3.0**.

See the LICENSE file for details.

---

# Motto

> **Inspect. Diagnose. Resolve.**
