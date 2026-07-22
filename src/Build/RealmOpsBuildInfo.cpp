#include "RealmOpsBuildInfo.h"

#include "GitRevision.h"
#include "realmops_build_info.generated.h"

namespace RealmOps
{
BuildInfo GetBuildInfo()
{
    BuildInfo info;
    info.moduleVersion = REALMOPS_MODULE_VERSION;
    info.protocolVersion = REALMOPS_PROTOCOL_VERSION;
    info.releaseChannel = REALMOPS_RELEASE_CHANNEL;
    info.capabilities = REALMOPS_CAPABILITIES;
    info.moduleCommit = REALMOPS_MODULE_GIT_HASH;
    info.moduleWorkspace = REALMOPS_MODULE_GIT_DIRTY;
    info.coreCommit = GitRevision::GetHash();
    info.coreDate = GitRevision::GetDate();
    info.coreWorkspace = REALMOPS_CORE_GIT_DIRTY;
    info.playerbotsCommit = REALMOPS_PLAYERBOTS_GIT_HASH;
    info.playerbotsWorkspace = REALMOPS_PLAYERBOTS_GIT_DIRTY;
    info.buildType = REALMOPS_BUILD_TYPE;
    info.builtAt = __DATE__ " " __TIME__;
    return info;
}
}
