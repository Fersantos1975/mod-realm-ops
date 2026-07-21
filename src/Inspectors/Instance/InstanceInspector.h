#ifndef REALMOPS_INSTANCE_INSPECTOR_H
#define REALMOPS_INSTANCE_INSPECTOR_H

#include "Inspectors/Inspector.h"
#include "InstanceAuditContext.h"

#include <cstdint>
#include <string_view>

namespace RealmOps
{
class InstanceInspector final : public Inspector
{
public:
    static constexpr std::string_view Id = "instance.access";

    std::string_view GetId() const noexcept override { return Id; }
    std::string_view GetName() const noexcept override { return "Instance Access Inspector"; }

    Report Inspect(InspectorContext& context) const override;
    Report Inspect(InstanceAuditContext const& context) const;

    static std::uint32_t FindReferenceInstanceId(Player* requester, std::uint32_t mapId, Difficulty difficulty);
};
} // namespace RealmOps

#endif // REALMOPS_INSTANCE_INSPECTOR_H
