// 工作计时逻辑：每次刷新按本地绝对时间重新计算，避免休眠或卡顿造成计时漂移。
#include "WorkTimer.h"

#include <QDate>
#include <QDateTime>
#include <QLocale>
#include <QTime>
#include <QVector>

#include <algorithm>
#include <cmath>

namespace {
constexpr qint64 kMsPerSecond = 1000;
constexpr qint64 kMsPerMinute = 60 * kMsPerSecond;
constexpr qint64 kMsPerHour = 60 * kMsPerMinute;
constexpr int kExperiencePerWorkday = 20;
constexpr int kExperiencePerLevel = 500;

QDateTime atLocalTime(const QDate &date, const QString &time) {
    return QDateTime(date, QTime::fromString(time, QStringLiteral("HH:mm")));
}
}

WorkTimer::WorkTimer(QObject *parent)
    : QObject(parent), settings_(QStringLiteral("NiumaTimer"),
                                 QStringLiteral("NiumaTimer")) {
    const QDate today = QDate::currentDate();
    rotationAnchorMonday_ = today.addDays(1 - today.dayOfWeek());
    loadSettings();
    connect(&networkClock_, &NetworkClock::statusChanged, this,
            [this] { emit snapshotChanged(); });
    connect(&networkClock_, &NetworkClock::timeSynchronized, this,
            &WorkTimer::refresh);
    connect(&refreshTimer_, &QTimer::timeout, this, &WorkTimer::refresh);
    refreshTimer_.setInterval(500);
    refreshTimer_.start();
    refresh();
}

// 接入独立的本地历史仓库，并把存储错误反馈到应用提示。
void WorkTimer::setHistoryStore(WorkHistoryStore *store) {
    historyStore_ = store;
    if (store) {
        connect(store, &WorkHistoryStore::storageErrorChanged, this, [this, store] {
            if (!store->storageError().isEmpty()) emit toast(store->storageError());
        });
        refresh();
    }
}

void WorkTimer::loadSettings() {
    windowPinned_ = settings_.value(QStringLiteral("ui/windowPinned"), false).toBool();
    salaryMode_ = settings_.value(QStringLiteral("pay/mode"), salaryMode_).toString();
    if (salaryMode_ != QLatin1String("hourly") &&
        salaryMode_ != QLatin1String("daily") &&
        salaryMode_ != QLatin1String("monthly")) {
        salaryMode_ = QStringLiteral("monthly");
    }
    salaryAmount_ = settings_.value(QStringLiteral("pay/amount"), salaryAmount_).toDouble();
    monthlyWorkDays_ = settings_.value(QStringLiteral("pay/monthlyWorkDays"), monthlyWorkDays_).toDouble();
    startTime_ = settings_.value(QStringLiteral("schedule/start"), startTime_).toString();
    endTime_ = settings_.value(QStringLiteral("schedule/end"), endTime_).toString();
    breakEnabled_ = settings_.value(QStringLiteral("schedule/breakEnabled"), breakEnabled_).toBool();
    breakStart_ = settings_.value(QStringLiteral("schedule/breakStart"), breakStart_).toString();
    breakEnd_ = settings_.value(QStringLiteral("schedule/breakEnd"), breakEnd_).toString();
    workdaysMask_ = settings_.value(QStringLiteral("schedule/workdaysMask"), workdaysMask_).toUInt();
    scheduleMode_ = settings_.value(QStringLiteral("schedule/mode"), scheduleMode_).toString();
    if (scheduleMode_ != QLatin1String("fixed") &&
        scheduleMode_ != QLatin1String("alternating")) {
        scheduleMode_ = QStringLiteral("fixed");
    }
    bigWeekMask_ = settings_.value(QStringLiteral("schedule/bigWeekMask"), bigWeekMask_).toUInt();
    smallWeekMask_ = settings_.value(QStringLiteral("schedule/smallWeekMask"), smallWeekMask_).toUInt();
    rotationAnchorIsBigWeek_ = settings_.value(QStringLiteral("schedule/anchorIsBigWeek"),
                                                rotationAnchorIsBigWeek_).toBool();
    const QDate savedAnchor = QDate::fromString(
        settings_.value(QStringLiteral("schedule/rotationAnchorMonday")).toString(),
        QStringLiteral("yyyy-MM-dd"));
    if (savedAnchor.isValid()) {
        rotationAnchorMonday_ = savedAnchor.addDays(1 - savedAnchor.dayOfWeek());
    }

    if (salaryAmount_ < 0.0 || !std::isfinite(salaryAmount_)) salaryAmount_ = 0.0;
    if (monthlyWorkDays_ < 1.0 || monthlyWorkDays_ > 31.0) monthlyWorkDays_ = 21.75;
    if (!validClock(startTime_)) startTime_ = QStringLiteral("09:00");
    if (!validClock(endTime_)) endTime_ = QStringLiteral("18:00");
    if (!validClock(breakStart_)) breakStart_ = QStringLiteral("12:00");
    if (!validClock(breakEnd_)) breakEnd_ = QStringLiteral("13:00");
    workdaysMask_ &= 0b01111111;
    bigWeekMask_ &= 0b01111111;
    smallWeekMask_ &= 0b01111111;

    const QDate today = QDate::currentDate();
    const QString savedExperienceDate = settings_.value(
        QStringLiteral("experience/processedThrough")).toString();
    experienceProcessedThrough_ = QDate::fromString(savedExperienceDate,
                                                     QStringLiteral("yyyy-MM-dd"));
    completedWorkdays_ = std::clamp(settings_.value(
        QStringLiteral("experience/completedWorkdays"), 0).toInt(), 0, 10000000);
    if (!experienceProcessedThrough_.isValid()) {
        // 首次启用经验系统时只追踪今天起的排班，不虚构此前的上班天数。
        QDate trackingStart = today;
        const QDateTime now = networkClock_.currentDateTime();
        const ShiftWindow previousShift = shiftForDate(today.addDays(-1));
        const bool previousShiftActive = previousShift.isWorkday &&
                                         now >= previousShift.start &&
                                         now < previousShift.end;
        const bool previousOvernightJustFinished = previousShift.isWorkday &&
                                                   previousShift.end.date() == today &&
                                                   now >= previousShift.end;
        if (previousShiftActive || previousOvernightJustFinished) {
            trackingStart = previousShift.date;
        }
        experienceProcessedThrough_ = trackingStart.addDays(-1);
        saveExperienceSettings();
    }
}

