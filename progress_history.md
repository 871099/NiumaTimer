# 进度历史

## 2026-10-08（Asia/Shanghai）— 新增中国法定节假日倒计时

- 读取根AGENTS/program、项目progress和相关代码；项目无独立AGENTS及Git仓库。核对发现进度文档仍称页面未实现、方案待确认，与既有多页面代码及用户确认冲突，已更新当前进度和方案状态；此前多页面代码作为已有工作保留。
- 新增ChinaHolidayCalendar及版本化JSON官方年历，2026年日期与国务院通知（北京市政府转载）逐项核对。首页新增HolidayCountdownCard和全年详情，包含放假区间、调休上班日及官方来源；关于页增加口径。
- 假期时间从现有NetworkClock推进，采用北京时间UTC+8零点；假期内显示剩余时间，结束后切换下一假期。当前2027年连休安排未查到正式通知，元旦仅按法定1月1日显示并明确待公布；未知后续年度显示待更新，不推测农历节日。
- 本次不将官方假期套入个人工资、固定周/大小周、经验或历史，不更改用户现有输入值。
- 实际验证：Qt6.8.3/MSVC19.44/x64/Debug构建及链接成功，windeployqt返回0；涉及6份QML的qmllint返回0且无警告。新增独立CTest目标1/1通过，内含14个国庆/春节/元旦、结束边界、跨年、UTC及海外时区、未知日期断言。
- 实际运行：新版PID30392，标题“牛马打工计时器”、响应正常、标准错误为空；使用computer-use观察首页假期卡片，秒数随时间减少。详情点击受窗口用户输入打断，完整弹层和窄屏交互未验收，窗口保留给用户。
- 年历随应用版本更新，未实现自动联网获取年度数据；Android目录只有Windows Kit，APK/手机未构建。更新README、架构、UML、进度、方案状态和docs/05-china-holiday-countdown.md。

文档维护信息：2026-10-08（Asia/Shanghai）；记录新增模块、数据依据、实际验证及待验收边界。

## 2026-09-29 15:25（Asia/Shanghai）— 首版从零实现

- 按用户“从头开始做”的要求，在 `worker-timer-v2` 新建独立 Qt Quick + C++ 工程；旧 `worker-timer` 原型保持原样。
- 完成工资/班次设置、倒计时、今日已赚估算、跨午夜处理、休息暂停累计和本地持久化；完成响应式 QML 页面、原创像素风吉祥物、参考调研、架构与 UML 文档。
- 实际验证：Qt 6.8.3 `qmllint` 对三份 QML 文件报告 0 errors、0 warnings。
- 静态复核补齐跨午夜工资累计：同一自然日可合并前一晚延续班次与当天班次各自在当日产生的工资。
- 实际验证：CMake 配置失败，原因是当前解析到的 `J:/AutoMod/bin/cl.exe` 报 MSVC PDB 管理器不匹配（C1902）；C++ 未编译，桌面 UI 未运行。
- 环境检查：未找到 Qt Android Kit 或常见位置的 Android SDK；APK 和手机交互验收待完成。项目目录不是 Git 仓库。
- 已知限制：工资是个人税前估算，未计税费、法定节假日、调休和加班倍率；Android 锁屏常驻计时/通知不在首版承诺范围。

文档维护信息：2026-09-29 15:25（Asia/Shanghai）；追加本次从零实现、静态检查与工具链受阻记录。

## 2026-09-29 15:37（Asia/Shanghai）— 修复 Windows 编译器选择并启动应用

