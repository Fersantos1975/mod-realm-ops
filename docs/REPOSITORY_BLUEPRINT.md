# RealmOps Repository and Migration Blueprint

> **Operational Diagnostics Platform for AzerothCore**  
> **Inspect. Diagnose. Resolve.**

This document defines the target repository structure, source architecture, addon architecture, migration map, implementation sequence, and branding integration for RealmOps.

## 1. Final Repository Layout

```text
mod-realm-ops/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   └── feature_request.yml
│   ├── pull_request_template.md
│   └── workflows/
│       └── build.yml
├── addon/
│   └── RealmOps/
│       ├── RealmOps.toc
│       ├── Core/
│       │   ├── Bootstrap.lua
│       │   ├── Constants.lua
│       │   ├── Events.lua
│       │   ├── Namespace.lua
│       │   └── Version.lua
│       ├── Protocol/
│       │   ├── Codec.lua
│       │   ├── Dispatcher.lua
│       │   ├── Messages.lua
│       │   └── Transport.lua
│       ├── UI/
│       │   ├── MainFrame.lua
│       │   ├── Navigation.lua
│       │   ├── StatusBar.lua
│       │   └── Theme.lua
│       ├── Inspectors/
│       │   ├── Character/
│       │   ├── Instance/
│       │   └── Quest/
│       ├── Widgets/
│       │   ├── Button.lua
│       │   ├── EditBox.lua
│       │   ├── ReportView.lua
│       │   ├── ScrollList.lua
│       │   └── Tooltip.lua
│       ├── Settings/
│       │   ├── Defaults.lua
│       │   └── Options.lua
│       └── Media/
│           └── Textures/
├── docs/
│   ├── REPOSITORY_BLUEPRINT.md
│   ├── INSTALLATION.md
│   ├── TESTING.md
│   ├── PROTOCOL.md
│   └── RELEASES.md
├── images/
│   └── realmops/
├── sql/
│   ├── auth/
│   ├── characters/
│   └── world/
├── src/
│   ├── RealmOps/
│   │   ├── RealmOps.cpp
│   │   ├── RealmOps.h
│   │   ├── RealmOpsContext.cpp
│   │   └── RealmOpsContext.h
│   ├── Core/
│   │   ├── RealmOpsResult.h
│   │   ├── RealmOpsStatus.h
│   │   ├── Registry.cpp
│   │   ├── Registry.h
│   │   ├── VersionManager.cpp
│   │   └── VersionManager.h
│   ├── Diagnostics/
│   │   ├── Diagnostic.cpp
│   │   ├── Diagnostic.h
│   │   ├── DiagnosticContext.h
│   │   ├── DiagnosticRegistry.cpp
│   │   └── DiagnosticRegistry.h
│   ├── Inspectors/
│   │   ├── Inspector.cpp
│   │   ├── Inspector.h
│   │   ├── InspectorRegistry.cpp
│   │   ├── InspectorRegistry.h
│   │   ├── Character/
│   │   ├── Instance/
│   │   └── Quest/
│   ├── Reports/
│   │   ├── Report.cpp
│   │   ├── Report.h
│   │   ├── ReportBuilder.cpp
│   │   ├── ReportBuilder.h
│   │   ├── ReportFinding.h
│   │   └── ReportSection.h
│   ├── Protocol/
│   │   ├── Message.cpp
│   │   ├── Message.h
│   │   ├── Protocol.cpp
│   │   ├── Protocol.h
│   │   ├── ProtocolCodec.cpp
│   │   └── ProtocolCodec.h
│   ├── Commands/
│   │   ├── RealmOpsCommandScript.cpp
│   │   └── RealmOpsCommandScript.h
│   ├── Services/
│   │   ├── CharacterService.cpp
│   │   ├── InstanceService.cpp
│   │   ├── QuestService.cpp
│   │   └── VersionService.cpp
│   └── Utils/
│       ├── Format.cpp
│       ├── Format.h
│       ├── Parse.cpp
│       └── Parse.h
├── tests/
│   ├── Diagnostics/
│   ├── Inspectors/
│   ├── Protocol/
│   └── Reports/
├── tools/
│   ├── package-addon.sh
│   ├── package-release.sh
│   └── verify-protocol.py
├── CMakeLists.txt
├── mod-realm-ops.cmake
├── CHANGELOG.md
├── README.md
├── VISION.md
├── MANIFESTO.md
├── ROADMAP.md
├── CONTRIBUTING.md
├── ARCHITECTURE.md
└── LICENSE
```

## 2. Server Source Architecture

### RealmOps

The composition root. It initializes shared services and registries and exposes the module lifecycle.

### Core

Contains small project-wide types and infrastructure. It must not contain gameplay-specific rules.

### Diagnostics

Contains focused checks. A Diagnostic accepts a context and returns a structured result with outcome, evidence, details, and optional recommendation.

### Inspectors

Coordinate investigations. An Inspector validates input, loads context, selects Diagnostics, runs them, and produces a Report.

### Reports

Owns the structured result model. Reports must remain independent of chat formatting and addon layout.

### Protocol

Serializes and validates communication between module and addon. Domain code must not build raw protocol strings.

### Services

Provides narrow AzerothCore-facing data access. Services hide repeated core API and database access patterns from Diagnostics.

### Commands

Owns `.realmops` command registration, permission validation, input parsing, and dispatch.

### Utils

Contains truly generic helpers only. It must not become a dumping ground.

## 3. Addon Architecture

The addon is split by responsibility while preserving WoW 3.3.5a sequential load behavior.

### Core

Creates the namespace, registers events, loads constants, and performs startup.

### Protocol

Builds requests, validates server messages, reassembles chunks, and dispatches decoded responses.

### UI

Creates the main window, navigation, status presentation, and shared theme.