bool WorkTimer::saveSettings() {
    settings_.setValue(QStringLiteral("ui/windowPinned"), windowPinned_);
    settings_.setValue(QStringLiteral("pay/mode"), salaryMode_);
    settings_.setValue(QStringLiteral("pay/amount"), salaryAmount_);
    settings_.setValue(QStringLiteral("pay/monthlyWorkDays"), monthlyWorkDays_);
    settings_.setValue(QStringLiteral("schedule/start"), startTime_);
    settings_.setValue(QStringLiteral("schedule/end"), endTime_);
    settings_.setValue(QStringLiteral("schedule/breakEnabled"), breakEnabled_);
    settings_.setValue(QStringLiteral("schedule/breakStart"), breakStart_);
    settings_.setValue(QStringLiteral("schedule/breakEnd"), breakEnd_);
    settings_.setValue(QStringLiteral("schedule/workdaysMask"), workdaysMask_);
    settings_.setValue(QStringLiteral("schedule/mode"), scheduleMode_);
    settings_.setValue(QStringLiteral("schedule/bigWeekMask"), bigWeekMask_);
    settings_.setValue(QStringLiteral("schedule/smallWeekMask"), smallWeekMask_);
    settings_.setValue(QStringLiteral("schedule/rotationAnchorMonday"),
                       rotationAnchorMonday_.toString(QStringLiteral("yyyy-MM-dd")));
    settings_.setValue(QStringLiteral("schedule/anchorIsBigWeek"), rotationAnchorIsBigWeek_);
    settings_.setValue(QStringLiteral("experience/completedWorkdays"), completedWorkdays_);
    settings_.setValue(QStringLiteral("experience/processedThrough"),
                       experienceProcessedThrough_.toString(QStringLiteral("yyyy-MM-dd")));
    settings_.sync();
    return settings_.status() == QSettings::NoError;
}

void WorkTimer::saveExperienceSettings() {
    settings_.setValue(QStringLiteral("experience/completedWorkdays"), completedWorkdays_);
    settings_.setValue(QStringLiteral("experience/processedThrough"),
                       experienceProcessedThrough_.toString(QStringLiteral("yyyy-MM-dd")));
    settings_.sync();
}