- 根因：PATH 将 `J:\AutoMod\bin\cl.exe`（MSVC 16.0）排在前面，与 Qt 6.8.3 的 MSVC 2022 Kit 不匹配；机器实际装有 VS 2022 Community，MSVC 14.44.35207。
- 使用 VS 2022 x64 `vcvars64.bat` 初始化开发环境，在 `build-msvc` 全新目录成功配置 CMake；识别编译器版本为 MSVC 19.44.35228.0。
- Ninja 完成 24/24 构建步骤，生成 Debug 版 `build-msvc/NiumaTimer.exe`；运行 `windeployqt` 部署 Qt Quick 依赖。
- 实际运行：应用窗口标题“牛马下班计时器”，进程响应正常；已将正式构建窗口留给用户验收，替换此前固定演示数据预览。
- Android 工具链仍缺失，APK 和手机交互未验证。当前 Windows 仅为本机 Debug 构建；Release 包和其他电脑部署仍待验收。

文档维护信息：2026-09-29 15:37（Asia/Shanghai）；追加 MSVC 根因、构建、部署与启动结果。

## 2026-09-29 15:44（Asia/Shanghai）— 增加大小周排班

- 在固定周排班之外增加大小周轮换；大周、小周的上班日掩码分别保存，默认大周周一至周六、小周周一至周五，用户可逐日修改。
- 用户可将本周设为大周或小周；应用记录本周周一作为锚点，之后按周数奇偶自动交替，并将模式与锚点保存到 QSettings。
- 更新 SettingsPage、README、计薪架构说明和 UML；旧设置仍默认为固定周模式。
- 实际验证：三份 QML 的 `qmllint` 返回 0 errors、0 warnings；大小周改动的 C++/QML 编译和链接成功；`windeployqt` 更新部署目录；新窗口标题为“牛马下班计时器”且进程响应正常。
- 待验收：未人工点击大小周控件检查排班与工资联动；更新后的 Windows 窗口已打开供用户验收。

文档维护信息：2026-09-29 15:44（Asia/Shanghai）；追加大小周功能、构建和待验收情况。

## 2026-09-29 15:51（Asia/Shanghai）— 按参考图优化主页视觉层级

- 为首页生成并加入原创夜班办公室全景像素背景 `assets/office-city-panorama.png`，保留现有原创牛马角色叠加显示。
- 将下班倒计时与今日工资拆为并列主卡，进度改为独立横向卡片，新增今日班次摘要与排班设置快捷入口；主页继续支持窄屏滚动与宽屏布局。
- 更新 CMake 图片资源和素材来源说明 `assets/ARTWORK.md`。
- 实际验证：Qt 6.8.3 `qmllint` 返回 0 errors、0 warnings；CMake 自动重新生成后 Windows Debug 构建成功；`windeployqt` 执行成功；更新应用窗口标题正确且进程响应正常。
- 待验收：实际视觉排版和窄屏布局待用户在更新窗口检查；Android 尚未构建。

文档维护信息：2026-09-29 15:51（Asia/Shanghai）；追加主页视觉更新、素材说明与运行验证情况。

## 2026-09-29 16:04（Asia/Shanghai）— 加入牛马疲劳度动画帧

- 参考现有牛马角色生成六帧透明精灵图：精神饱满、专注打字、初显疲态、揉眼、趴桌休息、累趴睡着；图为 1536×1024，3列×2行，每帧512×512。
- 首页使用 Qt Quick `AnimatedSprite`，根据当天有效工时进度选择帧；同步显示对应疲劳状态短句，休息时因有效进度暂停而保持当前状态。
- 新增素材 `assets/cow-fatigue-spritesheet.png`，记录生成说明；加入 CMake 资源并更新架构、UML、README。
- 实际验证：素材左上背景像素 Alpha=0；`qmllint` 返回 0 errors、0 warnings；Windows Debug 增量构建/链接成功；`windeployqt` 成功；更新窗口启动且响应正常。
- 待验收：动画帧随计时进度切换的实际视觉效果待用户在已打开窗口检查；Android 未构建。

文档维护信息：2026-09-29 16:04（Asia/Shanghai）；追加动画素材、接入逻辑和构建状态。

## 2026-09-29 16:10（Asia/Singapore，UTC+8）— 增加随工时下降的牛马精力血条

