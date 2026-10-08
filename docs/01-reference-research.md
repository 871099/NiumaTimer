# 开源参考与 Qt 路线

调研日期：2026-09-29。附件仅作为视觉参考；功能范围以用户明示的计时、工资和排班需求为准。

## 参考项目

| 项目 | 可借鉴内容 | 不直接采用的部分 |
| --- | --- | --- |
| [DoneAt / Off-Work-Countdown](https://github.com/ififi2017/Off-Work-Countdown) | 下班倒计时、班次配置、跨午夜处理、工作日选择、当日工资估算。其 README 明确把排班时间与金额作为本地数据。 | 项目使用 Web/Tauri 和多套原生端；与 Qt C++/QML 不同，不复制其代码。 |
| [Flowkeeper](https://github.com/flowkeeper-org/fk-desktop) | Qt 桌面计时工具的设置分组、快捷交互和发布流程。 | 这是基于 Qt 6.11 的番茄钟桌面应用，采用 GPL-3.0；只参考工程习惯，不复制代码，也不把 GPL 代码并入本工程。 |

这两个项目分别提供业务参考和 Qt 桌面工程参考，没有一个直接覆盖本项目的 Qt + Android + Windows 计薪场景，因此本工程采用自建实现。

## Qt 平台依据

- Qt 官方 CMake 文档提供 QML 模块构建方式：[Building a QML application](https://doc.qt.io/qt-6/cmake-build-qml-application.html)。
- Android 通过 Qt Android Kit 构建，可生成 APK/AAB；Qt Creator 使用 `androiddeployqt` 打包：[Deploy applications to Android](https://doc.qt.io/qtcreator/creator-how-to-deploy-android-apps.html)。
- Windows Qt Quick 应用可用 `windeployqt` 收集 Qt、QML 模块和插件：[Qt for Windows deployment](https://doc.qt.io/qt-6/windows-deployment.html)。
- Qt 当前发行信息列出 Qt 6.11.2 支持至 2027-03-17、Qt 6.8 LTS 支持周期至 2029-10-08；6.8 的长期维护补丁发行受商业支持策略限制：[Qt Releases](https://doc.qt.io/qt-6/qt-releases.html)、[Qt LTS policy](https://www.qt.io/development/qt-framework/qt-lts)。当前实现按本机现有 Qt 6.8.3 API 编写，后续升级应单独核验工具链与许可安排。

## 设计取舍

- QML 负责自适应界面，C++/Qt 负责工资计算、设置持久化和时间快照。
- 计时不累加 `QTimer` tick；每次刷新都从当前本地时间重新计算，降低后台挂起后的误差。
- 先交付本地使用的 Windows/Android 应用；不引入账号、服务端或云同步依赖。
- 附图中的等级、任务、角色属性视为视觉示例，不作为本期功能需求。
