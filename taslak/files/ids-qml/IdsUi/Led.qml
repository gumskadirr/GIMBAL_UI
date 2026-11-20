import QtQuick
import IdsUi

// Durum çubuğu LED'i. kind: "tx" | "rx" | "heartbeat" | "custom"
// Veri geldiğinde pulse() çağırın; LED kısa süre parlar.
Row {
    id: root

    property string kind: "tx"
    property alias text: label.text
    property color ledColor: kind === "tx" ? Theme.tx : Theme.rx
    property bool active: true

    function pulse() { flash.restart() }

    spacing: 6

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
            id: dot
            anchors.fill: parent
            radius: 4
            color: root.active ? root.ledColor : Theme.idle
            SequentialAnimation {
                id: flash
                NumberAnimation { target: dot; property: "opacity"; to: 0.35; duration: 60 }
                NumberAnimation { target: dot; property: "opacity"; to: 1; duration: 140 }
            }
        }
    }
    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsOverline
        font.weight: Font.DemiBold
        font.letterSpacing: 0.66
        color: Theme.label
    }
}
