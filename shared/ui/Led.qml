import QtQuick
import IDS_GIMBAL

// kind: "tx" | "rx" | "heartbeat" | "custom"
// Status bar LED; active: lit (traffic seen / link alive), otherwise idle gray.
Row {
    id: root

    property string kind: "tx"
    property alias text: label.text
    property color ledColor: kind === "tx" ? Theme.tx : Theme.rx
    property bool active: true

    spacing: 6
    Accessible.role: Accessible.StaticText
    Accessible.name: label.text

    Item {
        width: 8; height: 8
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {          // hale / halka
            anchors.centerIn: parent
            width: root.kind === "heartbeat" ? 14 : 12
            height: width
            radius: width / 2
            color: root.kind === "heartbeat" ? Theme.okBg : root.ledColor
            opacity: root.kind === "heartbeat" ? 1 : 0.3
            visible: root.active
        }
        Rectangle {
            anchors.fill: parent
            radius: 4
            color: root.active ? root.ledColor : Theme.idle
        }
    }
    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsOverline
        font.weight: Font.DemiBold
        font.letterSpacing: 0.66
        font.capitalization: Font.AllUppercase
        color: Theme.label
    }
}
