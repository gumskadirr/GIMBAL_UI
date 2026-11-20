pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Top bar: breadcrumb on the left, actions (children) on the right.
//   TopBar { crumbs: ["Main control service", "Gimbal info"]; IdsButton {...} }
Rectangle {
    id: root

    property var crumbs: []
    default property alias actions: actionsRow.data

    implicitHeight: 60
    color: Theme.bg

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 14

        Row {
            spacing: 6
            Repeater {
                model: root.crumbs
                delegate: Row {
                    id: crumb
                    required property string modelData
                    required property int index
                    readonly property bool last: index === root.crumbs.length - 1
                    spacing: 6
                    Text {
                        text: "›"
                        visible: crumb.index > 0
                        font.family: Theme.fontSans; font.pixelSize: Theme.fsBody
                        color: Theme.label
                    }
                    Text {
                        text: crumb.modelData
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fsBody
                        font.weight: crumb.last ? Font.Medium : Font.Normal
                        color: crumb.last ? Theme.text : Theme.label
                    }
                }
            }
        }
        Item { Layout.fillWidth: true }
        RowLayout { id: actionsRow; spacing: 14 }
    }

    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 1
        color: Theme.div
    }
}
