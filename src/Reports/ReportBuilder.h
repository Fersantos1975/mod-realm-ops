#ifndef REALMOPS_REPORT_BUILDER_H
#define REALMOPS_REPORT_BUILDER_H

#include "Report.h"

#include <string>

namespace RealmOps
{
class ReportBuilder
{
public:
    ReportBuilder(std::string inspectorId, std::string subjectId);

    ReportBuilder& Title(std::string title);
    ReportBuilder& Summary(std::string summary);
    ReportBuilder& Metadata(std::string key, std::string value);
    ReportBuilder& Finding(std::string sectionId, std::string sectionTitle,
        std::string diagnosticId, Result result);

    Report Build();

private:
    Report _report;
};
} // namespace RealmOps

#endif // REALMOPS_REPORT_BUILDER_H
