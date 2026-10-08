// 像素面板的双层描边与阶梯角；内容放入内层，避免遮挡发光边缘。
import QtQuick

Item {
    id: panel
    default property alias contentData: body.data
    property color fillColor: Theme.surface
    property color edgeColor: "#142b68"
    property color accentColor: "#69cfff"
    property int padding: 12
    data: [
        Rectangle { x: 3; y: 5; width: panel.width - 3; height: panel.height - 5; color: "#112457" },
        Rectangle { x: 1; y: 1; width: panel.width - 4; height: panel.height - 5; radius: 4; color: panel.fillColor; border.color: panel.edgeColor; border.width: 2 },
        Rectangle { x: 4; y: 4; width: panel.width - 10; height: panel.height - 11; radius: 2; color: "transparent"; border.color: panel.accentColor; border.width: 1 },
        Rectangle { x: 0; y: 8; width: 3; height: Math.max(0, panel.height - 20); color: panel.accentColor },
        Rectangle { x: panel.width - 8; y: 0; width: 5; height: 5; color: panel.accentColor },
        Item { id: body; anchors.fill: parent; anchors.margins: panel.padding; anchors.bottomMargin: panel.padding + 3 }
    ]
}