void WorkTimer::updateExperience(const QDateTime &now, bool hasActiveShift) {
    bool changed = false;
    const QDate today = now.date();

    // 按时间顺序结算错过的完整班次，确保应用关闭后重开也不会重复或漏算。
    while (experienceProcessedThrough_.isValid()) {
        const QDate candidateDate = experienceProcessedThrough_.addDays(1);
        if (candidateDate > today) break;

        const ShiftWindow candidate = shiftForDate(candidateDate);
        if (!candidate.isWorkday || paidDurationMs(candidate) <= 0) {
            // 保留今天的游标，允许用户当天调整排班后仍纳入经验计算。
            if (candidateDate == today) break;
            experienceProcessedThrough_ = candidateDate;
            changed = true;
            continue;
        }
        if (candidate.start > now || candidate.end > now) break;

        ++completedWorkdays_;
        experienceProcessedThrough_ = candidateDate;
        changed = true;
    }

    if (changed) saveExperienceSettings();

    const double inProgressWorkday = hasActiveShift ? progress_ : 0.0;
    const double totalExperience = completedWorkdays_ * kExperiencePerWorkday +
                                   inProgressWorkday * kExperiencePerWorkday;
    experienceLevel_ = static_cast<int>(std::floor(totalExperience / kExperiencePerLevel)) + 1;
    const double pointsInLevel = std::fmod(totalExperience, kExperiencePerLevel);
    experiencePoints_ = static_cast<int>(std::floor(pointsInLevel));
    experienceProgress_ = std::clamp(pointsInLevel / kExperiencePerLevel, 0.0, 1.0);
    if (historyStore_) historyStore_->updateUnlocks(completedWorkdays_, experienceLevel_);
}

// 补结算上次启动后错过的完整排班日；每个日期只写一条估算记录。
void WorkTimer::settleHistory(const QDateTime &now) {
    if (!historyStore_) return;
    if (!historyStore_->storageError().isEmpty()) return;
    QDate firstDate = historyStore_->latestRecordDate();
    firstDate = firstDate.isValid() ? firstDate.addDays(1) : now.date();
    if (firstDate.daysTo(now.date()) > 1825) firstDate = now.date().addDays(-1825);

    for (QDate date = firstDate; date <= now.date(); date = date.addDays(1)) {
        const ShiftWindow shift = shiftForDate(date);
        if (!shift.isWorkday || shift.end > now) continue;

        const qint64 plannedMs = paidDurationMs(shift);
        const qint64 workedMs = paidElapsedMs(shift, now);
        const qint64 incomeCents = static_cast<qint64>(std::llround(
            static_cast<long double>(hourlyRateCents(shift)) * workedMs / kMsPerHour));
        const QVariantMap record{
            {QStringLiteral("date"), date.toString(Qt::ISODate)},
            {QStringLiteral("settled"), true},
            {QStringLiteral("scheduled"), true},
            {QStringLiteral("incomeCents"), incomeCents},
            {QStringLiteral("workMilliseconds"), workedMs},
            {QStringLiteral("plannedMilliseconds"), plannedMs},
            {QStringLiteral("shiftStart"), shift.start.toString(Qt::ISODate)},
            {QStringLiteral("shiftEnd"), shift.end.toString(Qt::ISODate)},
            {QStringLiteral("breakStart"), shift.breakStart.toString(Qt::ISODate)},
            {QStringLiteral("breakEnd"), shift.breakEnd.toString(Qt::ISODate)},
            {QStringLiteral("salaryMode"), salaryMode_}};
        if (!historyStore_->recordCompletedDay(record)) break;
    }
}

