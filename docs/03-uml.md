# UML 设计

## 产品图视觉组件（2026-10-08）

```mermaid
flowchart LR
    Shell[AppShell 桌面侧栏 / 手机五栏] --> Home[HomePage 像素首页]
    Home --> Panel[PixelPanel / PixelMeter]
    Home --> Digits[PixelDigits 实时点阵数字]
    Home --> Icons[PixelIcon 自绘像素图标]
    Home --> Quick[QuickScheduleCard 快捷设置]
    Home --> Holiday[HolidayCountdownCard]
    Quick --> Timer[WorkTimer 已有时间提交和设置保存]
    Home --> History[WorkHistoryStore 本月累计]
    Timer --> Home
```

## 中国法定节假日模块（2026-10-08）

```mermaid
classDiagram
    class ChinaHolidayCalendar {
        -QVector holidays
        -QString loadError
        +snapshot(now) QVariantMap
        -describe(holiday, today) QVariantMap
    }
    class HolidayCountdownCard {
        +holiday QVariantMap
        +显示下一假期或当前假期剩余时间
        +显示年历与调休详情
    }
    WorkTimer --> NetworkClock : 使用网络校准时间
    WorkTimer --> ChinaHolidayCalendar : 每次刷新计算快照
    ChinaHolidayCalendar --> HolidayData : 读取官方年度JSON资源
    HolidayCountdownCard --> WorkTimer : 绑定只读holiday属性
```

```mermaid
sequenceDiagram
    participant Clock as NetworkClock
    participant Timer as WorkTimer
    participant Calendar as ChinaHolidayCalendar
    participant UI as HolidayCountdownCard
    Timer->>Clock: currentDateTime()
    Clock-->>Timer: 当前校准时间或离线回退时间
    Timer->>Calendar: snapshot(now)
    Calendar->>Calendar: 转北京时间，选择当前或下一个假期
    Calendar-->>Timer: 日期、倒计时、调休、来源、公布状态
    Timer->>Calendar: scheduleOverride(班次日期)
    Calendar-->>Timer: 放假/补班/沿用个人周排班
    Timer->>Timer: 按最终班次计算倒计时、工资、经验和历史
    Timer-->>UI: snapshotChanged
    UI->>UI: 刷新卡片和全年详情
```

下列旧版总体图记录首版入口；当前页面已拆为 AppShell 与独立任务、统计、工资、排班、成就、外观、关于页，历史/任务/外观由 WorkHistoryStore 管理；原 SettingsPage 已被独立工资和排班页替换。

## 组件图

```mermaid
flowchart LR
    User[用户] --> UI[QML 主界面]
    UI --> Controller[WorkTimer Qt 控制器]
    Controller --> Clock[NetworkClock 网络时钟]
    Clock --> Ntp[NTP 服务]
    Controller --> Calc[班次快照与工资计算]
    Controller --> Store[QSettings 本地配置]
    Calc --> UI
    subgraph Targets[构建目标]
        Windows[Windows 桌面]
        Android[Android APK]
    end
    UI --> Targets
    Controller --> Targets
```

## 类图

```mermaid
classDiagram
    class WorkTimer {
        -QSettings settings_
        -NetworkClock networkClock_
        -QTimer refreshTimer_
        -QString salaryMode_
        -double salaryAmount_
        -QString startTime_
        -QString endTime_
        -unsigned workdaysMask_
        -QString scheduleMode_
        -unsigned bigWeekMask_
        -unsigned smallWeekMask_
        -QDate rotationAnchorMonday_
        -bool windowPinned_
        +setWindowPinned(enabled)
        +refresh()
        +applySettings()
        +worksOn(index) bool
        +setWorksOn(index, enabled)
        +worksOnPattern(bigWeek, index) bool
        +setCurrentWeekAsBig(bigWeek)
        +countdownText() QString
        +earnedText() QString
        +progress() double
        +experienceLevel() int
        +experiencePoints() int
        +experienceProgress() double
        +completedWorkdays() int
        +setCompletedWorkdays(days)
        +syncNetworkTime()
    }
    class NetworkClock {
        -QUdpSocket socket_
        -QTimer syncTimer_
        -QDateTime anchorUtc_
        +currentDateTime() QDateTime
        +statusText() QString
        +syncNow()
    }
    class ShiftWindow {
        +QDate date
        +QDateTime start
        +QDateTime end
        +QDateTime breakStart
        +QDateTime breakEnd
        +bool isWorkday
    }
    class MainQml {
        +展示下班倒计时
        +展示今日已赚工资
        +展示工作进度
        +按工作进度显示牛马精力血条并选择疲劳帧
        +显示等级、累计工作日和蓝色经验条
        +Windows 窗口置顶开关
    }
    class SettingsPageQml {
        +设置工资方式与金额
        +设置上下班及休息时间
        +设置固定周与大小周工作日
        +设置本周大小周锚点
    }
    MainQml --> WorkTimer : 属性绑定
    SettingsPageQml --> WorkTimer : 设置与操作
    WorkTimer --> NetworkClock : 当前时间与同步状态
    WorkTimer ..> ShiftWindow : 生成并计算
```

## 刷新时序图

```mermaid
sequenceDiagram
    participant Timer as Qt 定时器
    participant WorkTimer
    participant Clock as NetworkClock
    participant Ntp as NTP服务器
    participant Store as QSettings
    participant QML as QML 界面
    Timer->>WorkTimer: refresh()
    WorkTimer->>Clock: currentDateTime()
    WorkTimer->>WorkTimer: 生成班次与休息区间快照
    WorkTimer->>WorkTimer: 计算有效工时、进度与金额
    WorkTimer->>WorkTimer: 按排班日结算经验并生成当前班次经验进度
    WorkTimer-->>QML: snapshotChanged
    QML->>QML: 更新倒计时、精力条和经验条
    WorkTimer->>Store: 应用设置时写入本机配置
    opt 启动、恢复前台或定时校时
        Clock->>Ntp: 异步 UDP 时间请求
        Ntp-->>Clock: NTP 时间戳
        Clock->>Clock: 用单调时钟推进校准时间
    end
```

## 工作状态机

```mermaid
stateDiagram-v2
    [*] --> 休息日
    休息日 --> 待上班: 到排班日
    待上班 --> 打工中: 到上班时间
    打工中 --> 休息中: 进入已配置休息区间
    休息中 --> 打工中: 休息结束
    打工中 --> 已下班: 到下班时间
    已下班 --> 待上班: 下一个排班日
    待上班 --> 休息日: 当前日期无排班
```

## 部署图

```mermaid
flowchart TB
    subgraph Windows[Windows 10/11]
        WinExe[NiumaTimer.exe]
        WinSettings[用户配置目录 / QSettings]
        WinExe --> Topmost[WindowStaysOnTopHint]
        WinExe --> WinSettings
    end
    subgraph Android[Android 手机]
        Apk[NiumaTimer APK]
        AndroidSettings[应用私有设置目录 / QSettings]
        Apk --> AndroidSettings
    end
    Source[共享 Qt C++ 与 QML 源码] --> WinExe
    Source --> Apk
```
