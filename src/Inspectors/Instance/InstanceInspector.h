#ifndef REALMOPS_INSTANCE_INSPECTOR_H
#define REALMOPS_INSTANCE_INSPECTOR_H

#include "Chat.h"
#include "Define.h"

class ChatHandler;

namespace RealmOps
{
class InstanceInspector
{
public:
    static bool Search(ChatHandler* handler, Acore::ChatCommands::Tail search);
    static bool Audit(ChatHandler* handler, uint32 mapId, Acore::ChatCommands::Optional<uint8> difficultyArg);
};
}

#endif
