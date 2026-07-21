#ifndef REALMOPS_INSPECTOR_CONTEXT_H
#define REALMOPS_INSPECTOR_CONTEXT_H

#include "Diagnostics/DiagnosticContext.h"

#include <string>
#include <utility>

namespace RealmOps
{
class InspectorContext
{
public:
    InspectorContext(std::string subjectId, DiagnosticContext diagnosticContext)
        : _subjectId(std::move(subjectId)), _diagnosticContext(std::move(diagnosticContext))
    {
    }

    std::string const& GetSubjectId() const noexcept { return _subjectId; }
    DiagnosticContext const& GetDiagnosticContext() const noexcept { return _diagnosticContext; }
    DiagnosticContext& GetDiagnosticContext() noexcept { return _diagnosticContext; }

private:
    std::string _subjectId;
    DiagnosticContext _diagnosticContext;
};
} // namespace RealmOps

#endif // REALMOPS_INSPECTOR_CONTEXT_H
