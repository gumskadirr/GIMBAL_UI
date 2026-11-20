pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import IDS_GIMBAL

// model: ["Auto", "Manual"]  or  [{ text: "", iconPath: Icons.sun, accessibleName: "Light theme" }, ...]
Rectangle {
    id: root

    property var model: []
    property int currentIndex: 0
    signal activated(int index)

    implicitHeight: Theme.controlHeight
    implicitWidth: row.implicitWidth + 8
    radius: Theme.rBtn
    color: Theme.input
    opacity: enabled ? 1 : 0.5 // same disabled look as the other controls
    border.width: 1
    border.color: Theme.line2
    Accessible.role: Accessible.Grouping

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 4
        spacing: 2

        Repeater {
            model: root.model
            delegate: T.AbstractButton {
                id: seg
                required property var modelData
                required property int index

                readonly property bool isString: typeof modelData === "string"
                readonly property string label: isString ? modelData : (modelData.text || "")
                readonly property string iconPath: isString ? "" : (modelData.iconPath || "")
                readonly property bool on: root.currentIndex === seg.index
                readonly property color fg: on ? Theme.segOnText : (hovered ? Theme.text : Theme.muted)

                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: 32
                implicitWidth: segRow.implicitWidth + 24
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus

                Accessible.role: Accessible.Button
                Accessible.name: isString ? modelData : (modelData.accessibleName || label)
                Accessible.checkable: true
                Accessible.checked: on

                onClicked: { root.currentIndex = seg.index; root.activated(seg.index) }

                contentItem: Item {
                    Row {
                        id: segRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            width: 15; height: 15
                            anchors.verticalCenter: parent.verticalCenter
                            path: seg.iconPath
                            color: seg.fg
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: seg.label
                            visible: text !== ""
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fsSmall
                            font.weight: Font.DemiBold
                            color: seg.fg
                        }
                    }
                }
                background: Rectangle {
                    radius: Theme.rBtn
                    color: seg.on ? Theme.segOn : "transparent"
                    FocusRing { visible: seg.visualFocus }
                }
            }
        }
    }
}
