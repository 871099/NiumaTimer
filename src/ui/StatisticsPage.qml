// 历史统计页：按日、周、月汇总本机结算记录和当前班次实时快照。
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property var timerController
    property var historyStore
    property string period: "week"
    readonly property var currentStats: {
        historyStore.records
        return historyStore.statistics(period, timerController.liveSummary)
    }
    readonly property var chartData: {
        historyStore.records
        return historyStore.chartBars(period, timerController.liveSummary)
    }
    readonly property var recentRecords: {
        const all = historyStore.records
        return all.slice(Math.max(0, all.length - 10)).reverse()
    }

    function money(cents) { return "¥ " + (Number(cents || 0) / 100).toFixed(2) }
    function maxIncome() {
        let maximum = 0
        for (let i = 0; i < chartData.length; ++i)
            maximum = Math.max(maximum, Number(chartData[i].incomeCents || 0))
        return Math.max(maximum, 1)
    }
    function rangeLabel() {
        if (period === "day") return qsTr("当前班次估算")
        if (period === "month") return qsTr("本月排班记录")
        return qsTr("本周排班记录")
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
                    Text { text: qsTr("打工数据统计"); color: Theme.textPrimary; font.pixelSize: 21; font.bold: true }
                    Text { text: qsTr("工资与时长按本地班次规则估算"); color: Theme.textMuted; font.pixelSize: 11 }
                }
                Text { text: qsTr("%1 条历史").arg(page.historyStore.records.length); color: Theme.cyan; font.pixelSize: 10 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7
                Repeater {
                    model: [
                        { id: "day", label: qsTr("今天") },
                        { id: "week", label: qsTr("本周") },
                        { id: "month", label: qsTr("本月") }
                    ]
                    delegate: Rectangle {
                        id: periodTab
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 11
                        color: page.period === periodTab.modelData.id ? "#d4eaff" : Theme.surfaceDeep
                        border.color: page.period === periodTab.modelData.id ? Theme.cyan : Theme.border
                        Text { anchors.centerIn: parent; text: periodTab.modelData.label; color: page.period === periodTab.modelData.id ? Theme.cyan : Theme.textSecondary; font.pixelSize: 11; font.bold: page.period === periodTab.modelData.id }
                        MouseArea { anchors.fill: parent; onClicked: page.period = periodTab.modelData.id }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 9
                rowSpacing: 9
                Repeater {
                    model: [
                        { title: qsTr("估算收入"), value: page.money(page.currentStats.incomeCents), icon: "¥", color: Theme.orange },
                        { title: qsTr("有效工时"), value: qsTr("%1 小时").arg(Number(page.currentStats.hours || 0).toFixed(1)), icon: "◷", color: Theme.cyan },
                        { title: qsTr("排班天数"), value: qsTr("%1 天").arg(page.currentStats.workdays || 0), icon: "☷", color: Theme.green },
                        { title: qsTr("日均收入"), value: page.money(page.currentStats.averageCents), icon: "↗", color: Theme.yellow }
                    ]
                    delegate: Rectangle {
                        id: metricCard
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 86
                        radius: 15
                        color: Theme.surface
                        border.color: Theme.border
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10
                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                radius: 12
                                color: "#dcefff"
                                border.color: metricCard.modelData.color
                                Text { anchors.centerIn: parent; text: metricCard.modelData.icon; color: metricCard.modelData.color; font.pixelSize: 18; font.bold: true }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text { text: metricCard.modelData.title; color: Theme.textMuted; font.pixelSize: 9 }
                                Text { Layout.fillWidth: true; text: metricCard.modelData.value; color: metricCard.modelData.color; font.pixelSize: page.width < 450 ? 15 : 18; font.bold: true; fontSizeMode: Text.Fit; minimumPixelSize: 12 }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 260
                radius: Theme.radius
                color: Theme.surface
                border.color: Theme.border
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 7
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("%1 · 工资趋势").arg(page.rangeLabel()); color: Theme.textPrimary; font.pixelSize: 13; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: page.money(page.currentStats.incomeCents); color: Theme.orange; font.pixelSize: 11; font.bold: true }
                    }
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: Math.max(width, barRow.implicitWidth)
                        contentHeight: height
                        flickableDirection: Flickable.HorizontalFlick
                        boundsBehavior: Flickable.StopAtBounds
                        Row {
                            id: barRow
                            height: parent.height
                            spacing: page.period === "month" ? 3 : 8
                            Repeater {
                                model: page.chartData
                                delegate: Column {
                                    id: chartBar
                                    required property var modelData
                                    width: page.period === "month" ? 22 : Math.max(34, (page.width - 70) / Math.max(1, page.chartData.length))
                                    height: barRow.height
                                    spacing: 3
                                    Text {
                                        width: parent.width
                                        text: page.money(chartBar.modelData.incomeCents).replace("¥ ", "")
                                        color: chartBar.modelData.hasData ? Theme.textSecondary : Theme.textMuted
                                        font.pixelSize: 8
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                    Item {
                                        width: parent.width
                                        height: parent.height - 34
                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            width: parent.width * 0.64
                                            height: Math.max(3, parent.height * Number(chartBar.modelData.incomeCents || 0) / page.maxIncome())
                                            radius: 5
                                            color: chartBar.modelData.isToday ? Theme.cyan : chartBar.modelData.hasData ? "#268cff" : "#ccd9ee"
                                        }
                                    }
                                    Text { width: parent.width; text: chartBar.modelData.label; color: chartBar.modelData.isToday ? Theme.cyan : Theme.textMuted; font.pixelSize: 8; horizontalAlignment: Text.AlignHCenter }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: qsTr("最近已结算班次"); color: Theme.cyan; font.pixelSize: 13; font.bold: true }
                Item { Layout.fillWidth: true }
                Text { text: page.historyStore.records.length === 0 ? qsTr("等待首个完成班次") : qsTr("最多显示 10 条"); color: Theme.textMuted; font.pixelSize: 9 }
            }
            Repeater {
                model: page.recentRecords
                delegate: Rectangle {
                    id: recordRow
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    radius: 12
                    color: Theme.surfaceDeep
                    border.color: Theme.border
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        Text { Layout.fillWidth: true; text: recordRow.modelData.date; color: Theme.textSecondary; font.pixelSize: 10 }
                        Text { text: qsTr("%1 小时").arg((Number(recordRow.modelData.workMilliseconds || 0) / 3600000).toFixed(1)); color: Theme.cyan; font.pixelSize: 10 }
                        Text { text: page.money(recordRow.modelData.incomeCents); color: Theme.orange; font.pixelSize: 12; font.bold: true }
                    }
                }
            }
            Text { Layout.fillWidth: true; text: qsTr("补记记录按最近保存的排班和工资设置估算；修改设置不会回写已结算历史。当前班次按进度实时预览。"); color: Theme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 3 }
        }
    }
}