// 合并排班节点和自定义事项，按时间生成今日状态时间线。
void WorkTimer::updateTimeline(const ShiftWindow &shift, const QDateTime &now) {
    struct TimelineItem {
        QDateTime at;
        QVariantMap value;
    };
    QVector<TimelineItem> items;

    const auto appendItem = [&items](const QString &id, const QString &title,
                                     const QDateTime &at, bool custom,
                                     bool manuallyDone) {
        if (!at.isValid()) return;
        items.append({at, {{QStringLiteral("id"), id},
                           {QStringLiteral("title"), title},
                           {QStringLiteral("time"), at.toString(QStringLiteral("HH:mm"))},
                           {QStringLiteral("timestamp"), at.toMSecsSinceEpoch()},
                           {QStringLiteral("custom"), custom},
                           {QStringLiteral("manualDone"), manuallyDone}}});
    };

    if (shift.isWorkday) {
        appendItem(QStringLiteral("shift-start"), QStringLiteral("上班打卡"),
                   shift.start, false, false);
        if (breakEnabled_ && overlapMs(shift.start, shift.end,
                                       shift.breakStart, shift.breakEnd) > 0) {
            appendItem(QStringLiteral("break-start"), QStringLiteral("休息 / 摸鱼"),
                       shift.breakStart, false, false);
            appendItem(QStringLiteral("break-end"), QStringLiteral("继续搬砖"),
                       shift.breakEnd, false, false);
        }
        appendItem(QStringLiteral("shift-end"), QStringLiteral("下班自由"),
                   shift.end, false, false);
    } else {
        appendItem(QStringLiteral("rest-day"), QStringLiteral("今天休息，享受自由"),
                   QDateTime(shift.date, QTime(12, 0)), false, false);
    }

    if (historyStore_) {
        for (const QVariant &taskValue : historyStore_->todayTasks()) {
            const QVariantMap task = taskValue.toMap();
            QDateTime at = atLocalTime(shift.date,
                                       task.value(QStringLiteral("time")).toString());
            if (shift.end.date() > shift.date && at < shift.start) at = at.addDays(1);
            appendItem(task.value(QStringLiteral("id")).toString(),
                       task.value(QStringLiteral("title")).toString(), at, true,
                       task.value(QStringLiteral("done")).toBool());
        }
    }

    std::sort(items.begin(), items.end(), [](const TimelineItem &left,
                                             const TimelineItem &right) {
        return left.at < right.at;
    });
    int currentIndex = -1;
    if (shift.isWorkday && now >= shift.start && now < shift.end) {
        for (int i = 0; i < items.size(); ++i) {
            if (items.at(i).at <= now) currentIndex = i;
        }
    }

    timelineTasks_.clear();
    for (int i = 0; i < items.size(); ++i) {
        QVariantMap item = items.at(i).value;
        const bool current = i == currentIndex;
        const bool done = item.value(QStringLiteral("custom")).toBool()
                              ? item.value(QStringLiteral("manualDone")).toBool()
                              : items.at(i).at <= now;
        item.insert(QStringLiteral("current"), current);
        item.insert(QStringLiteral("done"), done);
        item.insert(QStringLiteral("state"), current ? QStringLiteral("current")
                          : done ? QStringLiteral("done") : QStringLiteral("pending"));
        item.remove(QStringLiteral("timestamp"));
        item.remove(QStringLiteral("manualDone"));
        timelineTasks_.append(item);
    }
}

bool WorkTimer::validClock(const QString &value) const {
    const QTime parsed = QTime::fromString(value, QStringLiteral("HH:mm"));
    return parsed.isValid() && parsed.toString(QStringLiteral("HH:mm")) == value;
}

void WorkTimer::setSalaryMode(const QString &value) {
    if (value != QLatin1String("monthly") && value != QLatin1String("daily") &&
        value != QLatin1String("hourly")) return;
    salaryMode_ = value;
    saveSettings();
    emit settingsChanged();
    refresh();
}

void WorkTimer::setSalaryAmount(double value) {
    if (!std::isfinite(value) || value < 0.0 || value > 100000000.0) return;
    salaryAmount_ = value;
    saveSettings();
    emit settingsChanged();
    refresh();
}

void WorkTimer::setMonthlyWorkDays(double value) {
    if (!std::isfinite(value) || value < 1.0 || value > 31.0) return;
    monthlyWorkDays_ = value;
    saveSettings();
    emit settingsChanged();
    refresh();
}

void WorkTimer::setStartTime(const QString &value) {
    if (!validClock(value) || value == endTime_) return;
    startTime_ = value;
    saveSettings();
    emit settingsChanged();
    refresh();
}

void WorkTimer::setEndTime(const QString &value) {
    if (!validClock(value) || value == startTime_) return;
    endTime_ = value;
    saveSettings();
    emit settingsChanged();
    refresh();
}

void WorkTimer::setWindowPinned(bool value) {
    if (windowPinned_ == value) return;
    windowPinned_ = value;
    const bool saved = saveSettings();
    emit settingsChanged();
    emit toast(saved ? (windowPinned_ ? QStringLiteral("窗口已固定在最前")
                                     : QStringLiteral("已取消窗口置顶"))
                     : QStringLiteral("置顶状态保存失败，请检查应用目录权限或磁盘空间"));
}

