#include "Chat.h"
#include "CommandScript.h"
#include "DBCStores.h"
#include "DisableMgr.h"
#include "Group.h"
#include "GitRevision.h"
#include "InstanceSaveMgr.h"
#include "InstanceScript.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QuestDef.h"
#include "RBAC.h"
#include "Util.h"
#include "World.h"
#include "realmops_build_info.generated.h"

#include <algorithm>
#include <cstdlib>
#include <functional>
#include <set>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
std::string Clean(std::string value)
{
    std::replace(value.begin(), value.end(), '|', '/');
    std::replace(value.begin(), value.end(), '\n', ' ');
    std::replace(value.begin(), value.end(), '\r', ' ');
    return value;
}

std::string MapName(MapEntry const* entry, ChatHandler* handler)
{
    if (!entry)
        return "Unknown";

    int locale = handler->GetSessionDbcLocale();
    std::string name = entry->name[locale];
    if (name.empty())
        name = entry->name[LOCALE_enUS];
    return Clean(name);
}

std::string QuestName(uint32 id)
{
    if (Quest const* quest = sObjectMgr->GetQuestTemplate(id))
        return Clean(quest->GetTitle());
    return "Unknown quest";
}

std::string ItemName(uint32 id);

std::string QuestFaction(Quest const* quest)
{
    // Playable WotLK race masks: Alliance 0x44D, Horde 0x2B2.
    // A zero AllowableRaces mask means the quest is available to all races.
    constexpr uint32 AllianceMask = 0x44D;
    constexpr uint32 HordeMask = 0x2B2;
    uint32 mask = quest->GetAllowableRaces();
    if (!mask)
        return "BOTH";

    bool alliance = (mask & AllianceMask) != 0;
    bool horde = (mask & HordeMask) != 0;
    if (alliance && horde) return "BOTH";
    if (alliance) return "ALLIANCE";
    if (horde) return "HORDE";
    return "UNKNOWN";
}

std::string QuestStatusName(Player* player, Quest const* quest)
{
    if (!quest)
        return "UNKNOWN";
    uint32 id = quest->GetQuestId();
    if (player->GetQuestRewardStatus(id))
        return "REWARDED";

    switch (player->GetQuestStatus(id))
    {
        case QUEST_STATUS_COMPLETE: return "COMPLETE";
        case QUEST_STATUS_INCOMPLETE: return "ACTIVE";
        case QUEST_STATUS_FAILED: return "FAILED";
        default: return "NONE";
    }
}

std::string QuestEligibility(Player* player, Quest const* quest, std::string& reason)
{
    std::string status = QuestStatusName(player, quest);
    if (status == "REWARDED")
    {
        reason = "Already rewarded";
        return "REWARDED";
    }
    if (status == "COMPLETE" || status == "ACTIVE" || status == "FAILED")
    {
        reason = status == "COMPLETE" ? "Ready to reward" : (status == "ACTIVE" ? "Already in quest log" : "Quest is failed");
        return status;
    }
    if (player->CanTakeQuest(quest, false))
    {
        reason = "All checked acceptance requirements passed";
        return "AVAILABLE";
    }

    std::vector<std::string> failures;
    auto check = [&failures](bool passed, char const* text) { if (!passed) failures.emplace_back(text); };
    check(player->SatisfyQuestRace(quest, false), "Wrong faction or race");
    check(player->SatisfyQuestClass(quest, false), "Wrong class");
    check(player->SatisfyQuestLevel(quest, false), "Level requirement not met");
    check(player->SatisfyQuestPreviousQuest(quest, false), "Missing prerequisite quest");
    check(player->SatisfyQuestReputation(quest, false), "Reputation requirement not met");
    check(player->SatisfyQuestStatus(quest, false), "Quest status blocks acceptance");
    check(player->SatisfyQuestExclusiveGroup(quest, false), "Exclusive quest-group conflict");
    check(player->SatisfyQuestBreadcrumb(quest, false), "Breadcrumb quest conflict");
    check(player->SatisfyQuestNextChain(quest, false), "Later chain quest already active or complete");
    check(player->SatisfyQuestPrevChain(quest, false), "Previous chain quest still active");
    check(player->SatisfyQuestDay(quest, false), "Daily quest already completed today");
    check(player->SatisfyQuestWeek(quest, false), "Weekly quest already completed this week");
    check(player->SatisfyQuestMonth(quest, false), "Monthly quest already completed");
    check(player->SatisfyQuestSeasonal(quest, false), "Seasonal quest requirement not met");
    check(player->SatisfyQuestTimed(quest, false), "Another timed quest is active");
    check(player->SatisfyQuestConditions(quest, false), "Additional server condition not met");

    std::ostringstream out;
    for (std::string const& failure : failures)
    {
        if (out.tellp() > 0) out << "; ";
        out << failure;
    }
    reason = out.str().empty() ? "Blocked by an acceptance requirement not exposed by the core" : out.str();
    return "BLOCKED";
}

