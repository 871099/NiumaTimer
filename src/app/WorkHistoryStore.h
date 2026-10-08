// 本地保存每日已结算快照、当日自定义事项与外观选择。
#pragma once

#include <QDate>
#include <QJsonObject>
#include <QMap>
#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

#include <functional>

#include "ChinaHolidayCalendar.h"

class WorkHistoryStore final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList records READ records NOTIFY historyChanged)
    Q_PROPERTY(QVariantList todayTasks READ todayTasks NOTIFY tasksChanged)
    Q_PROPERTY(QString selectedOutfit READ selectedOutfit NOTIFY appearanceChanged)
    Q_PROPERTY(QString dataPath READ dataPath CONSTANT)
    Q_PROPERTY(QString storageError READ storageError NOTIFY storageErrorChanged)

public:
    explicit WorkHistoryStore(QObject *parent = nullptr);
    // 提供独立存储路径，便于隔离验证迁移，不触碰用户本机历史。
    explicit WorkHistoryStore(const QString &dataPath, QObject *parent = nullptr);

    QVariantList records() const;
    QVariantList todayTasks() const;
    QString selectedOutfit() const { return selectedOutfit_; }
    QString dataPath() const { return dataPath_; }
    QString storageError() const { return storageError_; }

    // 计时器按校准后的班次日期切换当天任务列表。
    void setCurrentDate(const QDate &date);
    QDate latestRecordDate() const;
    // 已完成班次只允许首次写入，避免重复启动重复累计。
    bool recordCompletedDay(const QVariantMap &record);
    // 根据累计天数和等级补充永久解锁的外观。
    void updateUnlocks(int completedWorkdays, int level);

    Q_INVOKABLE bool addTask(const QString &title, const QString &time);
    Q_INVOKABLE bool updateTask(const QString &id, const QString &title,
                                const QString &time);
    Q_INVOKABLE bool removeTask(const QString &id);
    Q_INVOKABLE bool setTaskCompleted(const QString &id, bool completed);
    Q_INVOKABLE QVariantMap statistics(const QString &period,
                                       const QVariantMap &liveRecord) const;
    Q_INVOKABLE QVariantList chartBars(const QString &period,
                                       const QVariantMap &liveRecord) const;
    Q_INVOKABLE QVariantList achievements(int completedWorkdays, int level) const;
    Q_INVOKABLE QVariantList outfitOptions() const;
    Q_INVOKABLE bool selectOutfit(const QString &id);

signals:
    void historyChanged();
    void tasksChanged();
    void appearanceChanged();
    void storageErrorChanged();

private:
    bool load();
    // 将旧版误结算的法定放假日迁移为休息日，保留原快照和自定义任务。
    bool reconcileHolidayRecords();
    bool save();
    void setStorageError(const QString &message);
    QJsonObject dayObject(const QDate &date) const;
    QList<QDate> datesInPeriod(const QString &period, const QDate &today) const;
    QVariantMap recordForDate(const QDate &date,
                              const QVariantMap &liveRecord) const;
    bool updateTask(const QString &id,
                    const std::function<bool(QJsonObject &)> &change);

    QString dataPath_;
    QString storageError_;
    QString selectedOutfit_ = QStringLiteral("classic");
    QStringList unlockedOutfits_{QStringLiteral("classic")};
    QDate currentDate_ = QDate::currentDate();
    QMap<QString, QJsonObject> days_;
    bool writable_ = true;
    ChinaHolidayCalendar holidayCalendar_;
};
