# 牛马打工计时器

一个面向 Windows 与 Android 的 Qt 6 工具应用，包含下班倒计时、工资估算、任务、历史统计和成长装扮。界面采用深蓝夜色、霓虹色块和原创像素风牛马插画。

## Windows 下载

在 [GitHub Releases](https://github.com/871099/NiumaTimer/releases) 中下载 `NiumaTimer-0.1.0-windows-x64.zip`，完整解压后运行 `NiumaTimer.exe`。Qt 动态库和插件已经随包提供；如提示缺少 MSVC 运行库，可运行包内 `vc_redist.x64.exe`。功能和限制见 [v0.1.0 发布说明](docs/releases/v0.1.0.md)，第三方依赖见 [许可说明](THIRD_PARTY_NOTICES.md)。

## 当前功能

- 中国内地法定节假日倒计时：自动选择下一个假期，假期中显示剩余时间；法定放假日按休息日处理，暂停上班计时、工资和经验，官方调休上班日按个人班次执行；详情列出全年安排与官方来源，按北京时间计算。
- 已收录官方 2026 年放假安排；2027 年暂仅显示元旦法定日期，并标记连休/调休待公布。年历随应用更新，未收录日期显示待更新提示，详见 `docs/05-china-holiday-countdown.md`。
- 共享桌面侧栏与手机底栏；独立首页、任务、统计、工资、工作时间、成就、外观和关于页面。
- 首页按产品图采用明亮像素卡片、霓虹边框、实时点阵倒计时、中央疲劳牛马和办公室场景；状态/时间线/班次快捷设置在宽屏并排显示，手机纵向重排并使用五项底栏。
- 当日自定义任务可添加、编辑、删除和标记完成；日/周/月统计使用本地结算历史，成就和装扮根据工作天数、等级解锁。
- 优先使用网络时间推进上班/下班倒计时；断网时沿用本次运行最近一次校准，首次校时失败时回退到设备时间。支持跨午夜班次。
- 按月薪、日薪或时薪估算今日已赚金额，使用整数“分”显示结果。
- 可配置工资、上/下班时间、休息区间，并选择固定周排班或大小周轮换；大周、小周的上班日可分别设置。
- 首页显示牛马精力血条：随有效工时从 100% 逐渐降到 0%，颜色由绿转黄再转红；角色姿态和疲劳文案同步变化。
- 蓝色经验条随累计排班上班日增长：每完成一个工作日获得 20 XP，每 500 XP 升一级；当前班次会按有效工时预览经验增长，累计数据保存在本机。
- 设置页可录入既往累计上班天数；之后按完成的排班日继续累计，并可手动触发网络校时。
- Windows 应用顶栏图钉可切换窗口置顶，置顶状态保存在本机设置中。
- 休息时段继续计算墙钟倒计时，但冻结已赚工资与有效工时进度。
- 设置使用 Qt `QSettings` 保存在本机；应用恢复前台后会刷新班次并重新进行网络校时。

金额是税前个人估算，不计算个税、社保、公积金、法定节假日或加班倍率。Android 首版不承诺锁屏常驻通知；恢复应用后会重新计算。

## 工程结构

```text
worker-timer-v2/
├── CMakeLists.txt
├── assets/                  # 原创像素风吉祥物与素材说明
├── docs/                    # 技术参考、架构与 UML
├── src/
│   ├── app/WorkTimer.*      # Qt 属性、设置持久化与计时快照
│   ├── app/NetworkClock.*   # 异步 NTP 校时与时间推进
│   ├── app/ChinaHolidayCalendar.* # 官方年历与北京时间假期快照
│   ├── app/WorkHistoryStore.* # 版本化历史、任务与外观数据
│   ├── ui/                  # QML 主界面、主题和设置页
│   └── main.cpp
├── progress.md              # 当前实施与实际验收状态
└── progress_history.md     # 追加式历史记录
```

## 构建要求

- Qt 6.8 或更新版本，包含 Qt Quick、Qt Quick Controls 2 和对应目标平台 Kit。
- Windows：MSVC 2022 x64、CMake、Ninja。
- Android：Qt for Android Kit、JDK 17、Android SDK/NDK；Qt Creator 可生成 APK。

### Windows

在 Visual Studio 2022 x64 开发者终端中（确保 PATH 使用 VS 2022 的 `cl.exe`）：

```powershell
cmake -S . -B build-msvc -G Ninja `
  -DCMAKE_PREFIX_PATH="I:/soft/qt/6.8.3/msvc2022_64" `
  -DCMAKE_BUILD_TYPE=Release
cmake --build build-msvc
```

打包运行目录：

```powershell
I:/soft/qt/6.8.3/msvc2022_64/bin/windeployqt.exe `
  --qmldir src/ui build-msvc/NiumaTimer.exe
```

### Android

在 Qt Creator 中选择 Android Kit，配置 JDK、SDK 和 NDK 后构建 APK。也可以用对应 Qt Android Kit 的 `qt-cmake` 单独配置 Android 构建目录；桌面和 Android 产物必须分别构建。

## 研究与设计

- [开源项目与 Qt 官方资料](docs/01-reference-research.md)
- [架构与计算口径](docs/02-architecture.md)
- [UML 设计](docs/03-uml.md)
- [已确认的完整产品实施方案](docs/04-product-implementation-plan.md)
- [中国法定节假日倒计时与年度数据更新](docs/05-china-holiday-countdown.md)
- [实施进度与验收记录](progress.md)
