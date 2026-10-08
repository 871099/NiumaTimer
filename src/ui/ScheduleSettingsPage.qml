// 工作时间页：维护班次、休息、固定周与大小周轮换规则。
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property var timerController
    property string validationMessage: ""
    readonly property bool compact: width < 700
    readonly property var weekdays: [qsTr("一"), qsTr("二"), qsTr("三"), qsTr("四"), qsTr("五"), qsTr("六"), qsTr("日")]

    function validClock(value) { return /^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(value) }
    function saveChanges() {
        if (!validClock(startField.text) || !validClock(endField.text) || startField.text === endField.text) {
            validationMessage = qsTr("上下班时间格式无效，且不能相同。")
            return false
        }
        if (timerController.breakEnabled &&
                (!validClock(breakStartField.text) || !validClock(breakEndField.text))) {
            validationMessage = qsTr("请检查休息时间格式。")
            return false
        }
        if (!timerController.setShiftTimes(startField.text, endField.text)) {
            validationMessage = qsTr("班次时间未能更新，请检查输入。")
            return false
        }
        if (timerController.breakEnabled) {
            timerController.breakStart = breakStartField.text
            timerController.breakEnd = breakEndField.text
        }
        const saved = timerController.applySettings()
        validationMessage = saved ? "" : qsTr("保存失败，请检查本地配置权限或磁盘空间。")
        return saved
    }

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
                Text { text: qsTr("工作时间设置"); color: Theme.textPrimary; font.pixelSize: 21; font.bold: true }
                Text { text: qsTr("安排班次和大小周，首页与历史统计会使用相同规则"); color: Theme.textMuted; font.pixelSize: 11; wrapMode: Text.WordWrap }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: timeColumn.implicitHeight + 32
                radius: Theme.radius
                color: Theme.surface
                border.color: Theme.border
                ColumnLayout {
                    id: timeColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 10
                    Text { text: qsTr("每日班次"); color: Theme.cyan; font.pixelSize: 13; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("上班时间"); color: Theme.textSecondary; font.pixelSize: 11 }
                        Item { Layout.fillWidth: true }
                        TextField { id: startField; Layout.preferredWidth: 108; implicitHeight: 40; text: page.timerController.startTime; inputMask: "00:00"; horizontalAlignment: Text.AlignHCenter; color: Theme.textPrimary; background: Rectangle { radius: 10; color: Theme.surfaceDeep; border.color: startField.activeFocus ? Theme.cyan : Theme.border } }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("下班时间"); color: Theme.textSecondary; font.pixelSize: 11 }
                        Item { Layout.fillWidth: true }
                        TextField { id: endField; Layout.preferredWidth: 108; implicitHeight: 40; text: page.timerController.endTime; inputMask: "00:00"; horizontalAlignment: Text.AlignHCenter; color: Theme.textPrimary; background: Rectangle { radius: 10; color: Theme.surfaceDeep; border.color: endField.activeFocus ? Theme.cyan : Theme.border } }
                    }
                    Text { Layout.fillWidth: true; text: qsTr("下班早于上班时按次日下班处理；休息时间从计薪工时中扣除。"); color: Theme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: breakColumn.implicitHeight + 32
                radius: Theme.radius
                color: Theme.surface
                border.color: Theme.border
                ColumnLayout {
                    id: breakColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout { Layout.fillWidth: true; spacing: 2; Text { text: qsTr("休息时段"); color: Theme.cyan; font.pixelSize: 13; font.bold: true } Text { text: qsTr("休息期间计时继续，工资和精力进度暂停"); color: Theme.textMuted; font.pixelSize: 9 } }
                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 28
                            radius: 14
                            color: page.timerController.breakEnabled ? "#a8ead9" : "#c8d9ec"
                            border.color: page.timerController.breakEnabled ? Theme.cyan : Theme.border
                            Rectangle { width: 20; height: 20; radius: 10; y: 3; x: page.timerController.breakEnabled ? parent.width - width - 4 : 4; color: page.timerController.breakEnabled ? Theme.cyan : Theme.textMuted; Behavior on x { NumberAnimation { duration: 120 } } }
                            MouseArea { anchors.fill: parent; onClicked: page.timerController.breakEnabled = !page.timerController.breakEnabled }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        visible: page.timerController.breakEnabled
                        Text { text: qsTr("休息从"); color: Theme.textSecondary; font.pixelSize: 11 }
                        Item { Layout.fillWidth: true }
                        TextField { id: breakStartField; Layout.preferredWidth: 96; implicitHeight: 38; text: page.timerController.breakStart; inputMask: "00:00"; horizontalAlignment: Text.AlignHCenter; color: Theme.textPrimary; background: Rectangle { radius: 10; color: Theme.surfaceDeep; border.color: breakStartField.activeFocus ? Theme.cyan : Theme.border } }
                        Text { text: "—"; color: Theme.textMuted }
                        TextField { id: breakEndField; Layout.preferredWidth: 96; implicitHeight: 38; text: page.timerController.breakEnd; inputMask: "00:00"; horizontalAlignment: Text.AlignHCenter; color: Theme.textPrimary; background: Rectangle { radius: 10; color: Theme.surfaceDeep; border.color: breakEndField.activeFocus ? Theme.cyan : Theme.border } }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: scheduleColumn.implicitHeight + 32
                radius: Theme.radius
                color: Theme.surface
                border.color: Theme.border
                ColumnLayout {
                    id: scheduleColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 10
                    Text { text: qsTr("排班规则"); color: Theme.cyan; font.pixelSize: 13; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        Repeater {
                            model: [
                                { label: qsTr("固定每周"), mode: "fixed" },
                                { label: qsTr("大小周轮换"), mode: "alternating" }
                            ]
                            delegate: Rectangle {
                                id: scheduleMode
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                radius: 11
                                color: page.timerController.scheduleMode === scheduleMode.modelData.mode ? "#d4eaff" : Theme.surfaceDeep
                                border.color: page.timerController.scheduleMode === scheduleMode.modelData.mode ? Theme.cyan : Theme.border
                                Text { anchors.centerIn: parent; text: scheduleMode.modelData.label; color: page.timerController.scheduleMode === scheduleMode.modelData.mode ? Theme.cyan : Theme.textSecondary; font.pixelSize: 11; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: page.timerController.scheduleMode = scheduleMode.modelData.mode }
                            }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: page.timerController.scheduleMode === "fixed"
                        spacing: 7
                        Text { text: qsTr("每周上班日"); color: Theme.textSecondary; font.pixelSize: 10 }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Repeater {
                                model: page.weekdays
                                delegate: Rectangle {
                                    id: fixedDay
                                    required property int index
                                    required property string modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    radius: 9
                                    color: page.timerController.worksOn(fixedDay.index) ? "#d4eaff" : Theme.surfaceDeep
                                    border.color: page.timerController.worksOn(fixedDay.index) ? Theme.cyan : Theme.border
                                    Text { anchors.centerIn: parent; text: fixedDay.modelData; color: page.timerController.worksOn(fixedDay.index) ? Theme.cyan : Theme.textMuted; font.pixelSize: 11; font.bold: true }
                                    MouseArea { anchors.fill: parent; onClicked: page.timerController.setWorksOn(fixedDay.index, !page.timerController.worksOn(fixedDay.index)) }
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: page.timerController.scheduleMode === "alternating"
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("基准周：%1 为%2；之后每周自动交替。")
                                  .arg(page.timerController.rotationAnchorText)
                                  .arg(page.timerController.rotationAnchorIsBigWeek ? qsTr("大周") : qsTr("小周"))
                            color: Theme.textSecondary
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 7
                            Repeater {
                                model: [
                                    { label: qsTr("将本周设为大周"), big: true },
                                    { label: qsTr("将本周设为小周"), big: false }
                                ]
                                delegate: Rectangle {
                                    id: weekAnchor
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    radius: 9
                                    color: page.timerController.rotationAnchorIsBigWeek === weekAnchor.modelData.big ? "#d4eaff" : Theme.surfaceDeep
                                    border.color: page.timerController.rotationAnchorIsBigWeek === weekAnchor.modelData.big ? Theme.cyan : Theme.border
                                    Text { anchors.centerIn: parent; text: weekAnchor.modelData.label; color: Theme.textSecondary; font.pixelSize: 9 }
                                    MouseArea { anchors.fill: parent; onClicked: page.timerController.setCurrentWeekAsBig(weekAnchor.modelData.big) }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: qsTr("大周"); color: Theme.orange; font.pixelSize: 10; Layout.preferredWidth: 32 }
                            Repeater {
                                model: page.weekdays
                                delegate: Rectangle {
                                    id: bigWeekDay
                                    required property int index
                                    required property string modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    radius: 8
                                    color: page.timerController.worksOnPattern(true, bigWeekDay.index) ? "#d4eaff" : Theme.surfaceDeep
                                    border.color: page.timerController.worksOnPattern(true, bigWeekDay.index) ? Theme.cyan : Theme.border
                                    Text { anchors.centerIn: parent; text: bigWeekDay.modelData; color: page.timerController.worksOnPattern(true, bigWeekDay.index) ? Theme.cyan : Theme.textMuted; font.pixelSize: 10 }
                                    MouseArea { anchors.fill: parent; onClicked: page.timerController.setWorksOnPattern(true, bigWeekDay.index, !page.timerController.worksOnPattern(true, bigWeekDay.index)) }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: qsTr("小周"); color: Theme.magenta; font.pixelSize: 10; Layout.preferredWidth: 32 }
                            Repeater {
                                model: page.weekdays
                                delegate: Rectangle {
                                    id: smallWeekDay
                                    required property int index
                                    required property string modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    radius: 8
                                    color: page.timerController.worksOnPattern(false, smallWeekDay.index) ? "#d4eaff" : Theme.surfaceDeep
                                    border.color: page.timerController.worksOnPattern(false, smallWeekDay.index) ? Theme.cyan : Theme.border
                                    Text { anchors.centerIn: parent; text: smallWeekDay.modelData; color: page.timerController.worksOnPattern(false, smallWeekDay.index) ? Theme.cyan : Theme.textMuted; font.pixelSize: 10 }
                                    MouseArea { anchors.fill: parent; onClicked: page.timerController.setWorksOnPattern(false, smallWeekDay.index, !page.timerController.worksOnPattern(false, smallWeekDay.index)) }
                                }
                            }
                        }
                    }
                    Text { Layout.fillWidth: true; text: qsTr("节假日和调休暂不自动识别；如需不同排班，请在这里更新每周工作日。"); color: Theme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 13; color: "#0058ff"; border.color: Theme.cyan; Text { anchors.centerIn: parent; text: qsTr("保存工作时间"); color: "white"; font.pixelSize: 12; font.bold: true } MouseArea { anchors.fill: parent; onClicked: page.saveChanges() } }
            Text { Layout.fillWidth: true; visible: page.validationMessage.length > 0; text: page.validationMessage; color: Theme.red; font.pixelSize: 10; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 3 }
        }
    }
}

