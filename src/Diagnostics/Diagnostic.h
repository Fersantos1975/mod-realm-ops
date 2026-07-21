#ifndef REALMOPS_DIAGNOSTIC_H
#define REALMOPS_DIAGNOSTIC_H

#include "Core/RealmOpsResult.h"
#include "DiagnosticContext.h"

#include <string_view>

namespace RealmOps
{
class Diagnostic
{
public:
    virtual ~Diagnostic() = default;

    virtual std::string_view GetId() const noexcept = 0;
    virtual std::string_view GetName() const noexcept = 0;
    virtual Result Evaluate(DiagnosticContext const& context) const = 0;
};
} // namespace RealmOps

#endif // REALMOPS_DIAGNOSTIC_H
