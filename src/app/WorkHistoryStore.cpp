// 带版本号的本地历史仓库：使用原子文件替换，保护损坏或未来版本的数据。
#include "WorkHistoryStore.h"

#include <QDir>
#include <QDateTime>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStandardPaths>
#include <QUuid>

#include <algorithm>
#include <cmath>

namespace {
constexpr int kSchemaVersion = 1;
constexpr int kMaximumStoredDays = 1825;
constexpr int kMaximumTasksPerDay = 50;
constexpr qint64 kMaximumMoneyCents = 1000000000000LL;

bool validClock(const QString &value) {
    static const QRegularExpression expression(
        QStringLiteral("^(?:[01][0-9]|2[0-3]):[0-5][0-9]$"));
    return expression.match(value).hasMatch();
}

QVariantMap jsonMap(const QJsonObject &object) {
    return object.toVariantMap();
}
}

WorkHistoryStore::WorkHistoryStore(QObject *parent)
    : WorkHistoryStore(QDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation))
                           .filePath(QStringLiteral("history.json")), parent) {}

WorkHistoryStore::WorkHistoryStore(const QString &dataPath, QObject *parent)
    : QObject(parent), dataPath_(dataPath) {
    if (load()) reconcileHolidayRecords();
}

// 保存原文件备份后撤销旧假期结算；日期和任务继续保留，重复启动不会重复迁移。
bool WorkHistoryStore::reconcileHolidayRecords() {
    const auto previousDays = days_;
    bool changed = false;
    for (auto it = days_.begin(); it != days_.end(); ++it) {
        const QDate date = QDate::fromString(it.key(), Qt::ISODate);
        if (!it.value().value(QStringLiteral("settled")).toBool() ||
            holidayCalendar_.scheduleOverride(date) != 0) continue;
        QJsonObject day = it.value();
        // 内嵌原始结算快照，后续年历更新仍可追溯每条修正依据。
        day.insert(QStringLiteral("holidayCorrection"), it.value());
        day.insert(QStringLiteral("holidayName"), holidayCalendar_.holidayNameOn(date));
        day.insert(QStringLiteral("settled"), false);
        day.insert(QStringLiteral("scheduled"), false);
        day.insert(QStringLiteral("incomeCents"), 0);
        day.insert(QStringLiteral("workMilliseconds"), 0);
        day.insert(QStringLiteral("plannedMilliseconds"), 0);
        for (const auto *key : {"shiftStart", "shiftEnd", "breakStart", "breakEnd", "salaryMode"})
            day.remove(QString::fromLatin1(key));
        it.value() = day;
        changed = true;
    }
    if (!changed) return true;
    const QString backupPath = dataPath_ + QStringLiteral(".before-holiday-repair-") +
        QDateTime::currentDateTimeUtc().toString(QStringLiteral("yyyyMMdd-HHmmss-zzz")) +
        QStringLiteral(".bak");
    if (!QFile::copy(dataPath_, backupPath)) {
        days_ = previousDays;
        setStorageError(QStringLiteral("无法备份历史文件，假期记录修正尚未保存。"));
        return false;
    }
    if (!save()) {
        days_ = previousDays;
        return false;
    }
    emit historyChanged();
    return true;
}

