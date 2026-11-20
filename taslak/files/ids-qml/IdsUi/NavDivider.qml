import QtQuick
import IdsUi

Item {
    property var rail: null
    width: parent ? parent.width : 224
    implicitHeight: 31
    Rectangle {
        x: 6
        width: parent.width - 12
        y: 16
        height: 1
        color: Theme.line
    }
}
