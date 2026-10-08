// 今日任务页：排班节点自动同步，用户事项可增删改和标记完成但不影响计薪。
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property var timerController
    property var historyStore
    property string validationMessage: ""
    readonly property var customTasks: historyStore.todayTasks

    function openTaskEditor(task) {
        validationMessage = ""
        taskDialog.editingId = task ? task.id : ""
        titleField.text = task ? task.title : ""
        timeField.text = task ? task.time : timerController.startTime
        taskDialog.open()
    }
    function saveTask() {
        const title = titleField.text.trim()
        const time = timeField.text
        if (title.length === 0 || title.length > 48 || !/^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(time)) {
            validationMessage = qsTr("请输入 1–48 个字的事项名称和有效时间（HH:mm）。")
            return false
        }
        const saved = taskDialog.editingId.length > 0
                    ? historyStore.updateTask(taskDialog.editingId, title, time)
                    : historyStore.addTask(title, time)
        if (!saved) {
            validationMessage = qsTr("事项保存失败，请检查本地存储空间或输入数量。")
            return false
        }
        taskDialog.close()
        return true
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
                    Text { text: qsTr("今天的打工路线"); color: Theme.textPrimary; font.pixelSize: 21; font.bold: true }
                    Text { text: qsTr("%1 · 完成事项只记进度，不改变工资").arg(page.timerController.liveSummary.date); color: Theme.textMuted; font.pixelSize: 11 }
                }
                Rectangle {
                    Layout.preferredWidth: 98
                    Layout.preferredHeight: 40
                    radius: 12
                    color: "#0058ff"
                    border.color: Theme.cyan
                    Row { anchors.centerIn: parent; spacing: 5; Text { text: "+"; color: "white"; font.pixelSize: 18; font.bold: true } Text { text: qsTr("加事项"); color: "white"; font.pixelSize: 11; font.bold: true } }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.openTaskEditor(null) }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 94
                radius: Theme.radius
                color: "#dceeff"
                border.color: "#6ba8ea"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: page.width < 700 ? 12 : 18
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text { text: page.timerController.statusText; color: Theme.textPrimary; font.pixelSize: 13; font.bold: true }
                        Text { text: qsTr("%1 · 已工作 %2 · 还剩 %3").arg(page.timerController.shiftText).arg(page.timerController.earnedTimeText).arg(page.timerController.countdownText); color: Theme.textSecondary; font.pixelSize: 10; wrapMode: Text.WordWrap }
                    }
                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 58
                        radius: 13
                        color: "#d9ebff"
                        border.color: Theme.border
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("精力"); color: Theme.textMuted; font.pixelSize: 9 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("%1%").arg(100 - page.timerController.freeValue); color: Theme.yellow; font.pixelSize: 17; font.bold: true }
                        }
                    }
                }
            }

            Text { text: qsTr("排班节点"); color: Theme.cyan; font.pixelSize: 13; font.bold: true }
            Repeater {
                model: page.timerController.timelineTasks
                delegate: Rectangle {
                    id: timelineTask
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    radius: 14
                    color: timelineTask.modelData.current ? "#d6f4ee" : Theme.surface
                    border.color: timelineTask.modelData.current ? Theme.cyan : timelineTask.modelData.done ? "#00a77b" : Theme.border
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: timelineTask.modelData.done ? "#a4e9cd" : timelineTask.modelData.current ? "#c4edf8" : "#dbe6f4"
                            border.color: timelineTask.modelData.done ? Theme.green : timelineTask.modelData.current ? Theme.cyan : Theme.border
                            Text { anchors.centerIn: parent; text: timelineTask.modelData.done ? "✓" : timelineTask.modelData.current ? "●" : "○"; color: timelineTask.modelData.done ? Theme.green : timelineTask.modelData.current ? Theme.cyan : Theme.textMuted; font.pixelSize: 14 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: timelineTask.modelData.title; color: Theme.textPrimary; font.pixelSize: 12; font.bold: true }
                            Text { text: timelineTask.modelData.current ? qsTr("当前阶段") : timelineTask.modelData.done ? qsTr("已完成 / 已经过") : qsTr("等待开始"); color: Theme.textMuted; font.pixelSize: 9 }
                        }
                        Text { text: timelineTask.modelData.time; color: timelineTask.modelData.current ? Theme.cyan : Theme.textSecondary; font.pixelSize: 12; font.bold: true }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: qsTr("我的事项"); color: Theme.cyan; font.pixelSize: 13; font.bold: true }
                Item { Layout.fillWidth: true }
                Text { text: qsTr("%1 项").arg(page.customTasks.length); color: Theme.textMuted; font.pixelSize: 10 }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: page.customTasks.length === 0 ? 84 : customTaskList.implicitHeight + 20
                radius: Theme.radius
                color: Theme.surface
                border.color: Theme.border
                ColumnLayout {
                    id: customTaskList
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 5
                    visible: page.customTasks.length > 0
                    Repeater {
                        model: page.customTasks
                        delegate: Rectangle {
                            id: customTask
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            radius: 11
                            color: "#eaf4ff"
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 9
                                Rectangle {
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    radius: 7
                                    color: customTask.modelData.done ? "#b1ead7" : "#dfebfa"
                                    border.color: customTask.modelData.done ? Theme.green : Theme.border
                                    Text { anchors.centerIn: parent; text: customTask.modelData.done ? "✓" : ""; color: Theme.green; font.pixelSize: 14 }
                                    MouseArea { anchors.fill: parent; onClicked: page.historyStore.setTaskCompleted(customTask.modelData.id, !customTask.modelData.done) }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text { Layout.fillWidth: true; text: customTask.modelData.title; color: customTask.modelData.done ? Theme.textMuted : Theme.textPrimary; font.pixelSize: 11; font.strikeout: customTask.modelData.done; elide: Text.ElideRight }
                                    Text { text: customTask.modelData.time; color: Theme.textMuted; font.pixelSize: 9 }
                                }
                                Text {
                                    text: "✎"
                                    color: Theme.cyan
                                    font.pixelSize: 16
                                    MouseArea { anchors.fill: parent; onClicked: page.openTaskEditor(customTask.modelData) }
                                }
                                Text {
                                    text: "×"
                                    color: Theme.red
                                    font.pixelSize: 20
                                    MouseArea { anchors.fill: parent; onClicked: page.historyStore.removeTask(customTask.modelData.id) }
                                }
                            }
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: page.customTasks.length === 0
                    text: qsTr("还没有自定义事项，点右上角添加")
                    color: Theme.textMuted
                    font.pixelSize: 11
                }
            }
            Text { Layout.fillWidth: true; text: qsTr("自定义事项按日期保存在本机。勾选只更新个人进度，不会改变工资或排班结算。"); color: Theme.textMuted; font.pixelSize: 10; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 3 }
        }
    }

    Dialog {
        id: taskDialog
        property string editingId: ""
        parent: Overlay.overlay
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: Math.min(360, page.width - 24)
        modal: true
        title: editingId.length > 0 ? qsTr("编辑事项") : qsTr("新增事项")
        standardButtons: Dialog.NoButton
        background: Rectangle { radius: 18; color: Theme.surfaceRaised; border.color: Theme.cyan }
        contentItem: ColumnLayout {
            spacing: 10
            Text { text: qsTr("事项名称"); color: Theme.textSecondary; font.pixelSize: 11 }
            TextField {
                id: titleField
                Layout.fillWidth: true
                maximumLength: 48
                placeholderText: qsTr("例如：完成周报")
                color: Theme.textPrimary
                background: Rectangle { radius: 10; color: Theme.surfaceDeep; border.color: titleField.activeFocus ? Theme.cyan : Theme.border }
            }
            Text { text: qsTr("计划时间"); color: Theme.textSecondary; font.pixelSize: 11 }
            TextField {
                id: timeField
                Layout.fillWidth: true
                inputMask: "00:00"
                placeholderText: "HH:mm"
                color: Theme.textPrimary
                background: Rectangle { radius: 10; color: Theme.surfaceDeep; border.color: timeField.activeFocus ? Theme.cyan : Theme.border }
            }
            Text { Layout.fillWidth: true; visible: page.validationMessage.length > 0; text: page.validationMessage; color: Theme.red; font.pixelSize: 10; wrapMode: Text.WordWrap }
            RowLayout {
                Layout.fillWidth: true
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 38; radius: 10; color: Theme.surfaceDeep; Text { anchors.centerIn: parent; text: qsTr("取消"); color: Theme.textSecondary; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: taskDialog.close() } }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 38; radius: 10; color: "#0058ff"; Text { anchors.centerIn: parent; text: qsTr("保存事项"); color: "white"; font.pixelSize: 11; font.bold: true } MouseArea { anchors.fill: parent; onClicked: page.saveTask() } }
            }
        }
    }
}