void WorkTimer::setBreakEnabled(bool value) {
    breakEnabled_ = value;
    saveSettings();
    emit settingsChanged();
    refresh();
}

void WorkTimer::setBreakStart(const QString &value) {
    if (!validClock(value)) return;
    breakStart_ = value;
    saveSettings();
    emit settingsChanged();
    refresh();
}

void WorkTimer::setBreakEnd(const QString &value) {
    if (!validClock(value)) return;
    breakEnd_ = value;
    saveSettings();
    emit settingsChanged();
    refresh();
}

// 切换固定周或大小周规则后持久化并重新计算最近排班。
void WorkTimer::setScheduleMode(const QString &value) {
    if (value != QLatin1String("fixed") && value != QLatin1String("alternating")) return;
    scheduleMode_ = value;
    saveSettings();
    emit settingsChanged();
    refresh();
}

void WorkTimer::setCompletedWorkdays(int value) {
    const int clamped = std::clamp(value, 0, 10000000);
    if (completedWorkdays_ == clamped) return;

    completedWorkdays_ = clamped;
    const QDateTime now = networkClock_.currentDateTime();
    bool activeShiftFound = false;
    for (int offset = -1; offset <= 0; ++offset) {
        const ShiftWindow candidate = shiftForDate(now.date().addDays(offset));
        if (!candidate.isWorkday || now < candidate.start || now >= candidate.end) continue;
        experienceProcessedThrough_ = candidate.date.addDays(-1);
        activeShiftFound = true;
        break;
    }

    if (!activeShiftFound) {
        const ShiftWindow todayShift = shiftForDate(now.date());
        experienceProcessedThrough_ = todayShift.isWorkday && todayShift.end <= now
            ? now.date() : now.date().addDays(-1);
    }

    saveExperienceSettings();
    refresh();
    emit toast(QStringLiteral("累计上班天数已设为 %1 天").arg(completedWorkdays_));
}

bool WorkTimer::setShiftTimes(const QString &start, const QString &end) {
    if (!validClock(start) || !validClock(end) || start == end) return false;
    startTime_ = start;
    endTime_ = end;
    saveSettings();
    emit settingsChanged();
    refresh();
    return true;
}

bool WorkTimer::worksOn(int weekdayIndex) const {
    if (weekdayIndex < 0 || weekdayIndex > 6) return false;
    return (workdaysMask_ & (1u << static_cast<unsigned int>(weekdayIndex))) != 0;
}

void WorkTimer::setWorksOn(int weekdayIndex, bool enabled) {
    if (weekdayIndex < 0 || weekdayIndex > 6) return;
    const unsigned int bit = 1u << static_cast<unsigned int>(weekdayIndex);
    workdaysMask_ = enabled ? (workdaysMask_ | bit) : (workdaysMask_ & ~bit);
    saveSettings();
    emit settingsChanged();
    refresh();
}

// 查询指定周类型在某个周几是否排班。
bool WorkTimer::worksOnPattern(bool bigWeek, int weekdayIndex) const {
    if (weekdayIndex < 0 || weekdayIndex > 6) return false;
    const unsigned int mask = bigWeek ? bigWeekMask_ : smallWeekMask_;
    return (mask & (1u << static_cast<unsigned int>(weekdayIndex))) != 0;
}

// 更新大周或小周对应的上班日掩码并立即刷新排班。
void WorkTimer::setWorksOnPattern(bool bigWeek, int weekdayIndex, bool enabled) {
    if (weekdayIndex < 0 || weekdayIndex > 6) return;
    unsigned int &mask = bigWeek ? bigWeekMask_ : smallWeekMask_;
    const unsigned int bit = 1u << static_cast<unsigned int>(weekdayIndex);
    mask = enabled ? (mask | bit) : (mask & ~bit);
    saveSettings();
    emit settingsChanged();
    refresh();
}

// 将本周周一设为轮换锚点，并指定本周属于大周还是小周。
void WorkTimer::setCurrentWeekAsBig(bool bigWeek) {
    const QDate today = QDate::currentDate();
    rotationAnchorMonday_ = today.addDays(1 - today.dayOfWeek());
    rotationAnchorIsBigWeek_ = bigWeek;
    saveSettings();
    emit settingsChanged();
    refresh();
}

bool WorkTimer::applySettings() {
    const bool saved = saveSettings();
    emit settingsChanged();
    refresh();
    emit toast(saved ? QStringLiteral("设置已保存到本机")
                     : QStringLiteral("保存失败，请检查应用目录权限或磁盘空间"));
    return saved;
}