std::string QuestTypeName(Quest const* quest)
{
    if (quest->IsDaily()) return "Daily";
    if (quest->IsWeekly()) return "Weekly";
    switch (quest->GetType())
    {
        case QUEST_TYPE_ELITE: return "Group/Elite";
        case QUEST_TYPE_PVP: return "PvP";
        case QUEST_TYPE_RAID: return "Raid";
        case QUEST_TYPE_DUNGEON: return "Dungeon";
        case QUEST_TYPE_WORLD_EVENT: return "World event";
        case QUEST_TYPE_LEGENDARY: return "Legendary";
        case QUEST_TYPE_ESCORT: return "Escort";
        case QUEST_TYPE_HEROIC: return "Heroic";
        case QUEST_TYPE_RAID_10: return "Raid 10";
        case QUEST_TYPE_RAID_25: return "Raid 25";
        default: return quest->IsRepeatable() ? "Repeatable" : "Normal";
    }
}

std::string QuestItems(Quest const* quest)
{
    std::ostringstream out;
    for (uint8 i = 0; i < QUEST_ITEM_OBJECTIVES_COUNT; ++i)
    {
        if (!quest->RequiredItemId[i])
            continue;
        if (out.tellp() > 0) out << ", ";
        out << quest->RequiredItemId[i] << " [" << ItemName(quest->RequiredItemId[i]) << "] x" << quest->RequiredItemCount[i];
    }
    return out.str().empty() ? "None" : Clean(out.str());
}

std::string QuestReputation(Quest const* quest)
{
    std::ostringstream out;
    if (quest->GetRequiredMinRepFaction())
        out << "Faction " << quest->GetRequiredMinRepFaction() << " >= " << quest->GetRequiredMinRepValue();
    if (quest->GetRequiredMaxRepFaction())
    {
        if (out.tellp() > 0) out << ", ";
        out << "Faction " << quest->GetRequiredMaxRepFaction() << " < " << quest->GetRequiredMaxRepValue();
    }
    return out.str().empty() ? "None" : out.str();
}

std::string ItemName(uint32 id)
{
    if (ItemTemplate const* item = sObjectMgr->GetItemTemplate(id))
        return Clean(item->Name1);
    return "Unknown item";
}

