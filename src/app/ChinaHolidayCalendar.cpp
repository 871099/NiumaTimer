#include "ChinaHolidayCalendar.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimeZone>

#include <algorithm>

namespace {
constexpr int kBeijingOffset = 8 * 60 * 60;

// 使用固定 UTC+8，中国大陆当前不实行夏令时。
QDateTime beijingMidnight(const QDate &date) {
    return QDateTime(date, QTime(0, 0), QTimeZone::fromSecondsAheadOfUtc(kBeijingOffset));
}

QString durationText(qint64 seconds) {
    seconds = std::max<qint64>(0, seconds);
    return QStringLiteral("%1天 %2:%3:%4")
        .arg(seconds / 86400)
        .arg((seconds % 86400) / 3600, 2, 10, QLatin1Char('0'))
        .arg((seconds % 3600) / 60, 2, 10, QLatin1Char('0'))
        .arg(seconds % 60, 2, 10, QLatin1Char('0'));
}
}

// 年历随程序离线发布；无效数据整体拒绝，避免给出错误放假日期。
ChinaHolidayCalendar::ChinaHolidayCalendar() {
    QFile file(QStringLiteral(":/holidays/china-holidays.json"));
    if (!file.open(QIODevice::ReadOnly)) {
        loadError_ = QStringLiteral("节假日数据不可用");
        return;
    }
    QJsonParseError error;
    const auto document = QJsonDocument::fromJson(file.readAll(), &error);
    const auto root = document.object();
    if (error.error != QJsonParseError::NoError || root.value("schemaVersion").toInt() != 1) {
        loadError_ = QStringLiteral("节假日数据格式不受支持");
        return;
    }
    for (const auto &yearValue : root.value("years").toArray()) {
        const auto year = yearValue.toObject();
        for (const auto &value : year.value("holidays").toArray()) {
            const auto item = value.toObject();
            Holiday holiday;
            holiday.name = item.value("name").toString();
            holiday.start = QDate::fromString(item.value("start").toString(), Qt::ISODate);
            holiday.end = QDate::fromString(item.value("end").toString(), Qt::ISODate);
            holiday.sourceUrl = year.value("sourceUrl").toString();
            holiday.sourceTitle = year.value("sourceTitle").toString();
            bool valid = !holiday.name.isEmpty() && holiday.start.isValid() && holiday.end.isValid()
                && holiday.end >= holiday.start && holiday.start.year() == year.value("year").toInt()
                && holiday.end.year() == holiday.start.year() && holiday.start.daysTo(holiday.end) < 31
                && holiday.sourceUrl.startsWith(QStringLiteral("https://"));
            for (const auto &makeup : item.value("makeupDays").toArray()) {
                const auto day = QDate::fromString(makeup.toString(), Qt::ISODate);
                valid = valid && day.isValid() && day.year() == holiday.start.year()
                    && (day < holiday.start || day > holiday.end);
                holiday.makeupDays.append(day.toString(Qt::ISODate));
            }
            if (!valid) {
                holidays_.clear();
                loadError_ = QStringLiteral("节假日数据校验失败");
                return;
            }
            holidays_.append(holiday);
        }
    }
    std::sort(holidays_.begin(), holidays_.end(), [](const Holiday &a, const Holiday &b) {
        return a.start < b.start;
    });
    if (holidays_.isEmpty()) {
        loadError_ = QStringLiteral("尚无已公布的节假日安排");
        return;
    }
    // 仅衔接最后已公布年度后的元旦法定日期，不推测尚未公布的连休/农历假期。
    Holiday newYear;
    newYear.name = QStringLiteral("元旦");
    newYear.start = newYear.end = QDate(holidays_.last().end.year() + 1, 1, 1);
    newYear.confirmed = false;
    newYear.sourceUrl = QStringLiteral("https://www.gov.cn/zhengce/content/202411/content_6986380.htm");
    newYear.sourceTitle = QStringLiteral("全国年节及纪念日放假办法：元旦法定日期为1月1日");
    holidays_.append(newYear);
}

// 法定放假日压过固定周/大小周，公告中的调休上班日恢复正常班次。
int ChinaHolidayCalendar::scheduleOverride(const QDate &date) const {
    if (!date.isValid() || !loadError_.isEmpty()) return -1;
    const QString day = date.toString(Qt::ISODate);
    // 先查全部补班日期，确保补班规则优先于任何放假区间。
    for (const auto &holiday : holidays_)
        if (holiday.makeupDays.contains(day)) return 1;
    for (const auto &holiday : holidays_) {
        if (holiday.start <= date && date <= holiday.end) return 0;
    }
    return -1;
}

