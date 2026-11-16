import QtQuick
import IDS_GIMBAL

// status: "ok" | "warn" | "crit" | "info" | "idle"
Rectangle {
    property string status: "ok"
    property bool glow: false
    property color dotColor: Theme.stateColor(status)

    implicitWidth: 8
    implicitHeight: 8
    radius: width / 2
    color: dotColor

    Rectangle {
        visible: parent.glow
        anchors.centerIn: parent
        width: parent.width * 2; height: width
        radius: width / 2
        color: parent.dotColor
        opacity: 0.25
        z: -1
    }
}
