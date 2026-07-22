# RC2 architecture additions

`RealmOps::Manifest` is the single metadata source for module version, protocol, release channel, commits, workspace state, build information, and capabilities.

The legacy chat protocol remains protocol version 1. RC2 extends the VERSION payload with additive `release` and `capabilities` fields, so older protocol-1 addons can continue parsing fields they understand.

Advertised capabilities:

- BUILD_INFO
- INSTANCE_SEARCH
- INSTANCE_AUDIT
- QUEST_SEARCH
- QUEST_INFO
- QUEST_GROUP_AUDIT
- REPORT_EXPORT

Addon/module version equality is informational. Compatibility is determined by protocol equality; capabilities describe the available feature set.
