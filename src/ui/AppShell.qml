// 参考产品图的像素游戏外壳；桌面侧栏、手机五栏共用业务和页面路由。
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: shell
    property var timerController
    property var historyStore
    property string route: "home"
    readonly property bool mobilePlatform: Qt.platform.os === "android" || Qt.platform.os === "ios"
    readonly property bool showSidebar: !mobilePlatform && width >= 960
    readonly property var navigation: [
        {route:"home", label:qsTr("首页"), icon:"home"},
        {route:"tasks", label:qsTr("今日任务"), icon:"tasks"},
        {route:"statistics", label:qsTr("数据统计"), icon:"statistics"},
        {route:"salary", label:qsTr("工资设置"), icon:"salary"},
        {route:"schedule", label:qsTr("工作时间设置"), icon:"gear"},
        {route:"achievements", label:qsTr("成就图鉴"), icon:"achievements"},
        {route:"appearance", label:qsTr("外观换装"), icon:"appearance"},
        {route:"about", label:qsTr("关于"), icon:"about"}
    ]
    readonly property var bottomNavigation: [
        {route:"home", label:qsTr("首页"), icon:"home"},
        {route:"tasks", label:qsTr("任务"), icon:"tasks"},
        {route:"statistics", label:qsTr("统计"), icon:"statistics"},
        {route:"tools", label:qsTr("工具"), icon:"tools"},
        {route:"appearance", label:qsTr("我的"), icon:"cow"}
    ]
    function navigate(target) { route = target; morePopup.close() }
    function routeTitle() {
        for (let i=0; i<navigation.length; ++i) if (navigation[i].route === route) return navigation[i].label
        return qsTr("首页")
    }

    Rectangle { anchors.fill: parent; color: "#09183d"; border.color: "#1badff"; border.width: 2 }
    Rectangle { anchors.fill: parent; anchors.margins: 4; color: "transparent"; border.color: "#7351fc"; border.width: 2 }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 0
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: shell.showSidebar ? 37 : 69
            gradient: Gradient { GradientStop { position:0; color:shell.showSidebar ? "#365999" : "#edfbff" } GradientStop { position:1; color:shell.showSidebar ? "#1b346f" : "#c7e6ff" } }
            border.color: "#6bc8ff"
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 11; anchors.rightMargin: 8; spacing: 8
                PixelIcon { Layout.preferredWidth: shell.showSidebar ? 28 : 44; Layout.preferredHeight: shell.showSidebar ? 28 : 44; kind:"cow" }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text { Layout.fillWidth: true; text: qsTr("牛马打工计时器"); color: shell.showSidebar ? "#ffffff" : Theme.textPrimary; font.pixelSize: shell.showSidebar ? 14 : 19; font.bold: true; elide: Text.ElideRight }
                    Text { visible: !shell.showSidebar; text: qsTr("打工只是副本，下班才是主线！"); color: Theme.textSecondary; font.pixelSize: 10 }
                }
                Text { visible: shell.showSidebar; text: shell.routeTitle(); color:"#dceaff"; font.pixelSize:11 }
                Text { visible: shell.showSidebar; text: shell.timerController.dateText; color:"#bad7ff"; font.pixelSize:10 }
                Rectangle {
                    visible: Qt.platform.os === "windows"
                    Layout.preferredWidth: 29; Layout.preferredHeight: 27
                    color: shell.timerController.windowPinned ? "#4c6ba7" : "transparent"
                    border.color: shell.timerController.windowPinned ? "#00f5ff" : "#7b9dd4"
                    Text { anchors.centerIn: parent; text:"📌"; font.pixelSize:15 }
                    ToolTip.visible: pinMouse.containsMouse
                    ToolTip.text: shell.timerController.windowPinned ? qsTr("取消窗口置顶") : qsTr("窗口置顶")
                    MouseArea { id:pinMouse; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:shell.timerController.windowPinned = !shell.timerController.windowPinned }
                }
                PixelIcon { visible: !shell.showSidebar; Layout.preferredWidth:27; Layout.preferredHeight:27; kind:"gear"; MouseArea { anchors.fill:parent; onClicked:shell.navigate("schedule") } }
            }
        }
        RowLayout {
            Layout.fillWidth:true; Layout.fillHeight:true; spacing:0
            Rectangle {
                visible:shell.showSidebar
                Layout.preferredWidth:174; Layout.fillHeight:true
                gradient:Gradient { GradientStop {position:0;color:"#bfe0fc"} GradientStop {position:1;color:"#7396d8"} }
                border.color:"#82cfff"
                ColumnLayout {
                    anchors.fill:parent; anchors.margins:8; spacing:4
                    Repeater {
                        model:shell.navigation
                        delegate:Rectangle {
                            id:sideItem
                            required property var modelData
                            Layout.fillWidth:true; Layout.preferredHeight:44
                            radius:3
                            color:shell.route === sideItem.modelData.route ? "#e7f8ff" : "transparent"
                            border.color:shell.route === sideItem.modelData.route ? "#ffffff" : "transparent"; border.width:2
                            RowLayout {
                                anchors.fill:parent; anchors.margins:7; spacing:10
                                PixelIcon { Layout.preferredWidth:28; Layout.preferredHeight:28; kind:sideItem.modelData.icon }
                                Text { Layout.fillWidth:true; text:sideItem.modelData.label; color:Theme.textSecondary; font.bold:shell.route === sideItem.modelData.route; font.pixelSize:12; elide:Text.ElideRight }
                            }
                            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:shell.navigate(sideItem.modelData.route) }
                        }
                    }
                    Item { Layout.fillHeight:true }
                    Text { Layout.alignment:Qt.AlignHCenter; text:qsTr("打工只是副本\n下班才是主线！"); color:"#ffe3ff"; style:Text.Outline; styleColor:"#8174be"; font.pixelSize:18; font.family:"KaiTi"; font.bold:true; rotation:-8; horizontalAlignment:Text.AlignHCenter }
                    Item {
                        Layout.fillWidth:true; Layout.preferredHeight:140; clip:true
                        Image { anchors.fill:parent; source:"qrc:/qt/qml/NiumaTimer/assets/office-pixel-v2.png"; fillMode:Image.PreserveAspectCrop; smooth:false }
                        AnimatedSprite { anchors.horizontalCenter:parent.horizontalCenter; anchors.bottom:parent.bottom; anchors.bottomMargin:-17; width:149; height:149; source:"qrc:/qt/qml/NiumaTimer/assets/cow-fatigue-spritesheet.png"; frameWidth:512; frameHeight:512; frameCount:6; currentFrame:Math.round(shell.timerController.progress*5); running:false; paused:true; interpolate:false; smooth:false }
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth:true; Layout.fillHeight:true; spacing:0
                Rectangle {
                    visible:shell.historyStore.storageError.length > 0
                    Layout.fillWidth:true; Layout.preferredHeight:visible ? 35 : 0; color:"#ffe0e0"
                    Text { anchors.fill:parent; anchors.margins:7; text:shell.historyStore.storageError; color:"#9a1032"; font.pixelSize:10; elide:Text.ElideRight }
                }
                Rectangle {
                    Layout.fillWidth:true; Layout.fillHeight:true
                    color:shell.route === "home" ? "#233c7c" : "#e4f1ff"
                    Loader { id:pageHost; anchors.fill:parent; sourceComponent:shell.componentForRoute(shell.route) }
                }
            }
        }
        Rectangle {
            visible:!shell.showSidebar
            Layout.fillWidth:true; Layout.preferredHeight:60
            color:"#f8fcff"; border.color:"#81abe9"
            RowLayout {
                anchors.fill:parent; anchors.margins:3; spacing:2
                Repeater {
                    model:shell.bottomNavigation
                    delegate:Item {
                        id:bottomItem
                        required property var modelData
                        Layout.fillWidth:true; Layout.fillHeight:true
                        Column {
                            anchors.centerIn:parent; spacing:1
                            PixelIcon { anchors.horizontalCenter:parent.horizontalCenter; width:28; height:28; kind:bottomItem.modelData.icon; accent:shell.route === bottomItem.modelData.route ? Theme.cyan : "#28477a" }
                            Text { anchors.horizontalCenter:parent.horizontalCenter; text:bottomItem.modelData.label; color:shell.route === bottomItem.modelData.route ? Theme.cyan : Theme.textSecondary; font.bold:true; font.pixelSize:10 }
                        }
                        MouseArea { anchors.fill:parent; onClicked: { if (bottomItem.modelData.route === "tools") morePopup.open(); else shell.navigate(bottomItem.modelData.route) } }
                    }
                }
            }
        }
    }
    Popup {
        id:morePopup
        parent:Overlay.overlay
        anchors.centerIn:parent
        width:Math.min(parent.width-40,320); padding:12; modal:true; focus:true
        background:Rectangle { color:Theme.surface; border.color:Theme.cyan; border.width:2; radius:4 }
        contentItem:ColumnLayout {
            spacing:4
            Repeater {
                model:shell.navigation.slice(3)
                delegate:Rectangle {
                    id:toolItem
                    required property var modelData
                    Layout.fillWidth:true; Layout.preferredHeight:43
                    color:Theme.surfaceDeep
                    RowLayout { anchors.fill:parent; anchors.margins:8; spacing:9; PixelIcon {Layout.preferredWidth:26;Layout.preferredHeight:26;kind:toolItem.modelData.icon} Text {text:toolItem.modelData.label;color:Theme.textSecondary;font.pixelSize:13} }
                    MouseArea {anchors.fill:parent;onClicked:shell.navigate(toolItem.modelData.route)}
                }
            }
        }
    }
    Component {id:homePage; HomePage {timerController:shell.timerController;historyStore:shell.historyStore;onNavigateRequested:function(target){shell.navigate(target)}}}
    Component {id:tasksPage; TasksPage {timerController:shell.timerController;historyStore:shell.historyStore}}
    Component {id:statisticsPage; StatisticsPage {timerController:shell.timerController;historyStore:shell.historyStore}}
    Component {id:salaryPage; SalarySettingsPage {timerController:shell.timerController}}
    Component {id:schedulePage; ScheduleSettingsPage {timerController:shell.timerController}}
    Component {id:achievementsPage; AchievementsPage {timerController:shell.timerController;historyStore:shell.historyStore}}
    Component {id:appearancePage; AppearancePage {timerController:shell.timerController;historyStore:shell.historyStore}}
    Component {id:aboutPage; AboutPage {historyStore:shell.historyStore}}
    function componentForRoute(target) {
        switch(target) {
        case "tasks":return tasksPage
        case "statistics":return statisticsPage
        case "salary":return salaryPage
        case "schedule":return schedulePage
        case "achievements":return achievementsPage
        case "appearance":return appearancePage
        case "about":return aboutPage
        default:return homePage
        }
    }
    Rectangle {
        id:toastBox
        anchors.horizontalCenter:parent.horizontalCenter; anchors.bottom:parent.bottom; anchors.bottomMargin:shell.showSidebar?18:74
        z:50; visible:opacity>0.01; opacity:0; implicitWidth:Math.min(shell.width-30,toastText.implicitWidth+36); implicitHeight:46
        color:Theme.surface; border.color:Theme.cyan; border.width:2; radius:4
        Text {id:toastText;anchors.fill:parent;anchors.margins:9;color:Theme.textSecondary;font.pixelSize:12;wrapMode:Text.WordWrap;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter}
        Behavior on opacity {NumberAnimation {duration:180}}
    }
    Timer {id:toastTimer;interval:2400;onTriggered:toastBox.opacity=0}
    Connections {target:shell.timerController;function onToast(message){toastText.text=message;toastBox.opacity=1;toastTimer.restart()}}
}