std::string QuestSources(uint32 questId, bool enders)
{
    std::vector<std::string> sources;
    QuestRelations* creatureRelations = enders ? sObjectMgr->GetCreatureQuestInvolvedRelationMap() : sObjectMgr->GetCreatureQuestRelationMap();
    for (auto const& relation : *creatureRelations)
    {
        if (relation.second != questId || sources.size() >= 4)
            continue;
        CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(relation.first);
        sources.push_back((creature ? Clean(creature->Name) : "Creature") + " [" + std::to_string(relation.first) + "]");
    }

    QuestRelations* goRelations = enders ? sObjectMgr->GetGOQuestInvolvedRelationMap() : sObjectMgr->GetGOQuestRelationMap();
    for (auto const& relation : *goRelations)
    {
        if (relation.second != questId || sources.size() >= 4)
            continue;
        GameObjectTemplate const* object = sObjectMgr->GetGameObjectTemplate(relation.first);
        sources.push_back((object ? Clean(object->name) : "GameObject") + " [" + std::to_string(relation.first) + "]");
    }

    std::ostringstream out;
    for (std::string const& source : sources)
    {
        if (out.tellp() > 0) out << ", ";
        out << source;
    }
    return out.str().empty() ? "Not listed" : out.str();
}

std::string AchievementName(uint32 id)
{
    if (AchievementEntry const* achievement = sAchievementStore.LookupEntry(id))
        return Clean(achievement->name[LOCALE_enUS]);
    return "Unknown achievement";
}

char const* EnterStateName(Map::EnterState state)
{
    switch (state)
    {
        case Map::CAN_ENTER: return "CAN_ENTER";
        case Map::CANNOT_ENTER_ALREADY_IN_MAP: return "ALREADY_IN_MAP";
        case Map::CANNOT_ENTER_NO_ENTRY: return "NO_MAP_ENTRY";
        case Map::CANNOT_ENTER_UNINSTANCED_DUNGEON: return "NO_INSTANCE_TEMPLATE";
        case Map::CANNOT_ENTER_DIFFICULTY_UNAVAILABLE: return "DIFFICULTY_UNAVAILABLE";
        case Map::CANNOT_ENTER_NOT_IN_RAID: return "RAID_GROUP_REQUIRED";
        case Map::CANNOT_ENTER_CORPSE_IN_DIFFERENT_INSTANCE: return "CORPSE_IN_DIFFERENT_INSTANCE";
        case Map::CANNOT_ENTER_INSTANCE_BIND_MISMATCH: return "INSTANCE_BIND_MISMATCH";
        case Map::CANNOT_ENTER_TOO_MANY_INSTANCES: return "TOO_MANY_INSTANCES";
        case Map::CANNOT_ENTER_MAX_PLAYERS: return "INSTANCE_FULL";
        case Map::CANNOT_ENTER_ZONE_IN_COMBAT: return "ENCOUNTER_IN_PROGRESS";
        default: return "UNSPECIFIED";
    }
}

struct Audit
{
    std::vector<std::string> failures;
    std::vector<std::string> warnings;

    void Fail(std::string value) { failures.push_back(Clean(std::move(value))); }
    void Warn(std::string value) { warnings.push_back(Clean(std::move(value))); }

    std::string Result() const
    {
        if (!failures.empty()) return "FAIL";
        if (!warnings.empty()) return "WARN";
        return "PASS";
    }

    std::string Reasons() const
    {
        std::ostringstream out;
        auto append = [&out](std::vector<std::string> const& values)
        {
            for (std::string const& value : values)
            {
                if (out.tellp() > 0) out << "; ";
                out << value;
            }
        };
        append(failures);
        append(warnings);
        return out.str().empty() ? "All checked requirements passed" : out.str();
    }
};

bool AppliesTo(Player* player, ProgressionRequirement const* requirement)
{
    return requirement->faction == TEAM_NEUTRAL || requirement->faction == player->GetTeamId(true);
}

