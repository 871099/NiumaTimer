// 节假日边界回归：固定输入时间，避免触碰工资设置、工作记录和网络。
#include "../src/app/ChinaHolidayCalendar.h"
#include <QCoreApplication>
#include <QDebug>

int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    ChinaHolidayCalendar calendar;
    int failures = 0;
    auto check = [&failures](bool condition, const char *name) {
        if (!condition) { qCritical() << "FAIL:" << name; ++failures; }
    };
    auto snapshot = [&calendar](const char *time) {
        return calendar.snapshot(QDateTime::fromString(QString::fromLatin1(time), Qt::ISODateWithMs));
    };
    auto before = snapshot("2026-09-30T23:59:59.000+08:00");
    check(before.value("name") == "国庆节" && !before.value("ongoing").toBool(), "next National Day");
    check(before.value("countdown") == "0天 00:00:01", "one second before start");
    auto start = snapshot("2026-10-01T00:00:00.000+08:00");
    check(start.value("ongoing").toBool() && start.value("countdown") == "7天 00:00:00", "inclusive start");
    auto end = snapshot("2026-10-07T23:59:59.500+08:00");
    check(end.value("ongoing").toBool() && end.value("countdown") == "0天 00:00:01", "inclusive last day, ceiling seconds");
    auto after = snapshot("2026-10-08T00:00:00.000+08:00");
    check(after.value("name") == "元旦" && after.value("start") == "2027-01-01", "cross-year next holiday");
    check(!after.value("confirmed").toBool() && after.value("countdown") == "85天 00:00:00", "unannounced schedule marked");
    check(snapshot("2026-09-30T16:00:00.000Z") == start, "UTC converted to Beijing start");
    check(snapshot("2026-09-30T09:00:00.000-07:00") == start, "foreign device timezone invariant");
    auto spring = snapshot("2026-02-15T00:00:00.000+08:00");
    check(spring.value("name") == "春节" && spring.value("days").toInt() == 9, "official Spring Festival length");
    check(spring.value("makeupText").toString().contains("2026-02-14")
          && spring.value("makeupText").toString().contains("2026-02-28"), "Spring Festival makeup days");
    check(start.value("makeupText").toString().contains("2026-10-10"), "National Day makeup after holiday");
    check(snapshot("2027-01-01T00:00:00.000+08:00").value("ongoing").toBool(), "provisional statutory day begins");
    check(calendar.scheduleOverride(QDate(2026, 9, 28)) == -1, "ordinary date follows personal schedule");
    check(calendar.scheduleOverride(QDate(2026, 10, 1)) == 0, "statutory holiday is a rest day");
    check(calendar.scheduleOverride(QDate(2026, 9, 20)) == 1, "Sunday makeup day is a workday");
    check(calendar.scheduleOverride(QDate(2026, 10, 10)) == 1, "Saturday makeup day is a workday");
    check(calendar.scheduleOverride(QDate(2027, 1, 1)) == 0, "provisional New Year date is a rest day");
    check(calendar.scheduleOverride(QDate(2027, 1, 2)) == -1, "unannounced dates follow personal schedule");
    check(calendar.holidayNameOn(QDate(2026, 10, 3)) == "国庆节", "holiday name available for status");
    check(!snapshot("2027-01-02T00:00:00.000+08:00").value("available").toBool(), "unknown year does not skip unlisted lunar holidays");
    check(!calendar.snapshot(QDateTime()).value("available").toBool(), "invalid clock safe state");
    if (!failures) qInfo() << "PASS: 21 holiday boundary, schedule, and timezone checks";
    return failures ? 1 : 0;
}