bool WorkHistoryStore::load() {
    QFile file(dataPath_);
    if (!file.exists()) return true;
    if (!file.open(QIODevice::ReadOnly)) {
        writable_ = false;
        setStorageError(QStringLiteral("无法读取本地历史文件：%1").arg(file.errorString()));
        return false;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        writable_ = false;
        setStorageError(QStringLiteral("本地历史文件格式异常，已保留原文件避免覆盖。"));
        return false;
    }

    const QJsonObject root = document.object();
    if (root.value(QStringLiteral("version")).toInt(-1) != kSchemaVersion) {
        writable_ = false;
        setStorageError(QStringLiteral("本地历史文件版本不受支持，已保留原文件。"));
        return false;
    }

    const QStringList knownOutfits{QStringLiteral("classic"), QStringLiteral("hardhat"),
                                   QStringLiteral("neon"), QStringLiteral("crown")};
    const QString savedOutfit = root.value(QStringLiteral("selectedOutfit")).toString();
    if (knownOutfits.contains(savedOutfit)) selectedOutfit_ = savedOutfit;
    unlockedOutfits_.clear();
    const QJsonArray unlocked = root.value(QStringLiteral("unlockedOutfits")).toArray();
    for (const QJsonValue &item : unlocked) {
        const QString id = item.toString();
        if (knownOutfits.contains(id) && !unlockedOutfits_.contains(id))
            unlockedOutfits_.append(id);
    }
    if (!unlockedOutfits_.contains(QStringLiteral("classic")))
        unlockedOutfits_.prepend(QStringLiteral("classic"));
    if (!unlockedOutfits_.contains(selectedOutfit_))
        selectedOutfit_ = QStringLiteral("classic");

    const QJsonArray savedDays = root.value(QStringLiteral("days")).toArray();
    for (const QJsonValue &value : savedDays) {
        if (!value.isObject()) continue;
        QJsonObject day = value.toObject();
        const QString date = day.value(QStringLiteral("date")).toString();
        if (!QDate::fromString(date, Qt::ISODate).isValid()) continue;

        QJsonArray validTasks;
        const QJsonArray tasks = day.value(QStringLiteral("tasks")).toArray();
        for (const QJsonValue &taskValue : tasks) {
            if (!taskValue.isObject() || validTasks.size() >= kMaximumTasksPerDay) continue;
            const QJsonObject task = taskValue.toObject();
            if (task.value(QStringLiteral("id")).toString().isEmpty() ||
                task.value(QStringLiteral("title")).toString().trimmed().isEmpty() ||
                !validClock(task.value(QStringLiteral("time")).toString())) continue;
            validTasks.append(task);
        }
        day.insert(QStringLiteral("tasks"), validTasks);

        const double income = day.value(QStringLiteral("incomeCents")).toDouble();
        const double duration = day.value(QStringLiteral("workMilliseconds")).toDouble();
        if (!std::isfinite(income) || income < 0 || income > kMaximumMoneyCents ||
            !std::isfinite(duration) || duration < 0 || duration > 86400000.0) {
            day.insert(QStringLiteral("settled"), false);
            day.remove(QStringLiteral("incomeCents"));
            day.remove(QStringLiteral("workMilliseconds"));
        }
        days_.insert(date, day);
    }

    while (days_.size() > kMaximumStoredDays) days_.erase(days_.begin());
    return true;
}

bool WorkHistoryStore::save() {
    if (!writable_) return false;
    const QFileInfo fileInfo(dataPath_);
    if (!QDir().mkpath(fileInfo.absolutePath())) {
        setStorageError(QStringLiteral("无法创建本地数据目录。"));
        return false;
    }

    QJsonArray days;
    for (auto it = days_.cbegin(); it != days_.cend(); ++it) days.append(it.value());
    QJsonArray unlocked;
    for (const QString &id : unlockedOutfits_) unlocked.append(id);

    QJsonObject root;
    root.insert(QStringLiteral("version"), kSchemaVersion);
    root.insert(QStringLiteral("selectedOutfit"), selectedOutfit_);
    root.insert(QStringLiteral("unlockedOutfits"), unlocked);
    root.insert(QStringLiteral("days"), days);

    QSaveFile file(dataPath_);
    if (!file.open(QIODevice::WriteOnly)) {
        setStorageError(QStringLiteral("无法保存本地数据：%1").arg(file.errorString()));
        return false;
    }
    const QByteArray payload = QJsonDocument(root).toJson(QJsonDocument::Compact);
    if (file.write(payload) != payload.size() || !file.commit()) {
        setStorageError(QStringLiteral("本地数据写入失败：%1").arg(file.errorString()));
        return false;
    }
    if (!storageError_.isEmpty()) setStorageError(QString());
    return true;
}

