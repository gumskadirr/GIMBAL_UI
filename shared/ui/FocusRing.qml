import QtQuick
import IDS_GIMBAL

// Keyboard focus ring: 2 px accent border, 2 px gap.
Rectangle {
    property Item target: parent
    property real baseRadius: Theme.rBtn
    anchors.fill: parent
    anchors.margins: -4
    radius: baseRadius + 4
    color: "transparent"
    border.width: 2
    border.color: Theme.acc
}
