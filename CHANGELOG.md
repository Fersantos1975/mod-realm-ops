# Changelog
## v0.2.0-rc2-stabilization.1

- Fixed `InstanceInspector::Audit` declaration for AzerothCore Playerbot command API.
- Use the globally exposed `Optional<T>` command argument type, matching the implementation and command parser.


## 0.2.0-rc2

- Fixed AzerothCore Playerbot command API type visibility by including `Chat.h`.
- Namespace-qualified optional command arguments.
- Added `RealmOpsManifest` as the central immutable metadata provider.
- Added release-channel and capability advertisement to protocol v1.
- Updated addon compatibility diagnostics to display release and capabilities.
- Added `tools/realmops-check` preflight validation.
- Added RC2 installation and architecture documentation.

## 0.2.0 Release Candidate 1

- Add compatibility and release-support reporting.
- Keep version differences informational while protocol v1 remains compatible.
- Add explanatory troubleshooting guidance for supported mixed versions.
- Add Quest Group Audit and quest report export.
- Add selectable, copyable Quest and Instance report text.
- Add mouse-wheel scrollbars to Quest details, Quest audit/chain, Instance audit, and export reports.
- Add packaged RealmOps icon artwork for the main, floating, and minimap buttons.

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
