#include "RealmOpsManifest.h"

#include <sstream>
#include <string>

namespace RealmOps::Manifest
{
BuildInfo const& Get()
{
    static BuildInfo const manifest = GetBuildInfo();
    return manifest;
}

bool Supports(char const* capability)
{
    if (!capability || !*capability)
        return false;

    std::istringstream stream(Get().capabilities);
    std::string item;
    while (std::getline(stream, item, ','))
        if (item == capability)
            return true;

    return false;
}
}
