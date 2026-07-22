#ifndef REALMOPS_BUILD_INFO_SERVICE_H
#define REALMOPS_BUILD_INFO_SERVICE_H

#include <string>

namespace RealmOps
{
struct BuildInfo
{
    std::string moduleVersion;
    std::string protocolVersion;
    std::string releaseChannel;
    std::string capabilities;
    std::string moduleCommit;
    std::string moduleWorkspace;
    std::string coreCommit;
    std::string coreDate;
    std::string coreWorkspace;
    std::string playerbotsCommit;
    std::string playerbotsWorkspace;
    std::string buildType;
    std::string builtAt;
};

BuildInfo GetBuildInfo();
}

#endif
