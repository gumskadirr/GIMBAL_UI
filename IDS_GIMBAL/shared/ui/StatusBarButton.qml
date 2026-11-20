import QtQuick
import QtQuick.Templates as T
import IDS_GIMBAL

// Small monospace status bar button ("UART · COM3 · 115200 8N1 ˄").
// iconOnly: true gives a 32x32 icon button (set Accessible.name).
T.Button {
    id: control

    property string iconPath: ""
    property string trailingIconPath: ""
    property bool iconOnly: false
    property bool expanded: false

    implicitWidth: iconOnly ? 32 : implicitContentWidth + leftPadding + rightPadding
    implicitHeight: 32
    leftPadding: iconOnly ? 0 : 12
    rightPadding: leftPadding
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    font.family: Theme.fontMono
    font.pixelSize: Theme.fsSmall
    Accessible.name: text

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8
            Icon { width: 15; height: 15; anchors.verticalCenter: parent.verticalCenter; path: control.iconPath; color: Theme.text2 }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !control.iconOnly && text !== ""
                text: control.text
                font: control.font
                color: Theme.text2
            }
            Icon { width: 15; height: 15; anchors.verticalCenter: parent.verticalCenter; path: control.trailingIconPath; color: Theme.text2 }
        }
    }

    background: Rectangle {
        radius: Theme.rBtn
        color: control.hovered ? Theme.input : "transparent"
        border.width: 1
        border.color: control.expanded ? Theme.acc : Theme.line2
        FocusRing { visible: control.visualFocus }
    }
}
