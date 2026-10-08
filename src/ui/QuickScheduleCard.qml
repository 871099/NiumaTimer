// 首页快捷班次设置复用原子时间提交与QSettings保存，不另建一套设置状态。
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PixelPanel {
    id: card
    required property var timerController
    signal navigateRequested(string route)
    property string errorText: ""
    function save() {
        if (!startField.acceptableInput || !endField.acceptableInput || startField.text === endField.text) {
            errorText = qsTr("请输入不同的有效上下班时间")
            return
        }
        const amount = Number(wageField.text)
        if (timerController.salaryMode === "hourly" && (!wageField.acceptableInput || !isFinite(amount))) {
            errorText = qsTr("请输入有效时薪")
            return
        }
        if (!timerController.setShiftTimes(startField.text, endField.text)) {
            errorText = qsTr("班次时间无效")
            return
        }
        if (timerController.salaryMode === "hourly") timerController.salaryAmount = amount
        errorText = timerController.applySettings() ? "" : qsTr("保存失败，请检查本地存储")
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: qsTr("工作时间设置"); color: Theme.textPrimary; font.pixelSize: 16; font.bold: true }
            PixelIcon { Layout.preferredWidth: 23; Layout.preferredHeight: 23; kind: "gear"; MouseArea { anchors.fill: parent; onClicked: card.navigateRequested("schedule") } }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 4
            rowSpacing: 3
            Text { text: qsTr("今日时薪"); color: Theme.textSecondary; font.pixelSize: 11 }
            TextField {
                id: wageField
                Layout.fillWidth: true; Layout.preferredHeight: 25
                text: card.timerController.salaryMode === "hourly" ? Number(card.timerController.salaryAmount).toFixed(2) : card.timerController.hourlyText
                readOnly: card.timerController.salaryMode !== "hourly"
                color: Theme.textSecondary; font.pixelSize: 11; padding: 3; selectByMouse: true
                validator: DoubleValidator { bottom: 0; top: 100000000; decimals: 2; notation: DoubleValidator.StandardNotation }
                background: Rectangle { color: "#f8fbff"; border.color: "#abc4f2"; radius: 2 }
            }
            Text { text: qsTr("元/小时"); color: Theme.textSecondary; font.pixelSize: 10 }
            Text { text: qsTr("有效工时"); color: Theme.textSecondary; font.pixelSize: 11 }
            Text { Layout.fillWidth: true; text: card.timerController.paidDayText; color: Theme.textSecondary; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
            Item { Layout.preferredWidth: 1; Layout.preferredHeight: 1 }
            Text { text: qsTr("上班时间"); color: Theme.textSecondary; font.pixelSize: 11 }
            TextField {
                id: startField
                Layout.fillWidth: true; Layout.preferredHeight: 25
                text: card.timerController.startTime
                color: Theme.textSecondary; font.pixelSize: 11; padding: 3; selectByMouse: true
                validator: RegularExpressionValidator { regularExpression: /^([01]\d|2[0-3]):[0-5]\d$/ }
                background: Rectangle { color: "#f8fbff"; border.color: "#abc4f2"; radius: 2 }
            }
            PixelIcon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; kind: "schedule" }
            Text { text: qsTr("下班时间"); color: Theme.textSecondary; font.pixelSize: 11 }
            TextField {
                id: endField
                Layout.fillWidth: true; Layout.preferredHeight: 25
                text: card.timerController.endTime
                color: Theme.textSecondary; font.pixelSize: 11; padding: 3; selectByMouse: true
                validator: RegularExpressionValidator { regularExpression: /^([01]\d|2[0-3]):[0-5]\d$/ }
                background: Rectangle { color: "#f8fbff"; border.color: "#abc4f2"; radius: 2 }
            }
            PixelIcon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; kind: "schedule" }
        }
        Text {
            Layout.fillWidth: true
            text: card.errorText || (card.timerController.salaryMode === "hourly" ? qsTr("休息 / 大小周：完整设置 ›") : qsTr("时薪由工资折算 · 修改工资 ›"))
            color: card.errorText ? Theme.red : Theme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: card.navigateRequested(card.timerController.salaryMode === "hourly" ? "schedule" : "salary") }
        }
        Button {
            Layout.fillWidth: true; Layout.preferredHeight: 32
            onClicked: card.save()
            contentItem: Text { text: qsTr("▣  保存设置"); color: "white"; font.pixelSize: 12; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { color: "#0058ff"; border.color: "#00e7ff"; border.width: 2; radius: 2 }
        }
    }
}