bool WorkTimer::isScheduledWorkday(const QDate &date) const {
    const int holidayOverride = holidayCalendar_.scheduleOverride(date);
    if (holidayOverride >= 0) return holidayOverride == 1;
    const int index = date.dayOfWeek() - 1; // QDate：周一为 1，掩码从 0 开始
    if (index < 0 || index > 6) return false;
    if (scheduleMode_ == QLatin1String("fixed")) {
        return (workdaysMask_ & (1u << static_cast<unsigned int>(index))) != 0;
    }

    // 以锚点所在周为大小周起点；按相邻周数奇偶自动切换周类型。
    const QDate targetMonday = date.addDays(1 - date.dayOfWeek());
    const int weekOffset = rotationAnchorMonday_.daysTo(targetMonday) / 7;
    const bool isBigWeek = (weekOffset % 2 == 0)
                               ? rotationAnchorIsBigWeek_
                               : !rotationAnchorIsBigWeek_;
    const unsigned int mask = isBigWeek ? bigWeekMask_ : smallWeekMask_;
    return (mask & (1u << static_cast<unsigned int>(index))) != 0;
}

WorkTimer::ShiftWindow WorkTimer::shiftForDate(const QDate &date) const {
    ShiftWindow shift;
    shift.date = date;
    shift.isWorkday = isScheduledWorkday(date);
    shift.start = atLocalTime(date, startTime_);
    shift.end = atLocalTime(date, endTime_);
    if (shift.end <= shift.start) shift.end = shift.end.addDays(1);

    // 跨午夜班次遇到次日法定放假时，在放假日零点结束前一日班次。
    for (QDate day = date.addDays(1); day <= shift.end.date(); day = day.addDays(1)) {
        if (holidayCalendar_.scheduleOverride(day) != 0) continue;
        const QDateTime holidayStart = atLocalTime(day, QStringLiteral("00:00"));
        if (holidayStart > shift.start && holidayStart < shift.end) shift.end = holidayStart;
        break;
    }

    shift.breakStart = atLocalTime(date, breakStart_);
    shift.breakEnd = atLocalTime(date, breakEnd_);
    if (shift.breakStart < shift.start) {
        shift.breakStart = shift.breakStart.addDays(1);
        shift.breakEnd = shift.breakEnd.addDays(1);
    }
    if (shift.breakEnd <= shift.breakStart) shift.breakEnd = shift.breakEnd.addDays(1);
    return shift;
}

qint64 WorkTimer::overlapMs(const QDateTime &aStart, const QDateTime &aEnd,
                            const QDateTime &bStart, const QDateTime &bEnd) {
    const QDateTime start = std::max(aStart, bStart);
    const QDateTime end = std::min(aEnd, bEnd);
    return end > start ? start.msecsTo(end) : 0;
}

qint64 WorkTimer::paidDurationMs(const ShiftWindow &shift) const {
    if (!shift.isWorkday) return 0;
    const qint64 total = shift.start.msecsTo(shift.end);
    if (!breakEnabled_) return total;
    return std::max<qint64>(0, total - overlapMs(shift.start, shift.end,
                                               shift.breakStart, shift.breakEnd));
}

qint64 WorkTimer::paidElapsedMs(const ShiftWindow &shift, const QDateTime &now) const {
    const QDateTime finish = std::min(now, shift.end);
    if (finish <= shift.start) return 0;
    qint64 elapsed = shift.start.msecsTo(finish);
    if (breakEnabled_) {
        elapsed -= overlapMs(shift.start, finish, shift.breakStart, shift.breakEnd);
    }
    return std::clamp<qint64>(elapsed, 0, paidDurationMs(shift));
}

qint64 WorkTimer::paidWithinDate(const ShiftWindow &shift, const QDateTime &now,
                                 const QDate &date) const {
    if (!shift.isWorkday) return 0;
    const QDateTime dayStart(date, QTime(0, 0));
    const QDateTime dayEnd(dayStart.addDays(1));
    const QDateTime start = std::max(shift.start, dayStart);
    const QDateTime end = std::min(std::min(now, shift.end), dayEnd);
    if (end <= start) return 0;

    qint64 elapsed = start.msecsTo(end);
    if (breakEnabled_) {
        elapsed -= overlapMs(start, end, shift.breakStart, shift.breakEnd);
    }
    return std::max<qint64>(0, elapsed);
}

