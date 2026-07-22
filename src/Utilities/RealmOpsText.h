#ifndef REALMOPS_TEXT_H
#define REALMOPS_TEXT_H

#include <string>

class ChatHandler;
struct MapEntry;

namespace RealmOps
{
std::string Clean(std::string value);
std::string LocalizedMapName(MapEntry const* entry, ChatHandler* handler);
}

#endif
