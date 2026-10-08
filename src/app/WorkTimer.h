// 工作计时业务接口：向 QML 暴露工资、班次设置和当前工作快照。
#pragma once

#include <QDate>
#include <QDateTime>
#include <QObject>
#include <QPointer>
#include <QSettings>
#include <QString>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

#include "NetworkClock.h"
#include "ChinaHolidayCalendar.h"
#include "WorkHistoryStore.h"

class WorkTimer final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString countdownLabel READ countdownLabel NOTIFY snapshotChanged)
    Q_PROPERTY(QString countdownText READ countdownText NOTIFY snapshotChanged)
    Q_PROPERTY(QString earnedText READ earnedText NOTIFY snapshotChanged)
    Q_PROPERTY(QString hourlyText READ hourlyText NOTIFY snapshotChanged)
    Q_PROPERTY(QString progressText READ progressText NOTIFY snapshotChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY snapshotChanged)
    Q_PROPERTY(QString statusKind READ statusKind NOTIFY snapshotChanged)
    Q_PROPERTY(QString dateText READ dateText NOTIFY snapshotChanged)
    Q_PROPERTY(QString shiftText READ shiftText NOTIFY snapshotChanged)
    Q_PROPERTY(QString earnedTimeText READ earnedTimeText NOTIFY snapshotChanged)
    Q_PROPERTY(QString paidDayText READ paidDayText NOTIFY snapshotChanged)
    Q_PROPERTY(double progress READ progress NOTIFY snapshotChanged)
    Q_PROPERTY(int experienceLevel READ experienceLevel NOTIFY snapshotChanged)
    Q_PROPERTY(int experiencePoints READ experiencePoints NOTIFY snapshotChanged)
    Q_PROPERTY(double experienceProgress READ experienceProgress NOTIFY snapshotChanged)
    Q_PROPERTY(int freeValue READ freeValue NOTIFY snapshotChanged)
    Q_PROPERTY(int fishingValue READ fishingValue NOTIFY snapshotChanged)
    Q_PROPERTY(QVariantList timelineTasks READ timelineTasks NOTIFY snapshotChanged)
    Q_PROPERTY(QVariantMap liveSummary READ liveSummary NOTIFY snapshotChanged)
    Q_PROPERTY(int completedWorkdays READ completedWorkdays WRITE setCompletedWorkdays NOTIFY snapshotChanged)
    Q_PROPERTY(QString networkTimeStatusText READ networkTimeStatusText NOTIFY snapshotChanged)
    Q_PROPERTY(QVariantMap holiday READ holiday NOTIFY snapshotChanged)

    Q_PROPERTY(QString salaryMode READ salaryMode WRITE setSalaryMode NOTIFY settingsChanged)
    Q_PROPERTY(double salaryAmount READ salaryAmount WRITE setSalaryAmount NOTIFY settingsChanged)
    Q_PROPERTY(double monthlyWorkDays READ monthlyWorkDays WRITE setMonthlyWorkDays NOTIFY settingsChanged)
    Q_PROPERTY(QString startTime READ startTime WRITE setStartTime NOTIFY settingsChanged)
    Q_PROPERTY(QString endTime READ endTime WRITE setEndTime NOTIFY settingsChanged)
    Q_PROPERTY(bool breakEnabled READ breakEnabled WRITE setBreakEnabled NOTIFY settingsChanged)
    Q_PROPERTY(QString breakStart READ breakStart WRITE setBreakStart NOTIFY settingsChanged)
    Q_PROPERTY(QString breakEnd READ breakEnd WRITE setBreakEnd NOTIFY settingsChanged)
    Q_PROPERTY(QString scheduleMode READ scheduleMode WRITE setScheduleMode NOTIFY settingsChanged)
    Q_PROPERTY(QString rotationAnchorText READ rotationAnchorText NOTIFY settingsChanged)
    Q_PROPERTY(bool rotationAnchorIsBigWeek READ rotationAnchorIsBigWeek NOTIFY settingsChanged)
    Q_PROPERTY(bool windowPinned READ windowPinned WRITE setWindowPinned NOTIFY settingsChanged)

