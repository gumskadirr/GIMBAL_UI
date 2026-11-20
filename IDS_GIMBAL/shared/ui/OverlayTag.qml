import QtQuick
import IDS_GIMBAL

// Video / 3B görünüm üstündeki küçük etiket ("30 FPS · x1.0").
Rectangle {
    id: root
    property alias text: label.text
    property bool mono: false

    implicitHeight: label.implicitHeight + 8
    implicitWidth: label.implicitWidth + 16
    radius: Theme.rSmall
    color: "#B3000000"
    border.width: 1
    border.color: "#24FFFFFF"

    Text {
        id: label
        anchors.centerIn: parent
        font.family: root.mono ? Theme.fontMono : Theme.fontSans
        font.pixelSize: Theme.fsOverline
        font.weight: root.mono ? Font.Normal : Font.DemiBold
        font.letterSpacing: root.mono ? 0 : 0.66
        color: "#FFFFFF"
    }
}