qint64 WorkTimer::hourlyRateCents(const ShiftWindow &shift) const {
    const qint64 plannedMs = paidDurationMs(shift);
    if (plannedMs <= 0) return 0;
    long double cents = static_cast<long double>(salaryAmount_) * 100.0L;
    if (salaryMode_ == QLatin1String("daily")) {
        cents = cents * kMsPerHour / plannedMs;
    } else if (salaryMode_ == QLatin1String("monthly")) {
        const long double paidHours = static_cast<long double>(plannedMs) / kMsPerHour;
        const long double monthlyHours = paidHours * monthlyWorkDays_;
        cents = monthlyHours > 0.0L ? cents / monthlyHours : 0.0L;
    }
    return static_cast<qint64>(std::llround(cents));
}

QString WorkTimer::formatDuration(qint64 milliseconds) {
    const qint64 seconds = std::max<qint64>(0, milliseconds / kMsPerSecond);
    const qint64 hours = seconds / 3600;
    const qint64 minutes = (seconds % 3600) / 60;
    const qint64 remainder = seconds % 60;
    return QStringLiteral("%1:%2:%3")
        .arg(hours, 2, 10, QLatin1Char('0'))
        .arg(minutes, 2, 10, QLatin1Char('0'))
        .arg(remainder, 2, 10, QLatin1Char('0'));
}

QString WorkTimer::formatMoney(qint64 cents) {
    return QLocale(QLocale::Chinese, QLocale::China).toString(
        static_cast<double>(cents) / 100.0, 'f', 2);
}