void CheckAccessRequirements(Player* player, Player* leader, DungeonProgressionRequirements const* requirements, Audit& audit)
{
    if (!requirements || player->IsGameMaster())
        return;

    if (!sWorld->getBoolConfig(CONFIG_INSTANCE_IGNORE_LEVEL))
    {
        if (requirements->levelMin && player->GetLevel() < requirements->levelMin)
            audit.Fail("Level " + std::to_string(player->GetLevel()) + "; requires at least " + std::to_string(requirements->levelMin));
        if (requirements->levelMax && player->GetLevel() > requirements->levelMax)
            audit.Fail("Level " + std::to_string(player->GetLevel()) + "; maximum is " + std::to_string(requirements->levelMax));
    }

    if (sWorld->getBoolConfig(CONFIG_DUNGEON_ACCESS_REQUIREMENTS_PORTAL_CHECK_ILVL))
    {
        uint32 itemLevel = uint32(player->GetAverageItemLevelForDF());
        if (requirements->reqItemLevel > itemLevel)
            audit.Fail("Average item level " + std::to_string(itemLevel) + "; requires " + std::to_string(requirements->reqItemLevel));
    }

    for (ProgressionRequirement const* requirement : requirements->quests)
    {
        Player* checked = requirement->checkLeaderOnly ? leader : player;
        if (checked && AppliesTo(checked, requirement) && !checked->GetQuestRewardStatus(requirement->id))
            audit.Fail(std::string(requirement->checkLeaderOnly ? "Leader missing quest " : "Missing quest ") + std::to_string(requirement->id) + " [" + QuestName(requirement->id) + "]" + (requirement->note.empty() ? "" : " - " + requirement->note));
    }

    for (ProgressionRequirement const* requirement : requirements->items)
    {
        Player* checked = requirement->checkLeaderOnly ? leader : player;
        if (checked && AppliesTo(checked, requirement) && !checked->HasItemCount(requirement->id, 1))
            audit.Fail(std::string(requirement->checkLeaderOnly ? "Leader missing item " : "Missing item ") + std::to_string(requirement->id) + " [" + ItemName(requirement->id) + "]" + (requirement->note.empty() ? "" : " - " + requirement->note));
    }

    for (ProgressionRequirement const* requirement : requirements->achievements)
    {
        Player* checked = requirement->checkLeaderOnly ? leader : player;
        if (checked && AppliesTo(checked, requirement) && !checked->HasAchieved(requirement->id))
            audit.Fail(std::string(requirement->checkLeaderOnly ? "Leader missing achievement " : "Missing achievement ") + std::to_string(requirement->id) + " [" + AchievementName(requirement->id) + "]" + (requirement->note.empty() ? "" : " - " + requirement->note));
    }
}

uint32 ReferenceInstanceId(Player* requester, uint32 mapId, Difficulty difficulty)
{
    if (requester->GetMapId() == mapId && requester->GetMap()->IsDungeon() && requester->GetMap()->GetDifficulty() == difficulty)
        return requester->GetInstanceId();

    if (InstancePlayerBind* bind = sInstanceSaveMgr->PlayerGetBoundInstance(requester->GetGUID(), mapId, difficulty))
        return bind->save ? bind->save->GetInstanceId() : 0;

    return 0;
}

