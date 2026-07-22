# Changelog

## 0.2.0 - Unreleased

- Simplified compatibility status to Compatible or Protocol mismatch.
- Added RealmOps, AzerothCore, and Playerbots commit revisions.
- Added per-workspace Clean, Modified, or Unknown state.
- Centralized build metadata in `RealmOpsBuildInfo`.
- Moved instance inspection into `Inspectors/Instance`.
- Moved quest inspection into `Inspectors/Quest`.
- Centralized protocol v1 output in `Protocol/LegacyProtocol`.
- Reduced `mod_realm_ops.cpp` to command registration and delegation.

## 0.1.6

- First RealmOps release.
- Add structured quest and instance diagnostics for AzerothCore Playerbot.
- Add quest-chain inspection, faction detection, eligibility reasons, and selected-player status.
- Add group/raid instance audits, result filters, scrolling, bind inspection, and guarded reset controls.
- Add character, NPC, teleport, item, and quest GM tools.
- Add Shift-click smart link insertion for focused fields.
- Add Core, Playerbots, module, protocol, CMake configuration, and build-time diagnostics.
- Add per-character Interface Options, minimap/floating controls, confirmation settings, and display controls.
