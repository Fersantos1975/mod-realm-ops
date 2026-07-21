#include "RealmOps.h"

namespace RealmOps
{
Application& Application::Instance()
{
    static Application instance;
    return instance;
}

void Application::Reset() noexcept
{
    _inspectors.Clear();
    _diagnostics.Clear();
}
} // namespace RealmOps