// 获取放假区间当日名称，用于首页说明今天为何停班。
QString ChinaHolidayCalendar::holidayNameOn(const QDate &date) const {
    if (!date.isValid() || !loadError_.isEmpty()) return {};
    for (const auto &holiday : holidays_)
        if (holiday.start <= date && date <= holiday.end) return holiday.name;
    return {};
}

// 将日期、调休和来源放进同一展示模型，供首页和详情复用。
QVariantMap ChinaHolidayCalendar::describe(const Holiday &holiday, const QDate &today) {
    const auto dateText = holiday.start.toString(QStringLiteral("yyyy.MM.dd"))
        + (holiday.start == holiday.end ? QString() : QStringLiteral(" — ")
            + holiday.end.toString(QStringLiteral("MM.dd")));
    return {{"name", holiday.name}, {"start", holiday.start.toString(Qt::ISODate)},
            {"end", holiday.end.toString(Qt::ISODate)}, {"dateText", dateText},
            {"days", holiday.start.daysTo(holiday.end) + 1}, {"confirmed", holiday.confirmed},
            {"makeupText", !holiday.confirmed ? QStringLiteral("连休及调休安排待公布")
                : holiday.makeupDays.isEmpty() ? QStringLiteral("无额外调休上班日")
                : QStringLiteral("调休上班：") + holiday.makeupDays.join(QStringLiteral("、"))},
            {"sourceUrl", holiday.sourceUrl}, {"sourceTitle", holiday.sourceTitle},
            {"past", today > holiday.end}};
}

QVariantMap ChinaHolidayCalendar::snapshot(const QDateTime &now) const {
    QVariantMap result{{"available", false}, {"ongoing", false}, {"confirmed", false},
                       {"label", QStringLiteral("中国法定节假日")}, {"name", QString()},
                       {"countdown", QStringLiteral("等待年历更新")}, {"dateText", QString()},
                       {"note", loadError_.isEmpty() ? QStringLiteral("后续放假安排尚未收录，请更新年历数据") : loadError_},
                       {"calendar", QVariantList{}}, {"todayHoliday", false},
                       {"todayHolidayName", QString()}, {"todayMakeupWorkday", false}};
    if (!now.isValid() || !loadError_.isEmpty()) return result;
    const QDate today = now.toOffsetFromUtc(kBeijingOffset).date();
    const int todayOverride = scheduleOverride(today);
    result["todayHoliday"] = todayOverride == 0;
    result["todayHolidayName"] = holidayNameOn(today);
    result["todayMakeupWorkday"] = todayOverride == 1;
    QVariantList calendar;
    const Holiday *next = nullptr;
    for (const auto &holiday : holidays_) {
        if (holiday.start.year() >= today.year()) calendar.append(describe(holiday, today));
        if (!next && now < beijingMidnight(holiday.end.addDays(1))) next = &holiday;
    }
    result["calendar"] = calendar;
    if (!next) return result;
    const bool ongoing = now >= beijingMidnight(next->start);
    const auto target = beijingMidnight(ongoing ? next->end.addDays(1) : next->start);
    // 向上取整秒数，零点前最后不足一秒仍显示一秒。
    const qint64 remaining = (now.msecsTo(target) + 999) / 1000;
    const auto description = describe(*next, today);
    for (auto it = description.cbegin(); it != description.cend(); ++it) result[it.key()] = it.value();
    result["available"] = true;
    result["ongoing"] = ongoing;
    result["label"] = ongoing ? QStringLiteral("%1假期进行中 · 剩余").arg(next->name)
                              : QStringLiteral("距离%1%2").arg(next->name, next->confirmed ? QStringLiteral("假期") : QStringLiteral("节日当天"));
    result["countdown"] = durationText(remaining);
    result["note"] = next->confirmed
        ? QStringLiteral("共%1天 · 北京时间 · 官方放假调休安排").arg(next->start.daysTo(next->end) + 1)
        : QStringLiteral("%1年连休及调休安排待公布；当前仅按1月1日法定日期倒计时").arg(next->start.year());
    return result;
}
