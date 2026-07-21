# RealmOps Framework — Stage 2

## Instance Inspector Migration

Stage 2 migrates the existing Instance Audit engine from `mod_realm_ops.cpp` into the RealmOps framework.

### New pipeline

```text
.realmops instance audit
        │
        ▼
InstanceAuditContext
        │
        ▼
InstanceInspector
        │
        ▼
ReportBuilder / Result / Finding
        │
        ▼
InstanceLegacyProtocolFormatter
        │
        ▼
Existing REALMOPS|MEMBER protocol
        │
        ▼
Existing addon UI
```

### Compatibility guarantees

This stage preserves:

- `.realmops instance search`
- `.realmops instance audit`
- `REALMOPS|BEGIN`
- `REALMOPS|MEMBER`
- `REALMOPS|END`
- PASS, WARN, and FAIL values
- reason text and ordering
- offline-member behavior
- Quest commands
- addon parsing and filters

No addon update is required.

### Framework diagnostic codes

Findings now carry stable internal codes including:

- `instance.raid_group`
- `instance.difficulty`
- `instance.disabled`
- `instance.quest_requirement`
- `instance.item_requirement`
- `instance.achievement_requirement`
- `instance.lockout.conflict`
- `instance.hourly_limit`
- `instance.capacity`
- `instance.encounter`
- `instance.phase`

These codes are not sent to the addon yet. They prepare RealmOps for a future structured protocol.
