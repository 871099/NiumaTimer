// 关于页说明版本、估薪口径、网络时间、隐私与原创素材来源。
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property var historyStore
    readonly property bool compact: width < 700

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        contentWidth: availableWidth
        ColumnLayout {
            x: page.compact ? 12 : 22
            width: parent.width - (page.compact ? 24 : 44)
            spacing: 13

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: qsTr("关于牛马计时器"); color: Theme.textPrimary; font.pixelSize: 21; font.bold: true }
                Text { text: qsTr("把下班时间和每一份努力都看得更清楚"); color: Theme.textMuted; font.pixelSize: 11 }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 124
                radius: 19
                gradient: Gradient {
                    GradientStop { position: 0; color: "#d5edff" }
                    GradientStop { position: 1; color: "#f9fcff" }
                }
                border.color: Theme.cyan
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 14
                    Rectangle { Layout.preferredWidth: 62; Layout.preferredHeight: 62; radius: 20; color: Theme.surfaceDeep; border.color: Theme.cyan; Text { anchors.centerIn: parent; text: "牛"; color: Theme.yellow; font.pixelSize: 31; font.bold: true } }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: qsTr("牛马打工计时器"); color: Theme.textPrimary; font.pixelSize: 16; font.bold: true }
                        Text { text: qsTr("版本 0.1.0 · Qt 6.8 · Windows / Android"); color: Theme.textSecondary; font.pixelSize: 9; wrapMode: Text.WordWrap }
                        Text { text: qsTr("工资、任务与工作记录只保存在本机，不需要注册账号。"); color: "#314c82"; font.pixelSize: 9; wrapMode: Text.WordWrap }
                    }
                }
            }

            Repeater {
                model: [
                    { title: qsTr("计时与估薪口径"), body: qsTr("倒计时优先使用异步网络校准时间；工资按当前月薪、日薪或时薪和排班有效工时估算。休息区间不计入工资和有效工时。当前不计算个税、社保、公积金、法定节假日、调休或加班倍率。") },
                    { title: qsTr("本地数据与隐私"), body: qsTr("工资和排班使用 Qt 本机设置存储；每日结算、任务和外观数据保存在：%1。数据不上传云端。卸载应用前如需保留历史，请自行备份此文件。").arg(page.historyStore.dataPath) },
                    { title: qsTr("网络时间"), body: qsTr("应用通过 NTP 请求校准时间，用于推进倒计时。断网时沿用本次运行中最近一次校准；首次校时失败时使用设备时间。Android 仅申请普通网络访问权限。") },
                    { title: qsTr("法定节假日倒计时"), body: qsTr("首页按北京时间显示中国内地全体公民的下一个假期；假期内显示剩余时间。已收录国务院公布的2026年放假调休安排。2027年当前仅按元旦法定日期倒计时，连休及调休待正式公布后更新。假期提醒不自动改变个人排班或计薪，详情中可查看调休上班日及官方来源。") },
                    { title: qsTr("素材来源"), body: qsTr("牛马头像、夜间办公室背景和疲劳精灵图为本项目原创生成素材，不含第三方角色、商标或文字。更多素材说明与生成提示见 assets/ARTWORK.md。") }
                ]
                delegate: Rectangle {
                    id: aboutCard
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: aboutColumn.implicitHeight + 28
                    radius: Theme.radius
                    color: Theme.surface
                    border.color: Theme.border
                    ColumnLayout {
                        id: aboutColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 7
                        Text { text: aboutCard.modelData.title; color: Theme.cyan; font.pixelSize: 12; font.bold: true }
                        Text { Layout.fillWidth: true; text: aboutCard.modelData.body; color: Theme.textSecondary; font.pixelSize: 10; wrapMode: Text.WordWrap; textFormat: Text.PlainText }
                    }
                }
            }
            Item { Layout.preferredHeight: 3 }
        }
    }
}

