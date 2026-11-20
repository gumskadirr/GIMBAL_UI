import QtQuick
import QtQuick.Layouts
import IdsUi

// Anahtar / değer satırı. Değer yerine özel öğe koymak için çocuk ekleyin:
//   InfoRow { label: "Status"; Badge { kind: "ok"; text: "OK" } }
Item {
    id: root

    property string label: ""
    property string value: ""
    property bool mono: true
    property bool compact: false
    property bool showDivider: true
    property color valueColor: Theme.text
    default property alias trailing: trailingRow.data

    readonly property int _pad: compact ? 7 : 9

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight + 2 * _pad

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.topMargin: root._pad
        anchors.bottomMargin: root._pad
        spacing: 12

        Text {
            Layout.fillWidth: true
            text: root.label
            elide: Text.ElideRight
            font.family: Theme.fontSans
            font.pixelSize: Theme.fsSmall
            color: Theme.muted
        }
        Text {
            text: root.value
            visible: trailingRow.children.length === 0
            font.family: root.mono ? Theme.fontMono : Theme.fontSans
            font.pixelSize: Theme.fsBody
            color: root.valueColor
        }
        Row {
            id: trailingRow
            spacing: 8
            visible: children.length > 0
        }
    }

    Rectangle {
        visible: root.showDivider
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 1
        color: Theme.input
    }
}
