#ifndef REALMOPS_PLAIN_TEXT_REPORT_FORMATTER_H
#define REALMOPS_PLAIN_TEXT_REPORT_FORMATTER_H

#include "Report.h"

#include <string>

namespace RealmOps
{
class PlainTextReportFormatter
{
public:
    std::string Format(Report const& report) const;
};
} // namespace RealmOps

#endif // REALMOPS_PLAIN_TEXT_REPORT_FORMATTER_H
