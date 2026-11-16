import QtQuick
import QtQuick.Layouts
import IDS_GIMBAL

// Labelled form field; the first child takes the field width.
//   FormField { label: "Baud rate"; IdsComboBox { model: ["115200", "57600"] } }
// inline: true puts the label on the left (labelWidth) and the control on the right.
Item {
    id: root

    property string label: ""
    property bool inline: false
    property real labelWidth: 96
    default property alias content: holder.data

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    function _bind() {
        for (let i = 0; i < holder.children.length; ++i) {
            const c = holder.children[i]
            c.width = Qt.binding(() => holder.width)
            if (c.Accessible && !c.Accessible.name)
                c.Accessible.name = root.label
        }
    }
    Component.onCompleted: _bind()

    GridLayout {
        id: grid
        anchors.fill: parent
        columns: root.inline ? 2 : 1
        rowSpacing: 6
        columnSpacing: 10

        Text {
            Layout.preferredWidth: root.inline ? root.labelWidth : -1
            Layout.fillWidth: !root.inline
            Layout.alignment: Qt.AlignVCenter
            text: root.label
            visible: text !== ""
            wrapMode: Text.WordWrap
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsSmall
            color: Theme.muted
        }
        Item {
            id: holder
            Layout.fillWidth: true
            implicitWidth: children.length ? children[0].implicitWidth : 0
            implicitHeight: children.length ? children[0].implicitHeight : 0
            onChildrenChanged: root._bind()
        }
    }
}