### Inspectors

Each Inspector owns its page controller and Inspector-specific presentation.

### Widgets

Reusable 3.3.5a-compatible controls. Widgets do not know quest, instance, or character rules.

### Settings

Owns defaults, SavedVariables migration, and Interface Options.

### Media

Contains TGA textures used by the WoW client.

## 4. Existing File Migration Map

| Current file or concern | Target |
|---|---|
| `src/realmops.cpp` or equivalent module entry | `src/RealmOps/RealmOps.cpp` and `src/Commands/RealmOpsCommandScript.cpp` |
| existing quest command/diagnostic code | `src/Inspectors/Quest/` plus reusable files in `src/Diagnostics/Quest/` |
| existing instance audit code | `src/Inspectors/Instance/` plus reusable files in `src/Diagnostics/Instance/` |
| build/version macros | `src/Core/VersionManager.*` and generated build-info header |
| raw `REALMOPS|...` string creation | `src/Protocol/ProtocolCodec.*` |
| current large `RealmOps.lua` | split across `Core`, `Protocol`, `UI`, `Inspectors`, `Widgets`, and `Settings` |
| command templates table | `addon/RealmOps/Core/Constants.lua` |
| colors and styling | `addon/RealmOps/UI/Theme.lua` |
| common button/edit helpers | `addon/RealmOps/Widgets/` |
| quest UI state and handlers | `addon/RealmOps/Inspectors/Quest/` |
| instance UI state and handlers | `addon/RealmOps/Inspectors/Instance/` |
| compatibility/options code | `addon/RealmOps/Settings/` and `Core/Version.lua` |
| logo and icons | `images/realmops/` and `addon/RealmOps/Media/Textures/` |

No working code should be deleted until its replacement compiles and passes the existing manual test workflow.

## 5. Safe Migration Sequence

### Stage 0 — Baseline

- Tag or record the known working commit.
- Build and install the current module.
- Save server startup output and screenshots.
- Test Quest and Instance Inspectors.
- Record module, addon, protocol, core, and Playerbots versions.

### Stage 1 — Repository and Assets

- Add the final folders.
- Add the branding assets.
- Add this blueprint.
- Do not move source code yet.
- Confirm the build remains unchanged.

### Stage 2 — Core Types

- Introduce `RealmOpsStatus`, `RealmOpsResult`, and `VersionManager`.
- Adapt current version output to use the new service.
- Keep old Inspector behavior unchanged.

### Stage 3 — Report Framework

- Add `Report`, `ReportSection`, `ReportFinding`, and `ReportBuilder`.
- Convert one small existing response to a Report.
- Keep a compatibility formatter for the current protocol.

### Stage 4 — Diagnostic Framework

- Add `Diagnostic`, `DiagnosticContext`, and `DiagnosticRegistry`.
- Extract one existing quest or instance check.
- Compare old and new output using the same character state.

### Stage 5 — Inspector Framework

- Add `Inspector` and `InspectorRegistry`.
- Migrate Quest Inspector first.
- Migrate Instance Inspector second.
- Remove duplicated execution and formatting only after both pass.

### Stage 6 — Protocol Layer

- Move raw message construction and parsing into `ProtocolCodec`.
- Document message types in `docs/PROTOCOL.md`.
- Add protocol compatibility behavior before changing the protocol version.

### Stage 7 — Addon Modularization

Split `RealmOps.lua` incrementally in this order:

1. namespace and constants
2. theme and widgets
3. protocol handling
4. settings
5. Quest Inspector page
6. Instance Inspector page
7. remaining GM utility pages
8. bootstrap and event wiring

After every split, update `RealmOps.toc` and verify the addon loads without Lua errors.

### Stage 8 — Character Inspector

Only after the shared framework is proven by Quest and Instance should Character Inspector begin.

### Stage 9 — Tests and Automation

- Add protocol tests.
- Add pure C++ tests for Diagnostics where practical.
- Add release packaging tools.
- Add a GitHub build workflow after the local build process is stable.

## 6. Branding Integration

Official descriptor:

> **Operational Diagnostics Platform for AzerothCore**

Official motto:

> **Inspect. Diagnose. Resolve.**

### Repository Assets

- `realmops-master.png` — preserved original artwork
- `realmops-readme-banner.png` — README header with updated descriptor
- `realmops-social-preview.png` — GitHub social preview
- `realmops-addon-header.png` — addon/header source
- `realmops-icon-512.png`
- `realmops-icon-256.png`
- `realmops-icon-128.png`
- `realmops-icon-64.png`
- `realmops-icon-32.png`

### Addon Textures

- `RealmOpsLogo.tga`
- `RealmOpsHeader.tga`
- `RealmOpsIcon.tga`
- `RealmOpsMinimap.tga`
- `RealmOpsMiniIcon.tga`

### Recommended README Header

```markdown
<p align="center">
  <img src="images/realmops/realmops-readme-banner.png"
       alt="RealmOps — Operational Diagnostics Platform for AzerothCore">
</p>
```

### WoW Texture Paths

```lua
local MEDIA = "Interface\\AddOns\\RealmOps\\Media\\Textures\\"

logo:SetTexture(MEDIA .. "RealmOpsHeader")
minimapIcon:SetTexture(MEDIA .. "RealmOpsMinimap")
```

## Implementation Rule

Each migration commit must leave RealmOps buildable and testable.

The preferred commit sequence is:

```text
assets: add official RealmOps branding package
docs: add repository and migration blueprint
refactor: introduce RealmOps core result types
refactor: add shared report framework
refactor: add shared diagnostic framework
refactor: migrate quest inspector to shared framework
refactor: migrate instance inspector to shared framework
refactor: isolate RealmOps protocol layer
refactor: modularize RealmOps addon
feat: begin character inspector
```