- 首页角色状态区新增“牛马精力”百分比和横向血条：剩余精力 = 100% − 有效工时进度；颜色从绿、黄转为红，填充宽度平滑变化。
- 血条与现有角色疲劳帧、状态文案共用 `WorkTimer.progress`；午休时有效工时进度冻结，血条也暂停消耗。紧凑布局略微收窄文案区，为血条和角色图留出空间。
- 同步更新 README、架构说明和 UML。
- 实际验证：Qt 6.8.3 `qmllint` 检查 0 errors、0 warnings；VS 2022 x64 环境中 Windows Debug 构建 7/7 步骤成功；`windeployqt` 返回 0；启动后窗口标题为“牛马下班计时器”、进程响应正常，QML 标准错误为空。
- 验收范围：Windows 窗口已重新打开供用户目视确认血条样式和疲劳阶段；本次未实际跨时段观察血条下降过程。Android 未构建，`windeployqt` 对缺失 DXC DLL 和未设置 `VCINSTALLDIR` 有警告，干净 Windows 部署待验收。

文档维护信息：2026-09-29 16:10（Asia/Singapore，UTC+8）；记录精力血条、QML 检查、构建及待验收事项。

## 2026-09-29 16:21（Asia/Singapore，UTC+8）— 增加打工经验与等级条

- `WorkTimer` 新增经验等级、当前等级 XP、进度和累计完成工作日属性；每个完成的排班日奖励 20 XP，每 500 XP 升一级。当前班次按有效工时预览当天经验，午休冻结；完成记录和处理日期保存在 `QSettings`，应用重启后继续累计。
- 首次启用从当天排班开始记录，不补造历史上班天数；应用关闭期间的已完成排班日会在下次刷新时按当前排班补记，避免重复奖励。
- 首页精力条下方加入蓝色经验条，显示等级、累计工作日及本级 XP；Hero 卡片增高以容纳两条状态栏。
- 更新 README、架构说明、UML 和当前进度文档。
- 实际验证：Qt 6.8.3 `qmllint` 对三份 QML 返回 0 errors、0 warnings；VS 2022 x64 下 Windows Debug 构建 19/19 步骤成功；在 VS x64 环境运行 `windeployqt` 返回 0 且无警告；应用窗口标题为“牛马下班计时器”、进程响应正常，QML 标准输出与错误输出为空。
- 待验收：用户目视确认蓝色经验条的布局与进度表现；本次未等待完整班次观察经验结算；Android APK 未构建。

文档维护信息：2026-09-29 16:21（Asia/Singapore，UTC+8）；记录经验机制、UI 更新及实际 Windows 验证。

## 2026-09-29 16:40（Asia/Shanghai）— 累计上班天数录入与网络校时

- 设置页加入历史累计上班天数输入；保存到 `QSettings` 并重算等级/XP，当前未结束班次留待排班完成时结算，避免录入天数被重复奖励。
- 新增 `NetworkClock`，使用 Qt Network 的异步 DNS 与 NTP/UDP 校时；启动、回到前台时校时，成功后每小时同步，失败后每分钟重试。用单调时钟推进校准时间，设置页可看同步状态并手动重试。
- 加入基于 Qt 6.8 Android 默认清单的 `android/AndroidManifest.xml`，保留 Qt 插入占位符并声明普通 `INTERNET` 权限。
- 更新 README、架构口径与 UML。参考 Qt 6.8 `QHostInfo`/`QUdpSocket`、RFC 5905；所用 `time.cloudflare.com` 是 Cloudflare 公布的公共 NTP 服务。
- 实际验证：Qt 6.8.3 `qmllint` 0 errors、0 warnings；Windows Debug 构建 14/14 成功；VS x64 环境下 `windeployqt` 返回 0 且无警告；AndroidManifest XML 解析通过；窗口 PID 46028、标题“牛马下班计时器”、进程响应正常、标准错误为空。
- 待验收：未手动点击表单和网络同步按钮、未目视确认应用内状态文字；独立 Windows UDP 探测已收到公网 NTP 有效响应；Android APK 未构建。完整产品参考图中的任务、统计、成就和外观等页面仍未实现。
- 用户明确产品图是完整功能与 UI 基准；针对未实现页面形成方案 `docs/04-product-implementation-plan.md`。依根目录 `AGENTS.md` 第 3 节，大范围改造须待方案确认后开始。

