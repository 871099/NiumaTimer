// 首页假期卡：展示下一个官方假期、假期剩余时间和全年调休详情。
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PixelPanel {
    id: card
    required property var holiday
    readonly property bool compact: width < 700
    implicitHeight: holidayColumn.implicitHeight + 24
    accentColor: holiday.ongoing ? Theme.green : "#b0d6ff"

    ColumnLayout {
        id: holidayColumn
        anchors.fill: parent
        spacing: 5
        RowLayout {
            Layout.fillWidth: true
            PixelIcon { Layout.preferredWidth: 24; Layout.preferredHeight: 24; kind: "sun" }
            Text { Layout.fillWidth: true; text: card.holiday.label; color: Theme.textPrimary; font.bold: true; font.pixelSize: 13; wrapMode: Text.WordWrap }
            Text { visible: !card.compact; text: card.holiday.countdown; color: Theme.cyan; font.family: "Consolas"; font.bold: true; font.pixelSize: 23 }
            Button {
                text: qsTr("假期详情")
                onClicked: calendarPopup.open()
                contentItem: Text { text: qsTr("假期详情 ›"); color: Theme.cyan; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 9; color: Theme.surfaceDeep; border.color: Theme.border }
            }
        }
        Text {
            Layout.fillWidth: true
            visible: card.compact
            text: card.holiday.countdown
            color: card.holiday.ongoing ? "#008c60" : Theme.cyan
            font.pixelSize: 24
            font.bold: true
            font.family: "Consolas"
            fontSizeMode: Text.Fit
            minimumPixelSize: 20
        }
        Text {
            Layout.fillWidth: true
            text: (card.holiday.available ? card.holiday.dateText + " · " : "") + card.holiday.note
            color: card.holiday.confirmed ? Theme.textSecondary : Theme.orange
            font.pixelSize: 10
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            text: qsTr("法定放假日暂停上班计时、工资和经验；官方补班日按你设置的班次上班。")
            color: Theme.textSecondary
            font.pixelSize: 10
            wrapMode: Text.WordWrap
        }
    }

    Popup {
        id: calendarPopup
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(parent.width - 28, 560)
        height: Math.min(parent.height - 40, 610)
        padding: 18
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: Theme.surface; radius: 4; border.color: Theme.cyan; border.width: 2 }
        contentItem: ColumnLayout {
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: qsTr("中国内地 · 法定节假日"); color: Theme.textPrimary; font.pixelSize: 17; font.bold: true; wrapMode: Text.WordWrap }
                Button { text: qsTr("关闭"); onClicked: calendarPopup.close() }
            }
            Text { Layout.fillWidth: true; text: qsTr("法定放假日优先于固定周和大小周排班；放假日不累计工时、工资或经验。官方调休上班日按你设置的班次正常计算。"); color: Theme.textSecondary; font.pixelSize: 11; wrapMode: Text.WordWrap }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ColumnLayout {
                    width: parent.width
                    spacing: 9
                    Repeater {
                        model: card.holiday.calendar
                        delegate: Rectangle {
                            id: entry
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: entryColumn.implicitHeight + 24
                            radius: 12
                            color: Theme.surface
                            border.color: Theme.border
                            ColumnLayout {
                                id: entryColumn
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 12
                                spacing: 5
                                Text { Layout.fillWidth: true; text: entry.modelData.name + (entry.modelData.past ? qsTr(" · 已结束") : ""); color: entry.modelData.past ? Theme.textMuted : Theme.textPrimary; font.bold: true; font.pixelSize: 13 }
                                Text { Layout.fillWidth: true; text: entry.modelData.dateText + (entry.modelData.confirmed ? qsTr(" · 共%1天").arg(entry.modelData.days) : qsTr(" · 节日当天")); color: Theme.textSecondary; font.pixelSize: 11; wrapMode: Text.WordWrap }
                                Text { Layout.fillWidth: true; text: entry.modelData.makeupText; color: entry.modelData.confirmed ? Theme.textSecondary : Theme.orange; font.pixelSize: 10; wrapMode: Text.WordWrap }
                                Text {
                                    Layout.fillWidth: true
                                    text: entry.modelData.sourceTitle + qsTr(" ↗")
                                    color: Theme.cyan
                                    font.pixelSize: 9
                                    wrapMode: Text.WordWrap
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.openUrlExternally(entry.modelData.sourceUrl) }
                                }
                            }
                        }
                    }
                    Text { Layout.fillWidth: true; text: qsTr("已收录官方2026年安排；2027年目前仅展示元旦法定日期，连休及调休待正式公布后更新。"); color: Theme.textMuted; font.pixelSize: 10; wrapMode: Text.WordWrap }
                }
            }
        }
    }
}
