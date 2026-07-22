#include "Build/RealmOpsBuildInfo.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Inspectors/Instance/InstanceInspector.h"
#include "Inspectors/Quest/QuestInspector.h"
#include "Manifest/RealmOpsManifest.h"
#include "Protocol/LegacyProtocol.h"
#include "RBAC.h"

using namespace Acore::ChatCommands;

namespace
{
class realm_ops_commands : public CommandScript
{
public:
    realm_ops_commands() : CommandScript("realm_ops_commands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable instanceTable =
        {
            { "search", RealmOps::InstanceInspector::Search, rbac::RBAC_PERM_COMMAND_LOOKUP_MAP, Console::No },
            { "audit", RealmOps::InstanceInspector::Audit, rbac::RBAC_PERM_COMMAND_INSTANCE_LISTBINDS, Console::No },
        };
        static ChatCommandTable questTable =
        {
            { "search", RealmOps::QuestInspector::Search, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
            { "info", RealmOps::QuestInspector::Info, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
            { "audit", RealmOps::QuestInspector::Audit, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
        };
        static ChatCommandTable realmOpsTable =
        {
            { "instance", instanceTable },
            { "quest", questTable },
            { "version", HandleVersion, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
        };
        static ChatCommandTable commands = { { "realmops", realmOpsTable } };
        return commands;
    }

    static bool HandleVersion(ChatHandler* handler)
    {
        RealmOps::Protocol::SendVersion(handler, RealmOps::Manifest::Get());
        return true;
    }
};
}

void AddSC_realm_ops_commands()
{
    new realm_ops_commands();
}
