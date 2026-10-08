// 真正的5×7点阵数字；工资和倒计时均实时绘制，缩放时保持像素边缘。
import QtQuick

Canvas {
    id: digits
    property string text: "00:00:00"
    property color ink: "#00ff9a"
    property color outline: "#061d28"
    property bool outlined: true
    implicitHeight: 64
    implicitWidth: text.length * 40
    antialiasing: false
    onTextChanged: requestPaint()
    onInkChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    readonly property var glyphs: ({
        "0": ["01110","11011","11011","11011","11011","11011","01110"],
        "1": ["00110","01110","00110","00110","00110","00110","01111"],
        "2": ["11110","00011","00011","01110","11000","11000","11111"],
        "3": ["11110","00011","00011","01110","00011","00011","11110"],
        "4": ["11011","11011","11011","11111","00011","00011","00011"],
        "5": ["11111","11000","11000","11110","00011","00011","11110"],
        "6": ["01110","11000","11000","11110","11011","11011","01110"],
        "7": ["11111","00011","00011","00110","00110","01100","01100"],
        "8": ["01110","11011","11011","01110","11011","11011","01110"],
        "9": ["01110","11011","11011","01111","00011","00011","01110"],
        ":": ["000","010","010","000","010","010","000"],
        ".": ["00","00","00","00","00","11","11"],
        ",": ["00","00","00","00","01","01","10"],
        "¥": ["10001","01010","00100","11111","00100","11111","00100"],
        " ": ["00","00","00","00","00","00","00"]
    })
    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        let columns = 0
        for (let i = 0; i < text.length; ++i) columns += (glyphs[text[i]] || glyphs[" "])[0].length + 1
        const size = Math.max(1, Math.floor(Math.min((width - 6) / Math.max(1, columns), (height - 6) / 7)))
        let left = Math.floor((width - (columns - 1) * size) / 2)
        const top = Math.floor((height - 7 * size) / 2)
        // 先画整串外描边，再画全部前景，避免相邻像素把高光盖住。
        for (let pass = 0; pass < 2; ++pass) {
            let x = left
            ctx.fillStyle = pass === 0 ? outline : ink
            for (let i = 0; i < text.length; ++i) {
                const glyph = glyphs[text[i]] || glyphs[" "]
                for (let r = 0; r < 7; ++r) for (let c = 0; c < glyph[r].length; ++c) {
                    if (glyph[r][c] !== "1") continue
                    const edge = pass === 0 && outlined ? Math.max(1, Math.floor(size / 3)) : 0
                    if (pass === 0 && !outlined) continue
                    ctx.fillRect(x + c * size - edge, top + r * size - edge, size + 2 * edge, size + 2 * edge)
                }
                x += (glyph[0].length + 1) * size
            }
        }
    }
}
