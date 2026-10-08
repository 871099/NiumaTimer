// 中国内地全体公民节假日：读取经核实的年历，按北京时间生成倒计时快照。
#pragma once

#include <QDateTime>
#include <QVariantList>
#include <QVariantMap>
#include <QStringList>
#include <QVector>

class ChinaHolidayCalendar final {
public:
    ChinaHolidayCalendar();
    // 输入沿用网络时钟；假期边界统一为北京时间零点，不受设备时区影响。
    QVariantMap snapshot(const QDateTime &now) const;
    // 0=法定放假日，1=公告调休上班日，-1=按固定周/大小周判断。
    int scheduleOverride(const QDate &date) const;
    QString holidayNameOn(const QDate &date) const;

private:
    struct Holiday {
        QString name;
        QDate start;
        QDate end;
        QStringList makeupDays;
        QString sourceUrl;
        QString sourceTitle;
        bool confirmed = true;
    };
    static QVariantMap describe(const Holiday &holiday, const QDate &today);
    QVector<Holiday> holidays_;
    QString loadError_;
};
