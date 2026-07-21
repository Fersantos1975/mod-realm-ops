# RealmOps Framework — Stage 1

> **Operational Diagnostics Platform for AzerothCore**

Stage 1 introduces the shared domain framework without modifying existing Quest, Instance, command, protocol, or addon behavior.

## Added Components

### Core

- `Status`
- `Result`
- `Evidence`

### Reports

- `Report`
- `ReportSection`
- `ReportFinding`
- `ReportBuilder`
- `PlainTextReportFormatter`

### Diagnostics

- `Diagnostic`
- `DiagnosticContext`
- `DiagnosticRegistry`

### Inspectors

- `Inspector`
- `InspectorContext`
- `InspectorRegistry`

### Application

- `RealmOps::Application`

## Dependency Direction

```text
RealmOps Application
├── Inspector Registry
│   └── Inspector
│       ├── Inspector Context
│       └── Report
└── Diagnostic Registry
    └── Diagnostic
        ├── Diagnostic Context
        └── Result
```

Reports depend on results.

Inspectors may coordinate Diagnostics and build Reports.

Diagnostics must not depend on Inspectors, Reports, protocol strings, chat output, or addon layout.

## Integration Policy

Stage 1 is additive.

Do not delete or move existing code yet.

After this stage compiles:

1. create one adapter around an existing small Quest or Instance check
2. compare the framework result with the current result
3. add the compatibility formatter
4. migrate one Inspector at a time

## Build Verification

From the AzerothCore root:

```bash
cd /home/cura/azerothcore
cmake -S . -B build
cmake --build build -j$(nproc)
cmake --install build
```

Then confirm:

```bash
sha256sum \
  /home/cura/azerothcore/build/src/server/apps/worldserver \
  /home/cura/server/bin/worldserver
```

The hashes should match after installation.

Start `worldserver` and verify that the existing RealmOps commands still work.

## Expected Behavior

There should be no visible in-game change in Stage 1.

That is intentional.

This commit establishes the framework before any existing feature is migrated.
