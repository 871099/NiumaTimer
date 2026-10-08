// 原生顶层窗口保留系统标题栏；共享应用壳负责桌面和手机的页面导航。
import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window
    visible: true
    width: 1180
    height: 790
    minimumWidth: 360
    minimumHeight: 600
    title: qsTr("牛马打工计时器")
    color: Theme.background
    // qmllint disable unqualified
    property var appController: workTimer
    property var historyStore: workHistory
    // qmllint enable unqualified
    // 置顶只用于 Windows 桌面窗口，Android 不创建跨应用悬浮窗。
    flags: Qt.Window | (Qt.platform.os === "windows" && appController.windowPinned
                        ? Qt.WindowStaysOnTopHint : 0)

    AppShell {
        anchors.fill: parent
        timerController: window.appController
        historyStore: window.historyStore
    }
}
