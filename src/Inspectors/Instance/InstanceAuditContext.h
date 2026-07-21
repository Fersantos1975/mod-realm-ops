#ifndef REALMOPS_INSTANCE_AUDIT_CONTEXT_H
#define REALMOPS_INSTANCE_AUDIT_CONTEXT_H

#include "SharedDefines.h"

#include <cstdint>

class MapEntry;
class Player;

namespace RealmOps
{
struct InstanceAuditContext
{
    Player* player = nullptr;
    Player* requester = nullptr;
    Player* leader = nullptr;
    MapEntry const* mapEntry = nullptr;
    Difficulty difficulty = REGULAR_DIFFICULTY;
    std::uint32_t referenceInstanceId = 0;
};
} // namespace RealmOps

#endif // REALMOPS_INSTANCE_AUDIT_CONTEXT_H
