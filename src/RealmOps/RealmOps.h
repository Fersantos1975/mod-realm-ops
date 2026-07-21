#ifndef REALMOPS_REALMOPS_H
#define REALMOPS_REALMOPS_H

#include "Diagnostics/DiagnosticRegistry.h"
#include "Inspectors/InspectorRegistry.h"

namespace RealmOps
{
class Application
{
public:
    static Application& Instance();

    DiagnosticRegistry& Diagnostics() noexcept { return _diagnostics; }
    DiagnosticRegistry const& Diagnostics() const noexcept { return _diagnostics; }

    InspectorRegistry& Inspectors() noexcept { return _inspectors; }
    InspectorRegistry const& Inspectors() const noexcept { return _inspectors; }

    void Reset() noexcept;

private:
    Application() = default;

    DiagnosticRegistry _diagnostics;
    InspectorRegistry _inspectors;
};
} // namespace RealmOps

#endif // REALMOPS_REALMOPS_H
