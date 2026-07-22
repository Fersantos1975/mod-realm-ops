#ifndef REALMOPS_LEGACY_PROTOCOL_H
#define REALMOPS_LEGACY_PROTOCOL_H

#include "Build/RealmOpsBuildInfo.h"

#include <cstdint>
#include <string>

class ChatHandler;

namespace RealmOps::Protocol
{
void SendVersion(ChatHandler* handler, BuildInfo const& info);
void SendError(ChatHandler* handler, std::string const& reason);
void SendInstanceSearch(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::string const& type, std::uint32_t maxPlayers);
void SendInstanceSearchEnd(ChatHandler* handler, std::uint32_t count);
void SendInstanceBegin(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::uint32_t difficulty, std::uint32_t referenceId, std::uint32_t members);
void SendInstanceMember(ChatHandler* handler, std::string const& name, std::string const& result, std::uint32_t mapId, std::uint32_t instanceId, std::uint32_t phaseMask, std::string const& reason);
void SendInstanceEnd(ChatHandler* handler);
void SendQuestError(ChatHandler* handler, std::string const& reason);
void SendQuestSearch(ChatHandler* handler, std::uint32_t id, std::string const& title, std::string const& faction, std::string const& eligibility, std::string const& status, std::int32_t minLevel, std::int32_t level, std::string const& type, std::string const& player);
void SendQuestSearchEnd(ChatHandler* handler, std::uint32_t count);
void SendQuestInfo(ChatHandler* handler, std::uint32_t id, std::string const& title, std::string const& faction, std::int32_t minLevel, std::int32_t level, std::string const& type, bool repeatable, std::string const& status, std::string const& eligibility, std::string const& reason, std::string const& items, std::string const& reputation, std::string const& player, std::string const& starters, std::string const& enders);
void SendQuestChain(ChatHandler* handler, std::string const& direction, std::uint32_t id, std::string const& title, std::string const& status, std::string const& eligibility, std::string const& faction, std::string const& required, std::uint32_t depth, std::string const& reason);
void SendQuestInfoEnd(ChatHandler* handler, std::uint32_t id, std::uint32_t chainCount);
}

#endif
