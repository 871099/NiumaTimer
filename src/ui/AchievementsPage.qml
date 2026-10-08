// 成就图鉴由累计工作日、等级和本地已结算记录派生。
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property var timerController
    property var historyStore
    readonly property var savedRecords: historyStore.records
    readonly property var badges: {
        savedRecords
        return historyStore.achievements(timerController.completedWorkdays,
                                         timerController.experienceLevel)
    }
    readonly property int unlockedCount: {
        let count = 0
        for (let i = 0; i < badges.length; ++i)
            if (badges[i].unlocked) ++count
        return count
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        contentWidth: availableWidth
        ColumnLayout {
            x: page.width < 700 ? 12 : 22
            width: parent.width - (page.width < 700 ? 24 : 44)
            spacing: 13
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: qsTr("成就图鉴"); color: Theme.textPrimary; font.pixelSize: 21; font.bold: true }
                    Text { text: qsTr("每份努力都会留下一个本地徽章"); color: Theme.textMuted; font.pixelSize: 11 }
                }
                Text { text: qsTr("%1 / %2").arg(page.unlockedCount).arg(page.badges.length); color: Theme.yellow; font.pixelSize: 15; font.bold: true }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 90
                radius: Theme.radius
                color: "#dceeff"
                border.color: "#6ba8ea"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12
                    Text { text: "✦"; color: Theme.yellow; font.pixelSize: 30 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text { text: qsTr("Lv.%1 打工牛马").arg(page.timerController.experienceLevel); color: Theme.textPrimary; font.pixelSize: 14; font.bold: true }
                        Text { text: qsTr("累计 %1 个排班日 · %2 条历史记录").arg(page.timerController.completedWorkdays).arg(page.savedRecords.length); color: Theme.textSecondary; font.pixelSize: 10 }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: page.width < 720 ? 1 : 2
                columnSpacing: 10
                rowSpacing: 10
                Repeater {
                    model: page.badges
                    delegate: Rectangle {
                        id: badgeCard
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        radius: 15
                        color: badgeCard.modelData.unlocked ? "#fff5cd" : "#edf3fa"
                        border.color: badgeCard.modelData.unlocked ? Theme.yellow : Theme.border
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 13
                            spacing: 11
                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 15
                                color: badgeCard.modelData.unlocked ? "#ffeb9b" : "#d1deed"
                                border.color: badgeCard.modelData.unlocked ? Theme.yellow : Theme.border
                                Text { anchors.centerIn: parent; text: badgeCard.modelData.unlocked ? "🏆" : "🔒"; color: badgeCard.modelData.unlocked ? Theme.yellow : Theme.textMuted; font.pixelSize: 21 }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: badgeCard.modelData.title; color: badgeCard.modelData.unlocked ? Theme.textPrimary : Theme.textSecondary; font.pixelSize: 12; font.bold: true }
                                    Text { text: badgeCard.modelData.unlocked ? qsTr("已解锁") : qsTr("%1 / %2").arg(badgeCard.modelData.current).arg(badgeCard.modelData.target); color: badgeCard.modelData.unlocked ? Theme.green : Theme.textMuted; font.pixelSize: 9 }
                                }
                                Text { Layout.fillWidth: true; text: badgeCard.modelData.description; color: Theme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 6
                                    radius: 3
                                    color: "#b6cbe8"
                                    Rectangle { width: parent.width * badgeCard.modelData.progress; height: parent.height; radius: parent.radius; color: badgeCard.modelData.unlocked ? Theme.yellow : "#268cff" }
                                }
                            }
                        }
                    }
                }
            }
            Text { Layout.fillWidth: true; text: qsTr("成就只依据本机累计工作日、等级和历史数据计算，不需要登录账号或联网。"); color: Theme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 3 }
        }
    }
}

