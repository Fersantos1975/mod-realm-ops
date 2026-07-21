# RealmOps

RealmOps 0.1.6 is a WoW 3.3.5a GM companion for AzerothCore Playerbot servers. The project contains:

- `mod-realm-ops`, a server module for structured quest and instance diagnostics;
- `RealmOps`, the matching in-game administration addon.

## Tested baseline

- AzerothCore Playerbot: `bf25eae704f5`
- mod-playerbots: `3fa1c1e49f8f`
- RealmOps protocol: `1`

Compatible protocol and matching tested revisions are reported in the addon's Interface Options page.

## Repository layout

```text
mod-realm-ops/
├── addon/RealmOps/                 WoW 3.3.5a addon
├── src/                            AzerothCore module source
├── CMakeLists.txt
├── mod-realm-ops.cmake
└── README.md
```

## Install the server module

Stop the servers and make a backup first.

```bash
cd /azerothcore/modules
git clone https://github.com/Fersantos1975/mod-realm-ops.git

cd /azerothcore
cmake -S . -B build
cmake --build build -j$(nproc)
cmake --install build
```

Do not keep another module that registers the same `.realmops` commands.

## Install the client addon

Copy the complete `addon/RealmOps` directory to:

```text
World of Warcraft/Interface/AddOns/RealmOps/
```

`RealmOps.toc` and `RealmOps.lua` must be directly inside that directory. Enable RealmOps at character selection and use `/realmops` or `/ro` in game.

## Module commands

```text
.realmops version
.realmops quest search Deliverance from the Pit
.realmops quest info 24710
.realmops instance search icecrown
.realmops instance audit 631 0
```

The module reuses AzerothCore RBAC permissions for quest lookup, map lookup, and instance-bind inspection. Diagnostic commands are read-only; ordinary GM mutations remain subject to AzerothCore's existing command permissions.

## Highlights

- Quest search by title with faction and selected-player eligibility.
- Scrollable quest-chain inspection with prerequisite, alternative, next-step, status, faction, and blocking information.
- Group and raid instance eligibility audits with lockout, access, progression, phase, capacity, and visibility checks.
- Bind inspection and guarded selected-map/all-bind reset actions.
- Character, NPC, teleport, item, and quest administration shortcuts.
- Shift-click insertion of item, quest, spell, and player links into focused RealmOps fields.
- Per-character Interface Options, movable/minimized controls, filters, scrolling, tooltips, and compatibility diagnostics.
- Build metadata for RealmOps, AzerothCore, Playerbots, active CMake configuration, and build time.

## Updating

After pulling module changes, reconfigure, rebuild, install, and restart the server. Replace the client `RealmOps` addon directory whenever its files change.

```bash
cd /azerothcore/modules/mod-realm-ops
git pull --ff-only

cd /azerothcore
cmake -S . -B build
cmake --build build -j$(nproc)
cmake --install build
```

## Safety

- Back up databases and the installed server before module updates.
- Reset, reward, remove, summon, and teleport actions can require confirmation in Interface Options.
- RealmOps does not bypass AzerothCore permissions, encounter rules, access requirements, or instance capacity.