void AuditPlayer(Player* player, Player* requester, Player* leader, MapEntry const* entry, Difficulty difficulty, uint32 referenceId, Audit& audit)
{
    uint32 mapId = entry->MapID;

    if (player->IsGameMaster())
        audit.Warn("GM mode bypasses normal entrance requirements");

    if (entry->IsRaid() && (!player->GetGroup() || !player->GetGroup()->isRaidGroup()) && !sWorld->getBoolConfig(CONFIG_INSTANCE_IGNORE_RAID))
        audit.Fail("Raid group required");

    if (!GetMapDifficultyData(mapId, difficulty))
        audit.Fail("Difficulty " + std::to_string(uint32(difficulty)) + " is unavailable");

    if (sDisableMgr->IsDisabledFor(DISABLE_TYPE_MAP, mapId, player))
        audit.Fail("Instance is disabled for this player");

    if (!player->IsAlive())
    {
        if (!player->HasCorpse())
            audit.Fail("Dead with no corpse");
        else if (player->GetCorpseLocation().GetMapId() != mapId)
            audit.Fail("Corpse is on map " + std::to_string(player->GetCorpseLocation().GetMapId()));
    }

    CheckAccessRequirements(player, leader, sObjectMgr->GetAccessRequirement(mapId, difficulty), audit);

    InstancePlayerBind* bind = sInstanceSaveMgr->PlayerGetBoundInstance(player->GetGUID(), mapId, difficulty);
    uint32 playerBindId = bind && bind->save ? bind->save->GetInstanceId() : 0;
    if (bind && bind->perm && referenceId && playerBindId != referenceId)
        audit.Fail("Permanent lockout conflict: player ID " + std::to_string(playerBindId) + ", requester ID " + std::to_string(referenceId));
    else if (playerBindId && referenceId && playerBindId == referenceId)
        audit.Warn("Already bound to requester's instance ID " + std::to_string(referenceId));
    else if (playerBindId && !referenceId)
        audit.Warn("Player has instance ID " + std::to_string(playerBindId) + "; requester has no reference ID");

    uint32 countCheckId = playerBindId ? playerBindId : referenceId;
    if (entry->IsNonRaidDungeon() && !player->CheckInstanceCount(countCheckId))
        audit.Fail("Five-instances-per-hour limit reached");

    if (referenceId)
    {
        if (Map* destination = sMapMgr->FindMap(mapId, referenceId))
        {
            if (InstanceMap* instance = destination->ToInstanceMap())
            {
                if (instance->GetPlayersCountExceptGMs() >= instance->GetMaxPlayers())
                    audit.Fail("Reference instance is full");
                if ((instance->IsRaid() || mapId == 668) && instance->GetInstanceScript() && instance->GetInstanceScript()->IsEncounterInProgress() && player->GetInstanceId() != referenceId)
                    audit.Fail("Boss encounter is in progress");
            }
        }
    }

    if (player->GetMapId() == mapId)
    {
        if (referenceId && player->GetInstanceId() != referenceId)
            audit.Fail("Currently inside different instance ID " + std::to_string(player->GetInstanceId()));
        if (requester->GetMapId() == mapId && requester->GetInstanceId() == player->GetInstanceId() && !(requester->GetPhaseMask() & player->GetPhaseMask()))
            audit.Fail("Same instance but phase masks do not overlap (you " + std::to_string(requester->GetPhaseMask()) + ", player " + std::to_string(player->GetPhaseMask()) + ")");
        if (!player->isGMVisible())
            audit.Fail("Player is GM-invisible");
    }
    else
        audit.Warn("Currently outside target map (on map " + std::to_string(player->GetMapId()) + ")");
}
}

