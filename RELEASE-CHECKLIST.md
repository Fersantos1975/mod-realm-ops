# RealmOps 0.1.6 release checklist

## Source

- Confirm the repository is named `mod-realm-ops`.
- Confirm only RealmOps names, commands, SavedVariables, frames, and protocol identifiers are present.
- Confirm module and addon versions are `0.1.6` and protocol is `1`.
- Parse `RealmOps.lua` and inspect the archive layout.

## Server

- Ensure only `/home/cura/azerothcore/modules/mod-realm-ops` provides `.realmops`.
- Reconfigure and build AzerothCore.
- Confirm `realmops_build_info.generated.h` contains module and Playerbots revisions.
- Confirm the built binary contains `REALMOPS|VERSION`, `REALMOPS|QUEST_INFO`, and `REALMOPS|MEMBER`.
- Install, restart, and test `.realmops version`.
- Verify the addon reports the actual CMake configuration and a compatible protocol.

## Client

- Install `addon/RealmOps` as `Interface/AddOns/RealmOps`.
- Enable the addon and test `/realmops`, `/ro`, the minimap button, and Interface Options.
- Test quest search/details/chain, instance search/audit/binds, filters, tooltips, and scrolling.
- Focus item and quest ID fields and test Shift-click insertion.
- Test confirmations and target warnings before reset, teleport, or summon actions.

## Publishing

- Verify the server-module and addon ZIP archives.
- Create the new GitHub repository and upload only the clean RealmOps tree.
- Tag and publish RealmOps `0.1.6` after in-game validation.