void WorkHistoryStore::setStorageError(const QString &message) {
    if (storageError_ == message) return;
    storageError_ = message;
    emit storageErrorChanged();
}

QVariantList WorkHistoryStore::records() const {
    QVariantList result;
    for (auto it = days_.cbegin(); it != days_.cend(); ++it) {
        if (!it.value().value(QStringLiteral("settled")).toBool()) continue;
        // 即使磁盘修正失败，展示也不把法定放假日计为工作记录。
        if (holidayCalendar_.scheduleOverride(QDate::fromString(it.key(), Qt::ISODate)) == 0) continue;
        result.append(jsonMap(it.value()));
    }
    return result;
}

QVariantList WorkHistoryStore::todayTasks() const {
    QVariantList result;
    const QJsonArray tasks = dayObject(currentDate_).value(QStringLiteral("tasks")).toArray();
    for (const QJsonValue &value : tasks) result.append(jsonMap(value.toObject()));
    std::sort(result.begin(), result.end(), [](const QVariant &left, const QVariant &right) {
        return left.toMap().value(QStringLiteral("time")).toString() <
               right.toMap().value(QStringLiteral("time")).toString();
    });
    return result;
}

void WorkHistoryStore::setCurrentDate(const QDate &date) {
    if (!date.isValid() || currentDate_ == date) return;
    currentDate_ = date;
    emit tasksChanged();
}

QDate WorkHistoryStore::latestRecordDate() const {
    QDate latest;
    for (auto it = days_.cbegin(); it != days_.cend(); ++it) {
        if (it.value().value(QStringLiteral("settled")).toBool())
            latest = QDate::fromString(it.key(), Qt::ISODate);
    }
    return latest;
}

QJsonObject WorkHistoryStore::dayObject(const QDate &date) const {
    return days_.value(date.toString(Qt::ISODate));
}

bool WorkHistoryStore::recordCompletedDay(const QVariantMap &record) {
    const QDate date = QDate::fromString(record.value(QStringLiteral("date")).toString(),
                                         Qt::ISODate);
    if (!date.isValid()) return false;
    // 仓库入口再次约束放假日期，避免旧调用方重新写入假期班次。
    if (holidayCalendar_.scheduleOverride(date) == 0) return false;
    const QString key = date.toString(Qt::ISODate);
    QJsonObject day = days_.value(key);
    if (day.value(QStringLiteral("settled")).toBool()) return true;

    const qint64 income = record.value(QStringLiteral("incomeCents")).toLongLong();
    const qint64 duration = record.value(QStringLiteral("workMilliseconds")).toLongLong();
    const qint64 planned = record.value(QStringLiteral("plannedMilliseconds")).toLongLong();
    if (income < 0 || income > kMaximumMoneyCents || duration < 0 ||
        duration > 86400000LL || planned < 0 || planned > 86400000LL) return false;

    const QMap<QString, QJsonObject> previousDays = days_;
    for (auto it = record.cbegin(); it != record.cend(); ++it)
        day.insert(it.key(), QJsonValue::fromVariant(it.value()));
    day.insert(QStringLiteral("date"), key);
    day.insert(QStringLiteral("settled"), true);
    if (!day.contains(QStringLiteral("tasks"))) day.insert(QStringLiteral("tasks"), QJsonArray());
    days_.insert(key, day);
    while (days_.size() > kMaximumStoredDays) days_.erase(days_.begin());
    if (!save()) {
        days_ = previousDays;
        return false;
    }
    emit historyChanged();
    if (date == currentDate_) emit tasksChanged();
    return true;
}

