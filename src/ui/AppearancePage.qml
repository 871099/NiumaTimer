// 外观换装页：预览透明疲劳动画，以轻量饰品叠层表示解锁装扮。
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page
    property var timerController
    property var historyStore
    readonly property var outfits: {
        timerController.completedWorkdays
        timerController.experienceLevel
        historyStore.selectedOutfit
        return historyStore.outfitOptions()
    }
    readonly property bool compact: width < 700

    function accessoryFor(id) {
        for (let i = 0; i < outfits.length; ++i)
            if (outfits[i].id === id) return outfits[i].accessory
        return ""
    }
    function selectedName() {
        for (let i = 0; i < outfits.length; ++i)
            if (outfits[i].id === historyStore.selectedOutfit) return outfits[i].name
        return qsTr("经典打工装")
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
                Text { text: qsTr("外观换装"); color: Theme.textPrimary; font.pixelSize: 21; font.bold: true }
                Text { text: qsTr("累计工作与升级会解锁新的牛马配饰"); color: Theme.textMuted; font.pixelSize: 11 }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: page.compact ? 218 : 244
                radius: 20
                clip: true
                color: "#0d1d37"
                border.color: Theme.cyan
                Image {
                    anchors.fill: parent
                    source: "qrc:/qt/qml/NiumaTimer/assets/office-pixel-v2.png"
                    fillMode: Image.PreserveAspectCrop
                    smooth: false
                }
                Rectangle { anchors.fill: parent; color: "#a907142b" }
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 4
                    Text { text: qsTr("当前装扮"); color: "#dceaff"; font.pixelSize: 10 }
                    Text { text: page.selectedName(); color: Theme.yellow; font.pixelSize: 16; font.bold: true }
                    Text { text: qsTr("Lv.%1 · 累计上班 %2 天").arg(page.timerController.experienceLevel).arg(page.timerController.completedWorkdays); color: "#c5dcff"; font.pixelSize: 9 }
                }
                AnimatedSprite {
                    id: previewCow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: page.compact ? 170 : 210
                    height: page.compact ? 170 : 210
                    source: "qrc:/qt/qml/NiumaTimer/assets/cow-fatigue-spritesheet.png"
                    frameWidth: 512
                    frameHeight: 512
                    frameCount: 6
                    currentFrame: Math.round(page.timerController.progress * 5)
                    running: false
                    paused: true
                    interpolate: false
                    smooth: false
                }
                Text {
                    anchors.horizontalCenter: previewCow.horizontalCenter
                    anchors.top: previewCow.top
                    anchors.topMargin: 4
                    text: page.accessoryFor(page.historyStore.selectedOutfit)
                    color: Theme.yellow
                    font.pixelSize: 27
                    style: Text.Outline
                    styleColor: "#132540"
                }
            }

            Text { text: qsTr("已解锁装扮"); color: Theme.cyan; font.pixelSize: 13; font.bold: true }
            GridLayout {
                Layout.fillWidth: true
                columns: page.compact ? 1 : 2
                columnSpacing: 10
                rowSpacing: 10
                Repeater {
                    model: page.outfits
                    delegate: Rectangle {
                        id: outfitCard
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        radius: 14
                        color: page.historyStore.selectedOutfit === outfitCard.modelData.id ? "#d2f1ff" : Theme.surface
                        border.color: page.historyStore.selectedOutfit === outfitCard.modelData.id ? Theme.cyan : outfitCard.modelData.unlocked ? Theme.border : "#abc0df"
                        opacity: outfitCard.modelData.unlocked ? 1 : 0.68
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10
                            Rectangle {
                                Layout.preferredWidth: 46
                                Layout.preferredHeight: 46
                                radius: 14
                                color: "#e2efff"
                                border.color: outfitCard.modelData.unlocked ? Theme.cyan : Theme.border
                                Text { anchors.centerIn: parent; text: outfitCard.modelData.accessory.length > 0 ? outfitCard.modelData.accessory : "🐮"; color: Theme.yellow; font.pixelSize: 21 }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text { text: outfitCard.modelData.name; color: Theme.textPrimary; font.pixelSize: 11; font.bold: true }
                                Text { text: outfitCard.modelData.rule; color: Theme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap }
                            }
                            Text { text: page.historyStore.selectedOutfit === outfitCard.modelData.id ? qsTr("使用中") : outfitCard.modelData.unlocked ? qsTr("试穿") : "🔒"; color: outfitCard.modelData.unlocked ? Theme.cyan : Theme.textMuted; font.pixelSize: 10 }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: outfitCard.modelData.unlocked
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: page.historyStore.selectOutfit(outfitCard.modelData.id)
                        }
                    }
                }
            }
            Text { Layout.fillWidth: true; text: qsTr("外观与解锁结果保存在本机，首页和换装预览使用同一疲劳帧与装饰。新服饰通过透明配饰叠层呈现，不会拉伸拼版素材。"); color: Theme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap }
            Item { Layout.preferredHeight: 3 }
        }
    }
}

