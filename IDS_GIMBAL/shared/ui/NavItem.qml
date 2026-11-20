import QtQuick
import QtQuick.Templates as T
import IDS_GIMBAL

// NavItem { text: "Motor control"; iconPath: Icons.motor; current: page === "control"; onClicked: ... }
T.AbstractButton {
    id: control

    property var rail: null
    property bool current: false
    property string iconPath: ""
    readonly property bool revealed: rail ? rail.expanded : true
    readonly property color _fg: current ? Theme.navOnText : (hovered ? Theme.text : Theme.muted)

    width: parent ? parent.width : implicitWidth
    implicitWidth: 224
    implicitHeight: 40
    leftPadding: 10
    rightPadding: 10
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus

    Accessible.role: Accessible.Link
    Accessible.name: text
    Accessible.selected: current

    // Keyboard focus only: focus from a mouse click would keep the rail open over the selected page.
    onVisualFocusChanged: if (rail) rail.focusWithin = visualFocus

    contentItem: Row {
        spacing: 14
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: 20; height: 20
            path: control.iconPath
            color: control._fg
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            opacity: control.revealed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsBody
            color: control._fg
        }
    }

    background: Rectangle {
        radius: Theme.rBtn
        color: control.current ? Theme.navOn : (control.hovered ? Theme.input : "transparent")
        border.width: control.current ? 1 : 0
        border.color: Theme.navRing
        FocusRing { visible: control.visualFocus }
    }
}
