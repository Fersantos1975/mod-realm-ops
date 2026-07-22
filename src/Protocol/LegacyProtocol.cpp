#include "LegacyProtocol.h"

#include "Chat.h"
#include "Utilities/RealmOpsText.h"

namespace RealmOps::Protocol
{
void SendVersion(ChatHandler* handler, BuildInfo const& info)
{
    handler->PSendSysMessage(
        "REALMOPS|VERSION|module={}|protocol={}|modulegit={}|moduledirty={}|core={}|coredate={}|coredirty={}|playerbots={}|playerbotsdirty={}|build={}|built={}",
        info.moduleVersion, info.protocolVersion, info.moduleCommit, info.moduleWorkspace,
        info.coreCommit, info.coreDate, info.coreWorkspace, info.playerbotsCommit,
        info.playerbotsWorkspace, info.buildType, info.builtAt);
}

void SendError(ChatHandler* handler, std::string const& reason) { handler->PSendSysMessage("REALMOPS|ERROR|reason={}", Clean(reason)); }
void SendInstanceSearch(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::string const& type, std::uint32_t maxPlayers) { handler->PSendSysMessage("REALMOPS|SEARCH|map={}|name={}|type={}|max={}", mapId, Clean(name), type, maxPlayers); }
void SendInstanceSearchEnd(ChatHandler* handler, std::uint32_t count) { handler->PSendSysMessage("REALMOPS|SEARCH_END|count={}", count); }
void SendInstanceBegin(ChatHandler* handler, std::uint32_t mapId, std::string const& name, std::uint32_t difficulty, std::uint32_t referenceId, std::uint32_t members) { handler->PSendSysMessage("REALMOPS|BEGIN|map={}|name={}|difficulty={}|reference={}|members={}", mapId, Clean(name), difficulty, referenceId, members); }
void SendInstanceMember(ChatHandler* handler, std::string const& name, std::string const& result, std::uint32_t mapId, std::uint32_t instanceId, std::uint32_t phaseMask, std::string const& reason) { handler->PSendSysMessage("REALMOPS|MEMBER|name={}|result={}|map={}|instance={}|phase={}|reason={}", Clean(name), result, mapId, instanceId, phaseMask, Clean(reason)); }
void SendInstanceEnd(ChatHandler* handler) { handler->SendSysMessage("REALMOPS|END"); }
void SendQuestError(ChatHandler* handler, std::string const& reason) { handler->PSendSysMessage("REALMOPS|QUEST_ERROR|reason={}", Clean(reason)); }
void SendQuestSearch(ChatHandler* handler, std::uint32_t id, std::string const& title, std::string const& faction, std::string const& eligibility, std::string const& status, std::int32_t minLevel, std::int32_t level, std::string const& type, std::string const& player) { handler->PSendSysMessage("REALMOPS|QUEST_SEARCH|id={}|title={}|faction={}|eligibility={}|status={}|min={}|level={}|type={}|player={}", id, Clean(title), faction, eligibility, status, minLevel, level, type, Clean(player)); }
void SendQuestSearchEnd(ChatHandler* handler, std::uint32_t count) { handler->PSendSysMessage("REALMOPS|QUEST_SEARCH_END|count={}", count); }
void SendQuestInfo(ChatHandler* handler, std::uint32_t id, std::string const& title, std::string const& faction, std::int32_t minLevel, std::int32_t level, std::string const& type, bool repeatable, std::string const& status, std::string const& eligibility, std::string const& reason, std::string const& items, std::string const& reputation, std::string const& player, std::string const& starters, std::string const& enders)
{
    handler->PSendSysMessage("REALMOPS|QUEST_INFO|id={}|title={}|faction={}|min={}|level={}|type={}|repeatable={}|status={}|eligibility={}|reason={}|items={}|reputation={}|player={}|starters={}|enders={}", id, Clean(title), faction, minLevel, level, type, repeatable ? "yes" : "no", status, eligibility, Clean(reason), Clean(items), Clean(reputation), Clean(player), Clean(starters), Clean(enders));
}
void SendQuestChain(ChatHandler* handler, std::string const& direction, std::uint32_t id, std::string const& title, std::string const& status, std::string const& eligibility, std::string const& faction, std::string const& required, std::uint32_t depth, std::string const& reason) { handler->PSendSysMessage("REALMOPS|QUEST_CHAIN|direction={}|id={}|title={}|status={}|eligibility={}|faction={}|required={}|depth={}|reason={}", direction, id, Clean(title), status, eligibility, faction, required, depth, Clean(reason)); }
void SendQuestInfoEnd(ChatHandler* handler, std::uint32_t id, std::uint32_t chainCount) { handler->PSendSysMessage("REALMOPS|QUEST_INFO_END|id={}|chain={}", id, chainCount); }
void SendQuestAuditBegin(ChatHandler* handler, std::uint32_t id, std::string const& title, std::uint32_t members) { handler->PSendSysMessage("REALMOPS|QUEST_AUDIT_BEGIN|id={}|title={}|members={}", id, Clean(title), members); }
void SendQuestAuditMember(ChatHandler* handler, std::string const& name, std::string const& result, std::string const& status, std::string const& eligibility, std::string const& reason) { handler->PSendSysMessage("REALMOPS|QUEST_AUDIT_MEMBER|name={}|result={}|status={}|eligibility={}|reason={}", Clean(name), result, status, eligibility, Clean(reason)); }
void SendQuestAuditEnd(ChatHandler* handler) { handler->SendSysMessage("REALMOPS|QUEST_AUDIT_END"); }
}
