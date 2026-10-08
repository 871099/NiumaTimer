// 双层高光像素进度条：全部数值仍绑定业务层，不在控件中保存状态。
import QtQuick

Rectangle {
    id: meter
    property real value: 0
    property color fillColor: Theme.green
    implicitHeight: 17
    radius: 4
    color: "#faffff"
    border.color: "#789ed5"
    Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 2; color: "#b6cbe8" }
    Rectangle {
        x: 2; y: 2
        width: Math.max(0, (parent.width - 4) * Math.max(0, Math.min(1, meter.value)))
        height: parent.height - 4
        radius: 2
        color: meter.fillColor
        border.width: 1
        border.color: "#ffffff"
        Rectangle { x: 2; y: 2; width: Math.max(0, parent.width - 4); height: 2; color: "#aaffffff" }
        Behavior on width { NumberAnimation { duration: 300 } }
    }
}
