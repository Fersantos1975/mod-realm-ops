#include "InstanceInspector.h"

#include "DBCStores.h"
#include "DisableMgr.h"
#include "Group.h"
#include "InstanceSaveMgr.h"
#include "InstanceScript.h"
#include "MapMgr.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QuestDef.h"
#include "Reports/ReportBuilder.h"
#include "World.h"

#include <algorithm>
#include <string>

namespace RealmOps
{
namespace
{
std::string Clean(std::string value)
{
    std::replace(value.begin(), value.end(), '|', '/');
    std::replace(value.begin(), value.end(), '\n', ' ');
    std::replace(value.begin(), value.end(), '\r', ' ');
    return value;
}

std::string QuestName(std::uint32_t id)
{
    if (Quest const* quest = sObjectMgr->GetQuestTemplate(id))
        return Clean(quest->GetTitle());
    return "Unknown quest";
}

std::string ItemName(std::uint32_t id)
{
    if (ItemTemplate const* item = sObjectMgr->GetItemTemplate(id))
        return Clean(item->Name1);
    return "Unknown item";
}

std::string AchievementName(std::uint32_t id)
{
    if (AchievementEntry const* achievement = sAchievementStore.LookupEntry(id))
        return Clean(achievement->name[LOCALE_enUS]);
    return "Unknown achievement";
}

bool AppliesTo(Player* player, ProgressionRequirement const* requirement)
{
    return requirement->faction == TEAM_NEUTRAL || requirement->faction == player->GetTeamId(true);
}

void AddFailure(ReportBuilder& builder, std::string code, std::string summary)
{
    builder.Finding("access", "Access diagnostics", std::move(code),
        Result::Blocked(std::move(code), Clean(std::move(summary))));
}

void AddWarning(ReportBuilder& builder, std::string code, std::string summary)
{
    builder.Finding("access", "Access diagnostics", std::move(code),
        Result::Warning(std::move(code), Clean(std::move(summary))));
}

void CheckAccessRequirements(InstanceAuditContext const& context,
    DungeonProgressionRequirements const* requirements, ReportBuilder& builder)
{
    Player* player = context.player;
    if (!requirements || player->IsGameMaster())
        return;

    if (!sWorld->getBoolConfig(CONFIG_INSTANCE_IGNORE_LEVEL))
    {
        if (requirements->levelMin && player->GetLevel() < requirements->levelMin)
            AddFailure(builder, "instance.level.minimum",
                "Level " + std::to_string(player->GetLevel()) + "; requires at least " + std::to_string(requirements->levelMin));
        if (requirements->levelMax && player->GetLevel() > requirements->levelMax)
            AddFailure(builder, "instance.level.maximum",
                "Level " + std::to_string(player->GetLevel()) + "; maximum is " + std::to_string(requirements->levelMax));
    }

    if (sWorld->getBoolConfig(CONFIG_DUNGEON_ACCESS_REQUIREMENTS_PORTAL_CHECK_ILVL))
    {
        std::uint32_t itemLevel = std::uint32_t(player->GetAverageItemLevelForDF());
        if (requirements->reqItemLevel > itemLevel)
            AddFailure(builder, "instance.item_level",
                "Average item level " + std::to_string(itemLevel) + "; requires " + std::to_string(requirements->reqItemLevel));
    }

    for (ProgressionRequirement const* requirement : requirements->quests)
    {
        Player* checked = requirement->checkLeaderOnly ? context.leader : player;
        if (checked && AppliesTo(checked, requirement) && !checked->GetQuestRewardStatus(requirement->id))
            AddFailure(builder, "instance.quest_requirement",
                std::string(requirement->checkLeaderOnly ? "Leader missing quest " : "Missing quest ") +
                std::to_string(requirement->id) + " [" + QuestName(requirement->id) + "]" +
                (requirement->note.empty() ? "" : " - " + requirement->note));
    }

    for (ProgressionRequirement const* requirement : requirements->items)
    {
        Player* checked = requirement->checkLeaderOnly ? context.leader : player;
        if (checked && AppliesTo(checked, requirement) && !checked->HasItemCount(requirement->id, 1))
            AddFailure(builder, "instance.item_requirement",
                std::string(requirement->checkLeaderOnly ? "Leader missing item " : "Missing item ") +
                std::to_string(requirement->id) + " [" + ItemName(requirement->id) + "]" +
                (requirement->note.empty() ? "" : " - " + requirement->note));
    }

    for (ProgressionRequirement const* requirement : requirements->achievements)
    {
        Player* checked = requirement->checkLeaderOnly ? context.leader : player;
        if (checked && AppliesTo(checked, requirement) && !checked->HasAchieved(requirement->id))
            AddFailure(builder, "instance.achievement_requirement",
                std::string(requirement->checkLeaderOnly ? "Leader missing achievement " : "Missing achievement ") +
                std::to_string(requirement->id) + " [" + AchievementName(requirement->id) + "]" +
                (requirement->note.empty() ? "" : " - " + requirement->note));
    }
}
} // namespace

Report InstanceInspector::Inspect(InspectorContext& context) const
{
    DiagnosticContext const& diagnostic = context.GetDiagnosticContext();
    InstanceAuditContext audit;
    audit.player = diagnostic.GetSubjectPlayer();
    audit.requester = diagnostic.GetRequester();

    return Inspect(audit);
}

Report InstanceInspector::Inspect(InstanceAuditContext const& context) const
{
    std::string subject = context.player ? context.player->GetName() : "offline";
    ReportBuilder builder(std::string(Id), subject);
    builder.Title("Instance access audit");

    if (!context.player || !context.requester || !context.mapEntry)
    {
        AddFailure(builder, "instance.context.invalid", "Instance audit context is incomplete");
        return builder.Build();
    }

    Player* player = context.player;
    std::uint32_t mapId = context.mapEntry->MapID;

    builder.Metadata("map", std::to_string(mapId));
    builder.Metadata("difficulty", std::to_string(std::uint32_t(context.difficulty)));
    builder.Metadata("reference", std::to_string(context.referenceInstanceId));

    if (player->IsGameMaster())
        AddWarning(builder, "instance.gm_bypass", "GM mode bypasses normal entrance requirements");

    if (context.mapEntry->IsRaid() && (!player->GetGroup() || !player->GetGroup()->isRaidGroup()) &&
        !sWorld->getBoolConfig(CONFIG_INSTANCE_IGNORE_RAID))
        AddFailure(builder, "instance.raid_group", "Raid group required");

    if (!GetMapDifficultyData(mapId, context.difficulty))
        AddFailure(builder, "instance.difficulty", "Difficulty " + std::to_string(std::uint32_t(context.difficulty)) + " is unavailable");

    if (sDisableMgr->IsDisabledFor(DISABLE_TYPE_MAP, mapId, player))
        AddFailure(builder, "instance.disabled", "Instance is disabled for this player");

    if (!player->IsAlive())
    {
        if (!player->HasCorpse())
            AddFailure(builder, "instance.corpse.missing", "Dead with no corpse");
        else if (player->GetCorpseLocation().GetMapId() != mapId)
            AddFailure(builder, "instance.corpse.map", "Corpse is on map " + std::to_string(player->GetCorpseLocation().GetMapId()));
    }

    CheckAccessRequirements(context, sObjectMgr->GetAccessRequirement(mapId, context.difficulty), builder);

    InstancePlayerBind* bind = sInstanceSaveMgr->PlayerGetBoundInstance(player->GetGUID(), mapId, context.difficulty);
    std::uint32_t playerBindId = bind && bind->save ? bind->save->GetInstanceId() : 0;
    if (bind && bind->perm && context.referenceInstanceId && playerBindId != context.referenceInstanceId)
        AddFailure(builder, "instance.lockout.conflict", "Permanent lockout conflict: player ID " +
            std::to_string(playerBindId) + ", requester ID " + std::to_string(context.referenceInstanceId));
    else if (playerBindId && context.referenceInstanceId && playerBindId == context.referenceInstanceId)
        AddWarning(builder, "instance.lockout.shared", "Already bound to requester's instance ID " + std::to_string(context.referenceInstanceId));
    else if (playerBindId && !context.referenceInstanceId)
        AddWarning(builder, "instance.lockout.player_only", "Player has instance ID " +
            std::to_string(playerBindId) + "; requester has no reference ID");

    std::uint32_t countCheckId = playerBindId ? playerBindId : context.referenceInstanceId;
    if (context.mapEntry->IsNonRaidDungeon() && !player->CheckInstanceCount(countCheckId))
        AddFailure(builder, "instance.hourly_limit", "Five-instances-per-hour limit reached");

    if (context.referenceInstanceId)
    {
        if (Map* destination = sMapMgr->FindMap(mapId, context.referenceInstanceId))
        {
            if (InstanceMap* instance = destination->ToInstanceMap())
            {
                if (instance->GetPlayersCountExceptGMs() >= instance->GetMaxPlayers())
                    AddFailure(builder, "instance.capacity", "Reference instance is full");
                if ((instance->IsRaid() || mapId == 668) && instance->GetInstanceScript() &&
                    instance->GetInstanceScript()->IsEncounterInProgress() && player->GetInstanceId() != context.referenceInstanceId)
                    AddFailure(builder, "instance.encounter", "Boss encounter is in progress");
            }
        }
    }

    if (player->GetMapId() == mapId)
    {
        if (context.referenceInstanceId && player->GetInstanceId() != context.referenceInstanceId)
            AddFailure(builder, "instance.current_id", "Currently inside different instance ID " + std::to_string(player->GetInstanceId()));
        if (context.requester->GetMapId() == mapId && context.requester->GetInstanceId() == player->GetInstanceId() &&
            !(context.requester->GetPhaseMask() & player->GetPhaseMask()))
            AddFailure(builder, "instance.phase", "Same instance but phase masks do not overlap (you " +
                std::to_string(context.requester->GetPhaseMask()) + ", player " + std::to_string(player->GetPhaseMask()) + ")");
        if (!player->isGMVisible())
            AddFailure(builder, "instance.gm_visibility", "Player is GM-invisible");
    }
    else
        AddWarning(builder, "instance.location", "Currently outside target map (on map " + std::to_string(player->GetMapId()) + ")");

    return builder.Build();
}

std::uint32_t InstanceInspector::FindReferenceInstanceId(Player* requester, std::uint32_t mapId, Difficulty difficulty)
{
    if (requester->GetMapId() == mapId && requester->GetMap()->IsDungeon() && requester->GetMap()->GetDifficulty() == difficulty)
        return requester->GetInstanceId();

    if (InstancePlayerBind* bind = sInstanceSaveMgr->PlayerGetBoundInstance(requester->GetGUID(), mapId, difficulty))
        return bind->save ? bind->save->GetInstanceId() : 0;

    return 0;
}
} // namespace RealmOps
