import QtQuick
import IdsUi

// Video / 3B model alanı: koyu, noktalı zemin + isteğe bağlı nişangâh.
// Gerçek görüntü için içine VideoOutput veya View3D koyun (anchors.fill: parent).
//   VideoViewport { showCrosshair: true
//       OverlayTag { x: 12; y: 12; mono: true; text: "ROLL 0.0  TILT 0.0" } }
Item {
    id: root

    property real topRadius: Theme.rInp
    property real bottomRadius: Theme.rInp
    property bool showCrosshair: false
    property color crosshairColor: "#FFFFFF"
    property string placeholderIcon: ""
    property string placeholderTitle: ""
    property string placeholderText: ""
    default property alias overlay: overlayLayer.data

    implicitWidth: 640
    implicitHeight: 360

    Canvas {
        id: bg
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const w = width, h = height, tr = root.topRadius, br = root.bottomRadius
            ctx.reset()
            ctx.beginPath()
            ctx.moveTo(tr, 0)
            ctx.lineTo(w - tr, 0); ctx.arcTo(w, 0, w, tr, tr)
            ctx.lineTo(w, h - br); ctx.arcTo(w, h, w - br, h, br)
            ctx.lineTo(br, h); ctx.arcTo(0, h, 0, h - br, br)
            ctx.lineTo(0, tr); ctx.arcTo(0, 0, tr, 0, tr)
            ctx.closePath()
            ctx.fillStyle = Theme.viewportBg
            ctx.fill()
            ctx.clip()
            ctx.fillStyle = Theme.viewportDot
            ctx.beginPath()
            for (let y = 8; y < h; y += 16)
                for (let x = 8; x < w; x += 16) {
                    ctx.moveTo(x + 1.1, y)
                    ctx.arc(x, y, 1.1, 0, Math.PI * 2)
                }
            ctx.fill()
        }
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 280)
        spacing: 10
        visible: root.placeholderTitle !== ""
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56; height: 56; radius: 12
            color: "transparent"
            border.width: 1
            border.color: "#4DFFFFFF"
            visible: root.placeholderIcon !== ""
            Icon { anchors.centerIn: parent; width: 28; height: 28; path: root.placeholderIcon; color: "#BFFFFFFF" }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.placeholderTitle
            font.family: Theme.fontSans; font.pixelSize: 15; font.weight: Font.DemiBold
            color: "#FFFFFF"
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.placeholderText
            visible: text !== ""
            font.family: Theme.fontSans; font.pixelSize: Theme.fsSmall
            lineHeight: 1.5
            color: "#B3FFFFFF"
        }
    }

    Item {         // nişangâh: merkezde 6 px boşluklu 4 çizgi
        anchors.centerIn: parent
        width: 36; height: 36
        visible: root.showCrosshair
        Rectangle { x: 0;  y: 17; width: 12; height: 2; color: root.crosshairColor }
        Rectangle { x: 24; y: 17; width: 12; height: 2; color: root.crosshairColor }
        Rectangle { x: 17; y: 0;  width: 2; height: 12; color: root.crosshairColor }
        Rectangle { x: 17; y: 24; width: 2; height: 12; color: root.crosshairColor }
    }

    Item { id: overlayLayer; anchors.fill: parent }
}
