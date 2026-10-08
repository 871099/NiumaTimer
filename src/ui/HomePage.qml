// 产品图首页：办公室主视觉、并列主卡、三列状态面板，手机纵向重排。
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property var timerController
    property var historyStore
    signal navigateRequested(string target)
    readonly property bool compact: width < 820
    readonly property var monthStats: {
        historyStore.records
        return historyStore.statistics("month", timerController.liveSummary)
    }
    function accessory() {
        if (historyStore.selectedOutfit === "hardhat") return "⛑"
        if (historyStore.selectedOutfit === "neon") return "✦"
        if (historyStore.selectedOutfit === "crown") return "♛"
        return ""
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            x: 9
            width: parent.width - 18
            spacing: 7
            Item { Layout.preferredHeight: 1 }

            PixelPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: page.compact ? 174 : 204
                padding: 5
                fillColor: "#102255"
                accentColor: "#00bfff"
                Item {
                    anchors.fill: parent
                    clip: true
                    Image { anchors.fill: parent; source: "qrc:/qt/qml/NiumaTimer/assets/office-pixel-v2.png"; fillMode: Image.Stretch; smooth: false }
                    AnimatedSprite {
                        id: cow
                        width: page.compact ? 176 : 230
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: page.compact ? -12 : -22
                        source: "qrc:/qt/qml/NiumaTimer/assets/cow-fatigue-spritesheet.png"
                        frameWidth: 512; frameHeight: 512; frameCount: 6
                        currentFrame: Math.round(page.timerController.progress * 5)
                        running: false; paused: true; interpolate: false; smooth: false
                    }
                    Text { anchors.horizontalCenter: cow.horizontalCenter; anchors.top: cow.top; anchors.topMargin: 26; text: page.accessory(); color: Theme.yellow; font.pixelSize: 23; style: Text.Outline; styleColor: "#07142c" }
                    Rectangle {
                        x: page.compact ? 8 : parent.width * 0.36
                        y: page.compact ? 50 : 7
                        width: page.compact ? 92 : 146
                        height: 27
                        color: "#edffffff"; border.color: "#27418d"; border.width: 2
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 4; spacing: 4
                            Text { text: "HP"; color: Theme.textPrimary; font.pixelSize: 9; font.bold: true }
                            PixelMeter { Layout.fillWidth: true; Layout.preferredHeight: 9; value: 1 - page.timerController.progress; fillColor: Theme.red }
                            Text { text: (100 - page.timerController.freeValue).toString(); color: Theme.textSecondary; font.pixelSize: 9 }
                        }
                    }
                    PixelPanel {
                        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
                        width: page.compact ? 210 : 292; height: 49; padding: 8
                        RowLayout {
                            anchors.fill: parent; spacing: 5
                            PixelIcon { Layout.preferredWidth: 27; Layout.preferredHeight: 27; kind: "money" }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: qsTr("Lv.%1 打工牛马").arg(page.timerController.experienceLevel); color: Theme.textPrimary; font.bold: true; font.pixelSize: 11 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: qsTr("EXP %1 / 500").arg(page.timerController.experiencePoints); color: Theme.textSecondary; font.pixelSize: 9 }
                                }
                                PixelMeter { Layout.fillWidth: true; Layout.preferredHeight: 9; value: page.timerController.experienceProgress; fillColor: "#008dff" }
                            }
                        }
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 7
                        width: message.implicitWidth + 15; height: 23; color: "#cf0b1735"; border.color: "#bc61ff"
                        Text { id: message; anchors.centerIn: parent; text: qsTr("任务：苟到下班！  ·  累计 %1 天").arg(page.timerController.completedWorkdays); color: "#ffffff"; font.bold: true; font.pixelSize: 10 }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: page.compact ? 1 : 2
                columnSpacing: 7; rowSpacing: 7
                PixelPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: page.compact ? 164 : 154
                    fillColor: "#ecfaff"
                    padding: 12
                    Item {
                        anchors.fill: parent
                        PixelIcon { anchors.right: parent.right; anchors.top: parent.top; width: 41; height: 41; kind: "sun" }
                        PixelIcon { anchors.left: parent.left; anchors.bottom: parent.bottom; width: 42; height: 42; kind: "palm" }
                        PixelIcon { anchors.right: parent.right; anchors.bottom: parent.bottom; width: 33; height: 33; kind: "palm" }
                        ColumnLayout {
                            anchors.fill: parent; spacing: 1
                            Text { text: page.timerController.countdownLabel; color: Theme.textPrimary; font.pixelSize: 16; font.bold: true }
                            PixelDigits { Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 55; text: page.timerController.countdownText }
                            RowLayout {
                                Layout.fillWidth: true; Layout.leftMargin: 30; Layout.rightMargin: 30
                                Text { Layout.fillWidth: true; text: qsTr("小时"); color: Theme.textSecondary; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter }
                                Text { Layout.fillWidth: true; text: qsTr("分钟"); color: Theme.textSecondary; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter }
                                Text { Layout.fillWidth: true; text: qsTr("秒"); color: Theme.textSecondary; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter }
                            }
                            Text { Layout.fillWidth: true; text: qsTr("再坚持一下，下班就能拥抱自由了！"); color: Theme.textSecondary; font.bold: true; font.pixelSize: page.compact ? 10 : 11; horizontalAlignment: Text.AlignHCenter }
                        }
                    }
                }
                PixelPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: page.compact ? 133 : 154
                    RowLayout {
                        anchors.fill: parent; spacing: 7
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 5
                            RowLayout {
                                PixelIcon { Layout.preferredWidth: 32; Layout.preferredHeight: 32; kind: "money" }
                                Text { text: qsTr("今日工资"); color: Theme.textPrimary; font.pixelSize: 19; font.bold: true }
                            }
                            PixelDigits { Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 37; text: "¥" + page.timerController.earnedText; ink: Theme.orange; outlined: false }
                            Text { text: qsTr("每一秒，都有收获"); color: Theme.textMuted; font.pixelSize: 10 }
                        }
                        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.topMargin: 20; Layout.bottomMargin: 18; color: "#acc8ef" }
                        ColumnLayout {
                            Layout.preferredWidth: page.compact ? 136 : 156; spacing: 9
                            Text { Layout.fillWidth: true; text: qsTr("时薪：¥ %1").arg(page.timerController.hourlyText); color: Theme.textSecondary; font.pixelSize: 11; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: qsTr("今日工时：%1").arg(page.timerController.earnedTimeText); color: Theme.textSecondary; font.pixelSize: 11; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: qsTr("本月累计：¥ %1").arg((Number(page.monthStats.incomeCents) / 100).toFixed(2)); color: Theme.textSecondary; font.pixelSize: 11; elide: Text.ElideRight }
                            Text { text: qsTr("查看统计 ›"); color: Theme.cyan; font.pixelSize: 10; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.navigateRequested("statistics") } }
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: page.compact ? 1 : 3
                columnSpacing: 7; rowSpacing: 7
                PixelPanel {
                    Layout.fillWidth: true; Layout.preferredWidth: 238
                    Layout.preferredHeight: 214
                    ColumnLayout {
                        anchors.fill: parent; spacing: 8
                        Text { text: qsTr("角色状态"); color: Theme.textPrimary; font.pixelSize: 16; font.bold: true }
                        Repeater {
                            model: [
                                {icon: "coffee", label: qsTr("HP（精力值）"), value: 100 - page.timerController.freeValue, color: Theme.red},
                                {icon: "freedom", label: qsTr("自由值"), value: page.timerController.freeValue, color: "#ffcc00"},
                                {icon: "fish", label: qsTr("摸鱼值"), value: page.timerController.fishingValue, color: "#00baff"}
                            ]
                            delegate: RowLayout {
                                id: statusRow
                                required property var modelData
                                Layout.fillWidth: true; spacing: 7
                                PixelIcon { Layout.preferredWidth: 33; Layout.preferredHeight: 33; kind: statusRow.modelData.icon }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 3
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { Layout.fillWidth: true; text: statusRow.modelData.label; color: Theme.textPrimary; font.bold: true; font.pixelSize: 10 }
                                        Text { text: statusRow.modelData.value + "/100"; color: Theme.textSecondary; font.pixelSize: 10 }
                                    }
                                    PixelMeter { Layout.fillWidth: true; Layout.preferredHeight: 16; value: statusRow.modelData.value / 100; fillColor: statusRow.modelData.color }
                                }
                            }
                        }
                    }
                }
                PixelPanel {
                    Layout.fillWidth: true; Layout.preferredWidth: 385
                    Layout.preferredHeight: 214
                    ColumnLayout {
                        anchors.fill: parent; spacing: 7
                        RowLayout {
                            Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: qsTr("今日进度"); color: Theme.textPrimary; font.pixelSize: 16; font.bold: true }
                            Text { text: page.timerController.progressText; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }
                        }
                        Text { text: page.timerController.earnedTimeText + " / " + page.timerController.paidDayText; color: Theme.textSecondary; font.pixelSize: 10 }
                        PixelMeter { Layout.fillWidth: true; Layout.preferredHeight: 23; value: page.timerController.progress }
                        RowLayout {
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 3
                            Repeater {
                                model: page.timerController.timelineTasks.slice(0, 5)
                                delegate: ColumnLayout {
                                    id: node
                                    required property var modelData
                                    Layout.fillWidth: true; Layout.minimumWidth: 0; spacing: 3
                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 18; Layout.preferredHeight: 18; radius: 9
                                        color: node.modelData.done ? "#00cd90" : "#ffffff"
                                        border.color: node.modelData.current ? Theme.cyan : "#1b4298"
                                        Text { anchors.centerIn: parent; text: node.modelData.done ? "✓" : node.modelData.current ? "●" : ""; color: node.modelData.done ? "white" : Theme.cyan; font.pixelSize: 12 }
                                    }
                                    PixelIcon { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 35; Layout.preferredHeight: 35; kind: "cow" }
                                    Text { Layout.fillWidth: true; text: node.modelData.title; color: Theme.textPrimary; font.bold: true; font.pixelSize: 10; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
                                    Text { Layout.fillWidth: true; text: node.modelData.time; color: Theme.textSecondary; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter }
                                }
                            }
                        }
                        Text { text: qsTr("维护今日任务与阶段 ›"); color: Theme.cyan; font.pixelSize: 9; MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.navigateRequested("tasks") } }
                    }
                }
                QuickScheduleCard {
                    Layout.fillWidth: true; Layout.preferredWidth: 256
                    Layout.preferredHeight: 214
                    timerController: page.timerController
                    onNavigateRequested: function(target) { page.navigateRequested(target) }
                }
            }
            HolidayCountdownCard { Layout.fillWidth: true; holiday: page.timerController.holiday }
            Text { Layout.fillWidth: true; text: page.timerController.dateText + "  ·  " + page.timerController.shiftText + "  ·  " + page.timerController.networkTimeStatusText; color: "#d1e8ff"; font.pixelSize: 9; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 1 }
        }
    }
}