public:
    explicit WorkTimer(QObject *parent = nullptr);
    // 注入本地历史仓库，供结算、任务与成长外观共用。
    void setHistoryStore(WorkHistoryStore *store);

    QString countdownLabel() const { return countdownLabel_; }
    QString countdownText() const { return countdownText_; }
    QString earnedText() const { return earnedText_; }
    QString hourlyText() const { return hourlyText_; }
    QString progressText() const { return progressText_; }
    QString statusText() const { return statusText_; }
    QString statusKind() const { return statusKind_; }
    QString dateText() const { return dateText_; }
    QString shiftText() const { return shiftText_; }
    QString earnedTimeText() const { return earnedTimeText_; }
    QString paidDayText() const { return paidDayText_; }
    double progress() const { return progress_; }
    int experienceLevel() const { return experienceLevel_; }
    int experiencePoints() const { return experiencePoints_; }
    double experienceProgress() const { return experienceProgress_; }
    int freeValue() const { return freeValue_; }
    int fishingValue() const { return fishingValue_; }
    QVariantList timelineTasks() const { return timelineTasks_; }
    QVariantMap liveSummary() const { return liveSummary_; }
    int completedWorkdays() const { return completedWorkdays_; }
    QString networkTimeStatusText() const { return networkClock_.statusText(); }
    QVariantMap holiday() const { return holiday_; }

    QString salaryMode() const { return salaryMode_; }
    double salaryAmount() const { return salaryAmount_; }
    double monthlyWorkDays() const { return monthlyWorkDays_; }
    QString startTime() const { return startTime_; }
    QString endTime() const { return endTime_; }
    bool breakEnabled() const { return breakEnabled_; }
    QString breakStart() const { return breakStart_; }
    QString breakEnd() const { return breakEnd_; }
    QString scheduleMode() const { return scheduleMode_; }
    QString rotationAnchorText() const { return rotationAnchorMonday_.toString(QStringLiteral("yyyy-MM-dd")); }
    bool rotationAnchorIsBigWeek() const { return rotationAnchorIsBigWeek_; }
    bool windowPinned() const { return windowPinned_; }

    void setSalaryMode(const QString &value);
    void setSalaryAmount(double value);
    void setMonthlyWorkDays(double value);
    void setStartTime(const QString &value);
    void setEndTime(const QString &value);
    // 切换 Windows 窗口置顶状态并保存到本机设置。
    void setWindowPinned(bool value);
    void setBreakEnabled(bool value);
    void setBreakStart(const QString &value);
    void setBreakEnd(const QString &value);
    void setScheduleMode(const QString &value);
    // 设置经验系统的历史累计上班天数，并从当天班次继续自动累计。
    void setCompletedWorkdays(int value);
    // 原子更新上下班时间，允许用户同时调整两个时间点。
    Q_INVOKABLE bool setShiftTimes(const QString &start, const QString &end);

    Q_INVOKABLE bool worksOn(int weekdayIndex) const;
    Q_INVOKABLE void setWorksOn(int weekdayIndex, bool enabled);
    Q_INVOKABLE bool worksOnPattern(bool bigWeek, int weekdayIndex) const;
    Q_INVOKABLE void setWorksOnPattern(bool bigWeek, int weekdayIndex, bool enabled);
    Q_INVOKABLE void setCurrentWeekAsBig(bool bigWeek);
    // 同步设置到本机，返回 QSettings 的持久化结果。
    Q_INVOKABLE bool applySettings();
    Q_INVOKABLE void refresh();
    // 手动发起一次异步网络校时。
    Q_INVOKABLE void syncNetworkTime();

signals:
    void snapshotChanged();
    void settingsChanged();
    void toast(const QString &message);

private:
    struct ShiftWindow {
        QDate date;
        QDateTime start;
        QDateTime end;
        QDateTime breakStart;
        QDateTime breakEnd;
        bool isWorkday = false;
    };

    void loadSettings();
    // 写入当前工资、排班和经验数据并等待底层同步完成。
    bool saveSettings();
    void saveExperienceSettings();
    // 按已完成排班日累积经验，当前班次按有效工时显示未结算进度。
    void updateExperience(const QDateTime &now, bool hasActiveShift);
    void settleHistory(const QDateTime &now);
    void updateTimeline(const ShiftWindow &shift, const QDateTime &now);
    bool validClock(const QString &value) const;
    ShiftWindow shiftForDate(const QDate &date) const;
    bool isScheduledWorkday(const QDate &date) const;
    qint64 paidDurationMs(const ShiftWindow &shift) const;
    qint64 paidElapsedMs(const ShiftWindow &shift, const QDateTime &now) const;
    qint64 paidWithinDate(const ShiftWindow &shift, const QDateTime &now,
                          const QDate &date) const;
    qint64 hourlyRateCents(const ShiftWindow &shift) const;
    static QString formatDuration(qint64 milliseconds);
    static QString formatMoney(qint64 cents);
    static qint64 overlapMs(const QDateTime &aStart, const QDateTime &aEnd,
                            const QDateTime &bStart, const QDateTime &bEnd);

    QSettings settings_;
    NetworkClock networkClock_;
    ChinaHolidayCalendar holidayCalendar_;
    QTimer refreshTimer_;
    QPointer<WorkHistoryStore> historyStore_;
    QString salaryMode_ = QStringLiteral("monthly");
    double salaryAmount_ = 8000.0;
    double monthlyWorkDays_ = 21.75;
    QString startTime_ = QStringLiteral("09:00");
    QString endTime_ = QStringLiteral("18:00");
    bool breakEnabled_ = true;
    QString breakStart_ = QStringLiteral("12:00");
    QString breakEnd_ = QStringLiteral("13:00");
    unsigned int workdaysMask_ = 0b00011111; // 周一至周五
    QString scheduleMode_ = QStringLiteral("fixed");
    QDate rotationAnchorMonday_;
    bool rotationAnchorIsBigWeek_ = true;
    bool windowPinned_ = false;
    unsigned int bigWeekMask_ = 0b00111111; // 大周默认周一至周六
    unsigned int smallWeekMask_ = 0b00011111; // 小周默认周一至周五

    QString countdownLabel_;
    QString countdownText_;
    QString earnedText_;
    QString hourlyText_;
    QString progressText_;
    QString statusText_;
    QString statusKind_ = QStringLiteral("off");
    QString dateText_;
    QString shiftText_;
    QString earnedTimeText_;
    QString paidDayText_;
    double progress_ = 0.0;
    QDate experienceProcessedThrough_;
    int completedWorkdays_ = 0;
    int experienceLevel_ = 1;
    int experiencePoints_ = 0;
    double experienceProgress_ = 0.0;
    int freeValue_ = 0;
    int fishingValue_ = 0;
    QVariantList timelineTasks_;
    QVariantMap liveSummary_;
    QVariantMap holiday_;
};
