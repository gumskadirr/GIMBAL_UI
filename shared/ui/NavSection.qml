import QtQuick
import IDS_GIMBAL

// Section heading ("CONTROL"); becomes a short line while the rail is collapsed.
Item {
    id: root
    property var rail: null
    property alias text: label.text
    readonly property bool revealed: rail ? rail.expanded : true

    width: parent ? parent.width : 224
    implicitHeight: 30

    Text {
        id: label
        x: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        opacity: root.revealed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        font.family: Theme.fontSans
        font.pixelSize: Theme.fsOverline
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.overlineSpacing
        font.capitalization: Font.AllUppercase
        color: Theme.label
        Accessible.role: Accessible.Heading
        Accessible.name: text
    }
    Rectangle {
        x: 12
        width: 16                    // short line while collapsed
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        height: 1
        color: Theme.line
        opacity: root.revealed ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
}
