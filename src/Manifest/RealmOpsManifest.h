#ifndef REALMOPS_MANIFEST_H
#define REALMOPS_MANIFEST_H

#include "Build/RealmOpsBuildInfo.h"

namespace RealmOps::Manifest
{
// Returns the immutable metadata snapshot advertised to the addon.
BuildInfo const& Get();

// Capability lookup for server-side feature gating.
bool Supports(char const* capability);
}

#endif
