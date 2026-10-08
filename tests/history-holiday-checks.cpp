// 使用临时历史文件复现国庆误结算，验证数据迁移及统计真实行为。
#include "../src/app/WorkHistoryStore.h"
#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QTemporaryDir>

int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    QTemporaryDir temporary;
    if (!temporary.isValid()) return 1;
    const QString path = temporary.filePath(QStringLiteral("history.json"));
    int failures = 0;
    auto check = [&failures](bool condition, const char *name) {
        if (!condition) { qCritical() << "FAIL:" << name; ++failures; }
    };
    auto record = [](const QString &date, int cents = 10000) {
        return QJsonObject{{"date", date}, {"settled", true}, {"scheduled", true},
            {"incomeCents", cents}, {"workMilliseconds", 3600000},
            {"plannedMilliseconds", 3600000}, {"shiftStart", date + "T09:00:00"},
            {"shiftEnd", date + "T10:00:00"}, {"tasks", QJsonArray{}}};
    };
    QJsonArray days{record("2026-09-30"), record("2026-10-08"), record("2026-10-10", 20000)};
    for (int day : {1, 2, 3, 5, 6, 7}) {
        auto old = record(QStringLiteral("2026-10-%1").arg(day, 2, 10, QLatin1Char('0')), 91954020);
        old["tasks"] = QJsonArray{QJsonObject{{"id", "keep-task"}, {"title", "阅读"},
                                             {"time", "14:00"}, {"done", true}}};
        days.append(old);
    }
    const QJsonObject original{{"version", 1}, {"selectedOutfit", "neon"},
        {"unlockedOutfits", QJsonArray{"classic", "neon"}}, {"days", days}};
    const QByteArray originalBytes = QJsonDocument(original).toJson();
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly) || file.write(originalBytes) != originalBytes.size()) return 1;
    file.close();
    {
        WorkHistoryStore store(path);
        check(store.storageError().isEmpty(), "migration saved successfully");
        check(store.records().size() == 3, "six holiday shifts removed from recent records");
        check(store.selectedOutfit() == "neon", "appearance retained");
        store.setCurrentDate(QDate(2026, 10, 3));
        check(store.todayTasks().size() == 1 && store.todayTasks().first().toMap()["done"].toBool(),
              "holiday custom task and completion retained");
        const auto stats = store.statistics("month", {{"date", "2026-10-07"}, {"scheduled", false}});
        check(stats["incomeCents"].toLongLong() == 30000, "monthly income excludes holiday wages");
        check(stats["workMilliseconds"].toLongLong() == 7200000, "monthly hours exclude holidays");
        check(stats["workdays"].toInt() == 2, "monthly workday count corrected");
        const auto holidayStats = store.statistics("day", {{"date", "2026-10-03"},
            {"scheduled", true}, {"incomeCents", 99999}, {"workMilliseconds", 3600000}});
        check(holidayStats["incomeCents"].toLongLong() == 0, "holiday live estimate also excluded");
        check(!store.recordCompletedDay(record("2026-10-01").toVariantMap()), "holiday cannot be resettled");
        check(store.recordCompletedDay(record("2026-09-20").toVariantMap()), "Sunday makeup accepted");
    }
    const auto backups = QDir(temporary.path()).entryList({"*.bak"}, QDir::Files);
    check(backups.size() == 1, "one original file backup created");
    if (!backups.isEmpty()) {
        QFile backup(temporary.filePath(backups.first()));
        check(backup.open(QIODevice::ReadOnly) && backup.readAll() == originalBytes, "backup exactly matches original");
    }
    file.open(QIODevice::ReadOnly);
    const QByteArray corrected = file.readAll(); file.close();
    const auto saved = QJsonDocument::fromJson(corrected).object()["days"].toArray();
    for (const auto &value : saved) {
        const auto day = value.toObject();
        if (day["date"] != "2026-10-03") continue;
        check(!day["settled"].toBool() && day["workMilliseconds"].toInt() == 0,
              "holiday stored as nonworking with zero hours");
        check(day["holidayCorrection"].toObject()["incomeCents"].toInt() == 91954020,
              "original shift snapshot archived");
    }
    {
        WorkHistoryStore reopened(path);
        check(reopened.records().size() == 4, "reopen preserves ordinary and makeup records");
    }
    file.open(QIODevice::ReadOnly);
    check(file.readAll() == corrected, "repeated migration leaves file unchanged"); file.close();
    check(QDir(temporary.path()).entryList({"*.bak"}, QDir::Files).size() == 1, "reopen does not create extra backups");
    const QString brokenPath = temporary.filePath("broken.json");
    QFile broken(brokenPath); broken.open(QIODevice::WriteOnly); broken.write("{broken"); broken.close();
    WorkHistoryStore invalid(brokenPath);
    check(!invalid.storageError().isEmpty(), "corrupt history produces storage error");
    broken.open(QIODevice::ReadOnly);
    check(broken.readAll() == "{broken", "corrupt history not overwritten");
    return failures ? 1 : 0;
}
