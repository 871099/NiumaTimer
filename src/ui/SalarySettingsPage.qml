// 工资设置页：只管理估薪方式、金额、计薪天数和历史累计天数。
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property var timerController
    property string validationMessage: ""
    readonly property bool compact: width < 700

    function saveChanges() {
        if (!salaryField.acceptableInput || !isFinite(Number(salaryField.text)) ||
                Number(salaryField.text) < 0) {
            validationMessage = qsTr("请输入有效的工资金额。")
            return false
        }
        if (timerController.salaryMode === "monthly" &&
                (!daysField.acceptableInput || Number(daysField.text) < 1 || Number(daysField.text) > 31)) {
            validationMessage = qsTr("月计薪天数需要在 1 到 31 天之间。")
            return false
        }
        if (!workedDaysField.acceptableInput || !Number.isInteger(Number(workedDaysField.text)) ||
                Number(workedDaysField.text) < 0 || Number(workedDaysField.text) > 10000000) {
            validationMessage = qsTr("请输入 0 到 10000000 之间的累计上班天数。")
            return false
        }
        timerController.salaryAmount = Number(salaryField.text)
        if (timerController.salaryMode === "monthly") timerController.monthlyWorkDays = Number(daysField.text)
        timerController.completedWorkdays = Number(workedDaysField.text)
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
                Text { text: qsTr("工资设置"); color: Theme.textPrimary; font.pixelSize: 21; font.bold: true }
                Text { text: qsTr("配置估薪口径与打工经验起点"); color: Theme.textMuted; font.pixelSize: 11 }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: salaryColumn.implicitHeight + 32
                radius: Theme.radius
                color: Theme.surface
                border.color: Theme.border
                ColumnLayout {
                    id: salaryColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 11
                    Text { text: qsTr("工资方式"); color: Theme.cyan; font.pixelSize: 13; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7
                        Repeater {
                            model: [
                                { label: qsTr("月薪"), key: "monthly" },
                                { label: qsTr("日薪"), key: "daily" },
                                { label: qsTr("时薪"), key: "hourly" }
                            ]
                            delegate: Rectangle {
                                id: salaryMode
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 42
                                radius: 11
                                color: page.timerController.salaryMode === salaryMode.modelData.key ? "#d4eaff" : Theme.surfaceDeep
                                border.color: page.timerController.salaryMode === salaryMode.modelData.key ? Theme.cyan : Theme.border
                                Text { anchors.centerIn: parent; text: salaryMode.modelData.label; color: page.timerController.salaryMode === salaryMode.modelData.key ? Theme.cyan : Theme.textSecondary; font.pixelSize: 12; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: page.timerController.salaryMode = salaryMode.modelData.key }
                            }
                        }
                    }
                    Text {
                        text: page.timerController.salaryMode === "monthly" ? qsTr("税前月薪（元）") :
                              page.timerController.salaryMode === "daily" ? qsTr("税前日薪（元）") : qsTr("税前时薪（元）")
                        color: Theme.textSecondary
                        font.pixelSize: 11
                    }
                    TextField {
                        id: salaryField
                        Layout.fillWidth: true
                        implicitHeight: 48
                        text: Number(page.timerController.salaryAmount).toFixed(2)
                        color: Theme.textPrimary
                        font.pixelSize: 17
                        selectByMouse: true
                        validator: DoubleValidator { bottom: 0; top: 100000000; decimals: 2; notation: DoubleValidator.StandardNotation }
                        placeholderText: qsTr("输入工资金额")
                        background: Rectangle { radius: 12; color: Theme.surfaceDeep; border.color: salaryField.activeFocus ? Theme.cyan : Theme.border }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        visible: page.timerController.salaryMode === "monthly"
                        Text { text: qsTr("月计薪天数"); color: Theme.textSecondary; font.pixelSize: 11 }
                        Item { Layout.fillWidth: true }
                        TextField {
                            id: daysField
                            Layout.preferredWidth: 112
                            implicitHeight: 40
                            text: Number(page.timerController.monthlyWorkDays).toFixed(2)
                            color: Theme.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            validator: DoubleValidator { bottom: 1; top: 31; decimals: 2 }
                            background: Rectangle { radius: 10; color: Theme.surfaceDeep; border.color: daysField.activeFocus ? Theme.cyan : Theme.border }
                        }
                        Text { text: qsTr("天"); color: Theme.textMuted; font.pixelSize: 11 }
                    }
                    Text { Layout.fillWidth: true; text: qsTr("月薪按月计薪天数与每日有效工时折算；金额为个人税前估算，不含个税、社保和公积金。"); color: Theme.textMuted; font.pixelSize: 10; wrapMode: Text.WordWrap }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: experienceColumn.implicitHeight + 32
                radius: Theme.radius
                color: Theme.surface
                border.color: Theme.border
                ColumnLayout {
                    id: experienceColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 10
                    Text { text: qsTr("经验与网络时间"); color: Theme.cyan; font.pixelSize: 13; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text { text: qsTr("已上班天数"); color: Theme.textSecondary; font.pixelSize: 11 }
                            Text { text: qsTr("每完成一个排班日增加 20 XP"); color: Theme.textMuted; font.pixelSize: 9 }
                        }
                        TextField {
                            id: workedDaysField
                            Layout.preferredWidth: 112
                            implicitHeight: 40
                            text: String(page.timerController.completedWorkdays)
                            color: Theme.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            selectByMouse: true
                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator { bottom: 0; top: 10000000 }
                            background: Rectangle { radius: 10; color: Theme.surfaceDeep; border.color: workedDaysField.activeFocus ? Theme.cyan : Theme.border }
                        }
                        Text { text: qsTr("天"); color: Theme.textMuted; font.pixelSize: 11 }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3
                            Text { text: qsTr("网络时间"); color: Theme.textSecondary; font.pixelSize: 11 }
                            Text { Layout.fillWidth: true; text: page.timerController.networkTimeStatusText; color: page.timerController.networkTimeStatusText.indexOf("已同步") >= 0 ? Theme.green : Theme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap }
                        }
                        Rectangle {
                            Layout.preferredWidth: 92
                            Layout.preferredHeight: 36
                            radius: 11
                            color: "#d8edff"
                            border.color: Theme.cyan
                            Text { anchors.centerIn: parent; text: qsTr("立即同步"); color: Theme.cyan; font.pixelSize: 10; font.bold: true }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.timerController.syncNetworkTime() }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 14
                color: "#0058ff"
                border.color: Theme.cyan
                Text { anchors.centerIn: parent; text: qsTr("保存工资设置"); color: "white"; font.pixelSize: 13; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.saveChanges() }
            }
            Text { Layout.fillWidth: true; visible: page.validationMessage.length > 0; text: page.validationMessage; color: Theme.red; font.pixelSize: 10; wrapMode: Text.WordWrap }
            Text { Layout.fillWidth: true; text: qsTr("设置只保存在这台设备上。每日估薪在班次结束后写入历史，不会因以后改薪资而回算。"); color: Theme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 3 }
        }
    }
}

