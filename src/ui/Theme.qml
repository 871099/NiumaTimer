// 全局主题：集中维护霓虹像素风界面的色彩与间距。
pragma Singleton
import QtQuick

QtObject {
    readonly property color background: "#071226"
    readonly property color surface: "#ffffff"
    readonly property color surfaceRaised: "#d9edff"
    readonly property color surfaceDeep: "#edf6ff"
    readonly property color border: "#426db9"
    readonly property color textPrimary: "#101b40"
    readonly property color textSecondary: "#163678"
    readonly property color textMuted: "#516c96"
    readonly property color cyan: "#004bff"
    readonly property color magenta: "#d32aec"
    readonly property color yellow: "#ffd761"
    readonly property color orange: "#f52d15"
    readonly property color green: "#00d979"
    readonly property color red: "#ff3448"
    readonly property color neonCyan: "#00f5ff"
    readonly property color neonPurple: "#7952ff"
    readonly property int radius: 6
    readonly property int gap: 14
    readonly property int margin: 20
}
