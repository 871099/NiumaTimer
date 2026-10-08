// 项目自绘像素图标，避免系统字符/Emoji在Windows与Android呈现不同外观。
import QtQuick

Canvas {
    id: icon
    property string kind: "home"
    property color accent: Theme.cyan
    implicitWidth: 32
    implicitHeight: 32
    antialiasing: false
    onKindChanged: requestPaint()
    onAccentChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d")
        c.clearRect(0, 0, width, height)
        c.save()
        c.scale(width / 24, height / 24)
        const black = "#101938", white = "#fffdf0", blue = accent
        function box(x,y,w,h,color) { c.fillStyle = color; c.fillRect(x,y,w,h) }
        function framed(x,y,w,h,color) { box(x,y,w,h,black); box(x+1,y+1,w-2,h-2,color) }
        if (kind === "cow" || kind === "appearance") {
            box(2,3,4,6,"#815023"); box(18,3,4,6,"#815023")
            box(1,8,5,5,black); box(18,8,5,5,black)
            box(2,9,4,3,"#f7b57a"); box(18,9,4,3,"#f7b57a")
            framed(5,5,14,16,white); box(7,4,10,3,white)
            box(7,7,10,3,"#ff444b"); box(6,6,4,2,"#8e501f")
            box(8,12,2,2,black); box(14,12,2,2,black)
            box(7,15,3,2,"#ffb4af"); box(14,15,3,2,"#ffb4af")
            box(11,16,2,2,black); box(9,20,6,2,black)
        } else if (kind === "money" || kind === "salary") {
            framed(9,1,7,4,"#ffcd35"); box(7,5,11,2,black)
            framed(4,9,17,11,"#ffe55e"); framed(6,7,13,15,"#ffc52e")
            box(10,10,6,1,black); box(9,11,2,3,black); box(11,13,4,2,black)
            box(14,14,2,3,black); box(9,17,6,1,black); box(12,9,1,10,black)
        } else if (kind === "coffee") {
            box(7,1,2,3,black); box(10,3,2,3,black); box(14,1,2,4,black)
            framed(4,8,14,13,white); framed(18,9,5,8,white)
            box(6,7,10,3,black); box(7,10,8,2,"#6c422b")
            box(8,14,3,3,"#ff394c"); box(11,15,3,3,"#ff394c")
        } else if (kind === "freedom") {
            framed(5,3,14,18,"#ffe444"); box(3,7,2,10,black); box(19,7,2,10,black)
            box(8,8,2,3,black); box(14,8,2,3,black)
            box(8,15,2,2,black); box(10,17,5,1,black); box(15,15,1,2,black)
        } else if (kind === "fish") {
            framed(4,7,14,10,"#35dbff"); box(2,10,2,4,black)
            box(17,9,5,7,black); box(19,10,2,5,"#23b5ff")
            box(6,9,2,2,black); box(10,5,3,2,"#0878e8"); box(10,17,3,2,"#0878e8")
        } else if (kind === "sun") {
            framed(7,5,10,11,"#ffe43b"); box(4,3,2,3,"#ffd03a"); box(19,3,2,3,"#ffd03a")
            box(11,0,2,3,"#ffd03a"); box(2,9,3,2,"#ffd03a")
            framed(7,15,16,6,white); framed(12,12,7,8,white)
        } else if (kind === "palm") {
            box(11,11,3,13,"#996024"); box(12,12,1,11,"#e4a34f")
            box(9,4,6,6,black); box(4,6,7,3,black); box(15,5,6,3,black)
            box(1,9,7,3,black); box(16,8,7,3,black)
            box(9,5,5,4,"#52ef67"); box(4,7,7,2,"#27bb56")
            box(15,6,6,2,"#42dd66"); box(2,10,7,2,"#27bb56"); box(16,9,6,2,"#27bb56")
            box(9,10,3,2,"#754529"); box(14,9,3,3,"#754529")
        } else if (kind === "home") {
            box(10,2,4,3,blue); box(7,5,10,3,blue); box(4,8,16,3,blue); box(2,11,20,2,blue)
            framed(5,12,14,10,white); box(9,15,6,7,blue)
        } else if (kind === "statistics") {
            framed(3,13,5,9,blue); framed(10,7,5,15,"#30d6ff"); framed(17,2,5,20,blue)
        } else if (kind === "schedule" || kind === "about") {
            framed(5,3,14,18,white); box(3,7,2,10,black); box(19,7,2,10,black)
            box(11,6,2,7,blue); box(11,12,5,2,blue); box(9,1,6,2,black)
        } else if (kind === "achievements") {
            framed(7,2,11,12,"#ffdf3d"); framed(2,4,5,7,"#ffdf3d"); framed(18,4,5,7,"#ffdf3d")
            box(11,14,3,5,black); framed(7,19,11,4,"#ffa729")
        } else if (kind === "tools" || kind === "gear") {
            box(9,1,6,22,blue); box(1,9,22,6,blue); box(4,4,16,16,blue)
            framed(7,7,10,10,white); framed(10,10,4,4,"#b8e5ff")
        } else {
            framed(5,4,15,18,white); framed(9,1,7,5,"#ffdd4e")
            box(8,9,2,2,blue); box(12,9,5,1,black)
            box(8,13,2,2,blue); box(12,13,5,1,black); box(8,17,9,1,black)
        }
        c.restore()
    }
}