文档维护信息：2026-09-29 16:40（Asia/Shanghai，UTC+8）；记录累计天数录入、网络校时与平台限制。

## 2026-09-29 16:53（Asia/Shanghai）— 修复设置保存提交

- 排查到保存按钮只调用 `applySettings()`，文本输入则依赖各自的 `editingFinished` 写回业务对象；自绘按钮点击时不能保证输入完成信号先提交，可能导致保存旧值。
- 设置页保存现在会显式校验并提交工资金额、月计薪天数、累计上班日、上下班时间和休息时间，然后执行 `QSettings::sync()`。设置值落盘后通过成功/失败反馈提示用户。
- 增加原子 `setShiftTimes(start, end)`，避免更改班次两端时间时被旧的另一端值挡住；上下班输入格式和相同时间会在提交前提示。
- 实际验证：Qt 6.8.3 `qmllint` 0 errors、0 warnings；VS 2022 x64 Windows Debug 构建 7/7 成功；`windeployqt` 返回 0 且无警告；重启后窗口标题正确、响应正常、标准错误为空。
- 待验收：尚未通过人工点击表单并重启检查数据回读；当前窗口已重新打开供用户验收。

文档维护信息：2026-09-29 16:53（Asia/Shanghai，UTC+8）；记录保存提交修复与待验收事项。

## 2026-09-29 17:00（Asia/Shanghai）— 增加 Windows 窗口置顶

- WorkTimer 暴露 `windowPinned` 属性，使用 `QSettings` 的 `ui/windowPinned` 加载并保存；切换时立即同步设置，失败时通过应用提示告知用户。
- Windows 应用顶栏新增图钉按钮，绑定 `Qt.WindowStaysOnTopHint`，当前状态有颜色反馈和悬停说明；Android 隐藏按钮，不申请跨应用悬浮窗权限。
- 更新 README、架构说明和 UML。
- 实际验证：Qt 6.8.3 `qmllint` 检查 `Theme.qml`、`Main.qml`、`SettingsPage.qml` 返回 0 errors、0 warnings；VS 2022 x64 环境 Windows Debug 构建 19/19 成功；`windeployqt` 返回 0；新版 PID 43084、标题“牛马下班计时器”、进程响应正常、标准错误为空。
- 待验收：需手动点击图钉确认窗口在其他窗口前方显示、再点击可取消，并重启检查置顶状态保持。Android 未构建，未做手机交互验收。

文档维护信息：2026-09-29 17:00（Asia/Shanghai）；记录窗口置顶实现、Windows 构建及待人工验收项。

## 2026-10-08（Asia/Shanghai）— 法定假期停班与调休补班

- 用户明确法定节假日不上班。`ChinaHolidayCalendar::scheduleOverride()` 现对所有公告补班日期优先返回工作日，对官方放假区间返回休息日，其余日期继续采用固定周/大小周设置。
- `WorkTimer` 从排班判断源头应用覆盖，因此下班倒计时、有效工时、工资、进度、经验与历史结算一致；跨午夜班次在进入法定放假日的零点截断。
- 首页假期卡片与状态文案说明停班、补班行为；更新 README、架构、UML、产品方案、节假日说明和当前进度。
- 验证：21项节假日/排班回归由独立 CTest 目标1/1通过；Qt 6.8.3 `qmllint` 0 errors、0 warnings；Windows Debug 增量构建及 `windeployqt` 成功；新版窗口 PID 44556 响应正常，启动标准错误为空。
- 待人工验收：假期详情弹层、窄屏布局；Android Kit 未安装，未构建 APK。