bool WorkHistoryStore::addTask(const QString &title, const QString &time) {
    const QString cleanTitle = title.trimmed();
    if (cleanTitle.isEmpty() || cleanTitle.size() > 48 || !validClock(time)) return false;
    const QMap<QString, QJsonObject> previousDays = days_;
    QJsonObject day = dayObject(currentDate_);
    QJsonArray tasks = day.value(QStringLiteral("tasks")).toArray();
    if (tasks.size() >= kMaximumTasksPerDay) return false;

    QJsonObject task;
    task.insert(QStringLiteral("id"), QUuid::createUuid().toString(QUuid::WithoutBraces));
    task.insert(QStringLiteral("title"), cleanTitle);
    task.insert(QStringLiteral("time"), time);
    task.insert(QStringLiteral("done"), false);
    tasks.append(task);
    day.insert(QStringLiteral("date"), currentDate_.toString(Qt::ISODate));
    day.insert(QStringLiteral("tasks"), tasks);
    days_.insert(currentDate_.toString(Qt::ISODate), day);
    if (!save()) {
        days_ = previousDays;
        return false;
    }
    emit tasksChanged();
    return true;
}

bool WorkHistoryStore::updateTask(const QString &id, const QString &title,
                                  const QString &time) {
    const QString cleanTitle = title.trimmed();
    if (cleanTitle.isEmpty() || cleanTitle.size() > 48 || !validClock(time)) return false;
    return updateTask(id, [&cleanTitle, &time](QJsonObject &task) {
        task.insert(QStringLiteral("title"), cleanTitle);
        task.insert(QStringLiteral("time"), time);
        return true;
    });
}

bool WorkHistoryStore::removeTask(const QString &id) {
    const QString key = currentDate_.toString(Qt::ISODate);
    const QMap<QString, QJsonObject> previousDays = days_;
    QJsonObject day = days_.value(key);
    QJsonArray oldTasks = day.value(QStringLiteral("tasks")).toArray();
    QJsonArray newTasks;
    bool removed = false;
    for (const QJsonValue &value : oldTasks) {
        if (value.toObject().value(QStringLiteral("id")).toString() == id) {
            removed = true;
            continue;
        }
        newTasks.append(value);
    }
    if (!removed) return false;
    day.insert(QStringLiteral("tasks"), newTasks);
    days_.insert(key, day);
    if (!save()) {
        days_ = previousDays;
        return false;
    }
    emit tasksChanged();
    emit historyChanged();
    return true;
}

bool WorkHistoryStore::setTaskCompleted(const QString &id, bool completed) {
    return updateTask(id, [completed](QJsonObject &task) {
        task.insert(QStringLiteral("done"), completed);
        return true;
    });
}

bool WorkHistoryStore::updateTask(
    const QString &id, const std::function<bool(QJsonObject &)> &change) {
    if (id.isEmpty()) return false;
    const QString key = currentDate_.toString(Qt::ISODate);
    const QMap<QString, QJsonObject> previousDays = days_;
    QJsonObject day = days_.value(key);
    QJsonArray tasks = day.value(QStringLiteral("tasks")).toArray();
    bool changed = false;
    for (int i = 0; i < tasks.size(); ++i) {
        QJsonObject task = tasks.at(i).toObject();
        if (task.value(QStringLiteral("id")).toString() != id) continue;
        changed = change(task);
        if (changed) tasks.replace(i, task);
        break;
    }
    if (!changed) return false;
    day.insert(QStringLiteral("tasks"), tasks);
    days_.insert(key, day);
    if (!save()) {
        days_ = previousDays;
        return false;
    }
    emit tasksChanged();
    emit historyChanged();
    return true;
}

QList<QDate> WorkHistoryStore::datesInPeriod(const QString &period,
                                             const QDate &today) const {
    QList<QDate> dates;
    QDate start = today;
    QDate end = today;
    if (period == QLatin1String("week")) {
        start = today.addDays(1 - today.dayOfWeek());
        end = start.addDays(6);
    } else if (period == QLatin1String("month")) {
        start = QDate(today.year(), today.month(), 1);
        end = start.addMonths(1).addDays(-1);
    }
    for (QDate date = start; date <= end; date = date.addDays(1)) dates.append(date);
    return dates;
}