class realm_ops_commands : public CommandScript
{
public:
    realm_ops_commands() : CommandScript("realm_ops_commands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable instanceTable =
        {
            { "search", HandleSearch, rbac::RBAC_PERM_COMMAND_LOOKUP_MAP, Console::No },
            { "audit", HandleAudit, rbac::RBAC_PERM_COMMAND_INSTANCE_LISTBINDS, Console::No },
        };
        static ChatCommandTable questTable =
        {
            { "search", HandleQuestSearch, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
            { "info", HandleQuestInfo, rbac::RBAC_PERM_COMMAND_LOOKUP_QUEST, Console::No },
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
        handler->PSendSysMessage(
            "REALMOPS|VERSION|module={}|protocol={}|modulegit={}|moduledirty={}|core={}|coredate={}|playerbots={}|playerbotsdirty={}|build={}|built={}",
            REALMOPS_MODULE_VERSION, REALMOPS_PROTOCOL_VERSION, REALMOPS_MODULE_GIT_HASH, REALMOPS_MODULE_GIT_DIRTY,
            GitRevision::GetHash(), GitRevision::GetDate(), REALMOPS_PLAYERBOTS_GIT_HASH,
            REALMOPS_PLAYERBOTS_GIT_DIRTY, REALMOPS_BUILD_TYPE, __DATE__ " " __TIME__);
        return true;
    }

    static bool HandleQuestSearch(ChatHandler* handler, Tail search)
    {
        if (search.empty())
            return false;

        std::wstring needle;
        if (!Utf8toWStr(search, needle))
            return false;
        wstrToLower(needle);

        Player* player = handler->getSelectedPlayerOrSelf();
        uint32 count = 0;
        for (auto const& pair : sObjectMgr->GetQuestTemplates())
        {
            Quest const* quest = pair.second;
            if (!quest || !Utf8FitTo(quest->GetTitle(), needle))
                continue;

            std::string reason;
            std::string eligibility = QuestEligibility(player, quest, reason);
            handler->PSendSysMessage(
                "REALMOPS|QUEST_SEARCH|id={}|title={}|faction={}|eligibility={}|status={}|min={}|level={}|type={}|player={}",
                quest->GetQuestId(), Clean(quest->GetTitle()), QuestFaction(quest), eligibility,
                QuestStatusName(player, quest), quest->GetMinLevel(), quest->GetQuestLevel(), QuestTypeName(quest), Clean(player->GetName()));
            if (++count >= 12)
                break;
        }
        handler->PSendSysMessage("REALMOPS|QUEST_SEARCH_END|count={}", count);
        return true;
    }

    static bool HandleQuestInfo(ChatHandler* handler, uint32 questId)
    {
        Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
        if (!quest)
        {
            handler->PSendSysMessage("REALMOPS|QUEST_ERROR|reason=Quest {} does not exist", questId);
            return true;
        }

        Player* player = handler->getSelectedPlayerOrSelf();
        std::string reason;
        std::string eligibility = QuestEligibility(player, quest, reason);
        handler->PSendSysMessage(
            "REALMOPS|QUEST_INFO|id={}|title={}|faction={}|min={}|level={}|type={}|repeatable={}|status={}|eligibility={}|reason={}|items={}|reputation={}|player={}|starters={}|enders={}",
            quest->GetQuestId(), Clean(quest->GetTitle()), QuestFaction(quest), quest->GetMinLevel(),
            quest->GetQuestLevel(), QuestTypeName(quest), quest->IsRepeatable() ? "yes" : "no",
            QuestStatusName(player, quest), eligibility, Clean(reason), QuestItems(quest), QuestReputation(quest), Clean(player->GetName()),
            QuestSources(questId, false), QuestSources(questId, true));

        uint32 emitted = 0;
        std::set<uint32> visited;
        visited.insert(questId);
        std::function<void(Quest const*, uint32)> emitPrevious = [&](Quest const* current, uint32 depth)
        {
            if (!current || depth > 12 || emitted >= 32)
                return;
            for (int32 previous : current->prevQuests)
            {
                uint32 id = uint32(std::abs(previous));
                if (!id || !visited.insert(id).second)
                    continue;
                Quest const* linked = sObjectMgr->GetQuestTemplate(id);
                emitPrevious(linked, depth + 1);
                std::string linkedReason;
                std::string linkedEligibility = linked ? QuestEligibility(player, linked, linkedReason) : "UNKNOWN";
                handler->PSendSysMessage(
                    "REALMOPS|QUEST_CHAIN|direction=PREVIOUS|id={}|title={}|status={}|eligibility={}|faction={}|required={}|depth={}|reason={}",
                    id, QuestName(id), linked ? QuestStatusName(player, linked) : "UNKNOWN",
                    linkedEligibility, linked ? QuestFaction(linked) : "UNKNOWN",
                    previous < 0 ? "alternative" : "required", depth, Clean(linkedReason));
                ++emitted;
                if (emitted >= 32)
                    return;
            }
        };
        emitPrevious(quest, 1);

        Quest const* current = quest;
        for (uint32 depth = 1; current && depth <= 12 && emitted < 32; ++depth)
        {
            uint32 id = current->GetNextQuestInChain();
            if (!id)
                id = current->GetNextQuestId();
            if (!id || !visited.insert(id).second)
                break;
            Quest const* linked = sObjectMgr->GetQuestTemplate(id);
            std::string linkedReason;
            std::string linkedEligibility = linked ? QuestEligibility(player, linked, linkedReason) : "UNKNOWN";
            handler->PSendSysMessage("REALMOPS|QUEST_CHAIN|direction=NEXT|id={}|title={}|status={}|eligibility={}|faction={}|required=next|depth={}|reason={}", id, QuestName(id),
                linked ? QuestStatusName(player, linked) : "UNKNOWN", linkedEligibility,
                linked ? QuestFaction(linked) : "UNKNOWN", depth, Clean(linkedReason));
            ++emitted;
            current = linked;
        }
        handler->PSendSysMessage("REALMOPS|QUEST_INFO_END|id={}|chain={}", questId, emitted);
        return true;
    }

    static bool HandleSearch(ChatHandler* handler, Tail search)
    {
        if (search.empty())
            return false;

        std::wstring needle;
        if (!Utf8toWStr(search, needle))
            return false;
        wstrToLower(needle);

        uint32 count = 0;
        for (MapEntry const* entry : sMapStore)
        {
            if (!entry || !entry->IsDungeon())
                continue;
            std::string name = MapName(entry, handler);
            if (!Utf8FitTo(name, needle))
                continue;
            handler->PSendSysMessage("REALMOPS|SEARCH|map={}|name={}|type={}|max={}", entry->MapID, name, entry->IsRaid() ? "raid" : "dungeon", entry->maxPlayers);
            if (++count >= 12)
                break;
        }
        handler->PSendSysMessage("REALMOPS|SEARCH_END|count={}", count);
        return true;
    }

    static bool HandleAudit(ChatHandler* handler, uint32 mapId, Optional<uint8> difficultyArg)
    {
        Player* requester = handler->GetSession()->GetPlayer();
        MapEntry const* entry = sMapStore.LookupEntry(mapId);
        if (!entry || !entry->IsDungeon())
        {
            handler->PSendSysMessage("REALMOPS|ERROR|reason=Map {} is not an instance", mapId);
            return true;
        }

        Difficulty difficulty = difficultyArg ? Difficulty(*difficultyArg) : requester->GetDifficulty(entry->IsRaid());
        Group* group = requester->GetGroup();
        Player* leader = group ? group->GetLeader() : requester;
        if (!leader)
            leader = requester;
        uint32 referenceId = ReferenceInstanceId(requester, mapId, difficulty);

        handler->PSendSysMessage("REALMOPS|BEGIN|map={}|name={}|difficulty={}|reference={}|members={}", mapId, MapName(entry, handler), uint32(difficulty), referenceId, group ? group->GetMembersCount() : 1);

        auto emit = [&](Player* player, std::string const& fallbackName)
        {
            if (!player)
            {
                handler->PSendSysMessage("REALMOPS|MEMBER|name={}|result=OFFLINE|map=0|instance=0|phase=0|reason=Player is offline", Clean(fallbackName));
                return;
            }

            Audit audit;
            AuditPlayer(player, requester, leader, entry, difficulty, referenceId, audit);
            handler->PSendSysMessage("REALMOPS|MEMBER|name={}|result={}|map={}|instance={}|phase={}|reason={}", Clean(player->GetName()), audit.Result(), player->GetMapId(), player->GetInstanceId(), player->GetPhaseMask(), audit.Reasons());
        };

        if (group)
            for (Group::MemberSlot const& member : group->GetMemberSlots())
                emit(ObjectAccessor::FindConnectedPlayer(member.guid), member.name);
        else
            emit(requester, requester->GetName());

        handler->SendSysMessage("REALMOPS|END");
        return true;
    }
};

void AddSC_realm_ops_commands()
{
    new realm_ops_commands();
}