文档维护信息：2026-10-08（Asia/Shanghai）；记录法定放假日与调休补班计算、界面说明及验证结果。

## 2026-10-08 16:42：修正国庆旧历史仍显示工作

- 用户截图显示10月1、2、3、5、6、7日仍有8.5小时的结算。原因是上次仅让新班次遵循年历，没有迁移持久化旧结算；补齐了上一轮遗漏。
- 修改 `WorkHistoryStore.h/.cpp`：加载时先备份历史原文件，再将法定放假日误结算归档到 `holidayCorrection`，保留日期和任务，将排班/结算标记置为false、金额及工时置零；列表、统计读取和写入入口同时约束假期日期。提供独立文件路径用于隔离验证。
- 修改 `tests/CMakeLists.txt`，新增 `tests/history-holiday-checks.cpp`，使用临时目录验证迁移、月统计、当前假期统计、任务/外观保留、备份字节一致、重启幂等、假期写入拒绝、补班允许及损坏文件保护。
- 实测环境：Qt6.8.3 / MSVC19.44 / Windows x64 / Debug；CTest2/2通过（2.07秒），Windows增量构建44/44成功。
- 本机实际启动迁移了6条国庆班次，假期结算取消且工资/工时为零；非假期9月29日/30日保留，任务2→2，外观保留。备份 `history.json.before-holiday-repair-20261008-083851-541.bak` 的SHA256与原文件一致；证据保存在 `build-msvc/history-migration-verification.json`。
- 新版PID43300响应正常，启动标准错误为空；统计页实际视觉复核由用户在窗口验收。旧经验数据只记录含手填基数的总数，没有逐日来源，本次不根据工资历史反推扣减经验；后续自动经验已按假期规则停算。

文档维护信息：2026-10-08 16:42（Asia/Singapore，UTC+8）；记录国庆旧历史迁移、存量数据保护和实际验证结果。

## 2026-10-08 18:03：源码推送与v0.1.0发布

- 用户授权推送并发布。确认GitHub登录账号871099，当前工程原无Git仓库；未收到其他仓库/公开范围选择，按已说明的私有仓库方案创建 `https://github.com/871099/NiumaTimer`。
- 本地初始化main，仓库级配置GitHub noreply作者，保留源码、原创素材来源、UML与回归检查；忽略build、dist和本机日志。初始源码提交 `3c6e5bd818e4456a391c7a4a49c33181ca9ee2fe`，对应annotated标签v0.1.0。
- Qt6.8.3/MSVC2022 x64 Release构建59/59成功。windeployqt部署未改写的动态库/QML插件；包附VC x64运行库安装程序、Qt许可证、60份第三方声明及构建信息。移除开发Qt搜索路径后启动，PID11528响应正常，15个Qt模块来自下载包目录，标准错误为空。
- 下载包 `NiumaTimer-0.1.0-windows-x64.zip` 为58,623,064字节，1504个ZIP条目；解压EXE哈希与已启动包一致，未含用户历史、日志、编译缓存和调试符号。SHA256为 `16d5db84b1f454866aa259d39f53a7641dd3f9f67b33728d70d3a88e56fc37b0`。
- 首次Git传输因直连被重置/连接失败；读取现有Windows代理127.0.0.1:7897并通过本次命令的代理参数完成推送，未修改全局代理设置。远程main/tag提交与本机核对一致。
- Release已发布：`https://github.com/871099/NiumaTimer/releases/tag/v0.1.0`，非草稿；ZIP与SHA256SUMS.txt两份附件上传完成，GitHub返回的附件SHA256均与本机一致。
- 验证证据保存在忽略的 `build-release/release-startup-verification.json`、`release-archive-verification.json`、`release-publication-verification.json`。其他电脑及Android实机尚未验收，本次仅发布Windows x64版本。

文档维护信息：2026-10-08 18:03（Asia/Singapore，UTC+8）；记录Git初始化、Windows Release打包、远程源码与附件校验以及实际发布结果。