QVariantMap WorkHistoryStore::recordForDate(const QDate &date,
                                            const QVariantMap &liveRecord) const {
    if (holidayCalendar_.scheduleOverride(date) == 0) return {};
    const QString key = date.toString(Qt::ISODate);
    const QJsonObject day = days_.value(key);
    if (day.value(QStringLiteral("settled")).toBool()) return jsonMap(day);
    if (liveRecord.value(QStringLiteral("date")).toString() == key &&
        liveRecord.value(QStringLiteral("scheduled")).toBool()) return liveRecord;
    return {};
}

QVariantMap WorkHistoryStore::statistics(const QString &period,
                                          const QVariantMap &liveRecord) const {
    const QDate today = QDate::fromString(liveRecord.value(QStringLiteral("date")).toString(),
                                          Qt::ISODate).isValid()
                            ? QDate::fromString(liveRecord.value(QStringLiteral("date")).toString(),
                                                Qt::ISODate)
                            : currentDate_;
    const QList<QDate> dates = datesInPeriod(period, today);
    qint64 income = 0;
    qint64 work = 0;
    int workdays = 0;
    for (const QDate &date : dates) {
        const QVariantMap record = recordForDate(date, liveRecord);
        if (record.isEmpty()) continue;
        income += record.value(QStringLiteral("incomeCents")).toLongLong();
        work += record.value(QStringLiteral("workMilliseconds")).toLongLong();
        if (record.value(QStringLiteral("workMilliseconds")).toLongLong() > 0 ||
            record.value(QStringLiteral("settled")).toBool()) ++workdays;
    }
    return {{QStringLiteral("incomeCents"), income},
            {QStringLiteral("workMilliseconds"), work},
            {QStringLiteral("hours"), static_cast<double>(work) / 3600000.0},
            {QStringLiteral("workdays"), workdays},
            {QStringLiteral("averageCents"), workdays ? income / workdays : 0},
            {QStringLiteral("period"), period}};
}

QVariantList WorkHistoryStore::chartBars(const QString &period,
                                         const QVariantMap &liveRecord) const {
    const QDate parsed = QDate::fromString(liveRecord.value(QStringLiteral("date")).toString(),
                                           Qt::ISODate);
    const QDate today = parsed.isValid() ? parsed : currentDate_;
    const QList<QDate> dates = datesInPeriod(period, today);
    const QStringList weekdayNames{QStringLiteral("日"), QStringLiteral("一"),
                                   QStringLiteral("二"), QStringLiteral("三"),
                                   QStringLiteral("四"), QStringLiteral("五"),
                                   QStringLiteral("六")};
    QVariantList result;
    for (const QDate &date : dates) {
        const QVariantMap record = recordForDate(date, liveRecord);
        const QString label = period == QLatin1String("day")
                                  ? QStringLiteral("今天")
                                  : period == QLatin1String("week")
                                        ? QStringLiteral("周%1").arg(
                                              weekdayNames.at(date.dayOfWeek() % 7))
                                        : QString::number(date.day());
        result.append(QVariantMap{{QStringLiteral("date"), date.toString(Qt::ISODate)},
                                  {QStringLiteral("label"), label},
                                  {QStringLiteral("incomeCents"), record.value(QStringLiteral("incomeCents"), 0)},
                                  {QStringLiteral("workMilliseconds"), record.value(QStringLiteral("workMilliseconds"), 0)},
                                  {QStringLiteral("isToday"), date == today},
                                  {QStringLiteral("hasData"), !record.isEmpty()}});
    }
    return result;
}

