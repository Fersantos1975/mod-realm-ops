#ifndef REALMOPS_INSPECTOR_REGISTRY_H
#define REALMOPS_INSPECTOR_REGISTRY_H

#include "Inspector.h"

#include <memory>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace RealmOps
{
class InspectorRegistry
{
public:
    bool Register(std::unique_ptr<Inspector> inspector);
    Inspector const* Find(std::string_view id) const noexcept;
    std::vector<Inspector const*> List() const;
    void Clear() noexcept;

private:
    std::unordered_map<std::string, std::unique_ptr<Inspector>> _inspectors;
};
} // namespace RealmOps

#endif // REALMOPS_INSPECTOR_REGISTRY_H
