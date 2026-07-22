#ifndef REALMOPS_INSPECTOR_H
#define REALMOPS_INSPECTOR_H

#include "InspectorContext.h"
#include "Reports/Report.h"

#include <string_view>

namespace RealmOps
{
class Inspector
{
public:
    virtual ~Inspector() = default;

    virtual std::string_view GetId() const noexcept = 0;
    virtual std::string_view GetName() const noexcept = 0;
    virtual Report Inspect(InspectorContext& context) const = 0;
};
} // namespace RealmOps

#endif // REALMOPS_INSPECTOR_H