QVariantList WorkHistoryStore::achievements(int completedWorkdays, int level) const {
    const int savedDays = std::max(0, completedWorkdays);
    const int savedLevel = std::max(1, level);
    const int recordCount = records().size();
    const auto badge = [](const QString &id, const QString &title, const QString &description,
                          int current, int target) {
        return QVariantMap{{QStringLiteral("id"), id}, {QStringLiteral("title"), title},
                           {QStringLiteral("description"), description},
                           {QStringLiteral("current"), std::min(current, target)},
                           {QStringLiteral("target"), target},
                           {QStringLiteral("unlocked"), current >= target},
                           {QStringLiteral("progress"), target > 0
                                ? std::clamp(static_cast<double>(current) / target, 0.0, 1.0)
                                : 0.0}};
    };
    return {badge(QStringLiteral("first-day"), QStringLiteral("第一班"),
                  QStringLiteral("完成第一天排班"), savedDays, 1),
            badge(QStringLiteral("ten-days"), QStringLiteral("十日打卡"),
                  QStringLiteral("累计完成 10 天排班"), savedDays, 10),
            badge(QStringLiteral("thirty-days"), QStringLiteral("月度牛马"),
                  QStringLiteral("累计完成 30 天排班"), savedDays, 30),
            badge(QStringLiteral("hundred-days"), QStringLiteral("百日坚持"),
                  QStringLiteral("累计完成 100 天排班"), savedDays, 100),
            badge(QStringLiteral("level-three"), QStringLiteral("熟练打工人"),
                  QStringLiteral("达到 3 级"), savedLevel, 3),
            badge(QStringLiteral("level-five"), QStringLiteral("资深牛马"),
                  QStringLiteral("达到 5 级"), savedLevel, 5),
            badge(QStringLiteral("history"), QStringLiteral("留下足迹"),
                  QStringLiteral("生成第一条本地工作记录"), recordCount, 1)};
}

void WorkHistoryStore::updateUnlocks(int completedWorkdays, int level) {
    if (!writable_ || !storageError_.isEmpty()) return;
    QStringList earned;
    earned.append(QStringLiteral("classic"));
    if (completedWorkdays >= 10) earned.append(QStringLiteral("hardhat"));
    if (completedWorkdays >= 30) earned.append(QStringLiteral("neon"));
    if (level >= 5) earned.append(QStringLiteral("crown"));

    const QStringList previousUnlocks = unlockedOutfits_;
    bool changed = false;
    for (const QString &id : earned) {
        if (unlockedOutfits_.contains(id)) continue;
        unlockedOutfits_.append(id);
        changed = true;
    }
    if (!changed) return;
    if (save()) emit appearanceChanged();
    else unlockedOutfits_ = previousUnlocks;
}

QVariantList WorkHistoryStore::outfitOptions() const {
    const auto outfit = [this](const QString &id, const QString &name, const QString &rule,
                               const QString &accessory) {
        return QVariantMap{{QStringLiteral("id"), id}, {QStringLiteral("name"), name},
                           {QStringLiteral("rule"), rule},
                           {QStringLiteral("accessory"), accessory},
                           {QStringLiteral("unlocked"), unlockedOutfits_.contains(id)}};
    };
    return {outfit(QStringLiteral("classic"), QStringLiteral("经典打工装"),
                   QStringLiteral("默认外观"), QStringLiteral("")),
            outfit(QStringLiteral("hardhat"), QStringLiteral("安全帽"),
                   QStringLiteral("累计上班 10 天解锁"), QStringLiteral("⛑")),
            outfit(QStringLiteral("neon"), QStringLiteral("霓虹披风"),
                   QStringLiteral("累计上班 30 天解锁"), QStringLiteral("✦")),
            outfit(QStringLiteral("crown"), QStringLiteral("金牌牛马"),
                   QStringLiteral("达到 5 级解锁"), QStringLiteral("♛"))};
}

bool WorkHistoryStore::selectOutfit(const QString &id) {
    if (!unlockedOutfits_.contains(id) || selectedOutfit_ == id) return false;
    const QString previousOutfit = selectedOutfit_;
    selectedOutfit_ = id;
    if (!save()) {
        selectedOutfit_ = previousOutfit;
        return false;
    }
    emit appearanceChanged();
    return true;
}
