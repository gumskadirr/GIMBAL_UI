import QtQuick
import QtQuick.Templates as T
import IDS_GIMBAL

T.ProgressBar {
    id: control

    property real barHeight: 6
    property color fillColor: Theme.acc

    implicitWidth: 140
    implicitHeight: barHeight
    Accessible.role: Accessible.ProgressBar

    background: Rectangle {
        radius: height / 2
        color: Theme.track
    }

    contentItem: Item {
        implicitHeight: control.barHeight
        Rectangle {
            width: control.indeterminate ? parent.width * 0.3 : control.visualPosition * parent.width
            height: parent.height
            radius: height / 2
            color: control.fillColor
            visible: width > 0
            NumberAnimation on x {
                running: control.indeterminate && control.visible
                from: 0; to: control.width * 0.7
                duration: 900; loops: Animation.Infinite
                easing.type: Easing.InOutQuad
            }
        }
    }
}