void WorkTimer::refresh() {
    const QDateTime now = networkClock_.currentDateTime();
    // 法定放假日和官方调休上班日覆盖个人周排班，并统一影响工资、经验与历史结算。
    holiday_ = holidayCalendar_.snapshot(now);
    const QDate today = now.date();
    settleHistory(now);
    dateText_ = QLocale(QLocale::Chinese, QLocale::China)
                    .toString(today, QStringLiteral("yyyy年M月d日 dddd"));
    shiftText_ = startTime_ + QStringLiteral(" — ") + endTime_;

    ShiftWindow current;
    bool foundActive = false;
    for (int offset = -1; offset <= 0; ++offset) {
        const ShiftWindow candidate = shiftForDate(today.addDays(offset));
        if (candidate.isWorkday && now >= candidate.start && now < candidate.end) {
            current = candidate;
            foundActive = true;
            break;
        }
    }

    ShiftWindow displayShift;
    bool hasDisplayShift = false;
    bool nextIsToday = false;
    if (foundActive) {
        displayShift = current;
        hasDisplayShift = true;
    } else {
        for (int offset = 0; offset <= 14; ++offset) {
            const ShiftWindow candidate = shiftForDate(today.addDays(offset));
            if (candidate.isWorkday && candidate.start > now) {
                displayShift = candidate;
                hasDisplayShift = true;
                nextIsToday = offset == 0;
                break;
            }
        }
    }

    const bool todayIsWorkday = isScheduledWorkday(today);
    const ShiftWindow todayShift = shiftForDate(today);
    const qint64 todayPaidMs = paidDurationMs(todayShift);
    const qint64 rate = hourlyRateCents(hasDisplayShift ? displayShift : todayShift);
    hourlyText_ = formatMoney(rate);
    paidDayText_ = QStringLiteral("%1 小时").arg(
        static_cast<double>(todayPaidMs) / kMsPerHour, 0, 'f', 1);

    qint64 earnedCents = 0;
    for (int offset = -1; offset <= 0; ++offset) {
        const ShiftWindow candidate = shiftForDate(today.addDays(offset));
        if (!candidate.isWorkday) continue;
        const qint64 earnedPaidMs = paidWithinDate(candidate, now, today);
        earnedCents += static_cast<qint64>(std::llround(
            static_cast<long double>(hourlyRateCents(candidate)) * earnedPaidMs / kMsPerHour));
    }
    earnedText_ = formatMoney(earnedCents);

    if (foundActive) {
        const qint64 elapsed = paidElapsedMs(current, now);
        const qint64 plan = paidDurationMs(current);
        progress_ = plan > 0 ? std::clamp(static_cast<double>(elapsed) / plan, 0.0, 1.0) : 0.0;
        countdownLabel_ = QStringLiteral("距离下班还有");
        countdownText_ = formatDuration(now.msecsTo(current.end));
        statusKind_ = current.breakStart <= now && now < current.breakEnd && breakEnabled_
                          ? QStringLiteral("rest") : QStringLiteral("work");
        statusText_ = statusKind_ == QLatin1String("rest")
                          ? QStringLiteral("休息时间，工资暂停累计")
                          : QStringLiteral("正在打工，工资持续累计");
        earnedTimeText_ = formatDuration(elapsed);
    } else if (hasDisplayShift) {
        progress_ = 0.0;
        countdownLabel_ = nextIsToday ? QStringLiteral("距离上班还有")
                                      : QStringLiteral("距离下个工作日还有");
        countdownText_ = formatDuration(now.msecsTo(displayShift.start));
        statusKind_ = QStringLiteral("before");
        if (todayIsWorkday) {
            statusText_ = holiday_.value(QStringLiteral("todayMakeupWorkday")).toBool()
                ? QStringLiteral("官方调休补班日，按设置班次上班")
                : QStringLiteral("还没到上班时间");
        } else {
            const QString holidayName = holidayCalendar_.holidayNameOn(today);
            statusText_ = holidayName.isEmpty()
                ? QStringLiteral("今天是休息日")
                : QStringLiteral("%1法定假期休息，不计工时和工资").arg(holidayName);
        }
        earnedTimeText_ = QStringLiteral("00:00:00");
    } else {
        progress_ = 0.0;
        countdownLabel_ = QStringLiteral("当前没有排班日");
        countdownText_ = QStringLiteral("--:--:--");
        statusKind_ = QStringLiteral("off");
        statusText_ = QStringLiteral("请在设置里选择工作日");
        earnedTimeText_ = QStringLiteral("00:00:00");
    }

    if (todayIsWorkday && todayShift.end <= now) {
        progress_ = 1.0;
        statusKind_ = QStringLiteral("done");
        statusText_ = QStringLiteral("今天已经下班啦");
        earnedTimeText_ = formatDuration(todayPaidMs);
    }
    updateExperience(now, foundActive);
    progressText_ = QStringLiteral("%1%").arg(qRound(progress_ * 100.0));

    const ShiftWindow summaryShift = foundActive ? current : todayShift;
    const qint64 summaryElapsed = summaryShift.isWorkday
                                      ? paidElapsedMs(summaryShift, now) : 0;
    const qint64 summaryRate = hourlyRateCents(summaryShift);
    const qint64 summaryIncome = static_cast<qint64>(std::llround(
        static_cast<long double>(summaryRate) * summaryElapsed / kMsPerHour));
    const qint64 summaryPlan = summaryShift.isWorkday
                                   ? paidDurationMs(summaryShift) : 0;
    liveSummary_ = {{QStringLiteral("date"), summaryShift.date.toString(Qt::ISODate)},
                    {QStringLiteral("scheduled"), summaryShift.isWorkday},
                    {QStringLiteral("settled"), summaryShift.isWorkday && summaryShift.end <= now},
                    {QStringLiteral("incomeCents"), summaryIncome},
                    {QStringLiteral("plannedIncomeCents"),
                     static_cast<qint64>(std::llround(
                         static_cast<long double>(summaryRate) * summaryPlan / kMsPerHour))},
                    {QStringLiteral("workMilliseconds"), summaryElapsed},
                    {QStringLiteral("plannedMilliseconds"), summaryPlan},
                    {QStringLiteral("status"), statusKind_}};
    freeValue_ = qRound(progress_ * 100.0);

    if (breakEnabled_ && summaryShift.isWorkday) {
        const qint64 plannedRest = overlapMs(summaryShift.start, summaryShift.end,
                                             summaryShift.breakStart,
                                             summaryShift.breakEnd);
        const QDateTime restEnd = std::min(now, summaryShift.breakEnd);
        const qint64 elapsedRest = std::clamp<qint64>(
            overlapMs(summaryShift.breakStart, restEnd, summaryShift.start,
                      summaryShift.end), 0, plannedRest);
        fishingValue_ = plannedRest > 0
                            ? qRound(static_cast<double>(elapsedRest) * 100.0 / plannedRest)
                            : 0;
    } else {
        fishingValue_ = 0;
    }

    if (historyStore_) historyStore_->setCurrentDate(summaryShift.date);
    updateTimeline(summaryShift, now);
    emit snapshotChanged();
}

void WorkTimer::syncNetworkTime() {
    networkClock_.syncNow();
}
