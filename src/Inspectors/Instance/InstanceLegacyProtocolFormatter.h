#ifndef REALMOPS_INSTANCE_LEGACY_PROTOCOL_FORMATTER_H
#define REALMOPS_INSTANCE_LEGACY_PROTOCOL_FORMATTER_H

#include "Reports/Report.h"

#include <string>

namespace RealmOps
{
class InstanceLegacyProtocolFormatter
{
public:
    static std::string ResultName(Report const& report);
    static std::string Reasons(Report const& report);
};
} // namespace RealmOps

#endif // REALMOPS_INSTANCE_LEGACY_PROTOCOL_FORMATTER_H
